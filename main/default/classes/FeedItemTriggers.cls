public with sharing class FeedItemTriggers{
	
	private static Set<String> disabledDeleteTypes = new Set<String>{'AdvancedTextPost'
																	,'CallLogPost'
																	,'ContentPost'
																	,'LinkPost'
																	,'PollPost'
																	,'TextPost'};
	
    public static void FeedItemModified(List<FeedItem> tNew, List<FeedItem> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('FeedItem', isBefore, isDelete)) return;
    	
    	if(isBefore){
			Map<Id, FeedItem> tOldMap = tOld != null ? new Map<Id, FeedItem>(tOld) : new Map<Id, FeedItem>();
			if(!isDelete)
				SecurityUtils.checkCurrentUserHasChatterAccess(tNew, tOldMap);
    	}
    	else{
			ApexUtils.afterTriggerComplete('FeedItem', isDelete);
    	}
    }
	
	/*private static void handleDelete(List<FeedItem> tOld){
		if(!CustomSettingUtils.currentUserHasCustomPermission('Can_Delete_Chatter__c')){
			for(FeedItem fi : tOld){
				if(disabledDeleteTypes.contains(fi.Type))
					fi.addError('You do not have permission to delete chatter feed items');
			}
		}
	}*/
}