trigger AccountPartnerModified on Account_Partner__c (before insert, after insert, before update, after update, before delete, after delete) {
	AccountPartnerTriggers.AccountPartnerModified(trigger.new, trigger.old, trigger.isUpdate, trigger.isBefore, trigger.isDelete);
}