@isTest
public with sharing class Test_AttachmentTriggers{
    static testMethod void TestAttachment() {
        // create test data
        Mocks testData = new Mocks();
        Account a = testData.parentAccount;
		
        test.startTest();
		Blob b = Blob.valueOf('Test');
		
        Attachment at = new Attachment(ParentId = a.id,Name='Test',Body=b);
       	insert at;
		
		test.stopTest();
	}
}