@isTest
public class Test_AddressUtils {
    
    static testmethod void testLocationSubscriberAddressViewFields(){
        System.Assert(AddressUtils.LocationSubscriberAddressViewFields != null);
    }
    
    static testmethod void testCustomerDetailAddressFieldSet(){
        System.Assert(AddressUtils.CustomerDetailAddressFieldSet != null);
    }
 
 	static testmethod void testgetAddressFormatFromBuildingAndType(){
        Test.startTest();
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MArea;
        Building_Address_Format__c BAF = new Building_Address_Format__c(City__c = 'Toronto');
        insert BAF;
        Building__c b = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US', MSAG_Address_Format__r = BAF, Tax_Main_Address_Format__r = BAF);
        insert b;
        System.AssertEquals(AddressUtils.getAddressFormatFromBuildingAndType(null,null), null);
        System.AssertEquals(AddressUtils.getAddressFormatFromBuildingandType(b,1), (Building_Address_Format__c)BAF);
        System.AssertEquals(AddressUtils.getAddressFormatFromBuildingandType(b,2), (Building_Address_Format__c)BAF);
        Test.stopTest();
    }
 	
    static testmethod void testsetSubscriberAddressViewValues(){
        Test.startTest();
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MArea;
        System.AssertEquals(AddressUtils.setSubscriberAddressViewValues('Toronto','K1K 2G2', 'zipcode', 'ON', '123 Street', 'Location', 122, 1, 5, 'SomeSFDCId').Zip,'K1K 2G2-zipcode');
        System.AssertEquals(AddressUtils.setSubscriberAddressViewValues('Toronto','K1K 2G2', null, 'ON', '123 Street', 'Location', 122, 1, 5, 'SomeSFDCId', 'CA').Country,'CA');
        
        Building_Address_Format__c BAF = new Building_Address_Format__c(City__c = 'Toronto', Street__c = 'Street', House_Number__c = '123', Street_Type__c = 'Road', PostDirectional__c = 'NW');
        insert BAF;
        Building__c Building = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US', Postal_Code__c = 'K1K 2L2', Zip4__c = '5221',  MSAG_Address_Format__r = BAF, Tax_Main_Address_Format__r = BAF);
        insert Building;
        Location__c loc = new Location__c(Building__r = Building, Building__c = Building.Id, Room_Suite__c = '123');
        insert loc;
        System.AssertEquals(AddressUtils.setSubscriberAddressViewValues(loc, 567, 4, 2).street, '123 Address Street');
        System.AssertEquals(AddressUtils.setSubscriberAddressViewValues(new Location__c(), 567, 1, 2), null);
        
        System.AssertEquals(AddressUtils.setSubscriberAddressViewValues(Building, '005m00420032zBF', 'RoomSuite', 1, 1, 1).HouseNbr, '123');
        System.AssertEquals(AddressUtils.setSubscriberAddressViewValues(Building, '005m00420032zBF', 'RoomSuite', 1, 2, 1).PostDirectional, 'NW');
    	System.AssertEquals(AddressUtils.setSubscriberAddressViewValues(Building, '005m00420032zBF', 'RoomSuite', 1, null, 1).street, '123 Address Street');
        Test.stopTest();
    }
    
 	static testmethod void testsetSubscriberAddressViewNameValues(){
        System.AssertEquals(AddressUtils.setSubscriberAddressViewNameValues(new IntegraWS.SFSubscriberAddressView(),'Company', 'Backup', 'FName', 'LName').CompanyName, null);
        System.AssertEquals(AddressUtils.setSubscriberAddressViewNameValues(new IntegraWS.SFSubscriberAddressView(),'Company', 'Backup', 'FName', null).CompanyName, 'Company');
        System.AssertEquals(AddressUtils.setSubscriberAddressViewNameValues(new IntegraWS.SFSubscriberAddressView(), null, 'Backup', 'FName', null).CompanyName, 'Backup');
    }
 
