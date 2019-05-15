trigger OpportunityLocationTrigger on Opportunity_Location__c (after update, before update) {
    OpportunityLocationTrigger.OpportunityLocationModified(Trigger.newMap, Trigger.oldMap, Trigger.isUpdate, Trigger.isBefore);
}