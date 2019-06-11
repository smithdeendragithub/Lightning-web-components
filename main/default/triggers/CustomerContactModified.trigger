trigger CustomerContactModified on Customer_Contact__c (after insert, after update, before insert, before update, before delete) {
    CustomerContactTriggers.CustomerContactsModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}