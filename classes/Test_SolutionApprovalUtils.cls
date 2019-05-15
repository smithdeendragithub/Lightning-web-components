@isTest
public with sharing class Test_SolutionApprovalUtils extends TestUtils.TestClass { 

	static testMethod void testGetDiscountLevel(){
		Mocks testData = new Mocks();
		Test.startTest();
		SolutionApprovalUtils.getApprovalLevel(UserInfo.getUserId());
		Test.stopTest();

	}
	static testMethod void testApproveSolutionFromOLIs(){
		Mocks testData = new Mocks();
		Test.startTest();
		SolutionApprovalUtils.ApproveSoluitonFromOLIs(testData.lstLineItems);
		Test.stopTest();
	}
	static testMethod void testRequestApproval(){
		Mocks testData = new Mocks();
		Test.startTest();
		List<OpportunityLocationConfiguration__c> lstconfig = testData.lstconfig;
		SolutionApprovalUtils.RequestApprovals(testData.Opportunity.Id);
		Test.stopTest();
	}
	static testMethod void testGetIndriectSalesManager(){
		Mocks testData = new Mocks();
		Test.startTest();
		SolutionApprovalUtils.GetIndirectSalesManagerId();
		Test.stopTest();
	}
	static testMethod void testGetApprovalRequestTemplate(){
		Mocks testData = new Mocks();
		Test.startTest();
		SolutionApprovalUtils.GetApprovalRequestTemplateId();
		Test.stopTest();
	}
	static testMethod void testGetSMCompetitiveBuildingDiscount(){
		Mocks testData = new Mocks();
		Test.startTest();
		SolutionApprovalUtils.GetSMCompetitiveBuildingDiscount();
		Test.stopTest();
	}
}