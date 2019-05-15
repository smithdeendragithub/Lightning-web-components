public with sharing class DynamicTable extends ApexUtils.SortableClassConfig {
	
	public static final Set<Schema.DisplayType> numericDisplayTypes = new Set<Schema.DisplayType>{Schema.DisplayType.Currency, Schema.DisplayType.Double, Schema.DisplayType.Integer};
	
	private static final String template_hoverLink = '<a href="/{id}" id="{base}_{id}"'
										+ ' onblur="LookupHoverDetail.getHover(\'{base}_{id}\').hide();"'
										+ ' onfocus="LookupHoverDetail.getHover(\'{base}_{id}\', \'/{id}/m?retURL=%2F{base}_{id}&isAjaxRequest=1\').show();"'
										+ ' onmouseout="LookupHoverDetail.getHover(\'{base}_{id}\').hide();"'
										+ ' onmouseover="LookupHoverDetail.getHover(\'{base}_{id}\', \'/{id}/m?retURL=%2F{base}_{id}&isAjaxRequest=1\').show();">{display}</a>';
	
	private static final String markup_paging = '<div width="100%" style="font-weight:normal; position:absolute;">'
										+	'<span width="15%" style="float:left;">{from} - {to} of {total} records</div>'
										+	'<div style="text-align:center;">'
										+		'<a type="button" href="#" onClick="dynamicTable_Page(\'{tableid}\', false); return false;">Previous</a>&nbsp;&nbsp;'
										+		'<a type="button" href="#" onClick="dynamicTable_Page(\'{tableid}\', true); return false;">Next</a>'
										+	'</div>'
										+'</div>';
	
	public static String GetHoverLinkMarkup(String baseID, String specificID, String display){
		return '{!SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(hoverLinkTemplate, "{base}", ' + baseID + '), "{id}", ' + specificID + '), "{display}", ' + display + ')}';
	}

	private static final String defaultStringComparator = '{comp} LIKE \'%{path}%\'';
	private static final List<SelectOption> booleanComparators = new List<SelectOption>{new SelectOption('', '--Any--'), new SelectOption('true', 'Checked'), new SelectOption('false', 'Unchecked')};
	private static final List<SelectOption> relativeComparators = new List<SelectOption>{new SelectOption('=', '='), new SelectOption('!=', '!='), new SelectOption('>', '>'), new SelectOption('>=', '>='), new SelectOption('<', '<'), new SelectOption('<=', '<=')};
	private static final List<SelectOption> stringComparators = new List<SelectOption>{new SelectOption(defaultStringComparator, 'Contains'), new SelectOption('{comp}=\'{path}\'', 'Equals'), new SelectOption('(NOT {comp} LIKE \'%{path}%\')', 'Does not contain')};
	
	public static List<SelectOption> logicDelimiterOptions {
		get{ return new List<SelectOption>{new SelectOption('false', 'OR'), new SelectOption('true', 'AND')}; }
	}
	
	private static final Integer DefaultRecordsPerPage = 25;
	
	private static DynamicVisualforceBuilder dvb;
	private static DynamicVisualforceBuilder b{
		get{
			if(dvb == null)
				dvb = new DynamicVisualforceBuilder();
			return dvb;
		}
	}
	
	public Schema.SObjectType baseObject {get; private set;}
	public ConfigureSection configSection {get; private set;}
	
	private Boolean pagingEnabled {get; set;}
	public Paging paging {get; private set;}
	public String pageName{get; set;}
	public String arg_Mode{get; set;}
    public String caller {get;set;}
	
	public List<CustomColumn> customColumns {get; set;}
	public Map<String, List<CustomLink>> customButtonColumns {get; set;}
	public Map<String, String> customHiddenFields {get; set;}
	public Map<String, List<String>> customPicklistValues {get; set;}
	public Map<String, String> customStyleClass {get; set;}
	
	//Use checkBoxProperty for a sub-property to the collection and checkBoxExpression for one that is a related collection (ex: configs[{0}.Id].isSelected)
	public String checkBoxProperty {get; set;}
	public String checkBoxExpression {get; set;}
	
	public Boolean hoverLinkIDsEnabled {get; set;}
	
	public String id {get; private set;}
	public String selfRef {get; private set;}
	public String collectionExpression {get; private set;}
	public String objNamespace {get; private set;}
	public String userId {get{ return userId = UserInfo.getUserId();} private set;}
	
	public List<SelectOption> selectedFieldOptions {get; private set;}
	public Map<String, Schema.SObjectField> fieldMap {get; private set;}
	
	public String currentFieldConfig {get; set;}

	public DynamicTable(){
		setup('', '', true);
		init();
	}
	
	public DynamicTable(ApexUtils.SortableClassConfig config){	
		setup(config.sortObject, config.sortField, config.sortAscending);
		setup(config.sortObject, config.soqlSortField2, config.soqlSortAscending2);
		init();
	}
	
	private void init(){
		customColumns = new List<CustomColumn>();
		customButtonColumns = new Map<String, List<CustomLink>>();
		customHiddenFields = new Map<String, String>();
		customPicklistValues = new Map<String, List<String>>();
		customStyleClass = new Map<String, String>();
		configSection = new ConfigureSection();
		pagingEnabled = false;
		currentFieldConfig = 'CUSTOM';
		fieldConfigs = new List<SelectOption>();
		if(arg_Mode == '' || arg_Mode == null){
			arg_Mode = 'wsTable'; 
		}		
		hoverLinkIDsEnabled = true;
	}

	public String selectedPLValue = '';
	
	public void EnablePaging(){
		pagingEnabled = true;
		paging = new Paging();
	}
	
	public void BuildConfig(String id, String selfRef, String collectionExpression, String objNamespace, Schema.SObjectType baseObject){
		BuildConfig(id, selfRef, collectionExpression, objNamespace, baseObject, null, null);
	}
	
	public void BuildConfig(String id, String selfRef, String collectionExpression, String objNamespace, Schema.SObjectType baseObject, Set<String> supportedRelationships){
		BuildConfig(id, selfRef, collectionExpression, objNamespace, baseObject, supportedRelationships, null);
	}
	
	public void BuildConfig(String id, String selfRef, String collectionExpression, String objNamespace, Schema.SObjectType baseObject, Set<String> supportedRelationships, Map<String, String> additionalFields){
		this.id = id;
		this.selfRef = selfRef;
		this.collectionExpression = collectionExpression;
		this.objNamespace = objNamespace;
		this.baseObject = baseObject;
		fieldMap = new Map<String, Schema.SObjectField>();
		configSection.parentID = id;
		configSection.parentRef = selfRef;
		
		configSection.Reset();
		
		Schema.DescribeSObjectResult baseDesc = baseObject.getDescribe();
		String baseName = baseDesc.getName().toLowercase();
		Map<String, Schema.SObjectField> baseFields = baseDesc.fields.getMap();
		
		Map<String, String> fPathToName = new Map<String, String>();
		Map<String, String> rPathToName = new Map<String, String>();
		Map<String, String> nameFields = new Map<String, String>{baseName=>mapFields(baseDesc.getLabel(), baseFields, '', fPathToName)};
		
		Set<String> allRelationships = supportedRelationships != null ? new Set<String>(supportedRelationships) : new Set<String>();
		Map<String, Set<String>> additionalFieldsByPath = new Map<String, Set<String>>();
		Map<String, String> addFields = new Map<String, String>();
		for(String k : (additionalFields != null) ? additionalFields.keyset() : new Set<String>()){
			addFields.put(k.toLowercase(), additionalFields.get(k));
			String path = getFieldPath(k).toLowercase();
			
			Set<String> s = additionalFieldsByPath.get(path) != null ? additionalFieldsByPath.get(path) : new Set<String>();
			s.add(k.substring(path.length()+1));
			additionalFieldsByPath.put(path, s);
			
			allRelationships.add(path);
			fPathToName.put(k.toLowercase(), additionalFields.get(k));
		}
		
		for(String r : allRelationships){
			Schema.DescribeFieldResult f = null;
			Schema.DescribeSObjectResult fObj = null;
			Map<String, Schema.SObjectField> m = new Map<String, Schema.SObjectField>(baseFields);
			
			//Crawl the path and find what object we end on and what its fields are
			List<String> parts = r.replace('.', ',').split(',');
			for(Integer i=0; i<parts.size(); i++){
				Boolean found = false;
				for(String fieldStr : m.keyset()){
	        		Schema.DescribeFieldResult fdr = m.get(fieldStr).getDescribe();
	        		if(fdr.getRelationshipName() == parts[i]){
	        			List<Schema.sObjectType> refTo = fdr.getReferenceTo();
	        			
	        			if(refTo.size() > 1) break;
	        			
	        			f = fdr;
	        			fObj = refTo[0].getDescribe();
	        			m = fObj.fields.getMap();
	        			found = true;
	        			break;
	        		}
	        	}
	        	
	        	if(!found){
	        		f = null;
	        		break;
	        	}
			}
			
			if(f != null){
				rPathToName.put(r.toLowercase(), fObj.getName().toLowercase());
				if(supportedRelationships.contains(r))
					nameFields.put(fObj.getName().toLowercase(), mapFields(f.getLabel(), m, r.toLowercase(), fPathToName));
				else if(additionalFieldsByPath.containsKey(r)){
					for(String f2 : additionalFieldsByPath.get(r))
						fieldMap.put((r + '.' + f2).toLowercase(), m.get(f2));
				}
			}
		}
		
		//Correct cases
		Map<String, List<String>> pVals = new Map<String, List<String>>(customPicklistValues);
		customPicklistValues.clear();
		for(String str : pVals.keyset())
			customPicklistValues.put(str.toLowercase(), pVals.get(str));
		
		Map<String, String> style = new Map<String, String>(customStyleClass);
		customStyleClass.clear();
		for(String str : style.keyset())
			customStyleClass.put(str.toLowercase(), style.get(str));
		
		Set<String> unsupported = new Set<String>();
		for(String str : configSection.unsupportedFilterFields)
			unsupported.add(str.toLowercase());
		
		for(String val : fPathToName.keyset()){
			Schema.DescribeFieldResult f = fieldMap.get(val).getDescribe();
			
			//Only show fields the user has access to
			if(f.isAccessible()){
				Schema.DisplayType displayType = f.getType();
				String displayText = null;
				String lbl = f.getLabel();
				
				if(addFields.containsKey(val))
					lbl = addFields.get(val);
				else if(displayType == Schema.DisplayType.ID || displayType == Schema.DisplayType.Reference){
					
					//Get the object's name field for display values
					String path = getFieldPath(val);
					String nameField = nameFields.get(path != '' ? rPathToName.get(path) : baseName);
					
					if(val.endsWith('.ownerid') || val == 'ownerid'){
						displayText = val.substring(0, val.length()-7) + 'owner.name';
						lbl = 'Owner';
					}
					else if((val.endsWith('.id') || val == 'id') && nameField != null){
						displayText = val.substring(0, val.length()-2) + nameField;
						if(val == 'id')
							lbl = baseDesc.getLabel();
					}
					else if(val.endsWith('__c') && nameField != null)
						displayText = val.substring(0, val.length()-3) + '__r.' + nameField;
				}
				
				FieldConfiguration fc = new FieldConfiguration(lbl, fPathToName.get(val), val, displayText, displayType, !unsupported.contains(val));				
				fc.BuildFiltering(f, customPicklistValues.get(val));
				configSection.Add(fc);
			}
		}
	}
	
	public void BuildWhereClauses(List<String> whereClauses){
		
		for(FieldConfiguration fc : configSection.selectedFields){			
			List<String> subWhereClauses = new List<String>();	
		
			String cv = fc.val;
			String cd = fc.displayText;
			for(FieldFilter ff : fc.filters){
				
				String fv = ff.val;
				String fo = ff.option;
			
				try{
					if(fc.filterMode == 1 && !string.IsEmpty(fv))			//String
						ApexUtils.buildWhereClause(subWhereClauses, true, fo.replace('{path}', fv.replace('\'', '\\\'')).replace('{comp}', (!string.isEmpty(cd) ? cd : cv)));
					else if(fc.filterMode == 2){							//Number
						decimal d = decimal.valueOf(fv);
						ApexUtils.buildWhereClause(subWhereClauses, !string.IsEmpty(fv), cv + fo + fv);
					}
					else if(fc.filterMode == 3 || fc.filterMode == 4){		//Date/Datetime
						Date dt = Date.parse(fv);
						String y = string.valueOf(dt.year());
						String m = ((dt.month() < 10 ? '0' : '') + string.valueOf(dt.month()));
						String d = ((dt.day() < 10 ? '0' : '') + string.valueOf(dt.day()));
						
						String dStr = y + '-' + m + '-' + d;
						ff.val = m + '/' + d + '/' + y;
						ApexUtils.buildWhereClause(subWhereClauses, !string.IsEmpty(fv), cv + fo + dStr + (fc.filterMode == 4 ? 'T00:00:00Z' : ''));
					}
					else if(!string.IsEmpty(fo)){
						fo = fo.replace('\'', '\\\'');	//Escape single quotes
						
						if(fc.filterMode == 5)			//Boolean
							ApexUtils.buildWhereClause(subWhereClauses, true, cv + ' = ' + fo);
						else if(fc.filterMode == 6)	{	//Picklist
							ApexUtils.buildWhereClause(subWhereClauses, true, cv + ' = \'' + fo + '\'');
						}
						else if(fc.filterMode == 7)		//MultiPicklist
							ApexUtils.buildWhereClause(subWhereClauses, true, cv + ' includes (\'' + fo + '\')');
					}
				}
				catch(Exception e){ ff.val = ''; }
			}
			if(subWhereClauses.size() > 0){			
				whereClauses.add('(' + string.join(subWhereClauses, fc.isAndCompare == true ? ' AND ' : ' OR ') + ')');
			}		
		}
	}
	
	//Map out the fields via relationship path and return the name field on the object
	private String mapFields(String objLabel, Map<String, Schema.SObjectField> fMap, String rPath, Map<String, String> fPathToName){
		String prefix = objLabel + ': ';
		String fPath = !string.IsEmpty(rPath) ? rPath + '.' : '';
		
		String nameField;
		for(String fName : fMap.keyset()){
			Schema.DescribeFieldResult f = fMap.get(fName).getDescribe();
			
			if(f.isNameField())
				nameField = fName;
			
			fieldMap.put((fPath + fName).toLowercase(), fMap.get(fName));
			fPathToName.put((fPath + fName).toLowercase(), prefix + f.getLabel());
		}
		return nameField;
	}
	
	private String getFieldPath(String fPath){
		List<String> parts = fPath.replace('.', ',').split(',');
		String fPart = parts[parts.size()-1];
		return parts.size() > 1 ? fPath.substring(0, fPath.length() - (fPart.length()+1)) : '';
	}
	
	public String GetSortFieldValue(Boolean primary){
	
		//Don't allow double sorting on the same field
		if(sortField == soqlSortField2)
			soqlSortField2 = null;
		
		FieldConfiguration fc = primary
									? (sortField != null ? configSection.fieldConfigs.get(sortField) : null)
									: (soqlSortField2 != null ? configSection.fieldConfigs.get(soqlSortField2) : null);		
										
		return fc != null ? ((fc.displayText != null ? fc.displayText : fc.val) + ((primary ? sortAscending : soqlSortAscending2) ? ' ASC NULLS FIRST' : ' DESC NULLS LAST')) : null;
	}
	
	public String GetFilterNameValue(){
		String filterName = null;
		FieldConfiguration fc = filterName != null ? configSection.fieldConfigs.get(filterName) : null;
		
		return fc != null ? fc.displayText : ''; //fc.val;
	}
	
	public List<SelectOption> fieldConfigs {get; set;}
	
	public Boolean GetPreselectData(String categoryName, string cid, boolean mainTab){	
		Boolean dFilter = false; 		
		if(mainTab)	{
			if(currentFieldConfig == null){ 
				dFilter = GetCustomListViews(categoryName, null);
			}
			else
				dFilter = GetCustomListViews(categoryName, currentFieldConfig);
				
		}
		return dFilter;	
	}
	
	public Boolean GetCustomListViews(String categoryName, String filterName){ 
		Boolean defFilter = false;	 		
		fieldConfigs = new List<SelectOption>();
		List<Custom_List_View__c> clv = [select Id
        								,Label__c
        								,Category__c
        								,Owner.Name
        								,OwnerId
        								,isDefaultFilter__c
        								from Custom_List_View__c
        								where (OwnerId =: userId) OR (Owner.Name =: 'Integration User')
        								order by OwnerId, Label__c
        								limit 999];

       fieldConfigs.add(new SelectOption('', '--None--'));	        
       for(Custom_List_View__c c : clv){        	     	       	
       	if(c.Owner.Name == 'Integration User' && c.Category__c == categoryName)
       		fieldConfigs.add(new SelectOption(c.Id, '**' + c.Label__c + '**'));
       	else if(c.OwnerId == userId && c.Category__c == categoryName && c.isDefaultFilter__c == true){       		
       		fieldConfigs.add(new SelectOption(c.Id, c.Label__c + ' (Default)'));
       		defFilter = RefreshConfigFromFieldConfig(c.Id);
       	}
       	else if(c.OwnerId == userId && c.Category__c == categoryName){       		
       		fieldConfigs.add(new SelectOption(c.Id, c.Label__c));
       	}
        if(filterName == null && c.Label__c == '')
       		selectedPLValue = c.Id;
       	else if(c.Label__c == filterName)
       		selectedPLValue = c.Id;
       } 
       return defFilter; 								
	}
	
	public Component.Apex.SelectList GetFieldConfigOptions{		
		get{	
			if(currentFieldConfig != '' && currentFieldConfig != 'CUSTOM'){
				selectedPLValue = currentFieldConfig;
			}				
			return b.buildSelectList(false, 1, selectedPLValue, new List<ApexPages.Component>{
				b.buildSelectListOptions('{!' + selfRef + '.fieldConfigs}', null) }
				,new Map<String, String>{ 'id'=>'fieldConfigOptions', 'value'=>'{!' + selfRef + '.currentFieldConfig}', 'onchange'=>'dynamicTable_ConfigChanged("' + id + '");'});	
		}
	}
	
	private transient Component.Apex.DataTable dt {get; set;}
	public transient Set<String> selectFields {get; private set;}
	public Component.Apex.DataTable GetDynamicTable{
		get{
			BuildDynamicTable();		
			return dt;
		}
	}
	
	public void BuildDynamicTable(){
		if(dt == null){
			selectFields = new Set<String>{'id'};
			dt = new Component.Apex.DataTable(var='dtv', id=this.id, cellspacing='0', cellpadding='0', border='0', styleClass='list', headerClass='headerRow');
			dt.expressions.value = collectionExpression;
			
			if(pagingEnabled){
				String expr = '{!SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(pagingMarkup, "{from}", TEXT(' + selfRef + '.paging.RecordsFrom)), "{to}", TEXT(' + selfRef + '.paging.RecordsTo)), "{total}", TEXT(' + selfRef + '.paging.RecordsTotal)), "{tableid}", "' + id + '")}';
				
				dt.facets.header = b.buildOutputPanel(new List<ApexPages.Component>{b.buildOutputText(expr, new Map<String, String>{'escape'=>'false'})}, null);
				dt.facets.footer = b.buildOutputPanel(new List<ApexPages.Component>{b.buildOutputText(expr, new Map<String, String>{'escape'=>'false'})}, null);
			}
		
			dt.childComponents.add(buildDtSystemColumn());
			
			String path = 'dtv.' + (!string.isEmpty(objNamespace) ? objNamespace + '.' : '');
			for(CustomColumn cc : customColumns){
				String rendered = (cc.renderedExpression != null) ? cc.renderedExpression.replace('{0}', 'dtv') : null;
				String styleClass = (cc.styleClassExpression != null) ? (cc.styleClassExpression.startsWith('{!') ? cc.styleClassExpression.replace('{0}', 'dtv') : '{!"' + cc.styleClassExpression + '"}') : null;
				
				dt.childComponents.add(b.buildColumn(new List<ApexPages.Component>{ b.buildOutputText(cc.valExpression.replace('{0}', 'dtv'), new Map<String, String>{'escape'=>'false', 'styleClass'=>styleClass}) }
												,new Map<String, String>{'header'=>cc.text, 'rendered'=>rendered}));
			}
			
			for(FieldConfiguration fc : configSection.selectedFields){			
				String fPath = fc.val;
				selectFields.add(fPath);
				Schema.DescribeFieldResult f1 = fieldMap.get(fPath).getDescribe();
				
				Component.Apex.Column col = new Component.Apex.Column();
				col.facets.header = b.buildOutputPanel(new List<ApexPages.Component>{
														b.buildOutputPanel(new List<ApexPages.Component>{
																b.buildImage('/img/colTitle_uparrow.gif', new Map<String, String>{'rendered'=>'{!' + selfRef + '.sortAscending}'})
																,b.buildImage('/img/colTitle_downarrow.gif', new Map<String, String>{'rendered'=>'{!NOT(' + selfRef + '.sortAscending)}'})
																,new Component.Apex.OutputText(escape=false, value='&nbsp;')
															}
															,new Map<String, String>{'rendered'=>'{!' + selfRef + '.sortField == \'' + fPath + '\'}'})
														,new Component.Apex.OutputText(value=fc.name)
													}
													,fc.isSortable ? new Map<String, String>{'style'=>'cursor:pointer;', 'onclick'=>'dynamicTable_SortColumnClicked("' + this.id + '", "' + fPath + '", ' + (configSection.showSOQLSortControls ? 'true' : 'false') + ');'} : null);
				
				String customStyleVal = customStyleClass.get(fPath);
				String customStyleExpr = (customStyleVal != null)
											? (customStyleVal.startswith('{!') ? customStyleVal.replace('{0}', 'dtv') : '{!' + customStyleVal + '}')
											: null;
				
				Schema.DisplayType displayType = f1.getType();
				if(displayType == Schema.DisplayType.Boolean || displayType == Schema.DisplayType.Date || displayType == Schema.DisplayType.DateTime){
					Component.Apex.OutputField oField = new Component.Apex.OutputField();
					oField.expressions.value = '{!' + path + fPath + '}';
					
					//Custom styling gets lost on certain field types so put it in a panel and style that
					col.childComponents.add(b.buildOutputPanel(new List<ApexPages.Component>{oField}, new Map<String, String>{'styleClass'=>customStyleExpr}));
				}
				else{
					String val;	
					if(displayType == Schema.DisplayType.ID || displayType == Schema.DisplayType.Reference){
						String displayText = !string.isEmpty(fc.displayText) ? fc.displayText : fPath;
						selectFields.add(displayText);
						val = hoverLinkIDsEnabled ? GetHoverLinkMarkup(path + 'Id', path + fPath, path + displayText) : ('<a href="/{!' + path + fPath + '}">{!' + path + displayText + '}</a>');
					}
					else
						val = '{!' + path + fPath + '}';
					
					col.childComponents.add(b.buildOutputText(val, new Map<String, String>{'escape'=>'false', 'styleClass'=>customStyleExpr}));
				}
				
				dt.childComponents.add(col);
			}
			
			for(String n : customButtonColumns.keyset()){
				Component.Apex.Column col = new Component.Apex.Column(headerValue=n);
				
				for(CustomLink lnk : customButtonColumns.get(n)){
					Component.Apex.OutputLink l = new Component.Apex.OutputLink();
					l.expressions.value = lnk.valExpression.replace('{0}', 'dtv');
					
					if(lnk.styleClassExpression != null)
						l.expressions.styleClass = lnk.styleClassExpression.startsWith('{!') ? lnk.styleClassExpression.replace('{0}', 'dtv') : '{!"' + lnk.styleClassExpression + '"}';
					
					if(!string.IsEmpty(lnk.renderedExpression))
						l.expressions.rendered = lnk.renderedExpression.replace('{0}', 'dtv');
					
					l.childComponents.add(new Component.Apex.OutputText(value=lnk.text));
					l.childComponents.add(new Component.Apex.OutputText(value='<br/>', escape=false));
					col.childComponents.add(l);
				}
				
				dt.childComponents.add(col);
			}
		}
	}
	
	private Component.Apex.Column buildDtSystemColumn(){
		Component.Apex.Column col = new Component.Apex.Column();
		Component.Apex.OutputPanel hPanel = new Component.Apex.OutputPanel();
		if(!string.isEmpty(checkBoxProperty) || !string.isEmpty(checkBoxExpression)){
			hPanel.childComponents.add(new Component.Apex.OutputText(escape = false, value = '<input type="checkbox" onclick="checkAll(this);"/>'));
			col.childComponents.add(b.buildInputCheckbox(!string.isEmpty(checkBoxExpression) ? checkBoxExpression.replace('{0}', 'dtv') : '{!dtv.' + checkBoxProperty + '}', new Map<String, String>{'id'=>'chkSelected'}));
		}
		else
			col.width = '0px';
		
		col.facets.header = hPanel;
		
		if(!configSection.showSOQLSortControls)
			b.setStandardValues(col, new List<ApexPages.Component>{b.buildInputText('{!' + selfRef + '.sortField}', new Map<String, String>{'id'=>'sortField', 'style'=>'display:none'})
																,b.buildInputText('{!' + selfRef + '.sortAscending}', new Map<String, String>{'id'=>'sortAscending', 'style'=>'display:none'})
																,b.buildInputText('{!' + selfRef + '.soqlSortField2}', new Map<String, String>{'id'=>'soqlSortField2', 'style'=>'display:none'})
																,b.buildInputText('{!' + selfRef + '.soqlSortAscending2}', new Map<String, String>{'id'=>'soqlSortAscending2', 'style'=>'display:none'})}
															,null);
		
		for(String k : customHiddenFields.keyset()){	
			col.childComponents.add(b.buildOutputText('{!dtv.' + customHiddenFields.get(k) + '}', new Map<String, String>{'style'=>'display:none', 'id'=>k}));
		}
		return col;
	}
	
	/* Filter handling */
	private class filterStructureRoot{
		public String primarySortField {get; set;}
		public Boolean primarySortASC {get; set;}
		public String secondarySortField {get; set;}
		public Boolean secondarySortASC {get; set;}
		public String filterStructure {get; set;}
		public String personalFilterName {get; set;}
		public List<filterStructureField> fieldSet {get; set;}
	}
	
	private class filterStructureField{
		public String path {get; set;}
		public String displayName {get; set;}
		public Boolean isAndCompare {get; set;}
		public List<filterStructureFilter> filters {get; set;}
	}
	
	private class filterStructureFilter{
		public Integer num {get; set;}
		public String option {get; set;}
		public String val {get; set;}
	}

	public Boolean RefreshConfigFromFieldConfig(Id fieldConfigID){					
        currentFieldConfig = string.valueOf(fieldConfigID); 
              
        List<Custom_List_View__c> clv = [select Id
        								,Filter_Structure__c
        								,Primary_Sort_ASC__c
        								,Primary_Sort_Field__r.Field_Path__c
        								,Secondary_Sort_ASC__c
        								,Secondary_Sort_Field__r.Field_Path__c
        								,isDefaultFilter__c
        								from Custom_List_View__c
        								where Id =: fieldConfigID
        								limit 1];
   
        if(clv.size() == 0) return false;
      
		filterStructureRoot root = new filterStructureRoot();
		root.primarySortField = clv[0].Primary_Sort_Field__r.Field_Path__c;		
		root.primarySortASC = clv[0].Primary_Sort_ASC__c;
		root.secondarySortField = clv[0].Secondary_Sort_Field__r.Field_Path__c;
		root.secondarySortASC = clv[0].Secondary_Sort_ASC__c;
		root.filterStructure = clv[0].Filter_Structure__c;

		root.fieldSet = new List<filterStructureField>();
		for(Custom_List_View_Field__c clvf : [select Id
        												,Display_Name__c
        												,Field_Path__c
        												,isAndCompare__c
        												,(select Id
        														,Filter_Number__c
        														,Filter_Option__c
        														,Filter_Value__c
        														from Custom_Filters__r
        														order by Filter_Number__c ASC)
        												from Custom_List_View_Field__c
        												where Custom_List_View__c =: fieldConfigID order by Column_Order__c ASC]){
			filterStructureField f = new filterStructureField();
			f.path = clvf.Field_Path__c;
			f.displayName = clvf.Display_Name__c;
			f.isAndCompare = clvf.isAndCompare__c;
			f.filters = new List<filterStructureFilter>();
						
			for(Custom_List_View_Filter__c ff : clvf.Custom_Filters__r){
				filterStructureFilter fil = new filterStructureFilter();
				fil.num = Integer.valueOf(ff.Filter_Number__c);				
				fil.option = ff.Filter_Option__c;
				fil.val = ff.Filter_Value__c == 'Today' ? String.valueOf(Date.today().format()) : ff.Filter_Value__c;
				f.filters.add(fil);
			}	
					
			root.fieldSet.add(f);
		}					
		RefreshConfig(root);		
        return true;
	}
	
	private void RefreshConfig(filterStructureRoot root){						
		List<String> selectFields = new List<String>();
		List<FieldConfiguration> fConfig = new List<FieldConfiguration>();
			 sortField = root.primarySortField;
			 sortAscending = root.primarySortASC;
			 soqlSortField2 = root.secondarySortField;	 
			 soqlSortAscending2 = root.secondarySortASC;
			 filterName = root.personalFilterName;
			 			 
				for(filterStructureField csf : root.fieldSet){					
					String p = csf.path.toLowercase();					
					FieldConfiguration fc = configSection.fieldConfigs.get(p);
				
					if(fc != null){
						selectFields.add(p); 						
						fc.name = csf.DisplayName != null ? csf.DisplayName : fc.standardName;
						fc.isAndCompare = csf.isAndCompare;					
						fc.filters = new List<FieldFilter>();
							for(filterStructureFilter ff : csf.filters){ 								
								FieldFilter fil = new FieldFilter();
								fil.num = ff.num;
								fil.val = ff.val;
								fil.option = ff.option;								
								fc.filters.add(fil);								
							}								
						fConfig.add(fc);								
					}
				}				
		//we clear previous selection at this point and load only new selectedField config	
				configSection.deselectedVals = new List<String>();
				
				for(Integer i=configSection.selectedFields.size()-1; i>=0; i--){				
						configSection.availableFields.add(configSection.selectedFields[i]);
						configSection.availableOptions.add(configSection.selectedOptions[i]);					
						configSection.selectedFields.remove(i);
						configSection.selectedOptions.remove(i);					
				}
				
		configSection.Move(false);								
		configSection.UpdateOptions(selectFields);
	}

	public void SaveFieldConfigToCustomListView(string fName, string fOwner, string mode){
		List<String> wc = new List<String>();
		BuildWhereClauses(wc);

		List<Custom_List_View_Filter__c> sFilters = new List<Custom_List_View_Filter__c>();
		String tabMode = mode == 'wsTable' ? 'WorkstepManagement' : (mode == 'wsiTable' ? 	'WorkstepIssue' : 'CustomerTouchPoint');			
			Custom_List_View__c clv = new Custom_List_View__c();
			clv.Label__c = fName;
			clv.OwnerId = fOwner;
			clv.Object__c = tabMode == 'wsTable' ? 'Workstep__c' : (tabMode== 'WorkstepIssue' ? 'Workstep_Issue__c' : 'CustomerTouchPoint');
			clv.Category__c = tabMode;
			/*clv.Primary_Sort_Field__c = sortField;
			clv.Primary_Sort_ASC__c = sortAscending;
			clv.Secondary_Sort_Field__c = soqlSortField2;
			clv.Secondary_Sort_ASC__c = soqlSortAscending2;*/
			insert clv;
						
			for(FieldConfiguration fc : configSection.selectedFields){														
				Custom_List_View_Field__c f = new Custom_List_View_Field__c();
				f.Field_Path__c = fc.val;
				f.Display_Name__c = fc.name;
				f.Column_Order__c = fc.tablePosition;
				f.Custom_List_View__c = clv.Id;
				f.IsAndCompare__c = fc.isAndCompare;				
				insert f;
				for(FieldFilter ff : fc.filters){					
					Custom_List_View_Filter__c fil = new Custom_List_View_Filter__c();
					fil.Filter_Number__c = ff.num;
					fil.Filter_Value__c = ff.val;
					fil.Filter_Option__c = ff.option;
					fil.Custom_List_View_Field__c = f.Id;
					sFilters.add(fil);									
				}
			}
			insert sFilters;
			
			if(sortField != null){
				List<Custom_List_View_Field__c> cfld = [Select Id, Name, Field_Path__c From Custom_List_View_Field__c Where Custom_List_View__c =: clv.Id];
				for(Custom_List_View_Field__c fld : cfld){
					if(sortField == fld.Field_Path__c){
						clv.Primary_Sort_Field__c = fld.Id;
						clv.Primary_Sort_ASC__c = sortAscending;						
					}	
					if(soqlSortField2 != null && soqlSortField2 == fld.Field_Path__c){
						clv.Secondary_Sort_Field__c = fld.Id;
						clv.Secondary_Sort_ASC__c = soqlSortAscending2;						
					}
				}
				update clv;

			}
			GetCustomListViews(tabMode, fName);									
	}
	
	public virtual class DynamicTableController{

		public Component.Apex.OutputPanel sharedDynamicComponents { get {
			List<String> dataTables = new List<String>(tables.keyset());
			List<String> configTables = new List<String>();
			for(String t : dataTables)
				configTables.add('config_' + t);
			
			String addRerenderTargets = ',fieldConfigOptions';
			Component.Apex.OutputPanel op = b.buildOutputPanel(new List<ApexPages.Component>{
																		b.buildActionFunction('addRemoveDynamicFiltering', new Map<String, String>{'action'=>'{!AddRemoveFilter}', 'rerender'=>string.join(configTables, ',') + addRerenderTargets, 'status'=>'loadingStatus'})
																		,b.buildActionFunction(callerName+'updateDynamicPaging', new Map<String, String>{'action'=>'{!UpdatePage}', 'rerender'=>string.join(dataTables, ',') + addRerenderTargets, 'status'=>'loadingStatus'})
																		,b.buildActionFunction('updateDynamicSorting', new Map<String, String>{'action'=>'{!UpdateSorting}', 'rerender'=>string.join(dataTables, ',') + addRerenderTargets,  'status'=>'loadingStatus'})
																		,b.buildActionFunction('updateDynamicFieldConfig', new Map<String, String>{'action'=>'{!UpdateFieldConfig}', 'rerender'=>string.join(configTables, ',')  + ',' + string.join(dataTables, ',') + addRerenderTargets, 'status'=>'loadingStatus'})																		
																		,b.buildActionFunction('SaveFieldConfigsToCustomObjs', new Map<String, String>{'action'=>'{!SaveDynamicFiltering}', 'rerender'=>string.join(dataTables, ',') + ',' + string.join(configTables, ',') + addRerenderTargets, 'status'=>'loadingStatus'})
																		,b.buildInputText('{!arg_Mode}', new Map<String, String>{'id'=>'arg_Mode'})
																		,b.buildInputText('{!filterArg_Add}', new Map<String, String>{'id'=>'filterArg_Add'})
																		,b.buildInputText('{!filterArg_FieldPath}', new Map<String, String>{'id'=>'filterArg_FieldPath'})
																		,b.buildInputText('{!filterArg_Num}', new Map<String, String>{'id'=>'filterArg_Num'})
																		,b.buildInputText('{!filterArg_Name}', new Map<String, String>{'id'=>'filterArg_Name'})
																		,b.buildInputText('{!pageArg_Next}', new Map<String, String>{'id'=>'pageArg_Next'})
																}, new Map<String, String>{'style'=>'display:none;'});
		
			return op;
		}}
		
		public Map<String, DynamicTable> tables {get; set;}
	
		public String hoverLinkTemplate { get{ return DynamicTable.template_hoverLink; } }
		public String pagingMarkup { 
            get{ 	if (callerName != '') {
            			return DynamicTable.markup_paging.replace('dynamicTable_Page(', 'dynamicTable_Page(\'' + callerName + '\',');    	
            		} else {
                        return DynamicTable.markup_paging;
                    } 
            } 
        }
		
		public DynamicTableController(){
			tables = new Map<String, DynamicTable>();
			newCSL = new Custom_List_View__c();
            callerName = '';
		}
        
        public String callerName {get;set;}
		
		public String arg_Mode {get; set;}
		
		public Boolean filterArg_Add {get; set;}
		public String filterArg_FieldPath {get; set;}
		public String filterArg_Num {get; set;}
		public String filterArg_Name {get; set;}

		public Boolean pageArg_Next {get; set;}
		public Custom_List_View__c newCSL {get; set;}
		public void AddRemoveFilter(){					
			if(tables.get(arg_Mode) != null){
				FieldConfiguration fc = tables.get(arg_Mode).configSection.fieldConfigs.get(filterArg_FieldPath);											
				if(fc != null){
					if(filterArg_Add == true) fc.AddFilter();					
					else if(filterArg_Num != null) fc.RemoveFilter(Integer.valueOf(filterArg_Num));					
				}
			}
		}
		
		public void DynamicTableRefreshed(string mode){
			DynamicTable dt = tables.get(mode);
			string p = string.valueOf(ApexPages.currentPage());
			string pg = p.substringBefore('?').substringAfter('/');
	 		string pageName = pg.substringAfter('/');	
			
			if(dt != null){
				if(dt.configSection.isDirty == true){					
					dt.RefreshConfigFromFieldConfig(dt.currentFieldConfig);						
					FieldConfigChanged(mode);	
				}				
			}		
		}
		
		public void UpdateColumnSelection() {
			String mode = ApexPages.currentPage().getParameters().get('mode');
			
			DynamicTable dt = tables.get(mode);
			if(dt != null){
				Boolean add = ApexPages.currentPage().getParameters().get('add') == 'true';
				dt.configSection.deselectedVals = new List<String>();
				
				if(!add){
					dt.configSection.selectedVals = new List<String>();
					for(Integer i=0; i<dt.configSection.selectedFields.size(); i++){
						if(dt.configSection.selectedFields[i].isSelected)
							dt.configSection.deselectedVals.add(dt.configSection.selectedFields[i].val);
					}
				}				
				dt.configSection.UpdateOptions();
			}
		}
		
		public String RemoveSavedFilter(String categoryName, String mode) {									
			DynamicTable dt = tables.get(mode);						
			List<Custom_List_View_Field__c> clvField = new List<Custom_List_View_Field__c>();
			List<Custom_List_View_Filter__c> clvFilter = new List<Custom_List_View_Filter__c>();
			
			if(dt != null && dt.configSection != null){
				String currentSelectedFilter = dt.currentFieldConfig;

				Custom_List_View__c clview = [select Id, OwnerId from Custom_List_View__c where Id =: currentSelectedFilter Limit 1];
				String userId = UserInfo.getUserId();
					   
				if(userId == clview.OwnerId){						
					Custom_List_View__c clv = new Custom_List_View__c();
					for(Custom_List_View_Field__c clvf : [select Id
		        												,(select Id
		        														from Custom_Filters__r
		        														order by Filter_Number__c ASC)
		        												from Custom_List_View_Field__c
		        												where Custom_List_View__c =: currentSelectedFilter]){		
							
						for(Custom_List_View_Filter__c ff : clvf.Custom_Filters__r){
							clvFilter.add(ff);
						}
							clvField.add(clvf);									
		        	} 		        	       					
				delete clvFilter;
				delete clvField;
				delete clview;			        									
        		}
        		else{
        		//error msg can't delete saved filters you don't own.
        		return 'You can only delete filters you own';	
        		}
        		//try calling this method from WMP page itself and passing catagory name at least. Then call
        		//dt.GetCustomListViews(categoryName, null);        						
				//dt.configSection.UpdateOptions();				
			}

			return '';
		}
		
		public String SetDefaultFilter(String categoryName, String mode) {									
			DynamicTable dt = tables.get(mode);						

			if(dt != null && dt.configSection != null){
				List<Custom_List_View__c> cstmlv = new List<Custom_List_View__c>();
				String userId = UserInfo.getUserId();
				String currentSelectedFilter = dt.currentFieldConfig;

				List<Custom_List_View__c> clview = [select Id, isDefaultFilter__c, OwnerId from Custom_List_View__c where (OwnerId =: userId And isDefaultFilter__c =: true And Category__c =: categoryName) Or Id =: currentSelectedFilter];
				for(Custom_List_View__c clv : clview){
					if(clv.Id == currentSelectedFilter)
						clv.isDefaultFilter__c = true;
					else
						clv.isDefaultFilter__c = false;
						
					cstmlv.add(clv);
				}
				
				update cstmlv;	   			
			}

			return '';
		}
		
		public void UpdatePage(){		
			if(tables.get(arg_Mode) != null){
				tables.get(arg_Mode).paging.UpdateCurrentPage(pageArg_Next);		
				PageUpdated(arg_Mode);
			}
		}
		
		public void UpdateSorting(){
			if(tables.get(arg_Mode) != null){
				SortChanged(arg_Mode);
			}
		}
		
		public void UpdateFieldConfig(){
			DynamicTable dt = tables.get(arg_Mode);								
			dt.RefreshConfigFromFieldConfig(dt.currentFieldConfig);								
			FieldConfigChanged(arg_Mode);			
		}	

		public void setMode(string mode){
			arg_Mode = mode;
		}

		public void SaveDynamicFiltering() { 
			//This is where Salesforce Licensed users can create canned filter "views" for worksteps 		   
        	string newFilterName = FilterArg_Name;
        	string newFilterOwner = UserInfo.getUserId();  
        	DynamicTable dt = tables.get(arg_Mode);
      	      	
        	//Save table filters to Custom_List_View
			dt.SaveFieldConfigToCustomListView(newFilterName, newFilterOwner, arg_Mode);
			UpdateFieldConfig();
    	}
    
		public virtual void PageUpdated(String mode){ }
		
		public virtual void SortChanged(String mode){ }
		
		public virtual void FieldConfigChanged (String mode){}
	}
	
	public virtual class CustomColumn{
		public String text {get; set;}
		public String valExpression {get; set;}
		public String renderedExpression {get; set;}
		public String styleClassExpression {get; set;}
		
		public CustomColumn(){ }
		
		public CustomColumn(String text, String valExpression, String renderedExpression, String styleClassExpression){
			this.text = text;
			this.valExpression = valExpression;
			this.renderedExpression = renderedExpression;
			this.styleClassExpression = styleClassExpression;		
		}
	}
	
	public class CustomLink extends CustomColumn{
		public CustomLink(String text, String linkExpression, String renderedExpression){
			this.text = text;
			this.valExpression = linkExpression;
			this.renderedExpression = renderedExpression;
		}
	}
	
	public class FieldFilter{
		public Integer num {get; set;}
		public String val {get; set;}
		public String option {get; set;}
		
		public FieldFilter() { }
	}
	
	public class FieldConfiguration{
		public String standardName {get; private set;}
		public String name {get; set;}
		public String optionName {get; private set;}
		public String val {get; private set;}
		public String displayText {get; private set;}
		public Schema.DisplayType fieldType {get; set;}
		public SelectOption selectOption {get; private set;}
		
		public Boolean isSortable {get; private set;}
		
		public Boolean isFilterable {get; private set;}
		public Integer filterMode {get; private set;}	//0: none, 1: text, 2: number, 3: date, 4: datetime
		public List<FieldFilter> filters {get; private set;}
		public Boolean isAndCompare {get; set;}
		
		//Comparator or value picklist (depending on field)
		public List<SelectOption> filterOptions {get; private set;}
		public Boolean presetFilterValues {get; set;}
		
		public Integer tablePosition {get; set;}	//Used by ConfigureSection to move up or down
		public Boolean isSelected {get; set;}
		
		public FieldConfiguration(String standardName, String optionName, String val, String displayText, Schema.DisplayType fieldType, Boolean allowFilter){
			this.standardName = standardName;
			this.name = standardName;
			this.optionName = optionName;
			this.val = val;		
			this.displayText = displayText;
			this.fieldType = fieldType;		
			selectOption = new SelectOption(val, optionName);		
			isSelected = false;
			isFilterable = allowFilter;
			isSortable = fieldType != Schema.DisplayType.TextArea;
			filters = new List<FieldFilter>();
		}
		
		public FieldFilter AddFilter(){
			FieldFilter f = new FieldFilter();
			if(filterMode == 1)
				f.option = defaultStringComparator;
			else if(filterMode >= 2 && filterMode <= 4)
				f.option = '=';
			else
				f.option = '';
			filters.add(f);
			
			UpdateFilterNumbers();
			return f;
		}
		
		public void RemoveFilter(Integer num){
			for(Integer i=filters.size()-1; i>=0; i--){
				if(filters[i].num == num)
					filters.remove(i);
			}
			UpdateFilterNumbers();
		}
		
		private void UpdateFilterNumbers(){
			for(Integer i=0; i<filters.size(); i++)
				filters[i].num = i+1;
		}
		
		public void BuildFiltering(Schema.DescribeFieldResult f, List<String> customPicklistValues){			
			filterMode = 0;
			presetFilterValues = false;
			
			if(!string.IsEmpty(displayText) || fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.Email || fieldType == Schema.DisplayType.Phone)
				buildFiltering(1, false, stringComparators);
			else if(numericDisplayTypes.contains(fieldType) || fieldType == Schema.DisplayType.Date || fieldType == Schema.DisplayType.DateTime)
				buildFiltering(numericDisplayTypes.contains(fieldType) ? 2 : (fieldType == Schema.DisplayType.Date ? 3 : 4), false, relativeComparators);
			else if(fieldType == Schema.DisplayType.Boolean)
				buildFiltering(5, true, booleanComparators);
			else if(fieldType == Schema.DisplayType.Picklist || fieldType == Schema.DisplayType.MultiPicklist){
				List<SelectOption> l = new List<SelectOption>{new SelectOption('', '--Any--')};
				if(customPicklistValues != null){					
					for(String pv : customPicklistValues)
						l.add(new SelectOption(pv, pv));
				}
				else{
					for(Schema.PicklistEntry pe : f.getPicklistValues()){
						String pLabel = pe.getLabel();
						if(!String.IsEmpty(pLabel)) l.add(new SelectOption(pLabel, pLabel));
					}
				}
				buildFiltering((fieldType == Schema.DisplayType.Picklist) ? 6 : 7, true, l);
			}
			
			isAndCompare = !presetFilterValues;				
			isFilterable = isFilterable && filterMode != 0;
		}
		
		private void buildFiltering(Integer f, Boolean p, List<SelectOption> l){
			filterMode = f;			
			presetFilterValues = p;		
			filterOptions = l;
		}
	}
	
	public class ConfigureSection{
		public Map<String, FieldConfiguration> fieldConfigs {get; private set;}
		
		public List<FieldConfiguration> availableFields {get; private set;}
		public List<SelectOption> availableOptions {get; private set;}
		public List<String> selectedVals {get; set;}
		
		public List<FieldConfiguration> selectedFields {get; private set;}
		public List<SelectOption> selectedOptions {get; private set;}
		public List<String> deselectedVals {get; set;}
		
		public String filterStructure {get; set;}
		
		public String parentID {get; private set;}
		public String parentRef {get; private set;}
		public Boolean isDirty {get; set;}
		public Set<String> unsupportedFilterFields {get; set;}
		public Boolean showRowPositionControls {get; set;}
		public Boolean showSOQLSortControls {get; set;}

		public ConfigureSection(){
			Reset();
			unsupportedFilterFields = new Set<String>();
			showRowPositionControls = false;
			showSOQLSortControls = false;
		}
		
		public void Reset(){
			fieldConfigs = new Map<String, FieldConfiguration>();
			availableFields = new List<FieldConfiguration>();
			availableOptions = new List<SelectOption>();
			selectedVals = new List<String>();
			selectedFields = new List<FieldConfiguration>();
			selectedOptions = new List<SelectOption>();
			deselectedVals = new List<String>();
		}
		
		public void Add(FieldConfiguration fConfig){					
			availableFields.add(fConfig);
			availableOptions.add(new SelectOption(fConfig.val, fConfig.optionName));
			fieldConfigs.put(fConfig.val, fConfig);					
		}
		
		public List<SelectOption> SortingSelectOptions{
			get{
				List<SelectOption> l = new List<SelectOption>(selectedOptions);
				if(l.size() > 0)
					l.add(0, new SelectOption('', '--None--'));
				return l;
			}
		}
		
		public void UpdateOptions(List<String> selectedVals){	
			for(String f : selectedVals)
				f = f.toLowercase();				
			this.selectedVals = selectedVals;
															
			UpdateOptions();
		}
		
		public void UpdateOptions(){
			move(true);
			move(false);
			
			//Set the table positions
			for(Integer i=0; i<selectedFields.size(); i++){					
				selectedFields[i].tablePosition = i;	
			}
					
			//Sort available fields			
			List<FieldConfiguration> l = new List<FieldConfiguration>(availableFields);	 					
			availableFields.clear();
			availableOptions.clear();
			
			List<String> strL = new List<String>();
			for(FieldConfiguration fc : l){		
				strL.add(fc.optionName);
			}
			strL = new List<String>(new Set<String>(strL));		//distinct it
			strL.sort();
			
			for(String s : strL){				
				for(FieldConfiguration fc : l){					
					if(fc.optionName == s){
						availableFields.add(fc);										
						availableOptions.add(new SelectOption(fc.val, fc.optionName));
					}
				}
			}
							
		}
		
		public void VerifySelectionOrder(){
			
			Map<Integer, FieldConfiguration> fList = new Map<Integer, FieldConfiguration>();
			Map<Integer, SelectOption> oList = new Map<Integer, SelectOption>();
			
			Boolean sorted = true;							
			for(Integer i=0; i<selectedFields.size(); i++){									
				sorted &= (selectedFields[i].tablePosition == i);				
				fList.put(selectedFields[i].tablePosition, selectedFields[i]);
				oList.put(selectedFields[i].tablePosition, selectedOptions[i]);			
			}						
			if(!sorted){
				List<Integer> sortFList = new List<Integer>();
				List<Integer> sortOList = new List<Integer>();
				sortFList.addAll(fList.keySet());
				sortFList.sort();
				sortOList.addAll(oList.keySet());
				sortOList.sort();

				selectedFields.clear();
				selectedOptions.clear();
				for(Integer i : sortFList){
					FieldConfiguration nfc = fList.get(i);					
					SelectOption nso = oList.get(i);				
					selectedFields.add(fList.get(i));
					selectedOptions.add(oList.get(i));
				}
			}						
		}
		
		private void move(Boolean adding){
			List<FieldConfiguration> fList = adding ? selectedFields : availableFields;
			List<SelectOption> oList = adding ? selectedOptions : availableOptions;
			List<FieldConfiguration> fRList = adding ? availableFields : selectedFields;
			List<SelectOption> oRList = adding ? availableOptions : selectedOptions;
			List<String> vList = adding ? selectedVals : deselectedVals;

			for(String v : vList){				
				for(Integer i=fRList.size()-1; i>=0; i--){
					if(fRList[i].val == v){						
						fList.add(fRList[i]);
						oList.add(oRList[i]);
						fRList.remove(i);
						oRList.remove(i);
					}
				}
			}
		}
		
		private transient Component.Apex.DataTable dt {get; set;}
		public Component.Apex.DataTable GetSelectedTable{
			get{
				if(dt == null){
					dt = new Component.Apex.DataTable(var='f', id='config_' + parentID, cellspacing='0', cellpadding='0', border='0', styleClass='list', headerClass='headerRow');
					dt.expressions.value = '{!' + parentRef + '.configSection.selectedFields}';				
					Component.Apex.Column col = b.buildColumn(new List<ApexPages.Component>{b.buildInputCheckbox('{!f.isSelected}', new Map<String, String>{'id'=>'chkSelected'})}
														,null
														,b.buildOutputPanel(new List<ApexPages.Component>{new Component.Apex.OutputText(escape=false, value = '<input type="checkbox" onclick="checkAll(this);"/>')
														,b.buildOutputPanel(new List<ApexPages.Component>{b.buildInputCheckbox('{!' + parentRef + '.configSection.isDirty}', new Map<String, String>{'id'=>'isDirty', 'style'=>'display: none;'})}, new Map<String, String>{ 'style'=>'visibility: hidden;'})}, null));
					dt.childComponents.add(col);
					
					if(showRowPositionControls){
						col = b.buildColumn(new List<ApexPages.Component>{
																	b.buildInputText('{!f.tablePosition}', new Map<String, String>{'id'=>'tableposval', 'style'=>'display:none;'})
																	,b.buildImage('/img/arrow_up.gif', new Map<String, String>{'style'=>'cursor:pointer;', 'onclick'=>'dynamicTable_MoveConfigRow(jQuery(this), true);'})
																	,b.buildImage('/img/arrow_dwn.gif', new Map<String, String>{'style'=>'cursor:pointer;', 'onclick'=>'dynamicTable_MoveConfigRow(jQuery(this), false);'})
																}, null);
						dt.childComponents.add(col);
					}
					
					b.setStandardValues(col, new List<ApexPages.Component>{b.buildOutputText('{!f.standardName}', new Map<String, String>{'id'=>'standardName', 'style'=>'display: none;'})}, null);
					
					dt.childComponents.add(b.buildColumn(new List<ApexPages.Component>{b.buildOutputText('{!f.optionName}', null)}, new Map<String, String>{'header'=>'Option Name'}));
					dt.childComponents.add(b.buildColumn(new List<ApexPages.Component>{b.buildInputText('{!f.name}', new Map<String, String>{'onchange'=>'dynamicTable_setMode("' + parentId + '");'})}, new Map<String, String>{'header'=>'Display Name'}));
					
					/* Build filters sub-table */
					Component.Apex.DataTable fDt = new Component.Apex.DataTable(var='filter');
					fDt.expressions.value = '{!f.filters}';			
					fDt.expressions.rendered = '{!f.isFilterable}';
					
					//Comparator column
					fDt.childComponents.add(b.buildColumn(new List<ApexPages.Component>{b.buildSelectList(false, 1, new List<ApexPages.Component>{b.buildSelectListOptions('{!f.filterOptions}', null)}, new Map<String, String>{'value'=>'{!filter.option}'})}
														,new Map<String, String>{'rendered'=>'{!NOT(ISNULL(f.filterOptions))}'}));
					
					//Value column
					fDt.childComponents.add(b.buildColumn(new List<ApexPages.Component>{b.buildInputText('{!filter.val}', new Map<String, String>{'id'=>'dateval', 'rendered'=>'{!f.filterMode == 3 || f.filterMode == 4}', 'onfocus'=>'DatePicker.pickDate(false, this, false);'})
																					,b.buildInputText('{!filter.val}', new Map<String, String>{'rendered'=>'{!NOT(f.filterMode == 3 || f.filterMode == 4)}'})}
														,new Map<String, String>{'rendered'=>'{!NOT(f.presetFilterValues)}'}));
					
					//Remove column
					fDt.childComponents.add(b.buildColumn(new List<ApexPages.Component>{
															b.buildOutputText('<a type="button" href="#" onClick="dynamicTable_AddRemoveFilter(false, \'' + parentID + '\', \'{!f.val}\', \'{!filter.num}\'); return false;">Remove</a>', new Map<String, String>{'escape'=>'false'})
														}, null));
					
					fDt.facets.footer = b.buildOutputPanel(new List<ApexPages.Component>{
															b.buildOutputText('<a type="button" href="#" onClick="dynamicTable_AddRemoveFilter(true, \'' + parentID + '\', \'{!f.val}\', 0); return false;">Add filter</a>', new Map<String, String>{'escape'=>'false'})
															,b.buildSelectList(false, 1, new List<ApexPages.Component>{b.buildSelectListOptions('{!logicDelimiterOptions}', null)}, new Map<String, String>{'value'=>'{!f.isAndCompare}', 'rendered'=>'{!NOT(f.presetFilterValues) && f.filters.size > 1}', 'style'=>'float:right;'})
														}, null);
					/* End filters sub-table */
					
					dt.childComponents.add(b.buildColumn(new List<ApexPages.Component>{fDt
																					,b.buildOutputText('{!"Not supported"}', new Map<String, String>{'rendered'=>'{!NOT(f.isFilterable)}'})}
														,new Map<String, String>{'header'=>'Filters'}));
					
					Component.Apex.OutputPanel footer = b.buildOutputPanel(null, null);
					if(showSOQLSortControls){
						footer.childComponents.add(b.buildOutputPanel(new List<ApexPages.Component>{
																		buildSortingRow('Sort by', 'sortField', 'sortAscending')
																		,new Component.Apex.OutputText(value='<br/>', escape=false)
																		,buildSortingRow('then by', 'soqlSortField2', 'soqlSortAscending2')
																		,new Component.Apex.OutputText(value='<br/><br/>', escape=false)
																		,new Component.Apex.OutputText(value='Name Filter Config: ', escape=false)
																		,new Component.Apex.OutputText(value='<input type="textbox" id="personalFilterArg_Name"/>', escape=false)
																		,new Component.Apex.OutputText(value='<a type="button" href="#" onClick="dynamicTable_SaveFilterConfig(\'' + parentID + '\', this); return false;">Save My Page Setup Selections</a>',  escape=false)															
																	}, new Map<String, String>{'style'=>'float:right;'}));
					}
					dt.facets.footer = footer;
				}
													
				return dt;
			}
		}
		
		private Component.Apex.OutputPanel buildSortingRow(String sortTxt, String val, String ascVal){
			return b.buildOutputPanel(new List<ApexPages.Component>{
										new Component.Apex.OutputText(value=sortTxt + ': ')
										,b.buildSelectList(false, 1, new List<ApexPages.Component>{
																				b.buildSelectListOptions('{!' + parentRef + '.configSection.SortingSelectOptions}', null) }
																			,new Map<String, String>{'id'=>val, 'value'=>'{!' + parentRef + '.' + val + '}'})
										,b.buildSelectList(false, 1, new List<ApexPages.Component>{
																				new Component.Apex.SelectOption(itemLabel='ASC', itemValue=true)
																				,new Component.Apex.SelectOption(itemLabel='DESC', itemValue=false) }
																			,new Map<String, String>{'id'=>ascVal, 'value'=>'{!' + parentRef + '.' + ascVal + '}'})
									}, null);
		}
	}
	
	public class Paging{
		public Integer CurrPage { get; set; }
		public Integer MaxPage { get; set; }
		public Integer RecordsTotal { get; set; }
		public Integer RecordsPerPage { get; set; }
		public Integer RecordsFrom { get { return RecordsTotal > 0 ? CurrPage * RecordsPerPage + 1:0; } }
		public integer RecordsTo { get { return Math.Min((CurrPage + 1) * RecordsPerPage, RecordsTotal); } }
		
		public Paging(){
			RecordsPerPage = DefaultRecordsPerPage;
			Reset(0, true);
		}
		
		public void Reset(Integer recordCount, Boolean resetPage){
			RecordsTotal = recordCount;
			MaxPage = (recordCount > 0) ? ((recordCount - 1) / RecordsPerPage) : 0;
			if(resetPage)
				CurrPage = 0;
			else if(CurrPage > MaxPage)
				CurrPage = MaxPage;
		}
		
		public List<sObject> GetPagedsObjectList(List<sObject> allList){
			List<sObject> l = new List<sObject>();
			for (integer i = CurrPage * RecordsPerPage; i < allList.size() && i < (CurrPage + 1) * RecordsPerPage; i++)
				l.add(allList.get(i));
			return l;
		}
		
		public void UpdateCurrentPage(Boolean next){
			if (next && CurrPage < MaxPage)
				CurrPage++;
			else if (!next && CurrPage > 0)
				CurrPage--;
		}		
	}
}