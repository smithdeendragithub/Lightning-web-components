/***********************************************************************************************************
* Name       : ACR_ApprovalMatrixTrigger
* Purpose    : Triggers get executed before Approval Matrix records get updated
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Sathya                  | 1.0        | 22/03/2019      | Initial version
***********************************************************************************************************/

trigger ACR_ApprovalMatrixTrigger on Approval_Matrix__c (before update) {
    ACR_ApprovalMatrixTriggerHelper.ApprovalRecords(Trigger.new,Trigger.OldMap);
    
}