    static testmethod void testsetSubscriberAddressViewValuesFromCustomerDetailFieldSet(){
        Test.startTest();
        Market_Area__c MAreaNational = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MAreaNational;
        Market_Area__c MArea = new Market_Area__c(ICCMarketAreaID__c = 12, MarketAreaExternalID__c = 'ExternalID12345');
        insert MArea;
        Customer_Detail__c CD = new Customer_Detail__c(Market_Area__r = MArea, Market_Area__c = MArea.Id);
        insert CD;
        System.AssertEquals(AddressUtils.setSubscriberAddressViewValuesFromCustomerDetailFieldSet(CD,1,'Billing_Main'), null);
        
        CD.Billing_Main_City__c = 'Main Billing City';
        CD.Billing_Main_Country__c = 'CA';
        CD.Billing_Main_Name__c = 'Biller Name';
        CD.Billing_Main_Postal_Code__c = 'K1K 2L2';
        CD.Billing_Main_Street__c = '123 Street';
        CD.Billing_Main_State__c = 'ON';
        update CD;
    	System.AssertEquals(AddressUtils.setSubscriberAddressViewValuesFromCustomerDetailFieldSet(CD,1,'Billing_Main').MarketAreaID, 12);
        Test.stopTest();
    } 
 	
    static testmethod void testgetSFSubscriberAddressViewsFromCustomerDetail(){
        Test.startTest();
        Market_Area__c MAreaNational = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MAreaNational;
        Market_Area__c MArea = new Market_Area__c(ICCMarketAreaID__c = 12, MarketAreaExternalID__c = 'ExternalID12345');
        insert MArea;
        Customer_Detail__c CD = new Customer_Detail__c(Market_Area__r = MArea, Market_Area__c = MArea.Id, First_Name__c = 'FName', Last_Name__c = 'LName');
        insert CD;
        System.Assert(AddressUtils.getSFSubscriberAddressViewsFromCustomerDetail(CD,1).isEmpty());
        
        CD.Billing_Main_City__c = 'Main Billing City';
        CD.Billing_Main_Country__c = 'CA';
        CD.Billing_Main_Name__c = 'Biller Name';
        CD.Billing_Main_Postal_Code__c = 'K1K 2L2';
        CD.Billing_Main_Street__c = '123 Street';
        CD.Billing_Main_State__c = 'ON';
        update CD;
        System.AssertEquals(AddressUtils.getSFSubscriberAddressViewsFromCustomerDetail(CD,1,true)[0].MarketAreaID, AddressUtils.setSubscriberAddressViewValuesFromCustomerDetailFieldSet(CD,1,'Billing_Main').MarketAreaID);
    	System.Assert(AddressUtils.getSFSubscriberAddressViewsFromCustomerDetail(CD,1,false).isEmpty());
		Test.stopTest();
    }
 	
    static testmethod void testupdateCustomerDetailAddressSet(){
        Test.startTest();
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MArea;
        Customer_Detail__c CD = new Customer_Detail__c();
        AddressUtils.updateCustomerDetailAddressSet(CD, 'Billing_Main_FAKE', 'CA', 'K3K 2L2', 'ON', '123 Street', 'RoomSuite', 'OverrideName', 'CA');
        System.assertEquals(CD.Billing_Main_Postal_Code__c, null);
        AddressUtils.updateCustomerDetailAddressSet(CD, 'Billing_Main', 'CA', 'K3K 2L2', null, '123 Street', 'RoomSuite', 'OverrideName', 'CA');
        System.assertEquals(CD.Billing_Main_Name__c, null);
        
        AddressUtils.updateCustomerDetailAddressSet(CD, 'Billing_Main', 'CA', 'K3K 2L2', '1234', 'ON', '123 Street', 'RoomSuite', 'OverrideName', 'CA');
        System.assertEquals(CD.Billing_Main_Postal_Code__c, 'K3K 2L2-1234');
        AddressUtils.updateCustomerDetailAddressSet(CD, 'Billing_Main', 'CA', 'K3K 2L2', null, 'ON', '123 Street', 'RoomSuite', 'OverrideName', 'CA');
        System.assertEquals(CD.Billing_Main_Postal_Code__c, 'K3K 2L2');   
        Test.stopTest();
    }

