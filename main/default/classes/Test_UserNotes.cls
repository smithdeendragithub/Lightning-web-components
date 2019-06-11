@isTest
public class Test_UserNotes {
    
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
        insert owner;
        User_Note__c record1 = new User_Note__c(Name='A Test Comment1', User__c = owner.Id);
        User_Note__c record2 = new User_Note__c(Name='B Test Comment2', User__c = owner.Id);
        User_Note__c record3 = new User_Note__c(Name='C Test Comment3', User__c = owner.Id);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(owner);
        UserNotesControllerExtension  ctrl = new UserNotesControllerExtension(sc);
        
        ctrl.setUserID(owner.Id);
        System.assertEquals(ctrl.getUserID(), owner.Id);
        
        insert record1;
        insert record2;
        insert record3;
        
        List<User_Note__c> results = new List<User_Note__c>();
        
        // Test all the sorting methods
        ctrl.sortComments();
        System.assertEquals(ctrl.getNotes()[0].Id,record1.Id);
        System.assertEquals(ctrl.getNotes()[1].Id,record2.Id);
        System.assertEquals(ctrl.getNotes()[2].Id,record3.Id);
        ctrl.sortComments();
        System.assertEquals(ctrl.getNotes()[2].Id,record1.Id);
        System.assertEquals(ctrl.getNotes()[1].Id,record2.Id);
        System.assertEquals(ctrl.getNotes()[0].Id,record3.Id);
        
        ctrl.sortModifiedBy();
        results = [SELECT Name, Id, LastModifiedDate, CreatedDate, LastModifiedById, User__c FROM User_Note__c WHERE User__c =: owner.Id ORDER BY LastModifiedById ASC];
        System.assertEquals(ctrl.getNotes(),results);
        ctrl.sortModifiedBy();
        results = [SELECT Name, Id, LastModifiedDate, CreatedDate, LastModifiedById, User__c FROM User_Note__c WHERE User__c =: owner.Id ORDER BY LastModifiedById DESC];
        System.assertEquals(ctrl.getNotes(),results);   
        
        ctrl.sortDateModified();
        results = [SELECT Name, Id, LastModifiedDate, CreatedDate, LastModifiedById, User__c FROM User_Note__c WHERE User__c =: owner.Id ORDER BY LastModifiedDate DESC];
        System.assertEquals(ctrl.getNotes(),results);
        ctrl.sortDateModified();
        results = [SELECT Name, Id, LastModifiedDate, CreatedDate, LastModifiedById, User__c FROM User_Note__c WHERE User__c =: owner.Id ORDER BY LastModifiedDate ASC];
        System.assertEquals(ctrl.getNotes(),results);      
        
        ctrl.sortDateCreated();
        results = [SELECT Name, Id, LastModifiedDate, CreatedDate, LastModifiedById, User__c FROM User_Note__c WHERE User__c =: owner.Id ORDER BY CreatedDate DESC];
        System.assertEquals(ctrl.getNotes(),results);
        ctrl.sortDateCreated();
        results = [SELECT Name, Id, LastModifiedDate, CreatedDate, LastModifiedById, User__c FROM User_Note__c WHERE User__c =: owner.Id ORDER BY CreatedDate ASC];
        System.assertEquals(ctrl.getNotes(),results);
        
        // Test the RemoveNote method
        ctrl.DelRecordID = record1.Id;
        ctrl.RemoveNote();
        System.assertEquals([SELECT Id FROM User_Note__c WHERE Id =: record1.Id], new List<User_Note__c>());
        ctrl.DelRecordID = null;
        results = [SELECT Id FROM User_Note__c];
        ctrl.RemoveNote();
        System.assertEquals(results, [SELECT Id FROM User_Note__c]);
        
        Test.stopTest();        
    }
}