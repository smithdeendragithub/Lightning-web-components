trigger SubOrderGroupModified on Sub_Order_Group__c (before insert, before update, before delete, after insert, after update, after delete) {
	 SubOrderGroupTriggers.SubOrderGroupModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}