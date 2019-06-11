public with sharing class ProposalLOAController {   
 
 Map<Id, Service_Location__c> serviceLocations = new Map<Id, Service_Location__c>();
   
	public Boolean doRender {get;Set;}
	
    public class LocationWrapper {
		public String localProvider {get;set;}
		public String ldProvider {get;Set;}
		public String tollFreeProvider {get;set;}
        public List<Toll_Free_Number__c> tollFreeNumbers {get;set;}
        public List<DID__c> didNumbers {get;set;}
        public Boolean didRange {get;set;}
        public CompanyInfo locationAddress { get; set; }
        public Opportunity_Location__c rawLocation {get;set;}
		
        public Boolean hasTollFree {get;set;}
        public Boolean hasVoice {get;set;}
        public Boolean hasIntrastate {get;set;}
        public Boolean hasInterstate {get;set;}
		public Boolean hasTollFreeTech {Get;Set;}
		public Boolean hasCNs {get;Set;}
		public Boolean hasVirtualTN {get;Set;}
		
        
        public LocationWrapper(Opportunity_Location__c loc, Map<Id, Service_Location__c> srvloc, Map<Id, Building__c> buildings) {    	
        	localProvider = loc.Current_Provider_Local__c;
			ldProvider = loc.Current_LD_Provider__c;
        	tollFreeProvider = '';
            rawLocation = loc;
            tollFreeNumbers = new List<Toll_Free_Number__c>();
            didNumbers = new List<DID__c>();
            didRange = false;
            //locationAddress = new CompanyInfo(loc.Service_Location__r.Account__r); 
            String serviceLocName = '';
            String serviceLocId = '';           
            String serviceLocSuite = '';
            Service_Location__c sName = srvloc.get(Loc.Service_Location__c);
    		serviceLocName = sName.Name;
    		serviceLocId = sName.Location__r.Building__r.Id;
   			serviceLocSuite = loc.Service_Location__r.Location__r.Room_Suite__c;
       		Building__c bldg = buildings.get(serviceLocId);
            locationAddress = new CompanyInfo(bldg, serviceLocName, serviceLocSuite);    
            
            hasTollFree = false;
            hasVoice = false;
            hasIntrastate = false;
            hasInterstate = false;
			hasCNs = false;
			hasVirtualTN = false;
        }
		
		public Boolean CanDisplay(){
			return ((hasVoice && hasCNs)||
			       (hasVirtualTN && didNumbers.size()>0)||
			       (hasTollFree && tollFreeNumbers.size() > 0)||
			       (hasIntrastate && (hasCNs || didNumbers.size()>0))||
			       (hasInterstate && (hasCNs || didNumbers.size()>0)));
		}
    }

    public List<LocationWrapper> locations { get; set; }
	public List<LocationWrapper> displayLocations {
		get{
			List<LocationWrapper> locs = new List<LocationWrapper>();
			for(LocationWrapper rapper : locations){
				if(rapper.CanDisplay()){
					locs.add(rapper);
				}
			}
			return locs;
		}
	}
    public CompanyInfo clientMainAddress {get;set;}
    
    public Opportunity currentOpportunity {
        get{
            return currentOpportunity;
        }
        set{
            currentOpportunity = value;
            clientMainAddress = new CompanyInfo(currentOpportunity.Account);        
            getOpportunityLocationInfo();
        }
    }
    
    public Map<Id, Service_Location__c> getRelatedServiceLocations(List<Opportunity_Location__c> locations){
    	Set<Id> ids = new Set<Id>();
    	for(Opportunity_Location__c optloc : locations){
    		ids.Add(optloc.Service_Location__c);
    	}
    	 
    	return new Map<Id, Service_Location__c>([SELECT Name, Location__r.Building__r.Id FROM Service_Location__c WHERE Id IN:ids]);
    }
    
     public Map<Id, Building__c> getRelatedBuildings(List<Service_Location__c> locations){
    	Set<Id> ids = new Set<Id>();
    	for(Service_Location__c srvloc : locations){
    		ids.Add(srvloc.Location__r.Building__r.Id);
    	}
    	 
    	return new Map<Id, Building__c>([SELECT Address__c, City__c, State__c, Postal_Code__c FROM Building__c WHERE Id IN:ids]);
    }

    public void getOpportunityLocationInfo(){
        this.doRender = false;
        // don't want to use a map, since want an ordered list
        List<Opportunity_Location__c> rawLocations =  
            [Select Id, Service_Location__r.Location__r.Room_Suite__c, Name, Current_Provider_Local__c, Current_LD_Provider__c,
            Service_Location__r.Account__r.Name, Service_Location__r.Account__r.ShippingState, Service_Location__r.Account__r.ShippingCity, 
            Service_Location__r.Account__r.ShippingStreet, Service_Location__r.Account__r.ShippingPostalCode, 
            Service_Location__r.Account__r.Phone, Service_Location__r.Account__r.Fax,  
            Service_Location__r.Account__r.Local_Service_Provider__c,
            (Select Name From CNs__r ORDER BY Name) 
            From Opportunity_Location__c
            where Order__r.Opportunity__c = :currentOpportunity.Id AND On_Hold__c=false
            ORDER BY Service_Location__r.Account__r.Account_Depth__c, Service_Location__r.Account__r.Name];            
            Map<Id, Service_Location__c> srvloc = getRelatedServiceLocations(rawLocations);
            Map<Id, Building__c> srvlocbuilds = getRelatedBuildings(srvloc.values());
        
	        locations = new List<LocationWrapper>();
	        Set<Id> locIds = new Set<Id>();	        
	        
	        for(Opportunity_Location__c ol : rawLocations){    	
	            locations.add( new LocationWrapper(ol, srvloc, srvlocbuilds));
	            locIds.add(ol.Id);
	        }
        
        Map<Id, RecordType> rtTI = new Map<Id, RecordType>([select		Id, 
        									DeveloperName
		        				   from 	RecordType 
		        				   where 	SObjectType = 'Technical_Information__c'
		        				   and 		(DeveloperName = 'Toll_Free_Services' 
		        				   			or DeveloperName = 'Other_Technical_Notes'
		        				   			or DeveloperName = 'DID'
											or DeveloperName = 'Features_Schedule')]);
        
        
        // need to restrict by record type also
        List<Technical_Information__c> lstTechInfo = 
            [Select Id, 
            		Opportunity_Site__c, 
            		Toll_Free_Provider__c,
            		Current_Service_Provider__c,
					CurrentProvider__c,
					CurrentProviderLD__c,
            		RecordTypeId,
            		(Select Type__c, X8XX_555_5555_Number__c, Ring_to_Number__c, Restrictions__c, X800_Service_Area__c From Toll_Free_Numbers__r ORDER BY X8XX_555_5555_Number__c), 
           			(Select Start__c, End__c From DIDs__r ORDER By Start__c)
            From 	Technical_Information__c
            WHERE 	Opportunity_Site__c in :locIds
            and	  	RecordTypeId in :rtTI.keySet()];
        
        for( Technical_Information__c t : lstTechInfo ) {
            LocationWrapper loc = findLoc(t.Opportunity_Site__c);
            //System.debug('loc Name: ' + loc.rawLocation.Name + ' : L: ' + t.currentProvider__c + ' : LD: ' + t.CurrentProviderLD__c);
			//loc.localProvider = (!string.isEmpty(loc.localProvider) || string.isEmpty(t.CurrentProvider__c)) ? loc.localProvider : t.CurrentProvider__c;
			//loc.ldProvider = (!string.isEmpty(loc.ldProvider) || t.CurrentProviderLD__c == null)? loc.ldProvider : t.CurrentProviderLD__c;
            
			String rtName = rtTI.get(t.RecordTypeId).DeveloperName;
            
            if (rtName == 'Toll_Free_Services') {
            	
            	loc.tollFreeProvider = (t.Toll_Free_Provider__c == null) ? '' : t.Toll_Free_Provider__c;
            
            	if( t.Toll_Free_Numbers__r.size() > 0 ) {
	                for(Toll_Free_Number__c tfn : t.Toll_Free_Numbers__r){
						if(tfn.Type__c == 'Existing Toll-Free Number')
							loc.tollFreeNumbers.add(tfn);
					}
					loc.hasTollFreeTech = true;					
	            }
	            
            } else if (rtName == 'Other_Technical_Notes') {
            	loc.localProvider = string.isEmpty(t.Current_Service_Provider__c) ? loc.localProvider : t.Current_Service_Provider__c;
            	
            } else if (rtName == 'DID') {
            	
	            if( t.DIDs__r.size() > 0 ) {
	                loc.didNumbers.addAll(t.DIDs__r); 
	                if(t.DIDs__r.size() > 1) {
	            		loc.didRange = true;
	            	}
				}
	        }
        }
        
        
        //Get the Inter/Intra/Voice/Toll info
        List<OLI__c> lstOLIs = [Select Id,
        							   OLI__c.OpportunityLocationConfiguration__r.Opportunity_Location__c,
        							   OLI__c.PP_Voice_Line__c,
        							   OLI__c.PP_Toll_Free__c,
        							   OLI__c.PP_LD_Interstate__c,
        							   OLI__c.PP_LD_Intrastate__c,
									   OLI__c.PP_DID_Virtual_TN__c,
									   (select Name from CNs__r)
        					    from   OLI__c
        					    where  OLI__c.OpportunityLocationConfiguration__r.Active__c=true
        					    and    OLI__c.OpportunityLocationConfiguration__r.Opportunity_Location__c in :locIds];   
       
       	for (OLI__c oli : lstOLIs) {
       		LocationWrapper loc = findLoc(oli.OpportunityLocationConfiguration__r.Opportunity_Location__c);
            
			if(!loc.hasCNs && oli.CNs__r != null){ //marked as not, keep trying.  marked as true, we're done.
				for(CN__c cn : oli.CNs__r){
					if(!cn.Name.startsWithIgnoreCase('tn')){
						loc.hasCNs = true;
						break;
					}
				}
			}
		}
		for(OLI__c oli : lstOLIs){
			LocationWrapper loc = findLoc(oli.OpportunityLocationConfiguration__r.Opportunity_Location__c);
			
			loc.hasVoice = (oli.PP_Voice_Line__c || (oli.PP_DID_Virtual_TN__c && (loc.didNumbers.size()>0 || loc.hasCNs)) || loc.hasVoice); //If it's already true, don't set it to false
			loc.hasVirtualTN = (oli.PP_DID_Virtual_TN__c || loc.hasVirtualTN); //If it's already true, don't set it to fase
         	loc.hasTollFree = ((oli.PP_Toll_Free__c && loc.tollFreeNumbers.size() > 0) || loc.hasTollFree); //If it's already true, don't set it to false
         	loc.hasInterstate = (oli.PP_LD_Interstate__c || (loc.hasInterstate && (loc.didNumbers.size()>0 || loc.hasCNs))); //If it's already true, don't set it to false
         	loc.hasIntrastate = (oli.PP_LD_Intrastate__c || (loc.hasIntrastate && (loc.didNumbers.size()>0 || loc.hasCNs))); //If it's already true, don't set it to false
			
			this.doRender |= loc.CanDisplay();
       	}     
    }

    public LocationWrapper findLoc(Id locId) {
        for( LocationWrapper lw : locations ) {
            if( lw.rawLocation.Id == locId)
                return lw;              
        }
        return null;
    }
}