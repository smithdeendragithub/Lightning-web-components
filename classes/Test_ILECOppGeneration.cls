@isTest
public with sharing class Test_ILECOppGeneration extends TestUtils.TestClass {
	
	static testMethod void testILECOppGeneration(){
		Mocks testData = new Mocks();
        Account a = testData.parentAccount;
		a.ShippingStreet = '1201 ne lloyd blvd';
		a.ShippingCity = 'portland';
		a.ShippingState = 'OR';
		a.ShippingPostalCode = '97232';
		update a;
		        
		Opportunity opp = testData.opportunity;
		opp.type = 'New Logo';
		opp.StageName = 'Identification';
		opp.RecordTypeId = '0121A000000QeQ9QAK';
		update opp;
		Service_Location__c sLoc = testData.serviceLocation;
		
		Order__c o = testData.order;

		Contact cont = new Contact();
		cont.AccountId = a.Id;
		cont.FirstName = 'test';
		cont.LastName = 'guy';
		cont.Email = 'test@test.com';
		insert cont;
        test.startTest();
		
		PageReference pageReference = Page.ILECOpportunityGeneration;
		pageReference.getParameters().put('accountId', a.Id);
		
		pageReference.getParameters().put('streetNumber', '1201');
		pageReference.getParameters().put('street', 'NE LLOYD BLVD');
		pageReference.getParameters().put('city', 'Portland');
		pageReference.getParameters().put('state', 'OR');
		pageReference.getParameters().put('postalCode', '97232');
		pageReference.getParameters().put('latitude', '45.5296809');
		pageReference.getParameters().put('longitude', '-122.6532694');
		
		Test.setCurrentPage(pageReference);        
		ILECOpportunityGeneration con = new ILECOpportunityGeneration();
		con.ResponsiblePartyId = cont.Id;
		List<SelectOption> ctslst = con.contactList;
		//con.CreateLocation();
		con.AddProduct();
		con.Finalize();
		con.ValidateAddressesAndRedirectToOppIntegrationPage();
		Integer MRR = con.MRR;
		
		ILECOpportunityGeneration.TreeViewImplementation tv = new ILECOpportunityGeneration.TreeViewImplementation(a, testData.serviceLocation, opp);
		tv.getNodes();
		tv.getIconMap();
		
		/*opp.Type = 'New Logo';
		opp.StageName = OpportunityUtils.STAGE_QUALIFIED;
		update opp;
		Service_Location__c sloc = testData.serviceLocation;
		con = new ILECOpportunityGeneration();*/
		
		
		test.stopTest();
	}
    
    static testmethod void testCreateLocation(){
        Test.startTest();
        Mocks TestData = new Mocks();
        ApexPages.currentPage().getParameters().put('streetNumber', '1201');
		ApexPages.currentPage().getParameters().put('street', 'NE LLOYD BLVD');
		ApexPages.currentPage().getParameters().put('city', 'Portland');
		ApexPages.currentPage().getParameters().put('state', 'OR');
		ApexPages.currentPage().getParameters().put('postalCode', '97232');
		ApexPages.currentPage().getParameters().put('latitude', '45.5296809');
		ApexPages.currentPage().getParameters().put('longitude', '-122.6532694');
        ApexPages.currentPage().getParameters().put('country', 'CA');
        ApexPages.currentPage().getParameters().put('accountId', TestData.parentAccount.Id);
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MArea;
        
        ILECOpportunityGeneration instance = new ILECOpportunityGeneration();
        System.AssertNotEquals(instance.AddProduct(), null);         
        Test.stopTest();
    }
}