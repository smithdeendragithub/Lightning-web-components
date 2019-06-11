/***********************************************************************************************************
* Name       : ACR_Utils
* Purpose    : Utility Class
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Rahul Sekar                  | 1.0        | April 17, 2019     | Initial version
***********************************************************************************************************/
public with sharing class ACR_Utils {
    /*
     *  Determines the button access based on the current user criteria
     */
    public static Boolean determineApproveButtonAccess(Id recordIds, String recordType, String approvalMethodName){
        String currentUserId=UserInfo.getUserId();
        String recordId=(String)recordIds;
        list<User> delApp = new list<User>();
        list<Refund_Credit__c> rec= new list<Refund_Credit__c>();
        list<User> currUser = new list<User>();
        ACR_DomainLayer.QueryEditor existingUser = new ACR_DomainLayer.QueryEditor('User','WHERE Id=\''+currentUserId+'\'','Select','Profile.Name ');
        currUser=(list<User>)existingUser.ResultSet;
        ACR_DomainLayer.QueryEditor refundCredit = new  ACR_DomainLayer.QueryEditor('Refund_Credit__c','WHERE Id=\''+recordId+'\'','SELECT','Next_Approver__c ');
        rec=(list<Refund_Credit__c>)refundCredit.ResultSet;
        If(rec[0].Next_Approver__c!=Null)
        {  
            ACR_DomainLayer.QueryEditor delAppUser = new  ACR_DomainLayer.QueryEditor('User','WHERE Id=\''+rec[0].Next_Approver__c+'\'','SELECT','Id ');
            delApp= (list<User>)delAppUser.ResultSet;
        }
        If(!currUser.isEmpty() && !delApp.isEmpty() && 
           (currUser[0].Profile.Name==ACR_ConstantDeclarations.SYSTEM_ADMIN || currentUserId==rec[0].Next_Approver__c || currentUserId == delApp[0].Id) )
        {
            return true;
        }
        else{
            return false;
        }        
    }

    
}