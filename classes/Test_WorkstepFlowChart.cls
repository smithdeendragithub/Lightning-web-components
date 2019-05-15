@isTest
public with sharing class Test_WorkstepFlowChart extends TestUtils.TestClass {
    private static Order__c ord;
    private static Provisioning_Product__c provProd;
    private static Sub_Order__c so;
    private static Order_Property__c oProp;
    private static SPC_Product__c spc;
    private static Workplan_Template__c wpt;
    private static Workstep_Library__c wsl;
    private static Workstep_Template__c wst;
    private static Workstep__c ws;
    private static Workstep__c dws;
    private static Predecessor__c pred;
    
    static testMethod void testController(){
        Mocks testData = new Mocks();
        ord = testData.order;
        
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
            
            dws = new Workstep__c(
                                Order__c = ord.Id
                                ,Sub_Order__c = so.Id
                                ,Status__c = 'Blocked'
                                ,Attribute__c = 'Activate with Customer'
                                );
            insert dws;

        test.startTest();
        
        PageReference pageReference = Page.WorkstepFlowChart;
        pageReference.getParameters().put('id', ord.Id);

        test.setCurrentPage(pageReference);
        
        WorkstepFlowChartController fc = new WorkstepFlowChartController();
        system.assert(fc.wsCount != 0);
        
        test.stopTest();
    }
}