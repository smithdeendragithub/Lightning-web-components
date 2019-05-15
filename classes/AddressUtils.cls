/**************************************************************************************************
*    AddressUtils .cls
*
*    Modifications:
*    Developer Name       Date        Brief description
*    -------------------  ----------  ------------------------------------------------------------
*    Eunjung Ju           12/13/2017  SEAL-529 - Creating Building Access Availabilities for EoTDM
**************************************************************************************************/
public without sharing class AddressUtils {
    
    public final static Map<String, Integer> CustomerDetailFieldAddressTypes = new Map<String, Integer>{'Customer_Main_Address__c'=>1
                                                                                                    ,'Tax_Main_Address__c'=>2
                                                                                                    ,'Service_Address__c'=>9};
    
    public final static Map<String, Integer> CustomerDetailFieldSetAddressTypes = new Map<String, Integer>{'Billing_Main'=>3
                                                                                                            ,'Billing_Final'=>4};
    
    public final static List<String> CustomerDetailFieldSetAddressSubFields = new List<String>{ 'City__c', 'Postal_Code__c', 'Room_Suite__c', 'State__c', 'Street__c', 'Name__c', 'Country__c' };
    
    public static Set<String> LocationSubscriberAddressViewFields{
        get{
            Set<String> s = new Set<String>{ 'Id', 'Name', 'Room_Suite__c', 'Building__r.Id', 'Building__r.Address__c'
                , 'Building__r.City__c', 'Building__r.State__c', 'Building__r.Postal_Code__c'
                , 'Building__r.Zip4__c', 'Building__r.Building_Hash__c', 'Building__r.Country__c' };
            for(String formatBase : new Set<String>{ 'MSAG_Address_Format__r', 'Tax_Main_Address_Format__r' }){
                for(String formatField : new Set<String>{ 'Id', 'House_Number__c', 'PreDirectional__c', 'Street__c', 'Street_Type__c', 'PostDirectional__c', 'City__c' })
                    s.add('Building__r.' + formatBase + '.' + formatField);
            }
            return s;
        }
    }
    
    public static Set<String> CustomerDetailAddressFieldSet {
        get{
            Set<String> s = new Set<String>{ 'ICC_Subscriber_ID__c','Market_Area__r.Id','Market_Area__r.ICCMarketAreaID__c','Name','First_Name__c','Last_Name__c' };
            
            for(String k : CustomerDetailFieldSetAddressTypes.keySet()){
                for(String fsField : CustomerDetailFieldSetAddressSubFields)
                    s.add(k + '_' + fsField);
            }
            
            Set<String> addressViewFields = LocationSubscriberAddressviewFields;
            for(String k : CustomerDetailFieldAddressTypes.keySet()){
                String r = k.replace('__c', '__r');
                for(String f : addressViewFields)
                    s.add(r + '.' + f);
            }
            
            return s;
        }
    }
    
    /* Customer Detail Address Methods */
    
    public static Building_Address_Format__c getAddressFormatFromBuildingAndType(Building__c building, Integer addressTypeID){
        if(building != null && addressTypeID == 1)
            return (Building_Address_Format__c)building.getsObject('MSAG_Address_Format__r');
        else if(building != null && addressTypeID == 2)
            return (Building_Address_Format__c)building.getsObject('Tax_Main_Address_Format__r');
        else
            return null;
    }
    
    public static integraWS.SFSubscriberAddressView setSubscriberAddressViewValues(String city, String postalCode, String zip4, String state, String street, String location, Integer subscriberID, Integer addressTypeId, Integer marketAreaID, String salesforceID){
        integraWS.SFSubscriberAddressView address = new integraWS.SFSubscriberAddressView();
        address.SubscriberId = subscriberID;
        address.City = city;
        address.Zip = postalCode + (!String.isEmpty(zip4) ? ('-' + zip4) : '');
        address.State = state;
        address.Street = street;
        address.Location = location;
        address.Country = 'USA';
        address.AddressTypeId = addressTypeId;
        address.MarketAreaId = marketAreaID != null ? marketAreaID : 0;
        address.SalesforceId = salesforceID;
        return address;
    }
    
    //MNK added to support country
    public static integraWS.SFSubscriberAddressView setSubscriberAddressViewValues(String city, String postalCode, String zip4, String state, String street, String location, Integer subscriberID, Integer addressTypeId, Integer marketAreaID, String salesforceID, String country){
        integraWS.SFSubscriberAddressView address = new integraWS.SFSubscriberAddressView();
        address.SubscriberId = subscriberID;
        address.City = city;
        address.Zip = postalCode + (!String.isEmpty(zip4) ? ('-' + zip4) : '');
        address.State = state;
        address.Street = street;
        address.Location = location;
        address.Country = country;
        address.AddressTypeId = addressTypeId;
        address.MarketAreaId = marketAreaID != null ? marketAreaID : 0;
        address.SalesforceId = salesforceID;
        return address;
    }
    
    public static integraWS.SFSubscriberAddressView setSubscriberAddressViewNameValues(integraWS.SFSubscriberAddressView address, String companyName, String companyNameBackup, String firstName, String lastName){
        if(address != null){
            if(!String.isEmpty(lastName)){
                address.FirstName = firstName;
                address.LastName = lastName;
            }
            else{
                address.CompanyName = !string.isEmpty(companyName) ? companyName : companyNameBackup;
            }
        }
        return address;
    }
    
    public static integraWS.SFSubscriberAddressView setSubscriberAddressViewValues(Location__c loc, Integer subscriberID, Integer addressTypeId, Integer marketAreaID){
        return loc != null && loc.Building__c != null ? setSubscriberAddressViewValues(loc.Building__r, loc.Id, loc.Room_Suite__c, subscriberID, addressTypeId, marketAreaID) : null;
    }
    
    public static integraWS.SFSubscriberAddressView setSubscriberAddressViewValues(Building__c building, Id id, String roomSuite, Integer subscriberID, Integer addressTypeId, Integer marketAreaID){
        Building_Address_Format__c formatted = getAddressFormatFromBuildingAndType(building, addressTypeID);
        
        integraWS.SFSubscriberAddressView address = setSubscriberAddressViewValues(formatted == null ? building.City__c : formatted.City__c
                                                                                    ,building.Postal_Code__c
                                                                                    ,building.Zip4__c
                                                                                    ,building.State__c
                                                                                    ,formatted == null ? building.Address__c : formatted.Street__c
                                                                                    ,roomSuite
                                                                                    ,subscriberID
                                                                                    ,addressTypeId
                                                                                    ,marketAreaID
                                                                                    ,id
                                                                                    ,building.Country__c);
        if(formatted == null)
            address.BuildingHash = building.Building_Hash__c;
        else{
            address.HouseNbr = formatted.House_Number__c;
            address.PreDirectional = formatted.PreDirectional__c;
            address.PostDirectional = formatted.PostDirectional__c;
        }
        
        return address;
    }
    
    public static integraWS.SFSubscriberAddressView setSubscriberAddressViewValuesFromCustomerDetailFieldSet(Customer_Detail__c detail, Integer subscriberID, String fieldSetRoot){
        return CustomerDetailFieldSetAddressTypes.get(fieldSetRoot) != null && !string.IsEmpty(string.valueOf(detail.get(fieldSetRoot + '_City__c')))       //Assuming all or nothing validation rule
                ? setSubscriberAddressViewNameValues(
                        setSubscriberAddressViewValues(string.valueOf(detail.get(fieldSetRoot + '_City__c'))
                                                ,string.valueOf(detail.get(fieldSetRoot + '_Postal_Code__c'))
                                                ,null
                                                ,string.valueOf(detail.get(fieldSetRoot + '_State__c'))
                                                ,string.valueOf(detail.get(fieldSetRoot + '_Street__c'))
                                                ,string.valueOf(detail.get(fieldSetRoot + '_Room_Suite__c'))
                                                ,subscriberID
                                                ,CustomerDetailFieldSetAddressTypes.get(fieldSetRoot)
                                                ,detail.Market_Area__c != null ? integer.valueOf(detail.Market_Area__r.ICCMarketAreaID__c) : null
                                                ,detail.Id
                                                ,string.valueOf(detail.get(fieldSetRoot + '_Country__c')))
                                            ,string.valueOf(detail.get(fieldSetRoot + '_Name__c'))
                                            ,detail.Name
                                            ,detail.First_Name__c
                                            ,detail.Last_Name__c)
                : null;
    }
    
    public static List<integraWS.SFSubscriberAddressView> getSFSubscriberAddressViewsFromCustomerDetail(Customer_Detail__c detail, Integer subscriberID){
        return getSFSubscriberAddressViewsFromCustomerDetail(detail, subscriberID, true);
    }
    
    public static List<integraWS.SFSubscriberAddressView> getSFSubscriberAddressViewsFromCustomerDetail(Customer_Detail__c detail, Integer subscriberID, Boolean includeFieldSets){
        List<integraWS.SFSubscriberAddressView> addresses = new List<integraWS.SFSubscriberAddressView>();
        
        Integer marketAreaID = detail.Market_Area__c != null ? integer.valueOf(detail.Market_Area__r.ICCMarketAreaID__c) : null;
        for(String addressField : CustomerDetailFieldAddressTypes.keyset()){
            integraWS.SFSubscriberAddressView addr = setSubscriberAddressViewNameValues(
                                                                setSubscriberAddressViewValues(
                                                                    (Location__c)detail.getsObject(addressField.replace('__c', '__r'))
                                                                    ,subscriberID
                                                                    ,CustomerDetailFieldAddressTypes.get(addressField)
                                                                    , marketAreaID)
                                                            , null, detail.Name, detail.First_Name__c, detail.Last_Name__c);
            if(addr != null) addresses.add(addr);
        }
        
        if(includeFieldSets){
            for(String addressFieldRoot : CustomerDetailFieldSetAddressTypes.keyset()){
                integraWS.SFSubscriberAddressView addr = setSubscriberAddressViewValuesFromCustomerDetailFieldSet(detail
                                                                                                                  ,subscriberID
                                                                                                                  ,addressFieldRoot);
                if(addr != null) addresses.add(addr);
            }
        }
        
        return addresses;
    }
    
    //MNK added country
    public static void updateCustomerDetailAddressSet(Customer_Detail__c detail, String fieldSetRoot, String city, String postalCode, String zip4, String state, String street, String roomSuite, String overrideName, String country){
        String postalCodeWithZip4 = postalCode + (!String.isEmpty(zip4) ? ('-' + zip4) : '');
        updateCustomerDetailAddressSet(detail, fieldSetRoot, city, postalCodeWithZip4, state, street, roomSuite, overrideName, country);
    }
    
    public static void updateCustomerDetailAddressSet(Customer_Detail__c detail, String fieldSetRoot, String city, String postalCode, String state, String street, String roomSuite, String overrideName, String country){
        if(CustomerDetailFieldSetAddressTypes.get(fieldSetRoot) == null
            || string.IsEmpty(city)
            || string.IsEmpty(postalCode)
            || string.IsEmpty(state)
            || string.IsEmpty(street)
            || string.IsEmpty(country)) return;
        
        detail.put(fieldSetRoot + '_City__c', city);
        detail.put(fieldSetRoot + '_Postal_Code__c', postalCode);
        detail.put(fieldSetRoot + '_State__c', state);
        detail.put(fieldSetRoot + '_Street__c', street);
        detail.put(fieldSetRoot + '_Room_Suite__c', roomSuite);
        detail.put(fieldSetRoot + '_Name__c', overrideName);
        //MNK addedd
        detail.put(fieldSetRoot + '_Country__c', country);
    }
    
    //Clears bad addresses and returns errors
    public static List<String> validateAndClearCustomerDetailAddresses(Set<Id> customerDetailIDs){
        return validateAndClearCustomerDetailAddresses(customerDetailIDs, UserInfo.getSessionId());
    }
    
    @future(callout=true)
    public static void validateAndSetCustomerDetailAddresses_Asynch(String customerDetailAddressJSONMap, string sessionID){
        Map<Id, Map<String, String>> customerDetailAddressMap = (Map<Id, Map<String, String>>)JSON.deserialize(customerDetailAddressJSONMap, Map<Id, Map<String, String>>.class);
        List<String> errors = validateAndSetCustomerDetailAddresses(customerDetailAddressMap, sessionID);
        for(String error : errors) System.debug(error);
    }
    
    private static List<String> validateAndClearCustomerDetailAddresses(Set<Id> customerDetailIDs, string sessionID){
        Map<String, Customer_Detail__c> customerDetails = new Map<String, Customer_Detail__c>();
        List<integraWS.SFSubscriberAddressView> addresses = new List<integraWS.SFSubscriberAddressView>();
        for(Customer_Detail__c detail : (List<Customer_Detail__c>)(ApexUtils.retrieveObjectsFromFieldSet(
                                                                            Customer_Detail__c.getsObjectType()
                                                                            ,CustomerDetailAddressFieldSet
                                                                            ,'Id in (\'' + string.join(new List<Id>(customerDetailIDs), '\',\'') + '\')'
                                                                            ,null))){
            customerDetails.put(detail.Id, detail);
            for(integraWS.SFSubscriberAddressView addr : getSFSubscriberAddressViewsFromCustomerDetail(detail, detail.ICC_Subscriber_ID__c != null ? integer.valueOf(detail.ICC_Subscriber_ID__c) : 0)){
                addr.SalesforceID = detail.Id;
                addresses.add(addr);
            }
        }
        
        List<String> retval = new List<String>();
        if(addresses.size() > 0){
            Map<String, Customer_Detail__c> updates = new Map<String, Customer_Detail__c>();
            retval = validateAndClearCustomerDetailAddresses(customerDetails, addresses, sessionID, updates);
            if(updates.size() > 0) update updates.values();
        }
        
        return retval;
    }
    
    public static List<String> validateAndSetCustomerDetailAddresses(Map<Id, Map<String, String>> customerDetailAddressMap, String sessionID){
        System.debug('Validating the following addresses in validateAndSetCustomerDetailAddresses: ' + customerDetailAddressMap);
        
        List<String> retval = new List<String>();
        
        if(customerDetailAddressMap == null) return retval;
        
        Map<String, Integer> fssfMap = new Map<String, Integer>();
        for(Integer i=0; i<CustomerDetailFieldSetAddressSubFields.size(); i++)
            fssfMap.put(CustomerDetailFieldSetAddressSubFields[i], i);
        
        Map<Id, Location__c> lMap = new Map<Id, Location__c>();
        for(Id id : customerDetailAddressMap.keySet()){
            for(String k : customerDetailAddressMap.get(id).keyset()){
                if(CustomerDetailFieldAddressTypes.get(k) != null) lMap.put(customerDetailAddressMap.get(id).get(k), null);
            }
        }
        
        lMap = new Map<Id, Location__c>((List<Location__c>)(ApexUtils.retrieveObjectsFromFieldSet(
                                                                    Location__c.getsObjectType()
                                                                    ,LocationSubscriberAddressViewFields
                                                                    ,'Id in (\'' + string.join(new List<Id>(lMap.keyset()), '\',\'') + '\')'
                                                                    ,null)));
        
        Map<String, Customer_Detail__c> customerDetails = new Map<String, Customer_Detail__c>();
        List<integraWS.SFSubscriberAddressView> addresses = new List<integraWS.SFSubscriberAddressView>();
        for(Customer_Detail__c detail : [select Id, Name, First_Name__c, Last_Name__c, ICC_Subscriber_ID__c, Market_Area__c, Market_Area__r.ICCMarketAreaID__c from Customer_Detail__c where Id in: customerDetailAddressMap.keyset()]){
            customerDetails.put(detail.Id, detail);
            Integer marketAreaID = detail.Market_Area__c != null ? Integer.valueOf(detail.Market_Area__r.ICCMarketAreaID__c) : 0;
            Integer subscriberID = detail.ICC_Subscriber_ID__c != null ? Integer.valueOf(detail.ICC_Subscriber_ID__c) : 0;
            
            for(String k : customerDetailAddressMap.get(detail.Id).keyset()){
                integraWS.SFSubscriberAddressView addr = null;
                String val = customerDetailAddressMap.get(detail.Id).get(k);
                if(CustomerDetailFieldAddressTypes.get(k) != null){
                    addr = setSubscriberAddressViewNameValues(setSubscriberAddressViewValues(lMap.get(val), subscriberID, CustomerDetailFieldAddressTypes.get(k), marketAreaID), null, detail.Name, detail.First_Name__c, detail.Last_Name__c);
                }
                else if(CustomerDetailFieldSetAddressTypes.get(k) != null){
                    List<String> sp = val.split('\t');
                    for(Integer i=sp.size()-1; i<fssfMap.size(); i++) sp.add('');
                    
                    addr = setSubscriberAddressViewNameValues(setSubscriberAddressViewValues(sp[fssfMap.get('City__c')]
                                                    ,sp[fssfMap.get('Postal_Code__c')]
                                                    ,null
                                                    ,sp[fssfMap.get('State__c')]
                                                    ,sp[fssfMap.get('Street__c')]
                                                    ,sp[fssfMap.get('Room_Suite__c')]
                                                    ,subscriberID
                                                    ,CustomerDetailFieldSetAddressTypes.get(k)
                                                    ,marketAreaID
                                                    ,detail.Id
                                                    ,sp[fssfMap.get('Country__c')])
                                                ,sp[fssfMap.get('Name__c')]
                                                ,detail.Name
                                                ,detail.First_Name__c
                                                ,detail.Last_Name__c);
                }
                
                if(addr != null){
                    addr.SalesforceID = detail.Id;
                    addresses.add(addr);
                }
            }
        }
        
        Map<String, Schema.SObjectField> fieldMap = Customer_Detail__c.getsObjectType().getDescribe().fields.getMap();
        Map<String, Map<Integer, String>> errors = validateCustomerDetailAddresses(customerDetails, addresses, sessionID);
        for(Id id : customerDetailAddressMap.keySet()){
            Customer_Detail__c cd = customerDetails.get(id);
            Map<String, String> m = customerDetailAddressMap.get(id);
            for(String k : m.keyset()){
                String val = m.get(k);
                Integer addressTypeID = CustomerDetailFieldAddressTypes.containsKey(k) ? CustomerDetailFieldAddressTypes.get(k) : CustomerDetailFieldSetAddressTypes.get(k);
                if(errors.get(id) == null || errors.get(id).get(addressTypeID) == null){
                    if(CustomerDetailFieldAddressTypes.get(k) != null) cd.put(k, val);
                    else if(CustomerDetailFieldSetAddressTypes.get(k) != null){
                        List<String> sp = val.split('\t');
                        for(Integer i=sp.size()-1; i<fssfMap.size(); i++) sp.add('');
                        
                        for(Integer i=0; i<CustomerDetailFieldSetAddressSubFields.size(); i++)
                            cd.put(k + '_' + CustomerDetailFieldSetAddressSubFields[i], sp[fssfMap.get(CustomerDetailFieldSetAddressSubFields[i])]);
                    }
                }
                else retval.add('Address ' + k + ' did not validate for customer detail \'' + id + '\':' + errors.get(id).get(addressTypeID));
            }
        }
        
        update customerDetails.values();
        
        return retval;
    }
    
    public static List<String> validateAndClearCustomerDetailAddresses(Map<String, Customer_Detail__c> customerDetails, List<integraWS.SFSubscriberAddressView> addresses, string sessionID, Map<String, Customer_Detail__c> outUpdates){
        List<String> retval = new List<String>();
        
        if(outUpdates == null) outUpdates = new Map<String, Customer_Detail__c>();
        
        Map<Integer, String> reversedTypeMap = new Map<Integer, String>();
        for(String str : CustomerDetailFieldAddressTypes.keyset())
            reversedTypeMap.put(CustomerDetailFieldAddressTypes.get(str), str);
        
        Map<Integer, String> reversedTypeSetMap = new Map<Integer, String>();
        for(String str : CustomerDetailFieldSetAddressTypes.keyset())
            reversedTypeSetMap.put(CustomerDetailFieldSetAddressTypes.get(str), str);
        
        Map<String, Schema.SObjectField> fieldMap = Customer_Detail__c.getsObjectType().getDescribe().fields.getMap();
        Map<String, Map<Integer, String>> errors = validateCustomerDetailAddresses(customerDetails, addresses, sessionID);
        for(String id : errors.keyset()){
            Customer_Detail__c detail = customerDetails.get(id);
            for(Integer addressTypeID : errors.get(id).keyset()){
                String error = errors.get(id).get(addressTypeID);
                if(reversedTypeMap.get(addressTypeID) != null){                     //Clear the field
                    detail.put(reversedTypeMap.get(addressTypeID), '');
                    retval.add(reversedTypeMap.get(addressTypeID).replace('__c', '').replace('_', ' ') + ' did not validate for customer detail \'' + detail.Id + '\': ' + error);
                }
                else if(reversedTypeSetMap.get(addressTypeID) != null){         //Clear the fields by root name
                    String fieldRoot = reversedTypeSetMap.get(addressTypeID);
                    for(String fName : fieldMap.keyset()){
                        if(fName.startsWith(fieldRoot))
                            detail.put(fName, '');
                    }
                    retval.add(fieldRoot.replace('_', ' ') + ' Address did not validate for customer detail \'' + detail.Id + '\': ' + error);
                }
            }
            outUpdates.put(id, detail);
        }
        
        return retval;
    }
    
    private static Map<String, Map<Integer, String>> validateCustomerDetailAddresses(Map<String, Customer_Detail__c> customerDetails, List<integraWS.SFSubscriberAddressView> addresses, string sessionID){
        Map<String, Map<Integer, String>> errors = new Map<String, Map<Integer, String>>();
        
        List<integraWS.SFSubscriberAddressView> validationResults = ICCWrapper.validateSubscriberAddresses(addresses, sessionID);
        for(Integer i=0; i<validationResults.size(); i++){
            if(!string.IsEmpty(validationResults[i].ResultMessage)){
                if(errors.get(validationResults[i].SalesforceID) == null) errors.put(validationResults[i].SalesforceID, new Map<Integer, String>());
                errors.get(validationResults[i].SalesforceID).put(validationResults[i].AddressTypeId, validationResults[i].ResultMessage);
            }
        }
        
        return errors;
    }
    
    /* Building/Location methods */
    
    public static Building__c CreateBuilding(integraWS.SFLocationView loc, Boolean doInsert){
        return CreateBuilding(loc, doInsert, false);
    }
    
    public static Building__c CreateBuilding(integraWS.SFLocationView loc, Boolean doInsert, Boolean manualAddressCreate){
        Building__c building = GetBuildingByHash(loc.BuildingHash);
        if(building == null){
            Building__c b = new Building__c();
            string subLSOCLLI = '';
            if(loc.LSOCLLI != null){
                if(loc.LSOCLLI.length() > 8)
                    subLSOCLLI = loc.LSOCLLI.substring(0,8);
                else
                    subLSOCLLI = loc.LSOCLLI;
            }
            
            String postalCode = loc.PostalCode;
            String zip4 = postalCode != null && postalCode.contains('-') ? postalCode.substring(postalCode.indexOf('-')+1) : '';
            if(!string.isEmpty(zip4)) postalCode = postalCode.substring(0, postalCode.indexOf('-'));
            
            List<Building__c> colo = [Select Id From Building__c Where Building_CLLI__c = :subLSOCLLI and Building_CLLI__c != '' and Building_CLLI__c != 'NULL' and Building_CLLI__c != NULL and (Building_Type__c = 'ILEC LSO: Collocated' or Building_Type__c = 'ILEC LSO: Extended' or Building_Type__c = 'ILEC LSO: Extended Special' or Building_Type__c = 'ILEC LSO: Off Footprint' or Building_Type__c = 'ILEC Remote Switch')];
            b.Address__c = loc.Street;
            b.Building_Hash__c = loc.BuildingHash;
            b.Building_Type__c = 'Commercial Building';
            b.City__c = loc.City;
            //b.County__c = 'USA';
            b.Effective_Date__c = Datetime.now().date();
            b.House_Number__c = loc.StreetNumber;
            b.Latitude__c = loc.Latitude;
            b.Longitude__c = loc.Longitude;
            b.Postal_Code__c = postalCode;
            b.Zip4__c = zip4;
            b.State__c = loc.State;
            
            //MNK Added country
            b.Country__c = loc.Country;
            
            b.Net_Classification__c = 'Off-net';
            b.Status__c = 'New';
            b.AddressID__c = loc.AddressID;
            b.Manually_Created_Building__c = manualAddressCreate;
            if(!colo.isempty()){
                b.Serving_LSO__c = colo[0].id;  
            }
            
            if(doInsert){
                SecurityUtils.BypassProcesser.saveObjects(new List<Building__c>{ b }, true);
            
                if(colo.isEmpty()){
                    CreateTaskForNoServingLSO(b, loc.LSOCLLI);
                }else{
                   CreateBuildingAccessAvailabilityOfServingLSO(b);
                }                    
            }
            
            return b;
        }
        
        return building;
    }
    
    public static Building__c GetBuildingByHash(String hash){
        List<Building__c> buildings = [Select Id
                                            ,Serving_LSO__c
                                            ,Address__c
                                            ,Building_Hash__c
                                            ,City__c
                                            ,Effective_Date__c
                                            ,House_Number__c
                                            ,Latitude__c
                                            ,Longitude__c
                                            ,Postal_Code__c
                                            ,Zip4__c
                                            ,State__c
                                            ,Country__c
                                            ,Net_Classification__c
                                            ,Status__c
                                            ,MSAG_Address_Format__r.Id
                                            ,MSAG_Address_Format__r.House_Number__c
                                            ,MSAG_Address_Format__r.PreDirectional__c
                                            ,MSAG_Address_Format__r.Street__c
                                            ,MSAG_Address_Format__r.Street_Type__c
                                            ,MSAG_Address_Format__r.PostDirectional__c
                                            ,MSAG_Address_Format__r.City__c
                                            ,Tax_Main_Address_Format__r.Id
                                            ,Tax_Main_Address_Format__r.House_Number__c
                                            ,Tax_Main_Address_Format__r.PreDirectional__c
                                            ,Tax_Main_Address_Format__r.Street__c
                                            ,Tax_Main_Address_Format__r.Street_Type__c
                                            ,Tax_Main_Address_Format__r.PostDirectional__c
                                            ,Tax_Main_Address_Format__r.City__c
                                        From Building__c Where Building_Hash__c = :hash limit 1];
        return buildings != null && buildings.size() == 1 ? buildings[0] : null;
    }
    
    public static Task CreateTaskForNoServingLSO(Building__c b, string wireCenterCLLI){
        Task t = new Task();
        IntegraServiceSettings__c integraServiceSettings = IntegraServiceSettings__c.getInstance();
        User u = [select id from user where ntid__c = :integraServiceSettings.No_Serving_LSO_Task_Owner__c];
        
        t.OwnerId = u.id;
        t.Subject = 'No Serving LSO found for this newly created building';
        t.WhatId = b.id;
        t.Type = 'Research Request';
        t.Description = 'The wirecenterCLLI provided from address master(' + wireCenterCLLI + ') was not found as a serving LSO.';
        
        insert t;
        
        return t;
    }
    
    public static Location__c CreateLocation(Building__c b, integraWS.SFLocationView loc, Boolean doInsert){
        return CreateLocation(b.Id, loc.subPremise, doInsert);
    }
    
    public static Location__c CreateLocation(Id buildingID, String roomSuite, Boolean doInsert){
        if(buildingID == null && doInsert) return null;
        
        List<Location__c> locations = buildingID != null ? [Select Id
                                                            ,Name
                                                            ,Room_Suite__c
                                                            ,Building__r.Id
                                                            ,Building__r.Address__c
                                                            ,Building__r.City__c
                                                            ,Building__r.State__c
                                                            ,Building__r.Postal_Code__c
                                                            ,Building__r.Zip4__c
                                                            ,Building__r.Country__c
                                                            ,Building__r.MSAG_Address_Format__r.Id
                                                            ,Building__r.MSAG_Address_Format__r.House_Number__c
                                                            ,Building__r.MSAG_Address_Format__r.PreDirectional__c
                                                            ,Building__r.MSAG_Address_Format__r.Street__c
                                                            ,Building__r.MSAG_Address_Format__r.Street_Type__c
                                                            ,Building__r.MSAG_Address_Format__r.PostDirectional__c
                                                            ,Building__r.MSAG_Address_Format__r.City__c
                                                            ,Building__r.Tax_Main_Address_Format__r.Id
                                                            ,Building__r.Tax_Main_Address_Format__r.House_Number__c
                                                            ,Building__r.Tax_Main_Address_Format__r.PreDirectional__c
                                                            ,Building__r.Tax_Main_Address_Format__r.Street__c
                                                            ,Building__r.Tax_Main_Address_Format__r.Street_Type__c
                                                            ,Building__r.Tax_Main_Address_Format__r.PostDirectional__c
                                                            ,Building__r.Tax_Main_Address_Format__r.City__c
                                                        From Location__c where Building__r.id = :buildingID and Room_Suite__c = :roomSuite] : new List<Location__c>();
        if(locations.isempty()){
            Location__c l = new Location__c();
            l.building__c = buildingID;
            l.Room_Suite__c = roomSuite;
            
            if(doInsert)
                insert l;
            
            return l;
        }
        
        return locations[0];
    }
    
    public static List<Database.UpsertResult> SaveAddress(Building__c b, Location__c l, Service_Location__c sLoc, Boolean failOnError){
        List<Database.UpsertResult> results = new List<Database.UpsertResult>();
        if(b != null){ for(Database.UpsertResult s : SecurityUtils.BypassProcesser.saveObjects(new List<Building__c>{ b }, failOnError)) results.add(s); }
        if(l != null && b.Id != null){ l.Building__c = b.Id; for(Database.UpsertResult s : SecurityUtils.BypassProcesser.saveObjects(new List<Location__c>{ l }, failOnError)) results.add(s); }
        if(sLoc != null && l.Id != null){ sLoc.Location__c = l.Id; for(Database.UpsertResult s : SecurityUtils.BypassProcesser.saveObjects(new List<Service_Location__c>{ sLoc }, failOnError)) results.add(s); }
        return results;
    }
    
    public static void DisplayErrorMessageFromLocView(integraWS.SFLocationView locView, boolean htmlFormatResponse){
        
        if(htmlFormatResponse)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,string.join(locView.Messages.string_x,'<br />')));
        else
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,string.join(locView.Messages.string_x,',')));
    }
    
    public static void CreateLeadsFromGeoResultsBusinesses(Map<Id, Id> grbIDToOwnerID){
        Map<Id, Georesults_business__c> grMap = new Map<Id, Georesults_business__c>([select Id
                                                                                            ,Building__c
                                                                                            ,CleanBusiness__c
                                                                                            ,Phone__c
                                                                                            ,State__c
                                                                                            ,Unit__c
                                                                                            ,Contact__c
                                                                                        from Georesults_business__c where Id in: grbIDToOwnerID.keyset()
                                                                                        and Building__c != null]);
        
        Set<Id> bldgIDs = new Set<Id>();
        Set<String> rsList = new Set<String>();
        for(Georesults_business__c gr : grMap.values()){
            bldgIDs.add(gr.Building__c);
            if(gr.Unit__c != null) rsList.add(gr.Unit__c);
        }
        
        Map<String, Location__c> locs = new Map<String, Location__c>();
        for(Location__c l : [select Id, Building__c, Room_Suite__c from Location__c where Building__c in: bldgIDs and (Room_Suite__c = null or Room_Suite__c in: rsList)])
            locs.put(l.Building__c + '_' + (!String.isEmpty(l.Room_Suite__c) ? l.Room_Suite__c : ''), l);
        
        List<Location__c> newLocs = new List<Location__c>();
        for(Georesults_business__c gr : grMap.values()){
            String k = gr.Building__c + '_' + (!String.isEmpty(gr.Unit__c) ? gr.Unit__c : '');
            if(locs.get(k) == null){
                Location__c l = new Location__c(Building__c = gr.Building__c, Room_Suite__c = gr.Unit__c);
                locs.put(k, l);
                newLocs.add(l);
            }
        }
        
        if(newLocs.size() > 0) upsert newLocs;
        
        List<Lead> leads = new List<Lead>();
        for(Georesults_business__c gr : grMap.values()){
            String k = gr.Building__c + '_' + (!String.isEmpty(gr.Unit__c) ? gr.Unit__c : '');
            
            Lead l = new Lead(Status = 'Suspect'
                            ,LeadSource = 'Simplified Prospect Management'
                            ,GeoResults_Business__c = gr.Id
                            ,Phone = gr.Phone__c
                            ,Company = gr.CleanBusiness__c
                            ,State = gr.State__c
                            ,Building__c = gr.Building__c
                            ,Location__c = locs.get(k).Id);
            
            Id ownerID = grbIDToOwnerID.get(gr.Id);
            if(ownerID != null) l.OwnerId = ownerID;
            
            String cFirst = '';
            String cLast = '.';
            if(!string.isEmpty(gr.Contact__c)){
                List<String> ca = gr.Contact__c.split(' ');
                for (Integer i = 0; i < ca.size(); i++) {
                    if(i == 0) cFirst = ca[i];
                    else if(i == 1) cLast = ca[i];
                    else cLast = cLast + ' ' + ca[i]; 
                }
            }
            
            l.FirstName = cFirst;
            l.LastName = cLast;
            leads.add(l);
        }
        
        System.debug(leads);
        insert leads;
    }

    public static List<Building_Access_Availability__c> CreateBuildingAccessAvailabilityOfServingLSO(Building__c b){
       List<Building_Access_Availability__c> baas = new List<Building_Access_Availability__c>();

       for(Building_Access_Availability__c servingLSOBaa : [select Name, Access_Technology__c, Access_Technology_Name__c, Available_Bandwidth__c, Minimum_Required_Revenue__c, Status__c, Building__c, Maximum_Bandwidth__c, Minimum_Bandwidth__c, Carrier__c from Building_Access_Availability__c where building__c = :b.Serving_LSO__c and Access_Technology_Name__c in ('EoTDM','DSL PPPOE','TLS ADSL','Dedicated ADSL')]){
          Building_Access_Availability__c baa = new Building_Access_Availability__c();
          baa.Access_Technology__c = servingLSOBaa.Access_Technology__c;
          baa.Name = servingLSOBaa.Name;
          baa.Maximum_Bandwidth__c = (servingLSOBaa.Maximum_Bandwidth__c!= null && servingLSOBaa.Maximum_Bandwidth__c >0 ) ? servingLSOBaa.Maximum_Bandwidth__c : 12;
          baa.Minimum_Bandwidth__c = (servingLSOBaa.Minimum_Bandwidth__c!= null && servingLSOBaa.Minimum_Bandwidth__c >0 ) ? servingLSOBaa.Minimum_Bandwidth__c : 1.5;
          baa.Minimum_Required_Revenue__c = servingLSOBaa.Minimum_Required_Revenue__c;
          baa.Status__c = servingLSOBaa.Status__c;
          baa.building__c = b.Id;
          baa.Carrier__c = servingLSOBaa.Carrier__c;
          baas.add(baa);
       }
       if(baas.size() > 0){
          insert baas;
       }
       return baas;
    }
  
}