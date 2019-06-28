@isTest
public with sharing class Test_CustomerAtRiskTriggers extends TestUtils.TestClass {
    static testMethod void testCustomerAtRisk(){
        Mocks testData = new Mocks();
        
        Customer_At_Risk__c car = new Customer_At_Risk__c();
        car.Actions_Taken_to_Resolve__c = 'testing';
        car.Reason_At_Risk__c = 'Billing';
        car.Account__c = testData.parentAccount.id;
        car.Status__c = 'Open';
        car.Risk_Level__c = 'Low';
        car.At_Risk_Detail__c = 'Test';
        car.Total_Account_MRC__c = 1;
        car.MRR_at_Risk__c = 1;
        car.Product_Family__c = 'Data Services';
        car.Product__c = 'VPN Solutions';
        car.Service_Location__c = testData.serviceLocation.id;
        car.Contract_End_Date_for_Majorit_of_MRR__c = Date.today();
        insert car;
    }
}