public with sharing class CreateBuildingUsingGoogleAddress /*implements TestUtils.ITestableClass*/ {
    
    /*public Account locAccount {get;set;}
    public String selectedParent {get;set;}
    
    public List<SelectOption> availableParentLocs {get; private set;}
	
	public List<Building__c> foundBuildings {get;Set;}
	public transient string jsonbuildingBAA {get;Set;}
	
	public Id buildingID {get;Set;}
    public string streetNumber {get;set;}
    public string street {get;set;}
    public string suite {get;set;}
    public string city {get;set;}
    public string postalCode {get;set;}
    public string latitude {get;set;}
    public string longitude {get;set;}
    public string state {get;set;}
    public string returnURL {get;set;}
    public string phone {get;set;}
    public string overrideName {get;set;}
    public boolean billable {get;set;}
	public Boolean manualCreate {get;Set;}
	
	public Boolean readOnlyMode {get; set;}
    
	public Boolean canManuallyCreateBuilding{
		get{
			return CustomSettingUtils.currentUserHasCustomPermission('Can_Manually_Create_Building__c');
		}
	}
	
	
    public void messageDisplay(String Msg){
        ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, Msg);
        ApexPages.addMessage(m);
    }

    public CreateBuildingUsingGoogleAddress() {
        try{
			foundBuildings = new List<Building__c>();
            jsonBuildingBAA = '';
			LocAccount = [Select Id, Name, OwnerId, Customer_Detail__c From Account Where id = :ApexPages.currentPage().getParameters().get('Id')];
            readOnlyMode = !SecurityUtils.currentUserHasRecordAccess(LocAccount.Id, true);
            
            if(!readOnlyMode){
            	availableParentLocs = new List<SelectOption>();
				
	            //availableParentLocs.add(new SelectOption('', 'None'));
	            for(Service_Location__c sLoc : (List<Service_Location__c>)Database.Query('select Id, Name, ICC_Subscriber_ID__c From Service_Location__c where Account__c = \'' + LocAccount.Id + '\''
																					 	+ ' and (Parent_Service_Location__c = null' + (LocAccount.Customer_Detail__c != null ? (' or Parent_Service_Location__r.Customer_Detail__c = \'' + LocAccount.Customer_Detail__c + '\'') : '') + ')'
																						+ ' order by Name, ICC_Subscriber_ID__c')){
	                availableParentLocs.add(new SelectOption(sLoc.Id, sLoc.Name + (!string.isEmpty(sLoc.ICC_Subscriber_ID__c) ? (' [' + sLoc.ICC_Subscriber_ID__c + ']') : '')));
					
	            }
				
	            returnURL = ApexPages.currentPage().getParameters().get('retURL');
	            //testCB = false;
            }
            else
            	messageDisplay('You do not have access to modify this account. Please reach out to the Sales Ops Coordinators to build the service location for you or contact the account owner to approve your read/write access to the account.');
        }
        catch(Exception e){
            messageDisplay(e.getMessage());
        }
    }
    
	public PageReference createServiceLocOnExistingBuild(){
		if(buildingID != null){
			Location__c l = AddressUtils.CreateLocation(buildingID, suite, true);	
			Service_Location__c sLoc = CreateServiceLocation(l, null);
			
		  	if(returnURL != null){
				PageReference pr = new PageReference(returnURL);
				String retURL = ApexPages.currentPage().getParameters().get('retURL2');
				if(!String.isEmpty(retURL))
					pr.getParameters().put('retURL', retURL);
                return pr;
			}
            else
                return new PageReference('/' + locAccount.Id);
		}
		
		return null;
	}
	
    public pageReference ValidateBuildingAddress(){
        try{
           integraWS.SFLocationView locView = Test.isRunningTest() ? Test_CreateBuildingUsingGoogleAddress.getMockLocationView() : integraWSEndpointMediator.Endpoint.ValidateBuildingAddress(CreateSFLocationView(), UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint,manualCreate);

            if(locView.Success){
                if(locView.BuildingHash != null && locView.BuildingHash != ''){
                    
                    Building__c b = AddressUtils.CreateBuilding(locView, true, manualCreate);
                    Location__c l = AddressUtils.CreateLocation(b, locView, true);
                    Service_Location__c sLoc = CreateServiceLocation(l, locView);
                    integraws.ArrayOfLocationAccessAndBandwithResults baas = locView.AccessAndBandwidthResults;
                    List<Building_Access_Availability__c> baaRecords = CreateBuildingAccessAvailabilities(baas,b);
                    if(returnURL != null){
						PageReference pr = new PageReference(returnURL);
						String retURL = ApexPages.currentPage().getParameters().get('retURL2');
						if(!String.isEmpty(retURL))
							pr.getParameters().put('retURL', retURL);
                        return pr;
					}
                    else
                        return new PageReference('/' + locAccount.Id);
                }
                else
                    messageDisplay('No building hash found.');
            }
            else{
               if(locView.Messages != null)
                    messageDisplay(string.join(locView.Messages.string_x,','));
                else
                    messageDisplay('Unable to validate address.');
                    
                //Create task
                Task t = new Task();
                IntegraServiceSettings__c integraServiceSettings = IntegraServiceSettings__c.getInstance();
                User u = [select id from user where ntid__c = :integraServiceSettings.No_Serving_LSO_Task_Owner__c];

                t.OwnerId = u.id;
                t.Subject = 'Unable to create service location';
                t.WhatId = LocAccount.id;
                t.Type = 'Research Request';
                t.ActivityDate = Date.today();
                string errorMessage = '';
                if(locView.Messages != null)
                    errorMessage = string.join(locView.Messages.string_x,',');
                    
                t.Description = 'Unable to create service location.\nSupplied address:\nStreet: ' + street + '\nSuite: ' + suite + '\nCity: ' + city + '\nState: ' + state + '\nZip: ' + postalCode
                + '\nAddress Master Details:' + errorMessage;
                
                insert t;
            }
                
        }catch(Exception e){
                //Create task
                Task t = new Task();
                IntegraServiceSettings__c integraServiceSettings = IntegraServiceSettings__c.getInstance();
                User u = [select id from user where ntid__c = :integraServiceSettings.No_Serving_LSO_Task_Owner__c];
                
                t.OwnerId = u.id;
                t.Subject = 'Unable to create service location';
                t.WhatId = LocAccount.id;
                t.Type = 'Research Request';
                t.ActivityDate = Date.today();
                t.Description = 'Unable to create service location.\nSupplied address:\nStreet: ' + street + '\nSuite: ' + suite + '\nCity: ' + city + '\nState: ' + state + '\nZip: ' + postalCode 
                + '\nException details:\n' + e.getMessage();
                
                insert t;
            
            messageDisplay(e.getMessage());
        }
        
        return null;
    }
  
    public integraWS.SFLocationView CreateSFLocationView(){
        integraWS.SFLocationView loc = new integraWS.SFLocationView();
        if(latitude == '' || latitude == null){
            messageDisplay('Latitude must be supplied.');
        }
        if(longitude == '' || longitude == null){
            messageDisplay('Longitude must be supplied.');
        }
            
        loc.Latitude = latitude == null ? 0 : decimal.valueof(latitude);
        loc.Longitude = latitude == null ? 0 : decimal.valueof(longitude);
        
        loc.StreetNumber = streetNumber;
        loc.Street = street;
        loc.SubPremise = suite;
        loc.City = city; 
        loc.State = state;
        loc.PostalCode = postalCode;
        system.debug('loc: ' +loc);
        return loc;
    } 
	public static integraWS.SFLocationView CreateSFLocationViewFromParams(Decimal Latitude, Decimal Longitude, String StreetNumber, String Street, String Suite, String City, String State, String PostalCode)
	{
		integraWS.SFLocationView loc = new integraWS.SFLocationView();
                    
        loc.Latitude = Latitude;
        loc.Longitude = Longitude;
        
        loc.StreetNumber = StreetNumber;
        loc.Street = Street;
        loc.SubPremise = Suite;
        loc.City = City;
        loc.State = State;
        loc.PostalCode = PostalCode;
        
        return loc;
	}
    
    public Service_Location__c CreateServiceLocation(Location__c l, integraWS.SFLocationView loc){
        
        if(l == null) return null;

        Service_Location__c sLoc = new Service_Location__c
        								(
        									Name = string.IsEmpty(overrideName) ? locAccount.Name : overrideName
        									,Account__c = locAccount.id
        									,Location__c = l.id
        									,Phone__c = phone
        									,Billable__c = billable
        									,Parent_Service_Location__c = !string.IsEmpty(selectedParent) && selectedParent != 'None' ? selectedParent : null
        									,Owner__c = locAccount.OwnerId
        								);
        System.debug(sLoc);
        insert sLoc;
        
        return sLoc;
    }
    
    public decimal GetBandwidthValue(integer availBandwidth){
        decimal bandwidth = (availBandwidth/1000);
        if(bandwidth >= 3 && bandwidth < 5)
            return 3;
        else if(bandwidth >= 5 && bandwidth < 10)
            return 5;
        else if(bandwidth >= 10 && bandwidth < 15)
            return 10;
        else if(bandwidth >= 15 && bandwidth < 20)
            return 15;
        else if(bandwidth >= 20 && bandwidth < 25)
            return 20;
        else if(bandwidth >= 25 && bandwidth < 30)
            return 25;
        else if(bandwidth >= 30 && bandwidth < 40)
            return 30;
        else if(bandwidth >= 40 && bandwidth < 45)
            return 40;
        else if(bandwidth >= 45 && bandwidth < 50)
            return 45;
        else if(bandwidth >= 50 && bandwidth < 60)
            return 50;
        else 
            return bandwidth;

    }
    
	/*
    public List<Building_Access_Availability__c> CreateBuildingAccessAvailabilities (integraws.ArrayOfLocationAccessAndBandwithResults baas, Building__c bldg){
        
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
	                        decimal availBandwidth = GetBandwidthValue(v.AvailiableBandwidth);
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
					update b;
					upsert baaRecords;
				}
        	}
        }
        return baaRecords;

    }
	*/
	//@RemoteAction
	//public static List<BuildingReturnResult> GetBuildingsInRadius(Double Latitude, Double Longitude, String StreetName, String StreetNumber){
		//System.debug('lat: ' + latitude);
		//System.debug('long: ' + Longitude);
		//System.debug('streetNumber: ' + streetNumber);
		
		//integraWS.ArrayOfSFLocationView locationViews = integraWSEndpointMediator.Endpoint.GetSimilarBuildingsWithinRadius(latitude, longitude, /*streetName using empty for now*/'24th', streetNumber, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint); 
		//System.debug('Kit - location views: ' + locationViews.SFLocationView);
		//List<BuildingReturnResult> results = new List<BuildingReturnResult>();
		//if(locationViews != null && locationViews.SFLocationView != null){
		//	for(integraWS.SFLocationView locView : locationViews.SFLocationView){
		//		System.debug('Kit - locationHash: ' + locView.BuildingHash);
		//		BuildingReturnResult result = GetReturnResultFromLocView(locView);
		//		if(result != null)
		//			results.add(result);
		//	}
		//}
		//return results;
	//	return new  List<BuildingReturnResult>();
		
	//}
	/*
	@RemoteAction
	public static BuildingReturnResult BuildingIsValid(Double Latitude, Double Longitude, String StreetName, String StreetNumber, String Suite, String City, String State, String PostalCode){
		if(Test.isRunningTest())
			return GetReturnResultFromLocView(Test_CreateBuildingUsingGoogleAddress.getMockLocationView());
		else{	//validate the address first.
			integraWS.SFLocationView locView = integraWSEndpointMediator.Endpoint.ValidateBuildingAddress(CreateSFLocationViewFromParams(Latitude, Longitude, StreetNumber, StreetName, Suite, City, State, PostalCode), UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint,false);
			return GetReturnResultFromLocView(locView);
		}
	}
	
	private static BuildingReturnResult GetReturnResultFromLocView(integraWS.SFLocationView locView){
		List<Building__c> bldgs = [select Id, Net_Classification__c from Building__c where Building_Hash__c = :locView.BuildingHash];
		Building__c bldg = bldgs.size() > 0? bldgs[0] : null;
		List<Building_Access_Availability__c> baa = [select Access_Technology_Name__c, Available_Bandwidth__c, Minimum_Required_Revenue__c, Status__c, Building__c, Maximum_Bandwidth__c from Building_Access_Availability__c where building__r.Building_Hash__c = :locView.BuildingHash and (Access_Technology_Name__c = 'EoF' or Access_Technology_Name__c = 'EoC')];
		System.debug('Kit - building: ' + bldg);
		System.debug('Kit - location view: ' + locView);
		System.debug('Kit - BuildingAccess: ' + baa);
		BuildingReturnResult result = new BuildingReturnResult(bldg, locView, baa, bldg != null);	
		return result;
	}
	
	public class BuildingReturnResult
	{
		public Building_Access_Availability__c EoF {get;Set;}
		public Building_Access_Availability__c EoC {get;Set;}
		public String NetClassification {get;Set;}
		public Boolean IsValid {get;Set;}
		public String FormattedAddress {get;Set;}
		public String Latitude {get;Set;}
		public String Longitude {get;Set;}
		public Id Id{get;Set;}
		public BuildingReturnResult(){}
		
		public BuildingReturnResult(Building__c bldg, integraWS.SFLocationView loc, List<Building_Access_Availability__c> baas, Boolean FoundIt){
			IsValid = FoundIt;
			
			if(bldg != null){
				NetClassification = bldg.Net_Classification__c;
				Id = bldg.Id;
			}
			else{
				NetClassification = '';	
			}
			for(Building_Access_Availability__c baa : baas){
				if(baa.Access_Technology_Name__c == 'EoF')
					EoF = baa;
				if(baa.Access_Technology_Name__c == 'EoC')
					EoC = baa;
			}
			FormattedAddress = (loc.Street!=null && loc.Street.startsWith(loc.StreetNumber)? '' : (loc.StreetNumber == null? '': loc.StreetNumber)) + ' ' + (loc.Street == null? '' : loc.Street)  + ' ' + (loc.City == null? '' : loc.City) + ', ' + (loc.State == null? '' : loc.State) + ' ' + (loc.PostalCode == null? '' : loc.PostalCode) + ' ' + (loc.Country == null? '' : loc.Country);
			Latitude = String.ValueOf(loc.Latitude);
			Longitude = String.ValueOf(loc.Longitude);
		}
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
	
	public PageReference SearchBuildings(){
		foundBuildings = new List<Building__c>();
		string address = streetNumber + ' ' + street + ' ' + postalCode;
		address = replaceStreetTypes(replaceDirectionals(address)).replace('  ',' ');
		System.debug('address: ' + address);
		String searchString = '*'+address+'*';
		if(searchString.length() > 2){
			String searchQuery = 'FIND \'' + searchString + '\' IN ALL FIELDS RETURNING  Building__c (Id,Name,Address__c,City__c,County__c,State__c,Postal_Code__c,Net_classification__c,Building_Type__c,Status__c,Building_CLLI__c,Serving_LSO__r.Name, Latitude__c, Longitude__c order by Address__c) ';
			List<List <sObject>> searchList = search.query(searchQuery);

		
			foundBuildings = (List<Building__c>)searchList[0];
		}

		jsonBuildingBAA = json.serialize(getSearchedBuildingBAA());
		system.debug(jsonBuildingBAA);
		
		return null;
	}
	
	private Map<Id,List<Building_Access_Availability__c>> getSearchedBuildingBAA(){
		Map<Id,List<Building_Access_Availability__c>> buildBAA = new Map<Id,List<Building_Access_Availability__c>>();
		
		for(Building_Access_Availability__c baa : [select Access_Technology_Name__c, Available_Bandwidth__c, Minimum_Required_Revenue__c, Status__c, Building__c, Maximum_Bandwidth__c from Building_Access_Availability__c where building__c in :foundBuildings and (Access_Technology_Name__c = 'EoF' or Access_Technology_Name__c = 'EoC')]){
			if(buildBAA.containsKey(baa.Building__c)){
				buildBAA.get(baa.Building__c).add(baa);
			}
			else{
				buildBAA.put(baa.Building__c,new List<Building_Access_Availability__c>{baa});
			}
		}
		System.debug('buildBAA: ' + buildBAA);
		return buildBAA;
	}
	*/
	/* TestUtils.ITestableClass methods */
	//public TestUtils.TestClass getTestClass(){ return new Test_CreateBuildingUsingGoogleAddress(); }
}