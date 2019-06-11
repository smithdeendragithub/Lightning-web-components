@isTest
public with sharing class Test_SubOrderTriggers {
    
    static testMethod void testTriggers() {
        Mocks testData = new Mocks();
        Test.startTest();
        
        Opportunity opp = testData.opportunity;
        Order__c ord = new Order__c(Opportunity__c = opp.Id);
        insert ord;
        
        SPC_Product__c spc = new SPC_Product__c(
            SalesProductExternalID__c = -1
            ,Provisioning_Product__c = testData.mpProvProd.get('Standard').Id
        );
        insert spc;
        
        Sub_Order__c so = new Sub_Order__c(
            Service_Location__c = testData.serviceLocation.Id
            ,Order__c = ord.Id
            ,SPC_Product__c = spc.Id
            ,Workplan_Start_Date__c = Date.today()
            ,Provisioning_Product__c = testData.mpProvProd.get('Standard').Id
        );
        insert so;
        
        Feature__c f = new Feature__c(
            External_ID__c = -1
        );
        insert f;
        
        Feature_Duration__c fd = new Feature_Duration__c(
            External_ID__c = -1
            ,Feature__c = f.Id
        );
        insert fd;
        
        Sub_Order_Feature__c sof = new Sub_Order_Feature__c(
            Sub_Order__c = so.Id
            ,Feature__c = f.Id
        );
        insert sof;
        
        Sub_Order_Group__c sog = new Sub_Order_Group__c(
            Sub_Order__c = so.Id
            ,Quantity__c = 10
            ,Product__c = 'The Pickles'
        );
        insert sog;
        
        Workstep__c ws = new Workstep__c (Status__c = 'Open', Order__c = ord.Id, Sub_Order__c = so.Id);		
        insert ws;		
        
        so.Provisioning_Product__c = testData.mpProvProd.get('BO').Id;		
        update so;
        
        test.stopTest();
    }
    
    static testmethod void testhandleProvisioningProductUpdates(){
        Mocks Testdata = new Mocks();
        Test.startTest();
        
        Provisioning_Product__c pp = new Provisioning_Product__c();
        insert pp;
        
        Workstep__c ws = new Workstep__c(Status__c = 'Complete', Order__c = Testdata.order.Id, Sub_Order__c = Testdata.suborder.Id);
        insert ws;
        
        try{
            Testdata.suborder.Provisioning_Product__c = pp.Id;
            update Testdata.suborder;
        }
        catch (Exception e){
            System.assert(e.getMessage().contains('The provisioning product cannot be changed because the current workstep process has been started'));
        }
        Test.stopTest();        
    }
    
    static testmethod void testevaluateSubOrder(){
        Mocks Testdata = new Mocks();
        Test.startTest();  
        
        Workstep_Library__c wsl = new Workstep_Library__c(
            Start_Date_Driving_Fields__c = 'Sub_Order__c.Install_Date__c',
            Anti_Workstep__c = true
        );
        insert wsl;
        
        Access_Types__c aT = new Access_Types__c(Access_Type_ID__c = 1, Access_Technology__c = Testdata.accessTec.Id);
        insert aT;
        
        Workstep__c ws = new Workstep__c(Status__c = 'Blocked', Order__c = Testdata.order.Id, Sub_Order__c = Testdata.suborder.Id, Workstep_Library__c = wsl.Id);
        insert ws;
        
        Workstep_Issue__c wsi = new Workstep_Issue__c(Workstep__c = ws.Id);
        insert wsi;
        
        Testdata.suborder.Install_Date__c = Datetime.Now().addDays(7);
        Testdata.suborder.Status__c = 'Cancelled';
        Testdata.suborder.Access_Types__c = aT.Id;
        update Testdata.suborder;
        
        Test.stopTest();
    }    
}