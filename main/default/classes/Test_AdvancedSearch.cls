@isTest
public with sharing class Test_AdvancedSearch extends TestUtils.TestClass {
	
	static testMethod void testAccountSearch(){
        Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		a.Name = 'Test';
		update a;
		
		Service_Location__c sLoc = testData.serviceLocation;
		sLoc.Name = 'Test';
		update sLoc;
		
    	Test.startTest();
		
		Map<String, String> validSearchFields = AdvancedSearch.getValidSearchFields(new List<String>{'Account', 'Service_Location__c'});
		System.assert(validSearchFields.containsKey('name'), 'Name is not a valid search field for account and service location');
		
		//All field search
		AdvancedSearch.search('Test', new List<AdvancedSearch.SearchCriterion>(), new List<String>{'Account', 'Service_Location__c'}, null, null);
		
		List<AdvancedSearch.SearchCriterion> fieldSearchCriteria = new List<AdvancedSearch.SearchCriterion>();
		
		//Search just name
		AdvancedSearch.SearchCriterion sc = new AdvancedSearch.SearchCriterion('name');
		sc.value = 'Test';
		fieldSearchCriteria.add(sc);
    	
		AdvancedSearch.search('', fieldSearchCriteria, new List<String>{'Account', 'Service_Location__c'}, new Set<String>{'Billable__c', 'Customer_Detail__r.Name'}, null);
		
		//Search name and createddate
		sc = new AdvancedSearch.SearchCriterion('createddate');
		sc.value = Date.today().addDays(-1).format();
		sc.compareMode = AdvancedSearch.comp_GreaterThan;
		fieldSearchCriteria.add(sc);
		
		AdvancedSearch.search('', fieldSearchCriteria, new List<String>{'Account', 'Service_Location__c'}, new Set<String>{'Billable__c', 'Customer_Detail__r.Name'}, null);
    	
    	test.stopTest();
	}
	
	static testMethod void testInvalidSearch(){
		
		//No objects
		AdvancedSearch.search('', new List<AdvancedSearch.SearchCriterion>(), new List<String>(), null, null);
		
		//Invalid objects
		AdvancedSearch.search('', new List<AdvancedSearch.SearchCriterion>(), new List<String>{'Garbage'}, null, null);
		
		//All field too short
		AdvancedSearch.search('pu', new List<AdvancedSearch.SearchCriterion>(), new List<String>{'Account'}, null, null);
		
		//Criteria short
		AdvancedSearch.SearchCriterion sc = new AdvancedSearch.SearchCriterion('name');
		sc.value = 'pu';
		sc.compareMode = AdvancedSearch.comp_Contains;
		AdvancedSearch.search('', new List<AdvancedSearch.SearchCriterion>{sc}, new List<String>{'Account'}, null, null);
		
		//Exact date
		sc = new AdvancedSearch.SearchCriterion('createddate');
		sc.value = Date.today().format();
		sc.compareMode = AdvancedSearch.comp_Equal;
		AdvancedSearch.search('', new List<AdvancedSearch.SearchCriterion>{sc}, new List<String>{'Account'}, null, null);
		
		//Contains for non-string
		sc = new AdvancedSearch.SearchCriterion('createddate');
		sc.value = Date.today().format();
		sc.compareMode = AdvancedSearch.comp_Contains;
		AdvancedSearch.search('', new List<AdvancedSearch.SearchCriterion>{sc}, new List<String>{'Account'}, null, null);
		
		//Greater than string
		sc = new AdvancedSearch.SearchCriterion('name');
		sc.value = 'test';
		sc.compareMode = AdvancedSearch.comp_GreaterThan;
		AdvancedSearch.search('', new List<AdvancedSearch.SearchCriterion>{sc}, new List<String>{'Account'}, null, null);
		
		//Invalid date
		sc = new AdvancedSearch.SearchCriterion('createddate');
		sc.value = 'test';
		sc.compareMode = AdvancedSearch.comp_GreaterThan;
		AdvancedSearch.search('', new List<AdvancedSearch.SearchCriterion>{sc}, new List<String>{'Account'}, null, null);
	}
}