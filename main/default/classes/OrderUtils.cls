public without sharing class OrderUtils {
    
    //private static Map<String,String> OrderStatusToOppStage = new Map<String,String>{'Order Accepted'=>OpportunityUtils.STAGE_CLOSED_WON};
    private static Map<String,String> OrderStatusToOppStage = new Map<String,String>{'Order Accepted'=>OpportunityUtils.STAGE_5};
    
    private static RecordType integrationonlyRecordType = null;
    public static Id IntegrationOnlyRecordTypeID{
        get{
            if(integrationonlyRecordType == null)
                integrationonlyRecordType = [select Id from RecordType where DeveloperName = 'Integration_Only_Order' limit 1];
            return integrationonlyRecordType.Id;
        }
    }
    
    public static Boolean orderIsIntegrationOnlyRecordType(Order__c order){
        return order.RecordTypeId == IntegrationOnlyRecordTypeID;
    }
    
    private static RecordType buildOrderRecordType = null;
    public static Id BuildOrderRecordTypeID{
        get{
            if(buildOrderRecordType == null)
                buildOrderRecordType = [select Id from RecordType where DeveloperName = 'Build_Order' limit 1];
            return buildOrderRecordType.Id;
        }
    }
    private static RecordType decommOrderRecordType = null;
    public static Id decommOrderRecordTypeID{
        get{
            if(decommOrderRecordType == null)
                decommOrderRecordType = [select Id from RecordType where DeveloperName = 'Decomm_Order' limit 1];
            return decommOrderRecordType.Id;
        }
    }
    
    private static Boolean synchingOppFields = false;
    public static void synchOpportunityFields(List<sObject> tNew, Map<Id, sObject> tOldMap, Boolean orderMode, boolean forceRefresh){
        if(synchingOppFields) return;
        synchingOppFields = true;
        
        Set<String> updateFields = orderMode
                                        ? new Set<String>{ 'Opportunity_Coordinator__c', 'Data_Missing_Codes__c', 'Data_Missing_Comments__c', 'Status__c', 'Status_Reason__c'}
                                        : new Set<String>{ 'Account_Support_Coordinator__c', 'Order_Missing_Codes__c', 'Order_Missing_Comments__c', 'Order_Status__c', 'Order_Status_Reason__c'};
        
        Map<Id, sObject> updated = new Map<Id, sObject>();
        for(sObject oNew : tNew){
            sObject oOld = tOldMap != null ? tOldMap.get(oNew.Id) : null;
            if(oOld == null) updated.put(oNew.Id, oNew);
            else{
                for(String f : updateFields){
                    if(oNew.get(f) != oOld.get(f) || forceRefresh){
                        updated.put(oNew.Id, oNew);
                        break;
                    }
                }
            }
            
            //Only care about opportunity orders
            if(orderMode && updated.containsKey(oNew.Id) && ((Order__c)oNew).Opportunity__c == null) updated.remove(oNew.Id);
        }
        
        if(updated.size() > 0){
            Map<Id, Opportunity> opps = !orderMode ? new Map<Id, Opportunity>((List<Opportunity>)updated.values()) : new Map<Id, Opportunity>();
            Map<Id, Order__c> orders = orderMode ? new Map<Id, Order__c>((List<Order__c>)updated.values()) : new Map<Id, Order__c>([select Id
                                                                                                                                    ,Opportunity_Coordinator__c
                                                                                                                                    ,Data_Missing_Codes__c
                                                                                                                                    ,Data_Missing_Comments__c
                                                                                                                                    ,Status__c
                                                                                                                                    ,Status_Reason__c
                                                                                                                                    ,Opportunity__c
                                                                                                                                from Order__c where Opportunity__c in: updated.keyset()]);
            
            if(orderMode){
                for(Order__c o : orders.values()) opps.put(o.Opportunity__c, null);
                opps = new Map<Id, Opportunity>([select Id from Opportunity where Id in: opps.keyset()]);
            }
            
            for(Order__c o : orders.values()){
                Opportunity opp = opps.get(o.Opportunity__c);
                opp.Account_Support_Coordinator__c = o.Opportunity_Coordinator__c;
                opp.Order_Missing_Codes__c = o.Data_Missing_Codes__c;
                opp.Order_Missing_Comments__c = o.Data_Missing_Comments__c;
                opp.Order_Status__c = o.Status__c;
                opp.Order_Status_Reason__c = o.Status_Reason__c;
                opp.Order__c = o.Id;
                if(OrderStatusToOppStage.containsKey(o.Status__c)) opp.StageName = OrderSTatusToOppStage.get(o.Status__c);
                if(!(ApexUtils.inTrigger('Opportunity') || ApexUtils.inTrigger('Opportunity_Split'))) opp.Bypass_Validation__c = true;
                System.debug('opp: ' + opp);
            }
            
            if(orderMode){
                //boolean disabled = OpportunityTriggers.triggerDisabled;
                //OpportunityTriggers.triggerDisabled = true;
                update opps.values();
                //OpportunityTriggers.triggerDisabled = disabled;
             }
        }
        synchingOppFields = false;
    }
    
    public static Boolean orderIsBuildOrderRecordType(Id ord){
        Order__c order = [Select Id, RecordTypeId From Order__c Where Id =: ord];

        return order.RecordTypeId == BuildOrderRecordTypeID;
    }
    
    public static Boolean getServiceLocationsToIntegrate_subscriberIDExists {get; private set;}
    public static Map<Id, Service_Location__c> getServiceLocationsToIntegrate(Order__c order, List<Service_Location__c> sLocs){
        Map<Id, Service_Location__c> retval = new Map<Id, Service_Location__c>();
        
        if(sLocs == null)
            sLocs = getServiceLocationsFromOrder(order);
        
        getServiceLocationsToIntegrate_subscriberIDExists = false;
        if(sLocs != null){
            //Remove from all cases
            for(Integer i=sLocs.size()-1; i>=0; i--){
                if(sLocs[i].Level__c == 'ERROR' || sLocs[i].Account__c == null || (sLocs[i].Account__r.Type == 'Former Customer' && !string.isEmpty(sLocs[i].Account__r.ICC_Account_Number__c)) || !string.isEmpty(sLocs[i].ICC_Subscriber_ID__c)){
                    getServiceLocationsToIntegrate_subscriberIDExists = getServiceLocationsToIntegrate_subscriberIDExists || !string.isEmpty(sLocs[i].ICC_Subscriber_ID__c);
                    sLocs.remove(i);
                }
            }
            
            if(!orderIsIntegrationOnlyRecordType(order)){
                for(Service_Location__c sLoc : sLocs){
                    if(sLoc.ICC_Subscriber_ID__c == null)
                        retval.put(sLoc.Id, sLoc);
                }
            }
            else{
                if(!getServiceLocationsToIntegrate_subscriberIDExists)  //Return everything
                    retval = new Map<Id, Service_Location__c>(sLocs);
                else if(sLocs.size() > 0){
                    //Return only service locs that are attached to sub-orders
                    Set<Id> serviceLocIDs = new Set<Id>();
                    for(Sub_Order__c subOrder : [select Id, Service_Location__c from Sub_Order__c where Order__c =: order.Id and Service_Location__c != null])
                        serviceLocIDs.add(subOrder.Service_Location__c);
                        
                    for(Service_Location__c sLoc : sLocs){
                        if(serviceLocIDs.contains(sLoc.Id))
                            retval.put(sLoc.Id, sLoc);
                    }
                }
            }
            
            //Remove subscribers with parents that are not integrated and are not in this set
            Set<Id> parentWillNotIntegrate = new Set<Id>();
            for(Id id : retval.keyset()){
                Service_Location__c sLoc = retval.get(id);
                if(sLoc.Parent_Service_Location__c != null && sLoc.Parent_Service_Location__r.ICC_Subscriber_ID__c == null && retval.get(sLoc.Parent_Service_Location__c) == null)
                    parentWillNotIntegrate.add(id);
            }
        }
        
        return retval;
    }
    
    public static List<Service_Location__c> getServiceLocationsFromOrder(Order__c order){
        if(order.Opportunity__c != null){
            Map<Id, List<Service_Location__c>> sLocations = OpportunityUtils.getServiceLocationsFromOpportunities(new Map<Id, Opportunity>{order.Opportunity__c => order.Opportunity__r});
            return sLocations.get(order.Opportunity__c);
        }
        else if(order.Account__c != null){
            return [select Id 
                           ,ICC_Subscriber_ID__c
                           ,Level__c
                           ,Account__c
                           ,Account__r.ICC_Account_Number__c
                           ,Account__r.Type
                           ,Parent_Service_Location__c
                           ,Parent_Service_Location__r.ICC_Subscriber_ID__c
                     from Service_Location__c where Account__c = :order.Account__c];
        }
        return new List<Service_Location__c>();
    }
    
    public static List<String> createSubscribersFromOrder(Order__c order) {
        //List<Service_Location__c> sLocs = getServiceLocationsFromOrder(order);
        //system.debug('All possible service locations: ' + sLocs);
        
        //Boolean integrationOnlyMode = orderIsIntegrationOnlyRecordType(order);
        Map<Id, Id> orderIDsByServiceLocationID = new Map<Id, Id>();
        for(Service_Location__c sLoc : getServiceLocationsToIntegrate(order, null).values()){
            orderIDsByServiceLocationID.put(sLoc.Id, order.Id);
            /*if(!integrationOnlyMode){
                Opportunity e = earliestClosedOpps.get(sLoc.Id);
                if(e == null || e.Contract_Signed_Date__c > order.Opportunity__r.Contract_Signed_Date__c)
                    earliestClosedOpps.put(sLoc.Id, order.Opportunity__r);
            }*/
        }
        
        system.debug('Service locations to create as subscribers: ' + orderIDsByServiceLocationID.keyset());
        
        //Send the related locations to be built
        if(orderIDsByServiceLocationID.size() > 0){
            /*system.debug(locationsToIntegrate);
            
            Map<Id, Id> associatedOpps = new Map<Id, Id>();
            for(Id id :earliestClosedOpps.keyset())
                associatedOpps.put(id, earliestClosedOpps.get(id).Id);*/

            return IntegrationUtils.createSubscribersFromOrderRelatedServiceLocations(orderIDsByServiceLocationID, UserInfo.getSessionId());
        }
        return new List<String>();
    }
    
    public static void refreshOrderStatusesBySubOrderID(Set<Id> soIDs){
        Map<Id, Sub_Order__c> subOrders = new Map<Id, Sub_Order__c>();
        Map<Id, Order__c> orders = new Map<Id, Order__c>();
        Map<Id, Sub_Order__c> dsnctOrders = new Map<Id, Sub_Order__c>();
        if(soIDs.size() > 0){
            /*Order status is determined by all of it's suborder statuses. 
            Sub-Order status is determined by all of it's sog statuses.*/
            for(Sub_Order__c dOrder : [select Order__c from Sub_Order__c where Id in : soIDs]){
                dsnctOrders.put(dOrder.Order__c, dOrder);
            }
            subOrders = new Map<Id, Sub_Order__c>([select Id, Order__c, Status__c, (select Id, Status__c from Sub_Order_Groups__r) from Sub_Order__c where Order__c in : dsnctOrders.keyset() Order by Order__c ]);
            //for(Sub_Order__c so : subOrders.values())
                //orders.put(so.Order__c, null);
        }
        
        if(orders.size() > 0 || subOrders.size() > 0){
            //Status codes: 1=Complete, 2=Cancelled, 3=In Progress
            Map<Id, Set<Integer>> orderStatusCodes = new Map<Id, Set<Integer>>();           
            orders = new Map<Id, Order__c>([select Id, Order_Completion_Status__c from Order__c where Id in: dsnctOrders.keyset()]);

            List<Order__c> updatedOrders = new List<Order__c>();
            List<Sub_Order__c> updatedSubOrders = new List<Sub_Order__c>();
            for(Id ords : orders.keyset()){
                for(Sub_Order__c so : subOrders.values()){                  
                        if(so.Order__c == ords){
                        Set<Integer> codes = orderStatusCodes.get(so.Order__c) != null ? orderStatusCodes.get(so.Order__c) : new Set<Integer>();
                        String s = so.Status__c;
                    
                        codes.addAll(updateSubOrderStatusesFromSubOrderGroups(so, so.Sub_Order_Groups__r));
                        
                        if(s != so.Status__c)
                            updatedSubOrders.add(so);
                            orderStatusCodes.put(so.Order__c, codes);
                        }
                }
                        
                for(Id id : orderStatusCodes.keyset()){
                    Order__c ord = orders.get(id);                  
                    String correctStatus = getCorrectOrderStatusFromCodes(orderStatusCodes.get(id), false);             
                    if(ord.Order_Completion_Status__c != correctStatus){
                        ord.Order_Completion_Status__c = correctStatus;                 
                        updatedOrders.add(ord);
                        
                    }
                }
            }
            
            if(updatedOrders.size() > 0)
                update updatedOrders;
                
            if(updatedSubOrders.size() > 0)
                update updatedSubOrders;
        }
    }
    
    public static Set<Integer> updateSubOrderStatusesFromSubOrderGroups(Sub_Order__c so, List<Sub_Order_Group__c> sogs){
        Set<Integer> statusCodes = new Set<Integer>();
        for(Sub_Order_Group__c sog : sogs != null ? so.Sub_Order_Groups__r : new List<Sub_Order_Group__c>()){           
            if(sog.Status__c == 'Complete')
                statusCodes.add(1);
            else if(sog.Status__c == 'Cancel')
                statusCodes.add(2);
            else
                statusCodes.add(3);             
        }
        
        String correctStatus = getCorrectOrderStatusFromCodes(statusCodes, true);   
//Removed Blocked condition as it needs to be handled automagically now & not stop Workflow     
        //if(so.Status__c != correctStatus && (correctStatus != 'In Progress' || so.Status__c != 'Blocked')) 
        if(so.Status__c == null || (so.Status__c != correctStatus)){
            so.Status__c = correctStatus;           
        }                   
        return statusCodes;
    }
    
    private static String getCorrectOrderStatusFromCodes(Set<Integer> statusCodes, Boolean soMode){             
        if(statusCodes.contains(2) && !statusCodes.contains(1) && !statusCodes.contains(3))
            return 'Cancelled';
        else if(statusCodes.contains(1) && !statusCodes.contains(3))
            return soMode ? 'Closed' : 'Complete';
        return 'In Progress';
    }
    
    public static void refreshBuildingOrderStatuses(Set<Id> buildingIDs){
        if(buildingIDs.size() == 0) return;
        
        List<Building__c> bList = new List<Building__c>();
        for(Building__c b : [select Id, Build_Order_Status__c, (select Order_Completion_Status__c from Orders__r) from Building__c where Id in: buildingIDs]){
            Set<Integer> statusCodes = new Set<Integer>();
            for(Order__c o : b.Orders__r != null ? b.Orders__r : new List<Order__c>()){
                if(o.Order_Completion_Status__c == 'Complete')
                    statusCodes.add(1);
                else if(o.Order_Completion_Status__c == 'Cancelled')
                    statusCodes.add(2);
                else
                    statusCodes.add(3);
            }
            
            String s = getCorrectBuildingOrderStatusFromCodes(statusCodes);
            
            if(b.Build_Order_Status__c != s){
                b.Build_Order_Status__c = s;
                bList.add(b);
            }
        }
        
        if(bList.size() > 0) SecurityUtils.BypassProcesser.saveObjects(bList, true);
    }
    
    public static Id getAccountIdFromOrder(Order__c o){
        Id actId = (o.opportunity__c != null && o.opportunity__r != null)? o.opportunity__r.accountId : (o.account__c != null? o.account__c : null);
        return actId;
    }
    
    private static String getCorrectBuildingOrderStatusFromCodes(Set<Integer> statusCodes){
        if(statusCodes.size() == 0)
            return null;
        else if(statusCodes.size() == 1 && statusCodes.contains(2))
            return 'Cancelled';
        else if(statusCodes.contains(1) && !statusCodes.contains(3))
            return 'Complete';
        return 'In Progress';
    }
}