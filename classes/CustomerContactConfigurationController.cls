public with sharing class CustomerContactConfigurationController implements TestUtils.ITestableClass {
	
	public Contact c {get; private set;}
	public Map<Id, Map<String, List<Customer_Contact__c>>> customerContactsByDetailID {get; private set;}
	public Map<Id, Customer_Detail__c> details {get; private set;}
	public Map<Id, String> detailDesriptions {get; private set;}
    public Customer_Contact__c newCustomerContact {get; set;}
    
	public List<SelectOption> availableCustomers {get; private set;}
	public List<SelectOption> emails {get; private set;}
	public List<SelectOption> phoneNumbers {get; private set;}
    public List<String> selectedCustomers {get; set;}
    public List<SelectOption> availableContactTypes {get; private set;}
    public List<String> selectedContactTypes {get; set;}
    
    public string selectedRoleIds {get;set;}
	
	public CustomerContactConfigurationController(Apexpages.StandardController sc){
		c = (Contact)sc.getRecord();
		system.debug('c: ' + c);
		refreshData();
	}
	
	private void refreshData(){
		List<Contact> contacts = ((List<Contact>)ApexUtils.retrieveFullObjects(Contact.getsObjectType(), 'Id=\'' + c.Id + '\''));
		c = contacts.size() > 0 ? contacts[0] : c;
		
		customerContactsByDetailID = new Map<Id, Map<String, List<Customer_Contact__c>>>();
		details = new Map<Id, Customer_Detail__c>();
		detailDesriptions = new Map<Id, String>();
		newCustomerContact = new Customer_Contact__c();
		availableCustomers = new List<SelectOption>();
		
		Set<Id> accountIDs = new Set<Id>();
		if(c.AccountId != null){
			accountIDs.add(c.AccountId);
			for(Account_Partner__c p : [select Id, Account__c from Account_Partner__c where Partner__c =: c.AccountId]) accountIDs.add(p.Account__c);
		}
		
		emails = getPicklistValues(c.Additional_Email_Addresses__c, !string.isEmpty(c.Email) ? new Set<String>{ c.Email } : null);
		
		Set<String> pNums = new Set<String>();
		for(String s : new List<String>{ c.Phone, c.AssistantPhone, c.HomePhone, c.MobilePhone, c.OtherPhone }){
			if(!String.isEmpty(s)) pNums.add(s);
		}
		phoneNumbers = getPicklistValues(c.Additional_Phone_Numbers__c, pNums);
		
		if(c != null){
			details = new Map<Id, Customer_Detail__c>([select Id from Customer_Detail__c where Parent_Account__c in: accountIDs]);
			
			for(Customer_Contact__c cc : [select Id, Email__c, Phone__c, Contact__r.Id, Contact__r.Name, Contact_Type__c, Customer_Detail__c, ICC_Contact_ID__c from Customer_Contact__c
												where Contact__c =: c.Id and Customer_Detail__c != null
												order by Contact_Type__c, ICC_Contact_ID__c]){
				//Always instantiate
				if(customerContactsByDetailID.get(cc.Customer_Detail__c) == null) customerContactsByDetailID.put(cc.Customer_Detail__c, new Map<String, List<Customer_Contact__c>>());
				
				if(cc.Contact_Type__c != ICCWrapper.ResonsiblePartyContactType){
					Map<String, List<Customer_Contact__c>> m = customerContactsByDetailID.get(cc.Customer_Detail__c) != null ? customerContactsByDetailID.get(cc.Customer_Detail__c) : new Map<String, List<Customer_Contact__c>>();
					String modifier = CustomerDetailExtensionController.getCustomerContactModifier(cc);
					List<Customer_Contact__c> l = m.get(modifier) != null ? m.get(modifier) : new List<Customer_Contact__c>();
					l.add(cc);
					m.put(modifier, l);
					customerContactsByDetailID.put(cc.Customer_Detail__c, m);
					details.put(cc.Customer_Detail__c, null);
				}
			}
			
			details = new Map<Id, Customer_Detail__c>([select Id
															,Name
															,ICC_Subscriber_ID__c
															,(select Id, Name from Accounts__r)
															,(select Id, Name from Service_Locations__r)
															,(select Contact__r.Id, Contact__r.Name from Customer_Contacts__r where Contact_Type__c =: ICCWrapper.ResonsiblePartyContactType limit 1)
														from Customer_Detail__c where Id in : details.keyset() order by ICC_Subscriber_ID__c, Name]);
			
			for(Customer_Detail__c cd : details.values()){
				String n = ((cd.Accounts__r != null && cd.Accounts__r.size() > 0)
					? cd.Accounts__r[0].Name
					: ((cd.Service_Locations__r != null && cd.Service_Locations__r.size() > 0) ? cd.Service_Locations__r[0].Name : cd.Name))
					+ (!string.IsEmpty(cd.ICC_Subscriber_ID__c) ? (' [' + cd.ICC_Subscriber_ID__c + ']') : '');
				detailDesriptions.put(cd.Id, n);
				availableCustomers.add(new SelectOption(cd.Id, n));
			}
		}
		
		availableContactTypes = new List<SelectOption>();
		for(Schema.PicklistEntry ple : Customer_Contact__c.Contact_Type__c.getDescribe().getPicklistValues()){
			if(ple.getLabel() != ICCWrapper.ResonsiblePartyContactType)
				availableContactTypes.add(new SelectOption(ple.getLabel(), ple.getValue()));
		}
	}
	
	private List<SelectOption> getPicklistValues(String fieldValue, Set<String> additionalVals){
		List<SelectOption> retval = new List<SelectOption>{new SelectOption('', '[Default]')};
		for(String s : additionalVals != null ? additionalVals : new Set<String>())
			retval.add(new SelectOption(s, s));
		try{
			List<String> additionalValues = !String.isEmpty(fieldValue) ? fieldValue.split('\n') : new List<String>();
			additionalValues.sort();
			for(String s : additionalValues){
				List<String> parts = s.contains('\t') ? s.split('\t') : new List<String>();
				if(parts.size() > 0) retval.add(new SelectOption(parts[1], parts[0] + ': ' + parts[1]));
			}
		} catch(Exception e) { system.debug('Exception: ' + e); }
		
		return retval;
	}
	
	public PageReference createNewCustomerContacts(){
		if(selectedCustomers != null && selectedCustomers.size() > 0 && selectedContactTypes != null && selectedContactTypes.size() > 0){
			List<Customer_Contact__c> newCustomerContacts = new List<Customer_Contact__c>();
			
			for(String customerID : selectedCustomers){
				Map<String, Set<String>> existingTypes = new Map<String, Set<String>>();
				Map<String, List<Customer_Contact__c>> ccs = customerContactsByDetailID.get(customerID);
				if(ccs != null){
					for(String mod : ccs.keyset()){
						Set<String> modSet = new Set<String>();
						for(Customer_Contact__c cc : ccs.get(mod))
							modSet.add(cc.Contact_Type__c);
						existingTypes.put(mod, modSet);
					}
				}
				
				for(String t : selectedContactTypes){
					Customer_Contact__c cc = new Customer_Contact__c(Customer_Detail__c = customerID
																	,Contact__c = c.Id
																	,Email__c = newCustomerContact.Email__c
																	,Phone__c = newCustomerContact.Phone__c
																	,Contact_Type__c = t);
					String mod = CustomerDetailExtensionController.getCustomerContactModifier(cc);
					if(existingTypes.get(mod) == null || !existingTypes.get(mod).contains(t))
						newCustomerContacts.add(cc);
				}
			}
			
			insert newCustomerContacts;
		}
		
		return refresh();
	}
	
	public PageReference updateResponsibleParties(){
		if(selectedCustomers != null && selectedCustomers.size() > 0){
			List<Customer_Contact__c> respParties = new List<Customer_Contact__c>();
			List<Customer_Contact__c> oldRespParties = new List<Customer_Contact__c>();
			for(Customer_Detail__c cd : [select Id, (select Id from Customer_Contacts__r where Contact_Type__c =: ICCWrapper.ResonsiblePartyContactType limit 1) from Customer_Detail__c where Id in: selectedCustomers]){
				Customer_Contact__c r = null; 
				if(cd.Customer_Contacts__r != null && cd.Customer_Contacts__r.size() > 0)
					r = cd.Customer_Contacts__r[0];
				else
					r = new Customer_Contact__c(Customer_Detail__c = cd.Id, Contact_Type__c = ICCWrapper.ResonsiblePartyContactType);
				r.Contact__c = c.Id;
				r.Email__c = newCustomerContact.Email__c;
				r.Phone__c = newCustomerContact.Phone__c;
				respParties.add(r);
			}
			
			upsert respParties;
		}
		
		return refresh();
	}
	
	public PageReference updateRoles(){
		List<Customer_Contact__c> tContacts = selectedRoleIds != null ? [select Id from Customer_Contact__c  where Id in :selectedRoleIds.split(',')] : new List<Customer_Contact__c>();
		for(Customer_Contact__c cc : tContacts){
			cc.Email__c = newCustomerContact.Email__c;
			cc.Phone__c = newCustomerContact.Phone__c;
		}
		
		if(tContacts.size() > 0) update tContacts;
		
		return refresh();
	}
	
	public PageReference removeRoles(){
		List<Customer_Contact__c> tContacts = selectedRoleIds != null ? [select Id
																		,Customer_Detail__c
																		,Contact__c
																		,Email__c
																		,Phone__c
																  from Customer_Contact__c
																  where Id in :selectedRoleIds.split(',')]
																 : new List<Customer_Contact__c>();
		for(Customer_Contact__c cc : tContacts){
			customerContactsByDetailId.remove(cc.Customer_Detail__c);	
		}
		
		if(tContacts.size() > 0) delete tContacts;
		
		return refresh();
	}
	
	private PageReference refresh(){
		refreshData();
		return null;
		/*PageReference nextPage = ApexPages.currentPage();
        nextPage.setRedirect(true);
		return nextPage;*/
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_CustomerContactConfiguration(); }
}