@isTest
public with sharing class Test_OpportunityProductTriggers {
	
    static testMethod void testOpportunityProductUpdates() {
		OpportunityProductTriggers opt = new OpportunityProductTriggers();
		test.startTest();
        Mocks testData = new Mocks();
        
    	Opportunity_Product__c op = testData.opptyPrd;
    	List<Opportunity_Product__c> ops = new List<Opportunity_Product__c>();
    	ops.add(op);
    	List<Opportunity_Product__c> moprd = new List<Opportunity_Product__c>();
    	
    	for(Opportunity_Product__c prd : ops){    		
    		moprd.add(prd);
    	}
    	List<Opportunity_Product__c> moprdClone = moprd.deepClone();
    	List<Opportunity_Product__c> prod = new List<Opportunity_Product__c>();
    	for(Opportunity_Product__c oppPrd : [Select Id, Sales_Product__c, Opportunity__c, Primary_Service_Location__c, MRC__c FROM Opportunity_Product__c Where Id = : op.Id] ){		
    		oppPrd.MRC__c = 129.99;
    		prod.add(oppPrd);
    	}
    	update prod;
		
		List<Opportunity_Product__c>  oppProdMap = new List<Opportunity_Product__c> ();
    	for(Opportunity_Product__c oprd : [Select Id, Sales_Product__c From Opportunity_Product__c where Id =: op.Id Limit 1]){
    		oppProdMap.add(oprd);
    	}
		
        test.stopTest();
    }
}