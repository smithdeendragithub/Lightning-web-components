@isTest
public with sharing class Test_AccountSearch extends TestUtils.TestClass {
 	static testMethod void testController() {
    	AccountSearchController sc = new AccountSearchController();
    	sc.allFieldSearch = 'something';
    	sc.onlySearchProspects = true;
    	sc.pastDueSearch = true;
    	sc.nameSearch.value = sc.phoneSearch.value = sc.citySearch.value = sc.stateSearch.value = 'some things';
		sc.streetSearch.value = sc.zipSearch.value = sc.billplexSubIDSearch.value = sc.mssAccountIDSearch.value = sc.legacyIDSearch.value = sc.subscriberIDSearch.value = 'some other things%';
		sc.directSearch();
		
		sc.contactFirstNameSearch.value = sc.contactLastNameSearch.value = sc.contactPhoneSearch.value = 'some guy';
		sc.searchByContact();
    }
}