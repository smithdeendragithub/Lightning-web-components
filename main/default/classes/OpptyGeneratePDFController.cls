public with sharing class OpptyGeneratePDFController {

    private static final string ACTION_PREVIEW = 'Preview';
    private static final string ACTION_STORE = 'Store';
    public transient Blob fileContents {get;set;} 
    public transient Blob fileContentsUpload {get;set;}
    public ContentVersion cv {get;set;}
    public string titlePrefix { get; set; }
    public string objectId { get; set; }
    public List<SelectOption> workspaces {get;set;}
    public Id selectedWorkspace {get;set;}
    public String parentId {get;set;}
    public string oTypeName {get; set;}
    private String defaultWorkspaceSelection {get;set;}
    public list<SelectOption> potentialRecipients { get; set; }
    public List<GlobalUtilities.Recipient> recipients {get;set;}
    public string selectedContactRecipent { get; set; }
    public List<SelectOption> documentActions {
        get {
            List<SelectOption> options = new List<SelectOption>(); 
            options.add(new SelectOption(ACTION_PREVIEW,ACTION_PREVIEW)); 
            options.add(new SelectOption(ACTION_STORE,ACTION_STORE)); 
            return options;             
        }
    }
    
    public string currentOpportunityId {get; set;}
    public transient LIST<OpportunityLocationConfiguration__c> lstSolution;
    public Opportunity currentOppty { get; set; }
    public boolean canGenerateSA {get;set;}
    public string canGenerateETFIncentives {get;set;}
    public boolean canGeneratePrdOrderProfile {get;set;}
    public boolean overrideGenerateSA {get;set;}
	public Boolean canGenerateMonthToMonth {get;Set;}
    //public Case selectedCase {get;set;}
    public String selectedAction {get;set;}
    public String selectedDocType {get;set;}
    public String activeProps {get;Set;}
    public String existingProps {get;Set;}
    public String JSONSelectedProps {get;Set;}
    private Set<String> selectedProps{
        get{        
            return (Set<String>)JSON.deserialize(JSONSelectedProps, Set<String>.class);     
        }
    }
    private Set<String> activePropNames{
        get{
            return (Set<String>)JSON.deserialize(activeProps, Set<String>.class);
        }
    }
    public List<String> selectedProposalSections {get;set;}
    public List<ProposalElementSelectItem> proposalSections {
        get {
            
            List<ProposalElementSelectItem> retVal = new List<ProposalElementSelectItem>();
            
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_COVER_PAGE), 'Cover Page'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_ERATE), 'eRate Welcome Letter'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_ERATESVCREQ), 'ERate Prefunding Svc Request'));  
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_LETTER), 'Letter'));            
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_EXECSUMMARY), 'Executive Summary'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_QUOTE), 'Quote'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_COSTCOMPARISON), 'Cost Comparison'));                                  
            return retVal; 
        }
    }
    public string NextPage { get; set; }
    public static string storeDocURL {get;set;}
    public blob pageBytes {get;set;}

    public List<String> selectedContractSections {get;set;}
    public List<ProposalElementSelectItem> contractSections {
        get {
            List<ProposalElementSelectItem> retVal = new List<ProposalElementSelectItem>();

            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_SERVICEAGREEMENT), 'Service Agreement')); 
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_LOA), 'LOA'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_DIRECTORYFORM), 'Directory Listing Form'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_MSA), 'MSA'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_MSA_COLLABORATIONADDENDUM), 'MSA Collaboration and Messaging Service Addendum'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_MSA_COLOCATIONADDENDUM), 'MSA Colocation Service Addendum'));
            //retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_MSADDOSMIT), 'MSA DDoS Mitigation Addendum'));
			//retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_MSA_ETHERNETSERVICESADDENDUM), 'MSA Ethernet Services Addendum'));
			//retVal.add(new ProposalElementSelectItem(String.valueOf(GlobalUtilities.DOCGENBIT_MSA_HSISADDENDUM), 'MSA High Speed Internet Service Addendum'));
            //retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_MSA_HVSADDENDUM), 'MSA Hosted Voice Services Addendum'));
			//retVal.add(new ProposalElementSelectItem(String.valueOf(GlobalUtilities.DOCGENGIN_MSA_UC_CLOUDVOICE), 'MSA UC Cloud Voice Addendum'));
			retVal.add(new ProposalElementSelectItem(String.valueOf(GlobalUtilities.DOCGENBIT_MSA_CPPOES), 'MSA UC Cloud Voice Customer Provided POE Addendum'));
            //retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_MSAFORVPN), 'MSA VPN Solutions Service Addendum'));
            //retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_WAVELENGTH), 'MSA Wavelength Service Addendum'));
			//retVal.add(new ProposalElementSelectItem(String.valueOf(GlobalUtilities.DOCGENBIT_MSA_WIRELESSBACKUPADDENDUM), 'MSA Wireless Backup Addendum'));
            retVal.add(new ProposalElementSelectItem(String.valueOf(GlobalUtilities.DOCGENBIT_MSA_MONTHTOMONTHRENEWAL), 'Month to Month Renewal'));
			//retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_INSIDEADDENDUM), 'Inside Wiring Addendum'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_911FORM), '911 Form'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_SUMMARYOFWORK), 'Summary of Work'));
            return retVal; 
        }
    }
    
    public List<String> selectedOtherSections {get;set;}    
    public List<ProposalElementSelectItem> otherSections {
        get {
            List<ProposalElementSelectItem> retVal = new List<ProposalElementSelectItem>();
			//retVal.add(new ProposalElementSelectItem(String.valueOf(GlobalUtilities.DOCGENBIT_PAPERLESSBILLING), 'Paperless Billing'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_ROLOA), 'Records Only LOA')); 
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_ETFCREDIT), 'ETF Assistance Credit Addendum'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_INCENTIVE_MRC), 'Incentive Credit MRC Multiple Addendum'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_INCENTIVE_AMOUNT), 'Incentive Credit Dollar Amount Addendum'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_SATGUARANTEE), 'Customer Satisfaction Guarantee'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_MOVE), 'Move Addendum'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_BUSDOWNTURN_SR), 'Business Downturn Addendum Service Reduction'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_BUSDOWNTURN_LD), 'Business Downturn Addendum Location Downturn'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_CFSCB), 'Cloud Firewall Service - Configuration Brief'));
            //retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_CFSServiceLA), 'Cloud Firewall Service - Service Level Agreement'));
            return retVal; 
        }
    }
    public List<String> selectedIndirectSections {get;set;}    
    public List<ProposalElementSelectItem> indirectSections {
        get {
            List<ProposalElementSelectItem> retVal = new List<ProposalElementSelectItem>();
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_LOACPNI), 'LOA CPNI'));
            retVal.add(new ProposalElementSelectItem(String.valueof(GlobalUtilities.DOCGENBIT_PARTNERORDER), 'Partner Order Profile'));
            
            return retVal; 
        }
    }
    
    public boolean ShowDisplayButton { get; set; }
    public boolean ShowSelectionPanel { get; set; }
    
