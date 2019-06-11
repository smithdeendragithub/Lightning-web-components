@isTest
public with sharing class Test_Merge extends TestUtils.TestClass {
	
	static testMethod void testAccountMerge(){
		Mocks testData = new Mocks();
		
		sObjectType accountType = Account.getsObjectType();
		Account a1 = testData.parentAccount;
		a1 = ((List<Account>)ApexUtils.retrieveFullObjects(accountType, 'Id = \'' +  a1.Id + '\''))[0];
		
		Account a2 = (Account)ApexUtils.deepCopyFields(accountType, a1, new Account(), new Set<String>{'Customer_Detail__c','IsPartner'});
		a2.Name = 'Account 2';
		insert a2;
		
		test.startTest();
		
        PageReference pageReference = Page.Merge;
        Test.setCurrentPage(pageReference);
		
        pageReference.getParameters().put('objectType', 'Account');
        
    	MergeController mc = new MergeController();
		
		//Search and select 1
		mc.o1.allSearch = a1.Name;
		mc.objNum = 0;
		mc.search();
		mc.objID = a1.Id;
		mc.selectObj();
		
		//Search and select 2
		mc.o2.allSearch = a2.Name;
		mc.objNum = 1;
		mc.search();
		mc.objID = a2.Id;
		mc.selectObj();
		
		system.debug(mc.getDisplay != null);
		
		mc.mergeObjs();
		System.assert([select Id from Account where Id =: a1.Id].size() == 0, 'Merge from account was not deleted');
		
		System.debug(mc.getTestClass());
	}
}