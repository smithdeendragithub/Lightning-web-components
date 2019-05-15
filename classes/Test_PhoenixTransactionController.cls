@isTest
public class Test_PhoenixTransactionController {
    
    static testMethod void testNewCreateTransaction() {
        Mocks testData = new Mocks(); 
        //Market_Area__c ma = new Market_Area__c();
        //ma.Name = 'National';
        //ma.MarketAreaExternalID__c = '36';
        //insert ma;
                
        Phoenix_Account_Transaction__c pat = new Phoenix_Account_Transaction__c();
        pat.Customer_Detail__c = testData.customerDetail.Id;
        pat.In_Queue__c = 'Y';
        pat.Status__c = 'In Queue';
        pat.Action__c = 'Create';
        insert pat;
        test.startTest();
        Customer_Detail__c cdChild = new Customer_Detail__c(Name = 'Test CD'
                                                        ,Billing_Main_City__c='Toronto'
                                                        ,Billing_Main_Country__c = 'CA'
                                                        ,Billing_Main_State__c='ON'
                                                        ,Billing_Main_Street__c='200 Wellington ST @'
                                                        ,Billing_Main_Postal_Code__c='M5V 3G2'
                                                        ,Billing_Main_Room_Suite__c='1');
        cdChild.Acquired_Company_Biller__c = 'IBIS';
        cdChild.Legacy_ID__c = '00000123145';
        cdChild.Language_Preference__c = 'English';
        cdChild.Invoice_PLL__c = 'Online PDF';
        cdChild.Customer_Reference__c = '';
        cdChild.Billable__c = true;
        cdChild.Market_Area__c = [SELECT ID FROM Market_Area__c where Name='National'].Id;
        cdChild.Integration_Status__c = 'Active';
        insert cdChild;
        
        cdChild.ICC_Subscriber_ID__c = '9999991235';
        cdChild.Legacy_ID__c = '00000123146';
        update cdChild;
 
        test.stopTest();
    }  
    
    static testMethod void testNewUpdateTransaction() {
        Mocks testData = new Mocks(); 
        //Market_Area__c ma = new Market_Area__c();
        //ma.Name = 'National';
        //ma.MarketAreaExternalID__c = '36';
        //insert ma;

        
        Customer_Detail__c cdChild = new Customer_Detail__c(Name = 'Test CD'
                                                        ,Billing_Main_City__c='Toronto'
                                                        ,Billing_Main_Country__c = 'CA'
                                                        ,Billing_Main_State__c='ON'
                                                        ,Billing_Main_Street__c='200 Wellington ST @'
                                                        ,Billing_Main_Postal_Code__c='M5V 3G2'
                                                        ,Billing_Main_Room_Suite__c='1');
        cdChild.Acquired_Company_Biller__c = 'IBIS';
        cdChild.Legacy_ID__c = '00000123145';
        cdChild.Language_Preference__c = 'English';
        cdChild.Invoice_PLL__c = 'Online PDF';
        cdChild.Customer_Reference__c = '';
        cdChild.Billable__c = true;
        cdChild.Market_Area__c = [SELECT ID FROM Market_Area__c where Name='National'].Id;
        cdChild.ICC_Subscriber_ID__c = '9999991235';
        cdChild.Integration_Status__c = 'Active';
        insert cdChild;
        Phoenix_Account_Transaction__c pat = new Phoenix_Account_Transaction__c();
        pat.Customer_Detail__c = cdChild.Id;
        pat.In_Queue__c = 'N';
        pat.Status__c = 'Success';
        pat.Action__c = 'Create';
        insert pat;
        
        test.startTest();
        cdChild.Legacy_ID__c = '00000123146';
        cdChild.Language_Preference__c = 'French';
        cdChild.Invoice_PLL__c = 'Online PDF + Paper';
        cdChild.Customer_Reference__c = 'Test';
        cdChild.Billing_Main_City__c='Markham';
        cdChild.Billing_Main_Country__c = 'US';
        cdChild.Billing_Main_State__c='AB';
        cdChild.Billing_Main_Street__c='100 Wellington ST';
        cdChild.Billing_Main_Postal_Code__c='N5V 3G2';
        cdChild.Billing_Main_Room_Suite__c='100';
        cdChild.Billing_Main_Name__c = 'Hello';
        cdChild.CurrencyIsoCode = 'USD';
        update cdChild;
 
        test.stopTest();
    }  
    
    static testMethod void testNewCreateTransactionAfterInitialCreateFailed() {
        Mocks testData = new Mocks(); 
        //Market_Area__c ma = new Market_Area__c();
        //ma.Name = 'National';
        //ma.MarketAreaExternalID__c = '36';
        //insert ma;
		
        
        Customer_Detail__c cdChild = new Customer_Detail__c(Name = 'Test CD'
                                                        ,Billing_Main_City__c='Toronto'
                                                        ,Billing_Main_Country__c = 'CA'
                                                        ,Billing_Main_State__c='ON'
                                                        ,Billing_Main_Street__c='200 Wellington ST @'
                                                        ,Billing_Main_Postal_Code__c='M5V 3G2'
                                                        ,Billing_Main_Room_Suite__c='1');
        cdChild.Acquired_Company_Biller__c = 'IBIS';
        cdChild.Legacy_ID__c = '00000123145';
        cdChild.Language_Preference__c = 'English';
        cdChild.Invoice_PLL__c = 'Online PDF';
        cdChild.Customer_Reference__c = '';
        cdChild.Billable__c = true;
        cdChild.Market_Area__c = [SELECT ID FROM Market_Area__c where Name='National'].Id;
        cdChild.ICC_Subscriber_ID__c = '9999991235';
        cdChild.Integration_Status__c = 'Active';
        insert cdChild;
        Phoenix_Account_Transaction__c pat = new Phoenix_Account_Transaction__c();
        pat.Customer_Detail__c = cdChild.Id;
        pat.In_Queue__c = 'N';
        pat.Status__c = 'Failed';
        pat.Action__c = 'Create';
        insert pat;
        
        test.startTest();
        cdChild.Legacy_ID__c = '00000123146';
        cdChild.Language_Preference__c = 'French';
        cdChild.Invoice_PLL__c = 'Online PDF + Paper';
        cdChild.Customer_Reference__c = 'Test';
        cdChild.Billing_Main_City__c='Markham';
        cdChild.Billing_Main_Country__c = 'US';
        cdChild.Billing_Main_State__c='AB';
        cdChild.Billing_Main_Street__c='100 Wellington ST';
        cdChild.Billing_Main_Postal_Code__c='N5V 3G2';
        cdChild.Billing_Main_Room_Suite__c='100';
        cdChild.Billing_Main_Name__c = 'Hello';
        cdChild.CurrencyIsoCode = 'USD';
        update cdChild;
 
        test.stopTest();
    }  
   

}