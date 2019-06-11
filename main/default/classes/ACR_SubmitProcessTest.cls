/***********************************************************************************************************
* Name       : ACR_SubmitProcessTest
* Purpose    : Test class for ACR_SubmitProcess
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Sathya                 | 1.0        | 02/05/2019      | Initial version
***********************************************************************************************************/
@isTest
public class ACR_SubmitProcessTest {
    /*
    * 	Approve Process with higher limit
    */
    @isTest
    static void approveTest(){  
        Account newAccount = TestClassFactory.newAccount();        
        Customer_Detail__c customerDetail = TestClassFactory.customerDetails(newAccount.Id);
        String profileName='\'System Administrator\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        Id profId=profileId[0].Id;
        User oldUser = TestClassFactory.userDetails1(profId);
        insert oldUser;
        User newUser = TestClassFactory.userDetails2(profId,oldUser.Id);
        insert newUser;
        Refund_Credit__c refundRecord = TestClassFactory.refundCredit2(customerDetail.Id,newUser);
        Approval_Matrix__c approvalRecord = TestClassFactory.approvalMatrix(newUser.Id);     
        insert approvalRecord;
        Approval_Matrix__c managerApprovalRecord = TestClassFactory.approvalMatrix1(oldUser.Id);     
        insert managerApprovalRecord;
        ApexPages.StandardController sc = new ApexPages.StandardController(refundRecord);
        ACR_SubmitProcess submitProcess = new ACR_SubmitProcess(sc);
        Test.StartTest();
        if(newUser != null){
            system.runAs(newUser){
                submitProcess.userId = newUser.Id;
                Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
                submitRequest.setComments('Comments');
                submitRequest.setObjectId(refundRecord.Id);
                submitRequest.setNextApproverIds(new Id[] {oldUser.Id});
                Approval.ProcessResult result = Approval.process(submitRequest); 
                submitProcess.initialiseApprovalRecord();
                apexpages.currentpage().getparameters().put('action' , 'Approve'); 
                submitProcess.validateActionParam();
                submitProcess.processUser();
                submitProcess.approveProcess();
                submitProcess.processUser();
                submitProcess.resetShowComments();
                System.assertEquals(True,Approval.isLocked(refundRecord.Id));
                System.assertEquals(True,submitProcess.showComments);
                System.assertEquals(True,submitProcess.isApprove);
                System.assertEquals(True,submitProcess.showUserHierarchy);
            }
        }
        Test.StopTest();     
    }
    
    /*
    * 	Rejecting approval Process
    */
    @isTest
    static void rejectTest(){  
        Account newAccount = TestClassFactory.newAccount();        
        Customer_Detail__c customerDetail = TestClassFactory.customerDetails(newAccount.Id);
        String profileName='\'System Administrator\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        Id profId=profileId[0].Id;
        User oldUser = TestClassFactory.userDetails1(profId);
        insert oldUser;
        User newUser = TestClassFactory.userDetails2(profId,oldUser.Id);
        insert newUser;
        Refund_Credit__c refundRecord = TestClassFactory.refundCredit2(customerDetail.Id,newUser);
        Approval_Matrix__c managerApprovalRecord = TestClassFactory.approvalMatrix(oldUser.Id);     
        insert managerApprovalRecord;
        Approval_Matrix__c approvalRecord = TestClassFactory.approvalMatrix1(newUser.Id);     
        insert approvalRecord;
        ApexPages.StandardController sc = new ApexPages.StandardController(refundRecord);
        ACR_SubmitProcess submitProcess = new ACR_SubmitProcess(sc);
        submitProcess.recordId=refundRecord.Id;
        submitProcess.validateActionParam();
        Test.StartTest();
        if(newUser != null){
            system.runAs(newUser){
                submitProcess.userId = newUser.Id;
                submitProcess.submitRecord();
                apexpages.currentpage().getparameters().put('action' , 'Reject'); 
                submitProcess.validateActionParam();
                submitProcess.processUser();
                submitProcess.rejectRecord();
                submitProcess.processUser();
                submitProcess.resetShowComments();
                System.assertEquals(True,Approval.isLocked(refundRecord.Id));
                System.assertEquals(True,submitProcess.showComments);
                System.assertEquals(True,submitProcess.isReject);
                System.assertEquals(True,submitProcess.showUserHierarchy);
            }
        }
        Test.StopTest();     
    }
    
