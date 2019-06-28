@isTest
public with sharing class Test_DeliverEmail extends TestUtils.TestClass {

    static testMethod void myUnitTest() {
        
        // create test data
        Mocks testData = new Mocks();

        // create sender
        DeliverEmail sender = new DeliverEmail();

        // create message
        DeliverBase.MessageInfo messageInfo = new DeliverBase.MessageInfo();
        messageInfo.SenderEmail = 'noreply@email.com';
        messageInfo.TemplateId = '-Not using a template-';
        messageInfo.Message = 'Message';
        messageInfo.Subject = 'Subject';
        messageInfo.WhatID = testData.opportunity.Id;
        messageInfo.contacts = new List<DeliverBase.MessageContact>();
        messageInfo.documents = new List<ContentVersion>();
        
        // create contacts for message
        DeliverBase.MessageContact mc = new DeliverBase.MessageContact();
        mc.rawContact = testData.parentAccountContact;
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