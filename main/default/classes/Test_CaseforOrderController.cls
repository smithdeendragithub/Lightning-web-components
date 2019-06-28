@isTest
public with sharing class Test_CaseforOrderController{
    
    static testmethod void testCreateOrder(){
        Mocks testData = new Mocks();
        
        Account a = testData.parentAccount;
        Id caseToOrderRt = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Case_To_Order_Support').getRecordTypeId();
        Id queueId = [Select Id, Name, DeveloperName from Group where Type =  'Queue' and developerName = 'Voice_Orders'].Id;
        Case ca = new Case(AccountId = a.Id
                        ,Status = 'New'
                        ,Origin = 'Email'
                        ,Subject = 'Test Case'
                        ,recordTypeId = caseToOrderRt
                        , OwnerId= queueId); 
        insert ca;
        
        PageReference pageRef = Page.CreateOrderFromCase;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('caseId', ca.Id);
        
        Test.startTest();
        CaseforOrderController controller = new CaseforOrderController();
        controller.createOrder();        
        
        Test.stopTest();

    }
}