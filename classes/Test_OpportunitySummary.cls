@isTest
public with sharing class Test_OpportunitySummary extends TestUtils.TestClass {
    
    static testMethod void testController() {

		Mocks testData = new Mocks();
		
		Test.startTest();

		ApexPages.StandardController sc = new ApexPages.StandardController(testData.parentAccount);
    	OpportunitySummaryController osc = new OpportunitySummaryController(sc);
     	test.stopTest();
    }
}