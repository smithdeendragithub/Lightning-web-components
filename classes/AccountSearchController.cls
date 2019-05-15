public with sharing class AccountSearchController implements TestUtils.ITestableClass {
	
	public String allFieldSearch {get; set;}
	public Boolean onlySearchAccounts {get; set;}
	public Boolean onlySearchProspects {get; set;}
	public Boolean pastDueSearch {get;set;}
	
	public AdvancedSearch.SearchCriterion nameSearch {get; set;}
	public AdvancedSearch.SearchCriterion phoneSearch {get; set;}
	public AdvancedSearch.SearchCriterion citySearch {get; set;}
	public AdvancedSearch.SearchCriterion stateSearch {get; set;}
	public AdvancedSearch.SearchCriterion streetSearch {get; set;}
	public AdvancedSearch.SearchCriterion zipSearch {get; set;}
	public AdvancedSearch.SearchCriterion billplexSubIDSearch {get;set;}
	public AdvancedSearch.SearchCriterion mssAccountIDSearch {get;set;}
	public AdvancedSearch.SearchCriterion legacyIDSearch {get;set;}
	
	public AdvancedSearch.SearchCriterion subscriberIDSearch {get;set;}
	
	public AdvancedSearch.SearchCriterion contactFirstNameSearch {get; set;}
	public AdvancedSearch.SearchCriterion contactLastNameSearch {get; set;}
	public AdvancedSearch.SearchCriterion contactPhoneSearch {get; set;}
	
	public Map<String, AdvancedSearch.SearchResultSet> resultSets {get; set;}
	
	public Map<Id, RecordType> recordTypes {get; set;}

	public AccountSearchController(){
		onlySearchAccounts = false;
		onlySearchProspects = false;
		
		nameSearch = new AdvancedSearch.SearchCriterion('name');
		phoneSearch = new AdvancedSearch.SearchCriterion();
		citySearch = new AdvancedSearch.SearchCriterion();
		stateSearch = new AdvancedSearch.SearchCriterion();
		streetSearch = new AdvancedSearch.SearchCriterion();
		zipSearch = new AdvancedSearch.SearchCriterion();
		billplexSubIDSearch = new AdvancedSearch.SearchCriterion();
		mssAccountIDSearch = new AdvancedSearch.SearchCriterion();
		legacyIDSearch = new AdvancedSearch.SearchCriterion();
		pastDueSearch = false;
		subscriberIDSearch = new AdvancedSearch.SearchCriterion();
		
		contactFirstNameSearch = new AdvancedSearch.SearchCriterion('FirstName');
		contactLastNameSearch = new AdvancedSearch.SearchCriterion('LastName');
		contactPhoneSearch = new AdvancedSearch.SearchCriterion('Phone');
		
		recordTypes = new Map<Id, RecordType>([select Id, Name from RecordType where SobjectType in ('Account')]);
	}
	
	public PageReference directSearch(){
		return search(false);
	}
	
	public PageReference searchByContact(){
		return search(true);
	}
	
	private List<String> errors;
	private List<String> warnings;
	
    public Map<String, Map<String, String>> headers { get; private set; }
    public Map<String, List<String>> sortedFields { get; private set; }
    private final List<String> accountFieldList = new List<String>{'RecordType.Name', 'ShippingCity', 'ShippingState', 'ShippingStreet', 'ShippingPostalCode'};
    private final List<String> serviceLocFieldList = new List<String>{'Account__r.Name', 'Phone__c', 'Location__r.Building__r.City__c', 'Location__r.Building__r.State__c', 'Location__r.Building__r.Address__c', 'Location__r.Building__r.Postal_Code__c'};
    private final List<String> customerDetailFieldList = new List<String>{'ICC_Subscriber_ID__c', 'Phone__c', 'Service_Address__r.Building__r.City__c', 'Service_Address__r.Building__r.State__c', 'Service_Address__r.Building__r.Address__c', 'Service_Address__r.Building__r.Postal_Code__c'};
    private final List<String> relatedCustomerDetailFieldList = new List<String>{'customer_detail__r.ICC_Subscriber_ID__c', 'customer_detail__r.Legacy_ID__c', 'customer_detail__r.MSS_Account_ID__c', 'customer_detail__r.Past_Due__c', 'customer_detail__r.Billing_ID__c'};
    private final Map<String, String> knownRelatedFields = new Map<String, String>{
    	'Account__r.Name' => 'Account Name'
    	,'RecordType.Name' => 'Record Type'
    	,'ShippingCity' => 'City'
    	,'ShippingState' => 'State'
    	,'ShippingStreet' => 'Street'
    	,'ShippingPostalCode' => 'Zip/Postal Code'
    	,'Location__r.Building__r.City__c' => 'City'
    	,'Location__r.Building__r.State__c' => 'State'
    	,'Location__r.Building__r.Address__c' => 'Street'
    	,'Location__r.Building__r.Postal_Code__c' => 'Zip/Postal Code'
    	,'Service_Address__r.Building__r.City__c' => 'City'
    	,'Service_Address__r.Building__r.State__c' => 'State'
    	,'Service_Address__r.Building__r.Address__c' => 'Street'
    	,'Service_Address__r.Building__r.Postal_Code__c' => 'Zip/Postal Code'
    };
    
	public PageReference search(Boolean searchByContact){
		List<AdvancedSearch.SearchCriterion> criteria = new List<AdvancedSearch.SearchCriterion>();
		
		errors = new List<String>();
		warnings = new List<String>();
		List<String> customWhere = new List<String>();
		
		String fieldSearch = allFieldSearch.replace('\'', '\\\'');
		resultSets = new Map<String, AdvancedSearch.SearchResultSet>();
		headers = new Map<String, Map<String, String>>();
		sortedFields = new Map<String, List<String>>();
		
		AdvancedSearch.SearchResults sResults = null;
		AdvancedSearch.treatNullsAsEmptyString = true;
		if(searchByContact){
			if(!string.IsEmpty(contactFirstNameSearch.value))
				criteria.add(updateCriterion(contactFirstNameSearch));
			if(!string.IsEmpty(contactLastNameSearch.value))
				criteria.add(updateCriterion(contactLastNameSearch));
			if(!string.IsEmpty(contactPhoneSearch.value))
				criteria.add(updateCriterion(contactPhoneSearch));
			
			sResults = AdvancedSearch.search(fieldSearch, criteria, new List<String>{'Contact'}, new Set<String>{'AccountId'}, (onlySearchProspects ? 'ICC_Account_Number__c = null' : null));
			handleSearchResults(sResults, null);
			AdvancedSearch.customIDSet = new Set<Id>();
			
			Set<Id> contactIDs = new Set<Id>();
			for(AdvancedSearch.SearchResultSet resultSet : sResults.resultSets){
				for(AdvancedSearch.SearchResult result : resultSet.results){
					AdvancedSearch.customIDSet.add((Id)result.fieldMap.get('accountid'));
					contactIDs.add(result.Id);
				}
			}
			fieldSearch = null;
			criteria.clear();
			
			if(!onlySearchAccounts){
				//Get the customer details that have these contacts
				for(Customer_Contact__c cc : [select Customer_Detail__c from Customer_Contact__c where Contact__c in: contactIDs])
					AdvancedSearch.customIDSet.add(cc.Customer_Detail__c);
			}
		}
		else{
			if(!string.IsEmpty(nameSearch.value))
				criteria.add(updateCriterion(nameSearch));
			if(!string.IsEmpty(phoneSearch.value)){
				phoneSearch.fieldName = 'phone';
				criteria.add(updateCriterion(phoneSearch));
			}
			if(!string.IsEmpty(citySearch.value)){
				citySearch.fieldName = 'shippingcity';
				criteria.add(updateCriterion(citySearch));
			}
			if(!string.IsEmpty(stateSearch.value)){
				stateSearch.fieldName = 'shippingstate';
				criteria.add(updateCriterion(stateSearch));
			}
			if(!string.IsEmpty(streetSearch.value)){
				streetSearch.fieldName = 'shippingstreet';
				criteria.add(updateCriterion(streetSearch));
			}
			if(!string.IsEmpty(zipSearch.value)){
				zipSearch.fieldName = 'shippingpostalcode';
				criteria.add(updateCriterion(zipSearch));
			}
			if(!string.IsEmpty(billplexSubIDSearch.value)){
				billplexSubIDSearch.fieldName = 'Billing_ID__c';
				billplexSubIDSearch = updateCriterion(billplexSubIDSearch);
				customWhere.add('customer_detail__r.Billing_ID__c' + AdvancedSearch.getCriteriaCompareString(billplexSubIDSearch.compareMode, billplexSubIDSearch.value ));
			}
			if(!string.IsEmpty(mssAccountIDSearch.value)){
				mssAccountIDSearch.fieldName = 'MSS_Account_ID__c';
				mssAccountIDSearch = updateCriterion(mssAccountIDSearch);
				customWhere.add('customer_detail__r.MSS_Account_ID__c' + AdvancedSearch.getCriteriaCompareString(mssAccountIDSearch.compareMode, mssAccountIDSearch.value ));
			}
			if(!string.isEmpty(legacyIDSearch.value)){
				legacyIDSearch.fieldName = 'Legacy_ID__c';
				legacyIDSearch = updateCriterion(legacyIDSearch);
				customWhere.add('customer_detail__r.Legacy_ID__c' + AdvancedSearch.getCriteriaCompareString(legacyIDSearch.compareMode, legacyIDSearch.value ));
			}
			if(pastDueSearch){
				customWhere.add('customer_detail__r.Past_Due__c = true');
			}
			if(!string.isEmpty(subscriberIDSearch.value)){
				subscriberIDSearch.fieldName = 'ICC_Subscriber_ID__c';
				subscriberIDSearch = updateCriterion(subscriberIDSearch);
				customWhere.add('customer_detail__r.ICC_Subscriber_ID__c' + AdvancedSearch.getCriteriaCompareString(subscriberIDSearch.compareMode, subscriberIDSearch.value ));
			}
		}
		
		
		if(onlySearchProspects)
			customWhere.add(searchByContact ? 'Account.ICC_Account_Number__c = null' : 'ICC_Account_Number__c = null');
		if(searchByContact)
			customWhere.add('Id in :customIDSet');
		List<String> allFields = new List<String>(accountFieldList);
		allFields.addAll(relatedCustomerDetailFieldList);
		sResults = AdvancedSearch.search(fieldSearch, criteria, new List<String>{'Account'}, new Set<String>(allFields), string.join(customWhere, ' and '));
		resultSets.put('Account', handleSearchResults(sResults, accountFieldList));
		
		if(!onlySearchAccounts){
			List<String> cdWhere = new List<String>();
			List<String> sLocWhere = new List<String>();
			
			for(Integer i=criteria.size()-1; i>=0; i--){
				if(criteria[i].fieldName == 'phone')
					criteria[i].fieldName = 'phone__c';
				else if(criteria[i].fieldName != 'name'){
					if(criteria[i].valid && (criteria[i].fieldName == 'shippingcity' || criteria[i].fieldName == 'shippingstate'
											|| criteria[i].fieldName == 'shippingstreet' || criteria[i].fieldName == 'shippingpostalcode')){
						String f = (criteria[i].fieldName == 'shippingpostalcode' ? 'postal_code' : (criteria[i].fieldName == 'shippingstreet' ? 'address' : (criteria[i].fieldName.substring(8))) + '__c ');
						cdWhere.add('service_address__r.' + f + AdvancedSearch.getCriteriaCompareString(criteria[i].compareMode, criteria[i].value));
						sLocWhere.add('location__r.building__r.' + f + AdvancedSearch.getCriteriaCompareString(criteria[i].compareMode, criteria[i].value));
					}
					criteria.remove(i);
				}
			}
			
			Set<String> cdCustomWheres = new Set<String>();
			if(!string.IsEmpty(billplexSubIDSearch.value)){
				billplexSubIDSearch.fieldName = 'Billing_ID__c';
				billplexSubIDSearch = updateCriterion(billplexSubIDSearch);
				
				cdCustomWheres.add('Billing_ID__c' + AdvancedSearch.getCriteriaCompareString(billplexSubIDSearch.compareMode, billplexSubIDSearch.value));
			}
			if(!string.IsEmpty(mssAccountIDSearch.value)){
				mssAccountIDSearch.fieldName = 'MSS_Account_ID__c';
				mssAccountIDSearch = updateCriterion(mssAccountIDSearch);
				
				cdCustomWheres.add('MSS_Account_ID__c' + AdvancedSearch.getCriteriaCompareString(mssAccountIDSearch.compareMode, mssAccountIDSearch.value));
			}
			if(!string.isEmpty(legacyIDSearch.value)){
				legacyIDSearch.fieldName = 'Legacy_ID__c';
				legacyIDSearch = updateCriterion(legacyIDSearch);
				
				cdCustomWheres.add('Legacy_ID__c' + AdvancedSearch.getCriteriaCompareString(legacyIDSearch.compareMode, legacyIDSearch.value));
			}
			if(pastDueSearch){
				cdCustomWheres.add('Past_Due__c = true');
			}
			if(onlySearchProspects && string.isEmpty(subscriberIDSearch.value)){
				cdCustomWheres.add('ICC_Subscriber_ID__c = null');
			}
			else if(!string.isEmpty(subscriberIDSearch.value)){
				subscriberIDSearch.fieldName = 'ICC_Subscriber_ID__c';
				subscriberIDSearch = updateCriterion(subscriberIDSearch);
				
				cdCustomWheres.add('ICC_Subscriber_ID__c' + AdvancedSearch.getCriteriaCompareString(subscriberIDSearch.compareMode, subscriberIDSearch.value));
			}
			if(searchByContact){
				cdWhere.add('Id in :customIDSet');
				sLocWhere.add('Account__c in :customIDSet');
			}
			
			for(String s : cdCustomWheres){
				cdWhere.add(s);
				sLocWhere.add('customer_detail__r.' + s);
			}
			
			sResults = AdvancedSearch.search(fieldSearch, criteria, new List<String>{'Service_Location__c'}, new Set<String>(serviceLocFieldList), string.join(sLocWhere, ' and '));
			resultSets.put('Service Location', handleSearchResults(sResults, serviceLocFieldList));
			
			sResults = AdvancedSearch.search(fieldSearch, criteria, new List<String>{'Customer_Detail__c'}, new Set<String>(customerDetailFieldList), string.join(cdWhere, ' and '));
			resultSets.put('Customer Detail', handleSearchResults(sResults, customerDetailFieldList));
			
			system.debug('sLocs: ' + resultSets.get('Service Location'));
			system.debug('cds: ' + resultSets.get('Customer Detail'));
		}
		
		for(String message : warnings)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, message));
		
		if(errors.size() > 0){
			for(String error : errors)
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
			
			resultSets = null;
		}
		
		return null;
	}
	
	private AdvancedSearch.SearchResultSet handleSearchResults(AdvancedSearch.SearchResults sResults, List<String> fieldList){
		for(String error : sResults.errors)
			errors.add(error);
		for(String message : sResults.messages)
			warnings.add(message);
		
		AdvancedSearch.debugQueriesFromResults(sResults);
		
		if(sResults.resultSets.size() > 0){
			Map<String, String> h = new Map<String, String>();
			List<String> f = new List<String>();
			if(fieldList != null){
				for(String str : fieldList){
					String sl = str.toLowerCase();
					system.debug('sl: ' + sl);
					system.debug('knownRelatedFields: ' + knownRelatedFields);
					if(knownRelatedFields.get(str) != null){
						h.put(sl, knownRelatedFields.get(str));
						f.add(sl);
					}
					else{
						String v = AdvancedSearch.validFields.get(sl);
						if(v != null){
							h.put(sl, v);
							f.add(sl);
						}
					}
				}
			}
			sortedFields.put(sResults.resultSets[0].objectName, f);
			headers.put(sResults.resultSets[0].objectName, h);
		}
		
		return (sResults.resultSets.size() > 0) ? sResults.resultSets[0] : null;
	}
	
	private AdvancedSearch.SearchCriterion updateCriterion(AdvancedSearch.SearchCriterion criterion){
		AdvancedSearch.SearchCriterion retval = new AdvancedSearch.SearchCriterion(criterion);
		Boolean startsWith = retval.value.endsWith('*');
		Boolean endsWith = retval.value.startsWith('*');
		if(endsWith || startsWith){
			retval.value = retval.value.substring((endsWith ? 1 : 0), retval.value.length()-(startsWith ? 1 : 2));
			retval.compareMode = (endsWith ? (startsWith ? AdvancedSearch.comp_Contains : AdvancedSearch.comp_EndsWith) : AdvancedSearch.comp_StartsWith);
		}
		else
			retval.compareMode = AdvancedSearch.comp_Equal;
		
		retval.value = retval.value.replace('%', '\\%').trim();
		
		return retval;
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_AccountSearch(); }
}