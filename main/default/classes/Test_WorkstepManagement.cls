@isTest
public with sharing class Test_WorkstepManagement extends TestUtils.TestClass {
	
	static testMethod void testController(){
        Mocks testData = new Mocks();
    	test.startTest();
    	
    	createWorkstep(testData.order.Id);
		
		PageReference pageReference = Page.WorkstepManagement;
		pageReference.getParameters().put('orderId', testData.order.Id);
		test.setCurrentPage(pageReference);
		
		WorkstepManagementController wsm = new WorkstepManagementController();
		wsm.getWorkstepFilterOptions(new List<String>{'Id != null'});
		
		system.assertNotEquals(wsm.wsParams.config.GetDynamicTable, null);
		system.assertNotEquals(wsm.wsParams.config.configSection.GetSelectedTable, null);
		
		wsm.wsWrapperList[0].isSelected = true;
		wsm.CompleteSelectedWorksteps();
		wsm.SortChanged('wsTable');
		wsm.FieldConfigChanged('wsTable');
        wsm.AssignSelectedWorksteps();
        wsm.Test_Save() ;
		
		test.stopTest();
	}
	
	private static Id createWorkstep(Id orderID){
    	Workstep__c ws = new Workstep__c(
    									Name='Test Workstep'
    									,Order__c = orderID
    									,Duration__c = 4
    									,Lag__c = 0
    									,SLA__c = 4
    									,Status__c = WorkstepUtils.STATUS_OPEN
    									);
    	insert ws;
		
		system.assert(ws.Status__c == WorkstepUtils.STATUS_OPEN, 'Workstep was not created with an open status');
		
		return ws.Id;
	}
}