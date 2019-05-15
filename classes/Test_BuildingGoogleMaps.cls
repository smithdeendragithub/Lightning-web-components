@isTest
public with sharing class Test_BuildingGoogleMaps extends TestUtils.TestClass {
	
    static testMethod void testController() {
    	Mocks testData = new Mocks();
    	
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.building);
		BuildingGoogleMapsController b = new BuildingGoogleMapsController(sc);
    }
}