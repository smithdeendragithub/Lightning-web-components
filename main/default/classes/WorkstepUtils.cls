public with sharing class WorkstepUtils {
    public static final String ACTIVATE_WITH_CUSTOMER = 'Activate with Customer';
    public static final String APPLY_REDLINES = 'Apply Redlines';
    public static final String CCD_DRIVEN = 'CCD Driven';
    public static final String CLICK_ACTIVATION_DATE_DRIVEN = 'CLICK Activation Date Driven';
    public static final String CONFIRM_CUSTOMER_ACCEPTANCE = 'Confirm Customer Acceptance';
    public static final String FOC_DRIVEN = 'FOC Driven';
    public static final String HARDWARE_INSTALL_AND_TEST = 'Hardware Install and Test';
    public static final String OBTAIN_CLLI_CODE = 'Obtain CLLI Code';
    public static final String PDD_CALCULATION = 'Exclude From PDD Calculation';
    public static final String PROCURE_TEST_FACILITY = 'Procure and Test Facility';
    public static final String SEND_TO_BILLING = 'Send to Billing';
    
    private static final String NETWORK_NODE_TURN_UP = 'Network Node Turn Up';
    public static final String SITE_SURVEY = 'Site Survey';
    private static final String ESTIMATED_PERMIT = 'Estimated Permit';
    private static final String ESTIMATED_BLA = 'Estimated BLA';
    private static final String ESTIMATED_CONSTRUCTION = 'Estimated Construction';
    private static final String FIBER_SMP = 'Fiber SMP';
    private static final String NIE_SMP = 'NIE SMP';
    private static final String POWER_SMP = 'Power SMP';
    
    public static final String STATUS_BLOCKED = 'Blocked';
    public static final String STATUS_CANCELLED = 'Cancelled';
    public static final String STATUS_COMPLETE = 'Complete';
    public static final String STATUS_INTEGRATE = 'Integrating';
    public static final String STATUS_INTEGRATE_FAIL = 'ICC Action Required';
    public static final String STATUS_OPEN = 'Open';
    public static final String STATUS_PENDING = 'Pending';
    
    public static final String ISSUE_RESOLVED = 'Resolved';
    public static final String TECHNICAL_ORDER_VALIDATION = 'Technical Order Validation';
    public static final String TECHNICAL_SHEET_CREATION = 'Technical Sheet Creation';
    public static final String VPN_SOLUTIONS = 'VPN Solutions';
    public static final String CLOUD_FIREWALL_SERVICE = 'Cloud Firewall Service';
    public static final String SIP_SOLUTIONS = 'SIP Solutions';
    public static final String UC_CLOUD_VOICE_MS = 'UC Cloud Voice - Main Site';
    public static final String UC_CLOUD_VOICE_RS = 'UC Cloud Voice - Remote Site';
    public static final String VPLS = 'VPLS - Virtual Private LAN Solutions';
    public static final String DEDICATED_INTERNET  = 'Dedicated Internet';
    
    private static Id unUser;
    public static Id UnassignedUser {
        get {
            if(unUser == null) unUser = [SELECT Id from User WHERE Name = :'Unassigned' Limit 1].Id;
            return unUser;
        }
    }
    
    private static Map<Id, Group> om;
    public static Map<Id, Group> orderManager{
        get{
            if(om == null){
                om =  new Map<Id, Group>([select Id, Name from Group where Type = 'Queue' and Name in ('SIP-Order Management','Legacy-Order Management')]);
            }
            return om;
        }
    }
    
    private static Map<Id, Group> dm;
    public static Map<Id, Group> deliveryManager{
        get{
            if(dm == null){
                dm =  new Map<Id, Group>([select Id, Name from Group where Type = 'Queue' and Name in ('Data/Internet-Delivery Management','SIP-Delivery Management')]);
            }
            return dm;
        }
    }

    private static Map<Id, Group> oe;
    public static Map<Id, Group> orderEntry{
        get{
            if(oe == null){
                oe =  new Map<Id, Group>([select Id, Name from Group where Type = 'Queue' and Name in ('Data/Internet-Order Entry', 'Legacy-Order Entry', 'SIP-Order Entry')]);
            }
            return oe;
        }
    }
    
    class PredecessorException extends Exception {}
    
    public class WorkstepDates{
        public Date StartDate {get; set;}       
        public Date EndDate {get; set;}
    }
    
    private static List<Holiday> allHolidaysList;
    private static List<Holiday> AllHolidays{
        get{
            if(allHolidaysList == null)
                allHolidaysList = [SELECT Id, ActivityDate, RecurrenceStartDate, StartTimeInMinutes, EndTimeInMinutes,RecurrenceInterval,RecurrenceEndDateOnly FROM Holiday];
            return allHolidaysList;
        }
    }
    
    //New Predeceesor Chain
    public class PredecessorChain{
        public Map<Id, Integer> AllWorkstepLevels {get; set;}
        public Map<Id, List<Predecessor__c>> PredecessorMap {get; set;}
        public Map<Id, List<Predecessor__c>> DependentMap {get; set;}
        public Map<Id, Workstep__c> WorkstepList {get; set;}
        
        public PredecessorChain(){
            AllWorkstepLevels = new Map<Id, Integer>();
            PredecessorMap = new Map<Id, List<Predecessor__c>>();
            DependentMap = new Map<Id, List<Predecessor__c>>();
            WorkstepList = new Map<Id, Workstep__c>();
        }
        
        public List<Workstep__c> GetWorkstepLevel(Integer lvl){
            List<Workstep__c> result = new List<Workstep__c>();
            if(lvl > 0){
                for(Id w : AllWorkstepLevels.keySet()){
                    if(AllWorkstepLevels.get(w) == lvl) result.add(WorkstepList.get(w));
                }
            }
            return result;
        }
        
        public Map<Integer, Set<Id>> GetReversedWorkstepLevelMap(){
            Map<Integer, Set<Id>> r = new Map<Integer, Set<Id>>();
            
            List<Integer> allVals = new List<Integer>(new Set<Integer>(AllWorkstepLevels.values()));
            allVals.sort();
            
            for(Integer v : allVals) r.put(v, new Set<Id>());
            
            for(Id id : AllWorkstepLevels.keyset()) r.get(AllWorkstepLevels.get(id)).add(id);
            
            return r;
        }
    }
    
    public static PredecessorChain getPredecessorChain(Set<Id> wsIDs){
        PredecessorChain pChain = new PredecessorChain();
        
        if(wsIDs.size() > 0){
            Set<Id> suborderIds = new Set<Id>();
            Set<Id> orderIds = new Set<Id>();
            for (Workstep__c ws : [select Order__c, Sub_Order__c from Workstep__c where Id in: wsIDs]){
                if(ws.Sub_Order__c != null) suborderIds.add(ws.Sub_Order__c);
                else orderIds.add(ws.Order__c);     //Only add Order__c if no SubOrder case we have cross-object dependencies
            }
            
            //get the list of worksteps with their preds and successors
            List<Workstep__c> wsList = new List<Workstep__c>([select Id, Unblocked_Date__c, Name, Predecessor_Count__c, Start_Date__c, End_Date__c,(select Id, Task_Dependency_Type__c, Predecessor_Workstep__c, Dependent_Workstep__c, Name from Predecessors__r),(select Id, Task_Dependency_Type__c, Predecessor_Workstep__c, Dependent_Workstep__c, Name from Successors__r)
                                                                from Workstep__c where Sub_Order__c in: suborderIds or (Sub_Order__c = null and Order__c in: orderIds) order by Sub_Order__c, Predecessor_Count__c]);
            
            //Get the worksteps with no preds
            Set<Workstep__c> firstWS = new Set<Workstep__c>();
            for(Workstep__c ws : wsList){
                if(ws.Predecessors__r == null || ws.Predecessors__r.size() == 0) pChain.AllWorkstepLevels.put(ws.Id,1);
                
                pChain.WorkstepList.put(ws.Id, ws);
                pChain.PredecessorMap.put(ws.Id, ws.Predecessors__r != null ? ws.Predecessors__r : new List<Predecessor__c>());
                pChain.DependentMap.put(ws.Id, ws.Successors__r != null ? ws.Successors__r : new List<Predecessor__c>());
            }
            
            //Now start with those first steps create a list of Successors and loop through them
            
            Integer lvl = 1;
            while(lvl <= pChain.WorkstepList.size()){
                Map<Id, Workstep__c> successorList = new Map<Id, WorkStep__c>();
                Set<Id> levelSteps = new Set<Id>();
                for(Workstep__c ws : wsList){
                    if(pChain.AllWorkstepLevels.get(ws.Id) == lvl){
                        for(Predecessor__c sws : ws.Successors__r){
                            Workstep__c sWorkstep = pChain.WorkstepList.get(sws.Dependent_Workstep__c);
                            if(sWorkstep != null) successorList.put(sWorkstep.Id, sWorkstep);
                        }
                    }
                }
                //now go through successorList and set them to next level
                lvl += 1;
                for(Workstep__c s : successorList.values()) pChain.AllWorkstepLevels.put(s.Id,lvl);
            }
        }
        
        return pChain;
    }
    
    public static Boolean canExpedite(Workstep__c ws){
        return ws.Workstep_Library__c == null || dateDrivenLibraries.get(ws.Workstep_Library__c) == null || String.isEmpty(dateDrivenLibraries.get(ws.Workstep_Library__c).Start_Date_Driving_Fields__c);
    }
    
    public static Boolean updatingSuccessors {get; private set;}
    public static void updateWorkstepSuccessors(Set<Id> wsIDs){
        if(updatingSuccessors == true) return;
        
        PredecessorChain predChain = getPredecessorChain(wsIDs);
        Map<Id, Workstep__c> allWorksteps = new Map<Id, Workstep__c>([SELECT Id
                                                                            ,Actual_Completion_Date__c
                                                                            ,Attribute__c
                                                                            ,CTP_Attribute__c
                                                                            ,CTP_Communication_Type__c
                                                                            ,Duration__c
                                                                            ,End_Date__c
                                                                            ,Lag__c
                                                                            ,Order__c
                                                                            ,SLA__c
                                                                            ,Start_Date__c
                                                                            ,Status__c
                                                                            ,Sub_Order__c
                                                                            ,Unblocked_Date__c
                                                                            ,Workstep_Library__c
                                                                            ,Name
                                                                            FROM Workstep__c WHERE Workstep__c.Id IN :predChain.AllWorkstepLevels.keyset()]);
        
        Map<Id, Order__c> oMap = new Map<Id, Order__c>();
        Map<Id, Sub_Order__c> soMap = new Map<Id, Sub_Order__c>();
        for(Workstep__c ws : allWorksteps.values()){
            oMap.put(ws.Order__c, null);
            if(ws.Sub_Order__c != null) soMap.put(ws.Sub_Order__c, null);
        }
        
        Set<Id> ids = oMap.keyset();
        oMap = new Map<Id, Order__c>((List<Order__c>)Database.query('select ' + SchemaUtils.RetrieveFullObjectFields(Order__c.getsObjectType()) + ' from Order__c where Id in: ids'));
        ids = soMap.keyset();
        soMap = new Map<Id, Sub_Order__c>((List<Sub_Order__c>)Database.query('select ' + SchemaUtils.RetrieveFullObjectFields(Sub_Order__c.getsObjectType()) + ' from Sub_Order__c where Id in: ids'));
        
        //Now run through relations and update any successors
        Map<Id, Workstep__c> soDateDriven = new Map<Id, Workstep__c>();
        Map<Id, Workstep__c> updateSuccessors = new Map<Id, Workstep__c>();
        Map<Integer, Set<Id>> rMap = predChain.GetReversedWorkstepLevelMap();
        
        Set<Id> updatedPending = new Set<Id>();
        
        for(Integer lvl : rMap.keyset()){
            for(Id wsID : rMap.get(lvl)){
                Workstep__c ws = allWorksteps.get(wsID);
                String status = ws.Status__c;
                Date startDate = ws.Start_Date__c;
                Date endDate = ws.End_Date__c;
                Date unblockDate = null;
                if(ws.Unblocked_Date__c != null) unblockDate = ws.Unblocked_Date__c;
                if(ws.Sub_Order__c != null) recalculateAttributeWorkstep(ws, soMap.get(ws.Sub_Order__c), soDateDriven, false);
                else if(ws.Order__c != null) recalculateOrderAttributeWorkstep(ws, oMap.get(ws.Order__c), soDateDriven, false);
                
                Boolean dateDetermined = soDateDriven.containsKey(ws.Id);
                List<Predecessor__c> pList = predChain.PredecessorMap.get(wsID);
                
                Set<String> predStatus = new Set<String>();
                Map<Id, Workstep__c> pWSMap = getPredecessorMapping(allWorksteps, pList, predStatus);
                
                //If pending and there are either no preds or all preds are Complete update the status
                if(ws.Status__c == STATUS_PENDING && (pWSMap.size() == 0 || (predStatus.size() == 1 && predStatus.contains(STATUS_COMPLETE)))){
                    ws.Status__c = (ws.Duration__c == 0 && pWSMap.size() > 0) ? STATUS_COMPLETE : STATUS_OPEN;
                    if(ws.Status__c == STATUS_OPEN && ws.Workstep_First_Opened_Date__c == null)
                        ws.Workstep_First_Opened_Date__c = DateTime.now();
                    updatedPending.add(ws.Id);
                }
                
                if(!dateDetermined){
                    Workstep__c maxWS = getMaxWorkstep(pWSMap.values());
                    if(maxWS != null || unblockDate != null){
                        Date predEndDate = (maxWS != null) ? ((maxWS.Status__c == STATUS_COMPLETE && maxWS.Actual_Completion_Date__c != null) ? maxWS.Actual_Completion_Date__c : maxWS.End_Date__c) : null;
                        if(predEndDate != null || unblockDate != null){
                            WorkstepDates newDates = (unblockDate != null && predEndDate != null)
                                                                                ? (unblockDate > predEndDate ? calculateSuccessorDates(unblockDate,(Integer)ws.SLA__c, (Integer)ws.Lag__c) : calculateSuccessorDates(predEndDate,(Integer)ws.Duration__c, (Integer)ws.Lag__c))
                                                                                : (unblockDate != null ? calculateSuccessorDates(unblockDate,(Integer)ws.SLA__c, (Integer)ws.Lag__c) : calculateSuccessorDates(predEndDate,(Integer)ws.Duration__c, (Integer)ws.Lag__c));
                            ws.Start_Date__c = newDates.StartDate;
                            ws.End_Date__c = newDates.EndDate;
                        }
                    }
                }
                
                if(ws.Status__c != status || ws.Start_Date__c != startDate || ws.End_Date__c != endDate){
                    updateSuccessors.put(ws.Id, ws);
                }
            }
        }
        
        updatingSuccessors = true;
        if(updateSuccessors.size() > 0){
            
            //If we are attempting to update the statuses of one or more worksteps, we save in a "test" state first, rollback and fix any errors
            if(updatedPending.size() > 0){
                List<Workstep__c> wsList = updateSuccessors.values();
                
                Savepoint sp = Database.setSavepoint();
                WorkstepTriggers.validateMode = true;
                List<Database.UpsertResult> upsertResults = SecurityUtils.BypassProcesser.saveObjects(wsList, false);
                WorkstepTriggers.validateMode = false;
                
                Set<Id> failed = new Set<Id>();
                for(Integer i=0; i<wsList.size(); i++){
                    if(!upsertResults[i].isSuccess()) failed.add(wsList[i].Id);
                }
                Database.rollback(sp);
                
                for(Integer lvl : rMap.keyset()){
                    for(Id wsID : rMap.get(lvl)){
                        if(updatedPending.contains(wsID)){
                            Workstep__c ws = allWorksteps.get(wsID);
                            ws.Status__c = STATUS_PENDING;
                            
                            List<Predecessor__c> pList = predChain.PredecessorMap.get(wsID);
                            Set<String> predStatus = new Set<String>();
                            Map<Id, Workstep__c> pWSMap = getPredecessorMapping(allWorksteps, pList, predStatus);
                            
                            //Apply complete only if the original criteria passes but do not complete if it failed to save
                            if(pWSMap.size() == 0 || (predStatus.size() == 1 && predStatus.contains(STATUS_COMPLETE)))
                                ws.Status__c = (!failed.contains(ws.Id) && ws.Duration__c == 0 && pWSMap.size() > 0) ? STATUS_COMPLETE : STATUS_OPEN;
                        }
                    }
                }
            }
            
            //Do the full save
            SecurityUtils.BypassProcesser.saveObjects(updateSuccessors.values(), false);
        }
        updatingSuccessors = false;
    }
    
    private static Map<Id, Workstep__c> getPredecessorMapping(Map<Id, Workstep__c> allWorksteps, List<Predecessor__c> pList, Set<String> predStatus){
        Map<Id, Workstep__c> pWSMap = new Map<Id, Workstep__c>();
        for(Predecessor__c p : pList != null ? pList : new List<Predecessor__c>()){
            Workstep__c pWs = allWorksteps.get(p.Predecessor_Workstep__c);
            if(pWs != null){
                pWSMap.put(p.Predecessor_Workstep__c, pWs);
                if(pWs.Status__c != null) predStatus.add(pWs.Status__c);
            }
        }
        return pWSMap;
    }
    
    private static Workstep__c getMaxWorkstep(List<Workstep__c> wsList){
        //Must handle null dates as comparisons for dates where 1 is null don't work otherwise
        Workstep__c result = null;
        Date maxDate = null;
        for(Workstep__c ws : (wsList != null) ? wsList : new List<Workstep__c>()){
            Date d = (ws.Status__c == 'Complete' && ws.Actual_Completion_Date__c  != null) ? ws.Actual_Completion_Date__c  : ws.End_Date__c;
            
            if(result == null || d > maxDate){
                maxDate = d;
                result = ws;
            }
        }
        
        return result;
    }
    
    //New simplifyed date calulator
    public static WorkstepDates calculateSuccessorDates(Date predecessorsEndDate, Integer duration, Integer lag){
        WorkstepDates result = new WorkstepDates();
        
        //Get the holidays
        Set<Date> holidayRSDs = new Set<Date>();
        for (Holiday h : AllHolidays) holidayRSDs.add(h.RecurrenceStartDate);
        
        //The successors start date is it's predecessors end date
        //If there is lag then those days will be need to added to start date
        if(lag > 0){
            Integer i = 1;
            do {    //Set condition for validate the Next Day is a workable Date;
                Boolean isValidDate = false;
                do{
                    predecessorsEndDate = predecessorsEndDate.addDays(1);
                    isValidDate = predecessorsEndDate != predecessorsEndDate.toStartOfWeek() && predecessorsEndDate != (predecessorsEndDate.toStartOfWeek() + 6) && !holidayRSDs.contains(predecessorsEndDate);
                }while(!isValidDate);
                i++;
            }while(i <= lag);
            result.StartDate = predecessorsEndDate;
        }
        else result.StartDate = predecessorsEndDate;
        
        //the end date will be the start date plus duration
        if(duration > 0){
            Date EndDate = result.StartDate;
            Integer i = 1;
            do {    //Set condition for validate the Next Day is a workable Date;
                Boolean isValidDate = false;
                do{
                    EndDate = EndDate.addDays(1);
                    isValidDate = (EndDate != EndDate.toStartOfWeek() && EndDate != (EndDate.toStartOfWeek() + 6) && !holidayRSDs.contains(EndDate));
                }while(!isValidDate);
                i++;
            }while(i <= duration);
            result.EndDate = EndDate;
        }
        else result.EndDate = result.StartDate;

        return result;
    }
    
    public static Date calculateFirstDate(Date currentDate, Integer durationDays, boolean isStartDate){
        return calculateRelativeDate(currentDate, durationDays, isStartDate, false);
    }
    
    public static Date calculateAfterDate(Date currentDate, Integer durationDays, boolean isStartDate){
        return calculateRelativeDate(currentDate, durationDays, isStartDate, true);
    }
    
    private static Date calculateRelativeDate(Date currentDate, Integer durationDays, boolean isStartDate, Boolean afterMode){
        Set<Date> holidayRSDs = new Set<Date>();
        for (Holiday h : AllHolidays) holidayRSDs.add(h.RecurrenceStartDate);
        
        Date futureDate = currentDate;
        if(futureDate != null){
            Integer i = 0;
            if(isStartDate){
                Integer max = afterMode ? 0 : durationDays;
                while(i <= max){
                    if(afterMode) currentDate = currentDate.addDays(1);     //Increment first
                    
                    if(currentDate != currentDate.toStartOfWeek() && currentDate != (currentDate.toStartOfWeek() + 6) && !holidayRSDs.contains(currentDate)){
                        futureDate = currentDate;
                        i++;
                    }
                    
                    if(!afterMode) currentDate = currentDate.addDays(1);    //Increment last
                }
            }
            
            if(afterMode){
                i = (durationDays > 0) ? 1 : ((durationDays == 0) ? 0 : -1);
                while((((i <= durationDays && durationDays > 0) || (i >= durationDays && durationDays < 0)) && isStartDate) || (i < durationDays && durationDays > 0 && !isStartDate)){
                    currentDate = currentDate.addDays((durationDays > 0 ? 1 : -1));
                    
                    if(currentDate != currentDate.toStartOfWeek() && currentDate != (currentDate.toStartOfWeek() + 6) && !holidayRSDs.contains(currentDate)){
                        futureDate = currentDate;
                        i = (durationDays > 0 ? i + 1 : i - 1);
                    }
                }
            }
        }
        return futureDate;
    }
    
    public static void recalculatePDD(Set<Id> subOrderIDs){
        if(subOrderIDs.size() > 0){
            List<Sub_Order__c> subOrdersList = [SELECT Id
                                                        ,Projected_Due_Date__c
                                                        ,Order__r.RecordType.DeveloperName
                                                        ,(select
                                                            Status__c
                                                            ,Actual_Completion_Date__c
                                                            ,End_Date__c
                                                            from Worksteps__r
                                                            where Name = :SEND_TO_BILLING)
                                                        FROM Sub_Order__c WHERE Id IN :subOrderIDs];
            
            //Changing the rules to have PDD match the end date of Send To Billing
            List<Sub_Order__c> modifiedSubOrdersList = new List<Sub_Order__c>();
            for (Sub_Order__c so :subOrdersList){                   
                Workstep__c maxWS = getMaxWorkstep(so.Worksteps__r);
                if(maxWS != null){
                    Date d = (maxWS.Status__c == 'Complete') ? maxWS.Actual_Completion_Date__c : maxWS.End_Date__c;
                    
                    DateTime maxEndDate = (d != null) ? DateTime.newInstance(d.year(), d.month(), d.day(), 17, 0, 0) : null;
                    if(so.Projected_Due_Date__c != maxEndDate){
                        so.Projected_Due_Date__c = maxEndDate;
                        modifiedSubOrdersList.add(so);
                    }
                }
            }
            if(modifiedSubOrdersList.size() > 0) SecurityUtils.BypassProcesser.saveObjects(modifiedSubOrdersList, false);
        }
    }
    
    public static void recalculatePNR(Set<Id> OrderIDs){
        if(OrderIDs.size() > 0){
            List<Workstep__c> OrdersList = [SELECT Id
                                            ,Status__c
                                            ,End_Date__c
                                            ,Order__r.Projected_Network_Ready_Date__c
                                            ,Order__r.Id
                                    FROM Workstep__c WHERE Order__c IN :OrderIDs AND Name = :APPLY_REDLINES];
            
            //Changing the rules to have PNR match the end date of APPLY_REDLINES
            List<Order__c> modifiedOrdersList = new List<Order__c>();
            for (Workstep__c ord :OrdersList){
                ord.Order__r.Projected_Network_Ready_Date__c = ord.End_Date__c;
                modifiedOrdersList.add(ord.Order__r);
            }
            if(modifiedOrdersList.size() > 0) SecurityUtils.BypassProcesser.saveObjects(modifiedOrdersList, false);
        }
    }
    
    private static Map<String, Boolean> waTemplateMap;
    private static Map<String, Boolean> getAttributeTemplateMapping(){
        if(waTemplateMap == null){
            waTemplateMap = new Map<String, Boolean>();
            for (Workstep_Attribute_Configuration__c c : Workstep_Attribute_Configuration__c.getall().values())
                waTemplateMap.put(c.Name.toLowerCase(), c.Template_Attribute__c);
        }
        return waTemplateMap;
    }
    
    private static Map<String, Boolean> compressibilityMap;
    public static Map<String, Boolean> getAttributesCompressibility(){
        if(compressibilityMap == null){
            compressibilityMap = new Map<String, Boolean>();
            for (Workstep_Attribute_Configuration__c c : Workstep_Attribute_Configuration__c.getall().values())
                compressibilityMap.put(c.Name.toLowerCase(), c.Compressible__c);
        }
        return compressibilityMap;
    }
    
    public static void createWorksteps(List<Order__c> orders){
        List<Workplan_Template__c> wpt = new List<Workplan_Template__c>();
        Id rtBuildOrderId = Schema.Sobjecttype.Order__c.getRecordTypeInfosByName().get('Build Order').getRecordTypeId();
        Id rtDecommOrderId = Schema.Sobjecttype.Order__c.getRecordTypeInfosByName().get('Decomm Order').getRecordTypeId();
        
        if(orders.size() > 0 && rtBuildOrderId == orders[0].RecordTypeId)
            wpt = [SELECT Id FROM Workplan_Template__c WHERE Active__c = true AND Name = 'Standard Build' limit 1];
        else if(orders.size() > 0 && rtDecommOrderId == orders[0].RecordTypeId && orders[0].OSP_Required__c == true)
            wpt = [SELECT Id FROM Workplan_Template__c WHERE Active__c = true AND Name = 'Standard Build Decommission' limit 1];
        else if(orders.size() > 0 && rtDecommOrderId == orders[0].RecordTypeId && orders[0].OSP_Required__c == false)
            wpt = [SELECT Id FROM Workplan_Template__c WHERE Active__c = true AND Name = 'Build Decommission - no OSP' limit 1];
        else wpt = [SELECT Id FROM Workplan_Template__c WHERE Active__c = true AND RecordType.DeveloperName = 'Order' limit 1];
        
        if(wpt.size() > 0){
            List<Workstep_Template__c> wstList = [SELECT Id, Name, Workstep_Library__c, OwnerId, Workstep_Library__r.Attribute__c, Workstep_Library__r.Milestone__c,
                                                    Workstep_Library__r.Work_Group__c, Non_Access_Duration__c, Non_Access_Lag__c, Non_Access_SLA__c
                                                    ,(select Order__c from Worksteps__r where Order__c IN: orders)
                                                    FROM Workstep_Template__c WHERE Workplan_Template__c = :wpt[0].Id];
            
            Map<String, Boolean> wtMap = getAttributeTemplateMapping();
            
            List<Workstep__c> wsList = new List<Workstep__c>();
            for (Order__c o : orders){
                for (Workstep_Template__c wst : wstList){
                    Boolean wsExists = false;
                    for(Workstep__c existing : wst.Worksteps__r != null ? wst.Worksteps__r : new List<Workstep__c>())
                        wsExists = wsExists || existing.Order__c == o.Id;
                    
                    if(wsExists) continue;
                    
                    String attr = wst.Workstep_Library__r.Attribute__c != null ? wst.Workstep_Library__r.Attribute__c.toLowercase() : '';
                    if(o.TOV_Needed__c || (!o.TOV_Needed__c && (wst.Name != TECHNICAL_ORDER_VALIDATION && wst.Name != TECHNICAL_SHEET_CREATION))){
                        wsList.add(new Workstep__c(Order__c = o.Id
                                ,Name = wst.Name
                                ,Workstep_Library__c = wst.Workstep_Library__c
                                ,OwnerId = wst.OwnerId != UnassignedUser ? wst.OwnerId : o.OwnerId
                                ,Status__c = STATUS_PENDING
                                ,Milestone__c = wst.Workstep_Library__r.Milestone__c
                                ,Work_Group__c = wst.Workstep_Library__r.Work_Group__c
                                ,Duration__c = wst.Non_Access_Duration__c
                                ,Lag__c = wst.Non_Access_Lag__c
                                ,SLA__c = wst.Non_Access_SLA__c
                                ,Template__c = wst.Id
                                ,Attribute__c = wtMap.get(attr) == true ? wst.Workstep_Library__r.Attribute__c : null));
                    }
                }
            }
            
            if(wsList.size() > 0){
                insert wsList;
                createPredecessors(wsList, (new Map<Id, Workstep_Template__c>(wstList)).keyset());
            }
            
            List<Order__c> tOrder = new List<Order__c>();
            for(Order__c o : orders){
                if(rtBuildOrderId == o.RecordTypeId && (o.Building_CLLI__c == null && o.action__c != 'Remove'))
                    tOrder.add(o);
            }           
            if(tOrder.size() > 0){
                //Now update the durations on the Obtain CLLI Code worksteps
                List<Workstep__c> wsUpdated = new List<Workstep__c>();
                for(Workstep__c ws : [select Id, Name, Duration__c, SLA__c from Workstep__c where Name =: OBTAIN_CLLI_CODE AND Order__c IN: tOrder]){
                    ws.Duration__c = 2;
                    ws.SLA__c = 2;
                    wsUpdated.add(ws);
                }
                if(wsUpdated.size() > 0) update wsUpdated;
            }
        }
    }
    
    @future (callout=false)
    public static void createOrderWorkstepForContractSigned(Set<Id> opps){
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Opportunity> tovOpps = new Map<Id, Opportunity>();
        for(OpportunityLocationConfiguration__c sol : [Select Id, OpportunityId__c,
                                                        (Select PP_Product_Pricing_Name__c, PP_Sales_Product__c, Opportunity__c From Opportunity_Line_Items__r
                                                        WHERE PP_Sales_Product__c =: VPN_SOLUTIONS
                                                        OR PP_Sales_Product__c =: CLOUD_FIREWALL_SERVICE
                                                        OR PP_Sales_Product__c =: UC_CLOUD_VOICE_MS
                                                        OR PP_Sales_Product__c =: UC_CLOUD_VOICE_RS
                                                        OR PP_Sales_Product__c =: VPLS
                                                        OR (PP_Sales_Product__c =: SIP_SOLUTIONS AND PP_Product_Pricing_Name__c Like : 'SIP Trunking Sessions%')
                                                        OR (PP_Sales_Product__c =: DEDICATED_INTERNET AND PP_Product_Pricing_Name__c Like : 'Managed Router%'))
                                                        From OpportunityLocationConfiguration__c
                                                        WHERE Opportunity_Location__r.Order__r.Opportunity__c in : opps AND Active__c = true]){
            if(sol.Opportunity_Line_Items__r.size() > 0) oppIds.add(sol.OpportunityId__c);
        }
        
        //once all match opps are in list do this to create tov.
        List<Order__c> orders = new List<Order__c>();
        for(Order__c ord : [select id from order__c where opportunity__c in :oppIds]) orders.add(ord);
        
        List<Workstep__c> wsList = new List<Workstep__c>();
        Map<Id, Workstep_Template__c> wstMap = new Map<Id, Workstep_Template__c>();
        if(orders.size() > 0){
            wstMap = new Map<Id, Workstep_Template__c>([SELECT Id, Name, Workstep_Library__c, OwnerId, Workstep_Library__r.Attribute__c, Workstep_Library__r.Milestone__c,
                                                        Workstep_Library__r.Work_Group__c, Non_Access_Duration__c, Non_Access_Lag__c, Non_Access_SLA__c
                                                        ,(select Order__c from Worksteps__r where Order__c IN: orders)
                                                        FROM Workstep_Template__c WHERE Name =: TECHNICAL_ORDER_VALIDATION OR Name =: TECHNICAL_SHEET_CREATION]);
            
            for (Order__c o : orders){
                for (Workstep_Template__c wst : wstMap.values()){
                    Boolean wsExists = false;
                    for(Workstep__c existing : wst.Worksteps__r != null ? wst.Worksteps__r : new List<Workstep__c>())
                    wsExists = wsExists || existing.Order__c == o.Id;
                    
                    if(wsExists) continue;
                    
                    String attr = wst.Workstep_Library__r.Attribute__c != null ? wst.Workstep_Library__r.Attribute__c.toLowercase() : '';
                    wsList.add(new Workstep__c(Order__c = o.Id
                                ,Name = wst.Name
                                ,Workstep_Library__c = wst.Workstep_Library__c
                                ,OwnerId = wst.OwnerId != UnassignedUser ? wst.OwnerId : o.OwnerId
                                ,Status__c = wst.Name == TECHNICAL_ORDER_VALIDATION ? STATUS_PENDING : STATUS_OPEN
                                ,Milestone__c = wst.Workstep_Library__r.Milestone__c
                                ,Work_Group__c = wst.Workstep_Library__r.Work_Group__c
                                ,Duration__c = wst.Non_Access_Duration__c
                                ,Lag__c = wst.Non_Access_Lag__c
                                ,SLA__c = wst.Non_Access_SLA__c
                                ,Template__c = wst.Id));
                }
            }
        }
        
        if(wsList.size() > 0){
            insert wsList;
            createPredecessors(wsList, wstMap.keyset());
            //fix tov status after creating Predecessors
            for(Workstep__c ws : wsList){
                if(ws.Name == TECHNICAL_ORDER_VALIDATION) ws.Status__c = 'Pending';
                update ws;
            }
        }
    }
    
    public static void createWorksteps(Map<Id, Sub_Order__c> updated){
        
        Set<Id> oId = new Set<Id>();
        for(Sub_Order__c sOwn : updated.values()) oId.add(sOwn.Order__c);
        Map<Id, Order__c> ordOwnerMap =  new Map<Id, Order__c>([Select Id, OwnerId From Order__c WHERE ID IN : oId]);
        
        Set<Id> accessTypesSet = new Set<Id>();
        Set<String> provProducts = new Set<String>();
        
        //Need to get the Provisioning Product to determine the Workplan that will be created
        Map<Id, Order_Property__c> oProps = new Map<Id, Order_Property__c>();
        for (Sub_Order__c so : updated.values()){
            provProducts.add(so.Provisioning_Product__c);
            if(so.Access_Types__c != null) accessTypesSet.add(so.Access_Types__c);
            if(so.External_Order__c != null) oProps.put(so.External_Order__c, null);
        }
        
        Map<Id, Workstep_Template__c> wstMap = new Map<Id, Workstep_Template__c>([SELECT Id, Name, Milestone__c, Non_Access_Duration__c, Non_Access_Lag__c, Non_Access_SLA__c, Workplan_Template__r.Provisioning_Product__c, Workstep_Library__c,
                                                                                OwnerId, Workstep_Library__r.Milestone__c, Workstep_Library__r.Work_Group__c, Workstep_Library__r.Attribute__c
                                                                                ,(select Order__c, Sub_Order__c, Order__r.OwnerId, Access_Types__c from Worksteps__r where Sub_Order__c IN: updated.keyset())
                                                                                FROM Workstep_Template__c WHERE Workplan_Template__r.Provisioning_Product__c IN :provProducts AND
                                                                                Workplan_Template__r.Active__c = true]);
        
        List<Workstep__c> wsList = new List<Workstep__c>();
        Map<String, Map<Id, Access_Duration__c>> accessDurationMap = getAccessDurationMap(accessTypesSet);
        Map<String, Map<Id, Feature_Duration__c>> featureDurationMap = getFeatureDurationMap(updated.keyset());
        
        Map<String, Boolean> wtMap = getAttributeTemplateMapping();
        
        for (Sub_Order__c so : updated.values()){
            Map<Id, Access_Duration__c> accessDurMap = so.Access_Types__c != null ? accessDurationMap.get(so.Access_Types__c) : new Map<Id, Access_Duration__c>();
            Map<Id, Feature_Duration__c> featureDurMap = featureDurationMap.get(so.Id) != null ? featureDurationMap.get(so.Id) : new Map<Id, Feature_Duration__c>();
            for (Workstep_Template__c wst : wstMap.values()){
                if(so.Provisioning_Product__c == wst.Workplan_Template__r.Provisioning_Product__c){
                    Boolean wsExists = false;
                    for(Workstep__c existing : wst.Worksteps__r != null ? wst.Worksteps__r : new List<Workstep__c>())
                        wsExists = wsExists || existing.Sub_Order__c == so.Id;
                    
                    if(wsExists) continue;
                    
                    String attr = wst.Workstep_Library__r.Attribute__c != null ? wst.Workstep_Library__r.Attribute__c.toLowercase() : '';
                    Order__c oM = ordOwnerMap.get(so.Order__c);
                    
                    Id ownerId = wst.OwnerId;
                    if(orderManager.get(wst.OwnerId)!=null && so.Order_Manager__c != null){
                        ownerId = so.Order_Manager__c;
                    }else if(deliveryManager.get(wst.OwnerId) != null && so.Delivery_Manager__c != null){
                        ownerId = so.Delivery_Manager__c;
                    }else if(orderEntry.get(wst.OwnerId) != null && so.Order_Entry_Rep__c != null){
                        ownerId = so.Order_Entry_Rep__c;
                    }else if(wst.OwnerId != UnassignedUser){
                        ownerID = wst.OwnerId;
                    }else{
                        ownerId = (oM != null) ? oM.OwnerId : null;
                    }
                    
                    Workstep__c ws = new Workstep__c(Sub_Order__c = so.Id
                                                    ,Order__c = so.Order__c
                                                    ,Provisioning_Product__c = so.Provisioning_Product__c
                                                    ,Name = wst.Name
                                                    ,Workstep_Library__c = wst.Workstep_Library__c
                                                    //,OwnerId = wst.OwnerId != UnassignedUser ? wst.OwnerId : ((oM != null) ? oM.OwnerId : null)
                                                    ,OwnerId = ownerId                                                  
                                                    ,Status__c = 'Pending'
                                                    ,Milestone__c = wst.Workstep_Library__r.Milestone__c
                                                    ,Work_Group__c = wst.Workstep_Library__r.Work_Group__c
                                                    ,Duration__c = wst.Non_Access_Duration__c
                                                    ,Lag__c = wst.Non_Access_Lag__c
                                                    ,SLA__c = wst.Non_Access_SLA__c
                                                    ,Template__c = wst.Id
                                                    ,Attribute__c = wtMap.get(attr) == true ? wst.Workstep_Library__r.Attribute__c : null);

                    calculateRelatedOffsets(ws, wst, accessDurMap, featureDurMap);
                    recalculateAttributeWorkstep(ws, so, null, false);
                    
                    wsList.add(ws);
                }
            }
        }
        
        if(oProps.size() > 0){
            oProps = new Map<Id, Order_Property__c>([select Order__c, Order__r.OwnerId, Order_Actions__c from Order_Property__c where Id in: oProps.keyset() and Order_Actions__c != null]);
            
            Map<Id, Set<String>> orderWSTs = new Map<Id, Set<String>>();
            Set<String> actions = new Set<String>();
            for(Order_Property__c p : oProps.values()){
                actions.addAll(p.Order_Actions__c.split(';'));
                
                Set<String> s = orderWSTs.get(p.Order__c) != null ? orderWSTs.get(p.Order__c) : new Set<String>();
                s.addAll(p.Order_Actions__c.split(';'));
                orderWSTs.put(p.Order__c, s);
            }
            if(actions.size() > 0){
                Map<String, Workstep_Template__c> wstAttrMap = new Map<String, Workstep_Template__c>();
                for(Workstep_Template__c wst : [SELECT Id, Name, Workstep_Library__c, OwnerId, Workstep_Library__r.Attribute__c, Workstep_Library__r.Milestone__c,
                                                            Workstep_Library__r.Work_Group__c, Non_Access_Duration__c, Non_Access_Lag__c, Non_Access_SLA__c
                                                            FROM Workstep_Template__c WHERE Workstep_Library__r.Attribute__c IN :actions]){
                    wstAttrMap.put(wst.Workstep_Library__r.Attribute__c, wst);
                }
                
                for(Id orderID : orderWSTs.keyset()){
                    for(String att : orderWSTs.get(orderID)){
                        Boolean exists = false;     //todo: how do we determine its already there?
                        
                        Workstep_Template__c wst = wstAttrMap.get(att);
                        if(!exists && wst != null){
                            String attr = wst.Workstep_Library__r.Attribute__c != null ? wst.Workstep_Library__r.Attribute__c.toLowercase() : '';
                            wsList.add(new Workstep__c(Order__c = orderID
                                                        ,Name = wst.Name
                                                        ,Workstep_Library__c = wst.Workstep_Library__c
                                                        ,OwnerId = wst.OwnerId
                                                        ,Status__c = 'Pending'
                                                        ,Milestone__c = wst.Workstep_Library__r.Milestone__c
                                                        ,Work_Group__c = wst.Workstep_Library__r.Work_Group__c
                                                        ,Duration__c = wst.Non_Access_Duration__c
                                                        ,Lag__c = wst.Non_Access_Lag__c
                                                        ,SLA__c = wst.Non_Access_SLA__c
                                                        ,Template__c = wst.Id
                                                        ,Attribute__c = wtMap.get(attr) == true ? wst.Workstep_Library__r.Attribute__c : null));
                        }
                    }
                }
            }
        }
        if(wsList.size() > 0){
            insert wsList;
            createPredecessors(wsList, wstMap.keyset());
        }
    }
    
    public static void updateOrderWorksteps(Map<Id, Order__c> updated){
        Map<Id, String> features = new Map<Id, String>();
        List<Order__c> orders = new List<Order__c>();
        List<Workstep__c> wsList = new List<Workstep__c>();
        Map<String, Map<Id, Feature_Duration__c>> featureDurationMap = new Map<String, Map<Id, Feature_Duration__c>>();
        if(updated.size() > 0){
            for(Order__c feat : updated.values()){
                if(!string.isEmpty(feat.Features__c)) features.put(feat.Id, feat.Features__c);
            }
            
            if(features.size() > 0) featureDurationMap = getFeatureDurationMap(features);
            
            Map<Id, Access_Duration__c> accessDurMap =  new Map<Id, Access_Duration__c>();
            
            List<Workplan_Template__c> wpt = new List<Workplan_Template__c>();
            Id rtBuildOrderId = Schema.Sobjecttype.Order__c.getRecordTypeInfosByName().get('Build Order').getRecordTypeId();
            Id rtDecommOrderId = Schema.Sobjecttype.Order__c.getRecordTypeInfosByName().get('Decomm Order').getRecordTypeId();
            for(Order__c oUpdate : updated.values()){
                if(rtBuildOrderId == oUpdate.RecordTypeId)
                    wpt = [SELECT Id FROM Workplan_Template__c WHERE Active__c = true AND Name = 'Standard Build' limit 1];
                else if(rtDecommOrderId == oUpdate.RecordTypeId && oUpdate.OSP_Required__c)
                    wpt = [SELECT Id FROM Workplan_Template__c WHERE Active__c = true AND Name = 'Standard Build Decommission' limit 1];
                else if(rtDecommOrderId == oUpdate.RecordTypeId && !oUpdate.OSP_Required__c)
                    wpt = [SELECT Id FROM Workplan_Template__c WHERE Active__c = true AND Name = 'Build Decommission - no OSP' limit 1];
            }

            Map<Id, Workstep_Template__c> wstMap = new Map<Id, Workstep_Template__c>([SELECT Id, Name, Milestone__c, Non_Access_Duration__c, Non_Access_Lag__c, Non_Access_SLA__c, Workplan_Template__r.Provisioning_Product__c, Workstep_Library__c,
                                                                                        OwnerId, Workstep_Library__r.Milestone__c, Workstep_Library__r.Work_Group__c, Workstep_Library__r.Attribute__c
                                                                                        ,(select Id, Order__c, Sub_Order__c, Name, Workstep_Library__c, Status__c, Order__r.OwnerId, Access_Types__c,
                                                                                        Milestone__c, Work_Group__c, Duration__c, Lag__c, SLA__c, Template__c from Worksteps__r where Order__c IN: updated.keyset())
                                                                                        FROM Workstep_Template__c WHERE Workplan_Template__c = :wpt[0].Id AND
                                                                                        Workplan_Template__r.Active__c = true]);
            
            for(Order__c oUpdate : updated.values()){
                Set<Workstep__c> sTemp = new Set<Workstep__c>();
                for(Workstep_Template__c wst : wstMap.values()){
                    Map<Id, Feature_Duration__c> featureDurMap = featureDurationMap.get(wst.Workstep_Library__c) != null ? featureDurationMap.get(wst.Workstep_Library__c) : new Map<Id, Feature_Duration__c>();
                    if(wst.Worksteps__r.size() > 0){
                        calculateRelatedOffsets(wst.Worksteps__r, wst, accessDurMap, featureDurMap);
                        wsList.add(wst.Worksteps__r);
                    }
                }
            }
            if(wsList.size() > 0) update wsList;
        }
    }
    
    private static Map<String, Map<Id, Feature_Duration__c>> getFeatureDurationMap(Map<Id, String> newFeatures){
        Set<String> features = new Set<String>();
        Map<Id, Set<Id>> sFeatures = new Map<Id, Set<Id>>();
        for(string p : newFeatures.values()) features.addAll(p.split(';'));
        
        Map<String, Id> orderFeatures = new Map<String, Id>();
        for (Feature__c oFeature : [SELECT Id, Name FROM Feature__c WHERE Name IN : features])
            orderFeatures.put(oFeature.Name, oFeature.Id);
        
        Map<String, Map<Id, Feature_Duration__c>> featureDurationMap = new Map<String, Map<Id, Feature_Duration__c>>();
        for(Feature_Duration__c fd : [SELECT Id, Feature__c, Workstep_Library__c, Duration__c, Lag__c, SLA__c FROM Feature_Duration__c WHERE Feature__c IN : orderFeatures.values()]){
            for(Id oID : orderFeatures.values()){
                if(fd.Feature__c == oID){
                    Map<Id, Feature_Duration__c> m = featureDurationMap.get(oID) != null ? featureDurationMap.get(oID) : new Map<Id, Feature_Duration__c>();
                    Feature_Duration__c pfd = m.get(fd.Workstep_Library__c);
                    if(pfd == null || pfd.Duration__c < fd.Duration__c) m.put(fd.Workstep_Library__c, fd);
                    if(m.size() > 0) featureDurationMap.put(fd.Workstep_Library__c, m);
                }
            }
        }
        
        return featureDurationMap;
    }
    
    public static List<Workstep__c> calculateRelatedWorkstepOffsets(Set<Id> soIDs){
        Map<Id, Sub_Order__c> soMap = new Map<Id, Sub_Order__c>((List<Sub_Order__c>)Database.query('select ' + SchemaUtils.RetrieveFullObjectFields(Sub_Order__c.getsObjectType()) + ' from Sub_Order__c where Id in: soIDs'));
        List<Workstep__c> wsList = [SELECT Sub_Order__c, Duration__c, Lag__c, SLA__c, Workstep_Library__c, Workstep_Library__r.Non_Access_Duration__c, Workstep_Library__r.Non_Access_SLA__c, Workstep_Library__r.Non_Access_Lag__c, Template__c, Start_Date__c, End_Date__c FROM Workstep__c WHERE Sub_Order__c IN :soIDs];
        return calculateRelatedWorkstepOffsets(soMap, wsList);
    }
    
    public static List<Workstep__c> calculateRelatedWorkstepOffsets(Map<Id, Sub_Order__c> soMap, List<Workstep__c> wsList){
        Map<Id, Workstep__c> updateMap = new Map<Id, Workstep__c>();
        Map<Id, Workstep__c> wsc = new Map<Id, Workstep__c>();
        Set<Id> ats = new Set<Id>();
        for(Sub_Order__c so : soMap.values()){
            if(so.Access_Types__c != null) ats.add(so.Access_Types__c);
        }
        
        Map<Id, Workstep_Template__c> wstMap = new Map<Id, Workstep_Template__c>();
        Map<Id, List<Workstep__c>> wsMap = new Map<Id, List<Workstep__c>>();
        for(Workstep__c ws : wsList){
            List<Workstep__c> l = wsMap.get(ws.Sub_Order__c) != null ? wsMap.get(ws.Sub_Order__c) : new List<Workstep__c>();
            l.add(ws);
            wsMap.put(ws.Sub_Order__c, l);

            if(ws.Template__c != null) wstMap.put(ws.Template__c, null);
        }
        
        Map<String, Map<Id, Access_Duration__c>> accessDurationMap = getAccessDurationMap(ats);
        Map<String, Map<Id, Feature_Duration__c>> featureDurationMap = getFeatureDurationMap(soMap.keyset());
        wstMap = new Map<Id, Workstep_Template__c>([select Non_Access_Duration__c, Non_Access_Lag__c, Non_Access_SLA__c, Workstep_Library__c from Workstep_Template__c where Id in: wstMap.keyset()]);
        
        for (Sub_Order__c so : soMap.values()){
            Map<Id, Access_Duration__c> accessDurMap = so.Access_Types__c != null ? accessDurationMap.get(so.Access_Types__c) : new Map<Id, Access_Duration__c>();
            Map<Id, Feature_Duration__c> featureDMap = featureDurationMap.get(so.Id) != null ? featureDurationMap.get(so.Id) : new Map<Id, Feature_Duration__c>();
            for(Workstep__c ws : wsMap.get(so.Id) != null ? wsMap.get(so.Id) : new List<Workstep__c>()){
                //if we have no template, the duration remains the same as what's on the record
                if(ws.Template__c != null){
                    Double durationOld = ws.Duration__c;
                    Double lagOld = ws.Lag__c;
                    Double slaOld = ws.SLA__c;
                    
                    Workstep_Template__c wst = wstMap.get(ws.Template__c);
                    Access_Duration__c ad = accessDurMap.get(wst.Workstep_Library__c);
                    Feature_Duration__c fd = featureDMap.get(wst.Workstep_Library__c);
                    
                    ws.Duration__c = wst.Non_Access_Duration__c;
                    ws.lag__c = wst.Non_Access_Lag__c;
                    ws.sla__c = wst.Non_Access_SLA__c;
                    if(ad != null && (fd == null || fd.Duration__c < ad.Duration__c)){
                        ws.Duration__c = ad.Duration__c;
                        ws.lag__c = ad.Lag__c;
                        ws.sla__c = ad.SLA__c;
                    }
                    else if(fd != null){
                        ws.Duration__c = fd.Duration__c;
                        ws.lag__c = fd.Lag__c;
                        ws.sla__c = fd.SLA__c;
                    }
                    
                    if(durationOld != ws.Duration__c || lagOld != ws.Lag__c || slaOld != ws.SLA__c)
                        updateMap.put(ws.Id, ws);
                }
                recalculateAttributeWorkstep(ws, so, updateMap, true);
            }
        }
        
        return updateMap.values();
    }
    
    private static List<Workstep__c> combineAccessFeatures(List<Workstep__c> updated, List<Workstep__c> featureUpdated, Map<Id, Sub_Order__c> soMap, List<Workstep__c> wsList, Map<Id, Workstep_Template__c> wstMap){
        List<Workstep__c> updateList = new List<Workstep__c>();
        if(updated.size() > 0){
            if(featureUpdated.size() > 0){
                Map<String, Map<Id, Workstep__c>> soUpdates = new Map<String, Map<Id, Workstep__c>>();
                Map<Id, Workstep__c> accessUp = new Map<Id, Workstep__c>();
                for(Sub_Order__c so : soMap.values()){
                    
                    for (Workstep__c sf : updated){
                        if(so.Id == sf.Sub_Order__c){
                            accessUp.put(sf.Workstep_Library__c, sf);
                            soUpdates.put(so.Id, accessUp);
                        }
                    }
                    
                    for(Workstep__c fd : featureUpdated){
                        Map<Id, Workstep__c> step = soUpdates.get(so.Id) != null ? soUpdates.get(so.Id) : new Map<Id, Workstep__c>();
                        Workstep__c wac = step.get(fd.Workstep_Library__c);
                        if(wac != null && wac.Duration__c > fd.Duration__c && wac.Sub_Order__c == so.Id)
                            updateList.add(wac);
                        else if(fd.Sub_Order__c == so.Id)
                            updateList.add(fd);
                    }
                }
            }
            else updateList.addAll(updated);
        }
        else if(featureUpdated.size() > 0) updateList.addAll(featureUpdated);
        
        //Now take the updated list and find all worksteps not in that list and add those so that they are what they should be if user going back and forth
        //changing accesstypes and features repeatedly on same suborder.
        
        if(soMap.size() == 1){
            Map<Id, Workstep__c> updatedWSMap = new Map<Id, Workstep__c>();
            Map<Id, Workstep_Template__c> tempMap = new Map<Id, Workstep_Template__c>();
            for(Workstep__c sws : updateList) updatedWSMap.put(sws.Workstep_Library__c, sws);
            for(Workstep_Template__c wst : wstMap.values()) tempMap.put(wst.Workstep_Library__c, wst);
            for(Workstep__c ws : wsList){
                if(updatedWSMap.get(ws.Workstep_Library__c) == null){
                    Workstep_Template__c t = tempMap.get(ws.Workstep_Library__c);
                    ws.Duration__c = t.Non_Access_Duration__c;
                    ws.SLA__c = t.Non_Access_SLA__c;
                    ws.Lag__c = t.Non_Access_Lag__c;
                    updateList.add(ws);
                }
            }
        }
        return updateList;
    }
    
    private static void calculateRelatedOffsets(Workstep__c ws, Workstep_Template__c wst, Map<Id, Access_Duration__c> accessDurationMap, Map<Id, Feature_Duration__c> featureDurationMap){
        
        if(wst != null){
            ws.Duration__c = wst.Non_Access_Duration__c;
            ws.Lag__c = wst.Non_Access_Lag__c;
            ws.SLA__c = wst.Non_Access_SLA__c;
            
            Access_Duration__c ad = accessDurationMap.get(ws.Workstep_Library__c);
            if(ad != null){
                ws.Access_Types__c = ad.Access_Types__c;
                ws.Duration__c = ad.Duration__c;
                ws.Lag__c = ad.Lag__c;
                ws.SLA__c = ad.SLA__c;
            }
            else ws.Access_Types__c = null;
            
            Feature_Duration__c fd = featureDurationMap.get(wst.Workstep_Library__c);
            if(fd != null){
                ws.Duration__c = fd.Duration__c;
                ws.Lag__c = fd.Lag__c;
                ws.SLA__c = fd.SLA__c;
            }
        }
    }
    
    private static void createPredecessors(List<Workstep__c> wsList, Set<Id> wstIDs){
        Map<Id, Map<Id, Id>> m = new Map<Id, Map<Id, Id>>();
        for(Workstep__c ws : wsList){
            if(ws.Template__c != null){
                Id pID = ws.Sub_Order__c != null ? ws.Sub_Order__c : ws.Order__c;
                Map<Id, Id> sm = m.get(pID) != null ? m.get(pID) : new Map<Id, Id>();
                sm.put(ws.Template__c, ws.Id);
                m.put(pID, sm);
            }
        }
        
        List<Predecessor__c> predList = new List<Predecessor__c>();
        Set<Id> wsIDs = new Set<Id>();
        for (Predecessor_Template__c pred : [SELECT Dependent_Workstep_Template__c, Predecessor_Workstep_Template__c, Task_Dependency_Type__c
                                                FROM Predecessor_Template__c WHERE Predecessor_Workstep_Template__c IN :wstIDs OR Dependent_Workstep_Template__c IN :wstIDs]){
                                                
            for(Id pID : m.keyset()){
                Id d = m.get(pID).get(pred.Dependent_Workstep_Template__c);
                Id p = m.get(pID).get(pred.Predecessor_Workstep_Template__c);
                
                if(d != null && p != null){
                    wsIds.add(d);
                    wsIds.add(p);
                    predList.add(new Predecessor__c(Dependent_Workstep__c = d
                                                ,Predecessor_Workstep__c = p
                                                ,Task_Dependency_Type__c = pred.Task_Dependency_Type__c));
                }
            }
        }
        
        if(predList.size() > 0){
            Boolean dtOld = PredecessorTriggers.DisableTrigger;
            PredecessorTriggers.DisableTrigger = true;
            insert predList;
            PredecessorTriggers.DisableTrigger = dtOld;
            WorkstepUtils.updateWorkstepSuccessors(wsIDs);
        }
    }
    
    private static Map<String, Map<Id, Access_Duration__c>> getAccessDurationMap(Set<Id> accessTypesSet){
        List<Access_Duration__c> accessDurationList = [SELECT Id, Access_Types__c, Workstep_Library__c, Duration__c, Lag__c, SLA__c from Access_Duration__c WHERE Access_Types__c IN :accessTypesSet];
        Map<String, Map<Id, Access_Duration__c>> accessDurationMap = new Map<String, Map<Id, Access_Duration__c>>();
        
        for (Access_Duration__c ad : accessDurationList){
            Map<Id, Access_Duration__c> m = accessDurationMap.get(ad.Access_Types__c) != null ? accessDurationMap.get(ad.Access_Types__c) : new Map<Id, Access_Duration__c>();
            m.put(ad.Workstep_Library__c, ad);
            accessDurationMap.put(ad.Access_Types__c, m);
        }
        return accessDurationMap;
    }

    private static Map<String, Map<Id, Feature_Duration__c>> getFeatureDurationMap(Set<Id> so){
        Map<Id, Set<Id>> subOrderFeatures = new Map<Id, Set<Id>>();
        for (Sub_Order_Feature__c sf : [SELECT Id, Feature__c, Sub_Order__c, Sub_Order__r.Customer_Commit_Date__c FROM Sub_Order_Feature__c WHERE Sub_Order__c IN :so]){
            Set<Id> s = subOrderFeatures.get(sf.Feature__c) != null ? subOrderFeatures.get(sf.Feature__c) : new Set<Id>();
            s.add(sf.Sub_Order__c);
            subOrderFeatures.put(sf.Feature__c, s);
        }
        
        Map<String, Map<Id, Feature_Duration__c>> featureDurationMap = new Map<String, Map<Id, Feature_Duration__c>>();
        for(Feature_Duration__c fd : [SELECT Id, Feature__c, Workstep_Library__c, Duration__c, Lag__c, SLA__c FROM Feature_Duration__c WHERE Feature__c IN : subOrderFeatures.keyset()]){
            for(Id soID : subOrderFeatures.get(fd.Feature__c)){
                Map<Id, Feature_Duration__c> m = featureDurationMap.get(soID) != null ? featureDurationMap.get(soID) : new Map<Id, Feature_Duration__c>();
                Feature_Duration__c pfd = m.get(fd.Workstep_Library__c);
                if(pfd == null || pfd.Duration__c < fd.Duration__c){
                    m.put(fd.Workstep_Library__c, fd);
                    featureDurationMap.put(soID, m);
                }
            }
        }
        return featureDurationMap;
    }
    
    private static void recalculateAttributeWorkstep(Workstep__c ws, Sub_Order__c so, Map<Id, Workstep__c> outMap, Boolean onlyAddUpdates){
        WorkstepDates d = new WorkstepDates();
             
        if(tryGetAttributeDates(ws, so, d) && d.EndDate != null && d.StartDate != null){
            Boolean updated = ws.Start_Date__c != d.StartDate || ws.End_date__c != d.EndDate;
            ws.Start_Date__c = d.StartDate;
            ws.End_date__c = d.EndDate;
            if(outMap != null && (!onlyAddUpdates || updated))
                outMap.put(ws.Id, ws);
        }
    }
    
    private static void recalculateOrderAttributeWorkstep(Workstep__c ws, Order__c ord, Map<Id, Workstep__c> outMap, Boolean onlyAddUpdates){
        WorkstepDates d = new WorkstepDates();
        
        if(tryGetAttributeDates(ws, ord, d) && d.EndDate != null && d.StartDate != null){
            Boolean updated = ws.Start_Date__c != d.StartDate || ws.End_date__c != d.EndDate;
            ws.Start_Date__c = d.StartDate;
            ws.End_date__c = d.EndDate;
            
            if(outMap != null && (!onlyAddUpdates || updated))
                outMap.put(ws.Id, ws);
        }
    }
    
    /* Date driven functionality */
    private static Map<Id, Workstep_Library__c> p_dateDrivenLibraries = null;
    public static Map<Id, Workstep_Library__c> dateDrivenLibraries{
        get{
            if(p_dateDrivenLibraries == null) p_dateDrivenLibraries = new Map<Id, Workstep_Library__c>([select Id, Complete_Date_Field__c, Start_Date_Driving_Fields__c, Start_Date_Driven_Duration__c from Workstep_Library__c where Complete_Date_Field__c != null or Start_Date_Driving_Fields__c != null]);
            return p_dateDrivenLibraries;
        }
    }
    
    public static Set<String> SubOrderDateDrivingFields {
        get{
            Set<String> s = new Set<String>();
            for(Workstep_Library__c lib : dateDrivenLibraries.values()){
               s.addAll(getDateDrivenFields(lib, 'Sub_Order__c'));
            }
            return s;
        }
    }
    
    public static Set<String> OrderDateDrivingFields {
        get{
            Set<String> s = new Set<String>();
            for(Workstep_Library__c lib : dateDrivenLibraries.values()) s.addAll(getDateDrivenFields(lib, 'Order__c'));
            return s;
        }
    }
    
    public static Boolean tryGetAttributeDates(Workstep__c ws, Sub_Order__c so, WorkstepDates d){
        return so != null && tryGetFieldDates(ws, so, 'Sub_Order__c', d);
    }
    
    public static Boolean tryGetAttributeDates(Workstep__c ws, Order__c ord, WorkstepDates d){
        return ord != null && tryGetFieldDates(ws, ord, 'Order__c', d);
    }
    
    private static Boolean tryGetFieldDates(Workstep__c ws, sObject obj, String objName, WorkstepDates d){
        Workstep_Library__c lib = ws.Workstep_Library__c != null ? dateDrivenLibraries.get(ws.Workstep_Library__c) : null;
        if(lib != null && !String.isEmpty(lib.Start_Date_Driving_Fields__c)){
            for(String f : getDateDrivenFields(lib, objName)){
                object val = obj.get(f);
                if(val != null){
                    d.StartDate = (val instanceof Datetime) ? ((Datetime)val).dateGMT() : (Date)val;
                    break;
                }
            }
            
            //If Start_Date_Driven_Duration__c is set to a non-negative number add it as the duration, else use the workstep's duration
            //d.EndDate = d.StartDate != null ? d.StartDate.addDays((Integer)(lib.Start_Date_Driven_Duration__c >= 0 ? lib.Start_Date_Driven_Duration__c : (ws.Duration__c != null ? ws.Duration__c : 0))) : null;
            if(d.StartDate != null){
                Integer duration = (Integer)(lib.Start_Date_Driven_Duration__c >= 0 ? lib.Start_Date_Driven_Duration__c : (ws.Duration__c != null ? ws.Duration__c : 0));
                if(duration > 0){
                    Set<Date> holidayRSDs = new Set<Date>();
                    for (Holiday h : AllHolidays) holidayRSDs.add(h.RecurrenceStartDate);

                    Date EndDate = d.StartDate;
                    Integer i = 1;
                    do {    //Set condition for validate the Next Day is a workable Date;
                        Boolean isValidDate = false;
                        do{
                            EndDate = EndDate.addDays(1);
                            isValidDate = (EndDate != EndDate.toStartOfWeek() && EndDate != (EndDate.toStartOfWeek() + 6) && !holidayRSDs.contains(EndDate));
                        }while(!isValidDate);
                        i++;
                    }while(i <= duration);
                    d.EndDate = EndDate;
                }else{
                    d.EndDate = d.StartDate;
                }
             }else{
                d.EndDate =  null;
             }
        
            return true;
        }
        
        return false;
    }
    
    private static List<String> getDateDrivenFields(Workstep_Library__c lib, String objName){
        List<String> l = new List<String>();
        if(!String.isEmpty(lib.Start_Date_Driving_Fields__c)){
            for(String f : lib.Start_Date_Driving_Fields__c.split('\n')){
                if(f.startsWith(objName + '.')){
                    l.add(f.subString(objName.length() + 1).replace('\r', ''));
                }
            }
        }
        return l;
    }
}