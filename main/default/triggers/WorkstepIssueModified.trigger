trigger WorkstepIssueModified on Workstep_Issue__c (after insert, after update, after delete, before update, before insert, before delete) {
	WorkstepIssueTriggers.WorkstepIssueModified(trigger.new, trigger.old, trigger.isUpdate, trigger.isBefore, trigger.isDelete);
}