trigger OpportunityModified on Opportunity (after insert, after update, before insert, before update) {   
    OpportunityTriggers.OpportunityModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore);
}