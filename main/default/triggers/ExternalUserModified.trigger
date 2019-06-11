trigger ExternalUserModified on External_User__c (before update) {
	ExternalUserTriggers.ExternalUserModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}