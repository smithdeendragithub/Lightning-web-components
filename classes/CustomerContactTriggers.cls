public without sharing class CustomerContactTriggers {

    public static Boolean IntegrationDisabled = false;

    public static void CustomerContactsModified(List<Customer_Contact__c> tNew, List<Customer_Contact__c> tOld, boolean isUpdate, boolean isBefore, boolean isDelete) {
    	
    	if(!ApexUtils.executeTriggerMethods('Customer_Contact__c', isBefore, isDelete)) return;
    	
    	if(isBefore){
		    if(isDelete) customerContactsDeleted(tOld);
			else updateContactListFields(tNew);
		}
		else{
		    updateContacts(tNew);
		    
			ApexUtils.afterTriggerComplete('Customer_Contact__c', isDelete);
		}
    }
	
	private static void updateContactListFields(List<Customer_Contact__c> tNew){
		Map<Id, Set<String>> additionalEmails = new Map<Id, Set<String>>();
		Map<Id, Set<String>> additionalPhoneNumbers = new Map<Id, Set<String>>();
		
		for(Customer_Contact__c cc : tNew){
			//Leave additional phone numbers on the Auto-Dialer instances
			if(cc.Contact_Type__c != 'AutoDialer'){
				if(!string.isEmpty(cc.Email__c)){
					Set<String> s = additionalEmails.get(cc.Contact__c) != null ? additionalEmails.get(cc.Contact__c) : new Set<String>();
					s.add(cc.Email__c);
					additionalEmails.put(cc.Contact__c, s);
				}
				if(!string.isEmpty(cc.Phone__c)){
					Set<String> s = additionalPhoneNumbers.get(cc.Contact__c) != null ? additionalPhoneNumbers.get(cc.Contact__c) : new Set<String>();
					s.add(cc.Phone__c);
					additionalPhoneNumbers.put(cc.Contact__c, s);
				}
			}
		}
		
		List<Contact> cList = new List<Contact>();
		for(Contact c : [select Id, Email, Phone, AssistantPhone, HomePhone, MobilePhone, OtherPhone, Additional_Email_Addresses__c, Additional_Phone_Numbers__c from Contact where Id in: additionalEmails.keyset() or Id in: additionalPhoneNumbers.keyset()]){
			Set<String> newEmails = getUpdatedFieldVals(c.Additional_Email_Addresses__c, !string.isEmpty(c.Email) ? new Set<String>{ c.Email } : null, additionalEmails.get(c.Id));
			
			Set<String> pNums = new Set<String>();
			for(String s : new List<String>{ c.Phone, c.AssistantPhone, c.HomePhone, c.MobilePhone, c.OtherPhone }){
				if(!String.isEmpty(s)) pNums.add(s);
			}
			Set<String> newPNums = getUpdatedFieldVals(c.Additional_Phone_Numbers__c, pNums, additionalPhoneNumbers.get(c.Id));
			
			if(newEmails.size() > 0 || newPNums.size() > 0){
				for(String s : newEmails) c.Additional_Email_Addresses__c = (string.isEmpty(c.Additional_Email_Addresses__c) ? '' : (c.Additional_Email_Addresses__c + '\n')) + 'Additional Email\t' + s;
				for(String s : newPNums) c.Additional_Phone_Numbers__c = (string.isEmpty(c.Additional_Phone_Numbers__c) ? '' : (c.Additional_Phone_Numbers__c + '\n')) + 'Additional Number\t' + s;
				cList.add(c);
			}
		}
		
		if(cList.size() > 0) update cList;
	}
	
	private static Set<String> getUpdatedFieldVals(String f, Set<String> additionalVals, Set<String> newVals){
		Set<String> retval = new Set<String>();
		try{
			Set<String> currentVals = new Set<String>();
			if(additionalVals != null) currentVals.addAll(additionalVals);
			for(String s : !String.isEmpty(f) ? f.split('\n') : new List<String>()){
				if(s.contains('\t')) currentVals.add(s.split('\t')[1]);
			}
			
			for(String s : newVals != null ? newVals : new Set<String>()){
				if(!currentVals.contains(s)) retval.add(s);
			}
		}
		catch(Exception e){ System.debug('getUpdatedField exception: ' + e); }
		
		return retval;
	}
    
    public static void customerContactsDeleted(List<Customer_Contact__c> tOld){
    	if(IntegrationDisabled) return;
    	
        Map<Integer, Id> contactIDs = new Map<Integer, Id>();
        for(Customer_Contact__c cc : tOld){
            if(!string.IsEmpty(cc.ICC_Contact_ID__c) && cc.ICC_Contact_ID__c != '0'){
                contactIDs.put(integer.valueof(cc.ICC_Contact_ID__c), cc.Id);
            }
        }
        
        if(contactIDs.size() > 0 && integraWSEndpointMediator.canRunIntegrationUpdate('Contact'))
            deleteCustomerContacts(contactIDs, UserInfo.getSessionId(), UserInfo.getUserEmail());
    }
    
    @future(callout=true)
    public static void deleteCustomerContacts(Map<Integer, Id> contactIds, string sessionID, string errorEmail){
        try{
	        ICCWrapper.deleteSubscriberContacts(new List<Integer>(contactIds.keyset()), sessionID);
        }
	    catch(Exception e){
	    	String detailString = IntegrationUtils.emailIntegrationException(e, errorEmail, 'Contact integration update exception');
			
	    	List<Integration_Error__c> errors = new List<Integration_Error__c>();
	    	for(Integer iccID : contactIds.keyset())
	    		errors.add(new Integration_Error__c(ObjectID__c = string.valueof(contactIds.get(iccID)), Action__c = 'Delete', Info__c = string.valueof(iccID), Message__c = detailString));
	    	
	    	insert errors;
	    }
    }
    
    public static void updateContacts(List<Customer_Contact__c> tNew){
    	updateContacts(tNew, new Map<Id, Customer_Contact__c>());
    }
    
    public static void updateContacts(List<Customer_Contact__c> tNew, Map<Id, Customer_Contact__c> tOldMap){
    	if(IntegrationDisabled) return;
    	
    	List<Customer_Contact__c> filtered = new List<Customer_Contact__c>();
		for(Customer_Contact__c cc : tNew){
			Customer_Contact__c tOld = tOldMap.get(cc.Id);
			
			//Only trigger on the fields we care about
			if(cc.Contact__c != null && cc.Contact_Type__c != null &&
				(tOld == null
				|| tOld.Phone__c != cc.Phone__c
				|| tOld.Email__c != cc.Email__c
				|| tOld.Contact_Type__c != cc.Contact_Type__c
				|| tOld.Contact__c != cc.Contact__c
				|| tOld.Customer_Detail__c != cc.Customer_Detail__c))
				filtered.add(cc);
		}
    	
    	if(filtered.size() > 0){
	        Map<Id, String> ccs = getSubscriberIDsByCustomerContactID(filtered);
	        
	        if(ccs.size() > 0 && integraWSEndpointMediator.canRunIntegrationUpdate('Contact'))
	            updateContacts(ccs.keyset(), UserInfo.getSessionId(), UserInfo.getUserEmail());
    	}
    }

    @future(callout=true)
    public static void updateContacts(Set<Id> customerContactIDs, string sessionID, string errorEmail){
        try{
	    	Map<Id, Customer_Contact__c> ccs = new Map<Id, Customer_Contact__c>([select Id, ICC_Contact_ID__c, Email__c, Phone__c, Contact_Type__c, Contact__c, Customer_Detail__c from Customer_Contact__c where Id in : customerContactIDs and Contact_Type__c != null and Contact__c != null]);
	        Map<Id, String> subscriberIDByCustomerContactID = getSubscriberIDsByCustomerContactID(ccs.values());
	    	
	    	if(subscriberIDByCustomerContactID.size() > 0)
	    		integrateContacts(ccs, subscriberIDByCustomerContactID, sessionID, true);
        }
	    catch(Exception e){
	    	String detailString = IntegrationUtils.emailIntegrationException(e, errorEmail, 'Contact integration update exception');
	    	IntegrationUtils.createUpdateIntegrationErrors(customerContactIDs, detailString, null);
	    }
    }

	@future(callout=true)
    public static void integrateContacts(List<String> contactIds, String subscriberId, String sessionID) {

		Map<Id, Customer_Contact__c> customerContactsToIntegrate = new Map<Id, Customer_Contact__c>();
        Map<Id, String> subscriberIDByCustomerContactID = new  Map<Id, String>();
                    
        List<Customer_Contact__c> contacts = [SELECT Id, ICC_Contact_ID__c, Email__c, Phone__c, Contact_Type__c, Contact__c, Customer_Detail__c 
        	                                 FROM Customer_Contact__c where Contact_Type__c != null and Contact__c != null and id in : contactIds];            
   	                
        for (Customer_Contact__c cc: contacts) {
        	customerContactsToIntegrate.put(cc.Id, cc);
            subscriberIDByCustomerContactID.put(cc.Id, subscriberId);        	
        }        
        
        integrateContacts(customerContactsToIntegrate, subscriberIDByCustomerContactID, sessionID, true);
    } 
    
    public static List<Customer_Contact__c> integrateContacts(Map<Id, Customer_Contact__c> ccs, Map<Id, String> subscriberIDByCustomerContactID, string sessionID){
    	return integrateContacts(ccs, subscriberIDByCustomerContactID, sessionID, false);
    }
    
    private static List<Customer_Contact__c> integrateContacts(Map<Id, Customer_Contact__c> ccs, Map<Id, String> subscriberIDByCustomerContactID, string sessionID, Boolean saveOnComplete){

    	Map<Id, Contact> contacts = new Map<Id, Contact>();
	    for(Customer_Contact__c cc : ccs.values()){
	    	ccs.put(cc.Id, cc);
	    	contacts.put(cc.Contact__c, null);
	    }
	    
	    contacts = new Map<Id, Contact>((List<Contact>)ApexUtils.retrieveFullObjects(Contact.sObjectType, 'Id in (\'' + string.join(new List<Id>(contacts.keyset()), '\',\'') + '\')', null));
 
    	Map<Id, integraWS.SFSubscriberContactView> contactViews = new Map<Id, integraWS.SFSubscriberContactView>();
    	for(Id ccID : subscriberIDByCustomerContactID.keyset()){
    		Customer_Contact__c cc = ccs.get(ccID);
    		Contact c = contacts.get(cc.Contact__c);
     		integraWS.SFSubscriberContactView v = contactViews.get(cc.Contact__c);

    		if(v == null){
    			v = ICCWrapper.setSubscriberContactValues(c);
		    	v.FieldsToNull = new schemasMicrosoftCom200310Serializat.ArrayOfstring();
				v.FieldsToNull.string_x = new List<String>();
				//if(string.isEmpty(v.FirstName)) v.FieldsToNull.string_x.add('FirstName');
				//if(string.isEmpty(v.LastName)) v.FieldsToNull.string_x.add('LastName');
				if(string.isEmpty(v.Title)) v.FieldsToNull.string_x.add('Title');
				if(string.isEmpty(v.Fax)) v.FieldsToNull.string_x.add('Fax');
				if(string.isEmpty(v.AuthorizedUserPassword)) v.FieldsToNull.string_x.add('AuthorizedUserPassword');
				if(string.isEmpty(v.Extension)) v.FieldsToNull.string_x.add('Extension');
				if(string.isEmpty(v.Cell)) v.FieldsToNull.string_x.add('Cell');
				if(string.isEmpty(v.City)) v.FieldsToNull.string_x.add('City');
				if(string.isEmpty(v.State)) v.FieldsToNull.string_x.add('State');
				if(string.isEmpty(v.Street)) v.FieldsToNull.string_x.add('Street');
				if(string.isEmpty(v.Zip)) v.FieldsToNull.string_x.add('Zip');
    			contactViews.put(cc.Contact__c, v);
    		}
             
    		integraWS.SFSubscriberContactAliasView alias = new integraWS.SFSubscriberContactAliasView();
    		alias.SalesforceId = cc.Id;
    		alias.ContactId = !string.IsEmpty(cc.ICC_Contact_ID__c) ? integer.valueOf(cc.ICC_Contact_ID__c) : 0;
    		alias.SubscriberId = integer.valueOf(subscriberIDByCustomerContactID.get(ccID));
    		alias.ContactTypeDescription = cc.Contact_Type__c;
    		alias.Phone = cc.Phone__c != null ? cc.Phone__c : c.Phone;
    		alias.Phone = alias.Phone != null ? alias.Phone.replace('(','').replace(')','').replace('-','').replace(' ','') : alias.Phone;
    		alias.Email = cc.Email__c != null ? cc.Email__c : c.Email;
    		
    		v.Aliases.SFSubscriberContactAliasView.add(alias);
    	}

    	List<Customer_Contact__c> updatedCCs = new List<Customer_Contact__c>();
    	for(integraWS.SFSubscriberContactView view : ICCWrapper.updateSubscriberContacts(contactViews.values(), sessionID)) {
    		if(view.Aliases == null || view.Aliases.SFSubscriberContactAliasView == null) continue;
    		for(integraWS.SFSubscriberContactAliasView alias : view.Aliases.SFSubscriberContactAliasView){
    			if(alias.SalesForceId != null){
	    			Customer_Contact__c cc = ccs.get(alias.SalesforceId);
		            if(cc != null && alias.ContactId != null && alias.ContactId != 0 && cc.ICC_Contact_ID__c != String.valueOf(alias.ContactId)) {
		                cc.ICC_Contact_ID__c = String.valueOf(alias.ContactId);
		                updatedCCs.Add(cc);
		            }
    			}
    		}
    	}
    
        if(saveOnComplete && updatedCCs.size() > 0) {
            IntegrationDisabled = true;	//Just in case
            update updatedCCs;
        }
        
        return updatedCCs;
    }
    
    private static Map<Id, String> getSubscriberIDsByCustomerContactID(List<Customer_Contact__c> ccs){
    	Map<Id, String> retval = new Map<Id, String>();
    	
    	Map<Id, Customer_Detail__c> details = new Map<Id, Customer_Detail__c>();
    	for(Customer_Contact__c cc : ccs)
    		details.put(cc.Customer_Detail__c, null);
    	
    	details = new Map<Id, Customer_Detail__c>([select Id, ICC_Subscriber_ID__c from Customer_Detail__c where Id in : details.keyset()]);
    	
    	for(Customer_Contact__c cc : ccs){
    		String subID = details.get(cc.Customer_Detail__c) != null ? details.get(cc.Customer_Detail__c).ICC_Subscriber_ID__c : null;
    		if(!string.IsEmpty(subID))
    			retval.put(cc.Id, subID);
    	}
    	
    	return retval;
    }
}