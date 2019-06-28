public with sharing class WorkstepIssueTriggers {
	
	public static void WorkstepIssueModified(List<Workstep_Issue__c> tNew, List<Workstep_Issue__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
		if (!ApexUtils.executeTriggerMethods('Workstep_Issue__c', isBefore, false)) return ;
		
        Map<Id, Workstep_Issue__c> tOldMap = tOld != null ? new Map<Id, Workstep_Issue__c>(tOld) : new Map<Id, Workstep_Issue__c>();
		if(isBefore){
			if(!isDelete)
				updateBefore(tNew, tOldMap, isUpdate);
		}
		else{
			updateWorksteps(tNew, tOldMap, isUpdate, isDelete);
			
			ApexUtils.afterTriggerComplete('Workstep_Issue__c', false);
		}
	}
	
	private static void updateBefore(List<Workstep_Issue__c> tNew, Map<Id, Workstep_Issue__c> tOldMap, Boolean isUpdate){
    	
    	List<Workstep_Issue__c> setDefaultOwner = new List<Workstep_Issue__c>();
    	
    	for(Workstep_Issue__c wi : tNew){
    		Workstep_Issue__c wiOld = wi.Id != null ? tOldMap.get(wi.Id) : null;
    		if(wi.Status__c == 'Resolved' && (wiOld == null || wiOld.Status__c != wi.Status__c))
    			wi.Date_Resolved__c = Date.today();
    			wi.OwnerId = wi.OwnerId;
		
    		if(!isUpdate)
    			setDefaultOwner.add(wi);
    	}
    	
    	if(setDefaultOwner.size() > 0){
    		List<Issue_to_Queue_Mapping__c> iqms = Issue_to_Queue_Mapping__c.getall().values();
    		List<String> ownerDefs = new List<String>();
    		Map<Id, Workstep__c> causeMap = new Map<Id, Workstep__c>();
    		
    		for(Workstep_Issue__c wi : setDefaultOwner){
    			if(wi.Caused_By__c != null){
    				ownerDefs.add(string.valueOf(wi.Caused_By__c));
    				causeMap.put(wi.Caused_By__c, null);
    			}
    			else{
    				String queue = null;
	    			for(Issue_to_Queue_Mapping__c iqm : iqms){
	    				if(iqm.Issue_Type__c == wi.Risk_Type__c && iqm.Reason__c == wi.Reason__c && (string.isEmpty(wi.Reason_Subcategory__c) || iqm.Reason_Subcategory__c == wi.Reason_Subcategory__c)){
	    					queue = iqm.Queue__c;
	    					break;
	    				}
	    			}
	    			
	    			if(queue != null)
	    				ownerDefs.add(queue);
	    			else
	    				ownerDefs.add(null);
    			}
    		}
    		
    		causeMap = new Map<Id, Workstep__c>([select Id, OwnerId from Workstep__c where Id in: causeMap.keyset()]);
    		
    		Map<String, Id> qMap = new Map<String, Id>();
    		for(Group q : [select Id, DeveloperName from Group where Type = 'Queue' and DeveloperName in: ownerDefs])
    			qMap.put(q.DeveloperName, q.Id);
    		
    		for(Integer i=0; i<ownerDefs.size(); i++){
    			String def = ownerDefs[i];
    			if(def == null) continue;
    			
    			Id qId = qMap.get(def);
    			setDefaultOwner[i].OwnerId = tNew[i].OwnerId;
    			if(setDefaultOwner[i].OwnerId == null)
    				setDefaultOwner[i].OwnerId = (qId != null) ? qId : (ApexUtils.isValidId(def) ? causeMap.get(def).OwnerId : setDefaultOwner[i].OwnerId);			
    		}
    	}
    	
	}
	
	private static void updateWorksteps(List<Workstep_Issue__c> tNew, Map<Id, Workstep_Issue__c> tOldMap, Boolean isUpdate, Boolean isDelete){
    	Map<Id, Workstep__c> wsMap = new Map<Id, Workstep__c>();
		Set<Id> wsResolved = new Set<Id>();
		Set<Id> sos = new Set<Id>();
    	
    	List<Workstep_Issue__c> m = isDelete ? tOldMap.values() : tNew;
    	for(Workstep_Issue__c wi : m){
    		Workstep_Issue__c wiOld = wi.Id != null ? tOldMap.get(wi.Id) : null;
    		if(isDelete || wiOld == null || wiOld.Status__c != wi.Status__c)
    			wsMap.put(wi.Workstep__c, null);
			if(wi.Status__c == WorkstepUtils.ISSUE_RESOLVED)
				wsResolved.add(wi.Workstep__c);
    	}
    	
    	if(wsMap.size() > 0){
    		wsMap = new Map<Id, Workstep__c>([select Id, Status__c, Sub_Order__c, (select Id from Workstep_Issues__r where Status__c != 'Resolved' limit 1) from Workstep__c where Id in: wsMap.keyset()]);
    		for(Workstep__c ws : wsMap.values())
			{
				ws.Status__c = (ws.Workstep_Issues__r != null && ws.Workstep_Issues__r.size() > 0) ? WorkstepUtils.STATUS_BLOCKED : WorkstepUtils.STATUS_OPEN;
				if(wsResolved.contains(ws.Id))
					ws.Unblocked_Date__c = Date.today();
			}
    		
    		update wsMap.values();   		
    	}
    	    Map<Id, Sub_Order__c> so = new Map<Id, Sub_Order__c>();
    		for(Workstep__c ws : wsMap.values())
			{				
				Sub_Order__c bSO = new Sub_Order__c();
				bSO.Id = ws.Sub_Order__c;
				if(ws.Status__c == 'BLOCKED'){
					bSO.Has_Blocked_Workstep__c =  true;
					if(bSO.Id != null)
						so.put(bSO.Id, bSO);
				}
				else
					sos.add(ws.Sub_Order__c);
			}	

			//check if the SO has any blocked ws before removing the Has_Block from the SO	
			Set<Id> blkSO = new Set<Id>();
			for(Workstep__c oWS : [Select Sub_Order__c FROM Workstep__c WHERE Status__c IN ('Blocked') AND Sub_Order__c IN: sos AND Id NOT IN: wsMap.keyset()]){				
				blkSO.add(oWS.Sub_Order__c);
			}
			if(blkSO.size() <= 0){
				for(Id sub : sos){
					Sub_Order__c bSO = new Sub_Order__c();
					bSO.Id = sub;
					bSO.Has_Blocked_Workstep__c =  false;
					if(bSO.Id != null)
						so.put(bSO.Id, bSO);
				}
			}
			update so.values();
	}
	
	/*private static void evaluateStatus(Set<Id> wsIds){
		List<Workstep_Issue__c> wiList = [SELECT Id, Status__c, Workstep__c, Date_Resolved__c FROM Workstep_Issue__c WHERE Workstep__c IN :wsIds];
		//List of issues that will need to be updated if status changed
		List<Workstep_Issue__c> updatewiList = new List<Workstep_Issue__c>();
		//List of Workstpes that will need to be updated if Wiorkstepp issue status changed
		Set<Id> updateWorkSteps = new Set<Id>();
		
		for(Workstep_Issue__c wi : wiList){
			if(wi.Status__c == WorkstepUtils.STATUS_RESOLVED)
			{
				//need to put date resolved if not set
				if (wi.Date_Resolved__c == null)
					wi.Date_Resolved__c = Date.today();
				//add issue to update and Workstep to update list
				updatewiList.add(wi);
				updateWorkSteps.add(wi.Workstep__c);
			}
		}
		//Need to go through and remove and Worksteps that have an open issue if there are multiple issues on a workstep
		for(Workstep_Issue__c wi : wiList){
			if(wi.Status__c != WorkstepUtils.STATUS_RESOLVED && updateWorkSteps.contains(wi.Workstep__c))
			{
				updateWorkSteps.remove(wi.Workstep__c);
			}
		}
		
		List<Workstep__c> wsList = [SELECT Id, Status__c, Start_Date__c, Owner.email FROM Workstep__c WHERE Id IN :updateWorkSteps];
		for(Workstep__c ws : wsList) {
			ws.Status__c = WorkstepUtils.STATUS_OPEN;
			ws.Start_Date__c = date.today();
			//ws.BlockedPendingValidationByCode__c = true;
		}
		if(updatewiList.size() > 0)
			update updatewiList;
		
		if(wsList.size()>0)
			update wsList;
		
		for(Workstep__c ws :wsList)
			sendEmail(ws.Owner.email, ws.Id);
	}
	
	private static void sendEmail(String userEmail, Id wsId){
		if (!Test.isRunningTest())
			ApexUtils.sendEmails(new Messaging.SingleEmailMessage[]{ ApexUtils.createEmailMessage(new List<String>{ userEmail }, null, 'Workstep issues resolved', 'All issues related to the workstep '+ wsId + ' have been resolved and are waiting validation.', false, null)});
	}*/
}