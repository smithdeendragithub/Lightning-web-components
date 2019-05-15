public without sharing class CustomSettingUtils implements TestUtils.ITestableClass {
    
    public static Integer WSTimeout {
        get {
            IntegraServiceSettings__c integraServiceSettings = IntegraServiceSettings__c.getInstance();
            if((integraServiceSettings == null) || (integraServiceSettings.Timeout__c == null))
                return 60 * 1000;
            else 
                return Integer.valueOf(integraServiceSettings.Timeout__c) * 1000;
        }
    }
    
    public static List<String> getEmailListsFromSettings(String typeID){
    	List<String> retval = new List<String>();

    	for(Email_Lists__c l : [select Id, Name, Type__c, Email__c from Email_Lists__c where Type__c = : typeID]){
			for(String email : !String.IsEmpty(l.Email__c) ? l.Email__c.split(',') : new List<String>())
				retval.add(email);
    	}
    	
    	return retval;
    }

    public static List<String> BillingChangeNotificationEmailAddresses {
        get { return GetEmailListsFromSettings('BillingChangeNotification'); }
    }
    
    public static List<String> IntegrationErrorEmailAddresses {
        get { return GetEmailListsFromSettings('IntegrationError'); }
    }
    
    public static List<String> TaskInternalKickoffCall {
        get { return GetEmailListsFromSettings('TaskInternalKickoffCall'); }
    }
	
	public static String EnvironmentURLPrefix{
		get{
            IntegraServiceSettings__c integraServiceSettings = IntegraServiceSettings__c.getInstance();
			return (integraServiceSettings != null && integraServiceSettings.Environment_URL_Prefix__c != null) ? integraServiceSettings.Environment_URL_Prefix__c : '';
		}
	}
	
	public static String TranslateEnvironmentURL(String url){
			return (url != null) ? url.replace('{envPrefix}', EnvironmentURLPrefix) : null;
	}
    
    public static String IntegraWSEndpoint {
		get {
			IntegraServiceSettings__c integraServiceSettings = IntegraServiceSettings__c.getInstance();
			return (integraServiceSettings != null) ? TranslateEnvironmentURL(integraServiceSettings.IntegraWS_Endpoint__c) : null;
		}
    }
	
	public static String IntegraDocumentDownloadURL{
		get{
            IntegraServiceSettings__c integraServiceSettings = IntegraServiceSettings__c.getInstance();
			return (integraServiceSettings != null) ? TranslateEnvironmentURL(integraServiceSettings.DocumentDownloadURL__c) : null;
		}
	}

    public static String SFDCCallbackEndpoint {
        get{ return URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/34.0/' + UserInfo.getOrganizationId(); }
    }
    
    private static Map<String, Map<String, List<String>>> processConfigurations = null;
    public static Map<String, String> getiCertProcessConfigurations(String processName){
		Map<String, String> config = new Map<String, String>();
		
		for(Process_Configuration__c pc : [select Key__c, Value__c from Process_Configuration__c Where Process__c = :processName])
			config.put(pc.Key__c, pc.Value__c);
    	
    	return config;
    }
    
    private static Map<String, List<String>> getProcessConfigurations(String processName){
    	
    	if(processConfigurations == null){
    		processConfigurations = new Map<String, Map<String, List<String>>>();
    		
    		for(Process_Configuration__c pc : [select Process__c, Key__c, Value__c from Process_Configuration__c]){
    			Map<String, List<String>> config = processConfigurations.get(pc.Process__c);
    			if(config == null)
    				config = new Map<String, List<String>>();
    			
    			List<String> configList = config.get(pc.Key__c);
    			if(configList == null)
    				configList = new List<String>();
    			
    			configList.add(pc.Value__c);
    			config.put(pc.Key__c, configList);
				processConfigurations.put(pc.Process__c, config);
    		}
    	}
    	
    	return processConfigurations.get(processName);
    }
    
    public static List<String> getProcessConfigurationValues(String processName, String key){
    	Map<String, List<String>> configs = getProcessConfigurations(processName);
    	return configs != null && configs.get(key) != null ? configs.get(key) : new List<String>();
    }
    
    private static Map<String, Map<String, List<User>>> processConfigurationUsers = null;
    private static List<User> getUsersFromProcessConfiguration(String processName, String key){
    	List<User> retval = new List<User>();
    	
    	if(processConfigurationUsers == null)
    		processConfigurationUsers = new Map<String, Map<String, List<User>>>();
    	
    	Map<String, List<String>> configs = getProcessConfigurations(processName);
    	Map<String, List<User>> userList = processConfigurationUsers.get(processName);
    	
    	if(userList == null && configs != null && configs.size() > 0){
    		userList = new Map<String, List<User>>();
    		Map<String, User> userByNTID = new Map<String, User>();
    		for(String k : configs.keyset()){
    			for(String v : configs.get(k))
    				userByNTID.put(v, null);
    		}
    		
    		if(userByNTID.size() > 0){
	    		for(User u : [select Id, Name, Email, NTID__c, State, Sales_Channel__c from User where NTID__c in : userByNTID.keyset()])
	    			userByNTID.put(u.NTID__c, u);
	    		for(String k : configs.keyset()){
	    			List<User> ul = new List<User>();
	    			for(String v : configs.get(k)){
	    				User u = userByNTID.get(v);
	    				if(u != null)
	    					ul.add(u);
	    			}
	    			userList.put(k, ul);
	    		}
    		}
    		processConfigurationUsers.put(processName, userList);
    	}
    	
    	if(userList != null && userList.get(key) != null){
    		for(User u : userList.get(key))
    			retval.add(u);
    	}
    	
    	return retval;
    }
    
    public static String getSingleProcessConfigurationValue(String processName, String key, Boolean defaultIfNeeded){
    	List<String> s = getProcessConfigurationValues(processName, key);
    	if(s.size() == 0 && defaultIfNeeded)
    		s = getProcessConfigurationValues(processName, 'Default');
    	
    	return s.size() > 0 ? s.get(0) : null;
    }
    
    public static String getPrimaryContactByState(String StateCode){
    	return getSingleProcessConfigurationValue('PrimaryContactLookup', StateCode, false);
    }
    
    public static String getICertBusinessUnitFromOppSalesChannel(String OppSalesChannel){
    	return getSingleProcessConfigurationValue('MapInternalSalesChannelToICertBusinessUnit', OppSalesChannel, true);
    }
    
    public static String getICertSalesChannelFromOppSalesChannel(String OppSalesChannel){
    	return getSingleProcessConfigurationValue('MapInternalSalesChannelToICertSalesChannel', OppSalesChannel, true);
    }
    
    public static User getSingleUserFromProcessConfiguration(String processName, String key, Boolean defaultIfNeeded){
    	List<User> u = getUsersFromProcessConfiguration(processName, key);

    	if(u.size() == 0 && defaultIfNeeded)
    		u = getUsersFromProcessConfiguration(processName, 'Default');
    	return u.size() > 0 ? u.get(0) : null;
    }
    
    public static User getRegionalAE(String stateCode){
    	return getSingleUserFromProcessConfiguration('RegionAE', stateCode, true);
    }
    
    public static User getInternalKickoffSalesChannelManager(String salesChannel){
    	if(salesChannel == 'Enterprise' || salesChannel == 'GovEd')
    		return getSingleUserFromProcessConfiguration('InternalKickoffSalesChannelManager', salesChannel, true);
    	else
    		return getSingleUserFromProcessConfiguration('InternalKickoffSalesChannelManager', 'Default', true);
    }
    
    private static Map<String, Boolean> overrideSettingValue = new Map<String, Boolean>();
    public static Boolean getOverrideSettingValue(String overrideSettingName){
    	if(overrideSettingValue.get(overrideSettingName) == null){
    		List<OverrideSettings__c> osett = [Select Id, Name, Override__c From OverrideSettings__c Where Name =: overrideSettingName];
    		overrideSettingValue.put(overrideSettingName, osett.size() > 0 && osett[0].Override__c);
    	}
    	return overrideSettingValue.get(overrideSettingName);
    }
	
	private static List<Custom_Permissions__c> currentUserCustomPermissions = null;
	public static List<Custom_Permissions__c> getCurrentUserCustomPermissions(){
		if(currentUserCustomPermissions == null){
    		User currentUser = [select Id, Profile.Name, (select PermissionSet.Name from PermissionSetAssignments) from User where Id =: UserInfo.getUserId()];
    		
			//Get Any public group users
			Set<String> publicGroups = new Set<String>();
			for(GroupMember gm : [Select Id, GroupID, Group.DeveloperName From GroupMember Where UserOrGroupID =: UserInfo.getUserId()])
				publicGroups.add(gm.Group.DeveloperName);
			
    		Set<String> permissionSets = new Set<String>();
    		for(PermissionSetAssignment psa : currentUser.PermissionSetAssignments != null ? currentUser.PermissionSetAssignments : new List<PermissionSetAssignment>())
    			permissionSets.add(psa.PermissionSet.Name);
			
    		currentUserCustomPermissions = (List<Custom_Permissions__c>)ApexUtils.retrieveFullObjects(Custom_Permissions__c.getsObjectType()
    																	,'(Group_Type__c=\'Profile\' and Group__c = \'' + currentUser.Profile.Name + '\')'
    																	+ ' or (Group_Type__c=\'Permission Set\' and Group__c in (\'' + string.join(new List<String>(permissionSets), '\',\'') + '\'))'
																		+ ' or (Group_Type__c=\'Public Group\' and Group__c in (\'' + string.join(new List<String>(publicGroups), '\',\'') + '\'))');
		}
		
		return currentUserCustomPermissions;
	}
    
    private static Set<String> currentUserCustomPermissionOptions = null;
    public static Boolean currentUserHasCustomPermission(String permissionName){
    	if(currentUserCustomPermissions == null){
    		currentUserCustomPermissionOptions = new Set<String>();
			
    		Set<String> fieldsToCheck = new Set<String>();
    		Map<String, Schema.SObjectField> fieldMap = Custom_Permissions__c.getsObjectType().getDescribe().fields.getMap();
    		for(String fieldStr : fieldMap.keyset()){
    			if(fieldStr != 'Is_Profile_Permission__c'){
	        		Schema.DescribeFieldResult fdr = fieldMap.get(fieldStr).getDescribe();
	        		if(fdr.getSoapType() == Schema.SOAPType.Boolean)
	        			fieldsToCheck.add(fieldStr);
    			}
        	}
			
    		for(Custom_Permissions__c p : getCurrentUserCustomPermissions()){
				for(String f : fieldsToCheck){
					if((Boolean)p.get(f)) currentUserCustomPermissionOptions.add(f.toLowercase());
				}
			}
    	}
    	
    	return permissionName != null ? currentUserCustomPermissionOptions.contains(permissionName.toLowercase()) : false;
    }
	
	public static String GetDocumentDownLoadURL(String DocumentID, String salesForceSessionID, String apiURL){
		String Url = IntegraDocumentDownloadURL;
		Url = Url.replace('{documentID}', DocumentID);
		Url = Url.replace('{salesForceSessionID}', salesForceSessionID);
		Url = Url.replace('{apiUrl}', apiURL);
		return Url;
	}
	
	/*
	public static List<SelectOption> GetEnniCarrierList(){
		List<SelectOption> EnniCarriers = new List<SelectOption>();
		for(eNNI_Carrier_List__c enni : [Select Table_Suffix__c, CarrierName__c from eNNI_Carrier_List__c]){
			EnniCarriers.add(new SelectOption(enni.Table_Suffix__c, enni.CarrierName__c));
		}
		return EnniCarriers;
	}*/
	
	public static Green_Light_Scoring__c GetGreenLightScoringForScore(Decimal score){
		Green_Light_Scoring__c tgls = null;
		for(Green_Light_Scoring__c gls : [Select Score__c, Image_Name__c, Help_Text__c, Color__c from Green_Light_Scoring__c]){
			if(score >= gls.Score__c && gls.Score__c > (tgls == null? -100 : tgls.Score__c))
				tgls = gls;
		}	
		return tgls;
	}
	
	public static Bad_Deal_Percentage_Text__c GetBadDealPercentageText(Decimal percent){
		Bad_Deal_Percentage_Text__c tbdpt = null;
		for(Bad_Deal_Percentage_Text__c bdpt : [select percent__c, text__c from Bad_Deal_Percentage_Text__c]){
			if(percent >= bdpt.percent__c && bdpt.percent__c > (tbdpt == null? -100 : tbdpt.percent__c))
				tbdpt = bdpt;
		}
		return tbdpt;
	
	}
	
	public static String GetICertSalesChannelMapping(String sfdcOwnersSalesChannel){
		return getSingleProcessConfigurationValue('iCertSalesChannelMapping', sfdcOwnersSalesChannel, true);
	}
	
	public static String GetICertBusinessUnitMapping(String sfdcAccountSalesChannel){
		return getSingleProcessConfigurationValue('iCertBusinessUnitMapping', sfdcAccountSalesChannel, true);
	}

	public static string GetICertSE(string key){
		return getSingleProcessConfigurationValue('ICertSE',key,true);
	}
	
	private static List<String> pITSOppProds = null;
	public static List<String> GetITSOppProductNames(){
		if(pITSOppProds == null){
			pITSOppProds = new List<String>();
			for(ITS_Opp_Prods__c itsOppProd : [select Product_Name__c from ITS_Opp_Prods__c])
				pITSOppProds.add(itsOppProd.Product_Name__c);
		}
		return pITSOppProds;
	}
	
	/* Dynamic SOQL Criteria */
	public class DynamicSOQLException extends Exception {}
	
	public static Boolean dynamicQueryDebug = false;
	private static Integer maxDynamicCriteriaID = 0;
	private static Map<Integer, Dynamic_SOQL_Criteria__c> p_dynamicCriteria = null;
	private static Map<Integer, Dynamic_SOQL_Criteria__c> dynamicCriteria{
		get{
			if(p_dynamicCriteria == null){
				p_dynamicCriteria = new Map<Integer, Dynamic_SOQL_Criteria__c>();
				for(Dynamic_SOQL_Criteria__c c : Dynamic_SOQL_Criteria__c.getall().values()){
					Integer uID = (Integer)c.Unique_ID__c;
					p_dynamicCriteria.put(uID, c);
					maxDynamicCriteriaID = uID > maxDynamicCriteriaID ? uID : maxDynamicCriteriaID;
				}
			}
			return p_dynamicCriteria;
		}
	}
	
	public static Set<String> getDynamicQueryObjects(String criteriaString){
		criteriaString = formatCriteriaString(criteriaString);
		
		Set<String> retval = new Set<String>();
		
		Map<Integer, Dynamic_SOQL_Criteria__c> dc = dynamicCriteria;
		for(Integer i=maxDynamicCriteriaID; i>=1; i--){
			if(criteriaString.contains('{' + string.valueOf(i) + '}') && dc.get(i) != null) retval.add(dc.get(i).sObject__c);
		}
		
		return retval;
	}
	
	public static Set<Id> getRecordsByDynamicCriteria(String criteriaString, Set<Id> setIDs){
		criteriaString = formatCriteriaString(criteriaString);
		
		Set<Id> retval = new Set<Id>();
		
		Map<Integer, Dynamic_SOQL_Criteria__c> dc = dynamicCriteria;
		
		String objName = null;
		Set<Integer> cIDs = new Set<Integer>();
		for(Integer i=maxDynamicCriteriaID; i>=1; i--){
			if(criteriaString.contains('{' + string.valueOf(i) + '}')){
				cIDs.add(i);
				if(dc.get(i) == null) throw new DynamicSOQLException('Invalid SOQL Query Id: ' + String.valueOf(i));
				
				if(objName == null) objName = dc.get(i).sObject__c;
				else if(dc.get(i).sObject__c != objName) throw new DynamicSOQLException('Multiple sObjects encountered in the same dynamic SOQL query: ' + criteriaString);
			}
		}
		
		Set<Id> subsetIDs = new Set<Id>();
		for(Id id : setIDs){
			if(SchemaUtils.GetSObjectNameByID(id).toLowercase() == objName.toLowerCase()) subsetIDs.add(id);
		}
		
		if(cIDs.size() == 0){ System.debug('No Unique IDs found for: ' + criteriaString); return retval; }
		else if(subsetIDs != null && subsetIDs.size() == 0){ System.debug('No records in the set to query: ' + criteriaString); return retval; }
		
		validateDynamicSOQLString(criteriaString, cIDs);
		
		if(cIDs.size() == 1 && String.isEmpty(dc.get((new List<Integer>(cIDs))[0]).Criteria__c)) retval = subsetIDs != null ? subsetIDs : new Set<Id>();
		else{
			String csCopy = criteriaString;
			for(Integer i : cIDs) csCopy = csCopy.replace('{' + string.valueOf(i) + '}', '(' + (!String.isEmpty(dc.get(i).Criteria__c) ? dc.get(i).Criteria__c : 'Id != null') + ')');
			
			String soql = 'select Id from ' + objName + ' where ' + (subsetIDs != null && subsetIDs.size() > 0 ? 'Id in: subsetIDs and ' : '') + csCopy;
			System.debug('Executing dynamic criteria ' + criteriaString + ' on object ' + objName + ': ' + soql);
			for(sObject o : Database.query(soql)) retval.add(o.Id);
		}
		
		System.debug(string.valueOf(retval.size()) + ' records found');
		
		return retval;
	}
	
	private static Map<String, Boolean> dynamicCriteriaPriorResults = new Map<String, Boolean>();
	public static Boolean dynamicCriteriaRecordsExist(String criteriaString, Set<Id> setIDs, Boolean usePriorResults){
		criteriaString = formatCriteriaString(criteriaString);
		
		Map<Integer, Dynamic_SOQL_Criteria__c> dc = dynamicCriteria;
		
		Set<Integer> cIDs = new Set<Integer>();
		for(Integer i=maxDynamicCriteriaID; i>=1; i--){
			if(criteriaString.contains('{' + string.valueOf(i) + '}')){
				cIDs.add(i);
				if(dc.get(i) == null) throw new DynamicSOQLException('Invalid SOQL Query Id: ' + String.valueOf(i));
			}
		}
		
		if(cIDs.size() == 0){ System.debug('No Unique IDs found for: ' + criteriaString); return false; }
		
		validateDynamicSOQLString(criteriaString, cIDs);
		
		System.debug('Transforming: ' + criteriaString);																	//ex: ({1} AND ({2} OR {3}) AND {4}) AND {5} AND {6}
		criteriaString = criteriaString.replace(' ', '').replace('AND', '&').replace('OR', '|').replace('NOT', '!');		//ex: ({1}&({2}|{3})&{4})&{5}&{6}
		String csCopy = criteriaString;
		
		/* ex
		* Assuming 1, 2, 5 and 6 are object A and 3 and 4 is object B
		* parts = '({1}&({2}', '|{3})&{4})', '&{5}&{6}'
		* objects = A, B, A
		*/
		
		List<String> parts = new List<String>();
		List<String> objects = new List<String>();
		while(csCopy.contains('{')){
			Integer i = Integer.valueOf(csCopy.substringAfter('{').substringBefore('}'));
			
			String objName = objects.size() > 0 ? objects[objects.size()-1] : null;
			Boolean newObj = objName != dc.get(i).sObject__c;
			if(objName == null || newObj || csCopy.substringBefore('{').contains('|') || csCopy.substringBefore('{').contains('!')){		//Need to be careful with OR/NOT and parens
				objName = dc.get(i).sObject__c;
				objects.add(objName);
				parts.add('');
			}
			
			String part = csCopy.substringBefore('}') + '}';
			if(part.substringBefore('{').contains('!')) part = part.substringAfter('!');	//NOT will be applied later
			csCopy = csCopy.substringAfter('}');
			
			while(csCopy != '' && csCopy.substring(0, 1) == ')'){
				part += ')';
				csCopy = csCopy.substring(1);
			}
			
			parts[parts.size()-1] += part;
		}
		
		//Collapse if possible on OR
		for(Integer i=0; i<parts.size(); i++){
			String mergePart = parts[i];
			String additionalParts = '';
			
			//Get the number of possible entries we can collapse
			Integer collapseNum = 0;
			while(i<parts.size()-(1+collapseNum) && objects[i] == objects[i+1+collapseNum] && parts[i+1+collapseNum].startsWith('|'))
				collapseNum++;
			
			Boolean otherPartsExist = (collapseNum + i) != (parts.size() - 1);
			
			if(otherPartsExist){
				Integer possibleCollapses = collapseNum;
				collapseNum = 0;
				
				//Make sure we don't have open parens and there are no NOT tokens
				Integer openParens = parts[i].countMatches('(') - parts[i].countMatches(')');
				if(openParens > 0 && !parts[i].contains('!')){
					for(Integer k=0; k<possibleCollapses; k++){
						Integer x = i+k+1;
						Integer closeParens = parts[x].countMatches(')') - parts[x].countMatches('(');
						if(closeParens > 0){
							collapseNum = k + 1;
							openParens -= closeParens;
						}
						
						if(parts[x].contains('!')){
							collapseNum = 0;
							break;
						}
						if(openParens <= 0) break;
					}
				}
			}
			
			for(Integer k=0; k<collapseNum; k++){
				parts[i] += parts[i+1];
				parts.remove(i+1);
				objects.remove(i+1);
			}
			
			i += collapseNum;
		}
		
		/* ex
		* query parts = '{1}', '{2}', '{3}', '{4}', '{5}&{6}'
		* objects = A, A, B, B, A
		*/
		
		//Simplify so we drop trailing parens etc
		for(Integer i=0; i<parts.size(); i++){
			String part = parts[i];
			
			if(!part.startsWith('(') && !part.startsWith('{')) part = part.contains('(') && part.indexOf('(') < part.indexOf('{') ? ('(' + part.substringAfter('(')) : ('{' + part.substringAfter('{'));
			
			while((part.startsWith('(') || part.endsWith(')')) && part.countMatches('(') != part.countMatches(')')){
				if(part.startsWith('(')) part = part.substring(1);
				else part = part.substring(0, part.length()-1);
			}
			
			String next = '';
			while(part.countMatches('(') != part.countMatches(')')){
				next = '{' + part.substringAfterLast('{') + next;
				part = part.substringBeforeLast('{');
				next = part.substringAfterLast('}') + next;
				part = part.substringBeforeLast('}') + '}';
			}
			
			if(next != ''){
				if(i == parts.size() - 1) parts.add(next);
				else parts.add(i+1, next);
			}
			parts[i] = part;
		}
		
		//Now query each part
		csCopy = criteriaString;
		for(Integer i=0; i<parts.size(); i++){
			Boolean bVal = false;
			if(usePriorResults && dynamicCriteriaPriorResults.get(parts[i]) != null) bVal = dynamicCriteriaPriorResults.get(parts[i]);
			else{
				Set<Id> objIDs = getRecordsByDynamicCriteria(parts[i].replace('{', '').replace('}', '').replace('&', ' AND ').replace('|', ' OR ').replace('!', ' NOT '), setIDs);
				bVal = objIDs.size() > 0;
				if(usePriorResults) dynamicCriteriaPriorResults.put(parts[i], bVal);
			}
			csCopy = csCopy.replace(parts[i], String.valueOf(bVal));				//Replace each part with true or false for the record existing
		}
		
		//Simplify until we have a true or false answer
		csCopy = csCopy.replace('true', '1').replace('false', '0');
		
		String unsimplified = csCopy;
		Boolean simplifying = csCopy != '1' && csCopy != '0';
		if(simplifying){
			System.debug('Before simplifying: ' + unsimplified);
			while(simplifying){
				String csCopyOld = csCopy;
				
				while(csCopy.contains('!1') || csCopy.contains('!0')){
					csCopy = csCopy.replace('!1', '0').replace('!0', '1');
				}
				
				csCopy = csCopy.replace('1&1', '1').replace('0&1', '0').replace('1&0', '0').replace('0&0', '0');
				csCopy = csCopy.replace('1|1', '1').replace('0|1', '1').replace('1|0', '1').replace('0|0', '0');
				csCopy = csCopy.replace('(1)', '1').replace('(0)', '0');
				
				simplifying = csCopyOld != csCopy;
			}
			System.debug('After simplifying: ' + csCopy);
		}
		
		if(csCopy.length() > 1) throw new DynamicSOQLException('Invalid SOQL criteria could not be simplified');
		if(dynamicQueryDebug) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, ('"' + criteriaString.replace('{', '').replace('}', '') + '" evaluates to "' + (unsimplified + '"' + (unsimplified != csCopy ? (' simplified as "' + csCopy + '"') : '')).replace('1', 'true').replace('0', 'false')).replace('&', ' AND ').replace('|', ' OR ').replace('!', ' NOT ')));
		
		return csCopy == '1';
	}
	
	private static String formatCriteriaString(String criteriaString){
		criteriaString = criteriaString.toUpperCase();
		Boolean readingInteger = false;
		for(Integer i=0; i<criteriaString.length(); i++){
			String before = criteriaString.substring(0, i);
			String ch = criteriaString.substring(i, i+1);
			if(ch.isNumeric() && !readingInteger){
				readingInteger = true;
				criteriaString = before + '{' + criteriaString.substring(i++);
			}
			else if(!ch.isNumeric() && readingInteger){
				readingInteger = false;
				criteriaString = before + '}' + criteriaString.substring(i++);
			}
		}
		if(readingInteger) criteriaString += '}';
		return criteriaString;
	}
	
	private static void validateDynamicSOQLString(String criteriaString, Set<Integer> cIDs){
		String csCopy = criteriaString;
		for(Integer i : cIDs) csCopy = csCopy.replace('{' + string.valueOf(i) + '}', '');
		csCopy = csCopy.replace(' ', '').replace('(', '').replace(')', '').replace('NOT', '').replace('AND', '').replace('OR', '');
		
		if(csCopy.length() > 0) throw new DynamicSOQLException('Invalid elements encountered in dynamic SOQL query: ' + criteriaString);
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_CustomSettingUtils(); }
}