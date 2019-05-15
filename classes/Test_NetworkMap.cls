@isTest
public with sharing class Test_NetworkMap extends TestUtils.TestClass {

    static testMethod void testController() {
		NetworkMap nm = new NetworkMap();
		nm.latitude = 45.5000;
		nm.longitude = -120.000;
		nm.distRange = 1;
		nm.displayAllIlec = false;
		nm.myNearNet = false;
		nm.myOnNet = false;
		nm.displayIlec = true;
		nm.nearNetHigh = false;
		nm.nearNetMed = false;
		nm.nearNetLow = false;
		nm.nearNetUnPrior = false;
		nm.leadRoomSuite = '';
		nm.selectedMaxBAA = 30;
		nm.selectedMinBAA = 5;
		nm.maxBAA = 30;
		nm.MinBAA = 0;
		nm.maxMRREoF = 800;
		nm.minMRREoF = 10;
		nm.selectedMaxMRREoF = 800;
		nm.selectedMinMRREoF = 0;
		string userSalesChannel = nm.UserSalesChannel;
		List<SelectOption> opts = nm.gbFilterListViews;
		List<SelectOption> opts2 = nm.leadFilterListViews;
		List<SelectOption> opts3 = nm.accountFilterListViews;
		NetworkMap.rt_map = new map<Id, Schema.RecordTypeInfo>();
		NetworkMap.BuildOrderData bod = new NetworkMap.BuildOrderData(new Order__c());
		NetworkMap.CapitalProjectData cpd = new NetworkMap.CapitalProjectData(new Capital_Project_Building__c());

		boolean test1 = nm.isDebugProfile;
		string s = nm.wireCenterBuildings;
		nm.GatherBuildingData();
		
		NetworkMap.getTimeZone();
		NetworkMap.WireCenter wc = new NetworkMap.WireCenter('test',new List<building__c>());
		NetworkMap.AcctData ad = new NetworkMap.AcctData(new Account(),true);
		NetworkMap.GRBusData gr = new NetworkMap.GRBusData(new GeoResults_Business__c(CreatedDate = Datetime.now()),1,false);
		NetworkMap.BuildingData bd = new NetworkMap.BuildingData(new Building__c(),new Set<GeoResults_Business__c>(),new Set<Building_Access_Availability__c>(), new Set<Account>(),new Set<Id>(),new Map<String,Integer>(),new Map<Id,GeoResults_Business__c>());
		
		
		
		
		nm.leadstatus = 'test';
		nm.leadsource = 'test';
		nm.leadFirstName = 'Solaire';
		nm.leadLastName = 'of Astora';
		nm.leadGRID = gr.id;
		nm.leadPhone = '5555555555';
		nm.leadCompany = 'Sunlight Knights';
		nm.CreateLead();
		
		nm.oppAccountID = new Account().Id;
		nm.oppAcctName = 'Unending Awesomeness';
		nm.CreateOpportunity();
		
    }
}