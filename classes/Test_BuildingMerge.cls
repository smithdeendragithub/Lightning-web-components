@isTest
public with sharing class Test_BuildingMerge extends TestUtils.TestClass {
	
	static testMethod void testBuildingMerge() {
		Mocks testData = new Mocks();
		
		BuildingMergeController bmc = new BuildingMergeController();
		bmc.buildingID = testData.building.Id;
		bmc.mergeType = 'From';
				
		bmc.GetBuildingData();
		
		bmc.buildingID = testData.building.Id;
		bmc.mergeType = 'To';
		bmc.GetBuildingData();
		
		bmc.mergeObjs();
	}
}