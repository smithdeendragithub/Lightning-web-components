trigger ICBBeforeUpsert on ICB__c (before insert, before update) {
    ICBTriggers.updateFormFields(Trigger.new, Trigger.isUpdate);
}