trigger CapitalProjectModified on Capital_Project__c (after delete, after insert, after update, before delete, before insert, before update) {
    CapitalProjectTriggers.CapitalProjectModified(trigger.new, trigger.old, trigger.isBefore, trigger.isUpdate, trigger.isDelete);
}