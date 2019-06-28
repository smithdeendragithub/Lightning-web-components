/**************************************************************************************************

AccountExtensionController.cls
*
Modifications: Line 104 added a condition to fitler out 'Unqualified' Leads
Developer Name Date Brief description
------------------- ---------- ------------------------------------------------------------
Elaine Gong 12/19/2017   SEAL-605  - Changes to Target Leads
**************************************************************************************************/

public with sharing class AccountExtensionController extends CustomerDetailBaseController implements TestUtils.ITestableClass {
    
    public Account account {get; private set;}
    
    public List<AccountTeamMember> activeTeamMembers {get; private set;}
    public Map<Id, AccountShare> activeAccountTeamShares {get; set;}
    public List<SelectOption> teamMemberRoles {get; set;}
    public Map<Id, Boolean> readOnlyTeamMembers {get; set;}
    
    public AccountTeamMember newTeamMember {get; private set;}
    public AccountShare newTeamMemberShare {get; private set;}
    
    public Boolean hasAddressForMatchingLoc {get; private set;}
    public Boolean canCreateNonBillableParent {get; private set;}
    public Boolean canEdit {get; set;}
    public Integer canReactivate {get; private set;}            //0: cannot reactivate, 1: can reactivate, -1: cannot reactivate because of an errored state
    public Boolean canUpdateCAM {get; private set;}
    public Integer accountTeamPrivLevel {get; private set;}     //0: read, 1: read/create, 2: read/create/modify/share
    
    public String addressToGeocode {get; private set;}
    
    public Boolean isAgency {get; private set;}
    public Boolean isPriorLake {get; private set;}
    public String oppCreatePageURL {get;private set;}
    public Boolean canCreateHierarchy {get; private set;}
    //public Integer integrationOnlyOrderGenerated {get; private set;}  //0 - Not generated, 1 - Already existed, 2 - Generated

    public Boolean isGenerateDetailsVisible {get; private set;}
    public Set<String> camTeamMemberRoles { get { return ICCWrapper.CamTeamMemberRoles; } }
    public Boolean hasWorkstepCreate { get { return Schema.sobjecttype.Workstep__c.isCreateable(); } }
    
    public transient List<String> customErrorMessages {get; private set;}
    public transient List<String> customInfoMessages {get; private set;}
    
    public override void addCustomMessage(Boolean isError, String message){
        List<String> l = isError ? customErrorMessages : customInfoMessages;
        if(l == null)
            l = new List<String>();
        l.add(message);
        if(isError)
            customErrorMessages = l;
        else
            customInfoMessages = l;
    }
    
    public AccountExtensionController(Apexpages.StandardController sc) {
        //integrationOnlyOrderGenerated = 0;
        account = (Account)sc.getRecord();
        if(account != null){
            account = ((List<Account>)ApexUtils.retrieveObjectsFromFieldSets(Account.getsObjectType()
                                                            ,new List<Set<String>>
                                                            {
                                                                SchemaUtils.RetrieveFullObjectFieldSet(Account.getsObjectType())
                                                                ,new Set<String>
                                                                {
                                                                    'Agency__r.Id'
                                                                    ,'Agency__r.AgentId__c'
                                                                    ,'Agency__r.Parent.AgentId__c'
                                                                    ,'RecordType.DeveloperName'
                                                                    ,'Language_Preference__c'
                                                                }
                                                            }
                                                            ,'Id=\'' + account.Id + '\''
                                                            ,null))[0];
            baseObject = account;
            canEdit = SecurityUtils.currentUserHasRecordAccess(account.Id, true);
            Boolean accountEdit = false;
            Boolean accountTransfer = false;
            for(UserRecordAccess ura : [select RecordId, HasEditAccess, HasTransferAccess from UserRecordAccess where UserId =: UserInfo.getUserId() and RecordId =: account.Id]){
                accountEdit = ura.HasEditAccess;
                accountTransfer = ura.HasTransferAccess;
            }
            
            isGenerateDetailsVisible = userProfileName.indexOf('Partner') == -1;
            
            /*Set<Id> psParentIDs = new Set<Id>();
            for(PermissionSetAssignment psa : [select PermissionSetId from PermissionSetAssignment where AssigneeId =: UserInfo.getUserId()])
                psParentIDs.add(psa.PermissionSetId);*/
            
            Boolean userRead = User.sObjectType.getDescribe().isAccessible();
            /*for(ObjectPermissions op : [select sObjectType, PermissionsRead from ObjectPermissions where ParentId in: psParentIDs and sObjectType in ('User')])
                userRead |= op.PermissionsRead;*/
            
            accountTeamPrivLevel = (userRead && accountEdit) ? (accountTransfer ? 2 : 1) : 0;
            
            List<RecordType> rt = [select DeveloperName from RecordType where Id = :account.RecordTypeId];
            isAgency = rt != null && rt.size() > 0 && rt[0].DeveloperName == 'Agency';
            isPriorLake = rt != null && rt.size() > 0 && rt[0].DeveloperName == 'ILEC_Prior_Lake';
            
            if(account.Customer_Detail__c != null) loadDetails();
            
            Boolean hasDetailServiceAddress = detail != null && detail.Service_Address__c != null;
            Boolean isInactive = !string.IsEmpty(account.ICC_Account_Number__c) && account.Type == 'Former Customer' && !isAgency && detail.Integration_Status__c != null && IntegrationUtils.inactiveSubscriberStatuses.contains(detail.Integration_Status__c);
            if(isInactive) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This account is inactive.'));
            
            // Add a condition to limit the appearance of the warning tag when the existing Leads are marked ‘Unqualified’
            List<Lead> relatedLeads = [select Id from Lead where Related_Account__c =: account.Id and Status != 'Converted'and Status != 'Unqualified'];
           //Chanchev
            //if(relatedLeads.size() > 0) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This account has a related lead that must be converted before being worked on. Leads can be accessed via the related lists.'));
            
            List<Service_Location__c> sLocs = [select Id, ICC_Subscriber_ID__c, Level__c, Customer_Detail__r.Integration_Status__c from Service_Location__c where Account__c =: account.Id];
            canCreateNonBillableParent = (!isAgency && CustomSettingUtils.currentUserHasCustomPermission('Can_Integrate_Subscribers__c') && ICCWrapper.accountCanHaveNonBillableParentCreated(account, sLocs)) || Test.IsRunningTest();
            canReactivate = (isInactive && CustomSettingUtils.currentUserHasCustomPermission('Can_Reactivate_Accounts__c')) ? 1 : 0;
            canCreateHierarchy = CustomSettingUtils.currentUserHasCustomPermission('Can_Create_Hierarchy__c') && !isAgency;
            Boolean hasMatchingLoc = false;
            for(Service_Location__c sLoc : sLocs){
                hasMatchingLoc |= (sLoc.Level__c == '1');
                if(canReactivate == 1) canReactivate = (sLoc.Customer_Detail__r == null || sLoc.Customer_Detail__r.Integration_Status__c == null || IntegrationUtils.inactiveSubscriberStatuses.contains(sLoc.Customer_Detail__r.Integration_Status__c)) ? 1 : -1;
            }
            
            hasAddressForMatchingLoc = hasDetailServiceAddress || hasMatchingLoc || !string.IsEmpty(account.ShippingStreet);
            
            if(!hasDetailServiceAddress && !hasMatchingLoc && canCreateNonBillableParent)   //If we need a service loc, do we need to parse the account address?
                addressToGeocode = account.ShippingStreet
                                    + (!string.IsEmpty(account.ShippingCity) ? ', ' + account.ShippingCity : '')
                                    + (!string.IsEmpty(account.ShippingState) ? ', ' + account.ShippingState : '')
                                    + (!string.IsEmpty(account.ShippingPostalCode) ? ', ' + account.ShippingPostalCode : '');
            
            canUpdateCAM = Customer_Detail__c.Customer_Account_Manager__c.getDescribe().isUpdateable() || String.isEmpty(account.ICC_Account_Number__c);
            getAccountTeam();
            
            Set<String> rSet = new Set<String>();
            for(Schema.PicklistEntry ple : AccountTeamMember.TeamMemberRole.getDescribe().getPicklistValues())
                rSet.add(ple.getLabel());
            
            if(!canUpdateCAM) rSet.removeAll(camTeamMemberRoles);
            
            teamMemberRoles = new List<SelectOption>();
            for(String r : rSet)
                teamMemberRoles.add(new SelectOption(r, r));
            
            teamMemberRoles.sort();
            teamMemberRoles.add(0, new SelectOption('', '--None--'));
            
            TreeViewsByDivID = new Map<String, TreeViewImplementation>{'hierarchy'=>new CustomerHierarchyController.TreeViewImplementation(account.Id)};
        }
    }
    
    public PageReference reactivateAccount(){
        List<String> errors = IntegrationUtils.reactivateAccounts(new Set<Id>{account.Id});
        for(String error : errors)
            addCustomMessage(true, error);
        
        return errors.size() == 0 ? refresh() : null;
    }
    
    private Service_Location__c matchingServiceLoc;
    
    public PageReference createNonBillableParent(){
        List<Customer_Setting__c> billCycles = new List<Customer_Setting__c>{};
            
        Map<Id, RecordType> rts = new Map<Id, RecordType>([select Id from RecordType where sObjectType = 'Customer_Setting__c' and DeveloperName = 'Bill_Cycle_Schedule']);
        for(Customer_Setting__c setting : [select Id
                                           ,External_ID__c
                                           ,RecordType.DeveloperName
                                           ,Value__c
                                           ,Market_Area__r.ICCMarketAreaID__c
                                           ,Market_Type__r.External_ID__c
                                           ,Description__c
                                           from Customer_Setting__c where RecordTypeId in : rts.keyset()]){
            billCycles.add(setting);
        }        
        
        Boolean doUpdate = Test.IsRunningTest();
        if(canCreateNonBillableParent){
            if(matchingServiceLoc == null){
                List<Service_Location__c> sloc = [select Id
                                                    from Service_Location__c
                                                    where Account__c =: account.Id
                                                    and ICC_Subscriber_ID__c =: account.ICC_Account_Number__c];
                if(sloc.size() == 0){
                    if(detail != null && detail.Service_Address__c != null)
                        matchingServiceLoc = getServiceLocFromLocation(detail.Service_Address__c);
                    else{
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No matching service location with a valid market area found for this account.'));
                        return ApexPages.currentPage();
                    }
                }
                else
                    matchingServiceLoc = sloc[0];
            }

            Customer_Detail__c cd = ((List<Customer_Detail__c>)
                                            (ApexUtils.retrieveObjectsFromFieldSets(Customer_Detail__c.getsObjectType()
                                                ,new List<Set<String>>{
                                                    AddressUtils.CustomerDetailAddressFieldSet
                                                    ,IntegrationUtils.CustomerDetailIntegrationFieldSet
                                                    }
                                                ,'Id = \'' + account.Customer_Detail__c + '\''
                                                ,null)))[0];
 
            if (cd.Bill_Cycle__c == null) {
                cd.Bill_Cycle_External_ID__c = 70;  
            } else {
                for (Customer_Setting__c billCycle: billCycles) {
                    if (billCycle.id == cd.Bill_Cycle__c) {
                        cd.Bill_Cycle_External_ID__c =  integer.ValueOf(billCycle.External_ID__c); 
                        break;
                    }
                }
            }
            
            integraWS.SFSubscriberView newParentSub = ICCWrapper.setSubscriberValuesFromAccount(account, cd);
            newParentSub.SubscriberId = newParentSub.BillingID = 0;
            newParentSub.Billable = false;
            newParentSub.DateOfSale = Datetime.now();
            
            integraWS.SFSubscriberView currentSub = new integraWS.SFSubscriberView();
            currentSub.SalesforceId = null;
            currentSub.SubscriberId = integer.valueOf(cd.ICC_Subscriber_ID__c);
            
            newParentSub.Children.SFSubscriberView.add(currentSub);
            
            List<integraWS.SFSubscriberView> subscriberResults = ICCWrapper.updateSubscribers(new List<integraWS.SFSubscriberView>{newParentSub}, UserInfo.getSessionID());
              
            List<String> errors = new List<String>();
            integraWS.SFSubscriberView accountResult;
            
            for(integraWS.SFSubscriberView view : ICCWrapper.getFlattenedSFSubscriberViewList(subscriberResults)){
                if(!string.IsEmpty(view.ResultMessage))
                    errors.add(view.SalesforceId + ': ' + view.ResultMessage);
                  
                if((view.SalesforceId == account.Id && view.SubscriberId != 0 && view.SubscriberId != integer.valueOf(cd.ICC_Subscriber_ID__c)) || Test.IsRunningTest()){
                    accountResult = view;
                    doUpdate = string.IsEmpty(view.ResultMessage);
                    break;
                }
            }
            if(doUpdate){
                if(!CustomerDetailUtils.cloneCustomerDetails(new Set<Id>{account.Id}, null))
                    errors.add('Integration completed with errors. Please verify hierarchy structure in the external system.');
                
                Account updatedAccount = [select Id, Customer_Detail__c, Language_Preference__c from Account where Id =: account.Id];
                updatedAccount.ICC_Account_Type__c = accountResult.SubscriberType;
                update updatedAccount;
                
                //Remove the billing address values and set the fields coming back
                List<Customer_Detail__c> d = [select Id from Customer_Detail__c where Id =: updatedAccount.Customer_Detail__c];
                if(d.size() > 0){
                    d[0].ICC_Subscriber_ID__c = string.valueOf(accountResult.SubscriberId);
                    d[0].Billable__c = accountResult.Billable;
                    d[0].Care_Access_Code__c = accountResult.CareAccessCode;
                    d[0].Language_Preference__c = updatedAccount.Language_Preference__c;
                    Map<String, Schema.SObjectField> fieldMap = Customer_Detail__c.getsObjectType().getDescribe().fields.getMap();
                    for(String key : AddressUtils.CustomerDetailFieldSetAddressTypes.keyset()){
                        for(String fName : fieldMap.keyset()){
                            if(fName.startsWith(key.toLowerCase()))
                                d[0].put(fName, '');
                        }
                    }
                    update d;
                }
                
                if(matchingServiceLoc.Id == null)
                    createNewLocation();
                
                List<Service_Location__c> childLocs = [select Id, Parent_Service_Location__c from Service_Location__c where Id !=: matchingServiceLoc.Id and Account__c =: account.Id and Parent_Service_Location__c = null];
                for(Service_Location__c child : childLocs)
                    child.Parent_Service_Location__c = matchingServiceLoc.Id;
                
                update childLocs;

                //copy contact info to ICC
                List<Id> contactIds = new List<Id>{};
                List<Customer_Contact__c> contacts = [SELECT Id FROM Customer_Contact__c where Contact_Type__c != null and Contact__c != null and Customer_Detail__c =: updatedAccount.Customer_Detail__c];            
                    
                for (Customer_Contact__c cc: contacts) 
                    contactIds.add(cc.id);
    
                if(contactIds.size() > 0){
                    try {
                        CustomerContactTriggers.integrateContacts(contactIds, string.valueOf(accountResult.SubscriberId),UserInfo.getSessionId());
                    }
                    catch(Exception e){ 
                        system.debug('AccountExtensionController exception: ' + e.getMessage());
                        errors.add(e.getMessage()); 
                    }
                }
                //end of copy contact info to ICC
            }            
            for(String error : errors)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
        }
        
        return doUpdate ? refresh() : null;
    }
    
    private Service_Location__c getServiceLocFromLocation(Id locationID){
        return new Service_Location__c(
                                    Name = account.Name
                                    ,Account__c = account.Id
                                    ,Phone__c = account.Phone
                                    ,Owner__c = account.OwnerId
                                    ,Agency__c = account.Agency__c
                                    ,Billable__c = account.Billable__c
                                    ,Customer_Detail__c = account.Customer_Detail__c
                                    ,Location__c = locationID
                                );
    }
    
    private Building__c newRootBuilding;
    private Location__c newRootLocation;
    public void createNewLocation(){
        if(newRootBuilding != null){
            upsert newRootBuilding;
            
            if(newRootLocation != null){
                newRootLocation.Building__c = newRootBuilding.Id;
                upsert newRootLocation;
                
                matchingServiceLoc.Location__c = newRootLocation.Id;
            }
        }
        
        insert matchingServiceLoc;
    }
    
    public String redirectUrl {get; private set;}
    public PageReference createNonBillableParentAndLocation(){
        if(createMatchingServiceLocFromParsedAddress()){
            PageReference retval = createNonBillableParent();
            return retval != null ? new PageReference('/' + account.Id) : retval;
        }
        
        return null;
    }
    
    public Boolean createMatchingServiceLocFromParsedAddress(){
        integraWS.SFLocationView locView = AddressParser.addressParsed();
        
        newRootBuilding = null;
        newRootLocation = null;
        if(locView != null && locView.Success && !string.IsEmpty(locView.BuildingHash)){
            newRootBuilding = AddressUtils.CreateBuilding(locView, false);
            newRootLocation = AddressUtils.CreateLocation(newRootBuilding, locView, false);
            
            matchingServiceLoc = getServiceLocFromLocation(null);
            
            if(newRootBuilding.Serving_LSO__c == null){
                createNewLocation();
                Task t = !Test.IsRunningTest() ? AddressUtils.CreateTaskForNoServingLSO(newRootBuilding, locView.LSOCLLI) : new Task();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'A <a href=\'../' + matchingServiceLoc.Id + '\'>service location</a> has been created to match this account but no serving LSO could be determined for this location. A <a href=\'../' + t.Id + '\'>task</a> has been created to correct the building.'));
                matchingServiceLoc = null;
                return false;
            }
            return true;
        }
        
        String formattedAddress = Apexpages.currentPage().getParameters().get('formattedAddress');
        if(string.IsEmpty(formattedAddress))
            formattedAddress = addressToGeocode;
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No service location can be created to represent the root subscriber from account address: ' + formattedAddress));
        return false;
    }
    
    /*public PageReference CreateHierarchy(){
        try{
            RecordType integrationOnlyRecordType = [select Id from recordtype where DeveloperName = 'Integration_Only_Order' limit 1];
            
            Order__c integrationOnlyOrder = null;
            for(Order__c order : [select Id
                                    ,Account__c
                                    ,Opportunity__c
                                    ,RecordTypeId
                                    from Order__c where Account__c =: account.Id and RecordTypeId =: integrationOnlyRecordType.Id])
                integrationOnlyOrder = order;
            
            if(integrationOnlyOrder == null){
                List<Contact> contacts = [select Id from Contact where accountId = :account.Id and Default_Responsible_Party__c = true limit 1];
                if(contacts.size() == 0){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must add at least 1 contact to this account before continuing.'));
                    integrationOnlyOrderGenerated = 0;
                    return null;
                }
                
                //see if we have any sLocs on the account.
                List<Service_Location__c> existingSLocs = [select Id, Customer_Detail__c from Service_Location__c where Account__c = :account.Id limit 1];
                if(existingSLocs.size() == 0){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must add at least 1 service location to the account before continuing.'));
                    integrationOnlyOrderGenerated = 0;
                    return null;
                }
                
                integrationOnlyOrder = new Order__c(Account__c = account.Id, RecordTypeId = integrationOnlyRecordType.Id);
                insert integrationOnlyOrder;
                
                List<Service_Location__c> sLocs = OrderUtils.getServiceLocationsFromOrder(integrationOnlyOrder);
                List<Set<Id>> updateDetails = new List<Set<Id>>();
                
                Boolean generateSLocDetails = true;
                if(string.IsEmpty(account.ICC_Account_Number__c)){
                    if(sLocs.size() == 1 && string.IsEmpty(sLocs[0].ICC_Subscriber_ID__c)){
                        updateDetails.add(new Set<Id>{account.Id, sLocs[0].Id});
                        generateSLocDetails = false;
                    }
                    else
                        updateDetails.add(new Set<Id>{account.Id});
                }
                if(generateSLocDetails){
                    for(Service_Location__c sLoc : sLocs){
                        if(string.IsEmpty(sLoc.ICC_Subscriber_ID__c))
                            updateDetails.add(new Set<Id>{sLoc.Id});
                    }
                }
                
                if(updateDetails.size() > 0){
                    CustomerDetailUtils.triggerDetailAddressValidation = false;
                    CustomerDetailUtils.updateCustomerDetails(updateDetails, null);
                }
                
                integrationOnlyOrderGenerated = 2;
            }
            else
                integrationOnlyOrderGenerated = 1;
            
            return null;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            integrationOnlyOrderGenerated = 0;
            return null;
        }
    }
    
    public PageReference ValidateAddressesAndRedirectToOppIntegrationPage(){
        try{
            Order__c order = [select Id, Name, RecordTypeId from Order__c where Account__c =: account.Id and RecordType.DeveloperName =: 'Integration_Only_Order' limit 1];
            
            if(integrationOnlyOrderGenerated == 2){
                Account a = [select Id, Customer_Detail__c from Account where Id = :account.Id];    //Get the Customer Detail ID
                
                Set<Id> customerDetailIDs = new Set<Id>();
                customerDetailIDs.add(account.Customer_Detail__c);
                for(Service_Location__c sloc : [select Id, Customer_Detail__c from Service_Location__c where Account__c = :account.Id and Customer_Detail__c != null])
                    customerDetailIDs.add(sloc.Customer_Detail__c);
                
                List<String> Errors = AddressUtils.validateAndClearCustomerDetailAddresses(customerDetailIDs);
                system.debug('CustomerDetail Validation: ' + Errors);
            }
            
            PageReference nextPage = Page.OrderIntegration;
            nextPage.getParameters().put('Id', order.Id);
            nextPage.setRedirect(true);
            return nextPage;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }*/
    
    private void getAccountTeam(){
        Boolean hadCAM = false;
        for(AccountTeamMember atm : activeTeamMembers != null ? activeTeamMembers : new List<AccountTeamMember>())
            hadCAM = hadCAM || camTeamMemberRoles.contains(atm.TeamMemberRole);
        
        activeTeamMembers = [select Id, UserId, TeamMemberRole, LastModifiedDate from AccountTeamMember where AccountId =: account.Id order by LastModifiedDate];
        readOnlyTeamMembers = new Map<Id, Boolean>();
        for(AccountTeamMember atm : activeTeamMembers)
            readOnlyTeamMembers.put(atm.Id, !canUpdateCAM && camTeamMemberRoles.contains(atm.TeamMemberRole));
        
        activeAccountTeamShares = new Map<Id, AccountShare>();
        for(AccountShare aShare : [select UserOrGroupId, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel from AccountShare where AccountId =: account.Id and RowCause = 'Team']){
            activeAccountTeamShares.put(aShare.UserOrGroupId, aShare);
        }
        
        Boolean hasCAM = false;
        for(AccountTeamMember atm : activeTeamMembers){
            hasCAM = hasCAM || camTeamMemberRoles.contains(atm.TeamMemberRole);
            if(activeAccountTeamShares.get(atm.UserId) == null)
                activeAccountTeamShares.put(atm.UserId, new AccountShare(AccountId = account.Id, UserOrGroupId = atm.UserId));
        }
        if(hadCAM && !hasCAM)
            setCAMs(null);
            
        newTeamMember = new AccountTeamMember(AccountId = account.Id);
        newTeamMemberShare = new AccountShare(AccountId = account.Id);
    }
    
    public PageReference addAccountTeamMember(){
        if(newTeamMember.UserId != null){
            if(accountTeamPrivLevel == 2){
                if(newTeamMember.TeamMemberRole != null && newTeamMemberShare.AccountAccessLevel != null && newTeamMemberShare.OpportunityAccessLevel != null){
                    newTeamMemberShare.UserOrGroupId = newTeamMember.UserId;
                    addAccountTeamMembers(new List<AccountTeamMember>{newTeamMember}, new List<AccountShare>{newTeamMemberShare});
                }
                else{
                    addCustomMessage(true, 'You must set the team member role and the account and opportunity access levels');
                }
            }
            else
                addAccountTeamMembers(new List<AccountTeamMember>{newTeamMember}, new List<AccountShare>());
        }
        return null;
    }
    
    /*public PageReference addDefaultAccountTeamMembers(){
        List<AccountTeamMember> teamMembers = new List<AccountTeamMember>();
        List<AccountShare> shares = new List<AccountShare>();
        
        for(UserAccountTeamMember uatm : [select AccountAccessLevel, CaseAccessLevel, OpportunityAccessLevel, TeamMemberRole, UserId from UserAccountTeamMember where OwnerId =: UserInfo.getUserId()]){
            system.debug('UserAccountTeamMember: ' + uatm);
            teamMembers.add(new AccountTeamMember(AccountId = account.Id
                                                ,UserId = uatm.UserId
                                                ,TeamMemberRole = uatm.TeamMemberRole));
            if(accountTeamPrivLevel == 2)
                shares.add(new AccountShare(AccountId = account.Id
                                            ,UserOrGroupId = uatm.UserId
                                            ,AccountAccessLevel = uatm.AccountAccessLevel
                                            ,CaseAccessLevel = uatm.CaseAccessLevel
                                            ,OpportunityAccessLevel = uatm.OpportunityAccessLevel));
        }
        
        if(teamMembers.size() > 0)
            addAccountTeamMembers(teamMembers, shares);
        
        return null;
    }*/
    
    private void addAccountTeamMembers(List<AccountTeamMember> atms, List<AccountShare> shares){
        List<AccountTeamMember> finalAtms = new List<AccountTeamMember>();
        
        Id camId = null;
        Set<Id> userIDs = new Set<Id>();
        for(AccountTeamMember atm : atms){
            Boolean add = true;
            if(camTeamMemberRoles.contains(atm.TeamMemberRole)){
                add = camId == null && canUpdateCAM;
                if(add)
                    camId = atm.UserId;
            }
            
            if(add){
                finalAtms.add(atm);
                userIDs.add(atm.UserId);
            }
            if(!add || atm.UserId == account.OwnerId){
                for(Integer i=shares.size()-1; i>=0; i--){
                    if(shares[i].UserOrGroupId == atm.UserId)
                        shares.remove(i);
                }
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try{
            if(camId != null){
                //Remove all other CAMs
                List<AccountTeamMember> l = [select Id from AccountTeamMember where AccountId =: account.Id and TeamMemberRole in: camTeamMemberRoles];
                if(l.size() > 0) SecurityUtils.BypassProcesser.deleteObjects(l, true);
                setCAMs(camId);
            }
            else{
                //Stop indirect removal of CAM through user role updates
                List<AccountTeamMember> l = [select Id from AccountTeamMember where AccountId =: account.Id and TeamMemberRole in: camTeamMemberRoles and UserId in: userIDs];
                if(!canUpdateCAM && l.size() > 0){ addCustomMessage(true, 'The requested change would update this account\'s CAM assignment. You do not have access to make this change.'); return; }
            }
            
            insert atms;
            //Shares get auto created by inserting team members, so load and update as needed
            if(shares.size() > 0){
                Map<Id, AccountShare> sMap = new Map<Id, AccountShare>();
                for(AccountShare share : shares) sMap.put(share.UserOrGroupId, share);
                for(AccountShare share : [select Id, UserOrGroupId from AccountShare where AccountId =: account.Id and RowCause = 'Team' and UserOrGroupId in: sMap.keyset()]) sMap.get(share.UserOrGroupId).Id = share.Id;
                update sMap.values();
            }
        }
        catch(Exception e){
            addCustomMessage(true, 'Account team membership could not be updated');
            addCustomMessage(true, e.getMessage());
            Database.rollback(sp);
        }
        
        getAccountTeam();
    }
    
    public PageReference removeAccountTeamMembers(){
        String atmIDs = Apexpages.currentPage().getParameters().get('atmIDs');
        List<AccountTeamMember> deleteList = new List<AccountTeamMember>();
        
        Set<String> atmIDSet = atmIDs != null ? new Set<String>(atmIDs.split(',')) : new Set<String>();
        for(AccountTeamMember atm : activeTeamMembers){
            if(atmIDSet.contains(atm.Id) && (!camTeamMemberRoles.contains(atm.TeamMemberRole) || canUpdateCAM))
                deleteList.add(atm);
        }
        
        if(deleteList.size() > 0){
            try{
                delete deleteList;
            }
            catch(Exception e){
                addCustomMessage(true, 'You do not have access to remove one or more of the selected account team members');
            }
            getAccountTeam();
        }
        
        return null;
    }
    
    private void setCAMs(Id userId){
        Set<Id> customerDetailIDs = new Set<Id>();
        for(Service_Location__c sLoc : [select Customer_Detail__c from Service_Location__c where Account__c =: account.Id and Customer_Detail__c != null]){
            customerDetailIDs.add(sLoc.Customer_Detail__c);
        }
        
        List<Customer_Detail__c> details = customerDetailIDs.size() > 0 ? [select Id from Customer_Detail__c where Id in : customerDetailIDs] : new List<Customer_Detail__c>();
        if(detail != null && !customerDetailIDs.contains(detail.Id))
            details.add(detail);
        
        if(details.size() > 0){
            for(Customer_Detail__c cd : details)
                cd.Customer_Account_Manager__c = userId;
            update details;
        }
        
        if(userId != null) AccountTransferController.SendTransferEmail(userId, true, new Set<Id>{account.Id}, null);
    }
    
    public PageReference updateAccountSharing(){
        String atmIDs = Apexpages.currentPage().getParameters().get('atmIDs');
        List<AccountShare> shares = new List<AccountShare>();
        
        Set<String> atmIDSet = atmIDs != null ? new Set<String>(atmIDs.split(',')) : new Set<String>();
        for(AccountTeamMember atm : activeTeamMembers){
            if(atmIDSet.contains(atm.Id)){
                shares.add(activeAccountTeamShares.get(atm.UserId));
            }
        }
        
        if(shares.size() > 0){
            try{
                upsert shares;
            }
            catch(Exception e)
            {
                addCustomMessage(true, 'You do not have access to update one of the selected account team members');
            }
            
            getAccountTeam();
        }
        
        return null;
    }
    
    public PageReference VerifyContactsAndRedirectToOppGen(){
        List<Contact> contacts = [select Id from Contact where accountId = :account.Id];
        if(contacts.size() < 1){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must add at least 1 contact to this account before continuing.'));
            return null;
        }
        PageReference OppCreatePage = new PageReference('/apex/ILECOpportunityGeneration?accountId=' + account.Id);
        OppCreatePage.setRedirect(true);
        oppCreatePageURL = oppCreatePage.getUrl();
        return null;
    }
    
    //Variable to return the current logged in User Profile Name.  Only the get is necessary
    public String userProfileName {                                     
        get {return [select Profile.Name from User where Id = :Userinfo.getUserId()].Profile.Name;}
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_AccountExtensionController(); }
}