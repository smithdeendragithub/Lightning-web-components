@isTest
public with sharing class Test_BuildingAccounts extends TestUtils.TestClass {

    static testMethod void BuildAccounts() {
    	Mocks testData = new Mocks();
    	
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.parentAccount);
		BuildingAccounts b = new BuildingAccounts(sc);
    }
}