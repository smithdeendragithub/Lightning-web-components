public without sharing class IntegrationUtils implements TestUtils.ITestableClass {
    
    public final static Set<String> CustomerDetailIntegrationFieldSet = new Set<String>{'ICC_Subscriber_ID__c','Name','Phone__c','First_Name__c','Last_Name__c'
                                                                                        ,'Customer_Account_Manager__c','Customer_Account_Manager__r.NTID__c','LOA_Signed_By__c'
                                                                                        ,'Owner__c','Owner__r.NTID__c','Owner__r.Sales_Channel__c'
                                                                                        ,'Owner_Agency__c','Owner_Agency__r.AgentId__c','Owner_Agency__r.Parent.AgentId__c'
                                                                                        ,'Split_Owner_Agency__c','Split_Owner_Agency__r.AgentId__c','Split_Owner_Agency__r.Parent.AgentId__c'
                                                                                        ,'Split_Owner__c','Split_Owner__r.NTID__c','Split_Owner_Percentage__c'
                                                                                        ,'Collection_Rep__c','Collection_Rep__r.NTID__c'
                                                                                        ,'Credit_Checked_By__c','Credit_Checked_By__r.NTID__c'
                                                                                        ,'Bill_Cycle__c','Bill_Cycle__r.Value__c', 'Bill_Cycle__r.External_ID__c', 'Collection_Code__c','Collection_Code__r.External_ID__c','Credit_Approved_Date__c'
                                                                                        ,'Credit_Bureau__c','Credit_Bureau_Not_Available__c','Credit_Class__c','Credit_Limit__c','Credit_Score__c','Credit_Score_Date__c'
                                                                                        ,'Disputed_Amount__c','Exchange__c','Exchange__r.External_ID__c','Market_Area__c','Market_Area__r.Name', 'Market_Area__r.ICCMarketAreaID__c','Market_Subtype__c'
                                                                                        ,'Market_Subtype__r.External_ID__c','Market_Type__c','Market_Type__r.External_ID__c','MSS_Account_ID__c','Past_Due__c','Prov_Market_Area__c'
                                                                                        ,'Prov_Market_Area__r.ProvMarketAreaID__c','Reporting_Company__c','Reporting_Company__r.External_ID__c','Suspended__c','Government_Contract_Type__c'
                                                                                        ,'Government_Segment__c','Care_Organization__c','Care_Organization__r.External_ID__c','Acquired_Company_Biller__c','Accounts_Receivable_System__c'
                                                                                        ,'Billable__c','Parent_Account__r.Customer_Detail__c, Bill_Cycle_External_ID__c','CurrencyISOCode'};
    
    public final static Set<String> inactiveSubscriberStatuses = new Set<String>{'Cancel', 'Inactive'};
        
    public final static String integrationEmailReplyTo = 'no-reply.integration@salesforce.com';
    public static String emailIntegrationException(Exception e, String errorEmail, String detailedMessageSubject){
        String details = (e instanceof System.CalloutException) ? String.valueOf(e) : e.getStackTraceString();
        
        List<String> intErrorAddresses = CustomSettingUtils.IntegrationErrorEmailAddresses;
        if(intErrorAddresses.size() > 0){
            Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[2];
            emails[0] = ApexUtils.createEmailMessage(intErrorAddresses, null, detailedMessageSubject + ': ' + e.getMessage(), details, false, integrationEmailReplyTo);
            emails[1] = ApexUtils.createEmailMessage(new List<String>{errorEmail}, null, 'An integration exception has occurred',
                                                                    'An error has occurred while attempting to communicate with our external systems.',
                                                                    false, integrationEmailReplyTo);
            if(!Test.isRunningTest())
                ApexUtils.sendEmails(emails);
        }
        
        return details;
    }
    
    public static void createUpdateIntegrationErrors(Set<Id> ids, String errorMessage, Map<Id, String> specificUpdates){

        Map<Id, String> errorMap = new Map<Id, String>();
        for(Id id : ids)
            errorMap.put(id, errorMessage);
        createUpdateIntegrationErrors(errorMap, specificUpdates);
    }
    
    public static void createUpdateIntegrationErrors(Map<Id, String> errorMap, Map<Id, String> specificUpdates){

        if(specificUpdates == null)
            specificUpdates = new Map<Id, String>();
        
        List<Integration_Error__c> errors = new List<Integration_Error__c>();
        for(Id id : errorMap.keySet())
            errors.add(new Integration_Error__c(ObjectID__c = id, Action__c = 'Update', Info__c = specificUpdates.get(id), Message__c = errorMap.get(id)));
            
        insert errors;
    }
    
    public static List<String> reactivateAccounts(Set<Id> accountIDs){
        List<String> errors = new List<String>();
        
        Map<Id, Account> accounts = getAccountsForReactivationByID(accountIDs);
        List<Service_Location__c> sLocs = [select Id, Account__c, Customer_Detail__c from Service_Location__c where Account__c =: accountIDs];
        
        try{
            //if(sLocs.size() > 0)
            errors = reactivateAccountAndLocations(new Map<Id, Service_Location__c>(sLocs).keyset(), accounts);
        }
        catch(Exception e){
            errors.add(e.getMessage());
        }
        
        return errors;
    }
    
    public static List<String> reactivateServiceLocs(Set<Id> serviceLocIDs){
        return reactivateAccountAndLocations(serviceLocIDs, null);
    }
    
    private static List<String> reactivateAccountAndLocations(Set<Id> serviceLocIDs, Map<Id, Account> accounts){
        List<String> errors = new List<String>();
        
        serviceLocIDs = serviceLocIDs != null ? new Set<Id>(serviceLocIDs) : new Set<Id>(); //Correct for read-only source like map keyset
        sObjectType sLocType = Service_Location__c.getsObjectType();
        try{
            //Get highest part of the branch
            for(Service_Location__c sLoc : [select Id
                                                    ,Parent_Service_Location__c
                                                    ,Parent_Service_Location__r.Parent_Service_Location__c
                                                from Service_Location__c
                                                where Id in: serviceLocIDs or Parent_Service_Location__c in: serviceLocIDs or Parent_Service_Location__r.Parent_Service_Location__c in: serviceLocIDs]){
                serviceLocIDs.add(sLoc.Id);
                if(sLoc.Parent_Service_Location__c != null){
                    serviceLocIDs.add(sLoc.Parent_Service_Location__c);
                    if(sLoc.Parent_Service_Location__r.Parent_Service_Location__c != null)
                        serviceLocIDs.add(sLoc.Parent_Service_Location__r.Parent_Service_Location__c);
                }
            }
            
            List<Service_Location__c> sLocs = (List<Service_Location__c>)Database.query('select Id, Customer_Detail__r.Integration_Status__c, Account__c, Account__r.Customer_Detail__c, '
                                                                                        + '(select Id from Opportunity_Locations__r where Opportunity__r.StageName not in (\'Closed Won\', \'Closed Lost\')), '
                                                                                        + '(select Id from Opportunity_Products__r where Opportunity__r.StageName not in (\'Closed Won\', \'Closed Lost\')) '
                                                                                        + ' from Service_Location__c'
                                                                                        + ' where Account__r.RecordType.DeveloperName != \'System\' and Id in: serviceLocIDs');
            
            if(accounts == null){
                accounts = new Map<Id, Account>();
                for(Service_Location__c sLoc : sLocs)
                    accounts.put(sLoc.Account__c, null);
                accounts = getAccountsForReactivationByID(accounts.keyset());
            }
            
            Map<Id, Id> matchingSLocs = new Map<Id, Id>();
            Map<Id, Integer> allAccounts = new Map<Id, Integer>();
            Map<Id, Customer_Detail__c> updateDetails = new Map<Id, Customer_Detail__c>();
            List<Service_Location__c> upsertLocs = new List<Service_Location__c>();
            for(Service_Location__c sLoc : sLocs){
                if(sLoc.Customer_Detail__c != null && sLoc.Customer_Detail__c == sLoc.Account__r.Customer_Detail__c) matchingSLocs.put(sLoc.Account__c, sLoc.Id);
                updateDetails.put(sLoc.Customer_Detail__c, null);
                sLoc.Agency__c = null;
                sLoc.Customer_Detail__c = null;
                upsertLocs.add(sLoc);
                allAccounts.put(sLoc.Account__c, allAccounts.get(sLoc.Account__c) != null ? (allAccounts.get(sLoc.Account__c) + 1) : 1);
            }
            
            if(upsertLocs.size() > 0) SecurityUtils.BypassProcesser.saveObjects(upsertLocs, true);
            
            List<Set<Id>> cdGenerateList = new List<Set<Id>>();
            List<Account> updateAccounts = new List<Account>();
            RecordType prt = [select Id from RecordType where sObjectType = 'Account' and DeveloperName = 'Prospect'];
            for(Account a : accounts.values()){
                updateDetails.put(a.Customer_Detail__c, null);
                a.Agency__c = null;
                a.Customer_Detail__c = null;
                a.Type = 'Former Customer';
                if(a.RecordType.DeveloperName != 'ILEC_Prior_Lake')
                    a.RecordTypeId = prt.Id;
                updateAccounts.add(a);
                allAccounts.put(a.Id, allAccounts.get(a.Id) != null ? allAccounts.get(a.Id) : 0);
                if(allAccounts.get(a.Id) > 1 && matchingSLocs.get(a.Id) != null)
                    cdGenerateList.add(new Set<Id>{ a.Id, matchingSLocs.get(a.Id)});
            }
            
            if(updateAccounts.size() > 0) SecurityUtils.BypassProcesser.saveObjects(updateAccounts, true);
            
            CustomerDetailUtils.triggerDetailAddressValidation = false;
            if(cdGenerateList.size() > 0)
                CustomerDetailUtils.updateCustomerDetails(cdGenerateList, null);
            
            //Clone over contacts so they get freed up on the accounts
            if(updateDetails.size() > 0){
                Id sysAccountID = SecurityUtils.SystemAccount.Id;
                allAccounts.remove(sysAccountID);
                updateDetails = new Map<Id, Customer_Detail__c>([select Id
                                                                        ,Parent_Account__c
                                                                        ,(select Id from Accounts__r)
                                                                        ,(select Id from Service_Locations__r)
                                                                        ,(select Id, Contact__c from Customer_Contacts__r where Contact__r.AccountId in: allAccounts.keyset())
                                                                        from Customer_Detail__c where Id in: updateDetails.keyset()]);
                
                List<Customer_Contact__c> customerContacts = new List<Customer_Contact__c>();
                Map<Id, Contact> contacts = new Map<Id, Contact>();
                for(Customer_Detail__c cd : updateDetails.values()){
                    Boolean detached = (cd.Accounts__r == null || cd.Accounts__r.size() == 0) && (cd.Service_Locations__r == null || cd.Service_Locations__r.size() == 0);
                    if(detached){
                        for(Customer_Contact__c cc : cd.Customer_Contacts__r != null ? cd.Customer_Contacts__r : new List<Customer_Contact__c>()){
                            customerContacts.add(cc);
                            contacts.put(cc.Contact__c, null);
                        }
                    }
                }
                
                if(contacts.size() > 0){
                    sObjectType cType = Contact.sObjectType;
                    contacts = new Map<Id, Contact>((List<Contact>)ApexUtils.retrieveFullObjects(cType, 'Id in(\'' + string.join(new List<Id>(contacts.keyset()), '\',\'') + '\')'));
                    
                    List<Contact> cList = contacts.values();
                    for(Contact c : cList)
                        contacts.put(c.Id, (Contact)ApexUtils.deepCopyFields(cType, c, new Contact(AccountId = sysAccountID, Default_Responsible_Party__c = false), new Set<String>{'AccountId', 'Default_Responsible_Party__c'}));
                    
                    insert contacts.values();
                    
                    for(Customer_Contact__c cc : customerContacts)
                        cc.Contact__c = contacts.get(cc.Contact__c).Id;
                    
                    Boolean ccD = CustomerContactTriggers.IntegrationDisabled;
                    CustomerContactTriggers.IntegrationDisabled = true;
                    update customerContacts;
                    CustomerContactTriggers.IntegrationDisabled = ccD;
                }
            }
            
            List<Disconnect_Line_Item__c> dlis = [select Id from Disconnect_Line_Item__c where Opportunity_Location__r.Service_Location__c in: serviceLocIDs];
            if(dlis.size() > 0) Database.delete(dlis);  //Don't let this fail the whole process
        }
        catch(Exception e){
            errors.add(e.getMessage());
        }
        
        return errors;
    }
    
    private static Map<Id, Account> getAccountsForReactivationByID(Set<Id> accountIDs){
        return new Map<Id, Account>([select Id, Name, Phone, OwnerId, Agency__c, Billable__c, Customer_Detail__r.Id, Customer_Detail__r.Service_Address__c, RecordType.DeveloperName
                                    from Account where Id =: accountIDs and Customer_Detail__c != null and Type = 'Former Customer']);
    }
     
    public static List<String> createSubscribersFromOrderRelatedServiceLocations(Map<Id, Id> orderIDsByLocationID, string sessionID){

        List<Customer_Setting__c> billCycles = new List<Customer_Setting__c>{};

        Map<String, Map<String, Id>> settings = new Map<String, Map<String, Id>>();
        
        Map<Id, RecordType> rts = new Map<Id, RecordType>([select Id from RecordType where sObjectType = 'Customer_Setting__c' and DeveloperName in ('Bill_Cycle_Schedule', 'Care_Organization', 'Collection_Code', 'Exchange', 'Market_Type', 'Market_Subtype')]);
        for(Customer_Setting__c setting : [select Id
                                           ,External_ID__c
                                           ,RecordType.DeveloperName
                                           ,Value__c
                                           ,Market_Area__r.ICCMarketAreaID__c
                                           ,Market_Type__r.External_ID__c
                                           ,Description__c
                                           from Customer_Setting__c where RecordTypeId in : rts.keyset()]){
            Map<String, Id> mp = settings.get(setting.RecordType.DeveloperName);
            if(mp == null)
                mp = new Map<String, Id>();
                                               
            if(setting.RecordType.DeveloperName == 'Bill_Cycle_Schedule'){
                billCycles.add(setting);
                if(setting.Market_Area__c != null && setting.Market_Type__c != null && setting.Description__c == null) {
                    mp.put(setting.Market_Area__r.ICCMarketAreaID__c + '_' + setting.Market_Type__r.External_ID__c + '_' + setting.Value__c, setting.Id);
                } else if(setting.Market_Area__c != null && setting.Market_Type__c != null && setting.Description__c != null) {
                    mp.put(setting.Market_Area__r.ICCMarketAreaID__c + '_' + setting.Market_Type__r.External_ID__c + '_' + setting.Value__c + '_' + setting.Description__c, setting.Id);
                } else if(setting.Market_Area__c == null && setting.Market_Type__c == null) {
                    mp.put('Default_' + setting.Value__c, setting.Id);
                }
            } else {
                mp.put(setting.External_ID__c, setting.Id);
            }
            settings.put(setting.RecordType.DeveloperName, mp);
        }        
        
        List<String> errors = new List<String>();
        
        List<Service_Location__c> sLocations = [select Id
                                        ,ICC_Subscriber_ID__c
                                        ,Account__r.Id
                                        ,Account__r.Customer_Detail__c
                                        ,Account__r.ICC_Account_Number__c
                                        ,Account__r.ICC_Account_Type__c
                                        ,Account__r.Billable__c
                                        ,Account__r.Owner.NTID__c
                                        ,Account__r.Agency__c
                                        ,Account__r.Industry
                                        /*,Account__r.BillingCity
                                        ,Account__r.BillingCountry
                                        ,Account__r.BillingState
                                        ,Account__r.BillingStreet
                                        ,Account__r.BillingPostalCode*/
                                        ,Customer_Detail__r.Id
                                        ,Customer_Detail__r.Market_Area__c
                                        /*,Location__r.Id
                                        ,Location__r.Building__r.Address__c
                                        ,Location__r.Building__r.Building_Hash__c
                                        ,Location__r.Building__r.City__c
                                        ,Location__r.Building__r.Postal_Code__c
                                        ,Location__r.Building__r.State__c*/
                                        ,Parent_Service_Location__r.Id
                                        ,Parent_Service_Location__r.ICC_Subscriber_ID__c
                                        ,Parent_Service_Location__r.Customer_Detail__r.Bill_Cycle__r.External_ID__c 
                                        from Service_Location__c
                                        where ICC_Subscriber_ID__c = null
                                        and Id in : orderIDsByLocationID.keyset()
                                        order by Parent_Service_Location__r.Id nulls first];

        //Populate with what we actually found (this allows already integrated subs to be added in as parents even if passed in here)
        Set<Id> serviceLocationIDs = new Set<Id>();
        for(Service_Location__c sLoc : sLocations) serviceLocationIDs.add(sLoc.Id);
                                        
        Map<Id, Order__c> orders = new Map<Id, Order__c>([select Id
                                                                ,Contract_Signed_Date__c
                                                                ,Opportunity__r.Id
                                                                ,Opportunity__r.OwnerId
                                                                ,Opportunity__r.LOA_Signed_By__r.Name
                                                            from Order__c where Id in :orderIDsByLocationID.values()]);
        
        Map<Id, Customer_Detail__c> customerDetails = new Map<Id, Customer_Detail__c>();
        Map<Id, Service_Location__c> parentServiceLocs = new Map<Id, Service_Location__c>();
        Map<Id, Boolean> accountIds = new Map<Id, Boolean>();
        
        for(Service_Location__c loc : sLocations){
            if(loc.Parent_Service_Location__c != null && !serviceLocationIDs.contains(loc.Parent_Service_Location__c))
                parentServiceLocs.put(loc.Parent_Service_Location__c, null);
            accountIds.put(loc.Account__c, accountIds.get(loc.Account__c) != null ? accountIds.get(loc.Account__c) : false);
            
            if(loc.Customer_Detail__c != null){
                customerDetails.put(loc.Customer_Detail__c, null);
                if(loc.Parent_Service_Location__c == null && loc.Customer_Detail__c != loc.Account__r.Customer_Detail__c)
                     accountIds.put(loc.Account__c, true);
            }
            else
                return new List<String>{'One or more service location has no customer detail generated which is required for integration.'};
            if(loc.Customer_Detail__r.Market_Area__c == null)
                return new List<String>{'One or more service location has no market area assigned.'};
            
            //Use the earliest available contract signed date for the account
            Id orderID = orderIDsByLocationID.get(loc.Id);
            if(orderID != null && loc.Account__c != null && orders.get(orderID) != null){
                Order__c order = orders.get(orderID);
                Id accountOrderId = orderIDsByLocationID.get(loc.Account__c);
                if(accountOrderId == null || orders.get(accountOrderId) == null || orders.get(accountOrderId).Contract_Signed_Date__c > order.Contract_Signed_Date__c)
                    orderIDsByLocationID.put(loc.Account__c, order.Id);
            }
        }

        Map<Id, Customer_Detail__c> allCustomerDetails = new Map<Id, Customer_Detail__c>();
        
        //Set<Id> forcedNonBillableAccounts = new Set<Id>();
        Map<Id, Service_Location__c> matchingServiceLoc = new Map<Id, Service_Location__c>();
        Map<Id, Account> accounts = new Map<Id, Account>();
        for(Account a : [select Id
                                ,(select Id, ICC_Subscriber_ID__c, Customer_Detail__c, Parent_Service_Location__c from Account_Locations__r)
                                ,(select Id,Description__c, OwnerId, External_ID__c from Notes__r)
                                ,ICC_Account_Number__c
                                ,ICC_Account_Type__c
                                ,Billable__c
                                ,Industry
                                /*,ShippingCity
                                ,ShippingCountry
                                ,ShippingState
                                ,ShippingStreet
                                ,ShippingPostalCode
                                ,BillingCity
                                ,BillingCountry
                                ,BillingState
                                ,BillingStreet
                                ,BillingPostalCode*/
                                ,Customer_Detail__r.Id
                                ,Customer_Detail__r.Market_Area__c
                                ,CurrencyISOCode
                                from Account where Id in : accountIds.keyset()]){
            accounts.put(a.Id, a);
            
            if(a.Customer_Detail__c != null)
                customerDetails.put(a.Customer_Detail__c, null);
            else
                return new List<String>{'One or more account has no customer detail generated which is required for integration.'};
            if(a.Customer_Detail__r.Market_Area__c == null)
                return new List<String>{'One or more account has no market area assigned.'};
            
            Service_Location__c matchingLoc;
            for(Service_Location__c sloc : a.Account_Locations__r){
                //I can't add all customer details or I will run out of memory for the biggest accounts.
                //I need to only select customer details that are parents of the customer detail I am integrating
                //and maybe the customer detail related to the location I am integrating
                for (Service_Location__c sl: sLocations) {
                    if (sl.Id == sloc.id || sl.Parent_Service_Location__c  == sloc.id) 
                		allCustomerDetails.put(sloc.Customer_Detail__c, null);
                }
                if(sloc.Customer_Detail__c == a.Customer_Detail__c)
                    matchingLoc = sloc;
            }
                                  
            if(matchingLoc != null){
                matchingServiceLoc.put(a.Id, matchingLoc);
                if(accountIds.get(a.Id)){
                    Service_Location__c reAddMatchingLoc = null;
                    for(Integer i=sLocations.size()-1; i>=0; i--){
                        Service_Location__c sLoc = sLocations[i];
                        if(sLoc.Id == matchingLoc.Id){
                            sLocations.remove(i);
                            reAddMatchingLoc = sLoc;
                        }
                        else if(sLoc.Account__c == a.Id && sLoc.Parent_Service_Location__c == null && sLoc.Customer_Detail__c != a.Customer_Detail__c){
                            sLoc.Parent_Service_Location__c = matchingLoc.Id;
                            if(!serviceLocationIDs.contains(matchingLoc.Id))
                                parentServiceLocs.put(matchingLoc.Id, null);
                        }
                    }
                    if(reAddMatchingLoc != null)
                        sLocations.add(0, reAddMatchingLoc);
                }
            }
            
            /*if(string.IsEmpty(a.ICC_Account_Number__c)){
                //Look for a level 3 to force billable
                for(Service_Location__c sloc : a.Account_Locations__r){
                    if(sloc.Parent_Service_Location__c != null && (matchingLoc == null || sloc.Parent_Service_Location__c != matchingLoc.Id))
                        forcedNonBillableAccounts.add(a.Id);
                }
            }*/
        }
        
        parentServiceLocs = new Map<Id, Service_Location__c>([select Id
                                                                    ,ICC_Subscriber_ID__c
                                                                    ,Billable__c
                                                                    from Service_Location__c
                                                                    where Id in :parentServiceLocs.keyset()]);
        
        String customerDetailIds = '';
        for (String cdid : allCustomerDetails.keyset())
            customerDetailIds = CustomerDetailIds + cdid + ',';
        
        if(customerDetails.size() > 0)
            customerDetails = new Map<Id, Customer_Detail__c>((List<Customer_Detail__c>)
                                                                (ApexUtils.retrieveObjectsFromFieldSets(Customer_Detail__c.getsObjectType()
                                                                    ,new List<Set<String>>{
                                                                        AddressUtils.CustomerDetailAddressFieldSet
                                                                        ,IntegrationUtils.CustomerDetailIntegrationFieldSet
                                                                        }
                                                                    ,'Id in (\'' + string.join(new List<Id>(customerDetails.keyset()), '\',\'') + '\')'
                                                                    ,null)));
        //allCustomerDetails is used when a child account needs to look at its parent's customer details to get bill cycle info
        //customerDetails only has information for service locations that have not been integrated so the integrated parents would
        //not be found in that set.
        if (allCustomerDetails.size() > 0)
            allCustomerDetails = new Map<Id, Customer_Detail__c>((List<Customer_Detail__c>)
                                                                (ApexUtils.retrieveObjectsFromFieldSets(Customer_Detail__c.getsObjectType()
                                                                    ,new List<Set<String>>{
                                                                        AddressUtils.CustomerDetailAddressFieldSet
                                                                        ,IntegrationUtils.CustomerDetailIntegrationFieldSet
                                                                        }
                                                                    ,'Id in (\'' + string.join(new List<Id>(allCustomerDetails.keyset()), '\',\'') + '\')'
                                                                    ,null)));           
        
        Map<Id, integraWS.SFSubscriberView> subscribers = new Map<Id, integraWS.SFSubscriberView>();
        Map<Id, integraWS.SFSubscriberView> allSubs = new Map<Id, integraWS.SFSubscriberView>();
        
        Set<Id> matchOppOwnerAccounts = new Set<Id>();
 
        Integer someBillCycleExtId = null;

        for (Integer pass = 0; pass < 2; pass++) {
            //pass 0 - handle the billable service locations, pass = 1 handle the non-billables which will refer to the billables
            for (Service_Location__c loc : sLocations) {
                Customer_Detail__c d = customerDetails.get(loc.Customer_Detail__c); 
                Customer_Detail__c alld = allCustomerDetails.get(loc.Customer_Detail__c);
                
                if (d.Bill_Cycle_External_ID__c != null) continue;
                
                if (pass == 0 && d.Billable__c == true) {
                    Integer billCycleExId = getBillCycle(d, billCycles);

                    if (billCycleExId != -1) {
                        someBillCycleExtId = billCycleExId;
                        d.Bill_Cycle_External_ID__c = billCycleExId;
                        alld.Bill_Cycle_External_ID__c = billCycleExId;
                    }
 
                } else if (pass == 1 && d.Billable__c != true) {
                    Account a = accounts.get(loc.Account__c);
                    Customer_Detail__c acd = customerDetails.get(a.Customer_Detail__c);
                    
                    if (acd.Bill_Cycle_External_ID__c == null) {
                        acd.Bill_Cycle_External_ID__c = getBillCycle(acd, billCycles);
                        if (acd.Bill_Cycle_External_ID__c == -1) acd.Bill_Cycle_External_ID__c = someBillCycleExtId;
                    }
                    
                    if (loc.Parent_Service_Location__c == null) {
                        if (acd.Bill_Cycle_External_ID__c != null) {
                            d.Bill_Cycle_External_ID__c = acd.Bill_Cycle_External_ID__c;
                        }
                    } else {
                        Customer_Detail__c parentCD = allCustomerDetails.get(loc.Parent_Service_Location__r.Customer_Detail__c);
                        if (parentCD == null) return new List<String>{'Could not retrieve parent customer detail: ' + loc.Parent_Service_Location__r.Customer_Detail__c + ' in (' + customerDetailIds + ')'};
                        if (parentCD.Bill_Cycle__c == null) {
                            if (parentCD.Bill_Cycle_External_ID__c == null) {
                                return new List<String>{'Parent Bill Cycle is not set'};  
                            } else {
                                d.Bill_Cycle_External_ID__c =  parentCD.Bill_Cycle_External_ID__c;
                            }
                        } else {
                            d.Bill_Cycle_External_ID__c = integer.valueOf(allCustomerDetails.get(loc.Parent_Service_Location__r.Customer_Detail__c).Bill_Cycle__r.External_ID__c);
                        }
                    }
                    if (d.Bill_Cycle_External_ID__c == null) {
                        d.Bill_Cycle_External_ID__c = someBillCycleExtId == null? 70: someBillCycleExtId;
                    }
               }
            }
        }
        
        for (String key: customerDetails.keySet()) {
            Customer_Detail__c thisDetail = customerDetails.get(key);
            
            if (thisDetail.Bill_Cycle_External_ID__c != null) continue;
            thisDetail.Bill_Cycle_External_ID__c = getBillCycle(thisDetail, BillCycles);
          
            if (thisDetail.Bill_Cycle_External_ID__c == -1 && thisDetail.Market_Area__r.Name == 'National')
                thisDetail.Bill_Cycle_External_ID__c = someBillCycleExtId == null ? 70: someBillCycleExtId;   
        }
        
        for(Service_Location__c loc : sLocations){
            Account a = accounts.get(loc.Account__c);
            Customer_Detail__c d = customerDetails.get(loc.Customer_Detail__c);
            Order__c ord = orderIDsByLocationID.get(loc.Id) != null ? orders.get(orderIDsByLocationID.get(loc.Id)) : null;
 
            Boolean matchOppOwner = matchOppOwnerAccounts.contains(a.Id);
            if(ord != null){
                if(!matchOppOwner && string.isEmpty(a.ICC_Account_Number__c) && ord.Opportunity__c != null){
                    matchOppOwner = true;
                    matchOppOwnerAccounts.add(a.Id);
                    a.OwnerId = ord.Opportunity__r.OwnerId;
                    if(matchingServiceLoc.get(a.Id) != null) matchingServiceLoc.get(a.Id).Owner__c = a.OwnerId;
                    if(customerDetails.get(a.Customer_Detail__c) != null) customerDetails.get(a.Customer_Detail__c).Owner__c = a.OwnerId;
                }
                if(matchOppOwner) d.Owner__c = loc.Owner__c = a.OwnerId;
            }
            
            if(loc.Customer_Detail__c == a.Customer_Detail__c){
                integraWS.SFSubscriberView locSub = buildSFSubscriberViewFromServiceLocationWithAccountInfo(loc, null, d, ord, billCycles);
 
                subscribers.put(loc.Id, locSub);
                allSubs.put(loc.Id, locSub);
            }
            else{
                Service_Location__c matchingLoc = matchingServiceLoc.get(a.Id);
                
                Boolean parentIsAccount;
                integraWS.SFSubscriberView p;
                if(loc.Parent_Service_Location__c == null){
                    parentIsAccount = matchingLoc == null;
                    p = allSubs.get(parentIsAccount ? a.Id : matchingLoc.Id);
                }
                else{
                    parentIsAccount = false;
                    p = allSubs.get(loc.Parent_Service_Location__c);
                }
                
                if(p == null){
                    if(parentIsAccount){
                        if(!string.IsEmpty(a.ICC_Account_Number__c)){
                            p = new integraWS.SFSubscriberView();
                            p.SalesforceID = matchingLoc != null ? matchingLoc.Id : a.Id;
                            p.SubscriberId = integer.valueOf(a.ICC_Account_Number__c);
                            p.Children = new integraWS.ArrayOfSFSubscriberView();
                            p.Children.SFSubscriberView = new list<integraWS.SFSubscriberView>();
                        }
                        else{
                            p = ICCWrapper.setSubscriberValuesFromAccount(a, customerDetails.get(a.Customer_Detail__c));
                            p.LOAEffectiveDate = p.DateOfSale = (ord != null && ord.Contract_Signed_Date__c != null ? ord.Contract_Signed_Date__c : DateTime.now());
                            p.LOASignedBy = (ord != null && ord.Opportunity__c != null && ord.Opportunity__r.LOA_Signed_By__c != null ? ord.Opportunity__r.LOA_Signed_By__r.Name : d.LOA_Signed_By__c);
                        }
                       
                        //p.Billable = a.Billable__c && !forcedNonBillableAccounts.contains(a.Id);
                        subscribers.put(a.Id, p);
                        allSubs.put(a.Id, p);
                    }
                    else{
                        Service_Location__c parentLoc = parentServiceLocs.get(loc.Parent_Service_Location__c != null ? loc.Parent_Service_Location__c : matchingLoc.Id);
                        if(parentLoc == null || parentLoc.ICC_Subscriber_ID__c == null){
                            errors.add(loc.Id + ': This location cannot integrate without its parent location.');
                            continue;
                        }
                        else{
                            p = new integraWS.SFSubscriberView();
                            p.SalesforceID = parentLoc.Id;
                            p.SubscriberId = integer.valueOf(parentLoc.ICC_Subscriber_ID__c);
                            p.Children = new integraWS.ArrayOfSFSubscriberView();
                            p.Children.SFSubscriberView = new list<integraWS.SFSubscriberView>();
                            
                            subscribers.put(parentLoc.Id, p);
                            allSubs.put(parentLoc.Id, p);
                        }
                    }
                }
                
                if(p != null){
                    integraWS.SFSubscriberView locSub = buildSFSubscriberViewFromServiceLocationWithAccountInfo(loc, p.SubscriberId, d, ord, billCycles);
 
                    //locSub.Billable = p.Billable != null ? !p.Billable : null;
                    p.Children.SFSubscriberView.add(locSub);
                    allSubs.put(loc.Id, locSub);
                }
            }
        }
 
        system.debug('Subs: ' + subscribers);
        if(subscribers.size() > 0){
             List<integraWS.SFSubscriberView> subscriberResults = !Test.isRunningTest()
                                                                    ? ICCWrapper.updateSubscribers(subscribers.values(), sessionID)
                                                                    : Test_IntegrationUtils.getMockSubscriberResults(subscribers.values());
            
            system.debug('Callout results: ' + subscriberResults);
            
            Map<Id, Account> updatedAccounts = new Map<Id, Account>();
            Map<Id, Service_Location__c> updatedLocs = new Map<Id, Service_Location__c>();
            
            Map<Id, Integer> subIDByRecordId = new Map<Id, Integer>();
            List<integraWS.SFSubscriberView> flattenedResults = ICCWrapper.getFlattenedSFSubscriberViewList(subscriberResults);
            Map<String, integraWS.SFSubscriberView> resultBySubscriberID = new Map<String, integraWS.SFSubscriberView>();
            Map<Id, Service_Location__c> sLocationsByID = new Map<Id, Service_Location__c>(sLocations);
            for(integraWS.SFSubscriberView result: flattenedResults){
                if(result.SubscriberId != 0)
                    resultBySubscriberID.put(string.valueOf(result.SubscriberId), result);
                
                if(string.IsEmpty(result.SalesforceId))
                    continue;
                else
                    subIDByRecordId.put(result.SalesforceId, result.SubscriberId);
                
                if(!string.IsEmpty(result.ResultMessage)){
                    errors.add(result.SalesforceId + ': ' + result.ResultMessage);
                    continue;
                }
                
                if(result.SubscriberId == 0) continue;
                
                Account a;
                Service_Location__c loc = sLocationsByID.get(result.SalesforceId);
                
                if(loc != null){
                    updatedLocs.put(loc.Id, loc);
                    
                    a = accounts.get(loc.Account__c);
                    if(a != null && a.Customer_Detail__c != loc.Customer_Detail__c)
                        a = null;
                }
                else
                    a = accounts.get(result.SalesforceId);
                
                if(a != null){
                    a.ICC_Account_Type__c = result.SubscriberType;
                    
                    updatedAccounts.put(a.Id, a);
                }
            }
            
            //Update the accounts that were only updates
            if(resultBySubscriberID.size() > 0){
                for(Account a: [select Id, ICC_Account_Number__c, Billable__c, ICC_Account_Type__c from Account where ICC_Account_Number__c in : resultBySubscriberID.keyset() and Id not in : updatedAccounts.keyset()]){
                    integraWS.SFSubscriberView result = resultBySubscriberID.get(a.ICC_Account_Number__c);
                    a.ICC_Account_Type__c = result.SubscriberType;
                    a.Billable__c = result.Billable;
                    updatedAccounts.put(a.Id, a);
                }
            }
            
            //Integrate settings, write back details
            List<Customer_Detail__c> updatedDetails = new List<Customer_Detail__c>();
            List<Customer_Contact__c> updatedCustomerContacts = new List<Customer_Contact__c>();
            List<Customer_Setting__c> updatedSettings = new List<Customer_Setting__c>();
            List<Customer_Setting__c> updatedTaxInfos = new List<Customer_Setting__c>();
            List<Note__c> updatedNotes = new List<Note__c>();
            
            Map<Id, Customer_Contact__c> customerContactsToIntegrate = new Map<Id, Customer_Contact__c>();
            Map<Id, String> subscriberIDByCustomerContactID = new  Map<Id, String>();
            
            if(updatedAccounts.size() > 0 || updatedLocs.size() > 0){
                Map<String, Schema.SObjectField> cdFieldMap = Customer_Detail__c.getsObjectType().getDescribe().fields.getMap();
 //               Map<String, Map<String, Id>> settings = new Map<String, Map<String, Id>>();
                
                Map<String, Id> marketAreaIDByICCID = new Map<String, Id>();
                Map<String, Id> marketAreaIDByProvID = new Map<String, Id>();
                for(Market_Area__c ma : [select Id, ICCMarketAreaID__c, ProvMarketAreaID__c from Market_Area__c]){
                    if(ma.ICCMarketAreaID__c != null)
                        marketAreaIDByICCID.put(string.valueOf(ma.ICCMarketAreaID__c), ma.Id);
                    if(!string.IsEmpty(ma.ProvMarketAreaID__c))
                        marketAreaIDByProvID.put(ma.ProvMarketAreaID__c, ma.Id);
                }
             
                Map<String, User> usersByNTID = new Map<String, User>();
                for(User u : [select Id, NTID__c from User where NTID__c != null])
                    usersByNTID.put(u.NTID__c, u);
                
                Map<Id, Customer_Setting__c> subSettings = new Map<Id, Customer_Setting__c>();
                List<integraWS.SFSubscriberSettingView> settingViews = new List<integraWS.SFSubscriberSettingView>();
                Map<Id, Customer_Setting__c> taxInfos = new Map<Id, Customer_Setting__c>();
                List<integraWS.SFSubscriberTaxInformationView> taxInfoViews = new List<integraWS.SFSubscriberTaxInformationView>();
                //List<integraWS.SFSubscriberAddressView> addressViews = new List<integraWS.SFSubscriberAddressView>();
                Map<Id, Note__c> notes = new Map<Id, Note__c>();
                List<integraWS.SFRemarkView> remarkViews = new List<integraWS.SFRemarkView>();
                Set<String> extraIntegrationFields = new Set<String>{'ICC_Subscriber_ID__c'
                                                                    ,'Bill_Cycle__r.Id'
                                                                    ,'Billing_ID__c'
                                                                    ,'Care_Organization__r.Id'
                                                                    ,'Collection_Code__r.Id'
                                                                    ,'Collection_Rep__r.Id'
                                                                    ,'Credit_Approved_Date__c'
                                                                    ,'Credit_Bureau__c'
                                                                    ,'Credit_Bureau_Not_Available__c'
                                                                    ,'Credit_Checked_By__r.Id'
                                                                    ,'Credit_Class__c'
                                                                    ,'Credit_Limit__c'
                                                                    ,'Credit_Score__c'
                                                                    ,'Credit_Score_Date__c'
                                                                    ,'Disputed_Amount__c'
                                                                    ,'Exchange__r.Id'
                                                                    ,'Legacy_ID__c'
                                                                    ,'Market_Type__r.Id'
                                                                    ,'Market_Subtype__r.Id'
                                                                    ,'Acquired_Company_Biller__c'
                                                                    ,'Market_Area__r.Name'
                                                                    ,'MSS_Account_ID__c'
                    												,'Accounts_Receivable_System__c'
                                                                    ,'(select Id from Accounts__r)'
                                                                    ,'(select Id from Service_Locations__r)'
                                                                    ,'(select Id,External_ID__c,Reference_ID__c,Start_Date__c,End_Date__c,Exempt_Form_Provided__c,Value__c,RecordType.DeveloperName from Customer_Settings__r)'
                                                                    ,'(select Id,ICC_Contact_ID__c,Email__c,Phone__c,Contact_Type__c,Contact__c,Customer_Detail__c from Customer_Contacts__r where Contact_Type__c != null and Contact__c != null)'};
                
                for(Customer_Detail__c detail : (List<Customer_Detail__c>)(ApexUtils.retrieveObjectsFromFieldSets(Customer_Detail__c.getsObjectType()
                                                                                                        ,new List<Set<String>>{ AddressUtils.CustomerDetailAddressFieldSet, extraIntegrationFields}
                                                                                                        ,'Id in (\'' + string.join(new List<Id>(customerDetails.keyset()), '\',\'') + '\')'
                                                                                                        ,null))){
                    
                    Account a = detail.Accounts__r.size() > 0 ? updatedAccounts.get(detail.Accounts__r[0].Id) : null;
                    Service_Location__c sloc = detail.Service_Locations__r.size() > 0 ? updatedLocs.get(detail.Service_Locations__r[0].Id) : null;
                    
                    String subID = string.valueOf((a != null && subIDByRecordId.get(a.Id) != null && subIDByRecordId.get(a.Id) != 0)
                                    ? subIDByRecordId.get(a.Id)
                                    :(sloc != null && subIDByRecordId.get(sloc.Id) != null && subIDByRecordId.get(sloc.Id) != 0)
                                        ? subIDByRecordId.get(sloc.Id)
                                        : null);
                    
                    integraWS.SFSubscriberView result = (subID != null && subID != '0') ? resultBySubscriberID.get(subID) : null;
               
                    if(result != null){
                        if(detail.ICC_Subscriber_ID__c != subID){
                            detail.ICC_Subscriber_ID__c = subID;
                            detail.LOA_Signed_By__c = result.LOASignedBy;
                            detail.LOA_Effective_Date__c = result.DateOfSale != null ? result.DateOfSale.date() : null;
                            
                            /*for(integraWS.SFSubscriberAddressView addr : AddressUtils.getSFSubscriberAddressViewsFromCustomerDetail(detail, result.SubscriberId, result.Billable))
                                addressViews.add(addr);*/
                            
                            for(Customer_Contact__c cc : detail.Customer_Contacts__r != null ? detail.Customer_Contacts__r : new List<Customer_Contact__c>()){
                                customerContactsToIntegrate.put(cc.Id, cc);
                                subscriberIDByCustomerContactID.put(cc.Id, subID);
                            }
                            
                            for(Customer_Setting__c setting : detail.Customer_Settings__r != null ? detail.Customer_Settings__r : new List<Customer_Setting__c>()){
                                if(setting.RecordType.DeveloperName == 'Subscriber_Setting'){
                                    subSettings.put(setting.Id, setting);
                                    settingViews.add(ICCWrapper.getSubscriberSettingFromCustomerSetting(setting, subID));
                                }
                                else if(setting.RecordType.DeveloperName == 'Tax_Information'){
                                    taxInfos.put(setting.Id, setting);
                                    taxInfoViews.add(ICCWrapper.getSubscriberTaxInformationFromCustomerSetting(setting, subID));
                                }
                            }
                            
                            for(Note__c note : a != null && a.Notes__r != null ? a.Notes__r : new List<Note__c>()){
                                notes.put(note.Id, note);
                                integraWS.SFRemarkView remark = new integraWS.SFRemarkView();
                                remark.SalesforceId = note.Id;
                                remark.ParentExternalID = integer.valueOf(subID);
                                remark.Remark = note.Description__c;
                                remark.CreateUser = GlobalUtilities.users.get(note.OwnerId).NTID__c;
                                remarkViews.add(remark);
                            }
                        }
                        Boolean parentIsBillable = (!result.Billable && result.ParentSubscriberId != null);
                
                        if(!parentIsBillable){
                            if (detail.Market_Area__c != null && detail.Market_Area__r.Name == 'National') {
                                if (detail.Acquired_Company_Biller__c == null) {
                                    if (detail.Bill_Cycle__c == null)
                                        detail.Bill_Cycle__c = result.BillCycleID == 19 ? settings.get('Bill_Cycle_Schedule').get(result.MarketAreaID + '_' + result.MarketTypeID + '_19_ICMS'):settings.get('Bill_Cycle_Schedule').get(result.MarketAreaID + '_' + result.MarketTypeID + '_27_IBIS'); 
                                    else
                                        detail.Bill_Cycle__c = detail.Bill_Cycle__c ; //just to document that we are keeping what is already set
                                } else {
                                    System.Debug('Setting a national bill cycle');
                                    
                                    detail.Bill_Cycle__c = result.BillCycleID != null && result.BillCycleID > 0 && detail.Acquired_Company_Biller__c != null ? settings.get('Bill_Cycle_Schedule').get(result.MarketAreaID + '_' + result.MarketTypeID + '_' + result.BillCycleID + '_' + detail.Acquired_Company_Biller__c + '-' + detail.Accounts_Receivable_System__c) : detail.Bill_Cycle__c;                                
                                }
                            } else {
                                detail.Bill_Cycle__c = result.BillCycleID != null ? settings.get('Bill_Cycle_Schedule').get(result.MarketAreaID + '_' + result.MarketTypeID + '_' + result.BillCycleID ) : null;
                            }
                            //Else use the default for that cycle
                            detail.Bill_Cycle__c = detail.Bill_Cycle__c != null ? detail.Bill_Cycle__c : settings.get('Bill_Cycle_Schedule').get('Default_' + result.BillCycleID);
                        }
                         
                        //Remove the billing address values
                        if(!result.Billable){
                            for(String key : AddressUtils.CustomerDetailFieldSetAddressTypes.keyset()){
                                for(String fName : cdFieldMap.keyset()){
                                    if(fName.startsWith(key))
                                        detail.put(fName, '');
                                }
                            }
                        }
                        
                        detail.Billable__c = result.Billable;
                       // detail.Billing_ID__c = result.BillingID != null ? string.valueOf(result.BillingID) : null;
                        detail.Care_Access_Code__c = result.CareAccessCode;
                        detail.Care_Organization__c = result.CareOrgID != null ? settings.get('Care_Organization').get(string.valueOf(result.CareOrgID)) : null;
                        detail.Collection_Code__c = result.CollectionCodeID != null ? settings.get('Collection_Code').get(string.valueOf(result.CollectionCodeID)) : null;
                        detail.Collection_Rep__c = !string.IsEmpty(result.CollectionRep) && usersByNTID.get(result.CollectionRep) != null
                                                    ? usersByNTID.get(result.CollectionRep).Id
                                                    : null;
                        detail.Credit_Checked_By__c = !string.IsEmpty(result.CreditCheckedBy) && usersByNTID.get(result.CreditCheckedBy) != null
                                                        ? usersByNTID.get(result.CreditCheckedBy).Id
                                                        : null;
                        detail.Credit_Bureau__c = result.CreditBureau;
                        detail.Credit_Bureau_Not_Available__c = result.CreditBureauNotAvailable != null ? result.CreditBureauNotAvailable : false;
                        detail.Credit_Class__c = result.CreditClass;
                        detail.Credit_Limit__c = result.CreditLimit;
                        detail.Credit_Score__c = result.CreditScore;
                        detail.Credit_Score_Date__c = result.CreditScoreDate;
                        detail.Credit_Approved_Date__c = result.CreditApprovedDate != null ? Date.newinstance(result.CreditApprovedDate.year(), result.CreditApprovedDate.month(), result.CreditApprovedDate.day()) : null;
                        detail.Disputed_Amount__c = result.DisputedAmount;
                        detail.Exchange__c = result.ExchangeID != null ? settings.get('Exchange').get(string.valueOf(result.ExchangeID)) : null;
                        detail.Legacy_ID__c = result.LegacyID != null ? result.LegacyID : detail.Legacy_ID__c;
                        detail.Market_Area__c = result.MarketAreaID != null && marketAreaIDByICCID.get(string.valueOf(result.MarketAreaID)) != null
                                                ? marketAreaIDByICCID.get(string.valueOf(result.MarketAreaID))
                                                : detail.Market_Area__c;
                        detail.Prov_Market_Area__c = result.ProvMarketAreaID != null ? marketAreaIDByProvID.get(string.valueOf(result.ProvMarketAreaID)) : detail.Prov_Market_Area__c;
                        detail.Market_Type__c = result.MarketTypeID != null ? settings.get('Market_Type').get(string.valueOf(result.MarketTypeID)) : null;
                        detail.Market_Subtype__c = result.EPCSubTypeID != null ? settings.get('Market_Subtype').get(string.valueOf(result.EPCSubTypeID)) : null;
                        detail.MSS_Account_ID__c = result.MSSAccountID;
                        updatedDetails.add(detail);
                    }
                }
                
                if(customerContactsToIntegrate.size() > 0){
                    try{
                        updatedCustomerContacts = CustomerContactTriggers.integrateContacts(customerContactsToIntegrate, subscriberIDByCustomerContactID, sessionID);
                    }
                    catch(Exception e){ errors.add(e.getMessage()); }
                }
                
                if(settingViews.size() > 0){
                    try{
                        for(integraWS.SFSubscriberSettingView result : ICCWrapper.updateSubscriberSettings(settingViews)){
                            if(string.IsEmpty(result.SalesforceID) || result.ID == null || result.ID == 0){
                                errors.add(string.IsEmpty(result.ResultMessage) ? 'Unable to save subscriber setting \'' + result.SalesforceID + '\'' : result.ResultMessage);
                                continue;
                            }
                            
                            Customer_Setting__c subSetting = subSettings.get(result.SalesforceID);
                            subSetting.External_ID__c = string.valueOf(result.ID);
                            updatedSettings.add(subSetting);
                        }
                    }
                    catch(Exception e){ errors.add(e.getMessage()); }
                }
                
                if(taxInfoViews.size() > 0){
                    try{
                        for(integraWS.SFSubscriberTaxInformationView result : ICCWrapper.updateSubscriberTaxInformation(taxInfoViews)){
                            if(string.IsEmpty(result.SalesforceID) || result.ID == null || result.ID == 0){
                                errors.add(string.IsEmpty(result.ResultMessage) ? 'Unable to save subscriber tax infomation \'' + result.SalesforceID + '\'' : result.ResultMessage);
                                continue;
                            }
                            
                            Customer_Setting__c taxInfo = taxInfos.get(result.SalesforceID);
                            taxInfo.External_ID__c = string.valueOf(result.ID);
                            taxInfo.Name = 'Exemption' + result.ID;
                            taxInfo.Start_Date__c = result.StartDate;
                            taxInfo.End_Date__c = result.EndDate;
                            updatedTaxInfos.add(taxInfo);
                        }
                    }
                    catch(Exception e){ errors.add(e.getMessage()); }
                }
                
                /*if(addressViews.size() > 0){
                    try{
                        for(integraWS.SFSubscriberAddressView result : ICCWrapper.updateSubscriberAddresses(addressViews, UserInfo.getSessionId())){
                            if(string.IsEmpty(result.SalesforceID) || !string.IsEmpty(result.ResultMessage))
                                errors.add(string.IsEmpty(result.ResultMessage) ? 'Unable to save subscriber address \'' + result.SalesforceID + '\'' : result.ResultMessage);
                        }
                    }
                    catch(Exception e){ errors.add(e.getMessage()); }
                }*/
                
                if(remarkViews.size() > 0){
                    try{
                        for(integraWS.SFRemarkView result : ICCWrapper.createRemarks(remarkViews, 'Subscriber', sessionID)){
                            if(result.ID == 0 || string.IsEmpty(result.SalesforceID)){
                                errors.add('Note \'' + result.SalesforceID + '\' could not be created as a subscriber remark');
                                continue;
                            }
                            
                            Note__c note = notes.get(result.SalesforceID);
                            note.External_ID__c = string.valueOf(result.ID);
                            updatedNotes.add(note);
                        }
                    }
                    catch(Exception e){ errors.add(e.getMessage()); }
                }
            }
            
            Boolean accountIntegrationDisabled = AccountTriggers.DisableIntegration;
            Boolean customerDetailIntegrationDisabled = CustomerDetailTriggers.IntegrationDisabled;
            Boolean customerDetailUpdateAddresses = CustomerDetailTriggers.UpdateAddresses;
            Boolean serviceLocIntegrationDisabled = ServiceLocationTriggers.DisableIntegration;
            
            SecurityUtils.AllowTemporaryOwnershipUpdates = true;
            AccountTriggers.DisableIntegration = true;
            CustomerDetailTriggers.IntegrationDisabled = true;      //Disable most integration but...
            CustomerDetailTriggers.UpdateAddresses = true;          //...allow addresses to flow through so they can pass asynch.
            ServiceLocationTriggers.DisableIntegration = true;
            
            saveAndGatherErrors(updatedAccounts.values(), errors, 'Account');
            saveAndGatherErrors(updatedLocs.values(), errors, 'Service Location');
            saveAndGatherErrors(updatedDetails, errors, 'Customer Detail');
            saveAndGatherErrors(updatedCustomerContacts, errors, 'Customer Contact');
            saveAndGatherErrors(updatedSettings, errors, 'Subscriber Setting');
            saveAndGatherErrors(updatedTaxInfos, errors, 'Subscriber Tax Information');
            saveAndGatherErrors(updatedNotes, errors, 'Note');
            
            AccountTriggers.DisableIntegration = accountIntegrationDisabled;
            CustomerDetailTriggers.IntegrationDisabled = customerDetailIntegrationDisabled;
            CustomerDetailTriggers.UpdateAddresses = customerDetailUpdateAddresses;
            ServiceLocationTriggers.DisableIntegration = serviceLocIntegrationDisabled;
            
            if(errors.size() > 0)
                system.debug('The process completed with errors: ' + errors);
        }
        return errors;
    }
     
    private static void saveAndGatherErrors(List<sObject> objs, List<String> errors, String objName){

        for(Database.SaveResult result : Database.Update(objs, false)){
            if(!result.isSuccess())
                errors.add(objName + ' save error [' + result.getId() + ']: ' + result.getErrors()[0]);
        }
    }
     
    private static integraWS.SFSubscriberView buildSFSubscriberViewFromServiceLocationWithAccountInfo(Service_Location__c loc, Integer parentSubscriberId, Customer_Detail__c detail, Order__c associatedOrder, List<Customer_Setting__c> billCycles){
        parentSubscriberId = parentSubscriberId != 0 ? parentSubscriberId : null;
        integraWS.SFSubscriberView sub = ICCWrapper.setSubscriberValuesFromCustomerDetail(new integraWS.SFSubscriberView(), detail);
        sub.ParentSubscriberId = parentSubscriberId != null ? parentSubscriberId : null;
        
        sub.SalesforceId = loc.Id;
        
        if(associatedOrder != null){
            sub.DateOfSale = sub.LOAEffectiveDate = (associatedOrder.Contract_Signed_Date__c != null ? associatedOrder.Contract_Signed_Date__c : DateTime.now());
            sub.LOASignedBy = (associatedOrder.Opportunity__c != null && associatedOrder.Opportunity__r.LOA_Signed_By__c != null ? associatedOrder.Opportunity__r.LOA_Signed_By__r.Name : null);
        }
            
        sub.SICCode = !string.IsEmpty(loc.Account__r.Industry) ? loc.Account__r.Industry : 'Z - Unclassified';
        
        sub.Children = new integraWS.ArrayOfSFSubscriberView();
        sub.Children.SFSubscriberView = new list<integraWS.SFSubscriberView>();
        
        return sub;
    }

    /* Re-integration methods */
    public static List<String> reintegrateObjects(Set<String> objectIDs){

        List<String> retval = new List<String>();
        
        List<Integration_Error__c> objErrors = [select Id, Name, ObjectID__c, Info__c, Message__c, Action__c, CreatedDate from Integration_Error__c where ObjectID__c in : objectIDs];
        Map<String, Set<String>> objActions = new Map<String, Set<String>>();
        Map<String, Set<String>> objInfos = new Map<String, Set<String>>();
        Map<String, Set<String>> objIdByTypeName = new Map<String, Set<String>>();
        
        for(Integration_Error__c error : objErrors){
            String shortID = error.ObjectID__c.substring(0, 15);    
            String sObjName = SchemaUtils.GetSObjectNameByID(error.ObjectID__c);
            if(objIdByTypeName.get(sObjName) == null)
                objIdByTypeName.put(sObjName, new Set<String>());
            objIdByTypeName.get(sObjName).add(shortID);
            
            if(objActions.get(shortID) == null)
                objActions.put(shortID, new Set<String>());
            objActions.get(shortID).add(error.Action__c);
            
            if(objInfos.get(shortID) == null)
                objInfos.put(shortID, new Set<String>());
            
            if(!string.IsEmpty(error.Info__c)){
                Set<String> info = new Set<String>(error.Info__c.split(','));
                for(String s : info)
                    objInfos.get(shortID).add(s);
            }
        }
        
        if(objErrors.size() > 0){
            if(objIdByTypeName.get('Account') != null)
                reintegrateAccounts(objIdByTypeName.get('Account'), objActions, objInfos, retval);
            if(objIdByTypeName.get('Contact') != null)
                reintegrateContacts(objIdByTypeName.get('Contact'), objActions, objInfos, retval);
            if(objIdByTypeName.get('Customer_Contact__c') != null)
                reintegrateCustomerContacts(objIdByTypeName.get('Customer_Contact__c'), objActions, objInfos, retval);
            if(objIdByTypeName.get('Customer_Detail__c') != null)
                reintegrateCustomerDetails(objIdByTypeName.get('Customer_Detail__c'), objActions, objInfos, retval);
            if(objIdByTypeName.get('Case') != null)
                reintegrateCaseNotes(objIdByTypeName.get('Case'), objActions, objInfos, retval);
            if(objIdByTypeName.get('CaseComment') != null)
                reintegrateCaseCommentNotes(objIdByTypeName.get('CaseComment'), objActions, objInfos, retval);
            if(objIdByTypeName.get('Capital_Project__c') != null)
                reintegrateCapitalProjects(objIdByTypeName.get('Capital_Project__c'), objActions, objInfos, retval);
            
            delete objErrors;
        }
        
        return retval;
    }
    
    private static void reintegrateAccounts(Set<String> ids, Map<String, Set<String>> objActions, Map<String, Set<String>> objInfos, List<String> messageList){

        Map<Id, String> accountMap = new Map<Id, String>();
        
        for(Account a : [select Id from Account where Id in :ids]){
            Set<String> objInfo = objInfos.get(string.valueof(a.Id).substring(0, 15));
            if(a != null && objInfo.size() > 0){
                messageList.add('Reintegrating account \'' + a.Id + '\' with fields: ' + objInfo);
                accountMap.put(a.Id, string.join(new List<String>(objInfo), ','));
            }
            else
                messageList.add('No integration needed for account \'' + a.Id + '\'');
        }
        
        if(accountMap.size() > 0)
            AccountTriggers.updateSubscribers(accountMap, UserInfo.getSessionId(), UserInfo.getUserEmail());
    }
    
    private static void reintegrateContacts(Set<String> ids, Map<String, Set<String>> objActions, Map<String, Set<String>> objInfos, List<String> messageList){

        List<Contact> updatedContacts = new List<Contact>();
        
        for(Contact c : [select Id, (select Id from Customer_Contacts__r where Customer_Detail__r.ICC_Subscriber_ID__c != null) from Contact where Id in :ids]){
            Set<String> objInfo = objInfos.get(string.valueof(c.Id).substring(0, 15));
            
            if(c != null && c.Customer_Contacts__r != null){
                messageList.add('Reintegrating contact \'' + c.Id + '\'');
                updatedContacts.add(c);
            }
            else
                messageList.add('No integration needed for contact \'' + c.Id + '\'');
        }
        
        if(updatedContacts.size() > 0)
            ContactTriggers.updateContacts(updatedContacts);
    }
    
    private static void reintegrateCustomerContacts(Set<String> ids, Map<String, Set<String>> objActions, Map<String, Set<String>> objInfos, List<String> messageList){

        Map<Integer, Id> deletedContactIDs = new Map<Integer, Id>();
        Set<Id> updatedContactIDs = new Set<Id>();
        Set<String> deletedIDs = new Set<String>();
        
        for(String id : ids){
            if(objActions.get(id).contains('Delete')){
                Set<String> objInfo = objInfos.get(id);
                if(objInfo.size() == 1){
                    for(String s : objInfo){
                        try{
                            Integer iccID = integer.valueOf(s);
                            deletedIDs.add(id);
                            messageList.add('Deleting customer contact with ID: ' + iccID);
                            deletedContactIDs.put(iccID, id);
                        }
                        catch(Exception e){}
                    }
                }
            }
        }
        
        for(Customer_Contact__c cc : [select Id from Customer_Contact__c
                                                    where Id in :ids
                                                    and Id not in : deletedIDs
                                                    and Customer_Detail__r.ICC_Subscriber_ID__c != null]){
            messageList.add('Reintegrating contact \'' + cc.Id + '\'');
            updatedContactIDs.add(cc.Id);
        }
        
        if(deletedContactIDs.size() > 0)
            CustomerContactTriggers.deleteCustomerContacts(deletedContactIDs, UserInfo.getSessionId(), UserInfo.getUserEmail());
        if(updatedContactIDs.size() > 0)
            CustomerContactTriggers.updateContacts(updatedContactIDs, UserInfo.getSessionId(), UserInfo.getUserEmail());
    }
    
    private static void reintegrateCustomerDetails(Set<String> ids, Map<String, Set<String>> objActions, Map<String, Set<String>> objInfos, List<String> messageList){

        Map<Id, String> cdMap = new Map<Id, String>();
        
        for(Customer_Detail__c cd : [select Id from Customer_Detail__c where Id in :ids]){
            Set<String> objInfo = objInfos.get(string.valueof(cd.Id).substring(0, 15));
            if(cd != null && objInfo.size() > 0){
                messageList.add('Reintegrating customer detail \'' + cd.Id + '\' with fields: ' + objInfo);
                cdMap.put(cd.Id, string.join(new List<String>(objInfo), ','));
            }
            else
                messageList.add('No integration needed for customer detail \'' + cd.Id + '\'');
        }
        
        if(cdMap.size() > 0)
            CustomerDetailTriggers.updateSubscribers(cdMap, UserInfo.getSessionId(), UserInfo.getUserEmail());
    }
        
    private static void reintegrateCaseNotes(Set<String> ids, Map<String, Set<String>> objActions, Map<String, Set<String>> objInfos, List<String> messageList){
        Map<Boolean, Set<Id>> IsClosedNoteToCaseId = new Map<Boolean, Set<Id>>();
        for(String id : objInfos.keySet()){
            Set<String> infos = objInfos.get(id);
            Boolean closed = (infos != null && infos.size() > 0 && infos.contains('Closed'));
            if(IsClosedNoteToCaseId.get(closed) == null)
                IsClosedNoteToCaseId.put(closed, new Set<Id>());
            Set<Id> caseIds = IsClosedNoteToCaseId.get(closed);
            caseIds.add(id);
            IsClosedNoteToCaseId.put(closed, caseIds);
            messageList.add('Resending ' + (closed? 'Closed' : 'Opened') + ' Note for Case Id: ' + id + 'to ICC.');
        }
        if(IsClosedNoteToCaseId.size() > 0)
            CaseTriggers.resendCaseComments(IsClosedNoteToCaseId);
    }
    
    private static void reintegrateCaseCommentNotes(Set<String> ids, Map<String, Set<String>> objActions, Map<String, Set<String>> objInfos, List<String> messageList){
        Set<Id> caseIds = new Set<Id>();
        for(String id : ids){
            caseIds.add(id);
        }
        CaseCommentTriggers.resendCaseComments(caseIds);
    }
    
    private static void reintegrateCapitalProjects(Set<String> ids, Map<String, Set<String>> objActions, Map<String, Set<String>> objInfos, List<String> messageList){
        Set<Id> capProjIds = new Set<Id>();
        for(String id: ids){
            capProjIds.add(id);
        }
        CapitalProjectTriggers.AutoGenerateICert(capProjIds, UserInfo.getSessionId());
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_IntegrationUtils(); }
    
    public static Integer getBillCycle(Customer_Detail__c d, List<Customer_Setting__c> billCycles) {
        Integer notFound = -1;
        
        if (d.Market_Area__r.Name == 'National' && String.isNotBlank(d.Acquired_Company_Biller__c) && String.isNotBlank(d.Accounts_Receivable_System__c)) {
            for (Customer_Setting__c billCycle: billCycles) {
                if (billCycle.Market_Area__c == d.Market_Area__c && billCycle.Market_Type__c == d.Market_Type__c && billCycle.Description__c == (d.Acquired_Company_Biller__c + '-' + d.Accounts_Receivable_System__c))
                    return integer.ValueOf(billCycle.External_ID__c); 
            }
        } else if (d.Market_Area__r.Name == 'National' && (String.isBlank(d.Acquired_Company_Biller__c) || String.isBlank(d.Accounts_Receivable_System__c))) {
            return notFound;    
        } else {
            for (Customer_Setting__c billCycle: billCycles) {
                if (billCycle.Market_Area__c == d.Market_Area__c && billCycle.Market_Type__c == d.Market_Type__c)
                    return integer.ValueOf(billCycle.External_ID__c);
            }
        }
        
        return notFound;
    }
}