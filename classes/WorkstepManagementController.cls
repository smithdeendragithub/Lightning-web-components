public class WorkstepManagementController extends DynamicTable.DynamicTableController implements TestUtils.ITestableClass {
    
    public boolean isWorkstepTabVisible { get; set; }
    public boolean isOrdersIOwnVisible { get; set; }

    public String userId;
    public string filterName {get;set;}
    public string filterOwnerName {get;set;}
    
    public String blockWorkstepLinkTemplate { get; set; }
    public Boolean ownedWorkstepsOnly { get; set; }
    public Boolean isDefaultFilter { get; set; }
    public Boolean hasCustomListViewCreate{
    get { return Schema.sobjecttype.Custom_List_View__c.isCreateable(); }
    set { hasCustomListViewCreate = Schema.sobjecttype.Custom_List_View__c.isCreateable(); }
    }
    public final Map<String, List<DynamicTable.CustomLink>> wsCustomColumns = new Map<String, List<DynamicTable.CustomLink>>{
                    'Actions'=>new List<DynamicTable.CustomLink>{new DynamicTable.CustomLink('Block Workstep', '/apex/NewWorkstepIssue?id={!{0}.workstep.Id}', '{!{0}.workstep.Status__c == \'Open\' || {0}.workstep.Status__c == \'Blocked\'}')
                                                    ,new DynamicTable.CustomLink('View Predecessors', '/apex/NewPredecessor?id={!{0}.workstep.Id}&wmp=true', null)}
                    };
    
    public class WSFilterParams{
        public DynamicTable config { get; set; }
        
        public Workstep__c ws { get; set; }
        
        public String ctx { get; set; }
        
        public WSFilterParams() {
            ws = new Workstep__c(OwnerId = UserInfo.getUserId());
            config = new DynamicTable();
            config.configSection.showRowPositionControls = true;
            config.configSection.showSOQLSortControls = true;
        }
    }
    
    private class wsGroupConfiguration{
        public String slVal { get; set; }
        public String queryClause { get; set; }
        public String orderByClause { get; set; }
        
        public wsGroupConfiguration(String slVal, String queryClause, String orderByClause){
            this.slVal = slVal;
            this.queryClause = queryClause;
            this.orderByClause = orderByClause;
        }
    }
    
    public class WorkstepWrapper {
        public Workstep__c workstep { get; set; }
        public String error {get; private set;}
        public boolean isSelected { get; set; }
        public boolean isPastDue { get; private set; }
        public boolean canComplete { get; private set; }
        public boolean isDirty { get; set; }
        
        public WorkstepWrapper(Workstep__c ws, Boolean isSelected, String error) {
            workstep = ws;
            this.isSelected = isSelected;
            this.error = error;
            isPastDue = ws.Status__c != WorkstepUtils.STATUS_COMPLETE && ws.Status__c != WorkstepUtils.STATUS_CANCELLED && ws.End_Date__c < Date.today();
            canComplete = ws.Status__c == WorkstepUtils.STATUS_OPEN;
            isDirty = false;
        }
    }
    
    public final List<wsGroupConfiguration> wsGroupConfigurations = new List<wsGroupConfiguration>{
                                                                        new wsGroupConfiguration('Open Worksteps Blocked/Past Due Worksteps', '(Status__c = \'Blocked\' OR (End_Date__c < TODAY AND Status__c !=\'Complete\'))', null)
                                                                        ,new wsGroupConfiguration('Open Worksteps on Expedited Sub-Orders', '(Status__c != \'Complete\' AND Sub_Order__r.Expedited__c = true)', null)
                                                                        ,new wsGroupConfiguration('Open Worksteps at 80%+ of Expected completion date', 'X80_Start_Date__c < TODAY AND Status__c != \'Complete\'', null)
                                                                        ,new wsGroupConfiguration('All other open worksteps by due date in descending order', '(NOT ( (Status__c = \'Blocked\' OR End_Date__c < TODAY) OR (Status__c != \'Complete\' AND Sub_Order__r.Expedited__c = true) OR X80_Start_Date__c < TODAY )) AND Status__c != \'Complete\'', 'End_Date__c desc')
                                                                    };
    
    public final List<SelectOption> validWorkstepStatusList = new List<SelectOption>{
        new SelectOption('', '-- All --')
        ,new SelectOption(WorkstepUtils.STATUS_BLOCKED, WorkstepUtils.STATUS_BLOCKED)
        ,new SelectOption(WorkstepUtils.STATUS_CANCELLED, WorkstepUtils.STATUS_CANCELLED)
        ,new SelectOption(WorkstepUtils.STATUS_COMPLETE, WorkstepUtils.STATUS_COMPLETE)
        ,new SelectOption(WorkstepUtils.STATUS_INTEGRATE, WorkstepUtils.STATUS_INTEGRATE)
        ,new SelectOption(WorkstepUtils.STATUS_INTEGRATE_FAIL, WorkstepUtils.STATUS_INTEGRATE_FAIL)
        ,new SelectOption(WorkstepUtils.STATUS_OPEN, WorkstepUtils.STATUS_OPEN)
        ,new SelectOption(WorkstepUtils.STATUS_PENDING, WorkstepUtils.STATUS_PENDING)
    };
    
    public String selectedFilter { get; set; }

    public Workstep__c assignWS { get; set; }
    
    public WSFilterParams wsParams { get; set; }
    public WSFilterParams wsiParams { get; set; }
    
    public List<WorkstepWrapper> wsWrapperList { get; private set; }
    public List<Workstep_Issue__c> wsIssuesList { get; private set; }
    
    public String currentOrderId;
    public String currentSubOrderId;
    
    public List<SelectOption> workstepFilterDisplayList { get; set; }
    
    public final List<String> wsStatusList = new List<String>{ WorkstepUtils.STATUS_OPEN, WorkstepUtils.STATUS_COMPLETE, WorkstepUtils.STATUS_PENDING, WorkstepUtils.STATUS_BLOCKED, WorkstepUtils.STATUS_CANCELLED, WorkstepUtils.STATUS_INTEGRATE_FAIL }; 
    
    private final List<String> defaultWSFields = new List<String>{'Id', 'Order__r.Account_Link__c', 'Sub_Order__r.Location__c', 'Order__c', 'Sub_Order__c', 'Sub_Order__r.External_Order__c', 'Sub_Order__r.SPC_Product__r.Name', 'Start_Date__c', 'End_Date__c', 'Lag__c', 'Duration__c', 'SLA__c', 'Sub_Order__r.Expedited__c', 'Access_Types__r.Name', 'Status__c', 'OwnerId'};
    private final List<String> defaultWSIFields = new List<String>{'Id','Workstep__c', 'Workstep__r.Order__c', 'Workstep__r.Sub_Order__c', 'Status__c', 'Risk_Type__c', 'Work_Group__c', 'Comments__c', 'OwnerId'};
    
    public WorkstepManagementController() {
        Map<String,String> params = ApexPages.currentPage().getParameters();
        currentOrderId = params.get('orderId');
        currentSubOrderId = params.get('subOrderId');
        userId = UserInfo.getUserId();
        blockWorkstepLinkTemplate = CustomSettingUtils.getSingleProcessConfigurationValue('CustomLink', 'BlockWorkstep', false);
        string currentPage = ApexPages.currentPage().getUrl().toLowerCase();        

        assignWS = new Workstep__c();
        /*
        wsParams = new WSFilterParams();
        wsParams.config.EnablePaging();
        wsParams.config.configSection.unsupportedFilterFields = new Set<String>{'OwnerId', 'Order__c', 'Sub_Order__c'};
        wsParams.config.customPicklistValues = new Map<String, List<String>>{ 'Status__c'=>wsStatusList };
        wsParams.config.customStyleClass = new Map<String, String>{'End_Date__c'=>'{!IF({0}.isPastDue, "errored", "")}'};
        wsParams.config.BuildConfig('wsTable', 'wsParams.config', '{!wsWrapperList}', 'workstep', Workstep__c.getSObjectType(), new Set<String>{'Sub_Order__r', 'Sub_Order__r.External_Order__r', 'Order__r'}, 
                                    new Map<String, String>{'Sub_Order__r.Service_Location__r.Customer_Detail__r.Market_Type__r.Name'=>'Market Type', 
                                    'Sub_Order__r.Service_Location__r.Customer_Detail__r.Market_Area__r.Name'=>'Market Area',
                                    'Sub_Order__r.Service_Location__r.Customer_Detail__r.Care_Organization__r.Name'=>'Care Organization',
                                    'Sub_Order__r.Service_Location__r.Location__r.Building__r.State__c'=>'Location State'});
        if(!wsParams.config.GetPreselectData('WorkstepManagement', 'WorkstepManagement_wsTable', true)){                    
            wsParams.config.configSection.UpdateOptions(defaultWSFields);
        }
        wsParams.config.checkBoxProperty = 'isSelected';
        wsParams.config.customButtonColumns = wsCustomColumns;
        wsParams.config.customColumns = new List<DynamicTable.CustomColumn>{new DynamicTable.CustomColumn('Errors', '{!{0}.error}', '{!wsErrored}', 'errored')};
        wsParams.config.customHiddenFields = new Map<String, String>{'canComplete'=>'canComplete', 'isPastDue'=>'isPastDue'};
        
        wsiParams = new WSFilterParams();
        //wsiParams.config.EnablePaging();
        wsiParams.config.configSection.unsupportedFilterFields = new Set<String>{'OwnerId', 'Status__c'};
        wsiParams.config.customPicklistValues = new Map<String, List<String>>{ 'Workstep__r.Status__c'=>wsStatusList };
        wsiParams.config.BuildConfig('wsiTable', 'wsiParams.config', '{!wsIssuesList}', '', Workstep_Issue__c.getSObjectType(), new Set<String>{'Workstep__r', 'Workstep__r.Sub_Order__r', 'Workstep__r.Sub_Order__r.External_Order__r', 'Workstep__r.Order__r'});
        if(!wsiParams.config.GetPreselectData('WorkstepIssue', 'WorkstepManagement_wsiTable', true)){
            wsiParams.config.configSection.UpdateOptions(defaultWSIFields);
        }
	
        tables = new Map<String, DynamicTable>{'wsTable'=>wsParams.config};
        
        ownedWorkstepsOnly = true;
        //wsiParams.ctx = 'WORKSTEP_OWNER';
        wsParams.ctx = 'ANY';

        Sub_Order__c ctxSO = !string.IsEmpty(currentSubOrderId) ? [SELECT Id, Name, Order__c FROM Sub_Order__c WHERE Id = :currentSubOrderId limit 1] : null;
        Order__c ctxO = !string.IsEmpty(currentOrderId)
                            ? [SELECT Id, Name FROM Order__c WHERE Id = :currentOrderId limit 1]
                            : (ctxSO != null ? [SELECT Id, Name FROM Order__c WHERE Id = :ctxSO.Order__c limit 1] : null);
        if(ctxSO != null){
            wsParams.ws.Sub_Order__c = ctxSO.Id;
            wsParams.ctx = 'BY_SUBORDER';
        }
        if(ctxO != null){
            wsParams.ws.Order__c = ctxO.Id;
            if(ctxSO == null){
                wsParams.ctx = 'BY_ORDER';
            }
        }
        */
        loadwsParams();
        isWorkstepTabVisible = CustomSettingUtils.currentUserHasCustomPermission('WsMgPage_Workstep_Issues_Visible__c');
        isOrdersIOwnVisible = CustomSettingUtils.currentUserHasCustomPermission('WsMgPage_Owned_Orders_Visible__c');
        
        //reselectWorkstepIssues();
        //reselectWorksteps(true);
    }
    
    public List<SelectOption> getCompareList() {
        return new List<SelectOption>{new SelectOption('=','='), new SelectOption('<','<'), new SelectOption('>','>')};
    }
    
    public void reselectWorksteps() {
        //DynamicTableRefreshed('wsTable');
        reselectWorksteps(true);
    } 
    
    public void reselectWorksteps(Boolean resetPage) {
        WSFilterParams p = wsParams;        
        List<String> whereClauses = new List<String>();
        
        Boolean defaultContext = true;
        defaultContext &= !ApexUtils.buildWhereClause(whereClauses, p.ctx == 'OWNED_ORDERS', 'Order__r.OwnerId = \'' + userId + '\'');
        defaultContext &= !ApexUtils.buildWhereClause(whereClauses, p.ws.Order__c != null && p.ctx == 'BY_ORDER', 'Order__c = \'' + p.ws.Order__c + '\'');
        defaultContext &= !ApexUtils.buildWhereClause(whereClauses, p.ws.Sub_Order__c != null && p.ctx == 'BY_SUBORDER', 'Sub_Order__c = \'' + p.ws.Sub_Order__c + '\'');
            
        if(ApexUtils.buildWhereClause(whereClauses, p.ws.OwnerId != null && p.ctx == 'BY_OWNER', 'OwnerId = \'' + p.ws.OwnerId + '\'')){
            defaultContext = false;
            ownedWorkstepsOnly = false;
        }
        else if(defaultContext){
            p.ctx = 'ANY';
            ownedWorkstepsOnly = true;
        }
            
        ApexUtils.buildWhereClause(whereClauses, ownedWorkstepsOnly, 'OwnerId = \'' + userId + '\'');
        
        for(wsGroupConfiguration c : wsGroupConfigurations){                        
            if(ApexUtils.buildWhereClause(whereClauses, selectedFilter == c.slVal, c.queryClause))
                break;
        }
    
        List<Workstep__c> wsList = (List<Workstep__c>)reselectObjects(p.config, whereClauses, new Set<String>{'name', 'end_date__c', 'start_date__c', 'status__c'}, null);  
        p.config.paging.Reset(wsList.size(), resetPage);        
        wsWrapperList = populateWsWrapperList(wsList);      
    }
    
    public void reselectWorkstepIssues(){
        WSFilterParams p = wsiParams;
        
        List<String> whereClauses = new List<String>{p.ctx == 'SPECIFIC_OWNER' && p.ws.OwnerId != null
                                ? ('OwnerId = \'' + p.ws.OwnerId + '\'') + ' AND Status__c = \'Open\''
                                : ((p.ctx == 'WORKSTEP_OWNER' ? 'Workstep__r.OwnerId = \'' : (p.ctx == 'ORDER_OWNER' ? 'Workstep__r.Order__r.OwnerId = \'' : 'OwnerId = \'')) + userId + '\'')
                                + ' AND Status__c = \'Open\''};
system.debug('EJ_ whereClause:'+ whereClauses);       
        wsIssuesList = (List<Workstep_Issue__c>)reselectObjects(p.config, whereClauses, null, null);
        //p.config.paging.Reset(wsIssuesList.size(), true);     
    }

    public List<sObject> reselectObjects(DynamicTable dt, List<String> whereClauses, Set<String> additionalSelectFields, Set<Id> ids){

        if(whereClauses == null)
            whereClauses = new List<String>();
            
        if(additionalSelectFields == null)
            additionalSelectFields = new Set<String>();
        
        dt.configSection.VerifySelectionOrder();
        dt.BuildDynamicTable();
        Set<String> selectFields = dt.selectFields;     
        selectFields.addAll(additionalSelectFields);
        
        String soql = 'SELECT ' + string.join(new List<String>(selectFields), ',') + ' FROM ' + dt.baseObject.getDescribe().getName();
system.debug('EJ_ soql :'+ soql );
        dt.BuildWhereClauses(whereClauses);
        
        String orderBy = null;
        String primary = dt.GetSortFieldValue(true);
        String newFilter = dt.GetFilterNameValue();
        if(!string.isEmpty(primary)){
            String secondary = dt.GetSortFieldValue(false);
            orderBy = primary + (!string.isEmpty(secondary) ? (', ' + secondary) : '');
        }
        
        soql += ' WHERE ' + string.join(whereClauses, ' AND ') + (orderBy != null ? (' order by ' + orderBy) : '');
system.debug('EJ_ soql :'+ soql );
        List<sObject> l = new List<sObject>();
        try{ l = Database.query(soql);  }catch(Exception e){ }
        
        return l;
    }

    /*public List<SelectOption> getWorkstepGroupOptions(List<String> whereClauses) {        
        String soqlp = 'SELECT Id FROM Workstep__c WHERE ' + string.join(whereClauses, ' AND ');
        
        List<SelectOption> l = new List<SelectOption>{new SelectOption('', '-- None --')};
        for(wsGroupConfiguration c : wsGroupConfigurations){            
            String q = soqlp + ' AND ' + c.queryClause;
            l.add(new SelectOption(c.slVal, c.slVal + ' (' + string.valueOf(Database.query(q).size())  + ')'));
        }
        
        return l;
    }*/
    
    public List<SelectOption> getWorkstepFilterOptions(List<String> whereClauses) {             
        /*String soqlp = 'SELECT Id, Label__c FROM Custom_List_View__c WHERE ' + string.join(whereClauses, ' AND ');
        
        List<SelectOption> l = new List<SelectOption>{new SelectOption('', '-- None --')};          
            l.add(new SelectOption(c.slVal, c.slVal + ' (' + string.valueOf(Database.query(soqlp).size())  + ')'));
        }
        
        return l;*/
        return null;
    }

    public transient Boolean wsErrored {get; private set;}
    public List<WorkstepWrapper> populateWsWrapperList(List<Workstep__c> wsList) {
        wsErrored = false;
        List<WorkstepWrapper> l = new List<WorkstepWrapper>();
        for(Workstep__c ws : (List<Workstep__c>)wsParams.config.paging.GetPagedsObjectList((List<sObject>)wsList)){
            String err = errorMap != null ? errorMap.get(ws.Id) : null;
            wsErrored |= !string.IsEmpty(err);
            l.add(new WorkstepWrapper(ws, false, err));
        }
        return l;
    }
    
    public void AssignSelectedWorksteps(){
        if(wsParams.ws.OwnerId != null){
            List<Workstep__c> l = new List<Workstep__c>();
            for (WorkstepWrapper wsw : wsWrapperList) {
                if (wsw.isSelected){        //todo: ignore unassignable
                    wsw.workstep.OwnerId = assignWS.OwnerId;
                    l.add(wsw.workstep);
                }
            }
            
            saveWorksteps(l, 'The workstep could not be reassigned');
            reselectWorksteps(true);
        }
    }
    
    public void CompleteSelectedWorksteps(){
        List<Workstep__c> l = new List<Workstep__c>();
        for (WorkstepWrapper wsw : wsWrapperList) {
            if (wsw.isSelected && wsw.canComplete){
                wsw.workstep.Status__c = 'Complete';
                if(wsw.isPastDue)
                    wsw.workstep.Missed_Reason__c = assignWS.Missed_Reason__c;
                l.add(wsw.workstep);
            }
        }
        
        saveWorksteps(l, 'The workstep could not be completed');
        reselectWorksteps(true);
    }
    
    private transient Map<Id, String> errorMap;
    private void saveWorksteps(List<Workstep__c> l, String defaultError){
        if(l.size() > 0){
            errorMap = new Map<Id, String>();
            Database.SaveResult[] srs = Database.Update(l, false);
            for(Integer i = 0; i<l.size(); i++){
                Database.SaveResult sr = srs[i];
                List<String> errors = new List<String>();
                for(Database.Error err : sr.getErrors())
                    errors.add(err.getMessage());
                errorMap.put(l[i].Id, (errors.size() > 0) ? string.join(errors, '\n') : (!sr.isSuccess() ? defaultError : null));
            }
        }
    }
    
    public override void PageUpdated(String mode){      
        if(mode == 'wsTable')
            reselectWorksteps(false);
        else if(mode == 'wsiTable')
            reselectWorkstepIssues();
    }
    
    public override void SortChanged(String mode){      
        if(mode == 'wsTable')
            reselectWorksteps(true);
        else if(mode == 'wsiTable')
            reselectWorkstepIssues();
    }
    
    public override void FieldConfigChanged(String mode){       
        if(mode == 'wsTable')
            reselectWorksteps(true);
        else if(mode == 'wsiTable')
            reselectWorkstepIssues();
    }
    
    public PageReference Remove_Saved_Filter() {
        String mode = ApexPages.currentPage().getParameters().get('tab');
        String tableName = ApexPages.currentPage().getParameters().get('tabmode');              
        String err = RemoveSavedFilter(mode, tableName);
        PageReference wsMgmt;
        if(err != '')
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, err)); 
        else{
            wsMgmt = Page.WorkstepManagement;
            wsMgmt.getParameters().put('subOrderId', currentSubOrderId);
            wsMgmt.setRedirect(true);
        }       
        return wsMgmt;
    }
    
    public PageReference Set_Default_Filter() {
        String mode = ApexPages.currentPage().getParameters().get('tab');
        String tableName = ApexPages.currentPage().getParameters().get('tabmode');              
        String err = SetDefaultFilter(mode, tableName);
        PageReference wsMgmt;
        if(err != '')
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, err)); 
        else{
            wsMgmt = Page.WorkstepManagement;
            wsMgmt.getParameters().put('subOrderId', currentSubOrderId);
            wsMgmt.setRedirect(true);
        }       
        return wsMgmt;
    }
    
    public void loadwsParams(){
        wsiParams = null;
    	wsParams = new WSFilterParams();
    	wsParams.config.EnablePaging();
        wsParams.config.configSection.unsupportedFilterFields = new Set<String>{'OwnerId', 'Order__c', 'Sub_Order__c'};
        wsParams.config.customPicklistValues = new Map<String, List<String>>{ 'Status__c'=>wsStatusList };
        wsParams.config.customStyleClass = new Map<String, String>{'End_Date__c'=>'{!IF({0}.isPastDue, "errored", "")}'};
        wsParams.config.BuildConfig('wsTable', 'wsParams.config', '{!wsWrapperList}', 'workstep', Workstep__c.getSObjectType(), new Set<String>{'Sub_Order__r', 'Sub_Order__r.External_Order__r', 'Order__r'}, 
                                    new Map<String, String>{'Sub_Order__r.Service_Location__r.Customer_Detail__r.Market_Type__r.Name'=>'Market Type', 
                                    'Sub_Order__r.Service_Location__r.Customer_Detail__r.Market_Area__r.Name'=>'Market Area',
                                    'Sub_Order__r.Service_Location__r.Customer_Detail__r.Care_Organization__r.Name'=>'Care Organization',
                                    'Sub_Order__r.Service_Location__r.Location__r.Building__r.State__c'=>'Location State'});
        if(!wsParams.config.GetPreselectData('WorkstepManagement', 'WorkstepManagement_wsTable', true)){                    
            wsParams.config.configSection.UpdateOptions(defaultWSFields);
        }
        wsParams.config.checkBoxProperty = 'isSelected';
        wsParams.config.customButtonColumns = wsCustomColumns;
        wsParams.config.customColumns = new List<DynamicTable.CustomColumn>{new DynamicTable.CustomColumn('Errors', '{!{0}.error}', '{!wsErrored}', 'errored')};
        wsParams.config.customHiddenFields = new Map<String, String>{'canComplete'=>'canComplete', 'isPastDue'=>'isPastDue'};
        tables = new Map<String, DynamicTable>{'wsTable'=>wsParams.config};
        
        ownedWorkstepsOnly = true;
        wsParams.ctx = 'ANY';

        Sub_Order__c ctxSO = !string.IsEmpty(currentSubOrderId) ? [SELECT Id, Name, Order__c FROM Sub_Order__c WHERE Id = :currentSubOrderId limit 1] : null;
        Order__c ctxO = !string.IsEmpty(currentOrderId)
                            ? [SELECT Id, Name FROM Order__c WHERE Id = :currentOrderId limit 1]
                            : (ctxSO != null ? [SELECT Id, Name FROM Order__c WHERE Id = :ctxSO.Order__c limit 1] : null);
        if(ctxSO != null){
            wsParams.ws.Sub_Order__c = ctxSO.Id;
            wsParams.ctx = 'BY_SUBORDER';
        }
        if(ctxO != null){
            wsParams.ws.Order__c = ctxO.Id;
            if(ctxSO == null){
                wsParams.ctx = 'BY_ORDER';
            }
        }   
        
        reselectWorksteps(true);
    }
    
    public void loadwsiParams(){
        wsParams = null;
        wsiParams = new WSFilterParams();
        //wsiParams.config.EnablePaging();
        wsiParams.config.configSection.unsupportedFilterFields = new Set<String>{'OwnerId', 'Status__c'};
        wsiParams.config.customPicklistValues = new Map<String, List<String>>{ 'Workstep__r.Status__c'=>wsStatusList };
        wsiParams.config.BuildConfig('wsiTable', 'wsiParams.config', '{!wsIssuesList}', '', Workstep_Issue__c.getSObjectType(), new Set<String>{'Workstep__r', 'Workstep__r.Sub_Order__r', 'Workstep__r.Sub_Order__r.External_Order__r', 'Workstep__r.Order__r'});
        if(!wsiParams.config.GetPreselectData('WorkstepIssue', 'WorkstepManagement_wsiTable', true)){
            wsiParams.config.configSection.UpdateOptions(defaultWSIFields);
        }

        tables = new Map<String, DynamicTable>{'wsiTable'=>wsiParams.config};
        
        ownedWorkstepsOnly = true;
        wsiParams.ctx = 'WORKSTEP_OWNER';   
        
        reselectWorkstepIssues();
    }
    
    public void Test_Save() {
        Custom_List_View__c clv = new Custom_List_View__c();
        clv.Label__c = 'The Best One';
        clv.Object__c = 'Workstep__c';
        securityUtils.BypassProcesser.saveObjects(new List<Custom_List_View__c>{clv}, true);
    }
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_WorkstepManagement(); }
}