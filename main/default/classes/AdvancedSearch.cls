public with sharing class AdvancedSearch implements TestUtils.ITestableClass {
	public static final Integer comp_Equal = 0;
	public static final Integer comp_NotEqual = 1;
	public static final Integer comp_Contains = 2;
	public static final Integer comp_StartsWith = 3;
	public static final Integer comp_EndsWith = 4;
	public static final Integer comp_GreaterThan = 5;
	public static final Integer comp_GreaterThanOrEqual = 6;
	public static final Integer comp_LessThan = 7;
	public static final Integer comp_LessThanOrEqual = 8;
	
	//Most standard objects do not need to be searchable.  All objects in this set must have the 'Name' field.
	public static final Set<String> supportedStandardObjects = new Set<String>{'Account', 'Contact', 'Lead', 'Opportunity'};
	public static final Map<String, String> reservedFields = new Map<String, String>{'name' => 'Name', 'id' => 'Id'};
	
	private static Map<String, Schema.SObjectType> globalDescribeMap {get; set;}
	private static Map<String, Schema.SObjectType> GlobalDescribe{
		get{
			if(globalDescribeMap == null)
				globalDescribeMap = Schema.getGlobalDescribe();
			return globalDescribeMap;
		}
	}
	
	public class SearchCriterion {
		public String fieldLabel {get; set;}
		public String fieldName {get; set;}
		
		public String value {get; set;}
		public Boolean valid {get; set;}
		public Integer compareMode {get; set;}
		public Integer id {get; private set;}
		
		public SearchCriterion(){ init(); }
		
		public SearchCriterion(SearchCriterion copyFrom){
			fieldLabel = copyFrom.fieldLabel;
			fieldName = copyFrom.fieldName;
			value = copyFrom.value;
			valid = copyFrom.valid;
			compareMode = copyFrom.compareMode;
			id = copyFrom.id;
		}
		
		public SearchCriterion(String name){ init(); fieldName = name; }
		
		public SearchCriterion(Integer id){ init(); this.id = id; }
		
		private void init(){
			fieldName = null;
			value = null;
			compareMode = 0;
			valid = true;
		}
	}
	
	public class SearchResult {
		public String name {get; set;}
		public Id id {get; set;}
		public Map<String, String> fieldMap {get; set;}
		
		public SearchResult(String name, Id id){
			this.name = name;
			this.id = id;
			fieldMap = new Map<String, String>();
		}
	}
	
	public class SearchResultSet{
		public String objectName {get; set;}
		public List<SearchResult> results {get; set;}
		public Integer total {get; set;}
		
		public SearchResultSet(String objName){
			objectName = objName;
			results = new List<SearchResult>();
			total = 0;
		}
	}
	
	public class SearchResults {
		public List<SearchResultSet> resultSets {get; set;}
		public List<String> errors {get; set;}
		public List<String> messages {get; set;}
		public List<String> soqlQueries {get; set;}
		public String soslQuery {get; set;}
		
		public SearchResults(){
			resultSets = new List<SearchResultSet>();
			errors = new List<String>();
			messages = new List<String>();
			soqlQueries = new List<String>();
		}
	}
	
	public class CriteriaValidation{
		public List<SearchCriterion> criteria {get; set;}
		public Map<String, String> validFields {get; set;}
		CriteriaValidation(){}
	}
	
	private static Map<Boolean, Map<String, String>> searchableObjects;
	public static Map<String, String> getSearchableObjects(Boolean custom){
		
		if(searchableObjects == null){
			searchableObjects = new Map<Boolean, Map<String, String>>{true=>new Map<String, String>(), false=>new Map<String, String>()};
				
			for(String sObjName : GlobalDescribe.keyset()){
	   			Schema.DescribeSObjectResult ds = GlobalDescribe.get(sObjName).getDescribe();
	   			if(ds.isSearchable() && (ds.isCustom() || supportedStandardObjects.contains(ds.getName())))
	   				searchableObjects.get(ds.isCustom()).put(ds.getName(), ds.getLabel());
			}
		}
		
		return searchableObjects.get(custom);
	}
	
	public static Map<String, String> validFields;
	public static CriteriaValidation validateCriteria(List<String> objectTypes, List<SearchCriterion> criteria){
		CriteriaValidation validation = new CriteriaValidation();
		if(objectTypes.size() > 0){
			validation.validFields = getValidSearchFields(objectTypes);
				
    		for(SearchCriterion c : criteria){
    			if(c.FieldName == null)
    				c.valid = false;
    			else{
	    			c.fieldName = c.fieldName.toLowerCase();
	    			c.valid = validation.validFields.get(c.fieldName) != null;
	    			c.fieldLabel = validation.validFields.get(c.fieldName) != null ? validation.validFields.get(c.fieldName) : c.fieldLabel;
    			}
    		}
		}
		else{
			validation.validFields = new Map<String, String>();
			for(SearchCriterion c : criteria)
				c.valid = false;
		}
		
		validFields = validation.validFields;
		validation.criteria = criteria;
		return validation;
	}
	
	public static Map<String, String> getValidSearchFields(List<String> objectTypes){
		Map<String, String> valid = new Map<String, String>();
		
		Map<String, Map<String, Schema.DescribeFieldResult>> fieldByObj = new Map<String, Map<String, Schema.DescribeFieldResult>>();
		Boolean firstObj = true;
		for(String typeStr : objectTypes){
   			Schema.DescribeSObjectResult ds = GlobalDescribe.get(typeStr).getDescribe();
        	Map<String, Schema.SObjectField> fieldMap = ds.fields.getMap();
        	
        	Map<String, Schema.DescribeFieldResult> objValid = new Map<String, Schema.DescribeFieldResult>();
        	for(String fieldStr : fieldMap.keyset()){
        		if(reservedFields.get(fieldStr) != null) continue;
        		
        		Schema.DescribeFieldResult fdr = fieldMap.get(fieldStr).getDescribe();
        		objValid.put(fieldStr, fdr);
				valid.put(fieldStr.toLowerCase(), fdr.getLabel());
        	}
        	
			fieldByObj.put(typeStr, objValid);
		}
		
		if(objectTypes.size() > 1){
			for(String fieldStr : new List<String>(valid.keyset())){
				Schema.DescribeFieldResult fdr = null;
				for(String typeStr : fieldByObj.keyset()){
					Schema.DescribeFieldResult objFdr = fieldByObj.get(typeStr).get(fieldStr);
					if(objFdr == null || (fdr != null && fdr.getLabel() != objFdr.getLabel() && fdr.getType() != objFdr.getType()))
						valid.remove(fieldStr);
					else
						fdr = objFdr;
				}
			}
		}
		for(String k : reservedFields.keyset())
			valid.put(k.toLowerCase(), reservedFields.get(k));
		
		return valid;
	}
	
	private static final Map<Integer, Map<Boolean, String>> criteriaMessages = new Map<Integer, Map<Boolean, String>>
											{comp_Equal => new Map<Boolean, String>{true=>' = \'{VALUE}\'',
																					false=>' equal to '},
											comp_NotEqual => new Map<Boolean, String>{true=>' != \'{VALUE}\'',
																					false=>' not equal to '},
											comp_Contains => new Map<Boolean, String>{true=>' like \'%{VALUE}%\'',
																					false=>' contains '},
											comp_StartsWith => new Map<Boolean, String>{true=>' like \'{VALUE}%\'',
																					false=>' starts with '},
											comp_EndsWith => new Map<Boolean, String>{true=>' like \'%{VALUE}\'',
																					false=>' ends with '},
											comp_GreaterThan => new Map<Boolean, String>{true=>' > {VALUE}',
																					false=>' greater than '},
											comp_GreaterThanOrEqual => new Map<Boolean, String>{true=>' >= {VALUE}',
																					false=>' greater than or equal to '},
											comp_LessThan => new Map<Boolean, String>{true=>' < {VALUE}',
																					false=>' less than '},
											comp_LessThanOrEqual => new Map<Boolean, String>{true=>' <= {VALUE}',
																					false=>' less than or equal to '}};
	public static String getCriteriaCompareString(Integer compareMode, String value){
		return criteriaMessages.get(compareMode).get(true).replace('{VALUE}', value);
	}
	
	public static Boolean treatNullsAsEmptyString {get; set;}
	public static Set<Id> customIDSet {get; set;}
	public static SearchResults search(String allFieldSearch, List<SearchCriterion> fieldSearchCriteria, List<String> objectTypes, Set<String> extraFieldsToReturn, String customWhereClause){
		SearchResults results = new SearchResults();
		
		getSearchableObjects(true);
		for(Integer i=objectTypes.size()-1; i>=0; i--){
			if(searchableObjects.get(true).get(objectTypes[i]) == null && searchableObjects.get(false).get(objectTypes[i]) == null){
				results.messages.add('Object \'' + objectTypes[i] + '\' is not searchable.');
				objectTypes.remove(i);
			}
		}
		
		if(objectTypes.size() == 0){
			results.errors.add('No searchable objects have been specified.');
			return results;
		}
		
		Boolean soslSearch = !string.IsEmpty(allFieldSearch);
		if(soslSearch && allFieldSearch.length() < 2){
			results.errors.add('All field search values need to be 2 characters minimum.');
			return results;
		}
		
		Set<String> whereClauses = new Set<String>();
		
		CriteriaValidation validation = validateCriteria(objectTypes, fieldSearchCriteria);
		List<SearchCriterion> activeCriteria = new List<SearchCriterion>();
		for(SearchCriterion c : validation.criteria){
			if(c.valid){
				c.value = (c.value != null ? c.value : '').replace('\'', '\\\'');
				activeCriteria.add(c);
			}
		}
		
		Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>();
		
		Map<String, Schema.DescribeSObjectResult> objDescribes = new Map<String, Schema.DescribeSObjectResult>();
		Map<String, Map<String, Schema.SObjectField>> fieldByObj = new Map<String, Map<String, Schema.SObjectField>>();
		for(String typeStr : objectTypes){
   			Schema.DescribeSObjectResult ds = GlobalDescribe.get(typeStr).getDescribe();
			objDescribes.put(typeStr, ds);
			Map<String, Schema.SObjectField> fm = ds.fields.getMap();
			fieldByObj.put(typeStr, fm);
			
			for(String str : fm.keyset()){
				if(fieldMap.get(str) == null)
					fieldMap.put(str, fm.get(str));
			}
		}
		
		Date d1;
		Date d2;
		
		Set<String> fSet = new Set<String>{'id', 'name'};
		if(extraFieldsToReturn != null){
			for(String f : extraFieldsToReturn){
				String fl = f.toLowerCase();
				if(!fSet.contains(fl))
					fSet.add(fl);
			}
		}
		Map<String, Schema.SOAPType> fieldTypeMap = new Map<String, Schema.SOAPType>();
		for(SearchCriterion c : activeCriteria){
			if(c.value.length() < 2 && (c.compareMode == comp_Contains || c.compareMode == comp_StartsWith || c.compareMode == comp_EndsWith)){
				results.messages.add('Ignoring invalid search criteria \'' + c.fieldLabel
									+ (c.compareMode == comp_Contains
										? ' contains '
										: (c.compareMode == comp_StartsWith
											? ' starts with '
											: ' ends with '))
									+ c.value + '.\' The value must be 2 or more characters for partial value searches.');
				continue;
			}
			
			Schema.SOAPType fd = fieldTypeMap.get(c.fieldName);
			if(fd == null){
				fd = fieldMap.get(c.fieldName).getDescribe().getSoapType();
				fieldTypeMap.put(c.fieldName, fd);
			}
			
			if(!fSet.contains(c.fieldName))
				fSet.add(c.fieldName);
			
			if(c.compareMode == comp_Equal || c.compareMode == comp_NotEqual){
				if(fd == Schema.SOAPType.DateTime || fd == Schema.SOAPType.Date)
					results.messages.add('Ignoring invalid search criteria \'' + c.fieldLabel + criteriaMessages.get(c.compareMode).get(false) + c.value + '\'');
				else
					whereClauses.add(c.fieldName + getCriteriaCompareString(c.compareMode, c.value));
			}
			else if(c.compareMode == comp_Contains || c.compareMode == comp_StartsWith || c.compareMode == comp_EndsWith){
				if(fd == Schema.SOAPType.String)
					whereClauses.add(c.fieldName + getCriteriaCompareString(c.compareMode, c.value));
				else
					results.messages.add('Ignoring invalid search criteria \'' + c.fieldLabel + criteriaMessages.get(c.compareMode).get(false) + c.value + '\'');
			}
			else if(c.compareMode == comp_GreaterThan || c.compareMode == comp_GreaterThanOrEqual || c.compareMode == comp_LessThan || c.compareMode == comp_LessThanOrEqual){
				
				if(fd != Schema.SOAPType.DateTime && fd != Schema.SOAPType.Date && fd != Schema.SOAPType.Double && fd != Schema.SOAPType.Integer)
					results.messages.add('Ignoring invalid search criteria \'' + c.fieldLabel + criteriaMessages.get(c.compareMode).get(false) + c.value + '\'');
				else{
					String val;
					if(fd == Schema.SOAPType.DateTime || fd == Schema.SOAPType.Date){
						Date dt;
						try{
							dt = Date.parse(c.value);
							if(dt != null){
								//todo: Cannot index in dynamic soql, find a better way?
								if(d1 == null){
									d1 = dt;
									val = ':d1';
								}
								else if(d2 == null){
									d2 = dt;
									val = ':d2';
								}
								else{
									results.errors.add('You cannot specify more than two date values to search on.');
									return results;
								}
							}
						}
						catch(Exception e){
							dt = null;
						}
						if(dt == null)
							results.messages.add('Ignoring invalid date string \'' + c.value + '.\' Please write date values in the following format DD/MM/YYYY.');
					}
					else
						val = ' \'' + c.value + '\'';
					
					if(!string.IsEmpty(val))
						whereClauses.add(c.fieldName + getCriteriaCompareString(c.compareMode, c.value));
				}
			}
		}
		
		if(!string.IsEmpty(customWhereClause))
			whereClauses.add('(' + customWhereClause + ')');
		
		if(!(soslSearch || whereClauses.size() > 0)){
			results.errors.add('No valid search criteria was specified.');
			return results;
		}
		
		Map<String, Set<Id>> soslIDs = new Map<String, Set<Id>>();
		if(soslSearch){
			String soslObjects = '';
			for(String objType : objectTypes){
				if(soslObjects.length() > 0)
					soslObjects += ', ';
				soslObjects += objType + '(Id)';
			}
			
			results.soslQuery = 'FIND \'' + allFieldSearch + '\' IN ALL FIELDS RETURNING ' + soslObjects;
			try{
				List<List<sObject>> soslResults = search.query(results.soslQuery);
				for(Integer i=0; i<soslResults.size(); i++){
					Set<Id> ids = new Set<Id>();
					for(sObject obj : soslResults[i])
						ids.add(obj.Id);
					soslIDs.put(objectTypes[i], ids);
				}
			}
			catch(Exception e){
				results.errors.add(e.getMessage());
				return results;
			}
			
			whereClauses.add('Id in: objIDs');
		}
		
		String selectStart = 'select ' + string.join(new List<String>(fSet), ',') + ' from ';
		String selectEnd = (whereClauses.size() > 0) ? (' where ' + string.join(new List<String>(whereClauses), ' and ')) : '';
		
		Set<String> newFieldSet = new Set<String>(fSet);
		newFieldSet.remove('name');
		newFieldSet.remove('id');
		for(String typeStr : objectTypes){
   			Schema.DescribeSObjectResult ds = objDescribes.get(typeStr);
        	Map<String,Schema.SObjectField> fMap = fieldByObj.get(typeStr);
        	
        	Boolean isValid = true;
        	for(SearchCriterion c : activeCriteria){
        		if(fMap.get(c.fieldName) == null){
        			isValid = false;
        			break;
        		}
        	}
        	
			SearchResultSet objResults = new SearchResultSet(typeStr);
        	if(isValid){
        		Set<Id> objIDs = soslIDs.get(typeStr);
        		if(!soslSearch || objIDs.size() > 0){
					String objSelect = selectStart + typeStr + selectEnd;
					
					results.soqlQueries.add(objSelect);
					try{
						List<sObject> objs = Database.query(objSelect + ' order by name limit 1001');
						objResults.total = objs.size();
						Integer max = objResults.total == 1001 ? 1000 : objResults.total;
						for(Integer i=0; i<max; i++){
							SearchResult result = new SearchResult(string.valueOf(objs[i].get('name')), (Id)objs[i].get('id'));
							for(String str : newFieldSet)
								result.fieldMap.put(str, getFieldValue(objs[i], str));
							objResults.results.add(result);
						}
					}
					catch(Exception e){
						results.errors.add(e.getMessage());
						break;
					}
        		}
        	}
			
			results.resultSets.add(objResults);
		}
		
		system.debug('results: ' + results);
		
		return results;
	}
	
	public static String getFieldValue(sObject obj, String fieldName){
		if(fieldName.contains('.')){
			List<String> sp = fieldName.split('\\.');
			sObject r;
			try{
				r = obj.getsObject(sp[0]);
			}
			catch(Exception e){ }
			if(r == null) return '';
			sp.remove(0);
			return getFieldValue(r, string.join(sp, '.'));
		}
		else
			return (treatNullsAsEmptyString == true && obj.get(fieldName) == null) ? '' : string.valueOf(obj.get(fieldName));
	}
	
	public static void debugQueriesFromResults(AdvancedSearch.SearchResults results){
		if(!string.IsEmpty(results.soslQuery))
			system.debug('SOSL Query: ' + results.soslQuery);
		
		for(String s : results.soqlQueries)
			system.debug('SOQL Query: ' + s);
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_AdvancedSearch(); }
}