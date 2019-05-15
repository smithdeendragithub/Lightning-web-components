public without sharing class SchemaUtils{
	
	public static String GetLookupLabel(sObjectType t, String fName){
		Schema.SObjectField f = t.getDescribe().fields.getMap().get(fName.toLowerCase());
		Schema.DescribeFieldResult dfr = f != null ? f.getDescribe() : null;
		List<sObjectType> refs = dfr != null ? dfr.getReferenceTo() : null;
		String refName = refs != null && refs.size() == 1 ? GetNameField(refs[0]) : null;
		return !string.IsEmpty(refName) ? (dfr.getRelationshipName() + '.' + refName) : null;
	}
	
	public static String GetName(sObjectType t){
		return t.getDescribe().getName();
	}
	
	public static String GetNameField(sObjectType t){
		for(Schema.SObjectField f : t.getDescribe().fields.getMap().values()){
			Schema.DescribeFieldResult dfr = f.getDescribe();
			if(dfr.isNameField()) return dfr.getName();
		}
		
		return null;
	}
	
	public static List<SelectOption> GetPicklistValues(Schema.SObjectField f, Boolean addBlank){
		List<SelectOption> l = new List<SelectOption>();
		if(addBlank) l.add(new SelectOption('', ''));
		for(Schema.PicklistEntry pe : f.getDescribe().getPicklistValues()){
			String pLabel = pe.getLabel();
			if(!String.IsEmpty(pLabel)) l.add(new SelectOption(pLabel, pLabel));
		}
		return l;
	}

    private static Map<String, String> sObjectNameByID;
    public static String GetSObjectNameByID(Id id){
    	if(id == null) return null;
    	
    	String idString = string.valueof(id);
    	
    	if(sObjectNameByID == null)
    		sObjectNameByID = new Map<String, String>();
    	if(sObjectNameByID.get(idString) == null)
    		sObjectNameByID.put(idString, idPrefixToObjectName.get(idString.subString(0,3)));
    		
		return sObjectNameByID.get(idString);
    }
    
    public static Schema.SObjectType GetSObjectTypeByID(Id id){
    	String name = GetSObjectNameByID(id);
    	return string.IsEmpty(name) ? null : Schema.getGlobalDescribe().get(name);
    }
	
	public static sObjectType GetType(String name){
		return Schema.getGlobalDescribe().get(name);
	}
    
    private static Map<String, String> idPrefixToObjectNameMap;
    private static Map<String, String> idPrefixToObjectName{
    	get{
    		if(idPrefixToObjectNameMap == null)
    			populatePrefixNameMaps();
	        
	        return idPrefixToObjectNameMap;
    	}
    }
	
	public static Boolean IsStringField(sObjectType t, String fName){
		Schema.SObjectField f = t.getDescribe().fields.getMap().get(fName.toLowerCase());
		return f != null && f.getDescribe().getType() == DisplayType.String;
	}
    
    private static Map<String, String> objectNameToIDPrefixMap;
    public static Map<String, String> ObjectNamesToIDPrefixes{
    	get{
    		if(objectNameToIDPrefixMap == null)
    			populatePrefixNameMaps();
	        
	        return objectNameToIDPrefixMap;
    	}
    }
    
    private static void populatePrefixNameMaps(){
    	idPrefixToObjectNameMap = new Map<String, String>{};
    	objectNameToIDPrefixMap = new Map<String, String>{};
    	
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for(String key : globalDescribe.keySet()){
            Schema.DescribeSObjectResult result =  globalDescribe.get(key).getDescribe();
            idPrefixToObjectNameMap.put(result.getKeyPrefix(), result.getName());
            objectNameToIDPrefixMap.put(result.getName(), result.getKeyPrefix());
        }
    }
    
    private static Map<String, Map<String, Schema.Describefieldresult>> objectFields = new Map<String,Map<String, Schema.Describefieldresult>>();
    public static Map<String, Schema.Describefieldresult> RetrieveFullObjectFieldDescribeMap(sObjectType objType){
        Schema.Describesobjectresult r = objType.getDescribe(); 
        
        if (!objectFields.containsKey(r.getName())){
        	Map<String, Schema.SObjectField> m = r.fields.getMap();
        	Map<String,Schema.Describefieldresult> val = new Map<String,Schema.Describefieldresult>();
        	for(String k : m.keyset())
        		val.put(k, m.get(k).getDescribe());
			
			//These fields are not useful and do not exist on all objects but will still come back as part of the describe;
			for(String f : new List<String>{ 'LastReferencedDate', 'LastViewedDate' })
				val.remove(f.toLowercase());
			
            objectFields.put(r.getName(), val);
        }
        
        return objectFields.get(r.getName());
    }
    
    public static String RetrieveFullObjectFields(sObjectType objType) {
		return string.join(new List<String>(RetrieveFullObjectFieldSet(objType)), ', ');
    }
    
    public static Set<String> RetrieveFullObjectFieldSet(sObjectType objType){
    	Set<String> retval = new Set<String>();
      	
        Map<String, Schema.Describefieldresult> fieldMap = retrieveFullObjectFieldDescribeMap(objType);
        for (String key :  fieldMap.keySet())
            retval.add(fieldMap.get(key).getName());
                  
        return retval;
    }
}