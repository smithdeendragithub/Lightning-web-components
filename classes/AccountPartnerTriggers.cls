public without sharing class AccountPartnerTriggers{
	
    public static void AccountPartnerModified(List<Account_Partner__c> tNew, List<Account_Partner__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('Account_Partner__c', isBefore, isDelete)) return;
		
    	if(isBefore){
			if(isDelete){
				preventDeletes(new Map<Id, Account_Partner__c>(tOld));
			}
			else{
				handleUpserts(tNew);
			}
    	}
    	else{
	        handleOwnershipRecalculation(isDelete ? tOld : tNew);
			ApexUtils.afterTriggerComplete('Account_Partner__c', isDelete);
    	}
	}
	
	private static Id agentRT = null;
	private static Id guestRT = null;
	private static Boolean rtsLoaded = false;
	private static Boolean isAgency(Account_Partner__c p){
		retrieveRecordTypes();
		return p.RecordTypeId == agentRT;
	}
	
	private static Boolean isGuest(Account_Partner__c p){
		retrieveRecordTypes();
		return p.RecordTypeId == guestRT;
	}
	
	private static void retrieveRecordTypes(){
		if(!rtsLoaded){
			for(RecordType rt : [select Id, DeveloperName from RecordType where sObjectType = 'Account_Partner__c' and DeveloperName in: ICCWrapper.PartnerAgentTypes]){
				if(rt.DeveloperName == ICCWrapper.partnerAgent) agentRT = rt.Id;
				if(rt.DeveloperName == ICCWrapper.partnerGuestAgent) guestRT = rt.Id;
			}
			rtsLoaded = true;
		}
	}
	
	private static void preventDeletes(Map<Id, Account_Partner__c> tOldMap){
		Set<Id> accountIDs = new Set<Id>();
		Set<Id> partnerIDs = new Set<Id>();
		for(Account_Partner__c p : tOldMap.values()){
			accountIDs.add(p.Account__c);
			partnerIDs.add(p.Partner__c);
		}
		
		Map<Id, Set<String>> erroredIDs = new Map<Id, Set<String>>();
		for(Customer_Detail__c cd : [select Id, (select Id, Contact__c, Contact__r.AccountId from Customer_Contacts__r where Contact__r.AccountId in: partnerIDs and Contact__r.AccountId != null) from Customer_Detail__c where Parent_Account__c in: accountIDs]){
			for(Customer_Contact__c cc : cd.Customer_Contacts__r != null ? cd.Customer_Contacts__r : new List<Customer_Contact__c>()){
				Set<String> s = erroredIDs.get(cc.Contact__r.AccountId) != null ? erroredIDs.get(cc.Contact__r.AccountId) : new Set<String>();
				s.add(cc.Contact__c);
				erroredIDs.put(cc.Contact__r.AccountId, s);
			}
		}
		
		for(Account_Partner__c p : tOldMap.values()){
			if(erroredIDs.containsKey(p.Partner__c)){
				p.addError('The following contacts from the partner account are being used by the assigned account\'s customer details: ' + String.join(new List<String>(erroredIDs.get(p.Partner__c)), ', '));
			}
		}
	}
	
	private static void handleUpserts(List<Account_Partner__c> tNew){
		
		Map<Id, Boolean> aMap = new Map<Id, Boolean>();
		for(Account_Partner__c p : tNew){
			if(isAgency(p) || isGuest(p)){
				aMap.put(p.Account__c, aMap.get(p.Account__c) != null);		//Prevent dupes within the current set
				/*if(p.Split_Ownership_Percentage__c == null){
					if(isAgency(p)) p.Split_Ownership_Percentage__c =  50;
					if(isGuest(p)) p.Split_Ownership_Percentage__c =  0;
				}*/
			}
		}
		
		for(Account_Partner__c p : [select Account__c from Account_Partner__c where Account__c in: aMap.keyset() and Id not in: tNew and RecordType.DeveloperName in: ICCWrapper.PartnerAgentTypes])
			aMap.put(p.Account__c, true);
		
		for(Account_Partner__c p : tNew){
			if((isAgency(p) || isGuest(p)) && aMap.get(p.Account__c)){
				p.addError('Only one external agency partner type is allowed on an account at once.');
			}
		}
	}
	
    private static void handleOwnershipRecalculation(List<Account_Partner__c> l){
    	
    	Set<Id> accountIDs = new Set<Id>();
    	for(Account_Partner__c a : l){
			if(isAgency(a) || isGuest(a)) accountIDs.add(a.Account__c);
    	}
		
		Batch_CalculateAccountOwnership.RecalculateAccounts(accountIDs);
    }
}