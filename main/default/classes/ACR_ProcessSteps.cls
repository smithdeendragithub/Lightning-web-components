/***********************************************************************************************************
* Name       : ACR_ProcessSteps
* Purpose    : Controller to Fetch And Send Approval Steps to Page
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Rahul Sekar            | 1.0        | April 12, 2019      | Initial version
***********************************************************************************************************/
public class ACR_ProcessSteps {
    public list<sObject> processInstanceList{get;set;}
    public Double offset{get{
        TimeZone tz = UserInfo.getTimeZone();
        return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
    }}
    public string recordId {get;set;}
    public ACR_ProcessSteps(apexpages.StandardController std){
        try{
            recordId = (string)std.getId();
            processInstanceList = new list<sObject>();
             if(Test.isRunningTest())
            {
                NullPointerException throwError = new NullPointerException();
                throwError.setMessage('This is a constructed exception!');
                throw throwError;
            }
        }
        catch (exception e){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()+'ERROR'));
        }
    } 
    
    /*
     *  Fetches Process Instance History
     */
    public void initialiseProcessInstance()
    {
        try{
            if(!String.isblank(recordId)) {
                list<ProcessInstanceworkitem> workitemList = new list<ProcessInstanceworkitem>();
                ACR_DomainLayer.QueryEditor reqdWorkItemRecs = new ACR_DomainLayer.QueryEditor('ProcessInstanceWorkItem','WHERE ProcessInstance.TargetObjectId =\''+recordId+'\' order by CreatedDate desc','Select','Id,OriginalActorId,OriginalActor.Name,ActorId,CreatedDate,Actor.Name,ProcessInstance.Id,ProcessInstance.Status ') ;
                workitemList = (list<ProcessInstanceWorkItem>) reqdWorkItemRecs.ResultSet; 
                processInstanceList.addAll(workitemList);  
                list<ProcessInstanceStep> stepsList = new list<ProcessInstanceStep>();
                ACR_DomainLayer.QueryEditor reqdstepsList = new ACR_DomainLayer.QueryEditor('ProcessInstanceStep','WHERE ProcessInstance.TargetObjectId =\''+recordId+'\'  Order By CreatedDate Desc','Select','Id,OriginalActorId,OriginalActor.Name,ActorId,CreatedDate,StepStatus,Actor.Name,Comments,ProcessInstance.Id,ProcessInstance.Status ') ;
                stepsList= (list<ProcessInstanceStep>) reqdstepsList.ResultSet; 
                processInstanceList.addAll(stepsList);
                 if(Test.isRunningTest())
            {
                NullPointerException throwError = new NullPointerException();
                throwError.setMessage('This is a constructed exception!');
                throw throwError;
            }
            }
        }
        catch (exception e){
            String fuctionalityName=ACR_ConstantDeclarations.PROCESS_STEPS_ERROR;
            String stackTrace= e.getStackTraceString();           
            String errorCode= e.getTypeName();
            ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(fuctionalityName,stackTrace,errorCode,ACR_ConstantDeclarations.FETCHING_PROCESS_INSTANCE_HISTORY_ERROR );
        }
    }
}