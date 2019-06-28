trigger TaskModified on Task bulk (before insert, after insert, before update, after update) {
    TaskTriggers.TaskModified(Trigger.new, Trigger.old, Trigger.isUpdate, Trigger.isBefore, Trigger.isDelete);
}