public with sharing class DeliverDocuSign extends DeliverBase {

    private static final Integer DEFAULT_CALLOUT_TIMEOUT = 60;
    
    private String accountId;
    private String userId;
    private String password;
    private String integratorsKey;
    private Integer timeout;
    private String webServiceUrl;
    private String sendOnBehalfOfId;

    public DeliverDocuSign(String accountId, String userId, String password, String integratorsKey, String webServiceUrl) {
        this(accountId, userId, password, integratorsKey, webServiceUrl, null, DEFAULT_CALLOUT_TIMEOUT);
    }   
    
    public DeliverDocuSign(String accountId, String userId, String password, String integratorsKey, String webServiceUrl, String sendOnBehalfOfId, Integer timeout) {
        
        // validate parameters
        if(accountId == null || userId == null || password == null || integratorsKey == null || timeout == null || webServiceUrl == null ) {
            throw new DeliverDocuSignException('Parameters must not be null.');
        }
        
        // set instance fields
        this.accountId = accountId;
        this.userId = userId;
        this.password = password;
        this.integratorsKey = integratorsKey;
        this.timeout = (timeout < 0 ? 0 : timeout);
        this.webServiceUrl = webServiceUrl;
        this.sendOnBehalfOfId = sendOnBehalfOfId;
    }
    
    public override Boolean SendNow( DeliverBase.MessageInfo info) {
                
        system.debug('Info: ');
        system.debug(info);
        
        system.debug('number of documents: ' + info.documents.size());
        
        DocuSignAPI.APIServiceSoap dsApiSend = new DocuSignAPI.APIServiceSoap(); 
        dsApiSend.endpoint_x = webServiceUrl;
        dsApiSend.timeout_x = this.timeout * 1000;

        //Set Authentication

        String auth = '<DocuSignCredentials><Username>'+ (sendOnBehalfOfId != null ? '[' + sendOnBehalfOfId + ']' + userId : userId)
                +'</Username><Password>' + password
                + '</Password><IntegratorKey>' + integratorsKey
                + '</IntegratorKey></DocuSignCredentials>';


//      String auth = '<Username>[' + integratorsKey + '][' + sendOnBehalfOfId + ']' + userId + '</Username>';


                
        System.debug('Setting authentication to: ' + auth);

        dsApiSend.inputHttpHeaders_x = new Map<String, String>();
        dsApiSend.inputHttpHeaders_x.put('X-DocuSign-Authentication', auth);
      
      
        DocuSignAPI.Envelope envelope = new DocuSignAPI.Envelope();
        envelope.AccountId  = accountId;

        System.debug('subject: ' + info.Message);

        envelope.Subject = info.Subject;
        // Use line below to set a message that goes to all recipients
        //envelope.EmailBlurb = info.Message;
        
        DocuSignAPI.CustomField oppfield = new DocuSignAPI.CustomField();
        oppfield.Name = '##SFOpportunity';
        oppfield.Value = info.WhatID;
        envelope.CustomFields = new DocuSignAPI.ArrayOfCustomField();
        envelope.CustomFields.CustomField = new DocuSignAPI.CustomField[] {oppfield};


        // Documents        
        envelope.Documents = new DocuSignAPI.ArrayOfDocument();
        envelope.Documents.Document = new DocuSignAPI.Document[info.documents.Size()];
        
        for( Integer nIdx=0; nIdx < info.documents.Size(); nIdx++) {
            DocuSignAPI.Document document = new DocuSignAPI.Document();
            document.ID = nIdx;
            document.pdfBytes = EncodingUtil.base64Encode(info.documents[nIdx].VersionData);
            document.Name = info.documents[nIdx].Title;
            
            // set the file extension.  first default to file type, and later try and be more specific.
            // (may be better to map types to extensions rather than parse - as the types cannot be spoofed)
            document.FileExtension = info.documents[nIdx].FileType;
            if((!info.documents[nIdx].PathOnClient.endsWith('.')) && (info.documents[nIdx].PathOnClient.lastIndexOf('.') != -1)) {
                document.FileExtension = info.documents[nIdx].PathOnClient.substring(info.documents[nIdx].PathOnClient.lastIndexOf('.') + 1);   
            }
      
            envelope.Documents.Document[nIdx] = document;
        }
                     
        Integer numberOfSigners = 0;

        envelope.Recipients = new DocuSignAPI.ArrayOfRecipient();
        envelope.Recipients.Recipient = new DocuSignAPI.Recipient[info.contacts.size()];
        System.debug('Number of recipients: ' + info.contacts.Size());
        for( Integer nIdx=0; nIdx < info.contacts.Size(); nIdx++) {
            DocuSignAPI.Recipient recipient = new DocuSignAPI.Recipient();
            
            recipient.ID = nIdx;
            if( info.contacts[nIdx].recipType == DeliverBase.RecipientType.Signer ) {
                recipient.Type_x = 'Signer';  //'Certified Delivery'; 
                recipient.Note = info.Message;
                numberOfSigners++;
            }
            else
                recipient.Type_x = 'CarbonCopy'; 
            
            recipient.RoutingOrder = info.contacts[nIdx].RoutingOrder;
            recipient.Email = info.contacts[nIdx].rawContact.Email;
            //todo - create a non SF specific contact type (contact name is calc'd field that can't be set)
            recipient.UserName = info.contacts[nIdx].rawContact.Name != null ? info.contacts[nIdx].rawContact.Name : info.contacts[nIdx].rawContact.LastName;
            // recipient.CustomFields = new DocuSignAPI.ArrayOfString1();
            // recipient.CustomFields.CustomField = new String[1];
            // recipient.CustomFields.CustomField[0] = info.contacts[nIdx].rawContact.Id;
                        
            // customfield.key = '##Contact';
            // customfield.value = parentId;
            
            // recipient.
            // This setting seems required or you see the error:
            // "The string '' is not a valid Boolean value. at System.Xml.XmlConvert.ToBoolean(String s)"
            recipient.RequireIDLookup = false;     
             
            envelope.Recipients.Recipient[nIdx] = recipient;
        }
             
        // Tab
        envelope.Tabs = new DocuSignAPI.ArrayOfTab();
        envelope.Tabs.Tab = new DocuSignAPI.Tab[] {};

        // Looks like a bug in DocuSign.  We should *not* go through all the docs... Just enough to set the 0'th.       
        envelope.Tabs.Tab.add(createTab('SignHere', 'DS-SIG', 0, 0));
        envelope.Tabs.Tab.add(createTab('DateSigned', 'DS-DATE', 0, 0));
    	envelope.Tabs.Tab.add(createTab('InitialHere', 'DS-REQI', 0, 0));
        envelope.Tabs.Tab.add(createTab('InitialHereOptional', 'DS-INIO', 0, 0));
        envelope.Tabs.Tab.add(createTab('Custom', 'DS-XMark', 0, 0));
        envelope.Tabs.Tab.add(createTab('Custom', 'DS-FILL', 0, 0));
        // only if there is a counter-signer, add the tab for him
        if( numberOfSigners > 1 ) {
            envelope.Tabs.Tab.add(createTab('SignHere', 'DS-CTRSIG', 1, 0));
            envelope.Tabs.Tab.add(createTab('FullName', 'DS-CTRNAME', 1, 0));
            envelope.Tabs.Tab.add(createTab('DateSigned', 'DS-CTRDATE', 1, 0));         
        }
             
        System.debug('Calling the API');
        try {
            
            // send envelope
            system.debug('envelope contents: ' + envelope);
            DocuSignAPI.EnvelopeStatus es = dsApiSend.CreateAndSendEnvelope(envelope);
            
            // create status
            dsfs__DocuSign_Status__c status = new dsfs__DocuSign_Status__c();
            status.dsfs__DocuSign_Envelope_ID__c = es.EnvelopeID;
            status.dsfs__Opportunity__c = info.WhatID;
            status.dsfs__Envelope_Status__c = es.Status;
            status.dsfs__Sender__c = es.UserName;
            status.dsfs__Sender_Email__c = es.Email;
            status.dsfs__Subject__c = es.Subject;
            status.dsfs__Sent_Date_Time__c = System.now();
            insert status;
            
            return true;
        } catch ( Exception e) {
            System.debug('Exception - ' + e );
            LastError = e.getMessage();
            return false;
        }     
        
    }
    
    private DocuSignAPI.Tab createTab( string tabKey, string ancorKey, Integer recipNum, Integer docNum ) {
        DocuSignAPI.Tab tab = new DocuSignAPI.Tab();
        tab.Type_x = tabKey;
        tab.RecipientID = recipNum;
        tab.DocumentID = docNum;
        tab.CustomTabRequired = false;
        if(ancorKey == 'DS-XMark'){
        tab.CustomTabWidth = 1;
        }
        else
        tab.CustomTabWidth = 100;
        tab.CustomTabHeight = 1;
        tab.AnchorTabItem = new DocuSignAPI.AnchorTab();
        tab.AnchorTabItem.AnchorTabString = ancorKey;
        tab.AnchorTabItem.IgnoreIfNotPresent = true;

        return tab;
    }
    
    public class DeliverDocuSignException extends Exception {
    }
	
	/* TestUtils.ITestableClass methods */
	public override TestUtils.TestClass getTestClass(){ return new Test_DeliverDocuSign(); }
}