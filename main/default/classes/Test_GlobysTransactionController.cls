@isTest
public with sharing class Test_GlobysTransactionController {

	
    public static final id MARKET_AREA_NATIONAL = 'a0JC000000ESX5W';
    //public static final id MARKET_AREA_NATIONAL = 'a0Jm0000006odFsEAI';

    static testMethod void testChangeLegacyIDChildCustomerDetail() {
        Mocks testData = new Mocks();
         
        
        
        Customer_Detail__c cdParent = test_setupTestData('Parent', testData.loc.Id, testData.parentAccount, testData.serviceLocation, false);
        cdParent.Market_Area__c = MARKET_AREA_NATIONAL;
        cdParent.BPID__c = '12345';
        cdParent.ICC_Subscriber_ID__c = '9999991234';
        cdParent.Integration_Status__c = 'Active';
        upsert cdParent;
        
        Service_Location__c childServiceLocation = new Service_Location__c(Account__c = testData.parentAccount.Id, Name = 'Child Test Loc', Location__c = testData.loc.Id);
		insert childServiceLocation;
 		test.startTest();
        Customer_Detail__c cdChild = test_setupTestData('Child', testData.loc.Id, testData.parentAccount, childServiceLocation, true);
        cdChild.Acquired_Company_Biller__c = 'IBIS';
        cdChild.Legacy_ID__c = '00000123145';
        cdChild.Parent_Customer__c = cdParent.id;
        cdChild.Market_Area__c = MARKET_AREA_NATIONAL;
        cdChild.ICC_Subscriber_ID__c = '9999991235';
        cdChild.Integration_Status__c = 'Active';
        upsert cdChild;

        cdChild.Legacy_ID__c = '00000123146';
        update cdChild;
 
        test.stopTest();
 	}  
 
    static testMethod void testChangeBillerChildCustomerDetail() {
        Mocks testData = new Mocks();
         
        
        
        Customer_Detail__c cdParent = test_setupTestData('Parent', testData.loc.Id, testData.parentAccount, testData.serviceLocation, false);
        cdParent.Market_Area__c = MARKET_AREA_NATIONAL;
        cdParent.BPID__c = '12345';
        cdParent.ICC_Subscriber_ID__c = '9999991234';
        cdParent.Integration_Status__c = 'Active';
        upsert cdParent;
        
        Service_Location__c childServiceLocation = new Service_Location__c(Account__c = testData.parentAccount.Id, Name = 'Test Loc', Location__c = testData.loc.Id);
		insert childServiceLocation;
 		test.startTest();
        Customer_Detail__c cdChild = test_setupTestData('Child', testData.loc.Id, testData.parentAccount, childServiceLocation, true);
        cdChild.Acquired_Company_Biller__c = 'IBIS';
        cdChild.Legacy_ID__c = '00000123145';
        cdChild.Parent_Customer__c = cdParent.id;
        cdChild.Market_Area__c = MARKET_AREA_NATIONAL;
        cdChild.ICC_Subscriber_ID__c = '9999991235';
        cdChild.Integration_Status__c = 'Active';
        upsert cdChild;
 
        cdChild.Acquired_Company_Biller__c = 'ICMS';
        update cdChild;
 
        test.stopTest();
 	}     
    
     static testMethod void testClearChildCustomerDetail() {
        Mocks testData = new Mocks();
                
        Customer_Detail__c cdParent = test_setupTestData('Parent', testData.loc.Id, testData.parentAccount, testData.serviceLocation, false);
        cdParent.Market_Area__c = MARKET_AREA_NATIONAL;
        cdParent.BPID__c = '12345';
        cdParent.ICC_Subscriber_ID__c = '9999991234';
        cdParent.Integration_Status__c = 'Active';
        upsert cdParent;
        
        Service_Location__c childServiceLocation = new Service_Location__c(Account__c = testData.parentAccount.Id, Name = 'Test Loc', Location__c = testData.loc.Id);
		insert childServiceLocation;
 		
        test.startTest();
        Customer_Detail__c cdChild = test_setupTestData('Child', testData.loc.Id, testData.parentAccount, childServiceLocation, true);
        cdChild.Acquired_Company_Biller__c = 'IBIS';
        cdChild.Legacy_ID__c = '00000123145';
        cdChild.Parent_Customer__c = cdParent.id;
        cdChild.Market_Area__c = MARKET_AREA_NATIONAL;
        cdChild.ICC_Subscriber_ID__c = '9999991235';
        cdChild.Integration_Status__c = 'Active';
        upsert cdChild;
 
        cdChild.Legacy_ID__c = '';
        update cdChild;
 
        test.stopTest();
 	}  
    
    
    static testMethod void testChangeParentCustomerDetail() {
        Mocks testData = new Mocks();
         
        
        
        Customer_Detail__c cdParent = test_setupTestData('Parent', testData.loc.Id, testData.parentAccount, testData.serviceLocation, false);
        cdParent.Market_Area__c = MARKET_AREA_NATIONAL;
        cdParent.BPID__c = '12345';
        cdParent.ICC_Subscriber_ID__c = '9999991234';
        cdParent.Integration_Status__c = 'Active';
        upsert cdParent;
        
        Service_Location__c childServiceLocation = new Service_Location__c(Account__c = testData.parentAccount.Id, Name = 'Test Loc', Location__c = testData.loc.Id);
		insert childServiceLocation;
 		test.startTest();
        Customer_Detail__c cdChild = test_setupTestData('Child', testData.loc.Id, testData.parentAccount, childServiceLocation, true);
        cdChild.Acquired_Company_Biller__c = 'IBIS';
        cdChild.Legacy_ID__c = '00000123145';
        cdChild.Parent_Customer__c = cdParent.id;
        cdChild.Market_Area__c = MARKET_AREA_NATIONAL;
        cdChild.ICC_Subscriber_ID__c = '9999991235';
        cdChild.Integration_Status__c = 'Active';
        upsert cdChild;
 
        cdParent.BPID__c = '12346';
        update cdParent;
        
        test.stopTest();
	}      
 
    static testMethod void testClearParentCustomerDetail() {
        Mocks testData = new Mocks();
         
        

        testData.serviceLocation.Billable__c = false;
        update testData.serviceLocation;
        
        Customer_Detail__c cdParent = test_setupTestData('Parent', testData.loc.Id, testData.parentAccount, testData.serviceLocation, false);
        cdParent.Market_Area__c = MARKET_AREA_NATIONAL;
        cdParent.BPID__c = '12345';
        cdParent.ICC_Subscriber_ID__c = '9999991234';
        cdParent.Integration_Status__c = 'Active';
        cdParent.Billable__c = false;
        upsert cdParent;
        
        Service_Location__c childServiceLocation = new Service_Location__c(Account__c = testData.parentAccount.Id, Name = 'Child', Location__c = testData.loc.Id, Billable__c = true);
		insert childServiceLocation;
 		test.startTest();
        Customer_Detail__c cdChild = test_setupTestData('Child', testData.loc.Id, testData.parentAccount, childServiceLocation, true);
        cdChild.Acquired_Company_Biller__c = 'IBIS';
        cdChild.Legacy_ID__c = '00000123145';
        cdChild.Parent_Customer__c = cdParent.id;
        cdChild.Market_Area__c = MARKET_AREA_NATIONAL;
        cdChild.ICC_Subscriber_ID__c = '9999991235';
        cdChild.Integration_Status__c = 'Active';
        upsert cdChild;
   
        cdParent.BPID__c = null;
        update cdParent;
      
        test.stopTest();
	}      
    
    private static Customer_Detail__c test_setupTestData(String cdName, Id locationId, Account a, Service_Location__c sLoc, Boolean billable){

        Customer_Detail__c cd = new Customer_Detail__c(Name = cdName
                                                       	,Billable__c = billable
    													,Customer_Main_Address__c=locationId
    													,Billing_Main_City__c='Toronto'
                                                        ,Billing_Main_Country__c = 'CA'
    													,Billing_Main_State__c='ON'
    													,Billing_Main_Street__c='200 Wellington ST @'
    													,Billing_Main_Postal_Code__c='M5V 3G2'
    													,Billing_Main_Room_Suite__c='1');
    	insert cd;
    	
    	if(a != null && cdName == 'Parent'){
	    	a.Customer_Detail__c = cd.Id;
	    	a.Phone = null;
	    	upsert a;
    	}
    	if(sLoc != null){
            sLoc.Billable__c = billable;
	    	sLoc.Customer_Detail__c = cd.Id;
	    	sLoc.Phone__c = null;
	    	update sLoc;
    	}
    	
    	return ((List<Customer_Detail__c>)ApexUtils.retrieveFullObjects(Customer_Detail__c.getsObjectType(), 'Id = \'' + cd.Id + '\''))[0];
	}
    

}