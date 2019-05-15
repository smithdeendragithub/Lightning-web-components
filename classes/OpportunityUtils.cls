public without sharing class OpportunityUtils {
	
	//public static final String STAGE_CONTRACT_DELIVERED = 'Contract Delivered';
	public static final String STAGE_CLOSED_LOST = 'Closed Lost';
	public static final String STAGE_CLOSED_WON = 'Closed Won';
	public static final String STAGE_QUALIFIED = 'Qualified';
	//public static final String STAGE_PROPOSED = 'Proposed';
	public static final String STAGE_CONTRACT_NEGOTIATION = 'Contract Negotiation';
	public static final String STAGE_CONTRACT_SIGNED = 'Contract Signed';
	public static final String STAGE_4 = 'Stage 4 - Contract Signed / Won';    
    public static final String STAGE_5 = 'Stage 5 - Accepted / Order Pending';    
    	
	private static Set<Id> changeRts;
	public static Set<Id> ChangeRecordTypes{
		get{
			if(changeRts == null){
				changeRts = new Map<Id, RecordType>([Select Id, Description, Name, DeveloperName, SobjectType from RecordType WHERE SobjectType = 'Opportunity' and DeveloperName in ('Retail', 'Order Fast Track')]).keyset();
			}
			return changeRts;
		}
	}
	
	public static Boolean oppIsClosed(Opportunity o){
		return o.StageName == STAGE_CLOSED_LOST || o.StageName == STAGE_CONTRACT_SIGNED || o.StageName == STAGE_CLOSED_WON || o.StageName == STAGE_4 || o.StageName == STAGE_5;
	}
    
    public static Map<Id, List<OpportunityLocationConfiguration__c>> getOLCsFromOpportunities(Map<Id, Opportunity> opps, Set<String> sLocFields){
    	Map<Id, List<OpportunityLocationConfiguration__c>> retval = new Map<Id, List<OpportunityLocationConfiguration__c>>();
    	
    	Set<Id> oppIDs = opps.keyset();
    	String soql = 'select MRC_Total__c, Opportunity_Location__r.MRC_Total__c, Opportunity_Location__r.Turndown_Total__c, Opportunity_Location__r.Opportunity__c ,Opportunity_Location__r.Service_Location__r.Id';
    	if(sLocFields != null){
	    	for(String str : sLocFields)
	    		soql += ' ,Opportunity_Location__r.Service_Location__r.' + str;
    	}
    	soql += ' from OpportunityLocationConfiguration__c where Active__c = true and Opportunity_Location__c != null and Opportunity_Location__r.Service_Location__c != null and Opportunity_Location__r.On_Hold__c = false and Opportunity_Location__r.Opportunity__c in: oppIDs';
 
    	for(OpportunityLocationConfiguration__c olc : ((List<OpportunityLocationConfiguration__c>) Database.query(soql))){
    		List<OpportunityLocationConfiguration__c> olcs = retval.get(olc.Opportunity_Location__r.Opportunity__c);
    		if(olcs == null)
    			olcs = new List<OpportunityLocationConfiguration__c>();
    		olcs.add(olc);
    		retval.put(olc.Opportunity_Location__r.Opportunity__c, olcs);
    	}
    	return retval;
    }
    
    public static Map<Id, List<Opportunity_Product__c>> getOppProdsFromOpportunities(Map<Id, Opportunity> opps, Set<String> sPrdFields){
    	Map<Id, List<Opportunity_Product__c>> retval = new Map<Id, List<Opportunity_Product__c>>();
    	
    	Set<Id> oppIDs = opps.keyset();
    	String str = '';
    	String soql = 'select PP_Sales_Product__c, Opportunity__c, Id from Opportunity_Product__c where Opportunity__c in: oppIDs and Active__c = true and PP_Sales_Product__c in: sPrdFields';

    	for(Opportunity_Product__c op : ((List<Opportunity_Product__c>) Database.query(soql))){
    		List<Opportunity_Product__c> ops = retval.get(op.Opportunity__c);
    		if(ops == null)
    			ops = new List<Opportunity_Product__c>();
    		ops.add(op);
    		retval.put(op.Opportunity__c, ops);
    	}
    	return retval;
    }
    
    public static Map<Id, List<Opportunity_Location__c>> getOpportunityLocationsFromOLCMap(Map<Id, List<OpportunityLocationConfiguration__c>> oppIDToOLCs){
    	Map<Id, List<Opportunity_Location__c>> oLocations = new Map<Id, List<Opportunity_Location__c>>();
    	for(Id id : oppIDToOLCs.keyset()){
    		for(OpportunityLocationConfiguration__c olc : oppIDToOLCs.get(id)){
	            List<Opportunity_Location__c> locs = oLocations.get(id);
	            if(locs == null)
	                locs = new List<Opportunity_Location__c>();
	
	            locs.add(olc.Opportunity_Location__r);
	            oLocations.put(id, locs);
    		}
    	}
        return oLocations;
    }
    
    public static Map<Id, List<Service_Location__c>> getServiceLocationsFromOpportunities(Map<Id, Opportunity> opps){
    	Map<Id, List<Service_Location__c>> sLocs = new Map<Id, List<Service_Location__c>>();
    	
    	/* Remove after ODI */
    	Map<Id, List<Opportunity_Location__c>> oLocs = getOpportunityLocationsFromOLCMap(getOLCsFromOpportunities(opps, new Set<String>{'Account__r.Id'
                                                                                            ,'Account__r.ICC_Account_Number__c'
                                                                                            ,'Account__r.ICC_Account_Type__c'
                                                                                            ,'Account__r.Type'
                                                                                            ,'ICC_Subscriber_ID__c'
                                                                                            ,'Level__c'
                                                                                            ,'Parent_Service_Location__r.Id'
                                                                                            ,'Parent_Service_Location__r.ICC_Subscriber_ID__c'}));
        
    	Set<Id> existingLocs = new Set<Id>();
    	Map<Id, Service_Location__c> parentServiceLocs = new Map<Id, Service_Location__c>();
    	for(Id id : oLocs.keyset()){
            for(Opportunity_Location__c oLoc : oLocs.get(id)){
                List<Service_Location__c> locs = sLocs.get(id) != null ? sLocs.get(id) : new List<Service_Location__c>();
                locs.add(oLoc.Service_Location__r);
                sLocs.put(id, locs);
                
				existingLocs.add(oLoc.Service_Location__c);
	        	if(oLoc.Service_Location__r.Parent_Service_Location__c != null)
	        		parentServiceLocs.put(oLoc.Service_Location__r.Parent_Service_Location__c, null);
            }
        }
        /* Remove after ODI */
    	
    	for(Opportunity_Product__c oppLoc : [select Id
    											,Opportunity__c
    											,Primary_Service_Location__r.Id
    											,Primary_Service_Location__r.Account__r.Id
												,Primary_Service_Location__r.Account__r.ICC_Account_Number__c
												,Primary_Service_Location__r.Account__r.ICC_Account_Type__c
												,Primary_Service_Location__r.Account__r.Type
												,Primary_Service_Location__r.Customer_Detail__r.Id
												,Primary_Service_Location__r.ICC_Subscriber_ID__c
												,Primary_Service_Location__r.Level__c
												,Primary_Service_Location__r.Parent_Service_Location__r.Id
												,Primary_Service_Location__r.Parent_Service_Location__r.ICC_Subscriber_ID__c
    											from Opportunity_Product__c
    											where Opportunity__c in : opps.keyset()
    												and Primary_Service_Location__c != null
    												and Active__c = true]){
			List<Service_Location__c> sLocList = sLocs.get(oppLoc.Opportunity__c) != null ? sLocs.get(oppLoc.Opportunity__c) : new List<Service_Location__c>();
			sLocList.add(oppLoc.Primary_Service_Location__r);
			existingLocs.add(oppLoc.Primary_Service_Location__c);
        	sLocs.put(oppLoc.Opportunity__c, sLocList);
        	if(oppLoc.Primary_Service_Location__r.Parent_Service_Location__c != null)
        		parentServiceLocs.put(oppLoc.Primary_Service_Location__r.Parent_Service_Location__c, null);
    	}
    	if(parentServiceLocs.size() > 0){
    		parentServiceLocs = new Map<Id, Service_Location__c>([select Id
    																	,Account__r.Id
																		,Account__r.ICC_Account_Number__c
																		,Account__r.ICC_Account_Type__c
																		,Account__r.Type
																		,Customer_Detail__r.Id
																		,ICC_Subscriber_ID__c
																		,Level__c
																		,Parent_Service_Location__r.Id
																		,Parent_Service_Location__r.ICC_Subscriber_ID__c
																		from Service_Location__c
																		where Id in : parentServiceLocs.keyset()
																			and Id not in : existingLocs]);
			for(List<Service_Location__c> sLocList : sLocs.values()){
				List<Service_Location__c> appendParents = new List<Service_Location__c>();
				for(Service_Location__c sLoc : sLocList){
					if(sLoc.Parent_Service_Location__c != null && !existingLocs.contains(sLoc.Parent_Service_Location__c) && parentServiceLocs.get(sLoc.Parent_Service_Location__c) != null){
						appendParents.add(parentServiceLocs.get(sLoc.Parent_Service_Location__c));
						existingLocs.add(sLoc.Parent_Service_Location__c);
					}
				}
				for(Service_Location__c append : appendParents)
					sLocList.add(append);
			}
    	}
    	
    	return sLocs;
    }
	
	public static Map<Id, Opportunity> getChangedStagedOpportunities(List<Opportunity> tNew, Map<Id, Opportunity> tOldMap, Set<String> stageNames){
        Map<Id, Opportunity> retval = new Map<Id, Opportunity>();
        for(Opportunity o :tNew){
			Opportunity oOld = tOldMap.get(o.id);
            if(stageNames.contains(o.StageName) && (oOld == null || oOld.StageName != o.StageName))
                retval.put(o.Id, o);
        }
        return retval;
    }
	
	private static Map<String, Id> templateIDsByName = null;
	public static void sendWorkflowAndApprovalEmail(Id parentObjectID, String templateName, List<User> mcUserList){
		if(templateIDsByName == null){
			templateIDsByName = new Map<String, Id>();
			for(EmailTemplate et : [select Id, DeveloperName from EmailTemplate where Folder.DeveloperName = 'Workflow_and_Approval_Templates'])
				templateIDsByName.put(et.DeveloperName, et.Id);
		}
		
		Id etID = templateIDsByName.get(TemplateName);
		if(etID != null){
			for(User u : mcUserList){
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();               
	        	email.setTemplateId(etID);
				email.setTargetObjectId(u.Id);
				
				email.setSaveAsActivity(false);
				email.setWhatId(parentObjectID);
				
				email.setBccSender(false);
				email.setUseSignature(false);
				
		        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
			}
		}
	}

	public static Map<Id, Contact> getResponsiblePartyForOpportunity(LIST<Opportunity> Opps){
		Map<Id, Contact> ContactByOppId = new Map<Id, Contact>();
		Map<Id, Id> OppIdByAccountId = new Map<Id,Id>();
		for(Opportunity opp : Opps){
			OppIdByAccountId.put(opp.AccountID, opp.Id);
		}
		
		List<Contact> cs = [select (Select Contact_Type__c from Customer_Contacts__r), c.Name, c.HasOptedOutOfEmail, c.Default_Responsible_Party__c, c.AccountId from Contact c where c.AccountId in :OppIdByAccountId.keyset()];
		for(Contact c : cs){
			if(c.Default_Responsible_Party__c){
				ContactByOppId.put(OppIdByAccountId.get(c.accountId), c);
			}
			else{
				for(Customer_Contact__c cc : c.Customer_Contacts__r){
					if(cc.Contact_Type__c == 'Responsible Party'){
						ContactByOppId.put(OppIdByAccountId.get(c.accountId), c);
					}
				}
			}
		}
		return ContactByOppId;
		
	}
	
	private static Map<Id, Id> salesEngineersByOppID;
	public static Map<Id, Id> getSalesEngineersByOppID(Set<Id> oppIDs){
		salesEngineersByOppID = salesEngineersByOppID == null ? new Map<Id, Id>() : salesEngineersByOppID;
		Set<Id> whatWeDontHave = new Set<Id>();
		for(Id oppId : oppIds){
			if(!salesEngineersByOppID.keyset().contains(oppId))
				whatWeDontHave.add(oppId);
		}
		if(whatWeDontHave.size() > 0){
			for(OpportunityTeamMember otm : [select OpportunityId, UserId from OpportunityTeamMember where OpportunityId in: whatWeDontHave and TeamMemberRole = 'Sales Engineer'])
    			salesEngineersByOppID.put(otm.OpportunityId, otm.UserId);
		}
		return getIdsFromMap(oppIDs, salesEngineersByOppID);
	}
	
	private static Map<Id, Id> salesEngineersByAcctID;
	public static Map<Id, Id> getSalesEngineersByAcctID(Set<Id> acctIDs){
		salesEngineersByAcctID = salesEngineersByAcctID == null ? new Map<Id, Id>() : salesEngineersByAcctID;
		Set<Id> whatWeDontHave = new Set<Id>();
		for(Id acctId : acctIds){
			if(!salesEngineersByAcctID.keyset().contains(acctId))
				whatWeDontHave.add(acctId);
		}
		if(whatWeDontHave.size() > 0){
			for(AccountTeamMember atm : [select AccountId, UserId from AccountTeamMember where AccountId in: whatWeDontHave and TeamMemberRole = 'Sales Engineer'])
    			salesEngineersByAcctID.put(atm.AccountId, atm.UserId);
		}
		return getIdsFromMap(acctIDs, salesEngineersByAcctID);
	}
	
	public static Map<Id, User> getUsers(List<Opportunity> opps, Set<Id> additionalUserIDs){
		Set<Id> ownerIDs = new Set<Id>();
		for(Opportunity o : opps)
			ownerIDs.add(o.OwnerId);
		
		return new Map<Id, User>([select Id, Email, NTID__c, State, Sales_Channel__c from User where Id in: ownerIDs or Id in: additionalUserIDs]);
	}
	
	private static Map<Id,Id> getIdsFromMap(Set<Id> ids, Map<Id,Id> daMap){
		Map<Id,Id> ret = new Map<Id,Id>();
		for(Id i : ids)
			ret.put(i, daMap.get(i));
		return ret;
	}
	
	private static final Map<String, String> taskTrackedDateFields = new Map<String, String>{ 'Initial_Appointment_Held_Date__c'=>'Initial Appointment Held'
																								, 'Initial_Appointment_Set_Date__c'=>'Initial Appointment Set'
																								, 'Proposal_Meeting_Held_Date__c'=>'Proposal Meeting Held'
																								, 'Proposal_Meeting_Set_Date__c'=>'Proposal Meeting Set' };
	public static void updateRelatedDateTasks(List<sObject> tNew, Map<Id, sObject> tOldMap){
		Set<String> availableFields = SchemaUtils.RetrieveFullObjectFieldSet(SchemaUtils.GetSObjectTypeByID(tNew[0].Id));
		
		Map<Id, Set<String>> updated = new Map<Id, Set<String>>();
		for(sObject sNew : tNew){
			Set<String> s = new Set<String>();
			sObject sOld = tOldMap != null ? tOldMap.get(sNew.Id) : null;
			for(String f : taskTrackedDateFields.keyset()){
				if(availableFields.contains(f) && ((sOld == null && sNew.get(f) != null) || (sOld != null && sOld.get(f) != sNew.get(f)))) s.add(f);
			}
			
			if(s.size() > 0) updated.put(sNew.Id, s);
		}
		
		if(updated.size() > 0) updateRelatedDateTasks(tNew, updated);
	}
		
	public static void updateRelatedDateTasks(List<sObject> objs, Map<Id, Set<String>> updated){
		Map<Id, sObject> objMap = new Map<Id, sObject>(objs);
		
		Map<Id, Map<String, Task>> existingMap = new Map<Id, Map<String, Task>>();
		for(Task t : [select Id, WhatId, WhoId, Type from Task where (WhatId in: updated.keyset() or WhoId in: updated.keyset()) and Type in: taskTrackedDateFields.values()]){
			for(Id relatedId : new Set<Id>{ t.WhatId, t.WhoId }){
				if(relatedId != null){
					Map<String, Task> m = existingMap.get(relatedId) != null ? existingMap.get(relatedId) : new Map<String, Task>();
					m.put(t.Type, t);
					existingMap.put(relatedId, m);
				}
			}
		}
		
		List<Task> upsertTasks = new List<Task>();
		List<Task> deleteTasks = new List<Task>();
		
		for(Id id : updated.keySet()){
			sObject obj = objMap.get(id);
			Map<String, Task> m = existingMap.get(id) != null ? existingMap.get(id) : new Map<String, Task>();
			for(String updateField : updated.get(id)){
				Date val = (Date)obj.get(updateField);
				String taskType = taskTrackedDateFields.get(updateField);
				
				Task t = m.get(taskType);
				if(val == null && t != null) deleteTasks.add(t);
				else if(val != null){
					if(t == null){
						t = new Task(Subject = taskType
									,OwnerId = (Id)obj.get('OwnerId')
									,Status = 'Completed'
									,Type = taskType);
						if(SchemaUtils.GetSObjectNameByID(id) == 'Lead') t.WhoId = id;
						else t.WhatId = id;
					}
					t.ActivityDate = val;
					upsertTasks.add(t);
				}
			}
		}
		
		if(deleteTasks.size() > 0) SecurityUtils.BypassProcesser.deleteObjects(deleteTasks, true);
		if(upsertTasks.size() > 0) SecurityUtils.BypassProcesser.saveObjects(upsertTasks, true);
	}
	
	public static void deleteRelatedDateFieldTasks(List<Task> tNew, Map<Id, Task> tOldMap){
		Set<String> mapVals = new Set<String>(taskTrackedDateFields.values());
		
		Set<Id> deleteTasks = new Set<Id>();
		for(Task oNew : tNew){
			Task oOld = tOldMap.get(oNew.Id);
			if(mapVals.contains(oNew.Type) && (oNew.WhatId != oOld.WhatId || oNew.WhoId != oOld.WhoId)) deleteTasks.add(oNew.Id);
		}
		
		if(deleteTasks.size() > 0) deleteTasks(deleteTasks);
	}
	
	@future(callout=true)
	private static void deleteTasks(Set<Id> tasksToDelete){
		SecurityUtils.BypassProcesser.deleteObjects([select Id from Task where Id in: tasksToDelete], false);
	}
}