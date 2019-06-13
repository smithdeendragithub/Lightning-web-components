/*
* @Author: Mahad Zaryab
* @Created Date: 
* @Modified Date: 
* Version     JIRA                  Author                        Comments
* 1.0         SEAL-2831             Mahad Zaryab                  Initial Comments  
*/

public with sharing class lgt_DataFactory {
    @AuraEnabled
    public static Opportunity getSFId(String OpportunityId){
        return [SELECT SF_Opportunity_ID__c FROM Opportunity WHERE Id='006n0000008jjPHAAY' LIMIT 1];
    }
    @AuraEnabled (Cacheable=true)
    public static Order__c[] getOrderNumber(String opportunityId) {
        Order__c[] orders = [SELECT Name FROM Order__c WHERE Id=:opportunityId];

        return orders;
    }

    @AuraEnabled (Cacheable=true)
    public static List<OpportunityTeamMember> getOpportunityTeamMembers(String opportunityId) {
        List<OpportunityTeamMember> teamMembers = [SELECT Id, User.Name, TeamMemberRole FROM OpportunityTeamMember
                                                WHERE OpportunityId = :opportunityId];
        
        return teamMembers;
    }

    // @AuraEnabled (Cacheable=true)
    // public static List<OpportunityLocationConfiguration__c> getSolutionTableData (String opportunityId) {
    //     List<OpportunityLocationConfiguration__c> finalSolutionData = new List<OpportunityLocationConfiguration__c>();
    //     Opportunity_Location__c oppLocs = [SELECT (SELECT Id FROM Opportunity_Sites__r ) FROM Opportunity WHERE Id = :opportunityId];
    //     for (Integer count = 0; count < oppLocs.size(); count++) {
    //         String locationID = oppLocs.Id[count];
    //         OpportunityLocationConfiguration__c solutionData = [SELECT (SELECT Name, Term__c, Active__c, MRC_Total__c,  NRC_Total__c FROM OpportunityLocationConfigurations__r) FROM Opportunity_Location__c WHERE Id = :locationID];
    //         for (Integer count1 = 0; count1 < solutionData.size(); count1++) {
    //             finalSolutionData.add(solutionData[count1]);
    //         }
    //     }
    //     return finalSolutionData;
    // }

//     public void configureProductApproval(List<QuoteWrapper.Product> lstProducts, solutionWrapper solution) {
//         Integer icbcnt = 0;
//         Integer idrcnt = 0;
//         String approvalStatus = "";
//         for (QuoteWrapper.Product prd : lstProducts) {
//             for (QuoteWrapper.QuoteLineItem oli: prd.lines) {
//                 String status = oli.rawOLI.Approval_Status__c;
//                 boolean isApproved = (!String.IsEmpty(String.valueOf(oli.rawOLI.Approved__c))) ? oli.rawOLI.Approved__c : false;
//                 boolean isQuoteItem = (!String.IsEmpty(String.valueOf(oli.rawOLI.SPC_MRC_Is_Quote__c))) ? oli.rawOLI.SPC_MRC_Is_Quote__c : false; 

//                 if (!String.IsEmpty(status) && !isApproved) {
//                     if (status.contains('offer')) {
//                         icbcnt++;
//                     } else if (status.contains('Sales')){
//                         idrcnt++;
//                     }
//                 }

//                 if (isQuoteItem && !isApproved) {
//                     icbcnt++;
//                 }

//                 if (icbcnt > 0)
//                     solution.approvalStatus = 'Offer Management Approval Required';
//                 else if (idrcnt > 0)
//                     solution.approvalStatus = 'Sales Management Approval Required';
//                 else 
//                     solution.approvalStatus = 'Approved';
//             }
//         }
//     }
// }

// public class solutionWrapper {
//     public OpportunityLocationConfiguration__c rawSolution;
//     public String approvalStatus;
//     public solutionWrapper (OpportunityLocationConfiguration__c rawSolution) {
//         this.rawSolution = rawSolution;
//     }
}
