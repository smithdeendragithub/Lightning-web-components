public without sharing virtual class OpportunityPDFController implements TestUtils.ITestableClass {
    
    public string opptyId { get; set; }
    public string contId { get; set; }
    public String returnURL { get; set; }
    
    public class VisualforceException extends Exception {}

    public Opportunity opp { get; set; }
    public List<Id> validContactIDs { get; set; }
    
    public Contact decMaker { get; private set; }
    
    private transient List<OpportunityLocationConfiguration__c> p_solutions = null;
    public List<OpportunityLocationConfiguration__c> solutions {
        get{
            if(p_solutions == null){
                p_solutions = [Select Id, Opportunity_Location__c, Opportunity_Location__r.Service_Location__r.Location__r.Name, Term__c from OpportunityLocationConfiguration__c where Opportunity_Location__r.Order__r.Opportunity__c =: opp.Id AND Opportunity_Location__r.On_Hold__c = false AND Active__c = true];
            }
            return p_solutions;
        }
    }
    
    private transient ICB__c p_icb = null;
    public ICB__c icb{
        get{
            if(p_icb == null && opp.Winning_ICB__c != null){
                for(ICB__c i : (List<ICB__c>)ApexUtils.retrieveFullObjects(ICB__c.sObjectType, 'Id = \'' + opp.Winning_ICB__c + '\'')) p_icb = i;
            }
            return p_icb;
        }
    }
    
    public String uniqueDocId { get; set; } //Do we need this?

    public transient Blob pdfBlob { get; set; }
    
    public Set<String> sectionHeaders { get; set; }
    public Map<String, List<RefElement>> selectableElements { get; set; }
    
    public class RefElement{
        public Boolean Active { get; set; }
        public Boolean Selected { get; set; }
        public String Label { get; set; }
        public String CriteriaHelpText { get; set; }
        public Id ID { get; set; }
        public List<RefElement> Clauses { get; set; }
        public List<RefElement> SubElements { get; set; }
        public transient Ref_PDF_Element__c obj { get; set; }
        
        public RefElement(){
            Clauses = new List<RefElement>();
            SubElements = new List<RefElement>();
            Active = true;
            Selected = false;
        }
    }

    public string pdfString {
        get{
            string s = pdfBlob == null ? '' : EncodingUtil.base64Encode(pdfBlob);
            System.debug('blob String: ' + s);
            return s;
        }
    }

    public OpportunityPDFController(){
        opptyId = ApexPages.currentPage().getParameters().get('oppId');
        
        if(!string.isEmpty(opptyId)){
            if(!SecurityUtils.currentUserHasRecordAccess(opptyId, true)) throw new VisualforceException('Edit access to Opportunity "' + opptyId + '" is required to generate PDFs.');
            
            contId = ApexPages.currentPage().getParameters().get('contId');
            returnURL = ApexPages.currentPage().getParameters().get('retURL');
            
            loadObjects();
            loadRefElements();
            init();
        }
    }
    
    protected virtual void init(){
        Set<Id> contactIDs = new Set<Id>();
        for(Contact c : [select Id from Contact where AccountId =: opp.AccountId]) contactIDs.add(c.Id);
        for(OpportunityContactRole r : [select ContactId from OpportunityContactRole where OpportunityId =: opp.Id]) contactIDs.add(r.ContactId);
        validContactIDs = new List<Id>(contactIDs);
        
        getAvailableElementProperties();
    }
    
    private void loadObjects(){
        opp = 
            [Select Name, Term__c, Amount, Current_Connection_Provider__c, Account.Government_Contract_Type__c, Account.Customer_Detail__r.Government_Contract_Type__c,
            Business_Objectives__c, Proposed_Solutions__c, Sales_Channel__c, AccountId, Proposal_Letter__c, Account2__r.Name,
            Winning_ICB__c, Winning_ICB__r.Product__c, Winning_ICB__r.Status__c, Opportunity_Product__c, X470__c,
            Account.Name, Account.ShippingState, Account.ShippingCity, Account.ShippingStreet, Account.ShippingPostalCode, 
            Account.BillingState, Account.BillingCity, Account.BillingStreet, Account.BillingPostalCode,
            //Account.Phone, Account.Fax, Account.Local_Service_Provider__c, Account.ICC_Account_Number__c, Account.Account_Sales_Channel__c, Account.AccountNumber,     
            Account.Phone, Account.Fax, Account.Local_Service_Provider__c, Account.ICC_Account_Number__c, Account.Account_Sales_Channel__c, Account.Owners_Sales_Channel__c, Account.AccountNumber,
            Account.Language_Preference__c, Service_Country__c,
            Owner.Name, Owner.Preferred_First_Name__c, Owner.LastName, Owner.Street, Owner.State, Owner.PostalCode, Owner.Email, Owner.City, Owner.Phone, Owner.MobilePhone, Owner.Fax, Owner.Title, 
            (Select Id, Opportunity__r.AccountId From Opportunity_Sites__r WHERE On_Hold__c=false and MRC_Total__c > 0 ORDER BY Opportunity__r.Account.Account_Depth__c, Opportunity__r.Account.Name)
            From Opportunity where id = :opptyId limit 1];
        
        uniqueDocId = 'DocumentID: ' + DateTime.Now().getTime() + Math.random().format();
        
        if(contId != null) getDecisionMakerContact();
    }
    
    private void getAvailableElementProperties(){
        
        Set<Id> mapSourceIDs = new Set<Id>();
        Set<Decimal> componentIDs = new Set<Decimal>();
        for(OLI__c oli : [select SPC_Sales_Product__c, SPC_Sales_Product_Component_Id__c from OLI__c where OpportunityLocationConfiguration__c in: solutions]){
            mapSourceIDs.add(oli.SPC_Sales_Product__c);
            if(oli.SPC_Sales_Product_Component_Id__c != null) componentIDs.add(oli.SPC_Sales_Product_Component_Id__c);
        }
        
        for(SPC_Component__c c : [select Id from SPC_Component__c where Sales_Product_Component_ID__c in: componentIDs]) mapSourceIDs.add(c.Id);
        
        Map<Id, Set<Id>> mapJunctions = new Map<Id, Set<Id>>();
        for(String section : selectableElements.keyset()){
            for(RefElement e : selectableElements.get(section)){
                mapJunctions.put(e.ID, null);
                for(RefElement c : e.SubElements) mapJunctions.put(c.ID, null);
            }
        }
        
        for(Junction__c j : [select Source_ID__c, Target_ID__c from Junction__c where Target_ID__c in: mapJunctions.keyset()]){
            Set<Id> s = mapJunctions.get(j.Target_Id__c) != null ? mapJunctions.get(j.Target_Id__c) : new Set<Id>();
            s.add(j.Source_ID__c);
            mapJunctions.put(j.Target_Id__c, s);
        }
        
        Boolean debugMode = ApexPages.currentPage().getParameters().get('debug') == '1';
        CustomSettingUtils.dynamicQueryDebug = debugMode;
        
        //todo: move into lazy load properties
        List<ICB__c> icbs = null;
        List<Integra_Contract__c> contracts = null;
        List<OLI__c> olis = null;
        List<Oppty_Cost_Comparison__c> costComps = null;
        List<Technical_Information__c> tis = null;
        List<Directory_Listing__c> dls = null;
        for(String section : selectableElements.keyset()){
            List<RefElement> l = selectableElements.get(section);
            for(RefElement p : l){
                Boolean autoIncludeParent = false;
                for(List<RefElement> eList : new List<List<RefElement>>{ new List<RefElement>{ p }, p.SubElements }){
                    Boolean parentMode = eList.size() == 1 && eList[0] == p;
                    for(RefElement e : eList){
                        if(!parentMode && !p.Active){
                            e.Active = false;
                            continue;
                        }
                        
                        e.Active = mapJunctions.get(e.ID) == null;  //Default to disabled if we have mapping to check
                        for(Id jID : mapJunctions.get(e.ID) != null ? mapJunctions.get(e.ID) : new Set<Id>()){
                            if(mapSourceIDs.contains(jID))
                                e.Active = true;
                        }
                        
                        if(!e.Active && debugMode) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, e.Label + ': This opportunity is not associated to any of the mapped products or components.'));
                        
                        if(e.Active && e.obj.Display_Criteria__c != null){
                            Set<Id> relatedIDs = new Set<Id>();
                            for(String s : CustomSettingUtils.getDynamicQueryObjects(e.obj.Display_Criteria__c)){
                                if(s == 'Opportunity') relatedIDs.add(opp.Id);
                                else if(s == 'OLI__c'){
                                    if(olis == null) olis = [select Id from OLI__c where OpportunityLocationConfiguration__c in: solutions];
                                    relatedIDs.addAll((new Map<Id, OLI__c>(olis)).keyset());
                                }
                                else if(s == 'Oppty_Cost_Comparison__c'){
                                    if(costComps == null){
                                        Set<Id> oppLocIDs = new Set<Id>();
                                        for(OpportunityLocationConfiguration__c olc : solutions) oppLocIDs.add(olc.Opportunity_Location__c);
                                        costComps = [select Id from Oppty_Cost_Comparison__c where Opportunity_Location__c in: oppLocIDs];
                                    }
                                    relatedIDs.addAll((new Map<Id, Oppty_Cost_Comparison__c>(costComps)).keyset());
                                }
                                else if(s == 'ICB__c'){
                                    if(icbs == null) icbs = [select Id from ICB__c where Opportunity__c =: opp.Id];
                                    relatedIDs.addAll((new Map<Id, ICB__c>(icbs)).keyset());
                                }
                                else if(s == 'Integra_Contract__c'){
                                    if(contracts == null) contracts = getContracts();
                                    relatedIDs.addAll((new Map<Id, Integra_Contract__c>(contracts)).keyset());
                                }
                                else if(s == 'Opportunity_Location__c'){
                                    Set<Id> oppLocIDs = new Set<Id>();
                                    for(OpportunityLocationConfiguration__c olc : solutions) oppLocIDs.add(olc.Opportunity_Location__c);
                                    relatedIDs.addAll(oppLocIDs);
                                }
                                else if(s == 'OpportunityLocationConfiguration__c') relatedIDs.addAll((new Map<Id, OpportunityLocationConfiguration__c>(solutions)).keyset());
                                else if(s == 'Technical_Information__c'){
                                    if(tis == null){
                                        Set<Id> oppLocIDs = new Set<Id>();
                                        for(OpportunityLocationConfiguration__c olc : solutions) oppLocIDs.add(olc.Opportunity_Location__c);
                                        tis = [select Id from Technical_Information__c where Opportunity_Site__c in: oppLocIDs];
                                    }
                                    relatedIDs.addAll((new Map<Id, Technical_Information__c>(tis)).keyset());
                                }
                                else if(s == 'Directory_Listing__c'){
                                    if(dls == null){
                                        Set<Id> oppLocIDs = new Set<Id>();
                                        for(OpportunityLocationConfiguration__c olc : solutions) oppLocIDs.add(olc.Opportunity_Location__c);
                                        dls = [select Id from Directory_Listing__c where Technical_Information__r.Opportunity_Site__c in: oppLocIDs];
                                    }
                                    relatedIDs.addAll((new Map<Id, Directory_Listing__c>(dls)).keyset());
                                }
                            }
                            
                            Boolean criteriaPassed = false;
                            try{
                                criteriaPassed = CustomSettingUtils.dynamicCriteriaRecordsExist(e.obj.Display_Criteria__c, relatedIDs, true);
                            }
                            catch(Exception ex){ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.Label + ': ' + ex.getMessage())); }
                            e.Active &= criteriaPassed;
                        }
                        
                        if(e.Active){
                            if(e.obj.Default_Selection__c == 'Auto-Included'){
                                e.Selected = true;
                                e.Active = false;
                                autoIncludeParent = !parentMode;
                            }
                            else e.Selected = e.obj.Default_Selection__c == 'Checked';
                        }
                        
                        for(RefElement c : e.Clauses){
                            c.Active = e.Active;
                            c.Selected = e.Selected;
                        }
                    }
                }
                
                //If we have a child selected and the parent CAN be selected, select it
                if(p.Active){
                    if(autoIncludeParent){
                        p.Active = false;
                        p.Selected = true;
                    }
                    for(RefElement c : p.SubElements) p.Selected |= c.Selected;
                }
            }
            
            for(Integer i=l.size()-1; i>=0; i--){
                for(Integer k=l[i].SubElements.size()-1; k>=0; k--){
                    if(l[i].SubElements[k].obj.Hide_When_Invalid__c && !l[i].SubElements[k].Active && !l[i].SubElements[k].Selected) l[i].SubElements.remove(k);
                }
                if(l[i].obj.Hide_When_Invalid__c && !l[i].Active && !l[i].Selected && l[i].SubElements.size() == 0) l.remove(i);
            }
        }
        
        for(String s : new List<String>(sectionHeaders)){
            if(selectableElements.get(s).size() == 0){
                sectionHeaders.remove(s);
                selectableElements.remove(s);
            }
        }
    }
    
    private List<Integra_Contract__c> getContracts(){
        return (List<Integra_Contract__c>) ApexUtils.retrieveFullObjects(Integra_Contract__c.sObjectType, 'Account__c=\'' + opp.AccountId + '\' and Status__c != \'Inactive\' and RecordType.Name =\'Customer\'');
    }
    
    private void loadRefElements(){
        selectableElements = new Map<string, List<RefElement>>();
        
        sectionHeaders = new Set<String>();
        for(Schema.PicklistEntry pe : Ref_PDF_Element__c.getSObjectType().getDescribe().fields.getMap().get('Section__c').getDescribe().getPickListValues())
            sectionHeaders.add(pe.getLabel());
        
        Map<Id, RefElement> m = new Map<Id, RefElement>();
        for(Ref_PDF_Element__c p : [select Id, Name, Parent_Element__c, Print_Order__c, Document_Name__c, Section__c, Signature_Grouping__c, Add_Signature__c, Default_Selection__c, Hide_When_Invalid__c, Display_Criteria__c, Criteria_Help_Text__c
                                            ,(select Id, Name, Component_Name__c from Ref_PDF_Clauses__r where Active__c = true)
                                            from Ref_PDF_Element__c
                                            where Active__c = true order by Print_Order__c, Parent_Element__c nulls first]){
            RefElement e = new RefElement();
            e.ID = p.Id;
            e.obj = p;
            e.Label = p.Document_Name__c;
            e.CriteriaHelpText = p.Criteria_Help_Text__c;
            m.put(p.Id, e);
            
            //if(p.Parent_Element__c != null) m.get(p.Parent_Element__c).SubElements.add(e);
            //else{
            // MSA addendums can be selected independently from the MSA (SEAL-305)
            List<RefElement> l = selectableElements.get(p.Section__c) != null ? selectableElements.get(p.Section__c) : new List<RefElement>();
            l.add(e);
            selectableElements.put(p.Section__c, l);
            //}
            
            for(Ref_PDF_Clause__c c : p.Ref_PDF_Clauses__r != null ? p.Ref_PDF_Clauses__r : new List<Ref_PDF_Clause__c>()){
                RefElement ce = new RefElement();
                ce.ID = c.Id;
                ce.Label = c.Component_Name__c;
                e.Clauses.add(ce);
            }
        }
        
        for(String s : new List<String>(sectionHeaders)){
            if(selectableElements.get(s) == null) sectionHeaders.remove(s);
        }
    }
    
    public void selectContact(){
        contId = Apexpages.currentPage().getParameters().get('contactID');
        getDecisionMakerContact();
    }
    
    private void getDecisionMakerContact(){
        decMaker = [SELECT Id, Name, FirstName, Title, Email, Phone from Contact where id =: contId limit 1];
    }
    
    public void getPDF(){
        PageReference pdf = new PageReference('/apex/OpportunityPDFDisplay');
        
        Set<Id> ids = getSelectedComponentIDs();
        string selectedComponents = String.join(new List<Id>(ids), ',');
        
        pdf.getParameters().put('pdfComps', selectedComponents);
        pdf.getParameters().put('oppId', opptyId);
        pdf.getParameters().put('contId', contId);
        
        pdf.setRedirect(false);
        pdfBlob = !Test.isRunningTest() ? pdf.getContent() : Test_OpportunityPDF.getTestPDFResults();
        System.debug('blob: ' + pdfBlob);
    }
    
    private Set<Id> getSelectedComponentIDs(){
        Set<Id> ids = new Set<Id>();
        for(String k : selectableElements.keySet()){
            for(RefElement p : selectableElements.get(k)){
                if(p.Selected){
                    ids.add(p.ID);
                    for(RefElement c : p.Clauses){
                        if(c.Selected) ids.add(c.ID);
                    }
                    
                    for(RefElement c : p.SubElements){
                        if(c.Selected) ids.add(c.ID);
                    }
                }
            }
        }
        return ids;
    }
    
    protected Map<Ref_PDF_Element__c, List<Ref_PDF_Clause__c>> loadSelectedElements(Set<Id> pdfCompIDs){
        
        Map<Ref_PDF_Element__c, List<Ref_PDF_Clause__c>> ret = new Map<Ref_PDF_Element__c, List<Ref_PDF_Clause__c>>();
        for(Ref_PDF_Element__c p : [select Id, Name, Print_Order__c, Document_Name__c, Signature_Grouping__c, Add_Signature__c
                                        ,(select Id, Name, Component_Name__c from Ref_PDF_Clauses__r where Id in: pdfCompIDs)
                                        from Ref_PDF_Element__c where Id in: pdfCompIDs order by Print_Order__c])
            ret.put(p, p.Ref_PDF_Clauses__r != null ? p.Ref_PDF_Clauses__r : new List<Ref_PDF_Clause__c>());
        
        return ret;
    }
    
    public PageReference savePDF(){
        
        List<AggregateResult> maxIds = [select MAX(External_Id__c)maxExtId from PDF_Element__c];
        Integer maxPDFEleExtId = maxIds.size() > 0 && maxIds[0].get('maxExtId') != null ? Integer.valueOf(maxIds[0].get('maxExtId')) : 1;
        maxIds = [select MAX(External_Id__c)maxExtId from PDF__c];
        Integer maxPDFExtId = maxIds.size() > 0 && maxIds[0].get('maxExtId') != null ? Integer.valueOf(maxIds[0].get('maxExtId')) : 1;
        
        PDF__c helperPDF = new PDF__c(External_Id__c = ++maxPDFExtId);
        
        getPDF();
        Map<Ref_PDF_Element__c, List<Ref_PDF_Clause__c>> pdfEles = loadSelectedElements(getSelectedComponentIDs());
        PDF__c pdf = new PDF__c();
        pdf.Active__c = true;
        pdf.Opportunity__c = opptyId;
        pdf.External_Id__c = maxPDFExtId;
        pdf.Name = 'Proposal - ' + datetime.now().format('YYYY-MM-dd');
        
        List<PDF_Element__c> pdfElements = new List<PDF_Element__c>();
        List<PDF_Clause__c> pdfClauses = new List<PDF_Clause__c>();
        for(Ref_PDF_Element__c ele : pdfEles.keyset()){
            PDF_Element__c pdfEle = new PDF_Element__c();
            pdfEle.PDF__r = helperPDF;
            pdfEle.Ref_PDF_Element__c = ele.Id;
            pdfEle.Name = ele.Name;
            
            if(pdfEles.containsKey(ele)){
                PDF_Element__c helperPDFEle = new PDF_Element__c(External_Id__c = ++maxPDFEleExtId);
                pdfEle.External_Id__c = maxPDFEleExtId;
                for(Ref_PDF_Clause__c pdfc : pdfEles.get(ele)){
                    PDF_Clause__c pdfClause = new PDF_Clause__c();
                    pdfClause.PDF_Element__r = helperPDFEle;
                    pdfClause.Ref_PDF_Clause__c = pdfc.Id;
                    pdfClause.Name = pdfc.Name;
                    pdfClauses.add(pdfClause);
                }
            }
            pdfElements.add(pdfEle);
        }
        
        //insert everything except for the attachment, becuase the attachment needs an id.
        List<sObject> PCinserts = new List<sObject>();
        PCinserts.add(pdf);
        PCinserts.addAll((List<sObject>)pdfElements);
        PCinserts.addAll((List<sObject>)pdfClauses);
        SecurityUtils.BypassProcesser.insertObjects(PCinserts, true);
        
        Attachment a = new Attachment();
        a.Body = pdfBlob;
        a.Description = uniqueDocId;
        a.Name = 'PDF for ' + opp.Name + ' ' + DateTime.now().format('YYYY-MM-dd') + '.pdf';
        a.OwnerId = UserInfo.getUserId();
        a.ParentId = pdf.Id;
        SecurityUtils.BypassProcesser.insertObjects(new List<sObject>{ a }, true);
        
        createIntegraContractRecord();
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'The Contract Proposal PDF has been saved to the Opportunity under the related CPQ Proposals/Contracts and is ready to use in the ‘Send Content’ area for Electronic Signature and/or Email. Click <a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + pdf.Id + '">here</a> to view it.'));
        loadRefElements();
        getAvailableElementProperties();
        decMaker = null;
        return null;
    }
    
    private void createIntegraContractRecord(){
        List<Integra_Contract__c> contracts = getContracts();
        if(contracts.size() == 0){
            insert new Integra_Contract__c(Account__c = opp.AccountId
                                            ,Contract_Type__c = 'Customer'
                                            ,RecordTypeId = Schema.SObjectType.Integra_Contract__c.getRecordTypeInfosByName().get('Customer').getRecordTypeId()
                                            ,Effective_Date_Note__c = 'Required'
                                            ,Effective_Date_Type__c = 'Installation Date'
                                            ,Original_Term__c = solutions.size() == 0 ? 0 : decimal.valueof(solutions[0].Term__c == 'Month to Month' ? '1' : solutions[0].Term__c) == null ? 0 : decimal.valueof(solutions[0].Term__c == 'Month to Month' ? '1' : solutions[0].Term__c)
                                            ,Customer_Signer__c = decMaker.Id
                                            ,Status__c = 'Draft'
                                        );
        }
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_OpportunityPDF(); }
}