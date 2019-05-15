trigger AccountModified on Account (after insert, after update, before insert, before update, before delete) {
    AccountTriggers.AccountModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}