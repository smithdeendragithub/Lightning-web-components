public with sharing class MassBlockManagement implements TestUtils.ITestableClass {

	public String orderId;
	public List<wsiWrapper> wsiWrapperList { get; set; }
	public Workstep_Issue__c dummyWSI { get; set; }
	public boolean sendNotification { get; set; }
	public List<Workstep_Issue__c> iss { get; set; }
	public List<Sub_Order__c> so { get; set; }
	public MassBlockManagement() {
		dummyWSI = new Workstep_Issue__c();
		orderId = ApexPages.currentPage().getParameters().get('id');
		wsiWrapperList = new List<wsiWrapper> ();
		String status = 'Open';
		so = new List<Sub_Order__c> ([Select Id From Sub_Order__c Where Order__c = :orderId]);
		sObjectType objType = Workstep_Issue__c.getsObjectType();

		iss = [Select Workstep__r.Sub_Order__r.Name, Workstep__r.Name, Name, Risk_Type__c, Reason__c, Reason_Subcategory__c,
		       Expected_Follow_Up_Date__c, Estimated_Resolution__c, Current_Action__c, Carrier__c, Owner.Name, OwnerId
		       FROM Workstep_Issue__c Where Workstep__r.Sub_Order__c IN :so AND Status__c = :'Open'];
		for (Workstep_Issue__c wsi : iss) {
			wsiWrapperList.add(new wsiWrapper(wsi, false));
		}
	}

	public PageReference Save() {
		return SaveAction(new PageReference('/' + orderId));
	}

	public PageReference Cancel() {
		return new PageReference('/' + orderId);
	}

	public PageReference QuickSave() {
		PageReference pageReference = Page.MassBlockManagement;
		pageReference.getParameters().put('Id', orderId);
		pageReference.setRedirect(true);
		return SaveAction(PageReference);
	}

	public PageReference ExitSave() {
		return SaveAction(new PageReference('/' + orderId));
	}

	private final Set<String> modifiableFields = new Set<String> { 'Risk_Type__c'
		, 'Reason__c'
		, 'Reason_Subcategory__c'
		, 'Expected_Follow_Up_Date__c'
		, 'Estimated_Resolution__c'
		, 'Current_Action__c'
		, 'OwnerId' };
	public PageReference SaveAction(PageReference pageRef) {
		Boolean anyChecked = false;
		sendNotification = false;
		try {
			List<String> errors = new List<String> ();

			for (wsiWrapper wss : wsiWrapperList) {
				if (wss.isSelected)
				anyChecked = true;
			}
			if (!anyChecked)
			errors.add('Please check at least 1 checkbox to perform updates on!');
			if (errors.size() > 0) {
				system.debug('errors: ' + errors);
				for (String error : errors)
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, error));
				return null;
			}

		}
		catch(DMLException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage()));
			return null;
		}
		List<Workstep_Issue__c> wsiForUpdate = new List<Workstep_Issue__c> ();
		List<Workstep_Issue__c> sWSI = new List<Workstep_Issue__c> ();
		Map<Id, Workstep_Issue__c> wsiDummyMap = new Map<Id, Workstep_Issue__c> ();
		Set<Id> emailIds = new Set<Id> ();
		for (wsiWrapper wsis : wsiWrapperList) {
			Boolean updated = false;
			for (String f : modifiableFields) {
				if (wsis.isSelected) {
					updated = updated || wsis.wsi.get(f) != wsis.wsiOld.get(f);
					if (f == 'OwnerId' && wsis.wsi.get(f) != wsis.wsiOld.get(f) && sendNotification) {
						emailIds.add(wsis.wsi.OwnerId);
					}
				}
			}
			if (updated) {
				wsis.isSelected = false;
				wsiForUpdate.add(wsis.wsi);
			}
			else {
				if (wsis.isSelected) {
					wsis.isSelected = false;
					sWSI.add(wsis.wsi);
				}
				if (sWSI.size() > 0) {
					for (Workstep_Issue__c work : sWSI) {
						Workstep_Issue__c tWSI = wsiDummyMap.get(work.Id);
						if (tWSI == null) {
							work.Risk_Type__c = dummyWSI.Risk_Type__c != null ? dummyWSI.Risk_Type__c : work.Risk_Type__c;
							work.Carrier__c = dummyWSI.Carrier__c != null ? dummyWSI.Carrier__c : work.Carrier__c;
							work.Reason__c = dummyWSI.Reason__c != null ? dummyWSI.Reason__c : work.Reason__c;
							work.Reason_Subcategory__c = dummyWSI.Reason_Subcategory__c != null ? dummyWSI.Reason_Subcategory__c : work.Reason_Subcategory__c;
							work.Expected_Follow_Up_Date__c = dummyWSI.Expected_Follow_Up_Date__c != null ? dummyWSI.Expected_Follow_Up_Date__c : work.Expected_Follow_Up_Date__c;
							work.Estimated_Resolution__c = dummyWSI.Estimated_Resolution__c != null ? dummyWSI.Estimated_Resolution__c : work.Estimated_Resolution__c;
							work.OwnerId = dummyWSI.OwnerId != null ? dummyWSI.OwnerId : work.OwnerId;
							work.Current_Action__c = dummyWSI.Current_Action__c != null ? work.Current_Action__c != null ? dummyWSI.Current_Action__c + '\n' + work.Current_Action__c : dummyWSI.Current_Action__c : work.Current_Action__c;
							wsiDummyMap.put(work.Id, work);

							if (work.OwnerId != dummyWSI.OwnerId && sendNotification)
							emailIds.add(dummyWSI.OwnerId);
						}
					}

				}
			}

		}
		try {
			for (Workstep_Issue__c wI : wsiDummyMap.values()) {
				wsiForUpdate.add(wI);
			}

			update wsiForUpdate;
		}
		catch(Exception e) {
			return null;
		}
		if (emailIds.size() > 0)
		getEmail(emailIds, wsiForUpdate);

		return pageRef;
	}

	public class wsiWrapper extends ApexUtils.SortableClass {
		public Workstep_Issue__c wsi { get; set; }
		public Workstep_Issue__c wsiOld { get; set; }
		public boolean isSelected { get; set; }

		public wsiWrapper(Workstep_Issue__c wsi, boolean isSelected) {
			this.wsi = wsi;
			this.wsiOld = wsi.clone();
			this.isSelected = isSelected;
		}
	}

	private void getEmail(Set<Id> eml, List<Workstep_Issue__c> wsiForUpdate) {
		List<Messaging.SingleEmailMessage> listmail = new List<Messaging.SingleEmailMessage> ();
		List<User> wsUsers = [SELECT Id, Email, IsActive FROM User WHERE Id IN :eml];
		List<Workstep_Issue__c> emailToSend = [SELECT Id, OwnerId FROM Workstep_Issue__c WHERE Id IN :wsiForUpdate];
		for (Workstep_Issue__c ets : emailToSend) {
			String objName = SchemaUtils.GetSObjectNameByID(ets.Id);
			String emailBody = (objName == 'Workstep__c')
			? 'Workstep has been assigned to you. Please click on the link below to view the record. \n\n'
			: 'Workstep Issue has been created. Please click on the link below to view the record. \n\n';
			emailBody += URL.getSalesforceBaseUrl().toExternalForm() + '/' + ets.Id + '\n\n';
			String objOwn = SchemaUtils.GetSObjectNameByID(ets.OwnerId);
			if (objOwn == 'User') {
				for (User u : wsUsers) {
					if (u.Id == ets.OwnerId) {
						Messaging.SingleEmailMessage m = ApexUtils.createEmailMessage(new String[] { u.Email }
						                                                              , null
						                                                              , (objName == 'Workstep__c') ? 'Workstep assigned to you.' : 'Workstep Issue has been created.'
						                                                              , emailBody
						                                                              , false
						                                                              , UserInfo.getUserEmail());

						listmail.add(m);
					}
				}
			}
		}
		if (!Test.isRunningTest())
			ApexUtils.sendEmails(listmail);
	}

	public String sortColumn { get; set; }
	private String sortOrder = 'Sub_Order__c ASC';
	public List<Workstep_Issue__c> wIss = new List<Workstep_Issue__c> ();
	private Boolean ordinal = true;
	public void sortResults() {
		if (this.sortOrder != sortColumn + ' ASC') {
			this.sortOrder = sortColumn + ' ASC';
		}
		else {
			this.sortOrder = sortColumn + ' DESC';
			ordinal = false;
		}
		List<Id> sid = new List<Id> ();
		for (Sub_Order__c soi : so) {
			sid.add(soi.Id);
		}

		String query = 'Select Workstep__r.Sub_Order__r.Name, Workstep__r.Name, Name, Risk_Type__c, Reason__c, Reason_Subcategory__c, ' +
		'Expected_Follow_Up_Date__c, Estimated_Resolution__c, Current_Action__c, Carrier__c, Owner.Name, OwnerId ' +
		'FROM Workstep_Issue__c ' +
		'Where Workstep__r.Sub_Order__c IN: sid  AND Status__c = \'Open\' ' +
		'Order By ' + this.sortOrder;
		wIss = database.query(query);
		wsiWrapperList.clear();
		for (Workstep_Issue__c works : wIss) {
			wsiWrapperList.add(new wsiWrapper(works, false));
		}
	}

	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass() { return new Test_MassBlockManagement(); }
}