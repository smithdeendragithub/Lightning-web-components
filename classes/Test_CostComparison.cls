@isTest
public with sharing class Test_CostComparison extends TestUtils.TestClass {

    static testMethod void testCostComparisonController(){
    	
    	Mocks testData = new Mocks();

    	test.startTest();
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.location);
    	CostComparisonController test_ctl = new CostComparisonController(sc);
    	
    	test_ctl.Recalculate();
    	test_ctl.AddTenRows(); 
    	
    	test_ctl.saveComparison();
    	    	
    	//Now test for the errors
    	CostComparisonController.wrapCostComparison wcc = test_ctl.CostComparisons[0];
    	
    	//Save the variables for future reference
    	String descr = wcc.opptyCostComparison.Description__c;
    	
    	wcc.opptyCostComparison.Description__c = null;
    	test_ctl.saveComparison();
    	wcc.opptyCostComparison.Description__c = descr;
    	
    	ApexPages.currentPage().getParameters().put('selectedComparisonId',null);
    	ApexPages.currentPage().getParameters().put('selectedComparisonIndex','0');
    	test_ctl.deleteComparison();
    	ApexPages.currentPage().getParameters().put('selectedComparisonId',testData.occ.Id);
    	test_ctl.deleteComparison();
    	
    	
    	test.stopTest();
    }
}