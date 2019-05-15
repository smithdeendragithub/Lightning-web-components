@isTest
public with sharing class Test_ApexUtils extends TestUtils.TestClass {
     
     static testMethod void testOrdinals() {
     	
     	String origin;
     	String destination;
     	
     	origin = '1';
     	destination = ApexUtils.numberToOrdinal(origin);
     	
     	system.assertEquals(destination, '1st');
     	
     	origin = '2';
     	destination = ApexUtils.numberToOrdinal(origin);
     	
     	system.assertEquals(destination, '2nd');
     	
     	origin = '3';
     	destination = ApexUtils.numberToOrdinal(origin);
     	
     	system.assertEquals(destination, '3rd');
     	
     	origin = '11';
     	destination = ApexUtils.numberToOrdinal(origin);
     	
     	system.assertEquals(destination, '11th');
	}
    
	static testMethod void captureIdByPostionTest(){
		String sValue = '001c0000001xk7i?macRedirectFlag=1&macRecordId=001c0000001tm7i&macRecordName=Angie+Test+Account+1&macSearchString=ang&macPosition=0&macSearchArea=header';
		test.startTest();
		ApexUtils.captureIdByPostion(sValue, 0);
		ApexUtils.captureIdByPostion(sValue, -1);
		System.assertEquals(ApexUtils.captureIdByPostion(sValue, 0), '001c0000001xk7iAAA');
		System.assertEquals(ApexUtils.captureIdByPostion(sValue, 1), '001c0000001tm7iAAA');
		test.stopTest();
	}
	
	static testMethod void testIsValidId(){
		ApexUtils.isValidId('garbage');
	}
	
	static testMethod void testSort(){
		Mocks testdata = new Mocks();
		List<Account> aList = testdata.accounts;
		test.startTest();
		
		ApexUtils.sortValues(aList, true);
		ApexUtils.sortValues(aList, false);
		
		ApexUtils.sortByComparableField(aList, 'name', true, true);
		ApexUtils.sortByComparableField(aList, 'name', true, false);
		ApexUtils.sortByComparableField(aList, 'name', false, true);
		ApexUtils.sortByComparableField(aList, 'name', false, false);
	}
    
    static testMethod void testCreateEmailMessage1() {
        User testUser = [Select id From User where Name = 'Integration User' LIMIT 1];
        String[] ccList = new String[]{};
        Messaging.Singleemailmessage email = ApexUtils.createEmailMessage(testUser.id, ccList, 'Test', 'This is a test', false, 'integration.user@allstream.com');
        
    }
    
    static testMethod void testCreateEmailMessage2() {
        String[] toList = new String[]{'integration.user@allstream.com'};
        String[] ccList = new String[]{};
        Messaging.Singleemailmessage email = ApexUtils.createEmailMessage(toList, ccList, 'Test', 'This is a test', false, 'integration.user@allstream.com');
        
    }
    
    //Messaging.Singleemailmessage createTemplatedEmailMessage(Id to, Id templateId, Id relatedToId)
  }