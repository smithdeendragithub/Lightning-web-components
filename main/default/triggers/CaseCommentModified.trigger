trigger CaseCommentModified on CaseComment (before insert, after insert, before update, after update) {
    CaseCommentTriggers.CaseCommentModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}