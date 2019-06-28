public with sharing class CompanyInfo {
    
    public string Name { get; set; }
    public string Street { get; set; }
    public string City { get; set; }
    public string State { get; set; }
    public string Zip { get; set; }
    public string CityStateZip { get; set; }
    public string Phone { get; set; }
    public string MobilePhone { get; set; }
    public string Fax { get; set; }
    public string Email { get; set; }
    public string Title { get; set; }
	public String AccountNumber {get;Set;}
	
	// date stuff
	private Date pTodaysDate {get;Set;}
	private Date todaysDate {
		get{
			if(pTodaysDate == null)
				pTodaysDate = Date.today();
			return pTodaysDate;
		}
	}
    
    private void setFromAccount(Account acct, Boolean useBilling) {
    	Name = acct.Name;
        Phone = acct.Phone;
        Fax = acct.Fax;
        Email = null;
        Title = null;
		AccountNumber = acct.AccountNumber;
        
        if (useBilling) {
        	Street = acct.BillingStreet;
        	City = acct.BillingCity;   
        	State = acct.BillingState; 
        	Zip = acct.BillingPostalCode;	
        } else {
        	Street = acct.ShippingStreet;
        	City = acct.ShippingCity;   
        	State = acct.ShippingState; 
        	Zip = acct.ShippingPostalCode;
        }
        
        CityStateZip = formatCityStateZip(City, State, Zip );
    }
    
    public CompanyInfo(Account acct, Boolean useBilling){
        if( acct == null )
            return;
        
         setFromAccount(acct, useBilling);  
    }
    
    public CompanyInfo(Account acct){
        if( acct == null )
            return;
        
        setFromAccount(acct, false); 
    }
        public CompanyInfo(User owner) {
        if( owner == null )
            return;
        
        if( String.IsEmpty(owner.Preferred_First_Name__c) ) {
        	Name = owner.Name;
        }
        else {
        	Name = owner.Preferred_First_Name__c + ' ' + owner.LastName;
        }
        
        Street = Owner.Street;
        City = Owner.City;  
        State = Owner.State;    
        Zip = Owner.PostalCode;
        Phone = Owner.Phone;
        MobilePhone = Owner.MobilePhone;
        Fax = Owner.Fax;
        Email = Owner.Email;
        Title = Owner.Title;
        CityStateZip = formatCityStateZip(City, State, Zip );   
    }
    
    //check for opportunity indirect agent first, otherwise opp.owner
    public CompanyInfo(Opportunity currentOppId, User owner) {
    	Map<Id,string> opps = new Map<id,string>();
    	Map<Id,string> ocrs = new Map<id,string>();

    	for(Opportunity opp : [Select Id, Name From Opportunity Where Id =: currentOppId.Id And Sales_Channel__c =: 'Indirect Sales' Limit 1]){
    		opps.put(opp.id, opp.Name);
    	}
        if(opps.size() > 0){
        	for(OpportunityContactRole ocr : [Select ContactId, Role From OpportunityContactRole Where OpportunityId =: opps.keyset() And OpportunityContactRole.Role =: 'Agent' Limit 1]){
        		ocrs.put(ocr.ContactId, ocr.Role);
        	}	
        	if(ocrs.size() > 0){
	        	Contact con = [Select Title, Account.Name, Phone, MobilePhone, Name, MailingStreet, MailingState, MailingPostalCode, MailingCity, Fax, Email From Contact Where Id =: ocrs.keyset() Limit 1];
	        	//Name = con.Name + ', ' + con.Account.Name;
	        	Name = con.Name;
	        	Street = con.MailingStreet;
		        City = con.MailingCity;  
		        State = con.MailingState;    
		        Zip = con.MailingPostalCode;
		        Phone = con.Phone;
                MobilePhone = con.MobilePhone;
		        Fax = con.Fax;
		        Email = con.Email;
		        Title = con.Title;
		        CityStateZip = formatCityStateZip(City, State, Zip );
        		}
        	else{
        		return;
        	}

        }
        else{
        	return;
        } 
  
    }
    
    public CompanyInfo(Directory_Listing__c listing) {
        if( listing == null )
            return;
        
        Name = listing.Company_Name__c;
        Street = listing.Address__c;
        City = listing.City__c; 
        State = listing.State__c;   
        Zip = listing.Zip__c;
        Phone = listing.Listing_Telephone_Number__c;
        Fax = null;
        Email = null;
        Title = null;
        CityStateZip = formatCityStateZip(City, State, Zip );   
    }
    public CompanyInfo(Building__c listing, String serviceLocName) {
        if( listing == null )
            return;
        
        Name = serviceLocName;
        Street = listing.Address__c;
        City = listing.City__c; 
        State = listing.State__c;   
        Zip = listing.Postal_Code__c;
        Phone = null;
        Fax = null;
        Email = null;
        Title = null;
        CityStateZip = formatCityStateZip(City, State, Zip );   
    }

    public CompanyInfo(Building__c listing, String serviceLocName, String serviceLocSuite) {
        if( listing == null )
            return;
        
        Name = serviceLocName;
        if(!String.IsEmpty(serviceLocSuite)){
        	Street = listing.Address__c + ' ' + serviceLocSuite;
        }
        else{
        	Street = listing.Address__c;
        }
        
        City = listing.City__c; 
        State = listing.State__c;   
        Zip = listing.Postal_Code__c;
        Phone = null;
        Fax = null;
        Email = null;
        Title = null;
        CityStateZip = formatCityStateZip(City, State, Zip );   
    }

    private string formatCityStateZip( string city, string state, string zip) {
        string total = '';
        
        if( !String.IsEmpty(city) ) {
            total += city;
        }
            
        if( !String.IsEmpty(state) ) {
            if( total != '' )
                total += ', ';
                
            total += state;
        }
        
        if( !String.IsEmpty(zip) ) {
            if( total != '' )
                total += ' ';
                
            total += zip;           
        }
        return total;
    }   
}