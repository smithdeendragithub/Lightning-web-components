@isTest
public with sharing class Test_MassUpdateSubOrders extends TestUtils.TestClass {

	static testMethod void testController(){
		Mocks testData = new Mocks();
		test.startTest();
		
		PageReference pageReference = Page.NotesViewer;
		pageReference.getParameters().put('id', testData.order.Id);
		
		insert new Sub_Order__c(Order__c = testData.order.Id);
		
		test.setCurrentPage(pageReference);
		
		MassUpdateSubOrders mu = new MassUpdateSubOrders();
		system.assert(mu.subOrderWrapperList.size() == 1);
		mu.subOrderWrapperList[0].isSelected = true;
		mu.dummySO.Hardware_Install_and_Test_Date__c = Date.today();
		mu.UpdateSelected();
		mu.Save();
		mu.QuickSave();
		mu.Cancel();
    	
		test.stopTest();
	}
}