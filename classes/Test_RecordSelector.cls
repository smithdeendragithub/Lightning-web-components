@isTest
public with sharing class Test_RecordSelector extends TestUtils.TestClass {
	
	static testMethod void testRecordSelector() {
		Mocks testData = new Mocks();
		
		PageReference pageReference = ApexPages.currentPage();
		pageReference.getParameters().put('sObjectType', 'building__c');
		pageReference.getParameters().put('fields', 'Id,Address__c,City__c,State__c,Postal_Code__c,Name');
		//pageReference.getParameters().put('useRecentRecords', 'true');
		
		RecordSelectorController rsc = new RecordSelectorController();
		
		rsc.multiSelect = false;
		rsc.useRecent = true;
		rsc.filter = 'test';
		rsc.sObjType = 'Building__c';
		rsc.objFields = 'Id,Name';
		rsc.customWhere = 'Locked__c = false';
		System.debug(rsc.sObjType);
		System.debug(rsc.objFields);
		rsc.refreshDataTable(true);
		
		rsc.Reset();
		rsc.ToggleViewMode();
		rsc.GatherSelection();
		
		rsc.PageUpdated('test');
		rsc.SortChanged('test');
		sObjectType t = testdata.building.getSObjectType();
		RecordSelectorController.Config c = new RecordSelectorController.Config(t,false);
		RecordSelectorController.sObjectConfig sc = new RecordSelectorController.sObjectConfig(testData.building.Id);
	}
}