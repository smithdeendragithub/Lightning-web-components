trigger PricingAgreementModified on Pricing_Agreement__c (after insert, after update, before insert, before update, before delete) {
   PricingAgreementTriggers.PricingAgreementModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);

}