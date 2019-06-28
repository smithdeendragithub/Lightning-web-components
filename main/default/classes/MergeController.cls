public with sharing class MergeController implements TestUtils.ITestableClass {
	
	public final String pageError {get; set;}
	
	public final String sObjectType {get; set;}
	public final sObjectType t {get; set;}
	public final String nameField {get; set;}
	
	public class sObjectWrapper{
		public sObject obj {get; set;}
		public String name {get; set;}
		public String id {get; set;}
		public Boolean isReadOnly {get; set;}
		public Boolean initialized {get; set;}
		public String selfRef {get; set;}
		
		public sObjectWrapper(){
			name = 'None selected';
			initialized = false;
			searchResults = new List<AdvancedSearch.SearchResult>();
		}
		
		public List<AdvancedSearch.SearchResult> searchResults {get; set;}
		public String allSearch {get; set;}
	}
	
	public sObjectWrapper o1 {get; set;}
	public sObjectWrapper o2 {get; set;}
	
	public List<sObjectWrapper> objs {get; set;}
	
	public Map<String, String> searchableFields {get; set;}
	public List<String> selectedFields {get; set;}
	public List<SelectOption> fieldOptions {get; set;}
	
	public MergeController(){
		String sObjType = ApexPages.currentPage().getParameters().get('objectType');
		
		t = sObjType != null ? Schema.getGlobalDescribe().get(sObjType) : null;
		if(t == null)
			pageError = 'ObjectType parameter "' + sObjType + '" is not valid';
		else{
			sObjType = t.getDescribe().getName();
			fieldOptions = new List<SelectOption>();
			
			searchableFields = AdvancedSearch.getValidSearchFields(new List<String>{sObjType});
			for(String k : searchableFields.keySet()){
				//todo: add other label field support
				if(k == 'name')
					nameField = 'name';
				else
					fieldOptions.add(new SelectOption(k, searchableFields.get(k)));
			}
			fieldOptions.sort();
			
			o1 = new sObjectWrapper();
			o1.isReadOnly = true;
			o1.selfRef = 'o1';
			o2 = new sObjectWrapper();
			o2.isReadOnly = false;
			o2.selfRef = 'o2';
			objs = new List<sObjectWrapper>{o1, o2};
		}
		
		sObjectType = sObjType;
	}
	
	public ApexPages.Component getDisplay{
		get{
			if(t == null) return null;
			
			List<ApexPages.Component> body = new List<ApexPages.Component>();
			
			Schema.DescribeSObjectResult d = t.getDescribe();
			Map<String, Schema.SObjectField> fMap = d.fields.getMap();
			List<String> fields = new List<String>(fMap.keyset());
			fields.sort();
			
			for(String k : fields){
				for(sObjectWrapper o : objs){
					Schema.DescribeFieldResult f = fMap.get(k).getDescribe();
					String fPath = '{!' + o.selfRef + '.obj[\'' + k + '\']}';
					if(!f.isUpdateable() || o.isReadOnly){
						Component.Apex.OutputField c = new Component.Apex.OutputField();
						c.expressions.value = fPath;
						body.add(c);
					}
					else{
						Component.Apex.InputField c = new Component.Apex.InputField();
						c.expressions.value = fPath;
						body.add(c);
					}
				}
			}
			
			Component.Apex.PageBlockSection pbs = new Component.Apex.PageBlockSection(columns=2);
			pbs.childComponents.addAll(body);
			return pbs;
		}
	}
	
	public Integer objNum {get; set;}
	public void search(){
		sObjectWrapper o = objs[objNum];
		
		Set<String> fields = new Set<String>();
		if(nameField != null)
			fields.add(nameField);
		if(selectedFields != null)
			fields.addAll(selectedFields);
		
		AdvancedSearch.treatNullsAsEmptyString = true;
		AdvancedSearch.SearchResults sr = AdvancedSearch.search(o.allSearch, new List<AdvancedSearch.SearchCriterion>(), new List<String>{sObjectType}, fields, null);
		o.searchResults = sr.resultSets.size() > 0 ? sr.resultSets[0].results : new List<AdvancedSearch.SearchResult>();
	}
	
	public String objID {get; set;}
	public void selectObj(){
		sObjectWrapper o = objs[objNum];
		sObjectWrapper other = (o == o1) ? o2 : o1;
		if(objID == other.id){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select two different objects'));
			return;
		}
		
		Map<String, String> validSearchFields = AdvancedSearch.getValidSearchFields(new List<String>{sObjectType});
		for(sObject x : Database.query('select ' + string.join(new List<String>(SchemaUtils.RetrieveFullObjectFieldSet(t)), ',') + ' from ' + sObjectType + ' where Id =: objID')){
			o.obj = x;
			o.initialized = true;
			o.id = x.Id;
			o.name = validSearchFields.containsKey('name') ? string.valueOf(x.get('name')) : x.id;
		}
	}
	
	public PageReference mergeObjs(){
		Boolean failed = false;
		
		try{
			Schema.DescribeSObjectResult d = t.getDescribe();
			
			//Chunk them together by object type so they can be saved together
			Map<String, Map<Id, sObject>> childObjs = new Map<String, Map<Id, sObject>>();
			for(Schema.ChildRelationship cr : d.getChildRelationships()){
				DescribeFieldResult fDesc = cr.getField().getDescribe();
				Schema.DescribeSObjectResult child = cr.getChildSObject().getDescribe();
				if(fDesc.isUpdateable() && child.isQueryable() && child.isUpdateable()){
					String f = fDesc.getName();
					String childObjName = child.getName();
					Map<Id, sObject> m = childObjs.get(childObjName) != null ? childObjs.get(childObjName) : new Map<Id, sObject>();
					for(sObject o : Database.query('select Id from ' + childObjName + ' where ' + f + ' = \'' + o1.id + '\'')){
						sObject obj = m.get(o.Id) != null ? m.get(o.Id) : o;
						o.put(f, o2.id);
						m.put(o.id, obj);
					}
					
					if(m.size() > 0) childObjs.put(childObjName, m);
				}
			}
			
			for(String childObjName : childObjs.keyset())
				update childObjs.get(childObjName).values();
			
			update o2.obj;
			delete o1.obj;
		}
		catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			failed = true;
		}
		
		return !failed ? new PageReference('/' + o2.id) : null;
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_Merge(); }
}