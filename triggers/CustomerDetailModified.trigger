trigger CustomerDetailModified on Customer_Detail__c (before insert, before update, after insert, after update) {
    CustomerDetailTriggers.CustomerDetailModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}