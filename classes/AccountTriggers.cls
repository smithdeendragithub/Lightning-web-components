/**************************************************************************************************

AccountTriggers.cls
*
Modifications: In 'synchLeadFields' method, deleted a for loop used for updating ownership of associated Leads
Developer Name Date Brief description
------------------- ---------- ------------------------------------------------------------
Elaine Gong 12/19/2017   SEAL-605  - Changes to Target Leads
**************************************************************************************************/

public without sharing class AccountTriggers {

    public static Boolean DisableIntegration = false;
    public static Boolean DisableTrigger = false;
    public static Boolean ForceCAMRestore = false;
    public static Boolean SynchronizingFields = false;
    public static Boolean SynchronizingLeadFields = false;
    
    public static void AccountModified(List<Account> tNew, List<Account> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
        
        if(DisableTrigger || !ApexUtils.executeTriggerMethods('Account', isBefore, isDelete)) return;
        
        if(isBefore){
            if(isDelete){
                if(!preventAccountDelete(tOld))
                    deleteRelatedObjects(tOld);
            }else{
                defaultNullValues(tNew);
                sanitizeAddressField(tNew);
                
                Map<Id, Account> tOldMap = tOld != null ? new Map<Id, Account>(tOld) : new Map<Id, Account>();
                if(isUpdate){
                    if(SecurityUtils.stopOwnershipUpdates(tNew, tOldMap)) return;
                    handleOwnershipUpdates(tNew, tOldMap);
                    synchLeadFields(tNew, tOldMap);
                }
                
                if(CustomerDetailUtils.checkRelatedObjectUpdated(tNew, tOldMap, true)){
                    synchCustomerDetailFields(tNew, tOldMap);
                }
                
                if(isUpdate) Batch_CalculateAccountOwnership.HandleOwnershipRecalculation(tNew, tOldMap, true);
            }
        }
        else{
            Map<Id, Account> tOldMap = tOld != null ? new Map<Id, Account>(tOld) : new Map<Id, Account>();
            if(!isDelete){
                createAccountReferenceObject(tNew);
                
                if(isUpdate){
                    restoreCAMsIfNeeded();
                    updateContracts(tNew, tOldMap);
                    updateSubscribers(tNew, tOldMap);
                }
                
                CustomerDetailUtils.handleNewCustomerDetailSet(tNew, tOldMap, true);
                handleShippingAddressUpdates(tNew, tOldMap);
            }
            CustomerDetailUtils.setCustomerDetailParents((List<sObject>)tNew, (List<sObject>)tOld, isDelete);
            
            if(isUpdate){
                Batch_CalculateAccountOwnership.HandleOwnershipRecalculation(tNew, tOldMap, false);
                updateAccountScheduledTask(tNew, tOldMap);
            }
            ApexUtils.afterTriggerComplete('Account', isDelete);
            ForceCAMRestore = false;    //Only force restore once per save
        }
    }
    
    public static Boolean PerformingControlledSubscriberMerge = false;
    
    private static Boolean preventAccountDelete(List<Account> tOld){
        
        Id systemRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('System').getRecordTypeId();
        
        Boolean allowSubscriberDeletion = null;
        Boolean errored = false;
        for(Account acc : tOld){
            if(!string.IsEmpty(acc.ICC_Account_Number__c)){
                if(allowSubscriberDeletion == null)
                    allowSubscriberDeletion = PerformingControlledSubscriberMerge || [select Name from Profile where Id =: UserInfo.getProfileId()].Name == 'System Administrator';
                
                if(!allowSubscriberDeletion){
                    acc.addError('Accounts with subscriber IDs cannot be deleted or merged.');
                    errored = true;
                }
            }
            if(acc.RecordTypeId == systemRT){
                acc.addError('The system account cannot be deleted.');
                errored = true;
            }
        }
        return errored;
    }
    
    private static Map<Id, AccountTeamMember> camsToKeep = null;
    public static void handleOwnershipUpdates(List<Account> tNew, Map<Id, Account> tOldMap){
        
        /*Map<Id, User> uMap = new Map<Id, User>();
        for(List<Account> aList : new List<List<Account>>{tNew, tOldMap.values()}){
            for(Account a : aList){
                if(a.OwnerId != null)
                    uMap.put(a.OwnerId, null);
            }
        }
        uMap = new Map<Id, User>([SELECT AccountOwnershipNotification__c, IsActive, Name, Email FROM User WHERE Id IN: uMap.keyset()]);*/
        
        Boolean keepCAMs = camsToKeep == null || ForceCAMRestore;
        if(keepCAMs) camsToKeep = new Map<Id, AccountTeamMember>();
        
        for(Account aNew : tNew){
            Account aOld = tOldMap.get(aNew.Id);
            if(aNew.OwnerId != aOld.OwnerId){
                aNew.PreviousOwner__c = aOld.OwnerId;
                if(keepCAMs) camsToKeep.put(aNew.Id, null);
            }
        }
        
        if(camsToKeep.size() > 0){
            for(AccountTeamMember atm : [select Id, AccountId, TeamMemberRole, UserId from AccountTeamMember where AccountId in: camsToKeep.keyset() and TeamMemberRole in: ICCWrapper.CamTeamMemberRoles]){
                camsToKeep.put(atm.AccountId, atm);
            }
        }
    }
    
    private static void restoreCAMsIfNeeded(){
        if(camsToKeep != null && camsToKeep.size() > 0){
            List<AccountTeamMember> restored = new List<AccountTeamMember>();
            List<AccountTeamMember> toDelete = [select Id from AccountTeamMember where AccountId in: camsToKeep.keyset() and TeamMemberRole in: ICCWrapper.CamTeamMemberRoles and Id not in: camsToKeep.values()];
            
            //If they weren't deleted, theres nothing to do
            for(AccountTeamMember atm : [select AccountId from AccountTeamMember where Id in: camsToKeep.values()])
                camsToKeep.remove(atm.AccountId);
            
            for(Id accountID : camsToKeep.keySet()){
                AccountTeamMember atm = camsToKeep.get(accountID);
                if(atm != null){
                    restored.add(new AccountTeamMember(AccountId = accountID
                                                    ,TeamMemberRole = atm.TeamMemberRole
                                                    ,UserId = atm.UserId));
                }
            }
            
            if(toDelete.size() > 0) delete toDelete;
            if(restored.size() > 0) insert restored;
        }
    }
    
    public static void handleShippingAddressUpdates(List<Account> tNew, Map<Id, Account> tOldMap){
        
        Set<Id> updated = new Set<Id>();
        for(Account aNew : tNew){
            Account aOld = tOldMap.get(aNew.Id);
            if(aOld == null
                || aNew.ShippingCity != aOld.ShippingCity
                || aNew.ShippingPostalCode != aOld.ShippingPostalCode
                || aNew.ShippingState != aOld.ShippingState
                || aNew.ShippingStreet != aOld.ShippingStreet){
                updated.add(aNew.Id);
            }
        }
        
        if(updated.size() == 1) //Callout doesn't handle bulk
            updateShippingLocation(updated, UserInfo.getSessionID());
    }
    
    public static void sanitizeAddressField(List<Account> newAcct){
        
        for(Account a : newAcct){
            a.BillingStreet = ApexUtils.removeAllByCustomPattern(a.BillingStreet, '\r\n');
            a.ShippingStreet = ApexUtils.removeAllByCustomPattern(a.ShippingStreet, '\r\n');
        }       
    }
    
    public static void synchCustomerDetailFields(List<Account> tNew, Map<Id, Account> tOldMap){
        
        if(CustomerDetailTriggers.SynchronizingFields) return;
        
        Id systemRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('System').getRecordTypeId();
        Set<Id> hierarchyFieldUpdated = new Set<Id>();
        Map<Id, Customer_Detail__c> cdUpdates = new Map<Id, Customer_Detail__c>();
        for(Account aNew : tNew){
            Account aOld = tOldMap != null && aNew.Id != null ? tOldMap.get(aNew.Id) : null;
            if(aNew.Customer_Detail__c != null
                    && (aOld == null
                    || aOld.Customer_Detail__c != aNew.Customer_Detail__c
                    || aOld.Name != aNew.Name
                    || aOld.Billable__c != aNew.Billable__c
                    || aOld.Phone != aNew.Phone
                    //|| aOld.Agency__c != aNew.Agency__c
                    || aOld.OwnerId != aNew.OwnerId))
                cdUpdates.put(aNew.Customer_Detail__c, null);
       /*     if(aNew.RecordTypeId != systemRTID && aOld != null
                && aOld.Account_Sales_Channel__c != aNew.Account_Sales_Channel__c && aNew.Account_Sales_Channel__c != null)
                hierarchyFieldUpdated.add(aNew.Id);*/
        }
        
        if(cdUpdates.size() > 0 || hierarchyFieldUpdated.size() > 0){
            cdUpdates = new Map<Id, Customer_Detail__c>([select Id, Care_Organization__c, Parent_Account__c from Customer_Detail__c where Id in: cdUpdates.keyset() or Parent_Account__c in: hierarchyFieldUpdated]);
            
            for(Account a : tNew){
                Customer_Detail__c cd = a.Customer_Detail__c != null ? cdUpdates.get(a.Customer_Detail__c) : null;
                if(cd != null){
                    cd.Name = a.Name;
                    cd.Billable__c = a.Billable__c;
                    cd.Phone__c = a.Phone;
                    cd.Owner__c = a.OwnerId;
                    //cd.Owner_Agency__c = a.Agency__c;
                }
                
            /*    if(hierarchyFieldUpdated.contains(a.Id)){
                    String scm = !string.isEmpty(a.Account_Sales_Channel__c) ? CustomSettingUtils.getSingleProcessConfigurationValue('SalesChannelDefaultCareOrg', a.Account_Sales_Channel__c, false) : null;
                    Customer_Setting__c careOrg = !String.IsEmpty(scm) ? CustomerDetailUtils.getCareOrgByName(scm) : null;
                    careOrg = careOrg != null ? careOrg : CustomerDetailUtils.getCareOrgByName(a.Account_Sales_Channel__c);
                    
                    for(Customer_Detail__c ccd : cdUpdates.values()){
                        if(ccd.Parent_Account__c == a.Id){
                            ccd.Care_Organization__c = careOrg != null ? careOrg.Id : ccd.Care_Organization__c;
                        }
                    }
                }*/
            }
            
            Boolean oSynch = SynchronizingFields;
            SynchronizingFields = true;
            if(cdUpdates.size() > 0) update cdUpdates.values();
            SynchronizingFields = oSynch;
        }
    }
    
    public static void synchLeadFields(List<Account> tNew, Map<Id, Account> tOldMap){
        
        if(LeadTriggers.SynchronizingAccountFields) return;
        
        Id systemRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('System').getRecordTypeId();
        Map<Id, Account> updated = new Map<Id, Account>();
        for(Account aNew : tNew){
            Account aOld = tOldMap != null && aNew.Id != null ? tOldMap.get(aNew.Id) : null;
            if(aNew.RecordTypeId != systemRTID && (aOld == null || aOld.OwnerId != aNew.OwnerId)) updated.put(aNew.Id, aNew);
        }
        
        if(updated.size() > 0){
            List<Lead> leads = [select Id, Related_Account__c from Lead where Related_Account__c in: updated.keyset() and IsConverted = false];
            // SEAL – 605: Deleting a for loop that syncs the OwnerId field of Account to Lead

            Boolean oSynch = SynchronizingLeadFields;
            SynchronizingLeadFields = true;
            if(leads.size() > 0) SecurityUtils.BypassProcesser.saveObjects(leads, true);
            SynchronizingLeadFields = oSynch;
        }
    }
     
    public static void createAccountReferenceObject(List<Account> newAcct){
        
        Map<Id, AccountReference__c > acctRefMap =  new Map<Id, AccountReference__c>();
        for(AccountReference__c ar : [SELECT Id, Name, Account__c  FROM AccountReference__c WHERE Account__c IN: newAcct])
            acctRefMap.put(ar.Account__c, ar);
              
        List<AccountReference__c> upsertList = new List<AccountReference__c>();
        for(Account a : newAcct){
            
            AccountReference__c ar = acctRefMap.get(a.Id);
            if(ar == null){
                ar = new AccountReference__c(Account__c = a.Id);
                acctRefMap.put(a.Id, ar);
            }
            
            ar.Phone__c = a.Phone;
            ar.ICC_Account_Number__c = a.ICC_Account_Number__c;
            ar.OwnerId = a.OwnerId;
            //80 character limit on name field
            ar.Name = a.Name.length() > 80 ? a.Name.substring(0, 80) : a.Name;
            
            upsertList.add(ar);
        }

        Database.UpsertResult[] results = Database.upsert(upsertList, false);
        for(Database.UpsertResult result : results){
            if(!result.isSuccess()){
                newAcct.get(0).addError('Exception Details: ' + result.getErrors());
            }
        }
    }
      
    private static void deleteRelatedObjects(List<Account> accounts) {
        List<AccountReference__c> refs = ([SELECT Id, Name, Account__c  FROM AccountReference__c WHERE Account__c IN: accounts]);
        if(refs.size() > 0) Database.delete(refs, false);
        
        List<Account_Partner__c> partners = [select Id from Account_Partner__c where Account__c in: accounts];
        if(partners.size() > 0) Database.delete(partners, false);
        
        //Merges should not transfer CAM
        List<AccountTeamMember> cams = [select Id from AccountTeamMember where AccountId in: accounts and TeamMemberRole in: ICCWrapper.CamTeamMemberRoles];
        if(cams.size() > 0) Database.delete(cams, false);
    }
    
    private static void updateContracts(List<Account> tNew, Map<Id, Account> tOldMap){
        Set<Id> activeIDs = new Set<Id>();
        Set<Id> inactiveIDs = new Set<Id>();
        
        for(Account aNew : tNew){
            Account aOld = tOldMap.get(aNew.Id);
            if(aOld == null || aOld.Type != aNew.Type){
                if(aNew.Type == 'Customer')
                    activeIDs.add(aNew.Id);
                else if(aNew.Type == 'Former Customer')
                    inactiveIDs.add(aNew.Id);
            }
        }
        
        if(activeIDs.size() > 0)
            SecurityUtils.updateAccountContractStatuses(activeIDs, 'Active', null);
        
        if(inactiveIDs.size() > 0)
            SecurityUtils.updateAccountContractStatuses(inactiveIDs, 'Inactive', null);
    }
      
    public static void updateSubscribers(List<Account> tNew, Map<Id, Account> tOldMap){
        
        Map<Id, String> updatedAccounts = new Map<Id, String>();
        for(Account aNew : tNew){
            Account aOld = tOldMap.get(aNew.Id);
            
            if(aNew.Type != 'Former Customer' && aNew.ICC_Account_Number__c != null){
                
                List<String> updates = new List<String>();
                if(aOld.Industry != aNew.Industry) updates.add('Industry');
                
                if(updates.size() > 0)
                    updatedAccounts.put(aNew.Id, string.join(updates, ','));
            }
        }
        
        if(!DisableIntegration && updatedAccounts.size() > 0 && integraWSEndpointMediator.canRunIntegrationUpdate('Account'))
            updateSubscribers(updatedAccounts, UserInfo.getSessionId(), UserInfo.getUserEmail());
    }
      
    @future(callout=true)
    public static void updateSubscribers(Map<Id, String> updatedAccounts, string sessionID, string errorEmail){
        try{
            Map<Id, Account> accounts = new Map<Id, Account>([select Id
                                                                    ,ICC_Account_Number__c
                                                                    ,Industry
                                                                    ,(select Id
                                                                        ,ICC_Subscriber_ID__c
                                                                        ,Owner__c
                                                                        from Account_Locations__r
                                                                        where ICC_Subscriber_ID__c != null)
                                                                    from Account where Id in :updatedAccounts.keyset()]);
            
            List<integraWS.SFSubscriberView> subscribers = new List<integraWS.SFSubscriberView>();
            for(Account a : accounts.values()){
                String updateVals = updatedAccounts.get(a.Id);
                if(a.ICC_Account_Number__c != null && updateVals != null){
                    Set<String> updates = new Set<String>(updateVals.split(','));
                    
                    if(updates == null || updates.size() == 0) continue;
                    system.debug(a.Id + ' had the following updates: ' + updates);
                    
                    integraWS.SFSubscriberView sub = new integraWS.SFSubscriberView();
                    sub.SubscriberId = integer.valueOf(a.ICC_Account_Number__c);
                    sub.SalesforceId = a.Id;
                    
                    sub.FieldsToNull = new schemasMicrosoftCom200310Serializat.ArrayOfstring();
                    sub.FieldsToNull.string_x = new List<String>();
                    
                    if(updates.contains('Industry')) sub.SICCode = a.Industry;
                    
                    subscribers.add(sub);
                    
                    for(Service_Location__c sLoc : a.Account_Locations__r != null ? a.Account_Locations__r : new List<Service_Location__c>()){
                        if(a.ICC_Account_Number__c != sLoc.ICC_Subscriber_ID__c){
                            integraWS.SFSubscriberView locSub = new integraWS.SFSubscriberView();
                            locSub.SubscriberId = integer.valueOf(sLoc.ICC_Subscriber_ID__c);
                            locSub.SalesforceId = a.Id;
                            locSub.FieldsToNull = sub.FieldsToNull;
                            locSub.ContractType = sub.ContractType;
                            locSub.GovernmentType = sub.GovernmentType;
                            locSub.SICCode = sub.SICCode;
                            subscribers.add(locSub);
                        }
                    }
                }
            }
            
            if(subscribers.size() > 0){
                List<integraWS.SFSubscriberView> flattenedResults = ICCWrapper.getFlattenedSFSubscriberViewList(ICCWrapper.updateSubscribers(subscribers, sessionID));
                
                Map<Id, String> errorMap = new Map<Id, String>();
                for(integraWS.SFSubscriberView v : flattenedResults){
                    if(!string.IsEmpty(v.ResultMessage)) errorMap.put(v.SalesforceId, v.ResultMessage);
                }
                
                if(errorMap.size() > 0) IntegrationUtils.createUpdateIntegrationErrors(errorMap, updatedAccounts);
            }
        }
        catch(Exception e){
            String detailString = IntegrationUtils.emailIntegrationException(e, errorEmail, 'Subscriber integration update exception');
            IntegrationUtils.createUpdateIntegrationErrors(updatedAccounts.keyset(), detailString, updatedAccounts);
        }
    }
    
    private static void updateAccountScheduledTask(List<Account> tNew, Map<Id,Account> tOldMap){
        Set<String> astBusinessUnits = new Set<String>( CustomSettingUtils.getProcessConfigurationValues('ASTAutogen','BusinessUnit'));
        List<Account> actsToWork = new List<Account>();
        List<Account_Scheduled_Task__c> updateTasks = new List<Account_Scheduled_Task__c>();

//        Map<Id, Customer_Detail__c>  custDetails = new Map<Id, Customer_Detail__c>();
  //      for(Customer_Detail__c cDetail : [select Id, Parent_Account__c, Care_Organization__c from Customer_Detail__c where Parent_Account__c in :tNew]){
    //        custDetails.put(cDetail.Parent_Account__c, cDetail);
      //  }
        Set<Id> actIds = new Set<Id>();
        for(Account act : tNew){
            Account oldAct = tOldMap.get(act.Id);
            //if(oldAct != null && (act.Account_Sales_Channel__c != oldAct.Account_Sales_Channel__c || act.MRR__c != oldAct.MRR__c)){
            if(oldAct != null &&  (act.Care_Organization_Name__c != oldAct.Care_Organization_Name__c || act.MRR__c != oldAct.MRR__c)){ //if care org has changed, CustomerDetailTrigger.createAccountScheduledTasks will deal with it. 
                actsToWork.add(act);
                actIds.add(act.Id);
            }
        }
        Map<Id,Account_Scheduled_Task__c> actToAst = new Map<Id,Account_Scheduled_Task__c>();
        for(Account_Scheduled_Task__c ast : [select Id, Account__c, Automation_Enabled__c, Previous_Proactive_Activity__c from Account_Scheduled_Task__c where Account__c in :actIds and Disabled__c = false]){
            actToAst.put(ast.Account__c, ast);
        }

        for(Account act : actsToWork){
            //use Care Organizaion to set AST
            //String careOrgName = null;
            //if(custDetails.size()>0){
              //  Customer_Detail__c cd = custDetails.get(act.id);
                //careOrgName = cd.Care_Organization__c!=null?CustomerDetailUtils.getCareOrgById(cd.Care_Organization__c).Name:null;                  
            //}           
            if(actToAst.containsKey(act.Id)){
                Account_Scheduled_Task__c ast = actToAst.get(act.Id);    
                //ast.Automation_Enabled__c = astBusinessUnits.Contains(act.Account_Sales_Channel__c);                
                //AccountScheduledTaskUtils.updateASTFromABSandMRR(ast, act.Account_Sales_Channel__c, act.MRR__c);
                ast.Automation_Enabled__c = astBusinessUnits.Contains(act.Care_Organization_Name__c);
                AccountScheduledTaskUtils.updateASTFromABSandMRR(ast, act.Care_Organization_Name__c, act.MRR__c);
                updateTasks.add(ast);
            }
            else if(astBusinessUnits.contains(act.Care_Organization_Name__c)){
                Account_Scheduled_Task__c ast = AccountScheduledTaskUtils.createASTForAccount(act.id, act.Care_Organization_Name__c, act.MRR__c);
                updateTasks.add(ast);
            }
        }

        if(updateTasks.size()>0) upsert updateTasks;
    }
    
    @future(callout=true)
    public static void updateShippingLocation(Set<Id> accountIDs, string sessionID){
        List<Account> accounts = [select Id, ShippingCity, ShippingState, ShippingStreet, ShippingPostalCode, Shipping_Location__c from Account where Id in: accountIDs];
        
        if(accounts.size() > 0){
            integraWS.SFLocationView locView = AddressParser.getSFLocationView(null, accounts[0].ShippingStreet, null, accounts[0].ShippingCity, accounts[0].ShippingState, accounts[0].ShippingPostalCode, null, null);
            locView = !Test.isRunningTest() ? integraWSEndpointMediator.Endpoint.ValidateBuildingAddress(locView, sessionID, CustomSettingUtils.SFDCCallbackEndpoint, false) : locView;
            
            if(locView != null){
                Building__c b = AddressUtils.CreateBuilding(locView, false);
                Location__c l = AddressUtils.CreateLocation(b, locView, false);
                
                //Only create locations, not buildings
                if(b != null && b.Id != null && l != null && (l.Id == null || accounts[0].Shipping_Location__c != l.Id)){
                    if(l.Id == null)
                        insert l;
                    
                    accounts[0].Shipping_Location__c = l.Id;
                    update accounts[0];
                }
            }
        }
    }
    
    private static void defaultNullValues(List<Account> tNew){
        for(Account act : tNew){
            if(act.Language_Preference__c == null) 
            	act.Language_Preference__c = 'English';
        }
    }
}