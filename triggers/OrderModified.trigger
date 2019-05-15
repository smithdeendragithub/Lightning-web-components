trigger OrderModified on Order__c (before insert, before update, before delete, after insert, after update, after delete) {
	OrderTriggers.OrderModified(trigger.new, trigger.old, trigger.isUpdate, trigger.isBefore, trigger.isDelete);
}