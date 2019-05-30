/*
* @Author: Mahad Zaryab
* @Created Date: 
* @Modified Date: 
* Version     JIRA                  Author                        Comments
* 1.0         SEAL-2831             Mahad Zaryab                  Initial Comments  
*/

public with sharing class lgt_DataFactory {
    @AuraEnabled (Cacheable=true)
    public static List<Order__c> getOrderNumber(String opportunityId) {
        List<Order__c> orders = [SELECT Id,Name,Opportunity_Coordinator__c,Status__c,
                                Status_Reason__c,Data_Missing_Codes__c,Data_Missing_Comments__c,
                                Order_Pending_Date__c FROM Order__c WHERE Id=:opportunityId];

        return orders;
    }

    @AuraEnabled(Cacheable=true)
    public static OpportunityLocationConfiguration__c[] getSolutionTableData(String opportunityId) {
        OpportunityLocationConfiguration__c[] solutions = [SELECT Name, Term__C, Active__c, MRC_Total__C,  NRC_Total__c FROM OpportunityLocationConfiguration__c 
                                                            WHERE Id =:opportunityId];

        // Add Approval Status Logic 
        
        return solutions;
    }

    // @AuraEnabled(Cacheable=true)
    // public static Opportunity getAccountId(String opportunityId) {
    //     Opportunity opportunity = [SELECT Account.Id FROM Opportunity where Id=:opportunityId LIMIT 1];

    //     return opportunity;
    // }

    // @AuraEnabled(Cacheable=true)
    // public static Account getAccountId() {
    //     Account account = [SELECT Id FROM Account where Id='001n000000Wdag9AAB'];

    //     return account;
    // }

    @AuraEnabled (Cacheable=true)
    public static List<OpportunityTeamMember> getOpportunityTeamMembers(String opportunityId) {
        List<OpportunityTeamMember> teamMembers = [SELECT Id, User.Name, TeamMemberRole FROM OpportunityTeamMember
                                                WHERE OpportunityId = :opportunityId];
        
        return teamMembers;
    }
}