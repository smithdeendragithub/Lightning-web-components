@isTest
public with sharing class Test_NewOpportunityRedirect extends TestUtils.TestClass {
	
    static testmethod void testNewOpportunityRedirect(){
    	Mocks mocks = new Mocks();
    	
        test.startTest();
        
    	ApexPages.StandardController controller = new ApexPages.StandardController(new Opportunity());
    	NewOpportunityRedirect nor = new newOpportunityRedirect(controller);
    	nor.sourceId = mocks.opportunity.Id;
    	nor.newOpportunity();
    	nor.sourceId = mocks.parentAccount.Id;
    	nor.newOpportunity();
    	
    	test.stopTest();
    }
}