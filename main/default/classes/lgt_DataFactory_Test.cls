@isTest
public with sharing class lgt_DataFactory_Test{
    static testMethod void test_getOrderNumber(){
        Customer_Detail__c cd = new Customer_Detail__c(ICC_Subscriber_ID__c='12345');
        insert cd;
        Account  a = new Account(Name = 'testAccount'
                                 ,ShippingCountry = 'US'
                                 ,Customer_Detail__c = cd.Id
                                 ,ShippingStreet = '1234 Someplace ST'
                                 ,ShippingCity = 'Nowhere'
                                 ,ShippingState = 'WA'
                                 ,ShippingPostalCode = '54321'
                                 ,Phone = '800-123-1234'
                                 ,Industry = 'Z - Unclassified');
        insert a;
        
        RecordType rt = [select Id from RecordType where SobjectType = 'Opportunity' and Name = 'Retail'];
        Opportunity opp = new Opportunity(AccountId = a.Id
                                          ,Name = 'Test Opp'
                                          ,RecordTypeId = rt.Id
                                          ,StageName = OpportunityUtils.STAGE_QUALIFIED
                                          ,Type = 'Existing'
                                          ,Oppty_Sub_Type__c='Renewal'
                                          ,CloseDate = Date.today().addDays(30)
                                          ,Customer_Requested_Due_Date__c = Date.today());
        insert opp;
        
        rt = [select Id from RecordType where SobjectType = 'Order__c' and DeveloperName = 'Opportunity_Order'];
        Order__c ord = new Order__c(Opportunity__c = opp.Id, RecordTypeId = rt.Id);
        insert ord;
        
        test.startTest();
        List<Order__c> orders = lgt_DataFactory.getOrderNumber(ord.id);
        System.assertNotEquals(orders[0].Name, null);
        test.stopTest();
        
    }
}