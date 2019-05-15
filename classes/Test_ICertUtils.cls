@isTest
public with sharing class Test_ICertUtils extends TestUtils.TestClass {
	
	static testMethod void test_getCustomerBuildTemplate(){
		Mocks testData = new Mocks();
		Account a = testData.parentAccount;
		Opportunity o = testData.opportunity;
		Opportunity_Product__c oppProd = testData.opptyPrd;
		Building__c b = testData.building;

		test.startTest();
		integraWS.CreateICertParamsObj res1 = ICertUtils.getCustomerBuildTemplate(a, o, b, 'AEID', 'title', 'description', true);
		integraWS.CreateICertParamsObj res2 = ICertUtils.getCustomerBuildTemplate(a, o, b, 'AEID', 'title', 'description', false);
		test.stopTest();
	}

	static testMethod void test_getNetworkBuildTemplate(){
		Mocks testData = new Mocks();
		Building__c b = testData.building;
		
		test.startTest();
		integraWS.CreateICertParamsObj res = ICertUtils.getNetworkBuildTemplate(b, 'AEID', 'title', 'description', 'ownerSalesChannel', 'businessUnit', 'department', Date.today());
		test.stopTest();
	}

	static testMethod void test_CreateICerts(){
		test.startTest();
		List<ICertUtils.SFICertView> res = ICertUtils.CreateICerts(new List<integraWS.CreateICertParamsObj>(), 'session');
		test.stopTest();
	}

	static testMethod void test_CreateICertsAndCompleteRequestOrigStep(){
		test.startTest();
		List<ICertUtils.SFICertView> res = ICertUtils.CreateICertsAndCompleteRequestOrigStep(new List<integraWS.CreateICertParamsObj>(), 'session');
		test.stopTest();
	}

	static testMethod void test_GetICertsByIds(){
		test.startTest();
		List<ICertUtils.SFICertView> res = ICertUtils.GetICertsByIds(new List<Integer>());
		test.stopTest();
	}

	static testMethod void test_GetICertVIews(){
		test.startTest();
		List<ICertUtils.SFICertView> res = ICertUtils.GetICertViews(new List<integraWS.SFICertResponseView>{new integraWS.SFICertResponseView()});
		test.stopTest();
	}

	static testMethod void test_GetRoutingStepsByICertId(){
		test.startTest();
		List<ICertUtils.SFRoutingStepView> res = ICertUtils.GetRoutingStepsByICertId(1);
		test.stopTest();
	}

	static testMethod void test_GetRoutingStepViews(){
		test.startTest();
		List<ICertUtils.SFRoutingStepView> res = ICertUtils.GetRoutingStepViews(new List<integraWS.SFRequestApprovalView>{new integraWS.SFRequestApprovalView()});
		test.stopTest();
	}

}