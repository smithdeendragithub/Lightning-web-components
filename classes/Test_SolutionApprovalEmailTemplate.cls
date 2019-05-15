@isTest
public with sharing class Test_SolutionApprovalEmailTemplate { 
	public static testmethod void testController(){
		Mocks testData = new Mocks();
		test.startTest();
		SolutionApprovalEmailTemplate controller = new SolutionApprovalEmailTemplate();
		controller.OpportunityId = testData.Opportunity.Id;
		controller.getApprovalViews();
		controller.getSize();
		SolutionAPprovalEmailTemplate.ApprovalView v = new SolutionApprovalEmailTemplate.ApprovalView(testData.location, testData.lstconfig[0]);
		test.stopTest();
	}
}