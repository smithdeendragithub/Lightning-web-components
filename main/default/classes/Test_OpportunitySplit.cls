@isTest
public with sharing class Test_OpportunitySplit {
    
    static testMethod void splitOpportunityTest() {
        List<User> users = new List<User>();
        users = getUserList();
                
        Mocks m = new Mocks(); 
        
        List<Account> accts = m.getAccountList(26);
        Integer index = Math.mod(Math.abs(Crypto.getRandomInteger()), accts.size());
        
        Account acct = accts.get(index);
        acct.OwnerId = users[0].Id;
        
        Id typeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Retail').getRecordTypeId();
            
            test.startTest();
            
            Opportunity oppt = new Opportunity();
            oppt.OwnerId = users[0].Id;
            oppt.RecordTypeId = typeid;
            oppt.StageName = 'Prospecting';
            oppt.AccountId = acct.Id;
            oppt.LeadSource = 'Jigsaw';
            oppt.Term__c = '36';
            oppt.Name = 'Acme Explosives 2';
            oppt.CloseDate = date.today().addDays(10);
            oppt.Amount = 243.39;
            oppt.Split_Owner_1__c = users[0].Id;
            oppt.Split_Owner_2__c = users[1].Id;
            oppt.Split_Percent_1__c = 20;
            oppt.Split_Percent_2__c = 80;
			oppt.ForecastCategoryName = 'Pipeline';
            
            insert oppt;
			update oppt;
            
            test.stopTest();
    }
    
    static List<User> getUserList(){
    
        //List<User> users = ([SELECT IsActive, Name, Id FROM User WHERE IsActive = true limit 2]);
        List<User> users = ([SELECT IsActive, Name, Id FROM User WHERE id ='005C0000003O30h' or id ='005C0000006qXvJ']);
        
        return (users.size() > 0) ? users : null;
    
    }
}