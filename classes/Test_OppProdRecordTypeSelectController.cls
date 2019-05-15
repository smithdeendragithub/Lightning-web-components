@isTest
public with sharing class Test_OppProdRecordTypeSelectController extends TestUtils.TestClass {    
    private static Mocks testData = null;
    
    private static void getTestData(){
        testData = new Mocks();
        Account a = testData.parentAccount;
        List<RecordType> rt = [select Id from RecordType where DeveloperName ='Care_Organization' limit 1];
        Customer_Setting__c cs = new Customer_Setting__c(RecordTypeId=rt.get(0).Id, Name='Wholesale Care Org', Value__c='Wholesale Care Org');
        insert cs;

        Customer_Detail__c detail = new Customer_Detail__c(Customer_Main_Address__c = testData.loc.Id
                                                            ,Service_Address__c = testData.loc.Id
                                                            ,Legacy_Id__c = '468475', care_Organization__c=cs.Id);

        insert detail;
        
        a.Customer_Detail__c = detail.Id;
        update a;
    }

    static testmethod void testRetailRT(){
        getTestData();
        Test.startTest(); 
        PageReference p= Page.OppProdRecordTypeSelector;
        Opportunity opp1 = testData.opportunity;
        opp1.Sell_To_Through__c = 'Sell Through';
        update opp1;
        p.getParameters().put('CF00NC0000005gStS_lkid',opp1.Id);        
        p.getParameters().put('CF00NC0000005gStS',opp1.Name);
        p.getParameters().put('retURL', '/'+ opp1.Id);

        Test.setCurrentPage(p);
        
        Apexpages.StandardController sc = new Apexpages.StandardController(new Opportunity_Product__c(Opportunity__c=opp1.Id));
        OppProdRecordTypeSelectController selectRT = new OppProdRecordTypeSelectController(sc);
        
        selectRT.continueMethod();        
        
        Test.stopTest();
    }    
    
    static testmethod void testWholesaleRT(){
        getTestData();
        Test.startTest(); 
        PageReference p= Page.OppProdRecordTypeSelector;
        Opportunity opp1 = testData.opportunity;
        RecordType rt = [Select r.SobjectType, r.Name, r.Id From RecordType r where r.SobjectType = 'Opportunity' and r.Name = 'Wholesale'];
        opp1.RecordTypeId = rt.Id;
        opp1.Service_Type_Detail__c ='T1';
        opp1.Service_Types__c = 'Voice Services';
        update opp1;
        p.getParameters().put('CF00NC0000005gStS_lkid',opp1.Id);        
        p.getParameters().put('CF00NC0000005gStS',opp1.Name);
        p.getParameters().put('retURL', '/'+ opp1.Id);

        Test.setCurrentPage(p);
        
        Apexpages.StandardController sc = new Apexpages.StandardController(new Opportunity_Product__c(Opportunity__c=opp1.Id));
        OppProdRecordTypeSelectController selectRT = new OppProdRecordTypeSelectController(sc);
        
        selectRT.continueMethod();        
        
        Test.stopTest();
    }    
    
}