@isTest
public with sharing class Test_RelatedSubOrders {
    
		static testMethod void testController(){
    	Mocks testData = new Mocks();
    	Test.startTest();
    	
    	Opportunity opp = testData.opportunity;
    	Order__c ord = new Order__c(Opportunity__c = opp.Id);
    	insert ord;
    	
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

    	Apexpages.StandardController sc = new Apexpages.StandardController(so);
    	RelatedSubOrders rso = new RelatedSubOrders(sc);
        rso.returnRelated(so);	
    	rso.Save();
    	rso.SaveManual();
    	rso.Remove();		
		test.stopTest();
	}
    
    static testmethod void testSave(){
        Mocks Testdata = new Mocks();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.suborder);
        RelatedSubOrders obj = new RelatedSubOrders(ctrl);
        obj.ModifiedTempIds = JSON.serialize(new Set<String>{Testdata.order.Id});
        
        Test.startTest();
        obj.Save();       
    }
    
    static testmethod void testSaveManual(){
        Mocks Testdata = new Mocks();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.suborder);
        RelatedSubOrders obj = new RelatedSubOrders(ctrl);
        
        Order__c order = new Order__c(opportunity__c = Testdata.opportunity.Id);
        order.Order_Completion_Status__c = 'In Progress';
       	order.RecordTypeId = Schema.Sobjecttype.Order__c.getRecordTypeInfosByName().get('Build Order').getRecordTypeId();
        order.building__c = Testdata.building.Id;
        insert order;
        
        obj.AddBldOrder = [Select Id, Name from Order__c Where Id =: order.Id Limit 1][0].Name;
        
        Test.startTest();
        obj.SaveManual();
    }
    
    static testmethod void testRemove(){
        Mocks Testdata = new Mocks();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.suborder);
        RelatedSubOrders obj = new RelatedSubOrders(ctrl);
        
        obj.ModifiedTempIds = JSON.serialize(new Set<String>{Testdata.suborder.Id});
        
        Test.startTest();
        obj.Remove();
    }
    
    static testmethod void testOrderWrapper(){
        Mocks Testdata = new Mocks();
        
        Test.startTest();
        RelatedSubOrders.OrderWrapper inst = new RelatedSubOrders.OrderWrapper(Testdata.order, true);
        System.assertEquals(true, inst.isSelected);
    }
    
    static testmethod void testsObjectWrapper(){
        Mocks Testdata = new Mocks();
        
        Test.startTest();
        RelatedSubOrders.sObjectWrapper inst = new RelatedSubOrders.sObjectWrapper(Testdata.location, true);
		System.assertEquals(true, inst.isSelected);
    }
    
    static testmethod void testGettersAndSetters(){
        Mocks Testdata = new Mocks();
   		ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.suborder);
        RelatedSubOrders obj = new RelatedSubOrders(ctrl);
        
        System.assertEquals(obj.o = Testdata.order, obj.o);
        System.assertEquals(obj.so = Testdata.suborder, obj.so);
        System.assertEquals(obj.getRelatedWrapperCollection(), (List<RelatedSubOrders.sObjectWrapper>)obj.ritem);
        System.assertEquals(obj.getWrapperCollection(), (List<RelatedSubOrders.sObjectWrapper>)obj.oitem);
        System.assertEquals(JSON.deserialize(obj.ModifiedTempIds, Set<String>.Class), null);
        System.assertEquals(obj.AddBldOrder, null);     
    }
    
    static testmethod void testreturnRelated(){
        Mocks Testdata = new Mocks();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(Testdata.suborder); // SourceIds
        RelatedSubOrders obj = new RelatedSubOrders(ctrl);
        
        Order__c order = new Order__c(opportunity__c = Testdata.opportunity.Id);
        order.building__c = Testdata.building.Id;
        order.Record_Status__c = 'Open';
        insert order; // TargetIds
        
        Junction__c junc = new Junction__c(Source_ID__c = Testdata.suborder.Id, Target_ID__c = order.Id, Source_Type__c = 'Test', Target_Type__c = 'Test');
        insert junc;
        
        Test.startTest();
        obj.returnRelated(Testdata.suborder);
    }
}