public class AccountTransferController implements TestUtils.ITestableClass {
	
    public Account toAccount {get;set;}
    public Account fromAccount {get;set;}
	
    public Account_Partner__c toPartner {get;set;}
    public Account_Partner__c fromPartner {get;set;}
	
	public Service_Location__c toLoc {get;set;}
	public Service_Location__c fromLoc {get;set;}
	
	public AccountTeamMember toCAM {get;set;}
	public AccountTeamMember fromCAM {get;set;}
	
	//public List<SelectOption> accountSalesChannels {get;set;}
	
	public Boolean canTransferOwner { get; set; }
	public Boolean canUpdateCAM { get; set; }
    
	private Map<Id, accountWrapper> aMap = new Map<Id, accountWrapper>();
	private Map<Id, serviceLocationWrapper> sMap = new Map<Id, serviceLocationWrapper>();
	
	public virtual class wrapperBase{
 		public Boolean selected {get;set;}
 		public Boolean canTransfer {get;set;}
 		public wrapperBase matchingRecord {get;set;}
		
		public User cam {get;set;}
		public Account_Partner__c partner {get;set;}
		
		public wrapperBase(){
 			selected = false;
 			canTransfer = true;
		}
		
		public void setCAM(AccountTeamMember atm){
			if(atm != null){
				cam = atm.User;
			}
		}
	}
    
 	public class accountWrapper extends wrapperBase{
 		public Account obj {get;set;}
 		public accountWrapper(Account a){
 			obj = a;
 		}
 	}
    
 	public class serviceLocationWrapper extends wrapperBase{
 		public Service_Location__c obj {get;set;}
 		public serviceLocationWrapper(Service_Location__c s){
 			obj = s;
 		}
 	}
 	
 	public Boolean currentAcountOnly {get;set;}
 	//public Boolean transferOtherOpenOpps {get;set;}
 	public Boolean keepAccountTeams {get;set;}
 	public Boolean keepOppTeams {get;set;}
 	public String nameContains {get;set;}
 	
    public Integer totalRecords {get;set;}
    public Integer transferableRecordCount {get;set;}
    public List<accountWrapper> accounts {get;set;}
    public List<serviceLocationWrapper> sLocs {get;set;}
	public List<SelectOption> camRoles {get;set;}
    
    public AccountTransferController() {
        toAccount = new Account();
        fromAccount = new Account();
		
		toPartner = new Account_Partner__c(RecordType = new RecordType(DeveloperName = ICCWrapper.partnerAgent));
		fromPartner = new Account_Partner__c(RecordType = new RecordType(DeveloperName = ICCWrapper.partnerAgent));
		
		toLoc = new Service_Location__c();
		fromLoc = new Service_Location__c();
		
		toCAM = new AccountTeamMember();
		fromCAM = new AccountTeamMember();
		
        accounts = new List<accountWrapper>();
        sLocs = new List<serviceLocationWrapper>();
        totalRecords = transferableRecordCount = 0;
		/*transferOtherOpenOpps = */currentAcountOnly = keepAccountTeams = keepOppTeams = false;
		canTransferOwner = SecurityUtils.currentUserHasProspectTransferAccess();
		canUpdateCAM = Customer_Detail__c.Customer_Account_Manager__c.getDescribe().isUpdateable();
		//accountSalesChannels = getAccountSalesChannels();
        
 		String accountId = ApexPages.currentPage().getParameters().get('accountId');
 		if(!string.IsEmpty(accountId)){
			fromAccount = [select Id, Name, OwnerId from Account where Id =:accountId limit 1];
			fromLoc.Owner__c = fromAccount != null ? fromAccount.OwnerId : null;
			for(AccountTeamMember atm : [select Id, TeamMemberRole, UserId from AccountTeamMember where AccountId =: accountId and TeamMemberRole in: ICCWrapper.CamTeamMemberRoles limit 1]){
				fromCAM.UserId = atm.UserId;
				toCAM.TeamMemberRole = atm.TeamMemberRole;
			}
			
			for(Account_Partner__c ap : [select Partner__c from Account_Partner__c where Account__c =: accountId and RecordType.DeveloperName in: ICCWrapper.PartnerAgentTypes])
				fromPartner.Partner__c = ap.Partner__c;
 		}
		else{
	 		String ownerId = ApexPages.currentPage().getParameters().get('ownerId');
	 		if(!string.IsEmpty(ownerId) && [select COUNT() from User where Id =:ownerId] > 0)
	 			fromLoc.Owner__c = ownerId;
	 		
	 		String agencyId = ApexPages.currentPage().getParameters().get('agencyId');
	 		if(!string.IsEmpty(agencyId) && [select COUNT() from Account where Id =:agencyId] > 0)
	 			fromPartner.Partner__c = agencyId;
		}
		
		camRoles = new List<SelectOption>();
		for(String s : ICCWrapper.CamTeamMemberRoles)
			camRoles.add(new SelectOption(s, s));
		camRoles.sort();
    }
	
/*	private List<SelectOption> getAccountSalesChannels(){
		List<SelectOption> l = new List<SelectOption>{new SelectOption('', '--Keep Existing--')};
		for(Schema.PicklistEntry pe : Account.Account_Sales_Channel__c.getDescribe().getPicklistValues())
			l.add(new SelectOption(pe.getLabel(), pe.getLabel()));
		l.sort();
		return l;
	}*/
    
