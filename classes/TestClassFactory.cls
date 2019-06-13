/***********************************************************************************************************
* Name       : TestClassFactory
* Purpose    : This class will act as a reference class for all test class
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Sathya                  | 1.0        | 25/03/2019      | Initial version
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
        User result = new User(Alias = 'ydhfta',Email='testingAll@pertitesnt.com',EmailEncodingKey='UTF-8',LastName='testing33',
                               LanguageLocaleKey='en_US',LocaleSidKey='en_US',ProfileId = userProfile,Title='TitleNotMatched',
                               TimeZoneSidKey='America/Los_Angeles',UserName='test30@testperficient.com');
        return result;
       }
    public static Approval_Matrix__c approvalMatrix(Id newUser) {
        
        Approval_Matrix__c result=new Approval_Matrix__c(
            Credit_Approval_Limit__c = 41,
            Refund_Approval_Limit__c = 23,
            iCert_Max__c = 23,
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
}