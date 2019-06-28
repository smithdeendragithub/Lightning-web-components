@isTest
public with sharing class Test_NewWorkstep {
	static testMethod void testController(){
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
															External_Id__c = -1
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
test.startTest();
		PageReference pageReference = Page.NewWorkstep;
		pageReference.getParameters().put('id', so.Id);
		pageReference.getParameters().put('oid', ord.Id);
		test.setCurrentPage(pageReference);
		
		NewWorkstep nws = new NewWorkstep();
		
		nws.Save();
		nws.Cancel();
		nws.getAllWorkstepsMap();
		nws.getWorkstepLibrary();
		nws.addWorksteps();
		nws.removeWorksteps();
		test.stopTest();
	}

}