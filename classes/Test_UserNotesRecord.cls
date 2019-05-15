@isTest
public class Test_UserNotesRecord {
    
    static testmethod void controllerExtensionTest(){
        Test.startTest();
        
        User owner = new User(FirstName = 'Test', LastName = 'User', Email = 'SampleTestUsername@TestDomain.com',
                              Username = 'UserNameSampleTestUsername@TestDomain.com',
                              CommunityNickname = 'nickname',
                              CompanyName = 'TEST',
                              Title = 'title',
                              Alias = 'alias',
                              TimeZoneSidKey = 'America/Los_Angeles',
                              EmailEncodingKey = 'UTF-8',
                              LanguageLocaleKey = 'en_US',
                              LocaleSidKey = 'en_US',
                              ProfileId = [Select Id from profile where Name='System Administrator'].Id
                             );
        User_Note__c record = new User_Note__c(Name='Test Comment');
        
        ApexPages.StandardController sc = new ApexPages.StandardController(record);
        UserNotesRecordControllerExtension  ctrl = new UserNotesRecordControllerExtension(sc);
        
        insert owner;
        
        ctrl.setUserID(owner.Id);
        System.assertEquals(ctrl.getUserID(), owner.Id);
        
        // Test getUserName method
        System.assertEquals(ctrl.getUserName().FirstName, owner.FirstName);
        System.assertEquals(ctrl.getUserName().LastName, owner.LastName);
        System.assertEquals(ctrl.getUserName().Id, owner.Id);
        
        // Test CustomSave method and check the record was saved
        ctrl.CustomSave();
        
        User_Note__c InsertedRecord = new User_Note__c();
        InsertedRecord = [SELECT Id, Name FROM User_Note__c WHERE User__c =: owner.Id ];
        System.assertEquals(InsertedRecord.Id, record.Id);
        System.assertEquals(InsertedRecord.Name, 'Test Comment');
        
        // Test CloseWindow function
        System.assertEquals(ctrl.getCloseWindow(), 'window.close()');
        record.Name = null;
        ctrl.setrecord(record);
        System.assertEquals(ctrl.getrecord(),record);
        System.assertEquals(ctrl.getCloseWindow(), null);
        
        // Test Warning message was added
        boolean MessageAdded = false;
        ctrl.CustomSave();
        List<ApexPages.Message> messages = ApexPages.getMessages();
        for (ApexPages.Message msg: messages){
            if (msg.getDetail().contains('Note cannot be left blank')) MessageAdded = true;
        }
        System.assert(MessageAdded);
                       
        Test.stopTest();
    }  
}