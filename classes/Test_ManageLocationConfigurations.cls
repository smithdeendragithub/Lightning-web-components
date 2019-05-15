@isTest
public with sharing class Test_ManageLocationConfigurations extends TestUtils.TestClass {
	
    static testMethod void testController() {
        // create test data
        Market_Area__c marketArea = new Market_Area__c(Name='asdf', MarketAreaExternalId__c='qwer1234');
        insert marketArea;
        Account grandparentAccount = new Account(Name = 'Grandparent', ShippingCountry='US', ShippingState = 'OR', ShippingCity = 'Portland', ShippingPostalCode = '97124', ShippingStreet = '1234 Test', Phone = '800-123-1234' );
        insert grandparentAccount;
        Account parentAccount = new Account(Name = 'Parent', ParentId = grandparentAccount.Id, ShippingCountry='US', ShippingState = 'OR', ShippingCity = 'Portland', ShippingPostalCode = '97124', ShippingStreet = '1234 Test' );
        insert parentAccount;
        Account childAccount = new Account(Name = 'Child', ParentId = parentAccount.Id, ShippingCountry='US', ShippingState = 'OR', ShippingCity = 'Portland', ShippingPostalCode = '97124', ShippingStreet = '1234 Test' );
        insert childAccount;
        Opportunity opportunity = new Opportunity(RecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Retail').getRecordTypeID() ,Name = 'Test Opp',  Product_Family__c = 'Data Services', Product__c = 'Elan', Type= 'New Logo', Oppty_Sub_Type__c='New Logo',StageName = OpportunityUtils.STAGE_QUALIFIED, CloseDate = Date.today().addDays(30), AccountId = grandparentAccount.Id);
        insert opportunity;
        Order__c ord = new Order__c(Opportunity__c = opportunity.Id);
        insert ord;
        Opportunity_Location__c opportunityLocations = new Opportunity_Location__c(Name = 'Parent', Opportunity__c = opportunity.id, Order__c = ord.Id);
        insert opportunityLocations;
        
        RecordType rtTechInfo = [select Id from RecordType WHERE SobjectType = 'Technical_Information__c' and DeveloperName != 'Features_Schedule' limit 1];
        
        Technical_Information__c technicalInfos = new Technical_Information__c(Name = '02-Features_Schedule', Opportunity_Site__c = opportunityLocations.Id, RecordTypeId = rtTechInfo.Id);
        //create our page reference
        PageReference pageReference = Page.ManageLocationConfigurations;
        pageReference.getParameters().put('opportunityId', opportunity.Id);
        Test.setCurrentPage(pageReference);
        
        // create our controller 
        ManageLocationConfigurationsController manageLocationConfigurationsController = new ManageLocationConfigurationsController();
        
        // workflow accessor only tests
        manageLocationConfigurationsController.gotoManageLocationProducts();
        manageLocationConfigurationsController.gotoGeneratePDF();
        
        manageLocationConfigurationsController.TechInfoRecordTypeId_gotoTechInfo = rtTechInfo.Id;
        manageLocationConfigurationsController.gotoTechInfo();
    }
    
    static testmethod void testgotoTechInfoDocument(){
        Test.startTest();
        Mocks TestData = new Mocks();
        ApexPages.currentPage().getParameters().put('opportunityId', TestData.opportunity.Id);
        manageLocationConfigurationsController controller = new manageLocationCOnfigurationsController();
        System.assertEquals(controller.gotoTechInfoDocument(), null);       
        Test.stopTest();
    }
    
    static testmethod void testsetUpProductFamily(){
        Test.startTest();
        // Data Setup
        Mocks TestData = new Mocks();
        ApexPages.currentPage().getParameters().put('opportunityId', TestData.opportunity.Id);
        Opportunity_Location__c loc = TestData.location;
        OpportunityLocationConfiguration__c sol = TestData.lstconfig[0];
        OLI__c LineItem = TestData.lstLineItems[0];
        SPC_Product__c SPCProd = new SPC_Product__c(name = TestData.lstLineItems[0].Product_Family_Product__c, SalesProductExternalID__c = 123);
        insert SPCProd;
        
        // Let contructor call setUpProductFamily
        manageLocationConfigurationsController controller = new manageLocationCOnfigurationsController();
        // Call some other functions to run them with data
		controller.LocationId_gotoTechInfo = TestData.location.Id;
        controller.gotoTechInfo();
        controller.gotoOpportunity();
        
        // Cover variables in wrapTI
        manageLocationConfigurationsController.wrapTI inst = new manageLocationConfigurationsController.wrapTI(new Technical_Information__c(), 'display');
        inst.documentName = 'DocName';
        inst.overrideDisplayName = 'overRideName';
        Test.stopTest();
    }

}