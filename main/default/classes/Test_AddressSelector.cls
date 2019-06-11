@isTest
public with sharing class Test_AddressSelector extends TestUtils.TestClass{
 	
	static testMethod void testController() {
    	Mocks testData = new Mocks();
    	
    	Building__c b = testData.building;
    	b.LSO_CLLI__c = 'PTLDOR12';
    	b.Building_Type__c = 'ILEC LSO: Collocated';
		b.Building_Hash__c = 'testclassbuildinghash';
    	update b;
    	
		Access_Technology__c atech = new Access_Technology__c();
		atech.Access_Technology_ID__c = 123;
		atech.Name = 'EoF';
		insert atech;
		
		Building_access_availability__c baa = new Building_Access_Availability__c();
		baa.Access_Technology__c = atech.id;
		baa.Minimum_Required_Revenue__c = 0;
		baa.Maximum_Bandwidth__c = 800;
		baa.Building__c = b.id;
		insert baa;
		
    	//Create
    	Account a = new Account();
    	a.Name = 'Test Class Account';
		a.Billable__c = true;
    	a.Phone = '1234567890';
    	a.ShippingStreet = '1234 Test';
    	a.ShippingCity = 'Portland';
        //MNK Added Aug 2017
        a.ShippingCountryCode = 'US';
    	a.ShippingState = 'OR';
    	a.ShippingPostalCode = '97232';
    	insert a;
      	
        PageReference pageReference = Page.CreateBuildingUsingGoogleAddress;
        Test.setCurrentPage(pageReference);
		pageReference.getParameters().put('Id', a.Id);
		
		AddressSelectorController ascr = new AddressSelectorController();
		boolean canmanuallycreatebuilding = ascr.canManuallyCreateBuilding;
		ascr.readOnlyMode = false;
		ascr.accountID = a.Id;
		ascr.buildingID = b.Id;
		ascr.billable = false;
		
		AddressParser ap = new AddressParser();
		pageReference.getParameters().put('streetNumber', '1201');
		pageReference.getParameters().put('street', 'NE LLOYD BLVD');
		pageReference.getParameters().put('city', 'Portland');
        //MNK Added Aug 2017
        pageReference.getParameters().put('country', 'US');
		pageReference.getParameters().put('state', 'OR');
		pageReference.getParameters().put('postalCode', '97232');

		ascr.SearchBuildings();
		ascr.CreateLocOnExistingBuild();
		
		//error on no lat/lng
		ascr.ValidateBuildingAddress();
		
		pageReference.getParameters().put('latitude', '45.5296809');
		pageReference.getParameters().put('longitude', '-122.6532694');
		ascr.ValidateBuildingAddress();
		
		failLocView = true;
		ascr.ValidateBuildingAddress();
		
    }
    
	public static Boolean failLocView = false;
	
	public static integraWS.SFLocationView  SetupLocationTestData(integraWS.SFLocationView locView){
	 	locView.Success = true; 
        locView.BuildingHash = failLocView ? null : 'testclassbuildinghash';
        locView.LSOCLLI = 'PTLDOR12';
		integraws.ArrayOfLocationAccessAndBandwithResults al = new integraws.ArrayOfLocationAccessAndBandwithResults();
		al.LocationAccessAndBandwithResults = new List<integraWS.LocationAccessAndBandwithResults>();
		integraWS.LocationAccessAndBandwithResults v = new integraWS.LocationAccessAndBandwithResults();
		v.AvailiableBandwidth = 20000;
		v.AccessTechnologyID = 1;
		al.LocationAccessAndBandwithResults.add(v);
		locView.AccessAndBandwidthResults = al;
	
		return locView;
	}
    	
}