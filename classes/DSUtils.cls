public without sharing class DSUtils implements TestUtils.ITestableClass {
	
    class DSException extends Exception {}
	
	public static final String TAB_XMARK = 'DS-XMark';
	
	public class DocuSignContent{
		public sObject Document { get; private set;}
		
		//Key=Uniqe tag ID, Val=DocuSign ID/Label
		public Map<String, String> SignerTabs { get; set; }
		public Map<String, String> CounterSignerTabs { get; set; }
		public Map<String, String> CCTabs { get; set; }
		
		public DocuSignContent(sObject doc){
			Document = doc;
			SignerTabs = new Map<String, String>();
			CounterSignerTabs = new Map<String, String>();
			CCTabs = new Map<String, String>();
		}
		
		public void AddStandardTabs(){
			SignerTabs.put('DS-SIG', 'SignHere');
			SignerTabs.put('DS-DATE', 'DateSigned');
			SignerTabs.put('DS-REQI', 'InitialHere');
			SignerTabs.put('DS-INIO', 'InitialHereOptional');
			SignerTabs.put(TAB_XMARK, 'Custom');
			SignerTabs.put('DS-FILL', 'Custom');
			
			CounterSignerTabs.put('DS-CTRSIG', 'SignHere');
			CounterSignerTabs.put('DS-CTRNAME', 'FullName');
			CounterSignerTabs.put('DS-CTRDATE', 'DateSigned');
		}
	}
	
	public class DSContact{
		
		public String Name { get; set; }
		public String Email { get; set; }
		
		public DSContact(Contact c){
			Name = c.Name != null ? c.Name : c.LastName;		//Do we ever pass in fake contacts?
			Email = c.Email;
		}
		
		public DSContact(User u){
			Name = u.Name;
			Email = u.Email;
		}
		
		public DSContact(String name, String email){
			this.Name = name;
			this.Email = email;
		}
	}
	
	public class EnvelopeRequest{
		
		public String Subject {get;set;}
		public String Message {get;set;}
		public String SenderEmail {get; set; }
		public List<DSContact> Signers { get; set; }
		public List<DSContact> CCs { get; set; }
		public DSContact CounterSigner { get; set; }
		
		//Defaulted params
		public String DSAccountID { get; set;}
		public String LoginID { get; set;}
		public String Password { get; set;}
		public String IntegratorKey { get; set;}
		public String EndpointURL { get; set;}
		public Integer Timeout { get; set; }
		
		public List<DocuSignContent> documents { get; set; }
		public Map<String, String> customFields { get; private set; }
		
		public EnvelopeRequest(String subject, String message, String senderEmail){
            System.debug('EvelopeRequest');
			this.Subject = subject;
			this.Message = message;
			this.SenderEmail = senderEmail;
			documents = new List<DocuSignContent>();
			customFields = new Map<String, String>();
			Signers = new List<DSContact>();
			CCs = new List<DSContact>();
			
			DocuSignServiceSettings__c settings = DocuSignServiceSettings__c.getInstance();
			
			if(settings != null){
				DSAccountID = settings.AccountID__c;
				LoginID = settings.UserID__c;
				Password = settings.Password__c;
				IntegratorKey = settings.IntegratorKey__c;
				EndpointURL = settings.ApiEndpointUrl__c;
			}
			Timeout = (settings != null && settings.Timeout__c != null) ? Integer.valueOf(settings.Timeout__c) : 60;
		}
		
		public DocuSignContent AddDocument(sObject d){
			DocuSignContent doc = new DocuSignContent(d);
			documents.add(doc);
			return doc;
		}
		
		public void AddCustomField(String name, String val){
			customFields.put(name, val);
		}
		
		public Boolean Validate(List<String> outErrors){
			List<String> errors = new List<String>();
			
			if(Subject == null || Subject.trim().length() == 0) errors.add('A valid subject is required.');
			if(Message == null || Message.trim().length() == 0) errors.add('A valid signer note is required.');
			if(documents == null || documents.size() == 0) errors.add('At least one document must be sent.');
			if(Signers == null || Signers.size() == 0) errors.add('At least one signer must be chosen.');
			
			if(outErrors != null) outErrors.addAll(errors);
			
			return errors.size() == 0;
		}
	}
	
	public class EnvelopeSendResult{
		public Boolean Success { get; set; }
		public List<String> Errors { get; set; }
		public DocuSignAPI.EnvelopeStatus EnvelopeStatus { get; set; }
		
		public EnvelopeSendResult(){
			Success = false;
			Errors = new List<String>();
		}
	}
	
	public static EnvelopeSendResult Send(EnvelopeRequest er){
		EnvelopeSendResult result = new EnvelopeSendResult();
		
		if(er.Validate(result.Errors)){
			
	        DocuSignAPI.Envelope envelope = new DocuSignAPI.Envelope();
	        envelope.AccountId  = er.DSAccountID;
	        envelope.Subject = er.Subject;
	        
			//Build the doc list
			List<DocuSignAPI.Document> docList = new List<DocuSignAPI.Document>();
	        for(Integer i=0; i<er.documents.size(); i++) {
				sObject d = er.documents[i].Document;
				
	            DocuSignAPI.Document doc = new DocuSignAPI.Document();
	            doc.ID = i;
				
				if(!Test.isRunningTest() || d != null){
					
					String fileName = '';
					if(SchemaUtils.GetSObjectNameByID(d.Id) == 'ContentVersion'){
						ContentVersion cv = (ContentVersion)d;
				        doc.pdfBytes = EncodingUtil.base64Encode(cv.VersionData);
				        doc.Name = cv.Title;
						fileName = cv.PathOnClient;
					}
					else{
						Attachment at = (Attachment)d;
				        doc.pdfBytes = EncodingUtil.base64Encode(at.Body);
						doc.Name = at.Name;
						fileName = at.Name;
					}
		            
		            // set the file extension.  first default to file name, and later try and be more specific.
		            // (may be better to map types to extensions rather than parse - as the types cannot be spoofed)
		            doc.FileExtension = fileName;
		            if((!fileName.endsWith('.')) && (fileName.lastIndexOf('.') != -1)) {
		                doc.FileExtension = fileName.substring(fileName.lastIndexOf('.') + 1);   
		            }
				}
				
	            docList.add(doc);
	        }
	        envelope.Documents = new DocuSignAPI.ArrayOfDocument();
	        envelope.Documents.Document = docList;
	        
	        //Build recipient and tab lists
			List<DocuSignAPI.Recipient> recipList = new List<DocuSignAPI.Recipient>();
			List<DocuSignAPI.Tab> tabList = new List<DocuSignAPI.Tab>();
			for(Integer i=0; i<er.Signers.size(); i++){
				recipList.add(buildRecipientFromContact(er.Signers[i], i, true, 1, er.Message));
				for(Integer k=0; k<er.documents.size(); k++){
					for(String uniqueID : er.documents[k].SignerTabs.keyset())
						tabList.add(createTab(er.documents[k].SignerTabs.get(uniqueID), uniqueID, i, k));
				}
			}
			
			if(er.CounterSigner != null){
				Integer rID = recipList.size();
				recipList.add(buildRecipientFromContact(er.CounterSigner, rID, true, 2, er.Message));
				
				for(Integer i=0; i<er.documents.size(); i++){
					for(String uniqueID : er.documents[i].CounterSignerTabs.keyset())
						tabList.add(createTab(er.documents[i].CounterSignerTabs.get(uniqueID), uniqueID, rID, i));
				}
			}
			
			for(Integer i=0; i<er.CCs.size(); i++){
				Integer rID = recipList.size();
				recipList.add(buildRecipientFromContact(er.CCs[i], rID, false, 2, null));
				for(Integer k=0; k<er.documents.size(); k++){
					for(String uniqueID : er.documents[k].CCTabs.keyset())
						tabList.add(createTab(er.documents[k].CCTabs.get(uniqueID), uniqueID, rID, k));
				}
			}
			
	        envelope.Recipients = new DocuSignAPI.ArrayOfRecipient();
	        envelope.Recipients.Recipient = recipList;
	        envelope.Tabs = new DocuSignAPI.ArrayOfTab();
	        envelope.Tabs.Tab = tabList;
			
			//Set the custom fields
			List<DocuSignAPI.CustomField> cfList = new List<DocuSignAPI.CustomField>();
			for(String name : er.customFields.keyset()){
				DocuSignAPI.CustomField cf = new DocuSignAPI.CustomField();
				cf.Name = name;
				cf.Value = er.customFields.get(name);
				cfList.add(cf);
			}
	        envelope.CustomFields = new DocuSignAPI.ArrayOfCustomField();
	        envelope.CustomFields.CustomField = cfList;
		    
	        String auth = '<DocuSignCredentials>'
				+ '<Username>' + (!string.isEmpty(er.SenderEmail) ? '[' + er.SenderEmail + ']' : '') + er.LoginID + '</Username>'
	            + '<Password>' + er.Password + '</Password>'
	            + '<IntegratorKey>' + er.IntegratorKey + '</IntegratorKey>'
	            + '</DocuSignCredentials>';
			
	        DocuSignAPI.APIServiceSoap ds = new DocuSignAPI.APIServiceSoap(); 
	        ds.endpoint_x = er.EndpointURL;
	        ds.timeout_x = er.Timeout * 1000;
	        
	        ds.inputHttpHeaders_x = new Map<String, String>();
	        ds.inputHttpHeaders_x.put('X-DocuSign-Authentication', auth);
			
	        try {
	            result.envelopeStatus = !Test.isRunningTest() ? ds.CreateAndSendEnvelope(envelope) : Test_DSUtils.getEnvelopeStatus();
				result.Success = true;
	        }
			catch(Exception e) {
				result.Errors.add('Exception: ' + e.getMessage());
	        }
		}
		
		return result;
	}
	
	private static Boolean userAccountCreated = false;
	public static Boolean CreateCurrentUserAccountIfNeeded(){
		if(!userAccountCreated && !Test.isRunningTest()){
	        DocuSignServiceSettings__c settings = DocuSignServiceSettings__c.getInstance();
			
			DocuSignAccountManagementAPI.AccountManagementServiceSoap amss = new DocuSignAccountManagementAPI.AccountManagementServiceSoap();
			amss.endpoint_x = settings.AccountManagementEndpointURL__c;
			amss.timeout_x = Integer.valueOf(settings.Timeout__c) * 1000;
			String auth = '<DocuSignCredentials><Username>'+ settings.UserId__c + '</Username>'
					+ '<Password>' + settings.Password__c + '</Password>'
					+ '<IntegratorKey>' + settings.IntegratorKey__c + '</IntegratorKey></DocuSignCredentials>';
			amss.inputHttpHeaders_x = new Map<String, String>();
			amss.inputHttpHeaders_x.put('X-DocuSign-Authentication', auth);
			
			DocuSignAccountManagementAPI.CheckAccountMemberResult_element response = amss.CheckAccountMember(settings.AccountId__c, UserInfo.getUserEmail());
			if(response.Error != null && response.Error.ErrorCode == 'INVALID_USER'){
				DocuSignAccountManagementAPI.Member member = new DocuSignAccountManagementAPI.Member();
				member.MemberEmailAddress = UserInfo.getUserEmail();
				member.MemberFirstName = Userinfo.getFirstName();
				member.MemberLastName = Userinfo.getLastName();
				member.MemberUserName = Userinfo.getName();  //Userinfo.getUserName();
				
				//Set default values for credentials so the user doesn't need to activate via email confirmation
				member.MemberPassword = 'pwd' + Math.random();
				member.MemberForgottenPasswordQuestion = 'You have not set up a security question';
				member.MemberForgottenPasswordAnswer  = 'Okay ' + Math.random();
				
				member.MemberSettings = new DocuSignAccountManagementAPI.MemberSettings();
				member.MemberSettings.CanSendEnvelope = true;
				DocuSignAccountManagementAPI.ArrayOfMember arrayOfMember = new DocuSignAccountManagementAPI.ArrayOfMember();
				arrayOfMember.Member = new DocuSignAccountManagementAPI.Member[] { member };
				
				amss.AddMembersToAccount(settings.AccountId__c, arrayOfMember);
			}
			else if(response.Error != null || (response.Status != null && response.Status.toLowerCase() != 'true')) throw new DSException('DocuSign user could not be created.');
			
			userAccountCreated = true;
		}
		
		return true;
	}
	
	public static Id CreateDocusignStatusRecord(EnvelopeSendResult esr, EnvelopeRequest er, Set<Id> relatedObjectIDs){
		Id statusID = null;
		
		if(esr.Success){
            Integer maxSubjectLength = dsfs__DocuSign_Status__c.fields.dsfs__Subject__c.getDescribe().getLength();
			String subject = esr.EnvelopeStatus.Subject != null && (esr.EnvelopeStatus.Subject.length() > maxSubjectLength) ? esr.EnvelopeStatus.Subject.substring(0, maxSubjectLength) : esr.EnvelopeStatus.Subject;
			
            dsfs__DocuSign_Status__c status = new dsfs__DocuSign_Status__c(
																			dsfs__DocuSign_Envelope_ID__c = esr.EnvelopeStatus.EnvelopeID
																			,dsfs__Envelope_Status__c = esr.EnvelopeStatus.Status
																			,dsfs__Sender__c = esr.EnvelopeStatus.UserName
																			,dsfs__Sender_Email__c = esr.EnvelopeStatus.Email
																			,dsfs__Subject__c = subject
																			,dsfs__Sent_Date_Time__c = esr.EnvelopeStatus.Sent
																		);
			
			for(Id rID : relatedObjectIDs != null ? relatedObjectIDs : new Set<Id>()){
				String sObjName = SchemaUtils.GetSObjectNameByID(rID);
                if(sObjName == 'Opportunity') status.dsfs__Opportunity__c = rID;
				if(sObjName == 'PDF__c') status.PDF__c = rID;
                if(sObjName == 'Pricing_Agreement__c') status.Pricing_Agreement__c = rID;
			}
			
            insert status;
			statusID = status.Id;
		}
		
		return statusID;
	}
	
	private static DocuSignAPI.Recipient buildRecipientFromContact(DSContact c, Integer id, Boolean isSigner, Integer routingOrder, String signerNote){
        DocuSignAPI.Recipient r = new DocuSignAPI.Recipient();
        r.ID = id;
		
		r.Type_x = isSigner ? 'Signer' : 'CarbonCopy';
		r.RoutingOrder = routingOrder;
        if(isSigner) r.Note = signerNote;
        
        r.Email = c.Email;
        r.UserName = c.Name;
        r.RequireIDLookup = false;
		
		return r;
	}
    
    private static DocuSignAPI.Tab createTab(string tabKey, string ancorKey, Integer recipNum, Integer docNum) {
		
        DocuSignAPI.Tab t = new DocuSignAPI.Tab();
        t.Type_x = tabKey;
        t.RecipientID = recipNum;
        t.DocumentID = docNum;
        t.CustomTabRequired = false;
		
		t.CustomTabWidth = (ancorKey == TAB_XMARK) ? 1 : 100;
        t.CustomTabHeight = 1;
        t.AnchorTabItem = new DocuSignAPI.AnchorTab();
        t.AnchorTabItem.AnchorTabString = ancorKey;
        t.AnchorTabItem.IgnoreIfNotPresent = true;
        
        return t;
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_DSUtils(); }
}