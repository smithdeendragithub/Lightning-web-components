@isTest
public with sharing class Test_CloneCostComparison extends TestUtils.TestClass {
	
    static testMethod void testController() {
    	
    	CloneCostComparisonController cloneCostComparisonController = null;
    	
    	// create test data
        Mocks testData = new Mocks();
        
        // test controller config constructor validation
        PageReference pageReference = Page.CloneCostComparison;
        Test.setCurrentPage(pageReference);
        try {
            cloneCostComparisonController = new CloneCostComparisonController();
        } catch(CloneCostComparisonController.CloneCostComparisonControllerException e) {}
        try {
            pageReference.getParameters().put('id', '');
            cloneCostComparisonController = new CloneCostComparisonController();
        } catch(CloneCostComparisonController.CloneCostComparisonControllerException e) {}
        try {
            pageReference.getParameters().put('id', 'a0aL00000008TQQ');
            cloneCostComparisonController = new CloneCostComparisonController();
        } catch(CloneCostComparisonController.CloneCostComparisonControllerException e) {}
        
        // construct controller
        pageReference.getParameters().put('id', testData.location.Id);
        cloneCostComparisonController = new CloneCostComparisonController();
        
        // exercise general workflows
        cloneCostComparisonController.gotoCostComparison();
        
        // perform a garbage search (expect no results)
        cloneCostComparisonController.searchMySolutionsOnly = true;
    	cloneCostComparisonController.searchOpportunityName = 'testasdasd';
    	cloneCostComparisonController.searchAccountName = 'testasdasd';
    	cloneCostComparisonController.searchMaxResults = 100;
    	cloneCostComparisonController.searchSolutions();
    	System.assert(cloneCostComparisonController.searchResults.isEmpty());
    	
    	// find ourself
    	cloneCostComparisonController.searchMySolutionsOnly = false;
    	cloneCostComparisonController.searchOpportunityName = '';
    	cloneCostComparisonController.searchAccountName = testData.location.Name;
    	cloneCostComparisonController.searchMaxResults = 100;
    	cloneCostComparisonController.searchSolutions();
    	System.assert(!cloneCostComparisonController.searchResults.isEmpty());
    	
    	// clone ourself
    	cloneCostComparisonController.ConfigId_cloneConfig = testData.location.Id;
    	cloneCostComparisonController.cloneConfig();    	
    }
}