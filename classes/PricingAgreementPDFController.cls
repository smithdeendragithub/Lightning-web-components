public without sharing virtual class PricingAgreementPDFController implements TestUtils.ITestableClass {
    public String paId {get;set;}
    public Pricing_Agreement__c pa {get;set;}
    public String returnURL {get;set;}
    public Contact decMaker { get; private set; }
    public string contId { get; set; }
    public String uniqueDocId { get; set; } 
    public List<Id> validContactIDs { get; set; }
    public Blob pdfBlob { get; set; }
    public string pdfString {
        get{
            string s = pdfBlob == null ? '' : EncodingUtil.base64Encode(pdfBlob);
            System.debug('blob String: ' + s);
            return s;
        }
    }
    
    public PricingAgreementPDFController(){
        paId = ApexPages.currentPage().getParameters().get('paId');    
        if(!string.isEmpty(paId)){
            if(!SecurityUtils.currentUserHasRecordAccess(paId, true)) throw new VisualforceException('Edit access to Pricing Agreement "' + paId + '" is required to generate PDFs.');
            
            returnURL = ApexPages.currentPage().getParameters().get('retURL');
            loadObjects();
            init();
        }
    }
    
     protected virtual void init(){
        Set<Id> contactIDs = new Set<Id>();
        for(Contact c : [select Id from Contact where AccountId =: pa.Account__r.Id]) contactIDs.add(c.Id);
        validContactIDs = new List<Id>(contactIDs);
        
    }
    
    private void loadObjects(){
        pa = [Select Name, Account__r.Name, Account__r.Id, Approval_Status__c From Pricing_Agreement__c where id = :paId limit 1];
        
        uniqueDocId = 'DocumentID: ' + DateTime.Now().getTime() + Math.random().format();
        
        if(contId != null) getDecisionMakerContact();
        if(pa.Approval_Status__c != 'Approved') ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Cannot print PDF as the Pricing Agreement has not been approved!'));
    }
    
    public void selectContact(){
        contId = Apexpages.currentPage().getParameters().get('contactID');
        getDecisionMakerContact();
    }
    
    private void getDecisionMakerContact(){
        decMaker = [SELECT Id, Name, FirstName, Title, Email, Phone from Contact where id =: contId limit 1];
    }

    public void getPDF(){
        PageReference pdf = new PageReference('/apex/PricingAgreementPDFDisplay');
        pdf.getParameters().put('pricingAgreementId', paId);
        pdf.setRedirect(false);
        pdfBlob = !Test.isRunningTest() ? pdf.getContent() : Test_OpportunityPDF.getTestPDFResults();
        System.debug('blob: ' + pdfBlob);
    }
    
    public void savePDF(){
        List<AggregateResult> maxIds = [select MAX(External_Id__c) maxExtId from Pricing_Agreement_Contract__c];
		Integer maxPDFExtId = maxIds.size() > 0 && maxIds[0].get('maxExtId') != null ? Integer.valueOf(maxIds[0].get('maxExtId')) : 1;
        Pricing_Agreement_Contract__c pricingAgreementPDF = new Pricing_Agreement_Contract__c(External_Id__c = ++maxPDFExtId);
        pricingAgreementPDF.Active__c = true;
        pricingAgreementPDF.Wholesale_Pricing_Agreement__c = paId;
        pricingAgreementPDF.Name = 'Proposal - ' + datetime.now().format('YYYY-MM-dd');
        List<sObject> PCinserts = new List<sObject>();
        PCinserts.add(pricingAgreementPDF);
        SecurityUtils.BypassProcesser.insertObjects(PCinserts, true);
        
        Attachment a = new Attachment(ContentType = 'application/pdf');
        a.Body = pdfBlob;
        a.Description = uniqueDocId;
        a.Name = 'PDF for ' + pa.Name + ' ' + DateTime.now().format('YYYY-MM-dd') + '.pdf';
        a.OwnerId = UserInfo.getUserId();
        //a.ParentId = paId;
        a.ParentId = pricingAgreementPDF.Id;
        SecurityUtils.BypassProcesser.insertObjects(new List<sObject>{ a }, true);  
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'The Contract Proposal PDF has been saved to the Wholesale Pricing Agreement under the related Pricing Agreement Contract and is ready to use in the ‘Send Content’ area for Electronic Signature and/or Email. Click <a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + pricingAgreementPDF.ID + '">here</a> to view it.'));
    }
    
     /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_OpportunityPDF(); }
}