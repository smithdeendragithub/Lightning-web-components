public with sharing class UserTriggers{
	
    public static void UserModified(List<User> tNew, List<User> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('User', isBefore, isDelete)) return;
		
    	if(isBefore){
    	}
    	else{
	        Map<Id, User> tOldMap = tOld != null ? new Map<Id, User>(tOld) : new Map<Id, User>();
			if(!isDelete){
				autoAssignChatterGroups(new Map<Id, User>(tNew).keyset());
			}
			
			if(isUpdate) Batch_CalculateAccountOwnership.HandleOwnershipRecalculation(tNew, tOldMap);
			ApexUtils.afterTriggerComplete('User', isDelete);
    	}
	}
	
    @future
    private static void autoAssignChatterGroups(Set<Id> userIDs){
		
		Map<String, Id> groupMapping = new Map<String, Id>();
		Map<Id, Set<String>> assignments = new Map<Id, Set<String>>();
		for(Chatter_Auto_Follow__c c : [select Criteria__c, Group__c from Chatter_Auto_Follow__c]){
			try{
				for(User u : (List<User>)Database.query('select Id from User where Id in: userIDs' + (!String.isEmpty(c.Criteria__c) ? (' AND (' + c.Criteria__c + ')') : ''))){
					Set<String> s = assignments.get(u.Id) != null ? assignments.get(u.Id) : new Set<String>();
					s.add(c.Group__c);
					assignments.put(u.Id, s);
				}
				groupMapping.put(c.Group__c, null);
			}
			catch(Exception e){}
		}
		
		for(CollaborationGroup cg : [select Id, Name from CollaborationGroup where Name in: groupMapping.keyset()])
			groupMapping.put(cg.Name, cg.Id);
		
		Map<Id, Set<Id>> existingMemberships = new Map<Id, Set<Id>>();
		for(CollaborationGroupMember cgm : [select Id, MemberId, CollaborationGroupId from CollaborationGroupMember where CollaborationGroupId in: groupMapping.values() and MemberId in: assignments.keyset()]){
			Set<Id> s = existingMemberships.get(cgm.MemberId) != null ? existingMemberships.get(cgm.MemberId) : new Set<Id>();
			s.add(cgm.CollaborationGroupId);
			existingMemberships.put(cgm.MemberId, s);
		}
		
		List<CollaborationGroupMember> cgms = new List<CollaborationGroupMember>();
		for(User u : [select Id, Name from User where Id in: assignments.keyset()]){
			Set<Id> existing = existingMemberships.get(u.Id);
			
			Set<String> names = assignments.get(u.Id);
			for(String name : names != null ? names : new Set<String>()){
				Id groupID = groupMapping.get(name);
				if(groupID != null && (existing == null || !existing.contains(groupID))){
					system.debug('Adding user ' + u.Name + '(' + u.Id + ') to chatter group ' + name);
					cgms.add(new CollaborationGroupMember(MemberId=u.Id, CollaborationGroupId=groupID, CollaborationRole='Standard', NotificationFrequency='D'));
				}
			}
		}
		
		if(cgms.size() > 0)
			insert cgms;
	}
}