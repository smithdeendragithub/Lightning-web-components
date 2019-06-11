@isTest
public with sharing class Test_DeliverDocuSign extends TestUtils.TestClass {
	
    static testMethod void testController() {
        
        // create sender
//        DocuSignServiceSettings__c docusignServiceSettings = DocuSignServiceSettings__c.getInstance();
//      During initial deployment custom settings object is created, but is not populated... therefore the code would fail
        DeliverDocuSign sender = null;
        try {
            sender = new DeliverDocuSign( null,
                null,
                null,
                null,
                null);
        } catch (DeliverDocuSign.DeliverDocuSignException ex) {
            // burried, this is expected
        }
        sender = new DeliverDocuSign('asdf',
                'asdf',
                'asdf',
                'asdf',
                'asdf',
                'admin@email.com', 120);
        
        // create message
        DeliverBase.MessageInfo messageInfo = new DeliverBase.MessageInfo();
        messageInfo.Message = 'Message';
        messageInfo.Subject = 'Subject';
        messageInfo.WhatID = 'ABC123';
        messageInfo.contacts = new List<DeliverBase.MessageContact>();
        messageInfo.documents = new List<ContentVersion>();
        
        // create contacts for message
        DeliverBase.MessageContact mc = new DeliverBase.MessageContact();
        mc.rawContact = new Contact(FirstName = 'Test', LastName = 'User', Email = 'customer@email.com');
        mc.routingOrder = 1;
        mc.recipType = DeliverBase.RecipientType.Signer;
        messageInfo.contacts.add(mc);
        
        // create docs for message
        ContentVersion doc = new ContentVersion();
        doc.Title = 'TestDoc';
        doc.VersionData = Blob.valueOf('ABCDEF');
        doc.PathOnClient = 'c:\\TestDoc.txt';
        messageInfo.documents.add(doc);
       
        // send message
        sender.SendNow(messageInfo);
    }
}