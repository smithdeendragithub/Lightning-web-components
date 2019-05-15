trigger CaseModified on Case (after delete, after insert, after update, before delete, before insert, before update) {
	CaseTriggers.CaseModified(trigger.new, trigger.old, trigger.isBefore, trigger.isUpdate, trigger.isDelete);
}