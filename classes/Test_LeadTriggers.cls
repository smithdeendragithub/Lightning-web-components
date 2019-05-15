@isTest
public with sharing class Test_LeadTriggers {
    
	static testMethod void TestLeadAfterUpdate() {
			
		Database.LeadConvert convert = new database.LeadConvert();
		
		GeoResults_Business__c b = new GeoResults_Business__c();
		b.CleanAddress__c = '1234 Somewhere st';
		b.City__c = 'Nowhere';
		b.State__c = 'WA';
		b.Zip__c = 54321;
		b.busid__c = -1;
        b.Country__c = 'US';
		insert b;
		
	    Lead l = new Lead();         
        l.Company = 'Acme Leads';
        l.Status = 'Suspect';
        l.LastName = 'Coyote';
        l.FirstName = 'Wile';
        l.LeadSource = 'Simplified Prospect Management';
        l.Phone = '(656) 555-1212';
        l.Street = '124 Parker Rd';
        l.State = 'WI';
        l.PostalCode = '98451';
        l.Country = 'US';
        l.City = 'Elam';
		l.Geo_Id__c = '-1';
    	insert l;
		         	
		convert.setLeadId(l.Id);
		convert.setDoNotCreateOpportunity(true);
        
		LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true limit 1];
		convert.setConvertedStatus(convertStatus.MasterLabel);              
        
		Database.LeadConvertResult result = Database.convertLead(convert);
	}
}