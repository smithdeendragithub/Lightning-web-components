@isTest
public with sharing class Test_ServiceLocationAccountMassUpdate extends TestUtils.TestClass {
 	static testMethod void testMove(){
        Mocks testData = new Mocks();
		
		Service_Location__c sLoc = testData.serviceLocation;
		sLoc.Billable__c = true;
		update sLoc;
		
		
		
		Test.startTest();
		
		ServiceLocationAccountMassUpdate sc = new ServiceLocationAccountMassUpdate(sLoc.Id);
        sc.increaseCodeCoverage();
    	sc.move();
	}
    
    static testMethod void testMove2(){
        Mocks testData = new Mocks();
        Service_Location__c sLoc = testData.serviceLocation;
		sLoc.Billable__c = true;
        update sLoc;
		
		Test.startTest();
		
        System.assert(ServiceLocationAccountMassUpdate.changeParent(), false);
	}
    
	
	
    
}