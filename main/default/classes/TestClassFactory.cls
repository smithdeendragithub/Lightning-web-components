/***********************************************************************************************************
* Name       : TestClassFactory
* Purpose    : This class will act as a reference class for all test class
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Sathya                 | 1.0       | 25/03/2019      | Initial version
***********************************************************************************************************/

@isTest
public class TestClassFactory {
    public static List<User> userDetails(Id userProfile, Integer totalUser) {
        List<User> result = new List<User>();
        for(Integer i=0;i<totalUser;i++)
        {
            User user=new User();
            user.Alias = 'ydhfta'; 
            user.Email=i+'testingAll@pertitesnt.com';
            user.EmailEncodingKey='UTF-8';
            user.LastName='test30'+i;
            user.LanguageLocaleKey='en_US'; 
            user.LocaleSidKey='en_US'; 
            user.ProfileId = userProfile; 
            user.Title='Perficient11'+i;
            user.TimeZoneSidKey='America/Los_Angeles';
            user.UserName='test30@testperficient.com'+i;
            user.IsActive = true;
            user.Excludes_From_Batch_Processing__c=False;
            user.Ready_For_DOA_Processing__c=True;
            result.add(user);
        }
        return result;
    } 
    public static User userDetails1(Id userProfile) {
        User result = new User(Alias = 'ydhfta',Email='testing123@pertitesnt.com',EmailEncodingKey='UTF-8',LastName='testing123',
                               LanguageLocaleKey='en_US',LocaleSidKey='en_US',ProfileId = userProfile,Title='TitleNotMatched',
                               TimeZoneSidKey='America/Los_Angeles',UserName='test123@testperficient.com');
        return result;
    }
    public static User userDetails2(Id userProfile, Id managerId) {
        User result = new User(Alias = 'ydhfta',Email='testing321@pertitesnt.com',EmailEncodingKey='UTF-8',LastName='testing321',
                               LanguageLocaleKey='en_US',LocaleSidKey='en_US',ProfileId = userProfile,Title='TitleNotMatched',
                               TimeZoneSidKey='America/Los_Angeles',UserName='test321@testperficient.com',ManagerId=managerId);
        return result;
    }
    public static Approval_Matrix__c approvalMatrix(Id newUser) {
        Approval_Matrix__c result=new Approval_Matrix__c(
            Credit_Approval_Limit__c = 2000,
            Refund_Approval_Limit__c = 2000,
            iCert_Max__c = 2000,
            User_ID__c = newUser);
        return result;
    }
    public static Approval_Matrix__c approvalMatrix1(Id newUser) {
        Approval_Matrix__c result=new Approval_Matrix__c(
            Credit_Approval_Limit__c = 20000,
            Refund_Approval_Limit__c = 20000,
            iCert_Max__c = 20000,
            User_ID__c = newUser);
        return result;
    }
    public static ContentVersion contentFile() {
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');
        ContentVersion result=new ContentVersion(
            title = 'test content trigger',      
            PathOnClient ='test',           
            VersionData =beforeblob);
        return result;
    }
    public static ContentDocumentLink contentDoc(Id approvalMat, Id ContentDocId) {
        ContentDocumentLink result=new ContentDocumentLink(
            LinkedEntityId=approvalMat,
            ShareType= 'I',
            ContentDocumentId=ContentDocId,
            Visibility = 'AllUsers');
        return result;
    }
    public static DOA_Mapping__c newDOA() {
        DOA_Mapping__c result=new DOA_Mapping__c(
            Job_Title__c='Perficient110',
            General_Limit__c=39,
            Credits_Refunds_Limit__c=39,
            CapEx_Limit__c=39);
        return result;
    }
    public static DOA_Mapping__c newDOA1() {
        DOA_Mapping__c result=new DOA_Mapping__c(
            Job_Title__c='NotMatched',
            General_Limit__c=39,
            Credits_Refunds_Limit__c=39,
            CapEx_Limit__c=39);
        return result;
    }
    public static Account newAccount() {
        Account acc = new Account(Name='Testing1',Phone='9999999999',Industry='Automotive');
        insert acc;
        return acc;
    }
    public static Customer_Detail__c customerDetails(Id newAccount) {
        Customer_Detail__c customerDet = new Customer_Detail__c(Name='Testing2',Parent_Account__c=newAccount);
        insert customerDet;
        return customerDet;
    }
    public static Refund_Credit__c refundCredit(Id customerId){
        Refund_Credit__c refundRecord = new Refund_Credit__c(Customer_Detail__c=customerId,Amount__c=1000,Current_Step__c=1);
        insert refundRecord;
        return refundRecord;  
    }
    public static Refund_Credit__c refundCredit1(Id customerId, user nextApprover){
        Refund_Credit__c refundRecord = new Refund_Credit__c(Customer_Detail__c=customerId,Current_Step__c=1,Amount__c=1000,Next_Approver__c=nextApprover.id);
        insert refundRecord;
        return refundRecord;  
    }
    public static Refund_Credit__c refundCredit2(Id customerId, user nextApprover ){
        Refund_Credit__c refundRecord =new Refund_Credit__c(Customer_Detail__c=customerId ,Amount__c=4000.00,Next_Approver__c=nextApprover.id,Current_Step__c=1, RecordTypeId=Schema.SObjectType.Refund_Credit__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId());
        insert refundRecord;
        return refundRecord;  
    }
    public static list<Refund_Credit__c> refundCredit3(Id customerId, user nextApprover, integer count ){
        list<Refund_Credit__c> refList = new list<Refund_Credit__c>();
        for(integer i=0;i<count;i++)
        {
            Refund_Credit__c refundRecord =new Refund_Credit__c(Customer_Detail__c=customerId ,Amount__c=4000.00,Next_Approver__c=nextApprover.id,Current_Step__c=1, RecordTypeId=Schema.SObjectType.Refund_Credit__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId());
            refList.add(refundRecord);
        }
        
        insert refList;
        return refList;  
    }
    public static Refund_Credit__c refundCredit4(Id customerId, user nextApprover ){
        Refund_Credit__c refundRecord =new Refund_Credit__c(Customer_Detail__c=customerId ,Amount__c=4000.00,Next_Approver__c=nextApprover.id,Current_Step__c=1, RecordTypeId=Schema.SObjectType.Refund_Credit__c.getRecordTypeInfosByName().get('Credit').getRecordTypeId());
        insert refundRecord;
        return refundRecord;  
    }
    
}