public with sharing class ILECOpportunityGeneration extends TreeViewController {
	
	public Boolean opportunityClosedSuccessfully {get; private set;}
	public Integer MRR {get;set;}
	public Opportunity_Product__c oppProd {get; private set;}
	public Service_Location__c sloc {get; private set;}
	public Opportunity opp {get; private set;}
	public Account account {get; private set;}
	public List<Contact> contacts {get;private set;}
	public List<SelectOption> contactList{
		get{
			List<SelectOption> options = new List<SelectOption>();
			if(contacts.size() > 0){
				for(Contact c : contacts){
					options.add(new SelectOption(c.Id,c.Name));
				}
			}	
			return options;
		}
	}
	public String addressToGeocode {get; private set;}
	public Boolean hasResponsibleParty {get;private set;}
	public Id ResponsiblePartyId {get;set;}
	public Boolean slocCreated {get;private set;}
	
	public ILECOpportunityGeneration(){
		opportunityClosedSuccessfully = false;
		hasResponsibleParty = false;
		
		String accountId = '';
		accountId = ApexPages.currentPage().getParameters().get('accountId');
		if(accountId != '')
		{
			loadAccount();
			
			List<Service_Location__c> slocs = loadServiceLocation(accountId);
			if(slocs.size() > 0){
				sloc = slocs[0];
				slocCreated = true; 
			}
			else{
				slocCreated = false;
				sloc = null;
			}
			
			List<Opportunity> opps = [select Id, Name from Opportunity where AccountId = :accountId and type = 'New Logo' and StageName = 'Identification' and RecordType.DeveloperName = 'ILEC_Manual_Entry' limit 1];
			if(opps.size() > 0) { 
				opp = opps[0];
				List<OpportunityContactRole> oppContacts = [select Id, ContactId
															from OpportunityContactRole 
															where OpportunityId = :opp.Id
																and Role = 'Responsible Party'];
				if(oppContacts.size() > 0)
					hasResponsibleParty = true; 
			}
			else{
				opp = new Opportunity();
				recordtype rt = [select Id from recordtype where sobjecttype = 'opportunity' and developername = 'ILEC_Manual_Entry' limit 1];
				opp.RecordTypeId = rt.Id;
				String oppName = 'New Opportunity for Account: ' + account.Name;
				opp.Name = (oppName.length() > 80)? oppName.substring(0,80) : oppName;
				opp.AccountId = account.id;
				opp.Type = 'New Logo';
				opp.StageName = 'Identification';
				opp.CloseDate = Date.today();				
			}
			
			oppProd = new Opportunity_Product__c();
			contacts = [select Id, Name, Default_Responsible_Party__c from Contact where AccountId = :account.Id order by createdDate];
			for(Contact con : contacts){
				if (ResponsiblePartyId == null){
					ResponsiblePartyId = con.Id;
				}
				if (con.Default_Responsible_Party__c)
				{
					ResponsiblePartyId = con.Id;
					break;
				}
			}
			
			addressToGeocode = account.ShippingStreet
									+ (!string.IsEmpty(account.ShippingCity) ? ', ' + account.ShippingCity : '')
									+ (!string.IsEmpty(account.ShippingState) ? ', ' + account.ShippingState : '')
									+ (!string.IsEmpty(account.ShippingPostalCode) ? ', ' + account.ShippingPostalCode : '');
			
			TreeViewsByDivID = new Map<String, TreeViewImplementation>{'opportunityHierarchy'=>new TreeViewImplementation(account, sLoc, opp)};
		}
		else
		{
			//error
		}
	}
	
	public class TreeViewImplementation extends TreeViewController.TreeViewImplementation{
		public Account account {get; set;}
		public Service_Location__c sLoc {get; set;}
		public Opportunity opp {get; set;}
		
		public TreeViewImplementation(Account account, Service_Location__c sLoc, Opportunity opp){
			this.account = account;
			this.sLoc = sLoc;
			this.opp = opp;
			loadMoreEnabled = false;
		}
		
		public override List<TreeNode> getNodes(){
			TreeNode accountNode = new TreeNode(account.Name, account.Id);
			if(sloc != null){
				accountNode.addChildNode(new TreeNode(sloc.Name, sloc.Id),'[Service Location]');
			}
			if(opp.Id != null){
				TreeNode oppNode = new TreeNode(opp.Name, opp.Id);
				for(Opportunity_Product__c oppProduct : [select Id, Sales_Product__c 
													 	from Opportunity_Product__c 
													 	where Opportunity__c = :opp.Id
														 	and Primary_Service_Location__c = :sloc.Id]){
					oppNode.addChildNode(new TreeNode(oppProduct.Sales_Product__c, oppProduct.Id), '[Products]');									 		
				}
				accountNode.addChildNode(oppNode, '[Opportunity]');
			}
			
			return new List<TreeNode>{accountNode};
		}
	    
		public override Map<String, String> getIconMap(){
			Map<String, String> m = CustomerHierarchyController.mapSObjectIcons();
			m.put('new', '/img/icon/flag16.png');
			return m;
		}
	}
	
	public PageReference AddProduct() {
		if(!CreateLocation()){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error creating service location!'));
			return null;
		}
		if(opp.id == null && opp != null) {
			insert opp;
		}
		if(opp == null || (opp != null && opp.id == null)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error creating opportunity!'));
			return null;
		}
		oppProd.Opportunity__c = opp.id;
		oppProd.Primary_Service_Location__c = sloc.Id;
		insert oppProd;
		oppProd = new Opportunity_Product__c();
		
		return refresh();
	}
	
	public PageReference Finalize() {
		closeOpp();
		return null;
	}
	
	private Boolean CreateLocation() {
		if(slocCreated) return true;
		
		Boolean buildingCreated = false;
		Boolean slocCreated = false;
		// create service location
		
		integraWS.SFLocationView locView = AddressParser.addressParsed();
        system.debug('KIT locView: ' + locView);
		Building__c tempRootBuilding = null;
		Location__c tempRootLocation = null;
		Service_Location__c tempMatchingServiceLoc = null;
        if(locView != null && locView.Success && !string.IsEmpty(locView.BuildingHash)){
			tempRootBuilding = AddressUtils.CreateBuilding(locView, false);
			tempRootLocation = AddressUtils.CreateLocation(tempRootBuilding, locView, false);
			system.debug('KIT tempRootBuilding: ' + tempRootBuilding);
			system.debug('KIT tempRootLocation: ' + tempRootLocation);
			
			tempMatchingServiceLoc = new Service_Location__c();
			tempMatchingServiceLoc.Name = account.Name;
			tempMatchingServiceLoc.Account__c = account.Id;
			tempMatchingServiceLoc.Phone__c = account.Phone;
			tempMatchingServiceLoc.Owner__c = account.OwnerId;
			tempMatchingServiceLoc.Agency__c = account.Agency__c;
			tempMatchingServiceLoc.Billable__c = account.Billable__c;
			tempMatchingServiceLoc.Customer_Detail__c = account.Customer_Detail__c;
			system.debug('KIT tempMatchingServiceLoc' + tempMatchingServiceLoc);
			
            	// create new location
            	
            if(tempRootBuilding != null){
            	system.debug('KIT upserting tempRootBuilding: ' + tempRootBuilding);
				upsert tempRootBuilding;
				buildingCreated = true;
				if(tempRootLocation != null){
					tempRootLocation.Building__c = tempRootBuilding.Id;
					system.debug('KIT upserting tempRootLocation: ' + tempRootLocation);
					upsert tempRootLocation;
				
					tempMatchingServiceLoc.Location__c = tempRootLocation.Id;
				}
            }
            system.debug('KIT inserting tempMatchingServiceLoc: ' + tempMatchingServiceLoc);
			insert tempMatchingServiceLoc;
		    slocCreated = true;
		    sloc = tempMatchingServiceLoc;
            if(tempRootBuilding.Serving_LSO__c == null){
            	system.debug('KIT Serving_LSO__c is null!');       	
            	// end create new location
                //Task t = !Test.IsRunningTest() ? AddressUtils.CreateTaskForNoServingLSO(tempRootBuilding, locView.LSOCLLI) : new Task();
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'A <a href=\'../' + tempMatchingServiceLoc.Id + '\'>service location</a> has been created to match this account but no serving LSO could be determined for this location. A <a href=\'../' + t.Id + '\'>task</a> has been created to correct the building.'));
            }
        }
        return buildingCreated && slocCreated;
        
	}
	
	public static Map<Id, Map<String, Id>> AddressValidationMappingByID { get; set; }
	private void closeOpp(){
		try{
			if(opp!=null && opp.id != null){
				if(!hasResponsibleParty){
					OpportunityContactRole ocr = new OpportunityContactRole();
					ocr.OpportunityId = opp.id;
					ocr.ContactId = ResponsiblePartyId;
					ocr.Role = 'Responsible Party';
					insert ocr;
				}
				
				CustomerDetailUtils.triggerDetailAddressValidation = false;
				CustomerDetailTriggers.ManualAddressValidation = true;
				//opp.StageName = OpportunityUtils.STAGE_CLOSED_WON;
				opp.StageName = OpportunityUtils.STAGE_5;
				opp.Contract_Signed_Date__c = Date.today();
				opp.Customer_Requested_Due_Date__c = Date.today();
				opp.Term__c = '12';
				opp.Bypass_Validation__c = true;
				update opp;
				
				AddressValidationMappingByID = CustomerDetailTriggers.AddressValidationMappingByID;
				
				opportunityClosedSuccessfully = true;
			}
		}
		catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			opportunityClosedSuccessfully = false;
		}
	}
	
	public PageReference ValidateAddressesAndRedirectToOppIntegrationPage(){
		List<String> errors = AddressUtils.validateAndSetCustomerDetailAddresses(AddressValidationMappingByID, UserInfo.getSessionId());
		system.debug('CustomerDetail Validation: ' + errors);
		
		PageReference nextPage = Page.CustomerIntegration;
		nextPage.getParameters().put('Id', [select Id from Order__c where Opportunity__r.Id =: opp.Id limit 1].Id);
		nextPage.setRedirect(true);
		return nextPage;
	}
	
	private void loadAccount(){
		String accountId = '';
		accountId = ApexPages.currentPage().getParameters().get('accountId');
		if(accountId != '')
		{
			account = [select Id
							 ,Name
							 ,Phone
							 ,OwnerId
							 ,Agency__c
							 ,Billable__c
							 ,Customer_Detail__c
							 ,ShippingStreet
							 ,ShippingCity
							 ,ShippingState
							 ,ShippingPostalCode 
							 ,ICC_Account_Type__c
					   from Account 
					   where id = :accountId limit 1];
		}
	}
	
	private List<Service_Location__c> loadServiceLocation(string AccountId){
		return [select Id, Name, Customer_Detail__c from Service_Location__c where account__c = :AccountId limit 1];
	}
	
	private PageReference refresh(){
		PageReference nextPage = Page.ILECOpportunityGeneration;
        nextPage.getParameters().put('accountId', account.Id);
        nextPage.setRedirect(true);
        return nextPage;
	}
}