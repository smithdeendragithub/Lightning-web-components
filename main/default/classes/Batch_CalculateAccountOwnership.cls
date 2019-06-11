global class Batch_CalculateAccountOwnership implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
	
	public static final Integer DefaultBatchSize = 10;
	private static final String OwnershipRecalculating = 'Recalculating';
	
	public static Boolean Recalculating = false;
	
	private final Set<Id> batchIDs;
	private Datetime startTime;
	private Map<Id, String> batchUpdates = null;
	private String sessionID = null;
	private String userEmail = null;

	global Batch_CalculateAccountOwnership(Set<Id> accountIDs) {
		batchIDs = accountIDs;
		startTime = Datetime.now();
		sessionID = UserInfo.getSessionId();
		userEmail = UserInfo.getUserEmail();
		gatherBatchUpdates();
	}

	global Database.QueryLocator start(Database.BatchableContext bc){
	   return Database.getQueryLocator([select Id from Account where Id in: batchIDs and RecordType.DeveloperName != 'System']);
	}

	global void execute(Database.BatchableContext bc, List<sObject> scope){
	  	RecalculateOwnership((new Map<Id, sObject>(scope)).keyset());
		gatherBatchUpdates();
	}
	
	private void gatherBatchUpdates(){
		if(CustomerDetailTriggers.batchUpdates != null && CustomerDetailTriggers.batchUpdates.size() > 0){
			if(batchUpdates == null) batchUpdates = new Map<Id, String>();
			for(Id id : CustomerDetailTriggers.batchUpdates.keySet()){
				Set<String> updates = batchUpdates.get(id) != null ? new Set<String>(CustomerDetailTriggers.batchUpdates.get(id).split(',')) : new Set<String>();
				updates.addAll(CustomerDetailTriggers.batchUpdates.get(id).split(','));
				batchUpdates.put(id, string.join(new List<String>(updates), ','));
			}
		}
	}
	
	public static void RecalculateOwnership(Set<Id> accountIDs){
		Map<Id, Account> accounts = new Map<Id, Account>([select Id, Dual_Ownership__c, Indirect_Ownership_Type__c, Owner.Id, Owner.Sales_Channel__c
															,Customer_Detail__r.Id
															,Customer_Detail__r.Owner_Agency__c
															,Customer_Detail__r.Split_Owner__c
															,Customer_Detail__r.Split_Owner_Agency__c
															,Customer_Detail__r.Split_Owner_Percentage__c
															,(select Id, Account__c, Indirect_Ownership_Type__c, Owner__r.Id, Owner__r.Sales_Channel__c
																,Customer_Detail__r.Id
																,Customer_Detail__r.Owner_Agency__c
																,Customer_Detail__r.Split_Owner__c
																,Customer_Detail__r.Split_Owner_Agency__c
																,Customer_Detail__r.Split_Owner_Percentage__c
																from Account_Locations__r)
															,(select Id, Account__c, Partner__c, RecordType.DeveloperName from Account_Partners__r where RecordType.DeveloperName in: ICCWrapper.PartnerAgentTypes)
															from Account where Id in: accountIDs]);
		
		Map<Id, Service_Location__c> serviceLocs = new Map<Id, Service_Location__c>();
		Map<Id, Account_Partner__c> accountAgents = new Map<Id, Account_Partner__c>();
		for(Account account : accounts.values()){
			for(Service_Location__c sLoc : account.Account_Locations__r != null ? account.Account_Locations__r : new List<Service_Location__c>())
				serviceLocs.put(sLoc.Id, sLoc);
			
			for(Account_Partner__c p : account.Account_Partners__r != null ? account.Account_Partners__r : new List<Account_Partner__c>())
				accountAgents.put(p.Account__c, p);
		}
		
		Map<Id, Customer_Detail__c> details = new Map<Id, Customer_Detail__c>();
		for(Account a : accounts.values()){
			if(a.Customer_Detail__c != null) details.put(a.Customer_Detail__c, a.Customer_Detail__r);
		}
		
		for(Service_Location__c sLoc : serviceLocs.values()){
			if(sLoc.Customer_Detail__c != null) details.put(sLoc.Customer_Detail__c, sLoc.Customer_Detail__r);
		}
		
		for(Account a : accounts.values()){
			Boolean accountIndirect = a.Owner.Sales_Channel__c != null && (a.Owner.Sales_Channel__c.toLowercase().contains('indirect') || a.Owner.Sales_Channel__c.equals('Allstream Alliance-CAN') || a.Owner.Sales_Channel__c.equals('Allstream Alliance-US'));
			
			Account_Partner__c p = accountAgents.get(a.Id);
			a.Indirect_Ownership_Type__c = determineOwnershipType(p, a.Dual_Ownership__c, accountIndirect, null);
			if(!a.Dual_Ownership__c) setCustomerDetailOwnershipFields(details.get(a.Customer_Detail__c), a.Indirect_Ownership_Type__c, a.OwnerId, p);
		}
		
		for(Service_Location__c sLoc : serviceLocs.values()){
			Account a = accounts.get(sLoc.Account__c);
			Boolean accountIndirect = a.Owner.Sales_Channel__c != null && (a.Owner.Sales_Channel__c.toLowercase().contains('indirect') || a.Owner.Sales_Channel__c.equals('Allstream Alliance-CAN') || a.Owner.Sales_Channel__c.equals('Allstream Alliance-US'));
			Boolean sLocIndirect = sLoc.Owner__r.Sales_Channel__c != null && (sLoc.Owner__r.Sales_Channel__c.toLowercase().contains('indirect') || sLoc.Owner__r.Sales_Channel__c.equals('Allstream Alliance-CAN') || sLoc.Owner__r.Sales_Channel__c.equals('Allstream Alliance-US'));
			
			Account_Partner__c p = accountAgents.get(a.Id);
			sLoc.Indirect_Ownership_Type__c = determineOwnershipType(p, a.Dual_Ownership__c, accountIndirect, sLocIndirect);
			if(!a.Dual_Ownership__c){
				sLoc.Owner__c = a.OwnerId;
				setCustomerDetailOwnershipFields(details.get(sLoc.Customer_Detail__c), sLoc.Indirect_Ownership_Type__c, sLoc.Owner__c, p);
			}
		}
		
		//Replace the system ownership types with the user friendly versions
		for(List<sObject> l : new List<List<sObject>>{accounts.values(), serviceLocs.values()}){
			for(sObject o : l){
				String ot = string.valueOf(o.get('Indirect_Ownership_Type__c'));
				if(ot.contains('Indirect')) ot = 'Indirect Owned';
				if(ot.contains('Guest')) ot = 'Guest';
				if(ot.startsWith('Direct')) ot = '';
				o.put('Indirect_Ownership_Type__c', ot);
			}
		}
		
		Recalculating = true;
		SecurityUtils.BypassProcesser.saveObjects(accounts.values(), false);
		SecurityUtils.BypassProcesser.saveObjects(serviceLocs.values(), false);
		
		CustomerDetailTriggers.IntegrateAllOwners = true;
		SecurityUtils.BypassProcesser.saveObjects(details.values(), false);
		Recalculating = false;
	}
	
	public static String determineOwnershipType(Account_Partner__c p, Boolean dualOwnership, Boolean indirectOwnedRoot, Boolean indirectOwnedLoc){
		Integer partnerType = (p == null) ? 0 : (p.RecordType.DeveloperName == ICCWrapper.partnerAgent ? 1 : 2);
		
		Boolean locMode = indirectOwnedLoc != null;
		Boolean isIndirect = (locMode && dualOwnership) ? indirectOwnedLoc : indirectOwnedRoot;	//We only check the location's sales channel under dual-ownership assignments
		
		return partnerType == 0
			? (isIndirect
				? 'Indirect'		//No partner, indirect
				: 'Direct')			//No partner, non-indirect
			: (partnerType == 1
				? (isIndirect
					? 'Indirect Agent'	//Agent partner, indirect
					: (dualOwnership
						? 'Dual Ownership'	//Agent partner, non-indirect, dual-ownership
						: 'Team Sold'))		//Agent partner, non-indirect, non-dual-ownership
				: (isIndirect
					? 'Indirect with Guest'	//Guest partner, indirect
					: 'Direct with Guest'));	//Guest partner, non-indirect
	}
	
	private static void setCustomerDetailOwnershipFields(Customer_Detail__c cd, String ownershipType, Id ownerID, Account_Partner__c p){
		if(cd != null){
			System.debug('Updating ' + cd.Id + ' with ownership logic for ' + ownershipType);
			
			cd.Owner_Agency__c = cd.Split_Owner_Agency__c = null;
			cd.Split_Owner__c = null;
			
			if(ownershipType == 'Indirect Agent' || ownershipType == 'Team Sold') cd.Owner_Agency__c = p.Partner__c;
			if(ownershipType.contains('Guest')) cd.Split_Owner_Agency__c = p.Partner__c;
			if(ownershipType == 'Team Sold') cd.Split_Owner__c = ownerID;
			
			cd.Split_Owner_Percentage__c = (cd.Split_Owner__c != null || cd.Split_Owner_Agency__c != null) ? (ownershipType == 'Team Sold' ? 50 : 0) : null;
			System.debug('Agency: ' + cd.Owner_Agency__c + '; Split Agency: ' + cd.Split_Owner_Agency__c + '; Split Owner: ' + cd.Split_Owner__c + '; Split Owner %: ' + cd.Split_Owner_Percentage__c);
		}
	}

	global void finish(Database.BatchableContext bc){
	    if(batchUpdates != null && batchUpdates.size() > 0)
			CustomerDetailTriggers.updateSubscribers_flushBatch(batchUpdates, sessionID, userEmail);
		
		Datetime completeTime = Datetime.now();
		if(startTime.addSeconds(10) < completeTime){
			//todo: send email to start user
		}
	}
	
    public static void HandleOwnershipRecalculation(List<Account> tNew, Map<Id, Account> tOldMap, Boolean isBefore){
    	if(Recalculating || ServiceLocationTriggers.SynchronizingFields) return;
		
		if(isBefore){
	    	for(Account aNew : tNew){
	    		Account aOld = tOldMap.get(aNew.Id);
	    		if(aOld == null
	    			|| aNew.OwnerId != aOld.OwnerId
	    			|| aNew.Customer_Detail__c != aOld.Customer_Detail__c
	    			|| aNew.Dual_Ownership__c != aOld.Dual_Ownership__c
	    			|| aNew.Indirect_Ownership_Type__c != aOld.Indirect_Ownership_Type__c){
					aNew.Indirect_Ownership_Type__c = OwnershipRecalculating;
				}
	    	}
		}
		else{
	    	Set<Id> r = new Set<Id>();
	    	for(Account aNew : tNew){
	    		if(aNew.Indirect_Ownership_Type__c == OwnershipRecalculating)
					r.add(aNew.Id);
	    	}
	    	
	    	batchRecalculateAccounts(r);
		}
    }
	
    public static void HandleOwnershipRecalculation(List<Customer_Detail__c> tNew, Map<Id, Customer_Detail__c> tOldMap){
    	if(Recalculating) return;
    	
    	Set<Id> accountIDs = new Set<Id>();
    	for(Customer_Detail__c cdNew : tNew){
    		Customer_Detail__c cdOld = tOldMap.get(cdNew.Id);
    		if(cdNew.Parent_Account__c != SecurityUtils.SystemAccount.Id
				&& (cdOld == null
					|| cdNew.Parent_Account__c != cdOld.Parent_Account__c
					|| cdNew.Owner_Agency__c != cdOld.Owner_Agency__c
					|| cdNew.Split_Owner__c != cdOld.Split_Owner__c
					|| cdNew.Split_Owner_Agency__c != cdOld.Split_Owner_Agency__c
					|| cdNew.Split_Owner_Percentage__c != cdOld.Split_Owner_Percentage__c)){
				accountIDs.add(cdNew.Parent_Account__c);
			}
    	}
    	
	    RecalculateAccounts(accountIDs);
    }
	
    public static void HandleOwnershipRecalculation(List<Service_Location__c> tNew, Map<Id, Service_Location__c> tOldMap){
    	if(Recalculating || AccountTriggers.SynchronizingFields) return;
    	
    	Set<Id> accountIDs = new Set<Id>();
    	for(Service_Location__c sNew : tNew){
    		Service_Location__c sOld = tOldMap.get(sNew.Id);
    		if(sOld == null
				|| sNew.Owner__c != sOld.Owner__c
				|| sNew.Account__c != sOld.Account__c
				|| sNew.Customer_Detail__c != sOld.Customer_Detail__c
				|| sNew.Indirect_Ownership_Type__c != sOld.Indirect_Ownership_Type__c){
				accountIDs.add(sNew.Account__c);
			}
    	}
    	
	    RecalculateAccounts(accountIDs);
    }
	
    public static void HandleOwnershipRecalculation(List<User> tNew, Map<Id, User> tOldMap){
    	if(Recalculating) return;
    	
    	Set<Id> updated = new Set<Id>();
    	for(User uNew : tNew){
    		User uOld = tOldMap.get(uNew.Id);
			String scNew = uNew.Sales_Channel__c != null ? uNew.Sales_Channel__c : '';
			String scOld = uOld.Sales_Channel__c != null ? uOld.Sales_Channel__c : '';
			if(scNew != scOld && ((scNew.toLowercase().contains('indirect') != scOld.toLowercase().contains('indirect')) || (scNew.equals('Allstream Alliance-CAN') != scOld.equals('Allstream Alliance-CAN')) || (scNew.equals('Allstream Alliance-US') != scOld.equals('Allstream Alliance-US')) )){
				updated.add(uNew.Id);
			}
    	}
		
		if(updated.size() > 0){
			Set<Id> accountIDs = new Set<Id>((new Map<Id, Account>([select Id from Account where OwnerId in: updated])).keyset());
			for(Service_Location__c sLoc : [select Id, Account__c from Service_Location__c where Owner__c in: updated])
				accountIDs.add(sLoc.Account__c);
	    	
	    	RecalculateAccounts(accountIDs);
		}
    }
	
	public static void RecalculateAccounts(Set<Id> accountIDs){
		List<Account> accounts = accountIDs.size() > 0 ? [select Id from Account where Id in: accountIDs and Indirect_Ownership_Type__c !=: OwnershipRecalculating] : new List<Account>();
		for(Account a : accounts)
			a.Indirect_Ownership_Type__c = OwnershipRecalculating;
		
		if(accounts.size() > 0){
			Boolean tVal = AccountTriggers.DisableTrigger;
			AccountTriggers.DisableTrigger = true;
			SecurityUtils.BypassProcesser.saveObjects(accounts, false);
			AccountTriggers.DisableTrigger = tVal;
			
			batchRecalculateAccounts(accountIDs);
		}
	}
	
	private static void batchRecalculateAccounts(Set<Id> accountIDs){
		if(accountIDs.size() > 0  && !Test.isRunningTest()) Database.executeBatch(new Batch_CalculateAccountOwnership(accountIDs), DefaultBatchSize);
	}
}