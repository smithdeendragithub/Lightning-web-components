@isTest
public with sharing class Test_IntegrationEndpoint extends TestUtils.TestClass {

    static testMethod void testUpdateSubscribers() {
		// create test data
        Mocks testData = new Mocks();
    	
    	Customer_Detail__c cd = new Customer_Detail__c(ICC_Subscriber_ID__c='-9999', Integration_Status__c='Active');
    	insert cd;
    	
		Account a = testData.parentAccount;
		a.Customer_Detail__c = cd.Id;
		update a;
		
		Service_Location__c sLoc = new Service_Location__c(Account__c = a.Id, Name = 'Test Loc', Customer_Detail__c=cd.Id, Location__c = testData.loc.Id);
		insert sLoc; 
		
		test.startTest();
		
    	IntegrationEndpoint.SubscriberUpdate u = new IntegrationEndpoint.SubscriberUpdate();
    	u.SubscriberID = '-9999';
    	u.Status = 'Inactive';
    	IntegrationEndpoint.UpdateSubscribers(new List<IntegrationEndpoint.SubscriberUpdate>{u});
    }
	
	static testMethod void testGetOrderReindexingOpportunitiesBySubscriberID(){
		// create test data
        Mocks testData = new Mocks();
    	
    	Customer_Detail__c cd = new Customer_Detail__c(ICC_Subscriber_ID__c='-9999', Integration_Status__c='Active');
    	insert cd;
    	
		Account a = testData.parentAccount;
		a.Customer_Detail__c = cd.Id;
		update a;
		
		Service_Location__c sLoc = new Service_Location__c(Account__c = a.Id, Name = 'Test Loc', Customer_Detail__c=cd.Id, Location__c = testData.loc.Id);
		insert sLoc; 
		
		test.startTest();
		
    	IntegrationEndpoint.GetOrderReindexingOpportunitiesBySubscriberID(new List<String>{'-9999'});
	}
	
	static testMethod void testGetServingBuildings(){
		IntegrationEndpoint.GetServingBuildings();
	}
}