public virtual class WorkflowAssignmentControllerBase {
	
	public virtual class sObjectWrapper {
		public boolean isSelected { get; set; }
		public sObject sObj {get; set;}
		
		public sObjectWrapper(){}
		public sObjectWrapper(sObject sObj, Boolean isSelected){
			this.sObj = sObj;
			this.isSelected = isSelected;
		}
		
		public virtual List<sObjectWrapper> getSubWrapperLists(){ return new List<sObjectWrapper>(); }
	}
	
	public Schema.sObjectType sObjType { get; set; }
	
	public boolean isError { get; set; }
	public String listViewURL;
	public sObject dummySObject { get; set; }
	public boolean sendNotification { get; set; }
	
	public virtual string emailSubject() { 
		return sObjType.getDescribe().getLabelPlural() + ' assigned to you';
	}
	
	//0 - object name, 1 - object id, 2 - SFDC base url, 
	public virtual string emailBodyTemplate() {
		return sObjType.getDescribe().getLabel() + ' {0} has been assigned to you. Please click on the link below to view the record. \n{2}/{1}\n\n';
	}
	
	public virtual List<sObjectWrapper> getWrapperCollection() {
		return new List<sObjectWrapper>();
	}
	
	public List<sObject> getRecords(ApexPages.StandardSetController sc){
		return !test.IsRunningTest() ? sc.getSelected() : sc.getRecords();
	}
	
	public String getListViewURL(ApexPages.StandardSetController sc, String ObjectName, String ListViewLabel){
		List<SelectOption> ListViews = sc.getListViewOptions();
		for(SelectOption w : ListViews){
			if(w.getLabel() == ListViewLabel)
				return '/' + SchemaUtils.ObjectNamesToIDPrefixes.get(ObjectName) + '?fcf=' + w.getValue().left(15);
		}
		
		return '/' + SchemaUtils.ObjectNamesToIDPrefixes.get(ObjectName) + '?fcf=' + ListViews[0].getValue().left(15);	//Default to the first view
	}
	
	public PageReference SaveAction(String listViewURL, List<sObjectWrapper> wrapperList) {
		try {
			String selectedUser = string.valueOf(dummySObject.get('OwnerId'));
			if (string.isEmpty(selectedUser)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Please select the new owner.'));
				return null;
			}
			
			List<sObject> selectedObjects = new List<sObject>();
			assignOwners(wrapperList, selectedUser, selectedObjects);
			
			if (selectedObjects.size() > 0)
				update selectedObjects;
			if (sendNotification){
				List<User> u = [select Email from User where Id =: selectedUser];
				if(u.size() > 0)
					sendEmail(u[0].Email, selectedObjects);
			}
			
			saveComplete();
		} catch (DMLException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'What?' + e.getMessage()));
			return null;
		}
		
		return listViewURL != null ? new PageReference(listViewURL) : null;
	}
	
	private void assignOwners(List<sObjectWrapper> wl, String selectedUser, List<sObject> selectedObjects){
		for (sObjectWrapper w : wl) {
			if (w.isSelected) {
				w.sObj.put('OwnerId', selectedUser);
				selectedObjects.add(w.sObj);
				assignOwners(w.getSubWrapperLists(), selectedUser, selectedObjects);
			}
		}
	}
	
	public virtual void saveComplete(){ }
	
	public PageReference Save() {
		return SaveAction(listViewURL, getWrapperCollection());
	}
	
	public PageReference Cancel() {
		return new PageReference(listViewURL);
	}
	
	public PageReference QuickSave() {
		return SaveAction(null, getWrapperCollection());
	}
	
	private void sendEmail(String userEmail, List<sObject> objList) {
		String emailBody = '';
		String fullFileURL = URL.getSalesforceBaseUrl().toExternalForm();
		for (sObject sObj : objList)
			emailBody += string.format(emailBodyTemplate(), new List<String>{ string.valueOf(sObj.get('Name')), string.valueOf(sObj.get('Id')), fullFileURL });
		
		if (!Test.isRunningTest())
			ApexUtils.sendEmails(new Messaging.SingleEmailMessage[] {ApexUtils.createEmailMessage(new List<String> {userEmail}, null, emailSubject(), emailBody, false, UserInfo.getUserEmail())});
	}
}