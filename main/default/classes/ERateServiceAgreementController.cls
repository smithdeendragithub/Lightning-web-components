public with sharing class ERateServiceAgreementController{
	
	public Opportunity CurrentOpportunity {get;Set;}
	
	public class Location {
		public String Name {get;Set;}
		public String Address {get;Set;}
		public String City {get;Set;}
		public String State {get;Set;}
		public String Zip {get;Set;}
		public Location(Opportunity_Location__c oloc){
			this.Name = oloc.Service_Location__r.Name;
			this.Address = oloc.Service_Location__r.Location__r.Building__r.Address__c;
			this.City = oloc.Service_Location__r.Location__r.Building__r.City__c;
			this.State = oloc.Service_Location__r.Location__r.Building__r.State__c;
			this.Zip = oloc.Service_Location__r.Location__r.Building__r.Postal_Code__c;
		}
	}
	
	private List<Location> locations{get;Set;}
	public List<Location> OppLocations{
		get{
			if(locations == null){
				locations = getLocationsForOpportunity();
			}
			return locations;
		}
	}
	
	 public List<Location> getLocationsForOpportunity(){
		 List<Location> locs = new List<Location>();
	 	for(Opportunity_Location__c oloc: [Select 
									 		Id, 
									 		Name,
											Service_Location__r.Name,
									 		Service_Location__r.Location__r.Building__r.Address__c,
									 		Service_Location__r.Location__r.Building__r.City__c,
									 		Service_Location__r.Location__r.Building__r.State__c,
									 		Service_Location__r.Location__r.Building__r.Postal_Code__c
							            From Opportunity_Location__c 
							            where Order__r.Opportunity__c=:currentOpportunity.Id AND On_Hold__c=false 
										])
		{
			locs.add(new Location(oloc));								
		}
		return locs;
	 }

}