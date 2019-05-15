@isTest
public with sharing class Test_CloneSolution extends TestUtils.TestClass {

    static testMethod void testController() {
        
        CloneSolutionController cloneSolutionController = null;
        
        // create test data
        Mocks testData = new Mocks();
        Test.startTest();
        // test controller config constructor validation
        PageReference pageReference = Page.CloneSolution;
        Test.setCurrentPage(pageReference);
        try {
            cloneSolutionController = new CloneSolutionController();
        } catch(CloneSolutionController.CloneSolutionControllerException e) {}
        try {
            pageReference.getParameters().put('opportunityLocationConfigurationId', '');
            cloneSolutionController = new CloneSolutionController();
        } catch(CloneSolutionController.CloneSolutionControllerException e) {}
        try {
            pageReference.getParameters().put('opportunityLocationConfigurationId', 'a0aL00000008TQQ');
            cloneSolutionController = new CloneSolutionController();
        } catch(CloneSolutionController.CloneSolutionControllerException e) {}
        
        // construct controller
        pageReference.getParameters().put('opportunityLocationConfigurationId', testData.lstconfig[0].Id);
        cloneSolutionController = new CloneSolutionController();
        
        // exercise general workflows
        
        cloneSolutionController.gotoManageLocationProducts();
        
        // perform a garbage search (expect no results)
        cloneSolutionController.searchMySolutionsOnly = true;
        cloneSolutionController.searchSolutionName = 'test';
        cloneSolutionController.searchOpportunityName = 'test';
        cloneSolutionController.searchAccountName = 'test';
        cloneSolutionController.searchExcludeEmptySolutions = true;
        cloneSolutionController.searchMaxResults = 100;
        cloneSolutionController.searchSolutions();
        System.assert(cloneSolutionController.searchResults.isEmpty());
        
		List<OLI__c> olis = testData.lstLineItems;
		
        // find ourself
		 cloneSolutionController.searchMySolutionsOnly = false;
        cloneSolutionController.searchSolutionName = testData.lstconfig[0].Name;
        cloneSolutionController.searchOpportunityName = '';
        cloneSolutionController.searchAccountName = '';
        cloneSolutionController.searchExcludeEmptySolutions = false;
        cloneSolutionController.searchMaxResults = 100;
		cloneSolutionController.cloneFromSolutionID = 'null';
        cloneSolutionController.searchSolutions();	
        System.debug(cloneSolutionController.searchResults);
		
        System.assert(!cloneSolutionController.searchResults.isEmpty());
        
        // clone ourself
		System.debug('testData.lstconfig[0].Id: ' + testData.lstconfig[0].Id);
        cloneSolutionController.ConfigId_cloneConfig = testData.lstconfig[0].Id;
        cloneSolutionController.Mode_cloneConfig = 'edit';
		cloneSolutionController.solutionsToCloneTo = new List<String>();
        cloneSolutionController.cloneConfig();
		
		CloneSolutionController.LineItemAssembler lia = new CloneSolutionController.LineItemAssembler();
		CloneSolutionController.LineItem li = new CloneSolutionController.LineItem();
		li = lia.fromOLI(testData.lstLineItems[0], testData.marketArea.Id);
		test.stopTest();
    }
    
    static testmethod void testcloneableSolutionsJSON(){
        CloneSolutionController controller = new CloneSolutionController();
        Map<String,OpportunityLocationConfiguration__c> mapping = new Map<String,OpportunityLocationConfiguration__c>();
        mapping.put('Key string with null value', null);
        controller.cloneableSolutions = mapping;
     	System.AssertEquals(controller.cloneableSolutionsJSON, JSON.serialize(mapping, true));   
    }
    
    static testmethod void testcreatSolution(){
        CloneSolutionController controller = new CloneSolutionController();
        controller.opportunityID = 'OPP ID 12345';
        System.AssertEquals(controller.createNewSolution().getParameters().get('OpportunityID'), 'OPP ID 12345');
        System.AssertEquals(controller.createNewSolution().getParameters().values().size(),2);        
    }
    
    static testmethod void testcloneConfig1(){
        Test.startTest();
        
        CloneSolutionController controller = new CloneSolutionController();
        Mocks TestData = new Mocks();
        Map<String,OpportunityLocationConfiguration__c> mapping = new Map<String,OpportunityLocationConfiguration__c>();
        mapping.put(String.valueOf(TestData.lstconfig[0].Id), TestData.lstconfig[0]);
        TestData.lstconfig.remove(1);
        
        controller.searchExcludeEmptySolutions = false;
        controller.searchMySolutionsOnly = false;
        controller.searchSolutionName = '';
        controller.searchOpportunityName = '';
        controller.searchAccountName = '';
        controller.cloneFromSolutionID = null;
        
        OLI__c LItem = new OLI__c(OpportunityLocationConfiguration__c = TestData.lstconfig[0].Id, SPC_Sales_Product_Component_Id__c = 0.602, Approval_Status__c = 'Approved');
        insert LItem;
        controller.ConfigId_cloneConfig = String.valueOf(TestData.lstconfig[0].Id);
        controller.cloneableSolutions = mapping;
        controller.solutionsToCloneTo = new list<String>{TestData.lstconfig[0].Id};
        controller.searchMaxResults = 1;

        SPC_Component__c fieldReq = new SPC_Component__c();
        insert fieldReq;
        SPC_Pricing__c SPCPricing = new SPC_Pricing__c(is_expired__c = false, Term__c = 0, Market__c = TestData.lstconfig[0].Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c, Sales_Product_Component_ID__c = 0.602, SPC_Component__c = fieldReq.Id);
        insert SPCPricing;
        SPC_Pricing__c SPCPricing2 = new SPC_Pricing__c(is_expired__c = false, Term__c = 0, Market__c = TestData.lstconfig[0].Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c, Sales_Product_Component_ID__c = 0.602, SPC_Component__c = fieldReq.Id);
        insert SPCPricing2;
        controller.searchSolutions();
        //System.AssertEquals(controller.cloneConfig(), controller.gotoManageLocationProducts());
        System.AssertNotEquals(controller.cloneConfig(), null);
        System.Assert([Select Id From OLI__c Where Id =: LItem.Id].isEmpty());
              
        Test.stopTest();       
    }
    
    static testmethod void testcloneConfig2(){
        Test.startTest();
        
        CloneSolutionController controller = new CloneSolutionController();
        Mocks TestData = new Mocks();
        Map<String,OpportunityLocationConfiguration__c> mapping = new Map<String,OpportunityLocationConfiguration__c>();
        mapping.put(String.valueOf(TestData.lstconfig[0].Id), TestData.lstconfig[0]);
        TestData.lstconfig.remove(1);
        
        controller.searchExcludeEmptySolutions = false;
        controller.searchMySolutionsOnly = false;
        controller.searchSolutionName = '';
        controller.searchOpportunityName = '';
        controller.searchAccountName = '';
        controller.cloneFromSolutionID = null;
        
        OLI__c LItem = new OLI__c(OpportunityLocationCOnfiguration__c = TestData.lstconfig[0].Id, SPC_Sales_Product_Component_Id__c = 0.602, Approval_Status__c = 'Approved');
        insert LItem;
        controller.ConfigId_cloneConfig = String.valueOf(TestData.lstconfig[0].Id);
        controller.cloneableSolutions = mapping;
        controller.solutionsToCloneTo = new list<String>{TestData.lstconfig[0].Id};
        controller.searchMaxResults = 1;

        SPC_Component__c fieldReq = new SPC_Component__c();
        insert fieldReq;
        SPC_Pricing__c SPCPricing = new SPC_Pricing__c(is_expired__c = false, Term__c = 0, Market__c = TestData.lstconfig[0].Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c, Sales_Product_Component_ID__c = 0.602, SPC_Component__c = fieldReq.Id);
        insert SPCPricing;
        
        SPC_Product__c SPCProd = new SPC_Product__c(SalesProductExternalID__c = 123, Hide_In_Wizard__c = true);
        insert SPCProd;
        LItem.PP_SalesProductExternalID__c = '123';
        update LItem;
        controller.searchSolutions();
        System.AssertEquals(controller.cloneConfig(), null);
        System.Assert([Select Id From OLI__c Where Id =: LItem.Id].isEmpty());
        
        LItem.PP_SalesProductExternalID__c = null;
        undelete LItem;
        upsert LItem;
        SPCPricing.Term__c = null;
        update SPCPricing;
        controller.searchSolutions();
        System.AssertEquals(controller.cloneConfig(), null);
        System.Assert([Select Id From OLI__c Where Id =: LItem.Id].isEmpty());
        
        Test.stopTest();
    }
}