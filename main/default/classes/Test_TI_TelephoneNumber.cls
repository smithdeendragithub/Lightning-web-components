@isTest
public with sharing class Test_TI_TelephoneNumber extends TestUtils.TestClass {
	
    static testMethod void testController(){
    	test.startTest();
    	//Retrieving Record Type for the test Account
    	RecordType art = [Select Id From RecordType 
			Where SobjectType = 'Account' And IsActive = true And Name like 'Prospect%' Limit 1];
    	//Retrieving Record Type for the test Opportunity
    	RecordType ort = [Select Id From RecordType 
			Where SobjectType = 'Opportunity' And IsActive = true And Name like 'Sales%' Limit 1];
    	//Retrieving Record Type for the test Technical Information
    	RecordType tirt = [Select Id From RecordType 
			Where SobjectType = 'Technical_Information__c' And IsActive = true Limit 1];
			
		
    	//Creating a test Account
    	Mocks testData = new Mocks();
 
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.lstTI[0]);
    	TI_TelephoneNumberController test_ctl = new TI_TelephoneNumberController(sc);
    	
    	PageReference p = test_ctl.returnTechInfo();
    	
    	List<TI_TelephoneNumberController.wrapTelephoneNumber> numbers = test_ctl.TelephoneNumbers;
    	//Clearing a Telephone number record to test delete
    	numbers[0].telephone.Telephone_Number__c = null;
    	//Creating a Telephone number record in table list
    	Telephone_Number__c t3 = new Telephone_Number__c(Telephone_Number__c='987654321', Technical_Information__c=testData.lstTI[0].Id);
    	TI_TelephoneNumberController.wrapTelephoneNumber wt = new TI_TelephoneNumberController.wrapTelephoneNumber(t3);
    	numbers.add(wt);
    	
    	test_ctl.saveNumbers();
    	test_ctl.AddTenRows();
    	test_ctl.messageDisplay('test message');
    	test.stopTest();
    }
}