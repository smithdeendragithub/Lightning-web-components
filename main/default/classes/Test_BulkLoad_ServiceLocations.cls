@isTest
public with sharing class Test_BulkLoad_ServiceLocations extends TestUtils.TestClass {
	
	static testMethod void testController() {
        Mocks testData = new Mocks();
    	test.startTest();
		
    	BulkLoad_ServiceLocations bl = new BulkLoad_ServiceLocations();
		bl.acc = testData.parentAccount;
    	bl.bulkQualify();
    	bl.attach();
		
		//BulkLoad_ServiceLocations.CreateTaskForNoServingLSO(testData.building, 'TestWireCenterCLLI');
    	
    	test.stopTest();
    }
	
	static testMethod void testSearch(){
        Mocks testData = new Mocks();
    	test.startTest();
		
    	BulkLoad_ServiceLocations bl = new BulkLoad_ServiceLocations();
		bl.acc = testData.parentAccount;
		
		bl.searchdata();
		bl.searchSLocs();
    	
    	test.stopTest();
	}
}