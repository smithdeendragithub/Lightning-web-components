@isTest
public with sharing class Test_ObjectPropertyController  extends TestUtils.TestClass {
	static testMethod void testController() {
		Mocks testData = new Mocks();
    	Test.startTest();
		
		ObjectPropertyController ctrl = new ObjectPropertyController();
		ctrl.sObjectID = testData.opportunity.Id;
		String an = ctrl.AccountNameDisplay;
		String cr = ctrl.CollectionRepDisplay; 
		String opn = ctrl.OppNameDisplay; 
		String osfid = ctrl.OppSFIDDisplay; 
		string oid = ctrl.OrderIDDisplay; 
		string rp = ctrl.ResponsiblePartyDisplay; 
		string sb = ctrl.SignedByDisplay;
						
		Test.stopTest();
	}
}