@isTest
public with sharing class Test_SecurityUtils {

	private static Account systemAccount;
	public static Id getSystemAccountID(){
		if(systemAccount == null){
			systemAccount = new Account(Name = 'System Account'
										,RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('System').getRecordTypeId());
			insert systemAccount;
		}
		return systemAccount.Id;
	}
}