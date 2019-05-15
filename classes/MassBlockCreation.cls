public with sharing class MassBlockCreation implements TestUtils.ITestableClass{
	
	public String orderId;
	public List<wsWrapper> wsWrapperList { get; set; }
	public List<Workstep__c> wStep {get; set;}
	public Workstep_Issue__c dummyWSI { get; set; }
	 
	public MassBlockCreation() {
		dummyWSI = new Workstep_Issue__c();
		orderId = ApexPages.currentPage().getParameters().get('id');
		wsWrapperList = new List<wsWrapper>();
		List<Sub_Order__c> so = new List<Sub_Order__c>();
		so = [Select Id From Sub_Order__c Where Order__c =: orderId];
		wStep = Database.query(
			'SELECT Id, Name, Sub_Order__r.Service_Location__r.Name, Sub_Order__r.Service_Location__r.Account__r.Name, Sub_Order__r.External_Products__c, Sub_Order__r.Name, Sub_Order__r.External_Order__r.Name, Order__r.Name, Owner.Name, Order__r.OwnerId, Status__c ' +
			'FROM Workstep__c '+
			'WHERE Sub_Order__c IN:so And Duration__c !=0  AND (Status__c =\'Open\' OR Status__c = \'Blocked\') '+			
			' ORDER BY ' + sortOrder);

		for(Workstep__c works : wStep){ 			      													
			wsWrapperList.add(new wsWrapper(works, false));
		}
	}
	
	public PageReference Save() {
		return SaveAction(new PageReference('/' + orderId));
	}
	
	public PageReference Cancel() {
		return new PageReference('/' + orderId);
	}
	
	public PageReference QuickSave() {
		PageReference pageReference = Page.MassBlockCreation;
        pageReference.getParameters().put('Id', orderId);
        pageReference.setRedirect(true);
		return SaveAction(PageReference);		
	}

	public PageReference ExitSave() {
		return SaveAction(new PageReference('/' + orderId));
	}
	
	private final Set<String> modifiableFields = new Set<String>{'Risk_Type__c'
																,'Reason__c'
																,'Reason_Subcategory__c'
																,'Expected_Follow_Up_Date__c'
																,'Comments__c'
																,'OwnerId'};
	public PageReference SaveAction(PageReference pageRef) {
		List<Workstep_Issue__c> wsiForInsert = new List<Workstep_Issue__c>();
		List<Workstep__c> sWorksteps = new List<Workstep__c>();
		Boolean anyChecked = false;
		try {
			List<String> errors = new List<String>();
			
			if (string.IsEmpty(dummyWSI.Risk_Type__c))
				errors.add('RespOrg: You must enter a value');
			if (dummyWSI.OwnerId == null)
				errors.add('Owner: You must enter a value');
			if (string.IsEmpty(dummyWSI.Comments__c))
				errors.add('Comments: You must enter a value');
			if(dummyWSI.Expected_Follow_Up_Date__c == null)
				errors.add('You must enter an expected follow up date');
			for (wsWrapper wss : wsWrapperList) {
				if (wss.isSelected) 
					anyChecked = true;
			}
			if(!anyChecked)
				errors.add('Please check at least 1 checkbox to create Workstep Issues for!');
			if (errors.size() > 0) {
				system.debug('errors: ' + errors);
				for(String error : errors)
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, error));
				return null;
			}
			
		} 
		catch (DMLException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
			return null;
		}
		for (wsWrapper wss : wsWrapperList) {
			if (wss.isSelected) 
				sWorksteps.add(wss.ws);
		}
		try{
			if (sWorksteps.size() > 0){
				for(Workstep__c work : sWorksteps){ 
					Workstep_Issue__c wsiTemplate = new Workstep_Issue__c();	
					wsiTemplate.Risk_Type__c = dummyWSI.Risk_Type__c;
					wsiTemplate.Reason__c = dummyWSI.Reason__c;
					wsiTemplate.Reason_Subcategory__c = dummyWSI.Reason_Subcategory__c;
					wsiTemplate.Expected_Follow_Up_Date__c = dummyWSI.Expected_Follow_Up_Date__c;
					wsiTemplate.Comments__c = dummyWSI.Comments__c;
					wsiTemplate.OwnerId = dummyWSI.OwnerId;
					wsiTemplate.Carrier__c = dummyWSI.Carrier__c;
					wsiTemplate.Status__c = 'Open';
					wsiTemplate.Workstep__c = work.Id;
					wsiForInsert.add(wsiTemplate);						
				}							
				insert wsiForInsert;
			}
		}
		catch(Exception e){			
			return null;
		}
		if(wsiForInsert.size() > 0)
			sendEmail(wsiForInsert);

		return pageRef;
	}

	public class wsWrapper {
		public Workstep__c ws { get; set; }
		public Workstep__c wsOld { get; set; }
		public boolean isSelected { get; set; }
		
		public wsWrapper(Workstep__c ws, boolean isSelected) {
			this.ws = ws;
			this.wsOld = ws.clone();
			this.isSelected = isSelected;
		}
	}
	private void sendEmail(List<Workstep_Issue__c> wsiForInsert) {
		List<Messaging.SingleEmailMessage> listmail = new List<Messaging.SingleEmailMessage> ();
		User wsUser = [SELECT Id, Email, IsActive FROM User WHERE Id = :dummyWSI.OwnerId];
		List<Workstep_Issue__c> emailToSend = [SELECT Id, OwnerId FROM Workstep_Issue__c WHERE OwnerId = :dummyWSI.OwnerId AND Status__c = :'Open' AND Expected_Follow_Up_Date__c = :dummyWSI.Expected_Follow_Up_Date__c AND Risk_Type__c = :dummyWSI.Risk_Type__c AND Reason__c = :dummyWSI.Reason__c];
		for (Workstep_Issue__c ets : emailToSend) {
			String objName = SchemaUtils.GetSObjectNameByID(ets.Id);
		String emailBody = (objName == 'Workstep__c') 
								? 'Workstep has been assigned to you. Please click on the link below to view the record. \n\n'
								: 'Workstep Issue has been created. Please click on the link below to view the record. \n\n';
			emailBody += URL.getSalesforceBaseUrl().toExternalForm() + '/' + ets.Id + '\n\n';
			String objOwn = SchemaUtils.GetSObjectNameByID(dummyWSI.OwnerId);
			if (objOwn == 'User') {
				Messaging.SingleEmailMessage m = ApexUtils.createEmailMessage(new String[] { wsUser.Email }
																								,null
																								,(objName == 'Workstep__c') ? 'Workstep assigned to you.' : 'Workstep Issue has been created.'
																								,emailBody
																								,false
				                                                              , UserInfo.getUserEmail());

				listmail.add(m);
			}
		}
		if (!Test.isRunningTest())
			ApexUtils.sendEmails(listmail);
	}

	public String sortColumn { get; set; }
    private String sortOrder = 'Sub_Order__c ASC';
    private Boolean ordinal = true;
     public void sortResults() {  
         if ( this.sortOrder != sortColumn + ' ASC') {
                   this.sortOrder = sortColumn + ' ASC' ;
                    }
                else {
                    this.sortOrder = sortColumn + ' DESC';
					ordinal = false;
                }

        wStep = ApexUtils.sortByComparableField(wStep, sortColumn, ordinal, true);

		wsWrapperList.clear();
		for(Workstep__c works : wStep){ 			      													
			wsWrapperList.add(new wsWrapper(works, false));
		}
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_MassBlockCreation(); }
}