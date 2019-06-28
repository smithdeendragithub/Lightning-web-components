/**************************************************************************************************
*    OpportunityTriggers.cls
*
*    Modifications:
*    Developer Name       Date        Brief description
*    -------------------  ----------  ------------------------------------------------------------
*    Eunjung Ju           01/10/2018  SEAL-636 - Change the MRR calculation based on Opportunity Type(Oppty_Sub_Type__c)
*    Eunjung Ju           01/12/2018  SEAL-249 - Fix to apply the conversion rate the Currency fields
*    Eunjung Ju           04/05/2018  SEAL-1020 - Add Manual Turndown/Writedown
**************************************************************************************************/
public without sharing class OpportunityTriggers {
    
    public static Boolean triggerDisabled = false;
    private static Map<Id, Datetime> lastRunMap = new Map<Id, Datetime>();
    
    public static void OpportunityModified(List<Opportunity> tNew, List<Opportunity> tOld, Boolean isUpdate, Boolean isBefore){
        if(triggerDisabled) return;
        
        List<Opportunity> tNewNormal = new List<Opportunity>();
        List<Opportunity> tOldNormal = tOld != null ? new List<Opportunity>() : null;
        
        List<Opportunity> tNewSplit = new List<Opportunity>();
        List<Opportunity> tOldSplit = tOld != null ? new List<Opportunity>() : null;
        
        for(Integer i=0; i<tNew.size(); i++){
            if(tNew[i].Opportunity_Parent__c == null){
                tNewNormal.add(tNew[i]);
                if(tOld != null) tOldNormal.add(tOld[i]);
            }
            else{
                tNewSplit.add(tNew[i]);
                if(tOld != null) tOldSplit.add(tOld[i]);
            }
        }
        
        if(tNewNormal.size() > 0)
            OpportunityModified_Normal(tNewNormal, tOldNormal, isUpdate, isBefore);
        if(tNewSplit.size() > 0)
            OpportunityModified_Split(tNewSplit, tOldSplit, isUpdate, isBefore);
    }
    
    private static Boolean fieldUpdatesRun(List<Opportunity> tOld){
        for(Opportunity o : tOld != null ? tOld : new List<Opportunity>()){
            if(lastRunMap.get(o.Id) != null && lastRunMap.get(o.Id) == o.LastModifiedDate)
                return true;
        }
        
        return false;
    }
    
    private static void markLastRun(List<Opportunity> tOld){
        for(Opportunity o : tOld != null ? tOld : new List<Opportunity>())
            lastRunMap.put(o.Id, o.LastModifiedDate);
    }
    
    public static void OpportunityModified_Normal(List<Opportunity> tNew, List<Opportunity> tOld, Boolean isUpdate, Boolean isBefore){
        
        if(!ApexUtils.executeTriggerMethods('Opportunity', isBefore, false)) return;
        
        //Hack to allow fields updated by workflow to be reacted to in the trigger
        Boolean isFirstRun = !fieldUpdatesRun(tOld);
        
        if(isBefore){
            if(isFirstRun){
                calculateMRRAmount(tNew, tOld);
                //requireITSTeamMembers(tNew);
                OpportunitySplit.splitOpportunity(tNew, tOld, isUpdate);
                
                if(isUpdate){
                    boolean forceRefresh = createOrderIfNeeded(tNew);
                    
                    Map<Id, Opportunity> tOldMap = tOld != null ? new Map<Id, Opportunity>(tOld) : new Map<Id, Opportunity>();
                    OrderUtils.synchOpportunityFields(tNew, tOldMap, false, forceRefresh);
                    if(!CustomSettingUtils.getOverrideSettingValue('Require Opportunity Responsible Party')){
                        Map<Id, Opportunity> responsiblePartyRequiredOpportunityStages = getChangedStagedOpportunities(tNew, tOldMap, new Set<String>{ OpportunityUtils.STAGE_CONTRACT_NEGOTIATION, OpportunityUtils.STAGE_CONTRACT_SIGNED, OpportunityUtils.STAGE_4 });
                        if(responsiblePartyRequiredOpportunityStages.size() > 0)
                            checkForMissingResponsibleParty(responsiblePartyRequiredOpportunityStages);
                    }               
                    
                    handleOwnershipChanges(tNew, tOldMap);
                }
            }
        }
        else{
            Map<Id, Opportunity> tNewMap = new Map<Id, Opportunity>(tNew);
            Map<Id, Opportunity> tOldMap = tOld != null ? new Map<Id, Opportunity>(tOld) : new Map<Id, Opportunity>();
            
            if(isUpdate){
                OpportunitySplit.synchChildFields(tNewMap);
            }

            if(isFirstRun){
                if(isUpdate){
                    sendWorkflowAndApprovalEmails(tNew, tOldMap);
                    updateRelatedICBStatuses(tNewMap, tOldMap);
                    updateRelatedOrder(tNewMap, tOldMap);
                    CustomerSurveyUtils.sendOpportunitySurveys(tNew, tOldMap);
                }
                /*else{
                    createOrderIfNeeded(tNew);
                    OrderUtils.synchOpportunityFields(tNew, tOldMap, false);
                }*/
            
                Map<Id, Opportunity> closedWonOpps = getChangedStagedOpportunities(tNew, tOldMap, new Set<String>{OpportunityUtils.STAGE_CLOSED_WON,OpportunityUtils.STAGE_5});
                if(closedWonOpps.size() > 0){
                    createCustomerDetailsForClosedWonOpps(closedWonOpps);
                    updateContracts(closedWonOpps);
                    //OpportunityTriggerTaskCreation.determineClosedWonTasksNeeded(closedWonOpps);
                }
                Map<Id, Opportunity> contractSignedOpps = getChangedStagedOpportunities(tNew, tOldMap, new Set<String>{OpportunityUtils.STAGE_CONTRACT_SIGNED,OpportunityUtils.STAGE_4});
                if(contractSignedOpps.size() > 0){
                    OpportunityTriggerTaskCreation.determineClosedWonTasksNeeded(contractSignedOpps);
                    updateOrdersForContractSignedOpps(contractSignedOpps);
                }
            }
            
            OpportunityUtils.updateRelatedDateTasks(tNew, tOldMap);
            
            if(isUpdate) markLastRun(tOld);
            
            ApexUtils.afterTriggerComplete('Opportunity', false);
        }
        
    }
    
    public static void OpportunityModified_Split(List<Opportunity> tNew, List<Opportunity> tOld, Boolean isUpdate, Boolean isBefore){
        
        if(!ApexUtils.executeTriggerMethods('Opportunity_Split', isBefore, false) || fieldUpdatesRun(tOld)) return;
        
        if(isBefore){
            if(isUpdate) handleOwnershipChanges(tNew, new Map<Id, Opportunity>(tOld));
        }
        else{
            if(isUpdate) markLastRun(tOld);
            ApexUtils.afterTriggerComplete('Opportunity_Split', false);
        }
    }
    
    private static Map<Id, Opportunity> getChangedStagedOpportunities(List<Opportunity> tNew, Map<Id, Opportunity> tOldMap, Set<String> stageNames){
        Map<Id, Opportunity> retval = new Map<Id, Opportunity>();
        for(Opportunity o :tNew){
            Opportunity oOld = tOldMap.get(o.id);
            if(stageNames.contains(o.StageName) && (oOld == null || oOld.StageName != o.StageName))
                retval.put(o.Id, o);
        }
        return retval;
    }
            
    private static void handleOwnershipChanges(List<Opportunity> tNew, Map<Id, Opportunity> tOldMap){
        
        Map<Id, User> userMap = new Map<Id, User>();
        List<Opportunity> modified = new List<Opportunity>();
        for(Opportunity o : tNew){
            Opportunity oOld = tOldMap.get(o.Id);
            if(o.OwnerId != oOld.OwnerId){
                modified.add(o);
                userMap.put(o.OwnerId, null);
                userMap.put(oOld.OwnerId, null);
            }
        }
        
        if(modified.size() > 0){
            userMap = new Map<Id, User>([select OpportunityOwnershipNotification__c, Name, Email, IsActive from User where Id in: userMap.keyset()]);
        
            for(Opportunity o : modified){
                Opportunity oOld = tOldMap.get(o.Id);
                
                User oUser = userMap.get(oOld.OwnerId);
                User nUser = userMap.get(o.OwnerId);
                
                //Do not send ownership change emails for bulk operations
                if(modified.size() == 1){
                    if(oUser != null && oUser.IsActive && oUser.OpportunityOwnershipNotification__c){
                        if(!test.isRunningTest()){
                            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { 
                                    ApexUtils.createEmailMessage(new String[]{oUser.Email}, null, 
                                    'Opportunity Ownership Change',
                                    '<table>' 
                                    + '<tr><td>**Notification of Opportunity Ownership Adjustment for <b><i>' + oOld.Name + '</i></b></td></tr>'
                                    + '<tr><td></td></tr>'
                                    + '<tr><td>Previous Opportunity Owner: <b><i> ' + oUser.Name + '</i></b></td></tr>'
                                    + '<tr><td>New Opportunity Owner: <b><i> ' + nUser.Name + '</i></b></td></tr>'
                                    + '</table>', true, null)                                            
                                    });
                        }
                    }
                }
                
                o.PreviousOwner__c = oUser.Id;
            }
        }
    }
    
    /*private static void requireITSTeamMembers(List<Opportunity> tNew){
        
        Set<String> stageTypesToCheck = new Set<String>{ OpportunityUtils.STAGE_CONTRACT_NEGOTIATION, OpportunityUtils.STAGE_CONTRACT_SIGNED };
        
        List<Opportunity> checkTeamMembers = new List<Opportunity>();
        for(Opportunity o : tNew){
            if(OpportunityUtils.ChangeRecordTypes.contains(o.RecordTypeId) && stageTypesToCheck.contains(o.StageName)) checkTeamMembers.add(o);
        }
        
        if(checkTeamMembers.size() > 0){
            //Require app specialist or ITS ATA II opp team member on opps(new/change) with CPE amt
            Set<Id> oppsWithAppSpecialists = new Set<Id>();
            Set<Id> oppsWithAppSpecialistOVRLY = new Set<Id>();
            for(OpportunityTeamMember otm : [Select Id, TeamMemberRole, OpportunityID From OpportunityTeamMember where OpportunityID in : checkTeamMembers and (TeamMemberRole = 'Application Specialist' or TeamMemberRole = 'ITS ASA II' or TeamMemberRole = 'Application Specialist-OVERLAY')]){
                if(otm.TeamMemberRole == 'Application Specialist-OVERLAY')
                    oppsWithAppSpecialistOVRLY.add(otm.OpportunityId);
                else if(otm.TeamMemberRole == 'Application Specialist Combo'){
                    oppsWithAppSpecialistOVRLY.add(otm.OpportunityId);
                    oppsWithAppSpecialists.add(otm.OpportunityID);
                }
                else
                    oppsWithAppSpecialists.add(otm.OpportunityID);
            }
            
            Set<Id> oppsWithITSProducts = new Set<Id>();
            List<String> ITSOppProds = CustomSettingUtils.GetITSOppProductNames();
            for(Opportunity_Product__c oppProd : [select Id, Opportunity__c from Opportunity_Product__c where Opportunity__c in :checkTeamMembers and Sales_Product__c in :ITSOppProds and active__c = true]){
                oppsWithITSProducts.add(oppProd.Opportunity__c);
            }
            
            for(Opportunity o : checkTeamMembers){
                if(!oppsWithAppSpecialists.contains(o.Id) && o.CPE_Amount__c != null && o.CPE_Amount__c != 0) o.addError('Unable to save the Opportunity with CPE Amount Products without and Application Specialist or ITS ASA II Opportunity Team Member');
                if(!oppsWithAppSpecialistOVRLY.contains(o.Id) && oppsWithITSProducts.contains(o.Id)) o.addError('Unable to save the Opportunity with Managed/Hosted ITS Overlay Products without an Application Specialist-OVERLAY Opportunity Team Member');
            }
        }
    }*/
    
    /* ICB related section */
    private static final Set<String> lostICBStatusSet = new Set<String>{'New', 'In Progress', 'Recalled', 'In Progress-OM and PM Approved'};
    private static final Set<String> wonICBStatusSet = new Set<String>{'Approved-Pending Sale'};
    
    public static void updateRelatedICBStatuses(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpp){
        
        Set<Id> stageRelatedIDs = new Set<id>();
        for(Opportunity opp : newOpps.values()){
            if(opp.StageName != oldOpp.get(opp.Id).StageName && opp.StageName != null && OpportunityUtils.oppIsClosed(opp))
                stageRelatedIDs.add(opp.Id);
        }
        
        //  Removed ICB_Technical_Reason__c because this field is deleted
        if(stageRelatedIDs.size() > 0){
            Map<Id, ICB__c> m = new Map<Id, ICB__c>([select Name, Id, Status__c, Opportunity__c, ICB_Pricing_Reason__c, ICB_Type__c from ICB__c where Opportunity__c in: stageRelatedIDs]);
            Map<Id, ICB__c> updates = new Map<Id, ICB__c>();
            
            for(Opportunity o : newOpps.values()){
                if(StageRelatedIds.contains(o.id)){
                    if(o.StageName == OpportunityUtils.STAGE_CLOSED_LOST){
                        for(ICB__c i : updateICBStatus(getICBsByOpportunityIdAndStatus(m, o.id, lostICBStatusSet), 'Cancelled'))
                            updates.put(i.id, i);
                    }
                    else if(o.StageName == OpportunityUtils.STAGE_CONTRACT_SIGNED  || o.StageName == OpportunityUtils.STAGE_4){
                        for(ICB__c i : updateICBStatus(getICBsByOpportunityIdAndStatus(m, o.id, wonICBStatusSet), 'Approved'))
                            updates.put(i.id, i);
                    }
                }
            }
            
            List<ICB__c> icbs = updates.values();
            if(icbs.size() > 0){
                List<String> errors = new List<String>();
                
                Database.SaveResult[] results = Database.update(icbs, false);
                for(Integer i=0; i<results.size(); i++){
                    Database.SaveResult result = results[i];
                    for(Database.Error error : result.getErrors())
                        errors.add(icbs[i].Id + ': ' + error.message);
                }
                
                if(errors.size() > 0)
                    ApexUtils.sendEmails(new List<Messaging.SingleEmailMessage>{ApexUtils.createEmailMessage(new List<String>{UserInfo.getUserEmail()}, CustomSettingUtils.IntegrationErrorEmailAddresses, 'ICB records failed to save from Opportunity stage change', string.join(errors, '\n'), false, null)});
            }
        }
    }
    
    private static List<ICB__c> getICBsByOpportunityIdAndStatus(Map<Id, ICB__c> icbmap, Id oppId, Set<String> statuses){
        List<ICB__c> icblist = new List<ICB__c>();
        for(ICB__c icb : icbmap.values()){
            string strOppid = icb.Opportunity__c;
            if(strOppid.contains(oppId) && statuses.contains(icb.status__c))
                icblist.add(icb);
        }
        return icblist; 
    }
    
    private static List<ICB__c> updateICBStatus(List<ICB__c> icbs, String newStatus){
        
        for(icb__c icb : icbs){
            icb.Status__c = newStatus;
            
            icb.ICB_Pricing_Reason__c = (string.isEmpty(icb.ICB_Pricing_Reason__c) && icb.ICB_Type__c == 'Pricing') ? 'Other' : icb.ICB_Pricing_Reason__c;
        }
        
        return icbs;
    }
    /* End: ICB related section */
    
    /* Customer related section */
    public static void checkForMissingResponsibleParty(Map<Id, Opportunity> opps) {
        List<Opportunity> oppList = opps.values();
        for(Opportunity o : oppList){
            if(o.Sales_Channel__c == 'Wholesale')
                opps.remove(o.Id);
        }
        
        if(opps.size() > 0){
            Map<Id, List<Service_Location__c>> serviceLocsByOppID = OpportunityUtils.getServiceLocationsFromOpportunities(opps);
            Map<Id, Id> responsiblePartiesByOpportunityID = getResponsiblePartyContactRolesByOpportunityID(opps);
            Map<Id, Contact> contacts = responsiblePartiesByOpportunityID.size() > 0 ? new Map<Id, Contact>([select Id, Email from Contact where Id in: responsiblePartiesByOpportunityID.values()]) : new Map<Id, Contact>();
            
            Map<Id, Set<Id>> opportunityIDsByServiceLocID = new Map<Id, Set<Id>>();
            for(Id oppID : serviceLocsByOppID.keyset()){
                for(Service_Location__c sLoc : serviceLocsByOppID.get(oppID)){
                    Set<Id> oppIDs = opportunityIDsByServiceLocID.get(sLoc.Id) != null ? opportunityIDsByServiceLocID.get(sLoc.Id) : new Set<Id>();
                    oppIDs.add(oppID);
                    opportunityIDsByServiceLocID.put(sLoc.Id, oppIDs);
                }
            }
            
            Map<Id, Account> accounts = new Map<Id, Account>();
            Map<Id, Integer> customerDetailsWithResponsibleParties = new Map<Id, Integer>();        //0: Does not exist, 1: Exists with no email, 2: Exists with email
            Map<Id, List<Service_Location__c>> sLocsByAccountID = new Map<Id, List<Service_Location__c>>();
            if(opportunityIDsByServiceLocID.size() > 0){
                for(Service_Location__c sLoc : [select Id
                                                ,Customer_Detail__c
                                                ,Account__r.Id
                                                ,Account__r.Customer_Detail__c
                                                from Service_Location__c
                                                where Id in : opportunityIDsByServiceLocID.keyset()]){
                List<Service_Location__c> l = sLocsByAccountID.get(sLoc.Account__c);
                if(l == null){
                    accounts.put(sLoc.Account__c, sLoc.Account__r);
                    l = new List<Service_Location__c>();
                    if(sLoc.Account__r.Customer_Detail__c != null)
                        customerDetailsWithResponsibleParties.put(sLoc.Account__r.Customer_Detail__c, 0);
                }
                l.add(sLoc);
                sLocsByAccountID.put(sLoc.Account__c, l);
                if(sLoc.Customer_Detail__c != null)
                    customerDetailsWithResponsibleParties.put(sLoc.Customer_Detail__c, 0);
                }
            }
            
            Set<String> invalidRespPartyMessages = new Set<String>();
            if(customerDetailsWithResponsibleParties.size() > 0){
                for(Customer_Contact__c respParty : [select Id, Customer_Detail__c, Email__c, Contact__r.Name, Contact__r.Email from Customer_Contact__c where Contact_Type__c =: ICCWrapper.ResonsiblePartyContactType and Customer_Detail__c in : customerDetailsWithResponsibleParties.keyset()]){
                    customerDetailsWithResponsibleParties.put(respParty.Customer_Detail__c, (string.IsEmpty(respParty.Email__c) && string.IsEmpty(respParty.Contact__r.Email)) ? 1 : 2);
                }
            }
            
            Set<Id> accountsWithDefaultRespParty = new Set<Id>();
            if(accounts.size() > 0){
                for(Contact c : [select AccountId from Contact where Default_Responsible_Party__c = true and AccountId in : accounts.keyset() and Email != null])
                    accountsWithDefaultRespParty.add(c.AccountId);
            }
            Set<Id> needsResponsibleParty = new Set<Id>();
            Set<Id> needsResponsiblePartyEmail = new Set<Id>();
            
            for(Id accountId : sLocsByAccountID.keyset()){
                if(!accountsWithDefaultRespParty.contains(accountId)){
                    Account a = accounts.get(accountId);
                    Integer mode = (a.Customer_Detail__c == null) ? 0 : customerDetailsWithResponsibleParties.get(a.Customer_Detail__c);
                    
                    if(mode != 2){
                        for(Opportunity opp : opps.values()){
                            if(opp.AccountId == a.Id){
                                if(mode == 1)
                                    needsResponsiblePartyEmail.add(opp.Id);
                                else if(responsiblePartiesByOpportunityID.get(opp.Id) == null || string.isEmpty(contacts.get(responsiblePartiesByOpportunityID.get(opp.Id)).Email))
                                    needsResponsibleParty.add(opp.Id);
                            }
                        }
                    }
                    else{
                        for(Service_Location__c sLoc : sLocsByAccountID.get(a.Id)){
                            mode = (sLoc.Customer_Detail__c == null) ? 0 : customerDetailsWithResponsibleParties.get(sLoc.Customer_Detail__c);
                            
                            if(mode != 2){
                                for(Id oppId : opportunityIDsByServiceLocID.get(sLoc.Id)){
                                    if(mode == 1)
                                        needsResponsiblePartyEmail.add(oppId);
                                    else if(responsiblePartiesByOpportunityID.get(oppId) == null || string.isEmpty(contacts.get(responsiblePartiesByOpportunityID.get(oppId)).Email))
                                        needsResponsibleParty.add(oppId);
                                }
                            }
                        }
                    }
                }
            }
            
            for(Id id : needsResponsibleParty)
                opps.get(id).addError('A Responsible Party contact role with a valid email address is required at this stage for this opportunity.');
            
            for(Id id : needsResponsiblePartyEmail)
                opps.get(id).addError('One or more existing Responsible Party contacts associated to this opportunity do not have a valid email address and must be corrected by this stage.');
        }
    }
    
    public static void createCustomerDetailsForClosedWonOpps(Map<Id, Opportunity> closedWonOpps){
        Map<Id, List<Service_Location__c>> serviceLocsByOppID = OpportunityUtils.getServiceLocationsFromOpportunities(closedWonOpps);
        Map<Id, Id> responsiblePartiesByOpportunityID = getResponsiblePartyContactRolesByOpportunityID(closedWonOpps);
        
        Set<Id> sLocIDs = new Set<Id>();
        for(List<Service_Location__c> sLocs : serviceLocsByOppID.values()){
            for(Service_Location__c sLoc : sLocs)
                sLocIDs.add(sLoc.Id);
        }
        
        if(sLocIDs.size() == 0) return;
        
        Map<Id, Boolean> customerDetailsWithResponsibleParties = new Map<Id, Boolean>();
        Map<Id, List<Service_Location__c>> sLocsByAccountID = new Map<Id, List<Service_Location__c>>();
        for(Service_Location__c sLoc : [select Id
                                            ,Customer_Detail__c
                                            ,Account__r.Id
                                            ,Account__r.Customer_Detail__c
                                            from Service_Location__c
                                            where Id in : sLocIDs]){
            List<Service_Location__c> l = (sLocsByAccountID.get(sLoc.Account__c) != null) ? sLocsByAccountID.get(sLoc.Account__c) : new List<Service_Location__c>();
            l.add(sLoc);
            sLocsByAccountID.put(sLoc.Account__c, l);
            if(sLoc.Customer_Detail__c != null)
               customerDetailsWithResponsibleParties.put(sLoc.Customer_Detail__c, false);
        }
                                            
        Map<Id, Account> accounts = new Map<Id, Account>([select Id, Customer_Detail__c, (select Id from Account_Locations__r limit 2) from Account where Id in: sLocsByAccountID.keyset()]);
        
        if(customerDetailsWithResponsibleParties.size() > 0){
            for(Customer_Contact__c respParty : [select Id, Customer_Detail__c from Customer_Contact__c where Contact_Type__c =: ICCWrapper.ResonsiblePartyContactType and Customer_Detail__c in : customerDetailsWithResponsibleParties.keyset()])
                customerDetailsWithResponsibleParties.put(respParty.Customer_Detail__c, true);
        }
        
        Map<Id, Id> repsonsiblePartiesToCreate = new Map<Id, Id>();
        List<Set<Id>> detailsToUpdate = new List<Set<Id>>();
        Set<Id> accountsToUpdate = new Set<Id>();
        Set<Id> sLocsToUpdate = new Set<Id>();
        for(Opportunity opp : closedWonOpps.values()){
            List<Service_Location__c> oppServiceLocs = serviceLocsByOppID.get(opp.Id);
            if(opp.AccountId == null || oppServiceLocs == null) continue;
            Account a = accounts.get(opp.AccountId);
            List<Service_Location__c> sLocs = sLocsByAccountID.get(opp.AccountId);
            
            if(a == null || sLocs == null || sLocs.size() == 0) continue;
 
            if((a.Customer_Detail__c == null || customerDetailsWithResponsibleParties.get(a.Customer_Detail__c) != true) && repsonsiblePartiesToCreate.get(a.Id) == null)
                repsonsiblePartiesToCreate.put(a.Id, responsiblePartiesByOpportunityID.get(opp.Id));
            
            if(a.Customer_Detail__c == null && !accountsToUpdate.contains(a.Id)){
                detailsToUpdate.add(a.Account_Locations__r.size() == 1
                                        ? new Set<Id>{a.Id, sLocs[0].Id}
                                        : new Set<Id>{a.Id});
                accountsToUpdate.add(a.Id);
            }
            
            Map<Id, Service_Location__c> sLocMap = new Map<Id, Service_Location__c>(sLocs);
            for(Service_Location__c oppServiceLoc : oppServiceLocs){
                Service_Location__c sLoc = sLocMap.get(oppServiceLoc.Id);
                if(sLoc != null){
                    if(a.Account_Locations__r.size() > 1 || a.Customer_Detail__c != null){
                        if(sLoc.Customer_Detail__c == null && !sLocsToUpdate.contains(sLoc.Id)){
                            detailsToUpdate.add(new Set<Id>{sLoc.Id});
                            sLocsToUpdate.add(sLoc.Id);
                        }
                    }
                    if((sLoc.Customer_Detail__c == null || customerDetailsWithResponsibleParties.get(sLoc.Customer_Detail__c) != true)
                        && repsonsiblePartiesToCreate.get(sLoc.Id) == null && a.Account_Locations__r.size() > 1){
                        repsonsiblePartiesToCreate.put(sLoc.Id, responsiblePartiesByOpportunityID.get(opp.Id));
                    }
                }
            }
        }
        
        Map<Id, List<Customer_Contact__c>> contactsToCreate = new Map<Id, List<Customer_Contact__c>>();
        for(Id id : repsonsiblePartiesToCreate.keyset()){
            if(repsonsiblePartiesToCreate.get(id) != null)
                contactsToCreate.put(id, new List<Customer_Contact__c>{new Customer_Contact__c(Contact__c = repsonsiblePartiesToCreate.get(id), Contact_Type__c = ICCWrapper.ResonsiblePartyContactType)});
        }
        
        CustomerDetailUtils.updateCustomerDetails(detailsToUpdate, contactsToCreate);
    }
    
    private static Map<Id, Id> getResponsiblePartyContactRolesByOpportunityID(Map<Id, Opportunity> opps){
        List<OpportunityContactRole> roles = [select Id, ContactId, OpportunityId, Contact.AccountId, Role from OpportunityContactRole where OpportunityId in : opps.keyset()];
        Map<Id, Id> responsiblePartiesByOpportunityID = new Map<Id, Id>();
        for(OpportunityContactRole role : roles){
            if(role.Contact.AccountId == opps.get(role.OpportunityId).AccountId && role.Role == ICCWrapper.ResonsiblePartyContactType)
                responsiblePartiesByOpportunityID.put(role.OpportunityId, role.ContactId);
        }
        
        return responsiblePartiesByOpportunityID;
    }
    /* End: Customer related section */
    
    /* Order related section */
    public static boolean createOrderIfNeeded(List<Opportunity> newOppt){
        
        if(OpportunitySplit.isSaving) return false;
        
        Set<Id> oppsWithOrders = new Set<Id>();
        for(Order__c o : [Select Opportunity__c From Order__c Where Opportunity__c in :newOppt])
            oppsWithOrders.add(o.Opportunity__c);
        
        List<Order__c> newOrders = new List<Order__c>();
        for(Opportunity o : newOppt){
            if(o.Opportunity_Parent__c == null && (o.StageName == OpportunityUtils.STAGE_CONTRACT_SIGNED || o.StageName == OpportunityUtils.STAGE_CLOSED_WON || o.StageName == OpportunityUtils.STAGE_4 || o.StageName == OpportunityUtils.STAGE_5) && !oppsWithOrders.contains(o.Id)){
                newOrders.add(new Order__c(Opportunity__c = o.Id
                                            ,OwnerId = o.OwnerId
                                            ,Record_Status__c = 'New'
                                            ,Status__c = 'Sales Working'));
            }
        }
        
        if(newOrders.size() > 0)
            insert newOrders;
        return newOrders.size() > 0;
    }
    
    public static void updateRelatedOrder(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpp){

        Map<Id, Opportunity> stageChanged = getChangedStagedOpportunities(newOpps.values(), oldOpp, new Set<String>{OpportunityUtils.STAGE_CONTRACT_SIGNED, OpportunityUtils.STAGE_4});
        List<Order__c> orderWithChanges = new List<Order__c>();
        for(Order__c ord : [select Winning_ICB__c
                                    ,OwnerId
                                    ,Opportunity__r.Id
                                    ,Opportunity__r.Winning_ICB__r.Name
                                    ,Opportunity__r.OwnerId
                                    ,Opportunity__r.StageName
                                    from Order__c Where opportunity__c IN : newOpps.keyset()]){
            Boolean updateICB = ord.Winning_ICB__c != (ord.Opportunity__r != null && ord.Opportunity__r.Winning_ICB__r != null ? ord.Opportunity__r.Winning_ICB__r.Name : null);
            Boolean updateOwner = (ord.OwnerId != ord.Opportunity__r.OwnerId) && ord.Opportunity__r.StageName != OpportunityUtils.STAGE_CONTRACT_SIGNED && ord.Opportunity__r.StageName != OpportunityUtils.STAGE_CLOSED_WON && ord.Opportunity__r.StageName != OpportunityUtils.STAGE_4 && ord.Opportunity__r.StageName != OpportunityUtils.STAGE_5;
            Boolean updateOppStatus = stageChanged.keyset().contains(ord.Opportunity__r.Id);
            if(updateICB) ord.Winning_ICB__c = ord.Opportunity__r.Winning_ICB__r.Name;
            if(updateOwner) ord.OwnerId = ord.Opportunity__r.OwnerId;
            if(updateOppStatus) ord.Status__c = 'Sales Working';
            if(updateICB || updateOwner || updateOppStatus) orderWithChanges.add(ord);
        }
        
        if(orderWithChanges.size() > 0)
            update orderWithChanges;
    }
    
    public static void updateOrdersForContractSignedOpps(Map<Id, Opportunity> opps){
        List<Order__c> ordersToUpdate = new List<Order__c>();
        for(Order__c ord : [select id, opportunity__c from order__c where opportunity__c in :opps.keyset()]){
            Opportunity opp = opps.get(ord.Opportunity__c);
            if(opp.Type == 'New Logo'){
                ord.Approved_MRR__c = opp.amount;
                ordersToUpdate.add(ord);
            }
        }
        if(ordersToUpdate.size() > 0){
            update ordersToUpdate;
        }
        Set<Id> tovOpps = new Set<Id>();
        for(Id opp : opps.keyset()){             
            tovOpps.add(opp);           
        }
        WorkstepUtils.createOrderWorkstepForContractSigned(tovOpps);
    }
    /* End: Order related section */
    
    /* Contract related section */
    private static void updateContracts(Map<Id, Opportunity> closedWonOpps){
        Set<Id> accountIDs = new Set<Id>();
        Map<Id, Date> executionDates = new Map<Id, Date>();
        for(Opportunity o : closedWonOpps.values()){
            accountIDs.add(o.AccountId);
            executionDates.put(o.AccountId, o.Contract_Signed_Date__c);
        }
        
        SecurityUtils.updateAccountContractStatuses(accountIDs, 'Pending', new Set<String>{'Draft'}, executionDates);
    }
    /* End: Contract related section */
    
    /* Workflow and approval emails section */
    private static User cCollectionsDL = null;
    private static User CollectionsDL{
        get{
            if(cCollectionsDL == null){
                for(User u : [Select Id from User where Email = 'corpcreditcheck@integratelecom.com']) cCollectionsDL = u;
            }
            return cCollectionsDL;
        }
    }
    
    private static User cCACollectionsDL = null;
    private static User CACollectionsDL{
    get{
            if(cCACollectionsDL == null){
                for(User u : [Select Id from User where Email = 'credit@allstream.com']) cCACollectionsDL = u;
//              for(User u : [Select Id from User where Email = 'marc.kirouac@allstream.com']) cCACollectionsDL = u;              
            }
            return cCACollectionsDL;
        }
    }
    
    private static void sendWorkflowAndApprovalEmails(List<Opportunity> tNew, Map<Id, Opportunity> tOldMap){
        Map<Id, Opportunity> stageChanged = getChangedStagedOpportunities(tNew, tOldMap, new Set<String>{OpportunityUtils.STAGE_CONTRACT_SIGNED, OpportunityUtils.STAGE_CLOSED_WON,OpportunityUtils.STAGE_4,OpportunityUtils.STAGE_5});
        
        if(stageChanged.size() > 0){
            Map<Id, Account> accounts = new Map<Id, Account>();
            for(Opportunity o : stageChanged.values()) accounts.put(o.AccountId, null);
            accounts = new Map<Id, Account>([select Id, RecordType.DeveloperName from Account where Id in: accounts.keyset()]);
            
            Map<Id, Order__c> ordByOppId = new Map<Id,Order__c>();
            for(Order__c ord : [Select Credit_Check_Approval__c, Credit_Hold_Reason__c, Credit_Commitment_Met__c, Opportunity__c, Market_Area__c from Order__c Where Opportunity__c in: stageChanged.keySet()])
                ordByOppId.put(ord.Opportunity__c, ord);
            
            for(Opportunity newOpp : stageChanged.values()){
                Account a = accounts.get(newOpp.AccountId);
                
                Order__c ord = ordByOppId.get(newOpp.Id);
                if(ord != null && a.RecordType.DeveloperName != 'ILEC_Prior_Lake' && ord.Credit_Check_Approval__c == null && ord.Credit_Commitment_Met__c == null && newOpp.Sales_Channel__c != 'Sales Support'){
                    Boolean sendEmail = false;
                    Boolean isWholesale = newOpp.Sales_Channel__c == 'Wholesale';
                    if(newOpp.Type == 'New Logo') sendEmail = true;
                    else if(newOpp.Type == 'Existing') sendEmail = !isWholesale && newOpp.Sales_Channel__c != 'Government and Education' && newOpp.New_MRR_del__c > 500;
                    else if(OpportunityUtils.ChangeRecordTypes.contains(newOpp.RecordTypeId)) sendEmail = !isWholesale && newOpp.Net_Difference__c > 500 && (newOpp.Type == 'Conversion' || newOpp.Type == 'Move' || newOpp.Type == 'Upgrade');
                    
                    if(sendEmail && !ApexUtils.isSandbox()){
                        if(newOpp.StageName == OpportunityUtils.STAGE_CONTRACT_SIGNED || newOpp.StageName == OpportunityUtils.STAGE_4 ) {
                            If (ord.Market_Area__c == 'National')
                                OpportunityUtils.sendWorkflowAndApprovalEmail(newOpp.Id, 'Credit_Check_Proposed_Stage', new List<User>{CACollectionsDL});
                            else
                                OpportunityUtils.sendWorkflowAndApprovalEmail(newOpp.Id, 'Credit_Check_Proposed_Stage', new List<User>{CollectionsDL});
                        } else if(newOpp.StageName == OpportunityUtils.STAGE_CLOSED_WON || newOpp.StageName == OpportunityUtils.STAGE_5)
                            If (ord.Market_Area__c != 'National')
                                OpportunityUtils.sendWorkflowAndApprovalEmail(newOpp.Id, 'Credit_Check_ClosedWon', new List<User>{CollectionsDL});
                    }
                }
            }
        }
    }
    /* End: Workflow and approval emails section */
    private static void calculateMRRAmount(List<Opportunity> tNew, List<Opportunity> tOld){
		//MNK added to reduce SOQL calls
        Map<String, currencytype> conversionRateMap = new Map<String, currencytype>();
        for (currencyType ct: [SELECT isocode, conversionrate FROM currencytype]) {
        	conversionRateMap.put(ct.IsoCode,ct);        
        }
         
        Map<Id, Opportunity> tOldMap = tOld != null ? new Map<Id, Opportunity>(tOld) : new Map<Id, Opportunity>();
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        Map<Id, Map<Boolean, List<AggregateResult>>> opAgg = new Map<Id, Map<Boolean, List<AggregateResult>>>();        
        for(Opportunity dNew : tNew){
            Opportunity dOld = tOldMap.get(dNew.Id);
                
            if((dOld != null && dNew.Type != dOld.Type) || (dOld != null && dNew.Oppty_Sub_Type__c != dOld.Oppty_Sub_Type__c) 
               || (dOld != null && dNew.CurrencyIsoCode != dOld.CurrencyIsoCode)){
                opps.put(dNew.Id, dNew);
                opAgg.put(dNew.Id, new Map<Boolean, List<AggregateResult>>{ true=>new List<AggregateResult>(), false=>new List<AggregateResult>() });
            }            
        }
        
        if(opps.keyset().size() > 0){
            for(AggregateResult ar : [select SUM(MRC__c) sumAmount, SUM(NRC__c) sumNRRAmount, SUM(CPE_Amount__c) sumCPEAmount, Opportunity__c, Sales_Product__c, RecordType.Name recordType, Is_CPE_Product__c from Opportunity_Product__c where Active__c = true and Opportunity__c in: opps.keyset() group by Opportunity__c, Sales_Product__c, RecordType.Name, Is_CPE_Product__c])
               opAgg.get((Id)ar.get('Opportunity__c')).get(ar.get('recordType') == 'Turndown/Writedown' || ar.get('recordType') == 'Manual Turndown/Writedown' || ar.get('Sales_Product__c') == 'Turndown').add(ar);
        
            for(Opportunity opp : opps.values()){                
                Decimal sumAmount = 0.00;
                Decimal nrrAmount = 0.00;
                Decimal cpeAmount = 0.00;
                Set<String> products = new Set<String>();
                
                Decimal tdSumAmount = 0.00;
                Set<String> tdProducts = new Set<String>();
                
                Map<Boolean, List<AggregateResult>> aggMap = opAgg.get(opp.Id); 
                for(Boolean isTurnDown : aggMap.keyset()){
                    for(AggregateResult agg : aggMap.get(isTurnDown)){
                        if(isTurnDown){
                            tdSumAmount -= agg.get('sumAmount') != null ? (Decimal)agg.get('sumAmount') : 0.00;
                            tdProducts.add(string.valueOf(agg.get('Sales_Product__c')));
                        }
                        else{
                            sumAmount += agg.get('sumAmount') != null ? (Decimal)agg.get('sumAmount') : 0.00;
                            nrrAmount += agg.get('sumNRRAmount') != null ? (Decimal)agg.get('sumNRRAmount') : 0.00;
                            cpeAmount += (Boolean)agg.get('Is_CPE_Product__c') == true ? (Decimal)agg.get('sumCPEAmount') : 0.00;
                            products.add(string.valueOf(agg.get('Sales_Product__c')));
                        }
                    }
                }
                
                List<String> prds = new List<String>(products);
                prds.sort();
                Decimal conversionRate = conversionRateMap.get(opp.CurrencyIsoCode).conversionRate;
                //Decimal conversionRate = [SELECT conversionrate FROM currencytype WHERE isocode = :opp.CurrencyIsoCode].conversionRate;
                
                //opp.New_MRR_del__c = sumAmount;
                opp.New_MRR_del__c = sumAmount*conversionRate ;
                
                //opp.NRR_Amount__c = nrrAmount;
                opp.NRR_Amount__c = nrrAmount*conversionRate;
                
                //opp.CPE_Amount__c = cpeAmount;
                opp.CPE_Amount__c = cpeAmount*conversionRate;
                
                opp.Opportunity_Product__c = String.join(prds, '; ');
                
                prds = new List<String>(tdProducts);
                prds.sort();
                //opp.Current_MRR_del__c = tdSumAmount;
                opp.Current_MRR_del__c = tdSumAmount*conversionRate;    
                
                opp.Turndown_Product__c = String.join(prds, '; ');
                
                Decimal oppNewMRRDel = opp.New_MRR_del__c == null ? 0.00 : opp.New_MRR_del__c;
                Decimal oppCurrentMRRDel = opp.Current_MRR_del__c == null ? 0.00 : opp.Current_MRR_del__c;
                
                if(opp.Oppty_Sub_Type__c == 'Product Change' || opp.Oppty_Sub_Type__c == 'New Logo'){
                    opp.Amount = oppNewMRRDel;
                }else{
                    opp.Amount = (oppNewMRRDel - oppCurrentMRRDel ) > 0 ?(oppNewMRRDel - oppCurrentMRRDel ) : 0.00 ;
                }
            }           
         }
      }    
}