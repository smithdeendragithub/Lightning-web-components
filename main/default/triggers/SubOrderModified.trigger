trigger SubOrderModified on Sub_Order__c (before insert, before update, after insert, after update) {
    SubOrderTriggers.SubOrderModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, false);
}