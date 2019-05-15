trigger AttachmentAdded on Attachment (after insert, before insert) {
	AttachmentTriggers.AttachmentAdded(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}