@isTest
public with sharing class Test_WorkstepTriggers {
    
    static testMethod void testTriggers() {
        Mocks testData = new Mocks();
        test.startTest();
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
            ,Install_Date__c  = Date.today()
        );
        insert so;
        
        Sub_Order_Group__c sog = new Sub_Order_Group__c(
            Sub_Order__c = so.Id
            ,Quantity__c = 10
            ,Product__c = 'The Pickles'
            ,External_ID__c = '1'
        );
        insert sog;
        
        Workstep_Library__c wsl = new Workstep_Library__c(
            External_Id__c = -1
            ,Complete_Date_Field__c ='Sub_Order__c.Install_Date__c'
        );
        
        insert wsl;
        
        Workstep_Template__c wst = new Workstep_Template__c(
            External_Id__c = -1
            ,Workstep_Library__c = wsl.Id
        );
        insert wst;
        
        List<Workstep__c> ws = new List<Workstep__c>();
        ws.add(new Workstep__c(
            Order__c = ord.Id
            ,Sub_Order__c = so.Id
            ,Template__c = wst.Id
            ,Workstep_Library__c = wsl.Id
            , Status__c = 'Integrating'
            ,CTP_Attribute__c = 'Start'
        ));
        
        ws.add(new Workstep__c(
            Order__c = ord.Id
            ,Sub_Order__c = so.Id
            ,Template__c = wst.Id
            ,Workstep_Library__c = wsl.Id
            , Status__c = 'Open'
            ,CTP_Attribute__c = 'Start'
        ));
        
        
        ws.add(new Workstep__c(
            Order__c = ord.Id
            ,Sub_Order__c = so.Id
            ,Template__c = wst.Id
            ,Workstep_Library__c = wsl.Id
            ,Name = 'Activate with Customer'
            , Status__c = 'Complete'
            ,CTP_Attribute__c = 'End'
        ));
        
        wsl.Complete_Date_Field__c = '999';
        update wsl;
        ws.add(new Workstep__c(
            Order__c = ord.Id
            ,Sub_Order__c = so.Id
            ,Template__c = wst.Id
            ,Workstep_Library__c = wsl.Id
            ,Name = 'Activate with Customer'
            , Status__c = 'Cancelled'
            ,CTP_Attribute__c = 'End'
        ));
        
        ws.add(new Workstep__c(
            Order__c = ord.Id
            ,Sub_Order__c = so.Id
        ));
        
        insert ws;
        
        Predecessor__c pred = new Predecessor__c(
            Predecessor_Workstep__c = ws[0].Id
            , Dependent_Workstep__c = ws[3].Id
        );
        insert pred;
        
        Workstep__c up1 = ws[0];		        
        up1.Status__c ='Blocked';		
        update up1;		
        
        //Workstep_Issue__c wi = new Workstep_Issue__c( Workstep__c = ws[0].ID		
        //                                                    );		
        //insert wi;		
        Workstep__c up2 = ws[0];		
        up2.Status__c ='Cancelled';		
        update up2;
        
        Test.stopTest();
    }
    
    static testmethod void testTriggers2(){
        Mocks Testdata = new Mocks();
        
        Order__c ord = Testdata.order;
        Order__c ord2 = new Order__c(RecordTypeId = OrderUtils.BuildOrderRecordTypeID, Opportunity__c = Testdata.opportunity.Id, Building__c = Testdata.building.Id);
        insert ord2;
        
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
        );
        insert so;
        
        Sub_Order_Group__c sog = new Sub_Order_Group__c(
            Sub_Order__c = so.Id
            ,Quantity__c = 10
            ,Product__c = 'The Pickles'
            ,External_ID__c = '1'
        );
        insert sog;
        
        Workstep_Library__c wsl = new Workstep_Library__c(
            External_Id__c = -1,
            Complete_Date_Field__c = '999',
            Start_Date_Driving_Fields__c = '999',
            Start_Date_Driven_Duration__c = 1
        );
        
        insert wsl;
        
        Workstep_Template__c wst = new Workstep_Template__c(
            External_Id__c = -1
            ,Workstep_Library__c = wsl.Id
        );
        insert wst;
        
        Test.startTest();
        List<Workstep__c> ws = new List<Workstep__c>();
        ws.add(new Workstep__c(
            Order__c = ord.Id
            ,Sub_Order__c = so.Id
            ,Template__c = wst.Id
            ,Workstep_Library__c = wsl.Id
            ,Status__c = 'Blocked'
            ,CTP_Attribute__c = 'Start'
        ));
        
        ws.add(new Workstep__c(
            Order__c = ord.Id
            ,Sub_Order__c = so.Id
            ,Template__c = wst.Id
            ,Workstep_Library__c = wsl.Id
            ,Name = 'Activate with Customer'
            , Status__c = 'Blocked'
            ,CTP_Attribute__c = 'End'
        ));
        ws.add(new Workstep__c(
            Order__c = ord2.Id
            ,Template__c = wst.Id
            ,Workstep_Library__c = wsl.Id
            ,Name = 'Activate with Customer'
            , Status__c = 'Complete'
            ,CTP_Attribute__c = 'End'
        ));
        insert ws;
        
        Workstep_Issue__c wsi = new Workstep_Issue__c(Workstep__c = ws[1].Id);
        insert wsi;
        
        ws[0].Status__c = 'Open';
        ws[1].Status__c = 'Cancelled';
        
        update ws;
        delete ws;
    }
    
    static testmethod void testWorkstepCalloutResult(){
        Mocks Testdata = new Mocks();
        Test.startTest();
        Workstep_Library__c wsl = new Workstep_Library__c(
            External_Id__c = -1,
            Complete_Date_Field__c = '999',
            Start_Date_Driving_Fields__c = '999',
            Start_Date_Driven_Duration__c = 1
        );
        insert wsl;
        Workstep__c ws = new Workstep__c(
            Order__c = Testdata.order.Id
            ,Workstep_Library__c = wsl.Id
            ,Status__c = 'Open'
        );
        insert ws;
        
        WorkstepTriggers.WorkstepCalloutResult inst = new WorkstepTriggers.WorkstepCalloutResult(ws);
        integraWS.SFSubOrderGroupStatusView inst2 = new integraWS.SFSubOrderGroupStatusView();
        inst2.ResultMessage = 'Test Message';
        inst2.ResultStatus = 'Fail';
        inst.AddResult(inst2);
        String holder = inst.FailureMessage;
        holder = inst.FailureEmailBody;
        holder = inst.FailureEmailSubject;
        System.assert(!inst.IsSuccessful);
    }
}