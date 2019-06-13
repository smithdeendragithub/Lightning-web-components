public without sharing class CaseTriggers {
    private static Boolean DisableTrigger = false;
	private static Map<Id, RecordType> ccaseRts = null;
	private static Map<Id, RecordType> CaseRts{
		get{
			if(ccaseRts == null) ccaseRts = new Map<Id, RecordType>([select Id, DeveloperName from RecordType where sObjectType = 'Case']);
			return ccaseRts;
		}
		Set{}
	}
	
  	public static void CaseModified(List<Case> tNew, List<Case> tOld, Boolean isBefore, Boolean isUpdate, Boolean isDelete){
        if(DisableTrigger || !ApexUtils.executeTriggerMethods('Case', isBefore, isDelete)) return;
		System.System.debug('pushed from VSC');
		
        if(isBefore){
        }
        else{
            
            if(!isDelete){
				List<Id> caseIds = new List<Id>();
				for(Case c : tNew)
					caseIds.add(c.Id);
				Map<Id, Case> tOldMap = tOld != null ? new Map<Id, Case>(tOld) : new Map<Id, Case>();					
				List<Case> openCases = handleCaseClosed(tNew, tOldMap);
				if(isUpdate){
					CustomerSurveyUtils.sendCaseSurveys(tNew, tOldMap);
					handleRecordTypeChange(tNew, tOldMap);
					changeOwnerIfQueueOwned(caseIds);
				}
				else{
					createCaseRemarks((new Map<Id, Case>(openCases)).keyset(), false, UserInfo.getSessionId(), UserInfo.getUserId());
				}
            }
			
        	ApexUtils.afterTriggerComplete('Case', isDelete);
        }
    }
	
	//Returns cases that are not closed
	private static List<Case> handleCaseClosed(List<Case> tNew, Map<Id, Case> tOldMap){
		List<Case> openCases = new List<Case>();
		
		Set<Id> closedCases = new Set<Id>();
		Set<Id> closedTaskCases = new Set<Id>();
        for(Case cNew : tNew){
            Case cOld = tOldMap.get(cNew.Id);
			if(cNew.IsClosed){
            	if(cOld == null || !cOld.IsClosed){
					closedCases.add(cNew.Id);
					if(cNew.Account_Scheduled_Task__c != null) closedTaskCases.add(cNew.Id);
				}
			}
			else{
				openCases.add(cNew);
			}
        }
		
        if(closedCases.size() > 0) createCaseRemarks(closedCases, true, UserInfo.getSessionId(), UserInfo.getUserId());
		if(closedTaskCases.size() > 0) updateScheduleTasks(closedTaskCases, UserInfo.getSessionId());
		
		return openCases;
	}
	
	private static void handleRecordTypeChange(List<Case>tNew, Map<Id, Case> tOldMap){
		Map<Id, String> astIdToActType = new Map<Id, String>();
		Set<Id> caseIds = new Set<Id>();
		for(Case c : tNew){
			Case oc = tOldMap.get(c.Id);
			if(oc != null){
				caseIds.add(c.Id);
				RecordType oldRt = CaseRts.get(oc.RecordTypeId);
				RecordType newRt = CaseRts.get(c.RecordTypeId);
				if(oldRt != null && oldRt != newRt && (oldRt.DeveloperName == 'Proactive_Review_Visit_Virtual' || oldRt.DeveloperName == 'Proactive_Call_Email') && (newRt.DeveloperName == 'Proactive_Review_Visit_Virtual' || newRt.DeveloperName == 'Proactive_Call_Email')){
					astIdToActType.put(c.Account_Scheduled_Task__c, newRt.DeveloperName);
				}
			}
		}
		
		List<Account_Scheduled_Task__c> tasks = [select Id, Previous_Proactive_Activity__c, Current_Activity_Required__c, (select Id, Proactive_Subtype__c from Cases__r order by CreatedDate desc limit 1) from Account_Scheduled_Task__c where Id in: astIdToActType.keyset()];
		List<Account_Scheduled_Task__c> tasksToUpdate = new List<Account_Scheduled_Task__c>();
		for(Account_Scheduled_Task__c ast : tasks){
			if(ast.Cases__r != null && ast.Cases__r.size() == 1 && caseIDs.contains(ast.Cases__r[0].Id) && astIdToActType.get(ast.Id) != null){
				ast.Current_Activity_Required__c = astIdToActType.get(ast.Id) == 'Proactive_Review_Visit_Virtual'? 'Contact' : 'Account Review';
				ast.Previous_Proactive_Activity__c = ast.Current_Activity_Required__c == 'Contact'? 'Account Review' : 'Contact';
				tasksToUpdate.add(ast);
			}
		}
		update tasksToUpdate;
	}
	
	@future(callout = true)
    public static void createCaseRemarks(Set<Id> updatedCases, Boolean closed, String sessionID, Id triggerUserID){
		List<Integration_Error__c> remarkErrors = new List<Integration_Error__c>();
		User u = [select Id, Name, NTID__c from User where Id =: triggerUserID];
		List<Case> Cases = [select Id, Account.Id, Account.ICC_Account_Number__c, CaseNumber, Description, Subject, Contact.Name, Service_Location__c, Service_Location__r.ICC_Subscriber_ID__c from Case where Id in : updatedCases];
		
		List<integraWS.SFRemarkView> remarks = new List<integraWS.SFRemarkView>();
        for(Case ca : Cases){
			String strSubId = !String.isEmpty(ca.Service_Location__r.ICC_Subscriber_ID__c) ? ca.Service_Location__r.ICC_Subscriber_ID__c : (!String.isEmpty(ca.Account.ICC_Account_Number__c)? ca.Account.ICC_Account_Number__c : '0');
			Integer subID = integer.valueOf(strSubId);			
			
			if(subID > 0){
				integraWS.SFRemarkView remark = new integraWS.SFRemarkView();
				remark.ParentExternalID = subID;
				remark.Remark = getFormattedRemark(ca, closed, u.Name);
				remark.CreateUser = u.NTID__c;
				remarks.add(remark);
				
				Integration_Error__c err = new Integration_Error__c();
				err.Message__c = 'Note not pushed to ICC';
				err.ObjectID__c = ca.Id;
				err.Info__c = closed ? 'Closed' : 'Opened';
				remarkErrors.add(err);
			}
        }
		
        if(remarks.size() > 0) {
			try{
				ICCWrapper.createRemarks(remarks, 'Subscriber', sessionID);
			}
			catch(Exception ex){
				insert remarkErrors;
			}
		}
    }
	
	public static void resendCaseComments(Map<Boolean,Set<Id>> IsClosedNoteToCaseId){
		for(Boolean closed : IsClosedNoteToCaseId.keySet()){
			createCaseRemarks(IsClosedNoteToCaseId.get(closed), closed, UserInfo.getSessionId(), UserInfo.getUserId());
		}
	}
    
    private static String getFormattedRemark(Case ca, Boolean closed, String userName){
        return 'Case#' + ca.CaseNumber + ' - ' + (closed ? 'Closed' : 'Opened')
				+ (!closed && ca.Contact != null ? (' - Contact: ' + ca.Contact.Name) : '')
				+ ((ca.Subject != null) ? (': ' + ca.Subject) : '')
				+ ((ca.Description != null) ? (': ' + ca.Description) : '');
    }
	
	@future(callout = true)
    private static void updateScheduleTasks(Set<Id> caseIDs, String sessionID){
		
		Map<Id, Account_Scheduled_Task__c> tasks = new Map<Id, Account_Scheduled_Task__c>();
		for(Case c : [select Id, Account_Scheduled_Task__c from Case where Id in: caseIDs and Account_Scheduled_Task__c != null])
			tasks.put(c.Account_Scheduled_Task__c, null);
		tasks = new Map<Id, Account_Scheduled_Task__c>([select Id, Current_Activity_Required__c, (select Id, Proactive_Subtype__c from Cases__r order by CreatedDate desc limit 1) from Account_Scheduled_Task__c where Id in: tasks.keyset()]);
		
		for(Account_Scheduled_Task__c t : tasks.values()){
			if(t.Cases__r != null && t.Cases__r.size() == 1 && caseIDs.contains(t.Cases__r[0].Id)){
				Case c = t.Cases__r[0];
				if(c.Proactive_Subtype__c == t.Current_Activity_Required__c){
					//todo: custom setting?
					String current = t.Current_Activity_Required__c;
					if(c.Proactive_Subtype__c == 'Account Review') t.Current_Activity_Required__c = 'Contact';
					else if(c.Proactive_Subtype__c == 'Contact') t.Current_Activity_Required__c = 'Account Review';
					if(t.Current_Activity_Required__c != current) t.Previous_Proactive_Activity__c = current;
				}
			}
		}
		
		if(tasks.size() > 0) update tasks.values();
	}
	
	@future
	private static void changeOwnerIfQueueOwned(List<Id> caseIds){
		//do not send owner change emails.
		DisableTrigger = true;
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.EmailHeader.triggerUserEmail = false;
		List<Case> tNew = [select Id, OwnerId from case where Id in :caseIds];
		string gkpx = Group.sObjectTYpe.getDescribe().getKeyPrefix();		
		Map<Id, Group> grpsById = new Map<Id, Group>([Select Id, Name, Type, ( Select UserOrGroupId from GroupMembers) from Group WHERE DeveloperName = 'IB_Customer_Care' or DeveloperName = 'IL_Customer_Care' or DeveloperName = 'EL_Customer_Care']);
		Set<Id> groupIds = new Set<Id>();
		for(Group g : grpsById.values()){
			for(GroupMember gm : g.GroupMembers){
				if(string.valueOf(gm.UserOrGroupId).startsWith(gkpx))
					groupIds.add(gm.UserOrGroupId);
			}
		}
		Map<Id,Group> subGroups = new Map<Id, Group>([select Id, Name, Type, (Select UserOrGroupId from GroupMembers) from Group WHERE Id in :groupIds]);
		
		//include sub group members.  i just hope we don't go any deeper.
		Map<Id, Set<Id>> groupIdToMemberIds = new Map<Id, Set<Id>>();
		for(Group g : grpsById.values()){
			Set<Id> memIds = groupIdToMemberIds.containsKey(g.Id) ? groupIdToMemberIds.get(g.Id) : new Set<Id>();
			for(GroupMember gm : g.GroupMembers){
				if(subGroups.containsKey(gm.UserOrGroupId)){
					Group sGrp = subGroups.get(gm.UserOrGroupId);
					for(GroupMember sgm : sGrp.GroupMembers){
						memIds.add(sgm.UserOrGroupId);
					}
				}
				else{
					memIds.add(gm.UserOrGroupId);
				}
			}
			groupIdToMemberIds.put(g.Id, memIds);
		}
		Id currentUser = UserInfo.getUserId();
		for(Case c : tNew){
			if(grpsById.keySet().Contains(c.OwnerId)){
				for(Id uId : groupIdToMemberIds.get(c.OwnerId)){
					if(uId == currentUser){
						c.OwnerId = uId;
						break;
					}
				}
			}
		}
		Database.update(tNew, dmo);
	}
}