public with sharing class WorkstepTriggers {
    
    public static Boolean validateMode = false;
    
    public static void WorkstepModified(List<Workstep__c> tNew, List<Workstep__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
        
        if(!ApexUtils.executeTriggerMethods('Workstep__c', isBefore, isDelete)) return;
        
        if(isBefore){
            if(isDelete){
                deletePredecessors(tOld);
            }
            else{
                Map<Id, Workstep__c> tOldMap = tOld != null ? new Map<Id, Workstep__c>(tOld) : new Map<Id, Workstep__c>();
                if(!isUpdate){
                    populateWorkstepDefaults(tNew, tOldMap);
                }
                
                updateBefore(tNew, tOldMap);
            }
        }
        else{
            if(!validateMode){
                Map<Id, Workstep__c> tOldMap = tOld != null ? new Map<Id, Workstep__c>(tOld) : new Map<Id, Workstep__c>();
                
                if(isDelete){
                    //Nothing specific to do
                }
                else{
                    processWorkstep(tNew, tOldMap);
                    calculatePDD(tNew, tOldMap, isDelete);
                    calculatePNR(tNew, tOldMap, isDelete);
                    updateBuildOrderStatus(tNew, tOldMap);
                }
            }
            
            ApexUtils.afterTriggerComplete('Workstep__c', isDelete);
        }
    }
    
    private static void populateWorkstepDefaults(List<Workstep__c> tNew, Map<Id, Workstep__c> tOldMap) {
        
        Set<String> fieldDefaults = new Set<String>{'OwnerId', 'Milestone__c', 'Work_Group__c', 'Attribute__c', 'CTP_Attribute__c', 'CTP_Communication_Type__c'};
        Set<Id> orderIds = new Set<Id>();
        Set<Id> wslIds = new Set<Id>();
        Set<Id> soIds = new Set<Id>();
        for (Workstep__c ws : tNew) {
            if (ws.Order__c != null)
                orderIds.add(ws.Order__c);
            if(ws.Workstep_Library__c != null)
                wslIds.add(ws.Workstep_Library__c);
            if (ws.Sub_Order__c != null)
                soIds.add(ws.Sub_Order__c);
        }
        
        Map<Id, Order__c> orderMap = new Map<Id, Order__c>([SELECT Id, Project_Date__c, Expedited__c, OwnerId FROM Order__c WHERE Id IN :orderIds]);
        Map<Id, Sub_Order__c> soMap = new Map<Id, Sub_Order__c>([SELECT Id, Workplan_Start_Date__c, FOC_date__c, Activate_with_Customer_Date__c, Hardware_Install_and_Test_Date__c, Customer_Commit_Date__c, Expedited__c FROM Sub_Order__c WHERE Id IN :soIds]);
        Map<Id, Workstep_Library__c> wsLibraryMap = new Map<Id, Workstep_Library__c>([SELECT Id, OwnerId, Milestone__c, Work_Group__c, Non_Access_Duration__c, Non_Access_Lag__c, 
                                                                                        Non_Access_SLA__c, Attribute__c, CTP_Attribute__c, CTP_Communication_Type__c, Default_to_Order_Owner__c
                                                                                        FROM Workstep_Library__c WHERE Id IN :wslIds]);
                                                                        
        Map<String, Boolean> compressibilityMap = WorkstepUtils.getAttributesCompressibility();
        for (Workstep__c ws : tNew) {
            if (ws.Workstep_Library__c != null) {
                Workstep_Library__c wsl = wsLibraryMap.get(ws.Workstep_Library__c);
                for(String f : fieldDefaults)
                    ws.put(f, ws.get(f) == null ? wsl.get(f) : ws.get(f));
                
                ws.Lag__c = (ws.Lag__c == null ? wsl.Non_Access_Lag__c : ws.Lag__c);
                ws.SLA__c = (ws.SLA__c == null ? wsl.Non_Access_SLA__c : ws.SLA__c);                
                ws.Status__c = (ws.Status__c == null ? 'Pending' : ws.Status__c);
                
                Order__c ord = ws.Order__c != null ? orderMap.get(ws.Order__c) : null;
                Sub_Order__c so = ws.Sub_Order__c != null ? soMap.get(ws.Sub_Order__c) : null;
                
                if(wsl.Default_to_Order_Owner__c) ws.OwnerId = ord.OwnerId;
                
                if (((so != null && so.Expedited__c) || (ord != null && ord.Expedited__c)) && (ws.Attribute__c == null || compressibilityMap.get(ws.Attribute__c.toLowerCase()) == true))
                    ws.Duration__c = (Integer)(ws.Duration__c == null ? (wsl.Non_Access_Duration__c + 1)/2 : (ws.Duration__c + 1)/2);
                else
                    ws.Duration__c = (ws.Duration__c == null ? wsl.Non_Access_Duration__c : ws.Duration__c);
                
                if(ws.Start_Date__c == null){
                    ws.Start_Date__c = so != null ? so.Workplan_Start_Date__c : ord.Project_Date__c;
                    ws.Start_Date__c = (ws.Start_Date__c == null || ws.Start_Date__c < Date.today()) ? Date.today() : ws.Start_Date__c;
                }
            }
        }
    }
    
    private static void updateBefore(List<Workstep__c> tNew, Map<Id, Workstep__c> tOldMap){     
        List<Workstep__c> completed = new List<Workstep__c>();
        Map<Id, Workstep_Template__c> templates = new Map<Id, Workstep_Template__c>();
        Map<Id, List<Workstep__c>> soWSMap = new Map<Id, List<Workstep__c>>();
        Map<Id, Workstep__c> unblocked = new Map<Id, Workstep__c>();
        Map<Id, Workstep__c> cancelBlocked = new Map<Id, Workstep__c>();
        List<Workstep_Issue__c> updateWSI = new List<Workstep_Issue__c>();
        
        Set<Id> unpending = new Set<Id>();
        Set<Id> updateOrders = new Set<Id>();
        for(Workstep__c ws : tNew){
            Workstep__c wOld = ws.Id != null ? tOldMap.get(ws.Id) : null;
            
            //Any status change/initial setting
            if((wOld == null || wOld.Status__c != ws.Status__c)){
                
                //New value is complete
                if(ws.Status__c == WorkstepUtils.STATUS_COMPLETE){
                    completed.add(ws);
                    if(ws.Template__c != null)
                        templates.put(ws.Template__c, null);
                    
                    Workstep_Library__c lib = ws.Workstep_Library__c != null ? WorkstepUtils.dateDrivenLibraries.get(ws.Workstep_Library__c) : null;
                    if(lib != null && !String.isEmpty(lib.Complete_Date_Field__c)){
                        if(ws.Sub_Order__c != null && lib.Complete_Date_Field__c.startsWith('Sub_Order__c.')){
                            List<Workstep__c> l = soWSMap.get(ws.Sub_Order__c) != null ? soWSMap.get(ws.Sub_Order__c) : new List<Workstep__c>();
                            l.add(ws);
                            soWSMap.put(ws.Sub_Order__c, l);
                        }
                        else if(ws.Order__c != null && lib.Complete_Date_Field__c.startsWith('Order__c.')) updateOrders.add(ws.Order__c);
                    }
                }
                
                //Old value was blocked
                if(wOld != null && wOld.Status__c == WorkstepUtils.STATUS_BLOCKED && ws.Status__c != WorkstepUtils.STATUS_CANCELLED)
                    unblocked.put(ws.Id, ws);
                else if(wOld != null && wOld.Status__c == WorkstepUtils.STATUS_BLOCKED && ws.Status__c == WorkstepUtils.STATUS_CANCELLED){
                    cancelBlocked.put(ws.Id, ws);
                }
            }
            
            //todo: can these be formulas?
            ws.BlockedByCode__c = (ws.Status__c == 'Blocked');
            ws.BlockedPendingValidationByCode__c = (ws.Status__c == 'Blocked Pending Validation');
            
            if(ws.Start_Date__c != null && ws.End_Date__c == null)
                ws.End_Date__c = WorkstepUtils.calculateSuccessorDates(ws.Start_Date__c, (Integer)ws.Duration__c, 0).EndDate;
        }
        
        if(completed.size() > 0){
            templates = new Map<Id, Workstep_Template__c>([select Id, External_Callout_Type__c from Workstep_Template__c where Id in : templates.keyset()]);
            for(Workstep__c ws : completed){
                if(ws.Template__c != null && templates.get(ws.Template__c).External_Callout_Type__c != null && ws.Actual_Completion_Date__c == null){               
                    ws.Status__c = WorkstepUtils.STATUS_INTEGRATE;
                }
                else
                    ws.Actual_Completion_Date__c = Date.today();
            }
        }
        
        if(unblocked.size() > 0){
            for(Workstep__c ws: [select Id, (select Workstep__c from Workstep_Issues__r WHERE Status__c = 'Open' limit 1) from Workstep__c where Id in: unblocked.keyset()]){
                if(ws.Workstep_Issues__r != null && ws.Workstep_Issues__r.size() > 0)
                    unblocked.get(ws.Id).addError('Worksteps with Open Workstep Issues cannot be unblocked.');
            }
        }   
        if(cancelBlocked.size() > 0){
            for(Workstep_Issue__c wsi: [select Id, Workstep__c, Reason__c, Resolution_Comments__c from Workstep_Issue__c WHERE   Workstep__c in: cancelBlocked.keyset()]){
                wsi.Reason__c = 'Order Canceled';
                wsi.Status__c = 'Resolved';
                wsi.Resolution_Comments__c = 'Cancelling Sub-Order';
                wsi.Resolution_Code__c = 'Order Canceled';
                wsi.Date_Resolved__c = date.today();
            
                updateWSI.add(wsi);
            }
        }
        
        Boolean setSubOrderValues = soWSMap.size() > 0 && !validateMode;
        
        Map<Id, Order__c> ords = new Map<Id, Order__c>();
        for(Id ordID : updateOrders) ords.put(ordID, null);
        
        List<Sub_Order__c> soList = null;
        if(setSubOrderValues){
            soList = [SELECT Id, Order__c, External_Order__c, External_Order__r.Type__c, External_Products__c, Service_Location__c, Service_Location__r.Customer_Detail__c, Service_Location__r.Account__r.Customer_Detail__c   FROM Sub_Order__c WHERE Id IN :soWSMap.keySet()];
            for(Sub_Order__c so : soList) ords.put(so.Order__c, null);
        }
        
        if(ords.size() > 0){
            ords = new Map<Id, Order__c>([SELECT Account__c, Opportunity__c, Opportunity__r.AccountId, Opportunity__r.Id, RecordType.DeveloperName, Care_Organization__c, (Select Type__c from Order_Properties__r where Type__c = 'Install Order') FROM Order__c where Id in : ords.keyset()]);
            if(updateOrders.size() > 0){
                for(Order__c ord : ords.values()){
                    if(updateOrders.contains(ord.Id)){
                        for(Workstep__c ws : completed){
                            Workstep_Library__c lib = WorkstepUtils.dateDrivenLibraries.get(ws.Workstep_Library__c);
                            if(ws.Order__c == ord.Id && lib.Complete_Date_Field__c.startsWith('Order__c.')){
                                String fieldName = lib.Complete_Date_Field__c.substring(lib.Complete_Date_Field__c.indexOf('.') + 1);
                                ord.put(fieldName, Date.today());
                            }
                        }
                    }
                }
            }
        }
        
        if(setSubOrderValues){
            CustomerSurveyUtils.sendOrderSurveys(ords, soList, soWSMap);
            
            for (Sub_Order__c so : soList) {
                Order__c ord = ords.get(so.order__c);
                for(Workstep__c ws : soWSMap.get(so.Id)){
                    Workstep_Library__c lib = WorkstepUtils.dateDrivenLibraries.get(ws.Workstep_Library__c);
                    String fieldName = lib.Complete_Date_Field__c.substring(lib.Complete_Date_Field__c.indexOf('.') + 1);
                    so.put(fieldName, Date.today());
                }
            }
            
            update updateWSI;
            
            SecurityUtils.BypassProcesser.saveObjects(soList, false);
        }
        
        if(updateOrders.size() > 0) SecurityUtils.BypassProcesser.saveObjects(ords.values(), false);
    }
    
    private static void processWorkstep(List<Workstep__c> tNew, Map<Id, Workstep__c> tOldMap) {
        List<Workstep__c> newWorksteps = new List<Workstep__c>([SELECT Id
                                                                        ,CTP_Attribute__c
                                                                        ,Start_Date__c
                                                                        ,End_Date__c
                                                                        ,Duration__c
                                                                        ,Actual_Completion_Date__c
                                                                        ,Status__c
                                                                        ,Unblocked_Date__c
                                                                        ,Workstep_First_Opened_Date__c
                                                                        ,Name
                                                                        ,Sub_Order__r.id
                                                                    FROM Workstep__c WHERE Id IN :tNew]);
        Set<Id> updateCTP = new Set<Id>();
        Set<Id> updateSuccessors = new Set<Id>();
        Set<Id> doCallout = new Set<Id>();
        
        Set<String> recalcFields = new Set<String>{'Actual_Completion_Date__c', 'Start_Date__c', 'End_Date__c', 'Duration__c', 'Unblocked_Date__c', 'Status__c'};
        for (Workstep__c ws : newWorksteps) {
            Workstep__c wsOld = ws.Id != null ? toldMap.get(ws.Id) : null;
            
            if(wsOld == null || (ws.Status__c != wsOld.Status__c)){
                if ((ws.Status__c == WorkstepUtils.STATUS_OPEN && ws.CTP_Attribute__c == 'Start')
                    || (ws.Status__c == WorkstepUtils.STATUS_COMPLETE && ws.CTP_Attribute__c == 'End'))
                    updateCTP.add(ws.Id);
                    
                if (ws.Status__c == WorkstepUtils.STATUS_OPEN && ws.Workstep_First_Opened_Date__c == null){
                    ws.Workstep_First_Opened_Date__c = DateTime.now();              
                    update ws;
                }
                if(ws.Status__c == WorkstepUtils.STATUS_INTEGRATE)
                    doCallout.add(ws.Id);
                else if(ws.Status__c == WorkstepUtils.STATUS_COMPLETE || ws.Status__c == WorkstepUtils.STATUS_OPEN){                                        
                    updateSuccessors.add(ws.Id);
                }
//                if (ws.Status__c == WorkstepUtils.STATUS_COMPLETE && ws.Name == 'Send to Billing') {
//                    processSDWAN(ws.Sub_Order__r.id);
//                }
                    
            }
            
            if(wsOld != null){
                for(String f : recalcFields){
                    if(ws.get(f) != wsOld.get(f))
                        updateSuccessors.add(ws.Id);
                }
            }
        }
        
        if (updateCTP.size() > 0)
            insertCTPs(updateCTP);
        
        if(updateSuccessors.size() > 0)
            WorkstepUtils.updateWorkstepSuccessors(updateSuccessors);
        
        if(doCallout.size() > 0)
            handleExternalCallouts(doCallout, UserInfo.getSessionID());
    }
    
    private static void insertCTPs(Set<Id> updateCTP) {
        Map<Id, Workstep__c> wsMap = new Map<Id, Workstep__c>([SELECT Id, Name, CTP_Attribute__c, CTP_Communication_Type__c, Order__c, Order__r.OwnerId, Order__r.RecordTypeId, Sub_Order__c, Sub_Order__r.Order__r.OwnerId, Sub_Order__r.Order__r.RecordTypeId FROM Workstep__c WHERE Id IN :updateCTP]);

        List<Task> taskList = new List<Task>();
        for (Workstep__c ws : wsMap.values()) {
            if (ws.CTP_Attribute__c != null) {
                for (String ct : (ws.CTP_Communication_Type__c != null) ? ws.CTP_Communication_Type__c.split(';') : new List<String>{null})
                    taskList.add(new Task(Subject = ('CTP - ' + ws.Name + ' - ' + ws.CTP_Attribute__c)
                                ,ActivityDate = date.today()
                                ,Type = 'CTP ' + ws.CTP_Attribute__c
                                ,SubType__c = ct
                                ,Status = 'Not Started'
                                ,Priority = 'Normal'
                                ,WhatId = ws.Sub_Order__c != null ? ws.Sub_Order__c : ws.Order__c
                                ,IsReminderSet = true
                                ,OwnerId = ws.Order__r.OwnerId));
            }
        }
        
        if(taskList.size() > 0){
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.EmailHeader.triggerUserEmail = true;
            Database.insert(taskList, dmlOptions);
        }
    }
    
    private static void calculatePDD(List<Workstep__c> tNew, Map<Id, Workstep__c> tOldMap, Boolean isDelete) {
        Set<Id> subOrderPDDSet = new Set<Id>();
        for (Workstep__c ws : isDelete ? tOldMap.values() : tNew) {
            Workstep__c wsOld = ws.Id != null && !isDelete ? tOldMap.get(ws.Id) : null;
            if (ws.Sub_Order__c != null)
                subOrderPDDSet.add(ws.Sub_Order__c);
        }       
        WorkstepUtils.recalculatePDD(subOrderPDDSet);
    }
    
    private static void calculatePNR(List<Workstep__c> tNew, Map<Id, Workstep__c> tOldMap, Boolean isDelete) {
        Set<Id> OrderPNRSet = new Set<Id>();
        for (Workstep__c ws : isDelete ? tOldMap.values() : tNew) {
            Workstep__c wsOld = ws.Id != null && !isDelete ? tOldMap.get(ws.Id) : null;
            if (ws.Order__c != null)
                OrderPNRSet.add(ws.Order__c);
        }
        
        WorkstepUtils.recalculatePNR(OrderPNRSet);
    }
    
    private static void updateBuildOrderStatus(List<Workstep__c> tNew, Map<Id, Workstep__c> tOldMap) {
        //1. Determine if workstep is related to Build ||Decomm Order in OrderUtils
        //2. If it is related to Build/Decomm order then flip thru the WS status and if all = 'complete' then update orderstatus
        //3. else do nothing.
        List<Workstep__c> bows = new List<Workstep__c>();
        Id oId = null;
        Boolean isBldOrd = false;
        Boolean isOrderComplete = false;
        Map<Id, Order__c> ods = new Map<Id,Order__c>();
        for(Workstep__c ws : tNew){
            if(ws.Order__c != null)
            ods.put(ws.Order__c, null);
        }
        ods = new Map<Id, Order__c>([select Id, recordtypeid from Order__c where id in :ods.keySet()]);
        for (Workstep__c ws : tNew) {       
            if(ws.Order__c != null) {           
                order__c ord = ods.containsKey(ws.Order__c)?ods.get(ws.Order__c) : null;
                oId = ord.Id;               
                isBldOrd = ord != null && (ord.recordTypeId == OrderUtils.BuildOrderRecordTypeID || ord.recordTypeId == OrderUtils.DecommOrderRecordTypeID);
            }
        }
        if(isBldOrd && oId != null){
            bows = [Select Id, Status__c From Workstep__c Where Order__c =: oId];           
        }
        for(Workstep__c wstep : bows){          
            if(wstep.Status__c == 'Complete')
                isOrderComplete = true;
            else{
                isOrderComplete = false;
                break;
            }
        }
        if(isOrderComplete){            
            Order__c o = [Select Id, Order_Completion_Status__c From Order__c Where Id =: oId];
            if(o != null){
                o.Order_Completion_Status__c = 'Complete';
                update o;
            }
        }
    }

    private static void deletePredecessors(List<Workstep__c> tOld) {
        Set<Id> wsForDeleteIds = new Set<Id>();
        for (Workstep__c ws : tOld)
            wsForDeleteIds.add(ws.Id);
        
        List<Predecessor__c> predList = [SELECT Id, Dependent_Workstep__c, Predecessor_Workstep__c FROM Predecessor__c WHERE Predecessor_Workstep__c IN :wsForDeleteIds];
        if (predList.size() > 0)
            delete predList;
    }
    
    //return workstep ids with a status of success or failure
    @future (callout=true)
    private static void handleExternalCallouts(Set<Id> workstepIds, String sessionId){
        List<Workstep__c> workSteps = [select Id, Name, Sub_Order__c, Template__r.External_Callout_Type__c, Actual_Completion_Date__c, OwnerId, Owner.Email, Status__c, Callout_Error__c from Workstep__c where Id in : workstepIds];
        List<String> OwnerEmails = new List<String>();
        Map<Id, WorkstepCalloutResult> workStepResults = new Map<Id, WorkstepCalloutResult>(); 
        Map<Id, Sub_Order__c> soMap = new Map<Id, Sub_Order__c>();
        
        for (Workstep__c ws : workSteps) {
            soMap.put(ws.Sub_Order__c, null);
            workStepResults.put(ws.Id, new WorkstepCalloutResult(ws));
            if(ws.Owner.Email != null && ws.Owner.Email.length() > 0)
             OwnerEmails.add(ws.Owner.Email);
        }
        
        soMap = new Map<Id, Sub_Order__c>([select Id, Name, Customer_Acceptance_Date__c, (select Id, Name, External_ID__c, Status__c from Sub_Order_Groups__r where External_ID__c != null) from Sub_Order__c where Id in: soMap.keyset()]);
        
        Map<String, String> groupCalloutTypes = new Map<String, String>();
        Date groupCustomerAcceptanceDate = Date.today();
        Map<String, Sub_Order_Group__c> subOrderGroups = new Map<String, Sub_Order_Group__c>();
        Map<String, Workstep__c> OrderProductGroupToWorkstep = new Map<String, Workstep__c>();
        for(Workstep__c ws : workSteps){
            Sub_Order__c so = soMap.get(ws.Sub_Order__c);
            if(so != null && so.Sub_Order_Groups__r != null){
                if(so.Customer_Acceptance_Date__c != null)
                    groupCustomerAcceptanceDate = date.newinstance(so.Customer_Acceptance_Date__c.year(), so.Customer_Acceptance_Date__c.month(), so.Customer_Acceptance_Date__c.day());
                for(Sub_Order_Group__c sog : so.Sub_Order_Groups__r){
                    subOrderGroups.put(sog.External_ID__c, sog);
                    
                    OrderProductGroupToWorkstep.put(sog.External_ID__c, ws);                                //todo: neither of these scale if multiple process at once on same sub-order
                    groupCalloutTypes.put(sog.External_ID__c, ws.Template__r.External_Callout_Type__c); //
                    
                }
            }
        }

        if(groupCalloutTypes.size() > 0) {
            
            Map<String, List<Integer>> calloutSet = new Map<String, List<Integer>>();
            for(String d : groupCalloutTypes.keySet()){
                if (!calloutSet.containsKey(groupCalloutTypes.get(d)))
                    calloutSet.put(groupCalloutTypes.get(d), new List<Integer>());
                        
                calloutSet.get(groupCalloutTypes.get(d)).add(Integer.valueOf(d));
            }
            
            //Get the callout results
            List<integraWS.SFSubOrderGroupStatusView> calloutResults = new List<integraWS.SFSubOrderGroupStatusView>();
            for(String callOutType : calloutSet.keySet()){
                try{
                    calloutResults.addAll(ICCWrapper.UpdateOrderProductGroups(calloutSet.get(callOutType), callOutType, groupCustomerAcceptanceDate, sessionId, CustomSettingUtils.SFDCCallbackEndpoint));
                }
                catch (Exception ex) {
                    String errorMessage = 'An error occurred while processing an external callout for your Workstep.\r\n';
                    errorMessage += 'Please report the following error to your Salesforce Administrator:\r\n';
                    errorMessage += ex.getMessage();
                    if(OwnerEmails.size() > 0)
                    sendEmail(OwnerEmails, 'There was an error trying to update the external systems', errorMessage);
                }
            }
            
            // now loop through results and update Sub Order Group status and return WorkSteps with Success or failure
            List<Sub_Order_Group__c> updateSubOrderGroup = new List<Sub_Order_Group__c>();
            for(integraWS.SFSubOrderGroupStatusView sr : calloutResults){
                Sub_Order_Group__c sog = subOrderGroups.get(String.valueOf(sr.OrderProductGroupID));                
                if(sog != null && sr.ResultStatus == 'Success') {
                    if(sr.GroupStatusDescription != null)
                        sog.Status__c = sr.GroupStatusDescription;
                    updateSubOrderGroup.add(sog);               
                }
                
                //Add the results to workstep result class
                Workstep__c ows = OrderProductGroupToWorkstep.get(String.valueOf(sr.OrderProductGroupID));
                if(ows != null) {
                    WorkstepCalloutResult wsResult = workStepResults.get(ows.Id);
                    if(wsResult != null)
                        wsResult.AddResult(sr);
                }
            }
            
            if(updateSubOrderGroup.size() > 0)
                update updateSubOrderGroup;
            
            //now go through all the worksteps results if ALL their status successfully updated and add to list of Worksteps that can be complete if not we will send an Email to the Owner
            List<Workstep__c> updateWorksteps = new List<Workstep__c>();
            List<WorkstepCalloutResult> failedCallouts = new List<WorkstepCalloutResult>();
            Map<Id, Workstep__c> successfulWorksteps = new Map<Id,Workstep__c>();
            for(WorkstepCalloutResult wsr : workStepResults.values()) {
                if(wsr.IsSuccessful) {
                    wsr.WorkStep.Status__c = WorkstepUtils.STATUS_COMPLETE;
                    wsr.Workstep.Actual_Completion_Date__c = Date.today();
                    successfulWorksteps.put(wsr.WorkStep.Id,wsr.WorkStep);
                }
                else {
                    wsr.WorkStep.Status__c = WorkstepUtils.STATUS_INTEGRATE_FAIL;
                    wsr.Workstep.Callout_Error__c = wsr.FailureMessage;
                    failedCallouts.add(wsr);
                }
                updateWorksteps.add(wsr.WorkStep);
            }
            
            if(updateWorksteps.size() > 0)
                update  updateWorksteps;
        
                
            
            //Email those callouts that were not successful
            if(failedCallouts.size() > 0) {
                for(WorkstepCalloutResult wcr : failedCallouts)
                    sendEmail(new List<String> {wcr.WorkStep.Owner.Email}, wcr.FailureEmailSubject, wcr.FailureEmailBody);
            }
            //The Completed Wirksteps need to update Successors
            if(successfulWorksteps.size() > 0)
                WorkstepUtils.updateWorkstepSuccessors(successfulWorksteps.keySet());
        }
    }
    
    private static void sendEmail(List<String> userEmail, String subject, String body){
        if (!Test.isRunningTest())
            ApexUtils.sendEmails(new Messaging.SingleEmailMessage[]{ ApexUtils.createEmailMessage(userEmail, null, subject, body, false, null)});
    }
    
    public class WorkstepCalloutResult {
        public Workstep__c WorkStep {get; set;}
        List<integraWS.SFSubOrderGroupStatusView> SubOrderGroupResults {get; set;}
        public Boolean IsSuccessful {
            get {
                Boolean result = false;
                if(this.SubOrderGroupResults.size() > 0) {
                    result = true;
                    for(integraWS.SFSubOrderGroupStatusView sv : this.SubOrderGroupResults) {
                        if(sv.ResultStatus != 'Success') {
                            result = false;
                            break;
                        }
                    }
                }
                return result;
            }
        }
        
        public String FailureEmailSubject {
            get { return (WorkStep == null)
                            ? 'There was a failure on an external callout on a Workstep you own.'
                            : ('The external callout on Workstep: ' + WorkStep.Name + ' on Sub-Order: ' + WorkStep.Sub_Order__r.Name + ' has failed.'); }
        }
        
        public String FailureEmailBody {
            get{
                String result = (WorkStep == null)
                                ? 'There was a failure on an external callout on Workstep you own.'
                                : ('The external callout on Workstep: ' + WorkStep.Name + ' on Sub-Order: ' + WorkStep.Sub_Order__r.Name + ' has failed.\r\n');
                
                if(SubOrderGroupResults.size() > 0) {
                    for(integraWS.SFSubOrderGroupStatusView sv : SubOrderGroupResults) {
                        result += 'Order Product Group: ' + String.valueOf(sv.OrderProductGroupID) + ' - Result: ' + sv.ResultStatus;
                        if(sv.ResultMessage.length() > 0)
                            result += ' - Message: ' + sv.ResultMessage;
                        result += '.\r\n';
                    }
                }
                return result;
            }
        }
        
        public String FailureMessage {
            get{
                String result = '';
                if(SubOrderGroupResults.size() > 0) {
                    for(integraWS.SFSubOrderGroupStatusView sv : SubOrderGroupResults) {
                        result += 'Order Product Group: ' + String.valueOf(sv.OrderProductGroupID) + '\r\n';
                        if(sv.ResultMessage.length() > 0)
                            result += ' - Message: ' + sv.ResultMessage;
                        result += '.\r\n';
                    }
                }
                return result;
            }
        }
        
        public WorkstepCalloutResult(Workstep__c workstep) {
            this.WorkStep = workstep;
            this.SubOrderGroupResults = new List<integraWS.SFSubOrderGroupStatusView>();
        }
        
        public void AddResult(integraWS.SFSubOrderGroupStatusView result) {
            this.SubOrderGroupResults.add(result);
        }
    }
    
    /* Was part of SEAL-1985 put requirement was dropped for now
    //@future - Future method cannot be called from a future or batch method: CaseTriggers.createCaseRemarks(Set<Id>, Boolean, String, Id)
    static void processSDWAN(id soid) {
        //if Sub-order Group contains the SD-WAN product & Market is “National” 
        //create case
        List<Case> newCases = new List<Case> {};
       
        Sub_Order_Group__c sog = [SELECT id, Product__c, Sub_Order__c, Sub_Order__r.Order__r.Account__c, 
                                 Sub_Order__r.Service_Location__c, Sub_Order__r.Order__c, Sub_Order__r.Customer_Detail__c, Sub_Order__r.Customer_Detail__r.Market_Area__r.Name 
                                 FROM Sub_Order_Group__c WHERE Sub_Order__r.id =: soid];
        if (sog.Product__c == 'SD WAN' && sog.Sub_Order__r.Customer_Detail__r.Market_Area__r.Name == 'National') {
            Customer_Contact__c cc = [SELECT Contact__c FROM Customer_Contact__c WHERE Contact_Type__c = 'Responsible Party' AND Customer_Detail__c =: sog.Sub_Order__r.Customer_Detail__c LIMIT 1];
            Case newCase = new Case(
                recordTypeId = '012C0000000MZeiIAG', //Support
                AccountId = sog.Sub_Order__r.Order__r.Account__c,
                Service_Location__c = sog.Sub_Order__r.Service_Location__c,
                Status = 'New',
                Type = 'Manual Billing',
                Manual_Billing_Request_Type__c = 'Manual Billing',
                Origin = 'Internal',
                Commit_Date__c = date.today() + 30,
                Sub_Order__c = sog.Sub_Order__c,
                ContactId = cc.Contact__c
            );
            newCases.add(newCase);
        }
        insert newCases;
    }
    */
}