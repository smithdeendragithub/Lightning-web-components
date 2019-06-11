public with sharing class CustomerIntegrationController extends TreeViewController implements TestUtils.ITestableClass {
	
	public final Order__c order {get; private set;}
	public final Opportunity opportunity {get; private set;}
	public final Id accountID {get; private set;}
	public final Id customerDetailID {get; private set;}
	
	private final String CreditApprovedPendingCondition = 'Credit Approved pending condition';
	private final String CreditDenied = 'Credit Denied';
	
	private integraWS.SFLocationView locView {get; private set;}
	private Location__c newRootLocation {get; private set;}
	private Building__c newRootBuilding {get; private set;}
	private String newRootBuildingCLLI {get; private set;}
	
	public String addressToGeocode {get; private set;}
	
	public Boolean canIntegrate {get; private set;}
	public Boolean canParseAccountAddresses {get; private set;}
	public Boolean canCloneParentDetails {get; private set;}
	public Boolean mustUpdateBillableFlags {get; private set;}
	public Boolean mustUpdateDetails {get; private set;}
	public Boolean willMatchOpportunityOwner {get; private set;}
	
	public String noIntegrationReason {get; private set;}
	
	public List<SelectOption> needsResponsibleParty {get; set;}
	public List<String> selectedCustomers {get; set;}
	
	private Boolean doBillableCorrection {get; set;}
    private Set<Id> billableFlagsToUpdate {get; set;}
    private Set<Id> detailsToCreate {get; set;}
	
	private Boolean doCreditCheck {get; set;}
    
    public List<SelectOption> availableContacts {get; private set;}
    public Customer_Contact__c responsibleParty {get; set;}
    
	/* Tree view properties */
	public String actDef_OpenCustomerDetail { get { return CustomerHierarchyController.actDef_OpenCustomerDetail; } }
	public String actDef_OpenCustomerDetailInNewTab { get { return CustomerHierarchyController.actDef_OpenCustomerDetailInNewTab; } }
	public String actDef_OpenServiceLocation { get { return CustomerHierarchyController.actDef_OpenServiceLocation; } }
	public String actDef_OpenServiceLocationInNewTab { get { return CustomerHierarchyController.actDef_OpenServiceLocationInNewTab; } }
	
	private Map<String, String> iconMapping { get; set;}
    
    public Boolean RO {get;set;}
	
	public class TreeViewImplementation extends TreeViewController.TreeViewImplementation{
		public CustomerIntegrationController Parent {get; set;}
		
		public TreeViewImplementation(CustomerIntegrationController parent){
			this.Parent = parent;
			loadMoreEnabled = false;
		}
		
		public override List<TreeNode> getNodes(){
			TreeNode rootNode = Parent.init(true);
			return rootNode != null ? new List<TreeNode>{rootNode} : new List<TreeNode>();
		}
	    
	    public override Map<String, String> getActionMap(){
	    	return new Map<String, String>{
				CustomerHierarchyController.actDef_OpenCustomerDetail => CustomerHierarchyController.act_OpenCustomerDetail,
				CustomerHierarchyController.actDef_OpenCustomerDetailInNewTab => CustomerHierarchyController.act_OpenCustomerDetailInNewTab,
				CustomerHierarchyController.actDef_OpenServiceLocation => CustomerHierarchyController.act_OpenServiceLocation,
				CustomerHierarchyController.actDef_OpenServiceLocationInNewTab => CustomerHierarchyController.act_OpenServiceLocationInNewTab
			};
	    }
		
		public override Map<String, String> getIconMap(){
			return Parent.iconMapping;
		}
	}

	public CustomerIntegrationController(){

    	String pID = ApexPages.currentPage().getParameters().get('id');
        RO = ApexPages.currentPage().getParameters().get('ro') == '1'? true: false;
 		
		Boolean customerDetailMode = ApexUtils.isValidId(pID) && SchemaUtils.GetSObjectNameByID(pID) == 'Customer_Detail__c';
		if (RO)
            canIntegrate = !string.isEmpty(pID) && ApexUtils.isValidId(pID);
        else {    
            canIntegrate = !string.isEmpty(pID) && CustomSettingUtils.currentUserHasCustomPermission('Can_Integrate_Subscribers__c') && ApexUtils.isValidId(pID) && (!customerDetailMode || CustomSettingUtils.currentUserHasCustomPermission('Can_Create_Hierarchy__c'));
            canIntegrate &= SecurityUtils.checkObjectAccess(Account.getsObjectType(), false, true);
            canIntegrate &= SecurityUtils.checkObjectAccess(Contact.getsObjectType(), true, true);
            canIntegrate &= SecurityUtils.checkObjectAccess(Service_Location__c.getsObjectType(), false, true);
            canIntegrate &= SecurityUtils.checkObjectAccess(Customer_Detail__c.getsObjectType(), false, true);
            canIntegrate &= SecurityUtils.checkObjectAccess(Customer_Contact__c.getsObjectType(), false, true);
            canIntegrate &= SecurityUtils.checkObjectAccess(Customer_Setting__c.getsObjectType(), false, true);
        }		
		TreeViewsByDivID = new Map<String, TreeViewImplementation>{'integrationHierarchy'=>new TreeViewImplementation(this)};
		if(canIntegrate){
			for(Order__c o : [select Id
										,Name
										,Account__c
										,RecordTypeId
										,RecordType.DeveloperName
										,Credit_Check_Approval__c
										,Credit_Commitment_Met__c
										,Opportunity__r.Id
										,Opportunity__r.Name
										,Opportunity__r.AccountId
										,Opportunity__r.OwnerId
										,Opportunity__r.StageName
										,Opportunity__r.Sales_Channel__c
										,Opportunity__r.RecordType.DeveloperName
                                   		,Opportunity__r.Type
									from Order__c where Id =: pID])
	 			order = o;
			
	 		opportunity = order != null && order.Opportunity__c != null ? order.Opportunity__r : null;
			if(customerDetailMode){
				for(Customer_Detail__c cd : [select Id, Parent_Account__c from Customer_Detail__c where Id =: pID]){
					customerDetailID = cd.Id;
					accountID = cd.Parent_Account__c;
				}
			}
			else accountID = opportunity != null ? opportunity.AccountId : (order != null && order.Account__c != null ? order.Account__c : pID);
			
			Account account = null;
			for(Account a : [select Id, Customer_Detail__c, Default_NAA_Exempt__c, RecordType.DeveloperName, Billable__c from Account where Id =: accountID])
				account = a;
			
			needsResponsibleParty = new List<SelectOption>();
			billableFlagsToUpdate = new Set<Id>();
			detailsToCreate = new Set<Id>();

			if(order == null && account == null) 
                noIntegrationReason = 'The requested order or account could not be found.';
			else{
                if (RO ) {
                    init(false);
                } else {
                    String AccountRecordTypeName = account != null && account.RecordType != null ? account.RecordType.DeveloperName : null;
                    
                    responsibleParty = new Customer_Contact__c(Contact_Type__c = ICCWrapper.ResonsiblePartyContactType);
                    doBillableCorrection = CustomSettingUtils.getSingleProcessConfigurationValue('DisableFunctionality', 'OppIntBillableCorrection', false) != 'true';
                    doCreditCheck = opportunity != null && opportunity.RecordType.DeveloperName == 'New' && opportunity.type == 'New Logo' && CustomSettingUtils.getSingleProcessConfigurationValue('DisableFunctionality', 'OppIntCreditCheck', false) != 'true';
    
                    if(order == null && Account != null && !CustomSettingUtils.currentUserHasCustomPermission('Can_Create_Hierarchy__c')) 
                        noIntegrationReason = 'You do not have access to integrate customers without an order.';
                    else if(!SecurityUtils.currentUserHasRecordAccess(accountID, true)) 
                        noIntegrationReason = 'Edit access is required on the account to integrate customers.';
                    else if(opportunity != null && opportunity.StageName != OpportunityUtils.STAGE_CONTRACT_SIGNED && opportunity.StageName != OpportunityUtils.STAGE_CLOSED_WON && opportunity.StageName != OpportunityUtils.STAGE_4 && opportunity.StageName != OpportunityUtils.STAGE_5) 
                        noIntegrationReason = 'You cannot integrate through orders attached to opportunities that are not currently in the stage \'' + OpportunityUtils.STAGE_CONTRACT_SIGNED + '\' or later.';
                    else if(doCreditCheck
                            && ((opportunity.Sales_Channel__c != null && opportunity.Sales_Channel__c != 'Sales Support')	//Opp SalesChannel is not null or Sales Support
                            && ((order.Credit_Check_Approval__c == CreditDenied || order.Credit_Check_Approval__c == null) || (order.Credit_Check_Approval__c == CreditApprovedPendingCondition && order.Credit_Commitment_Met__c == null))		//Check order state
                            && (AccountRecordTypeName != 'ILEC_Prior_Lake'))){	//Check record types
                        noIntegrationReason = 'Credit check approval process pending, must be completed to integrate account and orders.  Please email collections team at CorpCreditCheck@integratelecom.com if further assistance is needed.';
                    }
                    else init(false);
                } 
 			}
			
			mustUpdateBillableFlags = billableFlagsToUpdate.size() > 0;
			mustUpdateDetails = detailsToCreate.size() > 0;
			canCloneParentDetails = mustUpdateDetails && account != null && account.Customer_Detail__c != null;
			canParseAccountAddresses = (canParseAccountAddresses == true) && !mustUpdateBillableFlags && !mustUpdateDetails;
			canIntegrate = canIntegrate && !mustUpdateBillableFlags && !mustUpdateDetails;
			
			if(!string.IsEmpty(noIntegrationReason)){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, noIntegrationReason));
				canIntegrate = false;
			}
            if (RO == false) {
                if(needsResponsibleParty.size() > 0){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'One or more customers that will be integrated is missing a responsible party.'));
                    canIntegrate = false;
                }
                if(canIntegrate && account.Default_NAA_Exempt__c){
                    Map<String, Boolean> naaExemptions = new Map<String, Boolean>{ '38'=>false, '96'=>false, '103'=>false, '104'=>false };
                    for(Customer_Setting__c tax : [select Id, Reference_ID__c from Customer_Setting__c where Customer_Detail__c =: account.Customer_Detail__c and RecordType.DeveloperName = 'Tax_Information' and End_Date__c = null and Reference_ID__c in: naaExemptions.keyset()]) naaExemptions.put(tax.Reference_ID__c, true);
                    
                    for(String taxID : naaExemptions.keyset()){
                        if(!naaExemptions.get(taxID)){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'NAA tax exemptions have not been set. Please contact the Billing Department.'));
                            canIntegrate = false;
                        }
                    }
                }
                
                if(canIntegrate){
                    if(willMatchOpportunityOwner) 
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Account and service location ownership associated to this order will be assigned to the opportunity owner.'));
                    if(order == null && customerDetailID == null) 
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Once you integrate this hierarchy you cannot append additional subscribers without an order. Please verify that you have the full hierarchy needed before clicking the "Integrate" button.'));
                }
                else if(ApexPages.getMessages().size() == 0) 
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'One or more customers that will be integrated is missing necessary information that must be corrected before you can proceed.'));
            }
        }
		else if(string.isEmpty(pID)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No account or order ID specified.'));
		else ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have access to integrate customers.'));
	}
	
	private transient Boolean initialized {get; set;}
	private transient TreeNode initResult {get; set;}
	private TreeNode init(Boolean treeMode){

		if(initialized == true) return initResult;
		initialized = true;
		
		Account a = accountID != null
					? [select Id
							,Name
							,ICC_Account_Number__c
							,ICC_Account_Type__c
							,Billable__c
							,Type
							,OwnerId
							,Agency__r.Name
							,ShippingStreet
							,ShippingCity
							,ShippingState
							,ShippingPostalCode
							,Customer_Detail__r.Id
							,Customer_Detail__r.Billing_Main_City__c
							,Customer_Detail__r.Exchange__c
							,Customer_Detail__r.First_Name__c
							,Customer_Detail__r.Last_Name__c
							,Customer_Detail__r.Care_Organization__c
							,Customer_Detail__r.Customer_Main_Address__c
							,Customer_Detail__r.Service_Address__c
							,Customer_Detail__r.Tax_Main_Address__c
							,Customer_Detail__r.Market_Area__r.Id
							,Customer_Detail__r.Market_Area__r.MarketAreaExternalID__c
							,Customer_Detail__r.Market_Type__r.Id
							,Customer_Detail__r.Market_Type__r.Name
                       		,Customer_Detail__r.Market_Area__r.Name
                       		,Customer_Detail__r.Acquired_Company_Biller__c
                       		,Customer_Detail__r.Accounts_Receivable_System__c
                       		,Customer_Detail__r.Billable__c
							,(Select Id From Account_Locations__r limit 2)
					from Account where Id = :accountID]
					: null;
		
		if(a == null){
			noIntegrationReason = 'You cannot integrate a customer that is not associated with an account.';
			return null;
		}
		
		Boolean accountIsIntegrated = !string.IsEmpty(a.ICC_Account_Number__c);
		willMatchOpportunityOwner = !accountIsIntegrated && opportunity != null;
		
		if(a.Type == 'Former Customer' && accountIsIntegrated){
			noIntegrationReason = 'No service locations can be integrated from Former Customer accounts.';
			return null;
		}
		
		availableContacts = new List<SelectOption>();
		
		for(Contact c : [select Id, Name from Contact where AccountId = : a.Id order by LastName, FirstName, Phone nulls first])
			availableContacts.add(new SelectOption(c.Id, c.Name));
		
		Set<Id> integratable = getServiceLocationsToIntegrate();
		//Boolean integrationOnlyMode = OrderUtils.orderIsIntegrationOnlyRecordType(order);
		
		if(integratable.size() == 0){
			noIntegrationReason = 'No service locations will integrate for this ' + (order != null ? 'order' : 'account') + '.';
			return null;
		}
		
 		/*
 		If  customer_detail.account != null (top level, grand parent or parent with no grandparent)
            If grandparent, don’t bother checking – you’ll never click Integrate on a grand parent.
            If parent, all service locations on account must match country
        
        If customer_detail.account = null (parent under grandparent or child)
            If service location has parent service location then child – all locations under this parent service location must match country
            If service location has null parent service location then parent – no need to check. You only have one service location at this point.
        */
		/*commenting all this code out as we are simplifying that all locations under an account must be for the same
		country for now.        
        if (canIntegrate) {
            Service_Location__c thisSL = [SELECT id, parent_service_location__c, customer_detail__c, Customer_Detail__r.Market_Area__r.Name, 
                                          Customer_Detail__r.Acquired_Company_Biller__c, Customer_Detail__r.Billable__c, Location__r.Building__r.Country__c, Level__c 
                                          FROM Service_Location__c WHERE Customer_Detail__c =: customerDetailID LIMIT 1];

            string tier = null;
        
            if (thisSL.Level__c == '3')
                tier = 'CHILD';
            else if (thisSL.Level__c == '2') {
            	if (thisSL.Parent_Service_Location__c != null)
                    tier = 'CHILD';
                else {
					//if no service locations have a parent service location, treat this a child and all countries must match
                    List<Service_Location__c> parentSLCheck = [SELECT id FROM Service_Location__c WHERE Account__c =: a.id AND Parent_Service_Location__c != null];
                    tier = (parentSLCheck.size() == 0) ? 'CHILDwithoutParent': 'PARENTunderGRANDPARENT';
                  }
            } else
                tier = 'PARENT'; //since this logic should not be triggered for a grandparent

            String slCountry = null;
            if (tier == 'CHILD') {
                for (Service_Location__c sl : [SELECT id, Location__r.Building__r.Country__c FROM Service_Location__c WHERE Account__c =: a.id AND (parent_service_location__c =: thisSL.Parent_Service_Location__c OR id =: thisSL.Parent_Service_Location__c)]){
                    if (slCountry == null) slCountry = sl.Location__r.Building__r.Country__c;
                    if (slCountry != sl.Location__r.Building__r.Country__c) {
                        System.debug(slCountry + '<>' + sl.Location__r.Building__r.Country__c);
                        noIntegrationReason = 'Service Locations at this tier of the customer hierarchy are not all the same country';
                        return null;                   
                    }
                }                
            } else if (tier == 'PARENT' || tier == 'CHILDwithoutParent') {
                for (Service_Location__c sl : [SELECT id, Location__r.Building__r.Country__c FROM Service_Location__c WHERE Account__c =: a.id]){
                    if (slCountry == null) slCountry = sl.Location__r.Building__r.Country__c;
                    if (slCountry != sl.Location__r.Building__r.Country__c) {
                        noIntegrationReason = 'Service Locations on this account are not all the same country';
                        return null;                   
                    }
                } 
            } else if (tier == 'PARENTunderGRANDPARENT') {
            	//no need to check anything until a child is added    
            }
        }
		*/
        if (RO == false && canIntegrate) {
			String slCountry = null;
            for (Service_Location__c sl : [SELECT id, Location__r.Building__r.Country__c FROM Service_Location__c WHERE Account__c =: a.id]){
                if (slCountry == null) slCountry = sl.Location__r.Building__r.Country__c;
                if (slCountry != sl.Location__r.Building__r.Country__c) {
                    noIntegrationReason = 'Service Locations on this account are not all the same country';
                    return null;                   
                }
            }             
        }
        
		Map<Id, Service_Location__c> allServiceLocs = new Map<Id, Service_Location__c>([select Id
																								,Name
																								,Owner__c
																								,ICC_Subscriber_ID__c
																								,Level__c
																								,Parent_Service_Location__r.Id
																								,Parent_Service_Location__r.Customer_Detail__c
																								,Customer_Detail__c
																						from Service_Location__c where Account__c = : a.Id]);
		
		Integer maxLevel = 0;
		Set<Id> lvl2 = new Set<Id>();
		Set<Id> lvl3 = new Set<Id>();
		
		Boolean hasMatchingAccountServiceLoc = false;
		Set<Id> detailIDs = new Set<Id>();
		Service_Location__c matchingLoc;
		for(Service_Location__c sLoc : allServiceLocs.values()){
			if(sLoc.Level__c == 'ERROR'){
				noIntegrationReason = 'One or more service locations on this account is saved at a hierarchy level greater than the allowed depth. The location \'' + sLoc.Name + '\' must be corrected before integration can be done.';
				return null;
			}
			
			if(accountIsIntegrated && sLoc.ICC_Subscriber_ID__c == a.ICC_Account_Number__c)
				hasMatchingAccountServiceLoc = true;
			
			if(sLoc.Parent_Service_Location__c == null || (a.Customer_Detail__c != null && sLoc.Parent_Service_Location__r.Customer_Detail__c == a.Customer_Detail__c))
				lvl2.add(sLoc.Id);
			else {
				lvl2.add(sLoc.Parent_Service_Location__c);
				lvl3.add(sLoc.Id);
			}
			
			if(sLoc.Customer_Detail__c != null){
				detailIDs.add(sLoc.Customer_Detail__c);
				if(sLoc.Customer_Detail__c == a.Customer_Detail__c)
					matchingLoc = sLoc;
			}
		}
		
		if(lvl3.size() > 0 && !string.IsEmpty(a.ICC_Account_Number__c) && a.Billable__c){
			noIntegrationReason = 'Grand-child subscribers cannot be integrated on a billable root subscriber.';
			return null;
		}
		//noIntegrationReason = '';
		
		List<Service_Location__c> baseLocs = new List<Service_Location__c>();
		Map<Id, List<Service_Location__c>> childLocs = new Map<Id, List<Service_Location__c>>();
		for(Service_Location__c sLoc: [select Id
												,Name
												,Parent_Service_Location__c
												,Billable__c
												,Owner__c
												,Agency__r.Name
												,ICC_Subscriber_ID__c
												,Customer_Detail__r.Id
												,Customer_Detail__r.Billing_Main_City__c
												,Customer_Detail__r.Exchange__c
												,Customer_Detail__r.First_Name__c
												,Customer_Detail__r.Last_Name__c
												,Customer_Detail__r.Care_Organization__c
												,Customer_Detail__r.Customer_Main_Address__c
												,Customer_Detail__r.Service_Address__c
												,Customer_Detail__r.Tax_Main_Address__c
												,Customer_Detail__r.Market_Area__r.Id
												,Customer_Detail__r.Market_Area__r.MarketAreaExternalID__c
                                       			,Customer_Detail__r.Market_Area__r.Name
												,Customer_Detail__r.Market_Type__r.Id
												,Customer_Detail__r.Market_Type__r.Name
                                       			,Customer_Detail__r.Acquired_Company_Biller__c
                                       			,Customer_Detail__r.Billable__c
                                       			,Customer_Detail__r.Accounts_Receivable_System__c
												from Service_Location__c
												where Id in : lvl2 or Id in : lvl3]){
			if(lvl2.contains(sLoc.Id))
				baseLocs.add(sLoc);
			else if(lvl3.contains(sLoc.Id) && sLoc.Parent_Service_Location__c != null){
				List<Service_Location__c> subLocs = childLocs.get(sLoc.Parent_Service_Location__c) != null ? childLocs.get(sLoc.Parent_Service_Location__c) : new List<Service_Location__c>();
				subLocs.add(sLoc);
				childLocs.put(sLoc.Parent_Service_Location__c, subLocs);
			}
		}
		
		if(a.Customer_Detail__c != null)
			detailIDs.add(a.Customer_Detail__c);
		
		Map<Id, List<Customer_Contact__c>> customerContactsByDetailID = new Map<Id, List<Customer_Contact__c>>();
		for(Customer_Contact__c cc : [select Id
											,Name
											,Contact__c
											,Contact__r.Name
											,Contact__r.Default_Responsible_Party__c
											,Contact_Type__c
											,Contact__r.Phone
											,Contact__r.Email
											,Customer_Detail__c
											,Phone__c
											,Email__c
										from Customer_Contact__c
										where Customer_Detail__c in : detailIDs
										order by Contact__r.LastName, Contact__r.FirstName, Contact_Type__c]){
			List<Customer_Contact__c> ccs = customerContactsByDetailID.get(cc.Customer_Detail__c) != null ? customerContactsByDetailID.get(cc.Customer_Detail__c) : new List<Customer_Contact__c>();
			ccs.add(cc);
			customerContactsByDetailID.put(cc.Customer_Detail__c, ccs);
		}
		
		Map<Id, User> users = new Map<Id, User>();
		users.put(a.OwnerId, null);
		if(willMatchOpportunityOwner) users.put(opportunity.OwnerId, null);
		
		for(Service_Location__c sloc : allServiceLocs.values())
			users.put(sloc.Owner__c, null);
		
		users = new Map<Id, User>([select Id, Name, Sales_Channel__c from User where Id in :users.keyset()]);
		
		Boolean willBeBillableAccount = (accountIsIntegrated && a.Billable__c) || (!accountIsIntegrated && lvl3.size() == 0 && (a.Billable__c || matchingLoc != null));
		
        canParseAccountAddresses = !accountIsIntegrated && a.Customer_Detail__c != null && (a.Customer_Detail__r.Customer_Main_Address__c == null
																	|| a.Customer_Detail__r.Service_Address__c == null
																	|| a.Customer_Detail__r.Tax_Main_Address__c == null);
		
		TreeNode accountNode = new TreeNode(a.Name + (accountIsIntegrated ? ' [' + a.ICC_Account_Number__c + ']' : ''), a.Id);
		if(matchingLoc != null){
			accountNode.hiddenAttributes.put('sLoc', matchingLoc.Id);
			addActionsToNode(accountNode, new List<String>{CustomerHierarchyController.actDef_OpenServiceLocation, CustomerHierarchyController.actDef_OpenServiceLocationInNewTab});
		}
		
		if(a.Customer_Detail__c != null){
			accountNode.hiddenAttributes.put('cDetail', a.Customer_Detail__c);
			addActionsToNode(accountNode, new List<String>{CustomerHierarchyController.actDef_OpenCustomerDetail, CustomerHierarchyController.actDef_OpenCustomerDetailInNewTab});
		}
		
		if(iconMapping == null){
			iconMapping = CustomerHierarchyController.mapSObjectIcons();
			setCustomIconMapping('existing_billable', CustomSettingUtils.getSingleProcessConfigurationValue('SubscriberIntegration', 'ExistingBillable', false), null, iconMapping);
			setCustomIconMapping('existing_nonbillable', CustomSettingUtils.getSingleProcessConfigurationValue('SubscriberIntegration', 'ExistingNonBillable', false), null, iconMapping);
			setCustomIconMapping('new_billable', CustomSettingUtils.getSingleProcessConfigurationValue('SubscriberIntegration', 'NewBillable', false), '/img/icon/flag16.png', iconMapping);
			setCustomIconMapping('new_nonbillable', CustomSettingUtils.getSingleProcessConfigurationValue('SubscriberIntegration', 'NewNonBillable', false), '/img/icon/flag16.png', iconMapping);
		}
		
		Id accountOwner = willMatchOpportunityOwner ? opportunity.OwnerId : a.OwnerId;
		accountNode.setAttribute('Integrated', accountIsIntegrated ? 'Yes' : 'No');
		accountNode.setAttribute('Sales Channel', users.get(accountOwner).Sales_Channel__c);
		accountNode.setAttribute('Owner', ICCWrapper.IndirectChannels.contains(users.get(accountOwner).Sales_Channel__c) ? a.Agency__r.Name : users.get(accountOwner).Name);
		if(accountIsIntegrated){
			accountNode.setAttribute('ICC subscriber type', a.ICC_Account_Type__c);
			accountNode.setAttribute('ICC subscriber ID', a.ICC_Account_Number__c);
			accountNode.setAttribute('Has matching Service Location ID', hasMatchingAccountServiceLoc ? 'Yes' : 'No');
			accountNode.iconID = ((a.Billable__c && iconMapping.get('existing_billable') != null)
									? 'existing_billable'
									: ((!a.Billable__c && iconMapping.get('existing_nonbillable') != null)
										? 'existing_nonbillable'
										: null));
		}
		else{
			accountNode.setAttribute('Will result in billable root', willBeBillableAccount ? 'Yes' : 'No');
			accountNode.iconID = willBeBillableAccount ? 'new_billable' : 'new_nonbillable';
			
			if(a.Billable__c != willBeBillableAccount)
				billableFlagIsIncorrect(accountNode, a.Id);
		}
		
		for(Service_Location__c sloc2 : baseLocs){
			TreeNode lvl2Node = new TreeNode(sloc2.Name + (!string.IsEmpty(sloc2.ICC_Subscriber_ID__c) ? ' [' + sloc2.ICC_Subscriber_ID__c + ']' : ''), sloc2.Id);
			
			Id sLoc2Owner = willMatchOpportunityOwner ? opportunity.OwnerId : sLoc2.Owner__c;
			Boolean lvl2WillMatchAccountSubID = matchingLoc != null && matchingLoc.Id == sLoc2.Id;
			Boolean lvl2NodeIntegrated = !string.IsEmpty(sLoc2.ICC_Subscriber_ID__c);
			Boolean lvl2Billable = lvl2NodeIntegrated ? sLoc2.Billable__c : (lvl2WillMatchAccountSubID ? willBeBillableAccount : !willBeBillableAccount);
			lvl2Node.setAttribute('Integrated', lvl2NodeIntegrated ? 'Yes' : 'No');
			lvl2Node.setAttribute('Sales Channel', users.get(sLoc2Owner).Sales_Channel__c);
			lvl2Node.setAttribute('Owner', ICCWrapper.IndirectChannels.contains(users.get(sLoc2Owner).Sales_Channel__c) ? sLoc2.Agency__r.Name : users.get(sLoc2Owner).Name);
			if(lvl2NodeIntegrated){
				lvl2Node.setAttribute('ICC subscriber ID', sLoc2.ICC_Subscriber_ID__c);
				lvl2Node.iconID = ((sloc2.Billable__c && iconMapping.get('existing_billable') != null)
									? 'existing_billable'
									: ((!sloc2.Billable__c && iconMapping.get('existing_nonbillable') != null)
										? 'existing_nonbillable'
										: null));
			}
			else{
				lvl2Node.setAttribute('Will integrate', integratable.contains(sloc2.Id) ? 'Yes' : 'No');
				if(integratable.contains(sloc2.Id)){
					lvl2Node.setAttribute('Will be billable', lvl2Billable ? 'Yes' : 'No');
					lvl2Node.setAttribute('Will match account subscriber ID', lvl2WillMatchAccountSubID ? 'Yes' : 'No');
					lvl2Node.iconID = lvl2Billable ? 'new_billable' : 'new_nonbillable';
					
					if(sLoc2.Billable__c != lvl2Billable)
						billableFlagIsIncorrect(lvl2Node, sLoc2.Id);
				}
			}
			
			for(Service_Location__c sloc3 : childLocs.get(sloc2.Id) != null ? childLocs.get(sloc2.Id) : new List<Service_Location__c>()){
				TreeNode lvl3Node = new TreeNode(sloc3.Name + (!string.IsEmpty(sloc3.ICC_Subscriber_ID__c) ? ' [' + sloc3.ICC_Subscriber_ID__c + ']' : ''), sloc3.Id);
				Id sLoc3Owner = willMatchOpportunityOwner ? opportunity.OwnerId : sLoc3.Owner__c;
				Boolean lvl3NodeIntegrated = !string.IsEmpty(sLoc3.ICC_Subscriber_ID__c);
				lvl3Node.setAttribute('Integrated', lvl3NodeIntegrated ? 'Yes' : 'No');
				lvl3Node.setAttribute('Sales Channel', users.get(sLoc3Owner).Sales_Channel__c);
				lvl3Node.setAttribute('Owner', ICCWrapper.IndirectChannels.contains(users.get(sLoc3Owner).Sales_Channel__c) ? sLoc3.Agency__r.Name : users.get(sLoc3Owner).Name);
				if(lvl3NodeIntegrated){
					lvl3Node.setAttribute('ICC subscriber ID', sLoc3.ICC_Subscriber_ID__c);
					lvl3Node.iconID = ((sloc3.Billable__c && iconMapping.get('existing_billable') != null)
										? 'existing_billable'
										: ((!sloc3.Billable__c && iconMapping.get('existing_nonbillable') != null)
											? 'existing_nonbillable'
											: null));
				}
				else {
					lvl3Node.setAttribute('Will integrate', integratable.contains(sloc3.Id) ? 'Yes' : 'No');
					if(integratable.contains(sloc3.Id)){
						Boolean lvl3Billable = !lvl2Billable;
						lvl3Node.setAttribute('Will be billable', lvl3Billable ? 'Yes' : 'No');
						lvl3Node.iconID = !lvl2Billable ? 'new_billable' : 'new_nonbillable';
						
						if(sLoc3.Billable__c != lvl3Billable)
							billableFlagIsIncorrect(lvl3Node, sLoc3.Id);
					}
				}
				
				if(integratable.contains(sloc3.Id)){
					if(sLoc3.Customer_Detail__c == null)
						noCustomerDetailExists(lvl3Node, sLoc3.Name, sLoc3.Id);
					else{
						lvl3Node.hiddenAttributes.put('cDetail', sLoc3.Customer_Detail__c);
						addActionsToNode(lvl3Node, new List<String>{CustomerHierarchyController.actDef_OpenCustomerDetail, CustomerHierarchyController.actDef_OpenCustomerDetailInNewTab});
						if(CustomerHierarchyController.getContactNodes(lvl3Node, customerContactsByDetailID.get(sLoc3.Customer_Detail__c)) == null)
							noResponsibleParty(lvl3Node, sLoc3.Name, sLoc3.Id);
						if (RO == false) checkDetailFields(lvl3Node, sLoc3.Customer_Detail__r, sLoc3.Billable__c);
					}
				}
				
				lvl2Node.addChildNode(lvl3Node, '');
			}
			
			if(integratable.contains(sloc2.Id)){
				if(sLoc2.Customer_Detail__c == null){
					if(lvl2WillMatchAccountSubID && a.Customer_Detail__c != null){
						sLoc2.Customer_Detail__c = a.Customer_Detail__c;
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Customer detail must be assigned to service location \'' + sLoc2.Name + '\' from account \'' + a.Name + '.\''));
					}
					else
						noCustomerDetailExists(lvl2Node, sLoc2.Name, sLoc2.Id);
				}
				else{
					lvl2Node.hiddenAttributes.put('cDetail', sLoc2.Customer_Detail__c);
					addActionsToNode(lvl2Node, new List<String>{CustomerHierarchyController.actDef_OpenCustomerDetail, CustomerHierarchyController.actDef_OpenCustomerDetailInNewTab});
					if(CustomerHierarchyController.getContactNodes(lvl2Node, customerContactsByDetailID.get(sLoc2.Customer_Detail__c)) == null)
						noResponsibleParty(lvl2Node, sLoc2.Name, sLoc2.Id);
					if (RO == false) checkDetailFields(lvl2Node, sLoc2.Customer_Detail__r, sLoc2.Billable__c);
				}
			}
			
 			accountNode.addChildNode(lvl2Node, '');
		}
		
		if(!accountIsIntegrated){
			if(a.Customer_Detail__c == null){
				if(matchingLoc == null || matchingLoc.Customer_Detail__c == null)
					noCustomerDetailExists(accountNode, a.Name, a.Id);
			}
			else{
				if (RO == false) checkDetailFields(accountNode, a.Customer_Detail__r, a.Billable__c);
                //MNK commented out the below as "Assign To" would get two entries for same entity 
                //and if both selected by user, ICC would get to responsible parties
				//if(CustomerHierarchyController.getContactNodes(accountNode, customerContactsByDetailID.get(a.Customer_Detail__c)) == null)
				//	noResponsibleParty(accountNode, a.Name, a.Id);
			}
		}
		
		if(order != null){
			TreeNode config = new TreeNode(order.Name, order.Id);
			config.iconID = 'config';
			accountNode.addChildNode(config, 'Configuration Objects');
		}
		
		if(opportunity != null){
			TreeNode config = new TreeNode(opportunity.Name, opportunity.Id);
			config.iconID = 'config';
			accountNode.addchildNode(config, 'Configuration Objects');
		}
		
		if(!treeMode){
			if(!accountIsIntegrated){
				if(a.Billable__c && !willBeBillableAccount)
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'The account is marked as billable but will be forced to save as non-billable due to its 3 level integration hierarchy.'));
			}
		}
		
		initResult = accountNode;
		return initResult;
	}
	
	private void setCustomIconMapping(String key, String val, String defaultVal, Map<String, String> m){
		if(!string.isEmpty(val) || defaultVal != null)
			m.put(key, !string.isEmpty(val) ? val : defaultVal);
	}
	
	private void addError(TreeNode node, String text){
		node.errors.add(text);
		canIntegrate = false;
	}
	
	private void checkDetailFields(TreeNode node, Customer_Detail__c detail, Boolean isBillable){
       
        if(detail.Customer_Main_Address__c == null) addError(node, 'Address of type \'Customer Main\' required.');
		if(detail.Service_Address__c == null) addError(node, 'Address of type \'Service\' required.');
		if(detail.Tax_Main_Address__c == null) addError(node, 'Address of type \'Tax Main\' required.');
		if(doBillableCorrection && isBillable && detail.Billing_Main_City__c == null) addError(node, 'Address of type \'Billing Main\' required.');
		if(detail.Care_Organization__c == null) addError(node, 'Care Organization must be set.');
		if(detail.Market_Area__c == null) addError(node, 'Market area must be set.');
		if(detail.Market_Type__c != null && detail.Market_Type__r.Name == 'Residential' && (string.IsEmpty(detail.First_Name__c) || string.IsEmpty(detail.Last_Name__c))) addError(node, 'First name and last name must be set.');
		if(detail.Market_Area__c != null && detail.Market_Area__r.MarketAreaExternalID__c == ICCWrapper.PriorLakeMarketAreaID && detail.Exchange__c == null) addError(node, 'No exchange value has been set.');
		if(detail.Market_Area__c != null && detail.Billable__c == true && detail.Market_Area__r.Name == 'National' && detail.Acquired_Company_Biller__c == null) addError(node, '\'Acquired Company or Biller\' must be set.');
        if(detail.Market_Area__c != null && detail.Billable__c == true && detail.Market_Area__r.Name == 'National' && detail.Accounts_Receivable_System__c == null) addError(node, '\'Accounts Receivable System\' must be set.');
        if(detail.Market_Area__c != null && detail.Market_Area__r.Name == 'National' && detail.Acquired_Company_Biller__c == 'IBIS' && detail.Accounts_Receivable_System__c != 'IBIS') addError(node, 'If the Acquired Company Biller is IBIS, Accounts Receivable System must be IBIS');
        if(detail.Market_Area__c != null && detail.Market_Area__r.Name == 'National' && detail.Acquired_Company_Biller__c == 'Phoenix' && detail.Accounts_Receivable_System__c != 'RevChain') addError(node, 'If the Acquired Company Biller is Phoenix, Accounts Receivable System must be RevChain');
        if(detail.Market_Area__c != null && detail.Market_Area__r.Name == 'National' && detail.Acquired_Company_Biller__c == 'ICMS' && detail.Accounts_Receivable_System__c != 'ICMS') addError(node, 'If the Acquired Company Biller is ICMS, Accounts Receivable System must be ICMS.');
        if(detail.Market_Area__c != null && detail.Market_Area__r.Name == 'National' && detail.Acquired_Company_Biller__c == 'ASAP' && detail.Accounts_Receivable_System__c != 'ASAP') addError(node, 'If the Acquired Company Biller is ASAP, Accounts Receivable System must be ASAP.');
    }
	
	private void noResponsibleParty(TreeNode node, String name, Id id){
		node.errors.add('No responsible party assigned.');
		needsResponsibleParty.add(new SelectOption(id, name));
		canIntegrate = false;
	}
	
	private void noCustomerDetailExists(TreeNode node, String name, Id id){
		node.errors.add('No customer detail exists.');
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Customer details must be generated for \'' + name + '.\''));
		detailsToCreate.add(id);
		canIntegrate = false;
	}
	
	private void billableFlagIsIncorrect(TreeNode node, Id id){
		if(doBillableCorrection){
			node.errors.add('Billable flag does not match integration value.');
			billableFlagsToUpdate.add(id);
			canIntegrate = false;
		}
	}
	
	private void creditCheckIsIncomplete(TreeNode node, Id Id){
		if(doCreditCheck){
			node.errors.add('Credit check Approval process pending, must be completed to integrate account and orders.');
			canIntegrate = false;
		}
	}
	
	public PageReference updateBillableFlags(){

		List<Account> accounts = [select Id
										,Billable__c
										,BillingCity
										,BillingPostalCode
										,BillingState
										,BillingStreet
										,Customer_Detail__c
										from Account where Id in : billableFlagsToUpdate];
		List<Service_Location__c> sLocs = [select Id
												,Billable__c
												,Customer_Detail__c
												,Location__r.Building__c
												,Location__r.Building__r.City__c
												,Location__r.Building__r.Postal_Code__c
												,Location__r.Building__r.State__c
												,Location__r.Building__r.Address__c
                                                ,Location__r.Building__r.Zip4__c
                                           		,Location__r.Building__r.Country__c
												,Location__r.Room_Suite__c
												from Service_Location__c where Id in : billableFlagsToUpdate];
		
		Set<Id> billableDetailIDs = new Set<Id>();
		for(Account a : accounts){
			a.Billable__c = !(a.Billable__c == true);
			if(a.Billable__c && a.Customer_Detail__c != null)
				billableDetailIDs.add(a.Customer_Detail__c);
		}
		
		for(Service_Location__c sLoc : sLocs){
			sLoc.Billable__c = !(sLoc.Billable__c == true);
			if(sLoc.Billable__c && sLoc.Customer_Detail__c != null)
				billableDetailIDs.add(sLoc.Customer_Detail__c);
		}
		
		SecurityUtils.BypassProcesser.saveObjects(accounts, true);
		SecurityUtils.BypassProcesser.saveObjects(sLocs, true);
		
		if(billableDetailIDs.size() > 0){
			Map<Id, Customer_Detail__c> detailUpdates = new Map<Id, Customer_Detail__c>([select Id
																								,Billing_Main_City__c
																							from Customer_Detail__c
																							where Id in: billableDetailIDs
																							and Billing_Main_City__c = null]);
			for(Service_Location__c sLoc : sLocs){
				if(sLoc.Customer_Detail__c != null && detailUpdates.get(sLoc.Customer_Detail__c) != null && sLoc.Location__r.Building__c != null){
					AddressUtils.updateCustomerDetailAddressSet(detailUpdates.get(sLoc.Customer_Detail__c)
													,'Billing_Main'
													,sLoc.Location__r.Building__r.City__c
													,sLoc.Location__r.Building__r.Postal_Code__c
													,sLoc.Location__r.Building__r.Zip4__c
													,sLoc.Location__r.Building__r.State__c
													,sLoc.Location__r.Building__r.Address__c
													,sLoc.Location__r.Room_Suite__c
													,null
                                                    ,sLoc.Location__r.Building__r.Country__c);
				}
			}
			
			for(Account a : accounts){
				if(a.Customer_Detail__c != null && detailUpdates.get(a.Customer_Detail__c) != null && detailUpdates.get(a.Customer_Detail__c).Billing_Main_City__c == null){
					AddressUtils.updateCustomerDetailAddressSet(detailUpdates.get(a.Customer_Detail__c)
													,'Billing_Main'
													,a.BillingCity
													,a.BillingPostalCode
													,a.BillingState
													,a.BillingStreet
													,null
													,null
                                                    ,a.BillingCountry);
				}
			}
			
			update detailUpdates.values();
		}
		
		return refresh();
	}
	
	public PageReference updateCustomerDetails(){
        
		Boolean cloneFromParent = Apexpages.currentPage().getParameters().get('cloneFromParent') == 'true';
		
		Account a = [select Id, Customer_Detail__c, ICC_Account_Number__c from Account where Id =: accountID];
		List<Service_Location__c> sLocs = [select Id, Customer_Detail__c, ICC_Subscriber_ID__c from Service_Location__c where Account__c =: a.Id];
		Boolean singleLoc = sLocs.size() == 1;
		
		CustomerDetailUtils.triggerDetailAddressValidation = false;
		
		Id matchingLocID = null;
		List<Set<Id>> detailsToCreateList = new List<Set<Id>>();
		Set<Id> needCloned = new Set<Id>();
		if(detailsToCreate.size() > 1 || !detailsToCreate.contains(a.Id)){
			for(Service_Location__c sLoc : sLocs){
				if(cloneFromParent){
					if(detailsToCreate.contains(sLoc.Id)) needCloned.add(sLoc.Id);
				}
				else{
					if(singleLoc && string.IsEmpty(sLocs[0].ICC_Subscriber_ID__c) && string.IsEmpty(a.ICC_Account_Number__c)){
						matchingLocID = sLoc.Id;
						detailsToCreateList.add(new Set<Id>{a.Id, sLoc.Id});	//Create/update the shared detail
					}
					else if(detailsToCreate.contains(sLoc.Id))
						detailsToCreateList.add(new Set<Id>{sLoc.Id});			//Creating a new customer detail
					else if(string.IsEmpty(a.ICC_Account_Number__c) && a.Customer_Detail__c != null && sLoc.Customer_Detail__c == a.Customer_Detail__c)
						CustomerDetailUtils.cloneCustomerDetails(new Set<Id>{sLoc.Id}, null);	//Clone the detail from the account to the service loc
				}
			}
		}
		
		if(detailsToCreate.contains(a.Id) && matchingLocID == null)
			detailsToCreateList.add(new Set<Id>{a.Id});
			
		system.debug('Updating details for: ' + detailsToCreate);
		
		if(detailsToCreateList.size() > 0)
			CustomerDetailUtils.updateCustomerDetails(detailsToCreateList);
		
		if(needCloned.size() > 0)
			CustomerDetailUtils.cloneCustomerDetailsFromParent(needCloned);
		
		return refresh();
	}
	
	public PageReference setResponsibleParty(){

        List<String> errors = new List<String>();
		if(responsibleParty != null && selectedCustomers != null && selectedCustomers.size() > 0){
			Map<Id, Id> customerDetailIDByObjectID = new Map<Id, Id>();
			for(String c : selectedCustomers)
				customerDetailIDByObjectID.put(c, null);
				
			for(Account a : [select Id, Customer_Detail__c from Account where Id in : customerDetailIDByObjectID.keyset() and Customer_Detail__c != null])
				customerDetailIDByObjectID.put(a.Id, a.Customer_Detail__c);
			for(Service_Location__c sLoc : [select Id, Customer_Detail__c from Service_Location__c where Id in : customerDetailIDByObjectID.keyset() and Customer_Detail__c != null])
				customerDetailIDByObjectID.put(sLoc.Id, sLoc.Customer_Detail__c);
			
			List<Customer_Contact__c> newResponsibleParties = new List<Customer_Contact__c>();
			for(Id id : customerDetailIDByObjectID.keyset()){
				Customer_Contact__c cc = new Customer_Contact__c(Contact__c = responsibleParty.Contact__c
																,Contact_Type__c = responsibleParty.Contact_Type__c
																,Email__c = responsibleParty.Email__c
																,Phone__c = responsibleParty.Phone__c);
				cc.Customer_Detail__c = customerDetailIDByObjectID.get(id);
				
				if(cc.Customer_Detail__c == null) continue;
				
				newResponsibleParties.add(cc);
			}
			
			for(Database.UpsertResult result : Database.Upsert(newResponsibleParties, false)){
				for(Database.Error err : result.getErrors())
					errors.add(err.getMessage());
			}
		}
		
		for(String error : errors)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
		
		return errors.size() == 0 ? refresh() : null;
	}
	
	private PageReference refresh(){

        PageReference nextPage = Page.CustomerIntegration;
        if(order != null) nextPage.getParameters().put('Id', order.Id);
        else if(customerDetailID != null) nextPage.getParameters().put('Id', customerDetailID);
        else if(accountID != null) nextPage.getParameters().put('Id', accountID);
        nextPage.setRedirect(true);
        return nextPage;
	}
	
	public PageReference accountAddressParsed(){

        Boolean success = Apexpages.currentPage().getParameters().get('success') == 'true';
		String error = Apexpages.currentPage().getParameters().get('error');
		
		canIntegrate = false;
		
		List<ApexPages.Message> messages = ApexPages.getMessages();
		for(Integer i=messages.size()-1; i>=0; i--){
			if(messages[i].getSeverity() == ApexPages.Severity.INFO)
				messages.remove(i);
		}
		
		if(success){
	        integraWS.SFLocationView locView = AddressParser.addressParsed();
	        system.debug('locView: ' + locView);
	        
            if(locView != null && locView.Success && !string.IsEmpty(locView.BuildingHash)){
				newRootBuilding = AddressUtils.CreateBuilding(locView, false);
				newRootLocation = AddressUtils.CreateLocation(newRootBuilding, locView, false);
				newRootBuildingCLLI = locView.LSOCLLI;
				
				if(newRootBuilding != null && newRootLocation != null){
					canIntegrate = true;
					
					String parsedAddress = locView.Street
											+ (!string.IsEmpty(locView.SubPremise) ? ', ' + locView.SubPremise : '')
											+ (!string.IsEmpty(locView.City) ? ', ' + locView.City : '')
											+ (!string.IsEmpty(locView.State) ? ', ' + locView.State : '')
											+ (!string.IsEmpty(locView.PostalCode) ? ', ' + locView.PostalCode : '');
					
					List<Account> accounts = [select Id
												from Account where Id = :accountID
												and (Customer_Detail__r.Customer_Main_Address__c = null
												or Customer_Detail__r.Service_Address__c = null
												or Customer_Detail__r.Tax_Main_Address__c = null)];
					
					canParseAccountAddresses = accounts.size() > 0;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Account address parsed as: ' + parsedAddress));
				}
            }
		}
		
		if(!canIntegrate){
			
			if(!string.IsEmpty(error))
				system.debug('Google address parsing failed with error: ' + error);
			
			canIntegrate = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No location can be created from account address: ' + addressToGeocode));
		}
		else
			canIntegrate = !canParseAccountAddresses;
		
		addressToGeocode = null;
		
		return null;
	}
	
	public PageReference updateAccountAddresses(){
        
        if(newRootBuilding != null && newRootLocation != null){
			
			List<Account> accounts = [select Id
										,Customer_Detail__c
										from Account where Id = :accountID];

			if(accounts.size() > 0 && accounts[0].Customer_Detail__c != null){
				Customer_Detail__c detail = ((List<Customer_Detail__c>)(ApexUtils.retrieveObjectsFromFieldSet(
																			Customer_Detail__c.getsObjectType()
																			,AddressUtils.CustomerDetailAddressFieldSet
																			,'Id = \'' + accounts[0].Customer_Detail__c + '\''
																			,null)))[0];
				
        		Map<Integer, String> reversedTypeMap = new Map<Integer, String>();
				for(String str : AddressUtils.CustomerDetailFieldAddressTypes.keyset())
					reversedTypeMap.put(AddressUtils.CustomerDetailFieldAddressTypes.get(str), str);
				
				Integer maID = detail.Market_Area__c != null ? Integer.valueOf(detail.Market_Area__r.ICCMarketAreaID__c) : 0;
				List<integraWS.SFSubscriberAddressView> addresses = new List<integraWS.SFSubscriberAddressView>();
				for(String typeName : AddressUtils.CustomerDetailFieldAddressTypes.keyset()){
 					if(string.IsEmpty(string.valueOf(detail.get(typeName))))
						addresses.add(AddressUtils.setSubscriberAddressViewNameValues(
										AddressUtils.setSubscriberAddressViewValues(newRootBuilding, null, null, 0, AddressUtils.CustomerDetailFieldAddressTypes.get(typeName), maID)
										,null, detail.Name, detail.First_Name__c, detail.Last_Name__c));
				}
				
				Boolean invalidFound = false;
				List<integraWS.SFSubscriberAddressView> validationResults = ICCWrapper.validateSubscriberAddresses(addresses, UserInfo.getSessionId());
				for(Integer i=0; i<validationResults.size(); i++){
 					if(!string.IsEmpty(validationResults[i].ResultMessage)){
						invalidFound = true;
						system.debug('Address type ' + validationResults[i].AddressTypeId + ' did not validate for customer detail \'' + detail.Id + '\'');
					}
					else
						detail.put(reversedTypeMap.get(validationResults[i].AddressTypeId), newRootLocation.Id);
				}
				update detail;
				
				if(invalidFound){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The account shipping address can not be set for one or more of the missing addresses found. Please set the missing addresses from the customer detail page.'));
					return null;
				}
			}
			AddressUtils.SaveAddress(newRootBuilding, newRootLocation, null, true);
		}
		
		return refresh();
	}
	
	private Set<Id> getServiceLocationsToIntegrate(){
        Set<Id> sLocIDs = new Set<Id>();
		if(customerDetailID != null){
			for(Service_Location__c sLoc : [select Id, Parent_Service_Location__c, Parent_Service_Location__r.Parent_Service_Location__c from Service_Location__c where Customer_Detail__c =: customerDetailID]){
				for(Id id : new List<Id>{ sLoc.Id, sLoc.Parent_Service_Location__c, sLoc.Parent_Service_Location__r != null ? sLoc.Parent_Service_Location__r.Parent_Service_Location__c : null }){
					if(id != null) sLocIDs.add(id);
				}
			}
		}
		else{
			if (RO)
                sLocIDs = new Map<Id, Service_Location__c>([select Id from Service_Location__c where Account__c =: accountID]).keyset();
            else
            	sLocIDs = (order != null
						? OrderUtils.getServiceLocationsToIntegrate(order, null)
						: new Map<Id, Service_Location__c>([select Id from Service_Location__c where Account__c =: accountID and ICC_Subscriber_ID__c = null])).keyset();
		}
		return sLocIDs;
	}
	
	public PageReference integrate(){
		try{
			Map<Id, Id> orderIDsByServiceLocationID = new Map<Id, Id>();
			for(Id sLocID : getServiceLocationsToIntegrate())
	        	orderIDsByServiceLocationID.put(sLocID, order != null ? order.Id : null);
			
			system.debug('Service locations to create as subscribers: ' + orderIDsByServiceLocationID.keyset());
            List<String> errors = (orderIDsByServiceLocationID.size() > 0) ? IntegrationUtils.createSubscribersFromOrderRelatedServiceLocations(orderIDsByServiceLocationID, UserInfo.getSessionId()) : new List<String>();
			
			if(willMatchOpportunityOwner){
				List<Service_Location__c> sLocs = [select Id from Service_Location__c where Account__c =: accountID and Owner__c !=: opportunity.OwnerId];
				for(Service_Location__c sLoc : sLocs)
					sLoc.Owner__c = opportunity.OwnerId;
				if(sLocs.size() > 0) SecurityUtils.BypassProcesser.saveObjects(sLocs, false);
			}
			
			if(errors.size() == 0){
				return (new ApexPages.StandardController([select Id from Account where Id =: accountID])).view();
			}
			else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'Subscriber integration has completed with errors:'));
				for(String err : errors)
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, err));
			}
		}
		catch(Exception e){
            system.debug('CustomerIntegrationController exception');
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getStackTraceString()));
 		}
		canIntegrate = false;
		
	    return null;
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_CustomerIntegration(); }
}