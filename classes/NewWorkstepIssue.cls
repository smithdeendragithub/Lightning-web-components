public with sharing class NewWorkstepIssue {
	
	private static final String BLOCKING_WORKSTEP ='Blocking Workstep';
	
	public Workstep_Issue__c dummyWI { get; set; }
	public String wsId;
	public Workstep__c currentWs {get; set;}
	public String selectedWs { get; set; }
	public Map<Id,Workstep__c> wsMap = new Map<Id,Workstep__c>();
	public Map<Id,Boolean> ownerMap = new Map<Id,Boolean>();
	public List<SelectOption> wsList { get; set; }
	public boolean showWsList { get; set; }
	private Set<Id> ownerIdSet = new Set<Id>();
	private Issue_to_Queue_Mapping__c issueMapping;
	
	public NewWorkstepIssue() {
		dummyWI = new Workstep_Issue__c();
		wsId = ApexPages.currentPage().getParameters().get('id');
		currentWs = [SELECT Id, Name, Sub_Order__r.Service_Location__r.Name, Sub_Order__r.Service_Location__r.Account__r.Name, SPC_Product__c, Sub_Order__r.Name, Order__r.Name, OwnerId, Order__r.OwnerId, Status__c FROM Workstep__c WHERE Id = :wsId];
		wsList = getWorkstepList();
		showWsList = false;
		issueMapping = getIssueMapping();
	}
	
	public Set<Id> getAllPredecessors() {
		Set<Id> predSet = new Set<Id>();
		Set<Id> currentPredSet = new Set<Id>{currentWs.Id};
		
		//todo: verify that we want to do this
		Integer i = 0;
		while (i <= 50 && currentPredSet.size() > 0) {
			List<Predecessor__c> pList = [SELECT Id, Predecessor_Workstep__c, Predecessor_Workstep__r.Name FROM Predecessor__c WHERE Dependent_Workstep__c IN :currentPredSet];
			currentPredSet = new Set<Id>();
			for (Predecessor__c p : pList)
				currentPredSet.add(p.Predecessor_Workstep__c);
			predSet.addAll(currentPredSet);
			i++;
		}
		return predSet;
	}
	
	public List<SelectOption> getWorkstepList() {
		List<SelectOption> options = new List<SelectOption>{new SelectOption('', '--None--')};
		Set<Id> predSet = getAllPredecessors();
		for (Workstep__c ws : [SELECT Id, Name, Owner.Id, Workstep_Library__r.OwnerId FROM Workstep__c WHERE Id IN :predSet]) {
			options.add(new SelectOption(ws.Id, ws.Name));
			ownerIdSet.add(ws.OwnerId);
			wsMap.put(ws.Id,ws);
		}
		return options;
	}
	
	private void getOwnerMap() {
		for (User u : [SELECT Id, Email, IsActive FROM User WHERE Id IN :ownerIdSet])
			ownerMap.put(u.Id, u.IsActive);
		for (Group g : [SELECT Id, Name FROM Group WHERE Id IN :ownerIdSet])
			ownerMap.put(g.Id, true);
	}
	
	public void setOwner() {
		getOwnerMap();
		if (selectedWs != '' && selectedWs != null) 
			dummyWI.OwnerId = (ownerMap.get(wsMap.get(selectedWs).OwnerId)) ? wsMap.get(selectedWs).OwnerId : wsMap.get(selectedWs).Workstep_Library__r.OwnerId;
		else
			dummyWI.OwnerId = (issueMapping.Id != null) ? getCustomSettingQueueId(issueMapping) : null;
	}
	
	private Issue_to_Queue_Mapping__c getIssueMapping() {
		String soql = '';
		soql = 'SELECT Id, Name, Issue_Type__c, Reason__c, Reason_Subcategory__c, Workstep_Attribute__c, Queue__c FROM Issue_to_Queue_Mapping__c';
		soql += ' WHERE Issue_Type__c = \'' + dummyWI.Risk_Type__c + '\'';
		soql += ' AND Reason__c = \'' + dummyWI.Reason__c + '\'';
		if (dummyWI.Reason_Subcategory__c != '' && dummyWI.Reason_Subcategory__c != null)
			soql += ' AND Reason_Subcategory__c = \'' + dummyWI.Reason_Subcategory__c + '\'';
		//soql += ' Limit 1';
		System.debug('soql::::' + soql);
		List<Issue_to_Queue_Mapping__c> issueMapp = database.query(soql);
		if (issueMapp.size() == 1)
			return issueMapp[0];
		return new Issue_to_Queue_Mapping__c();
	}
	
	private String getCustomSettingQueueId(Issue_to_Queue_Mapping__c issueMapping) {
		List<Group> grp = [SELECT Id FROM Group WHERE DeveloperName = :issueMapping.Queue__c AND Type = 'Queue' limit 1];
		return grp.size() > 0 ? grp[0].Id : null;
	}
	
	private List<Workstep__c> getWs(Issue_to_Queue_Mapping__c issueMapping) {
		List<Workstep__c> wsList = new List<Workstep__c>();
		System.debug('issueMapping.Workstep_Attribute__c:::' + issueMapping.Workstep_Attribute__c);
		if (issueMapping.Workstep_Attribute__c != null)
			wsList = (currentWs.Sub_Order__c == null)
						? [SELECT Id, Name, OwnerId, Workstep_Library__r.OwnerId FROM Workstep__c WHERE Attribute__c = :issueMapping.Workstep_Attribute__c AND Order__c = :currentWs.Order__c limit 1]
						: [SELECT Id, Name, OwnerId, Workstep_Library__r.OwnerId FROM Workstep__c WHERE Attribute__c = :issueMapping.Workstep_Attribute__c AND Sub_Order__c = :currentWs.Sub_Order__c limit 1];
		return wsList;
	}
	
	public PageReference saveAction(PageReference pageRef) {
		try {
			List<String> errors = new List<String>();
			
			if (string.IsEmpty(dummyWI.Risk_Type__c))
				errors.add('Type: You must enter a value');
			if ((string.IsEmpty(dummyWI.Carrier__c)) && dummyWI.Risk_Type__c == 'Carrier')
				errors.add('Carrier: You must enter a value');
			if (string.IsEmpty(dummyWI.Reason__c))
				errors.add('Reason: You must enter a value');
			/*if (dummyWI.Status__c == null || dummyWI.Status__c == '')
				errors.add('Status: You must enter a value');*/
			if (dummyWI.OwnerId == null)
				errors.add('Owner: You must enter a value');
			if (string.IsEmpty(dummyWI.Comments__c))
				errors.add('Comments: You must enter a value');
			if (dummyWI.Reason__c == BLOCKING_WORKSTEP && (string.IsEmpty(selectedWs)))
				errors.add('You must choose a blocking workstep.');
			if(dummyWI.Expected_Follow_Up_Date__c == null)
				errors.add('You must enter an expected follow up date');
			if (errors.size() > 0) {
				for(String error : errors)
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, error));
				return null;
			}
			
			issueMapping = getIssueMapping();
			List<Workstep__c> ws = getWs(issueMapping);
			dummyWI.Workstep__c = wsId;
			
			List<Workstep__c> wsForUpdate = new List<Workstep__c>();
			String userEmail;
			if (selectedWs != null && selectedWs != '') {
				dummyWI.Caused_By__c = selectedWs;
				if (wsMap.get(selectedWs).OwnerId != dummyWI.OwnerId) {
					wsMap.get(selectedWs).OwnerId = dummyWI.OwnerId;
					wsForUpdate.add(wsMap.get(selectedWs));
					
					String objName = SchemaUtils.GetSObjectNameByID(dummyWI.OwnerId);
					if (objName == 'User') {
						User wsUser = [SELECT Id, Email, IsActive FROM User WHERE Id = :dummyWI.OwnerId];
						userEmail = wsUser.Email;
						sendEmail(userEmail, selectedWs);
					}
				}
			}
			
			dummyWI.Last_Time_Touched__c = Datetime.now();
System.debug('ownerId:::' + dummyWI.OwnerId);
			insert dummyWI;
			
			Set<String> emailSet = getEmailsWI();
			for (String email : emailSet) {
				if (email != '' && email != null)
					sendEmail(email, dummyWI.Id);
			}
			
			currentWs.Status__c = 'Blocked';
			wsForUpdate.add(currentWs);
					
			if (wsForUpdate.size() > 0)
				update wsForUpdate;
			if (pageRef == null)
				dummyWI = new Workstep_Issue__c(Status__c = 'Open');
		} catch (DMLException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
			return null;
		}
		return pageRef;
	}
	
	private Set<String> getEmailsWI() {
		Set<Id> ownerIds = new Set<Id>();
		ownerIds.add(currentWs.OwnerId);
		
		String objName='';
		objName = SchemaUtils.GetSObjectNameByID(dummyWI.OwnerId);
		if (objName == 'User')
			ownerIds.add(dummyWI.OwnerId);
		
		Set<String> emailSet = new Set<String>();
		for (User u : [SELECT Id, Email, Manager.Email FROM User WHERE Id IN :ownerIds]) {
			emailSet.add(u.Email);
			emailSet.add(u.Manager.Email);
		}
		
		System.debug('emailSet:::' + emailSet);
		return emailSet;
	}
	
	private void sendEmail(String userEmail, String wsId) {
		String objName = SchemaUtils.GetSObjectNameByID(wsId);
		String emailBody = (objName == 'Workstep__c') 
								? 'Workstep has been assigned to you. Please click on the link below to view the record. \n\n'
								: 'Workstep Issue has been created. Please click on the link below to view the record. \n\n';
		emailBody += URL.getSalesforceBaseUrl().toExternalForm() + '/' + wsId + '\n\n';
		
		//mail.setSenderDisplayName(UserInfo.getName());
		if (!Test.isRunningTest())
			ApexUtils.sendEmails(new Messaging.SingleEmailMessage[] {ApexUtils.createEmailMessage(new List<String> {userEmail}
																								,null
																								,(objName == 'Workstep__c') ? 'Workstep assigned to you.' : 'Workstep Issue has been created.'
																								,emailBody
																								,false
																								,UserInfo.getUserEmail())});
	}
	
	public void ChooseDefaultWorkstepForReason() {
		dummyWI.Reason_Subcategory__c = null;
		ChooseDefaultWorkstep();
	}
	
	public void ChooseDefaultWorkstep() {
		if (dummyWI.Risk_Type__c != null && dummyWI.Reason__c != null) {
			issueMapping = getIssueMapping();
			List<Workstep__c> ws = getWs(issueMapping);
			wsList = getWorkstepList();
			if (ws.size() > 0) {
				wsMap.put(ws[0].Id, ws[0]);
				ownerIdSet.add(ws[0].OwnerId);
				wsList.add(new SelectOption(ws[0].Id, ws[0].Name));
				selectedWs = ws[0].Id;
			}
			else
				selectedWs = null;
			
			setOwner();
			showWsList = wsList.size() > 1;
		}
	}
	
	public PageReference Save() {
		return saveAction(new PageReference('/' + wsId));
	}
	
	public PageReference SaveAndNew() {
		return saveAction(null);
	}
	
	public PageReference Cancel() {
		return new PageReference('/' + wsId);
	}
}