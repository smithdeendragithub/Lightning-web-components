public with sharing class OpptySendContentController implements TestUtils.ITestableClass {

    public class ContentDoc {
        public Boolean bSelected {get;set;}
        public ContentVersion cv {get;set;}
		public Attachment at {get;set;}
        public String sizeLabel {get;set;}
		
        public ContentDoc(ContentVersion in_cv) {
            if(in_cv.ContentSize != null) {
            sizeLabel = string.valueOf(in_cv.ContentSize/1024);}
            cv = in_cv;
            bSelected = false;          
        }
        
        public ContentDoc(Attachment at) {
            sizeLabel = string.valueOf(at.BodyLength/1024);
            this.at = at;
            bSelected = false;          
        }
    }
    
    // became properties because I can't figure out how 
    // to reference a static constant from a VF page
    public String DELIVERY_METHOD_TYPE_EMAIL { get { return 'Email'; }}
    public String DELIVERY_METHOD_TYPE_DOCUSIGN { get { return 'DocuSign'; }}
    
    private static final String ROLE_INTERNAL_SIGNER = 'Countersigner';
    
    public Boolean sendDisabled { get; set; }
    public Boolean docuSignCreateRequestSuccessfullySent { get; set; }
    
    public List<SelectOption> deliveryMethods {get;set;}
    public String selectedDeliveryMethod {get; set; }

    public Opportunity currentOppty {get;set;}
	
	public List<ContentDoc> RelatedAttachments { get; set; }
    public List<ContentDoc> contentDocs {get;set;}
    public List<ContentDoc> selectedDocs {get;set;}
    public String selectedDocId {get;set;}
    public String sortOrder {get;set;}
    
    public List<GlobalUtilities.Recipient> selectedRecipients {get;set;}
    
    public Case selectedCase {get;set;}
    public Opportunity selectedOpportunity {get;set;}
    public String selectedWorkspace {get;set;}
    public List<SelectOption> workspaces {get;set;}

    public String searchTitle {get;set;}
    
    private final String noTemplate = '-Not using a template-';
    private final String noTemplateDocusign = '-Using DocuSign Templates-';
    private final String customerFacingAudience = 'Customer Facing';

    public Map<Id, EmailTemplate> mapTemplates {get;set;}
    public List<SelectOption> lstTemplates {get;set;}
    public String selectedTemplate {get;set;}
    public EmailTemplate currentTemplate {get;set;}
    public Boolean bUseTemplate { get { return (currentTemplate != null); } }

    public String subject {get;set;}
    public String message {get;set;}
	
	private Id counterSignerID {get; set;}
    
    public Boolean isDocuSignEnabled {
		get {
	        DocuSignServiceSettings__c ds = DocuSignServiceSettings__c.getInstance();       
	        return ds != null && ds.AccountId__c != null;
		}
    }
    
    public OpptySendContentController(ApexPages.StandardController stdController){
        currentOppty = (Opportunity) stdController.getRecord();
		
        sendDisabled = false;
        docuSignCreateRequestSuccessfullySent = false;
        
        contentDocs = new List<ContentDoc>();
		for(ContentVersion cv : [SELECT Id, Title, Description, LastModifiedDate, CreatedDate, LastModifiedBy.Name, ContentSize from ContentVersion where Opportunity__c =: currentOppty.Id AND Intended_Audience__c =: customerFacingAudience AND IsLatest=true]) contentDocs.add(new ContentDoc(cv));
        
        selectedDocs = new List<ContentDoc>();
        
        selectedRecipients = GlobalUtilities.LoadRecipients(currentOppty);
        
        selectedCase = new Case();
        selectedOpportunity = new Opportunity();
        
        deliveryMethods = new List<SelectOption>{new SelectOption(DELIVERY_METHOD_TYPE_EMAIL, DELIVERY_METHOD_TYPE_EMAIL), new SelectOption(DELIVERY_METHOD_TYPE_DOCUSIGN, 'Send For Signatures')};
        selectedDeliveryMethod = DELIVERY_METHOD_TYPE_EMAIL;
        
        workspaces = UploadContentController.LoadWorkspaces('Sales Workspace%');
        
        // Record types happen to be named the same as template folders
        mapTemplates = new Map<Id, EmailTemplate>([Select Id, Name, DeveloperName, Subject, HtmlValue, Description, Body From EmailTemplate WHERE Folder.DeveloperName =: currentOppty.RecordType.DeveloperName]);
        lstTemplates = LoadTemplates();     
        selectedTemplate = lstTemplates[0].getValue();
        updateCurrentTemplate();
		
		Set<Id> parentIDs = new Set<Id>{ currentOppty.Id };
		for(PDF__c pdf : [select Id from PDF__c where Opportunity__c =: currentOppty.Id]) parentIDs.add(pdf.Id);
		
		RelatedAttachments = new List<ContentDoc>();
		for(Attachment at : [select Id, ParentId, Name, BodyLength, CreatedDate, LastModifiedDate, LastModifiedBy.Name from Attachment where ParentId in: parentIDs]) RelatedAttachments.add(new ContentDoc(at));
    }
    
    public PageReference updateCurrentTemplate() {
        system.debug('updating current template to: ' + selectedTemplate);
        if( selectedTemplate == noTemplate ) {
            currentTemplate = null;
            subject = '';
            message = '';
        }
        else {
            currentTemplate = mapTemplates.get(selectedTemplate);
            subject = currentTemplate.Subject;
            message = currentTemplate.Body;
        }
		return null;
    }

    
    private List<SelectOption> LoadTemplates() {
        List<SelectOption> selectOptions = new List<SelectOption>{new SelectOption(noTemplate, noTemplate)};
        for( EmailTemplate e : mapTemplates.values()) selectOptions.add(new SelectOption(e.Id, e.Name));
        return selectOptions;
    }
    
    public PageReference changeDeliveryMethod() {
        
        if(selectedDeliveryMethod == DELIVERY_METHOD_TYPE_DOCUSIGN) {
            
            // reset template
            lstTemplates.add(new SelectOption(noTemplateDocusign, noTemplateDocusign));
            selectedTemplate = noTemplateDocusign;
            currentTemplate = null;
            subject = '';
            message = '';
			
            //try {
                DSUtils.CreateCurrentUserAccountIfNeeded();
				
				if(counterSignerID != null){
					List<Integra_Contract__c> c = [select Id from Integra_Contract__c where Account__c =: currentOppty.AccountId limit 1];
					if(c.size() > 0){
						c[0].Integra_Signatory__c = counterSignerID;
						update c;
					}
				}
            //} catch(Exception e) {
            //    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            //}
        }
        else {
            // remove dosusign option
            for(Integer x = 0; x < lstTemplates.size(); x++) {
                if(lstTemplates.get(x).getValue() == noTemplateDocusign) {
                    lstTemplates.remove(x);
                    break;
                }
            }
            selectedTemplate = noTemplate;
            
            // enable send button
            sendDisabled = false;
        }
		
        return null;
    }
    
    public PageReference addRecipient() {
        
        for(GlobalUtilities.Recipient recipient : selectedRecipients) {
            if(recipient.opptyRole != ROLE_INTERNAL_SIGNER && recipient.c.Id == selectedCase.ContactId) return null;
        }
        
        for(Contact c : [Select Name, Email, Account.Name, AssistantName, (Select Role From OpportunityContactRoles where OpportunityId = :currentOppty.Id) From Contact where Id = :selectedCase.ContactId]){
			GlobalUtilities.Recipient recipient = new GlobalUtilities.Recipient();
	        recipient.c = c;
	        recipient.recipientType = GlobalUtilities.RECIPIENT_TYPE_SIGNER;
	        for(OpportunityContactRole opportunityContactRole : c.OpportunityContactRoles) recipient.opptyRole = opportunityContactRole.Role;
	        selectedRecipients.add(recipient);
		}
		
        selectedCase = new Case();
        return null;
    }
    
    public PageReference addUserAsRecipient() {
        
        for(GlobalUtilities.Recipient recipient : selectedRecipients) {
            if(recipient.opptyRole == ROLE_INTERNAL_SIGNER && recipient.c.AssistantName == selectedOpportunity.InternalSigner__c) return null;
        }
        
        // create a contact from the user
		User u = [Select Name, Email From User where Id = :selectedOpportunity.InternalSigner__c];
        GlobalUtilities.Recipient recipient = new GlobalUtilities.Recipient();
        recipient.c = new Contact(AssistantName = u.Id, LastName = u.Name, Email = u.Email);
        recipient.opptyRole = ROLE_INTERNAL_SIGNER;
        recipient.recipientType = GlobalUtilities.RECIPIENT_TYPE_COUNTERSIGNER;
        selectedRecipients.add(recipient);
        selectedOpportunity = new Opportunity();
        return null;
    }
    
    public PageReference reorderDocs() {
        
        List<ContentDoc> newSelectedDocs = new List<ContentDoc>();
        for(String id : sortOrder.split(',')) {
            for(ContentDoc d : selectedDocs) {
                if((d.cv != null && d.cv.Id == id) || (d.at != null && d.at.Id == id)) newSelectedDocs.add(d);
            }
        }
        selectedDocs = newSelectedDocs;
        return null;
    }
    
    public PageReference removeDoc() {
		for(Integer i=selectedDocs.size()-1; i>=0; i--){
			ContentDoc d = selectedDocs[i];
			if((d.cv != null && d.cv.Id == selectedDocId) || (d.at != null && d.at.Id == selectedDocId)) selectedDocs.remove(i);
		}
        return null;
    }
    
    public PageReference addDoc() {
        
        // ignore if already there
        for(ContentDoc contentDoc : selectedDocs) {
            if((contentDoc.cv != null && contentDoc.cv.Id == selectedDocId) || (contentDoc.at != null && contentDoc.at.Id == selectedDocId)) return null;
        }
		
		for(List<ContentDoc> l : new List<List<ContentDoc>>{ RelatedAttachments, contentDocs/*, featuredDocs, msaDocs, foundDocs*/ }){
			for(ContentDoc d : l) {
	            if((d.cv != null && d.cv.Id == selectedDocId) || (d.at != null && d.at.Id == selectedDocId)) {
	                selectedDocs.add(d);   
	                return null;
	            }
	        }
		}
    
        return null;
    }
    
    public PageReference SendNow() {
			
		List<String> errors = new List<String>();
        
        // validate docusign
        if(selectedDeliveryMethod == DELIVERY_METHOD_TYPE_DOCUSIGN) {
			
            // validate recipients
            Integer signerCount = 0;
            Integer countersignerCount = 0;
            for( GlobalUtilities.Recipient r : selectedRecipients ) {
                if(r.getTo()) {
                    if(r.recipientType == GlobalUtilities.RECIPIENT_TYPE_SIGNER ) {
                        signerCount++;
                    } else if(r.recipientType == GlobalUtilities.RECIPIENT_TYPE_COUNTERSIGNER ) {
       	 				counterSignerID = r.c.AssistantName;		//hack :(
                        countersignerCount++;
                    }
                }
            }
			
            // validate subject
            if(subject == null || subject.trim().length() == 0) errors.add('Unable to send content via DocuSign. A valid subject is required.');
            
            // validate message
            if(message == null || message.trim().length() == 0) errors.add('Unable to send content via DocuSign. A valid signer note is required.');
			
            if(signerCount != 1) errors.add('Unable to send content via DocuSign. Exactly one signer with the signer type \'' + GlobalUtilities.RECIPIENT_TYPE_SIGNER + '\' must be selected.');
			else if(countersignerCount > 1) errors.add('Unable to send content via DocuSign. A maximum of one signer with the signer type \'' + GlobalUtilities.RECIPIENT_TYPE_COUNTERSIGNER + '\' can be selected.');
			
            if(selectedDocs.size() == 0) errors.add('Unable to send content via DocuSign. Please select at least one attachment.');
        }
		
        Set<Id> docIDs = new Set<Id>();
		for(ContentDoc cd : selectedDocs != null ? selectedDocs : new List<ContentDoc>()) docIDs.add(cd.cv != null ? cd.cv.Id : cd.at.Id);
		
        Map<Id, ContentVersion> cvMap = new Map<Id, ContentVersion>([select Id, VersionData, Title, ContentSize, PathOnClient, FileType from ContentVersion where Id in: docIDs]);
        Map<Id, Attachment> atMap = new Map<Id, Attachment>([select Id, ParentId, Body, BodyLength, Name from Attachment where Id in: docIDs]);
        
        //order the documents per UI
        Integer totalSize = 0;
		Id pdfID = null;
        List<sObject> documents = new List<sObject>();
        for(ContentDoc d : selectedDocs) {
			if(d.cv != null){
                ContentVersion cv = cvMap.get(d.cv.Id);
                documents.add(cv);
				totalSize = totalSize + cv.ContentSize;
			}
			else{
                Attachment at = atMap.get(d.at.Id);
                documents.add(at);
				totalSize = totalSize + at.BodyLength;
				
				if(SchemaUtils.GetSObjectNameByID(at.ParentId) == 'PDF__c') pdfID = at.ParentId;
			}
        }
		
		if(pdfID != null && documents.size() > 1 && DELIVERY_METHOD_TYPE_DOCUSIGN.equals(selectedDeliveryMethod)) errors.add('You cannot send a PDF generated document via DocuSign in addition to another document');
            
        if(selectedRecipients.size() == 0) errors.add('Please select recipients');
        
        if(selectedDocs.size() == 0) errors.add('Please select documents to send');
        
        if(totalSize > (1048576 * 10)) errors.add('Please limit the size of all attachments to 10 MB');
		
		if(errors.size() > 0){
			for(String error : errors) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
			return null;
		}
        
        try {
			Boolean bRetVal = false;
			if(DELIVERY_METHOD_TYPE_EMAIL.equals(selectedDeliveryMethod)) bRetVal = sendEmailNow(documents);
			else if(DELIVERY_METHOD_TYPE_DOCUSIGN.equals(selectedDeliveryMethod)) bRetVal = sendDocuSignRequestNow(documents, pdfID);
            
			PageReference pageRef = null;
            if(!bRetVal) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send'));
            else{
				pageRef = new PageReference('/' + currentOppty.Id);
				pageRef.setRedirect(true);
				
				if(counterSignerID != null){
					List<Integra_Contract__c> c = [select Id from Integra_Contract__c where Account__c =: currentOppty.AccountId limit 1];
					if(c.size() > 0){
						c[0].Integra_Signatory__c = counterSignerID;
						update c;
					}
				}
            }
            
            return pageRef;
        }
        catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send: ' + e.GetMessage()));
            return null;            
        }
    }
	
	private Boolean sendDocuSignRequestNow(List<sObject> documents, Id pdfID){
		
		try{
			DSUtils.EnvelopeRequest er = new DSUtils.EnvelopeRequest(subject, message, Userinfo.getUserEmail());
			
			for(Integer i=0; i<documents.size(); i++){
				DSUtils.DocuSignContent dsc = er.AddDocument(documents[i]);
				dsc.AddStandardTabs();
			}
			
			for(GlobalUtilities.Recipient r : selectedRecipients) {
				if(r.getTo() || r.getCC()) {
					DSUtils.DSContact dsc = new DSUtils.DSContact(r.c);
					
					if(!r.getTo()){
						er.CCs.add(dsc);
					}
					else{
		                if(r.recipientType == GlobalUtilities.RECIPIENT_TYPE_SIGNER) er.Signers.add(dsc);
		                else if(r.recipientType == GlobalUtilities.RECIPIENT_TYPE_COUNTERSIGNER) er.CounterSigner = dsc;
					}
	            }
			}
			
			Set<Id> relatedIDs = new Set<Id>{ currentOppty.Id };
			if(pdfID != null) relatedIDs.add(pdfID);
			
			DSUtils.EnvelopeSendResult result = DSUtils.Send(er);
			System.debug('Errors: ' + result.Errors);
			DSUtils.CreateDocusignStatusRecord(result, er, relatedIDs);
		}
		catch(Exception ex){ System.debug('DocuSign exception: ' + ex.getMessage()); return false; }
		
		return true;
	}
	
	private Boolean sendEmailNow(List<sObject> documents) {
		for(GlobalUtilities.Recipient r : selectedRecipients) {
			if(!r.getTo() && !r.getCC()) continue;
			
        	Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();               
        	if(selectedTemplate == null || selectedTemplate == '-Not using a template-'){
				email.setToAddresses( new List<string>{r.c.Email} );
				email.setPlainTextBody(message);
				email.setSubject(subject);
			}else{
				email.setTemplateId(selectedTemplate);
				if(r.c != null) email.setTargetObjectId(r.c.Id);
				email.setSaveAsActivity(false);
				email.setWhatId(currentOppty.Id);
			}
			email.setReplyTo(Userinfo.getUserEmail());
			email.setBccSender(false);
			email.setUseSignature(false);
			
			List<string> fileNames = new List<string>();
			List<Messaging.Emailfileattachment> fileList = new List<Messaging.Emailfileattachment>(); 
			for(sObject d : documents){
				Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
				string fileName = '';
				
				if(SchemaUtils.GetSObjectNameByID(d.Id) == 'ContentVersion'){
					ContentVersion cv = (ContentVersion)d;
					efa.setBody(cv.VersionData);
					fileName = cv.PathOnClient;
				}
				else{
					Attachment at = (Attachment)d;
					efa.setBody(at.Body);
					fileName = at.Name;
				}
				
				if(fileName.lastIndexOf('\\') != -1){
					fileName = fileName.substring(fileName.lastIndexOf('\\') + 1, fileName.length());	
				}
				fileNames.add(fileName);					
				efa.setFileName(fileName);
				fileList.add(efa);
			}
			
			email.setFileAttachments(fileList);
	        Messaging.SendEmailResult [] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
	        for(Messaging.SendEmailResult emailResult : results){
	        	if(emailResult.isSuccess() && r.c != null) addActivityForContentDelivery(r.c.Id, currentOppty.Id, fileNames);
	        }
        }
		return true;
	}
	
	private void addActivityForContentDelivery(string whoId, string whatId, List<string> fileNames){
		insert new Task(ActivityDate = Date.today()
						,Description = message + '\nAttached Files: \n' + string.join(fileNames, '\n') + '\n'
						,Status = 'Completed'
						,Subject = subject
						,WhatId = whatId
						,WhoId = whoId
						,Type = 'Email');
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return null;/*new Test_OpptySendContent();*/ }
}