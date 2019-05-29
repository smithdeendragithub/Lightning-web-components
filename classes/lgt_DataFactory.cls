/*
* @Author: Mahad Zaryab
* @Created Date: 
* @Modified Date: 
* Version     JIRA                  Author                        Comments
* 1.0         SEAL-2831             Mahad Zaryab                  Initial Comments  
*/

public with sharing class lgt_DataFactory {
    @AuraEnabled (Cacheable=true)
    public static Order__c[] getOrderNumber(String opportunityId) {
        Order__C[] orders = [SELECT Name FROM Order__C WHERE Id=:opportunityId];

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
    public static OpportunityTeamMember[] getOpportunityTeamMembers(String opportunityId) {
        OpportunityTeamMember[] teamMembers = [SELECT Id, User.Name, TeamMemberRole FROM OpportunityTeamMember
                                                WHERE OpportunityId = :opportunityId];
        
        return teamMembers;
    }

    @AuraEnabled (Cacheable=true)
    public static List<WorkStepIssue> getWorkstepIssuesByOrderID(Id orderID) {
        String whereClause = CustomSettingUtils.getSingleProcessConfigurationValue('Order_WorkstepIssuesWhereClause', 'User', false);
        
        Set<Id> userIDs = new Map<Id, User>((List<User>)Database.query('select Id from User' + (string.isEmpty(whereClause) ? '' : (' where ' + whereClause)))).keyset();
        
        Set<Id> wsIDs = new Set<Id>();
        for(Workstep__c ws : [select Id from Workstep__c where Order__c =: orderId]) wsIDs.add(ws.Id);
        List<WorkStepIssue> wsis = new List<WorkStepIssue>();
            for(Workstep_Issue__c w : [SELECT Id, Name, Status__c, Expected_Follow_Up_Date__c, Reason__c, Estimated_Resolution__c, 
                                Workstep__r.Name, Workstep__r.Id, Workstep__r.Sub_Order__r.Name, Workstep__r.Sub_Order__r.Order__r.Name, 
                                Workstep__r.Sub_Order__c, Workstep__r.Sub_Order__r.Order__c, Owner.Name, Owner.Type, Owner.Id        
                                    FROM Workstep_Issue__c 
                                    WHERE Workstep__c in: wsIDs and OwnerId in: userIDs
                            //and Workstep__r.Sub_Order__r.Order__r.Opportunity_Status__c = 'Sales Working'
                            and Status__c = 'Open'])
        {
        wsis.add(new WorkStepIssue(w));
        }
        
        return wsis;
    }
}