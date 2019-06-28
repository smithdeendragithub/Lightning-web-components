/***********************************************************************************************************
* Name       : ACR_ApprovalMatrixTriggerHelperTest
* Purpose    : Test class for ACR_ApprovalMatrixTriggerHelper
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Sathya                  | 1.0        | 24/03/2019      | Initial version
***********************************************************************************************************/

@isTest
public class ACR_ApprovalMatrixTriggerHelperTest {
    @isTest
    static void attachmentErrorSysAdminTest(){
        //Fetching Profile Id
        String profileName='\'System Administrator\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        Id profId=profileId[0].Id;
        //Inserting Users
        Integer totalUsers=10;
        List<User> newUser = TestClassFactory.userDetails(profId,totalUsers);
        insert newUser; 
        Test.StartTest();
        for(User user: newUser){
            System.runAs(user){
                //Inserting a record in Approval Matrix
                Approval_Matrix__c approvalMat = TestClassFactory.approvalMatrix(user.id); 
                insert approvalMat;
                ContentVersion contentFiles = TestClassFactory.contentFile();    
                insert contentFiles;         
                String contentId='\''+contentFiles.Id+'\'' ;
                ACR_DomainLayer.QueryEditor contentVer = new ACR_DomainLayer.QueryEditor('ContentDocument','','SELECT','Id, Title, LatestPublishedVersionId ');
                List<ContentDocument> ContentDoc=(List<ContentDocument>) contentVer.ResultSet; 
                ContentDocumentLink contentDocs = TestClassFactory.contentDoc(approvalMat.Id,ContentDoc[0].Id);
                insert contentDocs;
                
                //Updating a field in Approval Matrix
                approvalMat.iCert_Max__c = 26;
                try{
                    update approvalMat; 
                    System.assertEquals(41,approvalMat.Credit_Approval_Limit__c);
                    System.assertEquals(23,approvalMat.Refund_Approval_Limit__c);
                    System.assertEquals(26,approvalMat.iCert_Max__c);
                }
                Catch(exception error){
                    System.Assert(error.getMessage().contains('Please add the attachment!'),error.getMessage());
                }
            }    
        }
        Test.StopTest();
    }
    @isTest   
    static void attachmentErrorStandardUserTest(){
        //Fetching Profile Id
        String profileName='\'Standard User\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        Id profId=profileId[0].Id;
        //Inserting Users
        Integer totalUsers=10;
        List<User> newUser = TestClassFactory.userDetails(profId,totalUsers);
        insert newUser; 
        Test.StartTest();
        for(User user: newUser){
            System.runAs(user){
                //Inserting a record in Approval Matrix
                Approval_Matrix__c approvalMat = TestClassFactory.approvalMatrix(user.id); 
                insert approvalMat;
                //Updating a field in Approval Matrix
                approvalMat.iCert_Max__c = 26;
                try{
                    update approvalMat;
                    System.assertEquals(41,approvalMat.Credit_Approval_Limit__c);
                    System.assertEquals(23,approvalMat.Refund_Approval_Limit__c);
                    System.assertEquals(26,approvalMat.iCert_Max__c);
                }
                Catch(exception error){
                    System.Assert(error.getMessage().contains('Please add the attachment'),error.getMessage());
                } 
            }    
        }
        Test.StopTest();
    }
}