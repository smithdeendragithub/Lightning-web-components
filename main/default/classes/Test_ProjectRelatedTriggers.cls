@isTest
public with sharing class Test_ProjectRelatedTriggers {
	
    static testMethod void ProjectIssueModified() {
    	ProjectRelatedTriggers prt = new ProjectRelatedTriggers();
    	test.startTest();
    	Project__c p = new Project__c();
    	insert p;


    	Project_Issue__c pi = new Project_Issue__c(Magnitude__c = ProjectRelatedTriggers.magnitudeHigh, Project__c = p.Id);
    	insert pi;
    	Map<Id, Project_Issue__c> mpi = new Map<Id, Project_Issue__c>();
    	for(Project_Issue__c proj : [Select Id, Magnitude__c, Name, Project__c From Project_Issue__c where Project__c =: p.Id Limit 1]){
    		mpi.put(proj.Id, proj);
    	}
		ProjectRelatedTriggers.UpdateCombinedIssuesStatus(mpi);
    	test.stopTest();
    }
    
    static testmethod void UpdateCombinedIssuesStatusTest(){
    	test.startTest();

    	Map<Id, Project_Issue__c> mpi = new Map<Id, Project_Issue__c>();
    	for(Project_Issue__c proj : [Select Id, Magnitude__c, Name, Project__c From Project_Issue__c  Limit 1]){
    		mpi.put(proj.Id, proj);
    	}
    	
    	test.stopTest();
    
    }
}