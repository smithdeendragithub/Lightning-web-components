trigger SubOrderFeatureModified on Sub_Order_Feature__c (after insert, after update, after delete, before insert, before update, before delete) {
	SubOrderFeatureTriggers.SubOrderFeatureModified(trigger.new, trigger.old, trigger.isUpdate, trigger.isBefore, trigger.isDelete);
}