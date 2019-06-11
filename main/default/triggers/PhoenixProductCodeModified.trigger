trigger PhoenixProductCodeModified on Phoenix_Product_Code__c (before insert, before update, after insert, after update) {
        PhoenixProductCodeTrigger.PhoenixProductCodeModified (Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);

}