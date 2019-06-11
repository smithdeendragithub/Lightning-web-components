@isTest
public class Test_CapitalProjectController extends TestUtils.TestClass{
	static testMethod void testController() {
		Mocks testData = new Mocks();
				
		
		Capital_Project__c cproj = new Capital_Project__c();
		cproj.Opportunity__c = testData.Opportunity.Id;
		Account a = testData.parentAccount;
		Opportunity_Location__c oloc = testData.location;
		List<OpportunityLocationConfiguration__c> configs = testData.lstconfig;
		Building__c bldg = testData.building;
		Location__c loc = testData.loc;
		Service_Location__c sloc = testData.serviceLocation;
		cproj.Auto_Generate__c = false;
		cproj.Request_Title__c = 'title';
		cproj.Description__c = 'description';
		cproj.Requested_Due_Date__c = Date.today();
        cproj.RecordTypeID = Schema.SObjectType.Capital_Project__c.getRecordTypeInfosByName().get('Customer Build').getRecordTypeID();
		insert cproj;
		
		Capital_Project_Building__c cbldg = new Capital_Project_Building__c();
		cbldg.Building__c = bldg.Id;
		cbldg.Capital_Project__c = cproj.Id;
		insert cbldg;
		
		PageReference pr = Page.CapitalProject;
				
		Test.startTest();
		
		CapitalProjectController con = new CapitalProjectController(new ApexPages.StandardController(cproj));
		boolean t = con.HaveOppBuildings;
		boolean t2 = con.haveActBuildings;
		con.iCerts = new List<ICertUtils.SFICertView>();
		con.RoutingSteps = new List<ICertUtils.SFRoutingStepView>();
		
		CapitalProjectController.BuildingSelectionElement bse = new CapitalProjectController.BuildingSelectionElement(testData.Building);

		con.capBldgId = cbldg.Id;
		con.DeleteCapitalProjectBuilding_Click();
		
		con.selBldgs = string.valueOf(bldg.Id);
		con.AddBuildings_Click();
		
		con.selSLocId = sloc.Location__r.Id;
		con.AddCapitalProjectBuilding_Click();
        
       
		
		con.CreateICert_Click();
		
		cproj.iCERT_ID__c = '2';
		update cproj;
		con.GetICert();
		con.GetRoutingSteps_Click();
		
		
		
		Test.stopTest();
		
		
	}

	static testMethod void testAutogen(){
		Mocks testData = new Mocks();
				
		
		Capital_Project__c cproj = new Capital_Project__c();
		cproj.Opportunity__c = testData.Opportunity.Id;
		Account a = testData.parentAccount;
		Opportunity_Location__c oloc = testData.location;
		List<OpportunityLocationConfiguration__c> configs = testData.lstconfig;
		Building__c bldg = testData.building;
		Location__c loc = testData.loc;
		Service_Location__c sloc = testData.serviceLocation;
		cproj.Auto_Generate__c = false;
		cproj.Request_Title__c = 'title';
		cproj.Description__c = 'description';
		cproj.Requested_Due_Date__c = Date.today();
		insert cproj;
		
		Capital_Project_Building__c cbldg = new Capital_Project_Building__c();
		cbldg.Building__c = bldg.Id;
		cbldg.Capital_Project__c = cproj.Id;
		insert cbldg;
		
		Test.startTest();
		
		cproj.Auto_Generate__c = true;
		
		update cproj;
		
		
		
		Test.stopTest();
		
	}
	
