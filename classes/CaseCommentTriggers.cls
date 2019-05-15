public with sharing class CaseCommentTriggers{

    public static void CaseCommentModified(List<CaseComment> tNew, List<CaseComment> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('CaseComment', isBefore, isDelete)) return;
		
		if(isBefore){
		}
		else{
			
			if(!isUpdate && !isDelete){
				createCaseRemarks(new Map<Id, CaseComment>(tNew).keyset(), UserInfo.getSessionId());
			}
			
        	ApexUtils.afterTriggerComplete('CaseComment', isDelete);
		}
	}
	
	@future(callout = true)
    public static void createCaseRemarks(Set<Id> ccIDs, String sessionID){
		List<Integration_Error__c> remarkErrors = new List<Integration_Error__c>();
		List<CaseComment> caseComments = [select Id, CommentBody, CreatedById, ParentId, Parent.CaseNumber, Parent.Account.ICC_Account_Number__c, Parent.Service_Location__r.ICC_Subscriber_ID__c from CaseComment where Id in: ccIDs and Parent.Account.ICC_Account_Number__c != null];
		Map<Id, User> users = new Map<Id, User>();
		for(CaseComment cc : caseComments)
			users.put(cc.CreatedById, null);
		users = new Map<Id, User>([select Id, Name, NTID__c from User where Id in: users.keyset()]);
		
		List<integraWS.SFRemarkView> remarks = new List<integraWS.SFRemarkView>();
		for(CaseComment cc : caseComments){
			User u = users.get(cc.CreatedById);
			String subId = cc.Parent.Service_Location__r != null && !String.isEmpty(cc.Parent.Service_Location__r.ICC_Subscriber_ID__c) ? cc.Parent.Service_Location__r.ICC_Subscriber_ID__c : cc.Parent.Account.ICC_Account_Number__c;
			integraWS.SFRemarkView remark = new integraWS.SFRemarkView();
			remark.ParentExternalID = Integer.valueOf(subId);
			remark.remark = 'Case#' + cc.Parent.CaseNumber + ': ' + cc.CommentBody;
			remark.CreateUser = u.NTID__c;
			remarks.add(remark);
			
			Integration_Error__c err = new Integration_Error__c();
			err.Message__c = 'Note not pushed to ICC';
			err.ObjectID__c = cc.Id;
			err.Info__c = '';
			remarkErrors.add(err);
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
	
	public static void resendCaseComments(Set<Id> CaseCommentIds){
		createCaseRemarks(CaseCommentIds, UserInfo.getSessionId());
	}
}