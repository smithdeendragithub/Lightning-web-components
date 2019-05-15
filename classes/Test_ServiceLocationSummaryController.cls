@isTest
public with sharing class Test_ServiceLocationSummaryController extends TestUtils.TestClass {
	static testMethod void myUnitTest() {
		Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		Service_Location__c sloc = testData.serviceLocation;
		Building_Access_Availability__c baa = testData.BAA;
		
		Test.startTest();
		
		PageReference pageReference = Page.ServiceLocationSummary;
		pageReference.getParameters().put('accountId', a.Id);
		
		Test.setCurrentPage(pageReference);
		ServiceLocationSummaryController con = new ServiceLocationSummaryController();
	}
}