public with sharing class FeedCommentTriggers{
	
    public static void FeedCommentModified(List<FeedComment> tNew, List<FeedComment> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('FeedComment', isBefore, isDelete)) return;
    	
    	if(isBefore){
			Map<Id, FeedComment> tOldMap = tOld != null ? new Map<Id, FeedComment>(tOld) : new Map<Id, FeedComment>();
			if(!isDelete)
				SecurityUtils.checkCurrentUserHasChatterAccess(tNew, tOldMap);
    	}
    	else{
			ApexUtils.afterTriggerComplete('FeedComment', isDelete);
    	}
    }
	
	/*private static void handleDelete(List<FeedComment> tOld){
		if(!CustomSettingUtils.currentUserHasCustomPermission('Can_Delete_Chatter__c')){
			for(FeedComment fc : tOld)
				fc.addError('You do not have permission to delete chatter comments');
		}
	}*/
}