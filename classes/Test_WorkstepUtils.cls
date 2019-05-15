@isTest
public with sharing class Test_WorkstepUtils {
	
	static testMethod void testUtils() {
		populateTestData(true);
		
		WorkstepUtils.canExpedite(ws);
    }
	
	static testMethod void testOrderCreateWorksteps() {
		populateTestData(false);
		
		Id rtID = [select Id from RecordType where sObjectType = 'Workplan_Template__c' and DeveloperName = 'Order' limit 1].Id;
		wpt.RecordTypeId = rtID;
		update wpt;
		
		List<Order__c> orders = new List<Order__c>();
		orders.add(ord);
		WorkstepUtils.createWorksteps(orders);
    }
    
	static testMethod void testOrderCreateWorkstepsForBuildOrder() {
		populateTestData(false);
		
		Id rtID = [select Id from RecordType where sObjectType = 'Workplan_Template__c' and DeveloperName = 'Order' limit 1].Id;
		wpt.RecordTypeId = rtID;
        wpt.Name = 'Standard Build';
		update wpt;
		
		List<Order__c> orders = new List<Order__c>();
		Id rtBuildOrderID = [select Id from RecordType where sObjectType = 'Order__c' and DeveloperName = 'Build_Order' limit 1].Id;
		ord.RecordTypeId = rtBuildOrderID;
        
		orders.add(ord);
		WorkstepUtils.createWorksteps(orders);
    }    
	
   static testMethod void createOrderWorkstepForContractSigned() {
		populateTestData(true);
		
		Set<Id> oppIds = new Set<Id>();
		oppIds.add(opp.Id);
		WorkstepUtils.createOrderWorkstepForContractSigned(oppIds);
    }
    
	static testMethod void testSubOrderCreateWorksteps() {
		populateTestData(false);
		
		Map<Id, Sub_Order__c> suborders = new Map<Id, Sub_Order__c>();
		suborders.put(so.Id, so);
		WorkstepUtils.createWorksteps(suborders);
    }
	
	static testMethod void testUpdateWorkstepSuccessors() {
		populateTestData(true);
		
		WorkstepUtils.updateWorkstepSuccessors(new Set<Id>{ws.Id});
    }
	
	static testMethod void testPredecessorChain() {
		populateTestData(true);
		
		WorkstepUtils.PredecessorChain pc = WorkstepUtils.getPredecessorChain(new Set<Id>{ws.Id});
		pc.GetWorkstepLevel(1);
    }
	
	static testMethod void testDateCalculations() {
		WorkstepUtils.calculateFirstDate(Date.today(),1,true);
		WorkstepUtils.calculateAfterDate(Date.today(),1,true);
		WorkstepUtils.calculateSuccessorDates(Date.today(),1,1);
    }
	
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
	private static Workstep__c ws;
	private static Workstep__c dws;
	private static Predecessor__c pred;
	private static void populateTestData(Boolean createWorksteps){
		
        Mocks testData = new Mocks();
		
    	opp = testData.opportunity;
    	ord = new Order__c(Opportunity__c = opp.Id);
        ord.TOV_Needed__c = true;
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
                                    ,name = 'Technical Order Validation'
									);
		insert wst;
		
		if(createWorksteps){
	    	ws = new Workstep__c(
								Order__c = ord.Id
								,Sub_Order__c = so.Id
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
								,Attribute__c = 'Activate with Customer'
								);
			insert dws;
			
			pred = new Predecessor__c(
									Predecessor_Workstep__c = ws.Id
									, Dependent_Workstep__c = dws.Id
									);
			insert pred;
		}
		
    	Test.startTest();
	}
}