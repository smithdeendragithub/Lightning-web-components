public without sharing class ServiceLocationTriggers {

    public static Boolean DisableIntegration = false;
	public static Boolean SynchronizingFields = false;
    
    public static void ServiceLocationModified(List<Service_Location__c> tNew, List<Service_Location__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('Service_Location__c', isBefore, false)) return;
    	
    	if(isBefore){
    		if(!isDelete){
		        if(!isUpdate)
		        	fixCustomerDetails(tNew, true);
		        
		        handleNullOwners(tNew);
	            Map<Id, Service_Location__c> tOldMap = tOld != null ? new Map<Id, Service_Location__c>(tOld) : new Map<Id, Service_Location__c>();
				
				if(isUpdate && SecurityUtils.stopOwnershipUpdates(tNew, tOldMap)) return;
	            if(CustomerDetailUtils.checkRelatedObjectUpdated(tNew, tOldMap, false)){
	           		synchCustomerDetailFields(tNew, tOldMap);
	            }
    		}
    	}
    	else{
	        Map<Id, Service_Location__c> tOldMap = tOld != null ? new Map<Id, Service_Location__c>(tOld) : new Map<Id, Service_Location__c>();
    		if(!isDelete){
				
				if(!isUpdate)
		        	fixCustomerDetails(tNew, false);
				
				CustomerDetailUtils.handleNewCustomerDetailSet(tNew, tOldMap, false);
			}
			
        	CustomerDetailUtils.setCustomerDetailParents((List<sObject>)tNew, (List<sObject>)tOld, isDelete);
	        
			if(isUpdate) Batch_CalculateAccountOwnership.HandleOwnershipRecalculation(tNew, tOldMap);
			ApexUtils.afterTriggerComplete('Service_Location__c', isDelete);
    	}
    }
    
    private static void handleNullOwners(List<Service_Location__c> tNew){
    	Map<Id, Account> accounts = new Map<Id, Account>();
    	Set<Integer> fix = new Set<Integer>();
    	for(Integer i=0; i<tNew.size(); i++){
     		if(tNew[i].Owner__c == null){
     			accounts.put(tNew[i].Account__c, null);
     			fix.add(i);
     		}
    	}
    	
    	if(accounts.size() > 0){
    		accounts = new Map<Id, Account>([select Id, OwnerId from Account where Id in : accounts.keyset()]);
    		for(Integer f : fix){
				if(CustomerDetailTriggers.SynchronizingFields) tNew[f].addError('Owner is required');
    			else tNew[f].Owner__c = accounts.get(tNew[f].Account__c).OwnerId;
			}
    	}
    }
    
    public static void synchCustomerDetailFields(List<Service_Location__c> tNew, Map<Id, Service_Location__c> tOldMap){
		
		if(CustomerDetailTriggers.SynchronizingFields) return;
		
		Map<Id, Customer_Detail__c> cdUpdates = new Map<Id, Customer_Detail__c>();
		Map<Id, Service_Location__c> parentLocs = new Map<Id, Service_Location__c>();
		Map<Id, Account> accountParents = new Map<Id, Account>();
		Set<Service_Location__c> accountParentUpdated = new Set<Service_Location__c>();
     	for(Service_Location__c sNew : tNew){
     		Service_Location__c sOld = sNew.Id != null ? tOldMap.get(sNew.Id) : null;
			if(sOld == null || ((sOld.Account__c != sNew.Account__c || sOld.Parent_Service_Location__c != null) && sNew.Parent_Service_Location__c == null)) accountParentUpdated.add(sNew);
     		if(sNew.Customer_Detail__c != null
	     		&& (sOld == null
	     			|| sOld.Customer_Detail__c != sNew.Customer_Detail__c
	     			|| sOld.Name != sNew.Name
					|| sOld.Billable__c != sNew.Billable__c
	     			|| sOld.Phone__c != sNew.Phone__c
	     			//|| sOld.Agency__c != sNew.Agency__c
	     			|| sOld.Owner__c != sNew.Owner__c
					|| sOld.Parent_Service_Location__c != sNew.Parent_Service_Location__c
					|| accountParentUpdated.contains(sNew))){
     			cdUpdates.put(sNew.Customer_Detail__c, null);
				accountParents.put(sNew.Account__c, null);
				
				if(sNew.Id != null) parentLocs.put(sNew.Id, sNew);
				if(sNew.Parent_Service_Location__c != null) parentLocs.put(sNew.Parent_Service_Location__c, null);
			}
     	}
		
     	if(cdUpdates.size() > 0){
			cdUpdates = new Map<Id, Customer_Detail__c>([select Id, (select Name, Billable__c, Phone, OwnerId/*, Agency__c*/ from Accounts__r) from Customer_Detail__c where Id in: cdUpdates.keyset()]);
			for(Service_Location__c sLoc : [select Id, Customer_Detail__c, (select Id, Customer_Detail__r.Parent_Customer__c from Service_Locations__r) from Service_Location__c where Id in: parentLocs.keyset()]){
				if(parentLocs.get(sLoc.Id) == null) parentLocs.put(sLoc.Id, sLoc);
			}
			accountParents = new Map<Id, Account>([select Id, Customer_Detail__c from Account where Id in: accountParents.keyset()]);
			
	     	for(Service_Location__c s : tNew){
     			Service_Location__c sOld = s.Id != null ? tOldMap.get(s.Id) : null;
				Customer_Detail__c cd = s.Customer_Detail__c != null ? cdUpdates.get(s.Customer_Detail__c) : null;
				
				if(cd != null){
					Account a = (cd.Accounts__r != null && cd.Accounts__r.size() > 0) ? cd.Accounts__r[0] : null;
					Boolean useAccountFields = (sOld == null || sOld.Customer_Detail__c != s.Customer_Detail__c) && a != null;
					
					s.Name = cd.Name = (useAccountFields ? a.Name : s.Name);
					s.Billable__c = cd.Billable__c = (useAccountFields ? a.Billable__c : s.Billable__c);
					s.Phone__c = cd.Phone__c = ((useAccountFields && a.Phone != null) ? a.Phone : s.Phone__c);
					s.Owner__c = cd.Owner__c = (useAccountFields ? a.OwnerId : s.Owner__c);
					//s.Agency__c = cd.Owner_Agency__c = ((useAccountFields && a.Agency__c != null) ? a.Agency__c : s.Agency__c);
					
					Account sa = accountParents.get(s.Account__c);
					cd.Parent_Account__c = (a != null) ? a.Id : s.Account__c;
					cd.Parent_Customer__c = (s.Parent_Service_Location__c != null) ? parentLocs.get(s.Parent_Service_Location__c).Customer_Detail__c : ((sa.Customer_Detail__c != cd.Id) ? sa.Customer_Detail__c : null);
				}
	     	}
			
			Boolean oSynch = SynchronizingFields;
			SynchronizingFields = true;
			if(cdUpdates.size() > 0) update cdUpdates.values();
			SynchronizingFields = oSynch;
     	}
	}
    
    //If a new service location is inserted we may need to detach the customer detail value from a once single loc account
    private static void fixCustomerDetails(List<Service_Location__c> sLocs, Boolean isBefore){
    	Map<Id, Account> accounts = new Map<Id, Account>();
    	Map<Id, Map<Id, Service_Location__c>> serviceLocsByAccountID = new Map<Id, Map<Id, Service_Location__c>>();
    	for(Service_Location__c sLoc : sLocs){
    		if(sLoc.Account__c != null){
    			accounts.put(sLoc.Account__c, null);
    			
    			Map<Id, Service_Location__c> locs = serviceLocsByAccountID.get(sLoc.Account__c);
    			if(locs == null)
    				locs = new Map<Id, Service_Location__c>();
    			
    			locs.put(sLoc.Id, sLoc);
    			serviceLocsByAccountID.put(sLoc.Account__c, locs);
    		}
    	}
    	
    	accounts = new Map<Id, Account>([select Id
    											,ICC_Account_Number__c
    											,Customer_Detail__c
    											,(select Id, Account__c, ICC_Subscriber_ID__c, Customer_Detail__c from Account_Locations__r)
    											from Account where ICC_Account_Number__c = null and Customer_Detail__c != null and Id in : accounts.keyset()]);
    	
    	List<Service_Location__c> serviceLocsToUpdate = new List<Service_Location__c>();
    	Set<Id> serviceLocIDsToUpdate = new Set<Id>();
    	for(Id accountID : serviceLocsByAccountID.keyset()){
    		Account a = accounts.get(accountID);
    		Map<Id, Service_Location__c> newLocs = serviceLocsByAccountID.get(accountID);
    		
    		if(a == null || newLocs == null) continue;
    		
    		if(isBefore){
    			if(newLocs.size() == 1 && (a.Account_Locations__r == null || a.Account_Locations__r.size() == 0)
    					&& a.Customer_Detail__c != null && newLocs.values()[0].Customer_Detail__c == null)
    				newLocs.values()[0].Customer_Detail__c = a.Customer_Detail__c;
    		}
    		else if(a.Account_Locations__r.size() > 1){
	    		for(Service_Location__c accountLoc : a.Account_Locations__r){
	    			if(newLocs.get(accountLoc.Id) == null && accountLoc.Customer_Detail__c == a.Customer_Detail__c)
	    				serviceLocIDsToUpdate.add(accountLoc.Id);
	    		}
    		}
    	}
    	
    	if(serviceLocIDsToUpdate.size() > 0)
    		CustomerDetailUtils.cloneCustomerDetails(serviceLocIDsToUpdate, null);
    }
}