    static testmethod void testvalidateAndClearCustomerDetailAddresses(){
        Test.startTest();
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MArea;
        List<Customer_Detail__c> details = new List<Customer_Detail__c>();
        Set<Id> CustomerIDs = new Set<Id>();
        for (Integer i = 0; i < 5; ++i){
            details.add(new Customer_Detail__c(Billing_Main_City__c = 'Toronto', Billing_Main_Country__c = 'CA', Billing_Main_Name__c = 'Biller Name', Billing_Main_Postal_Code__c = 'K1K 2L2', Billing_Main_Street__c = '123 Street', Billing_Main_State__c = 'ON', ICC_Subscriber_ID__c = '1234' + String.valueOf(i), First_Name__c = 'FName' + String.valueOf(i), Last_Name__c = 'LName' + String.valueOf(i)));
        }
        insert details;
        for (Integer i = 0; i < 5; ++i){
            CustomerIDS.add(details[i].Id);
        }
        System.Assert(AddressUtils.validateAndClearCustomerDetailAddresses(CustomerIDs).isEmpty());
        
        
        Map<String, Customer_Detail__c> CustomerDetails = new Map<String, Customer_Detail__c>();
        List<IntegraWS.SFSubscriberAddressView> addresses = new List<IntegraWS.SFSubscriberAddressView>();
        for (Integer i = 0; i < 5; ++i){
            CustomerDetails.put(String.valueOf(i), details[i]);
            addresses.add(AddressUtils.setSubscriberAddressViewValues('Toronto','K1K 2G2', 'zipcode', 'ON', String.valueOf(i) + ' Street', 'Location', 122, 1, 5, 'SomeSFDCId'));
        }
        // integraWSEndpointMediator.simulateIntegrationException = true;
        System.Assert(AddressUtils.validateAndClearCustomerDetailAddresses(CustomerDetails, addresses, 'SessionID', null).isEmpty());
        Test.stopTest();
    }
    
    static testmethod void testvalidateAndSetCustomerDetailAddresses_Asynch(){
        AddressUtils.validateAndSetCustomerDetailAddresses_Asynch(JSON.serialize(new Map<Id, Map<String, String>>()), UserInfo.getSessionId());
    }
    
    static testmethod void testvalidateAndSetCustomerDetailAddresses(){
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MArea;
        Test.startTest();
        Map<Id, Map<String,String>> mapping = new Map<Id, Map<String,String>>();
        List<Customer_Detail__c> details = new List<Customer_Detail__c>();
        for (Integer i = 0; i < 5; ++i){
            details.add(new Customer_Detail__c(Billing_Main_City__c = 'Toronto', Billing_Main_Country__c = 'CA', Billing_Main_Name__c = 'Biller Name', Billing_Main_Postal_Code__c = 'K1K 2L2', Billing_Main_Street__c = '123 Street', Billing_Main_State__c = 'ON', ICC_Subscriber_ID__c = '1234' + String.valueOf(i), First_Name__c = 'FName' + String.valueOf(i), Last_Name__c = 'LName' + String.valueOf(i)));
        }
        insert details;
        for (Integer i = 0; i < details.size() ; ++i){
            mapping.put((Id)details[i].Id, new Map<String,String>{'Billing_Main' => ''});
        }
        System.Assert(AddressUtils.validateAndSetCustomerDetailAddresses(mapping, UserInfo.getSessionID()).isEmpty());
        Test.stopTest();   
    }
    
    static testmethod void testCreateBuilding(){
        Test.startTest();
        Building__c b = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US', Building_Hash__c = 'BHash');
        insert b;
        integraWS.SFLocationView loc = new integraWS.SFLocationView();
        loc.BuildingHash = 'BHash';
        System.AssertEquals(AddressUtils.CreateBuilding(loc,null,null), b);      
        
        loc.BuildingHash = 'DoesNotExist';
        loc.LSOCLLI = '123456789';
        loc.PostalCode = 'K2K 2L2-zip4';
        loc.Street = '123 Street';
        loc.City = 'Toronto';
        loc.State = 'ON';
        loc.Country = 'CA';
        b.Building_Hash__c = null;
        update b;
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MArea;
        
        IntegraServiceSettings__c integraServiceSettings = IntegraServiceSettings__c.getInstance();
        List<User> u = new List<User>();
        u = [select id, ntid__c, IsActive from user where ntid__c = :integraServiceSettings.No_Serving_LSO_Task_Owner__c];
        for (User x : u){
            x.ntid__c = 'Don\'t Query Me';       
        }
        u[0].ntid__c = integraServiceSettings.No_Serving_LSO_Task_Owner__c;
        System.runAs(new User(Id = UserInfo.getUserId())){
        	update u;        
        }
        
        System.AssertEquals(AddressUtils.CreateBuilding(loc,true,true).Postal_Code__c, 'K2K 2L2');
        Test.stopTest();
    }

