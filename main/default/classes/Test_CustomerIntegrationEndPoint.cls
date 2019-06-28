@isTest
public with sharing class Test_CustomerIntegrationEndPoint extends TestUtils.TestClass {

    static testMethod void testIntegrateAccounts(){
     	Integer accountsProcessed = CustomerIntegrationEndPoint.integrateAccounts(1, false);
    }
    
    static testMethod void testIntegrateServiceLocation(){
       	Integer Processed = CustomerIntegrationEndPoint.integrateServiceLocation(false, true);
    }
    
    static testMethod void testIntegrateAccountServiceLocations(){
        Integer Processed = CustomerIntegrationEndPoint.integrateAccountServiceLocations('a270h000001Q7Ct', true);
    }
}