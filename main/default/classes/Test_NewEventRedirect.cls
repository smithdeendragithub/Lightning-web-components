@isTest
public with sharing class Test_NewEventRedirect extends TestUtils.TestClass {
	
    static testmethod void testNewEventRedirect(){
    	Mocks mocks = new Mocks();
    	
        test.startTest();
    	
    	ApexPages.StandardController controller = new ApexPages.StandardController(new Event());
    	NewEventRedirect ner = new newEventRedirect(controller);
    	ner.sourceId = mocks.parentAccount.Id;
    	ner.newEvent();
    	
    	test.stopTest();
    }
}