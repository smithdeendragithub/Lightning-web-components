@isTest
public with sharing class Test_MSAGAddressSelector extends TestUtils.TestClass {
	
	static testMethod void testController() {
		Mocks testData = new Mocks();
		Test.startTest();
		
		PageReference pageReference = Page.CustomerDetailExtensionController;
		Test.setCurrentPage(pageReference);
		
		system.assertNotEquals(MSAGAddressSelectorController.AddressLookup('portland', 'OR', '1201 NW Lloyd'), '');
		
		Test.stopTest();
	}
}