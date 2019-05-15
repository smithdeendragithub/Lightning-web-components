@isTest
public with sharing class Test_EmailToCaseHandler extends TestUtils.TestClass {
    
    static testMethod void testCreateCase(){
        // Create a new email, envelope object and Attachment
        Test.startTest();
        insert new List<Process_Configuration__c>{new Process_Configuration__c(Name='EmailToCaseForOrder', Process__c='EmailToCaseRoutingLookup', Key__c='Order', Value__c='voiceorders')};
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();       
        envelope.toAddress = 'voiceorders@allstream.com';
        
        email.subject = 'Email To Case Test';
        email.fromName = 'test test';
        email.plainTextBody = 'Hello, Please create an Order';
        Messaging.InboundEmail.BinaryAttachment[] binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[1];  
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'test.txt';
        String algorithmName = 'HMacSHA1';
        Blob b = Crypto.generateMac(algorithmName, Blob.valueOf('test'),
        Blob.valueOf('test_key'));
        binaryAttachment.Body = b;
        binaryAttachments[0] =  binaryAttachment ;
        email.binaryAttachments = binaryAttachments ;
        envelope.fromAddress = 'user@customer.com';    


        // setup controller object
        EmailToCaseHandler catcher = new EmailToCaseHandler();
        Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
        System.assertEquals( result.success  ,true);        
        Test.stopTest();
    }

}