/**************************************************************************************************
*    CustomerDetailExtensionController.cls
*
*    Modifications:
*    Developer Name       Date        Brief description
*    -------------------  ----------  ------------------------------------------------------------
*    Eunjung Ju           01/22/2018  SEAL-643 - Changed the retrieving care org logic to sort by reference id field(sorting the list)
**************************************************************************************************/
public with sharing class CustomerDetailExtensionController extends TreeViewController implements TestUtils.ITestableClass {
    
    public Customer_Detail__c customerDetail {get; private set;}
    public Account account {get; private set;}
    public Service_Location__c serviceLocation {get; private set;}
    public Boolean detached {get; private set;}
    
    public Building__c parsedBuilding {get; set;}
    
    public Map<String, List<SelectOption>> selectOptions {get; private set;}
    public Id persistedBillCycle {get; private set;}
    public String persistedBillCycleName {get; private set;}
    
    public List<SelectOption> availableContacts {get; private set;}
    public String selectedContact {get; set;}
    public List<SelectOption> availableContactTypes {get; private set;}
    public List<String> selectedContactTypes {get; set;}
    public Customer_Contact__c newCustomerContact {get; set;}
    public Map<Id, Map<String, List<Customer_Contact__c>>> customerContacts {get; set;}
    public Map<Id, Contact> contacts {get; set;}
    public List<Id> activeContacts {get; set;}
    
    public Customer_Contact__c responsibleParty {get; set;}
    public Map<string, string> textValues {get;set;}
    
    public List<SelectOption> availableSubscriberSettings {get; private set;}
    public String selectedSubSetting {get; set;}
    public Customer_Setting__c newSubSetting {get; set;}
    private Map<String, Boolean> subSettingMap = new Map<String, Boolean>();
    
    public List<SelectOption> availableSubscriberTaxes {get; private set;}
    public String selectedSubTax {get; set;}
    public Customer_Setting__c newSubTax {get; set;}
    private Map<String, Customer_Setting_Reference__c> subTaxMap = new Map<String, Customer_Setting_Reference__c>();
    
    public Map<Id, Customer_Setting__c> customerSettings {get; private set;}
    
    public Map<Id, Market_Area__c> marketAreas {get; private set;}
    
    public Boolean billCycleMismatch {get; private set;}
    public Boolean exchangeNeeded {get; private set;}
    public Boolean parentIsBillable {get; private set;}
    
    public Boolean canDeleteOrClone {get; private set;}
    public Boolean canIntegrate {get; private set;}
    public Boolean canUpdateMarketAreas {get; private set;}
    public Boolean canRelink {get; private set;}
    public Boolean canModifyCareOrg { get; private set;}
    public Boolean canModifyTaxExempt { get; private set;}
    
    public Boolean isCollectionsUser {get; private set;}
    public Boolean isBillingUser {get; private set;}
    public Boolean isCareUser {get; private set;}
    public Boolean isAdmin {get; private set;}
    
    public Boolean contactReadOnlyMode {get; private set;}
    public Boolean settingReadOnlyMode {get; private set;}
    
    public List<Id> subscriberSettings {get; private set;}
    public List<Id> taxInfos {get; private set;}
    
    public Boolean invoiceReadOnlyMode {get; private set;}
    public String invoiceHelpText {get; private set;}
    
    public transient List<String> customErrorMessages {get; private set;}
    public transient List<String> customInfoMessages {get; private set;}
    
    public void addCustomMessage(Boolean isError, String message){
        if(customErrorMessages == null) customErrorMessages = new List<String>();
        if(customInfoMessages == null) customInfoMessages = new List<String>();
        
        List<String> l = isError ? customErrorMessages : customInfoMessages;
        l.add(message);
    }
    
    public String previousCollectionCode {get;set;}
    
    public class LocationAddress {
        public String name {get; set;}
        public String text {get; set;}
        public String id {get; set;}
        public Id locationId {get; set;}
        public Boolean canUpdateToValidatedAddress {get; set;}
        public Boolean locationMode {get; set;}
        public String message {get; set;}
        public String MSAGAddress {get; set;}
        public String TaxMainAddress {get;Set;}
        
        public String street {get; set;}
        public String city {get; set;}
        public String state {get; set;}
        public String postalCode {get; set;}
        public String zip4 {get; set;}
        public String roomSuite {get; set;}
        public String overrideName {get; set;}
        public Boolean overrideNameEnabled {get; set;}
        //MNK added country
        public String country {get; set;}
        
        public LocationAddress(String name, Location__c location, Building_Address_Format__c format, String id){
            this.name = name;
            this.id = id;
            setLocationInformation(location, format);
            canUpdateToValidatedAddress = false;
            overrideNameEnabled = false;
        }

        public LocationAddress(String name, String id, String city, String postalCode, String zip4, String state, String street, String roomSuite, String overrideName, String country){
            this.name = name;
            this.id = id;
            setAddressInformation(city, postalCode, zip4, state, street, roomSuite, overrideName, country);
            canUpdateToValidatedAddress = false;
            overrideNameEnabled = true;
            locationId = null;
        }        
        /*
        public LocationAddress(String name, String id, String city, String postalCode, String zip4, String state, String street, String roomSuite, String overrideName){
            this.name = name;
            this.id = id;
            setAddressInformation(city, postalCode, zip4, state, street, roomSuite, overrideName);
            canUpdateToValidatedAddress = false;
            overrideNameEnabled = true;
            locationId = null;
        }
        */
        public void setLocationInformation(Location__c location, Building_Address_Format__c format){
            if(location != null){
                setAddressInformation(
                    location.Building__c != null ? location.Building__r.City__c : null
                    ,location.Building__c != null ? location.Building__r.Postal_Code__c : null
                    ,location.Building__c != null ? location.Building__r.Zip4__c : null
                    ,location.Building__c != null ? location.Building__r.State__c : null
                    ,location.Building__c != null ? location.Building__r.Address__c : null
                    ,location.Building__c != null ? location.Room_Suite__c : null
                    ,null
                    ,location.Building__c != null ? location.Building__r.Country__c : null
                );
                
                MSAGAddress = format != null
                                ? string.join(new List<String>{format.House_Number__c
                                                                ,format.PreDirectional__c
                                                                ,format.PostDirectional__c
                                                                ,format.Street__c
                                                                ,format.City__c}, ' ')
                                : null;
                TaxMainAddress = format != null
                                ? string.join(new List<String>{format.House_Number__c
                                                                ,format.PreDirectional__c
                                                                ,format.Street__c
                                                                ,format.Street_Type__c
                                                                ,format.PostDirectional__c
                                                                ,format.City__c}, ' ')
                                : null;
                                
                locationId = location.Id;
            }
            else{
                street = city = state = postalCode = zip4 = roomSuite = null;
                locationId = null;
            }
            locationMode = true;
        }
        
        public void setAddressInformation(String city, String postalCode, String zip4, String state, String street, String roomSuite, String overrideName){
            this.city = city;
            this.postalCode = postalCode;
            this.zip4 = zip4;
            this.state = state;
            this.street = street;
            this.roomSuite = roomSuite;
            this.overrideName = overrideName;
              
            locationMode = false;
        }
        
        public void setAddressInformation(String city, String postalCode, String zip4, String state, String street, String roomSuite, String overrideName, String country){
            this.city = city;
            this.postalCode = postalCode;
            this.zip4 = zip4;
            this.state = state;
            this.street = street;
            this.country = country;
            this.roomSuite = roomSuite;
            this.overrideName = overrideName;
            locationMode = false;
        }
        
        public Boolean isValid(){
            return !string.IsEmpty(city) && !string.IsEmpty(postalCode) && !string.IsEmpty(state) && !string.IsEmpty(street) && !string.IsEmpty(country);
        }
    }
    
    public class AddressFormat {
        public LocationAddress location {get; set;}
        public Building_Address_Format__c format {get; set;}
        public Boolean validated {get; set;}
        public String error {get; set;}
        public Integer typeId {get;Set;}
        
        public AddressFormat(LocationAddress location, Building_Address_Format__c format, Integer typeId, Boolean validated){
            this.location = location;
            this.format = format;
            this.typeId = typeId;
            this.validated = validated == null ? false : validated;
        }
    }
    
    public List<LocationAddress> addresses {get; private set;}
    public List<AddressFormat> addressFormats {get; private set;}
    public integraWS.SFOverriddenAddresses SFOverriddenAddresses {get;Set;}
    
    public CustomerDetailExtensionController(Apexpages.StandardController sc) {
        textValues = new Map<string, string>();
        customerDetail = (Customer_Detail__c)sc.getRecord();

        if(customerDetail != null){
            load();
            textValues.put('disputedAmount', String.valueOf(customerDetail.Disputed_Amount__c));
            persistedBillCycle = customerDetail.Bill_Cycle__c;
            Profile p = [select Name from Profile where Id =: UserInfo.getProfileId()];
            isAdmin = canRelink = canDeleteOrClone = p.Name == 'System Administrator';
            canIntegrate = String.isEmpty(customerDetail.ICC_Subscriber_ID__c) && (isAdmin || CustomSettingUtils.currentUserHasCustomPermission('Can_Create_Hierarchy__c'));
            
            Boolean customerNotPastPreactive = String.isEmpty(customerDetail.ICC_Subscriber_ID__c) || String.isEmpty(customerDetail.Integration_Status__c) || customerDetail.Integration_Status__c == 'Pre-Active' || customerDetail.INtegration_Status__c == 'Draft';
            canModifyCareOrg = true;
            if(CustomSettingUtils.getOverrideSettingValue('CareOrg Permissions'))
                canModifyCareOrg =  (Customer_Detail__c.Care_Organization__c.getDescribe().isUpdateable() && !String.isEmpty(customerDetail.ICC_Subscriber_ID__c)) || String.isEmpty(customerDetail.ICC_Subscriber_ID__c);
            canUpdateMarketAreas = isAdmin || customerNotPastPreactive;
            
            isCollectionsUser = CustomSettingUtils.currentUserHasCustomPermission('Can_Do_Collections_Options__c');
            isBillingUser = CustomSettingUtils.currentUserHasCustomPermission('Can_Do_Billing_Options__c');
            isCareUser = CustomSettingUtils.currentUserHasCustomPermission('Can_Do_Care_Options__c');
            canModifyTaxExempt = CustomSettingUtils.currentUserHasCustomPermission('Can_Do_Tax_Exempt_Options__c');
            
            Schema.Describesobjectresult r = Customer_Contact__c.getSObjectType().getDescribe();
            contactReadOnlyMode = !r.isUpdateable();
            User u = [Select Country from User where Id =: UserInfo.getUserId()];
            invoiceHelpText = '';
            invoiceReadOnlyMode = false;  
            if (customerDetail.Data_Sovereignty_Requirements__c == 'Yes - Canada'){
                if(u.Country.equalsIgnoreCase('CA') || u.Country.equalsIgnoreCase('CAN') || u.Country.equalsIgnoreCase('Canada')){
                    invoiceReadOnlyMode = false;
                } else{
                    invoiceReadOnlyMode = true;
                    invoiceHelpText = 'Invoice is not available due to data sovereignty requirements.';
                }
            }
            else if (customerDetail.Data_Sovereignty_Requirements__c == 'Yes - US'){
                if(u.Country.equalsIgnoreCase('US') || u.Country.equalsIgnoreCase('USA') || u.Country.equalsIgnoreCase('United States')){
                    invoiceReadOnlyMode = false;
                } else{
                    invoiceReadOnlyMode = true;
                    invoiceHelpText = 'Invoice is not available due to data sovereignty requirements.';
                }    
            }
            
            r = Customer_Setting__c.getSObjectType().getDescribe();
            settingReadOnlyMode = !r.isUpdateable() || !SecurityUtils.currentUserHasRecordAccess(customerDetail.Id, true);
            
            if(String.isEmpty(previousCollectionCode))
                previousCollectionCode = customerDetail.Collection_Code__c;
            
            init();
        }
    }
    
    private void save(){
        SecurityUtils.BypassProcesser.saveObjects(new List<Customer_Detail__c>{customerDetail}, true);
        load();     //reload to get anything the trigger updated
    }
    
    private void load(){
        customerDetail = ((List<Customer_Detail__c>)ApexUtils.retrieveFullObjects(Customer_Detail__c.getsObjectType(), 'Id=\'' + customerDetail.Id + '\''))[0];
    }
    
    public Boolean systemAccountParent { get; set; }
    private void init() {
        addresses = new List<LocationAddress>();
        SFOverriddenAddresses = new integraWS.SFOverriddenAddresses();
        systemAccountParent = true;
        for(Customer_Detail__c c : (List<Customer_Detail__c>)(ApexUtils.retrieveObjectsFromFieldSets(
                                                                Customer_Detail__c.getsObjectType()
                                                                ,new List<Set<String>>{
                                                                    AddressUtils.CustomerDetailAddressFieldSet
                                                                    ,new Set<String>{'Billable__c'
                                                                                    ,'Integration_Status__c'
                                                                                    ,'Parent_Account__c'
                                                                                    ,'Parent_Account__r.RecordType.DeveloperName'
                                                                                    ,'Parent_Customer__r.Billable__c'
                                                                                    ,'Parent_Customer__r.Name'
                                                                                    ,'Root_Customer_ID__c'
                                                                                    ,'(select Id, Name, RecordType.DeveloperName, Default_NAA_Exempt__c from Accounts__r)'
                                                                                    ,'(select Id, Name from Service_Locations__r)'}
                                                                    }
                                                                ,'Id = \'' + customerDetail.Id + '\''
                                                                ,null))){
            systemAccountParent = (c.Parent_Account__r.RecordType.DeveloperName == 'System');
            contactReadOnlyMode |= systemAccountParent;
            parentIsBillable = c.Parent_Customer__c != null && c.Parent_Customer__r.Billable__c;
            
            detached = c.Accounts__r.size() == 0 && c.Service_Locations__r.size() == 0;
            exchangeNeeded = c.Market_Area__c != null && string.valueOf(c.Market_Area__r.ICCMarketAreaID__c) == ICCWrapper.PriorLakeMarketAreaID;
            for(Account a : c.Accounts__r)
                account = a;
            for(Service_Location__c sLoc : c.Service_Locations__r)
                serviceLocation = sLoc;
            
            addresses.add(new LocationAddress('Customer Main Address (MSAG)'
                                            ,c.Customer_Main_Address__r
                                            ,c.Customer_Main_Address__r != null && c.Customer_Main_Address__r.Building__r != null
                                                ? c.Customer_Main_Address__r.Building__r.MSAG_Address_Format__r
                                                : null
                                            ,'Customer_Main_Address__c'));
            addresses.add(new LocationAddress('Tax Main Address', c.Tax_Main_Address__r, null, 'Tax_Main_Address__c'));
            if(c.Billable__c || !string.isEmpty(c.Billing_Main_City__c)){
                addresses.add(new LocationAddress('Billing Main Address', 'Billing_Main'
                                                ,c.Billing_Main_City__c
                                                ,c.Billing_Main_Postal_Code__c
                                                ,null
                                                ,c.Billing_Main_State__c
                                                ,c.Billing_Main_Street__c
                                                ,c.Billing_Main_Room_Suite__c
                                                ,c.Billing_Main_Name__c
                                                ,c.Billing_Main_Country__c));
            }
            if((c.Billable__c && (c.Integration_Status__c == 'Active' || c.Integration_Status__c == 'Inactive')) || !string.isEmpty(c.Billing_Final_City__c)){
                addresses.add(new LocationAddress('Final Billing Address', 'Billing_Final'
                                                ,c.Billing_Final_City__c
                                                ,c.Billing_Final_Postal_Code__c
                                                ,null
                                                ,c.Billing_Final_State__c
                                                ,c.Billing_Final_Street__c
                                                ,c.Billing_Final_Room_Suite__c
                                                ,c.Billing_Final_Name__c
                                                ,c.Billing_Final_Country__c));
            }
            addresses.add(new LocationAddress('Service Address', c.Service_Address__r, null, 'Service_Address__c'));
            
            Id treeViewID = null;
            if(!systemAccountParent) treeViewID = c.Parent_Account__c;
            else if(c.Root_Customer_ID__c != 'ERROR') treeViewID = c.Root_Customer_ID__c;
            
            if(treeViewID != null) TreeViewsByDivID = new Map<String, TreeViewImplementation>{'hierarchy'=>new CustomerHierarchyController.TreeViewImplementation(treeViewID)};
        }
        
        getCustomerContacts();
        
        if(responsibleParty == null || responsibleParty.Id == null){
            responsibleParty = new Customer_Contact__c(Customer_Detail__c = customerDetail.Id, Contact_Type__c = ICCWrapper.ResonsiblePartyContactType);
            ApexPages.addMessage(new APexPages.Message(ApexPages.Severity.Warning, 'There is no responsible party contact associated with this customer.'));
        }
        
        availableContactTypes = new List<SelectOption>();
        for(Schema.PicklistEntry ple : Customer_Contact__c.Contact_Type__c.getDescribe().getPicklistValues()){
            if(ple.getLabel() != ICCWrapper.ResonsiblePartyContactType)
                availableContactTypes.add(new SelectOption(ple.getLabel(), ple.getValue()));
        }
        
        Set<String> ddFieldSet = new Set<String>{'Bill_Cycle_Schedule', 'Care_Organization', 'Collection_Code', 'Exchange', 'Market_Type', 'Market_Subtype', 'Reporting_Company'};
        selectOptions = new Map<String, List<SelectOption>>();
        for(String str : ddFieldSet)
            selectOptions.put(str, new List<SelectOption>{new SelectOption('', '')});
        
        Map<Id, RecordType> rts = new Map<Id, RecordType>([select Id, DeveloperName from RecordType where sObjectType = 'Customer_Setting__c' and (DeveloperName in ('Subscriber_Setting', 'Tax_Information') or DeveloperName in : ddFieldSet)]);
        
        subscriberSettings = new List<Id>();
        taxInfos = new List<Id>();
        
        marketAreas = new Map<Id, Market_Area__c>();
        customerSettings = new Map<Id, Customer_Setting__c>();
        for(Customer_Setting__c s : (List<Customer_Setting__c>)ApexUtils.retrieveFullObjects(Customer_Setting__c.getsObjectType(), 'RecordTypeId in (\'' + string.join(new List<Id>(rts.keyset()), '\',\'') + '\') and (RecordType.DeveloperName not in (\'Subscriber_Setting\', \'Tax_Information\',\'Care_Organization\') or Customer_Detail__c = \'' + customerDetail.Id + '\')', 'Name, Start_Date__c nulls first')){
            RecordType rt = rts.get(s.RecordTypeId);
            
            if(ddFieldSet.contains(rt.DeveloperName)){
                selectOptions.get(rt.DeveloperName).add(new SelectOption(s.Id, s.Name));
                if(rt.DeveloperName == 'Bill_Cycle_Schedule' && s.Market_Area__c != null){
                    marketAreas.put(s.Market_Area__c, null);
                }
            }
            else if(rt.DeveloperName == 'Subscriber_Setting'){
                subscriberSettings.add(s.Id);
                subSettingMap.put(s.Reference_ID__c, true);
            }
            else if(rt.DeveloperName == 'Tax_Information')
                taxInfos.add(s.Id);
            customerSettings.put(s.Id, s);
        }
        //sorted list of care org
        for(Customer_Setting__c s : (List<Customer_Setting__c>)ApexUtils.retrieveFullObjects(Customer_Setting__c.getsObjectType(), 'RecordTypeId in (\'' + string.join(new List<Id>(rts.keyset()), '\',\'') + '\') and (RecordType.DeveloperName in (\'Care_Organization\') or Customer_Detail__c = \'' + customerDetail.Id + '\') and (REFERENCE_ID__C != null or REFERENCE_ID__C !=\'\')' , 'REFERENCE_ID__C nulls last, Name')){
            RecordType rt = rts.get(s.RecordTypeId);
            
            if(rt.DeveloperName == 'Care_Organization'){
                selectOptions.get(rt.DeveloperName).add(new SelectOption(s.Id, s.Name));                
            }
            customerSettings.put(s.Id, s);
        }
        
        selectOptions.put('Market_Area', new List<SelectOption>{new SelectOption('', '')});
        for(Market_Area__c ma : [select Id, Name, ICCMarketAreaID__c, ProvMarketAreaID__c from Market_Area__c order by Name]){
            marketAreas.put(ma.Id, ma);
            selectOptions.get('Market_Area').add(new SelectOption(ma.Id, ma.Name));
        }
        
        updateMarketAreaBasedSelections(false);
        
        availableSubscriberSettings = new List<SelectOption>();
        availableSubscriberTaxes = new List<SelectOption>();

        for(RecordType rt : rts.values()){
            if(rt.DeveloperName == 'Subscriber_Setting')
                newSubSetting = new Customer_Setting__c(RecordTypeId = rt.Id);
            else if(rt.DeveloperName == 'Tax_Information')
                newSubTax = new Customer_Setting__c(RecordTypeId = rt.Id);
        }
        
        updateCustomerSettingReferences();
        //updateOtherCustomerDetailList();
        
    }
    
    public /*transient*/ string jsonContactEmails { get; set; }
    public /*transient*/ string jsonContactPhoneNumbers { get; set; }
    private void getCustomerContacts(){
        availableContacts = new List<SelectOption>{new SelectOption('', '')};
        newCustomerContact = new Customer_Contact__c();
        customerContacts = new Map<Id, Map<String, List<Customer_Contact__c>>>();
        contacts = new Map<Id, Contact>();
        activeContacts = new List<Id>();
        
        Set<Id> partnerAccountIDs = new Set<Id>();
        if(!systemAccountParent){
            for(Account_Partner__c ap : [select Account__c, Partner__c from Account_Partner__c where Account__c =: customerDetail.Parent_Account__c]){
                partnerAccountIDs.add(ap.Partner__c);
            }
        }
        
        for(Customer_Contact__c cc : [select Contact__c from Customer_Contact__c where Customer_Detail__c =: customerDetail.Id])
            contacts.put(cc.Contact__c, null);
        
        Map<Id, List<String>> contactEmails = new Map<Id, List<String>>();
        Map<Id, List<String>> contactPhoneNumbers = new Map<Id, List<String>>();
        Set<Id> contactIDs = contacts.keySet();
        for(Contact c : (List<Contact>)Database.query('select Id'
                                                        + ',Name'
                                                        + ',Email'
                                                        + ',Phone'
                                                        + ',AssistantPhone'
                                                        + ',HomePhone'
                                                        + ',MobilePhone'
                                                        + ',OtherPhone'
                                                        + ',Additional_Email_Addresses__c'
                                                        + ',Additional_Phone_Numbers__c'
                                                        + ',(select Id'
                                                                + ',Contact__c'
                                                                + ',Contact_Type__c'
                                                                + ',ICC_Contact_ID__c'
                                                                + ',Email__c'
                                                                + ',Phone__c'
                                                                + ',CreatedDate'
                                                                + ' from Customer_Contacts__r'
                                                                + ' where Customer_Detail__c = \'' + customerDetail.Id + '\''
                                                                + ' order by Contact_Type__c, ICC_COntact_ID__c nulls first)'
                                                        + ' from Contact'
                                                        + ' where Id in: contactIDs'
                                                            + (systemAccountParent ? '' : (' or AccountId = \'' + customerDetail.Parent_Account__c + '\''))
                                                            + (partnerAccountIDs.size() > 0 ? ' or AccountId in: partnerAccountIDs' : '')
                                                        + ' order by LastName, FirstName, Phone nulls first limit 999')){
            Boolean contactListNotFull = true;
            contacts.put(c.Id, c);
            //if(!contactReadOnlyMode)
            availableContacts.add(new SelectOption(c.Id, c.Name));
            
            contactEmails.put(c.Id, c.Email != null ? new List<String>{ c.Email } : new List<String>());
            for(String line : c.Additional_Email_Addresses__c != null ? c.Additional_Email_Addresses__c.split('\n') : new List<String>()){
                if(line.Contains('\t')) contactEmails.get(c.Id).add(line.split('\t')[1]);
            }
            
            Set<String> pNums = new Set<String>();
            for(String s : new List<String>{ c.Phone, c.AssistantPhone, c.HomePhone, c.MobilePhone, c.OtherPhone }){
                if(!String.isEmpty(s)) pNums.add(s);
            }
            
            contactPhoneNumbers.put(c.Id, new List<String>(pNums));
            for(String line : c.Additional_Phone_Numbers__c != null ? c.Additional_Phone_Numbers__c.split('\n') : new List<String>()){
                if(line.Contains('\t')) contactPhoneNumbers.get(c.Id).add(line.split('\t')[1]);
            }
            
            if(c.Customer_Contacts__r != null && c.Customer_Contacts__r.size() > 0){                
                Map<String, List<Customer_Contact__c>> modMap = new Map<String, List<Customer_Contact__c>>();
                for(Customer_Contact__c cc : c.Customer_Contacts__r){
                    if(cc.Contact_Type__c == ICCWrapper.ResonsiblePartyContactType && (responsibleParty == null || responsibleParty.CreatedDate > cc.CreatedDate))
                        responsibleParty = cc;
                    else{
                        String mod = getCustomerContactModifier(cc);
                        
                        List<Customer_Contact__c> ccs = modMap.get(mod);
                        if(ccs == null)
                            ccs = new List<Customer_Contact__c>();
                        
                        ccs.add(cc);
                        modMap.put(mod, ccs);
                    }
                }
                if(modMap.size() > 0 && contactListNotFull){
                    if(activeContacts.size() < 1000){
                        activeContacts.add(c.Id);
                        customerContacts.put(c.Id, modMap);
                    }
                    else{
                        contactListNotFull = false;
                        ApexPages.addMessage(new APexPages.Message(ApexPages.Severity.Warning, 'Limit of 1000 contacts reached.'));
                    }
                }
            }
        }
        
        jsonContactEmails = JSON.serialize(contactEmails);
        jsonContactPhoneNumbers = JSON.serialize(contactPhoneNumbers);
    }
    
    /*public String otherCustomerDetailFilter { get; set; }
    public transient List<Customer_Detail__c> otherCustomerDetailList { get; set; }
    public void updateOtherCustomerDetailList(){
        otherCustomerDetailList = (List<Customer_Detail__c>)Database.query('select Id'
                                        + ',Name'
                                        + ',ICC_Subscriber_ID__c'
                                        + ',Parent_Customer__c'
                                        + ',Parent_Customer__r.Name'
                                        + ',Parent_Customer__r.ICC_Subscriber_ID__c'
                                    + ' from Customer_Detail__c'
                                    + (' where Parent_Account__c = \'' + customerDetail.Parent_Account__c + '\' and Id != \'' + customerDetail.Id + '\'')
                                    + (!String.isEmpty(otherCustomerDetailFilter) ? (' and Name like \'%' + otherCustomerDetailFilter + '%\'') : '')
                                    + ' order by Parent_Customer__r.Parent_Customer__r.ICC_Subscriber_ID__c, Parent_Customer__r.ICC_Subscriber_ID__c, ICC_Subscriber_ID__c, Parent_Customer__c, Id'
                                    + ' limit 1000');
    }*/
    
    private void updateCustomerSettingReferences(){
        availableSubscriberSettings.clear();
        availableSubscriberTaxes.clear();
        
        availableSubscriberSettings.add(new SelectOption('', ''));
        availableSubscriberTaxes.add(new SelectOption('', ''));
        Set<String> subSettingsToDisplay = new Set<String>();
        Set<String> existingTaxInfos = getExistingTaxInfos(new List<String>{ customerDetail.Id }).get(customerDetail.Id);
        for(Customer_Setting_Reference__c s : [select Category__c, Description__c, ID__c, Flags__c from Customer_Setting_Reference__c where Category__c in ('SubscriberSetting', 'SubscriberTax') and Inactive__c = false order by Description__c]){
            if(s.Category__c == 'SubscriberSetting'){
                List<String> flags = s.Flags__c != null ? s.Flags__c.split(',') : new List<String>();
                if(subSettingMap.get(s.ID__c) != true){
                    availableSubscriberSettings.add(new SelectOption(s.ID__c, s.Description__c));
                    subSettingMap.put(s.ID__c, false);
                }
                else if(flags.size() == 3 && flags.get(0) == '1'){
                    subSettingsToDisplay.add(s.Description__c);
                }
            }
            else{
                if((existingTaxInfos == null || !existingTaxInfos.contains(s.ID__c)) && (s.Flags__c != 'Billing Only' || isBillingUser || isAdmin))
                    availableSubscriberTaxes.add(new SelectOption(s.ID__c, s.Description__c));
                subTaxMap.put(s.ID__c, s);
            }
        }
        
        if(subSettingsToDisplay.size() > 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Subscriber settings: ' + ' \'' + string.join(new List<string>(subSettingsToDisplay), '\', \'')  + '\' set on this customer.'));
        }
    }
    
    public PageReference linkToObject(){
        String linkID = Apexpages.currentPage().getParameters().get('linkID');
        
        Boolean relinked = false;
        if(!string.IsEmpty(linkID)){
            List<Account> accounts = [select Id from Account where Id =: linkID];
            if(accounts.size() > 0 && (account == null || account.Id != accounts[0].Id)){
                accounts[0].Customer_Detail__c = customerDetail.Id;
                if(account != null){
                    account.Customer_Detail__c = null;
                    accounts.add(account);
                }
                update accounts;
                relinked = true;
            }
            
            List<Service_Location__c> sLocs = [select Id from Service_Location__c where Id =: linkID];
            if(sLocs.size() > 0 && (serviceLocation == null || serviceLocation.Id != sLocs[0].Id)){
                sLocs[0].Customer_Detail__c = customerDetail.Id;
                if(serviceLocation != null){
                    serviceLocation.Customer_Detail__c = null;
                    sLocs.add(serviceLocation);
                }
                update sLocs;
                relinked = true;
            }
        }
        
        addCustomMessage(false, relinked ? ('Linked to: ' + linkID) : 'Could not relink to: ' + linkID);
        return null;
    }
    
    public PageReference marketAreaUpdated(){
        updateMarketAreaBasedSelections(true);
        return null;
    }
    
    private void updateMarketAreaBasedSelections(Boolean isUpdate){
        String marketAreaName = customerDetail.Market_Area__c != null ? marketAreas.get(customerDetail.Market_Area__c).Name : null;
        
        String configVal = CustomSettingUtils.getSingleProcessConfigurationValue('ValidMarketTypes', marketAreaName, true);
        Set<String> validMarketTypes = !string.IsEmpty(configVal) ? new Set<String>(configVal.split(',')) : null;
        configVal = CustomSettingUtils.getSingleProcessConfigurationValue('ValidProvMarketAreas', marketAreaName, true);
        List<String> sortedValidMarketAreas = !string.IsEmpty(configVal) ? configVal.split(',') : null;
        Set<String> validProvMarketAreas = sortedValidMarketAreas != null ? new Set<String>(sortedValidMarketAreas) : null;
        configVal = CustomSettingUtils.getSingleProcessConfigurationValue('InvalidProvMarketAreas', marketAreaName, true);
        Set<String> invalidProvMarketAreas = !string.IsEmpty(configVal) ? new Set<String>(configVal.split(',')) : new Set<String>();
        
        selectOptions.put('Prov_Market_Area', new List<SelectOption>{new SelectOption('', '')});
        for(Market_Area__c ma : marketAreas.values()){
            if(!string.IsEmpty(ma.ProvMarketAreaID__c) && (validProvMarketAreas == null || validProvMarketAreas.contains(ma.Name)) && (ma.Name == marketAreaName || !invalidProvMarketAreas.contains(ma.Name)))
                selectOptions.get('Prov_Market_Area').add(new SelectOption(ma.Id, ma.Name));
            if(isUpdate && ((sortedValidMarketAreas == null && ma.Name == marketAreaName) || (sortedValidMarketAreas != null && sortedValidMarketAreas.get(0) == ma.Name)))
                customerDetail.Prov_Market_Area__c = ma.Id;
        }
        
        if(selectOptions.get('Prov_Market_Area').size() == 2 && (isUpdate || selectOptions.get('Prov_Market_Area')[1].getValue() == customerDetail.Prov_Market_Area__c)){
            selectOptions.get('Prov_Market_Area').remove(0);
            customerDetail.Prov_Market_Area__c = selectOptions.get('Prov_Market_Area')[0].getValue();
        }
        selectOptions.get('Prov_Market_Area').sort();
        
        RecordType rt = [select Id, DeveloperName from RecordType where sObjectType = 'Customer_Setting__c' and DeveloperName = 'Market_Type'];
        selectOptions.put('Market_Type', new List<SelectOption>{new SelectOption('', '')});
        for(Customer_Setting__c s : customerSettings.values()){
            if(s.RecordTypeId == rt.Id && (validMarketTypes == null || validMarketTypes.contains(s.Name)))
                selectOptions.get('Market_Type').add(new SelectOption(s.Id, s.Name));
        }
        selectOptions.get('Market_Type').sort();
        
        updateBillCycleSelectOptions(isUpdate);
    }
    
    public PageReference marketTypeUpdated(){
        updateBillCycleSelectOptions(true);
        return null;
    }
    
    public void updateBillCycleSelectOptions(Boolean isUpdate){
        if(!parentIsBillable){
            RecordType rt = [select Id, DeveloperName from RecordType where sObjectType = 'Customer_Setting__c' and DeveloperName = 'Bill_Cycle_Schedule'];
            Market_Area__c maNational = [select id from Market_Area__c where Name = 'National' Limit 1];
            
            Boolean resetBillCycle = billCycleMismatch = true;
            selectOptions.put('Bill_Cycle_Schedule', new List<SelectOption>());
            Boolean userCanDoBillingOptions = isAdmin || CustomSettingUtils.currentUserHasCustomPermission('Can_Do_Billing_Options__c');
            for(Customer_Setting__c s : customerSettings.values()){
                if(s.Id == persistedBillCycle)
                    persistedBillCycleName = s.Name;
                if(s.RecordTypeId == rt.Id && 
                        ((s.Id == persistedBillCycle && !isUpdate)
                            || (s.Market_Area__c == maNational.id && s.Market_Type__c != null && customerDetail.Acquired_Company_Biller__c != null && customerDetail.Accounts_Receivable_System__c != null && s.Market_Area__c == customerDetail.Market_Area__c && s.Description__c != null && s.Market_Type__c == customerDetail.Market_Type__c && s.Description__c.indexOf(customerDetail.Acquired_Company_Biller__c + '-' + customerDetail.Accounts_Receivable_System__c) > -1)
                            || (s.Market_Area__c != null && s.Market_Area__c != maNational.id && s.Market_Type__c != null && s.Market_Area__c == customerDetail.Market_Area__c && s.Market_Type__c == customerDetail.Market_Type__c)
                            || (s.Market_Area__c == null && s.Market_Type__c == null && userCanDoBillingOptions))){
                    selectOptions.get(rt.DeveloperName).add(new SelectOption(s.Id, s.Name));

                    if(s.Id == persistedBillCycle){
                        billCycleMismatch = resetBillCycle = false;
                        customerDetail.Bill_Cycle__c = s.Id;
                    }
                }
            }
            selectOptions.get(rt.DeveloperName).sort();
            if(resetBillCycle){
                //todo: fix?
                if(selectOptions.get(rt.DeveloperName).size() == 2){
                    selectOptions.get(rt.DeveloperName).add(0, new SelectOption('', ''));
                    customerDetail.Bill_Cycle__c = selectOptions.get(rt.DeveloperName)[1].getValue();
                }
                else{
                    selectOptions.get(rt.DeveloperName).add(new SelectOption('', ''));
                    customerDetail.Bill_Cycle__c = null;
                    /*if(selectOptions.get(rt.DeveloperName).size() > 0)
                        selectOptions.get(rt.DeveloperName).add(0, new SelectOption('', ''));*/
                }
                selectOptions.get(rt.DeveloperName).sort();
            }
        }
    }
    
    public PageReference doSave(){
        try{
            customerDetail.Disputed_Amount__c = Decimal.valueOf(textValues.get('disputedAmount'));
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, textValues.get('disputedAmount') + ' is not a valid number'));
            textValues.put('disputedAmount', String.valueOf(customerDetail.Disputed_Amount__c));
            return null;
        }
        Boolean validCollectionCode = ValidateCollectionCOde();
        if(!validCollectionCode)
            return null;
        save();
        addCustomMessage(false, 'Details saved.');
        return null;
    }
    
    private Boolean ValidateCollectionCode(){
        Boolean isValid = true;
        if(previousCollectionCode != string.valueOf(customerDetail.Collection_Code__c)) {          
            String pCCodeText = '';
            String cCodeText = '';
            for(Customer_Setting__c cs : [select id, name from Customer_Setting__c where id = :previousCollectionCode or Id = :customerDetail.Collection_Code__c]){
                if(String.isEmpty(pCCodeText) || String.isEmpty(CCodeText)){
                    if(string.valueOf(cs.Id) == previousCollectionCode)
                        pCCodeText = cs.Name;
                    if(string.valueOf(cs.Id) == customerDetail.Collection_Code__c)
                        cCodeText = cs.Name;
                }
                else
                    break;
            }
            if(cCodeText.startsWith('AID') || cCodeText.startsWith('ORG') || cCodeText.startsWith('BIL')){
                if(customerDetail.Disputed_Amount__c <= 0.0){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You need to provide a disputed ammount.'));
                    isValid = false;
                }
                if(cCodeText.startsWith('AID') && customerDetail.User_Into_Dispute__c == null){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You need to provide User who put into dispute.'));
                    isValid = false;
                }                
            }
            else {
                if(customerDetail.Disputed_Amount__c > 0.0){
                    customerDetail.Disputed_Amount__c = 0.0;
                    textValues.put('disputedAmount', '0.0');
                    addCustomMessage(false, 'Disputed Amount reset to $0.00');
                }
            }
            if(isValid){
                if(cCodeText.startsWith('AID')){
                   customerDetail.Date_in_AID__c = Date.Today();
                }else if(pCCodeText.startsWith('AID')&&customerDetail.Date_in_AID__c!= null){
                    customerDetail.Date_in_AID__c = null;
                } 
            }
            
            if(isValid && customerDetail.ICC_Subscriber_ID__c != null){
                String remark = 'Collection Code changed from: ' + pCCodeText + ' To: ' + cCodeText + ' By: ' + UserInfo.getName() + ' On: ' + Datetime.now();
                AddNote(customerDetail.ICC_Subscriber_ID__c, remark);
                previousCollectionCode = customerDetail.Collection_Code__c;
            }
        }
        return isValid;
    }
    
    private void saveCustomerContacts(List<Customer_Contact__c> ccs, String customMessage){
        Boolean success = false;
        List<String> errors = new List<String>();
        for(Database.UpsertResult result : Database.Upsert(ccs, false)){
            success = success || result.isSuccess();
            for(Database.Error err : result.getErrors())
                errors.add(err.getMessage());
        }
        
        if(success)
            addCustomMessage(false, customMessage == null ? 'Contacts updated' : customMessage);
        if(errors.size() > 0)
            addCustomMessage(true, string.join(errors, '\n'));
    }
    
    public PageReference updateResponsibleParty(){
        if(responsibleParty != null && responsibleParty.Contact__c != null)
            saveCustomerContacts(new List<Customer_Contact__c>{responsibleParty}, 'Responsible Party updated');
        
        return null;
    }
    
    public PageReference createNewCustomerContact(){
        if(!string.IsEmpty(selectedContact) && selectedContactTypes != null && selectedContactTypes.size() > 0){
            List<Customer_Contact__c> newCustomerContacts = new List<Customer_Contact__c>();
            
            Map<String, Set<String>> existingTypes = new Map<String, Set<String>>();
            Map<String, List<Customer_Contact__c>> ccs = customerContacts.get(selectedContact);
            if(ccs != null){
                for(String mod : ccs.keyset()){
                    Set<String> modSet = new Set<String>();
                    for(Customer_Contact__c cc : ccs.get(mod))
                        modSet.add(cc.Contact_Type__c);
                    existingTypes.put(mod, modSet);
                }
            }
            else{
                ccs = new Map<String, List<Customer_Contact__c>>();
                customerContacts.put(selectedContact, ccs);
                activeContacts.add(selectedContact);
            }
            
            for(String t : selectedContactTypes){
                Customer_Contact__c cc = new Customer_Contact__c(Customer_Detail__c = customerDetail.Id
                                                                ,Contact__c = selectedContact
                                                                ,Email__c = newCustomerContact.Email__c
                                                                ,Phone__c = newCustomerContact.Phone__c
                                                                ,Contact_Type__c = t);
                String mod = getCustomerContactModifier(cc);
                if(existingTypes.get(mod) == null || !existingTypes.get(mod).contains(t)){
                    newCustomerContacts.add(cc);
                    List<Customer_Contact__c> l = ccs.get(mod) != null ? ccs.get(mod) : new List<Customer_Contact__c>();
                    l.add(cc);
                    ccs.put(mod, l);
                }
            }
            
            saveCustomerContacts(newCustomerContacts, null);
            newCustomerContact = new Customer_Contact__c();
        }
        
        return null;
    }
    
    public PageReference removeRoles(){
        String roleIDs = Apexpages.currentPage().getParameters().get('roleIDs');
        List<Customer_Contact__c> tContacts = roleIDs != null ? [select Id from Customer_Contact__c where Id in :roleIDs.split(',')] : new List<Customer_Contact__c>();
        
        if(tContacts.size() > 0){
            Database.Delete(tContacts, false);
            getCustomerContacts();
        }
        
        return null;
    }
    
    public PageReference updateRoles(){
        String roleIDs = Apexpages.currentPage().getParameters().get('roleIDs');
        List<Customer_Contact__c> tContacts = roleIDs != null ? [select Id from Customer_Contact__c where Id in :roleIDs.split(',')] : new List<Customer_Contact__c>();
        for(Customer_Contact__c cc : tContacts){
            cc.Email__c = newCustomerContact.Email__c;
            cc.Phone__c = newCustomerContact.Phone__c;
        }
        
        if(tContacts.size() > 0){
            Database.Update(tContacts, false);
            getCustomerContacts();
        }
        
        return null;
    }
    
    public PageReference createNewSubscriberSetting(){
        if(!string.IsEmpty(selectedSubSetting)){
            newSubSetting.Customer_Detail__c = customerDetail.Id;
            newSubSetting.Reference_ID__c = selectedSubSetting;
            system.debug('selectedSubSetting: ' + selectedSubSetting);
            List<Customer_Setting_Reference__c> refs = [select Description__c from Customer_Setting_Reference__c where ID__c = : selectedSubSetting and Category__c = 'SubscriberSetting'];
            newSubSetting.Name = newSubSetting.Description__c = refs.size() > 0 ? refs[0].Description__c : null;
            
            String errorMessage = CustomerDetailUtils.integrateSubscriberSetting(customerDetail, newSubSetting);
            if(String.isEmpty(errorMessage)){
                insert newSubSetting;
                subscriberSettings.add(newSubSetting.Id);
                customerSettings.put(newSubSetting.Id, newSubSetting);
                
                subSettingMap.put(newSubSetting.Reference_ID__c, true);
                updateCustomerSettingReferences();

                //tracking Auto Renewal Exemption customer setting
                if(newSubSetting.Name == 'Auto Renewal Exemption'){
                   customerDetail.Auto_Renewal_Exemption_Status__c = 1;
                   update customerDetail;
                }
                             
                addCustomMessage(false, 'New subscriber setting \'' + newSubSetting.Description__c +  '\' created.');
                newSubSetting = new Customer_Setting__c(RecordTypeId = newSubSetting.RecordTypeId);
            }
            else addCustomMessage(true, errorMessage);
        }
        
        return null;
    }
    
    public PageReference deleteSubscriberSettings(){
        String settingIDs = Apexpages.currentPage().getParameters().get('settingIDs');
        Set<String> settingIDSet = settingIDs != null ? new Set<String>(settingIDs.split(',')) : new Set<String>();
        
        if(settingIDSet.size() > 0){
            Map<Id, Customer_Setting__c> settingMap = new Map<Id, Customer_Setting__c>();
            Map<Integer, Customer_Setting__c> settingByExternalId = new Map<Integer, Customer_Setting__c>();
            List<Integer> externalIDs = new List<Integer>();
            for(String settingId : settingIDSet){
                Customer_Setting__c setting = customerSettings.get(settingId);
                if(setting != null){
                    settingMap.put(setting.Id, setting);
                    if(!string.IsEmpty(setting.External_ID__c)){
                        externalIDs.add(integer.valueOf(setting.External_ID__c));
                        settingByExternalId.put(integer.valueOf(setting.External_ID__c), setting);
                    }
                }
            }
            if(externalIDs.size() > 0){
                List<Integer> results = ICCWrapper.deleteSubscriberSettings(externalIDs, UserInfo.getSessionID());
                Set<Integer> resultIds = results != null && results.size() > 0 ? new Set<Integer>(results) : new Set<Integer>();
                if(resultIds.size() < externalIDs.size())
                    addCustomMessage(true, 'One or more setting could not be deleted from the external system');
                
                for(Integer id : settingByExternalId.keyset()){
                    if(!resultIds.contains(id)){
                        settingMap.remove(settingByExternalId.get(id).Id);
                        settingIDSet.remove(settingByExternalId.get(id).Id);
                    }
                }
            }
            
            for(Integer i=subscriberSettings.size()-1; i>=0; i--){
                if(settingIDSet.contains(subscriberSettings[i])){
                    subSettingMap.put(customerSettings.get(subscriberSettings[i]).Reference_ID__c, false);
                    subscriberSettings.remove(i);
                }
            }
            
            delete settingMap.values();
            
            //tracking Auto Renewal Exemption
            Boolean hasAutoRenewalExemption = false;
            for(Customer_Setting__c cs: settingMap.values()){
                if(cs.Name == 'Auto Renewal Exemption'){                
                    hasAutoRenewalExemption = true;
                    break;
                }
            } 
            if(hasAutoRenewalExemption){
                customerDetail.Auto_Renewal_Exemption_Status__c = 0;
                update customerDetail;
            }
                                    
            updateCustomerSettingReferences();
        }
        
        return null;
    }
    
    public PageReference updateSubscriberSettings(){
        String settingIDs = Apexpages.currentPage().getParameters().get('settingIDs');
        List<String> settingIDList = settingIDs != null ? settingIDs.split(',') : new List<String>();
        
        if(settingIDList.size() > 0){
            Map<Id, Customer_Setting__c> updates = new Map<Id, Customer_Setting__c>();
            List<integraWS.SFSubscriberSettingView> settings = new List<integraWS.SFSubscriberSettingView>();
            for(String settingId : settingIDList){
                if(!string.IsEmpty(settingId) && customerSettings.keyset().contains(settingId)){
                    Customer_Setting__c setting = customerSettings.get(settingId);
                    updates.put(setting.Id, setting);
                    if(!string.IsEmpty(customerDetail.ICC_Subscriber_ID__c))
                        settings.add(ICCWrapper.getSubscriberSettingFromCustomerSetting(setting, customerDetail.ICC_Subscriber_ID__c));
                }
            }
            
            if(settings.size() > 0){
                for(integraWS.SFSubscriberSettingView result : ICCWrapper.updateSubscriberSettings(settings)){
                    Customer_Setting__c setting = customerSettings.get(result.SalesforceID);
                    if(handleIntegrationResult(result.SalesforceID, result.ResultMessage, 'Setting updated', 'Unable to save subscriber setting \'' + result.SalesforceID + '\'')
                        && result.Id != 0 && setting != null && setting.External_ID__c != string.valueOf(result.Id)){
                        setting.External_ID__c = string.valueOf(result.Id);
                        updates.put(setting.Id, setting);
                    }
                }
            }
            
            if(updates.size() > 0)
                update updates.values();
        }
        
        return null;
    }
    
    public PageReference createNewSubscriberTax(){
        createNewSubscriberTaxes(new List<String>{ customerDetail.Id }, new Set<String>{ selectedSubTax });
        return null;
    }
    
    public PageReference saveAccountAndCreateNewSubscriberTaxes(){
        Map<String, String> params = Apexpages.currentPage().getParameters();
        List<String> cdIDs = params.get('cdIDs') != null ? params.get('cdIDs').split(',',0) : new List<String>();
        Set<String> refIDs = new Set<String>(params.get('refIDs') != null ? params.get('refIDs').split(',',0) : new List<String>());
        
        createNewSubscriberTaxes(cdIDs, refIDs);
        SecurityUtils.BypassProcesser.saveObjects(new List<Account>{account}, true);
        
        return null;
    }
    
    private void createNewSubscriberTaxes(List<String> cdIDs, Set<String> refIDs){
        List<Customer_Setting__c> taxes = new List<Customer_Setting__c>();
        for(String refID : refIDs){
            Customer_Setting_Reference__c ref = subTaxMap.get(refID);
            taxes.add(new Customer_Setting__c(RecordTypeId = newSubTax.RecordTypeId
                                        ,Name = ref != null ? ref.Description__c : null
                                        ,Description__c = ref != null ? ref.Description__c : null
                                        ,Exempt_Form_Provided__c = true     //always set
                                        ,Reference_ID__c = refID
                                        ,Start_Date__c = Datetime.now()
                                        ));
        }
        
        copyTaxExemptions(taxes, cdIDs);
        newSubTax = new Customer_Setting__c(RecordTypeId = newSubTax.RecordTypeId);
        updateCustomerSettingReferences();
    }
    
    //Returns true if the caller should save
    private Boolean integrateSubscriberTaxInfos(Map<String, List<Customer_Setting__c>> taxInfosBySubscriberId){
        List<integraWS.SFSubscriberTaxInformationView> taxInfos = new List<integraWS.SFSubscriberTaxInformationView>();
        Map<String, Customer_Setting__c> settingByID = new Map<String, Customer_Setting__c>();
        
        Integer infoCount =  0;
        for(String subID : taxInfosBySubscriberId.keyset()){
            for(Customer_Setting__c taxInfoSetting : taxInfosBySubscriberId.get(subID)){
                integraWS.SFSubscriberTaxInformationView taxInfo = ICCWrapper.getSubscriberTaxInformationFromCustomerSetting(taxInfoSetting, subID);
                taxInfo.SalesforceID = subID + '_' + string.valueOf(infoCount++);
                taxInfos.add(taxInfo);
                settingByID.put(taxInfo.SalesforceID, taxInfoSetting);
            }
        }
        
        if(taxInfos.size() > 0){
            Boolean doSave = false;
            for(integraWS.SFSubscriberTaxInformationView result : ICCWrapper.updateSubscriberTaxInformation(taxInfos)){
                if(result.SalesforceID != null){
                    Customer_Setting__c setting = settingByID.get(result.SalesforceID);
                    if(setting != null){
                        if((result.ID != null && result.ID != 0) || Test.IsRunningTest()){
                            setTaxInfoResults(setting, result);
                            doSave = true;
                        }
                        else
                            addCustomMessage(true, 'New subscriber tax \'' + setting.Description__c +  '\' could not be created: ' + result.ResultMessage);
                    }
                }
            }
            return doSave;
        }
        
        return true;
    }
    
    private void setTaxInfoResults(Customer_Setting__c setting, integraWS.SFSubscriberTaxInformationView result){
        setting.External_ID__c = string.valueOf(result.ID);
        setting.Name = 'Exemption' + result.ID;
        setting.Start_Date__c = result.StartDate;
        setting.End_Date__c = result.EndDate;
    }
    
    private Map<Id, Set<String>> getExistingTaxInfos(List<String> cdIDs){
        Map<Id, Set<String>> m = new Map<Id, Set<String>>();
        for(Customer_Setting__c existing : [select Reference_ID__c, Customer_Detail__c from Customer_Setting__c where Customer_Detail__c in : cdIDs and RecordType.DeveloperName = 'Tax_Information' and End_Date__c = null]){
            Set<String> s = m.get(existing.Customer_Detail__c) != null ? m.get(existing.Customer_Detail__c) : new Set<String>();
            s.add(existing.Reference_ID__c);
            m.put(existing.Customer_Detail__c, s);
        }
        return m;
    }
    
    public PageReference copyTaxExemptions(){
        List<String> copyTaxInfoIDs = Apexpages.currentPage().getParameters().get('copyTaxInfoIDs').split(',',0);
        List<String> copyToIDs = Apexpages.currentPage().getParameters().get('copyToIDs').split(',',0);
        
        copyTaxExemptions((List<Customer_Setting__c>)ApexUtils.retrieveFullObjects(Customer_Setting__c.getsObjectType(), 'Id in (\'' + (string.join(new List<String>(copyTaxInfoIDs), '\',\'')) + '\')'), copyToIDs);
        
        return null;
    }
    
    private void copyTaxExemptions(List<Customer_Setting__c> copyFromTaxes, List<String> copyToIDs){
        List<Customer_Setting__c> newTaxes = new List<Customer_Setting__c>();
        
        Map<Id, Set<String>> existingActiveTaxTypes = getExistingTaxInfos(copyToIDs);
        Map<Id, List<Customer_Setting__c>> newTaxesByDetailID = new Map<Id, List<Customer_Setting__c>>();
        sObjectType settingType = Customer_Setting__c.getsObjectType();
        for(Customer_Setting__c copyFrom : copyFromTaxes){
            for(Id copyToId : copyToIDs){
                if(existingActiveTaxTypes.get(copyToId) != null && existingActiveTaxTypes.get(copyToId).contains(copyFrom.Reference_ID__c))
                    addCustomMessage(false, 'Tax: ' + copyFrom.Description__c + ' already exists on customer: ' + copyToId + '.');
                else{
                    Customer_Setting__c taxInfo = (Customer_Setting__c)ApexUtils.deepCopyFields(settingType, (sObject)copyFrom, (sObject)new Customer_Setting__c(Customer_Detail__c=copyToId), new Set<String>{'Customer_Detail__c', 'External_ID__c', 'OwnerId'});
                    if(taxInfo.Start_Date__c != null) taxInfo.Start_Date__c = Datetime.now();
                    if(taxInfo.End_Date__c != null) taxInfo.End_Date__c = Datetime.now();
                    
                    List<Customer_Setting__c> l = newTaxesByDetailID.get(copyToId) != null ? newTaxesByDetailID.get(copyToId) : new List<Customer_Setting__c>();
                    l.add(taxInfo);
                    newTaxesByDetailID.put(copyToId, l);
                    newTaxes.add(taxInfo);
                }
            }
        }
        
        Map<String, List<Customer_Setting__c>> taxInfosBySubscriberID = new Map<String, List<Customer_Setting__c>>();
        for(Customer_Detail__c cd : [select Id, ICC_Subscriber_ID__c from Customer_Detail__c where Id in : copyToIDs]){
            if(!string.isEmpty(cd.ICC_Subscriber_ID__c)){
                for(Customer_Setting__c setting : newTaxesByDetailID.get(cd.Id) != null ? newTaxesByDetailID.get(cd.Id) : new List<Customer_Setting__c>()){
                    List<Customer_Setting__c> l = taxInfosBySubscriberID.get(cd.ICC_Subscriber_ID__c) != null ? taxInfosBySubscriberID.get(cd.ICC_Subscriber_ID__c) : new List<Customer_Setting__c>();
                    l.add(setting);
                    taxInfosBySubscriberID.put(cd.ICC_Subscriber_ID__c, l);
                }
            }
        }
        
        if(newTaxes.size() > 0 && (taxInfosBySubscriberID.size() == 0 || integrateSubscriberTaxInfos(taxInfosBySubscriberID))){
            insert newTaxes;
            for(Customer_Setting__c cs : newTaxes){
                if(cs.Customer_Detail__c == customerDetail.Id){
                    taxInfos.add(cs.Id);
                    customerSettings.put(cs.Id, cs);
                }
            }
            addCustomMessage(false, 'New Tax Information saved');
        }
    }
    
    public PageReference updateSubscriberTaxInformation(){
        String settingIDs = Apexpages.currentPage().getParameters().get('settingIDs');
        Boolean endDate = ApexPages.currentPage().getParameters().get('endDate') == 'true';
        List<String> settingIDList = settingIDs != null ? settingIDs.split(',') : new List<String>();
        
        if(settingIDList.size() > 0){
            Map<Id, Customer_Setting__c> updates = new Map<Id, Customer_Setting__c>();
            List<integraWS.SFSubscriberTaxInformationView> settings = new List<integraWS.SFSubscriberTaxInformationView>();
            for(String settingId : settingIDList){
                if(!string.IsEmpty(settingId) && customerSettings.containsKey(settingId)){
                    Customer_Setting__c setting = customerSettings.get(settingId);
                    if(endDate && setting.End_Date__c == null) setting.End_Date__c = Datetime.now();
                    updates.put(setting.Id, setting);
                    if(!string.IsEmpty(customerDetail.ICC_Subscriber_ID__c))
                        settings.add(ICCWrapper.getSubscriberTaxInformationFromCustomerSetting(setting, customerDetail.ICC_Subscriber_ID__c));
                }
            }
            
            if(settings.size() > 0){
                for(integraWS.SFSubscriberTaxInformationView result : ICCWrapper.updateSubscriberTaxInformation(settings)){
                    Customer_Setting__c setting = customerSettings.get(result.SalesforceID);
                    if(handleIntegrationResult(result.SalesforceID, result.ResultMessage, 'Tax information updated', 'Unable to save subscriber tax information \'' + result.SalesforceID + '\'')
                            && result.Id != 0 && setting != null
                            && (setting.External_ID__c != string.valueOf(result.Id) || setting.Start_Date__c != result.StartDate || setting.End_Date__c != result.EndDate)){
                        setTaxInfoResults(setting, result);
                        updates.put(setting.Id, setting);
                    }
                }
            }
            
            if(updates.size() > 0)
                update updates.values();
            
            updateCustomerSettingReferences();
        }
        
        return null;
    }
    
    public PageReference updateAddressesFromValidatedAddress(){
        String addressIDs = Apexpages.currentPage().getParameters().get('addressIDs');
        String locationID = Apexpages.currentPage().getParameters().get('locationID');
        
        Boolean createLocation = false;
        Map<String, Building_Address_Format__c> validAddressFormats = new Map<String, Building_Address_Format__c>();
        Map<Boolean, Set<String>> addressIDSet = new Map<Boolean, Set<String>>{true=>new Set<String>(),false=>new Set<String>()};       //true for location ID addresses, false for text field addresses
        for(String id : addressIDs != null ? addressIDs.split(',') : new List<String>()){
            if(AddressUtils.CustomerDetailFieldAddressTypes.keyset().contains(id)  || AddressUtils.CustomerDetailFieldSetAddressTypes.keyset().contains(id)){
                addressIDSet.get(AddressUtils.CustomerDetailFieldAddressTypes.keyset().contains(id)).add(id);
            }
            for(AddressFormat af : addressFormats){
                if(af.validated && af.location != null && af.location.id == id)
                    validAddressFormats.put(id, af.format);
            }
        }
        
        for(LocationAddress address : addresses){
            if(addressIDSet.get(true).contains(address.id) || addressIDSet.get(false).contains(address.id)){
                if(validAddressFormats.get(address.id) == null && (address.canUpdateToValidatedAddress || (locationID != null && address.locationId == locationID))){
                    addressIDSet.get(true).remove(address.id);
                    addressIDSet.get(false).remove(address.id);
                }
            }
        }
        
        if(addressIDSet.get(true).size() > 0 || addressIDSet.get(false).size() > 0){
            
            Location__c l = [select Id, Building__r.Id, Building__r.City__c, Building__r.Postal_Code__c, Building__r.Zip4__c, Building__r.State__c, Building__r.Address__c, Room_Suite__c, Building__r.Country__c from Location__c where Id =: locationID];
            Building__c b = l.Building__r;
            
            if(addressIDSet.get(true).size() > 0){
                if(validAddressFormats.size() > 0){
                    upsert validAddressFormats.values();
                    
                    for(String key : validAddressFormats.keyset()){
                        if(key == 'Customer_Main_Address__c') b.MSAG_Address_Format__c = validAddressFormats.get(key).Id;
                        else if (key == 'Tax_Main_Address__c') b.Tax_Main_Address_Format__c = validAddressFormats.get(key).Id;
                    }
                    AddressUtils.SaveAddress(b, null, null, true);
                }
                
                for(String addressId : addressIDSet.get(true)){
                    customerDetail.put(addressId, string.valueOf(locationID));
                }
            }
            
            for(LocationAddress address : addresses){
                if(addressIDSet.get(true).contains(address.id)){
                    address.setLocationInformation(l, null);
                    address.canUpdateToValidatedAddress = false;
                    //address.message = '';
                }
                else if(addressIDSet.get(false).contains(address.id)){
                    AddressUtils.updateCustomerDetailAddressSet(customerDetail, address.Id, b.City__c, b.Postal_Code__c, b.Zip4__c, b.State__c, b.Address__c, l.Room_Suite__c, address.overrideName, b.Country__c);
                    address.setAddressInformation(b.City__c,  b.Postal_Code__c, b.Zip4__c, b.State__c, b.Address__c, l.Room_Suite__c, address.overrideName, b.Country__c);
                    address.canUpdateToValidatedAddress = false;
                    //address.message = '';
                }
                
            }
            save();
        }
        
        return null;
    }
    
    public PageReference updateAddresses(){
        String addressIDs = Apexpages.currentPage().getParameters().get('addressIDs');
        if(string.isEmpty(addressIDs)) return null;
        List<Location__c> updateLocs = new List<Location__c>();
        List<integraWS.SFSubscriberAddressView> addrs = new List<integraWS.SFSubscriberAddressView>();
        Map<String, Set<Integer>> addressIDMap = new Map<String, Set<Integer>>();
        Map<String, Boolean> updateAddressSets = new Map<String, Boolean>();
        Map<Integer, LocationAddress> locationByTypeMap = new Map<Integer, LocationAddress>();
        
        Integer marketAreaID = customerDetail.Market_Area__c != null ? integer.valueOf(marketAreas.get(customerDetail.Market_Area__c).ICCMarketAreaID__c) : null;
        for(String id : addressIDs != null ? addressIDs.split(',') : new List<String>()){
            if(string.isEmpty(id)) continue;
         
            if(!string.IsEmpty(customerDetail.ICC_Subscriber_ID__c) && AddressUtils.CustomerDetailFieldAddressTypes.keyset().contains(id)){
                Id addressLocId = (Id)customerDetail.get(id);
                if(addressLocId != null){
                    Integer typeID = AddressUtils.CustomerDetailFieldAddressTypes.get(id);
                    Set<Integer> mVal = addressIDMap.get(addressLocId) != null ? addressIDMap.get(addressLocId) : new Set<Integer>();
                    mVal.add(typeID);
                    addressIDMap.put(addressLocId, mVal);
                    
                    for(LocationAddress address : addresses){
                        if(address.id == id)
                            locationByTypeMap.put(typeID, address);
                    }
                }
            }
            else if(AddressUtils.CustomerDetailFieldSetAddressTypes.keyset().contains(id)){
                for(LocationAddress address : addresses){
                    if(address.id == id && address.isValid()){
                        updateAddressSets.put(id, string.IsEmpty(customerDetail.ICC_Subscriber_ID__c));
                        if(!updateAddressSets.get(id)){
                            addrs.add(AddressUtils.setSubscriberAddressViewNameValues(AddressUtils.setSubscriberAddressViewValues(address.city
                                                                                    ,address.postalCode
                                                                                    ,null
                                                                                    ,address.state
                                                                                    ,address.street
                                                                                    ,address.roomSuite
                                                                                    ,integer.valueOf(customerDetail.ICC_Subscriber_ID__c)
                                                                                    ,AddressUtils.CustomerDetailFieldSetAddressTypes.get(id)
                                                                                    ,marketAreaID
                                                                                    ,customerDetail.Id
                                                                                    ,address.country)
                                                                                , address.overrideName, customerDetail.Name, customerDetail.First_Name__c, customerDetail.Last_Name__c));
                        }
                    }
                }
            }
        }
        Map<String, Location__c> newLocationMap = new Map<String, Location__c>();
        Map<String, String> newLocationUpdates = new Map<String, String>();
        if(addressIDMap.size() > 0){
            for(Location__c loc : [select Id
                                    ,Room_Suite__c
                                    ,Building__r.Id
                                    ,Building__r.Address__c
                                    ,Building__r.City__c
                                    ,Building__r.State__c
                                    ,Building__r.Postal_Code__c
                                    ,Building__r.Zip4__c
                                    ,Building__r.Country__c
                                    ,Building__r.Building_Hash__c
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
                                    from Location__c where Id in: addressIDMap.keyset()]){
                for(Integer typeId : addressIDMap.get(loc.Id)){
                    integraWS.SFSubscriberAddressView addr = AddressUtils.setSubscriberAddressViewValues(loc, integer.valueOf(customerDetail.ICC_Subscriber_ID__c), typeId, marketAreaID);
                    if(addr != null){
                        LocationAddress locAddr = locationByTypeMap.get(typeId);
                        if(locAddr != null){
                            locAddr.roomSuite = locAddr.roomSuite != null ? locAddr.roomSuite.trim() : null;
                            if(locAddr.roomSuite != loc.Room_Suite__c){
                                addr.Location = locAddr.roomSuite;
                                String combinationID = loc.Building__c + '_{' + (locAddr.roomSuite != null ? locAddr.roomSuite : '') + '}';
                                newLocationUpdates.put(locAddr.id, combinationID);
                                if(newLocationMap.get(combinationID) == null)
                                    newLocationMap.put(combinationID, new Location__c(Building__c = loc.Building__c, Room_Suite__c = locAddr.roomSuite));
                            }
                        }
                        addrs.add(AddressUtils.setSubscriberAddressViewNameValues(addr, null, customerDetail.Name, customerDetail.First_Name__c, customerDetail.Last_Name__c));
                    }
                }
            }
        }
        if(addrs.size() > 0){
            Map<Integer, String> reversedTypeMap = new Map<Integer, String>();
            for(String str : AddressUtils.CustomerDetailFieldAddressTypes.keyset())
                reversedTypeMap.put(AddressUtils.CustomerDetailFieldAddressTypes.get(str), str);
            for(String str : AddressUtils.CustomerDetailFieldSetAddressTypes.keyset())
                reversedTypeMap.put(AddressUtils.CustomerDetailFieldSetAddressTypes.get(str), str);
                
            for(integraWS.SFSubscriberAddressView result : ICCWrapper.updateSubscriberAddresses(addrs, UserInfo.getSessionId())){
                for(LocationAddress address : addresses){
                    if(reversedTypeMap.get(result.AddressTypeId) == address.id){
                        //MNK temporary logic until AddressMaster can support Canadian addresses
//                        If (address.Country == 'CA') {
//                            updateAddressSets.put(address.id, true);
//                        }
//                        else
                        if(!string.IsEmpty(result.resultMessage)){
                            address.message = result.ResultMessage;
                            if(newLocationUpdates.get(address.id) != null)
                                newLocationUpdates.remove(address.id);
                        }
                        else if(updateAddressSets.get(address.id) == false)
                            updateAddressSets.put(address.id, true);
                    }
                }
            }
        }
        
        Set<String> newLocationKeys = new Set<String>(newLocationUpdates.values());
        Boolean updateCustomerDetail = newLocationKeys.size() > 0;
        for(LocationAddress address : addresses){
            if(updateAddressSets.get(address.id) == true){
                updateCustomerDetail = true;
                AddressUtils.updateCustomerDetailAddressSet(customerDetail, address.id, address.city, address.postalCode, null, address.state, address.street, address.roomSuite, address.overrideName, address.country);
            }
        }
        
        if(updateCustomerDetail){
            if(newLocationMap.size() > 0){
                Set<String> allLocationKeys = newLocationMap.keyset();
                List<String> whereClause = new List<String>();
                for(String k : allLocationKeys){
                    if(!newLocationKeys.contains(k))
                        newLocationMap.remove(k);
                    else{
                        Location__c loc = newLocationMap.get(k);
                        whereClause.add('(Building__c = \'' + loc.Building__c + '\' and Room_Suite__c = ' + (loc.Room_Suite__c != null ? ('\'' + loc.Room_Suite__c + '\'') : 'null') + ')');
                    }
                }
                
                Set<String> existingLocations = new Set<String>();
                if(whereClause.size() > 0){
                    for(Location__c loc : (List<Location__c>)Database.query('select Id, Building__c, Room_Suite__c from Location__c where ' + string.join(whereClause, ' or '))){
                        String combinationID = loc.Building__c + '_{' + (loc.Room_Suite__c != null ? loc.Room_Suite__c : '') + '}';
                        existingLocations.add(combinationID);
                        newLocationMap.put(combinationID, loc);
                    }
                }
                
                if(existingLocations.size() != newLocationMap.size()){
                    List<Location__c> newLocations = new List<Location__c>();
                    for(String k : newLocationMap.keyset()){
                        if(!existingLocations.contains(k))
                            newLocations.add(newLocationMap.get(k));
                    }
                    if(newLocations.size() > 0)
                        insert newLocations;
                }
                
                for(String fieldID : newLocationUpdates.keyset())
                    customerDetail.put(fieldID, newLocationMap.get(newLocationUpdates.get(fieldID)).Id);
            }
            
            CustomerDetailTriggers.IntegrationDisabled = true;
            save();
            CustomerDetailTriggers.IntegrationDisabled = false;
            addCustomMessage(false, 'Addresses updated.');
        }
        
        return null;
    }
    
    private Boolean handleIntegrationResult(string salesforceID, string resultMessage, string successMessage, string defaultFailureMessage){
        if(string.IsEmpty(salesforceID) || !string.IsEmpty(resultMessage)){
            addCustomMessage(true, string.IsEmpty(resultMessage) ? defaultFailureMessage : resultMessage);
            return false;
        }
        
        addCustomMessage(false, successMessage);
        return true;
    }
    
    public String validatedAddress {get; set;}
    public PageReference validateAddress(){
        for(LocationAddress address : addresses) {
            address.canUpdateToValidatedAddress = false;
        }
        
        addressFormats = new List<AddressFormat>();
        integraWS.SFLocationView locView = AddressParser.addressParsed();

        validatedAddress = null;
        
        if(locView != null && locView.Success && !string.IsEmpty(locView.BuildingHash)){
            parsedBuilding = AddressUtils.CreateBuilding(locView, false);
            Location__c parsedLocation = AddressUtils.CreateLocation(parsedBuilding, locView, false);
            
            if(parsedBuilding != null && parsedLocation != null){
                validatedAddress = locView.Street
                                    + (!string.IsEmpty(locView.SubPremise) ? ', ' + locView.SubPremise : '')
                                    + (!string.IsEmpty(locView.City) ? ', ' + locView.City : '')
                                    + (!string.IsEmpty(locView.State) ? ', ' + locView.State : '')
                                    + (!string.IsEmpty(locView.PostalCode) ? ', ' + locView.PostalCode : '')
                                    + (!string.IsEmpty(locView.Country) ? ', ' + locView.Country : '');

                validateAvailableAddresses(parsedLocation);
            }
        }
        else addCustomMessage(true, 'Address could not be validated with the external systems');
        
        return null;
    }
    
    private void validateAvailableAddresses(Location__c l){
        Building__c b = parsedBuilding;

        if(b == null || l == null) return;
        
        Map<String, LocationAddress> locAddressMap = new Map<String, LocationAddress>();
        for(LocationAddress address : addresses){
            locAddressMap.put(address.id, address);
            address.canUpdateToValidatedAddress = false;
        }
        
        Market_Area__c ma = customerDetail.Market_Area__c != null ? marketAreas.get(customerDetail.Market_Area__c) : null;
        List<integraWS.SFSubscriberAddressView> addressViews = new List<integraWS.SFSubscriberAddressView>();

        for(String typeName : AddressUtils.CustomerDetailFieldAddressTypes.keyset()){
            LocationAddress lAddr = locAddressMap.get(typeName);
            if(lAddr != null && (lAddr.locationId == null || lAddr.locationId != l.Id))
                addressViews.add(AddressUtils.setSubscriberAddressViewNameValues(buildAddressViewFromBuilding(b, AddressUtils.CustomerDetailFieldAddressTypes.get(typeName), ma), null, customerDetail.Name, customerDetail.First_Name__c, customerDetail.Last_Name__c));
        }

        for(String typeName : AddressUtils.CustomerDetailFieldSetAddressTypes.keyset()){
            LocationAddress lAddr = locAddressMap.get(typeName);
            if(lAddr != null && (lAddr.street != b.Address__c
                                || lAddr.city != b.City__c
                                || lAddr.state != b.State__c
                                || lAddr.postalCode != b.Postal_Code__c
                                || lAddr.zip4 != b.Zip4__c
                                || ((!string.IsEmpty(lAddr.roomSuite) || !string.IsEmpty(l.Room_Suite__c))
                                    && lAddr.roomSuite != l.Room_Suite__c)))
                addressViews.add(AddressUtils.setSubscriberAddressViewNameValues(buildAddressViewFromBuilding(b, AddressUtils.CustomerDetailFieldSetAddressTypes.get(typeName), ma), lAddr.overrideName, customerDetail.Name, customerDetail.First_Name__c, customerDetail.Last_Name__c));
        }

        Set<Integer> validAddressTypes = new Set<Integer>();
        Set<Integer> invalidAddressTypes = new Set<Integer>();
        Map<Integer, String> invalidMessages = new Map<Integer, String>();
    
        for(integraWS.SFSubscriberAddressView result : ICCWrapper.validateSubscriberAddresses(addressViews, UserInfo.getSessionId())){
            //MNK if below is temporary until AddressMaster can support Canadian addresses
 //           if (result.Country.equals('CA')||result.Country.equals('CAN'))
 //               validAddressTypes.add(result.AddressTypeId);
 //           else
 //           {
                if (string.IsEmpty(result.ResultMessage)) 
                    validAddressTypes.add(result.AddressTypeId);
                 else
                {
                    invalidMessages.put(result.AddressTypeId, result.ResultMessage);
                    invalidAddressTypes.add(result.AddressTypeId);
                }
 //           }
        }
        
        Map<String, Integer> mergedMap = new Map<String, Integer>();
        for(String key : AddressUtils.CustomerDetailFieldAddressTypes.keyset())
            mergedMap.put(key, AddressUtils.CustomerDetailFieldAddressTypes.get(key));
        for(String key : AddressUtils.CustomerDetailFieldSetAddressTypes.keyset())
            mergedMap.put(key, AddressUtils.CustomerDetailFieldSetAddressTypes.get(key));
        
        //Get known validated addressformats from AM
        if(!Test.IsRunningTest())
            SFOverriddenAddresses = integraWSEndpointMediator.Endpoint.GetOverrideAddressesByBuildingHashText(b.building_hash__c, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
        Map<Integer,Boolean> amValidatedTypes = GetAMValidationStatus(SFOverriddenAddresses);
        
        //get current sfdc values
        Set<Integer> overrideAddressTypes = new Set<Integer>{1,2};
        Map<Integer,Building_Address_Format__c> currentSFDCFormatValues = new Map<Integer,Building_Address_Format__c>();
        //if(b.MSAG_Address_Format__r != null)
            currentSFDCFormatValues.put(1,b.MSAG_Address_Format__r);
        //if(b.Tax_Main_Address_Format__r != null)
            currentSFDCFormatValues.put(2,b.Tax_Main_Address_Format__r);
        
        currentSFDCFormatValues = GetAddressFormatFromAMAddress(SFOverriddenAddresses,currentSFDCFormatValues);
        
        
        for(String addressType : mergedMap.keyset()){
            LocationAddress locAddr = locAddressMap.get(addressType);
            if(locAddr != null){
                Integer fieldID = AddressUtils.CustomerDetailFieldAddressTypes.get(addressType);
                if(fieldID == null)
                    fieldID = AddressUtils.CustomerDetailFieldSetAddressTypes.get(addressType);
                locAddr.canUpdateToValidatedAddress = invalidAddressTypes.contains(fieldID);
                locAddr.message = invalidMessages.get(fieldID);
                if(overrideAddressTypes.contains(mergedMap.get(addressType)) && (locAddr.canUpdateToValidatedAddress || currentSFDCFormatValues.get(mergedMap.get(addressType)) != null)){
                    Building_Address_Format__c baf = currentSFDCFormatValues.get(mergedMap.get(addressType)) == null ? buildNewBuildingAddressFormat(b,locaddr.id) : currentSFDCFormatValues.get(mergedMap.get(addressType));
                    addressFormats.add(new AddressFormat(locAddr,baf , mergedMap.get(addressType), amValidatedTypes.get(mergedMap.get(addressType)) == null ?  baf.Id != null : amValidatedTypes.get(mergedMap.get(addressType))));
                }
            }
        }
    }
    
    private Building_Address_Format__c buildNewBuildingAddressFormat(Building__c b,String type){
        Building_Address_Format__c baf = new Building_Address_Format__c();
        if(type == 'Tax_Main_Address__c'){
            baf.City__c = b.city__c;
            baf.Street__c = b.Address__c;
        }
        return baf;
    }
    public Map<Integer,Boolean> GetAMValidationStatus(integraWS.SFOverriddenAddresses adds){
        Map<Integer,Boolean> statusMap = new Map<Integer,Boolean>();
        if(adds != null){
            if(adds.MSAGAddress != null){
                statusMap.put(1,adds.MSAGAddress.ValidationStatus);
            }
            if(adds.TaxMainAddress != null){
                statusMap.put(2,adds.TaxMainAddress.ValidationStatus);
            }
        }
        return statusMap;
    }
    
    private Map<integer,Building_Address_Format__c> GetAddressFormatFromAMAddress(integraWS.SFOverriddenAddresses adds, Map<Integer,Building_Address_Format__c> currentSFDCFormatValues){
        if(adds != null){
            System.debug('adds: ' + adds);
            Building_Address_Format__c msagbaf = currentSFDCFormatValues.get(1) != null ? currentSFDCFormatValues.get(1) : new Building_Address_Format__c();
            if(adds.MSAGAddress != null){
                msagbaf.House_Number__c = adds.MSAGAddress.streetnumber;
                msagbaf.PreDirectional__c = adds.MSAGAddress.streetDirectionalPrefix;
                msagbaf.Street__c = adds.MSAGAddress.StreetName;
                msagbaf.PostDirectional__c = adds.MSAGAddress.streetDirectionalSuffix;
                msagbaf.Street_Type__c = adds.MSAGAddress.streetType;
                msagbaf.City__c = adds.MSAGAddress.city;
                currentSFDCFormatValues.put(1,msagbaf);
            }
            
            
            Building_Address_Format__c taxbaf = currentSFDCFormatValues.get(2) != null ? currentSFDCFormatValues.get(2) : new Building_Address_Format__c();
            if(adds.TaxMainAddress != null){
                taxbaf.House_Number__c = adds.TaxMainAddress.streetnumber;
                taxbaf.PreDirectional__c = adds.TaxMainAddress.streetDirectionalPrefix;
                taxbaf.Street__c = adds.TaxMainAddress.StreetName;
                taxbaf.PostDirectional__c = adds.TaxMainAddress.streetDirectionalSuffix;
                taxbaf.Street_Type__c = adds.TaxMainAddress.streetType;
                taxbaf.City__c = adds.TaxMainAddress.city;
                currentSFDCFormatValues.put(2,taxbaf);
            }
            
        }
        
        return currentSFDCFormatValues;
    }
    
    public PageReference updateAddressFormat(){
        String formatId = Apexpages.currentPage().getParameters().get('formatId');
        String houseNumber = Apexpages.currentPage().getParameters().get('houseNumber');
        String preDirectional = Apexpages.currentPage().getParameters().get('preDirectional');
        String street = Apexpages.currentPage().getParameters().get('street');
        String streetType = Apexpages.currentPage().getParameters().get('streetType');
        String postDirectional = Apexpages.currentPage().getParameters().get('postDirectional');
        String city = Apexpages.currentPage().getParameters().get('city');
        
        AddressFormat addrFormat = null;
        for(AddressFormat af : addressFormats){
            if(af.location != null && af.location.id == formatId && AddressUtils.CustomerDetailFieldAddressTypes.get(formatId) != null){
                addrFormat = af;
                break;
            }
        }
        
        if(addrFormat != null){
            Building_Address_Format__c baf = addrFormat.format;
            baf.House_Number__c = houseNumber;
            baf.PreDirectional__c = preDirectional;
            baf.Street__c = street;
            baf.PostDirectional__c = postDirectional;
            baf.City__c = city;
            baf.Street_Type__c = streetType;
            
            integraWS.SFSubscriberAddressView addr = AddressUtils.setSubscriberAddressViewNameValues(buildAddressViewFromBuilding(parsedBuilding
                                                                                ,AddressUtils.CustomerDetailFieldAddressTypes.get(formatId)
                                                                                ,customerDetail.Market_Area__c != null ? marketAreas.get(customerDetail.Market_Area__c) : null
                                                                                ,baf)
                                                                            ,null, customerDetail.Name, customerDetail.First_Name__c, customerDetail.Last_Name__c);
            for(integraWS.SFSubscriberAddressView result : ICCWrapper.validateSubscriberAddresses(new List<integraWS.SFSubscriberAddressView>{addr}, UserInfo.getSessionId())){
                addrFormat.validated = string.IsEmpty(result.ResultMessage);
                addrFormat.error = result.ResultMessage;
            }
            
            //update format in AM if it was successfully validated
            if(addrFormat.validated){
                
                integraWS.SFOverriddenAddresses adds = SFOverriddenAddresses == null ? new integraWS.SFOverriddenAddresses() : SFOverriddenAddresses;
                integraWS.SFOverriddenAddresses addsToUpdate = new integraWS.SFOverriddenAddresses();
                if(AddressUtils.CustomerDetailFieldAddressTypes.get(formatId) == 1){
                    integraWS.SFMSAGAddress msagAdd = adds.MSAGAddress == null ? new integraWS.SFMSAGAddress() : adds.MSAGAddress;
                    msagAdd.validationstatus = true;
                    msagAdd.StreetNumber = houseNumber;
                    msagAdd.StreetDirectionalPrefix = preDirectional;
                    msagAdd.StreetName = street;
                    msagAdd.StreetType = streettype;
                    msagAdd.StreetDirectionalSuffix = postDirectional;
                    msagAdd.city = city;
                    msagAdd.BuildingHash = parsedBuilding.building_hash__c;
                    
                    addsToUpdate.MSAGAddress = msagAdd;
                }
                else if(AddressUtils.CustomerDetailFieldAddressTypes.get(formatId) == 2){
                    integraWS.SFTaxMainAddress taxMainAdd = adds.TaxMainAddress == null ? new integraWS.SFTaxMainAddress() : adds.TaxMainAddress;
                    taxMainAdd.validationstatus = true;
                    taxMainAdd.StreetNumber = houseNumber;
                    taxMainAdd.StreetDirectionalPrefix = preDirectional;
                    taxMainAdd.StreetName = street;
                    taxMainAdd.StreetType = streettype;
                    taxMainAdd.StreetDirectionalSuffix = postDirectional;
                    taxMainAdd.city = city;
                    taxMainAdd.BuildingHash = parsedBuilding.building_hash__c;
                    
                    addsToUpdate.TaxMainAddress = taxMainAdd;
                }
            
                System.debug('addsToUpdate: ' + addsToUpdate);
                if(!Test.IsRunningTest())
                    integraWS.SFOverriddenAddresses response = integraWSEndpointMediator.Endpoint.UpsertOverriddenAddresses(addsToUpdate, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
                
            }
        }
        else
            addCustomMessage(true, 'Invalid address format returned');
        
        return null;
    }
    
    private static integraWS.SFSubscriberAddressView buildAddressViewFromBuilding(Building__c building, Integer addressTypeId, Market_Area__c marketArea, Building_Address_Format__c format){
        integraWS.SFSubscriberAddressView addr = AddressUtils.setSubscriberAddressViewValues(building, null, null, 0, addressTypeId, marketArea != null ? integer.valueOf(marketArea.ICCMarketAreaID__c) : 0);
        addr.BuildingHash = null;
        addr.City = format.City__c;
        addr.HouseNbr = format.House_Number__c;
        addr.PreDirectional = format.PreDirectional__c;
        addr.Street = format.Street__c;
        addr.PostDirectional = format.PostDirectional__c;
        addr.streetsuff = format.Street_Type__c;
        return addr;
    }
    
    private static integraWS.SFSubscriberAddressView buildAddressViewFromBuilding(Building__c building, Integer addressTypeId, Market_Area__c marketArea){
        return AddressUtils.setSubscriberAddressViewValues(building, null, null, 0, addressTypeId, marketArea != null ? integer.valueOf(marketArea.ICCMarketAreaID__c) : 0);
    }
    
    public static String getCustomerContactModifier(Customer_Contact__c cc){
        return (!string.IsEmpty(cc.Email__c) ? (cc.Email__c + '_') : '') + (!string.IsEmpty(cc.Phone__c) ? cc.Phone__c : '');
    }
    
    private void AddNote(String SubscriberId, String remarkText) {
        List<integraWS.SFRemarkView> remarks = new List<integraWS.SFRemarkView>();
        integraWS.SFRemarkView remark = new integraWS.SFRemarkView();
        remark.ParentExternalID = Integer.valueOf(SubscriberId);
        remark.Remark = remarkText;
        remark.CreateUser = UserInfo.getUserId();
        remarks.add(remark);
        ICCWrapper.createRemarks(remarks, 'Subscriber', UserInfo.getSessionId());
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_CustomerDetailExtensionController(); }
}