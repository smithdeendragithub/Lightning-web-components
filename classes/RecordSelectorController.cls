public with sharing class RecordSelectorController extends DynamicTable.DynamicTableController implements TestUtils.ITestableClass{
	
	public class Config{
		public String sObjectType { get; set; }
		public String Fields { get; set; }
		public Boolean MultiSelect { get; set; }
		
		public Config(){ }
		public Config(sObjectType t, Boolean multiSelect){
			this.MultiSelect = multiSelect;
			sObjectType = SchemaUtils.GetName(t);
		}
	}
	
	public Boolean objectAccessible { get; set; }
	
	public Boolean multiSelect { get; set; }
	public Boolean useRecent { get; set; }
	public Boolean viewAllMode { get; set; }
	public String filter { get; set; }
	
	private String sot { get; set; }
	public String sObjType {
		get{ return sot; }
		set{
			if(sot != value){
				filter = '';
				sot = value;
				defaultFieldMode = false;
				cWhere = '';
				
				if(string.isEmpty(sot)) dt = null;
			}
		}
	}
	
	private Boolean defaultFieldMode { get; set; }
	private Map<String, List<String>> ofMap { get; set; }
	public String objFields {
		get{ return ''; }
		set{
			ofMap = ofMap != null ? ofMap : new Map<String, List<String>>();
			if(!string.isEmpty(sot)){
				String oldVal = (defaultFieldMode == true) ? 'DEFAULT' : (ofMap.get(sot) != null ? String.join(ofMap.get(sot), ',') : '');
				if(!string.isEmpty(value) && oldVal != value){
					defaultFieldMode = value == 'DEFAULT';
					if(defaultFieldMode){
						String d = CustomSettingUtils.getSingleProcessConfigurationValue('RecordSelector', sot, false);
						ofMap.put(sot, !string.isEmpty(d) ? string.valueOf(d).split(',') : new List<String>{ 'Id' });
					}
					else ofMap.put(sot, string.valueOf(value).split(','));
					rebuildDataTable();
				}
			}
		}
	}
	
	private String cWhere {get; set;}
	public String customWhere {
		get{ return cWhere; }
		set{
			if(!string.isEmpty(sot) && cWhere != value){
				cWhere = value;
				rebuildDataTable();
			}
		}
	}
	
	public sObjectType t {get; set;}
	public String tLabel {get; set;}
	
	public DynamicTable dt { get; set; }
	
	public Map<String, List<sObject>> records { get; set; }
	public Map<Id, sObjectConfig> recordConfigs { get; set; }
	
	public class sObjectConfig{
		public Id recordID { get; set; }
		public Boolean isSelected { get; set; }
		
		public sObjectConfig(Id recordID){
			this.recordID = recordID;
			isSelected = false;
		}
		
		public Boolean noConfig(){
			return !isSelected;
		}
	}
	
	public List<Id> objIDs {get;set;}
	public Boolean objIDsAreValid {get;Set;}
	public Boolean useSosl {get;Set;}
	
	public RecordSelectorController(){
		objectAccessible = false;
		viewAllMode = true;
        callerName = 'recordSel';
	}
	
	private void rebuildDataTable(){
		
		if(sot != null && ofMap != null && ofMap.get(sot) != null && ofMap.get(sot).size() > 0){
			t = sot != null ? Schema.getGlobalDescribe().get(sot) : null;
			if(t == null)
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'ObjectType parameter "' + sot + '" is not valid'));
			else if(SecurityUtils.checkObjectAccess(t, true, true)){
				objectAccessible = true;
				sot = SchemaUtils.GetName(t);
				tLabel = SchemaUtils.GetNameField(t);
				
				dt = new DynamicTable();
				dt.EnablePaging();
				dt.hoverLinkIDsEnabled = false;
				dt.paging.RecordsPerPage = 10;
				dt.configSection.showRowPositionControls = true;
				dt.configSection.showSOQLSortControls = false;
				
				//Checkboxes vs select buttons
				if(multiSelect == true) dt.checkBoxExpression = '{!recordConfigs[{0}.Id].isSelected}';
				else dt.customColumns = new List<DynamicTable.CustomColumn>{new DynamicTable.CustomColumn('', '{!"<input type=\'button\' class=\'btn\' value=\'Select\' onclick=\'recordSelector_select(this);\'/>"}', null, null)};
				
				dt.customHiddenFields = new Map<String, String>{'recordID'=>'Id', 'label'=>tLabel};
				dt.BuildConfig('dtSelector', 'dt', '{!records[\'' + sot + '\']}', '', t, null);
				System.debug('ofList' + ofMap.get(sot));
				dt.configSection.UpdateOptions(ofMap.get(sot));
				refreshDataTable(true);
				
				tables = new Map<String, DynamicTable>{'dtSelector'=>dt};
			}
		}
	}
	
	public void refreshDataTable(Boolean resetPage){
		dt.configSection.VerifySelectionOrder();
		dt.BuildDynamicTable();
		
		String objName = SchemaUtils.GetName(dt.baseObject);
		
		List<String> whereClauses = new List<String>();
		System.debug('fields' + dt.selectFields);
		String soql = 'SELECT ' + string.join(new List<String>(dt.selectFields), ',') + ' FROM ' + objName;
		if(!String.isEmpty(cWhere)) whereClauses.add(cWhere);
		if(!String.isEmpty(filter)){
			Set<String> subWhereClauses = new Set<String>();
			for(String f : dt.selectFields){
				String f2 = (f == 'id')
								? (!String.isEmpty(tLabel) && tLabel != 'id' ? tLabel : null)
								: (SchemaUtils.IsStringField(dt.baseObject, f)
									? f
									: SchemaUtils.GetLookupLabel(dt.baseObject, f));
				if(!String.isEmpty(f2)) subWhereClauses.add(f2 + ' like \'%' + filter + '%\'');
			}
			if(subWhereClauses.size() > 0) whereClauses.add('(' + string.join(new List<String>(subWhereClauses), ' or ') + ')');
		}
		dt.BuildWhereClauses(whereClauses);
		
		String orderBy = null;
		String primary = dt.GetSortFieldValue(true);
		if(!string.isEmpty(primary)){
			String secondary = dt.GetSortFieldValue(false);
			orderBy = primary + (!string.isEmpty(secondary) ? (', ' + secondary) : '');
		}
		
		Set<Id> selectedIDs = new Set<Id>();
		recordConfigs = recordConfigs != null ? recordConfigs : new Map<Id, sObjectConfig>();
		for(Id id : new List<Id>(recordConfigs.keySet())){
			if(SchemaUtils.GetSObjectNameByID(id) != sot) continue;
			
			if(recordConfigs.get(id).noConfig())
				recordConfigs.remove(id);
			else if(recordConfigs.get(id).isSelected) selectedIDs.add(id);
		}
		if(!viewAllMode) whereClauses.add('Id in: selectedIDs');
		
		Set<Id> rvSet = new Set<Id>();
		if(whereClauses.size() == 0 && useRecent){
			rvSet = (new Map<Id, RecentlyViewed>([select Id from RecentlyViewed where Type =: objName])).keyset();
			whereClauses.add('Id in: rvSet');
		}
		if(objIDs != null)
			whereClauses.add('Id ' + (objIDsAreValid ? '' : 'not ') + 'in :objIDs');
		
		soql += (whereClauses.size() > 0 ? ' WHERE ' + string.join(whereClauses, ' AND ') : '') + (orderBy != null ? (' order by ' + orderBy) : '');
		
		List<sObject> rList = new List<sObject>();
		
		
		
		try{
			
			System.debug('Executing query: ' + soql);
			
			if(useSosl && !String.isEmpty(filter)){
				String searchQuery = 'FIND \'' + filter + '\' IN ALL FIELDS RETURNING ' +   objName + ' (' + string.join(new List<String>(dt.selectFields), ',') + ') ';
				List<List <sObject>> searchList = search.query(searchQuery);
				rList = searchList[0];
			}
			else
				rList = Database.query(soql + ' limit 1000');
		}
		catch(Exception e){
			System.debug('Query Exception: ' + e.getMessage());
		}
		dt.paging.Reset(rList.size(), resetPage);
		rList = dt.paging.GetPagedsObjectList(rList);
		
		records = records != null ? records : new Map<String, List<sObject>>();
		records.put(sot, rList);
		
		for(sObject obj : rList){
			if(recordConfigs.get(obj.Id) == null)
				recordConfigs.put(obj.Id, new sObjectConfig(obj.Id));
		}
	}
	
	public void Reset(){
		//recordConfigs = new Map<Id, sObjectConfig>();
		viewAllMode = true;
		refreshDataTable(true);
	}
	
	public void ToggleViewMode(){
		viewAllMode = !viewAllMode;
		refreshDataTable(true);
	}
	
	public transient String selection{ get; set; }
	public void GatherSelection(){
		List<String> selectedIDs = new List<String>();
		for(Id id : recordConfigs != null ? recordConfigs.keySet() : new Set<Id>()){
			if(recordConfigs.get(id).isSelected)
				selectedIDs.add(id);
		}
		selection = '{records:[' + (selectedIDs.size() > 0 ? ('"' + String.join(selectedIDs, '","') + '"') : '') + ']}';
	}
	
	public override void PageUpdated(String mode){
		refreshDataTable(false);
	}
	
	public override void SortChanged(String mode){
		refreshDataTable(true);
	}
	
	/* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_RecordSelector(); }
}