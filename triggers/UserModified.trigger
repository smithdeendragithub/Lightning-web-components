trigger UserModified on User (before insert, after insert, before update, after update) {
	UserTriggers.UserModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}