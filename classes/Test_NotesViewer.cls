@isTest
public with sharing class Test_NotesViewer extends TestUtils.TestClass {
	
	static testMethod void testController() {
		Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		Note__c note = new Note__c(Name='Test note', Account__c=a.Id);
		insert note;
		
    	Customer_Detail__c detail = new Customer_Detail__c(ICC_Subscriber_ID__c = '-9999'
															,Customer_Main_Address__c = testData.loc.Id
															,Service_Address__c = testData.loc.Id);
    	insert detail;
		
		a.Customer_Detail__c = detail.Id;
		update a;
		
		Service_Location__c sLoc = testData.serviceLocation;
		Note standardNote = new Note(Title='Standard note', ParentId=sLoc.Id, Body='bodyText');
		insert standardNote;
		
		Test.startTest();
		
		PageReference pageReference = Page.NotesViewer;
		pageReference.getParameters().put('id', a.Id);
		pageReference.getParameters().put('related', '[{"name":"Account_Locations__r"}]');
		
		Test.setCurrentPage(pageReference);
		
		Date sd = Date.today().addDays(-1);
		Date ed = Date.today().addDays(1);
		
		NotesViewerController nvc = new NotesViewerController();
		nvc.StartDateString = string.valueOf(sd.year()) + '-' + string.valueOf(sd.month()) + '-' + string.valueOf(sd.day());
		nvc.EndDateString = string.valueOf(ed.year()) + '-' + string.valueOf(ed.month()) + '-' + string.valueOf(ed.day());
		nvc.GetNotes();
		
		pageReference.getParameters().put('sortColumn', 'ParentName');
		nvc.changeSort();
		
		System.debug(nvc.getTestClass());
	}
}