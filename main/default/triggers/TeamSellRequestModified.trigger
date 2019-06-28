trigger TeamSellRequestModified on Team_Sell_Request__c(before insert, before update, after insert, after update) {
	TeamSellRequestTriggers.TeamSellRequestModified(trigger.new, trigger.old, trigger.isBefore, trigger.isUpdate, trigger.isDelete);
}