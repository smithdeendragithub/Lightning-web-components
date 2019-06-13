@isTest
public class Test_CustomerHierarchyController {
    
    static testmethod void testgetCanLoadTree(){
        Test.startTest();
        Mocks Testdata = new Mocks();
        CustomerHierarchyController.TreeViewImplementation inst = new CustomerHierarchyController.TreeViewImplementation(Testdata.parentAccount.Id);
        List<Service_Location__c> sLocs = new List<Service_Location__c>();
        sLocs.add(new Service_Location__c(Account__c = Testdata.parentAccount.Id, Location__c = Testdata.loc.Id));
        insert sLocs;
        System.assertEquals(inst.getCanLoadTree(), true);
        
        for (Integer i = 0; i < 1000; ++i){
            sLocs.add(new Service_Location__c(Account__c = Testdata.parentAccount.Id, Location__c = Testdata.loc.Id));
        }
        upsert sLocs;
        System.assertEquals(inst.getCanLoadTree(), false);
        Test.stopTest();
    }    
    
    static testmethod void testGetIntegrationHierarchiesFromIDs1(){
        Test.startTest();
        Mocks Testdata = new Mocks();            
        Contact c = Testdata.parentAccountContact;
        Testdata.serviceLocation.Customer_Detail__c = Testdata.customerDetail.Id;
        update Testdata.serviceLocation;
        Testdata.parentAccount.Customer_Detail__c = new Customer_Detail__c().Id;
        update Testdata.parentAccount;
        
        CustomerHierarchyController.TreeViewImplementation inst = new CustomerHierarchyController.TreeViewImplementation(Testdata.parentAccount.Id);
        System.assertNotEquals(inst.getNodes(), new List<TreeNode>());
        System.assert(!inst.getNodes().isEmpty());
        
        Testdata.parentAccount.Customer_Detail__c = Testdata.customerDetail.Id;
        update Testdata.parentAccount;
        System.assertNotEquals(inst.getNodes(), new List<TreeNode>());
        System.assert(!inst.getNodes().isEmpty());
               
        Testdata.parentAccount.RecordTypeId = [Select Id from RecordType where Name = 'System' Limit 1].Id;
        update Testdata.parentAccount;
        System.assertEquals(inst.getNodes(), new List<TreeNode>());
        Test.stopTest();
    }
    
    static testmethod void testGetIntegrationHierarchiesFromIDs2(){
        Test.startTest();
        Mocks Testdata = new Mocks();            
        Testdata.parentAccountContact.Default_Responsible_Party__c = true;
        update Testdata.parentAccountContact;
        Testdata.serviceLocation.Customer_Detail__c = Testdata.customerDetail.Id;
        update Testdata.serviceLocation;
        Testdata.parentAccount.Customer_Detail__c = Testdata.customerDetail.Id;
        update Testdata.parentAccount;
        Customer_Contact__c cc = new Customer_Contact__c(Contact__c = Testdata.parentAccountContact.Id, Customer_Detail__c = Testdata.customerDetail.Id, Contact_Type__c = 'ISP');
        insert cc;
        Opportunity op = new Opportunity(Account = Testdata.parentAccount, Name = 'Test', StageName = 'Open', CloseDate = Date.today().addDays(5));
        insert op;
        Order__c order = new Order__c(Account__c = Testdata.parentAccount.Id, Opportunity__c = op.Id);
        insert order;
        Order_Property__c orderProp = new Order_Property__c(Order__c = order.Id, External_ID__c = '1234567');
        insert orderProp;
        Sub_Order__c subOrder = new Sub_Order__c(Order__c = order.Id, Customer_Detail__c = Testdata.customerDetail.Id, Service_Location__c = Testdata.serviceLocation.Id, External_Order__c = orderProp.Id);
        insert subOrder;
        Sub_Order_Group__c subOrderGroup = new Sub_Order_Group__c(Sub_Order__c = subOrder.Id, Quantity__c = 5, Product__c = 'Expensive Product');
        insert subOrderGroup;
        Service__c service = new Service__c(Customer_Detail__c = Testdata.customerDetail.Id, Product_Name__c = 'Prod Name');
        insert service;
        OpportunityContactRole OCR = new OpportunityContactRole(OpportunityId = op.Id, ContactId = Testdata.parentAccountContact.Id);
        insert OCR;
        
        CustomerHierarchyController.TreeViewImplementation inst = new CustomerHierarchyController.TreeViewImplementation(Testdata.parentAccount.Id);
        List<TreeNode> Result = inst.getNodes();
        System.assertNotEquals(result, new List<TreeNode>());
        System.assert(!result.isEmpty());
        Test.stopTest();
    }
    
    static testmethod void testgetContactNodes(){
        Test.startTest();
        Mocks Testdata = new Mocks();
        Customer_Contact__c cc = new Customer_Contact__c(Contact__c = Testdata.parentAccountContact.Id, Contact_Type__c = 'ISP', Customer_Detail__c = Testdata.customerDetail.Id);
        insert cc;
        
        CustomerHierarchyController.getContactNodes(new TreeNode(), new List<Customer_Contact__c>{cc});        
        Test.stopTest();
    }
    
    static testmethod void testgetMoreNodes(){
        Test.startTest();
        Mocks Testdata = new Mocks();
        CustomerHierarchyController.TreeViewImplementation inst = new CustomerHierarchyController.TreeViewImplementation(Testdata.parentAccount.Id);
        inst.getMoreNodes('String');
        Test.stopTest();
    }
    
    static testmethod void testgetActionMap(){
        Test.startTest();
        Mocks Testdata = new Mocks();
        CustomerHierarchyController.TreeViewImplementation inst = new CustomerHierarchyController.TreeViewImplementation(Testdata.parentAccount.Id);
        inst.getActionMap();
        Test.stopTest();
    }
    
    static testmethod void testgetIconMap(){
        Test.startTest();
        Mocks Testdata = new Mocks();
        CustomerHierarchyController.TreeViewImplementation inst = new CustomerHierarchyController.TreeViewImplementation(Testdata.parentAccount.Id);
        inst.getIconMap();
        Test.stopTest();
    }
}