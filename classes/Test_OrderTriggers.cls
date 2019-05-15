@isTest
public with sharing class Test_OrderTriggers {
    static testMethod void testEmails() {
        Mocks testData = new Mocks();
        
        Contact c = testData.parentAccountContact;
        Opportunity op = testData.opportunity;
        
        Test.startTest();
        
        //op.RecordTypeId = [select Id, DeveloperName FROM RECORDTYPE WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'new' limit 1].Id;
        //op.StageName = OpportunityUtils.STAGE_CONTRACT_NEGOTIATION;
        op.Type = 'New Logo';
        op.Term__c = '24';
        op.CloseDate = Date.today();
        op.Amount = 5000;
        op.Opportunity_Product__c = 'some stuff';
        update testData.opportunity;
        
        Order__c tO = testData.order;
        tO.Credit_Check_Approval__c = 'Credit Approved';
        tO.Credit_Commitment_Met__c = Date.today();
        tO.Opportunity__c = op.Id;
        update tO;
        
        tO.Credit_Check_Approval__c = 'Credit Denied';
        update tO;
        
        //op.StageName = OpportunityUtils.STAGE_CLOSED_WON;
        op.StageName = OpportunityUtils.STAGE_5;
        op.Contract_Signed_Date__c = Date.today();
        op.Initial_Appointment_Held_Date__c = Date.today();
        op.LOA_Signed_By__c = c.Id;
        op.Bypass_Validation__c = true;
        update op;
        
        tO.Credit_Check_Approval__c = 'Credit Approved pending condition';
        tO.Credit_Commitment_Met__c = null;
        tO.Credit_Hold_Reason__c = 'Credit Application Requested';
        List<User> us = [select Id from user where userrole.name = 'collections'];
        User u = null;
        if(us.size() > 0)
            u = us[0];
        tO.Credit_Check_Rep__c = u == null? null : u.Id;
        update tO;
        
        tO.Credit_Hold_Reason__c = 'Payment for past due on existing account required';
        update tO;
        
        tO.Credit_Hold_Reason__c = 'Payment on previous account required';
        update tO;
        
        tO.Credit_Hold_Reason__c = 'Deposit Requested';
        update tO;
        
        tO.Credit_Hold_Reason__c = 'Other';
        update tO;
        
        Test.stopTest();        
    }
    
    static testmethod void testhandleOwnershipChanges(){
        Mocks Testdata = new Mocks();
        
        Test.startTest();
        Testdata.user.FirstName = '';
        Testdata.user.LastName = 'Unassigned';
        update Testdata.user;
        
        Workstep__c ws = new Workstep__c(Order__c = Testdata.order.Id, OwnerId = Testdata.user.Id);
        insert ws;
        
        Testdata.order.OwnerId = Testdata.user.Id;
        update Testdata.order;
        Test.stopTest();
    }
    
    static testmethod void testevaluateOrder(){
        Mocks Testdata = new Mocks();
        
        Test.startTest();
        Workstep_Library__c wsl1 = new Workstep_Library__c(Start_Date_Driving_Fields__c = 'Order.Order_Completion_Status__c', Anti_Workstep__c = true);
        insert wsl1;
        Workstep_Library__c wsl2 = new Workstep_Library__c(Start_Date_Driving_Fields__c = 'Order.StartDate');
        insert wsl2;
        
        Workstep__c ws = new Workstep__c(Order__c = Testdata.order.Id, OwnerId = Testdata.user.Id, Status__c = 'Blocked', Workstep_Library__c = wsl1.Id, Duration__c = 1);
        insert ws;
        
        Workstep_Issue__c wsi = new Workstep_Issue__c(Workstep__c = ws.Id);
        insert wsi;
        
        Testdata.order.Order_Completion_Status__c = 'Cancelled';
        Testdata.order.recordTypeId = OrderUtils.DecommOrderRecordTypeID;
        Testdata.order.Building__c = Testdata.building.Id;
        Testdata.order.Cancel_Reason_Code__c = 'Customer cancelled request for services';
        update Testdata.order;
        Test.stopTest();
    }
    
    static testmethod void testsendWorkflowAndApprovalEmails(){
        Mocks Testdata = new Mocks();
        
        Sub_Order__c so = Testdata.suborder;
        
        Testdata.opportunity.StageName = 'Stage 4 - Contract Signed / Won';
        Testdata.opportunity.Type = 'New Logo';
        Testdata.opportunity.Contract_Signed_Date__c = Date.today();
        Testdata.opportunity.Opportunity_Product__c = 'Basic Voice';
        Testdata.opportunity.Proposal_Meeting_Held_Date__c = Date.today();
        Testdata.opportunity.LOA_Signed_By__c = Testdata.parentAccountContact.Id;
        Testdata.user.ManagerId = UserInfo.getUserId();
        update Testdata.user;
        Testdata.opportunity.OwnerId = Testdata.user.Id;
        update Testdata.opportunity;
        
        Test.startTest();
        Testdata.order.Record_Status__c = 'Cancelled';
        Testdata.order.Credit_Check_Approval__c = 'Credit Approved pending condition';
        Testdata.order.Credit_Hold_Reason__c = 'Credit Application Requested';
        update Testdata.order;
        Testdata.order.Credit_Hold_Reason__c = 'Payment for past due on existing account required';
        Testdata.order.Expedited__c = true;
        update Testdata.order;   
        Testdata.order.Credit_Hold_Reason__c = 'Payment on previous account required';
        update Testdata.order;
        Testdata.order.Credit_Hold_Reason__c = 'Deposit Requested';
        update Testdata.order;
        Test.stopTest();
    }
    
    static testmethod void testsendWorkflowAndApprovalEmails2(){
        Mocks Testdata = new Mocks();
        
        Sub_Order__c so = Testdata.suborder;
        
        Testdata.opportunity.StageName = 'Stage 4 - Contract Signed / Won';
        Testdata.opportunity.Type = 'New Logo';
        Testdata.opportunity.Contract_Signed_Date__c = Date.today();
        Testdata.opportunity.Opportunity_Product__c = 'Basic Voice';
        Testdata.opportunity.Proposal_Meeting_Held_Date__c = Date.today();
        Testdata.opportunity.LOA_Signed_By__c = Testdata.parentAccountContact.Id;
        Testdata.user.ManagerId = UserInfo.getUserId();
        update Testdata.user;
        Testdata.opportunity.OwnerId = Testdata.user.Id;
        update Testdata.opportunity;
        
        Test.startTest();
        Testdata.order.Credit_Check_Rep__c = Testdata.user.Id;
        Testdata.order.Record_Status__c = 'Cancelled';
        Testdata.order.Credit_Check_Approval__c = 'Credit Approved pending condition';
        Testdata.order.Credit_Hold_Reason__c = 'Credit Application Requested';
        update Testdata.order;
        Testdata.order.Credit_Hold_Reason__c = 'Other';
        update Testdata.order;
        Testdata.order.Credit_Check_Approval__c = 'Credit Denied';
        Testdata.order.Credit_Commitment_Met__c = Datetime.now();
        update Testdata.order;
        Testdata.order.Credit_Check_Approval__c = 'Credit Approved';
        Testdata.order.Credit_Commitment_Met__c = Datetime.now();
        update Testdata.order;
        Test.stopTest();
    }
    
    static testmethod void testcheckForCLLI(){
        Mocks Testdata = new Mocks();
        
        Test.startTest();
        
        Workstep__c ws = new Workstep__c(Order__c = Testdata.order.Id, OwnerId = Testdata.user.Id, Status__c = 'Blocked', Duration__c = 1);
        insert ws;
        
        Order__c ord = new Order__c();
        ord.Opportunity__c = Testdata.opportunity.Id;
        ord.RecordTypeId = OrderUtils.BuildOrderRecordTypeID;
        ord.Building__c = Testdata.building.Id;
        ord.Features__c = 'Obtain CLLI Code';
        insert ord;
        delete ord;
    }
    
    static testmethod void testHandleContractRenewalOrderType(){
        Mocks Testdata = new Mocks();
        
        Test.startTest();
        Id ctrRewRtID = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Contract Renewal').getRecordTypeId();
        SPC_Product__c spc = new SPC_Product__c(
            SalesProductExternalID__c = -1
            ,Provisioning_Product__c = testData.mpProvProd.get('Standard').Id
        );
        insert spc;

        Order__c ord = new Order__c();
        ord.Account__c = Testdata.parentAccount.Id;
        ord.RecordTypeId = ctrRewRtID;
        ord.Original_Contract_MRC__c = 100.00;
        ord.Old_Contract_End_Date__c = Date.Today();
        ord.SPC_Product__c = spc.Id;
        ord.New_Contract_MRC__c =    200.00;
        ord.New_Contract_End_Date__c = Date.today();
        ord.New_Contract_Start_Date__c = Date.today();
        ord.Contract_Status__c = 'Renewal';
       
        insert ord;
        
    }

    static testmethod void testHandleContractRenewalOrderTypeUpdateNewContractInfo(){
        Mocks Testdata = new Mocks();
        
        Test.startTest();
        Id ctrRewRtID = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Contract Renewal').getRecordTypeId();
        SPC_Product__c spc = new SPC_Product__c(
            SalesProductExternalID__c = -1
            ,Provisioning_Product__c = testData.mpProvProd.get('Standard').Id
        );
        insert spc;

        Order__c ord = new Order__c();
        ord.Account__c = Testdata.parentAccount.Id;
        ord.RecordTypeId = ctrRewRtID;
        ord.Original_Contract_MRC__c = 100.00;
        ord.Old_Contract_End_Date__c = Date.Today();
        ord.SPC_Product__c = spc.Id;
        ord.Contract_Status__c = 'Renewal';
        insert ord;
        
        ord.New_Contract_MRC__c =    200.00;
        ord.New_Contract_End_Date__c = Date.today();
        ord.New_Contract_Start_Date__c = Date.today();       
        
        update ord;
        
        
    }
    
}