@isTest
public with sharing class Test_AssignOrders extends TestUtils.TestClass {

	static testMethod void testController(){
		Mocks testData = new Mocks();
		test.startTest();
		
		Apexpages.StandardSetController sc = new Apexpages.StandardSetController(new List<Order__c>{testData.order});
    	AssignOrders ao = new AssignOrders(sc);
    	system.assert(!ao.isError, 'AssignOrders has loaded in an errored state');
    	system.assert(ao.orderWrapperList.size() == 1);
    	ao.orderWrapperList[0].isSelected = true;
    	ao.sendNotification = true;
    	ao.dummyOrd.OwnerId = [select Id from User where Name = 'Unassigned'].Id;
    	ao.Save();
    	ao.orderWrapperList[0].isSelected = true;
    	ao.QuickSave();
    	ao.Cancel();
    	
		test.stopTest();
	}
}