@isTest
public with sharing class Test_CreateBuildingUsingGoogleAddress extends TestUtils.TestClass {
	
  /*  static testMethod void testController() {
    	Mocks testData = new Mocks();
    	
    	Building__c b = testData.building;
    	b.LSO_CLLI__c = 'PTLDOR12';
    	b.Building_Type__c = 'ILEC LSO: Collocated';
		b.Building_Hash__c = 'testclassbuildinghash';
    	update b;
    	
    	//Create
    	Account a = new Account();
    	a.Name = 'Test Class Account';
		a.Billable__c = true;
    	a.Phone = '1234567890';
    	a.ShippingStreet = '1234 Test';
    	a.ShippingCity = 'Portland';
    	a.ShippingState = 'OR';
    	a.ShippingPostalCode = '97232';
    	insert a;
      	
        PageReference pageReference = Page.CreateBuildingUsingGoogleAddress;
        Test.setCurrentPage(pageReference);
		pageReference.getParameters().put('Id', a.Id);
		
        CreateBuildingUsingGoogleAddress ga = new CreateBuildingUsingGoogleAddress();
        ga.manualCreate = false;
        ga.billable = true;
		
        
        ga.streetNumber = '1201';
        ga.street = 'Northeast Lloyd Boulevard';
        ga.suite = '555';
        ga.city = 'Portland';
        ga.postalCode = '97232';
        ga.latitude = '45.529734';
        ga.longitude = '-122.65319499999998';
        ga.state = 'OR';
        ga.phone = '';
        ga.overrideName = '';
		
		integraWS.SFLocationView loc = ga.CreateSFLocationView();
		
		integraWS.SFLocationView loc2 = CreateBuildingUsingGoogleAddress.CreateSFLocationViewFromParams(45.529734,-122.65319499999998,ga.streetNumber,ga.street,ga.suite,ga.city,ga.state,ga.postalCode);
		ga.GetBandwidthValue(3000);
		ga.GetBandwidthValue(5000);
		ga.GetBandwidthValue(10000);
		ga.GetBandwidthValue(15000);
		ga.GetBandwidthValue(20000);
		ga.GetBandwidthValue(25000);
		ga.GetBandwidthValue(30000);
		ga.GetBandwidthValue(40000);
		ga.GetBandwidthValue(45000);
		ga.GetBandwidthValue(50000);
		ga.GetBandwidthValue(60000);
        ga.ValidateBuildingAddress();
        
        //List<Building__c> buildings = [Select Id From Building__c Where Building_Hash__c = :loc.BuildingHash limit 1];
		//if(!buildings.isempty())
			//ga.CreateLocation(buildings[0],loc); 
			
		ga.suite = '555-2';
		loc.subpremise = '555-2';
		//ga.createLocation(buildings[0],loc);	
		integraws.ArrayOfLocationAccessAndBandwithResults baas = new integraws.ArrayOfLocationAccessAndBandwithResults();
		baas.LocationAccessAndBandwithResults = new integraWS.LocationAccessAndBandwithResults[]{};
		
		integraws.LocationAccessAndBandwithResults lab = new integraws.LocationAccessAndBandwithResults();
		lab.AccessTechnologyID = 1;
		lab.AvailiableBandwidth = 50000;
		
		baas.LocationAccessAndBandwithResults.add(lab);
		
		List<Building_Access_Availability__c> b2 =  ga.CreateBuildingAccessAvailabilities(baas, b);
		CreateBuildingUsingGoogleAddress.BuildingReturnResult brr = new CreateBuildingUsingGoogleAddress.BuildingReturnResult(b,loc,b2,true);
		Double lat = 45.529734;
		Double lng = -122.65319499999998;
		CreateBuildingUsingGoogleAddress.BuildingIsValid(lat,lng,ga.street,ga.streetNumber,ga.suite,ga.city,ga.state,ga.postalCode);
		
		ga.selectedParent = 'failure';
		ga.ValidateBuildingAddress();
		
		
    }
    
    public static integraWS.SFLocationView getMockLocationView(){
    	integraWS.SFLocationView locView = new integraWS.SFLocationView();
    	locView.Success = true; 
        locView.BuildingHash = 'testclassbuildinghash';
        locView.LSOCLLI = 'PTLDOR12';
        locView.Street = '1234 Test';
		locView.StreetNumber = '1234';
        locView.City = 'Portland';
        locView.State = 'OR';
        locView.PostalCode = '97232';
		
		integraws.ArrayOfLocationAccessAndBandwithResults baas = new integraws.ArrayOfLocationAccessAndBandwithResults();
		
		integraws.LocationAccessAndBandwithResults lab = new integraws.LocationAccessAndBandwithResults();
		lab.AccessTechnologyID = 1;
		lab.AvailiableBandwidth = 10;
		baas.LocationAccessAndBandwithResults = new  integraWS.LocationAccessAndBandwithResults[]{lab};
		//baas.LocationAccessAndBandwithResults.add(lab);
		
		locView.AccessAndBandwidthResults = baas;
		System.debug('locView: ' + locView);
		System.debug('baas: ' + baas);
        return locView;
    }
	*/
}