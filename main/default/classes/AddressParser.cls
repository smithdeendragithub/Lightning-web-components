public with sharing class AddressParser {
	
	private static Map<String, String> params = null;
	private static String getParam(String paramName){
		if(params == null)
			params = Apexpages.currentPage().getParameters();
 		return params.get(paramName) != null ? params.get(paramName).trim().replace('&apos;','') : null;
	}
	
	public static String Param_StreetNumber { get{ return getParam('streetNumber'); } }
	public static String Param_Street { get{ return getParam('street'); } }
	public static String Param_Suite { get{ return getParam('suite'); } }
	public static String Param_City { get{ return getParam('city'); } }
	public static String Param_State { get{ return getParam('state'); } }
	public static String Param_PostalCode { get{ return getParam('postalCode'); } }
	public static Boolean Param_ManualCreate { get{ return getParam('manualCreate') == 'true'; } }
	public static Decimal Param_Latitude { get{ return !String.IsEmpty(getParam('latitude')) ? Decimal.valueOf(getParam('latitude')) : null; } }
	public static Decimal Param_Longitude { get{ return !String.IsEmpty(getParam('longitude')) ? Decimal.valueOf(getParam('longitude')) : null; } }
	public static String Param_Country { get{ return getParam('country'); } }
    
	public static integraWS.SFLocationView addressParsed(){
		system.debug('streetNo: ' + Param_StreetNumber);
		system.debug('street: ' + Param_Street);
		system.debug('suite: ' + Param_Suite);
		system.debug('city: ' + Param_City);
		system.debug('state: ' + Param_State);
		system.debug('postalCode: ' + Param_PostalCode);
		system.debug('latitude: ' + Param_Latitude);
		system.debug('longitude: ' + Param_Longitude);
		system.debug('manual: ' + Param_ManualCreate);
        system.debug('country: ' + Param_Country);
		return AddressParser.parseAddress(Param_StreetNumber, string.escapeSingleQuotes(Param_Street), Param_Suite, string.escapeSingleQuotes(Param_City.replace('\'',' ')), Param_State, Param_PostalCode, Param_Latitude, Param_Longitude, Param_ManualCreate, Param_Country);
	}
	
    //MNK Added new method to support country
    public static integraWS.SFLocationView parseAddress(String streetNum, String street, String subPremise, String city, String state, String postalCode, Decimal latitude, Decimal longitude, Boolean manualCreate, String country){
        integraWS.SFLocationView locView = getSFLocationView(streetNum, street, subPremise, city, state, postalCode, latitude, longitude, country);

		system.debug('Location to parse: ' + locView);

		locView = Test.isRunningTest() ? Test_AddressSelector.SetupLocationTestData(locView) : integraWSEndpointMediator.Endpoint.ValidateBuildingAddress(locView, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint, manualCreate);
		
		System.debug('locView: ' + locView);
		
		return locView;
	}
    
	public static integraWS.SFLocationView parseAddress(String streetNum, String street, String subPremise, String city, String state, String postalCode, Decimal latitude, Decimal longitude, Boolean manualCreate){
		//System.debug('MNK AddressParser parseAddress no country passed');
        
        integraWS.SFLocationView locView = getSFLocationView(streetNum, street, subPremise, city, state, postalCode, latitude, longitude);
        
		system.debug('Location to parse: ' + locView);

		locView = Test.isRunningTest() ? Test_AddressSelector.SetupLocationTestData(locView) : integraWSEndpointMediator.Endpoint.ValidateBuildingAddress(locView, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint, manualCreate);
		
		System.debug('locView: ' + locView);
		
		return locView;
	}
	
	public static integraWS.SFLocationView getSFLocationView(String streetNum, String street, String subPremise, String city, String state, String postalCode, Decimal latitude, Decimal longitude){
        integraWS.SFLocationView locView = new integraWS.SFLocationView();
        locView.StreetNumber = streetNum;
        locView.Street = street;
        locView.SubPremise = subPremise;
        locView.City = city;
        locView.State = state;
        locView.PostalCode = postalCode;
        locView.Latitude = latitude;
        locView.Longitude = longitude;
        
        return locView;
	}
    //MNK added to support country
    public static integraWS.SFLocationView getSFLocationView(String streetNum, String street, String subPremise, String city, String state, String postalCode, Decimal latitude, Decimal longitude, String country){
		integraWS.SFLocationView locView = new integraWS.SFLocationView();
        locView.StreetNumber = streetNum;
        locView.Street = street;
        locView.SubPremise = subPremise;
        locView.City = city;
        locView.State = state;
        locView.PostalCode = postalCode;
        locView.Latitude = latitude;
        locView.Longitude = longitude;
        locView.Country = country;
        
        return locView;
	}
}