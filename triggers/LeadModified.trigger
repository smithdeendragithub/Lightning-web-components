trigger LeadModified on Lead (before insert, after insert, before update, after update, before delete, after delete) {
	LeadTriggers.LeadModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}