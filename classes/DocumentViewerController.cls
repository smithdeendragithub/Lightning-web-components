public with sharing class DocumentViewerController extends RelatedRecordViewerBaseController {
	
	private final Map<String, String> defaultRelatedJSON = new Map<String, String>{
			'Account'=>'[{\'name\':\'Opportunities\',\'related\':[{\'name\':\'PDFs__r\'}]}]'
		};
	
	public class DocumentData extends ApexUtils.SortableClass {
		public String Name { get; set; }
		public String Link { get; set; }
		public String Type { get; set; }
		public String Description { get; set; }
		public String Status { get; set; }
		public String SubscriberID { get; set; }
		public nObject parent { get; set; }
		
		public Datetime EffectiveDate { get; set; }
		public String CreatedBy { get; set; }
		public String CreatedById { get; set; }
		public String Term { get; set; }
		public Datetime ExpirationDate { get; set; }
		
		public DocumentData(){ }
		
		public override object getFieldImp(String fName){
			if(fName == 'Name') return Name;
			if(fName == 'Type') return Type;
			if(fName == 'Description') return Description;
			if(fName == 'Status') return Status;
			if(fName == 'EffectiveDate') return EffectiveDate;
			if(fName == 'CreatedBy') return CreatedBy;
			if(fName == 'Term') return Term;
			if(fName == 'ExpirationDate') return ExpirationDate;
			if(fName == 'ParentName') return parent.name;
			return null;
		}
	}
	
	public ApexUtils.SortableClassConfig sortConfig { get; set; }
	
	public Boolean contractMode { get; set; }
	public Boolean includeChildren { get; set; }
	public Boolean showExpired { get; set; }
	
	public transient List<DocumentData> DocumentList { get; set; }
	
	public DocumentViewerController(){
		contractMode = ApexPages.currentPage().getParameters().get('contractMode') == '1';
		initialize(contractMode || (ApexPages.currentPage().getParameters().get('defaultRelated') == '1') ? defaultRelatedJSON : null);
		
		includeChildren = false;
		showExpired = false;
		sortConfig = new ApexUtils.SortableClassConfig('', 'Type', true);
		
		getDocuments(false);
	}
	
	public void GetDocuments(){
		getDocuments(true);
	}
	
	public void changeSort() {
		String sortColumn = ApexPages.currentPage().getParameters().get('sortColumn');
		sortConfig.changeSort('', sortColumn);
		GetDocuments();
	}
	
	private void getDocuments(Boolean getExternal){
		
		DocumentList = new List<DocumentData>();
		
		if(!reset()) return;
		
		DocumentList = getPDFs();
		DocumentList.addAll(getIntegraContracts());
		if(!contractMode) DocumentList.addAll(getAttachments());
		if(getExternal){
			for(nObject n : nObjects.values()){
				String objName = SchemaUtils.GetSObjectNameByID(n.Id);
				if(objName == 'Account' && n.externalID != null) DocumentList.addAll(getExternalDocumentsByAccountSubscriberID(n.Id, string.valueOf(n.externalID)));
			}
		}
		
		Map<Id, String> createUsers = new Map<Id, String>();
		for(DocumentData d : DocumentList){
			if(d.CreatedById != null) createUsers.put(d.CreatedById, null);
		}
		
		for(User u : [select Id, Name from User where Id in: createUsers.keyset()]) createUsers.put(u.Id, u.Name);
		
		for(DocumentData d : DocumentList){
			if(d.CreatedById != null) d.CreatedBy = createUsers.get(d.CreatedById);
		}
		
		for(Integer i=DocumentList.size()-1; i>=0; i--){
			DocumentData d = DocumentList[i];
			if((!showExpired && (d.Status == 'Expired' || d.Status == 'Inactive' || (d.ExpirationDate != null && d.ExpirationDate <= Datetime.now())))
				|| (StartDate != null && d.EffectiveDate < StartDate)
				|| (EndDate != null && d.EffectiveDate > EndDate))
				DocumentList.remove(i);
		}
		
		ApexUtils.Sort(DocumentList, sortConfig);
	}
	
	//todo: pass in parent or parent/children
	private List<DocumentData> getAttachments(){
		List<DocumentData> docs = new List<DocumentData>();
		for(Attachment att : [select Id
									,Name
									,CreatedDate
									,CreatedById
									,ParentId
								from Attachment where ParentId in: nObjects.keyset()]){
			nObject parentObject = nObjects.get(att.ParentId);
			String parentObjectName = SchemaUtils.GetSObjectNameByID(att.ParentId);
			
			if(parentObjectName != 'Service_Location__c' || includeChildren){
				DocumentData d = new DocumentData();
				d.Name = att.Name;
				d.Parent = nObjects.get(att.ParentId);
				d.Link = '..\\' + att.Id;
				d.Type = parentObjectName == 'dsfs__DocuSign_Status__c' ? 'DocuSigned Attachment' : 'Attachment';
				d.Description = att.Name;
				d.Status = 'Active';
				d.SubscriberID = parentObject.externalID != null ? String.valueOf(parentObject.externalID) : 'N/A';
				d.EffectiveDate = att.CreatedDate;
				d.CreatedById = att.CreatedById;
				d.Term = 'N/A';
				d.ExpirationDate = null;
				docs.add(d);
			}				
		}
		return docs;
	}
	
	private List<DocumentData> getPDFs(){
		List<DocumentData> docs = new List<DocumentData>();
		for(PDF__c pdf : [select Id
								,Name
								,CreatedDate
								,CreatedById
								,Active__c
								,DocuSign_Completed__c
								,Opportunity__c
								from PDF__c where Opportunity__c in: nObjects.keyset()]){
			if(contractMode && !pdf.DocuSign_Completed__c) continue;
			
			DocumentData d = new DocumentData();
			d.Name = pdf.Name;
			d.Parent = nObjects.get(pdf.Opportunity__c);
			d.Link = '..\\' + pdf.Id;
			d.Type = 'PDF';
			d.Description = pdf.Name;
			d.Status = pdf.Active__c ? 'Active' : 'Inactive';
			d.SubscriberID = 'N/A';
			d.EffectiveDate = pdf.CreatedDate;
			d.CreatedById = pdf.CreatedById;
			d.Term = 'N/A';
			d.ExpirationDate = null;
			docs.add(d);
		}
		return docs;
	}
	
	private List<DocumentData> getIntegraContracts(){
		List<DocumentData> docs = new List<DocumentData>();
		for(Integra_Contract__c c : [select Id
											,Name
											,CreatedDate
											,CreatedById
											,Contract_Term__c
											,Contract_Type__c
											,Description__c
											,Effective_Date__c
											,Expiration_Date__c
											,Status__c
											,Title__c
											,Account__c
											,Account__r.ICC_Account_Number__c
										from Integra_Contract__c where RecordType.Name = 'Customer' and Account__c in: nObjects.keyset()]){
			if(contractMode && c.Status__c != 'Active') continue;
			
			DocumentData d = new DocumentData();
			d.Name = !string.isEmpty(c.Title__c) ? c.Title__c : c.Name;
			d.Parent = nObjects.get(c.Account__c);
			d.Link = '..\\' + c.Id;
			d.Type = 'Contract' + (!String.isEmpty(c.Contract_Type__c) ? (': ' + c.Contract_Type__c) : '');
			d.Description = c.Description__c;
			d.Status = c.Status__c;
			d.SubscriberID = c.Account__r.ICC_Account_Number__c;
			d.EffectiveDate = c.Effective_Date__c != null ? c.Effective_Date__c : c.CreatedDate;
			d.CreatedById = c.CreatedById;
			d.Term = string.valueOf(c.Contract_Term__c);
			d.ExpirationDate = c.Expiration_Date__c;
			docs.add(d);
		}
		return docs;
	}
	
	private List<DocumentData> getExternalDocumentsByAccountSubscriberID(Id accountID, String subID){
		List<DocumentData> docs = new List<DocumentData>();
		
		try{
	        List<integraWS.DocumentListResultContract> newDocDatas = !Test.isRunningTest()
																	? integraWSEndpointMediator.Endpoint.GetDocumentsBySubscriberID(integer.valueOf(subID), showExpired, includeChildren, UserInfo.getSessionID(), CustomSettingUtils.SFDCCallbackEndpoint).DocumentListResultContract
																	: new List<integraWS.DocumentListResultContract>();
			
			for(integraWS.DocumentListResultContract docData : newDocDatas){
				DocumentData d = new DocumentData();
				d.Name = docData.DocumentName;
				d.Parent = nObjects.get(accountID);
				d.Link = CustomSettingUtils.GetDocumentDownLoadURL(string.valueOf(docData.DocumentID), UserInfo.getSessionID(), CustomSettingUtils.SFDCCallbackEndpoint);
				d.Type = 'External Document';
				d.Description = docData.TypeDescription;
				d.Status = docData.Expired ? 'Expired' : 'Active';
				d.SubscriberID = String.valueOf(docData.ICCSubscriberID);
				d.EffectiveDate = docData.CreateDate;
				d.CreatedBy = docData.CreateUser;
				d.Term = 'N/A';
				docs.add(d);
			}
		}
		catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Callout exception: "'+ e.getMessage() + '"'));
		}
		
		return docs;
	}
	
	public TestUtils.TestClass getTestClass(){ return null; }//new Test_DocumentViewerController(); }
}