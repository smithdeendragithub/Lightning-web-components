@isTest
public with sharing class Test_SubOrder_PDD extends TestUtils.TestClass{
	static testMethod void testSchedule_PDD_TrueUp(){
        Mocks testData = new Mocks();
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
    									,Has_Blocked_Workstep__c = true
    									,Workplan_Start_Date__c = Date.today().addDays(-23) 
    									);  									
    	insert so;
    	
    	Sub_Order__c soOne = new Sub_Order__c(
    									Service_Location__c = testData.serviceLocation.Id
    									,Order__c = ord.Id
    									,SPC_Product__c = spc.Id
    									,Has_Blocked_Workstep__c = false
    									,Workplan_Start_Date__c = Date.today().addDays(-7) 
    									);     									 									
    	insert soOne;
 	    	Sub_Order__c soTwo = new Sub_Order__c(
    									Service_Location__c = testData.serviceLocation.Id
    									,Order__c = ord.Id
    									,SPC_Product__c = spc.Id
    									,Has_Blocked_Workstep__c = true
    									,Workplan_Start_Date__c = Date.today().addDays(13) 
    									);      																		
    	insert soTwo;
		
		Workstep_Library__c wsl = new Workstep_Library__c(
															Name = 'PDD TrueUp Test'
															,External_Id__c = -1
															);																
		insert wsl;
		
		Workstep_Template__c wst = new Workstep_Template__c(
															Name = 'WST PDD TrueUp test'
															,External_Id__c = -1
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
										, Status__c = 'Open'
										,CTP_Attribute__c = 'End'
										));
		
		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = so.Id
										,Template__c = wst.Id
										,Workstep_Library__c = wsl.Id
										,Name = 'Send to Billing'
										, Status__c = 'Blocked'
										));
		
		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = so.Id
		));
		
		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = soOne.Id
										,Template__c = wst.Id
										,Workstep_Library__c = wsl.Id
										, Status__c = 'Integrating'
										,CTP_Attribute__c = 'Start'
										));

		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = soOne.Id
										,Template__c = wst.Id
										,Workstep_Library__c = wsl.Id
										, Status__c = 'Open'
										,CTP_Attribute__c = 'Start'
										));
    	
		
		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = soOne.Id
										,Template__c = wst.Id
										,Workstep_Library__c = wsl.Id
										,Name = 'Activate with Customer'
										, Status__c = 'Open'
										,CTP_Attribute__c = 'End'
										));
		
		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = soOne.Id
										,Template__c = wst.Id
										,Workstep_Library__c = wsl.Id
										,Name = 'Send to Billing'
										, Status__c = 'Blocked'
										));
		
		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = soOne.Id
		));
		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = soTwo.Id
										,Template__c = wst.Id
										,Workstep_Library__c = wsl.Id
										, Status__c = 'Integrating'
										,CTP_Attribute__c = 'Start'
										));

		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = soTwo.Id
										,Template__c = wst.Id
										,Workstep_Library__c = wsl.Id
										, Status__c = 'Open'
										,CTP_Attribute__c = 'Start'
										));
    	
		
		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = soTwo.Id
										,Template__c = wst.Id
										,Workstep_Library__c = wsl.Id
										,Name = 'Activate with Customer'
										, Status__c = 'Open'
										,CTP_Attribute__c = 'End'
										));
		
		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = soTwo.Id
										,Template__c = wst.Id
										,Workstep_Library__c = wsl.Id
										,Name = 'Send to Billing'
										, Status__c = 'Blocked'
										));
		
		ws.add(new Workstep__c(
										Order__c = ord.Id
										,Sub_Order__c = soTwo.Id
		));
					
		insert ws;

				
		test.startTest();		
		Schedule_PDD_TrueUp.getActiveSubOrders(soTwo.Id);		
		test.stopTest();
	}
}