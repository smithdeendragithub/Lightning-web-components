public class BuildingAccounts implements TestUtils.ITestableClass {
	public List<Service_Location__c> bsl {get;set;}

	public BuildingAccounts(ApexPages.StandardController stdController){
		ApexPages.Standardcontroller sc = stdController;
		if(!Test.isRunningTest()){
        sc.addFields(new List<String>{'id'});
		Building__c b = (Building__c)sc.getRecord();
		
		bsl = GetBuildingAccount(b);
		}
	}
	
	public List<Service_Location__c> GetBuildingAccount(Building__c b){

			//return [Select Account__r.Id, Account__r.Name, Account__r.Type, Account__r.Owner.Name, Id, Name, Location__r.Id, Location__r.Name, Account__r.Account_Sales_Channel__c From Service_Location__c Where Location__r.Building__c = :b.id Order by Location__r.Room_Suite__c];
			return [Select Account__r.Id, Account__r.Name, Account__r.Type, Account__r.Owner.Name, Id, Name, Location__r.Id, Location__r.Name From Service_Location__c Where Location__r.Building__c = :b.id Order by Location__r.Room_Suite__c];
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_BuildingAccounts(); }
}