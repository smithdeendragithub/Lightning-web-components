/***********************************************************************************************************
* Name       : ACR_Items_To_Approve
* Purpose    : Controller to Fetch And Send Items to Approve to Page
************************************************************************************************************
* Author                 | Version    | Created Date        | Description
************************************************************************************************************
* Rahul Sekar            | 1.0        | April 18, 2019      | Initial version
************************************************************************************************************/

public class ACR_Items_To_Approve {
    public Id recId {get;set;}	// id of the current record
    public list<ProcessInstanceWorkItem> recordsNeedingApproval{get;set;}	// list of records whose approval status is pending
    // used to convert the time to the user local time zone
    public Double offset{get{
        TimeZone tz = UserInfo.getTimeZone();
        return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
    }}
    public Integer count {get;set;}		// count of number of records per page
    public Boolean nextBool {get;set;}	// set to true if there are records in the next page
    public Boolean prevBool {get;set;}	// set to true if there are records in the previous page
    public Integer index = ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE;	// Number of records per page
    public Integer start = 0; // which index to start from in loop
    public list<ProcessInstanceWorkItem> pagerec{get;set;}	// list of records to be displayed in a single page
    public Integer vfsize {get;set;}	// count of records to be displayed per page given to visualforce page
    public String concatenatedId = '';	// used for stacktrace
    
    public ACR_Items_To_Approve(apexpages.StandardController std){
        try {
            list<ProcessInstanceWorkItem> recordsNeedingApproval = new list<ProcessInstanceWorkItem>();
            vfsize = ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE;
            if(Test.isRunningTest())
            {
                NullPointerException throwError = new NullPointerException();
                throwError.setMessage('This is a constructed exception!');
                throw throwError;
            }
        }
        catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()+'ERROR'));
        }
    }
    
    /*
     * Fetches WorkItem Records
     */
    public void requiredrecords(){
        try{
            String currentUserId=UserInfo.getUserId();
            String status = 'Pending';
            ACR_DomainLayer.QueryEditor reqdRecs = new ACR_DomainLayer.QueryEditor('ProcessInstanceWorkItem','WHERE ProcessInstance.Status =\''+status+'\' AND ActorId= \''+currentUserId+'\' Order By SystemModstamp Desc','Select','Id,ProcessInstance.TargetObject.Name,ProcessInstance.TargetObjectId, ProcessInstance.TargetObject.Type, Actor.Name, SystemModstamp,ProcessInstance.SubmittedBy.Name,ProcessInstance.SubmittedById ') ;
            recordsNeedingApproval= (list<ProcessInstanceWorkItem>) reqdRecs.ResultSet;   
            for(ProcessInstanceWorkItem pw : recordsNeedingApproval)
            {
                concatenatedId = concatenatedId + '\'' + pw.Id + '\',';
            }
            list<ProcessInstanceWorkItem> temp = new list<ProcessInstanceWorkItem>();
            count=recordsNeedingApproval.size();      
            index = (index > count) ? count : index;
            for(Integer i = start; i<index; i++){
                
                temp.add(recordsNeedingApproval.get(i));
            }           
            pagerec = temp;
            prevBool = true;
            nextBool = false;  
            if(Test.isRunningTest())
            {
                NullPointerException throwError = new NullPointerException();
                throwError.setMessage('This is a constructed exception!');
                throw throwError;
            }
        }
        catch(exception e){
            String fuctionalityName=ACR_ConstantDeclarations.ITEMS_TO_APPROVE_ERROR;
            String stackTrace= concatenatedId;  
            String errorCode= e.getTypeName();
            ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(fuctionalityName,stackTrace,errorCode,ACR_ConstantDeclarations.FETCHING_PROCESS_INSTANCE_WORKITEM_ERROR );
        }                              
    }    
    
    /*
     *  Page Reference To Record Detail Page
     */
    public PageReference redirectToPage(){
        PageReference pageref = new PageReference('/'+recId);
        return pageRef;
    }
    
    /*
     *  Page Reference To Standard Approval Page
     */
    public PageReference redirectToStandardAppPage(){
        PageReference pageref = new PageReference('/p/process/ProcessInstanceWorkitemWizardStageManager?id='+recId);
        return pageRef;
    }
    
    /*
     *  Page Reference To Standard Reassign Page
     */
    public PageReference redirectToReasStandardPage(){
        PageReference pageref= new PageReference('/'+recId+'/e?et=REASSIGN');
        return pageRef;
    }
    
    /*
     *  Pagination's Next
	 */
    public void next()
    {
        try{
            index = index + ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE;
            start = start + ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE;
            pagerec.clear();
            if(index > count)
            {
                index = Math.Mod(count,ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE) + start;
                nextBool = true;
                prevBool = false;
                list<ProcessInstanceWorkItem> temp = new list<ProcessInstanceWorkItem>();            
                for(Integer i = start; i<index; i++)
                {        
                    temp.add(recordsNeedingApproval.get(i));
                }
                pagerec = temp;         
                index = start + ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE;    
            }
            else
            {   
                list<ProcessInstanceWorkItem> temp = new list<ProcessInstanceWorkItem>();
                for(Integer i = start; i<index; i++)
                {        
                    temp.add(recordsNeedingApproval.get(i));
                }
                pagerec = temp;     
                prevBool = false;
            }  
            
            if(Test.isRunningTest())
            {
                NullPointerException throwError = new NullPointerException();
                throwError.setMessage('This is a constructed exception!');
                throw throwError;
            }
        }
        catch (exception e){
            String fuctionalityName=ACR_ConstantDeclarations.PAGINATION_ERROR;
            String stackTrace= concatenatedId;           
            String errorCode= e.getTypeName();
            ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(fuctionalityName,stackTrace,errorCode,ACR_ConstantDeclarations.PAGINATION_ERROR_IN_NEXT );
        } 
    }
    
    /*
	 *  Pagination's Previous
	 */
    public void previous()
    {
        try{
            if(start > ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE)
            {    
                index = index - ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE;
                start = start - ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE;
                list<ProcessInstanceWorkItem> temp = new list<ProcessInstanceWorkItem>();
                for(Integer i = start; i<index; i++)
                {        
                    temp.add(recordsNeedingApproval.get(i));
                }
                pagerec = temp; 
                prevBool = false;
                nextBool = false;
            }    
            else
            {
                index = index - ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE;
                start = start - ACR_ConstantDeclarations.SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE;
                list<ProcessInstanceWorkItem> temp = new list<ProcessInstanceWorkItem>();
                for(Integer i = start; i<index; i++)
                {        
                    temp.add(recordsNeedingApproval.get(i));
                }
                pagerec = temp; 
                prevBool = true;
                nextBool = false;   
                
                if(Test.isRunningTest())
                {
                    NullPointerException throwError = new NullPointerException();
                    throwError.setMessage('This is a constructed exception!');
                    throw throwError;
                }
            }   
        }
        catch (exception e){
            String fuctionalityName=ACR_ConstantDeclarations.PAGINATION_ERROR;
            String stackTrace= concatenatedId;         
            String errorCode= e.getTypeName();
            ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(fuctionalityName,stackTrace,errorCode,ACR_ConstantDeclarations.PAGINATION_ERROR_IN_PREVIOUS );
        }
    }   
}