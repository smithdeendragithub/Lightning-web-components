@isTest
public with sharing class Test_ContactTriggers extends TestUtils.TestClass {

	//Also tests IntegrationErrorsController.integrateBatch()
    static testMethod void testContactUpdate() {
        // create test data
        Mocks testData = new Mocks();
        
        test.startTest();
    	
        List<Contact> tNew = new List<Contact>{testData.parentAccountContact};
        
		integraWSEndpointMediator.simulateIntegrationException = true;
    	update tNew;
    	
    	//This won't actually create the IntegrationError object so let's make it
    	Integration_Error__c error = new Integration_Error__c(ObjectID__c = tNew[0].Id, Action__c = 'Update');
    	insert error;
    	
    	IntegrationErrorsController errorController = new IntegrationErrorsController();
    	errorController.objectTypeSelection = 'Contact';
    	errorController.integrateBatch();
    	
    	Customer_Contact__c cc = new Customer_Contact__c(Contact__c=tNew[0].Id, Customer_Detail__c=testData.customerDetail.Id, Contact_Type__c='Test type', ICC_Contact_ID__c='-1');
    	insert cc;
    	
		integraWSEndpointMediator.simulateIntegrationException = false;
		update tNew;

        test.stopTest();
    }
    
	//Also tests IntegrationErrorsController.integrateSingle()
    static testMethod void testContactDelete() {
        // create test data
        Mocks testData = new Mocks();
        
        List<Contact> tNew = new List<Contact>{testData.parentAccountContact};
    	Customer_Contact__c cc = new Customer_Contact__c(Contact__c=tNew[0].Id, Customer_Detail__c=testData.customerDetail.Id, Contact_Type__c='Test type', ICC_Contact_ID__c='-1');
    	insert cc;
        
        test.startTest();
        
        if(tNew.size() > 0){
			integraWSEndpointMediator.simulateIntegrationException = true;
        	delete tNew;
        	
	    	//This won't actually create the IntegrationError object so let's make it
	    	/*Integration_Error__c error = new Integration_Error__c(ObjectID__c = tNew[0].Id, Action__c = 'Delete', Info__c = tNew[0].ICCContactID__c);
	    	insert error;*/
	    	
	    	IntegrationErrorsController errorController = new IntegrationErrorsController();
	    	errorController.objectID = tNew[0].Id;
	    	errorController.integrateSingle();
        }

        test.stopTest();
    }
	
    static testMethod void testExternalUserContact() {
        Mocks testData = new Mocks();
        
        test.startTest();
		
		External_User__c u = new External_User__c(
													Logon_Name__c = 'testuser'
													,First_Name__c = 'External'
													,Last_Name__c = 'Flexternal'
													,Email__c = 'test@test.com'
												);
		insert u;
    	u.Last_Name__c = 'Flexternalist';
		update u;
        List<Contact> tNew = new List<Contact>{testData.parentAccountContact};
        
		tNew[0].External_User__c = u.Id;
    	update tNew;
		
        test.stopTest();
    }
}