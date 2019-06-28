@isTest
public with sharing class Test_AccountTriggers extends TestUtils.TestClass {
    
    static testMethod void TestAccountReferenceObject(){
        
        Mocks testdata = new Mocks();
        
        List<Account> accts = testdata.getAccountList(1);
        
        test.startTest();
        
        AccountTriggers.createAccountReferenceObject(accts);
        
        List<AccountReference__c> refList = ([SELECT Id, Name, Account__c  FROM AccountReference__c WHERE Account__c IN: accts]);
        
        system.assertEquals(1, refList.size());
		
        delete accts;
		
		refList = ([SELECT Id, Name, Account__c  FROM AccountReference__c WHERE Account__c IN: accts]);
        
        system.assertEquals(0, refList.size());
        
        test.stopTest();
    }
    
    static testMethod void TestSetPreviousUserField(){
        
        Mocks testdata = new Mocks();       
        List<Account> accts = testdata.getAccountList(20);
        
        upsert accts;
        
        User u = [SELECT Title, Id, Username, Name FROM User WHERE IsActive = true AND UserType LIKE:'%Standard%' LIMIT 1];
        
        for(Account a : accts){         
            a.OwnerId = u.Id;
        }
        
        List<Database.Saveresult> results;
         
        try{
        
            results = Database.update(accts, false);
        
        }catch(DmlException e){
            
            for(Database.SaveResult result : results){
                    if(!result.isSuccess())
                        system.debug(result.getErrors()[0]);
            }
            
            
            for (Integer i = 0; i < results.size(); i++) {
           
                if (results[i].isSuccess()) {
                    System.debug('Successfully created ID: ' + results[i].getId());
                } else {
                
                System.debug('Error: could not create sobject for array element ' + i + '.');
                System.debug('   The error reported was: ' + results[i].getErrors()[0].getMessage() + '\n');
                }
            }
        }
    }
    
    static testMethod void TestAccountUpdateIntegration(){
    	Mocks mocks = new Mocks();
    	
        List<Customer_Detail__c> cd = new List<Customer_Detail__c>{new Customer_Detail__c(ICC_Subscriber_ID__c = '-1')
																,new Customer_Detail__c(ICC_Subscriber_ID__c = '-2')};
        insert cd;
		
    	Account a = mocks.parentAccount;
		integraWSEndpointMediator.simulateIntegrationException = true;
    	a.Phone = '(555) 555-1234';
    	//a.OwnerId = mocks.user.Id;
        a.Customer_Detail__c = cd[0].Id;
        a.Billable__c = false;
    	update a;
        
		Service_Location__c sLoc = mocks.serviceLocation;
		sLoc.Customer_Detail__c = cd[1].Id;
		update sLoc;
    	
        test.startTest();
    	
		a.Name = a.Name + '1';
    	a.Billable__c = true;
    	a.Phone = '(555) 555-4321';
		a.Government_Contract_Type__c = 'CALNET3';
		a.Government_Segment__c = 'Federal';
		a.Industry = 'Education';
    	update a;
    	
    	//This won't actually create the IntegrationError object so let's make it
    	Integration_Error__c error = new Integration_Error__c(ObjectID__c = a.Id, Action__c = 'Update', Info__c = 'Phone,Owner');
    	insert error;
    	
    	IntegrationUtils.reintegrateObjects(new Set<String>{a.Id});
    	
    	test.stopTest();
    }

}