trigger CaseNetXWorkFlow on Case ( after insert, after update, before insert, before update) {
  CaseNetXWorkFlow.CaseNetXWorkFlow(trigger.new, trigger.old, trigger.isBefore, trigger.isUpdate, trigger.isDelete);
}