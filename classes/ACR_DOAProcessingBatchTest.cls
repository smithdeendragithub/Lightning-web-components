/***********************************************************************************************************
* Name       : ACR_DOAProcessingBatchTest
* Purpose    : Test class for ACR_DOAProcessingBatch
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Sathya                  | 1.0        | 27/03/2019      | Initial version
***********************************************************************************************************/
@isTest
public class ACR_DOAProcessingBatchTest {
    @testSetup
    static void dataSetup(){
        
    }
    @isTest
    static void titleNotFoundScenarioTest(){ 
        //Fetching Profile Id
        String profileName='\'System Administrator\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        Id profId=profileId[0].Id;
        //Inserting User
        Integer totalUsers=5;
        List<User> newUser = TestClassFactory.userDetails(profId,totalUsers);
        insert newUser; 
        //Creating DOA record
        DOA_Mapping__c createDOA= TestClassFactory.newDOA();    
        insert createDOA;
        Integer i=0;
        Test.startTest();
        for(User user:newUser)
        {
            System.runAs(user){ 
                ACR_DOAProcessingBatch batchJob = new ACR_DOAProcessingBatch();
                DataBase.executeBatch(batchJob);
                String currentUser=(String)user.Id;
                ACR_DomainLayer.QueryEditor userDetail = new ACR_DomainLayer.QueryEditor('USER','WHERE Id= \''+currentUser+'\'','SELECT','Id,Name,Title ');
                List<User> insertedUser=(List<User>) userDetail.ResultSet; 
                System.assertEquals('Perficient11'+i,insertedUser[0].Title);
                //System.assertEquals(False,insertedUser.Excludes_From_Batch_Processing__c);
                //System.assertEquals(True,insertedUser.Ready_For_DOA_Processing__c);
                System.assertEquals(False,user.Title_Not_Found_in_DOA__c);
                i++;
            }
        }
        Test.StopTest();
    }
    @isTest
    static void approvalMatrixUpdateTest(){
        //Fetching Profile Id
        String profileName='\'System Administrator\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        Id profId=profileId[0].Id;
        //Inserting Users
        Integer totalUsers=5;
        List<User> newUser = TestClassFactory.userDetails(profId,totalUsers);
        insert newUser;
        //Creating DOA record
        DOA_Mapping__c createDOA2 = TestClassFactory.newDOA1();    
        insert createDOA2;
        Integer i=0;
        Test.startTest();
        for(User user: newUser){
            System.runAs(user){    
                ACR_DOAProcessingBatch batchJob = new ACR_DOAProcessingBatch();
                //DataBase.executeBatch(batchJob);
                batchJob.start(null);
                batchJob.execute(null,newUser);
                String currentUser=(String)user.Id;
                ACR_DomainLayer.QueryEditor userDetail = new ACR_DomainLayer.QueryEditor('USER','WHERE Id= \''+currentUser+'\'','SELECT','Id,Name,Title ');
                List<User> insertedUser=(List<User>) userDetail.ResultSet; 
                System.assertEquals('Perficient11'+i,insertedUser[0].Title);
                //System.assertEquals(False,insertedUser.Excludes_From_Batch_Processing__c);
                //System.assertEquals(True,insertedUser.Ready_For_DOA_Processing__c);
                System.assertEquals(True,user.Title_Not_Found_in_DOA__c);
                i++;
            }
        }
        Test.StopTest();
    }

    @isTest
    static void scheduleClassTest(){
        Test.startTest();
            ACR_SchedulerClass sh1 = new ACR_SchedulerClass();
            String sch = '0 0 23 * * ?'; system.schedule('HR Integration Test', sch, sh1); 
            sh1.execute(null); 
        Test.stopTest(); 
    }

    @isTest
    static void scheduleClassTest1(){
        Test.startTest();
            ACR_SchedulerClass.scheduleBatch();
        Test.stopTest(); 
    }
}