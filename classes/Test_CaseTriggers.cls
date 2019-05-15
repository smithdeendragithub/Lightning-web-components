@isTest
public with sharing class Test_CaseTriggers extends TestUtils.TestClass {
	
    static testMethod void testCase(){
        Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		
		Customer_Detail__c cd = new Customer_Detail__c(ICC_Subscriber_ID__c = '-1');
		insert cd;
		
		a.Customer_Detail__c = cd.Id;
		update a;
		
        test.startTest();
		
		Case cs = new Case(AccountId = a.Id
						,Status = 'New'
						,Origin = 'Email'
						,Alternate_Contact_First_Name__c = 'Test'
						,Alternate_Contact_Last_Name__c = 'Guy'
						,Alternate_Contact_Phone__c = '(000) 000-0000'
						,Alternate_Contact_Email__c = 'test@test.com'
						,Commit_Date__c = Date.today());
		insert cs;
		
		//cases no longer create contacts
		//cs = [select Id, ContactId from Case where Id =: cs.Id];
		//System.assert(cs.ContactId != null, 'Alternate Contact was not created');
	}
	
    static testMethod void testCaseComment(){
        Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		
		Customer_Detail__c cd = new Customer_Detail__c(ICC_Subscriber_ID__c = '-1');
		insert cd;
		
		a.Customer_Detail__c = cd.Id;
		update a;
		
		Case cs = new Case(AccountId = a.Id
						,Status = 'New'
						,Origin = 'Email'
						,Alternate_Contact_First_Name__c = 'Test'
						,Alternate_Contact_Last_Name__c = 'Guy'
						,Alternate_Contact_Phone__c = '(000) 000-0000'
						,Alternate_Contact_Email__c = 'test@test.com'
						,Commit_Date__c = Date.today());
		insert cs;
		
        test.startTest();
		
		CaseComment cc = new CaseComment(ParentId = cs.Id
										,CommentBody = 'blahblahblah');
		insert cc;
	}
}