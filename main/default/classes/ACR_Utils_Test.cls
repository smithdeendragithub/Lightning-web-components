/***********************************************************************************************************
* Name       : ACR_Utils_Test
* Purpose    : Test class for ACR_Utils
************************************************************************************************************
* Author                 | Version    | Created Date    | Description
************************************************************************************************************
* Rahul Sekar            | 1.0        | April 30, 2019      | Initial version
***********************************************************************************************************/

@isTest
public class ACR_Utils_Test {
    /*
     * 	Conditions not satisfied Approve button access function returns false
     */
    @isTest
    private static void runAsUser(){
        Account ac = TestClassFactory.newAccount();
        Customer_Detail__c custDet = TestClassFactory.customerDetails(ac.id);       
        Refund_Credit__c rc = TestClassFactory.refundCredit(custDet.id);
        Test.startTest();        
            Boolean br = ACR_Utils.determineApproveButtonAccess(rc.id, ACR_ConstantDeclarations.RECORD_TYPE_REFUND , '');
            System.assertEquals(false, br);
        Test.stopTest();
    }
    /*
     *  Conditions satisfied Approve button access function returns true
     */
    @isTest
    private static void runAsSysAdmin(){
        String profileName='\'System Administrator\'';
        ACR_DomainLayer.QueryEditor prof = new ACR_DomainLayer.QueryEditor('Profile','WHERE Name='+profileName,'SELECT','Id ');
        List<Profile> profileId=(List<Profile>) prof.ResultSet; 
        User us = TestClassFactory.userDetails1(profileId[0].id);
        insert us;
        Account ac = TestClassFactory.newAccount();
        Customer_Detail__c custDet = TestClassFactory.customerDetails(ac.id);
        Refund_Credit__c rc = TestClassFactory.refundCredit1(custDet.id,us);
        Test.startTest();
        System.runAs(us){
            Boolean br = ACR_Utils.determineApproveButtonAccess(rc.id, ACR_ConstantDeclarations.RECORD_TYPE_REFUND , '');
            System.assertEquals(true, br);
        }
        Test.stopTest();
    }
}