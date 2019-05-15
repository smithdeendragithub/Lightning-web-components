@isTest
public with sharing class Test_AssignWorksteps extends TestUtils.TestClass {

	static testMethod void testController(){
		Mocks testData = new Mocks();
		test.startTest();
		
		Workstep__c ws = new Workstep__c(Name = 'Test WS', Order__c = testData.order.Id);
		insert ws;
		
		Apexpages.StandardSetController sc = new Apexpages.StandardSetController(new List<Workstep__c>{ws});
    	AssignWorksteps aw = new AssignWorksteps(sc);
    	system.assert(!aw.isError, 'AssignWorksteps has loaded in an errored state');
    	system.assert(aw.workstepWrapperList.size() == 1);
    	aw.workstepWrapperList[0].isSelected = true;
    	aw.sendNotification = true;
    	aw.dummyWS.OwnerId = [select Id from User where Name = 'Unassigned'].Id;
    	aw.Save();
    	aw.workstepWrapperList[0].isSelected = true;
    	aw.QuickSave();
    	aw.Cancel();
    	
		test.stopTest();
	}
}