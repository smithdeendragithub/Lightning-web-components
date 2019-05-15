/***********************************************************************************************************
* Name       : ACR_Items_To_Approve_Test
* Purpose    : Test class for ACR_Items_To_Approve
************************************************************************************************************
* Author                 | Version    | Created Date        | Description
************************************************************************************************************
* Rahul Sekar            | 1.0        | April 30, 2019      | Initial version
************************************************************************************************************/

@isTest
public class ACR_Items_To_Approve_Test {
    /*
     * Tesing a single record
     */
    @isTest
    private static void singleRecord(){
        String profileName='\'System Administrator\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        User us = TestClassFactory.userDetails1(profileId[0].id);
        insert us;
        list<Id> idlist = new list<Id>();
        idlist.add(us.id);
        Account ac = TestClassFactory.newAccount();
        Customer_Detail__c custDet = TestClassFactory.customerDetails(ac.id);
        Refund_Credit__c rc = TestClassFactory.refundCredit2(custDet.id,us);
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(rc.Id);
        app.setComments('Test comment');
        app.setNextApproverIds(new Id[] {Userinfo.getUserId()});
        Approval.ProcessResult result = Approval.Process(app);    
        ApexPages.StandardController std = new ApexPages.StandardController(rc);        
        Test.startTest();
        System.runAs(us){
            ACR_Items_To_Approve itemsToApprove = new ACR_Items_To_Approve(std);
            Double userTime = itemsToApprove.offset;
            itemsToApprove.redirectToStandardAppPage();
            itemsToApprove.redirectToReasStandardPage();
            itemsToApprove.redirectToPage();
            itemsToApprove.requiredrecords();
            itemsToApprove.next();
            itemsToApprove.start=7;
            itemsToApprove.previous();      
            System.assertEquals(1, itemsToApprove.count);
        }
        Test.stopTest();        
    }   
    /*
     *  Testing Multiple Records
	 */
    @isTest
    private static void multipleRecord(){
        String profileName='\'System Administrator\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        User us = TestClassFactory.userDetails1(profileId[0].id);
        insert us;
        list<Id> idlist = new list<Id>();
        idlist.add(us.id);
        Account ac = TestClassFactory.newAccount();
        Customer_Detail__c custDet = TestClassFactory.customerDetails(ac.id);
        list<Refund_Credit__c> rcList = TestClassFactory.refundCredit3(custDet.id,us,10);
        for(integer i=0;i<10;i++)
        {
            Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
            app.setObjectId(rcList[i].Id);
            app.setComments('Test comment');
            app.setNextApproverIds(new Id[] {Userinfo.getUserId()});
            Approval.ProcessResult result = Approval.Process(app); 
        }
        ApexPages.StandardController std = new ApexPages.StandardController(rcList[0]);        
        Test.startTest();
        System.runAs(us){
            ACR_Items_To_Approve itemsToApprove = new ACR_Items_To_Approve(std);
            itemsToApprove.redirectToStandardAppPage();
            itemsToApprove.redirectToReasStandardPage();
            itemsToApprove.redirectToPage();
            itemsToApprove.requiredrecords();
            itemsToApprove.next();
            itemsToApprove.previous();     
            System.assertEquals(10, itemsToApprove.count);
        }
        Test.stopTest();               
    }   
}