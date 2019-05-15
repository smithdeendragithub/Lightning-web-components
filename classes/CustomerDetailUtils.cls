public without sharing class CustomerDetailUtils{
    public static final String COUNTRY_CA = 'CA';
    public static final String COUNTRY_CAN = 'CAN';
    public static final String COUNTRY_US = 'US';
    public static final String LANGUAGE_ENGLISH = 'English';
    
    public static final String PAYMENT_TERM_US_DEFAULT = '23';
    public static final String PAYMENT_TERM_CA_DEFAULT = '30';    
    
    public static Boolean checkRelatedObjectUpdated(List<sObject> tNew, Map<Id, sObject> tOldMap, Boolean accountMode){
        Boolean valid = true;
        Map<Id, Set<Integer>> customerDetailIDs = new Map<Id, Set<Integer>>();
        Map<Id, Set<Id>> relatedToDetailMap = new Map<Id, Set<Id>>();
        
        for(Integer i=0; i<tNew.size(); i++){
            sObject aNew = tNew[i];
            sObject aOld = aNew.Id != null ? tOldMap.get(aNew.Id) : null;
            
            String cdNew = string.valueOf(aNew.get('Customer_Detail__c'));
            if(cdNew != null && (aOld == null || string.valueOf(aOld.get('Customer_Detail__c')) != cdNew)){
                Set<Integer> cdIDSet = customerDetailIDs.get(cdNew) != null ? customerDetailIDs.get(cdNew) : new Set<Integer>();
                cdIDSet.add(i);
                customerDetailIDs.put(cdNew, cdIDSet);
                
                if(aNew.Id != null){
                    Set<Id> relatedToMap = relatedToDetailMap.get(cdNew) != null ? relatedToDetailMap.get(cdNew) : new Set<Id>();
                    relatedToMap.add(aNew.Id);
                    relatedToDetailMap.put(cdNew, relatedToMap);
                }
            }
        }
        
        if(customerDetailIDs.size() > 0){
            Set<Id> cdIDs = customerDetailIDs.keyset();
            String cRelate = (accountMode ? 'Accounts__r' : 'Service_Locations__r');
            for(Customer_Detail__c cd : (List<Customer_Detail__c>)Database.query('select Id, (select Id from ' + cRelate + ') from Customer_Detail__c where Id in : cdIDs')){
                Set<Id> relatedToDetail = relatedToDetailMap.get(cd.Id) != null ? relatedToDetailMap.get(cd.Id) : new Set<Id>();
                List<sObject> cr = cd.getSObjects(cRelate);
                for(SObject o : cr != null ? cr : new List<sObject>()){
                    if(tOldMap.get(o.Id) == null)
                        relatedToDetail.add(o.Id);
                }
                
                Boolean errored = customerDetailIDs.get(cd.Id).size() > 1;
                if(!errored){
                    for(Integer i : customerDetailIDs.get(cd.Id))
                        errored = relatedToDetail.size() > 0 && (tNew[i].Id == null || !relatedToDetail.contains(tNew[i].Id) || relatedToDetail.size() > 1);
                }
                
                if(errored){
                    valid = false;
                    for(Integer i : customerDetailIDs.get(cd.Id))
                        tNew[i].addError('No more than 1 ' + (accountMode ? 'account' : 'service location') + ' can be associated with a customer detail object.');
                }
            }
        }
        
        return valid;
    }
    
    public static Boolean cloneCustomerDetails(Set<Id> recordsToUpdate, String newSubID){
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>([select Id, Customer_Detail__c, Default_NAA_Exempt__c from Account where Id in: recordsToUpdate]);
        Map<Id, Service_Location__c> serviceLocsToUpdate = new Map<Id, Service_Location__c>([select Id, Customer_Detail__c, Account__r.Default_NAA_Exempt__c from Service_Location__c where Id in: recordsToUpdate]);
        
        if(accountsToUpdate.size() > 0 || serviceLocsToUpdate.size() > 0){
            Map<Id, Customer_Detail__c> details = new Map<Id, Customer_Detail__c>();
            for(Account a : accountsToUpdate.values()){
                if(a.Customer_Detail__c != null)
                    details.put(a.Customer_Detail__c, null);
            }
            for(Service_Location__c sLoc : serviceLocsToUpdate.values()){
                if(sLoc.Customer_Detail__c != null)
                    details.put(sLoc.Customer_Detail__c, null);
            }
            
            details = new Map<Id, Customer_Detail__c>((List<Customer_Detail__c>)ApexUtils.retrieveFullObjects(Customer_Detail__c.getsObjectType(), 'Id in (\'' + string.join(new List<Id>(details.keyset()), '\',\'') + '\')'));
            Map<Id, Customer_Contact__c> responsiblePartyByCustomerDetail = new Map<Id, Customer_Contact__c>();
            for(Customer_Contact__c cc : [select Customer_Detail__c, Contact__c, Phone__c, Email__c from Customer_Contact__c where Customer_Detail__c in : details.keyset()])
                responsiblePartyByCustomerDetail.put(cc.Customer_Detail__c, cc);
            
            List<Customer_Detail__c> detailsToInsert = new List<Customer_Detail__c>();
            List<Id> relatedObjects = new List<Id>();
            List<Id> clonedFromIDs = new List<Id>();
            
            for(Id id : recordsToUpdate){
                Account a = accountsToUpdate.get(id);
                Service_Location__c sLoc = serviceLocsToUpdate.get(id);
                
                if(a == null && sLoc == null) continue;
                
                Customer_Detail__c detail = details.get(a != null && a.Customer_Detail__c != null ? a.Customer_Detail__c : sLoc.Customer_Detail__c);
                Customer_Detail__c cloned = (Customer_Detail__c)ApexUtils.deepCopyFields(Customer_Detail__c.getSObjectType(), (sObject)detail, (sObject)new Customer_Detail__c(ICC_Subscriber_ID__c = newSubID), new Set<String>{'Billing_ID__c', 'Care_Access_Code__c', 'ICC_Subscriber_ID__c', 'Integration_Status__c', 'Language_Preference__c'});
                
                Id objID = a != null ? a.Id : sLoc.Id;
                system.debug('Cloning the customer detail field for ' + objID);
                detailsToInsert.add(cloned);
                relatedObjects.add(objID);
                clonedFromIDs.add(detail.Id);
            }
            
            Boolean success = true;
            if(detailsToInsert.size() > 0){
                for(Database.SaveResult result : Database.Insert(detailsToInsert, false))
                    success = success && result.isSuccess();
                
                List<Customer_Setting__c> settingsToCreate = new List<Customer_Setting__c>();
                List<Customer_Contact__c> responsiblePartiesToCreate = new List<Customer_Contact__c>();
                for(Integer i=0; i<detailsToInsert.size(); i++){
                    Account a = accountsToUpdate.get(relatedObjects.get(i));
                    Service_Location__c sLoc = serviceLocsToUpdate.get(relatedObjects.get(i));
                    
                    Customer_Detail__c detail = detailsToInsert.get(i);
                    Customer_Contact__c clonedFromRespParty = responsiblePartyByCustomerDetail.get(clonedFromIDs.get(i));
                    if(clonedFromRespParty != null){
                        responsiblePartiesToCreate.add(new Customer_Contact__c(
                                                            Contact__c = clonedFromRespParty.Contact__c
                                                            ,Email__c = clonedFromRespParty.Email__c
                                                            ,Phone__c = clonedFromRespParty.Phone__c
                                                            ,Contact_Type__c = ICCWrapper.ResonsiblePartyContactType
                                                            ,Customer_Detail__c = detail.Id
                                                            ));
                    }
                    
                    //Just copy
                    //settingsToCreate.addAll(getDefaultCustomerSettings(detail, a != null ? a : sLoc.Account__r));
                    
                    if(a != null) a.Customer_Detail__c = detail.Id;
                    if(sLoc != null) sLoc.Customer_Detail__c = detail.Id;
                }
                
                for(Database.SaveResult result : Database.Update(accountsToUpdate.values(), false)) success = success && result.isSuccess();
                for(Database.SaveResult result : Database.Update(serviceLocsToUpdate.values(), false)) success = success && result.isSuccess();
                for(Database.SaveResult result : Database.Insert(responsiblePartiesToCreate, false)) success = success && result.isSuccess();
                for(Database.SaveResult result : Database.insert(settingsToCreate, false)) success = success && result.isSuccess();
            }
            
            return success;
        }
        
        return false;
    }
    
    private static List<Customer_Setting__c> getDefaultCustomerSettings(Customer_Detail__c detail, Account parentAccount){
        Map<String, Set<String>> defaults = new Map<String, Set<String>>{ 'Subscriber_Setting'=>new Set<String>(), 'Tax_Information'=>new Set<String>() };
        if(parentAccount.Default_NAA_Exempt__c) defaults.get('Tax_Information').addAll(new Set<String>{ '38', '96', '103', '104' });
        
        List<Customer_Setting__c> settingsToCreate = new List<Customer_Setting__c>();
        if(defaults.size() > 0){
            for(String k : defaults.keyset()){
                Id rtID = getCustomerSettingRecordTypeByDeveloperName(k);
                String settingCategory = k == 'Tax_Information' ? 'SubscriberTax' : 'SubscriberSetting';
                for(String refID : defaults.get(k)){
                    Customer_Setting_Reference__c ref = getCustomerSettingReferenceByID(settingCategory, refID);
                    settingsToCreate.add(new Customer_Setting__c
                                                    (Customer_Detail__c = detail.Id
                                                    ,Reference_ID__c = ref.ID__c
                                                    ,RecordTypeId = rtID
                                                    ,Name = ref.Description__c
                                                    ,Description__c = ref.Description__c
                                                    ,Start_Date__c = Datetime.now()));
                }
            }
        }
        return settingsToCreate;
    }
    
    public static List<Customer_Detail__c> cloneCustomerDetailsFromParent(Set<Id> serviceLocationIDs){

        List<Service_Location__c> sLocs = [select Id
                                                ,Billable__c
                                                ,Location__c
                                                ,Location__r.Room_Suite__c
                                                ,Location__r.Building__r.City__c
                                                ,Location__r.Building__r.Postal_Code__c
                                                ,Location__r.Building__r.Zip4__c
                                                ,Location__r.Building__r.State__c
                                                ,Location__r.Building__r.Address__c
                                                ,Location__r.Building__r.Country__c
                                                ,Account__r.Customer_Detail__c
                                                ,Parent_Service_Location__c
                                                ,Parent_Service_Location__r.Customer_Detail__c
                                            from Service_Location__c
                                            where Id in: serviceLocationIDs and Customer_Detail__c = null
                                                and ((Parent_Service_Location__c = null and Account__r.Customer_Detail__c != null)
                                                    or (Parent_Service_Location__c != null and Parent_Service_Location__r.Customer_Detail__c != null))];
        
        Map<Id, Id> parentDetailIDs = new Map<Id, Id>();
        for(Service_Location__c sLoc : sLocs)
            parentDetailIDs.put(sLoc.Id, sLoc.Parent_Service_Location__c != null ? sLoc.Parent_Service_Location__r.Customer_Detail__c : sLoc.Account__r.Customer_Detail__c);
        
        sObjectType detailType = Customer_Detail__c.getsObjectType();
        sObjectType settingType = Customer_Setting__c.getsObjectType();
        sObjectType contactType = Customer_Contact__c.getsObjectType();
        Map<Id, Customer_Detail__c> cdMap = new Map<Id, Customer_Detail__c>((List<Customer_Detail__c>)ApexUtils.retrieveObjectsFromFieldSets(detailType
                                                                                        ,new List<Set<String>>
                                                                                        {
                                                                                            SchemaUtils.RetrieveFullObjectFieldSet(detailType)
                                                                                            ,new Set<String>{
                                                                                                '(select ' + string.join(new List<String>(SchemaUtils.RetrieveFullObjectFieldSet(settingType)), ',') + ' from Customer_Settings__r)'
                                                                                                ,'(select ' + string.join(new List<String>(SchemaUtils.RetrieveFullObjectFieldSet(contactType)), ',') + ' from Customer_Contacts__r)'
                                                                                            }
                                                                                        }
                                                                                        ,'Id in (\'' + String.join(parentDetailIDs.values(), '\',\'') + '\')'
                                                                                        ,null));
        
        Map<Id, Customer_Detail__c> cloneMap = new Map<Id, Customer_Detail__c>();
        for(Service_Location__c sLoc : sLocs){
            Customer_Detail__c customerDetail = cdMap.get(parentDetailIDs.get(sLoc.Id));
            Customer_Detail__c clone = (Customer_Detail__c)ApexUtils.deepCopyFields(detailType, (sObject)customerDetail, (sObject)new Customer_Detail__c()
                                        ,new Set<String>{'ICC_Subscriber_ID__c', 'Integration_Status__c', 'Customer_Main_Address__c'
                                                ,'Tax_Main_Address__c', 'Service_Address__c'
                                                ,'Billing_Main_City__c', 'Billing_Main_Postal_Code__c'
                                                ,'Billing_Main_Room_Suite__c', 'Billing_Main_State__c', 'Billing_Main_Street__c'
                                                ,'Billing_Final_City__c', 'Billing_Final_Postal_Code__c', 'Billing_Country__c'
                                                ,'Billing_Final_Room_Suite__c', 'Billing_Final_State__c', 'Billing_Final_Street__c', 'CurrencyISOCode', 'Language_Preference__c'});
            
            clone.Customer_Main_Address__c = sLoc.Location__c;
            clone.Service_Address__c = sLoc.Location__c;
            clone.Tax_Main_Address__c = sLoc.Location__c;
            if(sLoc.Billable__c && sLoc.Location__c != null){
                AddressUtils.updateCustomerDetailAddressSet(clone
                                                ,'Billing_Main'
                                                ,sLoc.Location__r.Building__r.City__c
                                                ,sLoc.Location__r.Building__r.Postal_Code__c
                                                ,sLoc.Location__r.Building__r.Zip4__c
                                                ,sLoc.Location__r.Building__r.State__c
                                                ,sLoc.Location__r.Building__r.Address__c
                                                ,sLoc.Location__r.Room_Suite__c
                                                ,clone.Billing_Main_Name__c
                                                ,sLoc.Location__r.Building__r.Country__c);
            }
            cloneMap.put(sLoc.Id, clone);
        }
        
        insertCustomerDetails(cloneMap.values());
        
        List<Customer_Setting__c> clonedSettings = new List<Customer_Setting__c>();
        List<Customer_Contact__c> clonedContacts = new List<Customer_Contact__c>();
        for(Service_Location__c sLoc : sLocs){
            Customer_Detail__c clone = cloneMap.get(sLoc.Id);
            Customer_Detail__c cloned =  cdMap.get(parentDetailIDs.get(sLoc.Id));
            
            sLoc.Customer_Detail__c = clone.Id;
            for(Customer_Setting__c setting : cloned.Customer_Settings__r != null ? cloned.Customer_Settings__r : new List<Customer_Setting__c>())
                clonedSettings.add((Customer_Setting__c)ApexUtils.deepCopyFields(settingType, (sObject)setting, (sObject)new Customer_Setting__c(Customer_Detail__c = clone.Id), new Set<String>{'Customer_Detail__c', 'External_ID__c'}));
                
            for(Customer_Contact__c contact : cloned.Customer_Contacts__r != null ? cloned.Customer_Contacts__r : new List<Customer_Contact__c>())
                clonedContacts.add((Customer_Contact__c)ApexUtils.deepCopyFields(contactType, (sObject)contact, (sObject)new Customer_Contact__c(Customer_Detail__c = clone.Id), new Set<String>{'Customer_Detail__c', 'ICC_Contact_ID__c'}));
        }
        SecurityUtils.BypassProcesser.saveObjects(sLocs, true);
        
        if(clonedSettings.size() > 0) insert clonedSettings;
        if(clonedContacts.size() > 0) insert clonedContacts;
        
        return cloneMap.values();
    }
    
    private static Map<String, Customer_Setting__c> careOrgsByName = null;
    public static Customer_Setting__c getCareOrgByName(String name){
        if(name == null) return null;
        
        if(careOrgsByName == null){
            careOrgsByName = new Map<String, Customer_Setting__c>();
            
            for(Customer_Setting__c careOrg : [select Id, Name from Customer_Setting__c where RecordTypeId =: getCustomerSettingRecordTypeByDeveloperName('Care_Organization')])
                careOrgsByName.put(careOrg.Name.toLowerCase(), careOrg);
        }
        
        return careOrgsByName.get(name.toLowerCase());
    }
    
    private static Map<String, Customer_Setting__c> careOrgsById = null;
    public static Customer_Setting__c getCareOrgById(Id careOrgId){
        if( careOrgId== null) return null;
        
        if(careOrgsById == null){
            careOrgsById = new Map<String, Customer_Setting__c>();
            
            for(Customer_Setting__c careOrg : [select Id, Name from Customer_Setting__c where RecordTypeId =: getCustomerSettingRecordTypeByDeveloperName('Care_Organization')])
                careOrgsById.put(careOrg.Id, careOrg);
        }
        
        return careOrgsById.get(careOrgId);
    }    
    
    private static Map<String, RecordType> customerSettingRecordTypesByDeveloperName = null;
    public static Id getCustomerSettingRecordTypeByDeveloperName(String developerName){
        if(customerSettingRecordTypesByDeveloperName == null){
            customerSettingRecordTypesByDeveloperName = new Map<String, RecordType>();
            for(RecordType rt : [select Id, DeveloperName from RecordType where sObjectType = 'Customer_Setting__c'])
                customerSettingRecordTypesByDeveloperName.put(rt.DeveloperName, rt);
        }
        return customerSettingRecordTypesByDeveloperName.get(developerName) != null ? customerSettingRecordTypesByDeveloperName.get(developerName).Id : null;
    }
    
    private static Map<String, Map<String, Customer_Setting_Reference__c>> customerSettingReferences = null;
    public static Customer_Setting_Reference__c getCustomerSettingReferenceByID(String category, String refID){
        if(customerSettingReferences == null){
            customerSettingReferences = new Map<String, Map<String, Customer_Setting_Reference__c>>();
            List<Customer_Setting_Reference__c> refs = Customer_Setting_Reference__c.getAll().values();
            for(Customer_Setting_Reference__c ref : refs){
                Map<String, Customer_Setting_Reference__c> m = customerSettingReferences.get(ref.Category__c) != null ? customerSettingReferences.get(ref.Category__c) : new Map<String, Customer_Setting_Reference__c>();
                m.put(ref.ID__c, ref);
                customerSettingReferences.put(ref.Category__c, m);
            }
        }
        return customerSettingReferences.get(category) != null ? customerSettingReferences.get(category).get(refID) : null;
    }
    
    public static void handleNewCustomerDetailSet(List<sObject> tNew, Map<Id, sObject> tOldMap, Boolean accountMode){

        Map<Id, Id> cdMap = new Map<Id, Id>();
        for(sObject a : tNew){
            sObject aOld = tOldMap.get(a.Id);
            String cdNew = string.valueOf(a.get('Customer_Detail__c'));
            if(cdNew != null && (aOld == null || cdNew != string.valueOf(aOld.get('Customer_Detail__c'))))
                cdMap.put(a.Id, cdNew);
        }
        
        if(cdMap.size() > 0){
            Map<Id, Customer_Detail__c> updatedDetails = new Map<Id, Customer_Detail__c>();
            
            Set<Id> cdIDs = cdMap.keyset();
            String soql = accountMode
                            ? 'select Id, Account__c, Customer_Detail__r.Id, Customer_Detail__r.Parent_Customer__c from Service_Location__c where Customer_Detail__c != null and Parent_Service_Location__c = null and Account__c in: cdIDs'
                            : 'select Id, Parent_Service_Location__c, Customer_Detail__r.Id, Customer_Detail__r.Parent_Customer__c from Service_Location__c where Customer_Detail__c != null and Parent_Service_Location__c in: cdIDs';
            for(Service_Location__c sLoc : (List<Service_Location__c>)Database.query(soql)){
                Id cdID = cdMap.get(accountMode ? sLoc.Account__c : sLoc.Parent_Service_Location__c);
                Customer_Detail__c cd = sLoc.Customer_Detail__r;
                if(cd.Id != cdID && cd.Parent_Customer__c != cdID){
                    cd.Parent_Customer__c = cdID;
                    updatedDetails.put(cd.Id, cd);
                }
            }
                                                
            if(updatedDetails.size() > 0)
                update updatedDetails.values();
        }
    }
    
    public static void setCustomerDetailParents(List<sObject> triggerNew, List<sObject> triggerOld, Boolean isDelete){

        List<sObject> lNew = !isDelete ? triggerNew : triggerOld;
        Map<Id, sObject> tOldMap = !isDelete && triggerOld != null ? new Map<Id, sObject>(triggerOld) : new Map<Id, sObject>();
        
        Boolean sLocMode = lNew.size() > 0 && SchemaUtils.GetSObjectNameByID(lNew[0].Id) == 'Service_Location__c';
        Set<Id> cdIDs = new Set<Id>();
        for(Integer i=0; i<lNew.size(); i++){
            sObject old = !isDelete && lNew[i].Id != null ? tOldMap.get(lNew[i].Id) : null;
            Id newDetail = (Id)lNew[i].get('Customer_Detail__c');
            Id oldDetail = old != null ? (Id)old.get('Customer_Detail__c') : null;
            
            if((old == null && newDetail != null) || (old != null && (newDetail != oldDetail || (sLocMode && lNew[i].get('Account__c') != old.get('Account__c'))))){
                for(Id id : new Set<Id>{newDetail, oldDetail}){
                    if(id != null)
                        cdIDs.add(id);
                }
            }
        }
        
        setCustomerDetailParents(cdIDs);
    }
    
    public static void setCustomerDetailParents(Set<Id> cdIDs){

        if(cdIDs.size() > 0){
            List<Customer_Detail__c> updates = new List<Customer_Detail__c>();
            for(Customer_Detail__c cd : [select Parent_Account__c, Parent_Customer__c, (select Id from Accounts__r limit 1), (select Account__c from Service_Locations__r limit 1) from Customer_Detail__c where Id in : cdIDs]){
                Id newParent = cd.Accounts__r.size() > 0 ? cd.Accounts__r[0].Id : (cd.Service_Locations__r.size() > 0 ? cd.Service_Locations__r[0].Account__c : SecurityUtils.SystemAccount.Id);
                if(cd.Parent_Account__c != newParent){
                    cd.Former_Account__c = cd.Parent_Customer__c == null && newParent == SecurityUtils.SystemAccount.Id ? cd.Parent_Account__c : null;
                    cd.Parent_Account__c = newParent;
                    updates.add(cd);
                }
            }
            
            if(updates.size() > 0)
                update updates;
        }
    }
    
    public static Boolean triggerDetailAddressValidation = true;
    public static void updateCustomerDetails(List<Set<Id>> detailsToUpdate){
        updateCustomerDetails(detailsToUpdate, null);
    }
        
    public static void updateCustomerDetails(List<Set<Id>> detailsToUpdate, Map<Id, List<Customer_Contact__c>> contactsToCreate){

        if((detailsToUpdate != null && detailsToUpdate.size() > 0) || (contactsToCreate != null && contactsToCreate.size() > 0)){
            contactsToCreate = (contactsToCreate != null) ? contactsToCreate : new Map<Id, List<Customer_Contact__c>>();
            
            Map<Id, Id> pairedIDs = new Map<Id, Id>();
            Set<Id> allIDs = new Set<Id>();
            for(Set<Id> ids : detailsToUpdate){
                for(Id id : ids)
                    allIDs.add(id);
                
                List<Id> idList = new List<Id>(ids);
                if(idList.size() == 2){
                    pairedIDs.put(idList[0], idList[1]);
                    pairedIDs.put(idList[1], idList[0]);
                }
            }
            system.debug('pairedIDs: ' + pairedIDs);
            //MNK changed BillingState to BillingStateCode - may not need to do this now that Terrie is using Integration Value
            Map<Id, Account> accountsToUpdate =  new Map<Id, Account>([select Id
                                                                     //       ,Account_Sales_Channel__c
                                                                            ,Billable__c
                                                                            ,BillingCity
                                                                            ,BillingStateCode
                                                                            ,BillingStreet
                                                                            ,BillingPostalCode
                                                                            ,BillingCountry
                                                                            ,Customer_Detail__c
                                                                            ,Name
                                                                            ,RecordType.DeveloperName
                                                                            ,Default_NAA_Exempt__c
                                                                            ,CurrencyISOCode
                                                                            ,Owners_Sales_Channel__c
                                                                            ,Language_Preference__c
                                                                            ,Customer_Detail__r.Care_Organization__c
                                                                            from Account
                                                                            where Id in : allIDs
                                                                            or Id in : contactsToCreate.keyset()]);

            Map<Id, Service_Location__c> sLocsToUpdate = new Map<Id, Service_Location__c>([select Id
                                                                                                ,Account__c
                                                                                              //  ,Account__r.Account_Sales_Channel__c
                                                                                                ,Account__r.Owners_Sales_Channel__c
                                                                                                ,Account__r.RecordType.DeveloperName
                                                                                                ,Account__r.Default_NAA_Exempt__c
                                                                                                ,Account__r.CurrencyISOCode
                                                                                                ,Account__r.Language_Preference__c
                                                                                                ,Account__r.Customer_Detail__r.Care_Organization__c
                                                                                                ,Billable__c
                                                                                                ,Customer_Detail__c
                                                                                                ,Location__r.Id
                                                                                                ,Location__r.Room_Suite__c
                                                                                                ,Location__r.Building__r.Id
                                                                                                ,Location__r.Building__r.Address__c
                                                                                                ,Location__r.Building__r.City__c
                                                                                                ,Location__r.Building__r.Postal_Code__c
                                                                                                ,Location__r.Building__r.Zip4__c
                                                                                                ,Location__r.Building__r.State__c
                                                                                                ,Location__r.Building__r.Market_Area_ID__c
                                                                                                ,Location__r.Building__r.Country__c
                                                                                                ,Name
                                                                                                ,Owner_Sales_Channel__c
                                                                                                ,CurrencyISOCode
                                                                                                ,Parent_Service_Location__r.Customer_Detail__c
                                                                                                ,Parent_Service_Location__r.Customer_Detail__r.Care_Organization__c
                                                                                            from Service_Location__c
                                                                                            where Id in : allIDs
                                                                                            or Id in : contactsToCreate.keyset()]);
            
            Set<Id> accountIDs = new Set<Id>();
            for(Id id : accountsToUpdate.keyset())
                accountIDs.add(id);
            
            for(Service_Location__c sLoc : sLocsToUpdate.values()){
                if(sLoc.Account__c != null)
                    accountIDs.add(sLoc.Account__c);
            }
            
            List<Customer_Contact__c> customerContactsToCreate = new List<Customer_Contact__c>();
            
            Set<Id> removeIDs = new Set<Id>();
            for(Account a : accountsToUpdate.values()){
                if(a.Customer_Detail__c != null){
                    if(pairedIDs.get(a.Id) != null)
                        sLocsToUpdate.get(pairedIDs.get(a.Id)).Customer_Detail__c = a.Customer_Detail__c;
                    removeIDs.add(a.Id);
                }
            }
            
            for(Service_Location__c sLoc : sLocsToUpdate.values()){
                if(sLoc.Customer_Detail__c != null && (pairedIDs.get(sLoc.Id) == null || !removeIDs.contains(pairedIDs.get(sLoc.Id)))){
                    if(pairedIDs.get(sLoc.Id) != null)
                        accountsToUpdate.get(pairedIDs.get(sLoc.Id)).Customer_Detail__c = sLoc.Customer_Detail__c;
                    removeIDs.add(sLoc.Id);
                }
            }
            
            for(Id id : removeIDs){
                List<Customer_Contact__c> ccs = contactsToCreate.get(id);
                if(ccs != null){
                    Account a = accountsToUpdate.get(id);
                    Service_Location__c sLoc = sLocsToUpdate.get(id);
                    for(Customer_Contact__c cc : ccs){
                        cc.Customer_Detail__c = a != null ? a.Customer_Detail__c : sLoc.Customer_Detail__c;
                        customerContactsToCreate.add(cc);
                    }
                }
                accountsToUpdate.remove(id);
                sLocsToUpdate.remove(id);
                for(Integer i=detailsToUpdate.size()-1; i>=0; i--){
                    if(detailsToUpdate[i].contains(id))
                        detailsToUpdate.remove(i);
                }
            }
            
            List<Customer_Setting__c> settingsToCreate = new List<Customer_Setting__c>();

            if(detailsToUpdate.size() > 0){
                //Need to insert details
                Map<Id, List<Contact>> defaultContactsByAccountId = new Map<Id, List<Contact>>();
                for(Contact c : [select Id
                                        ,AccountId
                                        ,Default_Contact_Types__c
                                        ,Default_Responsible_Party__c
                                    from Contact where AccountId in : accountIDs and (Default_Contact_Types__c != null or Default_Responsible_Party__c = true)]){
                    List<Contact> cList = defaultContactsByAccountId.get(c.AccountId) != null ? defaultContactsByAccountId.get(c.AccountId) : new List<Contact>();
                    cList.add(c);
                    defaultContactsByAccountId.put(c.AccountId, cList);
                }
                
                Map<Id, Market_Area__c> marketAreas = new Map<Id, Market_Area__c>();
                Map<String, Id> marketAreaIDByICCID = new Map<String, Id>();
                Map<String, Id> marketAreaIDByName = new Map<String, Id>();
                for(Market_Area__c ma : [select Id, Name, ICCMarketAreaID__c, ProvMarketAreaID__c from Market_Area__c]){
                    marketAreas.put(ma.Id, ma);
                    marketAreaIDByICCID.put(string.valueOf(ma.ICCMarketAreaID__c), ma.Id);
                    marketAreaIDByName.put(ma.Name, ma.Id);
                }
                
                Map<Id, Id> camIDByAccountID = new Map<Id, Id>();
                for(AccountTeamMember atm : [select UserId, AccountId from AccountTeamMember where TeamMemberRole in : ICCWrapper.CamTeamMemberRoles and AccountId in: accountIds])
                    camIDByAccountID.put(atm.AccountId, atm.UserId);
                
                Set<Id> csrtIDs = new Set<Id>{ getCustomerSettingRecordTypeByDeveloperName('Care_Organization'), getCustomerSettingRecordTypeByDeveloperName('Market_Type') };
                
                Map<String, Id> careOrgIDsByName = new Map<String, Id>();
                Map<String, Id> marketTypeIDByName = new Map<String, Id>();
                for(Customer_Setting__c c : [select Id, Name, RecordType.DeveloperName from Customer_Setting__c where RecordTypeId in: csrtIDs]){
                    if(c.RecordType.DeveloperName == 'Care_Organization')
                        careOrgIDsByName.put(c.Name.toLowerCase(), c.Id);
                    else if(c.RecordType.DeveloperName == 'Market_Type')
                        marketTypeIDByName.put(c.Name, c.Id);
                }
                
                Map<Id, Id> firstMarketAreaIDFoundPerAccount = new Map<Id, Id>();   //Not the greatest solution but it works
                Map<Integer, Customer_Detail__c> detailsToInsert = new Map<Integer, Customer_Detail__c>();
                Set<Integer> isPriorLake = new Set<Integer>();
                Id parentCareOrg = null;

                for(Integer i=0; i<detailsToUpdate.size(); i++){
                    Customer_Detail__c detail = new Customer_Detail__c();
                    
                    Account a = null;
                    Service_Location__c sLoc = null;
                    for(Id id : detailsToUpdate[i]){
                        a = (a == null ? accountsToUpdate.get(id) : a);
                        sLoc = (sLoc == null ? sLocsToUpdate.get(id) : sLoc);
                    }
                    
                    Boolean isPl = false;
                    if(sLoc != null){
                        isPl |= sLoc.Account__r.RecordType.DeveloperName == ICCWrapper.PriorLakeRecordType;
                        
                        if(sLoc.Location__c != null){
                            if(sLoc.Location__r.Building__c != null){
                                if(firstMarketAreaIDFoundPerAccount.get(sLoc.Account__c) == null)
                                    firstMarketAreaIDFoundPerAccount.put(sLoc.Account__c, sLoc.Location__r.Building__r.Market_Area_ID__c);
                                detail.Market_Area__c = sLoc.Location__r.Building__r.Market_Area_ID__c;
                            }
                        }
                        detail.Customer_Main_Address__c = sLoc.Location__c;
                        detail.Service_Address__c = sLoc.Location__c;
                        detail.Tax_Main_Address__c = sLoc.Location__c;

                        if (sLoc.Account__c != null) {
                            detail.CurrencyISOCode = sLoc.Account__r.CurrencyISOCode;
                            //if (detail.Language_Preference__c == null)
                                detail.Language_Preference__c = sLoc.Account__r.Language_Preference__c;
                        }
                        
                        if(sLoc.Billable__c && sLoc.Location__r.Building__c != null){
                            AddressUtils.updateCustomerDetailAddressSet(detail
                                                            ,'Billing_Main'
                                                            ,sLoc.Location__r.Building__r.City__c
                                                            ,sLoc.Location__r.Building__r.Postal_Code__c
                                                            ,sLoc.Location__r.Building__r.State__c
                                                            ,sLoc.Location__r.Building__r.Address__c
                                                            ,sLoc.Location__r.Room_Suite__c
                                                            ,null
                                                            ,sLoc.Location__r.Building__r.Country__c);
                        }
                        detail.Customer_Account_Manager__c = sLoc.Account__c != null ? camIDByAccountID.get(sLoc.Account__c) : null;
                        
                        parentCareOrg = sLoc.Parent_Service_Location__r.Customer_Detail__c != null ? sLoc.Parent_Service_Location__r.Customer_Detail__r.Care_Organization__c : sLoc.Account__r.Customer_Detail__r.Care_Organization__c;
                    }
                    if(a != null){
                        detail.CurrencyIsoCode = a.CurrencyISOCode;
                        if (detail.Language_Preference__c == null) {
                            if (a.Language_Preference__c == null)
                                detail.Language_Preference__c = LANGUAGE_ENGLISH;
                            else
                                detail.Language_Preference__c = a.Language_Preference__c;
                        }
 
                        isPl |= a.RecordType.DeveloperName == ICCWrapper.PriorLakeRecordType;
                        
                        if(detail.Market_Area__c == null && firstMarketAreaIDFoundPerAccount.get(a.Id) != null){
                            detail.Market_Area__c = firstMarketAreaIDFoundPerAccount.get(a.Id);
                        }
                        //Use the account billing address if it exists
                        if(a.Billable__c){
                            //MNK Changed BillingState to BillingStateCode
                            AddressUtils.updateCustomerDetailAddressSet(detail
                                                            ,'Billing_Main'
                                                            ,a.BillingCity
                                                            ,a.BillingPostalCode
                                                            ,a.BillingStateCode
                                                            ,a.BillingStreet
                                                            ,null
                                                            ,null
                                                            ,a.BillingCountry);
                        }
                        detail.Customer_Account_Manager__c = camIDByAccountID.get(a.Id);
                        
                        if(parentCareOrg == null){
                        	parentCareOrg = a.Customer_Detail__r.Care_Organization__c;
                        }
                        
                    }
                    
                    if(isPl){
                        isPriorLake.add(i);
                        detail.Market_Area__c = marketAreaIDByICCID.get(ICCWrapper.PriorLakeMarketAreaID);
                        detail.Prov_Market_Area__c = detail.Market_Area__c;
                        detail.Name = (sLoc != null) ? sLoc.Name : a.Name;
                        
                        if(detail.Name.contains(',') && detail.Name.split(',').size() == 2){
                            List<String> nameParts = detail.Name.split(',');
                            if(nameParts.size() == 2 && nameParts[0].trim().length() > 0 && nameParts[1].trim().length() > 0){
                                detail.First_Name__c = nameParts[1].trim();
                                detail.Last_Name__c = nameParts[0].trim();
                                detail.Market_Type__c = marketTypeIDByName.get('Residential');
                            }
                        }
                    }
                    
                    //String sc = a != null ? a.Account_Sales_Channel__c : sLoc.Account__r.Account_Sales_Channel__c;
                    String sc = a != null ? a.Owners_Sales_Channel__c : sLoc.Account__r.Owners_Sales_Channel__c;
                    
					if(parentCareOrg != null){
                    	detail.Care_Organization__c = parentCareOrg;
                    } else{
	                    if(sc != null){
	                        String scm = CustomSettingUtils.getSingleProcessConfigurationValue('SalesChannelDefaultCareOrg', sc, false);
	                        scm = scm != null ? scm.toLowerCase() : null;
	//                        detail.Care_Organization__c = (scm != null && careOrgIDsByName.containsKey(scm) != null) ? careOrgIDsByName.get(scm) : careOrgIDsByName.get(sc.toLowerCase());
	                        detail.Care_Organization__c = (scm != null && careOrgIDsByName.containsKey(scm) != null) ? careOrgIDsByName.get(scm) : null;
	                    }
					}
                    
                    detailsToInsert.put(i, detail);
                }
                
                List<Customer_Detail__c> details = detailsToInsert.values();
                if(details.size() > 0){
                    //Fix the prov market areas and market types to their defaults
                    for(Customer_Detail__c detail: details){
                        if(detail.Market_Area__c != null){
                            String marketAreaName = marketAreas.get(detail.Market_Area__c).Name;
                            
                            String configVal = CustomSettingUtils.getSingleProcessConfigurationValue('ValidProvMarketAreas', marketAreaName, true);
                            List<String> validTypes = !string.IsEmpty(configVal) ? configVal.split(',') : null;
                            detail.Prov_Market_Area__c = validTypes != null ? marketAreaIDByName.get(validTypes.get(0)) : (marketAreas.get(detail.Market_Area__c).ProvMarketAreaID__c != null ? detail.Market_Area__c : detail.Prov_Market_Area__c);
                            
                            if(detail.Market_Type__c == null){
                                configVal = CustomSettingUtils.getSingleProcessConfigurationValue('ValidMarketTypes', marketAreaName, true);
                                validTypes = !string.IsEmpty(configVal) ? configVal.split(',') : null;
                                detail.Market_Type__c = validTypes != null ? marketTypeIDByName.get(validTypes.get(0)) : detail.Market_Type__c;
                            }
                        }
                    }
                    
                    insertCustomerDetails(details);
                    
                    if(isPriorLake.size() > 0){
                        try{
                            Customer_Setting_Reference__c ref = getCustomerSettingReferenceByID('SubscriberSetting', '21');
                            Id subSetingID = getCustomerSettingRecordTypeByDeveloperName('Subscriber_Setting');
                            for(Integer i : isPriorLake){
                                settingsToCreate.add(new Customer_Setting__c
                                                                (Customer_Detail__c = details[i].Id
                                                                ,Reference_ID__c = ref.ID__c
                                                                ,RecordTypeId = subSetingID
                                                                ,Name = ref.Description__c
                                                                ,Description__c = ref.Description__c));
                            }
                        }
                        catch(Exception e) {}
                    }
                    
                    Set<String> contactTypes = new Set<String>();
                    for(Schema.PicklistEntry ple : Customer_Contact__c.Contact_Type__c.getDescribe().getPicklistValues()){
                        if(ple.getLabel() != ICCWrapper.ResonsiblePartyContactType)
                            contactTypes.add(ple.getLabel());
                    }
                    
                    Set<Id> detailsWithResponsibleParty = new Set<Id>();
                    for(Integer i=0; i<detailsToUpdate.size(); i++){
                        Boolean firstLoop = true;
                        for(Id id : detailsToUpdate[i]){
                            Account a = accountsToUpdate.get(id);
                            Service_Location__c sLoc = sLocsToUpdate.get(id);
                            Id accountId = a != null ? a.Id : sLoc.Account__c;
                            
                            system.debug(string.format('Setting customer detail for {0} to {1}', new List<String>{id, details[i].Id}));
                            List<Customer_Contact__c> ccs = contactsToCreate.get(id);
                            if(a != null)
                                a.Customer_Detail__c = details[i].Id;
                            if(sLoc != null)
                                sLoc.Customer_Detail__c = details[i].Id;
                            if(ccs != null){
                                for(Customer_Contact__c cc : ccs){
                                    if(cc.Contact_Type__c == ICCWrapper.ResonsiblePartyContactType)
                                        detailsWithResponsibleParty.add(details[i].Id);
                                    cc.Customer_Detail__c = details[i].Id;
                                    customerContactsToCreate.add(cc);
                                }
                            }
                            
                            if(firstLoop) settingsToCreate.addAll(getDefaultCustomerSettings(details[i], a != null ? a : sLoc.Account__r));
                            
                            if(firstLoop && accountId != null && defaultContactsByAccountId.get(accountId) != null){
                                for(Contact c : defaultContactsByAccountId.get(accountId)){
                                    if(c.Default_Responsible_Party__c == true && !detailsWithResponsibleParty.contains(details[i].Id)){
                                        customerContactsToCreate.add(new Customer_Contact__c(Customer_Detail__c = details[i].Id
                                                                                        ,Contact__c = c.Id
                                                                                        ,Contact_Type__c = ICCWrapper.ResonsiblePartyContactType));
                                        detailsWithResponsibleParty.add(details[i].Id);
                                    }
                                    for(String typeName : c.Default_Contact_Types__c != null ? c.Default_Contact_Types__c.split(';') : new List<String>()){
                                        if(typeName != ICCWrapper.ResonsiblePartyContactType && contactTypes.contains(typeName)){
                                            customerContactsToCreate.add(new Customer_Contact__c(Customer_Detail__c = details[i].Id
                                                                                            ,Contact__c = c.Id
                                                                                            ,Contact_Type__c = typeName));
                                        }
                                    }
                                }
                            }
                            firstLoop = false;
                        }
                    }
                    List<Task> createResponsiblePartyTasks = new List<Task>();
                    for(Integer i=0; i<details.size(); i++){
                        if(!detailsWithResponsibleParty.contains(details[i].Id)){
                            createResponsiblePartyTasks.add(new Task(
                                                                    WhatId = details[i].Id,
                                                                    WhoId = UserInfo.getUserId(),
                                                                    Type = 'Follow Up',
                                                                    Subject = 'Create Responsible Party'
                                                                ));
                        }
                    }
                    
                    if(createResponsiblePartyTasks.size() > 0)
                        SecurityUtils.BypassProcesser.saveObjects(createResponsiblePartyTasks, false);
                }
            }
            
            if(settingsToCreate.size() > 0)
                SecurityUtils.BypassProcesser.saveObjects(settingsToCreate, false);
            
            //Failure to update these is critical
            if(accountsToUpdate.size() > 0)
                SecurityUtils.BypassProcesser.saveObjects(accountsToUpdate.values(), true);
            if(sLocsToUpdate.size() > 0)
                SecurityUtils.BypassProcesser.saveObjects(sLocsToUpdate.values(), true);
            if(customerContactsToCreate.size() > 0)
                SecurityUtils.BypassProcesser.saveObjects(customerContactsToCreate, true);
        }
    }
    
    private static void insertCustomerDetails(List<Customer_Detail__c> insertList){

        CustomerDetailTriggers.ValidateAddresses = triggerDetailAddressValidation || trigger.isExecuting;
        if(!CustomerDetailTriggers.ValidateAddresses) validateAddresses(insertList);    //Run synchronous first
        else CustomerDetailTriggers.preloadAddressValidations(insertList);
        SecurityUtils.BypassProcesser.saveObjects(insertList, true);
    }
    
    private static List<string> validateAddresses(List<Customer_Detail__c> details){
        Map<String, Customer_Detail__c> cdMap = new Map<String, Customer_Detail__c>();
        Map<Id, Location__c> locMap = new Map<Id, Location__c>();
        for(Integer i=0; i<details.size(); i++){
            cdMap.put(string.valueOf(i), details[i]);
            for(Id locID : new Set<Id>{ details[i].Customer_Main_Address__c, details[i].Tax_Main_Address__c, details[i].Service_Address__c }){
                if(locID != null) locMap.put(locID, null);
            }
        }
        
        Set<Id> ids = locMap.keySet();
        locMap = new Map<Id, Location__c>((List<Location__c>)Database.query('select ' + string.join(new List<String>(AddressUtils.LocationSubscriberAddressViewFields), ',') + ' from Location__c where Id in: ids'));
        
        List<integraWS.SFSubscriberAddressView> addresses = new List<integraWS.SFSubscriberAddressView>();
        for(String key : cdMap.keySet()){
            Customer_Detail__c cd = cdMap.get(key);
            
            //Add the lookups so they can be pulled in the address utils method
            cd.Customer_Main_Address__r = locMap.get(cd.Customer_Main_Address__c);
            cd.Tax_Main_Address__r = locMap.get(cd.Tax_Main_Address__c);
            cd.Service_Address__r = locMap.get(cd.Service_Address__c);
            
            for(integraWS.SFSubscriberAddressView addr : AddressUtils.getSFSubscriberAddressViewsFromCustomerDetail(cd, 0, cd.Billable__c)){
                addr.CompanyName = 'Validating';        //The name is irrelevant but required for validation
                addr.SalesforceID = key;
                addresses.add(addr);
            }
            
            //Put the ID lookups back
            cd.Customer_Main_Address__c = cd.Customer_Main_Address__r.Id;
            cd.Tax_Main_Address__c = cd.Tax_Main_Address__r.Id;
            cd.Service_Address__c = cd.Service_Address__r.Id;
        }
        
        return AddressUtils.validateAndClearCustomerDetailAddresses(cdMap, addresses, UserInfo.getSessionId(), null);
    }
    
    public static String integrateSubscriberSetting(Customer_Detail__c cd, Customer_Setting__c setting){
        String message = null;
        if(!string.isEmpty(cd.ICC_Subscriber_ID__c)){
            for(integraWS.SFSubscriberSettingView result : ICCWrapper.updateSubscriberSettings(new List<integraWS.SFSubscriberSettingView>{ICCWrapper.getSubscriberSettingFromCustomerSetting(setting, cd.ICC_Subscriber_ID__c)})){
                if((result.SalesforceID == setting.Id && result.ID != null && result.ID != 0) || Test.IsRunningTest())
                    setting.External_ID__c = string.valueOf(result.ID);
                else
                    message = 'New subscriber setting \'' + setting.Description__c +  '\' could not be created: ' + result.ResultMessage;
            }
        }
        
        return message;
    }
}