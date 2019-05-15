public without sharing class TaskTriggers{
	
    public static void TaskModified(List<Task> tNew, List<Task> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('Task', isBefore, isDelete)) return;
		
        if(isBefore){
        }
        else{
			if(!isDelete){
				if(isUpdate){
					Map<Id, Task> tOldMap = new Map<Id, Task>(tOld);
					OpportunityUtils.deleteRelatedDateFieldTasks(tNew, tOldMap);
				}
				else{
					handleGeoResultsConversionTaskInsert(tNew);
				}
			}
			
			ApexUtils.afterTriggerComplete('Task', isDelete);
    	}
    }
	
	public static void handleGeoResultsConversionTaskInsert(List<Task> tNew){
		
		Map<Id, Id> grbToOwnerID = new Map<Id, Id>();
		for(Task t : tNew){
			if(t.Type == 'GeoResults Conversion') grbToOwnerID.put(t.WhatId, t.Description);
		}
		
		if(grbToOwnerID.size() > 0){
			List<Map<Id, Id>> batches = new List<Map<Id, Id>>();
			for(Id k : grbToOwnerID.keySet()){
				if(batches.size() == 0 || batches[batches.size()-1].size() == 20) batches.add(new Map<Id, Id>());	//Limit 20 so batch of 200 calls 10 futures, don't pass more than 200 to this function from non-triggered contexts
				batches[batches.size()-1].put(k, grbToOwnerID.get(k));
			}
			
			for(Map<Id, Id> batch : batches) asynch_convertGeoResults(batch);
		}
	}
	
	@future(callout=true)
	private static void asynch_convertGeoResults(Map<Id, Id> grbToOwnerID){
		convertGeoResults(grbToOwnerID);
	}
	
	public static void convertGeoResults(Map<Id, Id> grbToOwnerID){
		
		Map<Id, Id> noLead = new Map<Id, Id>();
		Map<Id, Georesults_business__c> grMap = new Map<Id, Georesults_business__c>([select Id, (select Id from Leads__r where Related_Account__c = null) from Georesults_business__c where Id in: grbToOwnerID.keyset()]);
		for(Georesults_business__c gr : grMap.values()){
			if(gr.Leads__r == null || gr.Leads__r.size() == 0) noLead.put(gr.Id, grbToOwnerID.get(gr.Id));
		}
		
		if(noLead.size() > 0) AddressUtils.CreateLeadsFromGeoResultsBusinesses(noLead);
		
		sObjectType lt = Lead.getSObjectType();
		Set<Id> grIDs = grMap.keySet();
		String allLeadFields = SchemaUtils.RetrieveFullObjectFields(lt);
		Map<Id, Lead> grLeadMap = new Map<Id, Lead>();
		for(Lead l : (List<Lead>)Database.query('select ' + allLeadFields + ' from Lead where Georesults_business__c in: grIDs and Related_Account__c = null'))
			grLeadMap.put(l.Georesults_business__c, l);
		
		List<Lead> keep = grLeadMap.values();
		List<Lead> convert = new List<Lead>();
		for(Lead l : keep) convert.add((Lead)ApexUtils.deepCopyFields(lt, l, new Lead(), null));
		
		List<Database.SaveResult> sr = Database.Insert(convert, false);
		
		AccountTriggers.DisableTrigger = true;
		ContactTriggers.DisableTrigger = true;
		LeadTriggers.DisableTrigger = true;
		OpportunityTriggers.triggerDisabled = true;
		
		Set<Id> removeTaskGRBIDs = new Set<Id>();
		Set<Id> newAccountIDs = new Set<Id>();
		for(Integer i=convert.size()-1; i>=0; i--){
			if(sr[i].isSuccess()){
				Database.LeadConvert lc = new Database.LeadConvert();
				lc.setLeadId(convert[i].id);
				lc.convertedStatus = 'Converted';
				lc.setDoNotCreateOpportunity(true);
				Database.LeadConvertResult lcr = Database.convertLead(lc);
				
				delete convert[i];
				keep[i].Related_Account__c = lcr.getAccountId();
				removeTaskGRBIDs.add(keep[i].Georesults_business__c);
				newAccountIDs.add(keep[i].Related_Account__c);
			}
			else keep.remove(i);
		}
		//Clean up so we're just left with the lead and account
		delete [select Id from Contact where AccountId in: newAccountIDs];
		
		OpportunityTriggers.triggerDisabled = false;
		LeadTriggers.DisableTrigger = false;
		ContactTriggers.DisableTrigger = false;
		AccountTriggers.DisableTrigger = false;
		
		//Allow the triggers to fire
		update keep;
		update [select Id from Account where Id in: newAccountIDs];
		delete [select Id from Task where WhatId in: removeTaskGRBIDs and Type = 'GeoResults Conversion'];
	}
}