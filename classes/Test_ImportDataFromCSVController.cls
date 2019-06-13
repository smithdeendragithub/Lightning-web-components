@isTest
public with sharing class Test_ImportDataFromCSVController extends TestUtils.TestClass {
    static String str = 'RENEWAL_STATUS,CONTRACT,CUSTNO,CTR_END,CTR_PRICE,NEXT_START,NEXT_END,NEXT_PRICE \n Renewed,16-113101,468475,30/07/2018,154.5,31/07/2018,30/07/2019,154.5'; 
	static String churnStr = 'CONTRACT,CUSTNO,CURRENTCANCELDATE,CANCELLATIONDESCRIPTION,CURRENTSTARTDATE,CURRENTENDDATE,MRR \n 16-113101,468475,30/07/2018,test,31/07/2018,30/07/2019,154.5'; 
	static String installStr = 'Order,CUSTNBR,MRR \n 186756,468475,154.5';     

    public static String[] csvFileLines;
    public static Blob csvFileBody;
    private static Mocks testData = null;
    
    private static void getTestData(){
        testData = new Mocks();
		Market_Area__c ma = testData.marketArea;
        ma.Name = 'National';
        update ma;
        Account a = testData.parentAccount;
        
        Customer_Detail__c detail = new Customer_Detail__c(ICC_Subscriber_ID__c = '-9999'
                                                            ,Customer_Main_Address__c = testData.loc.Id
                                                            ,Service_Address__c = testData.loc.Id
                                                            ,Market_Area__c = testData.marketArea.Id
                                                            ,Legacy_Id__c = '468475');
        insert detail;
        
        a.Customer_Detail__c = detail.Id;
        update a;
    }
    
    static testmethod void testReadFromFile(){
        getTestData();
        Test.startTest();       
        csvFileBody = Blob.valueOf(str);
        String csvAsString = csvFileBody.toString();
        csvFileLines = csvAsString.split('\n'); 

        ImportDataFromCSVController importData = new ImportDataFromCSVController();
        importData.csvFileBody = csvFileBody;
        importData.selectedFileType = 'Renewal';
        importData.readFromFile();
        System.assert(importData.orderDataLines.size() ==csvFileLines.size() );
        importData.saveData();
        Test.stopTest();
    }         
    static testmethod void testReadFromChurnFile(){
        getTestData();
        Test.startTest();       
        csvFileBody = Blob.valueOf(churnStr);
        String csvAsString = csvFileBody.toString();
        csvFileLines = csvAsString.split('\n'); 

        ImportDataFromCSVController importData = new ImportDataFromCSVController();
        importData.csvFileBody = csvFileBody;
        importData.selectedFileType = 'Actual Churn';
        importData.readFromFile();
        System.assert(importData.orderDataLines.size() ==csvFileLines.size() );
        importData.saveData();        
        Test.stopTest();
    }         
    static testmethod void testReadFromInstallFile(){
        getTestData();
        Test.startTest();       
        csvFileBody = Blob.valueOf(installStr);
        String csvAsString = csvFileBody.toString();
        csvFileLines = csvAsString.split('\n'); 

        ImportDataFromCSVController importData = new ImportDataFromCSVController();
        importData.csvFileBody = csvFileBody;
        importData.selectedFileType = 'Actual Install';
        importData.readFromFile();
        System.assert(importData.orderDataLines.size() ==csvFileLines.size() );
        importData.saveData();
        Test.stopTest();
    }         
    
}