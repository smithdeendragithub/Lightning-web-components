@isTest
public with sharing class Test_AssignWorkstepIssues extends TestUtils.TestClass {

	static testMethod void testController(){
		Mocks testData = new Mocks();
		test.startTest();
		
		Workstep__c ws = new Workstep__c(Name = 'Test WS', Order__c = testData.order.Id);
		insert ws;
		
		Workstep_Issue__c wsi = new Workstep_Issue__c(Workstep__c = ws.Id);
		insert wsi;
		
		Apexpages.StandardSetController sc = new Apexpages.StandardSetController(new List<Workstep_Issue__c>{wsi});
    	AssignWorkstepIssues awi = new AssignWorkstepIssues(sc);
    	system.assert(!awi.isError, 'AssignWorkstepIssues has loaded in an errored state');
    	system.assert(awi.issueWrapperList.size() == 1);
    	awi.issueWrapperList[0].isSelected = true;
    	awi.sendNotification = true;
    	awi.dummyWSIssue.OwnerId = [select Id from User where Name = 'Unassigned'].Id;
    	awi.Save();
    	awi.issueWrapperList[0].isSelected = true;
    	awi.QuickSave();
    	awi.Cancel();
    	
		test.stopTest();
	}
}