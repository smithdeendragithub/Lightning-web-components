@isTest
public with sharing class Test_DocumentViewerController  extends TestUtils.TestClass {
	static testMethod void testController() {
		Mocks testData = new Mocks();
    	Test.startTest();
		
		Account a = testData.accounts[0];
		a.Customer_Detail__c = testData.customerDetail.Id;
		update a;
		
		PageReference pr = Page.DocumentViewer;
		pr.getParameters().put('id', a.Id);
		Test.setCurrentPage(pr);
		
		DocumentViewerController dc = new DocumentViewerController();
		
		dc.includeChildren = true;
		dc.showExpired = false;
		//dc.GetDocuments();
				
		Test.stopTest();
	}
}