trigger WorkstepModified on Workstep__c (after insert, after update, after delete, before update, before insert, before delete) {
	WorkstepTriggers.WorkstepModified(trigger.new, trigger.old, trigger.isUpdate, trigger.isBefore, trigger.isDelete);
}