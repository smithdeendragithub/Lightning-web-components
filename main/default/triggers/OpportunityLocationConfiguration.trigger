trigger OpportunityLocationConfiguration on OpportunityLocationConfiguration__c (before update, after update, before delete, after delete) {
    OpportunityLocationConfigurationTriggers.OpportunityLocationConfigurationModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}