//    public transient blob docData { get; set; }
    
    public String AutoCheckPDFs {get;set;}
	
	public List<Integra_Contract__c> integraContract {get;Set;}
	public Id ccRecTypId {get;Set;}
    
	
	//Save content

	
	
	
    public OpptyGeneratePDFController(ApexPages.StandardController stdController){
        
        currentOpportunityId = stdController.getId();
        parentId = currentOpportunityId;
        currentOppty = getCurrentOpportunity();
        canGenerateSA = getCanGenerateSA(currentOppty);
        canGenerateETFIncentives = getCanGenerateETFIncentives(currentOppty);
        canGeneratePrdOrderProfile = getCanGeneratePrdOrderProfile(currentOppty);
        selectedProposalSections = new List<String>();
        selectedContractSections = new List<String>();
        selectedOtherSections = new List<String>();
        selectedIndirectSections = new List<String>();
        ShowSelectionPanel = true;
        selectedAction = 'Preview';
        recipients = GlobalUtilities.LoadRecipients(currentOppty);
        potentialRecipients = createRecipientOptions();
       /* if(check911ProductOnSolution()) 
        {
                    selectedOtherSections.add(String.valueof(GlobalUtilities.DOCGENBIT_911FORM));
        }
        */
        AutoCheckPDFs = GetPDFsByOpportunity();
        List<String> lactiveProps = new List<String>();
        List<String> lexistingProps = new List<String>();
        for(ProposalElement__c propE : getProposalElements()){
            if(propE.Active__c)
                lactiveProps.add(propE.Name);
            lexistingProps.add(propE.Name);
        }
        activeProps = JSON.serialize(lactiveProps);
        existingProps = JSON.serialize(lexistingProps);
        
		ccRecTypId = Schema.SObjectType.Integra_Contract__c.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
		integraContract = (List<Integra_Contract__c>) ApexUtils.retrieveFullObjects(Integra_Contract__c.sObjectType, 'Account__c=\'' + currentOppty.AccountId + '\' and Status__c != \'Inactive\' and RecordTypeId =\'' + ccRecTypId + '\'');
        
		canGenerateMonthToMonth = getCanGenerateMonthToMonth(integraContract);

		
		initStore();
		cv = InitContentVersion();
        //selectedCase = new Case();
    }
	
	
	private void initStore(){
		workspaces = LoadWorkspaces('Sales Workspace%');
		titlePrefix = '';
		titlePrefix = currentOppty.Name + ' - ';
	}
    
    //Get distinct list of products on opportunity to determine which PDFs to auto include
    public String GetPDFsByOpportunity(){
        Set<String> oppSPCProducts = new Set<String>();
        for(AggregateResult oliAR : [Select SPC_Sales_Product__r.Name From OLI__c Where OpportunityLocationConfiguration__r.Opportunity_Location__r.Order__r.Opportunity__c = :currentOppty.id and OpportunityLocationConfiguration__r.Active__c = true and OpportunityLocationConfiguration__r.Opportunity_Location__r.On_Hold__c = false Group By SPC_Sales_Product__r.Name]){
            oppSPCProducts.add(string.valueOf(oliAR.get('Name')));
        }
        
        User u = [Select Id,Sales_Channel__c From User where Id= :UserInfo.getUserId()];
        List<PDF_Mapping__c> pdfMaps = [Select Id,Name, Sales_Channel__c, Selected_PDFS__c, SPC_Product__r.Name From PDF_Mapping__c];
        List<String> pdfNames = new List<String>();
        
        for(PDF_Mapping__c m : pdfMaps){
            if((oppSPCProducts.contains(m.SPC_Product__r.Name) || m.SPC_Product__r.Name == null) && (m.Sales_Channel__c == null || m.Sales_Channel__c == u.Sales_Channel__c)){
                if(m.Selected_PDFS__c != null){
                    for(string s :m.Selected_PDFS__c.split(',')){
                        if(s != null && s != '')
                            pdfNames.add(s);
                    }
                }
            }
        }
        return JSON.serialize(pdfNames);
    }

    public list<SelectOption> createRecipientOptions(){
        list<SelectOption> optionList = new list<SelectOption>();
        integer recipientCount = 0;
        for(GlobalUtilities.Recipient r : recipients){
            SelectOption option = new SelectOption(r.c.Id, r.c.Name);
            optionList.add(option);
            if(recipientCount == 0){
                selectedContactRecipent = r.c.Id;
            }
            recipientCount++;
        }
        if(optionList.size() < 1){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no contacts related to this opportunity'));
        }
        return optionList;
    }

    public Opportunity getCurrentOpportunity(){
        try {
            return [Select Id, Name, AccountId,Account.Name, Contract_Signed_Date__c, Owner.Name, Owner.Preferred_First_Name__c, Owner.LastName, Owner.Street, Owner.State, Owner.PostalCode, Owner.Email, Owner.City, Owner.Phone, Owner.Fax, Owner.Title, Term2__c, Type, Description_of_Sale__c, SLA2_Status__c, OwnerId from Opportunity where Id = : currentOpportunityId];
        }
        catch(Exception e) {
            ApexUtils.messageDisplay('Unable to find Opportunity');
            return null;
        }
    }
	
	public Boolean getCanGenerateMonthToMonth(List<Integra_Contract__c> integraContracts){
		if(integraContracts != null && integraContracts.size() > 0)
		{
			if(integraContracts[0].Auto_Renewal_Exemption__c)
				return true;
		}
		
		return false;
	}
    
    public Boolean getCanGenerateSA(Opportunity opp){
        //If any sols are returned active and have OLI's not approved dont allow SA
        lstSolution=new List<OpportunityLocationConfiguration__c>();
        overrideGenerateSA = CustomSettingUtils.getOverrideSettingValue('MLDA Service Agreement');      
        Map<Id, ICB__c> icbs = new Map<Id, ICB__c>();
        List<OpportunityLocationConfiguration__c> sols =new List<OpportunityLocationConfiguration__c>();
        
        for(OpportunityLocationConfiguration__c oloc:[Select nonPreferredAccess__c,Opportunity_Location__r.On_Hold__c ,Id, Term__c From OpportunityLocationConfiguration__c 
                                                        Where Active__c=true AND Opportunity_Location__r.Opportunity__r.id = :opp.id]) 
                                                        {
                                                            if(oloc.nonPreferredAccess__c && !oloc.Opportunity_Location__r.On_Hold__c)
                                                            {
                                                                sols.add(oloc);
                                                            }
                                                            lstSolution.add(oloc);
                                                        }
        
        
        
        if(sols.size() > 0){
            for(ICB__c icb : [Select Id From ICB__c Where Id =: opp.Id And ICB_Type__c =: 'Pricing' And Approved_Date__c !=: null]){
                icbs.put(icb.id, icb);
            }           
            if(icbs.size() <= 0){
                return false;
            }
        }
        return true;
    }

    public Boolean getCanGeneratePrdOrderProfile(Opportunity opp){
        //Indirect or Integra
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        for(Opportunity oppt : [Select Id, Name From Opportunity Where Id =: opp.Id And Sales_Channel__c =: 'Indirect Sales' Limit 1]){
            opps.put(oppt.id, oppt);
        }
        if(opps.size() > 0){
            return true;
        }
        return false;
    }
    
    public String getCanGenerateETFIncentives(Opportunity opp){
        string creditType = '';
        Id winningICB;
        ICB__c icb = null;
        for(Opportunity o : [Select Winning_ICB__c From Opportunity Where Id = :opp.id Limit 1]){
                winningICB = o.Winning_ICB__c;
        }
        if(winningICB == null){
            for(List<ICB__c> icbs : [Select Credit_Type_Approval__c,Number_of_Months__c, Number_of_Days__c, Credit_Amount_Approved__c, NRC_Credit_Amount__c, 
            Incentive_Credit_Type__c, Additional_Conditions_Required__c, Comments__c From ICB__c where Opportunity__c = :opp.Id]){
                if(icbs.size() == 1){
                    for(ICB__c oneICB : icbs){
                    icb = oneICB;
                    }
                }
            }
        }
        else{
            icb = [Select Credit_Type_Approval__c, Number_of_Months__c,Number_of_Days__c, Credit_Amount_Approved__c, NRC_Credit_Amount__c, Incentive_Credit_Type__c, Additional_Conditions_Required__c, Comments__c From ICB__c Where Id = :winningICB];
        }
        if(icb != null){
            if(icb.Credit_Type_Approval__c == 'ETF Program' && icb.Credit_Amount_Approved__c != null && icb.Additional_Conditions_Required__c != 'Yes'){
                creditType = icb.Credit_Type_Approval__c;
            }
            else if(icb.Credit_Type_Approval__c == 'ETF Program' && icb.Credit_Amount_Approved__c != null && icb.Additional_Conditions_Required__c == 'Yes' && icb.Number_of_Days__c != null && icb.Comments__c != null){
                creditType = icb.Credit_Type_Approval__c;
            }
            else if(icb.Credit_Type_Approval__c == 'Incentive Credit' && icb.Incentive_Credit_Type__c == 'Free Month(s)' && icb.Number_of_Months__c != null){
                creditType = icb.Credit_Type_Approval__c + ' MRC';
            }
            else if(icb.Credit_Type_Approval__c == 'Incentive Credit' && icb.NRC_Credit_Amount__c != null && icb.Incentive_Credit_Type__c == 'One Time'){
                creditType = icb.Credit_Type_Approval__c + ' OneTime';
            }
        }   
        return creditType;
    }
    
        public blob pr(string storeURL) {

            Pagereference retVal = new Pagereference(storeURL);         
            return retVal.getContent();

    }
    
    public PageReference generate() {
		PageReference pref = null;
	        if(storeDocURL== null){         
	            storeDocURL = generateNextPageUrl();
	        }       
           blob bytes;
           try{
                bytes = pr(storeDocURL);    
            }
          
            catch (VisualforceException e) {
              //bytes = Blob.valueOf('Error generating document');
                ApexUtils.messageDisplay('Error generating document: ' + e.getMessage());
            }
            catch(Exception exp){
                ApexUtils.messageDisplay('Error, check your selected options.');
            }

        if(selectedContactRecipent == null){
            ApexUtils.messageDisplay('Please select a recipient');
            return null;                
        }

        if( storeDocURL == null ) {
            ApexUtils.messageDisplay('Please select document sections');
            return null;                            
        }

        createIntegraContractRecord();
 		
		
        
		if(selectedAction.equals(ACTION_STORE) ) {       
			if(SaveContentVersion(bytes)){
				pref = new PageReference('/' + currentOppty.id);
	        	pref.setRedirect(true);
			}
           	else {
            	nextPage = '';    
            	storeDocURL = '';  
				return null;     
			}
        }

        //not storing the drafts anymore.
        //if( selectedAction.equals(ACTION_PREVIEW) ) {
        //  createDraftPDF(bytes);
        //}
       
		createProposalElements();
		
        return pref;                    
    }
    
    @TestVisible
    private void createProposalElements(){
        List<ProposalElement__c> pElements = new List<ProposalElement__c>();
        List<ProposalElement__c> updatePE = new List<ProposalElement__c>();
        Order__c o = [Select ord.Id from Order__c ord where ord.Opportunity__c = :currentOppty.Id limit 1]; 
        Map<string,ProposalElement__c> propElements = new Map<string,ProposalElement__c>();
        //List<ProposalElement__c> propEs = [Select Id, Opportunity__c, Name From ProposalElement__c Where Opportunity__c = :currentOppty.Id ];
        List<ProposalElement__c> propEs = getProposalElements();//[Select Id, Order__c, Name From ProposalElement__c Where Order__c = :o.Id ];
        for(ProposalElement__c props : propEs){
        
            props.Active__c = activePropNames.contains(props.Name);
             
            propElements.put(props.Name,props);
        }		
		
		if(integraContract == null || integraContract.size() == 0){
			integraContract = (List<Integra_Contract__c>) ApexUtils.retrieveFullObjects(Integra_Contract__c.sObjectType, 'Account__c=\'' + currentOppty.AccountId + '\' and Status__c != \'Inactive\' and RecordTypeId =\'' + ccRecTypId + '\'');
		}
        
        
		
		String u = UserInfo.getUserID();
		
		
        
        for(ContentVersion contractVersion :[Select Title, Integra_Contract_Version__c From ContentVersion Where Intended_Audience__c=:'Master Contract' and IsActiveVersion__c=true and Title in :selectedPdfs]){
            if(propElements.get(contractVersion.Title) != null){
                for(ProposalElement__c pe : propElements.values()){
    
                    if(pe.Name == contractVersion.Title){   
                        pe.Contract_Version__c = contractVersion.Integra_Contract_Version__c;
                        pe.Active__c = true;
                        pe.Generated_by__c = u;
                        pe.Last_Generated_On__c = Datetime.now();
                        //updatePE.add(pe);
                    }
                }
            }
            else{
                ProposalElement__c pe = new ProposalElement__c();
                pe.Name = contractVersion.Title;
                pe.Integra_Contract__c = integraContract[0].Id;
                pe.Contract_Version__c = contractVersion.Integra_Contract_Version__c;
                //pe.Opportunity__c = currentOppty.id;
                pe.Order__c = o.id;
                pe.Generated_by__c = u;
                pe.Last_Generated_On__c = Datetime.now();
                pElements.add(pe);
            }
        }
        update propElements.values();
        //update updatePE;      
        insert pElements;
    }
    
 /*
    private void createDraftPDF(blob bytes){
        //storeDocURL = nextPage;  
        fileContentsUpload = bytes;
        fileContents = fileContentsUpload;
        objectId = getObjectId();
        getObjectProperties();
        workspaces = LoadWorkspaces('Sales Workspace%');
        if(!String.IsEmpty(defaultWorkspaceSelection)){
            for(SelectOption so : workspaces){
                if(so.getLabel() == defaultWorkspaceSelection)
                    selectedWorkspace = so.getValue();
            }
        }
        cv = InitContentVersion();
        Schema.DescribeSObjectResult r = Account.SObjectType.getDescribe();
        if(parentId.startsWith(Account.SObjectType.getDescribe().getKeyPrefix()))
            cv.Account__c = parentId;
        else if(parentId.startsWith(Opportunity.SObjectType.getDescribe().getKeyPrefix()))
            cv.Opportunity__c = parentId;
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Must be associated to Account or Opportunity'));                          
        }       
       
        cv.VersionData = fileContents;  
        cv.FirstPublishLocationId = selectedWorkspace;
        cv.Title = titlePrefix + 'DRAFT-'+datetime.now();
        cv.Intended_Audience__c = 'Customer Facing';
        cv.Asset_Type__c = 'Sales Forms and Pricing';
        cv.Asset_SubType__c = 'Technical Supporting Documents';
        cv.PathOnClient = titlePrefix + cv.Title + '.pdf';
        if(cv.Account__c == null){
            cv.Account__c = currentOppty.AccountId;
        }
        if(cv.Opportunity__c == null){
            cv.Opportunity__c = currentOppty.Id;
        }
        try{ 
           insert cv;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
    }
*/
    
    private void createIntegraContractRecord(){
        Id recipId = selectedContactRecipent;
   		if(lstSolution == null){
			lstSolution = [Select nonPreferredAccess__c,Opportunity_Location__r.On_Hold__c ,Id, Term__c From OpportunityLocationConfiguration__c 
                                                        Where Active__c=true AND Opportunity_Location__r.Opportunity__r.id = :currentOpportunityId];
		}
		Decimal solutionTerm = 0;
		if(lstSolution != null && lstSolution.Size() > 0)
			solutionTerm = decimal.valueof(lstSolution[0].Term__c == 'Month to Month' ? '1' : lstSolution[0].Term__c) == null ? 0 : decimal.valueof(lstSolution[0].Term__c == 'Month to Month' ? '1' : lstSolution[0].Term__c);
		
        if(integracontract.size() == 0 || integracontract == null){
            Integra_Contract__c icr = new Integra_Contract__c(Account__c = currentOppty.AccountId
                                                            ,Contract_Type__c = 'Customer'
                                                            ,RecordTypeId = ccRecTypId
                                                            ,Effective_Date_Note__c = 'Required'
                                                            //,icr.SLA_Notes__c = 'Required'
                                                            //,Contract_Term__c = decimal.valueof(lstSolution[0].Term__c) == null ? 0 : decimal.valueof(lstSolution[0].Term__c)
                                                            //,Effective_Date__c = date.valueof(datetime.now())
                                                            ,Effective_Date_Type__c = 'Installation Date'
                                                            //,Execution_Date__c = currentOppty.Contract_Signed_Date__c
                                                            //,Integra_Signatory__c = selectedContactRecipent
                                                            ,Original_Term__c = solutionTerm
                                                            ,Customer_Signer__c = selectedContactRecipent
                                                            ,Status__c = 'Draft'
                                                            );
            insert icr;
        }
    }
    
    //@TestVisible
    private boolean getObjectProperties(){
        
        string retVal;
        Boolean flag = false;
        
        if(objectId.startsWith(Account.SObjectType.getDescribe().getKeyPrefix())){
            Account a = [Select Name, Id, OwnerId from Account where Id = : objectId];
            
            defaultWorkspaceSelection = CustomSettingUtils.getSingleProcessConfigurationValue('UploadContentSalesChannelLibrary-Account', [select Id, Sales_Channel__c from User where Id = : a.OwnerId].Sales_Channel__c, true);
            titlePrefix = a.Name + ' - ';
            retVal = 'Account';
        }
        else if( objectId.startsWith(Opportunity.SObjectType.getDescribe().getKeyPrefix())){
            Opportunity o = [Select Name, Id, OwnerId from Opportunity where Id = : objectId];
            
            defaultWorkspaceSelection = CustomSettingUtils.getSingleProcessConfigurationValue('UploadContentSalesChannelLibrary-Opportunity', [select Id, Sales_Channel__c from User where Id = : o.OwnerId].Sales_Channel__c, true);
            titlePrefix = o.Name + ' - ';
            retVal = 'Opportunity';
        }

        else{
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Must be associated to Account or Opportunity'));
        }
        oTypeName = retVal;
        
        if(!String.IsEmpty(oTypeName)){
            flag = true;
        }  
        return flag;
    }
    
    public string getObjectId(){
        return ApexPages.currentPage().getParameters().get('id');  
    }

    public static List<SelectOption> LoadWorkspaces(string filter) {
        
        List<SelectOption> retVal = new List<SelectOption>();
        
        for( ContentWorkspace cw : [Select Id, Name from ContentWorkspace where Name LIKE:filter])
            retVal.add( new SelectOption(cw.Id, cw.Name));
        
        if(retVal.size() < 1)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have access to contribute to the Sales Workspace'));
  
        return retVal;
    }
    
    private ContentVersion InitContentVersion() {
        
        ContentVersion c = new ContentVersion();
        
        return c;
    }
    
    public List<String> selectedPdfs {get;set;}
    public string generateNextPageUrl(){
        
        System.debug('JSONSelectedProps: ' + JSONSelectedProps);
        list<string> selections = new list<string>();
        if(JSONSelectedProps != '')
			selections.addAll(selectedProps);
		else
			return null;

        
        /*
        if(selectedProposalSections.size() > 0){
            selections.addAll(selectedProposalSections);            
        }
        if(selectedContractSections.size() > 0){
            selections.addAll(selectedContractSections);            
        }
        if(selectedOtherSections.size() > 0){
            selections.addAll(selectedOtherSections);           
        }
        if(selectedIndirectSections.size() > 0){
            selections.addAll(selectedIndirectSections);           
        }
        if(selections.size() == 0){
            return null;
        }
        */

        Long allSections = 0;
        string url = '';
       for(string s : selections){                    
            allSections = allSections | Long.valueOf(s);
        }
        
        
        // Adding a random number at the end to prevent caching of the page
            selectedPdfs = new  List<String>();        
            for(string s : selections){             
                for(ProposalElementSelectItem so : proposalSections){               
                    if(so.getValue() == s)                  
                        selectedPdfs.add(so.getLabel());
                }
                for(ProposalElementSelectItem so : contractSections){
                    if(so.getValue() == s)
                        selectedPdfs.add(so.getLabel());
                }
                for(ProposalElementSelectItem so : otherSections){
                    if(so.getValue() == s)
                        selectedPdfs.add(so.getLabel());
                }
                for(ProposalElementSelectItem so : indirectSections){
                    if(so.getValue() == s)
                        selectedPdfs.add(so.getLabel());
                }               
                if(storeDocURL == null){
                    url = '/apex/ProposalGeneratePDF?id=' + currentOpportunityId + '&recipient=' + selectedContactRecipent + '&document=' + String.valueOf(allSections) + '&rand=' + Math.random();    
            }
        }       
        return url; 
    }
    
    private List<ProposalElement__c> getProposalElements(){
        Order__c o = [Select ord.Id from Order__c ord where ord.Opportunity__c = :currentOppty.Id limit 1]; 
        //List<ProposalElement__c> propEs = [Select Id, Opportunity__c, Name From ProposalElement__c Where Opportunity__c = :currentOppty.Id ];
        List<ProposalElement__c> propEs = null;
        propEs = [Select Id, Active__c, Order__c, Name From ProposalElement__c Where Order__c = :o.Id];        
        return propEs;  
    }
	
	 private Boolean SaveContentVersion(blob bytes) {
        System.debug('SaveContentVersion Blob: ' + bytes);
        if( ((cv.Title == null) || (cv.Title == ''))) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Title'));
            return false;               
        }
                
        if( ((cv.Description == null) || (cv.Description == ''))) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Description'));
            return false;               
        }
        
        if( (bytes == null) || (bytes.size() == 0) ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select file to upload'));
            return false;               
        }
        
        cv.Opportunity__c = currentOppty.Id;
        
        cv.VersionData = bytes;  
        cv.FirstPublishLocationId = selectedWorkspace;
		
       	cv.Asset_Type__c = 'Sales Forms and Pricing';
        cv.Asset_SubType__c = 'Technical Supporting Documents';
       cv.Intended_Audience__c = 'Customer Facing';
		cv.PathOnClient = cv.Title + '.pdf';
        
      
        cv.Title = (titlePrefix + cv.Title);
        
        try{       	
            insert cv;
            return true;
        }
        catch(Exception e){
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'You do not have publish persmissions in the selected library.'));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
        return false;
    }
	
	
	
    
    public class ProposalElementSelectItem{
        public Boolean Active { get;Set;}
        public Boolean Selected {get;Set;}
        public String Value {get;Set;}
        public String Label {get;Set;}
        public String getValue(){ 
            return this.Value;            
        }
        public String getLabel(){
            return this.Label;
        }
        
        private ProposalElementSelectItem(){
            this(false, false, '', '');
        }
        public ProposalElementSelectItem(String theValue, String theLabel){
            this(false, false, theValue, theLabel); 
        }
        public ProposalElementSelectItem(Boolean isActive, String theValue, String theLabel){
            this(isActive, false, theValue, theLabel);  
        }
        public ProposalElementSelectItem(String theValue, String theLabel, Boolean isSelected){
            this(false, isSelected, theValue, theLabel);    
        }
        public ProposalElementSelectItem(Boolean isActive, Boolean isSelected, String theValue, String theLabel){
            Active = isActive;
            Selected = isSelected;
            Value = theValue; 
            Label = theLabel;
        }
    }
	
	
	
}