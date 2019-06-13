public with sharing class OpportunityPDFDisplayController extends OpportunityPDFController {

    public transient ApexPages.Component comp {get; private Set;}
    
    //public String salesChannel { get{ return opp!= null ? String.IsEmpty(opp.Account.Account_Sales_Channel__c) ? 'IntegraBusiness' : opp.Account.Account_Sales_Channel__c.replaceAll(' ', '') : 'IntegraBusiness'; } }
    public String salesChannel { get{ return opp!= null ? String.IsEmpty(opp.Account.Owners_Sales_Channel__c) ? 'IntegraBusiness' : opp.Account.Owners_Sales_Channel__c.replaceAll(' ', '') : 'IntegraBusiness'; } }
    
    public CompanyInfo intDecMaker { get; private set; }
    public CompanyInfo clientMainAddress { get; private set; }
    
    public String PDFException{ get{ throw new VisualforceException('Invalid PDF Criteria'); return ''; } }
    
    private transient String p_brandingURL = null;
    public String brandingURL {
        get{
            if(p_brandingURL == null){
                //List<String> brandingURLs = CustomSettingUtils.getProcessConfigurationValues('SalesChannelBrandingURL', opp.Account.Account_Sales_Channel__c);
                List<String> brandingURLs = CustomSettingUtils.getProcessConfigurationValues('SalesChannelBrandingURL', opp.Account.Owners_Sales_Channel__c);
                List<String> defaultBrandingURLs = CustomSettingUtils.getProcessConfigurationValues('SalesChannelBrandingURL', 'Default');
                String defaultBrandingURL = defaultBrandingURLs != null && defaultBrandingURLs.size() > 0 ? defaultBrandingURLs[0] : '';
                p_brandingURL = brandingUrls != null && brandingURLs.size() > 0? brandingURLs[0] : defaultBrandingURL; 
            }
            return p_brandingURL;
        }
    }
    
    private transient String p_businessDownturn = null;
    public String businessDownturn{
        get{
            if(p_businessDownturn == null){
                for(Technical_Information__c ti : [Select Business_Downturn_Decrease_Revenue_Pct__c, ETF_Assistance_Credit_Max_Amount__c, Move_Addendum_Months__c From Technical_Information__c Where Opportunity_Site__r.Order__r.Opportunity__c =: opp.Id And (Business_Downturn_Decrease_Revenue_Pct__c != null Or ETF_Assistance_Credit_Max_Amount__c != null Or Move_Addendum_Months__c != null) limit 1]){
                    //techInfo = ti
                    
                    p_businessDownturn = ti.Business_Downturn_Decrease_Revenue_Pct__c != null ? ti.Business_Downturn_Decrease_Revenue_Pct__c : null;
                    //etfmax = ti.ETF_Assistance_Credit_Max_Amount__c != null ? ti.ETF_Assistance_Credit_Max_Amount__c : '';
                    //moveaddendum = ti.Move_Addendum_Months__c != null ? ti.Move_Addendum_Months__c : '';

                }
                p_businessDownturn = p_businessDownturn != null ? p_businessDownturn : 'twenty percent (20%)';
            }
            return p_businessDownturn;
        }
    }
    
    private transient List<Opportunity_Location__c> p_currentOpptyLocs = null;
    public List<Opportunity_Location__c> currentOpptyLocs{
        get{
            if(p_currentOpptyLocs == null){
                p_currentOpptyLocs =  [Select Id, Opportunity__r.AccountId, Order__r.Id From Opportunity_Location__c WHERE On_Hold__c=false and MRC_Total__c > 0 AND Order__r.Opportunity__r.Id =: opp.Id ORDER BY Opportunity__r.Account.Account_Depth__c, Opportunity__r.Account.Name];
            }
            return p_currentOpptyLocs;
        }
    }
    
    private transient IncentiveCreditText__c p_iCText = null;
    public IncentiveCreditText__c iCText{
        get{
            if(p_iCText == null && icb != null){
                for(IncentiveCreditText__c ict  : [select Credit_Text__c from IncentiveCreditText__c where Number_of_Months__c =: icb.Number_of_Months__c and Term__c =: opp.term__c])
                    p_iCText = ict;
            }
            return p_iCText;
        }
    }
    
    private transient String p_techInfo = null;
    public String techInfo{
        get{
            if(p_techInfo == null){
                Set<String> tis = new Set<String>();
                for(Technical_Information__c ti : [select CurrentProvider__c from Technical_Information__c where Opportunity_Site__r.Order__r.Opportunity__c =: opp.Id and CurrentProvider__c != null])
                    tis.add(ti.CurrentProvider__c);
                
                p_techInfo = tis.size() > 0 ? String.join(new List<string>(tis), '; ') : '';
            }
            
            return p_techInfo;
        }
    }
    
    private transient List<OLI__c> p_oppLocOLIs = null;
    public List<OLI__c> oppLocOLIs{
        get{
            if(p_oppLocOLIs == null) loadOLIsAndOLCs();
            return p_oppLocOLIs;
        }
    }
    
    private transient Map<Id, Opportunity_Location__c> p_oppLocMap = null;
    public Map<Id, Opportunity_Location__c> oppLocMap{
        get{
            if(p_oppLocMap == null) loadOLIsAndOLCs();
            return p_oppLocMap;
        }
    }

    public OpportunityPDFDisplayController(){ }
    
    //Called by base constructor
    protected override void init(){
        string pdfComps = ApexPages.currentPage().getParameters().get('pdfComps');
        
        intDecMaker = new CompanyInfo(opp, opp.Owner);
        if(intDecMaker.Name == null) intDecMaker = new CompanyInfo(opp.Owner);
        
        clientMainAddress = new CompanyInfo(opp.Account);
        
        if(!string.isEmpty(pdfComps)){
            Set<Id> ids = new Set<Id>();
            for(Id id : pdfComps.split(',')) ids.add(id);
            loadComps(ids);
        }
    }
    
    private void loadOLIsAndOLCs(){
        p_oppLocMap = new Map<Id, Opportunity_Location__c>();
        for(Opportunity_Location__c oploc :[Select Id, Order__r.Opportunity__r.Id, Name, NRC_Total__c, MRC_Total__c, Order__r.Opportunity__r.Term__c, Order__r.Opportunity__r.Proposed_Solutions__c,
            Opportunity__r.Account.Name, Opportunity__r.Account.ShippingState, Opportunity__r.Account.ShippingCity, Opportunity__r.Account.ShippingStreet, Opportunity__r.Account.ShippingPostalCode, Opportunity__r.Account.Phone, Opportunity__r.Account.Fax,
            Service_Location__r.Location__r.Building__r.Address__c,Service_Location__r.Location__r.Building__r.City__c,Service_Location__r.Location__r.Building__r.State__c,
            Service_Location__r.Location__r.Building__r.Postal_Code__c,Service_Location__r.Location__r.Building__r.Id,Service_Location__r.Name, Service_Location__r.Location__r.Room_Suite__c,                                                    
            (Select Description__c, Qty__c, MRC__c From Oppty_Cost_Comparisons__r),              
            (Select EPCProductDescription__c, FirstCN__c, Quantity__c, MRC__c From Disconnect_Line_Items__r),
            (Select Id, Term__c, Display_on_Solution__c, Name, Active__c from OpportunityLocationConfigurations__r Where Active__c=true)      
            from Opportunity_Location__c       
            where Order__r.Opportunity__r.Id =: opp.Id]){
                p_oppLocMap.put(opLoc.Id, opLoc);
        }
        p_oppLocOLIs = ApexUtils.retrieveObjectsFromFieldSets(OLI__c.getsObjectType()
                                                    ,new List<Set<String>>
                                                    {
                                                        SchemaUtils.RetrieveFullObjectFieldSet(OLI__c.getsObjectType())
                                                        ,new Set<String> {
                                                            'Parent_Opportunity_Line_Item__r.PP_SalesRatePlanPricingExternalID__c'
                                                            ,'OpportunityLocationConfiguration__r.Opportunity_Location__c'
                                                            ,'OpportunityLocationConfiguration__r.Active__c'
                                                            ,'Secondary_Location__r.Building__r.Name'
                                                            ,'Secondary_Service_Location__r.Location__r.Building__r.Name'
                                                            ,'SPC_Component__r.Display_name__c'
                                                            ,'SPC_Component__c'
                                                        }
                                                    }
                                                    ,'OpportunityLocationConfiguration__r.Opportunity_Location__c in (\'' + string.join(new List<Id>(p_oppLocMap.keySet()), '\',\'') + '\') AND PP_Package_Feature__c = false'
                                                    ,'Product_Family_Product__c, MRC__c DESC, Qty__c DESC'
                                                    );
    }
    
    private void loadComps(Set<Id> pdfComps){
        comp = new Component.Apex.OutputPanel();
        
        Map<Ref_PDF_Element__c, List<Ref_PDF_Clause__c>> elementMap = loadSelectedElements(pdfComps);
        List<Ref_PDF_Element__c> elems = new List<Ref_PDF_Element__c>(elementMap.keySet());
        elems = ApexUtils.sortByComparableField(elems, 'Print_Order__c', true, true);
        
        Map<String, Id> finalSigGroupElement = new Map<String, Id>();
        for(Ref_PDF_Element__c e : elems){
            if(!string.isEmpty(e.Signature_Grouping__c)) finalSigGroupElement.put(e.Signature_Grouping__c, e.Id);
        }
        
        for(Ref_PDF_Element__c e : elems){
            Set<string> clauseNames = new Set<string>();
            for(Ref_PDF_Clause__c clause : elementMap.get(e)) clauseNames.add(clause.Name);
            Boolean addSig = !string.isEmpty(e.Signature_Grouping__c) && finalSigGroupElement.get(e.Signature_Grouping__c) == e.Id;
            ApexPages.Component c = loadComponentAndClausesByName(e.Name, clauseNames, addSig);
            if(comp.childComponents.size() > 0) comp.childComponents.add(getBreak());
            comp.childComponents.add(c);
        }
    }
    
    public ApexPages.Component loadComponentByName(string componentName){
        return loadComponentByName(componentName, false);
    }

    public ApexPages.Component loadComponentByName(string componentName, boolean addSignature){
        return loadComponentAndClausesByName(componentName, new Set<String>(), addSignature);
    }

    public ApexPages.Component loadComponentAndClausesByName(string componentName, List<string> clauseNames){
        return loadComponentAndClausesByName(componentName, new Set<String>(clauseNames), false);
    }

    public ApexPages.Component loadComponentAndClausesByName(string componentName, Set<string> clauseNames, boolean addSignature){
        ApexPages.Component op = getHeader();
        
        //Proposal Sections
        if(componentName == 'CoverPage'){
            op.childComponents.add(new Component.c.PDF_CoverPage(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, clientMainAddress = clientMainAddress));
            op.childComponents.add(getFooter());
        }
        else if(componentName == 'ERateWelcomeLetter') op.childComponents.add(new Component.c.PDF_ERateWelcomeLetter(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'ERateServiceAgreement') op.childComponents.add(new Component.c.PDF_ERateServiceAgreement(currentOpp = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'eRateNoBid') op.childComponents.add(new Component.c.PDF_ERateNoBid(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'Letter') op.childComponents.add(new Component.c.PDF_Letter(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, clientMainAddress = clientMainAddress));
        else if(componentName == 'ExecutiveSummary') op.childComponents.add(new Component.c.PDF_ExecutiveSummary(currentOpportunity = opp, decisionMaker = decMaker));
        else if(componentName == 'Quote') op.childComponents.add(new Component.c.PDF_Quote(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker /*,  oppLocs = oppLocMap, oppLocOLIsMap = new Map<Id, OLI__c>(oppLocOLIs), currentOpportunityLocationId = oLoc.Id */));
        else if(componentName == 'QuoteFrench') op.childComponents.add(new Component.c.PDF_QuoteFrench(currentOpportunityFR = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker /*,  oppLocs = oppLocMap, oppLocOLIsMap = new Map<Id, OLI__c>(oppLocOLIs), currentOpportunityLocationId = oLoc.Id */));
        else if(componentName == 'QuoteComparison'){
            for(Opportunity_Location__c oLoc : currentOpptyLocs){
                op.childComponents.add(new Component.c.PDF_QuoteComparison(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, oppLocs = oppLocMap, oppLocOLIsMap = new Map<Id, OLI__c>(oppLocOLIs), currentOpportunityLocationId = oLoc.Id));
            }
        }
        
        //Contract Sections
        else if(componentName == 'ServiceAgreement') op.childComponents.add(new Component.c.PDF_ServiceAgreement(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'ServiceAgreementFrench') op.childComponents.add(new Component.c.PDF_ServiceAgreementFrench(currentOpportunityFR = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'LOA') op.childComponents.add(new Component.c.PDF_LOA(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'DirectoryForm') op.childComponents.add(new Component.c.PDF_DirectoryForm(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'MSA') op.childComponents.add(new Component.c.PDF_MSA(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker/*, renderKitTestClause = clauseNames.contains('kitTestClause')*/));
        else if(componentName == 'MSAFrench') op.childComponents.add(new Component.c.PDF_MSA_French(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker/*, renderKitTestClause = clauseNames.contains('kitTestClause')*/));
        else if(componentName == 'MSACollaboration') op.childComponents.add(new Component.c.PDF_MSACollaboration(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'MSAColocation') op.childComponents.add(new Component.c.PDF_MSAColocation(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'MSADDoSMitigationAddendum') op.childComponents.add(new Component.c.PDF_MSADDoSMitigationAddendum(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'MSAEthernetAddendum') op.childComponents.add(new Component.c.PDF_MSAEthernetAddendum(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'MSAHSISAddendum') op.childComponents.add(new Component.c.PDF_MSAHSISAddendum(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'MSA_HVS') op.childComponents.add(new Component.c.PDF_MSA_HVS(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'MSASecurityProServices') op.childComponents.add(new Component.c.PDF_MSASecurityProServices(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'MSAUCCloudVoice') op.childComponents.add(new Component.c.PDF_MSAUCCloudVoice(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'MSACPPoES') op.childComponents.add(new Component.c.PDF_MSACPPoES(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'MSAFORVPN') op.childComponents.add(new Component.c.PDF_MSAFORVPN(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'WavelengthService') op.childComponents.add(new Component.c.PDF_WavelengthService(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'WirelessBackupAddendum') op.childComponents.add(new Component.c.PDF_WirelessBackupAddendum(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'MtMRenewalAddendum') op.childComponents.add(new Component.c.PDF_MtMRenewalAddendum(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'InsideWiringAddendum') op.childComponents.add(new Component.c.PDF_InsideWiringAddendum(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, locations = solutions));
        else if(componentName == 'X911Form') op.childComponents.add(new Component.c.PDF_X911Form(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'SummaryOfWork') op.childComponents.add(new Component.c.PDF_SummaryOfWork(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        
        //Other Sections
        //else if(componentName == 'PaperlessBilling') op.childComponents.add(new Component.c.PDF_PaperlessBilling(decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'RecordsOnlyLOA') op.childComponents.add(new Component.c.PDF_RecordsOnlyLOA(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, clientMainAddress = clientMainAddress, techInfo = techInfo));
        else if(componentName == 'ETFCredit') op.childComponents.add(new Component.c.PDF_ETFCredit(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, icb = icb));
        else if(componentName == 'IncentiveCredit_MRCMultiple') op.childComponents.add(new Component.c.PDF_IncentiveCredit_MRCMultiple(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, icb = icb/*, iCText = iCText*/));
        else if(componentName == 'IncentiveCredit_DollarAmount') op.childComponents.add(new Component.c.PDF_IncentiveCredit_DollarAmount(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, icb = icb));
        else if(componentName == 'SatisfactionGuarantee') op.childComponents.add(new Component.c.PDF_SatisfactionGuarantee(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        else if(componentName == 'MoveAddendum') op.childComponents.add(new Component.c.PDF_MoveAddendum(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        //else if(componentName == 'BusinessDownturn') op.childComponents.add(new Component.c.PDF_BusinessDownturn(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, clientMainAddress = clientMainAddress, businessDownturn = businessDownturn));
        else if(componentName == 'BusinessDownturn_ServiceReduction') op.childComponents.add(new Component.c.PDF_BusinessDownturn_ServiceReduction(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, businessDownturn = businessDownturn));
        else if(componentName == 'BusinessDownturn_LocationDownturn') op.childComponents.add(new Component.c.PDF_BusinessDownturn_LocationDownturn(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker, businessDownturn = businessDownturn));
        else if(componentName == 'CloudFirewallServiceConfigBrief') op.childComponents.add(new Component.c.PDF_CloudFirewallServiceConfigBrief());
        //else if(componentName == 'CloudFirewallServiceSLA') op.childComponents.add(new Component.c.PDF_CloudFirewallServiceSLA());
        //else if(componentName == 'HSInternetAddendum') op.childComponents.add(new Component.c.PDF_HSInternetAddendum(currentOpportunity = opp, decisionMaker = decMaker, integraDecisionMaker = intDecMaker));
        
        //Indirect Sections
        else if(componentName == 'LOACPNI') op.childComponents.add(new Component.c.PDF_LOACPNI(currentOpportunity = opp, decisionMaker = decMaker, clientMainAddress = clientMainAddress));
        else if(componentName == 'PartnerOrderProfile') op.childComponents.add(new Component.c.PDF_PartnerOrderProfile(integraDecisionMaker = intDecMaker));
        
        //else if(componentName == 'kitTestClause') op = new Component.c.kitTestClause();
        else throw new ComponentLoaderException('invalid component name: ' + componentName);

        if(addSignature){
            if (componentName == 'MSAFrench'){
            	op.childComponents.add(new Component.c.PDF_SignatureBlock(decisionMaker = decMaker, language = 'French'));	    
            }
            else{
                op.childComponents.add(new Component.c.PDF_SignatureBlock(decisionMaker = decMaker, language = 'English'));
            }  
        } 
        return op;
    }

    public ApexPages.Component getHeader(){
        Component.Apex.OutputPanel op = new Component.Apex.OutputPanel(layout='block');
        op.styleclass='dynamicHeader';
        return op;
    }
    
    public ApexPages.Component getFooter(){
        return new Component.Apex.OutputPanel(layout = 'block', styleClass = 'dynamicFooter');
    }
    
    public ApexPages.Component getBreak(){
        return new Component.Apex.OutputText(escape = false, value = '<div style="page-break-before:always;"></div>');
    }
    
    public class ComponentLoaderException extends Exception{}
}