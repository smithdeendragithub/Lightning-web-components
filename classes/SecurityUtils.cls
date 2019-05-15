public with sharing class SecurityUtils {
	private static Account sysAccount;
	public static Account SystemAccount{
		get{
			if(sysAccount == null){
				if(test.isRunningTest())
					Test_SecurityUtils.getSystemAccountID();
				
				sysAccount = BypassProcesser.getSystemAccount();
			}
			return sysAccount;
		}
	}
	
	private static Boolean chatterTermsAccepted;
	public static Boolean currentUserHasAgreedToChatterTerms(){
		if(chatterTermsAccepted == null){
			DateTime chatterTermsLastAccepted = [select Chatter_Terms_Last_Accepted__c from User where Id =: UserInfo.getUserId()].Chatter_Terms_Last_Accepted__c;
			List<StaticResource> termsOfUse = [select LastModifiedDate from StaticResource where Name = 'ChatterTermsOfUse' limit 1];
			chatterTermsAccepted = termsOfUse.size() == 0 || (chatterTermsLastAccepted != null && chatterTermsLastAccepted > termsOfUse[0].LastModifiedDate);
		}
		
		return test.isRunningTest() || chatterTermsAccepted;
	}
	
	public static Boolean checkCurrentUserHasChatterAccess(List<sObject> tNew, Map<Id, sObject> tOldMap){
		Boolean canUseChatter = currentUserHasAgreedToChatterTerms();
		
		List<sObject> l = tNew != null ? tNew : tOldMap.values();
		if(!canUseChatter){
			for(sObject c : l)
				c.addError('You must agree to the most recent chatter terms of usage before using chatter. Please navigate to your Home tab to agree to the terms.');
		}
		
		return canUseChatter;
	}
	
	public static Boolean checkObjectAccess(sObjectType objType, Boolean viewOnly, Boolean printPageMessage){
        Schema.Describesobjectresult r = objType.getDescribe();
		Boolean hasAccess = (viewOnly && r.isAccessible()) || (!viewOnly && r.isUpdateable());
        if(!hasAccess && printPageMessage) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You require ' + (viewOnly ? 'view' : 'edit') + ' access to the object type \'' + r.getLabel() + '\' to use this page'));
        return hasAccess;
	}
	
	private static String p_currentUserAccountTransferAccess = null;
	public static String CurrentUserAccountTransferAccess{
		get{
			if(p_currentUserAccountTransferAccess == null){
				p_currentUserAccountTransferAccess = 'None';
				for(Custom_Permissions__c p : CustomSettingUtils.getCurrentUserCustomPermissions()){
					if((p_currentUserAccountTransferAccess == 'None' && p.Account_Transfer_Access__c == 'Prospects') || p.Account_Transfer_Access__c == 'Subscribers')
						p_currentUserAccountTransferAccess = p.Account_Transfer_Access__c;
				}
			}
			return p_currentUserAccountTransferAccess;
		}
	}
	
	public static Boolean currentUserHasProspectTransferAccess(){
		return CurrentUserAccountTransferAccess != 'None';
	}
	
	public static Boolean currentUserHasSubscriberTransferAccess(){
		return CurrentUserAccountTransferAccess == 'Subscribers';
	}
	
	public static Boolean AllowTemporaryOwnershipUpdates = false;
	public static Boolean stopOwnershipUpdates(List<sObject> tNew, Map<Id, sObject> tOldMap){
		Boolean retval = false;
		
		Boolean sLocMode = SchemaUtils.GetSObjectNameByID(tNew[0].Id) == 'Service_Location__c';
		for(sObject t : tNew){
			Boolean isSubscriber = t.get(sLocMode ? 'ICC_Subscriber_ID__c' : 'ICC_Account_Number__c') != null;
			Boolean preventUpdate = t.get(sLocMode ? 'Owner__c' : 'OwnerId') != tOldMap.get(t.Id).get(sLocMode ? 'Owner__c' : 'OwnerId')
									&& ((isSubscriber && !currentUserHasSubscriberTransferAccess()) || (!isSubscriber && !currentUserHasProspectTransferAccess()))
									&& !AllowTemporaryOwnershipUpdates;
			if(preventUpdate) t.addError('You do not have access to change Account ownership.');
			retval |= preventUpdate;
		}
		
		return retval;
	}
	
	public static Boolean currentUserHasRecordAccess(Id recordID, Boolean editMode){
		Boolean access = false;
		for(UserRecordAccess ura : [select HasReadAccess, HasEditAccess, RecordId from UserRecordAccess where RecordID =: recordID and UserID =: UserInfo.getUserId()])
			access |= (editMode ? ura.HasEditAccess : ura.HasReadAccess);
		return access;
	}
	
	public static void updateAccountContractStatuses(Set<Id> accountIDs, String status, Set<String> fromStatuses){
		BypassProcesser.updateContractStatuses(accountIDs, status, fromStatuses, new Map<Id, Date>());
	}
	
	public static void updateAccountContractStatuses(Set<Id> accountIDs, String status, Set<String> fromStatuses, Map<Id, Date> executionDates){
		BypassProcesser.updateContractStatuses(accountIDs, status, fromStatuses, executionDates);
	}
	
	//Use sparingly for whenever something must succeed regardless of executing user security
	public virtual without sharing class ISecurityBypassProcessor{
		
		public List<Database.DeleteResult> deleteObjects(List<sObject> objs, Boolean failOnError){
			return Database.Delete(objs, failOnError);
		}
		
		public List<Database.SaveResult> insertObjects(List<sObject> objs, Boolean failOnError){
			return Database.Insert(objs, failOnError);
		}
		
		public List<Database.UpsertResult> saveObjects(List<sObject> objs, Boolean failOnError){
			return Database.Upsert(objs, failOnError);
		}
	}
	
	public without sharing class SecurityBypassProcessor extends ISecurityBypassProcessor{
		public SecurityBypassProcessor(){}
		
		public Account getSystemAccount(){
			Id rtID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('System').getRecordTypeId();
			return [select Id from Account where RecordTypeId =: rtID limit 1];
		}
		
		public void updateContractStatuses(Set<Id> accountIDs, String status, Set<String> fromStatuses, Map<Id, Date> executionDates){
			List<Integra_Contract__c> cList = (List<Integra_Contract__c>)Database.query('select Id, Account__c, Execution_Date__c from Integra_Contract__c where Account__c in: accountIDs and ' + (fromStatuses != null && fromStatuses.size() > 0 ? 'Status__c in: fromStatuses' : 'Status__c !=: status'));
			for(Integra_Contract__c c : cList){
				c.Status__c = status;
				c.Execution_Date__c = (c.Execution_Date__c == null) ? executionDates.get(c.Account__c) : c.Execution_Date__c;
			}
			
			if(cList.size() > 0)
				Database.Update(cList, false);
		}
	}
	
	private static SecurityBypassProcessor bp = null;
	public static SecurityBypassProcessor BypassProcesser{
		get{
			if(bp == null)
				bp = new SecurityBypassProcessor();
			return bp;
		}
	}
}