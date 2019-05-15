trigger CustomerAtRiskModified on Customer_At_Risk__c (after insert,after update) {
	CustomerAtRiskTriggers.CustomerAtRiskModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore);
}