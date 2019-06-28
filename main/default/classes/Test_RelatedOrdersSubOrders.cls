@isTest
public with sharing class Test_RelatedOrdersSubOrders {
	static testMethod void testController(){
        Mocks testData = new Mocks();
    	test.startTest();
    	
    	Order__c o = testData.order;
    	Apexpages.StandardController sc = new Apexpages.StandardController(o);
    	RelatedOrdersSubOrders roso = new RelatedOrdersSubOrders(sc);
    	
    	roso.DetermineRelationOfOrderOrSub(o);
    	
    	List<Order__c> lOrd = new List<Order__c>();
    	
    	lOrd.add(testData.order);
    	
    	roso.RelatedOrder(lOrd);
    	    	    	
    	roso.Save();
    	
    	roso.SaveManual();
    	
    	roso.Remove();				
		
		Order__c ord = testData.order;
		SPC_Product__c spc = new SPC_Product__c(
    									SalesProductExternalID__c = -1
    									,Provisioning_Product__c = testData.mpProvProd.get('Standard').Id
    									);
    	insert spc;
		Sub_Order__c so = new Sub_Order__c(
    									Service_Location__c = testData.serviceLocation.Id
    									,Order__c = ord.Id
    									,SPC_Product__c = spc.Id
    									,Workplan_Start_Date__c = Date.today()
    									);
    	insert so;
    	
    	Apexpages.StandardController sosc = new Apexpages.StandardController(o);
    	RelatedOrdersSubOrders rso = new RelatedOrdersSubOrders(sosc);
    	
    	List<Sub_Order__c> subOrd = new List<Sub_Order__c>();
    	
    	subOrd.add(so);
    	
    	rso.RelatedSubOrders(subOrd);
    	    	    	
    	rso.Save();
    	
    	rso.SaveManual();
    	
    	rso.Remove();
    	
    	test.stopTest();
	}
    
    static testmethod void testSave(){
        Mocks Testdata = new Mocks();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.order);
        RelatedOrdersSubOrders obj = new RelatedORdersSubOrders(ctrl);
        obj.ModifiedTempIds = JSON.serialize(new Set<String>{Testdata.suborder.Id});
        
        Test.startTest();
        obj.Save();       
    }
    
    static testmethod void testSaveManual(){
        Mocks Testdata = new Mocks();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.order);
        RelatedOrdersSubOrders obj = new RelatedOrdersSubOrders(ctrl);
        
        Sub_Order__c suborder = new Sub_Order__c(Order__c = Testdata.order.Id);
        suborder.Status__c = 'In Progress';
        insert suborder;
        
        obj.AddSubOrder = [Select Id, Name from Sub_Order__c Where Id =: suborder.Id Limit 1][0].Name;
        
        Test.startTest();
        obj.SaveManual();
        
        Junction__c junc = new Junction__c(Source_ID__c = Testdata.order.Id, Target_ID__c = suborder.Id, Source_Type__c = 'Test', Target_Type__c = 'Test');
        insert junc;
        
        obj.SaveManual();
    }
    
    static testmethod void testRemove(){
        Mocks Testdata = new Mocks();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.order);
        RelatedOrdersSubOrders obj = new RelatedOrdersSubOrders(ctrl);
        
        obj.ModifiedTempIds = JSON.serialize(new Set<String>{Testdata.suborder.Id, Testdata.order.Id});
        Junction__c junc = new Junction__c(Source_ID__c = Testdata.order.Id, Target_ID__c = Testdata.suborder.Id, Source_Type__c = 'Test', Target_Type__c = 'Test');
        insert junc;
        
        Test.startTest();
        obj.Remove();
    }
    
    static testmethod void testOrderWrapper(){
        Mocks Testdata = new Mocks();
        
        Test.startTest();
        RelatedOrdersSubOrders.OrderWrapper inst = new RelatedOrdersSubOrders.OrderWrapper(Testdata.order, true);
        System.assertEquals(true, inst.isSelected);
    }
    
    static testmethod void testSubOrderWrapper(){
        Mocks Testdata = new Mocks();
        
        Test.startTest();
        RelatedOrdersSubOrders.SubOrderWrapper inst = new RelatedOrdersSubOrders.SubOrderWrapper(Testdata.suborder, true);
        System.assertEquals(true, inst.isSelected);
    }
    
    static testmethod void testsObjectWrapper(){
        Mocks Testdata = new Mocks();
        
        Test.startTest();
        RelatedOrdersSubOrders.sObjectWrapper inst = new RelatedOrdersSubOrders.sObjectWrapper(Testdata.suborder, true);
		System.assertEquals(true, inst.isSelected);
    }
    
    static testmethod void testRelatedSubOrders(){
        Mocks Testdata = new Mocks();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.order);
        RelatedOrdersSubOrders obj = new RelatedOrdersSubOrders(ctrl);
        // source = order // target = suborder
        
        Junction__c junc = new Junction__c(Source_ID__c = Testdata.order.Id, Target_ID__c = Testdata.suborder.Id, Source_Type__c = 'Test', Target_Type__c = 'Test');
        insert junc;
        
        Test.startTest();
        obj.RelatedSubOrders(new List<Sub_Order__c>{Testdata.suborder});        
    }
    
    static testmethod void testRelatedOrder(){
        Mocks Testdata = new Mocks();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.order);
        RelatedOrdersSubOrders obj = new RelatedOrdersSubOrders(ctrl);
        // source = suborder // target = order
        
        Junction__c junc = new Junction__c(Source_ID__c = Testdata.suborder.Id, Target_ID__c = Testdata.order.Id, Source_Type__c = 'Test', Target_Type__c = 'Test');
        insert junc;
        
        Test.startTest();
        obj.RelatedOrder(new List<Order__c>{Testdata.order});        
    }
    
    static testmethod void testDetermineRelationOfOrderOrSub(){
        Mocks Testdata = new Mocks();
        
        Order__c order = new Order__c(opportunity__c = Testdata.opportunity.Id);
        order.Order_Completion_Status__c = 'In Progress';
       	order.RecordTypeId = Schema.Sobjecttype.Order__c.getRecordTypeInfosByName().get('Build Order').getRecordTypeId();
        order.building__c = Testdata.building.Id;
        insert order;
        
		Test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(order);
        RelatedOrdersSubOrders obj = new RelatedOrdersSubOrders(ctrl);
    }
    
    static testmethod void testGettersAndSetters(){
        Mocks Testdata = new Mocks();
   		ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.order);
        RelatedOrdersSubOrders obj = new RelatedOrdersSubOrders(ctrl);
        
        System.assertEquals(obj.o = Testdata.order, obj.o);
        System.assertEquals(obj.getRelatedWrapperCollection(), (List<RelatedOrdersSubOrders.sObjectWrapper>)obj.ritem);
        System.assertEquals(obj.getWrapperCollection(), (List<RelatedOrdersSubOrders.sObjectWrapper>)obj.oitem);
        System.assertEquals(JSON.deserialize(obj.ModifiedTempIds, Set<String>.Class), null);
        System.assertEquals(obj.AddSubOrder, null);     
    }
}