@isTest
public with sharing class Test_CustomerContactConfiguration extends TestUtils.TestClass {
	
 	static testMethod void testController() {
        Mocks testData = new Mocks();
    	test.startTest();
    	
    	Customer_Detail__c cd = new Customer_Detail__c(ICC_Subscriber_ID__c='-9999'
    													,Customer_Main_Address__c=testData.loc.Id
    													,Billing_Main_City__c='abcd'
                                                        ,Billing_Main_Country__c = 'US'
    													,Billing_Main_State__c='OR'
    													,Billing_Main_Street__c='1234'
    													,Billing_Main_Postal_Code__c='00000'
    													,Billing_Main_Room_Suite__c='1');
    	insert cd;
    	
    	testData.parentAccount.Customer_Detail__c = cd.Id;
    	update testData.parentAccount;
    	
    	Contact c = new Contact(FirstName='Francis'
    							,LastName='Morgan'
    							,Email='justcallmeyork@everybodydoes.com'
    							,AccountId=testData.parentAccount.Id);
    	insert c;
    	
    	List<Customer_Contact__c> ccs = new List<Customer_Contact__c>{
    										new Customer_Contact__c(Contact__c=testdata.parentAccountContact.Id, Customer_Detail__c=cd.Id, Contact_Type__c=ICCWrapper.ResonsiblePartyContactType, Email__c='fake@fakeadress.com')
    										,new Customer_Contact__c(Contact__c=c.Id, Customer_Detail__c=cd.Id, Contact_Type__c='Authorized Agent')
    									};
    	insert ccs;
    	
        PageReference pageReference = Page.CustomerContactConfiguration;
        Test.setCurrentPage(pageReference);
        
		Apexpages.StandardController sc = new Apexpages.StandardController(c);
    	CustomerContactConfigurationController cc = new CustomerContactConfigurationController(sc);
    	cc.selectedContactTypes = new List<String>{'Bravest and strongest man'};
    	cc.selectedCustomers = new List<String>{string.valueOf(cd.Id)};
    	cc.createNewCustomerContacts();
    	cc.updateResponsibleParties();
        pageReference.getParameters().put('roleIDs', string.valueOf(ccs[0].Id));
    	cc.removeRoles();
    	
    	test.stopTest();
    }
}