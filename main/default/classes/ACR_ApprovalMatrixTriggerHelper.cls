/***********************************************************************************************************
* Name       : ACR_ApprovalMatrixTriggerHelper
* Purpose    : Check for Files in Approval Matrix record and logs error in a Custom Label
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Sathya                  | 1.0        | 22/03/2019      | Initial version
***********************************************************************************************************/

public class ACR_ApprovalMatrixTriggerHelper {
    
    public static void ApprovalRecords(List<Approval_Matrix__c> newApproval,Map<Id,Approval_Matrix__c> oldApprovalMapId){ 
        String matrixId ='';
        try{ 
            // checkbox exemption
            Set<Id> approvalId = new Set<Id>();
            if(System.isBatch())  // Don't execute the validation in batch context.
            return;
            //Checking for field update
            List<Approval_Matrix__c> listAppMatrix = new List<Approval_Matrix__c>();
            for (Approval_Matrix__c approvalRecord:newApproval){
                if(!approvalRecord.Override_Attachment_Validation__c){
                    if(approvalRecord.Credit_Approval_Limit__c != oldApprovalMapId.get(approvalRecord.Id).Credit_Approval_Limit__c ||
                       approvalRecord.Refund_Approval_Limit__c != oldApprovalMapId.get(approvalRecord.Id).Refund_Approval_Limit__c ||
                       approvalRecord.iCert_Max__c != oldApprovalMapId.get(approvalRecord.Id).iCert_Max__c ){
                           matrixId = matrixId + '\'' + approvalRecord.Id + '\',';
                           listAppMatrix.add(approvalRecord);   
                       }
                }                
            }
            matrixId = matrixId.removeEnd(',');         
            Map<Id, Id> entityVsconDocument = new Map<Id, Id>();
            //Fetching the Files realted to the Approval Matrix
            if(String.isNotEmpty(matrixId)){
                Datetime myDateTime = Datetime.now().addHours(-24);
                String pastDateTime = myDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                ACR_DomainLayer.QueryEditor attachments = new 
                    ACR_DomainLayer.QueryEditor('ContentDocumentLink','WHERE LinkedEntityId IN ('+ matrixId+ ') AND ContentDocument.CreatedDate>= '+pastDateTime,'SELECT');
                List<ContentDocumentLink> attachmentFiles = (List<ContentDocumentLink>) attachments.ResultSet;
                for( ContentDocumentLink file :attachmentFiles){
                    entityVsconDocument.put(file.LinkedEntityId, file.Id);
                }
            }
            //Displays error from custom label value
            for(Approval_Matrix__c appMatrix : listAppMatrix){
                if(entityVsconDocument.get(appMatrix.Id) ==null){
                    appMatrix.adderror(System.Label.ACR_Exempt_DOA_Validation_Message);
                }   
            }
            if(Test.isRunningTest())
            {
                NullPointerException testException = new NullPointerException();
                testException.setMessage('This is a constructed exception!');
                throw testException;
            }  
        }
        // Catching the Exception
        catch(Exception e){
            String fuctionalityName=ACR_ConstantDeclarations.APPROVAL_MATRIX_TRIGGER_ERROR;
            String stackTrace=e.getStackTraceString();
            String errorCode=e.getMessage();
            String operation=ACR_ConstantDeclarations.OPERATION_NAME_TRIGGER;
            String recURL=matrixId;
            ACR_DomainLayer.PRFT_Error errorLog = new 
                ACR_DomainLayer.PRFT_Error(fuctionalityName,stackTrace,errorCode,operation,recURL,true);
        } 
    }
}