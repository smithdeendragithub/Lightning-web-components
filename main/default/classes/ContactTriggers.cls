public without sharing class ContactTriggers {
    
    public static Boolean DisableTrigger = false;
    public static Boolean IntegrationDisabled = false;

    public static void ContactsModified(List<Contact> tNew, List<Contact> tOld, boolean isUpdate, boolean isBefore, boolean isDelete) {
    	
    	if(DisableTrigger || !ApexUtils.executeTriggerMethods('Contact', isBefore, isDelete)) return;
    	
    	if(isBefore){
	        Map<Id, Contact> tOldMap = tOld != null ? new Map<Id, Contact>(tOld) : new Map<Id, Contact>();
		    if(isDelete)
		        deleteCustomerContacts(tOld);
		    else{
				handleMarkForDelete(tNew);
				setFieldsFromExternalUser(tNew, tOldMap);
		    	checkDefaultResponsibleParties(tNew);
			}
		}
		else{
	        Map<Id, Contact> tOldMap = tOld != null ? new Map<Id, Contact>(tOld) : new Map<Id, Contact>();
		    updateContacts(tNew, tOldMap);
		    
			ApexUtils.afterTriggerComplete('Contact', isDelete);
		}
    }
    
    private static void deleteCustomerContacts(List<Contact> tOld){
		List<Customer_Contact__c> ccs = [select Id, ICC_Contact_ID__c from Customer_Contact__c where Contact__c in : tOld];
		delete ccs;
    }
	
	private static void setFieldsFromExternalUser(List<Contact> tNew, Map<Id, Contact> tOldMap){
		if(ExternalUserTriggers.SynchingFields) return;
		
		List<Contact> updated = new List<Contact>();
		Map<Id, External_User__c> eUsers = new Map<Id, External_User__c>();
		for(Contact cNew : tNew){
			Contact cOld = cNew.Id != null ? tOldMap.get(cNew.Id) : null;
			if(cNew.External_User__c != null && (cOld == null
				|| cOld.External_User__c != cNew.External_User__c
				|| cOld.Phone != cNew.Phone
				|| cOld.Email != cNew.Email
				|| cOld.FirstName != cNew.FirstName
				|| cOld.LastName != cNew.LastName)){
				eUsers.put(cNew.External_User__c, null);
				updated.add(cNew);
			}
		}
		
		if(eUsers.size() > 0){
			eUsers = new Map<Id, External_User__c>([select Id, First_Name__c, Last_Name__c, Phone__c, Email__c from External_User__c where Id in: eUsers.keyset()]);
			for(Contact u : updated){
				External_User__c eu = eUsers.get(u.External_User__c);
				u.FirstName = eu.First_Name__c;
				u.LastName = eu.Last_Name__c;
				u.Phone = eu.Phone__c;
				u.Email = eu.Email__c;
			}
		}
	}
    
    private static void checkDefaultResponsibleParties(List<Contact> tNew){
    	Set<Id> accountIDs = new Set<Id>();
    	Set<Id> existingIDs = new Set<Id>();
    	Set<Id> multiResponsiblePartyAccountIDs = new Set<Id>();
    	for(Contact c : tNew){
    		if(c.Default_Responsible_Party__c && c.AccountId != null){
    			if(accountIDs.contains(c.AccountId))
    				multiResponsiblePartyAccountIDs.add(c.AccountId);
    			accountIDs.add(c.AccountId);
	    		if(c.Id != null)
	    			existingIDs.add(c.Id);
    		}
    	}
    	
    	if(multiResponsiblePartyAccountIDs.size() > 0){
    		for(Contact c : tNew){
	    		if(c.Default_Responsible_Party__c && c.AccountId != null && multiResponsiblePartyAccountIDs.contains(c.AccountId))
	    			c.addError('Only one default resonsible party contact can be associated with an account.');
	    	}
    	}
    	else if(accountIDs.size() > 0){
    		List<Contact> removeDefaultResponsibleParty = new List<Contact>();
	    	for(Contact c : [select Id, AccountId from Contact where AccountId in: accountIDs and Id not in: existingIDs and Default_Responsible_Party__c = true]){
				c.Default_Responsible_Party__c = false;
				removeDefaultResponsibleParty.add(c);
	    	}
	    	update removeDefaultResponsibleParty;
    	}
    }
	
	private static void handleMarkForDelete(List<Contact> tNew){
		Set<Id> marked = new Set<Id>();
		
		for(Contact cNew : tNew){
			if(cNew.Former_Contact__c && cNew.AccountId != null) marked.add(cNew.Id);
		}
		
		if(marked.size() > 0){
			Set<Id> errorIDs = new Set<Id>();
			for(Customer_Contact__c cc : [select Contact__c from Customer_Contact__c where Contact__c in: marked]) errorIDs.add(cc.Contact__c);
			
			for(Contact cNew : tNew){
				if(errorIDs.contains(cNew.Id)) cNew.addError('This Contact cannot be marked as a Former Contact until all customer \'contact role\' assignments have been removed.');
				else if(marked.contains(cNew.Id)){
					cNew.Former_Account__c = cNew.AccountId;
					cNew.AccountId = null;
				}
			}
		}
	}
    
    public static void updateContacts(List<Contact> tNew){
    	updateContacts(tNew, new Map<Id, Contact>());
    }
    
    public static void updateContacts(List<Contact> tNew, Map<Id, Contact> tOldMap){
    	if(IntegrationDisabled) return;
    	
    	Set<Id> ids = new Set<Id>();
		for(Contact c : tNew){
			Contact tOld = tOldMap.get(c.Id);
			
			//Only trigger on the fields we care about
			if(tOld == null
				|| tOld.FirstName != c.FirstName
				|| tOld.LastName != c.LastName
				|| tOld.Phone != c.Phone
				|| tOld.Email != c.Email
				|| tOld.MobilePhone != c.MobilePhone
				|| tOld.Fax != c.Fax
				|| tOld.MailingCity != c.MailingCity
				|| tOld.MailingState != c.MailingState
				|| tOld.MailingPostalCode != c.MailingPostalCode
				|| tOld.MailingStreet != c.MailingStreet
				|| tOld.MailingCountry != c.MailingCountry
				|| tOld.Title != c.Title
				|| tOld.Authorized_User_Password__c != c.Authorized_User_Password__c
				|| tOld.Extension__c != c.Extension__c)
				ids.add(c.Id);
		}
		
		if(ids.size() > 0){
	    	List<Customer_Contact__c> ccs = [select Id
													,Contact__c
													,Contact_Type__c
													,Customer_Detail__c
											from Customer_Contact__c where Contact__c in : ids];
	    	
	        if(ccs.size() > 0)
	            CustomerContactTriggers.updateContacts(ccs);
		}
    }
}