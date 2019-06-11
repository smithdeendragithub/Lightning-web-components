/**************************************************************************************************
*    CustomerDetailTriggers.cls
*
*    Modifications:
*    Developer Name       Date        Brief description
*    -------------------  ----------  ------------------------------------------------------------
*    Eunjung Ju           03/01/2018  SEAL-863 - Update Reproting Company logic
**************************************************************************************************/
public without sharing class CustomerDetailTriggers {

    public static Boolean IntegrationDisabled = false;
    public static Boolean SynchronizingFields = false;
    public static Boolean UpdateAddresses = false;
    public static Boolean ValidateAddresses = false;
    public static Boolean IntegrateAllOwners = false;
    
    public static void CustomerDetailModified(List<Customer_Detail__c> tNew, List<Customer_Detail__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
        
        if(!ApexUtils.executeTriggerMethods('Customer_Detail__c', isBefore, isDelete)) return;

        if(isBefore){
            if(isDelete)
                preventSubscriberDelete(tOld);
            else{
                Map<Id, Customer_Detail__c> tOldMap = tOld != null ? new Map<Id, Customer_Detail__c>(tOld) : new Map<Id, Customer_Detail__c>();
                if(isUpdate){
                    checkBillableToggle(tNew, tOldMap);
                    synchAccountsAndServiceLocations(tNew, tOldMap);
                    createAccountScheduledTasks(tNew, tOldMap);
                }
                else {
                    defaultNullValues(tNew);
                    handleAddressValidations(tNew, tOldMap);
                }
                handleUpdatedTaxMainAddress(tNew, tOldMap);
                checkDuplicateBillingId(tNew, tOldMap);
                formatAccountNumbers(tNew);
            }
        }
        else {
            Map<Id, Customer_Detail__c> tOldMap = tOld != null ? new Map<Id, Customer_Detail__c>(tOld) : new Map<Id, Customer_Detail__c>();
            if(!isDelete){
                if(isUpdate) {
                    updateSubscribers(tNew, tOldMap);
                    GlobysTransactionController.processCustomerDetailChanges(tNew, tOldMap, isDelete);
                    PhoenixTransactionController.processCustomerDetailChanges(tNew, tOldMap, isDelete);
                }
                else
                    validateAddresses(tNew);

                Batch_CalculateAccountOwnership.HandleOwnershipRecalculation(tNew, tOldMap);
            } else {
                GlobysTransactionController.processCustomerDetailChanges(tNew, tOldMap, isDelete);
            }
            
            ApexUtils.afterTriggerComplete('Customer_Detail__c', isDelete);
        }
    }
    
    private static void checkBillableToggle(List<Customer_Detail__c> tNew, Map<Id, Customer_Detail__c> tOldMap){
        Schema.DescribeFieldResult f = Customer_Detail__c.ICC_Subscriber_ID__c.getDescribe();
        Boolean overrideUpdateCheck = f.isAccessible() && f.isUpdateable();
        
        List<String> notifications = new List<String>();
        for(Customer_Detail__c cd : tNew){
            Customer_Detail__c cdOld = tOldMap.get(cd.Id);
            if(cdOld != null && cd.Billable__c != cdOld.Billable__c && cd.ICC_Subscriber_ID__c != null && cd.ICC_Subscriber_ID__c == cdOld.ICC_Subscriber_ID__c){
                if(overrideUpdateCheck)
                    notifications.add('ID: ' + cd.ICC_Subscriber_ID__c + '; Name: ' + cd.Name + '; Billable: ' + (cd.Billable__c == true ? 'Yes' : 'No'));
                else
                    cd.addError('You cannot change the billable status of a subscriber.');
            }
        }
        
        if(notifications.size() > 0 && CustomSettingUtils.BillingChangeNotificationEmailAddresses.size() > 0 && !CustomSettingUtils.getOverrideSettingValue('Send Billing Change Email'))
            ApexUtils.sendEmails(new List<Messaging.SingleEmailMessage>{ApexUtils.createEmailMessage(CustomSettingUtils.BillingChangeNotificationEmailAddresses, null, 'Subscriber billing status modified', string.join(notifications, '\n'), false, null)});
    }
    
    private static Boolean preventSubscriberDelete(List<Customer_Detail__c> tOld){
        
        Boolean allowSubscriberDeletion = null;
        Boolean errored = false;
        for(Customer_Detail__c cd : tOld){
            if(!string.IsEmpty(cd.ICC_Subscriber_ID__c)){
                if(allowSubscriberDeletion == null)
                    allowSubscriberDeletion = [select Name from Profile where Id =: UserInfo.getProfileId()].Name == 'System Administrator';
                
                if(!allowSubscriberDeletion){
                    cd.addError('Customers with subscriber IDs cannot be deleted or merged.');
                    errored = true;
                }
            }
        }
        return errored;
    }
    
    private static void synchAccountsAndServiceLocations(List<Customer_Detail__c> tNew, Map<Id, Customer_Detail__c> tOldMap){
        
        Map<Id, Customer_Detail__c> beforeLoaded = new Map<Id, Customer_Detail__c>();
       // Map<Id, Account> parentAccounts = new Map<Id, Account>();
        for(Customer_Detail__c dNew : tNew){
            Customer_Detail__c dOld = tOldMap.get(dNew.Id);
            if((dNew.ICC_Subscriber_ID__c != null && dOld.ICC_Subscriber_ID__c == null)
                    || dNew.Name != dOld.Name
                    || dNew.Billable__c != dOld.Billable__c
                    || dNew.Phone__c != dOld.Phone__c
                    || dNew.Owner__c != dOld.Owner__c
                    //|| dNew.Owner_Agency__c != dOld.Owner_Agency__c
                    || dNew.Integration_Status__c != dOld.Integration_Status__c
                    || dNew.Parent_Account__c != dOld.Parent_Account__c
                    || dNew.Parent_Customer__c != dOld.Parent_Customer__c){
                beforeLoaded.put(dNew.Id, null);
               // if(dNew.Parent_Account__c != null) parentAccounts.put(dNew.Parent_Account__c, null);
            }
        }
        
        if(beforeLoaded.size() > 0){
            beforeLoaded = new Map<Id, Customer_Detail__c>([select Id
                                                                    ,ICC_Subscriber_ID__c
                                                                    //,Parent_Account__r.Account_Sales_Channel__c
                                                                    ,Parent_Account__r.RecordType.DeveloperName
                                                                    ,(select Id, Name, Billable__c, Phone, OwnerId, /*Agency__c,*/ Type, RecordTypeId, RecordType.DeveloperName from Accounts__r)
                                                                    ,(select Id, Name, Billable__c, Phone__c, Owner__c, /*Agency__c,*/ Account__r.Customer_Detail__c, Parent_Service_Location__r.Customer_Detail__c from Service_Locations__r)
                                                            from Customer_Detail__c where Id in : beforeLoaded.keyset()]);
            //parentAccounts = new Map<Id, Account>([select Id, Account_Sales_Channel__c, RecordType.DeveloperName from Account where Id in: parentAccounts.keyset()]);
            
            Id subRtID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subscriber').getRecordTypeId();
            
            List<Account> updatedAccounts = new List<Account>();
            List<Service_Location__c> updatedSLocs = new List<Service_Location__c>();
            for(Customer_Detail__c dNew : tNew){
                Customer_Detail__c dLoad = beforeLoaded.get(dNew.Id);
                
                if(dLoad == null) continue;
           /*no need to update CareOrg based on ABS     
                Account pa = dNew.Parent_Account__c != null ? parentAccounts.get(dNew.Parent_Account__c) : null;
                if(pa != null && pa.RecordType.DeveloperName != 'System'
                    && (dNew.Integration_Status__c == null || !IntegrationUtils.inactiveSubscriberStatuses.contains(dNew.Integration_Status__c))){
                    //Synch with account hierarchy fields
                    String scm = !string.isEmpty(pa.Account_Sales_Channel__c) ? CustomSettingUtils.getSingleProcessConfigurationValue('SalesChannelDefaultCareOrg', pa.Account_Sales_Channel__c, false) : null;
                    Customer_Setting__c careOrg = !String.IsEmpty(scm) ? CustomerDetailUtils.getCareOrgByName(scm) : null;
                    careOrg = careOrg != null ? careOrg : CustomerDetailUtils.getCareOrgByName(pa.Account_Sales_Channel__c);
                    if(careOrg != null) dNew.Care_Organization__c = careOrg.Id;
                }*/
                
                for(Account a : dLoad.Accounts__r != null && !AccountTriggers.SynchronizingFields ? dLoad.Accounts__r : new List<Account>()){
                    dNew.Parent_Customer__c = null;
                    
                    Boolean prospectRT = a.RecordType.DeveloperName == 'Prospect';
                    Boolean updateAccountTypes = (prospectRT || a.Type == 'Prospect' || (a.Type == 'Former Customer' && dLoad.ICC_Subscriber_ID__c == null)) && dNew.ICC_Subscriber_ID__c != null;
                    Boolean fUpdate = a.Name != dNew.Name
                                            || a.Billable__c != dNew.Billable__c
                                            || a.Phone != dNew.Phone__c
                                            || a.OwnerId != dNew.Owner__c
                                            /*|| a.Agency__c != dNew.Owner_Agency__c*/;
                    
                    if(updateAccountTypes || fUpdate){
                        //Update the account to become a subscriber recordtype and customer type
                        if(updateAccountTypes){
                            a.Type = 'Customer';
                            if(prospectRT)
                                a.RecordTypeId = subRtID;
                        }
                        
                        //Synch the account fields
                        if(fUpdate){
                            a.Name = dNew.Name;
                            a.Billable__c = dNew.Billable__c;
                            a.Phone = dNew.Phone__c;
                            a.OwnerId = dNew.Owner__c;
                            //a.Agency__c = dNew.Owner_Agency__c;
                        }
                        
                        updatedAccounts.add(a);
                    }
                }
                
                for(Service_Location__c sLoc : dLoad.Service_Locations__r != null && !ServiceLocationTriggers.SynchronizingFields ? dLoad.Service_Locations__r : new List<Service_Location__c>()){
                    //Keep the parent customer in synch with the service loc
                    dNew.Parent_Customer__c = sLoc.Parent_Service_Location__r != null ? sLoc.Parent_Service_Location__r.Customer_Detail__c : (sLoc.Account__r.Customer_Detail__c != dNew.Id ? sLoc.Account__r.Customer_Detail__c : null);
                    
                    //Synch the service location fields
                    if(sLoc.Name != dNew.Name
                            || sLoc.Billable__c != dNew.Billable__c
                            || sLoc.Phone__c != dNew.Phone__c
                            || sLoc.Owner__c != dNew.Owner__c
                            /*|| sLoc.Agency__c != dNew.Owner_Agency__c*/){
                        sLoc.Name = dNew.Name;
                        sLoc.Billable__c = dNew.Billable__c;
                        sLoc.Phone__c = dNew.Phone__c;
                        sLoc.Owner__c = dNew.Owner__c;
                        //sLoc.Agency__c = dNew.Owner_Agency__c;
                        updatedSLocs.add(sLoc);
                    }
                }
            }
            
            Boolean oSynch = SynchronizingFields;
            SynchronizingFields = true;
            if(updatedAccounts.size() > 0) update updatedAccounts;
            if(updatedSLocs.size() > 0) update updatedSLocs;
            SynchronizingFields = oSynch;
        }
    }
    
    private static void defaultNullValues(List<Customer_Detail__c> tNew){
        for(Customer_Detail__c cd : tNew){
            if(cd.Name == null) cd.Name = 'Customer Detail';
            if(cd.Parent_Account__c == null) cd.Parent_Account__c = SecurityUtils.SystemAccount.Id;
        }
    }
    
    private static void handleUpdatedTaxMainAddress(List<Customer_Detail__c> tNew, Map<Id, Customer_Detail__c> tOldMap){        
        List<Customer_Detail__c> updated = new List<Customer_Detail__c>();
        List<Customer_Detail__c> defaultPaymentCD = new List<Customer_Detail__c>();
        Map<Id, Location__c> lMap = new Map<Id, Location__c>();
        Map<Id, Location__c> l2Map = new Map<Id, Location__c>();

        for(Customer_Detail__c dNew : tNew){
            Customer_Detail__c dOld = tOldMap.get(dNew.Id);
                
            if(dNew.Tax_Main_Address__c != null || (dOld != null && dNew.Tax_Main_Address__c != dOld.Tax_Main_Address__c) || (dOld != null && dNew.ICC_Subscriber_ID__c == null && dNew.Care_Organization__c != dOld.Care_Organization__c)){
                lMap.put(dNew.Tax_Main_Address__c, null);
                if(dOld != null && dOld.Tax_Main_Address__c != null) lMap.put(dOld.Tax_Main_Address__c, null);
                updated.add(dNew);
            }
            
            if(dNew.Payment_Term__c == null && ( dNew.Tax_Main_Address__c != null || (dOld != null && dNew.Tax_Main_Address__c != dOld.Tax_Main_Address__c))){
                defaultPaymentCD.add(dNew);
                l2Map.put(dNew.Tax_Main_Address__c, null);
            }
        }

        if(updated.size() > 0){
            lMap = new Map<Id, Location__c>([select Id, Building__r.State__c, Building__r.Country__c from Location__c where Id in: lMap.keyset()]);
            
            for(Integer i=updated.size()-1; i>=0; i--){
                Customer_Detail__c dNew = updated[i];
                Customer_Detail__c dOld = tOldMap.get(dNew.Id);
                
                String newCountry = lMap.get(dNew.Tax_Main_Address__c).Building__r.Country__c;
                String oldCountry = dOld != null && dOld.Tax_Main_Address__c != null ? lMap.get(dOld.Tax_Main_Address__c).Building__r.Country__c : null;

                String newState = lMap.get(dNew.Tax_Main_Address__c).Building__r.State__c;
                String oldState = dOld != null && dOld.Tax_Main_Address__c != null ? lMap.get(dOld.Tax_Main_Address__c).Building__r.State__c : null;
                String oldCareOrg = dOld != null? dOld.Care_Organization__c : null;
                if(string.isEmpty(newState) || newState == oldState || newCountry==CustomerDetailUtils.COUNTRY_CA){
                    if(string.isEmpty(newState)){
                        updated.remove(i);
                    }                    
                    
                    if(dNew.ICC_Subscriber_ID__c!= null){ 
                       if((newCountry==CustomerDetailUtils.COUNTRY_US &&  newState == oldState) ||(newCountry==CustomerDetailUtils.COUNTRY_CA)){                   
                           updated.remove(i);
                       }
                    }else if(dNew.ICC_Subscriber_ID__c == null && dNew.Reporting_Company__c != null && (dNew.Care_Organization__c == oldCareOrg ||newCountry==CustomerDetailUtils.COUNTRY_CA) ){
                       updated.remove(i);
                    }                                    
                }
            }
            
            if(updated.size() > 0){
                Map<String, Integer> keyToRCID = new Map<String, Integer>();
                for(Process_Configuration__c pc : [select Key__c, Value__c from Process_Configuration__c Where Process__c = 'ReportingCompanyMap']){
                    for(String v : pc.Value__c.split(',')) keyToRCID.put(v, Integer.valueOf(pc.Key__c));
                }
                
                Id coID = [select Id from RecordType where sObjectType = 'Customer_Setting__c' and DeveloperName = 'Care_Organization'].Id;
                Map<Id, String> careOrgNames =new Map<Id, String>();            
                Map<String, Id> careOrgKeys =new Map<String, Id>(); 
                for(Customer_Setting__c co : [select Id, Name from Customer_Setting__c where RecordTypeId =: coID]){            
                   careOrgNames.put(co.Id, co.Name);
                   careOrgKeys.put(co.Name, co.Id);
                }                
                
                Id rcID = [select Id from RecordType where sObjectType = 'Customer_Setting__c' and DeveloperName = 'Reporting_Company'].Id;
                Map<Integer, Id> rcIDToSFID = new Map<Integer, Id>();
                for(Customer_Setting__c rc : [select Id, External_ID__c from Customer_Setting__c where RecordTypeId =: rcID]) rcIDToSFID.put(Integer.valueOf(rc.External_ID__c), rc.Id);
                
                for(Customer_Detail__c dNew : updated){
                    String careOrgName = dNew.Care_Organization__c!=null?careOrgNames.get(dNew.Care_Organization__c):null;

                    for(String key : new List<String>{ careOrgName, lMap.get(dNew.Tax_Main_Address__c).Building__r.Country__c == CustomerDetailUtils.COUNTRY_CA ? CustomerDetailUtils.COUNTRY_CAN : lMap.get(dNew.Tax_Main_Address__c).Building__r.Country__c}){                        
                        if(keyToRCID.get(key) != null && rcIDToSFID.get(keyToRCID.get(key)) != null){
                             dNew.Reporting_Company__c = rcIDToSFID.get(keyToRCID.get(key));
                        }
                    }
                }
            }
            
            if(defaultPaymentCD.size() > 0){
                l2Map = new Map<Id, Location__c>([select Id, Building__r.State__c, Building__r.Country__c from Location__c where Id in: l2Map.keyset()]);
                 for(Customer_Detail__c dNew : defaultPaymentCD){
                    String newCountry = dNew.Tax_Main_Address__c != null ? l2Map.get(dNew.Tax_Main_Address__c).Building__r.Country__c : null;
                     if(newCountry == CustomerDetailUtils.COUNTRY_CA){
                       dNew.Payment_Term__c = CustomerDetailUtils.PAYMENT_TERM_CA_DEFAULT;
                     }else if(newCountry == CustomerDetailUtils.COUNTRY_US){
                        dNew.Payment_Term__c = CustomerDetailUtils.PAYMENT_TERM_US_DEFAULT;
                     }
                }               
            }
        }
    }
    
    private static void updateSubscribers(List<Customer_Detail__c> tNew, Map<Id, Customer_Detail__c> tOldMap){
        Map<Id, User> owners = new Map<Id, User>();
        if(!IntegrationDisabled){
            for(List<Customer_Detail__c> cdl : new List<List<Customer_Detail__c>>{tNew, tOldMap.values()}){
                for(Customer_Detail__c cd : cdl){
                    if(cd.Owner__c != null)
                        owners.put(cd.Owner__c, null);
                }
            }
            owners = new Map<Id, User>([select Id, Sales_Channel__c from User where Id in : owners.keyset()]);
        }
        
        Set<Id> detached = new Set<Id>();
        for(Customer_Detail__c cd : [select Id, (select Id from Accounts__r), (select Id from Service_Locations__r) from Customer_Detail__c where Id in: tNew]){
            if((cd.Accounts__r == null || cd.Accounts__r.size() == 0) && (cd.Service_Locations__r == null || cd.Service_Locations__r.size() == 0)) detached.add(cd.Id);
        }
        
        Map<Id, String> updatedCustomerDetails = new Map<Id, String>();
        for(Customer_Detail__c dNew : tNew){
            if(!string.IsEmpty(dNew.ICC_Subscriber_ID__c)){
                Customer_Detail__c dOld = tOldMap.get(dNew.Id);
                Set<String> updates = new Set<String>();
                
                Boolean nameUpdated = false;
                if(!IntegrationDisabled){
                    //Name
                    Boolean nflNameSet = !string.IsEmpty(dNew.First_Name__c) && !string.IsEmpty(dNew.Last_Name__c);
                    Boolean oflNameSet = !string.IsEmpty(dOld.First_Name__c) && !string.IsEmpty(dOld.Last_Name__c);
                    if(nflNameSet) updates.add(getUpdateName(dNew.First_Name__c != dOld.First_Name__c || dNew.Last_Name__c != dOld.Last_Name__c, 'FirstName_LastName'));
                    else updates.add(getUpdateName(oflNameSet || dNew.Name != dOld.Name, 'Name'));
                    nameUpdated = updates.contains('Name') || updates.contains('FirstName_LastName');
                    
                    //Ownership
                    if(dOld.Owner__c != dNew.Owner__c || dOld.Owner_Agency__c != dNew.Owner_Agency__c || dOld.Split_Owner__c != dNew.Split_Owner__c || dOld.Split_Owner_Agency__c != dNew.Split_Owner_Agency__c){
                        if(IntegrateAllOwners || detached.contains(dNew.Id))
                            updates.add(getUpdateName(true, 'Owner'));
                        else batchUpdates.put(dNew.Id, 'Owner');
                    }
                    updates.add(getUpdateName(dNew.Customer_Account_Manager__c != dOld.Customer_Account_Manager__c, 'CAM'));
                    
                    //Credit Info
                    updates.add(getUpdateName(dNew.Collection_Code__c != null && dNew.Collection_Code__c != dOld.Collection_Code__c, 'CollectionCode'));
                    updates.add(getUpdateName(dNew.Collection_Rep__c != null && dNew.Collection_Rep__c != dOld.Collection_Rep__c, 'CollectionRep'));
                    updates.add(getUpdateName(dNew.Credit_Approved_Date__c != null && dNew.Credit_Approved_Date__c != dOld.Credit_Approved_Date__c, 'CreditApprovedDate'));
                    updates.add(getUpdateName(dNew.Credit_Bureau__c != null && dNew.Credit_Bureau__c != dOld.Credit_Bureau__c, 'CreditBureau'));
                    updates.add(getUpdateName(dNew.Credit_Bureau_Not_Available__c != null && dNew.Credit_Bureau_Not_Available__c != dOld.Credit_Bureau_Not_Available__c, 'CreditBureauNotAvailable'));
                    updates.add(getUpdateName(dNew.Credit_Checked_By__c != null && dNew.Credit_Checked_By__c != dOld.Credit_Checked_By__c, 'CreditCheckedBy'));
                    updates.add(getUpdateName(dNew.Credit_Class__c != null && dNew.Credit_Class__c != dOld.Credit_Class__c, 'CreditClass'));
                    updates.add(getUpdateName(dNew.Credit_Limit__c != null && dNew.Credit_Limit__c != dOld.Credit_Limit__c, 'CreditLimit'));
                    updates.add(getUpdateName(dNew.Credit_Score__c != null && dNew.Credit_Score__c != dOld.Credit_Score__c, 'CreditScore'));
                    updates.add(getUpdateName(dNew.Credit_Score_Date__c != null && dNew.Credit_Score_Date__c != dOld.Credit_Score_Date__c, 'CreditScoreDate'));
                    updates.add(getUpdateName(dNew.MSS_Account_ID__c != null && dNew.MSS_Account_ID__c != dOld.MSS_Account_ID__c, 'MSSAccountID'));
                    
                    updates.add(getUpdateName(dNew.Phone__c != null && dNew.Phone__c != dOld.Phone__c, 'Phone'));
                    updates.add(getUpdateName(dNew.Care_Organization__c != null && dNew.Care_Organization__c != dOld.Care_Organization__c, 'CareOrg'));
                    updates.add(getUpdateName(dNew.Government_Contract_Type__c != dOld.Government_Contract_Type__c, 'ContractType'));
                    updates.add(getUpdateName(dNew.Government_Segment__c != dOld.Government_Segment__c, 'GovernmentType'));
                    updates.add(getUpdateName(dNew.Bill_Cycle__c != null && dNew.Bill_Cycle__c != dOld.Bill_Cycle__c, 'BillCycle'));
                    updates.add(getUpdateName(dNew.Disputed_Amount__c != null && dNew.Disputed_Amount__c != dOld.Disputed_Amount__c, 'DisputedAmount'));
                    updates.add(getUpdateName(dNew.Exchange__c != null && dNew.Exchange__c != dOld.Exchange__c, 'Exchange'));
                    updates.add(getUpdateName(dNew.Market_Subtype__c != null && dNew.Market_Subtype__c != dOld.Market_Subtype__c, 'MarketSubtype'));
                    updates.add(getUpdateName(dNew.Prov_Market_Area__c != null && dNew.Prov_Market_Area__c != dOld.Prov_Market_Area__c, 'ProvMarketArea'));
                    updates.add(getUpdateName(dNew.Past_Due__c != dOld.Past_Due__c, 'PastDue'));
                    updates.add(getUpdateName(dNew.Reporting_Company__c != dOld.Reporting_Company__c, 'ReportingCompany'));
                    updates.add(getUpdateName(dNew.Suspended__c != dOld.Suspended__c, 'Suspended'));
                }
                
                if(!IntegrationDisabled || UpdateAddresses){
                    //Adddresses
                    Boolean subIDSet = dOld.ICC_Subscriber_ID__c != dNew.ICC_Subscriber_ID__c;
                    updates.add(getUpdateName(dNew.Customer_Main_Address__c != null && (dNew.Customer_Main_Address__c != dOld.Customer_Main_Address__c || subIDSet || nameUpdated), 'Customer_Main_Address__c'));
                    updates.add(getUpdateName(dNew.Service_Address__c != null && (dNew.Service_Address__c != dOld.Service_Address__c || subIDSet || nameUpdated), 'Service_Address__c'));
                    updates.add(getUpdateName(dNew.Tax_Main_Address__c != null && (dNew.Tax_Main_Address__c != dOld.Tax_Main_Address__c || subIDSet || nameUpdated), 'Tax_Main_Address__c'));
                    updates.add(getUpdateName(dNew.Billing_Main_Street__c != null &&
                        ((dNew.Billing_Main_City__c != dOld.Billing_Main_City__c
                        || dNew.Billing_Main_Postal_Code__c != dOld.Billing_Main_Postal_Code__c
                        || dNew.Billing_Main_State__c != dOld.Billing_Main_State__c
                        || dNew.Billing_Main_Street__c != dOld.Billing_Main_Street__c
                        || dNew.Billing_Main_Room_Suite__c != dOld.Billing_Main_Room_Suite__c
                        || dNew.Billing_Main_Name__c != dOld.Billing_Main_Name__c) || subIDSet || nameUpdated), 'Billing_Main'));
                    updates.add(getUpdateName(dNew.Billing_Final_Street__c != null &&
                        ((dNew.Billing_Final_City__c != dOld.Billing_Final_City__c
                        || dNew.Billing_Final_Postal_Code__c != dOld.Billing_Final_Postal_Code__c
                        || dNew.Billing_Final_State__c != dOld.Billing_Final_State__c
                        || dNew.Billing_Final_Street__c != dOld.Billing_Final_Street__c
                        || dNew.Billing_Final_Room_Suite__c != dOld.Billing_Final_Room_Suite__c
                        || dNew.Billing_Final_Name__c != dOld.Billing_Final_Name__c) || subIDSet || nameUpdated), 'Billing_Final'));
                }
                
                updates.remove('');
                if(updates.size() > 0)
                    updatedCustomerDetails.put(dNew.Id, string.join(new List<String>(updates), ','));
            }
        }
        
        if(updatedCustomerDetails.size() > 0 && integraWSEndpointMediator.canRunIntegrationUpdate('Customer_Detail__c'))
            updateSubscribers(updatedCustomerDetails, UserInfo.getSessionId(), UserInfo.getUserEmail());
    }
    
    private static string getUpdateName(Boolean updated, String value){
        return updated ? value : '';
    }
    
    public static Map<Id, String> batchUpdates = new Map<Id, String>();
    public static void updateSubscribers(Map<Id, String> updatedCustomerDetails, string sessionID, string errorEmail){
        
        if(!System.isBatch()){
            if(System.isFuture()) updateSubscribers_callout(updatedCustomerDetails, sessionID, errorEmail);
            else updateSubscribers_future(updatedCustomerDetails, sessionID, errorEmail);
        }
        else{
            //Add to the batchUpdates buffer to flush later
            for(Id id : updatedCustomerDetails.keySet()){
                Set<String> updates = batchUpdates.get(id) != null ? new Set<String>(updatedCustomerDetails.get(id).split(',')) : new Set<String>();
                updates.addAll(updatedCustomerDetails.get(id).split(','));
                batchUpdates.put(id, string.join(new List<String>(updates), ','));
            }
        }
    }
    
    public static void updateSubscribers_flushBatch(Map<Id, String> updates, string sessionID, string errorEmail){
        if(updates != null && updates.size() > 0) updateSubscribers_callout(updates, sessionID, errorEmail);
    }
    
    @future(callout=true)
    private static void updateSubscribers_future(Map<Id, String> updatedCustomerDetails, string sessionID, string errorEmail){
        updateSubscribers_callout(updatedCustomerDetails, sessionID, errorEmail);
    }
    
    private static void updateSubscribers_callout(Map<Id, String> updatedCustomerDetails, string sessionID, string errorEmail){
        try{
            Map<Id, Customer_Detail__c> customerDetails = new Map<Id, Customer_Detail__c>((List<Customer_Detail__c>)(ApexUtils.retrieveObjectsFromFieldSets(Customer_Detail__c.getsObjectType()
                                                                                                        ,new List<Set<String>>{
                                                                                                            AddressUtils.CustomerDetailAddressFieldSet
                                                                                                            ,IntegrationUtils.CustomerDetailIntegrationFieldSet
                                                                                                            ,new Set<String>{'(select Id, Name from Accounts__r)','(select Id, Name from Service_Locations__r)'}
                                                                                                            }
                                                                                                        ,'Id in (\'' + string.join(new List<Id>(updatedCustomerDetails.keyset()), '\',\'') + '\')'
                                                                                                        ,null)));
            
            List<integraWS.SFSubscriberView> subscribers = new List<integraWS.SFSubscriberView>();
            List<integraWS.SFSubscriberAddressView> addresses = new List<integraWS.SFSubscriberAddressView>();
            for(Id id : customerDetails.keyset()){
                Customer_Detail__c d = customerDetails.get(id);
                Set<String> updates = new Set<String>(updatedCustomerDetails.get(id).split(','));
                
                if(d == null || string.IsEmpty(d.ICC_Subscriber_ID__c) || updates == null || updates.size() == 0) continue;
                system.debug(id + ' had the following updates: ' + updates);
                
                Set<String> addressUpdates = new Set<String>();
                Set<String> subUpdates = new Set<String>();
                for(String str : updates){
                    if(AddressUtils.CustomerDetailFieldAddressTypes.keyset().contains(str)
                        || AddressUtils.CustomerDetailFieldSetAddressTypes.keyset().contains(str))
                        addressUpdates.add(str);
                    else subUpdates.add(str);
                }
                
                if(subUpdates.size() > 0){
                    integraWS.SFSubscriberView sub = new integraWS.SFSubscriberView();
                    sub.SubscriberId = integer.valueOf(d.ICC_Subscriber_ID__c);
                    sub.SalesforceId = id;
                    
                    sub.FieldsToNull = new schemasMicrosoftCom200310Serializat.ArrayOfstring();
                    sub.FieldsToNull.string_x = new List<String>();
                    
                    if(updates.contains('FirstName_LastName')){
                        sub.FirstName = d.First_Name__c;
                        sub.LastName = d.Last_Name__c;
                    }
                    else if(updates.contains('Name')) sub.AccountName = d.Name;
                    
                    if(updates.contains('CollectionCode') && d.Collection_Code__c != null) sub.CollectionCodeID = integer.ValueOf(d.Collection_Code__r.External_ID__c);
                    if(updates.contains('CollectionRep') && d.Collection_Rep__c != null) sub.CollectionRep = d.Collection_Rep__r.NTID__c;
                    if(updates.contains('CreditApprovedDate') && d.Credit_Approved_Date__c != null) sub.CreditApprovedDate = d.Credit_Approved_Date__c;
                    if(updates.contains('CreditBureau') && d.Credit_Bureau__c != null) sub.CreditBureau = d.Credit_Bureau__c;
                    if(updates.contains('CreditBureauNotAvailable') && d.Credit_Bureau_Not_Available__c != null) sub.CreditBureauNotAvailable = d.Credit_Bureau_Not_Available__c;
                    if(updates.contains('CreditCheckedBy') && d.Credit_Checked_By__c != null) sub.CreditCheckedBy = d.Credit_Checked_By__r.NTID__c;
                    if(updates.contains('CreditClass') && d.Credit_Class__c != null) sub.CreditClass = d.Credit_Class__c;
                    if(updates.contains('CreditLimit') && d.Credit_Limit__c != null) sub.CreditLimit = d.Credit_Limit__c;
                    if(updates.contains('CreditScore') && d.Credit_Score__c != null) sub.CreditScore = d.Credit_Score__c;
                    if(updates.contains('CreditScoreDate') && d.Credit_Score_Date__c != null) sub.CreditScoreDate = d.Credit_Score_Date__c;
                    if(updates.contains('MSSAccountID') && d.MSS_Account_ID__c != null) sub.MSSAccountID = d.MSS_Account_ID__c;
                    
                    if(updates.contains('CareOrg') && d.Care_Organization__c != null) sub.CareOrgID = integer.ValueOf(d.Care_Organization__r.External_ID__c);
                    if(updates.contains('BillCycle') && d.Bill_Cycle__c != null) sub.BillCycleID = integer.ValueOf(d.Bill_Cycle__r.Value__c);
                    if(updates.contains('DisputedAmount')) sub.DisputedAmount = d.Disputed_Amount__c;
                    if(updates.contains('Exchange') && d.Exchange__c != null) sub.ExchangeID = integer.ValueOf(d.Exchange__r.External_ID__c);
                    if(updates.contains('MarketSubtype') && d.Market_Subtype__r != null) sub.EPCSubTypeID = integer.ValueOf(d.Market_Subtype__r.External_ID__c);
                    if(updates.contains('ProvMarketArea') && d.Prov_Market_Area__r != null) sub.ProvMarketAreaId = integer.ValueOf(d.Prov_Market_Area__r.ProvMarketAreaID__c);
                    if(updates.contains('PastDue')) sub.IsPastDue = d.Past_Due__c;
                    if(updates.contains('ReportingCompany')) sub.ReportingCompanyID = d.Reporting_Company__c != null ? integer.valueOf(d.Reporting_Company__r.External_ID__c) : null;
                    if(updates.contains('Suspended')) sub.Suspended = d.Suspended__c;
                    if(updates.contains('Phone')){
                        if(!string.IsEmpty(d.Phone__c)) sub.MainNumber = d.Phone__c.replace('(', '').replace(')', '').replace('-', '').replace(' ', '');
                        else sub.FieldsToNull.string_x.add('Phone');
                    }
                    if(updates.contains('CAM')){
                        if(d.Customer_Account_Manager__c != null && d.Customer_Account_Manager__r.NTID__c != null) sub.AccountManagerID = d.Customer_Account_Manager__r.NTID__c;
                        else sub.FieldsToNull.string_x.add('AccountManager');
                    }
                    if(updates.contains('ContractType')){
                        if(!string.IsEmpty(d.Government_Contract_Type__c)) sub.ContractType = ICCWrapper.GetGovernmentContractType(d);
                        else sub.FieldsToNull.string_x.add('ContractType');
                    }
                    if(updates.contains('GovernmentType')){
                        if(!string.IsEmpty(d.Government_Segment__c)) sub.GovernmentType = d.Government_Segment__c;
                        else sub.FieldsToNull.string_x.add('GovernmentType');
                    }
                    if(updates.contains('Owner')){
                        sub.SalesUserID1IsAgent = d.Owner_Agency__c != null;
                        sub.SalesUserID2IsAgent = d.Split_Owner_Agency__c != null;
                        
                        sub.SalesUserID1 = sub.SalesUserID1IsAgent ? ICCWrapper.getAgentIDFromAgency(d.Owner_Agency__r) : d.Owner__r.NTID__c;
                        sub.SalesUserID2 = sub.SalesUserID2IsAgent ? ICCWrapper.getAgentIDFromAgency(d.Split_Owner_Agency__r) : (d.Split_Owner__c != null ? d.Split_Owner__r.NTID__c : null);
                        sub.SalesUserCommision2 = d.Split_Owner_Percentage__c != null ? (d.Split_Owner_Percentage__c).intValue() : null;
                        
                        if(sub.SalesUserID2 == null) sub.FieldsToNull.string_x.add('SalesUserID2');
                        if(sub.SalesUserCommision2 == null) sub.FieldsToNull.string_x.add('SalesUserCommission2');
                    }
                    
                    subscribers.add(sub);
                }
                if(addressUpdates.size() > 0){
                    Integer marketAreaID = d.Market_Area__c != null ? integer.valueOf(d.Market_Area__r.ICCMarketAreaID__c) : null;
                    for(String addressField : addressUpdates){
                        integraWS.SFSubscriberAddressView addr = AddressUtils.CustomerDetailFieldAddressTypes.keyset().contains(addressField)
                                                                ? AddressUtils.setSubscriberAddressViewNameValues(
                                                                        AddressUtils.setSubscriberAddressViewValues((Location__c)d.getsObject(addressField.replace('__c', '__r')), integer.valueOf(d.ICC_Subscriber_ID__c), AddressUtils.CustomerDetailFieldAddressTypes.get(addressField), marketAreaID)
                                                                    ,null, d.Name, d.First_Name__c, d.Last_Name__c)
                                                                : AddressUtils.setSubscriberAddressViewValuesFromCustomerDetailFieldSet(d, integer.valueOf(d.ICC_Subscriber_ID__c), addressField);
                        if(addr != null) addresses.add(addr);
                    }
                }
            }
            
            Map<Id, String> errorMap = new Map<Id, String>();
            if(subscribers.size() > 0){
                List<integraWS.SFSubscriberView> flattenedResults = ICCWrapper.getFlattenedSFSubscriberViewList(ICCWrapper.updateSubscribers(subscribers, sessionID));
                for(integraWS.SFSubscriberView v : flattenedResults){
                    if(!string.IsEmpty(v.ResultMessage)) errorMap.put(v.SalesforceId, v.ResultMessage);
                }
            }
            if(addresses.size() > 0){
                List<integraWS.SFSubscriberAddressView> results = ICCWrapper.updateSubscriberAddresses(addresses, sessionID);
                for(integraWS.SFSubscriberAddressView v : results){
                    if(!string.IsEmpty(v.ResultMessage)) errorMap.put(v.SalesforceId, v.ResultMessage);
                }
            }
            
            if(errorMap.size() > 0) IntegrationUtils.createUpdateIntegrationErrors(errorMap, updatedCustomerDetails);
        }
        catch(Exception e){
            String detailString = IntegrationUtils.emailIntegrationException(e, errorEmail, 'Subscriber integration update exception');
            IntegrationUtils.createUpdateIntegrationErrors(updatedCustomerDetails.keyset(), detailString, updatedCustomerDetails);
        }
    }
    
    private static List<Map<String, String>> addressValidationMapping = null;
    private static void handleAddressValidations(List<Customer_Detail__c> tNew, Map<Id, Customer_Detail__c> tOldMap){
        if(ValidateAddresses){
            Boolean validationsFound = false;
            if(addressValidationMapping == null) addressValidationMapping = new List<Map<String, String>>();
            
            for(Integer i=0; i<tNew.size(); i++){
                Boolean preloaded = addressValidationMapping.size() > i;
                validationsFound |= preloaded;
                
                Map<String, String> m = preloaded ? addressValidationMapping[i] : new Map<String, String>();
                
                Customer_Detail__c dNew = tNew[i];
                Customer_Detail__c dOld = tOldMap != null ? tOldMap.get(dNew.Id) : null;
                for(String str : AddressUtils.CustomerDetailFieldAddressTypes.keyset()){
                    if(dNew.get(str) != null && (dOld == null || dNew.get(str) != dOld.get(str))){
                        m.put(str, (Id)dNew.get(str));
                        dNew.put(str, dOld != null ? dOld.get(str) : '');
                        validationsFound = true;
                    }
                }
                
                for(String str : AddressUtils.CustomerDetailFieldSetAddressTypes.keyset()){
                    Boolean fsFound = false;
                    for(String fsField : AddressUtils.CustomerDetailFieldSetAddressSubFields){
                        String f = str + '_' + fsField;
                        fsFound = dNew.get(f) != null && (dOld == null || dNew.get(f) != dOld.get(f));
                        if(fsFound) break;
                    }
                    
                    if(fsFound){
                        validationsFound = true;
                        String val = '';
                        for(String fsField : AddressUtils.CustomerDetailFieldSetAddressSubFields){
                            String f = str + '_' + fsField;
                            val += (!String.isEmpty(val) ? '\t' : '') + (dNew.get(f) != null ? string.valueOf(dNew.get(f)).replace('\t', '') : '');
                            dNew.put(f, dOld != null ? dOld.get(f) : '');
                            validationsFound = true;
                        }
                        
                        m.put(str, val);
                    }
                }
                
                if(!preloaded) addressValidationMapping.add(m);
            }
            
            if(!validationsFound) AddressValidationMapping = null;
        }
    }
    
    //Hack to stop insert->delete history on inserted addresses
    public static void preloadAddressValidations(List<Customer_Detail__c> inserts){
        handleAddressValidations(inserts, null);
    }
    
    public static Boolean ManualAddressValidation = false;  //If this is set, prepare the address updates in the map below, but don't send them to the asynch process
    public static Map<Id, Map<String, String>> AddressValidationMappingByID = null;
    private static void validateAddresses(List<Customer_Detail__c> tNew){
        if(addressValidationMapping != null){
            AddressValidationMappingByID = new Map<Id, Map<String, String>>();
            for(Integer i=0; i<tNew.size(); i++){
                if(addressValidationMapping[i].size() > 0) AddressValidationMappingByID.put(tNew[i].Id, addressValidationMapping[i]);
            }
            
            if(AddressValidationMappingByID.size() > 0 && integraWSEndpointMediator.canRunIntegrationUpdate('Customer_Detail__c') && !ManualAddressValidation)
                AddressUtils.validateAndSetCustomerDetailAddresses_Asynch(JSON.serialize(AddressValidationMappingByID), UserInfo.getSessionId());
        }
    }
    
    private static void createAccountScheduledTasks(List<Customer_Detail__c> tNew, Map<Id, Customer_Detail__c> tOldMap){        
        List<Customer_Detail__c> detailsToWorkWith = new List<Customer_Detail__c>();
        Set<Id> acctIds = new Set<Id>();
        Set<Account_Scheduled_Task__c> upsertTasks = new Set<Account_Scheduled_Task__c>();
        
        Set<String> astBusinessUnits = new Set<String>( CustomSettingUtils.getProcessConfigurationValues('ASTAutogen','BusinessUnit'));
        
        for(Customer_Detail__c cDetail : tNew){
            Customer_Detail__c oldDetail = tOldMap.get(cDetail.Id);
            if(oldDetail != null && ((cDetail.Customer_Account_Manager__c != null && (/*cDetail.MRR__c != oldDetail.MRR__c ||*/ cDetail.Customer_Account_Manager__c != oldDetail.Customer_Account_Manager__c))|| ( cDetail.Care_Organization__c != oldDetail.Care_Organization__c ))){
                detailsToWorkWith.add(cDetail);
                acctIds.add(cDetail.Parent_Account__c);
            }
        }
        //Map<Id,Account> accts = new Map<Id,Account>([select Id, MRR__c, Account_Sales_Channel__c from Account where Id in :acctIds]);
        Map<Id,Account> accts = new Map<Id,Account>([select Id, MRR__c from Account where Id in :acctIds]);
        Map<Id,Account_Scheduled_Task__c> actToAst = new Map<Id,Account_Scheduled_Task__c>();
        for(Account_Scheduled_Task__c ast : [select Account__c, Starting_on__c, Automation_Enabled__c, Current_Activity_Required__c, Occurrence_Category__c, Occurrence_Day_of_the_Week__c, Occurrence_Frequency__c, Next_Run__c from Account_Scheduled_Task__c where Account__c in :acctIds and Disabled__c = false]){
            actToAst.put(ast.Account__c, ast);
        }
        for(Customer_Detail__c cDetail : detailsToWorkWith){
             String careOrgName =  cDetail.Care_Organization__c!=null?CustomerDetailUtils.getCareOrgById(cDetail.Care_Organization__c).Name:null;                  
            
            Account act = accts.get(cDetail.Parent_Account__c);
            if(act != null && astBusinessUnits.contains(careOrgName) && !actToAst.containsKey(act.Id)){            
                Account_Scheduled_Task__c ast = AccountScheduledTaskUtils.createASTForAccount(act.id, careOrgName, (decimal) act.MRR__c);
                upsertTasks.add(ast);
            }
            else{
                if(actToAst.containsKey(act.Id)){
                    Account_Scheduled_Task__c ast = actToAst.get(act.Id);
                    ast.Automation_Enabled__c = false;
                    upsertTasks.add(ast);
                }
            }
        }
        upsert new List<Account_Scheduled_Task__c>(upsertTasks);
        
    }
    
    private static void checkDuplicateBillingId(List<Customer_Detail__c> tNew, Map<Id, Customer_Detail__c> tOldMap){
        Map<String, Customer_Detail__c> tNewMap = new Map<String, Customer_Detail__c>();
        for(Customer_Detail__c cd : tNew){
            if (cd.Billable__c == true && cd.Billing_ID__c != null &&
                   ((tOldMap==null || (tOldMap != null && tOldMap.size() ==0))
                    || (tOldMap != null && cd.Id != null && cd.Billing_ID__c != tOldMap.get(cd.Id).Billing_ID__c)
                    || (tOldMap != null && cd.Id != null && cd.Acquired_Company_Biller__c != tOldMap.get(cd.Id).Acquired_Company_Biller__c)
                    || (tOldMap != null && cd.Id != null && cd.Legacy_ID__c != tOldMap.get(cd.Id).Legacy_ID__c)                    
                    )) {
               if (tNewMap.containsKey(cd.Billing_ID__c)) {               
                   Customer_Detail__c dupBillCD = tNewMap.get(cd.Billing_ID__c);
                   if(dupBillCD.Acquired_Company_Biller__c == cd.Acquired_Company_Biller__c){  
                      if(dupBillCD.Acquired_Company_Biller__c == 'IBIS' || dupBillCD.Acquired_Company_Biller__c == 'ICMS' ){
                             dupBillCD.addError('Another Customer Detail has Duplicate Billing ID.');
                      }
                         
                      if(dupBillCD.Acquired_Company_Biller__c == 'ASAP' && dupBillCD.Legacy_ID__c == cd.Legacy_ID__c){
                         dupBillCD.addError('Another Customer Detail has Duplicate Legacy ID.');
                      }
                   }
               } else {
            
                  tNewMap.put(cd.Billing_ID__c, cd);
               }
            }
        }            
    }
    
    private static void formatAccountNumbers(List<Customer_Detail__c> tNew) {
        
        List<Customer_Detail__c> updatedCDs = new List<Customer_Detail__c>{};
        for (Customer_Detail__c cd: tNew) {
            if (cd.Acquired_Company_Biller__c == 'IBIS') {
                if (cd.Legacy_ID__c != null && cd.Legacy_ID__c.length() < 12 ) 
                    cd.Legacy_ID__c = ('000000000000' + cd.Legacy_ID__c).right(12);

                if (cd.Billing_ID__c != null && cd.Billing_ID__c.length() < 12)  
                    cd.Billing_ID__c = '010000000000'.left(12 - cd.Billing_ID__c.length()) +  cd.Billing_ID__c; 
            }
        }
     }
}