trigger BuildingModified on Building__c (before update, after insert) {
    if (Trigger.isUpdate)
        BuildingTriggers.BuildingModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore);
    
    if (Trigger.isInsert)
        BuildingTriggers.BuildingInserted(Trigger.new);
}