    /*
    * 	Reassigning approval Process
    */
    @isTest
    static void reassignTest(){  
        Account newAccount = TestClassFactory.newAccount();        
        Customer_Detail__c customerDetail = TestClassFactory.customerDetails(newAccount.Id);
        String profileName='\'System Administrator\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        Id profId=profileId[0].Id;
        User oldUser = TestClassFactory.userDetails1(profId);
        insert oldUser;
        User newUser = TestClassFactory.userDetails2(profId,oldUser.Id);
        insert newUser;
        Approval_Matrix__c managerApprovalRecord = TestClassFactory.approvalMatrix(oldUser.Id);     
        insert managerApprovalRecord;
        Refund_Credit__c refundRecord = TestClassFactory.refundCredit2(customerDetail.Id,newUser);
        Approval_Matrix__c approvalRecord = TestClassFactory.approvalMatrix1(newUser.Id);     
        insert approvalRecord;
        ApexPages.StandardController sc = new ApexPages.StandardController(refundRecord);
        ACR_SubmitProcess submitProcess = new ACR_SubmitProcess(sc);
        Test.StartTest();
        if(newUser != null){
            system.runAs(newUser){
                submitProcess.userId = newUser.Id;
                Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
                submitRequest.setComments('Comments');
                submitRequest.setObjectId(refundRecord.Id);
                submitRequest.setNextApproverIds(new Id[] {oldUser.Id});
                Approval.ProcessResult result = Approval.process(submitRequest);
                submitProcess.initialiseApprovalRecord();
                apexpages.currentpage().getparameters().put('action' , 'Reassign'); 
                submitProcess.validateActionParam();
                submitProcess.processUser();
                submitProcess.reassignPage();
                submitProcess.processUser();
                submitProcess.resetShowComments();
                System.assertEquals(True,Approval.isLocked(refundRecord.Id));
                System.assertEquals(True,submitProcess.showComments);
                System.assertEquals(True,submitProcess.isReassign);
                System.assertEquals(True,submitProcess.showUserHierarchy);
            }
        }
        Test.StopTest();     
    }
    
    /*
    * 	Recalling approval Process
    */
    @isTest
    static void recallTest(){  
        Account newAccount = TestClassFactory.newAccount();        
        Customer_Detail__c customerDetail = TestClassFactory.customerDetails(newAccount.Id);
        String profileName='\'Standard User\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        Id profId=profileId[0].Id;
        User oldUser = TestClassFactory.userDetails1(profId);
        insert oldUser;
        User newUser = TestClassFactory.userDetails2(profId,oldUser.Id);
        insert newUser;
        Approval_Matrix__c managerApprovalRecord = TestClassFactory.approvalMatrix1(oldUser.Id);     
        insert managerApprovalRecord;
        Refund_Credit__c refundRecord = TestClassFactory.refundCredit2(customerDetail.Id,newUser);
        Approval_Matrix__c approvalRecord = TestClassFactory.approvalMatrix(newUser.Id);     
        insert approvalRecord;
        ApexPages.StandardController sc = new ApexPages.StandardController(refundRecord);
        ACR_SubmitProcess submitProcess = new ACR_SubmitProcess(sc);
        Test.StartTest();
        if(newUser != null){
            system.runAs(newUser){
                submitProcess.userId = newUser.Id;
                submitProcess.submitRecord();
                submitProcess.validateActionParam();
                submitProcess.processUser();
                submitProcess.recallApprovalProcess();
                submitProcess.processUser();
                submitProcess.initialiseApprovalRecord();
                submitProcess.resetShowComments();
                System.assertEquals(True,submitProcess.showComments);
                System.assertEquals(True,submitProcess.isRecall);
                System.assertEquals(False,submitProcess.showUserHierarchy);
            }
        }
        Test.StopTest();     
    }
}