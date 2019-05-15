public without sharing class ICCWrapper {
    
    public final static String NonBillableGrandparentType = 'Non-Billable Grandparent';
    public final static String BillableParentType = 'Billable Parent';
    public final static String NonBillableParentType = 'Non-Billable Parent';
    public final static String BillableChildType = 'Billable Child';
    public final static String NonBillableChildType = 'Non-Billable Child';
    public final static String StandAloneType = 'Stand-Alone';
    
    public final static String ResonsiblePartyContactType = 'Responsible Party';
    
    public final static String PriorLakeRecordType = 'ILEC_Prior_Lake';
    public final static String PriorLakeMarketAreaID = '27';
    
    public final static Set<String> BillableSubscriberTypes = new Set<String>{BillableParentType, BillableChildType, StandAloneType};
    public final static Set<String> IndirectChannels = new Set<String>{'Indirect', 'Indirect Sales'};
    
    public static final String roleAccountConsultant = 'Account Consultant';
    public static final String roleAcountSpecialistWholesale = 'Account Specialist - Wholesale';
    public static final String roleCustomerAccountManager = 'Customer Account Manager';
    
    public static final String partnerAgent = 'ICC_iSell_Assignment';
    public static final String partnerGuestAgent = 'Guest';
    
    public static Set<String> CamTeamMemberRoles {
        get {
            return new Set<String>{roleAccountConsultant, roleAcountSpecialistWholesale, roleCustomerAccountManager};
        }
    }
    
    public static Set<String> PartnerAgentTypes {
        get {
            return new Set<String>{partnerAgent, partnerGuestAgent};
        }
    }
    
    public static Boolean accountCanHaveNonBillableParentCreated(Account account, List<Service_Location__c> sLocs){
        Boolean canCreate = account.Type != 'Former Customer' && !string.IsEmpty(account.ICC_Account_Number__c);
        if(canCreate){
            List<Service_Location__c> lvl3;
            if(slocs == null){
                lvl3 = [select Id, Level__c from Service_Location__c where Account__c =: account.Id and Level__c = '3'];
            }
            else{
                lvl3 = new List<Service_Location__c>();
                for(Service_Location__c sloc : sLocs){
                    if(sloc.Level__c == '3')
                        lvl3.add(sloc);
                }
            }
            
            canCreate = canCreate && lvl3.size() == 0;
        }
        
        return canCreate;
    }
    
    public static String getAgentIDFromAgency(Account agency){
        return agency != null ? string.valueOf(/*(agency.AgentId__c != null || agency.Parent == null) ?*/ agency.AgentId__c /*: agency.Parent.AgentId__c*/) : null;
    }
    
    public static integraWS.SFSubscriberView setSubscriberValuesFromAccount(Account a, Customer_Detail__c detail) {
        
        integraWS.SFSubscriberView sub = setSubscriberValuesFromCustomerDetail(new integraWS.SFSubscriberView(), detail);
        sub.SalesforceId = a.Id;
        sub.Billable = a.Billable__c;   //Modify this outside of this method if needed
        sub.SICCode = !string.IsEmpty(a.Industry) ? a.Industry : 'Z - Unclassified';
        
        sub.Children = new integraWS.ArrayOfSFSubscriberView();
        sub.Children.SFSubscriberView = new list<integraWS.SFSubscriberView>();
        sub.BillCycleID = integer.ValueOf(detail.Bill_Cycle_External_ID__c) * -1;
        
        return sub;         
    }
    
    public static integraWS.SFSubscriberView setSubscriberValuesFromCustomerDetail(integraWS.SFSubscriberView sub, Customer_Detail__c detail){
        sub.SubscriberId = !string.IsEmpty(detail.ICC_Subscriber_ID__c) ? Integer.valueOf(detail.ICC_Subscriber_ID__c) : 0;

        sub.BillCycleID = integer.ValueOf(detail.Bill_Cycle_External_ID__c) * -1;

        sub.AccountManagerID = detail.Customer_Account_Manager__c != null ? GlobalUtilities.users.get(detail.Customer_Account_Manager__c).NTID__c : null;
        sub.CollectionCodeID = detail.Collection_Code__c != null ? integer.ValueOf(detail.Collection_Code__r.External_ID__c) : null;
        sub.CollectionRep = detail.Collection_Rep__c != null ? GlobalUtilities.users.get(detail.Collection_Rep__c).NTID__c : null;
        sub.CreditCheckedBy = detail.Credit_Checked_By__c != null ? GlobalUtilities.users.get(detail.Credit_Checked_By__c).NTID__c : null;
        sub.CreditBureau = detail.Credit_Bureau__c;
        sub.CreditBureauNotAvailable = detail.Credit_Bureau_Not_Available__c;
        sub.CreditClass = detail.Credit_Class__c;
        sub.CreditLimit = detail.Credit_Limit__c;
        sub.CreditScore = detail.Credit_Score__c;
        sub.CreditScoreDate = detail.Credit_Score_Date__c;
        sub.CreditApprovedDate = detail.Credit_Approved_Date__c;
        sub.DisputedAmount = detail.Disputed_Amount__c;
        sub.ExchangeID = detail.Exchange__c != null ? integer.ValueOf(detail.Exchange__r.External_ID__c) : null;
        sub.ContractType = GetGovernmentContractType(detail);
        sub.GovernmentType = detail.Government_Segment__c;
        sub.MarketAreaId = detail.Market_Area__c != null ? integer.ValueOf(detail.Market_Area__r.ICCMarketAreaID__c) : null;
        sub.MarketTypeID = detail.Market_Type__c != null ? integer.ValueOf(detail.Market_Type__r.External_ID__c) : null;
        sub.MSSAccountID = detail.MSS_Account_ID__c;
        sub.EPCSubTypeID = detail.Market_Subtype__c != null ? integer.ValueOf(detail.Market_Subtype__r.External_ID__c) : null;
        sub.ProvMarketAreaId = detail.Prov_Market_Area__c != null && !string.IsEmpty(detail.Prov_Market_Area__r.ProvMarketAreaID__c) ? integer.ValueOf(detail.Prov_Market_Area__r.ProvMarketAreaID__c) : null;
        sub.IsPastDue = detail.Past_Due__c;
        sub.Suspended = detail.Suspended__c;
        sub.ReportingCompanyID = detail.Reporting_Company__c != null ? integer.valueOf(detail.Reporting_Company__r.External_ID__c) : null;
        sub.CareOrgID = detail.Care_Organization__c != null ? integer.valueOf(detail.Care_Organization__r.External_ID__c) : null;
        
        //MNK added Aug 18, 17
        sub.CurrencyISOCode = detail.CurrencyISOCode;
        if(!string.IsEmpty(detail.First_Name__c) && !string.IsEmpty(detail.Last_Name__c)){
            sub.FirstName = detail.First_Name__c;
            sub.LastName = detail.Last_Name__c;
        }
        else
            sub.AccountName = detail.Name;
        
        if(!string.IsEmpty(detail.Phone__c)) sub.MainNumber = detail.Phone__c.replace('(','').replace(')','').replace('-','').replace(' ','');
        User owner = GlobalUtilities.users.get(detail.Owner__c);
        sub.SalesUserID1IsAgent = IndirectChannels.contains(owner.Sales_Channel__c);
        if(sub.SalesUserID1IsAgent)
            sub.SalesUserID1 = getAgentIDFromAgency(detail.Owner_Agency__r);
        else
            sub.SalesUserID1 = owner.NTID__c;
        
        sub.SalesUserID2IsAgent = detail.Split_Owner_Agency__c != null;
        if(sub.SalesUserID2IsAgent)
            sub.SalesUserID2 = getAgentIDFromAgency(detail.Split_Owner_Agency__r);
        else if(detail.Split_Owner__c != null)
            sub.SalesUserID2 = GlobalUtilities.users.get(detail.Split_Owner__c).NTID__c;
        
        if(detail.Split_Owner_Percentage__c != null)
            sub.SalesUserCommision2 = (detail.Split_Owner_Percentage__c).intValue();
        
        return sub;
    }
    
    public static String GetGovernmentContractType(Customer_Detail__c cd){
        return cd.Government_Contract_Type__c != null ? cd.Government_Contract_Type__c.replace(' (+Disaster Purchasing Program)', '') : null;
    }
    
    public static integraWS.SFSubscriberContactView setSubscriberContactValues(Contact c){
        integraWS.SFSubscriberContactView con = new integraWS.SFSubscriberContactView();
        con.SalesForceId = c.Id;
        con.Cell = c.MobilePhone != null ? c.MobilePhone.replace('(','').replace(')','').replace('-','').replace(' ','') : null;
        con.Fax = c.Fax != null ? c.Fax.replace('(','').replace(')','').replace('-','').replace(' ','') : null;
        con.FirstName = c.FirstName;
        con.LastName = c.LastName;
        con.City = c.MailingCity;
        con.State = c.MailingState;
        con.Zip = c.MailingPostalCode;
        con.Street = c.MailingStreet;
        con.Country = c.MailingCountry;
        con.Title = c.Title;
        con.AuthorizedUserPassword = c.Authorized_User_Password__c;
        con.Extension = c.Extension__c;
        
        con.Aliases = new integraWS.ArrayOfSFSubscriberContactAliasView();
        con.Aliases.SFSubscriberContactAliasView = new List<integraWS.SFSubscriberContactAliasView>();
        
        return con;
    }
    
    public static List<integraWS.SFSubscriberView> getFlattenedSFSubscriberViewList(List<integraWS.SFSubscriberView> subs){
        List<integraWS.SFSubscriberView> retval = new List<integraWS.SFSubscriberView>();
        
        if(subs != null){
            for(integraWS.SFSubscriberView sub : subs){
                retval.add(sub);
                if(sub.Children != null){
                    for(integraWS.SFSubscriberView child : getFlattenedSFSubscriberViewList(sub.Children.SFSubscriberView))
                        retval.add(child);
                }
            }
        }
        
        return retval;
    }
    
    public static List<integraWS.SFSubscriberView> updateSubscribers(List<integraWS.SFSubscriberView> subscribers, String sessionID) {
        integraWS.ArrayOfSFSubscriberView subs = new integraWS.ArrayOfSFSubscriberView();
        subs.SFSubscriberView = subscribers;

        if(!integraWSEndpointMediator.integrationEnabled()) return subscribers;
      
        subs = integraWSEndpointMediator.Endpoint.UpdateSubscriber(subs, sessionID, CustomSettingUtils.SFDCCallbackEndpoint);
       
        return (subs != null && subs.SFSubscriberView != null) ? subs.SFSubscriberView : new List<integraWS.SFSubscriberView>();
    }
    
    public static List<integraWS.SFSubscriberAddressView> updateSubscriberAddresses(List<integraWS.SFSubscriberAddressView> views, String sessionID){
        return updateValidateSubscriberAddresses(views, sessionID, true);
    }
    
    public static List<integraWS.SFSubscriberAddressView> validateSubscriberAddresses(List<integraWS.SFSubscriberAddressView> views, String sessionID){
        return updateValidateSubscriberAddresses(views, sessionID, false);
    }
    
    private static List<integraWS.SFSubscriberAddressView> updateValidateSubscriberAddresses(List<integraWS.SFSubscriberAddressView> views, String sessionID, Boolean updateMode){
        integraWS.ArrayOfSFSubscriberAddressView addresses = new integraWS.ArrayOfSFSubscriberAddressView();
        addresses.SFSubscriberAddressView = views;

        if(!integraWSEndpointMediator.integrationEnabled()) return views;

        addresses = updateMode
                    ? integraWSEndpointMediator.Endpoint.UpdateSubscriberAddresses(addresses, sessionID, CustomSettingUtils.SFDCCallbackEndpoint)
                    : integraWSEndpointMediator.Endpoint.ValidateSubscriberAddresses(addresses, sessionID, CustomSettingUtils.SFDCCallbackEndpoint);

        return (addresses != null && addresses.SFSubscriberAddressView != null) ? addresses.SFSubscriberAddressView : new List<integraWS.SFSubscriberAddressView>(); 
    }
    
    public static List<integraWS.SFSubscriberContactView> updateSubscriberContacts(List<integraWS.SFSubscriberContactView> views, String sessionID){
        integraWS.ArrayOfSFSubscriberContactView contacts = new integraWS.ArrayOfSFSubscriberContactView();
        contacts.SFSubscriberContactView = views;
        
        if(!integraWSEndpointMediator.integrationEnabled()) return views;

        contacts = integraWSEndpointMediator.Endpoint.UpdateSubscriberContacts(contacts, sessionID, CustomSettingUtils.SFDCCallbackEndpoint);
        return (contacts != null && contacts.SFSubscriberContactView != null) ? contacts.SFSubscriberContactView : new List<integraWS.SFSubscriberContactView>(); 
    }
    
    public static List<Integer> deleteSubscriberContacts(List<Integer> contactIDs, String sessionID){
        integraWS.ListOfInt cIDs = new integraWS.ListOfInt();
        cIDs.ListOfIntEntry = contactIDs;
        
        if(!integraWSEndpointMediator.integrationEnabled()) return contactIDs;
        
        return integraWSEndpointMediator.Endpoint.DeleteSubscriberContacts(cIDs, sessionID, CustomSettingUtils.SFDCCallbackEndpoint).ListOfIntEntry;
    }
    
    public static integraWS.SFSubscriberSettingView getSubscriberSettingFromCustomerSetting(Customer_Setting__c setting, String subscriberId){
        integraWS.SFSubscriberSettingView retval = new integraWS.SFSubscriberSettingView();
        retval.SubscriberID = !string.IsEmpty(subscriberId) ? integer.valueOf(subscriberId) : 0;
        retval.ID = !string.IsEmpty(setting.External_ID__c) ? integer.valueOf(setting.External_ID__c) : null;
        retval.SettingID = !string.IsEmpty(setting.Reference_ID__c) ? integer.valueOf(setting.Reference_ID__c) : 0;
        retval.Value = setting.Value__c;
        retval.SalesforceID = setting.Id;
        
        return retval;
    }
    
    public static List<integraWS.SFSubscriberSettingView> updateSubscriberSettings(List<integraWS.SFSubscriberSettingView> settings){
        integraWS.ArrayOfSFSubscriberSettingView ss = new integraWS.ArrayOfSFSubscriberSettingView();
        ss.SFSubscriberSettingView = settings;
        
        if(!integraWSEndpointMediator.integrationEnabled()) return settings;
        
        ss = integraWSEndpointMediator.Endpoint.UpdateSubscriberSettings(ss, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
        return (ss != null && ss.SFSubscriberSettingView != null) ? ss.SFSubscriberSettingView : new List<integraWS.SFSubscriberSettingView>();
    }
    
    public static List<Integer> deleteSubscriberSettings(List<Integer> settingIDs, String sessionID){
        integraWS.ListOfInt sIDs = new integraWS.ListOfInt();
        sIDs.ListOfIntEntry = settingIDs;
        
        if(!integraWSEndpointMediator.integrationEnabled()) return settingIDs;
        
        return integraWSEndpointMediator.Endpoint.DeleteSubscriberSettings(sIDs, sessionID, CustomSettingUtils.SFDCCallbackEndpoint).ListOfIntEntry;
    }
    
    public static integraWS.SFSubscriberTaxInformationView getSubscriberTaxInformationFromCustomerSetting(Customer_Setting__c setting, String subscriberId){
        integraWS.SFSubscriberTaxInformationView retval = new integraWS.SFSubscriberTaxInformationView();
        retval.SubscriberID = !string.IsEmpty(subscriberId) ? integer.valueOf(subscriberId) : 0;
        retval.ID = !string.IsEmpty(setting.External_ID__c) ? integer.valueOf(setting.External_ID__c) : null;
        retval.TaxID = !string.IsEmpty(setting.Reference_ID__c) ? integer.valueOf(setting.Reference_ID__c) : 0;
        retval.StartDate = setting.Start_Date__c;
        retval.EndDate = setting.End_Date__c;
        retval.ExemptFormProvided = setting.Exempt_Form_Provided__c;
        retval.SalesforceID = setting.Id;
        
        return retval;
    }
    
    public static List<integraWS.SFSubscriberTaxInformationView> updateSubscriberTaxInformation(List<integraWS.SFSubscriberTaxInformationView> taxInfos){
        integraWS.ArrayOfSFSubscriberTaxInformationView ti = new integraWS.ArrayOfSFSubscriberTaxInformationView();
        ti.SFSubscriberTaxInformationView = taxInfos;
        
        if(!integraWSEndpointMediator.integrationEnabled()) return taxInfos;
        
        ti = integraWSEndpointMediator.Endpoint.UpdateSubscriberTaxInformation(ti, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
        return (ti != null && ti.SFSubscriberTaxInformationView != null) ? ti.SFSubscriberTaxInformationView : new List<integraWS.SFSubscriberTaxInformationView>();
    }
    
    public static String getAdditionalFieldFromRemark(integraWS.SFRemarkView remark, String key){
        if(remark.AdditionalFields != null && remark.AdditionalFields.KeyValueOfstringstring != null){
            for(schemasMicrosoftCom200310Serializat.KeyValueOfstringstring_element e : remark.AdditionalFields.KeyValueOfstringstring){
                if(e.Key == key)
                    return e.Value;
            }
        }
        return null;
    }
    
    public static void setAdditionalFieldOnRemark(integraWS.SFRemarkView remark, String key, String val){
        if(remark.AdditionalFields == null){
            remark.AdditionalFields = new schemasMicrosoftCom200310Serializat.ArrayOfKeyValueOfstringstring();
            remark.AdditionalFields.KeyValueOfstringstring = new List<schemasMicrosoftCom200310Serializat.KeyValueOfstringstring_element>();
        }
        
        schemasMicrosoftCom200310Serializat.KeyValueOfstringstring_element e = new schemasMicrosoftCom200310Serializat.KeyValueOfstringstring_element();
        e.Key = key;
        e.Value = val;
        remark.AdditionalFields.KeyValueOfstringstring.add(e);
    }
    
    public static List<integraWS.SFRemarkView> createRemarks(List<integraWS.SFRemarkView> remarks, String mode, String sessionID){
        integraWS.ArrayOfSFRemarkView r = new integraWS.ArrayOfSFRemarkView();
        r.SFRemarkView = remarks;
        
        if(!integraWSEndpointMediator.integrationEnabled()) return remarks;
        
        r = integraWSEndpointMediator.Endpoint.createRemarks(r, mode, sessionID, CustomSettingUtils.SFDCCallbackEndpoint);
        return (r != null && r.SFRemarkView != null) ? r.SFRemarkView : new List<integraWS.SFRemarkView>();
    }
    
    public static List<integraWS.SFRemarkView> getRemarksByParentRecordIDs(List<Integer> parentRecordIDs, String mode, DateTime fromDate, DateTime toDate, Map<String, String> additionalFields) {
        integraWS.ArrayOfSFRemarkView remarks;
        integraWS.ListOfInt parentIDs = new integraWS.ListOfInt();
        parentIDs.ListofIntEntry = parentRecordIDs;
        
        integraWS.DictionaryOfStringAndString aFields = new integraWS.DictionaryOfStringAndString();
        aFields.Entries = new integraWS.ArrayOfDictionaryOfStringAndStringEntry();
        aFields.Entries.DictionaryOfStringAndStringEntry = new List<integraWS.DictionaryOfStringAndStringEntry>();
        for(String k : additionalFields.keyset()){
            integraWS.DictionaryOfStringAndStringEntry entry = new integraWS.DictionaryOfStringAndStringEntry();
            entry.Key = k;
            entry.Value = additionalFields.get(k);
            aFields.Entries.DictionaryOfStringAndStringEntry.Add(entry);
        }
        
        if(!integraWSEndpointMediator.integrationEnabled()) return new List<integraWS.SFRemarkView>();
        
        remarks = integraWSEndpointMediator.Endpoint.getRemarksByParentRecordIDs(parentIDs, mode, fromDate, toDate, aFields, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
        return remarks.SFRemarkView;
    }
    
    public static List<integraWS.SFSubscriberView> UpdateSubscriberHierarchies(Map<Integer, Integer> parentSubscriberIDBySubscriberID) {
        if(!integraWSEndpointMediator.integrationEnabled()) return new List<integraWS.SFSubscriberView>();
        
        integraWS.DictionaryOfIntAndNullableInt arr = new integraWS.DictionaryOfIntAndNullableInt();
        arr.Entries = new integraWS.ArrayOfDictionaryOfIntAndNullableIntEntry();
        arr.Entries.DictionaryOfIntAndNullableIntEntry = new List<integraWS.DictionaryOfIntAndNullableIntEntry>();
        for(Integer k : parentSubscriberIDBySubscriberID.keyset()){
            integraWS.DictionaryOfIntAndNullableIntEntry entry = new integraWS.DictionaryOfIntAndNullableIntEntry();
            entry.Key = k;
            entry.Value = parentSubscriberIDBySubscriberID.get(k);
            arr.Entries.DictionaryOfIntAndNullableIntEntry.Add(entry);
        }
        integraWS.ArrayOfSFSubscriberView subs = integraWSEndpointMediator.Endpoint.UpdateSubscriberHierarchies(arr, UserInfo.getSessionID(), CustomSettingUtils.SFDCCallbackEndpoint);
        return (subs != null && subs.SFSubscriberView != null) ? subs.SFSubscriberView : new List<integraWS.SFSubscriberView>();
    }
    
    public static integraWS.SFMSAGAddressView[] searchMSAGAddress(String city, String state, String street){
        if(!integraWSEndpointMediator.integrationEnabled()) return new List<integraWS.SFMSAGAddressView>();
        
        integraWS.ArrayOfSFMSAGAddressView views = integraWSEndpointMediator.Endpoint.SearchMSAGAddresses(city, state, street, UserInfo.getSessionID(), CustomSettingUtils.SFDCCallbackEndpoint);
        return views != null ? views.SFMSAGAddressView : new List<integraWS.SFMSAGAddressView>();
    }
    
    public static List<integraWS.SFSubOrderGroupStatusView> UpdateOrderProductGroups(List<Integer> subOrderGroupIds, String calloutType, Datetime billingDate, String salesForceSessionID, String apiUrl) {
        integraWS.ListOfInt opgIds = new integraWS.ListOfInt();
        opgIds.ListofIntEntry = subOrderGroupIds;
        
        if(!integraWSEndpointMediator.integrationEnabled()) return new List<integraWS.SFSubOrderGroupStatusView>();
        
        integraWS.ArrayOfSFSubOrderGroupStatusView sr = integraWSEndpointMediator.Endpoint.ProcessWorkFlowICCCallout(opgIds, calloutType, billingDate, salesForceSessionID, apiUrl);
        return (sr != null && sr.SFSubOrderGroupStatusView != null) ? sr.SFSubOrderGroupStatusView : new List<integraWS.SFSubOrderGroupStatusView>();
    }
}