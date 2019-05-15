@isTest
public with sharing class Test_CaseNetX extends TestUtils.TestClass {
  
    static testMethod void testCase(){
        Mocks testData = new Mocks();
    
    Account a = testData.parentAccount;
    
    Customer_Detail__c cd = new Customer_Detail__c(ICC_Subscriber_ID__c = '-1');
    insert cd;
    
    a.Customer_Detail__c = cd.Id;
    update a;
        
        Expense__c E3 = new Expense__c();  
        E3.Status__c = 'Active';
        E3.Vendor_Account__c = a.id;
        E3.Escalation_Type__c = 'NetX';
        E3.Netex_Service__c = 'DS1';
        E3.Product_Group__c = 'Voice';
        E3.CurrencyCode__c = 'USD';
        E3.Vendor_Circuit_Id__c = 'C123';
        E3.Netx_MRC__c = 3;
        E3.Business_Unit_Owner__c = 'Allstream_SMB';
        
        insert E3;
 //       System.AssertNotEquals(null, zExp1);
    
        test.startTest();
    
    //String strRecordTypeId = [Select Id From RecordType Where SobjectType = 'Case' and Name = 'NetEx Case'].Id;
    String strRecordTypeNetX     = [Select Id From RecordType Where SobjectType = 'Case' and Name = 'NetEx Case'].Id;
    
    Case cs = new Case(AccountId = a.Id
            ,Status = 'New'
            ,Origin = 'Email'
            ,Alternate_Contact_First_Name__c = 'Test'
            ,Alternate_Contact_Last_Name__c = 'Guy'
            ,Alternate_Contact_Phone__c = '(000) 000-0000'
            ,Alternate_Contact_Email__c = 'test@test.com'
            ,Netx__c = E3.Id
            ,Subject = 'Test'
            ,Description = 'TEST'
            ,RecordTypeId = strRecordTypeNetX
            ,Commit_Date__c = Date.today());
    insert cs;
    
    Case cu = cs;
    cu.status = 'In Progress';
    cu.type = 'Netx';
    update cu;
    
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
    
    String strRecordTypeId = [Select Id From RecordType Where SobjectType = 'Case' and Name = 'NetEx Case'].Id;
    
    Case cs = new Case(AccountId = a.Id
            ,Status = 'New'
            ,Origin = 'Email'
            ,Alternate_Contact_First_Name__c = 'Test'
            ,Alternate_Contact_Last_Name__c = 'Guy'
            ,Alternate_Contact_Phone__c = '(000) 000-0000'
            ,Alternate_Contact_Email__c = 'test@test.com'
            ,RecordTypeId = strRecordTypeId
            ,Commit_Date__c = Date.today());
    insert cs;
    
        test.startTest();
    
    CaseComment cc = new CaseComment(ParentId = cs.Id
                    ,CommentBody = 'blahblahblah');
    insert cc;
  }
}