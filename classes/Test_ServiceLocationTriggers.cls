@isTest
public with sharing class Test_ServiceLocationTriggers {
    
    static testMethod void testServiceLocationUpdate() {
        // create test data
        Mocks testData = new Mocks();
        
        test.startTest();
        
        Customer_Detail__c cd = new Customer_Detail__c(ICC_Subscriber_ID__c = '-1');
        insert cd;
        
        Service_Location__c sLoc = new Service_Location__c(Account__c = testData.parentAccount.Id, Customer_Detail__c = cd.Id, Billable__c = false, Location__c = testData.loc.Id);
        insert sLoc;
        
        testData.parentAccount.Customer_Detail__c = cd.Id;
        update testData.parentAccount;
        
		integraWSEndpointMediator.simulateIntegrationException = true;
        sLoc.Phone__c = '1234567890';
        //sLoc.Owner__c = testData.user.Id;
        sLoc.Billable__c = true;
		update sLoc;
		
    	//This won't actually create the IntegrationError object so let's make it
    	Integration_Error__c error = new Integration_Error__c(ObjectID__c = sLoc.Id, Action__c = 'Update', Info__c = 'Phone,Owner');
    	insert error;
    	
    	IntegrationUtils.reintegrateObjects(new Set<String>{sLoc.Id});

        test.stopTest();
    }
}