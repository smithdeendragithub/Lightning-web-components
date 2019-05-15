trigger FeedItemModified on FeedItem (before insert, before update, before delete) {
	FeedItemTriggers.FeedItemModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}