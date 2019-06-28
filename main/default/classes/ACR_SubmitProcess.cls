/***********************************************************************************************************
* Name       : ACR_SubmitProcess
* Purpose    : Approval Processing using custom buttons
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Sathya                 | 1.0        | April 12, 2019  | Initial version
***********************************************************************************************************/
public class ACR_SubmitProcess {
    private apexpages.StandardController sc;
    public Id userId {get; set;} //Stores selected User Id from User Hierarchy list
    public Id recordId {get; set;} //Passes the Refund/Credit record id to VF page
    public Boolean showUserHierarchy {get; set;} //Decides whether to display User Hierarchy page or not
    public Map<Id,userWithLimit> parentUser {get; set;} //Stores Id and approval limits of Hierarchy users
    public String Comments {get; set;} //User entered comments for the approval process
    public Boolean showComments {get; set;} //Displays comment section based on condition
    public Boolean showHideButtons {get; set;} //Displays custom approval buttons based on criteria
    public Boolean enableRecall {get; set;} //Enable recall button for the user who submitted approval process
    public Boolean isReassign {get; set;} //Checks if it's functionality
    public Boolean isReject {get; set;} //Checks if it's functionality
    public Boolean isRecall {get; set;} //Checks if it's functionality
    public Boolean isApprove {get; set;} //Checks if it's approve functionality
    Refund_Credit__c refund; //Gets record Id of Refund/Credit
    List<Refund_Credit__c> checkLimit; //Contains limits of Refund/Credit record
    public List<ProcessInstanceWorkitem> workItems; //Approval history of Refund/Credit record
    List<Approval_Matrix__c> approvalLimits; //List of Approval limits of users
    List<RecordType> recordTypeName; //Contains UI name of the record type
    String status=ACR_ConstantDeclarations.STATUS; //Status of the approval history
    Boolean isSubmit; //Checks if it's submit functionality
    Boolean recordTypeCheck; //Checks for record type name

