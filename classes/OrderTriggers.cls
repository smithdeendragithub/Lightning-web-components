public with sharing class OrderTriggers {
    
    public static Boolean DisableTrigger = false;
    
    public static void OrderModified(List<Order__c> tNew, List<Order__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
        
        if(DisableTrigger || !ApexUtils.executeTriggerMethods('Order__c', isBefore, isDelete)) return;
        
        Boolean inOppTrigger = ApexUtils.inTrigger('Opportunity') || ApexUtils.inTrigger('Opportunity_Split');  //Will only be set when the opp trigger has fired in the same static context
        if(isBefore){
            if(!isDelete){
                Map<Id, Order__c> tOldMap = isUpdate ? new Map<Id, Order__c>(tOld) : new Map<Id, Order__c>();
                if(isUpdate){
                    checkOpportunityMove(tNew, tOldMap);                    
                }
                checkForCLLI(tNew, tOldMap);
                setProjectDate(tNew, tOldMap);
                setOrderCompletionStatusForContractRenewalOrder(tNew, tOldMap);
            }
        }
        else{
            Map<Id, Order__c> tOldMap = isUpdate ? new Map<Id, Order__c>(tOld) : new Map<Id, Order__c>();
            if(!isDelete){
                if(!inOppTrigger) OrderUtils.synchOpportunityFields(tNew, tOldMap, true, false);
                BypassProcesser.sendWorkflowAndApprovalEmails(tNew, tOldMap);
            }
            updateBuildOrderBuildings(isDelete ? tOld : tNew, tOldMap);
            
            if(!isDelete){
                if(isUpdate){
                    handleOwnershipChanges(tNew, tOldMap);
                    updateExpeditedAndCancelledSubOrder(tNew, tOldMap);
                    handleFeatureChanges(tNew, tOldMap);
                 }else{
                //after insert, check the order is created from Case and if yes, copy the attachments from Case
                    //handleOrdersFromCase(tNew, tOldMap);
                }                                           
                createWorkstepsIfNeeded(tNew, tOldMap);
                evaluateOrder(tNew, tOldMap);
                handleContractRenewalOrderType(tNew, tOldMap);                
            }
            else{
                if(!isUpdate && tNew != null){
                    WorkstepUtils.recalculatePNR(new Map<Id, Order__c>(tNew).keyset());
                }
            }
            
            ApexUtils.afterTriggerComplete('Order__c', isDelete);
        }
    }
    
   private static void checkForCLLI(List<Order__c> tNew, Map<Id, Order__c> tOldMap){
        Map<Id, Order__c> updated = new Map<Id, Order__c>();
        Map<Id, String> feat = new Map<Id, String>();
        String features = null;
        //Feature__c feature = [Select Id, Name, External_ID__c From Feature__c Where Name =: 'Obtain CLLI Code'];      
        for(Order__c oNew : tNew){
            if(oNew.recordTypeId == OrderUtils.BuildOrderRecordTypeID && oNew.Building_CLLI__c == null){ 
                if(oNew.Features__c == null)
                    features = 'Obtain CLLI Code';
                else if(oNew.Features__c.contains('Obtain CLLI Code')){ 
                    features = oNew.Features__c;
                }  
                else{
                    features = oNew.Features__c + '; Obtain CLLI Code';
                }
                oNew.Features__c = features;
                updated.put(oNew.Id, oNew);
            }
        }
    }
    
    private static void handleFeatureChanges(List<Order__c> tNew, Map<Id, Order__c> tOldMap){
        Map<Id, Order__c> updated = new Map<Id, Order__c>();        
        for(Order__c oNew : tNew){
            if(oNew.Features__c != tOldMap.get(oNew.Id).Features__c) updated.put(oNew.Id, oNew);
        }
        if(updated.size() > 0){
            WorkstepUtils.updateOrderWorksteps(updated);
        }
    }
    
    private static void handleOwnershipChanges(List<Order__c> tNew, Map<Id, Order__c> tOldMap){
        Map<Id, Order__c> updated = new Map<Id, Order__c>();
        for(Order__c oNew : tNew){
            if(oNew.OwnerId != tOldMap.get(oNew.Id).OwnerId)
                updated.put(oNew.Id, oNew);
        }
        
        if(updated.size() > 0){
            Map<Id, Set<Id>> oldOwners = new Map<Id, Set<Id>>();
            for(Id id : updated.keySet())
                oldOwners.put(id, new Set<Id>{tOldMap.get(id).OwnerId});
            
            for(Order__History oHist : [select ParentId, OldValue from Order__History where ParentId in: updated.keyset() and Field = 'Owner']){
                String oVal = string.valueOf(oHist.OldValue);
                if(ApexUtils.isValidId(oVal) && oVal.startsWith('005'))
                    oldOwners.get(oHist.ParentId).add(oVal);
            }
            
            List<Order__Share> shares = new List<Order__Share>();
            if(oldOwners.size() > 0){
                Set<Id> activeOldOwners = new Set<Id>();
                for(Set<Id> oo : oldOwners.values()){
                    for(Id o : oo)
                        activeOldOwners.add(o);
                }
                activeOldOwners = (new Map<Id, User>([select Id from User where Id in: activeOldOwners and IsActive = true])).keyset();
                
                for(Id oID : oldOwners.keyset()){
                    for(Id ownerID : oldOwners.get(oID)){
                        if(activeOldOwners.contains(ownerID))
                            shares.add(new Order__Share(ParentId=oID, UserOrGroupId=ownerID, AccessLevel='Read'));
                    }
                }
            }
            
            Map<Id, Workstep__c> unassignedWorksteps = new Map<Id, Workstep__c>();
            for(Workstep__c ws : [Select Id, Name, OwnerId, Owner.Name, Order__r.Name from Workstep__c WHERE Order__r.Id IN :updated.keyset() AND Owner.Name = 'Unassigned']) {
                ws.OwnerId = updated.get(ws.Order__c).OwnerId;
                unassignedWorksteps.put(ws.Id, ws);
            }
            
            if(shares.size() > 0)
                SecurityUtils.BypassProcesser.saveObjects(shares, false);
            
            if(unassignedWorksteps.size() > 0)
                update unassignedWorksteps.values();
        }
    }
    
    private static void checkOpportunityMove(List<Order__c> tNew, Map<Id, Order__c> tOldMap){
        for(Order__c oNew : tNew){
            Order__c oOld = tOldMap.get(oNew.Id);
            if(oNew.Opportunity__c != oOld.Opportunity__c && oOld.Opportunity__c != null)
                oNew.addError('You cannot reassign an opportunity based order once it has been assigned to one.');
        }
    }
    
    private static void updateBuildOrderBuildings(List<Order__c> tNew, Map<Id, Order__c> tOldMap){
        Set<Id> buildingIDs = new Set<Id>();
        for(Order__c oNew : tNew){
            Order__c oOld = tOldMap.get(oNew.Id);
            if((oOld != null && (oOld.Building__c != oNew.Building__c || oOld.Order_Completion_Status__c != oNew.Order_Completion_Status__c))
                || (oOld == null && oNew.Building__c != null)){
                for(String bID : new List<String>{oOld != null ? oOld.Building__c : null, oNew.Building__c}){
                    if(bID != null)
                        buildingIDs.add(bID);
                }
            }
        }
        
        OrderUtils.refreshBuildingOrderStatuses(buildingIDs);
    }
    
    private static void createWorkstepsIfNeeded(List<Order__c> tNew, Map<Id, Order__c> tOldMap) {
        List<Order__c> provPlanEnabled = new List<Order__c>();
        for(Order__c oNew : tNew){          
            Order__c oOld = tOldMap.get(oNew.Id);
            if((oOld == null || !oOld.Provisioning_Plan_Enabled__c) && oNew.Provisioning_Plan_Enabled__c)
                provPlanEnabled.add(oNew);
        }
        
        if(provPlanEnabled.size() > 0)
            WorkstepUtils.createWorksteps(provPlanEnabled);
    }
    
    private static void evaluateOrder(List<Order__c> tNew, Map<Id, Order__c> tOldMap) { 
        Map<Id, Order__c> oMap = new Map<Id, Order__c>();
        Map<String, Map<Id, Order__c>> updateMaps = new Map<String, Map<Id, Order__c>>{'CreateWS'=>new Map<Id, Order__c>()
                                                                                        ,'Cancelled'=>new Map<Id, Order__c>()
                                                                                        ,'Expedited'=>new Map<Id, Order__c>()
                                                                                        ,'StartDate'=>new Map<Id, Order__c>()};
        
        Set<String> dateDrivingFields = WorkstepUtils.OrderDateDrivingFields;
        Set<String> checkFieldUpdates = new Set<String>{'Expedited__c'
                                                        ,'Order_Completion_Status__c'
                                                        ,'Record_Status__c'
                                                        ,'Workplan_Start_Date__c'};
        checkFieldUpdates.addAll(dateDrivingFields);
        for (Order__c ord :tNew) {
            Order__c oOld = tOldMap.get(ord.Id);
            Set<String> s = new Set<String>();
            if(oOld == null)
                s = checkFieldUpdates;
            else{
                for(String field : checkFieldUpdates){
                    if(oOld == null || oOld.get(field) != ord.get(field))
                        s.add(field);
                }
            }
            
            if(s.size() > 0){
                oMap.put(ord.Id, ord);
                
                for(String f : dateDrivingFields){
                    if (s.contains(f)){
                        updateMaps.get('StartDate').put(ord.Id, ord);
                        break;
                    }
                }
                    
                if(s.contains('Order_Completion_Status__c') && ord.Order_Completion_Status__c == 'Cancelled' && (ord.recordTypeId == OrderUtils.BuildOrderRecordTypeID || ord.recordTypeId == OrderUtils.DecommOrderRecordTypeID) && oOld != null)
                    updateMaps.get('Cancelled').put(ord.Id, ord);
                
                if(s.contains('Expedited__c'))
                    updateMaps.get('Expedited').put(ord.Id, ord);
            }
        }
        
        if(oMap.size() > 0){
            Map<Id, Workstep__c> wsForUpdate = new Map<Id, Workstep__c>();
            
            List<Workstep__c> wsList = [SELECT Id, Name, Attribute__c, Order__c, Status__c, Start_Date__c, End_Date__c, Lag__c, Duration__c, SLA__c, Template__c, Workstep_Library__c FROM Workstep__c WHERE Order__c IN :oMap.keySet()];
            if(updateMaps.get('StartDate').size() > 0){         
                for(Workstep__c ws : wsList){               
                    if(updateMaps.get('StartDate').containsKey(ws.Order__c)){
                        WorkstepUtils.WorkstepDates d = new WorkstepUtils.WorkstepDates();
                        
                        if(WorkstepUtils.tryGetAttributeDates(ws, oMap.get(ws.Order__c), d)){
                            if(d.StartDate != null) ws.Start_Date__c = d.StartDate;
                            
                            ws.End_Date__c = d.EndDate;     //Always set end date to force a recalc if anything changes
                            wsForUpdate.put(ws.Id, ws);
                        }
                    }
                }
            }
            //wsForUpdate.putAll(updateExpedited(wsList, soMap, updateMaps.get('Expedited').keyset()));
            wsForUpdate.putAll(setStatusForCancelOrd(wsList, updateMaps.get('Cancelled').keyset()));
            
            List<Workstep__c> newAntiWsList = createAntiWS(updateMaps.get('Cancelled').keyset());
            
            if (!wsForUpdate.isEmpty()) update wsForUpdate.values();
            if (newAntiWsList.size() > 0) insert newAntiWsList;
        }
    }
    
    private static Map<Id, Workstep__c> setStatusForCancelOrd(List<Workstep__c> wsList, Set<Id> canceledO) {
        Map<Id, Workstep__c> modifiedWs = new Map<Id, Workstep__c>();
        Map<Id, Workstep__c> cancelBlocked = new Map<Id, Workstep__c>();
        List<Workstep_Issue__c> updateWSI = new List<Workstep_Issue__c>();
        
        for (Workstep__c ws : wsList) {
            if(canceledO.contains(ws.Order__c) && ws.Status__c == WorkstepUtils.STATUS_BLOCKED){
                cancelBlocked.put(ws.Id, ws);
            }
            if (canceledO.contains(ws.Order__c) && ws.Status__c != WorkstepUtils.STATUS_COMPLETE) {
                ws.Status__c = WorkstepUtils.STATUS_CANCELLED;
                modifiedWs.put(ws.Id,ws);
            }
        }
        if(cancelBlocked.size() > 0){
            for(Workstep_Issue__c wsi: [select Id, Workstep__c, Reason__c, Resolution_Comments__c from Workstep_Issue__c WHERE   Workstep__c in: cancelBlocked.keyset()]){
                wsi.Reason__c = 'Order Canceled';
                wsi.Status__c = 'Resolved';
                wsi.Resolution_Comments__c = 'Cancelling Order';
                wsi.Resolution_Code__c = 'Order Canceled';
                wsi.Date_Resolved__c = date.today();            
                updateWSI.add(wsi);
            }
        }
        update updateWSI;
        return modifiedWs;
    }
    
    private static List<Workstep__c> createAntiWS(Set<Id> canceledOrder) { 
        List<Workstep__c> antiWSList = new List<Workstep__c>();
        if(canceledOrder.size() > 0){
            for (Workstep__c ws : [SELECT Id
                                    ,Duration__c
                                    ,Name
                                    ,Order__c
                                    ,OwnerId
                                    ,Workstep_Library__c
                                    ,Workstep_Library__r.Attribute__c
                                    ,Workstep_Library__r.Non_Access_Duration__c
                                    ,Workstep_Library__r.Non_Access_SLA__c
                                    ,Workstep_Library__r.OwnerId
                                    FROM Workstep__c WHERE Order__c IN :canceledOrder AND Workstep_Library__r.Anti_Workstep__c = true AND Duration__c != 0 AND (Status__c =: WorkstepUtils.STATUS_COMPLETE OR Status__c =: WorkstepUtils.STATUS_OPEN OR Status__c =: WorkstepUtils.STATUS_BLOCKED)]){
                                        antiWSList.add(new Workstep__c(Name = 'Cancelled ' + ws.Name
                                                                        ,Workstep_Library__c = ws.Workstep_Library__c
                                                                        ,Attribute__c = ws.Workstep_Library__r.Attribute__c
                                                                        ,Duration__c = ws.Duration__c
                                                                        ,SLA__c = ws.Workstep_Library__r.Non_Access_SLA__c
                                                                        ,Status__c = 'Open'
                                                                        ,Order__c = ws.Order__c
                                                                        ,Original_Workstep__c = ws.Id
                                                                        ,Start_Date__c = WorkstepUtils.calculateAfterDate(date.today(), 0, true)
                                                                        ,OwnerId = ws.OwnerId
                                                                    ));
                                   }
        }
        return antiWSList;
    }
    
    private static void updateExpeditedAndCancelledSubOrder(List<Order__c> tNew, Map<Id, Order__c> tOldMap) {
        Map<Id, boolean> updatedExpeditedOrders = new Map<Id, boolean>();
        Map<Id, Order__c> updatedExpeditedAndCancelledOrders = new Map<Id, Order__c>();
        for (Order__c o : tNew) {
            if (tOldMap.get(o.Id).Expedited__c != o.Expedited__c)
                updatedExpeditedOrders.put(o.Id, o.Expedited__c);
            if (tOldMap.get(o.Id).Expedited__c != o.Expedited__c || (tOldMap.get(o.Id).Record_Status__c != o.Record_Status__c && o.Record_Status__c == 'Cancelled'))
                updatedExpeditedAndCancelledOrders.put(o.Id, o);
        }
        
        if(updatedExpeditedOrders.size() > 0 || updatedExpeditedAndCancelledOrders.size() > 0){
            List<Workstep__c> wsList = updateExpeditedWS(updatedExpeditedOrders);
            List<Sub_Order__c> soList = [SELECT Id, Expedited__c, Order__c, Status__c FROM Sub_Order__c WHERE Order__c IN :updatedExpeditedAndCancelledOrders.keySet()];
            for (Sub_Order__c so : soList) {
                if (updatedExpeditedOrders.ContainsKey(so.Order__c))
                    so.Expedited__c = updatedExpeditedOrders.get(so.Order__c);
                if (updatedExpeditedAndCancelledOrders.get(so.Order__c).Record_Status__c == 'Cancelled' && so.Status__c != 'Closed')
                    so.Status__c = updatedExpeditedAndCancelledOrders.get(so.Order__c).Record_Status__c;
            }
            
            if (soList.size() > 0) update soList;
            if (wsList.size() > 0) update wsList;
        }
    }
    
    private static List<Workstep__c> updateExpeditedWS(Map<Id, boolean> updatedExpeditedOrders) {
        List<Workstep__c> wsList = [SELECT Id, Order__c, Duration__c, SLA__c, Workstep_Library__r.Non_Access_Duration__c, Attribute__c FROM Workstep__c WHERE Order__c IN :updatedExpeditedOrders.keySet()];
        for (Workstep__c ws : wsList) {
            if (updatedExpeditedOrders.containsKey(ws.Order__c) && WorkstepUtils.canExpedite(ws))
                ws.Duration__c = updatedExpeditedOrders.get(ws.Order__c) ? ((Integer)ws.SLA__c + 1) / 2 : ws.SLA__c;
        }
        return wsList;
    }
    
    private static void setProjectDate(List<Order__c> tNew, Map<Id, Order__c> tOldMap) {
        for (Order__c oNew : tNew) {
            if (oNew.Id == null || (tOldMap.get(oNew.Id).Project_Date__c != oNew.Project_Date__c)) {
                if (oNew.Project_Date__c != null)
                    oNew.Project_Date__c = WorkstepUtils.calculateFirstDate(oNew.Project_Date__c, 0, true);
            }
        }
    }
 /*   
    private static void handleOrdersFromCase(List<Order__c> tNew, Map<Id, Order__c> tOldMap){
        Map<Id, Id> caseOrders= new Map<Id, Id>();
        Map<Id, String> feat = new Map<Id, String>();
        List<Case> caseList = new List<Case>();
        
        Id integrationOnlyRecordTypeID = OrderUtils.IntegrationOnlyRecordTypeID;

        for(Order__c oNew : tNew){
            if(oNew.recordTypeId == integrationOnlyRecordTypeID && oNew.Case__c != null){ 
                caseOrders.put(oNew.Case__c, oNew.Id);            
            }
        }
        
        List<Attachment> attList = [select id, name, body,parentid  from Attachment where ParentId in :caseOrders.keyset()];
        List<Attachment> insertAttList = new List<Attachment>(); 

        if(attList != null && attList.size()>0){
            for(Attachment a: attList){    
               Attachment att = new Attachment(name = a.name, body = a.body, parentid = caseOrders.get(a.parentid));
               insertAttList.add(att);    
             }
    
             if(insertAttList.size() > 0){
                insert insertAttList;
             }
        }
        
        List<Case> caList = [select Id, Subject, Description  from Case where Id in :caseOrders.keyset()];
        List<Note> insertNoteList = new List<Note>(); 
        
        if(caList != null && caList.size()>0){
            for(Case a: caList){    
               Note note = new Note(Title = a.Subject, body = a.Description, parentid = caseOrders.get(a.Id));
               insertNoteList.add(note);    
             }
    
             if(insertNoteList.size() > 0){
                insert insertNoteList;
             }
        }
        
        for(Case ca:[Select Id, CaseNumber, Status from Case where Id in :caseOrders.keyset()]){
            if(ca.Status == 'New'){
                ca.Status = 'Working';
                caseList.add(ca);    
            }            
        }
        if(caseList.size() > 0){
            update caseList;
         }

    }
   */     
    private static SecurityBypassProcessor bp = null;
    public static SecurityBypassProcessor BypassProcesser{
        get{
            if(bp == null)
                bp = new SecurityBypassProcessor();
            return bp;
        }
    }
    
    public without sharing class SecurityBypassProcessor extends SecurityUtils.ISecurityBypassProcessor{
        
        /* Workflow and approval emails section */
        public void sendWorkflowAndApprovalEmails(List<Order__c> tNew, Map<Id, Order__c> tOldMap){
            
            List<Order__c> ords = new List<Order__c>();
            
            Map<Id, Opportunity> oppMap = new Map<Id,Opportunity>();
            Map<Id, User> uMap = new Map<Id, User>();
            for(Order__c ord : tNew){
                Order__c oldOrd = tOldMap.get(ord.Id);
                
                if(ord.Opportunity__c != null && (oldOrd == null
                                                || oldOrd.Credit_Check_Approval__c != ord.Credit_Check_Approval__c
                                                || oldOrd.Credit_Commitment_Met__c != ord.Credit_Commitment_Met__c
                                                || oldOrd.Credit_Hold_Reason__c != ord.Credit_Hold_Reason__c)){
                    ords.add(ord);
                    oppMap.put(ord.Opportunity__c, null);
                    
                    if(ord.Credit_Check_Rep__c != null)
                        uMap.put(ord.Credit_Check_Rep__c, null);
                }
            }
            
            if(ords.size() > 0){
                oppMap = new Map<Id, Opportunity>([select Id, Net_Difference__c, RecordType.DeveloperName, Sales_Channel__c, StageName, Type, Account.RecordType.DeveloperName, OwnerId from Opportunity where Id in : oppMap.keyset()]);
                for(Opportunity opp : oppMap.values())
                    uMap.put(opp.OwnerId, null);
                
                uMap = new Map<Id, User>([Select Id, Name, ManagerId from User where Id in : uMap.keyset()]);
                for(User u : uMap.values()){
                    if(u.ManagerId != null)
                        uMap.put(u.ManagerId, u);
                }
                
                uMap = new Map<Id, User>([Select Id, Name, ManagerId from User where Id in : uMap.keyset()]);
                
                for(Order__c ord : ords){
                    Order__c oldOrd = tOldMap.get(ord.Id);
                    Opportunity opp = oppMap.get(ord.Opportunity__c);
                    
                    Boolean sendEmailOppType =  (opp.StageName == OpportunityUtils.STAGE_CONTRACT_SIGNED || opp.StageName == OpportunityUtils.STAGE_4)
                                                && (opp.Type == 'New Logo')
                                                    //|| (opp.RecordType.DeveloperName == 'New' && opp.Type == 'Existing')
                                                    //|| (opp.RecordType.DeveloperName == 'Change' && (opp.Type == 'Conversion' || opp.Type == 'Move' || opp.Type == 'Upgrade')))
                                                && opp.Account.RecordType.DeveloperName != 'ILEC_Prior_Lake' /*&& opp.Sales_Channel__c != 'Wholesale' && opp.Sales_Channel__c != 'Government and Education' */ && opp.Sales_Channel__c != 'Sales Support';
                    
                    if(sendEmailOppType){
                        User AE = uMap.get(opp.OwnerId);
                        User Manager = AE.ManagerId != null ? uMap.get(AE.ManagerId) : null;
                        
                        String cca = ord.Credit_Check_Approval__c;
                        if(ord.Credit_Commitment_Met__c != null){
                            if(cca == 'Credit Denied')
                                OpportunityUtils.sendWorkflowAndApprovalEmail(ord.Id, 'Credit_Check_Completed_Denied', new List<User>{AE, Manager});
                            else if(cca == 'Credit Approved')
                                OpportunityUtils.sendWorkflowAndApprovalEmail(ord.Id, 'Credit_Check_Approved', new List<User>{AE});
                        }
                        else if(cca == 'Credit Approved pending condition' && (oldOrd == null || ord.Credit_Hold_Reason__c != oldOrd.Credit_Hold_Reason__c)){
                            
                            String emailTemplateName = null;
                            
                            String chr = ord.Credit_Hold_Reason__c;
                            if(chr == 'Credit Application Requested')
                                emailTemplateName = 'Credit_Check_Credit_App';
                            else if(chr == 'Payment for past due on existing account required')
                                emailTemplateName = 'Credit_Check_Credit_PastDue';
                            else if(chr == 'Payment on previous account required')
                                emailTemplateName = 'Credit_Check_Pymt_Prev_Acct';
                            else if(chr == 'Deposit Requested')
                                emailTemplateName = 'Credit_Check_Deposit';
                            else if(chr == 'Other')
                                emailTemplateName = 'Credit_Check_Other';
                                
                            if(emailTemplateName != null){
                                List<User> mcUserList = new List<User>{AE, Manager};
                                if(ord.Credit_Check_Rep__c != null)
                                    mcUserList.add(uMap.get(ord.Credit_Check_Rep__c));
                                OpportunityUtils.sendWorkflowAndApprovalEmail(ord.Id, emailTemplateName, mcUserList);
                            }
                        }
                    }
                }
            }
        }
        /* End: Workflow and approval emails section */
    }
    private static void handleContractRenewalOrderType(List<Order__c> tNew, Map<Id, Order__c> tOldMap){
        List<Sub_Order__c> newSubOrderList = new List<Sub_Order__c>();
        List<Sub_Order__c> updateSubOrderList = new List<Sub_Order__c>();        
        Id ctrRewRtID = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Contract Renewal').getRecordTypeId();
        List<Order__c> ctrOrders = new List<Order__c>();
        Set<Id> ctrOrderIds = new Set<Id>();
        for(Order__c oNew : tNew){
            if(oNew.recordTypeId == ctrRewRtID ){        
                ctrOrders.add(oNew);
                ctrOrderIds.add(oNew.Id);
            }
        }
        Map<Id, Sub_Order__c> existingSubOrders = new Map<Id, Sub_Order__c>();
        if(ctrOrderIds != null && ctrOrderIds.size() >0){
            for(Sub_Order__c so :[Select Order__c, Id, Name, Status__c,Contact_Renewal_MRR__c, New_Contract_End_Date__c, New_Contract_Start_Date__c, Old_Contract_Start_Date__c, Old_Contract_End_Date__c, Contract_Renewal_Order_Type__c from Sub_Order__c where Order__c in : ctrOrderIds  and Order__r.RecordTypeID = :ctrRewRtID order by Contract_Renewal_Order_Type__c]){
                  existingSubOrders.put(so.Order__c, so);
            }
        }
        
        for(Order__c oNew : ctrOrders){          
           if(oNew.recordTypeId == ctrRewRtID ){        
                Order__c oOld = tOldMap.get(oNew.Id);

                if(oOld == null){
                    if (oNew.Contract_Status__c == 'Renewal' || oNew.Contract_Status__c.contains('Churn')){
                        newSubOrderList.add(new Sub_Order__c(Name = 'c', Contact_Renewal_MRR__c = oNew.Original_Contract_MRC__c, 
                                                             Contract_Renewal_Order_Type__c='Disconnect', Old_Contract_Start_Date__c=oNew.Old_Contract_Start_Date__c,
                                                             Old_Contract_End_Date__c=oNew.Old_Contract_End_Date__c, 
                                                             Order__c = oNew.Id, SPC_Product__c=oNew.SPC_Product__c, Status__c= 'Closed', CurrencyIsoCode=oNew.CurrencyIsoCode));
                    }
                    String installSubOrderStatus = 'New';                                                         
                    if((oNew.New_Contract_Start_Date__c != null && oNew.New_Contract_End_Date__c != null && oNew.New_Contract_MRC__c != null)|| oNew.Contract_Status__c.contains('Install')){
                        installSubOrderStatus ='Closed';
                    }
                    if (oNew.Contract_Status__c == 'Renewal' || oNew.Contract_Status__c.contains('Install')){
                        newSubOrderList.add(new Sub_Order__c(Name = 'c', Contact_Renewal_MRR__c = oNew.New_Contract_MRC__c, 
                                         Contract_Renewal_Order_Type__c='Install', New_Contract_End_Date__c=oNew.New_Contract_End_Date__c, 
                                         New_Contract_Start_Date__c=oNew.New_Contract_Start_Date__c, 
                                         Order__c = oNew.Id, SPC_Product__c=oNew.SPC_Product__c, Status__c= installSubOrderStatus , CurrencyIsoCode=oNew.CurrencyIsoCode));
                    }
                    
               }else{
                  if(oNew.New_Contract_Start_Date__c != null && oNew.New_Contract_End_Date__c != null && oNew.New_Contract_MRC__c != null){
                     if(oOld.Contract_Status__c!= null && oOld.Contract_Status__c.contains('Churn') &&  oNew.Contract_Status__c.contains('Renewal')){
                        newSubOrderList.add(new Sub_Order__c(Name = 'c', Contact_Renewal_MRR__c = oNew.New_Contract_MRC__c, 
                                         Contract_Renewal_Order_Type__c='Install', New_Contract_End_Date__c=oNew.New_Contract_End_Date__c, 
                                         New_Contract_Start_Date__c=oNew.New_Contract_Start_Date__c, 
                                         Order__c = oNew.Id, SPC_Product__c=oNew.SPC_Product__c, Status__c= 'Closed', CurrencyIsoCode=oNew.CurrencyIsoCode));                     
                     }else{
                         Sub_Order__c updateSubOrder = existingSubOrders.get(oNew.Id);
                         if(updateSubOrder!= null){
                             if(oNew.Contract_Status__c.contains('Renewal') && updateSubOrder.Status__c== 'New' && updateSubOrder.Contract_Renewal_Order_Type__c == 'Install'){
                                 updateSubOrder.New_Contract_End_Date__c=oNew.New_Contract_End_Date__c;
                                 updateSubOrder.New_Contract_Start_Date__c=oNew.New_Contract_Start_Date__c;
                                 updateSubOrder.Contact_Renewal_MRR__c = oNew.New_Contract_MRC__c;
                                 updateSubOrder.Status__c= 'Closed';
                                 
                                 updateSubOrderList.add(updateSubOrder);
                             }else if(oOld.Contract_Status__c!= null && oOld.Contract_Status__c.contains('Anticipated') &&  oNew.Contract_Status__c.contains('Actual')){
                                 if(updateSubOrder.Contract_Renewal_Order_Type__c == 'Install'){
                                     updateSubOrder.New_Contract_End_Date__c=oNew.New_Contract_End_Date__c;
                                     updateSubOrder.New_Contract_Start_Date__c=oNew.New_Contract_Start_Date__c;
                                     updateSubOrder.Contact_Renewal_MRR__c = oNew.New_Contract_MRC__c;
                                     updateSubOrderList.add(updateSubOrder);
                                 }else{
                                     updateSubOrder.Old_Contract_End_Date__c=oNew.Old_Contract_End_Date__c;
                                     updateSubOrder.Old_Contract_Start_Date__c=oNew.Old_Contract_Start_Date__c;
                                     updateSubOrder.Contact_Renewal_MRR__c = oNew.Original_Contract_MRC__c;                             
                                     updateSubOrderList.add(updateSubOrder);
                                 }                                 
                             }                             
                         }
                      }
                   }
               }
        }
      }
        
        if(newSubOrderList.size() > 0)
            insert newSubOrderList;
            
        if(updateSubOrderList.size() > 0)
            update updateSubOrderList;      
        
    
    }
    
    private static void setOrderCompletionStatusForContractRenewalOrder(List<Order__c> tNew, Map<Id, Order__c> tOldMap){
        Id ctrRewRtID = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Contract Renewal').getRecordTypeId();
        for(Order__c oNew : tNew){  
           if(oNew.recordTypeId == ctrRewRtID ){        
                Order__c oOld = tOldMap.get(oNew.Id);
                if(oOld == null){
                    if(oNew.New_Contract_Start_Date__c != null && oNew.New_Contract_End_Date__c != null && oNew.New_Contract_MRC__c != null){
                        oNew.Order_Completion_Status__c = 'Complete';    
                    }
                }else{
                    if((oNew.Order_Completion_Status__c == null ||(oNew.Order_Completion_Status__c != null && oNew.Order_Completion_Status__c !='Complete' )) && oNew.New_Contract_Start_Date__c != null && oNew.New_Contract_End_Date__c != null && oNew.New_Contract_MRC__c != null){
                        oNew.Order_Completion_Status__c = 'Complete';
                    }
                }
            }
        }
    
    }
}