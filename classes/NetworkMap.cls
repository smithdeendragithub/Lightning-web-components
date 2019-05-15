public without sharing class NetworkMap implements TestUtils.ITestableClass {
//test comment
    public decimal latitude {get;set;}
    public decimal longitude {get;set;}
    public  transient string jsonBuildings {get;set;}
    public decimal distRange {get;set;}
    public boolean myOnNet {get;set;}
    public boolean myNearNet {get;set;}
    public boolean displayIlec {get;set;}
    public boolean displayAllIlec {get;set;}
    public Boolean nearNetHigh {get;set;}
    public Boolean nearNetMed {get;Set;}
    public Boolean nearNetLow {get;Set;}
    public Boolean nearNetUnPrior {get;Set;}
    public string leadStatus {get;set;}
    public string leadPhone {get;set;}
    public string leadFirstName {get;set;}
    public string leadLastName {get;set;}
    public string leadCompany {get;set;}
    public string leadSource {get;set;}
    public string leadGRId {get;set;}
    public string leadRoomSuite {get;set;}
    public id buildingID {get;set;}
    public id newLeadId{get;set;}
    public Double selectedMaxBAA{get;set;}
    public Double selectedMinBAA{get;set;}
    public Double maxBAA{get;set;}
    public Double minBAA{get;set;}
    public Double maxMRREoF{get;set;}
    public Double minMRREoF{get;set;}
    public Double selectedMaxMRREoF{get;set;}
    public Double selectedMinMRREoF{get;set;}
    public transient List<Building__c> gBuildings {get;Set;}
    public transient Map<Id,Georesults_business__c> filteredBusRecords {get;Set;}
    
    public id oppAccountID {get;set;}
    public string oppAcctName {get;set;}
    public id oppBuildingID {get;set;}
    public id newOppID {get;set;}
        public static String getTimeZone(){
        if(timeZone == null){
            timeZone = UserInfo.getTimeZone().getID();
        }
        return timeZone;
    }
    public static String timeZone;
    public string UserSalesChannel{
        get{
            return [Select Id,Sales_Channel__c From User where Id= :UserInfo.getUserId()].Sales_Channel__c;
        }  
    }
    
    private string profileName {get;set;} 
    public boolean isDebugProfile {
        get {
            set<string> debugProfiles = new set<string>{'System Administrator','Power User'};
            Id profileId=userinfo.getProfileId();
            if(profileName != null)
                return debugProfiles.contains(profileName);
            else
                return debugProfiles.contains([Select Id,Name from Profile where Id=:profileId].Name);
            
        }
    }
    public string wireCenterBuildings {
        get {
            List<WireCenter> wireCenterData = new List<WireCenter>();
            Map<string,List<Building__c>> mapBuilds = GetWireCenterSelectItems();
            list<string> mapKeySet = new list<string>();
            for(string s : mapBuilds.keySet()){
                mapKeySet.add(s);
            }
            mapKeySet.sort();
            for(string s: mapKeySet){
                wireCenterData.add(new WireCenter(s,mapBuilds.get(s)));
            }
            return json.serialize(wireCenterData);
        }
    }
    
    public List<SelectOption> gbFilterListViews{
        get{
            ApexPages.StandardSetController gbc = new ApexPages.StandardSetController(Database.getQueryLocator('Select id From GeoResults_Business__c limit 1'));   
            List<SelectOption> filters =  gbc.getListViewOptions();
            for(SelectOption so : filters){
                if(so.getLabel() == 'All'){
                    gbFilterID = so.getvalue();
                    gbAllFilterID = so.getvalue();
                }
            }
            return filters;
        }
    }
    
    public String gbFilterID {get;Set;}
    public String gbAllFilterID {get;Set;}

	public List<SelectOption> leadFilterListViews{
        get{
            ApexPages.StandardSetController lc = new ApexPages.StandardSetController(Database.getQueryLocator('Select id From Lead limit 1'));   
            //List<SelectOption> filters =  lc.getListViewOptions();
			List<SelectOption> filters = new List<SelectOption>();
            filters.add(new SelectOption('All','All'));
			filters.addall(lc.getListViewOptions());
            return filters;
        }
    }
    
    public String leadFilterID {get;Set;}

	public List<SelectOption> accountFilterListViews{
        get{
            ApexPages.StandardSetController ac = new ApexPages.StandardSetController(Database.getQueryLocator('Select id From Account limit 1'));   
            //List<SelectOption> filters =  lc.getListViewOptions();
			List<SelectOption> filters = new List<SelectOption>();
            filters.add(new SelectOption('All','All'));
			filters.addall(ac.getListViewOptions());
            return filters;
        }
    }
    
    public String accountFilterID {get;Set;}
    
    public class WireCenter{
        List<Building__c> Bldgs {get;set;}
        string st {get;set;}
        public WireCenter(string s, List<Building__c> b){
            Bldgs = b;
            st = s;
        }
    }
    
    public class AcctData{
        public string OwnerName {get;set;}
        public id Id {get;set;}
        public string AcctName {get;set;}
        public string Type {get;set;}
        public boolean HasOpenOpps {get;set;}
        public boolean ProtectedAccount {get;set;}
        public AcctData(Account a, boolean hasOpps){
            OwnerName = a.Owner.Name;
            Id = a.id;
            AcctName = a.name;
            Type=a.type;
            HasOpenOpps = hasOpps;
            ProtectedAccount = a.Protected_Account__c;
            //
        }
    }
    
    public class GRBusData{
        public id Id {get;set;}
        public string busid {get;set;}
        public id building {get;set;}
        public string CleanBusiness {get;set;}
        public integer TotalTelSpend {get;set;}
        public string Contact {get;set;}
        public string Phone {get;set;}
        public string CleanAddress {get;set;}
        public string Unit {get;set;}
        public string City {get;set;}
        public string State {get;set;}
        public decimal Zip {get;set;}
        public decimal NAICS2 {get;set;}
        public integer IconInt {get;set;}
        public string CreatedDateIndicator {get;Set;}
        public Boolean filteredBusRecord {get;Set;}
        
        public GRBusData(Georesults_Business__c gb, integer iconInteger, Boolean filtered){
            Id = gb.Id;
            busid = string.valueof(gb.busid__c);
            building = gb.building__c;
            CleanBusiness = gb.CleanBusiness__c;
            TotalTelSpend = gb.TotalTelSpendPerMonth__c == null ? 0 : integer.valueOf(gb.TotalTelSpendPerMonth__c);
            Contact = gb.Contact__c;
            Phone = gb.Phone__c;
            CleanAddress = gb.CleanAddress__c;
            Unit = gb.Unit__c;
            City = gb.City__c;
            State = gb.State__c;
            Zip = gb.Zip__c;
            NAICS2 = gb.NAICS2__c;
            IconInt = iconInteger;
            filteredBusRecord = filtered;
                
            Datetime dateGMT = gb.CreatedDate;
            integer Days = Integer.valueOf((Datetime.now().getTime() - dateGMT.getTime())/(1000*60*60*24));
            if(Days <= 90)
                CreatedDateIndicator = '**';
            else if(Days > 90 && Days <= 180)
                CreatedDateIndicator = '*';
            else
                CreatedDateIndicator = '';
        }
    }
       
	public class BuildOrderData{
		public id ID {get;set;}
		public string Equipment {get;set;}
		public datetime ProjectedNetworkReadyDate {get;set;}
		public string ESONumber {get;set;}
		public BuildOrderData(Order__c buildOrder){
			this.ID = buildOrder.id;
			this.Equipment = buildOrder.Equipment__c;
			this.ProjectedNetworkReadyDate = buildOrder.Projected_Network_Ready_Date__c;
			this.ESONumber = buildOrder.ESO_Number__c;
		}
	} 

	public class CapitalProjectData{
		public id ID {get;set;}
		public string Name {get;set;}
		public string RTName {get;set;}
		public CapitalProjectData(Capital_Project_Building__c cpb){
			this.id = cpb.Capital_Project__c;
			this.name = cpb.Capital_Project__r.Name;
			if(rt_map.containsKey(cpb.Capital_Project__r.recordTypeID))
				this.RTName = rt_map.get(cpb.Capital_Project__r.recordTypeID).getName();
		}
	}
	    
    public class BuildingData{

        public id ID {get;set;}//building id
        public decimal Longitude {get;set;}
        public decimal Latitude {get;set;}
        public string Name {get;set;}
        public string CLLI {get;set;}
        public string NetClass {get;set;}
        public string BuildingType {get;set;}
        public string Status {get;set;}
        public string AssignedAE {get;set;}
        public string SalesChannel {get;set;}
        public string SalesPriority {get;set;}

        
        //public set<Georesults_Business__c> GeoBusinesses {get;set;}
        public set<Building_Access_Availability__c> BAAs {get;set;}
        public set<AcctData> Accts {get;set;}
        public set<GRBusData> GeoBusinesses {get;set;}
		public set<BuildOrderData> BuildOrders {get;set;}
		public set<CapitalProjectData> CapitalProjects {get;set;}
        public BuildingData(building__c b,set<Georesults_Business__c> gbList, set<Building_Access_Availability__c> baaList, set<Account> acctList, set<id> acctsWithOpenOpps, Map<string,integer> mapGRHasLead, Map<Id,Georesults_business__c> filteredRecords ){
            ID = b.id;
            Longitude = b.Geo_Coordinates__Longitude__s;
            Latitude = b.Geo_Coordinates__Latitude__s;
            Name = b.Name;
            CLLI = b.Building_CLLI__c;
            NetClass = b.Net_Classification__c;
            BuildingType = b.Building_Type__c;
            Status = b.Status__c;
            SalesChannel = b.Building_Assigned_AE__r.Sales_Channel__c;
            AssignedAE = b.Building_Assigned_AE__r.Name;
            SalesPriority = b.Sales_Priority__c;
            set<GRBusData> grData = new set<GRBusData>();
            if(gbList != null){
                for(Georesults_Business__c gb :gbList){
                    GRBusData grBD = new GRBusData(gb,mapGRHasLead.get(string.valueof(gb.id)) == null ? 0 : mapGRHasLead.get(string.valueof(gb.id)),filteredRecords.get(gb.Id) != null ? true:false);
                    grData.add(grBD);
                }
            }
            GeoBusinesses = grData;
            
            BAAs = baaList;
            set<AcctData> acctDataList = new set<AcctData>();
            if(acctList != null){
                for(Account a : acctList){
                    AcctData ad = new AcctData(a,acctsWithOpenOpps.contains(a.id));
                    acctDataList.add(ad);
                }
            }
            Accts = acctDataList;
			
			BuildOrders = new set<BuildOrderData>();
			for(Order__c o : b.Orders__r){
				BuildOrders.add(new BuildOrderData(o));
			}

			CapitalProjects = new set<CapitalProjectData>();
			set<string> nonPendingStatusValues = new set<string>{'Completed','Withdrawn','Expired'};
			for(Capital_Project_Building__c cpb : b.Capital_Project_Buildings__r){
				if(!nonPendingStatusValues.contains(cpb.Capital_Project__r.Status__c))
					CapitalProjects.add(new CapitalProjectData(cpb));
			}

        }
    }

	public static map<Id, Schema.RecordTypeInfo> rt_map {get;set;}

    private string filterNearNetResults(Boolean nnHigh,Boolean nnMed, Boolean nnLow, Boolean nnUnPrior,String query, Boolean filterToMyBuildings){
        query += 'or ( net_classification__c = \'Near-net\'';
        if(filterToMyBuildings)
            query += ' and Building_Assigned_AE__c = \'' + UserInfo.getUserId() + '\'';
            
        
        if(!nnHigh && !nnMed && !nnLow && !nnUnPrior){
            query+=')';
            return query;
        }
        else{
            query+= 'and ( Id = null ';
            if(nnHigh)
                query += ' or Near_Net_Priority__c = \'High\'';
            if(nnMed)
                query += ' or Near_Net_Priority__c = \'Medium\'';
            if(nnLow)
                query += ' or Near_Net_Priority__c = \'Low\'';
            if(nnUnPrior)
                query += ' or Near_Net_Priority__c = null';
            query+= '))';
            System.debug('Query: ' + query);
            return query;
        }
    
    }
    
    public pageReference GatherBuildingData(){
		rt_map = Schema.getGlobalDescribe().get('Capital_Project__c').getDescribe().getRecordTypeInfosById();
        gBuildings = new List<Building__c>();
        
        string q = 'Select Id, Geo_Coordinates__Longitude__s,Geo_Coordinates__Latitude__s, Address__c, City__c, State__c, Postal_Code__c, Name, Building_CLLI__c, Net_Classification__c, Building_Type__c, Status__c, Sales_Priority__c,Building_Assigned_AE__r.Sales_Channel__c, Building_Assigned_AE__r.Name,Building_Assigned_AE__c,(Select Id, ESO_Number__c,Equipment__c,Projected_Network_Ready_Date__c From Orders__r),(Select Id,Capital_Project__c,Capital_Project__r.Name, Capital_Project__r.Status__c, Capital_Project__r.RecordTypeId From Capital_Project_Buildings__r)  From Building__c Where  Distance(Geo_Coordinates__c,GEOLOCATION(' + string.valueof(latitude) + ', ' + string.valueof(longitude) + ' ), \'mi\') < ' + string.valueof(distRange);
        
        if(myOnNet)
            q+= ' and ((Building_Assigned_AE__c = \'' + UserInfo.getUserId() + '\' and net_classification__c = \'On-net\')';
        else
            q+= ' and (net_classification__c = \'On-net\'';
        
        //Filter NearNet
        q = filterNearNetResults(nearNetHigh,nearNetMed,nearNetLow,nearNetUnPrior,q,myNearNet);
        
        if(displayIlec || displayAllIlec)
            q+= ' or net_classification__c = \'Off-net\'';
        
        
        q+= ' or Building_Type__c like \'%LSO%\')';
        system.debug(q);
        if(Test.isRunningTest())
            gBuildings = new List<Building__c>();
        else
            gBuildings = database.query(q);
                

        Map<Id, set<Account>> mapAccts = GetAcctsForBuildingList(gBuildings);
                
        Map<Id, set<string>> mapBuildingAccountNames = GetAccountNameList(mapAccts);
        Map<Id, set<Georesults_Business__c>> mapGRBiz = GetGRBsForBuildingList(gBuildings,mapBuildingAccountNames);
        
        Map<Id, set<Building_Access_Availability__c>> mapBAA = GetBAAForBuildingList(gBuildings);
        //Map<Id, set<Building_Access_Availability__c>> mapBAA = new Map<Id, set<Building_Access_Availability__c>>();
        Map<string,integer> mapGRHasLead = GetLeadsPerGRBusiness(mapGRBiz); 
        //Map<string,integer> mapGRHasLead = new  Map<string,integer>();
            
        set<id> acctsWithOpenOpps = GetAccountsHasOpenOpps(mapAccts);
        
        List<BuildingData> bdList = new List<BuildingData>();
        for(Building__c b :gBuildings){

            //Exclude buildings with no GR Data & exclude buildings with no EoC or EoF records
            //also exclude buildings that are not within the selected access speeds.
            
            if(b.net_classification__c == 'Off-net' && (b.Building_Type__c == null || !(b.Building_Type__c.contains('LSO')))){
                //if(IlecBuildingIsValidForMapping(b,mapGRBiz.get(b.id)) && BuildingHasValidBAAForMapping(b,mapBAA.get(b.id))){
                if(displayIlec && BuildingHasValidBAAForMapping(b,mapBAA.get(b.id)) && IlecBuildingIsValidForMapping(b,mapGRBiz.get(b.id))){
                    BuildingData bd = new BuildingData(b,mapGRBiz.get(b.id),mapBAA.get(b.id),mapAccts.get(b.id),acctsWithOpenOpps,mapGRHasLead,filteredBusRecords);
                    bdList.add(bd);
                }
            }
            else if(b.net_classification__c == 'Near-net' && (b.Building_Type__c == null || !(b.Building_Type__c.contains('LSO')))){
                 if(BuildingHasValidEoFMRRForMapping(b,mapBAA.get(b.id))){
                    BuildingData bd = new BuildingData(b,mapGRBiz.get(b.id),mapBAA.get(b.id),mapAccts.get(b.id),acctsWithOpenOpps,mapGRHasLead,filteredBusRecords);
                    bdList.add(bd);
                }
            }
            else{
                if((b.Building_Type__c.contains('LSO'))){
                    BuildingData bd = new BuildingData(b,mapGRBiz.get(b.id),mapBAA.get(b.id),mapAccts.get(b.id),acctsWithOpenOpps,mapGRHasLead,filteredBusRecords);
                    bdList.add(bd);
               }
               else if(BuildingHasValidBAAForMapping(b,mapBAA.get(b.id))){
                    BuildingData bd = new BuildingData(b,mapGRBiz.get(b.id),mapBAA.get(b.id),mapAccts.get(b.id),acctsWithOpenOpps,mapGRHasLead,filteredBusRecords);
                    bdList.add(bd);
                }
            }
            
            
        } 

        jsonBuildings = json.serialize(bdList);
        
        return null;
    }
            
    private boolean IlecBuildingIsValidForMapping(Building__c b, set<Georesults_Business__c> GRSet){
        boolean isValid = false;
        if(displayAllIlec)
            return true;
        else if(GrSet != null && GrSet.size() > 0)
            return true;
        
        return isValid;
    }       
           
     private boolean BuildingHasValidEoFMRRForMapping(Building__c b, set<Building_Access_Availability__c> BaaSet){
        boolean isValid = false;
        Set<String> BAAEoFTypes = new Set<String>{'EoF','10G CE Interface','10G CE Ring','10G DWDM'};
        if(BaaSet != null && BAASet.size() > 0){
            for(Building_Access_Availability__c baa : BaaSet){
                if(b.Net_Classification__c == 'Near-net' && BAAEoFTypes.contains(baa.Access_Technology_Name__c) && (baa.Minimum_Required_Revenue__c >= selectedMinMRREoF && baa.Minimum_Required_Revenue__c <= selectedMaxMRREoF))
                    return true;
            }   
        }
        
        return isValid;
    }       
    
    private boolean BuildingHasValidBAAForMapping(Building__c b, set<Building_Access_Availability__c> BaaSet){
        boolean isValid = false;
        Set<String> BAAEoFTypes = new Set<String>{'EoF','10G CE Interface','10G CE Ring','10G DWDM'};
        if(BaaSet != null && BAASet.size() > 0){
            for(Building_Access_Availability__c baa : BaaSet){
                if((baa.Access_Technology_Name__c == 'EoC' && (baa.Maximum_Bandwidth__c == null || (baa.Maximum_Bandwidth__c >= selectedMinBAA && baa.Maximum_Bandwidth__c <= selectedMaxBAA))) || BAAEoFTypes.contains(baa.Access_Technology_Name__c))
                    return true; 
            }   
        }
        
        return isValid;
    }       
            
    public map<id,set<string>> GetAccountNameList (map<id,set<Account>> acctMap){
         map<id,set<string>> acctNameMap = new map<id,set<string>>();
         for(id bid : acctMap.keyset()){
            for(Account a :acctMap.get(bid)){
                if(acctNameMap.get(bid) != null){
                    acctNameMap.get(bid).add(a.Name);
                }
                else{
                    set<string> acctNames = new set<string>();
                    acctnames.add(a.Name);
                    acctNameMap.put(bid,acctNames);
                }
            }
         }
         return acctNameMap;
    }       
    
    
    
  public map<Id,set<Georesults_Business__c>> GetGRBsForBuildingList(List<Building__c> buildings, map<id,set<string>> acctNameMap ){
       Map<Id,Georesults_business__c> gbs = new Map<Id,Georesults_business__c>([Select id,busid__c,building__c, CleanBusiness__c,TotalTelSpend__c, Contact__c, Phone__c, CleanAddress__c, Unit__c, City__c, State__c, Zip__c, NAICS2__c, CreatedDate,TotalTelSpendPerMonth__c   From GeoResults_Business__c Where building__c in :buildings and Hide_Prospect__c != true]);
        Map<Id, set<Georesults_Business__c>> mapGRBiz = new Map<Id, set<Georesults_Business__c>>();
        Map<Id,List<Georesults_Business__c>> filteredBuildings = new Map<Id,List<Georesults_Business__c>>();
        filteredBusRecords = new Map<Id,Georesults_business__c>();
      
        if(gbFilterID != gbAllFilterID){
            ApexPages.StandardSetController gbc = new ApexPages.StandardSetController(Database.getQueryLocator('Select id From GeoResults_Business__c limit 1'));
            gbc.setPageSize(2000);
            gbc.setFilterID(gbFilterID);
            if(gbc.getResultSize() <= 10000){
                
                //Max record set 10000, page size 2000, max pages 5
                for(integer i = 1; i <= 5; i++){
                    gbc.setPageNumber(i);
                    for(GeoResults_Business__c gb : (List<GeoResults_Business__c>)gbc.getRecords()){
                        if(gbs.get(gb.Id) != null){
                            GeoResults_Business__c mgb = gbs.get(gb.Id);
                            filteredBusRecords.put(mgb.Id,mgb);
                            if(filteredBuildings.get(mgb.building__c) != null){
                                filteredBuildings.get(mgb.building__c).add(mgb);
                            }
                            else{
                                List<Georesults_Business__c> busRecords = new List<Georesults_Business__c>();
                                busRecords.add(mgb);
                                filteredBuildings.put(mgb.building__c,busRecords);
                            }
                        }
                    }
                }
            }
            else{
                ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, 'Georesults filter returned too many results, limited to 10000.');
                ApexPages.addMessage(m);
                for(Georesults_business__c mgb : gbs.values()){
                    if(filteredBuildings.get(mgb.building__c) != null){
                        filteredBuildings.get(mgb.building__c).add(mgb);
                    }
                    else{
                        List<Georesults_Business__c> busRecords = new List<Georesults_Business__c>();
                        busRecords.add(mgb);
                        filteredBuildings.put(mgb.building__c,busRecords);
                    }
                }
            }
            List<Building__c> tempBuilds = new List<Building__c>();
            for(integer i = 0;i<buildings.size();i++){
                building__c b = buildings[i];
                if(filteredBuildings.get(b.Id) != null)
                    tempBuilds.add(b);
            }   
    
            gBuildings = tempBuilds;
        }
        else{
			for(Georesults_business__c mgb : gbs.values()){
				if(filteredBuildings.get(mgb.building__c) != null){
					filteredBuildings.get(mgb.building__c).add(mgb);
				}
				else{
					List<Georesults_Business__c> busRecords = new List<Georesults_Business__c>();
					busRecords.add(mgb);
					filteredBuildings.put(mgb.building__c,busRecords);
				}
			}
        }       
        
        
        
        for(Georesults_business__c gb : gbs.values()){
            if(filteredBuildings.get(gb.Building__c) != null){
                set<string> acctNames = new set<string>();
                if(acctNameMap.get(gb.Building__c) != null){
                    acctNames = acctNameMap.get(gb.Building__c);
                }
                if(!acctNames.contains(gb.CleanBusiness__c)){
                    if(mapGRBiz.get(gb.Building__c) != null){
                        mapGRBiz.get(gb.Building__c).add(gb);
                    }
                    else{
                        set<GeoResults_Business__c> gbList = new set<GeoResults_Business__c>();
                        gbList.add(gb);
                        mapGRBiz.put(gb.building__c,gbList);
                    }
                }
            }
        }  
        return mapGRBiz;
    }
    
    public Map<string,integer> GetLeadsPerGRBusiness(Map<Id, set<Georesults_Business__c>> mapGRBiz){

        //Map of GRID related to the Bus ID
        Set<Id> GRBusIds = new Set<Id>();
		Map<Id,Id> GRBusToBuilding = new Map<Id,Id>();
        for(set<Georesults_Business__c> gbs : mapGRBiz.values()){
            for(Georesults_Business__c gb : gbs){
                GRBusIds.add(gb.Id);
				GRBusToBuilding.put(gb.id,gb.Building__c);
			}
        }       

        Map<id,List<Lead>> mapGRLeadList = new Map<id,List<Lead>>();
		Map<Id,Id> mapLeadToGR = new Map<id,Id>();
		Set<string> leadStatuses = new Set<string>{'Unqualified','Converted'};
        for(Lead l :[Select Id,Geo_Id__c, OwnerID,GeoResults_Business__c From Lead Where Status not in :leadStatuses and GeoResults_Business__c in :GRBusIds]){
			mapLeadToGR.put(l.id,l.GeoResults_Business__c);
            if(mapGRLeadList.get(l.id) != null)
                mapGRLeadList.get(l.GeoResults_Business__c).add(l);
            else{
                List<Lead> leads = new List<Lead>{l};
                mapGRLeadList.put(l.GeoResults_Business__c,leads);
            }
        }
        
		Set<Id> leads = new Set<Id>();
		if(leadFilterID != 'All'){
			ApexPages.StandardSetController lc = new ApexPages.StandardSetController(Database.getQueryLocator('Select id From Lead limit 1'));
            lc.setPageSize(2000);
            lc.setFilterID(leadFilterID);
            if(lc.getResultSize() <= 10000){
                //Max record set 10000, page size 2000, max pages 5
                for(integer i = 1; i <= 5; i++){
                    lc.setPageNumber(i);
                    for(Lead l : (List<Lead>)lc.getRecords()){
						//Only return buildings where these accounts exist
						leads.add(l.id);
                    }
                }
            }
            else{
                ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, 'Lead filter returned too many results, limited to 10000.');
                ApexPages.addMessage(m);
            }
		}

		system.debug('leads: ' + leads);
		if(leads.size() > 0){
			set<id> buildsToKeep = new set<id>();	

			for(Id leadId: mapLeadToGR.keyset()){
				system.debug('leadId:' + leadId);
				if(leads.contains(leadId)){
					system.debug('leads contained.' + leadId);
					if(GRBusToBuilding.containsKey(mapLeadToGR.get(leadId))){
						buildsToKeep.add(GRBusToBuilding.get(mapLeadToGR.get(leadId)));
					}
				}
			}
			system.debug('buildsToKeep: ' + buildsToKeep);
			for(Integer i=gBuildings.size()-1; i>=0; i--){
				if(!buildsToKeep.contains(gBuildings[i].id))
					gBuildings.remove(i);
			}
		}

        Map<string,integer> mapGRLeadIconDisplay = new Map<string,integer>();
        ID userID = UserInfo.getUserId();
                
        for(string s :mapGRLeadList.keyset()){
            mapGRLeadIconDisplay.put(s,DetermineLeadReturnStatus(mapGRLeadList.get(s),userID));
        }
        
        return mapGRLeadIconDisplay;
    }
    
    private integer DetermineLeadReturnStatus(List<Lead> leads,ID userID){
        /*
            Map of each GR id and which icon to display(1,2,3,4):
            Return of 1: a single lead on this GR Bus but the current user is not the owner
            Return of 2: a single lead on this GR Bus and the current user is the owner
            Return of 3: multiple leads on this GR Bus and the current user does not own any
            Return of 4: multiple leads on this GR Bus and the current user owns one+
        */
            
        integer leadCount = leads.size();
        boolean userHasLead = false;
        for(Lead l :leads){
            if(l.OwnerId == userID){
                userHasLead = true;
                break;
            }
        }
        
        if(leadCount == 1 &&!userHasLead)
            return 1;
        else if(leadCount == 1 && userHasLead)
            return 2;
        else if(leadCount > 1 && !userHasLead)
            return 3;
        else if(leadCount > 1 && userHasLead)
            return 4;
        else return 0;
    }
    
    public map<Id,set<Building_Access_Availability__c>> GetBAAForBuildingList(List<Building__c> buildings){
        Map<Id, set<Building_Access_Availability__c>> mapBAA = new Map<Id, set<Building_Access_Availability__c>>();
        for(Building_Access_Availability__c baa : [Select id,building__c, Access_Technology_Name__c, Minimum_Required_Revenue__c,Maximum_Bandwidth__c,Status__c From Building_Access_Availability__c Where building__c in :buildings]){
            if(mapBAA.get(baa.Building__c) != null){
                mapBAA.get(baa.Building__c).add(baa);
            }
            else{
                set<Building_Access_Availability__c> baaList = new set<Building_Access_Availability__c>();
                baaList.add(baa);
                mapBAA.put(baa.building__c,baaList);
            }
        }   
        return mapBAA;
    }
    
 public map<Id,set<Account>> GetAcctsForBuildingList(List<Building__c> buildings){
        Map<Id, set<Account>> mapAcct = new Map<Id, set<Account>>();
        Map<Id,List<Id>> slAcctMap = new Map<Id,List<Id>>();//map of AccountID,BuildingID
        Set<id> bldgs = new Set<id>();
				
		for(Building__c b : buildings){
			bldgs.add(b.id);    
		}
        
		for(Service_Location__c sl :[Select Account__c,Location__r.building__c From Service_Location__c Where Location__r.building__c in :bldgs]){
			if(slAcctMap.get(sl.Account__c) != null){
				slAcctMap.get(sl.Account__c).add(sl.Location__r.building__c);
			}
			else{
				List<Id> buildList = new List<Id>();
				buildList.add(sl.Location__r.building__c);
				slAcctMap.put(sl.Account__c,buildList);
			}
		}
        
		for(Account a: [Select id,Owner.Name,Name,Type, Shipping_Location__r.Building__c, Protected_Account__c From Account Where (Shipping_Location__r.Building__c in :bldgs or id in :slAcctMap.keyset())  and (NOT Name  like '%System Account%')]){
			if(bldgs.contains(a.Shipping_Location__r.Building__c)){
				if(mapAcct.get(a.Shipping_Location__r.Building__c) != null){
					mapAcct.get(a.Shipping_Location__r.Building__c).add(a);
				}
				else{
					set<Account> acctList = new set<Account>();
					acctList.add(a);
					mapAcct.put(a.Shipping_Location__r.Building__c,acctList);
				}
			}
			if(slAcctMap.get(a.id) != null){
				List<Id> buildIds = slAcctMap.get(a.id);
				for(Id bid : buildIds){
					if(mapAcct.get(bid) != null){
						mapAcct.get(bid).add(a);
					}
					else{
						set<Account> acctList = new set<Account>();
						acctList.add(a);
						mapAcct.put(bid,acctList);
					}
				}
			}
		}

		Set<Id> accts = new Set<Id>();
		if(accountFilterID != 'All'){
			ApexPages.StandardSetController ac = new ApexPages.StandardSetController(Database.getQueryLocator('Select id From Account limit 1'));
            ac.setPageSize(2000);
            ac.setFilterID(accountFilterID);
            if(ac.getResultSize() <= 10000){
                //Max record set 10000, page size 2000, max pages 5
                for(integer i = 1; i <= 5; i++){
                    ac.setPageNumber(i);
                    for(Account a : (List<Account>)ac.getRecords()){
						//Only return buildings where these accounts exist
						accts.add(a.id);
                    }
                }
            }
            else{
                ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, 'Account filter returned too many results, limited to 10000.');
                ApexPages.addMessage(m);
              
            }
		}

		
		if(accts.size() > 0){
			set<id> buildsToKeep = new set<id>();	
			for(Id bid: mapAcct.keyset()){
				for(Account a : mapAcct.get(bid)){
					if(accts.contains(a.id))
						buildsToKeep.add(bid);
				}
			}
			system.debug('buildsToKeep: ' + buildsToKeep);
			for(Integer i=gBuildings.size()-1; i>=0; i--){
				if(!buildsToKeep.contains(gBuildings[i].id))
					gBuildings.remove(i);
			}
		}
		        
        return mapAcct;
    }
    
    public set<id> GetAccountsHasOpenOpps(Map<Id, set<Account>> mapAccts){
        set<id> accts = new set<id>();
        set<Account> acctsToSearch = new set<Account>();
        list<string> closedOppStages = new list<string>{'Closed Won','Stage 5 - Accepted / Order Pending','Closed Lost'};
        for(id gid :mapAccts.keyset()){
            acctsToSearch.addall(mapAccts.get(gid));
        }
        
        for(Opportunity opp : [Select Id, AccountId From Opportunity Where AccountId in :acctsToSearch and StageName not in :closedOppStages]){
            accts.add(opp.AccountId);
        }
        
        return accts;
    }
    
    
    
    public Map<string,List<Building__c>> GetWireCenterSelectItems(){
        Map<string,List<Building__c>> buildingMap = new Map<string,List<Building__c>>();
        List<Building__c> b = new List<Building__c>();
        for(Building__c build : [Select state__c,Building_CLLI__c, Geo_Coordinates__Longitude__s,Geo_Coordinates__Latitude__s,Building_Type__c, Building_Alias__c, No_Regrets_LSO__c from Building__c where Building_Type__c = 'ILEC LSO: Collocated' and (Building_CLLI__c != 'NULL' and Building_CLLI__c != null) Order By State__c desc,Building_CLLI__c]){
            if(buildingMap.get(build.state__c) != null){
                buildingMap.get(build.state__c).add(build); 
            }
            else{
                List<Building__c> builds = new List<Building__c>();
                builds.add(build);
                buildingMap.put(build.state__c,builds);
            }
        }
                
        return buildingMap;
    } 
        
    
    public void CreateLead(){
        Lead l = new Lead();
        l.status = leadStatus;
        l.LeadSource = leadSource;
        l.FirstName = leadFirstName;
        l.LastName = leadLastName == '' ? '.' : leadLastName;
        //l.Geo_Id__c = leadGRId;
        l.GeoResults_Business__c = leadGRId;
        l.Phone = leadPhone;
        l.Company = leadCompany;
        l.Building__c = buildingId;
        //Get location if it exists, otherwise create new
        if(buildingId != null){
            if(leadRoomSuite == null)
                leadRoomSuite = '';
            List<Location__c> locs = [Select Id From Location__c l Where building__c = :buildingId and Room_Suite__c = :leadRoomSuite];
            system.debug('LeadRoomSuite: ' + leadRoomSuite);
            system.debug('BuildingID: ' + buildingId);
            system.debug(locs);
            if(locs.size() > 0)
                l.Location__c = locs[0].Id;
            else{
                //insert new loc
                Location__c loc = new Location__c();
                loc.building__c = buildingId;
                loc.Room_Suite__c = leadRoomSuite;
                
                Insert loc;
                
                l.location__c = loc.id;
            }
        }
        try{
            insert l;
            newLeadId = l.id;
        }
        catch(Exception e){
            newLeadID = null;
            ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, 'Error Inserting Lead: ' + e.getMessage());
            ApexPages.addMessage(m);
        }
    } 
    
    public void CreateOpportunity(){
        
        Opportunity opp = new Opportunity();
        opp.AccountId = oppAccountID;
        opp.StageName = 'Identification';
        opp.Opportunity_Source__c = 'Simplify Prospect Management';
        opp.CloseDate = date.today().addDays(60);
        opp.RecordTypeId = Schema.Sobjecttype.Opportunity.RecordTypeInfosByName.get('Retail').RecordTypeId;
        opp.name = oppAcctName;
        
        UserRecordAccess ura = Test.isRunningTest() ? new UserRecordAccess() : [Select RecordId, HasEditAccess From UserRecordAccess Where UserID = :UserInfo.getUserID() and RecordID = :oppAccountID];
        if(ura.HasEditAccess){
            try{
                insert opp;
                newOppID = opp.id;
            }
            catch(Exception e){
                newOppID = null;
                ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, 'Error Inserting Opportunity: ' + e.getMessage());
                ApexPages.addMessage(m);
            }
        }
        else{
            newOppID = null;
            ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, 'Error Inserting Opportunity: Insufficient Privileges');
            ApexPages.addMessage(m);
        }
        
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_NetworkMap(); }
}