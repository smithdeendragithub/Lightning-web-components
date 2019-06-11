@isTest
public with sharing class Test_GlobalActions extends TestUtils.TestClass {
	
    static testMethod void testCreateBuildOrder() {
    	Mocks testData = new Mocks();
		
		Building__c b = testData.building;
		Location__c l = testData.loc;
		
    	test.startTest();
    	
    	system.assert(testData.mpProvProd.get('Standard Build') == null, 'Provisioning Product named "Standard Build" exists to associate to a build order');
    	GlobalActions.CreateBuildOrder(b.Id);
    	
    	test.stopTest();
    }
}