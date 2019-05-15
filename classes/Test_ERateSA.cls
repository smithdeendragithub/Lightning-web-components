@isTest
private class Test_ERateSA {
	static testMethod void TestERate() {
		Mocks testData = new Mocks();
        Account a = testData.parentAccount;
		
        test.startTest();
		ERateServiceAgreementController er = new ERateServiceAgreementController();
		er.CurrentOpportunity = testData.opportunity;
		List<ERateServiceAgreementController.Location> locs = er.OppLocations;
		ERateServiceAgreementController.Location l = new ERateServiceAgreementController.Location(testData.location);
		
		test.stopTest();
	}
}