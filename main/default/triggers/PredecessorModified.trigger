trigger PredecessorModified on Predecessor__c (before insert, before update, before delete, after insert, after update, after delete) {
	PredecessorTriggers.PredecessorModified(trigger.new, trigger.old, trigger.isUpdate, trigger.isBefore, trigger.isDelete);
}