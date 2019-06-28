@isTest
public with sharing class Test_DeliverBase extends TestUtils.TestClass {
	
    static testMethod void testDeliverBase() {
        DeliverBase base = new DeliverBase();
        base.SendNow(null);
        base.findTemplates('unknown');
        DeliverBase.MessageContact mc = new DeliverBase.MessageContact();
        DeliverBase.MessageInfo mi = new DeliverBase.MessageInfo();
        base.LastError = '';
    }
}