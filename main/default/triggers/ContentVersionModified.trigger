trigger ContentVersionModified on ContentVersion (after delete, after insert, after update) {
	Map<Id, ContentVersion> tNewMap = new Map<Id, ContentVersion>(Trigger.isDelete ? Trigger.old : Trigger.new);
	Map<Id, ContentVersion> tOldMap = Trigger.isUpdate ? new Map<Id, ContentVersion>(Trigger.old) : new Map<Id, ContentVersion>();
	
	Set<Id> updatedAssetTypes = new Set<Id>();
	for(ContentVersion cv : tNewMap.values()){
		ContentVersion cvOld = tOldMap.get(cv.Id);
		if(cvOld == null || cv.Asset_Type__c != cvOld.Asset_Type__c){
			for(Id projectID : new List<Id>{cv.Project__c, cvOld != null ? cvOld.Project__c : null}){
				if(projectID != null)
					updatedAssetTypes.add(projectID);
			}
		}
	}
	
	if(updatedAssetTypes.size() > 0){
		List<Project__c> updates = new List<Project__c>();
		for(Project__c p : [select Id, NPRF__c, (select Id from Content__r where Asset_Type__c = 'NPRF' limit 1) from Project__c where Id in : updatedAssetTypes]){
			Boolean nprf = (p.Content__r != null && p.Content__r.size() > 0);
			if(p.NPRF__c != nprf){
				p.NPRF__c = nprf;
				updates.add(p);
			}
		}
		
		if(updates.size() > 0)
			update updates;
	}
}