@isTest
public with sharing class Test_OpportunityTriggerTaskCreation extends TestUtils.TestClass {
    
    static testMethod void testDetermineClosedWonTasksNeeded() {
        List<User> users = new List<User>();
        
        Mocks m = new Mocks();
		User u = m.user;
		
		Opportunity o = m.opportunity;
		Building__c b = m.building;
		List<OLI__c> olis = m.lstLineItems;
		Opportunity_Product__c opProd = m.opptyPrd;
		
		b.Net_Classification__c = 'On-net';
		update b;
		
		Access_Technology__c atech = new Access_Technology__c(Name='Test', Access_Technology_ID__c=2);	//EoF
		insert atech;
		
		Building_Access_Availability__c baa = new Building_Access_Availability__c(Building__c=b.Id, Access_Technology__c=atech.Id);
		insert baa;
		
		Opportunity_Task_Definition__c taskDef = new Opportunity_Task_Definition__c(Name='TestDef', Task_Subject__c='Subject', Task_Description__c='Description', Task_Type__c='TaskType', Task_Activity_Date_Offset__c=1, Task_Reminder_Date_Offset__c=1);
		insert taskDef;
		
		Process_Configuration__c pc = new Process_Configuration__c(Name='Test', Process__c='RegionAE', Key__c='Default', Value__c=u.NTID__c);
		insert pc;
		
		Opportunity_BAA_Based_Action__c bba = new Opportunity_BAA_Based_Action__c(Name='Test', Task_Assignee__c='RegionalAE,Owner', Task_Definition__c='TestDef', Task_Parent__c='Order', Send_Task_Email__c=true);
		insert bba;
		
		Opportunity_Product_Task_Mapping__c optm = new Opportunity_Product_Task_Mapping__c(Name='Test', Product_Name__c=opProd.Sales_Product__c, Task_Definition__c='TestDef');
		insert optm;
		
		test.startTest();
		
        OpportunityTriggerTaskCreation.determineClosedWonTasksNeeded(new Map<Id, Opportunity>{o.Id=>o});
		
		test.stopTest();
    }
	
    static testMethod void testCreateICertsFromOpportunitiesWon() {
        Mocks m = new Mocks();
		
		Opportunity_Location__c oppLoc = m.location;
		oppLoc.Term__c = '12';
		update oppLoc;
		
		Building__c b = m.building;
		b.Net_Classification__c = 'On-net';
		update b;
		
		Opportunity opp = m.opportunity;
		
		test.startTest();
		
		OpportunityTriggerTaskCreation.createICertsFromClosedWonOpportunities(new Set<Id>{opp.Id});
		
		test.stopTest();
	}
}