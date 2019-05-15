@isTest
public class Test_PreventEmailFrequencyChange {
    @isTest 
    public static void TestDefaultNotificationFrequency() {
        // Insert 4 groups
        List<CollaborationGroup> lcg = new List<CollaborationGroup>();
        for (Integer i = 0; i < 4; i++) {
            CollaborationGroup cg = new CollaborationGroup(Name = 'Group' + i, CollaborationType='Public');
            lcg.add(cg);
        }
        insert lcg;
        // Create 4 Chatter Auto-Follow custom settings with 4 different Email Frequencies and insert them
        Chatter_Auto_Follow__c caf1 = new Chatter_Auto_Follow__c(Name='CS1', Criteria__c = '', Email_Frequency__c = 'P', Group__c = lcg[0].Name);
        insert caf1;
        Chatter_Auto_Follow__c caf2 = new Chatter_Auto_Follow__c(Name='CS2', Criteria__c = '', Email_Frequency__c = 'W', Group__c = lcg[1].Name);
        insert caf2;
        Chatter_Auto_Follow__c caf3 = new Chatter_Auto_Follow__c(Name='CS3', Criteria__c = '', Email_Frequency__c = 'D', Group__c = lcg[2].Name);
        insert caf3;
        Chatter_Auto_Follow__c caf4 = new Chatter_Auto_Follow__c(Name='CS4', Criteria__c = '', Email_Frequency__c = 'N', Group__c = lcg[3].Name);
        insert caf4;
        
        // Create 4 Users and 4 CollaborationGroupMembers and assign the Id from each User to a CollaborationGroupMember
        List<CollaborationGroupMember> lcgm = new List<CollaborationGroupMember>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        for (Integer j = 0; j < 4; j++) {
            User u = new User(Username='bsUser' + String.valueOf(j) + '@testbs.com', LastName='A', Email='bsUser' + String.valueOf(j) + '@testbs.com', Alias='bs' + String.valueOf(j), CommunityNickname='Test'+ string.valueOf(j), TimeZoneSidKey='America/Chicago', 
                              LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', ProfileId=p.Id, LanguageLocaleKey='en_US');
            
            //Required User fields: [Username, LastName, Email, Alias, CommunityNickname, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, ProfileId, LanguageLocaleKey]
            insert u;
            CollaborationGroupMember cgm = new CollaborationGroupMember(MemberId = u.Id, CollaborationGroupId = lcg[j].Id);
            lcgm.add(cgm);  
        }
      
        // Insert the CollaborationGroupMembers
        Test.startTest();
        insert lcgm;
       
        CollaborationGroupMember testcgm = [Select Id, NotificationFrequency, MemberId FROM CollaborationGroupMember Where MemberId = :lcgm[0].MemberId limit 1];
        System.assertEquals('P', testcgm.NotificationFrequency);
        testcgm = [Select Id, NotificationFrequency, MemberId FROM CollaborationGroupMember Where MemberId = :lcgm[1].MemberId limit 1];
        System.assertEquals('W', testcgm.NotificationFrequency);
        testcgm = [Select Id, NotificationFrequency, MemberId FROM CollaborationGroupMember Where MemberId = :lcgm[2].MemberId limit 1];
        System.assertEquals('D', testcgm.NotificationFrequency);
        testcgm = [Select Id, NotificationFrequency, MemberId FROM CollaborationGroupMember Where MemberId = :lcgm[3].MemberId limit 1];
        System.assertEquals('N', testcgm.NotificationFrequency);
        //System.assertEquals(lcgm[0].NotificationFrequency, 'P');
        //System.assertEquals(lcgm[1].NotificationFrequency, 'W');
        //System.assertEquals(lcgm[2].NotificationFrequency, 'D');
        //System.assertEquals(lcgm[3].NotificationFrequency, 'N');
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true) 
    public static void TestFrequencyChange() {
        Test.startTest();
        List<CollaborationGroup> lcg = [SELECT Id, Name FROM CollaborationGroup WHERE Name='Allstream - Critical' limit 1];
        if (lcg.isEmpty()){
           CollaborationGroup cg = new CollaborationGroup(Name = 'Allstream - Critical', CollaborationType='Public');
           insert cg; 
           lcg = [SELECT Id, Name FROM CollaborationGroup WHERE Name='Allstream - Critical' limit 1];
        }
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Username='bsUser100@testbs.com', LastName='A', Email='bsUser100@testbs.com', Alias='bs100', CommunityNickname='Test100', TimeZoneSidKey='America/Chicago', 
                              LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', ProfileId=p.Id, LanguageLocaleKey='en_US');
        insert u;
        
        CollaborationGroupMember cgm = new CollaborationGroupMember(MemberId = u.Id, CollaborationGroupId = lcg[0].Id, NotificationFrequency = 'P');
        insert cgm;
        try{
            cgm.NotificationFrequency = 'W';
        	update cgm;
       	} catch(Exception e){
        	System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
            System.Assert(e.getMessage().contains('You cannot change your email frequency for this group'));
        }
       	Test.stopTest();
    }
}