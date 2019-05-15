@isTest
public with sharing class Test_ContactEmailOptOutController extends TestUtils.TestClass  {
	static testMethod void testController() {
		Contact con = new Contact(firstName = 'test', lastName = 'user', email='test@test.com');
		insert con;
		
		Test.startTest();
		
		PageReference pageReference = Page.ContactEmailOptOut;
		pageReference.getParameters().put('cid', con.Id);
		
		Test.setCurrentPage(pageReference);
		
		ContactEmailOptOutController troller = new ContactEmailOptOutController();
		troller.OptOut();
		Test.stopTest();
	}
}