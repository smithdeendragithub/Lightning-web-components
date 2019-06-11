public with sharing class ProjectRelatedTriggers {
	public static final String magnitudeHigh = 'High';
	public static final String magnitudeMedium = 'Medium';
	public static final String magnitudeLow = 'Low';
	
	public static final String statusRed = 'Red';
	public static final String statusYellow = 'Yellow';
	public static final String statusGreen = 'Green';
	
	public static void ProjectIssueModified(Map<Id, Project_Issue__c> tNew, Map<Id, Project_Issue__c> tOld, Boolean isUpdate, Boolean isBefore){
		
    	if(!ApexUtils.executeTriggerMethods('Project_Issue__c', isBefore, false)) return;
    	
		if(!isBefore){
			UpdateCombinedIssuesStatus(tNew);
			
			ApexUtils.afterTriggerComplete('Project_Issue__c', false);
		}
    }

	public static void UpdateCombinedIssuesStatus(Map<Id, Project_Issue__c> newSol){
		
		Set<Id> projectIDs = new Set<Id>();
		for(Project_Issue__c pi : newSol.values()){
			if(pi.Project__c != null)
				projectIDs.add(pi.Project__c);
		}
		
		if(projectIDs.size() > 0){
	        List<Project__c> projectList = new List<Project__c>();
			for(Project__c proj : [select Id
										,Project_Issues_Overall_Status__c
										,(select Magnitude__c, Status__c from Project_Issues__r)
										from Project__c Where id in :projectIDs]){
				Set<String> magnitudes = new Set<String>();
				if(proj.Project_Issues__r != null){
					for(Project_Issue__c Issue : proj.Project_Issues__r){
						if((Issue.Magnitude__c == magnitudeHigh || Issue.Magnitude__c == magnitudeMedium) && Issue.Status__c != 'Resolved'){
							magnitudes.add(Issue.Magnitude__c);
						}
						else {
							magnitudes.add(magnitudeLow);
						}
					}
				}
				
				proj.Project_Issues_Overall_Status__c = (magnitudes.contains(magnitudeHigh)
															? statusRed
															: (magnitudes.contains(magnitudeMedium)
																? statusYellow
																: statusGreen));
				projectList.add(proj);
			}
			if(projectList.size() > 0)
				update projectList;
		}
		
	}
}