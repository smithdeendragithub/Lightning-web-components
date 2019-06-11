trigger ProjectIssueModified on Project_Issue__c (after insert, after update) {
	ProjectRelatedTriggers.ProjectIssueModified(Trigger.newMap, Trigger.oldMap, Trigger.isUpdate, Trigger.isBefore);
}