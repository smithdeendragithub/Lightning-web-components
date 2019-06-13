@isTest
public with sharing class Test_CustomerIntegration extends TestUtils.TestClass {
	
	private static Account a;
	private static Contact c;
	private static Opportunity o;
	private static Order__c ord;
	private static Service_Location__c sLoc;
	
	static testMethod void testController(){
		
		CustomerIntegrationController cic = getTestData(false, false);
		
		system.assert(string.isEmpty(cic.noIntegrationReason), string.format('No integration reason expected to be empty but found "{0}"', new List<String>{cic.noIntegrationReason}));
		
		cic.updateBillableFlags();
		
		System.debug(cic.getTestClass());
	}
	
	static testMethod void testAddressParsing(){
		
		CustomerIntegrationController cic = getTestData(true, false);
		
		PageReference pageReference = ApexPages.currentPage();
        pageReference.getParameters().put('streetNumber', '1234');
        pageReference.getParameters().put('street', 'fake');
        pageReference.getParameters().put('suite', '1');
        pageReference.getParameters().put('city', 'Coolsville');
        //MNK Added Aug 2017
        pageReference.getParameters().put('country', 'US');
        pageReference.getParameters().put('state', 'OR');
        pageReference.getParameters().put('postalCode', '54321');
        pageReference.getParameters().put('latitude', '54');
        pageReference.getParameters().put('longitude', '-111');
        pageReference.getParameters().put('success', 'true');
		
		cic.accountAddressParsed();
		cic.updateAccountAddresses();
	}
	
	static testMethod void testCustomerDetails(){
		
		CustomerIntegrationController cic = getTestData(true, true);
		
		test.startTest();
		
		system.assert(string.isEmpty(cic.noIntegrationReason), string.format('No integration reason expected to be empty but found "{0}"', new List<String>{cic.noIntegrationReason}));
		
    	cic.updateCustomerDetails();
    	cic.responsibleParty.Contact__c = c.Id;
		cic.selectedCustomers = new List<String>{a.Id};
    	cic.setResponsibleParty();
        String one= cic.actDef_OpenCustomerDetail;
        String two= cic.actDef_OpenCustomerDetailInNewTab;
        String three= cic.actDef_OpenServiceLocation;
        String four= cic.actDef_OpenServiceLocationInNewTab;
	}
	
	static testMethod void testIntegrate(){
		
		CustomerIntegrationController cic = getTestData(true, false);
		Id cdID = [select Customer_Detail__c from Account where Id =: a.Id].Customer_Detail__c;
		insert new Customer_Contact__c(Contact__c = c.Id
										,Contact_Type__c = 'Responsible Party'
										,Customer_Detail__c = cdID);
		
		RecordType rt = [select Id from RecordType where sObjectType = 'Customer_Setting__c' and DeveloperName = 'Bill_Cycle_Schedule'];
		
		Customer_Setting__c bc = new Customer_Setting__c(Name='BC', RecordTypeId=rt.Id, External_ID__c='9999', Value__c='9999');
		insert bc;
		
		Id ssrt = null;
		Id tirt = null;
		for(RecordType r : [select Id, DeveloperName from RecordType where sObjectType = 'Customer_Setting__c' and (DeveloperName = 'Subscriber_Setting' or DeveloperName = 'Tax_Information')]){
			if(r.DeveloperName == 'Subscriber_Setting') ssrt = r.Id;
			if(r.DeveloperName == 'Tax_Information') tirt = r.Id;
		}
		
		Customer_Setting__c ti = new Customer_Setting__c(Name='TaxInfo', RecordTypeId=tirt, Customer_Detail__c = cdID, Start_Date__c=Date.today(), End_Date__c=Date.today().addDays(1));
		insert ti;
		
		Customer_Setting__c ss = new Customer_Setting__c(Name='SubSetting', RecordTypeId=ssrt, Customer_Detail__c = cdID);
		insert ss;
		
		Note__c n = new Note__c(Account__c=a.Id, Description__c='Note');
		insert n;
		
		List<Customer_Detail__c> cdList = [select Id from Customer_Detail__c];
		for(Customer_Detail__c cd : cdList)
			cd.Bill_Cycle__c = bc.Id;
		update cdList;
		
    	cic.integrate();
	}
	
 	static testMethod void testTreeView() {
		
		CustomerIntegrationController cic = getTestData(true, false);
		
		cic.loadMore_divID = 'integrationHierarchy';
		System.debug(cic.loadNodes());
		cic.loadMore_path = a.Id + ':{Contacts}';
		cic.loadMore_currentlyLoaded = '1,2';
		System.debug(cic.loadNodes());
		System.debug(cic.ActionMappings);
		System.debug(cic.IconMappings);
		System.debug(cic.AllJSONTrees);
		System.debug(cic.TreesNodeCounts);
    }
	
	private static CustomerIntegrationController getTestData(Boolean generateDetails, Boolean integrationOnlyMode){
        Mocks testData = new Mocks();
    	
		a = testData.parentAccount;
		a.BillingCity = 'Coolsville';
		a.BillingCountryCode = 'US';
		a.BillingPostalCode = '54321';
        //MNK Added Aug 2017
        a.BillingCountryCode = 'US';
		a.BillingState = 'OR';
		a.BillingStreet = '1234 Coolguy Lane';
		update a;
		
		c = new Contact(
			FirstName = 'Mike'
			,LastName = 'Haggar'
			,Title = 'Mayor'
			,AccountId = a.Id
			,Email = 'test@test.com'
		);
		insert c;
		
		sLoc = new Service_Location__c(Account__c = a.Id, Name = 'Test Loc', Location__c = testData.loc.Id);
		insert sLoc;
		
		delete [select Id from Service_Location__c where Account__c =: a.Id and Id !=: sLoc.Id];	//Just work with the one we made
		
		sObjectType sLocType = Service_Location__c.getsObjectType();
		sLoc = ((List<Service_Location__c>)ApexUtils.retrieveFullObjects(sLocType, 'Id = \'' + sLoc.Id + '\''))[0];
		
		Service_Location__c child = (Service_Location__c)ApexUtils.deepCopyFields(sLocType, sLoc, new Service_Location__c(), null);
		child.Parent_Service_Location__c = sLoc.Id;
		insert child;
		
		if(generateDetails){
			CustomerDetailUtils.updateCustomerDetails(new List<Set<Id>>{new Set<Id>{a.Id, sLoc.Id}, new Set<Id>{child.Id}}, new Map<Id, List<Customer_Contact__c>>{child.Id=>new List<Customer_Contact__c>{new Customer_Contact__c(Contact__c=c.Id, Contact_Type__c=ICCWrapper.ResonsiblePartyContactType), new Customer_Contact__c(Contact__c=c.Id, Contact_Type__c='Authorized User')}});
			//Customer_Detail__c cd = [select Id, Customer_Detail__r.Id from Service_Location__c where Id=: sLoc.Id limit 1].Customer_Detail__r;
			//cd.ICC_Subscriber_ID__c = '-999';
			//update cd;
		}
		
		if(integrationOnlyMode){
			ord = new Order__c(Account__c = a.Id, RecordTypeId = OrderUtils.IntegrationOnlyRecordTypeID);
			insert ord;
		}
		else{
			OpportunityTriggers.triggerDisabled = true;
	    	o = testData.opportunity;
			Opportunity_Location__c opLoc = testData.location;
			
			opLoc.Service_Location__c = sLoc.Id;
			update opLoc;
			
			//o.StageName = OpportunityUtils.STAGE_CLOSED_WON;
			o.StageName = OpportunityUtils.STAGE_5;
			o.CloseDate = Date.today();
			o.Contract_Signed_Date__c = Date.today();
			o.LOA_Signed_By__c = testData.parentAccountContact.Id;
			o.CPE_Amount__c = 9.99;
			o.Product_Family__c = 'Colocation';
			o.Product__c = 'Colocation Services';
			o.Term__c = '12';
			o.Opportunity_Product__c = 'thing,stuff,other crap';
			o.Bypass_Validation__c = true;
			o.UC_Specialist__c =testData.user.Id;
			update o;			
			
			RecordType oppProdManual = [select Id from RecordType where sObjectType='Opportunity_Product__c' and DeveloperName='Manual_Entry'];
			Opportunity_Product__c oppProd = new Opportunity_Product__c(Opportunity__c=o.Id, Primary_Service_Location__c=sLoc.Id, Sales_Product__c='Some Product', RecordTypeId=oppProdManual.Id, Solution__c=testData.lstconfig[0].Id);
			test.startTest();	//Hack
			insert oppProd;
			
			ord = testData.order;
		}
		
		insert new Custom_Permissions__c(Name = 'SysAdmin', Group__c = 'System Administrator', Group_Type__c = 'Profile', Can_Integrate_Subscribers__c = true, Can_Create_Hierarchy__c = true);
		
    	PageReference pageReference = Page.CustomerIntegration;
        pageReference.getParameters().put('id', ord.Id);
        Test.setCurrentPage(pageReference);
		
		CustomerIntegrationController cic = new CustomerIntegrationController();
		//System.assert(cic.canIntegrate, 'The current User context does not have the proper permissions to use this page.');
    	return cic;
	}
}