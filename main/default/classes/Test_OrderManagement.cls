@isTest
public with sharing class Test_OrderManagement extends TestUtils.TestClass {
    
    static testmethod void testController(){
        getTestData();
        
        test.startTest();
        
        PageReference pageReference = Page.OrderManagement;
        pageReference.getParameters().put('accountId', a.Id);
        test.setCurrentPage(pageReference);
        
        OrderManagementController om = new OrderManagementController();
        om.GetICCOrders();
        om.SelectedICCOrderIds = '[]';
        om.PrepareConfigurationPage();
        om.subOrderConfig.Workplan_Start_Date__c = Date.today();
        om.Save();
        om.SaveModifiedSubOrders();
        
        String str = om.EditedICCTempIds;
        str = om.ModifiedTempIds;
        str = om.SelectedICCOrderIds;
        
        OrderManagementController.OppDisplay oppDisp = new OrderManagementController.OppDisplay();
        oppDisp = new OrderManagementController.OppDisplay(null);
        oppDisp = new OrderManagementController.OppDisplay(new Opportunity(Name='Test'));
        
        System.debug(om.hasWorkstepCreate);
        om.hasWorkstepCreate = true;
        System.debug(om.getTestClass());
    }
    
    static testmethod void testOrder(){
        getTestData();
        
        RecordType rt = [select Id from RecordType where SobjectType = 'Opportunity' and Name = 'Retail'];
        Opportunity opp = new Opportunity(AccountId = a.Id
                                            ,Name = 'Test Opp'
                                            ,RecordTypeId = rt.Id
                                            ,StageName = OpportunityUtils.STAGE_QUALIFIED
                                            ,Type = 'Existing'
                                            ,Oppty_Sub_Type__c='Renewal'
                                            ,CloseDate = Date.today().addDays(30)
                                            ,Customer_Requested_Due_Date__c = Date.today());
        insert opp;
        
        rt = [select Id from RecordType where SobjectType = 'Order__c' and DeveloperName = 'Opportunity_Order'];
        ord = new Order__c(Opportunity__c = opp.Id, RecordTypeId = rt.Id);
        insert ord;
        ord = [select Id, Name, AccountName__c from Order__c where Id =: ord.Id];
        
        rt = [select Id from RecordType where SobjectType = 'Order_Property__c' and DeveloperName = 'External_Order'];
        Order_Property__c op = new Order_Property__c(Order__c = ord.Id, External_ID__c = '1234', RecordTypeId = rt.Id, Type__c = 'Install');
        insert op;
        
        subOrd = new Sub_Order__c(Order__c = ord.Id, Service_Location__c = sLoc.Id, Customer_Detail__c = cd.Id);
        insert subOrd;
        
        test.startTest();
        
        PageReference pageReference = Page.OrderManagement;
        pageReference.getParameters().put('orderId', ord.Name);
        test.setCurrentPage(pageReference);
        
        OrderManagementController om = new OrderManagementController();
        om.GetICCOrders();
        
        om.EditedICCTempIds = om.ModifiedTempIds = '["' + om.subOrderDisplay[0].tempId + '"]';
        om.SelectedOrderId = ord.Id;
        om.UpdateSelectedOrder();
        om.EditSubOrders();
        
        om.selectedOrderInfo.Order = ord;
        om.Save();
        om.SaveModifiedSubOrders();
         
        //Hit some config code
        om.getOrderProperties(ord.Id);
        
        OrderManagementController.OrderConfigurator oc = new OrderManagementController.OrderConfigurator();
        om.orderDisplay[0].compareTo(om.orderDisplay[0]);
        om.subOrderDisplay[0].compareTo(om.subOrderDisplay[0]);
    }
    
    private static Mocks testData = null;
    private static Customer_Detail__c cd = null;
    private static Account a = null;
    private static Service_Location__c sLoc = null;
    private static Order__c ord = null;
    private static Sub_Order__c subOrd = null;
    private static void getTestData(){
        testData = new Mocks();
        
        cd = new Customer_Detail__c(ICC_Subscriber_ID__c='12345');
        insert cd;
        
        a = new Account(Name = 'testAccount'
                        ,Customer_Detail__c = cd.Id
                        ,ShippingCountry = 'US'
                        ,ShippingStreet = '1234 Someplace ST'
                        ,ShippingCity = 'Nowhere'
                        ,ShippingState = 'WA'
                        ,ShippingPostalCode = '54321'
                        ,Phone = '800-123-1234'
                        ,Industry = 'Z - Unclassified');
        insert a;
        
        sLoc = new Service_Location__c(Account__c = a.Id
                                        ,Customer_Detail__c = cd.Id
                                        ,Location__c = testData.loc.Id);
        insert sLoc;
    }
    
    /*public static integraWS.SFOrderView getSubOrderSummaryBySubscriberID(Integer subscriberID){
        integraWS.SFOrderView o = new integraWS.SFOrderView();
        o.OrderProperties = new integraWS.ArrayOfSFOrderPropertyView();
        o.OrderProperties.SFOrderPropertyView = new List<integraWS.SFOrderPropertyView>();
        
        o.SubOrders = new integraWS.ArrayOfSFSubOrderView();
        o.SubOrders.SFSubOrderView = new List<integraWS.SFSubOrderView>();
        
        o.OrderProperties.SFOrderPropertyView.add(getMockProp(subscriberID, 1, 'Install Order'));
        o.SubOrders.SFSubOrderView.add(getMockSO(subscriberID, 1, o.OrderProperties.SFOrderPropertyView.get(o.OrderProperties.SFOrderPropertyView.size() - 1).ExternalID));
        
        return o;
    }*/
    
    public static integraWS.ArrayOfSFOrderPropertyView getSubOrderListBySubscriberID(Integer subscriberID){
        integraWS.ArrayOfSFOrderPropertyView op = new integraWS.ArrayOfSFOrderPropertyView();
        op.SFOrderPropertyView = new List<integraWS.SFOrderPropertyView>();
        op.SFOrderPropertyView.add(getMockProp(subscriberID, 1, 'Install Order'));
        return op;
    } 
    
    public static integraWS.SFOrderView getSubOrderSummaryByOrderIds(List<Integer> orderIDs, Integer subscriberID){
        
        integraWS.SFOrderView o = new integraWS.SFOrderView();
        o.OrderProperties = new integraWS.ArrayOfSFOrderPropertyView();
        o.OrderProperties.SFOrderPropertyView = new List<integraWS.SFOrderPropertyView>();
        
        o.SubOrders = new integraWS.ArrayOfSFSubOrderView();
        o.SubOrders.SFSubOrderView = new List<integraWS.SFSubOrderView>();
        
        o.OrderProperties.SFOrderPropertyView.add(getMockProp(subscriberID, 1, 'Install Order'));
        integraWS.SFSubOrderView sov = getMockSO(subscriberID, 1, o.OrderProperties.SFOrderPropertyView.get(o.OrderProperties.SFOrderPropertyView.size() - 1).ExternalID);
        if(subOrd != null) sov.SalesforceID = subOrd.Id;
        o.SubOrders.SFSubOrderView.add(sov);
        
        sov = getMockSO(subscriberID, 2, o.OrderProperties.SFOrderPropertyView.get(o.OrderProperties.SFOrderPropertyView.size() - 1).ExternalID);
        o.SubOrders.SFSubOrderView.add(sov);
        
        return o;
        
        /*integraWS.SFOrderView o = new integraWS.SFOrderView();
        return o;*/
    }
    
    private static integraWS.SFOrderPropertyView getMockProp(Integer subscriberID, Integer offset, String typeName){
        integraWS.SFOrderPropertyView p = new integraWS.SFOrderPropertyView();
        p.ExternalID = subscriberID + offset;
        p.OrderType = typeName;
        return p;
    }
    
    private static integraWS.SFSubOrderView getMockSO(Integer subscriberID, Integer offset, Integer propExternalID){
        integraWS.SFSubOrderView so = new integraWS.SFSubOrderView();
        so.OrderPropertyExternalOrderID = propExternalID;
        so.SPCProductID = 185;
        so.SubscriberID = subscriberID;
        so.Groups = new integraWS.ArrayOfSFSubOrderGroupView();
        so.Groups.SFSubOrderGroupView = new List<integraWS.SFSubOrderGroupView>();
        
        integraWS.SFSubOrderGroupView g = new integraWS.SFSubOrderGroupView();
        g.ExternalID = propExternalID + offset;
        g.Status = 'In Progress';
        g.Quantity = 3;
        g.ProductDescription = 'Test Product';
        g.MRC = 1000000;
        so.Groups.SFSubOrderGroupView.add(g);
        
        return so;
    }
}