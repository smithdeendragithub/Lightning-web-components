@isTest
public with sharing class Test_PricingAgreementTriggers {
    
	static testmethod void testTriggers(){
		Mocks testData = new Mocks();
        User u = getStandardUser();  
        Account a = testData.parentAccount;
                
        Test.startTest(); 
        Pricing_Agreement__c pa = new Pricing_Agreement__c(Account__c = a.Id, Approval_Status__c ='Approval Required');
        insert pa;        
        
        ICB__c icb = new ICB__c();
        icb.ICB_Type__c = 'Pricing';
        icb.Description__c = 'This is a test pricing request for unit testing ICB triggers';
        icb.ICB_Pricing_Reason__c = 'Capital Build';
        icb.Account__c = a.Id;
        icb.Pricing_Agreement__c = pa.Id;
        icb.Sales_Engineer__c = u.Id;
        icb.status__c = 'Approved-Pending Sale';
        
        insert icb;
        
        pa.Approval_Status__c ='Approved';
        update pa;

        Test.stopTest();
    }
    
    
    private static User getStandardUser(){
		return [SELECT Title, Id, Username, Name FROM User WHERE IsActive = true AND UserType LIKE:'%Standard%' LIMIT 1];
    }



}