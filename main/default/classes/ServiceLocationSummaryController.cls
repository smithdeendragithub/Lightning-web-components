public with sharing class ServiceLocationSummaryController implements TestUtils.ITestableClass {

	public Account act {get;private Set;}
	public Date d {get;private Set;}
	
	public List<Service_Location__c> ServiceLocs {get; private Set;}
	public Map<Id, List<Building_Access_Availability__c>> BaaListByBuildingId {get; private Set;}
	public Map<Id, Set<Service_Location__c>> ServLocMap  {get; private Set;}
	public Map<Id, Building__c> buildingsMap  {get; private Set;}
	
	public ServiceLocationSummaryController(){
		d = Date.today();
		String accountID = ApexPages.currentPage().getParameters().get('accountId');
		
		if(act == null)
			act = [select Id, OwnerId, Name, Customer_Detail__c from Account where Id = :accountId];
		List<Service_Location__c> sLocs = [select Id
											,Account__c
											,Name
											,ICC_Subscriber_ID__c
											,Parent_Service_Location__c
											,Parent_Service_Location__r.Name
											,Level__c
											,Billable__c
                                           	,Owner_Sales_Channel__c
		    								,Customer_Detail__c
											,Customer_Detail__r.Integration_Status__c
											,Location__r.Building__c
											,Location__r.Building__r.Address__c
											,Location__r.Building__r.State__c
											,Location__r.Building__r.City__c
											,Location__r.Building__r.In_Market__c
											,Location__r.Building__r.Status__c
											,Location__r.Building__r.Net_Classification__c
											,Location__r.Building__r.Building_Type__c
											,Location__r.Building__r.Postal_Code__c
											,Location__r.Building__r.Serving_LSO__r.In_Market__c
											,Location__r.Building__r.Is_Serving_LSO__c
											,Location__r.Building__r.Building_CLLI__c
											
											,Location__r.Building__r.Serving_LSO__r.ID
											,Location__r.Building__r.Serving_LSO__r.Address__c
											,Location__r.Building__r.Serving_LSO__r.State__c
											,Location__r.Building__r.Serving_LSO__r.City__c
											,Location__r.Building__r.Serving_LSO__r.Postal_Code__c
											,Location__r.Building__r.Serving_LSO__r.Building_CLLI__c
											,Location__r.Building__r.Serving_LSO__r.Building_Alias__c
											
											from Service_Location__c where Account__c = :accountID];
		Set<Service_Location__c> sLocsToShow = new Set<Service_Location__c>();
		List<Service_Location__c> servLocs = new List<Service_Location__c>();
		Set<Id> possibleParentSlocIds = new Set<Id>();
		Set<Id> buildingIDs = new Set<Id>();
		Set<Building__c> buildingsSet = new Set<Building__c>();
		ServLocMap = new Map<Id, Set<Service_Location__c>>();
		BuildingsMap = new Map<Id,Building__c>();
		BaaListByBuildingId = new Map<Id, List<Building_Access_Availability__c>>();
		Set<Service_Location__c> tempSvcLocs;
		
		Integer startSize = -1;
		while(startSize != sLocsToShow.size()){
			startSize = sLocsToShow.size();
			
			for(Service_Location__c sLoc : sLocs){
				if(sLoc.Account__c == accountID){
					sLocsToShow.add(sloc);
					buildingIDs.add(sloc.location__r.Building__c);
					possibleParentSlocIds.add(sLoc.Id);
				}
				if(sLoc.Parent_Service_Location__c != null && possibleParentSlocIds.contains(sLoc.Parent_Service_Location__c)){
					sLocsToShow.add(sLoc);
					
					buildingsSet.add(sloc.location__r.Building__r);
				}
				
				tempSvcLocs = ServLocMap.get(sloc.location__r.Building__c);
				if (tempSvcLocs == null){
					tempSvcLocs = new Set<Service_Location__c>();
				}
				tempSvcLocs.add(sloc);
				ServLocMap.put(sloc.location__r.Building__c, tempSvcLocs);				
				Buildingsmap.put(sloc.location__r.building__r.id,sloc.location__r.building__r);
			}
		}

		for(Id bid : ServLocMap.keySet()){
			if(ServLocMap.get(bid) != null){
				for(Service_Location__c sLoc : ServLocMap.get(bid)){
					BaaListByBuildingId.put(sLoc.Location__r.building__c, new List<Building_Access_Availability__c>());
				}
			}
		}
		
		for(Building_Access_Availability__c baa : [select Id, Building__c, Access_Technology_Name__c, Carrier__c, Maximum_Bandwidth__c, Minimum_Bandwidth__c, Minimum_Required_Revenue__c, Wholesale_Hurdle__c, Status__c from building_Access_Availability__c where building__c in :buildingIDs]){
			List<Building_Access_Availability__c> baaList = null;
			if(BaaListByBuildingId.get(baa.building__c) != null)
				baaList = BaaListByBuildingId.get(baa.building__c);
			else
				baaList = new List<Building_Access_Availability__c>();			
			baaList.add(baa);			
			BaaListByBuildingId.put(baa.Building__c, baaList);
		}		
		ServiceLocs = new List<Service_Location__c>();
		ServiceLocs.addAll(sLocsToShow);		
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_ServiceLocationSummaryController(); }
}