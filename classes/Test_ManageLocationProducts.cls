@isTest
public with sharing class Test_ManageLocationProducts extends TestUtils.TestClass {
	
    static testMethod void testController() {
        
        // create test data
        Mocks testData = new Mocks();
        
        //create our page reference
        PageReference pageReference = Page.ManageLocationProducts;
        pageReference.getParameters().put('opportunityId', testData.opportunity.Id);
        Test.setCurrentPage(pageReference);
        system.debug(testData.location);
        system.debug(testData.order);
        system.debug(testData.lstconfig);
		System.debug(testData.lstLineItems);
		System.debug(testData.serviceLocation);
        // create our controller
        ManageLocationProductsController manageLocationProductsController = new ManageLocationProductsController();
        
        // get opportunity / assert same as controller param
        System.assertEquals(testData.opportunity.Id, manageLocationProductsController.opportunity.Id);
        
        // get locations / assert some were created
        System.assert(manageLocationProductsController.opportunityLocations.size() > 0);
        
        test.startTest();
        
        // execute redirects/workflow
        manageLocationProductsController.getDefaultConfigName();
        //manageLocationProductsController.getTermSelectOptions();
        manageLocationProductsController.gotoOpportunity();
        manageLocationProductsController.gotoManageLocationConfigurations();
        manageLocationProductsController.gotoGeneratePDF();
        manageLocationProductsController.gotoCostCompare();
        manageLocationProductsController.gotoTurnDowns();
        
        //Create/Rename new Solution
        Apexpages.currentPage().getParameters().put('newSolutionLocation',testData.serviceLocation.id);
        Apexpages.currentPage().getParameters().put('newSolutionName','Test');
        Apexpages.currentPage().getParameters().put('newSolutionTerm','36');
        Apexpages.currentPage().getParameters().put('newSolutionAccess','EOCopper');
        Apexpages.currentPage().getParameters().put('newSolutionBandwidth','10');
        Apexpages.currentPage().getParameters().put('newSolutionDisplay','True');
        Apexpages.currentPage().getParameters().put('accountId', testData.parentAccount.id);
		ApexPages.currentPage().getParameters().put('sLocIDs', testData.location.Id);
        
        manageLocationProductsController.createNewSolution();
        
        // create config and start wizard
        Account noLocAccount = new Account(Name = 'NoLoc', ParentId = testData.opportunity.AccountId, ShippingCountry='US', ShippingCity = 'Portland', ShippingPostalCode = '97124', ShippingState = 'OR', ShippingStreet = '1234 Test');
        insert noLocAccount;
            
        //Expire something
        //testData.lstpricing[0].Expiration_Date__c = datetime.now()-1; 
        //update testData.lstpricing;
        
        /*
        //Needs to be rewritten
        manageLocationProductsController.ConfigId_deleteExpiredLineItems = testData.lstconfig[0].id;
        manageLocationProductsController.deleteExpiredLineItems();
        */
    
        //Delete
        manageLocationProductsController.param_solutionId = testData.lstconfig[0].id;
        manageLocationProductsController.deleteSolution();
        
		manageLocationProductsController.badDealText = 'test';
		OpportunityLocationConfiguration__c newsol = manageLocationProductsController.newSol;
		manageLocationProductsController.selectedServiceLocationName = 'test';
		manageLocationProductsController.selectedServiceLocationPhone = '5555555555';
		
		manageLocationProductsController.getIsSalesDirector();
		
		manageLocationProductsController.updateColo();
						
		manageLocationProductsController.ConfigId_deleteExpiredLineItems = testData.lstconfig[0].id;
		manageLocationProductsController.expiredLineItemlst = new List<OLI__c>();
		OLI__c delOLI = new OLI__c(MRC__c = 123, OpportunityLocationConfiguration__c=testData.lstconfig[1].id,  Qty__c=3, Price_Id__c='SP185CO65321TM0A876AV2291', PP_SalesProductExternalID__c='185', PP_Product_Pricing_Name__c='product1', Product_Family_Product__c='Basic Voice Services');
		insert delOLI;
		
		manageLocationProductsController.expiredLineItemlst.add(delOLI);
		manageLocationProductsController.deleteExpiredLineItems();
		
		
		String oppLocInfo = 'test';
		//manageLocationProductsController.mapSelectOptions.put(testdata.location.id,new SelectOption(testdata.location.id, oppLocInfo));
		//manageLocationProductsController.selectedLocID = testdata.location.id;
		//manageLocationProductsController.addSelectedLocation();
		
		//manageLocationProductsController.removeSelectedLocID = testData.location.Id;
		//manageLocationProductsController.removeSelectedLocation();
		
		pageReference.getParameters().put('sLocationId', testData.serviceLocation.Id);
		manageLocationProductsController.findLocationByServLocation(testData.serviceLocation.id);
		//manageLocationProductsController.getOpportunityLocationPhone();
		manageLocationProductsController.cancelSolution();
		manageLocationProductsController.getTestClass();
		manageLocationProductsController.saveScoreToOpp();
        test.stopTest();
    
    }
	
	static testMethod void allmethod() {
        Mocks testData = new Mocks();
		Test.startTest();
		//Test_CPQOLIControllerBase.setupPage_SelectProductFamilies(testData.lstconfig[0].Id);
        
	//	ProductWizardController pw = simulateNavigation();
		//pw.gotoLineItemNextStep();

		PageReference newpageReference = Page.ManageLocationProducts;
		newpageReference.getParameters().put('opportunityId', testdata.opportunity.Id);
		Test.setCurrentPage(newpageReference);
		ManageLocationProductsController c = new ManageLocationProductsController();
		//c.newSol;
		c.getIsAuthorityLevel();
		c.getIsOfferManagement();
		//c.getLocationSelectOptions();
		//c.getBandwidthSelectOptions();
		c.gotoGenerateNewServiceLoc();
		//c.getSelectedLocation();
		//c.setSelectedLocation(new List<String>{'test'}); 
		//c.getSelectTerm();
		//c.setSelectTerm('36');
		//c.getSelectBandwidth();
		//c.setSelectBandwidth('2');
		//c.getNewSolutionName();
		//c.setNewSolutionName('newsolution');
		//c.getDisplayOnPDF();
		//c.setDisplayOnPDF(true);
		
		ManageLocationProductsController.OpportunityLocation oppLoc = new ManageLocationProductsController.OpportunityLocation(testData.location, new Set<Id>(), new List<Service_Location__c>(), new Map<Id, List<OLI__c>>());
		oppLoc.createNewSolution('', '', '', false);
		//oppLoc.IsHasExpiredLineItems(null, null);
		
		try{
			c.gotoOrder();
		}catch (Exception ex){}
		
		try{
			ManageLocationProductsController.Solution newsolution= new ManageLocationProductsController.Solution('36',true,testData.lstconfig[0].Id,null);
		}catch (Exception ex){}
		
		try{
			ManageLocationProductsController.Solution newsolution1= new ManageLocationProductsController.Solution('second','36',true,testData.lstconfig[0].Id,'3',true, null);
		}catch (Exception ex){}
		
		try{
			ManageLocationProductsController.Solution newsolution2= new ManageLocationProductsController.Solution(testData.lstconfig[0],true,new List<OLI__c>{new OLI__c()});
		}catch (Exception ex){}

     	test.stopTest();
    }
	
    static testMethod void allmethod2() { 
        Mocks testData = new Mocks();
		
		system.debug(testData.lstconfig);
		system.debug(testData.lstLineItems);
		//PageReference pageReference = Page.SelectProductFamilies;
		//Test.setCurrentPage(pageReference);
		
		// test controller constructor page 2
		//pageReference = Page.SelectProductFamilies;
		//pageReference.getParameters().put('opportunityLocationConfigurationId', testData.lstconfig[0].Id);
		//Test.setCurrentPage(pageReference);
		//ProductWizardController pw= simulateNavigation();
		List<OLI__c> lstoliTodelete = [Select id,Dq__c from OLI__c where OpportunityLocationConfiguration__c=:testData.lstconfig[0].Id];
		
		Test.startTest();
		delete lstoliTodelete;
		//pw.gotoLineItemNextStep();

		PageReference newpageReference = Page.ManageLocationProducts;
		newpageReference.getParameters().put('opportunityId', testdata.opportunity.Id);
		Test.setCurrentPage(newpageReference);
		ManageLocationProductsController manageLocationConfigurationsController = new ManageLocationProductsController();

		//manageLocationConfigurationsController.gotoCreateICB();
		//manageLocationConfigurationsController.addSelectedLocation();
		//manageLocationConfigurationsController.removeSelectedLocation();
		manageLocationConfigurationsController.approveActiveSolutions();

     	test.stopTest();
    }

	static testMethod void testActiveHolds(){
		Mocks testData = new Mocks();
        
        //create our page reference
        PageReference pageReference = Page.ManageLocationProducts;
        pageReference.getParameters().put('opportunityId', testData.opportunity.Id);
        Test.setCurrentPage(pageReference);
        system.debug(testData.location);
        system.debug(testData.order);
        system.debug(testData.lstconfig);
		System.debug(testData.lstLineItems);
		System.debug(testData.serviceLocation);
        // create our controller
        ManageLocationProductsController manageLocationProductsController = new ManageLocationProductsController();
        
        // get opportunity / assert same as controller param
        System.assertEquals(testData.opportunity.Id, manageLocationProductsController.opportunity.Id);
        
        // get locations / assert some were created
        System.assert(manageLocationProductsController.opportunityLocations.size() > 0);
        
        test.startTest();
        
        // execute redirects/workflow
        manageLocationProductsController.getDefaultConfigName();
        //manageLocationProductsController.getTermSelectOptions();
        manageLocationProductsController.gotoOpportunity();
        manageLocationProductsController.gotoManageLocationConfigurations();
        manageLocationProductsController.gotoGeneratePDF();
        manageLocationProductsController.gotoCostCompare();
        manageLocationProductsController.gotoTurnDowns();
        
        //Create/Rename new Solution
        Apexpages.currentPage().getParameters().put('newSolutionLocation',testData.serviceLocation.id);
        Apexpages.currentPage().getParameters().put('newSolutionName','Test');
        Apexpages.currentPage().getParameters().put('newSolutionTerm','36');
        Apexpages.currentPage().getParameters().put('newSolutionAccess','EOCopper');
        Apexpages.currentPage().getParameters().put('newSolutionBandwidth','10');
        Apexpages.currentPage().getParameters().put('newSolutionDisplay','True');
        Apexpages.currentPage().getParameters().put('accountId', testData.parentAccount.id);
		ApexPages.currentPage().getParameters().put('sLocIDs', testData.location.Id);
        
        manageLocationProductsController.createNewSolution();
        
        manageLocationProductsController.param_solutionId = testData.lstconfig[0].id;
        manageLocationProductsController.renameSolution();
        
        //Make Active
        manageLocationProductsController.param_solutionId = testData.lstconfig[0].id;
        manageLocationProductsController.param_locationId = testData.location.id;
        manageLocationProductsController.makeSolutionActive();
        
                
        //Holds
        manageLocationProductsController.param_locationId = testData.location.id;
        manageLocationProductsController.placeOnHold();
        manageLocationProductsController.takeOffHold();
        
        manageLocationProductsController.param_solutionId = testData.lstconfig[0].id;
        manageLocationProductsController.updateSolutionTerm();
        
          
        //Delete
        manageLocationProductsController.param_solutionId = testData.lstconfig[0].id;
        manageLocationProductsController.deleteSolution();
        
		
		pageReference.getParameters().put('sLocationId', testData.serviceLocation.Id);
		manageLocationProductsController.findLocationByServLocation(testData.serviceLocation.id);
		//manageLocationProductsController.getOpportunityLocationPhone();
		manageLocationProductsController.cancelSolution();
		test.stopTest();
	}
    
	//public static ProductWizardController simulateNavigation() {
	//	return Test_CPQOLIControllerBase.simulateNavigation(new Set<String>{'Colocation Services'}, new Set<String>{'VPN Solutions', 'Colocation Services'});
   // }
}