    public void search(){
    	if(fromLoc.Owner__c == null && fromPartner.Partner__c == null && fromCAM.UserId == null)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You must select an account Owner, Partner or CAM to transfer from.'));
		else{
			nameContains = nameContains != null ? nameContains.replace('\'', '').replace('%', '') : '';
			
			try{
				aMap.clear();
				sMap.clear();
				
				List<String> whereClause = new List<String>();
				
				Set<Id> accountsWithCAM = new Set<Id>();
				if(fromCAM.UserId != null){
					for(AccountTeamMember atm : [select AccountId from AccountTeamMember where UserId =: fromCAM.UserId and TeamMemberRole in: ICCWrapper.CamTeamMemberRoles limit 40000])
						accountsWithCAM.add(atm.AccountId);
					whereClause.add('(Customer_Detail__r.Customer_Account_Manager__c=\'' + fromCAM.UserId + '\' or Id in: accountsWithCAM)');
				}
				
				Set<Id> accountsWithPartner = new Set<Id>();
				if(fromPartner.Partner__c != null){
					for(Account_Partner__c ap : [select Account__c from Account_Partner__c where Partner__c =: fromPartner.Partner__c and RecordType.DeveloperName in: ICCWrapper.PartnerAgentTypes limit 40000])
						accountsWithPartner.add(ap.Account__c);
					whereClause.add('Id in: accountsWithPartner');
				}
				
				if(fromLoc.Owner__c != null) whereClause.add('Owner.Id = \'' + fromLoc.Owner__c + '\'');
				if(currentAcountOnly) whereClause.add('Id =\'' + fromAccount.Id + '\'');
				if(toAccount.ParentId != null) whereClause.add('Id=\'' + toAccount.ParentId + '\'');
				if(!string.IsEmpty(nameContains)) whereClause.add('Name like \'%' + nameContains + '%\'');
				whereClause.add('RecordType.Name not in (\'Agency\', \'System\')');
				
				Map<Id, accountWrapper> accountsByDetailId = new Map<Id, accountWrapper>();
				//for(Account a : (List<Account>) Database.query('select Id, Name, Owner.Id, Owner.Name, Customer_Detail__c, ICC_Account_Number__c, Account_Sales_Channel__c, Dual_Ownership__c, Parent.Name, Parent.Id from Account'
				for(Account a : (List<Account>) Database.query('select Id, Name, Owner.Id, Owner.Name, Customer_Detail__c, ICC_Account_Number__c, Dual_Ownership__c, Parent.Name, Parent.Id from Account'
																+ ' where ' + String.join(whereClause, ' and ')
																+ ' limit 200')){
					accountWrapper aw = new accountWrapper(a);
					if(a.Customer_Detail__c != null)
						accountsByDetailId.put(a.Customer_Detail__c, aw);
					aMap.put(a.Id, aw);
				}
				
				Set<Id> accountIDs = new Set<Id>(aMap.keySet());
				if((fromLoc.Owner__c != null || fromPartner.Partner__c != null) && toCAM.UserId == null){
					whereClause.clear();
					if(fromLoc.Owner__c != null) whereClause.add('Owner__c = \'' + fromLoc.Owner__c + '\'');
					if(currentAcountOnly) whereClause.add('Account__c =\'' + fromAccount.Id + '\'');
					if(toAccount.ParentId != null) whereClause.add('Account__r.Id=\'' + toAccount.ParentId + '\'');
					if(!string.IsEmpty(nameContains)) whereClause.add('Name like \'%' + nameContains + '%\'');
					if(fromPartner.Partner__c != null) whereClause.add('Account__c in: accountsWithPartner');
					if(fromCAM.UserId != null) whereClause.add('(Customer_Detail__r.Customer_Account_Manager__c=\'' + fromCAM.UserId + '\' or Account__c in: accountsWithCAM)');
					whereClause.add('Account__r.RecordType.Name not in (\'Agency\', \'System\')');
					
					for(Service_Location__c s : (List<Service_Location__c>) Database.query('select Id, Name, Owner__r.Id, Owner__r.Name, Parent_Service_Location__r.Id, Parent_Service_Location__r.Name'
																							+ ', Customer_Detail__c, ICC_Subscriber_ID__c, Account__r.Name, Account__r.Id, Account__r.Dual_Ownership__c from Service_Location__c'
																							+ ' where ' + String.join(whereClause, ' and ')
																							 + ' limit 200')){
						serviceLocationWrapper sw = new serviceLocationWrapper(s);
						if(s.Customer_Detail__c != null && accountsByDetailId.get(s.Customer_Detail__c) != null){
							accountWrapper aw = accountsByDetailId.get(s.Customer_Detail__c);
							aw.matchingRecord = sw;
							sw.matchingRecord = aw;
						}
						sMap.put(s.Id, sw);
						accountIDs.add(s.Account__c);
					}
				}
				
				Map<Id, AccountTeamMember> cams = new Map<Id, AccountTeamMember>();
				for(AccountTeamMember atm : [select AccountId, TeamMemberRole, User.Id, User.Name, User.Title from AccountTeamMember where AccountId in: accountIDs and TeamMemberRole in: ICCWrapper.CamTeamMemberRoles])
					cams.put(atm.AccountId, atm);
				
				Map<Id, Account_Partner__c> aps = new Map<Id, Account_Partner__c>();
				for(Account_Partner__c ap : [select Account__c, Partner__r.Id, Partner__r.Name, RecordType.DeveloperName from Account_Partner__c where Account__c in: accountIDs and RecordType.DeveloperName in: ICCWrapper.PartnerAgentTypes])
					aps.put(ap.Account__c, ap);
				
				for(accountWrapper a : aMap.values()){
					a.setCAM(cams.get(a.obj.Id));
					a.partner = aps.get(a.obj.Id);
				}
				
				for(serviceLocationWrapper s : sMap.values()){
					s.setCAM(cams.get(s.obj.Account__c));
					s.partner = aps.get(s.obj.Account__c);
				}
				
				updateCanTransfer();
			}
			catch(Exception e){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'An error occurred while executing the search criteria: ' + e.getMessage()));
			}
		}
		
		totalRecords = accounts.size() + sLocs.size();
    }
    
    public void ownerChanged(){
    	updateCanTransfer();
    }
    
    private void updateCanTransfer(){
    	if(toLoc.Owner__c != null){
    		User toOwner = [select Id, Name, ProfileId from User where Id = :toLoc.Owner__c];
    		
    		Boolean canAccessAccounts = false;
    		Boolean canAccessServiceLocations = false;
    		for(ObjectPermissions op : [select Id, sObjectType, PermissionsRead from ObjectPermissions where ParentId in (select Id from PermissionSet where ProfileId =: toOwner.ProfileId) and sObjectType in ('Account', 'Service_Location__c')]){
    			if(op.sObjectType == 'Account')
    				canAccessAccounts = op.PermissionsRead;
    			if(op.sObjectType == 'Service_Location__c')
    				canAccessServiceLocations = op.PermissionsRead;
    		}
    		
			Map<Id, Id> accountMatchingLocMap = new Map<Id, Id>();
			for(accountWrapper a : aMap.values())
				a.canTransfer = canAccessAccounts;
			for(serviceLocationWrapper s : sMap.values()){
				s.canTransfer = canAccessServiceLocations && s.obj.Account__r.Dual_Ownership__c;
				if(s.matchingRecord != null)
					accountMatchingLocMap.put(((accountWrapper)s.matchingRecord).obj.Id, s.obj.Id);
			}
			
			Set<Id> accountIDs = new Set<Id>(aMap.keyset());
			accountIDs.addAll(accountMatchingLocMap.keyset());
			if(accountIDs.size() > 0){
				for(UserRecordAccess ura : [select RecordId, HasTransferAccess from UserRecordAccess where UserId = :UserInfo.getUserId() and RecordId in :accountIDs]){
					accountWrapper a = aMap.get(ura.RecordId);
					if(a != null) a.canTransfer &= ura.HasTransferAccess;
					
					Id sLocId = accountMatchingLocMap.get(ura.RecordId);
					if(sLocId != null) sMap.get(sLocId).canTransfer &= ura.HasTransferAccess;
				}
			}
    	}
    	else{
			for(accountWrapper a : aMap.values())
				a.canTransfer = true;
			for(serviceLocationWrapper s : sMap.values())
				s.canTransfer = true;
    	}
    	
    	transferableRecordCount = 0;
		for(accountWrapper a : aMap.values()){
			if(a.canTransfer)
				transferableRecordCount++;
		}
		for(serviceLocationWrapper s : sMap.values()){
			if(s.canTransfer)
				transferableRecordCount++;
		}
    	
		accounts = aMap.values();
		sLocs = sMap.values();
    }
    
    public PageReference transferOwnership(){
    	
    	if(toLoc.Owner__c == null && toPartner.Partner__c == null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You must select an Owner or Partner to transfer to.'));
			return null;
    	}
    	else if(toLoc.Owner__c != null && toLoc.Owner__c == fromLoc.Owner__c){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You can\'t transfer ownership from a user to themselves.'));
			return null;
    	}

    	Map<Id, Account> selectedAccounts = new Map<Id, Account>();
    	Map<Id, Service_Location__c> selectedLocs = new Map<Id, Service_Location__c>();
    	
    	for(accountWrapper a : accounts){
    		if(a.selected && (toLoc.Owner__c == null || a.canTransfer))
				selectedAccounts.put(a.obj.Id, a.obj);
    	}
    	
    	for(serviceLocationWrapper s : sLocs){
    		if(s.selected && (toLoc.Owner__c == null || s.canTransfer))
				selectedLocs.put(s.obj.Id, s.obj);
    	}
    	
		system.debug('Selected accounts: ' + selectedAccounts.values());
		system.debug('Selected service locations: ' + selectedLocs.values());
		
		Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
		List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();
		if(toLoc.Owner__c != null && selectedAccounts.size() > 0){
			for(Opportunity opp :(List<Opportunity>)Database.query('select Id, OwnerId, Account.OwnerId from Opportunity where AccountId in (\'' + string.join(new List<Id>(selectedAccounts.keyset()), '\',\'') + '\')'
																	+ ' and StageName != \'' + OpportunityUtils.STAGE_CONTRACT_SIGNED + '\' and StageName != \'' + OpportunityUtils.STAGE_CLOSED_WON + '\' and StageName != \'' + OpportunityUtils.STAGE_4 + '\' and StageName != \'' + OpportunityUtils.STAGE_5 + '\' and StageName != \'' + OpportunityUtils.STAGE_CLOSED_LOST + '\'')){
				if(opp.OwnerId == opp.Account.OwnerId)
					opps.put(opp.Id, opp);
			}
			
			if(opps.size() > 0){
				system.debug(opps.size() + ' opportunities will be transferred to new owner.');
				if(!keepOppTeams){
					oppTeamMembers = [select Id, OpportunityId from OpportunityTeamMember where OpportunityId in: opps.keyset()];
					system.debug('Opportunity team members will not be kept.');
				}
			}
		}
		
		List<AccountTeamMember> accountTeamMembers = new List<AccountTeamMember>();
		if(!keepAccountTeams){
			accountTeamMembers = [select Id, AccountId from AccountTeamMember where AccountId in: selectedAccounts.keyset() and TeamMemberRole not in: ICCWrapper.CamTeamMemberRoles];
			system.debug('Account team members will not be kept.');
		}

		if(toLoc.Owner__c != null && fromLoc.Owner__c != toLoc.Owner__c){
			system.debug('Ownership will be transferred from ' + fromLoc.Owner__c + ' to ' + toLoc.Owner__c);
			
			for(Service_Location__c s : selectedLocs.values()){
				if(fromLoc.Owner__c == null || s.Owner__c == fromLoc.Owner__c)
					s.Owner__c = toLoc.Owner__c;
			}
			for(Account a : selectedAccounts.values()){
				if(fromLoc.Owner__c == null || a.OwnerId == fromLoc.Owner__c)
					a.OwnerId = toLoc.Owner__c;
			}
		}
		
		List<Account_Partner__c> partners = new List<Account_Partner__c>();
		if(toPartner.Partner__c != null && fromPartner.Partner__c != toPartner.Partner__c){
			system.debug('Partnership will be transferred from ' + fromPartner.Partner__c + ' to ' + toPartner.Partner__c);
			Id icciSell = [select Id from RecordType where sObjectType = 'Account_Partner__c' and DeveloperName = 'ICC_iSell_Assignment'].Id;
			for(Account a : selectedAccounts.values()){
				Account_Partner__c currentPartner = null;
		    	for(accountWrapper aw : accounts){
		    		if(aw.obj.Id == a.Id) currentPartner = aw.partner;
		    	}
				
				if(fromPartner.Partner__c == null || (currentPartner != null && fromPartner.Partner__c == currentPartner.Id)){
					Account_Partner__c p = new Account_Partner__c(Account__c = a.Id, Partner__c = toPartner.Partner__c);
					if(currentPartner != null) p.Id = currentPartner.Id;
					else p.RecordTypeId = icciSell;
					partners.add(p);
				}
			}
		}
		
	/*	if(toAccount.Account_Sales_Channel__c != null){
			for(Account a : selectedAccounts.values())
				a.Account_Sales_Channel__c = toAccount.Account_Sales_Channel__c;
		}*/
		
		Set<Id> accountIDs = new Set<Id>();
		Set<Id> erroredIds = new Set<Id>();
		for(Database.SaveResult result : Database.Update(selectedLocs.values(), false)){
			if(!result.isSuccess()) erroredIds.add(result.Id);
			else accountIDs.add(selectedLocs.get(result.Id).Account__c);
		}
		
		//Let service locs recalc because they can only be changed at a dual-ownership owner level
		Batch_CalculateAccountOwnership.Recalculating = true;
		for(Database.SaveResult result : Database.Update(selectedAccounts.values(), false)){
			if(!result.isSuccess()) erroredIds.add(result.Id);
			else accountIDs.add(result.Id);
		}
		
		if(opps.size() > 0){
			/*Set<Id> oppIDs = new Set<Id>();
			List<Opportunity> saveOpps = new List<Opportunity>();
			for(Id id: opps.keyset()){
				Opportunity o = opps.get(id);
				if(!erroredIds.contains(o.AccountId)){
					oppIDs.add(o.Id);
					saveOpps.add(o);
				}
			}
			Database.Update(saveOpps, false);*/
			
			if(oppTeamMembers.size() > 0){
				List<OpportunityTeamMember> otms = new List<OpportunityTeamMember>();
				for(OpportunityTeamMember otm : oppTeamMembers){
					//if(oppIDs.contains(otm.OpportunityId))
						otms.add(otm);
				}
				Database.Delete(otms, false);
			}
		}
		
		if(partners.size() > 0){
			List<Account_Partner__c> savePartners = new List<Account_Partner__c>();
			for(Account_Partner__c p : partners){
				if(!erroredIds.contains(p.Account__c)){
					savePartners.add(p);
					accountIDs.add(p.Account__c);
				}
			}
			Database.Update(savePartners, false);
		}
		
		if(accountTeamMembers.size() > 0){
			List<AccountTeamMember> atms = new List<AccountTeamMember>();
			for(AccountTeamMember atm : accountTeamMembers){
				if(!erroredIds.contains(atm.AccountId))
					atms.add(atm);
			}
			Database.Delete(atms, false);
		}
		
		Batch_CalculateAccountOwnership.Recalculating = false;
		Batch_CalculateAccountOwnership.RecalculateAccounts(accountIDs);
		
		SendTransferEmail(toLoc.Owner__c, false, selectedAccounts.keyset(), selectedLocs.keyset());
		search();
		
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Ownership transfer complete!'));
		return ApexPages.currentPage();
    }
    
    public PageReference transferCAM(){
		
    	if(toCAM.UserId == null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You must select a user to transfer to.'));
			return null;
    	}
		
		Map<Id, Customer_Detail__c> customerDetails = new Map<Id, Customer_Detail__c>();
    	Set<Id> selectedAccountIDs = new Set<Id>();
    	for(accountWrapper a : accounts){
    		if(a.selected){
				selectedAccountIDs.add(a.obj.Id);
				if(a.obj.Customer_Detail__c != null) customerDetails.put(a.obj.Customer_Detail__c, null);
			}
    	}
		
		for(Service_Location__c sLoc : [select Id, Customer_Detail__c from Service_Location__c where Account__c in: selectedAccountIDs and Customer_Detail__c != null])
			customerDetails.put(sLoc.Customer_Detail__c, null);
		
		customerDetails = new Map<Id, Customer_Detail__c>([select Id from Customer_Detail__c where Id in: customerDetails.keyset() and Customer_Account_Manager__c !=: toCAM.UserId]);
		for(Customer_Detail__c cd : customerDetails.values())
			cd.Customer_Account_Manager__c = toCAM.UserId;
		Database.Update(customerDetails.values(), false);
		
		//Delete CAMs that are not the user we're trying to insert (so we keep their share level)
		List<AccountTeamMember> existingCAMs = [select Id from AccountTeamMember where AccountId in: selectedAccountIDs and (UserId =: toCAM.UserId or TeamMemberRole in: ICCWrapper.CamTeamMemberRoles)];
		Database.Delete(existingCAMs, false);
		
		List<AccountTeamMember> newCAMs = new List<AccountTeamMember>();
		List<AccountShare> newShares = new List<AccountShare>();
		for(Id aID : selectedAccountIDs){
			newCAMs.add(new AccountTeamMember(AccountId = aID
												,UserId = toCAM.UserId
												,TeamMemberRole = toCAM.TeamMemberRole));
			newShares.add(new AccountShare(AccountId = aID
											,UserOrGroupId = toCAM.UserId
											,AccountAccessLevel = 'Edit'
											,OpportunityAccessLevel = 'Edit'));
		}
		
		Database.Insert(newCAMs, false);
		Database.Insert(newShares, false);
		
		SendTransferEmail(toCAM.UserId, true, selectedAccountIDs, null);
		search();
		
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'CAM transfer complete!'));
		return ApexPages.currentPage();
	}
	
	public static void SendTransferEmail(Id newOwnerId, Boolean camMode, Set<Id> accountIDs, Set<Id> sLocIDs){
		if(newOwnerId == null) return;
		
		accountIDs = accountIDs != null ? accountIDs : new Set<Id>();
		sLocIDs = sLocIDs != null ? sLocIDs : new Set<Id>();
		
		User u = [select Id, Email from User where Id =: newOwnerId limit 1];
		
		String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
		List<string> messages = new List<string>();
		for(Account a : [select Id, Name from Account where Id in: accountIDs])
			messages.add('<a href="' + baseURL + '/' + string.valueOf(a.Id) + '">' + a.Name.escapeHtml4() + '</a>');
		
		for(Service_Location__c s : [select Id, Name from Service_Location__c where Id in: sLocIDs])
			messages.add('<a href="' + baseURL + '/' + string.valueOf(s.Id) + '">' + s.Name.escapeHtml4() + '</a>');
		
		if(messages.size() > 0){
			Messaging.SingleEmailMessage m = ApexUtils.createEmailMessage(new String[]{u.Email}, null,
												String.format('{0} transfer notification', new List<String>{ (camMode ? 'Customer Account Management' : 'Account Ownership') }),
												'<table>'
												+ '<tr><td>The following' + (accountIDs.size() > 0 ? (' accounts' + (sLocIDs.size() > 0 ? ' and' : '')) : '') + (sLocIDs.size() > 0 ? ' locations' : '') + ' have been transferred to you:</td></tr>'
												+ '<tr><td></td></tr>'
												+ '<tr><td>' + String.join(messages, '</td></tr><tr><td>') + '</td></tr>'
												+ '</table>', true, null);
			if(!Test.isRunningTest())
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { m });
		}
	}
    
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_AccountTransfer(); }
}