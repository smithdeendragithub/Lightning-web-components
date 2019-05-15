public with sharing class ProposalGenericController {

    public CompanyInfo clientMainAddress {get;set;}
    public Date currentdate {get;set;}
    public String currentDayOrdinal {get;set;}
    public String currentMonthName {get;set;}
    public String currentDay {get;set;}
    public String currentYear {get;set;}
	public List<OpportunityLocationConfiguration__c> locations { get; set; }
	public String techInfo {get;set;}
	public ICB__C icb {get;Set;}
    public Opportunity currentOpportunity {
	    get{
            return currentOpportunity;
        }   
        set {
            currentdate = Date.Today();
            clientMainAddress = new CompanyInfo(value.Account);
            currentOpportunity = value;
            getLocationsForOpportunity();
	        }     
    }

	public class PDFException extends Exception {}
	
	public IncentiveCreditText__c iCText{
		get{
			System.debug('ICB : ' + icb);
			System.debug('No months: ' + icb.Number_Of_Months__c);
			System.debug('Term: ' + currentOpportunity.term__c);
			for(IncentiveCreditText__c ict  : [Select Credit_Text__c From IncentiveCreditText__c Where Number_of_Months__c = :icb.Number_of_Months__c and Term__c = :currentOpportunity.term__c]){
				return ict;
			}
			
			//return default if we don't find a valid combo
			throw new PDFException('Incentive Credit Addendum Error: Invalid combination of month\'s credit for term length. Please ensure Opportunity "Contract Term" field is set and Incentive Credit on ICB is set to a valid option.');
		}
		
	}
	
	public ProposalGenericController() {
   	 
        DateTime d = datetime.now();
        currentDayOrdinal = ApexUtils.numberToOrdinal(string.valueOf(d.day()));
        currentMonthName = d.format('MMMMM');
        currentDay = d.format('dd');
        currentYear = string.valueOf(d.year());
                   
    }   

    public void getLocationsForOpportunity(){
		locations = new List<OpportunityLocationConfiguration__c>();
        List<OpportunityLocationConfiguration__c> lstLocations = 
            [Select Id, Opportunity_Location__r.Service_Location__r.Location__r.Name
            from OpportunityLocationConfiguration__c 
            where Opportunity_Location__r.Order__r.Opportunity__c=:currentOpportunity.Id AND Opportunity_Location__r.On_Hold__c=false AND Active__c=true ];          
    	for( OpportunityLocationConfiguration__c ol : lstLocations ) {
    		locations.add(ol);
    	}
    	
    	Set<String> TI = new Set<String>();
    	for(Technical_Information__c techInfos : [Select Current_Service_Provider__c From Technical_Information__c  Where Opportunity_Site__r.Order__r.Opportunity__c=:currentOpportunity.Id]){
    		if(techInfos.Current_Service_Provider__c != null){
    			TI.Add(techInfos.Current_Service_Provider__c);
    		}
    	} 
    	
    	if(TI.size() > 0){
    		techInfo = '';
    		for(String tInfo : TI){
				if(tInfo != null)   			
    				techInfo= techInfo + tInfo + '; ' ;    				
    			}
    	}
    	
    }    
    
	
}