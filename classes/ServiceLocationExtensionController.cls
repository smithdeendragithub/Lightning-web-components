public with sharing class ServiceLocationExtensionController extends CustomerDetailBaseController implements TestUtils.ITestableClass {

    public Service_Location__c sLoc {get; private set;}
    
    public String specificHierarchyMoveRestriction {get; set;}
    public Boolean canCloneDetailFromParent {get; set;}
    public Boolean canEdit {get; set;}
    public Boolean canMove {get; set;}
    public Boolean canReactivate {get; private set;}
    public Boolean haveMoveAccess {get; set;}
    public Integer branchDepth {get; set;}
	public Boolean isGenerateDetailsVisible {get; private set;}

    //Bypass for controlled merges for hierarchy move
    private without sharing class AccountMerger {
        public AccountMerger(){}    //Sub-classes cannot be static
        
        public void MergeAccounts(Account target, Account source){
            AccountTriggers.PerformingControlledSubscriberMerge = true;
            merge target source;
            AccountTriggers.PerformingControlledSubscriberMerge = false;
        }
    }
    
    public ServiceLocationExtensionController(Apexpages.StandardController sc) {        
        sLoc = (Service_Location__c)sc.getRecord();
        if(sLoc != null){
            sLoc = ((List<Service_Location__c>)ApexUtils.retrieveObjectsFromFieldSets(Service_Location__c.getsObjectType()
                                                                                    ,new List<Set<String>>
                                                                                        {
                                                                                            SchemaUtils.RetrieveFullObjectFieldSet(Service_Location__c.getsObjectType())
                                                                                            ,new Set<String>
                                                                                            {
                                                                                                'Account__r.Customer_Detail__c'
                                                                                                ,'Account__r.Owners_Sales_Channel__c'
                                                                                                ,'Parent_Service_Location__r.Customer_Detail__c'
                                                                                                ,'Location__r.Building__r.Country__c'
                                                                                            }
                                                                                        }
                                                                                    ,'Id=\'' + sLoc.Id + '\''
                                                                                    ,null))[0];
            baseObject = sLoc;
            canEdit = SecurityUtils.currentUserHasRecordAccess(sLoc.Id, true);
 
            canCloneDetailFromParent = sLoc.Customer_Detail__c == null
                                    && sLoc.Account__c != null 
                                    && (sLoc.Account__r.Owners_Sales_Channel__c != null && sLoc.Account__r.Owners_Sales_Channel__c.indexOf('Wholesale') > -1)
                                    && ((sLoc.Parent_Service_Location__c != null && sLoc.Parent_Service_Location__r.Customer_Detail__c != null)
                                        || (sLoc.Parent_Service_Location__c == null && sLoc.Account__r.Customer_Detail__c != null));
            
            if(sLoc.Customer_Detail__c != null) loadDetails();
            
            Profile p = [select Name from Profile where Id =: UserInfo.getProfileId()];
            haveMoveAccess = p.Name == 'System Administrator' || CustomSettingUtils.currentUserHasCustomPermission('Can_Modify_Hierarchy__c');
            Boolean isInactive = !string.IsEmpty(sLoc.ICC_Subscriber_ID__c) && detail.Integration_Status__c != null && IntegrationUtils.inactiveSubscriberStatuses.contains(detail.Integration_Status__c);
            if(isInactive) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This service location is inactive.'));
            
            canMove = !isInactive && !string.IsEmpty(sLoc.ICC_Subscriber_ID__c) && sLoc.Level__c != 'ERROR';
            canReactivate = isInactive && CustomSettingUtils.currentUserHasCustomPermission('Can_Reactivate_Accounts__c');
            branchDepth = 1;
            if(canMove){
                Integer tempDepth = 1;
                for(Service_Location__c subLoc : getSubServiceLocations()){
                    Integer d = subLoc.Parent_Service_Location__c == sLoc.Id ? 1 : 2;
                    branchDepth = (branchDepth < (tempDepth + d)) ? (tempDepth + d) : branchDepth;
                }
                if(!sLoc.Billable__c && sLoc.Level__c != '1')               //Billable and roots
                    canMove = sLoc.Level__c == '2' && branchDepth > 1;      //NBP under a grand-parent
                
                if(canMove){
                    Set<String> closedStages = new Set<String>{ OpportunityUtils.STAGE_CONTRACT_SIGNED, OpportunityUtils.STAGE_CLOSED_LOST, OpportunityUtils.STAGE_CLOSED_WON, OpportunityUtils.STAGE_4, OpportunityUtils.STAGE_5 };
                    if(branchDepth > 3)
                        specificHierarchyMoveRestriction = 'You cannot move grandparent service locations.';
                    else if(sLoc.Level__c != '1'
                        && ([select Id from Opportunity_Location__c where Service_Location__c =: sLoc.Id and ((Opportunity__c != null and Opportunity__r.StageName not in: closedStages) or (Order__r.Opportunity__c != null and Order__r.Opportunity__r.StageName not in: closedStages))].size() > 0
                            || [select Id from Opportunity_Product__c where Primary_Service_Location__c =: sLoc.Id and Opportunity__r.StageName not in: closedStages].size() > 0)){
                        specificHierarchyMoveRestriction = 'You cannot move a non-root service location with an open opportunity associated with it.';
                    }
                    
                    canMove = specificHierarchyMoveRestriction == null;
                }
            }
            
            isGenerateDetailsVisible = userProfileName.indexOf('Partner') == -1;
            
            if(sLoc.Account__c != null)
                TreeViewsByDivID = new Map<String, TreeViewImplementation>{'hierarchy'=>new CustomerHierarchyController.TreeViewImplementation(sLoc.Account__c)};
        }
    }
    
    public PageReference reactivateLocation(){
        List<String> errors = IntegrationUtils.reactivateServiceLocs(new Set<Id>{sLoc.Id});
        for(String error : errors)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
        
        return errors.size() == 0 ? refresh() : null;
    }
    
    private List<Service_Location__c> getSubServiceLocations(){
        return [select Customer_Detail__c, Parent_Service_Location__c, Parent_Service_Location__r.Parent_Service_Location__c from Service_Location__c where Account__c =: sLoc.Account__c and (Parent_Service_Location__c =: sLoc.Id or Parent_Service_Location__r.Parent_Service_Location__c =: sLoc.Id)];
    }
    
    public PageReference move(){
        string newParentSubID = Apexpages.currentPage().getParameters().get('parentSubscriberID');

        Boolean isDetach = string.IsEmpty(newParentSubID);
        Boolean isCurrentRoot = sLoc.Level__c == '1';
        Boolean doUpdate = string.IsEmpty(newParentSubID);
        List<Account> accounts = null;
        List<Service_Location__c> sLocs = null;
        Account newAccount = null;
        Account currentAccount = ((List<Account>)ApexUtils.retrieveFullObjects(Account.getsObjectType(), 'Id=\'' + sLoc.Account__c + '\''))[0];
        
        Boolean oldAndNewAccountMatch = false;
        string error = null;

        if(!isDetach){
            accounts = [select Id, Name, Billable__c from Account where ICC_Account_Number__c =: newParentSubID and Billable__c = false limit 1];
            sLocs = [select Id
                            ,Name
                            ,Billable__c
                            ,Account__c
                            ,Account__r.Billable__c
                            ,Account__r.ICC_Account_Number__c
                            ,Account__r.Name
                            ,Level__c
                        from Service_Location__c where ICC_Subscriber_ID__c =: newParentSubID and Billable__c = false limit 1];

            oldAndNewAccountMatch = accounts.size() > 0 && accounts[0].Id == currentAccount.Id;
            
            if(sLocs.size() > 0){
                Service_Location__c s = sLocs[0];
                Account a = s.Account__r;
                Integer sLevel = s.Level__c != 'ERROR' ? Integer.valueOf(s.Level__c) : 4;
                if(sLevel + branchDepth > 3)
                    error = string.format('You cannot append a child to {0} [{1}] as it would exceed the maximum hierarchy depth of 3', new List<String>{s.Name, newParentSubID});
                else if(sLevel == 2 && a.Billable__c)
                    error = string.format('You cannot append a grand-child to the billable account {0} [{1}]', new List<String>{a.Name, a.ICC_Account_Number__c});
            }
            else if(accounts.size() == 0)
                error = string.format('No non-billable accounts or service locations found with subscriber ID {0}', new List<String>{newParentSubID});
            else if(oldAndNewAccountMatch && sLoc.Parent_Service_Location__c == null)
                error = string.format('This location is already a child of the customer with subscriber ID {0}', new List<String>{newParentSubID});
            
            if (error == null)
                error = checkCountryForMixing(sLoc.ICC_Subscriber_ID__c, newParentSubID);
/*  code crippler for testing purposes. remove at some future time.
            if (error == null)
                error = 'if you made it this far, you are good';                  
*/            
            doUpdate = accounts.size() > 0 || sLocs.size() > 0;
        }
        else{
            if(sLoc.Location__c == null)
                error = 'Service locations with no location assigned cannot be made a new root customer';
            else{
                newAccount = (Account)ApexUtils.deepCopyFields(Account.getsObjectType(), (sObject)currentAccount, (sObject)new Account(), new Set<String>{'RecordTypeID','IsPartner','OnyxCompanyID__c'});
                newAccount.Name = sLoc.Name;
                newAccount.Agency__c = sLoc.Agency__c;
                newAccount.Billable__c = sLoc.Billable__c;
                newAccount.Customer_Detail__c = sLoc.Customer_Detail__c;
                newAccount.Phone = sLoc.Phone__c;
                newAccount.OwnerId = sLoc.Owner__c;
                
                Location__c loc = [select Id
                                        ,Room_Suite__c
                                        ,Building__r.Address__c
                                        ,Building__r.City__c
                                        ,Building__r.Postal_Code__c
                                        ,Building__r.State__c
                                        ,Building__r.Country__c
                                        from Location__c where Id =: sLoc.Location__c];
                
                newAccount.ShippingCity = loc.Building__r.City__c;
                newAccount.ShippingStateCode = loc.Building__r.State__c;
                newAccount.ShippingCountryCode = loc.Building__r.Country__c;
                newAccount.ShippingState = loc.Building__r.State__c;
                newAccount.ShippingCountry = loc.Building__r.Country__c;
                
                newAccount.ShippingPostalCode = loc.Building__r.Postal_Code__c;
                newAccount.ShippingStreet = string.format('{0} {1}', new List<string>{loc.Building__r.Address__c, loc.Room_Suite__c != null ? loc.Room_Suite__c : ''}).trim();
            }
        }
        
        if(error != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
            doUpdate = false;
        }

        if(doUpdate){
            List<Service_Location__c> subLocations = getSubServiceLocations();
            Map<Id, Contact> contactsToClone = new Map<Id, Contact>();
            Map<Id, List<Customer_Contact__c>> customerContacts = new Map<Id, List<Customer_Contact__c>>();
            
            Set<Id> detailIDs = new Set<Id>{sLoc.Customer_Detail__c};
            for(Service_Location__c subLocation : subLocations){
                if(subLocation.Customer_Detail__c != null)
                    detailIDs.add(subLocation.Customer_Detail__c);
            }
            
            if(isDetach){
                for(Customer_Contact__c cc : [select Id, Contact__c, Contact__r.Name from Customer_Contact__c where Customer_Detail__c in : detailIDs]){
                    List<Customer_Contact__c> l = customerContacts.get(cc.Contact__c) != null ? customerContacts.get(cc.Contact__c) : new List<Customer_Contact__c>();
                    l.add(cc);
                    customerContacts.put(cc.Contact__c, l);
                    contactsToClone.put(cc.Contact__c, null);
                }
                
                if(customerContacts.size() > 0){
                    sObjectType contactType = Contact.getsObjectType();
                    for(Contact c : (List<Contact>)ApexUtils.retrieveFullObjects(contactType, 'Id in (\'' + string.join(new List<Id>(contactsToClone.keyset()), '\',\'') + '\')'))
                        contactsToClone.put(c.Id, (Contact)ApexUtils.deepCopyFields(contactType, (sObject)c, (sObject)new Contact(), null));
                }
            }
            
            Map<String, integraWS.SFSubscriberView> resultsBySubscriberID = new Map<String, integraWS.SFSubscriberView>();
            
            Map<Integer, Integer> arg = new Map<Integer, Integer>{integer.valueOf(sLoc.ICC_Subscriber_ID__c) => !string.IsEmpty(newParentSubID) ? integer.valueOf(newParentSubID) : null};
            List<integraWS.SFSubscriberView> results = !Test.isRunningTest() ? ICCWrapper.UpdateSubscriberHierarchies(arg) : Test_ServiceLocationExtensionController.simulateHierarchyUpdate(arg);
            for(integraWS.SFSubscriberView result : results)
                resultsBySubscriberID.put(string.valueOf(result.SubscriberId), result);
            
            List<Account> updatedAccounts = new List<Account>();
            for(Account resultAccount : [select Id
                                                ,ICC_Account_Number__c
                                                ,ICC_Account_Type__c
                                        from Account where ICC_Account_Number__c in: resultsBySubscriberID.keyset()]){
                integraWS.SFSubscriberView result = resultsBySubscriberID.get(resultAccount.ICC_Account_Number__c);
                if(resultAccount.ICC_Account_Type__c != result.SubscriberType && (isDetach || resultAccount.ICC_Account_Number__c != sLoc.ICC_Subscriber_ID__c)){
                    resultAccount.ICC_Account_Type__c = result.SubscriberType;
                    updatedAccounts.add(resultAccount);
                }
            }
            
            List<Service_Location__c> branchLocations = new List<Service_Location__c>{sLoc};
            branchLocations.addAll(subLocations);
            Id accountId = null;
            Id camID = detail.Customer_Account_Manager__c;
            if(!isDetach){
                if(sLocs.size() > 0){
                    accountId = sLocs[0].Account__c;
                    sLoc.Parent_Service_Location__c = sLocs[0].Id;
                }
                else if(accounts.size() > 0){
                    accountId = accounts[0].Id;
                    sLoc.Parent_Service_Location__c = null;
                }
                
                if(isCurrentRoot && currentAccount.Id != accountId){
                    for(AccountTeamMember atm : [select Id, UserId from AccountTeamMember where AccountId =: accountId and TeamMemberRole in: ICCWrapper.CAMTeamMemberRoles])
                        camID = atm.UserId;
                    new AccountMerger().MergeAccounts([select Id from Account where Id =: accountId], currentAccount);
                }
            }
            else{
                newAccount.ICC_Account_Type__c = resultsBySubscriberID.get(sLoc.ICC_Subscriber_ID__c).SubscriberType;
                insert newAccount;
                accountId = newAccount.Id;
                sLoc.Parent_Service_Location__c = null;
                
                Set<Id> atmUsers = new Set<Id>();
                List<AccountTeamMember> atms = new List<AccountTeamMember>();
                for(AccountTeamMember atm : [select Id, TeamMemberRole, UserId from AccountTeamMember where AccountId =: currentAccount.Id]){
                    if(ICCWrapper.CAMTeamMemberRoles.contains(atm.TeamMemberRole)) camID = atm.UserId;
                    atmUsers.add(atm.UserId);
                    atms.add(new AccountTeamMember(AccountId = accountId
                                                ,TeamMemberRole = atm.TeamMemberRole
                                                ,UserId = atm.UserId));
                }
                if(atms.size() > 0) insert atms;
                
                List<AccountShare> aShares = new List<AccountShare>();
                for(AccountShare aShare : [select Id, AccountAccessLevel, CaseAccessLevel, OpportunityAccessLevel, UserOrGroupId from AccountShare where AccountId =: currentAccount.Id and UserOrGroupId in: atmUsers and AccountAccessLevel != 'Owner']){
                    aShares.add(new AccountShare(AccountId = accountId
                                                ,AccountAccessLevel = aShare.AccountAccessLevel
                                                ,CaseAccessLevel = aShare.CaseAccessLevel
                                                ,OpportunityAccessLevel = aShare.OpportunityAccessLevel
                                                ,UserOrGroupId = aShare.UserOrGroupId));
                }
                
                if(aShares.size() > 0) insert aShares;
            }
            
            if(detail.Customer_Account_Manager__c != camID){
                List<Customer_Detail__c> cdList = [select Id from Customer_Detail__c where Id in: detailIDs and Customer_Account_Manager__c !=: camID and Id !=: detail.Id];
                cdList.add(detail);
                
                for(Customer_Detail__c cd : cdList)
                    detail.Customer_Account_Manager__c = camID;
                
                update cdList;
            }
            
            for(Service_Location__c loc : branchLocations)
                loc.Account__c = accountId;
            
            Id newAccountId = sLoc.Account__c;
            if(contactsToClone.size() > 0){
                for(Contact c : contactsToClone.values())
                    c.AccountId = newAccountId;
                
                insert contactsToClone.values();
                
                List<Customer_Contact__c> customerContactsToUpdate = new List<Customer_Contact__c>();
                for(Id id : contactsToClone.keyset()){
                    for(Customer_Contact__c cc : customerContacts.get(id)){
                        cc.Contact__c = contactsToClone.get(id).Id;
                        customerContactsToUpdate.add(cc);
                    }
                }
                
                update customerContactsToUpdate;
            }
            
            if(updatedAccounts.size() > 0)
                update updatedAccounts;
            
            update branchLocations;
        }
        
        return doUpdate ? refresh() : null;
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_ServiceLocationExtensionController(); }
    
    private string checkCountryForMixing(string sourceSubId, string targetSubId) {
        string error = null;
        Account a = [select Id from Account where ICC_Account_Number__c =: targetSubId limit 1];
        List<Service_Location__c> sLocs = [select Id, Location__r.Building__r.Country__c from Service_Location__c where ICC_Subscriber_ID__c =: targetSubId];
        if (sLocs.size() > 0) {
            for (integer i = 0; i < sLocs.size(); i++) {
                if (sLocs[i].Location__r.Building__r.Country__c != sLoc.Location__r.Building__r.Country__c)
                    error = 'The target parent\'s country does not match the country on this service location';    
            }
        } else {
            sLocs = [Select Id, Location__r.Building__r.Country__c from Service_Location__c where Account__r.id =: a.id];
            for (integer i = 0; i < sLocs.size(); i++) {
                if (sLocs[i].Location__r.Building__r.Country__c != sLoc.Location__r.Building__r.Country__c)
                    error = 'The target parent\'s country does not match the country on this service location';    
            }                    
        }    
        return error;
    }
    
    //Variable to return the current logged in User Profile Name.  Only the get is necessary
    public String userProfileName {                                     
        get {return [select Profile.Name from User where Id = :Userinfo.getUserId()].Profile.Name;}
    }    
}