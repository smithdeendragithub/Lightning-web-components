@isTest
public with sharing class Test_AccountScheduledTaskUtils extends TestUtils.TestClass { 
    static testMethod void testUtils(){
        Mocks testData = new Mocks();
        
        Proactive_Case_Occurrence_Setting__c s1 = new Proactive_Case_Occurrence_Setting__c();
        s1.Account_Business_Segment__c = 'Electric Lightwave Premier';
        s1.Frequency__c = 1;
        s1.Minimum_MRR__c = 0;		
        s1.Name = 'ELPLT2.5k';
        s1.Occurrence_Category__c = 'Year';
        s1.Rotating_Proactive_Type__c = false;
        s1.Starting_Activity__c = 'Account Review';
        Proactive_Case_Occurrence_Setting__c s2 = new Proactive_Case_Occurrence_Setting__c();
        s2.Account_Business_Segment__c = 'Default';
        s2.Frequency__c = 6;
        s2.Minimum_MRR__c = 0;
        s2.Name = 'DefaultLT4k';
        s2.Occurrence_Category__c = 'Month';
        s2.Occurrence_Day_Offset__c = 'Last';
        s2.Rotating_Proactive_Type__c = true;
        s2.Starting_Activity__c = 'Account Review';
        insert new List<Proactive_Case_Occurrence_Setting__c>{s1,s2};
        Account a = testData.parentAccount;
        //a.Account_Sales_Channel__c = 'Electric Lightwave Premier';

        Test.startTest();
        AccountScheduledTaskUtils.getSettingForABSAndMRR('Electric Lightwave Premier', 1000);
        AccountScheduledTaskUtils.getSettingForABSAndMRR('Integra Business', 1000);
        AccountScheduledTaskUtils.getASTNextRunDateForQuarter();
        AccountScheduledTaskUtils.getASTNextRunDateForBiAnnual();
        AccountScheduledTaskUtils.getASTNextRunDateForYear();
		system.debug(a.Customer_Detail__c + ': ' + a.MRR__c);
        //Account_Scheduled_Task__c ast = AccountScheduledTaskUtils.createASTForAccount(a.id, a.Account_Sales_Channel__c, 100.0);
        Account_Scheduled_Task__c ast = AccountScheduledTaskUtils.createASTForAccount(a.id, null, 100.0);
        ast = AccountScheduledTaskUtils.createASTForAccount(a.id, 'Integra Business', a.MRR__c);
        AccountScheduledTaskUtils.updateASTFromABSandMRR(ast, 'Electric Lightwave Business', a.MRR__c);
        Test.stopTest();
    }
}