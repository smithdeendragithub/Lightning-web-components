@isTest
public with sharing class Test_Chatter{

	static testMethod void testAutoFollow() {
		Mocks testData = new Mocks();
		
		User u = testData.user;
		
		Chatter_Auto_Follow__c caf = new Chatter_Auto_Follow__c(Criteria__c=null, Group__c='Test', Name='Test');
		insert caf;
		
    	Test.startTest();
		
		update u;
	}
	
	static testMethod void testChatterTermsOfUse(){
		ChatterTermsOfUseController ctrl = new ChatterTermsOfUseController();
		ctrl.Agree();
	}
}