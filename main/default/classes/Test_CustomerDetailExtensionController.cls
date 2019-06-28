@isTest(SeeAllData=true)
public with sharing class Test_CustomerDetailExtensionController extends TestUtils.TestClass {
	
 	static testMethod void testControllerCoverage() {
        Mocks testData = new Mocks();
    	
    	Customer_Detail__c cd = test_setupTestData(testData.loc.Id, testData.parentAccount, testData.serviceLocation);
		cd.Disputed_Amount__c = 1.0;	//Let it hit the reset to zero code
		
		Building_Address_Format__c baf = new Building_Address_Format__c();
		insert baf;
		
		Building__c b = testData.building;
		b.MSAG_Address_Format__c = baf.Id;
		b.Tax_Main_Address_Format__c = baf.Id;
		update b;
		
    	Map<String, Id> rts = new Map<String, Id>();
    	for(RecordType rt : [select DeveloperName, Id from RecordType where DeveloperName in ('Collection_Code')])
    		rts.put(rt.DeveloperName, rt.Id);
		
		List<Customer_Setting__c> csList = new List<Customer_Setting__c>{
								    		new Customer_Setting__c(RecordTypeId=rts.get('Collection_Code'), External_ID__c='1', Value__c='1')
								    	};
		insert csList;
    	
    	//Hit integration trigger code
    	cd.Past_Due__c = true;
    	update cd;
		
    	test.startTest();
    	
    	//CustomerDetailExtensionController.AddressFormat format = new CustomerDetailExtensionController.AddressFormat(new CustomerDetailExtensionController.LocationAddress('addr name', testData.loc, null, 'addr'), new Building_Address_Format__c());
    	
        PageReference pageReference = Page.CustomerDetailExtensionController;
        Test.setCurrentPage(pageReference);
        
		Apexpages.StandardController sc = new Apexpages.StandardController(cd);
    	CustomerDetailExtensionController ec = new CustomerDetailExtensionController(sc);
    	ec.marketAreaUpdated();
    	ec.marketTypeUpdated();
		
		ec.customerDetail.Collection_Code__c = csList[0].Id;
    	ec.doSave();
    	
        pageReference.getParameters().put('streetNumber', '1234');
        pageReference.getParameters().put('street', 'fake');
        pageReference.getParameters().put('suite', '1');
        pageReference.getParameters().put('city', 'Coolsville');
        //MNK Added Aug 2017
        pageReference.getParameters().put('country', 'US');
        pageReference.getParameters().put('state', 'OR');
        pageReference.getParameters().put('postalCode', '54321');
        pageReference.getParameters().put('latitude', '111');
        pageReference.getParameters().put('longitude', '-111');
        pageReference.getParameters().put('success', 'true');
    	
    	pageReference.getParameters().put('addressIDs', 'Billing_Main,Customer_Main_Address__c');
    	pageReference.getParameters().put('locationID', cd.Customer_Main_Address__c);
		ec.validateAddress();
		for(CustomerDetailExtensionController.LocationAddress address : ec.addresses){
			address.canUpdateToValidatedAddress = true;
			address.RoomSuite = 'Something else';
		}
    	ec.updateAddressesFromValidatedAddress();
    	//pageReference.getParameters().put('addressIDs', 'Billing_Main');
    	ec.updateAddresses();
    	
        pageReference.getParameters().put('linkID', string.valueOf(testData.grandChildAccount.Id));
    	ec.linkToObject();
    	Service_Location__c newLoc = new Service_Location__c(Name='NewLoc', Location__c = testData.loc.Id, Account__c = testData.grandChildAccount.Id);
    	insert newLoc;
        pageReference.getParameters().put('linkID', string.valueOf(newLoc.Id));
    	ec.linkToObject();
		
        pageReference.getParameters().put('formatId', 'Customer_Main_Address__c');
        pageReference.getParameters().put('houseNumber', '123');
        pageReference.getParameters().put('street', 'jam st');
        pageReference.getParameters().put('city', 'slamsville');
		
		//Set the building address format explicitly
		/*for(CustomerDetailExtensionController.LocationAddress address : ec.addresses){
			if(address.id == 'Customer_Main_Address__c'){
				ec.addressFormats.add(new CustomerDetailExtensionController.AddressFormat(address, baf));
			}
		}
		
		ec.updateAddressFormat();
		System.debug(ec.getTestClass());*/
    	
    	test.stopTest();
    }
	
 	static testMethod void testContacts() {
        System.Debug('testContacts');
        Mocks testData = new Mocks();
    	test.startTest();
    	
    	Customer_Detail__c cd = test_setupTestData(testData.loc.Id, null, null);
    	
    	List<Customer_Contact__c> ccs = new List<Customer_Contact__c>{
    										new Customer_Contact__c(Contact__c=testData.parentAccountContact.Id, Customer_Detail__c=cd.Id, Contact_Type__c=ICCWrapper.ResonsiblePartyContactType, Email__c='fake@fakeadress.com')
    										,new Customer_Contact__c(Contact__c=testData.parentAccountContact.Id, Customer_Detail__c=cd.Id, Contact_Type__c='Authorized Agent', Email__c='fake@fakeadress.com')
    									};
    	insert ccs;
    	
        PageReference pageReference = Page.CustomerDetailExtensionController;
        Test.setCurrentPage(pageReference);
        System.debug('cd :'+cd);
		Apexpages.StandardController sc = new Apexpages.StandardController(cd);
    	CustomerDetailExtensionController ec = new CustomerDetailExtensionController(sc);
    	ec.updateResponsibleParty();
    	ec.selectedContact = string.valueOf(testData.parentAccountContact.Id);
    	ec.selectedContactTypes = new List<String>{'Roommate'};
    	ec.createNewCustomerContact();
    	
        pageReference.getParameters().put('roleIDs', string.valueOf(ccs[0].Id) + ',' + string.valueOf(ccs[1].Id));
    	ec.removeRoles();
    	
    	test.stopTest();
    }
	
	static testMethod void testSubSettings(){
        System.Debug('testSubSettings');
        Mocks testData = new Mocks();
    	
    	Customer_Detail__c cd = test_setupTestData(testData.loc.Id, null, null);
		Customer_Detail__c cd2 = (Customer_Detail__c)ApexUtils.deepCopyFields(Customer_Detail__c.getsObjectType(), cd, new Customer_Detail__c(), new Set<String>{'ICC_Subscriber_ID__c'});
		insert cd2;
    	
    	Map<String, Id> rts = new Map<String, Id>();
    	for(RecordType rt : [select DeveloperName, Id from RecordType where DeveloperName in ('Bill_Cycle_Schedule', 'Market_Type')])
    		rts.put(rt.DeveloperName, rt.Id);
		insert new List<Customer_Setting__c>{
								    		new Customer_Setting__c(RecordTypeId=rts.get('Bill_Cycle_Schedule'), External_ID__c='1', Value__c='1')
								    		,new Customer_Setting__c(RecordTypeId=rts.get('Market_Type'), External_ID__c='1')
								    	};
		
		insert new List<Customer_Setting_Reference__c>{new Customer_Setting_Reference__c(Name='Ref1', Category__c='SubscriberSetting', Description__c='SubSetting', ID__c='1', Flags__c='1,1,1')
														,new Customer_Setting_Reference__c(Name='Ref2', Category__c='SubscriberTaxInfo', Description__c='SubTaxInfo', ID__c='2')};
		
    	test.startTest();
		
        PageReference pageReference = Page.CustomerDetailExtensionController;
        Test.setCurrentPage(pageReference);
        
		Apexpages.StandardController sc = new Apexpages.StandardController(cd);
    	CustomerDetailExtensionController ec = new CustomerDetailExtensionController(sc);
    	
    	ec.selectedSubSetting = '1';
    	ec.createNewSubscriberSetting();
    	Customer_Setting__c subSetting = [select Id from Customer_Setting__c where Customer_Detail__c =: cd.Id and RecordType.DeveloperName = 'Subscriber_Setting'];
		subSetting.External_ID__c = '-1';
		update subSetting;
    	
    	ec.selectedSubTax = '1';
    	ec.createNewSubscriberTax();
    	Customer_Setting__c taxInfo = [select Id from Customer_Setting__c where Customer_Detail__c =: cd.Id and RecordType.DeveloperName = 'Tax_Information'];
		taxInfo.External_ID__c = '-1';
		update taxInfo;
		
		//Reload the controller so the external IDs get loaded
		ec = new CustomerDetailExtensionController(sc);
		
        pageReference.getParameters().put('settingIDs', string.valueOf(subSetting.Id));
    	ec.updateSubscriberSettings();
		
        pageReference.getParameters().put('settingIDs', string.valueOf(subSetting.Id));
    	ec.deleteSubscriberSettings();
		
        pageReference.getParameters().put('settingIDs', string.valueOf(taxInfo.Id));
    	ec.updateSubscriberTaxInformation();
		
		pageReference.getParameters().put('copyTaxInfoIDs', string.valueOf(taxInfo.Id));
		pageReference.getParameters().put('copyToIDs', string.valueOf(cd2.Id));
		ec.copyTaxExemptions();
		
    	test.stopTest();
	}
	
	private static Customer_Detail__c test_setupTestData(Id locationId, Account a, Service_Location__c sLoc){
    	Customer_Detail__c cd = new Customer_Detail__c(ICC_Subscriber_ID__c='-9999'
														,Billable__c = true
    													,Customer_Main_Address__c=locationId
    													,Billing_Main_City__c='abcd'
                                                        ,Billing_Main_Country__c = 'US'
    													,Billing_Main_State__c='OR'
    													,Billing_Main_Street__c='1234'
    													,Billing_Main_Postal_Code__c='00000'
    													,Billing_Main_Room_Suite__c='1'
														,Integration_Status__c = 'Active');
    	insert cd;
    	
    	if(a != null){
	    	a.Customer_Detail__c = cd.Id;
	    	a.Phone = null;
	    	upsert a;
    	}
    	if(sLoc != null){
	    	sLoc.Customer_Detail__c = cd.Id;
	    	sLoc.Phone__c = null;
	    	update sLoc;
    	}
    	
    	return ((List<Customer_Detail__c>)ApexUtils.retrieveFullObjects(Customer_Detail__c.getsObjectType(), 'Id = \'' + cd.Id + '\''))[0];
	}
}