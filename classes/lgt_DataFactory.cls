/*
* @Author: Smithdeendra A P
* @Created Date: 02-Jun-2019
* @Modified Date: 02-Jun-2019
* Version     JIRA                  Author                        Comments
* 1.0         SEAL-2879             Smithdeendra A P              Initial Comments  
*/

public with sharing class lgt_DataFactory {
    @AuraEnabled (Cacheable=true)
    public static List<Order__c> getOrderNumber(String opportunityId) {
        List<Order__c> orders = [SELECT Id,Name,Opportunity_Coordinator__c,Status__c,
                                Status_Reason__c,Data_Missing_Codes__c,Data_Missing_Comments__c,
                                Order_Pending_Date__c FROM Order__c WHERE Id=:opportunityId];

        return orders;
    }
}