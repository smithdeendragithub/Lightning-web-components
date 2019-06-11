trigger FeedCommentModified on FeedComment (before insert, before update, before delete) {
	FeedCommentTriggers.FeedCommentModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}