/***********************************************************************************************************
* Name       : ACR_DOAProcessingBatch
* Purpose    : Creating Approval Matrix record and Triggering email
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Satya                  | 1.0        | 19/03/2019      | Initial version
* Santoshi - Added upsert logic. Changed the select queries for DOA and few other clean up.
* Santoshi - Modified error handling codes.
***********************************************************************************************************/

global class ACR_DOAProcessingBatch implements Database.Batchable<sObject> {
    
    String QUERY = 'Select Id, Name,Title,Title_Not_Found_in_DOA__c FROM USER WHERE Excludes_From_Batch_Processing__c=False AND Ready_For_DOA_Processing__c=True ';
    
    public ACR_DOAProcessingBatch(){
        
    }
    public ACR_DOAProcessingBatch(String UserId){
        QUERY = 'Select Id, Name,Title,Title_Not_Found_in_DOA__c FROM USER WHERE Id = \''+UserId+'\'';
        
    }
    // Start method for batch class
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(QUERY) ;
    }
    
    //Execute method for batch class
    global void execute(Database.BatchableContext BC, List<User> retriveUser) {
        
        try{
            //Fetching DOA mappings
            ACR_DomainLayer.QueryEditor jobTitleQueryEditor = new ACR_DomainLayer.QueryEditor('DOA_Mapping__c',' ','SELECT');
            List<DOA_Mapping__c> jobTitle = (List<DOA_Mapping__c>) jobTitleQueryEditor.ResultSet;  
            ACR_DomainLayer.QueryEditor CustomMetadaRecords = new ACR_DomainLayer.QueryEditor('ACR_DOA_Approval_Mapping__mdt',' ','SELECT','Source_Field__c,Target_Field__c ');
            List<ACR_DOA_Approval_Mapping__mdt> metadataRecords = (List<ACR_DOA_Approval_Mapping__mdt>) CustomMetadaRecords.ResultSet;     
            Map<String,String> srcVsdest = new Map<String,String>();
            //Storing the Source and Target values in Map
            for(ACR_DOA_Approval_Mapping__mdt mapping : metadataRecords){
                srcVsdest.put((String)mapping.get('Source_Field__c'), (String)mapping.get('Target_Field__c'));
            }     
            Map<Id,User> titleNotFoundUsers= new Map<Id,User>();
            List<Approval_Matrix__c> newApprovalMatrix=new List<Approval_Matrix__c>();
            
            //Creating Approval Matrix Record if JobTitle matches 
            for(User user:retriveUser)
            {
                for(DOA_Mapping__c doa:jobTitle)
                {
                    if(user.Title == doa.Job_Title__c)
                    {
                        user.Title_Not_Found_in_DOA__c=false;
                        titleNotFoundUsers.remove(user.Id);
                        Approval_Matrix__c approvalMatrix= new Approval_Matrix__c();  
                        approvalMatrix.DOA_Matched_Job_Title__c=doa.Job_Title__c;
                        approvalMatrix.Employee__c = user.Id;
                        approvalMatrix.User_Id__c = user.Id;
                        for(String src : srcVsdest.keyset()){
                            approvalMatrix.put(srcVsdest.get(src),doa.get(src));
                        }
                        newApprovalMatrix.add(approvalMatrix); 
                        break;
                    }
                    //Updates two checkbox fields in User if title doesn't match
                    else
                    {
                        user.Title_Not_Found_in_DOA__c = True;
                        user.Ready_For_DOA_Processing__c = False;
                        titleNotFoundUsers.put(user.Id,user);                    
                    }
                }
            } 
            //Upserts the Approval Matrix Record
            Schema.SObjectField externalField = Approval_Matrix__c.Fields.User_Id__c;
            Database.UpsertResult [] UpsertResult = Database.upsert(newApprovalMatrix,externalField, false);
            List<Id> userId=new List<Id>();
            String concatenatedObjId;
            String fuctionalityName;
            String errorCode;
            String operation;
            //Fetching User Id's of successfully created record
            for(Integer index = 0, size = UpsertResult.size(); index < size; index++) {      
                if(UpsertResult[index].isSuccess()) {
                        Id approvalUserId=newApprovalMatrix[index].User_Id__c;
                        userId.add(approvalUserId); 	  
                }
                else if(UpsertResult[index].getErrors().size() > 0){
                    for(Database.Error err : UpsertResult[index].getErrors())
                    {
                        concatenatedObjId=UpsertResult[index].getId()+',';
                        errorCode=err.getMessage();
                    }
                }
            }
            if(!String.isBlank(concatenatedObjId)){
                fuctionalityName=ACR_ConstantDeclarations.HR_ERROR_FUNCTIONALITY_NAME;
                concatenatedObjId.removeEnd(',');
                operation = ACR_ConstantDeclarations.OPERATION_NAME_BATCH_UPSERT;
                ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(fuctionalityName,concatenatedObjId,errorCode,operation); 
            }
            //Fetches Users who belongs to that record
            List<User> lstUsersToBeUpdate= new List<User>(); 
            //Updates Ready_For_DOA_Processing__c as False for the users
            for( Id id : userId)
            {
                User user=new User(Id=id,Ready_For_DOA_Processing__c=False);
                lstUsersToBeUpdate.add(user);
            }update lstUsersToBeUpdate;
            Database.SaveResult [] updateResult = Database.update(titleNotFoundUsers.values(), false);           
            if(Test.isRunningTest())
            {
                NullPointerException throwError = new NullPointerException();
                throwError.setMessage('This is a constructed exception!');
                throw throwError;
            }   
        }
        // Catching the Exception
        catch(Exception ex){
            String fuctionalityName=ACR_ConstantDeclarations.HR_ERROR_FUNCTIONALITY_NAME;
            String stackTrace= ex.getStackTraceString();           
            String errorCode= ex.getTypeName();
            ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(fuctionalityName,stackTrace,errorCode,ACR_ConstantDeclarations.OPERATION_NAME_BATCH_UPSERT );
        } 
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
}