public with sharing class AddressSelectorController extends DynamicTable.DynamicTableController{
    
    public String accountID {
        get{ return account != null ? account.Id : null; }
        set{ if(accountID != value) setAccountID(value); }
    }
    public Account account { get; set; }
    
    public String jsSaveCallback { get; set; }
    public String resultID { get; set; }
    
    //Service loc fields
    public String selectedParent { get; set; }
    public String phone { get; set; }
    public String overrideName { get; set; }
    public Boolean billable { get; set; }
    
    public String ParentLocLabel {get; set;}
    public String ParentLocValue {get; set;}
    
    public List<SelectOption> availableParentLocs { get; private set; }
    public Integer numavailableParentLocs {get; private set;}
    
    public List<Building__c> foundBuildings { get; set; }
    public List<Building__c> displayedFoundBuildings { get; set; }
    public transient String jsonbuildingBAA { get; set; }
    
    public String returnURL { get; set; }
    public String returnURL2 { get; set; }
    
    public Boolean readOnlyMode {get; set;}
    
    public DynamicTable dt { get; set; }
    private final List<String> defaultBuildingFields = new List<String>{'Id', 'Address__c','City__c','County__c','State__c','Postal_Code__c', 'Zip4__c','Country__c','Net_Classification__c','Building_Type__c','Building_CLLI__c','Serving_LSO__c'};
        
    public Boolean canManuallyCreateBuilding{
        get{
            return CustomSettingUtils.currentUserHasCustomPermission('Can_Manually_Create_Building__c');
        }
    }
    
    public void messageDisplay(String Msg){
        ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, Msg);
        ApexPages.addMessage(m);
    }

    public AddressSelectorController() {
        try{
            foundBuildings = new List<Building__c>();
            jsonBuildingBAA = '';
                
            returnURL = ApexPages.currentPage().getParameters().get('retURL');
            returnURL2 = ApexPages.currentPage().getParameters().get('retURL2');
            
            init();
        }
        catch(Exception e){
            messageDisplay(e.getMessage());
        }
    }
    
    private void setAccountID(String value){
        readOnlyMode = false;
        if(value != null){
            account = [select Id, Name, OwnerId, Customer_Detail__c from Account where Id =: value];
            readOnlyMode = !SecurityUtils.currentUserHasRecordAccess(value, true);
            
            if(!readOnlyMode){                                          
                availableParentLocs = new List<SelectOption>();
                
                ParentLocLabel = '';
                ParentLocvalue = '';
                String legacyId = '';
                String billingId = ''; 
                numavailableParentLocs = 0;
                for(Service_Location__c sLoc : (List<Service_Location__c>)Database.Query('select Id, Name, ICC_Subscriber_ID__c, Customer_Detail__r.Legacy_ID__c, Customer_Detail__r.Billing_ID__c   From Service_Location__c where Account__c = \'' + account.Id + '\'' + ' and billable__c =true '
                                                                                        + ' and (Parent_Service_Location__c = null' + (account.Customer_Detail__c != null ? (' or Parent_Service_Location__r.Customer_Detail__c = \'' + account.Customer_Detail__c + '\'') : '') + ')'
                                                                                        + ' order by Name, ICC_Subscriber_ID__c')){
                    legacyId = (!string.isEmpty(sLoc.Customer_Detail__r.Legacy_ID__c)) ?' ' + sLoc.Customer_Detail__r.Legacy_ID__c:'';
                    billingId = (!string.isEmpty(sLoc.Customer_Detail__r.Billing_ID__c))?' ' + sLoc.Customer_Detail__r.Billing_ID__c:'';
                    //availableParentLocs.add(new SelectOption(sLoc.Id, sLoc.Name + (!string.isEmpty(sLoc.ICC_Subscriber_ID__c) ? (' [' + sLoc.ICC_Subscriber_ID__c + ']' + legacyId + billingId) : legacyId +  billingId)));
                    ParentLocLabel += sLoc.Name + (!string.isEmpty(sLoc.ICC_Subscriber_ID__c) ? (' [' + sLoc.ICC_Subscriber_ID__c + ']' + legacyId + billingId) : legacyId +  billingId) + '^';
                    ParentLocValue += sLoc.Id + '^';
					numavailableParentLocs++;
//                    availableParentLocs.add(new SelectOption(sLoc.Id, sLoc.Name + (!string.isEmpty(sLoc.ICC_Subscriber_ID__c) ? (' [' + sLoc.ICC_Subscriber_ID__c + ']') : '')));
                }
                ParentLocLabel = ParentLocLabel.replace('\'','\\\'');
            }
            else
                messageDisplay('You do not have access to modify this account. Please reach out to the Sales Ops Coordinators to build the service location for you or contact the account owner to approve your read/write access to the account.');
        }
    }
    
    public Id buildingID { get; set; }
    public PageReference CreateLocOnExistingBuild(){
        PageReference pr = getNextPage(null, null);
        if(buildingID != null){
            Location__c l = AddressUtils.CreateLocation(buildingID, AddressParser.Param_Suite, true);
            pr = getNextPage(l.Id, null);
            
            if(!string.isEmpty(accountID)){
                Service_Location__c sLoc = createServiceLocation(l, null);
                pr = getNextPage(l.Id, sLoc.Id);
            }
        }
        
        return pr;
    }
    private void init(){
        callerName = 'addSel';   // Added to distinguish different DynamicTables on the same page SEAL-1694
        dt = new DynamicTable();
        dt.EnablePaging();
        
        dt.paging.RecordsPerPage = 20;
        dt.configSection.showRowPositionControls = true;
        dt.configSection.showSOQLSortControls = false;
        
        dt.customColumns = new List<DynamicTable.CustomColumn>{new DynamicTable.CustomColumn('', '{!"<input type=\'radio\' id=\'existingBuildingSelect\' name=\'buildingSelect\' onclick=\'addressSelector_buildingSelected();\'></input>"}', null, null)};
                
        dt.BuildConfig('dtSelector', 'dt', '{!displayedFoundBuildings}', '', building__c.getSObjectType(), null);
        dt.configSection.UpdateOptions(defaultBuildingFields);
        dt.customHiddenFields = new Map<String, String>{'buildingID'=>'Id','buildingLat'=>'Latitude__c', 'buildingLng'=>'Longitude__c','buildingName'=>'Name','buildingNetClass'=>'Net_Classification__c'
                            ,'lblStreet'=>'Address__c','lblCity'=>'City__c','lblState'=>'State__c','lblPostalCode'=>'Postal_Code__c','lblCountry'=>'Country__c'};
        //refreshDataTable(true);
                
        tables = new Map<String, DynamicTable>{'dtSelector'=>dt};
        
        dt.BuildDynamicTable();
        
        
    }
    
    public PageReference SearchBuildings(){
        string address = AddressParser.Param_StreetNumber + ' ' + AddressParser.Param_Street + ' ' + AddressParser.Param_State;
        address = replaceStreetTypes(replaceDirectionals(address)).replace('  ',' ');
        String searchString = '*'+string.escapeSingleQuotes(address)+'*';
        if(searchString.length() > 2 && AddressParser.Param_Street.length() > 0){
            String searchQuery = 'FIND \'' + searchString + '\' IN ALL FIELDS RETURNING  Building__c (Id,Name,Address__c,City__c,County__c,State__c,Postal_Code__c,Zip4__c,Net_classification__c,Building_Type__c,Status__c,Building_CLLI__c,Serving_LSO__r.Name, Latitude__c, Longitude__c, Country__c) ';
            List<List <sObject>> searchList = search.query(searchQuery);
            foundBuildings = (List<Building__c>)searchList[0];
        }

        jsonBuildingBAA = json.serialize(getSearchedBuildingBAA());
        getBuildings(true);
        
        return null;
    }
    
    private void getBuildings(Boolean resetPage){
        if(!string.isEmpty(dt.sortField))
            foundBuildings = ApexUtils.sortByComparableField(foundBuildings,dt.sortField,dt.sortAscending,true);
        
        //dt.configSection.VerifySelectionOrder();
        dt.paging.Reset(foundBuildings.size(), resetPage);
        displayedFoundBuildings = dt.paging.GetPagedsObjectList(foundBuildings);
    }
    
    public PageReference ValidateBuildingAddress(){
        PageReference pr = getNextPage(null, null);
        try{
            if(AddressParser.Param_Latitude == null) messageDisplay('Latitude must be supplied.');
            if(AddressParser.Param_Longitude == null) messageDisplay('Longitude must be supplied.');
            
            integraWS.SFLocationView locView = AddressParser.addressParsed();
            
            if(locView.Messages != null){
                AddressUtils.DisplayErrorMessageFromLocView(locView,true);
            }
            
            if(locView.Success){
                if(locView.BuildingHash != null && locView.BuildingHash != ''){
                    
                    Building__c b = AddressUtils.CreateBuilding(locView, true, AddressParser.Param_ManualCreate);
                    buildingID = b.Id;
                    pr = CreateLocOnExistingBuild();
                    
                    integraws.ArrayOfLocationAccessAndBandwithResults baas = locView.AccessAndBandwidthResults;
                    List<Building_Access_Availability__c> baaRecords = createBuildingAccessAvailabilities(baas,b);
                }
                else
                    messageDisplay('No building hash found.');
            }
            else{
                pr = null;
                
                string errorMessage = '';
                if(locView.Messages != null)
                    errorMessage = string.join(locView.Messages.string_x,',');
                
                createErrorTask(accountID, 'Address Master Details:' + errorMessage);
            }
        }catch(Exception e){
            pr = null;
            createErrorTask(accountID, 'Exception details:\n' + e.getMessage());
            messageDisplay(e.getMessage());
        }
        
        return pr;
    }
    
    private PageReference getNextPage(Id locID, Id sLocID){
        
        PageReference pr = null;
        if(String.isEmpty(jsSaveCallback)){
            if(!String.isEmpty(returnURL)){
                pr = new PageReference(returnURL);
                if(!String.isEmpty(returnURL2))
                    pr.getParameters().put('retURL', returnURL2);
            }
            else if(!string.isEmpty(sLocID)) pr = new PageReference('/' + accountID);
            else if(locID != null) pr = new PageReference('/' + locID);
        }
        else resultID = sLocID != null ? sLocID : locID;    //If we're using this as a sub-component, let the page do the work on save
        
        return pr;
    }
    
    private static void createErrorTask(Id accountID, String error){
        Task t = new Task();
        IntegraServiceSettings__c integraServiceSettings = IntegraServiceSettings__c.getInstance();
        User u = [select id from user where ntid__c = :integraServiceSettings.No_Serving_LSO_Task_Owner__c limit 1];
        
        t.OwnerId = u.id;
        t.Subject = 'Unable to create service location';
        t.WhatId = accountID;
        t.Type = 'Research Request';
        t.ActivityDate = Date.today();
        t.Description = 'Unable to create service location.\nSupplied address:\nStreet: '
                        + AddressParser.Param_Street
                        + '\nSuite: ' + AddressParser.Param_Suite
                        + '\nCity: ' + AddressParser.Param_City
                        + '\nState: ' + AddressParser.Param_State
                        + '\nZip: ' + AddressParser.Param_PostalCode + '\n' + error;
        
        insert t;
    }
    
    private Service_Location__c createServiceLocation(Location__c l, integraWS.SFLocationView loc){
        
        if(l == null) return null;
        
        Service_Location__c sLoc = new Service_Location__c
                                        (
                                            Name = string.IsEmpty(overrideName) ? account.Name : overrideName
                                            ,Account__c = account.Id
                                            ,Location__c = l.id
                                            ,Phone__c = phone
                                            ,Billable__c = billable
                                            ,Parent_Service_Location__c = !string.IsEmpty(selectedParent) && selectedParent != 'None' ? selectedParent : null
                                            ,Owner__c = account.OwnerId
                                        );
        System.debug(sLoc);
        insert sLoc;
        
        return sLoc;
    }
    
    private decimal getBandwidthValue(integer availBandwidth){
        decimal bandwidth = (availBandwidth/1000);
        List<decimal> ranges = new List<decimal>{ 3, 5, 10, 15, 20, 25, 30, 40, 45, 50, 60 };
        for(Integer i=0; i<ranges.size()-1; i++){
            if(bandwidth >= ranges[i] && bandwidth < ranges[i+1])
                return ranges[i];
        }
        
        return bandwidth;
    }
    
    private List<Building_Access_Availability__c> createBuildingAccessAvailabilities(integraws.ArrayOfLocationAccessAndBandwithResults baas, Building__c bldg){
        
        //If we insert a baa record and status new, change to validated
        List<Building_Access_Availability__c> baaRecords = new List<Building_Access_Availability__c>();
        system.debug(baas);
        if(baas != null){
            if(baas.LocationAccessAndBandwithResults != null){
                List<Building_Access_Availability__c> baaExisting = [Select Access_Technology__r.Access_Technology_ID__c,Maximum_Bandwidth__c From Building_Access_Availability__c where building__c = :bldg.id];
                Map<decimal,Building_Access_Availability__c> baaExistingMap = new Map<decimal,Building_Access_Availability__c>(); 
                Access_Technology__c atech = Test.isRunningTest() ? new Access_Technology__c(Access_Technology_ID__c = 1) :[Select Id,Access_Technology_ID__c From Access_Technology__c Where Name = 'EoC' limit 1];
                Building__c b = [Select Id,Status__c From Building__c where id = :bldg.id];
                
                for(Building_Access_Availability__c baa :baaExisting){
                    baaExistingMap.put(baa.Access_Technology__r.Access_Technology_ID__c,baa);
                } 
                for(integraws.LocationAccessAndBandwithResults v : baas.LocationAccessAndBandwithResults){
                    if(v.AccessTechnologyID != null){
                        if(v.AvailiableBandwidth != null && v.AvailiableBandwidth > 3000){
                            Building_Access_Availability__c baa = baaExistingMap.get(v.AccessTechnologyID);
                            decimal availBandwidth = getBandwidthValue(v.AvailiableBandwidth);
                            if(baa != null){
                                //update
                                
                                if(baa.Maximum_Bandwidth__c != availBandwidth){
                                    baa.Maximum_Bandwidth__c = availBandwidth;
                                    baaRecords.add(baa);
                                }
                            }
                            else{
                                if(v.AccessTechnologyID == atech.Access_Technology_ID__c){
                                    //insert
                                    baa = new Building_Access_Availability__c();
                                    baa.Access_Technology__c = atech.id;
                                    //Create rules around grouping the bandwidth amounts??????
                                    baa.Maximum_Bandwidth__c = availBandwidth;
                                    baa.Available_Bandwidth__c = (v.AvailiableBandwidth/1000);
                                    baa.building__c = b.id;
                                    baa.Status__c = 'Qualified';
                                    baaRecords.add(baa);
                                }
                            }
                            
                            if(b.Status__c != 'Validated' && b.Status__c != 'Active')
                                b.Status__c = 'Validated';
                        }
                    }
                }
                if(!Test.isRunningTest()){
                    AddressUtils.SaveAddress(b, null, null, true);
                    upsert baaRecords;
                }
            }
        }
        return baaRecords;
    }
    
    private String replaceDirectionals(String address){
        Set<String> directionals = new Set<String>{'N','NE','E','SE','S','SW','W','NW'};
        List<string> addressSplit = address.split(' ');
        for(integer i=0;i<addressSplit.size();i++){
            if(directionals.contains(addressSplit[i].toUpperCase())){
                addressSplit[i] = '';
            }
        }
        return String.join(addressSplit,' ');
    }
    
    private String replaceStreetTypes(String address){
        Set<String> streetTypes = new Set<String>{'ALY','ANX','APT','ARC','AVE','BSMT','BYU','BCH','BND','BLF','BTM','BLVD','BR','BRG','BRK','BLDG','BG','BYP','CP','CYN','CPE','CSWY','CTR','CIR'
            ,'CLFS','CLFS','CLB','COR','CORS','CRSE','CT','CTS','CV','CRK','CRES','XING','DL','DM','DEPT','DV','DR','EST','EXPY','EXT','FLS','FRY','FLD','FLDS','FLT','FL','FRD','FRST','FRG','FRK'
            ,'FRKS','FT','FWY','FRNT','GDNS','GDNS','GTWY','GLN','GRN','GRV','HNGR','HBR','HVN','HTS','HWY','HL','HLS','HOLW','INLT','IS','ISS','JCT','KY','KNLS','KNLS','LK','LKS','LNDG','LN','LGT'
            ,'LF','LBBY','LCKS','LCKS','LDG','LOWR','MNR','MDWS','MDWS','ML','MLS','MSN','MT','MTN','NCK','OFC','ORCH','PKWY','PH','PNES','PNES','PL','PLN','PLNS','PLZ','PT','PRT','PR','RADL','RNCH'
            ,'RPDS','RPDS','RST','RDG','RIV','RD','RM','SHL','SHLS','SHR','SHRS','SPC','SPG','SPGS','SQ','STA','STRA','STRM','ST','STE','SMT','TER','TRCE','TRAK','TRFY','TRL','TRLR','TUNL','TPKE'
            ,'UN','UPPR','VLY','VIA','VW','VLG','VL','VIS','WAY','WLS','WLS'};
        List<string> addressSplit = address.split(' ');
        for(integer i=0;i<addressSplit.size();i++){
            if(streetTypes.contains(addressSplit[i].toUpperCase())){
                addressSplit[i] = '';
            }
        }
        return String.join(addressSplit,' ');
    }
    
    private Map<Id,List<Building_Access_Availability__c>> getSearchedBuildingBAA(){
        Map<Id, List<Building_Access_Availability__c>> buildBAA = new Map<Id, List<Building_Access_Availability__c>>();
        
        for(Building_Access_Availability__c baa : [select Access_Technology_Name__c, Available_Bandwidth__c, Minimum_Required_Revenue__c, Status__c, Building__c, Maximum_Bandwidth__c from Building_Access_Availability__c where building__c in :foundBuildings and (Access_Technology_Name__c = 'EoF' or Access_Technology_Name__c = 'EoC')]){
            List<Building_Access_Availability__c> l = buildBAA.get(baa.Building__c) != null ? buildBAA.get(baa.Building__c) : new List<Building_Access_Availability__c>();
            l.add(baa);
            buildBAA.put(baa.Building__c, l);
        }
        System.debug('buildBAA: ' + buildBAA);
        return buildBAA;
    }
    
    
    public override void PageUpdated(String mode){
        getBuildings(false);
    }
    
    public override void SortChanged(String mode){
        getBuildings(true);
    }
}