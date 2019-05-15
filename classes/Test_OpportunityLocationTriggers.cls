@isTest
public with sharing class Test_OpportunityLocationTriggers {
	
    static testMethod void testOpportunityLocationTrigger() {
    	OpportunityLocationTrigger oppLocator = new OpportunityLocationTrigger();
    	test.startTest();
    	
    	Mocks testData = new Mocks();

    	Opportunity_Location__c ol = testData.Location;
    	List<Opportunity_Location__c> ols = new List<Opportunity_Location__c>();
    	ols.add(ol);
    	Map<Id,Opportunity_Location__c> moloc = new Map<Id,Opportunity_Location__c>();

    	for(Opportunity_Location__c loc : ols){    		
    		moloc.put(loc.Id, loc);
    	}
    	Map<Id,Opportunity_Location__c> molocClone = moloc.deepClone();
    	List<Opportunity_Location__c> mol = new List<Opportunity_Location__c>();

		for(Opportunity_Location__c oppLoc : molocClone.values()) {
			oppLoc.On_Hold__c = true;
			mol.add(oppLoc);
		}
		 	
		update mol;
    	//OpportunityLocationTrigger.OpportunityLocationModified(molocClone, moloc, true, true);
    	
    	//OpportunityLocationTrigger.UpdateChangeOpportunity(molocClone);
    	test.stopTest();
    }
}