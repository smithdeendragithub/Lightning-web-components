public with sharing class OpportunityLocationTrigger {
	
	public static void OpportunityLocationModified(Map<Id,Opportunity_Location__c> tNew, Map<Id,Opportunity_Location__c> tOld, Boolean isUpdate, Boolean isBefore){
		
		if(!ApexUtils.executeTriggerMethods('Opportunity_Location__c', isBefore, false)) return;
		
		if(!isBefore){
			if(isUpdate){
				updateChangeOpportunity(tNew);
			}
			
			ApexUtils.afterTriggerComplete('Opportunity_Location__c', false);
		}
	}
	
	private static RecordType turndownRecordType = null;
	private static void updateChangeOpportunity(Map<Id, Opportunity_Location__c> newSol){
		
		Map<Id,Id> oppsLocs = new Map<Id,Id>();
		for(Opportunity_Location__c oLocs : [Select Id, Opportunity__c From Opportunity_Location__c Where id in :newSol.keyset()]){
			oppsLocs.put(oLocs.Opportunity__c ,oLocs.Id);
		}

		Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>([Select id, RecordType.Name from Opportunity Where id in :oppsLocs.keySet() and RecordType.Id in: OpportunityUtils.ChangeRecordTypes]);

		
		 //Determine turndown recordtype on opportunity_product__c
		if(turndownRecordType == null){
			turndownRecordType = [Select id From  RecordType  Where Name = 'Turndown/Writedown' and SobjectType = 'Opportunity_Product__c' Limit 1];
		}
		
		//Because user can undo turndowns, we 1st need to clear out any turndown opp products that may have previously been created for this opp.
		List<Opportunity_Product__c> delprds = [Select Id, Name, Sales_Product__c From Opportunity_Product__c WHERE Opportunity__c in : oppsMap.keyset() AND RecordType.Id = : turndownRecordType.Id];
		if(delprds.size() > 0) delete delprds;
		
		List<Opportunity_Product__c> oprds = new List<Opportunity_Product__c>();
		for(Disconnect_Line_Item__c dprds : [select Id
													,Name
													,EPCProductDescription__c
													,MRC__c
													,Opportunity_Location__r.On_Hold__c
													,Opportunity_Location__r.Opportunity__c
													,Opportunity_Location__r.Service_Location__c
													from Disconnect_Line_Item__c
													where Opportunity_Location__r.Opportunity__c in :oppsMap.keyset()]){
														
			Opportunity_Location__c opLoc = dprds.Opportunity_Location__r;
			
			Opportunity_Product__c op = new Opportunity_Product__c();
			op.Active__c = opLoc.On_Hold__c == true ? false : true;
			op.MRC__c = - dprds.MRC__c;
			op.Opportunity__c = opLoc.Opportunity__c;
			op.Primary_Service_Location__c = opLoc.Service_Location__c;
			op.RecordTypeId = turndownRecordType.Id;
			op.SE_Upsell__c = false;
			op.Sales_Product__c = dprds.EPCProductDescription__c;
			oprds.add(op);
		}
		
		if(oprds.size() > 0) insert oprds;
	}
}