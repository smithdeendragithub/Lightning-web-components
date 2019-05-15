trigger ContactModified on Contact (before insert, before update, after insert, after update, before delete) {
	ContactTriggers.ContactsModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}