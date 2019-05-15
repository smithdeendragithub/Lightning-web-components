trigger ServiceLocationModified on Service_Location__c (after insert, after update, after delete, before insert, before update, before delete) {
	ServiceLocationTriggers.ServiceLocationModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}