	static testMethod void testFailure(){
		Mocks testData = new Mocks();
		
		Capital_Project__c cp = new Capital_Project__c();
		cp.iCERT_ID__c = '1234';
		insert cp;
		
		Id rtID = [select Id from RecordType where sObjectType = 'Order_Property__c' and DeveloperName='ICert'].Id;
		Order_Property__c op = new Order_Property__c();
		op.Type__c = 'iCert';
		op.Order__c = testData.order.Id;
		op.External_ID__c = 'zebra';
		op.Service_Location__c = testData.location.Service_Location__c;
		op.RecordTypeId = rtID;
		insert op;
				
		PageReference pr = Page.CapitalProject;
		CapitalProjectController con = new CapitalProjectController(new ApexPages.StandardController(cp));
		con.GoToCreateCapitalProjectBuilding();
		Test.setCurrentPage(pr);
		
		Test.startTest();
		
		con.CreateICert_Click();
		
		cp.Opportunity__c = testData.opportunity.Id;
		
		con.CreateICert_Click();
		
		Test.stopTest();
	}
    
   
  static testMethod void testController2() {
		Mocks testData = new Mocks();
				
		
		Capital_Project__c cproj = new Capital_Project__c();
		cproj.Opportunity__c = testData.Opportunity.Id;
		Account a = testData.parentAccount;
		Opportunity_Location__c oloc = testData.location;
		List<OpportunityLocationConfiguration__c> configs = testData.lstconfig;
		Building__c bldg = testData.building;
		Location__c loc = testData.loc;
		Service_Location__c sloc = testData.serviceLocation;
		cproj.Auto_Generate__c = false;
		cproj.Request_Title__c = 'title';
		cproj.Description__c = 'description';
		cproj.Requested_Due_Date__c = Date.today();
		insert cproj;
		
		Capital_Project_Building__c cbldg = new Capital_Project_Building__c();
		cbldg.Building__c = bldg.Id;
		cbldg.Capital_Project__c = cproj.Id;
		insert cbldg;
		
		PageReference pr = Page.CapitalProject;
				
		Test.startTest();
		
		CapitalProjectController con = new CapitalProjectController(new ApexPages.StandardController(cproj));
		boolean t = con.HaveOppBuildings;
		boolean t2 = con.haveActBuildings;
		con.iCerts = new List<ICertUtils.SFICertView>();
		con.RoutingSteps = new List<ICertUtils.SFRoutingStepView>();
		
		CapitalProjectController.BuildingSelectionElement bse = new CapitalProjectController.BuildingSelectionElement(testData.Building);

     	 string accMeth= bse.AccessMethod;
      	string NetStat= bse.NetStatus;
      	Decimal Maxbw =bse.MaxBandwidth;
      Decimal minRev= bse.MinimumRevenue;
      Decimal hurd =bse.Hurdle;
      

		con.capBldgId = cbldg.Id;
		con.DeleteCapitalProjectBuilding_Click();
		
		con.selBldgs = string.valueOf(bldg.Id);
		con.AddBuildings_Click();
		
		//con.selSLocId = sloc.Location__r.Id;
		con.selSLocId = loc.Id;
		con.AddCapitalProjectBuilding_Click();
      
		con.CreateICert_Click();
		
		cproj.iCERT_ID__c = '2';
		update cproj;
		con.GetICert();
		con.GetRoutingSteps_Click();
		
		
		
		Test.stopTest();
		
		
	}
    
    static testMethod void testController3() {
		Mocks testData = new Mocks();
				
		
		Capital_Project__c cproj = new Capital_Project__c();
		cproj.Opportunity__c = testData.Opportunity.Id;
		Account a = testData.parentAccount;
		Opportunity_Location__c oloc = testData.location;
		List<OpportunityLocationConfiguration__c> configs = testData.lstconfig;
		Building__c bldg = testData.building;
		Location__c loc = testData.loc;
		Service_Location__c sloc = testData.serviceLocation;
		cproj.Auto_Generate__c = false;
		cproj.Request_Title__c = 'title';
		cproj.Description__c = 'description';
		cproj.Requested_Due_Date__c = Date.today();
        cproj.RecordTypeID = Schema.SObjectType.Capital_Project__c.getRecordTypeInfosByName().get('Network Build').getRecordTypeID();
		insert cproj;
		
		Capital_Project_Building__c cbldg = new Capital_Project_Building__c();
		cbldg.Building__c = bldg.Id;
		cbldg.Capital_Project__c = cproj.Id;
		insert cbldg;
		
		PageReference pr = Page.CapitalProject;
				
		Test.startTest();
		
		CapitalProjectController con = new CapitalProjectController(new ApexPages.StandardController(cproj));
		boolean t = con.HaveOppBuildings;
		boolean t2 = con.haveActBuildings;
		con.iCerts = new List<ICertUtils.SFICertView>();
		con.RoutingSteps = new List<ICertUtils.SFRoutingStepView>();
        Access_Technology__c ATech = new Access_Technology__c(Access_Technology_ID__c = 12);
        insert ATech;
		Building_Access_Availability__c ddd= new Building_Access_Availability__c(Access_Technology__c = ATech.Id, Building__c = testdata.building.Id);
        insert ddd;
        System.debug(testData.building.Access_Availabilities__r);
		CapitalProjectController.BuildingSelectionElement bse = new CapitalProjectController.BuildingSelectionElement(testData.Building);
        
        

		con.capBldgId = cbldg.Id;
		con.DeleteCapitalProjectBuilding_Click();
		
		con.selBldgs = string.valueOf(bldg.Id);
		con.AddBuildings_Click();
		
		con.selSLocId = sloc.Location__r.Id;
		con.AddCapitalProjectBuilding_Click();
        
       
		
		con.CreateICert_Click();
		
		cproj.iCERT_ID__c = '2';
		update cproj;
		con.GetICert();
		con.GetRoutingSteps_Click();
		
		
		
		Test.stopTest();
		
		
	}
    
    	
    
    
}