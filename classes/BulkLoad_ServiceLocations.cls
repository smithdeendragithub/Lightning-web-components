public with sharing class BulkLoad_ServiceLocations implements TestUtils.ITestableClass {
   //Constant for batchID (bid) parameter name
   private static final String PARAMETER_BATCH_ID = 'bid';
   public Account acc {get;set;}
   public Service_Location__c sl {get;set;}
   public Opportunity_Location__c ol {get;set;}
   public List<BatchViewWrapper> locView {get;set;}
   public String batchID {get;set;}
   public String selection {get;set;}
   
  public ContentVersion file { get; set; }
       
    public class BatchViewWrapper{
    	public String AddressKey {get;set;}
    	public Integer BatchID {get;set;}
        public Integer BroadbandSpeed {get;set;}
        public String BuildingHash {get;set;}
        public String City {get;set;}
        public Integer DSLSpeed {get;set;}
        public Decimal Elevation {get;set;}
        public String ErrorMessages {get;set;}
        public Integer EthernetSpeed {get;set;}
        public Boolean InFootprint {get;set;}
        public Boolean Is60MbpsCapable {get;set;}
        public Boolean IsCarrierEthernetCapable {get;set;}
        public String LEC {get;set;}
        public Decimal Latitude {get;set;}
        public String ListedName {get;set;}
        public String LocalServiceOffice {get;set;}
        public Decimal Longitude {get;set;}
        public String OnNetCLLI {get;set;}      
        public String PostalCode {get;set;}
        public Boolean Processed {get;set;}
        public String RateCenter {get;set;}
        public String State {get;set;}
        //MNK added Aug 2017
        public String Country {get;set;}
        public String StreetAddress {get;set;}
        public Boolean Success {get;set;}
        public String TelephoneNumber {get;set;}
        public String WireCenterCLLI {get;set;}
        public integer AccessTechID {get;set;}
        public integer Bandwidth {get;set;}
        public integer AddressID {get;set;}
        
        public BatchViewWrapper(integraWS.SFBatchLocationView view){
        	this.AddressKey = view.AddressKey;
        	this.BatchID = view.BatchID;
        	this.BroadbandSpeed = view.BroadbandSpeed;
        	this.BuildingHash = view.BuildingHash;
        	this.City = view.City;
        	this.DSLSpeed = view.DSLSpeed;
        	this.Elevation = view.Elevation;
        	this.ErrorMessages = view.ErrorMessages;
        	this.EthernetSpeed = view.EthernetSpeed;
        	this.InFootprint = view.InFootprint;
        	this.Is60MbpsCapable = view.Is60MbpsCapable;
        	this.IsCarrierEthernetCapable = view.IsCarrierEthernetCapable;
        	this.LEC = view.LEC;
        	this.Latitude = view.Latitude;
        	this.ListedName = view.ListedName;
        	this.LocalServiceOffice = view.LocalServiceOffice;
        	this.Longitude = view.Longitude;
        	this.OnNetCLLI = view.OnNetCLLI;
        	this.PostalCode = view.PostalCode;
        	this.Processed = view.Processed;
        	this.RateCenter = view.RateCenter;
            //MNK Added Aug 2017
            this.Country = view.Country;
        	this.State = view.State;
        	this.StreetAddress = view.StreetAddress;
        	this.Success = view.Success;
        	this.TelephoneNumber = view.TelephoneNumber;
        	this.WireCenterCLLI = view.WireCenterCLLI;
        	this.AccessTechID = view.AccessTechID;
        	this.Bandwidth = view.Bandwidth;
        	this.AddressID = view.AddressID;
        }
    }
	public PageReference bulkQualify(){
		try{
			User u = [Select Id,Email,Ntid__c From User where id = :UserInfo.getUserId()];
			integraWS.SFBulkQualView bqv = new integraWS.SFBulkQualView();
			 if(Test.isRunningTest()){
                bqv.Success = true;
                bqv.BatchJobID = 4000;
            }
            else			
				bqv = integraWSEndpointMediator.Endpoint.BulkGeoCodeFromContent(EncodingUtil.base64Encode(file.VersionData),u.NTID__c,u.Email, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
				
			system.debug('BQV: ' + bqv);
			if(bqv.Success){
				batchID = string.valueof(bqv.BatchJobID);
				saveContent();
								
				PageReference pageRef = new PageReference('/apex/BulkLoad_ServiceLocations?bid=' + string.valueof(bqv.BatchJobID));
				pageRef.setRedirect(true);
				system.debug(pageRef);
				return pageRef;
			}
			else
			{
				List<string> errors = bqv.MessageArray.string_x;	
				messageDisplay(string.join(errors,';'));
				return null;
			}
		}
		catch(Exception e){
            messageDisplay(e.getMessage());
            return null;
        }
		
	}
	
	public void saveContent(){
		List<ContentWorkspace> workspaces = [Select Id From ContentWorkspace Where name = 'BulkServiceLocation'];
		if(workspaces.isEmpty()){
			messageDisplay('No bulk service location workspace found.');
		}
		else
		{
			//inserts content version
			if(file.versionData != null){
				insert file;
				
				ContentVersion doc = [select ContentDocumentId from ContentVersion where id = :file.id];
				ContentWorkspaceDoc docLink = new ContentWorkspaceDoc();
	        	docLink.ContentDocumentId = doc.ContentDocumentId;
	        	docLink.ContentWorkspaceId = workspaces[0].id;
	        	insert docLink;
			}
			else
				messageDisplay('No file chosen.');
		}
	}

    public pagereference searchdata(){
		if(sl.Account__c == null){ 
			messageDisplay('Please enter an Account Name');
		}
		else {
			acc = [Select Id, Name From Account Where Id = :sl.Account__c limit 1];
			selection = acc.Name;
		}
        return null;
	}
	
	public pagereference searchSLocs()
	{
		 if(ol.Service_Location__c == null){ 
			messageDisplay('Please enter a Service Location');
		}
		else {
			sl = [Select Id, Name,Account__r.Name From Service_Location__c Where Id = :ol.Service_Location__c limit 1];
			selection = sl.Name;
		}
		 return null;
	}
	
	public pagereference attach()
	{
		//get list of building hashes where processed = true or addressID not null
		
		 List<Building__c> b = CreateBuilding(locView);
		 List<Building_Access_Availability__c> baa = CreateBuildingAccessAvailability(b,locView);
         List<Location__c> l = CreateLocation(locView);
         List<Service_Location__c> sLoc = CreateServiceLocation(locView);
        
         if(b != null){
         	messageDisplay('Done! creating Buildings: ' + b.size() + '; Building Access Availability: ' + baa.size() + '; Locations: ' + l.size() + '; Service Locations: ' + sLoc.size() + ' for ' + selection);
         }
         else{
         	messageDisplay('No Buildings/Locations/Service Locations were created for: ' + selection);
         }
		 return null;
	}
	
	
	public void messageDisplay(String Msg){
        ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, Msg);
        ApexPages.addMessage(m);
    }
    
	public BulkLoad_ServiceLocations(){
		if(acc==null && sl==null){ 
		acc = new Account();
		sl = new Service_Location__c();
		ol = new Opportunity_Location__c();
		file = new ContentVersion();
		}
		
		try{
			if(Test.isRunningTest()){
				batchID = '4000';
			}
			else
		    	batchID = Apexpages.currentPage().getParameters().get('bid');
			
			if(batchID != null){
				Integer bid = integer.valueof(batchId);
	            integraWS.ArrayOfSFBatchLocationView blsl = new integraWS.ArrayOfSFBatchLocationView();  
		        blsl.SFBatchLocationView  = new List<integraWS.SFBatchLocationView>();
	
	           if(Test.isRunningTest()){
	                locView = new List<BatchViewWrapper>();
	                integraWS.SFBatchLocationView bv = new integraWS.SFBatchLocationView();
	                
	                bv.AccessTechID = 1;
	                bv.AccessTechName = 'EoC';
	                bv.Bandwidth = 20;
	                bv.BatchID = 4000;
	                bv.BroadbandSpeed = 20;
	                bv.BuildingHash = 'C297B127A56F51C4FFFF8D9B0FBD7085';
	                bv.City = 'Portland';
	                bv.Latitude = 45.529734;
	                bv.Longitude = -122.653195;
	                bv.OnNetCLLI = 'PTLDOR13';
	                bv.PostalCode = '97232';
                    bv.Country = 'US';
	                bv.State = 'OR';
	                bv.StreetAddress = '1201 NE LLoyd Blvd';
	                bv.Success = true;
	                bv.WireCenterCLLI = 'PTLDOR12';
	                
	                blsl.SFBatchLocationView.add(bv);
	                
	                integraWS.SFBatchLocationView bv2 = new integraWS.SFBatchLocationView();
	                bv2.AccessTechID = 1;
	                bv2.AccessTechName = 'EoC';
	                bv2.Bandwidth = 20;
	                bv2.BatchID = 4000;
	                bv2.BroadbandSpeed = 20;
	                bv2.BuildingHash = 'C297B127A56F51C4FFFF8D9B0FBD7044';
	                bv2.City = 'Portland';
	                bv2.Latitude = 45.529734;
	                bv2.Longitude = -122.653195;
	                bv2.OnNetCLLI = 'PTLDOR13';
	                bv2.PostalCode = '97232';
                    bv2.Country = 'US';
	                bv2.State = 'OR';
	                bv2.StreetAddress = '1201 NE LLoyd Blvd';
	                bv2.Success = true;
	                bv2.WireCenterCLLI = 'PTLDORZZ';
	                
	                blsl.SFBatchLocationView.add(bv2);
	                
	                locView = GetViewWrapper(blsl.SFBatchLocationView);
	            }
	            else{
					blsl = integraWSEndpointMediator.Endpoint.GetBatchAddressProcessingResults(bid, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
					system.debug('BLSL: ' + blsl);
					locView = new List<BatchViewWrapper>();
					locView = GetViewWrapper(blsl.SFBatchLocationView);
	         	}
	        }
		}catch(Exception e){
	        messageDisplay(e.getMessage());
        }
	}
		
	public List<BatchViewWrapper> GetViewWrapper(List<integraWS.SFBatchLocationView> views){
		List<BatchViewWrapper> bvws = new List<BatchViewWrapper>();
		for(integraWS.SFBatchLocationView loc : views){
			bvws.add(new BatchViewWrapper(loc));
		}
		
		return bvws; 
	}
	
		public static List<Building__c> CreateBuilding(List<BatchViewWrapper> bRows){

		List<BatchViewWrapper> locs = new List<BatchViewWrapper>();
		Map<string,BatchViewWrapper> blocs = new Map<string,BatchViewWrapper>();
		for(BatchViewWrapper wrap : bRows){
			if(wrap.WireCenterCLLI != null){
				blocs.put(wrap.BuildingHash,wrap);
			}
		}

		Set<String> buds = new Set<String>();
		for(BatchViewWrapper bus : bRows){
			if(bus.BuildingHash != null){
				buds.add(bus.BuildingHash);
			}
		}
		
    	for(Building__c bldg : [Select Id,Serving_LSO__c,Address__c,Building_Hash__c,City__c,Effective_Date__c,House_Number__c,Latitude__c,Longitude__c,Postal_Code__c,State__c,Net_Classification__c,Status__c From Building__c Where Building_Hash__c in :buds]){
    		if(blocs.containsKey(bldg.Building_Hash__c))
    			blocs.remove(bldg.Building_Hash__c);
    		/*for(Integer j = 0; j < blocs.size(); j++){
    			if(blocs.get(j).BuildingHash == bldg.Building_Hash__c || blocs.get(j).BuildingHash == null){
    				blocs.remove(j);
    			}
    		}
    		*/
    	}
    	system.debug(blocs);
    	
       
        Map<string,Building__c> builds = new Map<string,Building__c>();
        if(!blocs.isempty()){
			
            for(BatchViewWrapper bvw : blocs.values()){
	            if(bvw.WireCenterCLLI != null){
	                if(bvw.WireCenterCLLI.length() > 8){
	                   bvw.WireCenterCLLI = bvw.WireCenterCLLI.substring(0,8);
	                }
	            }
            locs.add(bvw);
            }

			Set<String> lso = new Set<String>();           
			for(BatchViewWrapper blc : locs){
				if(blc.WireCenterCLLI != null){
					lso.add(blc.WireCenterCLLI);
				}
			}
            Map<String, Building__c> colo = new Map<String, Building__c>();
            for(Building__c co : [Select Id, Building_CLLI__c From Building__c Where Building_CLLI__c in :lso and (Building_Type__c = 'ILEC LSO: Collocated' or Building_Type__c = 'ILEC LSO: Extended' or Building_Type__c = 'ILEC LSO: Extended Special' or Building_Type__c = 'ILEC LSO: Off Footprint' or Building_Type__c = 'ILEC Remote Switch')]){
            	colo.put(co.Building_CLLI__c, co);
            }
            
            for(BatchViewWrapper loc : locs){
            	if(!builds.containsKey(loc.buildinghash)){
		            Building__c b = new Building__c();
		            
		            b.AddressID__c = loc.AddressID;
		            b.Address__c = loc.StreetAddress;
		            b.Building_Hash__c = loc.BuildingHash;
		            b.Building_Type__c = 'Commercial Building';
		            b.City__c = loc.City;
		            //b.County__c = 'USA';
		            b.Effective_Date__c = Datetime.now().date();
		            //b.House_Number__c = loc.StreetNumber;
		            b.Latitude__c = loc.Latitude;
		            b.Longitude__c = loc.Longitude;
		            b.Postal_Code__c = loc.PostalCode;
                    b.Country__c = loc.Country == null? 'US': loc.Country;
		            b.State__c = loc.State;
		            b.Net_Classification__c = 'Off-net';
		            b.Status__c = 'New';           
			            if(colo.size() > 0){
							Building__c bServing = colo.get(loc.WireCenterCLLI);
							if(bServing != null){
				            	b.Serving_LSO__c = bServing.Id;
							}
							else{
								if(loc.WireCenterCLLI != null){								
									CreateTaskForNoServingLSO(b, loc.WireCenterCLLI);
								}
							}
						}
		            builds.put(b.building_hash__c,b);
            	}
	        }
        }
        if(builds.size() > 0){
        	SecurityUtils.BypassProcesser.saveObjects(builds.values(), true);
        }
        
        return builds.values() == null ? new List<Building__c>() : builds.values();
    }
    
    public List<Building_Access_Availability__c> CreateBuildingAccessAvailability(List<Building__c> buildings,List<BatchViewWrapper> loc){
    	Map<string,BatchViewWrapper> mapBatch = new Map<string,BatchViewWrapper>();
    	List<Building_Access_Availability__c> baas = new List<Building_Access_Availability__c>();
    	for(BatchViewWrapper l : loc){
    		mapBatch.put(l.BuildingHash,l);
    	}
    	
    	Map<decimal,id> AccessTechMap = new Map<decimal,id>();
    	for(Access_Technology__c atech : [Select Id, Access_Technology_ID__c From Access_Technology__c]){
    		AccessTechMap.put(atech.Access_Technology_ID__c,atech.id);
    	}
    	for(Building__c b : buildings){
    		BatchViewWrapper bvw = mapBatch.get(b.Building_Hash__c);
    		if(bvw != null){
    			//Only insert BAA for those records that have an Access Tech ID
    			if(bvw.AccessTechID != null){
    				if(AccessTechMap.get(bvw.AccessTechID) != null){
	    				Building_Access_Availability__c baa = new Building_Access_Availability__c();
	    				baa.Access_Technology__c = AccessTechMap.get(bvw.AccessTechID);
	    				baa.Maximum_Bandwidth__c = bvw.Bandwidth;
	    				baa.building__c = b.Id;
	    				baas.add(baa);
    				}
    			}
    		}
    	}
    	
    	if(baas.size() > 0){
    		insert baas;
    	}
    	
    	return baas;
    	
    }
    
   public static List<Location__c> CreateLocation(List<BatchViewWrapper> loc){
		Map<string,BatchViewWrapper> mapBatch = new Map<string,BatchViewWrapper>();
		Set<String> suite = new Set<String>();
		for(BatchViewWrapper bus : loc){
			if(bus.BuildingHash != null){
				bus.AddressKey = bus.AddressKey == '' ? null : bus.AddressKey;
				suite.add(bus.AddressKey);
			}
		}
    	for(BatchViewWrapper l : loc){
    		if(l.BuildingHash != null){
    			mapBatch.put(l.BuildingHash,l);
    		}
    	}
		List<Location__c> locs = new List<Location__c>();
		Map<String, Location__c> locations = new Map<String, Location__c>();
		//if building hash already in list, don't add it again.
		for(Location__c lc : [Select Id, Building__r.Building_Hash__c, Room_Suite__c From Location__c Where Building__r.Building_Hash__c In : mapBatch.keyset() And Room_Suite__c in :suite]){
			locations.put(lc.Building__r.Building_Hash__c, lc);
		}	
    	for(Building__c b : [Select Id, Building_Hash__c From Building__c Where Building_Hash__c in :mapBatch.keyset()]){

    			Location__c lc = locations.get(b.Building_Hash__c);

    			BatchViewWrapper bvw = mapBatch.get(b.Building_Hash__c);
    			if(lc != null && bvw != null){
    				Boolean locExists = false;
	    			if(bvw.AddressKey == lc.Room_Suite__c){
	    				locExists = true;
	    			}
    				if(lc != null && bvw != null && locExists != true){  					
				            Location__c l = new Location__c();
				            l.building__c = b.Id;
				            l.Room_Suite__c = bvw.AddressKey;
				
				            locs.add(l);
    				}
	        	}
	        	else if(bvw != null){	        	
	        			Location__c l = new Location__c();
			            l.building__c = b.Id;
			            l.Room_Suite__c = bvw.AddressKey;
			
			            locs.add(l);
	        	}
	        
    		}  
   		
system.debug('locs: ' + locs.size());   	
    	if(locs.size() > 0){
			insert locs;
    	}
	    return locs;
   } 
	 public List<Service_Location__c> CreateServiceLocation(List<BatchViewWrapper> loc){  
	 	Set<String> buds = new Set<String>();
	 	Set<String> suite = new Set<String>();
		for(BatchViewWrapper bus : loc){
			if(bus.BuildingHash != null){
				buds.add(bus.BuildingHash);
				suite.add(bus.AddressKey);
			}
		}
        Map<string,BatchViewWrapper> mapBatch = new Map<string,BatchViewWrapper>();
    	for(BatchViewWrapper sl : loc){
    		if(sl.BuildingHash != null){
    			mapBatch.put(sl.BuildingHash,sl);
    		}
    	}
		
		List<Service_Location__c> sLocs = new List<Service_Location__c>();
		Set<Id> locIds = new Set<Id>();
		AggregateResult[] ar = [Select Max(Id) Id, Building__r.Building_Hash__c, Room_Suite__c From Location__c Where Building__r.Building_Hash__c in :buds And Room_Suite__c in :suite GROUP BY Building__r.Building_Hash__c, Room_Suite__c];

		for(AggregateResult locs : ar){
			locIds.add(locs.Id);
		}
		
		for(Location__c locs : [Select Building__r.Id, Building__r.Building_Hash__c, Room_Suite__c From Location__c Where Id in :locIds]){
        		BatchViewWrapper bvw = mapBatch.get(locs.Building__r.Building_Hash__c);
    		if(bvw != null){
			if(bvw.AddressKey == locs.Room_Suite__c && bvw.BuildingHash == locs.Building__r.Building_Hash__c){
	    	Service_Location__c sLoc = new Service_Location__c();
	    	String slName = String.IsEmpty(acc.Name) ? sl.Account__r.Name : acc.Name;
	        sLoc.Name = String.IsEmpty(bvw.ListedName) ? slName : bvw.ListedName;
	        sLoc.Account__c = String.IsEmpty(acc.Id) ? sl.Account__r.Id : acc.Id;
	        sLoc.Location__c = locs.Id;
	        //sLoc.Phone__c = locs.phone;
	        if(!String.IsEmpty(sl.Id)){
	        	sLoc.Parent_Service_Location__c = sl.Id;
	        }
	        sLocs.add(sLoc);
			} 
		}
		}		
		if(sLocs.size() > 0){		
			System.debug(sLocs);
        	insert sLocs;
		}    
        return sLocs;
    }
    
    public static Task CreateTaskForNoServingLSO(Building__c b, string wireCenterCLLI){
        Task t = new Task();
        IntegraServiceSettings__c integraServiceSettings = IntegraServiceSettings__c.getInstance();
        User u = [select id from user where ntid__c = :integraServiceSettings.No_Serving_LSO_Task_Owner__c];
        
        t.OwnerId = u.id;
        t.Subject = 'No Serving LSO found for this newly created building';
        t.WhatId = b.id;
        t.Type = 'Research Request';
        t.Description = 'The wirecenterCLLI provided from address master(' + wireCenterCLLI + ') was not found as a serving LSO.';
        
        insert t;
        
        return t;
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_BulkLoad_ServiceLocations(); }
}