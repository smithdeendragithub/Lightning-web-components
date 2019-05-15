@isTest
public with sharing class Test_GlobalUtilities extends TestUtils.TestClass {

    static testMethod void testUtils() {
		
		Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		Contact c = testData.parentAccountContact;
		Opportunity o = testData.opportunity;
		
		test.startTest();
		
		List<GlobalUtilities.Recipient> lst = GlobalUtilities.LoadRecipients(o);
		if(lst.size() > 0){
			lst[0].setCC(true);
			System.assert(lst[0].getCC() == true);
			
			lst[0].setTo(true);
			System.assert(lst[0].getTo() == true);
		}
		
		test.stopTest();
    }
}