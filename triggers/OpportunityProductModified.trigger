trigger OpportunityProductModified on Opportunity_Product__c (before insert, before update, after insert, after update, after delete) {
    OpportunityProductTriggers.OpportunityProductModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}