    static testmethod void testSaveAddress(){
        Test.startTest();
        Building__c b = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US');
        Location__c loc = new Location__c();
        Account acc = new Account(Name = 'Name');
        insert acc;
        Service_Location__c sLoc = new Service_Location__c(Account__c = acc.Id);
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MArea;
        for (Database.UpsertResult x : AddressUtils.SaveAddress(b,loc,sLoc,false)){
            System.Assert(x.isSuccess());
        }
    
        // Error expected
        Service_Location__c sLoc2 = new Service_Location__c();
        Boolean err = false;
        for (Database.UpsertResult x : AddressUtils.SaveAddress(b,loc,sLoc2,false)){
            if (!x.isSuccess()){
                err = true;
                System.debug(x.getErrors());
                break;
            }
        }
        System.assert(err);
        Test.stopTest();
    }
    
    static testmethod void testDisplayErrorMessageFromLocView(){
        integraWS.SFLocationView loc = new integraWS.SFLocationView();
        loc.Messages = new schemasMicrosoftCom200310Serializat.ArrayOfstring();
        loc.Messages.string_x = new String[]{'Word', 'Puzzle'};
        AddressUtils.DisplayErrorMessageFromLocView(loc, false);
        System.Assert(ApexPages.hasMessages());
        System.AssertEquals(ApexPages.getMessages()[0], new ApexPages.Message(ApexPages.Severity.Warning, 'Word,Puzzle'));
        AddressUtils.DisplayErrorMessageFromLocView(loc, true);
        System.AssertEquals(ApexPages.getMessages()[1], new ApexPages.Message(ApexPages.Severity.Warning, 'Word<br />Puzzle'));
    }
    
    static testmethod void testCreateLeadsFromGeoResultsBusinesses(){
        Test.startTest();
        Map<Id,Id> mapping = new Map<Id,Id>();
        List<Georesults_business__c> geoB = new List<Georesults_business__c>();
        Building__c b = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US');
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MArea;
        insert b;
        Location__c loc = new Location__c(Building__c = b.Id);
        insert loc;
        for (Integer i = 0; i < 5; ++i){
            geoB.add(new Georesults_business__c(Building__c = b.Id, Phone__c = '1234567890', CleanBusiness__c = 'CleanBusinessName', Contact__c = 'ContactName'));
        }
        insert geoB;
        for (Integer i = 0; i < 5; ++i){
            mapping.put(geoB[i].Id,geoB[i].OwnerId);
        }
        AddressUtils.CreateLeadsFromGeoResultsBusinesses(mapping);
        Building__c b2 = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US');
        insert b2;
        loc.Building__c = b2.Id;
        update loc;
        AddressUtils.CreateLeadsFromGeoResultsBusinesses(mapping);
        System.Assert(![Select Id From Lead Where Building__c =: b.Id].isEmpty());
        Test.stopTest();
    }
    
    static testmethod void testCreateBuildingAccessAvailabilityOfServingLSO(){
        Test.startTest();
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345', Name = 'National');
        insert MArea;
        Building__c b1 = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US', Market_Area__c = MArea.Id, LSO_CLLI__c = 'EoTDM', Building_Type__c = 'ILEC LSO: Collocated');
        insert b1;
        Building__c b2 = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US', Serving_LSO__c = b1.Id, Market_Area__c = MArea.Id, LSO_CLLI__c = 'EoTDM', Building_Type__c = 'ILEC LSO: Collocated');
        insert b2;
        Access_Technology__c AT = new Access_Technology__c(Name = 'EoTDM', Access_Technology_ID__c = 123);
        insert AT;
        Building_Access_Availability__c BAA = new Building_Access_Availability__c(Building__c = b1.Id, Access_Technology__c = AT.Id);
        insert BAA;
        List<Building_Access_Availability__c> ret = AddressUtils.CreateBuildingAccessAvailabilityOfServingLSO(b2);
        System.Assert(ret.size() == 1);
 		Test.stopTest();
    }
}