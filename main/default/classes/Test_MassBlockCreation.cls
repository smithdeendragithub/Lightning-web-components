@isTest 
public with sharing class Test_MassBlockCreation extends TestUtils.TestClass {
    private static Opportunity opp;
    private static Order__c ord;
    private static Order_Property__c oProp;
    private static SPC_Product__c spc;
    private static Provisioning_Product__c provProd;
    private static Sub_Order__c so;
    private static Sub_Order_Group__c sog;
    private static Workplan_Template__c wpt;
    private static Workstep_Library__c wsl;
    private static Workstep_Template__c wst;
    private static Workstep_Issue__c wsi;
    private static Workstep__c ws;
    private static Workstep__c dws;
    private static Predecessor__c pred;
    static testMethod void testController(){
        
        Mocks testData = new Mocks();
        
        opp = testData.opportunity;
        ord = new Order__c(Opportunity__c = opp.Id);
        insert ord;
        
        oProp = new Order_Property__c(
            External_ID__c = '-1'
            ,Order__c = ord.Id
            ,Order_Actions__c = 'Move Address'
            ,Type__c = 'Install Order'
        );
        insert oProp;
        
        provProd = testData.mpProvProd.get('Standard');
        
        spc = new SPC_Product__c(
            SalesProductExternalID__c = -1
            ,Provisioning_Product__c = provProd.Id
        );
        insert spc;
        
        so = new Sub_Order__c(
            Service_Location__c = testData.serviceLocation.Id
            ,Order__c = ord.Id
            ,External_Order__c = oProp.Id
            ,Provisioning_Product__c = provProd.Id
            ,SPC_Product__c = spc.Id
            ,Activate_with_Customer_Date__c = Date.today()
            ,Workplan_Start_Date__c = Date.today()
        );
        insert so;
        
        sog = new Sub_Order_Group__c(
            Sub_Order__c = so.Id
            ,Quantity__c = 10
            ,Product__c = 'The Pickles'
            ,External_ID__c = '1'
        );
        insert sog;
        
        wpt = new Workplan_Template__c(
            Active__c = true
            ,External_ID__c = -1
            ,Provisioning_Product__c = testData.mpProvProd.get('Standard').Id
        );
        insert wpt;
        
        wsl = new Workstep_Library__c(
            External_Id__c = -1
        );
        insert wsl;
        
        wst = new Workstep_Template__c(
            External_Id__c = -1
            ,Workstep_Library__c = wsl.Id
            ,Workplan_Template__c = wpt.Id
        );
        insert wst;
        
        ws = new Workstep__c(
            Order__c = ord.Id
            ,Sub_Order__c = so.Id
            ,Status__c = 'Open'
            ,Template__c = wst.Id
            ,Workstep_Library__c = wsl.Id
            ,Start_Date__c = Date.today()
            ,Duration__c = 1
            ,Lag__c = 0
        );
        insert ws;
        
        dws = new Workstep__c(
            Order__c = ord.Id
            ,Sub_Order__c = so.Id
            ,Status__c = 'Open'
            ,Attribute__c = 'Activate with Customer'
        );
        insert dws;
        
        pred = new Predecessor__c(
            Predecessor_Workstep__c = ws.Id
            , Dependent_Workstep__c = dws.Id
        );
        insert pred;
        
        test.startTest();
        
        PageReference pageReference = Page.MassBlockCreation;      
        pageReference.getParameters().put('id', ord.Id);    
        test.setCurrentPage(pageReference);
        
        MassBlockCreation mu = new MassBlockCreation();
        system.assert(mu.wsWrapperList.size() != 0);
        mu.Save();
        mu.QuickSave();
        mu.Cancel();
  
        test.stopTest();
    }
    
    static testmethod void testcontroller2(){
       Mocks testData = new Mocks();
        
        opp = testData.opportunity;
        ord = new Order__c(Opportunity__c = opp.Id);
        insert ord;
        
        oProp = new Order_Property__c(
            External_ID__c = '-1'
            ,Order__c = ord.Id
            ,Order_Actions__c = 'Move Address'
            ,Type__c = 'Install Order'
        );
        insert oProp;
        
        provProd = testData.mpProvProd.get('Standard');
        
        spc = new SPC_Product__c(
            SalesProductExternalID__c = -1
            ,Provisioning_Product__c = provProd.Id
        );
        insert spc;
        
        so = new Sub_Order__c(
            Service_Location__c = testData.serviceLocation.Id
            ,Order__c = ord.Id
            ,External_Order__c = oProp.Id
            ,Provisioning_Product__c = provProd.Id
            ,SPC_Product__c = spc.Id
            ,Activate_with_Customer_Date__c = Date.today()
            ,Workplan_Start_Date__c = Date.today()
        );
        insert so;
        
        wpt = new Workplan_Template__c(
            Active__c = true
            ,External_ID__c = -1
            ,Provisioning_Product__c = testData.mpProvProd.get('Standard').Id
        );
        insert wpt;
        
        wsl = new Workstep_Library__c(
            External_Id__c = -1
        );
        insert wsl;
        
        wst = new Workstep_Template__c(
            External_Id__c = -1
            ,Workstep_Library__c = wsl.Id
            ,Workplan_Template__c = wpt.Id
        );
        insert wst;
        
        ws = new Workstep__c(
            Order__c = ord.Id
            ,Sub_Order__c = so.Id
            ,Status__c = 'Open'
            ,Template__c = wst.Id
            ,Workstep_Library__c = wsl.Id
            ,Start_Date__c = Date.today()
            ,Duration__c = 1
            ,Lag__c = 0
        );
        insert ws;
        
        wsi = new Workstep_Issue__c(
        	Risk_Type__c = 'Customer'
            ,Comments__c = 'Comments Here'
            ,Expected_Follow_Up_Date__c = Datetime.now().addDays(5)
            ,OwnerId = testData.user.Id
        );
        insert wsi;
       
        Test.startTest();
        
        ApexPages.currentPage().getParameters().put('id', ord.Id);
        MassBlockCreation mu = new MassBlockCreation();
        mu.wsWrapperList[0].isSelected = true;
        mu.dummyWSI = wsi;
        System.AssertEquals(mu.SaveAction(ApexPages.CurrentPage()), ApexPages.currentPage());
        mu.sortColumn = 'Id';
        mu.sortResults();
        mu.sortResults();
        mu.ExitSave();
        mu.getTestClass();
    }
}