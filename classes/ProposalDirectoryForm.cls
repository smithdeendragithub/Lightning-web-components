public with sharing class ProposalDirectoryForm {
    
    private final Opportunity_Location__c oppLocation;
    public CompanyInfo clientMainAddress {get;set;}
    public CompanyInfo clientBillingAddress {get;set;}
    
    
    public class DirectoryListing {
        public Directory_Listing__c rawListing {get;set;}
        public CompanyInfo listingAddress {get;set;}
        
        public DirectoryListing(Directory_Listing__c dl) {
            rawListing = dl;
            listingAddress = new CompanyInfo(dl);
        }
    }


    public List<DirectoryListing> listings {get;set;}
    
    //public List<Technical_Information__c> techInfo {get;set;} 
      public Technical_Information__c  techInfo {get;set;}
      public String summarywork {get;set;}
      public String servicelimit {get;set;}
      
        
    public Opportunity currentOpportunity {
        get{
            return currentOpportunity;
        }
        set{
            currentOpportunity = value;
            clientMainAddress = new CompanyInfo(currentOpportunity.Account);
try{
            techInfo = [Select SummaryOfWork__c, Service_Limits__c From Technical_Information__c  Where Opportunity_Site__r.Order__r.Opportunity__c=:currentOpportunity.Id And (SummaryOfWork__c != null Or Service_Limits__c != null)];
			if((! String.IsEmpty(techInfo.SummaryOfWork__c)) || (! String.IsEmpty(techInfo.Service_Limits__c))) {
				summarywork = techInfo.SummaryOfWork__c;
				servicelimit = techInfo.Service_Limits__c;
			}else {
				summarywork = 'No Info Entered';
				servicelimit = 'No Info Entered';
			}
			
}catch(exception e) 
{
ApexUtils.messageDisplay(e.getMessage());
}
            if (! String.IsEmpty(currentOpportunity.Account.BillingStreet)) {
            	clientBillingAddress = new CompanyInfo(currentOpportunity.Account, true);
            } else {
            	clientBillingAddress = new CompanyInfo(currentOpportunity.Account);
            }            
            
            getOpportunityInfo();
        }
    }

    public void getOpportunityInfo(){
        
        List<Directory_Listing__c> rawListings =
            [Select Company_Name__c, Address__c, City__c, State__c, Zip__c, Listing_Telephone_Number__c, Type__c, Which_Directory__c, Main_Listing__c
            From Directory_Listing__c 
            where Technical_Information__r.Opportunity_Site__r.On_Hold__c=false AND Technical_Information__r.Opportunity_Site__r.Order__r.Opportunity__c=:currentOpportunity.Id
            ORDER BY Technical_Information__r.Opportunity_Site__r.Account__r.Account_Depth__c,  Technical_Information__r.Opportunity_Site__r.Account__r.Name];
            
        listings = new List<DirectoryListing>();
        for( Directory_Listing__c dl : rawListings ) {
            listings.add(new DirectoryListing(dl));
        }   

		//List<Technical_Information__c> techInfos = ApexUtils.retrieveFullObjects(Technical_Information__c.sObjectType, 'Opportunity_Site__c=\'' + currentOpportunity.Id +'\'');        

    }       
}