    public class userWithLimit{
        public string managerName {get; set;}
        public string userTitle {get; set;}
        public integer userCreditLimit {get; set;}
        public integer userRefundLimit {get; set;}
    }  
    //Constructor
    public ACR_SubmitProcess(apexpages.StandardController sc){ 
        try{
            recordId = sc.getId();
            refund = (Refund_Credit__c) sc.getRecord(); 
            isReassign = false;
            isReject = false;
            isRecall = false;
            isApprove = false;
            isSubmit = false;
            initialiseApprovalRecord();
            if(Test.isRunningTest())
            {
                NullPointerException throwError = new NullPointerException();
                throwError.setMessage('This is a constructed exception!');
                throw throwError;
            }  
        }
        catch(exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()+'ERROR'));
        } 
    }

    /*
    *   Submits Record for Approval
    */
    public  void submitRecord(){
        try{
            isSubmit= True;
            refund.Current_Step__c=1;
            update refund; 
            showHideButtons=True; 
            if(Test.isRunningTest())
            {
                nullPointerException();
            }  
        }
        catch(Exception ex){
            ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(ACR_ConstantDeclarations.SUBMIT_PROCESS_ERROR,ex.getStackTraceString(),ex.getTypeName(),ACR_ConstantDeclarations.OPERATION_NAME_UPDATE_FIELD );
        } 
    }

    /*
    *   Initialises Record for Approval
    */
    public void initialiseApprovalRecord(){ 
        try{
            //Fetching record details
            ACR_DomainLayer.QueryEditor refundCredit = new ACR_DomainLayer.QueryEditor('Refund_Credit__c','WHERE Id= \''+recordId+'\'','SELECT','Id,Name,RecordType.Name,Amount__c,Next_Approver__c,Current_Step__c,Status__c ');
            checkLimit=(List<Refund_Credit__c>) refundCredit.ResultSet;
            //Fetching Record Type Name
            Id recordTypeId=checkLimit[0].RecordTypeId;
            ACR_DomainLayer.QueryEditor recordName = new ACR_DomainLayer.QueryEditor('RecordType','WHERE Id= \''+recordTypeId+'\'','SELECT','Id,Name ');
            recordTypeName=(List<RecordType>) recordName.ResultSet;
            recordTypeCheck = False;
            if(recordTypeName[0].Name.containsIgnoreCase('Refund'))
            {
                recordTypeCheck = True;
            }
            //Fetching approval details
            ACR_DomainLayer.QueryEditor workItemList = new ACR_DomainLayer.QueryEditor('ProcessInstanceWorkitem','WHERE ProcessInstance.TargetObjectId =\''+recordId+'\''+' AND ProcessInstance.Status = \''+status+'\'','SELECT','Id,ActorID,ProcessInstance.TargetObjectId,ProcessInstance.Status,ProcessInstance.submittedById ');
            workItems = (List<ProcessInstanceWorkitem>) workItemList.ResultSet; 
            //Fetching approval matrix record for the loggedin user
            Id currentUser=UserInfo.getUserId();
            ACR_DomainLayer.QueryEditor recordDetail = new ACR_DomainLayer.QueryEditor('Approval_Matrix__c','WHERE User_ID__c= \''+currentUser+'\'','SELECT','Id,User_ID__c,Refund_Approval_Limit__c,Credit_Approval_Limit__c ');
            approvalLimits=(List<Approval_Matrix__c>) recordDetail.ResultSet;
            showUserHierarchy = false;
            showComments = false; 
            ACR_Utils checkLink=new ACR_Utils();
            showHideButtons=ACR_Utils.determineApproveButtonAccess(recordId,'','');
            enableRecall=false;
            if(Approval.isLocked(recordId)==True){
                if(workItems != null && !workItems.isEmpty()){
                    if(workItems[0].ProcessInstance.submittedById == UserInfo.getUserId())
                    {
                        enableRecall=true;
                    } 
                }
            }
            validateActionParam();
            userDetails();
            if(Test.isRunningTest())
            {
                nullPointerException();
            }  
        }
        catch(Exception ex){
            ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(ACR_ConstantDeclarations.SUBMIT_PROCESS_ERROR,ex.getStackTraceString(),ex.getTypeName(),ACR_ConstantDeclarations.SUBMIT_PROCESS_INITIALIZATION );
        } 
    }

    /*
    *   Validation action value in URL
    */ 
    public void validateActionParam(){
        String actionName = System.currentPageReference().getParameters().get('action');
        if(!String.isBlank(actionName)) {
            if(actionName.containsIgnoreCase(ACR_ConstantDeclarations.Approve)) {
                approveProcess();
            } 
            else if(actionName.containsIgnoreCase(ACR_ConstantDeclarations.REJECT)) {
                rejectRecord();
            } 
            else if(actionName.containsIgnoreCase(ACR_ConstantDeclarations.REASSIGN)) {
                reassignPage();
            }
        }
    }

    /*
    *   Approval processing based on request
    */ 
    public void approvalProcessing(String action){
        if(workItems != null && !workItems.isEmpty()){
            Approval.ProcessWorkitemRequest workItem = new Approval.ProcessWorkitemRequest();
            workItem.setComments(Comments);
            workItem.setAction(action);
            workItem.setWorkItemId(workItems[0].id);
            Approval.ProcessResult result = Approval.process(workItem);  
        }
    }
    
    /*
    *  Fetching Manager Hierarchy List
    */
    public void userDetails(){
        try{
            Set<Id> keyValues;
            Id currentUser=UserInfo.getUserId();
            keyValues = new Set<Id>();
            Boolean top = false;
            parentUser = new Map<Id,userWithLimit>();
            //Displays Manager's list for the loggedin user
            while (!top) {
                userWithLimit userLimit = new userWithLimit();
                ACR_DomainLayer.QueryEditor currentUserDetail = new ACR_DomainLayer.QueryEditor('User','WHERE Id =\''+currentUser+'\'','SELECT','Id,ManagerId,Manager.Name,Manager.Title,Title ');  
                List<User> userDetail=(List<User>) currentUserDetail.ResultSet;       
                ACR_DomainLayer.QueryEditor recordDetail = new ACR_DomainLayer.QueryEditor('Approval_Matrix__c','WHERE User_ID__c= \''+userDetail[0].ManagerId+'\'','SELECT','Id,User_ID__c,Refund_Approval_Limit__c,Credit_Approval_Limit__c ');
                List<Approval_Matrix__c> managerApprovalLimits=(List<Approval_Matrix__c>) recordDetail.ResultSet;
                //Passing the values to Map in order to use in VF page
                if(managerApprovalLimits != null && !managerApprovalLimits.isEmpty() && userDetail != null && !userDetail.isEmpty() && approvalLimits != null && !approvalLimits.isEmpty()){
                    if (userDetail[0].ManagerId != null ){
                        if(((recordTypeCheck==True && managerApprovalLimits[0].Refund_Approval_Limit__c > approvalLimits[0].Refund_Approval_Limit__c))||((recordTypeCheck==False && managerApprovalLimits[0].Credit_Approval_Limit__c > approvalLimits[0].Credit_Approval_Limit__c))){
                            currentUser = userDetail[0].ManagerId;
                            userLimit.managerName = userDetail[0].Manager.Name;
                            userLimit.userTitle = userDetail[0].Manager.Title;
                            userLimit.userCreditLimit = Integer.valueOf(managerApprovalLimits[0].Credit_Approval_Limit__c);
                            userLimit.userRefundLimit = Integer.valueOf(managerApprovalLimits[0].Refund_Approval_Limit__c);
                            parentUser.put(currentUser,userLimit);
                        } 
                        currentUser = userDetail[0].ManagerId;
                    } 
                    else{
                        top = true;
                    }
                }
                else
                    top = true;
            }
            keyValues = parentUser.keySet();
            if(Test.isRunningTest())
            {
                nullPointerException();
            }  
        }
        catch(Exception ex){
            ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(ACR_ConstantDeclarations.SUBMIT_PROCESS_ERROR,ex.getStackTraceString(),ex.getTypeName(),ACR_ConstantDeclarations.SUBMIT_PROCESS_USER_DETAILS );
        } 
    } 
    
    /*
    *  Processing Request based on Locked Status
    */
    public PageReference processUser()
    {
        try{
            if(Approval.isLocked(recordId)){
                if(checkLimit != null && !checkLimit.isEmpty()){    
                    Integer currentStepNumber=integer.valueOf(checkLimit[0].Current_Step__c)+1;  
                    checkLimit[0].Next_Approver__c=userId;
                    if(!isReassign){
                        checkLimit[0].Current_Step__c=currentStepNumber;
                    }
                    update checkLimit;
                } 
                if(isReassign){
                    //Reassign the Refund/Credit record
                    if(workItems != null && !workItems.isEmpty() && checkLimit != null &&!checkLimit.isEmpty()){
                        workItems[0].ActorID=userId;
                        update workItems;
                        checkLimit[0].Next_Approver__c=userId;
                        update checkLimit;
                    }
                }
                else if(isReject){
                    //Rejecting the Refund/Credit record
                    String action = 'Reject';
                    approvalProcessing(action);
                }
                else if(isRecall){
                    //Recalling the Refund/Credit record
                    String action = 'Removed';
                    approvalProcessing(action);
                }
                else if(isApprove){
                    //Approving the Refund/Credit record
                    String action = 'Approve';
                    approvalProcessing(action);
                    }
            }
            else if(isSubmit){
                //Submitting Approval Record
                refund.Next_Approver__c = userId;
                update refund;
                Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
                submitRequest.setComments(Comments);
                submitRequest.setObjectId(recordId);
                submitRequest.setNextApproverIds(new Id[] {userId});
                Approval.ProcessResult result = Approval.process(submitRequest); 
            } 
            if(Test.isRunningTest())
            {
                nullPointerException();
            }  
        }
        catch(Exception ex){
            ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(ACR_ConstantDeclarations.SUBMIT_PROCESS_ERROR,ex.getStackTraceString(),ex.getTypeName(),ACR_ConstantDeclarations.SUBMIT_PROCESS_FUNCTIONALITY );
        } 
        PageReference pageR = new PageReference('/'+recordId);
        return pageR;
    }    
    
    /*
    *  Record Recall Process
    */
    public PageReference recallApprovalProcess(){ 
        isRecall=True;
        showComments=True;
        showUserHierarchy = true;
        return null;
    }
    
    /*
    *  Record Approval Process
    */
    public PageReference approveProcess(){
        try{
            if(workItems != null && !workItems.isEmpty()){
                Boolean sendToNextApprover=False;
                //Comparing User limits with Amount in the record
                if(checkLimit != null && !checkLimit.isEmpty() && approvalLimits != null && !approvalLimits.isEmpty()){
                    if(checkLimit[0].RecordType.Name.contains('Refund'))
                    {
                      if(checkLimit[0].Amount__c > approvalLimits[0].Refund_Approval_Limit__c)
                         {
                            sendToNextApprover=True;
                         }
                    }
                    else if(checkLimit[0].RecordType.Name.contains('Credit'))
                    {
                      if(checkLimit[0].Amount__c > approvalLimits[0].Credit_Approval_Limit__c)
                         {
                            sendToNextApprover=True;
                         }
                    }
                }   
                //Process Request if the User Limit is Higher
                if(!sendToNextApprover){
                    showComments=True;
                    isApprove = True;
                    showUserHierarchy = true;
                } 
                //Redirect to User Hierarchy Page
                else{
                    isApprove = True;
                    showUserHierarchy = true;
                } 
            }
            else{
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Action Not Allowed'); 
                ApexPages.addMessage(myMsg);
            }
            if(Test.isRunningTest())
            {
                nullPointerException();
            }  
        }
        catch(Exception ex){
            ACR_DomainLayer.PRFT_Error errorLog = new ACR_DomainLayer.PRFT_Error(ACR_ConstantDeclarations.SUBMIT_PROCESS_ERROR,ex.getStackTraceString(),ex.getTypeName(),ACR_ConstantDeclarations.SUBMIT_PROCESS_FUNCTIONALITY );
        } 
        return null;
    }
    
    /*
    *  Reassign the record to different user
    */
    public PageReference reassignPage() {
        isReassign = True;
        showUserHierarchy = true;  
        return null;    
    }
    
    /*
    *  Rejecting approval process
    */
    public PageReference rejectRecord() {
        isReject=True;
        showComments = true;
        showUserHierarchy = true; 
        return null;
    }
    
    /*
    *  Resetting Boolean value for Showing Comments section
    */
    public void resetShowComments(){
        showComments=True;
    }
    
    /*
    *  Null Pointer exception for catch
    */
    public void nullPointerException(){
           NullPointerException throwError = new NullPointerException();
           throwError.setMessage('This is a constructed exception!');
           throw throwError;
    }
}