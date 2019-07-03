/*
* @Author: Smithdeendra A P
* @Created Date: 18-Jun-2019
* @Modified Date: 18-Jun-2019
* @TestClass: lgt_DataFactory_Test
* Version     JIRA                  Author                        Comments
* 1.0         SEAL-2934            Smithdeendra A P              Initial Comments  
* 1.1         SEAL-3030/3031       Smithdeendra A P              updated method place on Hold and take of hold.
*/
public with sharing class lgt_ManageLocationProductsController implements TestUtils.ITestableClass {
    
    private static final String PARAMETER_OPPORTUNITY_ID = 'opportunityId';
    private static final String ERR_MSG_INSUFFICIENT_ACCESS_ACCOUNT_COLO = 'You do not have sufficient privileges to update the COLO.';
    private static final String DEFAULT_CONFIGURATION_NAME = 'Default Solution';
    
    @AuraEnabled
    public String getDefaultConfigName() {
        return DEFAULT_CONFIGURATION_NAME;
    }
    
    //Holds accountId related to oppotunity used when creating a location
    @AuraEnabled
    public String accountId {get; set;}
    
    //Holds default opportunity term used when creating a location
    @AuraEnabled
    public String defaultOpportunityTerm {get; set;}
    
    //Holds default opportunity location used when creating a location solution
    @AuraEnabled
    public String defaultOpportunityLocation {get;set;}
    
    //Holds instance of opportunity for which this controller manages location products
    @AuraEnabled
    public Opportunity opportunity { get;set; }
    
    //Holds the list of available locations to the UI
    @AuraEnabled
    public List<OpportunityLocation> opportunityLocations { get;set; }
    
    //Holds the name of the image
    @AuraEnabled
    public String scoreName {get;set;}
    private transient Boolean inCtor {get;set;}
    
    //Holds the help text to display to the user
    @AuraEnabled
    public String helpText {get;set;}
    @AuraEnabled
    public String scoreHelpText {get;set;}
    
    //used to hack around no dml in constructor
    @AuraEnabled
    public Boolean saveOpp {get;set;}
    
    //Holds a value indicating if the deal was scored.
    @AuraEnabled
    public Boolean isScored {get;set;}
    
    //Holds the friendly score percentage
    @AuraEnabled
    public String scorePercent {get;set;}
    
    //Holds value to indicate if the deal is bad!
    @AuraEnabled
    public Boolean badDeal {get;set;}
    
    //Holds the help text for a bad deal
    @AuraEnabled
    public String badDealText {get;Set;}
    
    @AuraEnabled
    public Boolean doScoring {get;set;}
    @AuraEnabled
    public Boolean BlockPDFGen {get;set;}
    
    //holds the relationship between buildings and the baa records
    @AuraEnabled
    public Map<Id, List<Building_Access_Availability__c>> BaaByBldgId {get;  Set;}
    
    private List<Id> oppLocIds {get;set;}
    
    //Holds the list of available select locations to the UI
    @AuraEnabled
    public Service_Location__c selectLocations { get;set; }
    
    //Holds select options for available terms
    //made this public and added the getter/setter because the page needs this property.  (KIT)
    
    public List<SelectOption> termSelectOptions {get;set;}
    
    private List<SelectOption> bandwidthSelectOptions;
    
    private List<Id> oppSolutionIds {get;set;}
    @AuraEnabled
    public Boolean isRecordTypeChange { get{ return OpportunityUtils.ChangeRecordTypes.contains(opportunity.RecordTypeId); } }
    
    @AuraEnabled
    public string returnURL {get;set;}
    
    @AuraEnabled
    public OpportunityLocationConfiguration__c newSol { get{ return new OpportunityLocationConfiguration__c(); } set; }
    
    @AuraEnabled
    public String selectedServiceLocationPhone {get;set;}
    @AuraEnabled
    public String selectedServiceLocationName {get;set;}
    
    @AuraEnabled
    public DiscountAuthorityLevels__c discountAuthorityLevel {private get; private set;}
    
    @AuraEnabled
    public Decimal discountAmountRemaining {get;Set;}
    @AuraEnabled
    public Boolean accountEditPermissions {get;set;}
    
    @AuraEnabled
    public Boolean canCreateContracts {get; set;}
    
    @AuraEnabled
    public Boolean getIsAuthorityLevel() {
        return (discountAuthorityLevel != null) ? discountAuthorityLevel.IsApprovalLevel__c : false;
    }
    
    @AuraEnabled
    public Boolean getIsOfferManagement() {
        return discountAuthorityLevel != null && discountAuthorityLevel.Name == 'Offer Management';
    }
    
    @AuraEnabled
    public Boolean getIsSalesDirector() {
        return discountAuthorityLevel != null && discountAuthorityLevel.Name == 'Sales Director';
    }
    
    @AuraEnabled
    public Boolean getIsSalesManager(){
        return discountAuthorityLevel != null && discountAuthorityLevel.Name == 'Sales Manager';
    }
    
    @AuraEnabled
    public Boolean salesManagerApprovable {get;set;}
    
    @AuraEnabled
    public Boolean canLinkToSolution{get{ return CustomSettingUtils.currentUserHasCustomPermission('Can_Link_To_Solution__c'); } }
    
    //public List<Id> invalidNewSolutionIds {get;Set;}
    
    public void loadUserDiscountAuthority(){
        //load property with user instance
        String userlvl = String.valueOf([SELECT Discount_Level_Authority__c FROM User WHERE Id =: UserInfo.getUserId()].Discount_Level_Authority__c);
        
        if(!String.IsEmpty(userlvl)){
            discountAuthorityLevel = DiscountAuthorityLevels__c.getInstance(userlvl);
        }
    }
    
    
    public lgt_ManageLocationProductsController(Id OpportunityId) {
        //initialize controller
        this.inCtor = true;
        init(opportunityId);
    }
    public lgt_ManageLocationProductsController() {
        //initialize controller
        this.inCtor = true;
    }
    
    public PageReference SendApprovalRequest(){
        SolutionApprovalUtils.RequestApprovals(this.opportunity.Id);
        List<OpportunityLocationConfiguration__c> configsToSave = new List<OpportunityLocationConfiguration__c>();
        for(OpportunityLocation opportunityLocation : this.opportunityLocations) {
            for(Solution nextSolution : opportunityLocation.solutions) {
                if(nextSolution.rawSolution.Active__c && nextSolution.cmptCount > 0 && nextSolution.mgrCount > 0 && nextSolution.icbCount == 0 && !nextSolution.approvalRequested) {
                    nextSolution.rawSolution.Approval_Requested_Date__c = date.today();
                    configsToSave.add(nextSolution.rawSolution);
                }
            }
        }
        if(configsToSave.size() > 0) update configsToSave;
        PageReference ref = Page.ManageLocationProducts;
        ref.getParameters().put('opportunityId',this.opportunity.id);
        ref.setRedirect(true);
        return ref;
    }
    
    //Action method that redirects to the opportunity
    public PageReference gotoOpportunity() {
        //return the opportunity page
        return (new ApexPages.StandardController(this.opportunity)).view();
    }
    
    //Action method that redirects to the ManageLocationConfigurations page
    public PageReference gotoManageLocationConfigurations() {
        PageReference pageReference = Page.ManageLocationConfigurations;
        pageReference.getParameters().put('opportunityId', this.opportunity.Id);
        return pageReference;
    }
    
    //Action method that redirects to GeneratePDF
    public PageReference gotoGeneratePDF() {
        PageReference pageReference = Page.OpptyGeneratePDF;
        pageReference manageLocPage = Page.ManageLocationProducts;
        
        pageReference.getParameters().put('Id', this.opportunity.Id);
        string retUrl = manageLocPage.getUrl() + '?' + PARAMETER_OPPORTUNITY_ID + '=' + this.opportunity.Id;
        pageReference.getParameters().put('retURL', retURL);
        return pageReference;
    }
    
    //Action method that redirects to CreateBuildingUsingGoogleAddress
    public PageReference gotoGenerateNewServiceLoc() {
        PageReference pageReference = Page.CreateBuildingUsingGoogleAddress;
        pageReference manageLocPage = Page.ManageLocationProducts;
        PageReference createSolPage = Page.CreateSolution;
        
        pageReference.getParameters().put('Id', accountId);
        String retURL2 = ApexPages.currentPage().getParameters().get('retURL');
        String retURL = createSolPage.getUrl() + '?' + PARAMETER_OPPORTUNITY_ID + '=' + this.Opportunity.Id + '&openNewSol=' + True;
        pageReference.getParameters().put('retURL', retURL);
        if(!String.isEmpty(retURL2))
            pageReference.getParameters().put('retURL2', retURL2);
        return pageReference;
    }
    
    /**
* Action method that updates an account's colo- Obsolete only the test was using this 2.27.2013
*
* @param AccountId */ 
    @AuraEnabled
    public String AccountId_updateColo{get; set;}/*
*       the Id of the account whose colo should be updated
*/
    public PageReference updateColo() {
        //grab account and update
        for(OpportunityLocation opportunityLocation : this.opportunityLocations) {
            if(opportunityLocation.rawLocation.Service_Location__r.Account__r.Id == AccountId_updateColo) {
                try {
                    update opportunityLocation.rawLocation.Service_Location__r.Account__r;
                } catch(DMLException e) {
                    if(e.getDmlType(0) == StatusCode.INSUFFICIENT_ACCESS_OR_READONLY) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERR_MSG_INSUFFICIENT_ACCESS_ACCOUNT_COLO));
                    } else {
                        throw e;
                    }
                }
                break;
            }
        }
        return null;
    }
    
    /**
* Action method for deleting expired line items from an opportunity configuration.
*
* @param configId */ @AuraEnabled 
    public String ConfigId_deleteExpiredLineItems {get; set;} /*
*           the Id of the opportunity configuration whose expired line items will be deleted
*/
    public PageReference deleteExpiredLineItems(){
        //if we have items to delete
        if(!expiredLineItemlst.isEmpty()){
            //get children to delete (assumes only one level hierarchy)
            List<OLI__c> childrenToDelete = new List<OLI__c>();
            Set<OLI__c> eli = new Set<OLI__c>();
            for(OLI__c expiredLineItem : expiredLineItemlst) {
                if(expiredLineItem.OpportunityLocationConfiguration__c == ConfigId_deleteExpiredLineItems){
                    childrenToDelete.addAll(expiredLineItem.Opportunity_Line_Items__r);
                    eli.add(expiredLineItem);
                }
            }
            
            //if we have children to delete
            if(!childrenToDelete.isEmpty()) {
                delete childrenToDelete;
            }
            
            delete new List<OLI__c>(eli);
        }
        
        //reload page
        PageReference pageReference = Page.ManageLocationProducts;
        pageReference.getParameters().put(PARAMETER_OPPORTUNITY_ID, this.opportunity.Id);
        pageReference.setRedirect(true);
        return pageReference;
    }
    @AuraEnabled
    public string param_accountId {get;set;}
    
    public PageReference updateSolutionTerm() {
        for(OpportunityLocation opportunityLocation : this.opportunityLocations) {
            for(Solution nextSolution : opportunityLocation.solutions) {
                if(nextSolution.rawSolution.Id == param_solutionId) {
                    update nextSolution.rawSolution;
                    return null;
                }
            }
        }
        
        //we should never get here (assumes no concurrency)
        throw new lgt_ManageLocationProductsControllerException('Unable to find configuration to update term!!!');
    }
    
    @AuraEnabled
    public String  selectTerm {get;set;}
    @AuraEnabled
    public String  selectBandwidth {get;set;}
    
    @AuraEnabled
    public String newSolutionName {get;set;}
    
    @AuraEnabled
    public Boolean displayOnPDF {get;set;}
    @AuraEnabled
    public String param_locationId {get;set;}
    @AuraEnabled public String param_orderId {get;set;}
    
    public PageReference gotoCostCompare() {
        PageReference pageRef = Page.CostComparison;
        Map<String, String> params = pageRef.getParameters();
        params.put('Id', param_locationId);
        params.put('retURL', '/apex/ManageLocationProducts?opportunityId=' + opportunity.Id);
        return pageRef;
    }
    
    public PageReference gotoOrder() {
        return (new ApexPages.StandardController([select Id from Order__c where Id = :param_orderId])).view();
    }
    
    public PageReference gotoTurnDowns() {
        PageReference pageRef = Page.DisconnectOrder;
        pageRef.getParameters().put('Id', param_locationId);
        pageRef.getParameters().put('retURL', '/apex/ManageLocationProducts?opportunityId=' + opportunity.Id);
        return pageRef;
    }
    
    public void placeOnHold(String param_locationId) {
        
        OpportunityLocation loc = findLocation(param_locationId);
        loc.rawLocation.On_Hold__c = true;
        update loc.rawLocation;
        //Get those active opp products
        List<Opportunity_Product__c> oppProds = GetOppProducts(loc.rawLocation.id,true);
        if(oppProds != null){
            for(Opportunity_Product__c op :oppProds)
                op.Active__c = false;
        }
        
       // ScoreDeal();
        update oppProds;
        //refresh the opp
        List<Opportunity> opportunities = [Select Id, Name, Deal_Score__c, AccountId, Account.Name, Account.ICC_Account_Number__c, RecordTypeId, Term__c, OwnerId,CPQ_Total__c,CPQ_NRC_Total__c,MRC_Floor_Total__c,CPQ_MRC_List_Total__c, Amount, NRR_Amount__c, (Select Id From Opportunity_Sites__r) From Opportunity Where Id = :this.Opportunity.Id];
        this.opportunity = opportunities.get(0);
       // setUpProductFamily();
        // return null;
    }
    
    public void takeOffHold(String param_locationId) {
        
        OpportunityLocation loc = findLocation(param_locationId);
        loc.rawLocation.On_Hold__c = false;
        update loc.rawLocation;
        
        List<Opportunity_Product__c> oppProds = GetOppProducts(loc.rawLocation.id,false);
        List<Opportunity_Product__c> oppProdsUpdate = new List<Opportunity_Product__c>();
        if(oppProds != null){
            for(Opportunity_Product__c op :oppProds){
                if(op.Solution__r.Active__c){
                    op.Active__c = true;
                    oppProdsUpdate.add(op);
                }
            }
        }
        
       // ScoreDeal();
        update oppProdsUpdate;
        //refresh the opp
        List<Opportunity> opportunities = [Select Id, Name, Deal_Score__c, AccountId, Account.Name, Account.ICC_Account_Number__c, RecordTypeId, Term__c, OwnerId,CPQ_Total__c,CPQ_NRC_Total__c,MRC_Floor_Total__c,CPQ_MRC_List_Total__c, Amount, NRR_Amount__c, (Select Id From Opportunity_Sites__r) From Opportunity Where Id = :this.Opportunity.Id];
        this.opportunity = opportunities.get(0);
        //setUpProductFamily();
        //return null;
    }
    
    private List<Opportunity_Product__c> GetOppProducts(id oppLocId, boolean active){
        RecordType recordType = [Select id From  RecordType  Where Name = 'CPQ Entry' and SobjectType = 'Opportunity_Product__c' Limit 1];
        return [Select Id,Active__c,Solution__r.Active__c From Opportunity_Product__c Where Active__c = :active and Solution__r.Opportunity_Location__c = :oppLocId and RecordTypeID = :recordType.Id];
    }
    
    /**
* Initializes the controller using the passed in opportunity ID.
*/
    private void init(String opportunityId) {
        saveOpp = false;
        badDeal = false;
        doScoring = CustomSettingUtils.getOverrideSettingValue('Enable Deal Scoring');
        BlockPDFGen = CustomSettingUtils.getOverrideSettingValue('Block PDF Gen For Bad Deals');
        // returnURL = ApexPages.currentPage().getParameters().get('retURL');
        
        newSolutionName = 'Default Solution';
        selectTerm = '36';
        //String opportunityId = Apexpages.currentPage().getParameters().get(PARAMETER_OPPORTUNITY_ID);
        
        if(opportunityId == null || opportunityId == '') {
            throw new lgt_ManageLocationProductsControllerException('Missing or invalid opportunity ID.');
        }
        
        //get/validate the opportunity
        List<Opportunity> opportunities = [Select Id, Name, Deal_Score__c, AccountId, Account.Name, Account.ICC_Account_Number__c, Account.Owners_Sales_Channel__c, RecordTypeId, Term__c, Contract_Term_End_Date__c, OwnerId,CPQ_Total__c,CPQ_NRC_Total__c,MRC_Floor_Total__c,CPQ_MRC_List_Total__c, Amount, NRR_Amount__c, (Select Id From Opportunity_Sites__r) From Opportunity Where Id = :opportunityId];
        if(opportunities.size() != 1) {
            throw new lgt_ManageLocationProductsControllerException('Missing or invalid opportunity ID.');
        }
        else {
            this.opportunity = opportunities.get(0);
            accountId = opportunity.AccountId;
            defaultOpportunityTerm = opportunity.Term__c;
            if(opportunity.Account.Owners_Sales_Channel__c != null &&  opportunity.Account.Owners_Sales_Channel__c.containsIgnoreCase('zCore')){
                canCreateContracts = false;
            }else{
                canCreateContracts = true;
            }
        }
        
        accountEditPermissions = SecurityUtils.currentUserHasRecordAccess(accountId, true);
        
        //set available locations for the opportunity
        this.oppLocIds = new List<Id>();
        
        //get list of all solution ids for the locations
        this.oppSolutionIds = new List<Id>();
        this.opportunityLocations = createOpportunityLocations(this.opportunity);
        
        //set available select locations for the opportunity
        //get/validate the opportunity
        List<Service_Location__c> opportunitySelectLocations = [Select Id, Name From Service_Location__c Where account__c = :accountId];
        if(opportunitySelectLocations.size() > 0) {
            this.selectLocations = opportunitySelectLocations.get(0);
            defaultOpportunityLocation = selectLocations.Name;
        }
        //set select options for terms
        this.termSelectOptions = createTermSelectOptions();
        
        //set select options for bandwidth
        this.bandwidthSelectOptions = createBandwidthSelectOptions();
        
        updateSolutionStatus();
        loadUserDiscountAuthority();
        setUpProductFamily();
        ScoreDeal();
        
        //invalidNewSolutionIds = getParentServiceLocIDs(accountId);
    }
    
    public void setUpProductFamily(){
        
        Set<Id> solutionId = new Set<Id>();
        for(OpportunityLocation op:opportunityLocations){
            //Setting all solution id from the location
            for(Solution s:op.solutions)
                solutionId.add(s.rawsolution.id);
        }
        
        Set<String> productFamily = new Set<String>();
        Set<String> productFamilyProduct = new Set<String>();
        List<OLI__c> allexistingOli = new List<OLI__c>();
        
        //Finding the line Items from the solution Id and setting a map from solution id to line item
        Map<Id,List<OLI__c>> solutionIdToOLI = new Map<Id,List<OLI__c>>();
        for(OLI__c ol:[Select MRC__c,Name,Product_Family_Product__c,Product_Family_Id__c ,MRC_Discount__c,MRC_Total__c,  NRC__c,
                       NRC_Discount__c,PP_SalesProductExternalID__c, Price_Id__c,  NRC_Total__c,  Qty__c, PP_Product_Pricing_Name__c,
                       Approval_Status__c,OpportunityLocationConfiguration__c,Approved__c,DQ__c, OLI_Score__c, Off_Footprint__c, Off_Footprint_Approved__c, SPC_MRC_IS_Quote__c,
                       OpportunityLocationConfiguration__r.Opportunity_Location__R.Order__r.Opportunity__r.Id, PP_Package_Feature__c, Product_Pricing_Display_Name__c From  OLI__c
                       where OpportunityLocationConfiguration__c IN:solutionId Order by Product_Family_Id__c DESC]){
                           Id solID = ol.OpportunityLocationConfiguration__c;
                           List<OLI__c> allList = solutionIdToOLI.get(solID) != null ? solutionIdToOLI.get(solID) : new List<OLI__c>();
                           allList.add(ol);
                           productFamily.add(ol.Product_Family_Id__c);
                           productFamilyProduct.add(ol.Product_Family_Product__c);
                           solutionIdToOLI.put(solID, allList);
                           allexistingOli.add(ol);
                       }
        
        //Sorting the product family
        productFamily = sortSetString(productFamily);
        ProductFamilyProduct = sortSetString(ProductFamilyProduct);
        Map<String,SPC_Product__c> nameToSPCProduct = new Map<String,SPC_Product__c>();
        Map<String,Id> nameToSPCProductSFDCID = new Map<String,ID>();
        //Seems not required delete it
        for(SPC_Product__c sp:[Select Name,Sales_Product_Group__c From SPC_Product__c where name IN:productFamilyProduct]){
            nameToSPCProduct.put(sp.name,sp);
            nameToSPCProductSFDCID.put(sp.name,sp.id);
        }
        
        //All product families is set in this map according to the product family name
        Map<String, QuoteWrapper.ProductFamily> groupNameToProductFamily = new Map<String, QuoteWrapper.ProductFamily>();
        
        //All product family is set on this map.All logic is executed while setting this map.
        Map<ID, Map<String, QuoteWrapper.ProductFamily>> solutionIdToProductFamily = new Map<ID, Map<String, QuoteWrapper.ProductFamily>>();
        Map<String, Set<String>> solutionIdToProductFamilylst = new Map<String, Set<String>>();
        Map<String,ID> productNameToId = new Map<String,Id>();
        for(Product_Families__c  pc : [select Id, Name from Product_Families__c])
            productNameToId.put(pc.name, pc.id);
        
        //Looping through solutionIdToOLI and setting wrapper class with appropriate line item and product....
        for(Id solId : solutionIdToOLI.keyset()){
            List<OLI__c> allOlilst = solutionIdToOLI.get(solID);
            Set<String> productAndSalesProductName = new Set<String>();
            groupNameToProductFamily = new Map<String, QuoteWrapper.ProductFamily>();
            Map<String, List<OLI__c>> productgroupAndSaleProductToOLI = new Map<String, List<OLI__c>>();
            for(OLI__c Oli:allOlilst){
                String k = oli.Product_Family_Id__c + oli.Product_Family_Product__c;
                List<OLI__c> l = productgroupAndSaleProductToOLI.get(k) != null ? productgroupAndSaleProductToOLI.get(k) : new List<OLI__c>();
                l.add(Oli);
                productgroupAndSaleProductToOLI.put(k, l);
            }
            
            //Setting solutionIdToProductFamily from existing OLI...
            for(OLI__C ol : allOlilst){
                String oliKey = ol.Product_Family_Id__c + ol.Product_Family_Product__c;
                if(!groupNameToProductFamily.containsKey(ol.Product_Family_Id__c)){
                    if(!productAndSalesProductName.contains(oliKey)){
                        if(!ol.PP_Package_Feature__c){
                            //Setting the product Family
                            QuoteWrapper.ProductFamily productFamilies = new QuoteWrapper.ProductFamily(ol.Product_Family_Id__c, productNameToId.get(ol.Product_Family_Id__c));
                            //Setting the Sales Product
                            QuoteWrapper.Product product = new QuoteWrapper.Product();
                            product.name=ol.Product_Family_Product__c;
                            product.SFDCId=nameToSPCProductSFDCID.get(ol.Product_Family_Product__c);
                            product.productFamilyId=productNameToId.get(ol.Product_Family_Id__c);
                            
                            if(ol.MRC_Total__c != null){
                                if(product.total == null)
                                    product.total = 0;
                                product.total += ol.MRC_Total__c;
                            }
                            else product.total=0;
                            
                            if(ol.NRC_Total__c != null){
                                if(product.NRCTotal == null)
                                    product.NRCTotal = 0;
                                product.NRCTotal += ol.NRC_Total__c;
                            }
                            else product.NRCTotal = 0;
                            
                            for(OLI__c lineItem:productgroupAndSaleProductToOLI.get(oliKey)){
                                QuoteWrapper.QuoteLineItem qlt = new QuoteWrapper.QuoteLineItem(lineItem);
                                product.lines.add(qlt);
                            }
                            productFamilies.products.add(product);
                            groupNameToProductFamily.put(ol.Product_Family_Id__c, productFamilies);
                            
                            Set<String> pfl = solutionIdToProductFamilylst.get(solID) != null ? solutionIdToProductFamilylst.get(solID) : new Set<String>();
                            pfl.add(ol.Product_Family_Id__c);
                            solutionIdToProductFamilylst.put(solID, pfl);
                            productAndSalesProductName.add(oliKey);
                        }
                    }
                }
                else{
                    if(!productAndSalesProductName.contains(oliKey)){
                        QuoteWrapper.Product product = new QuoteWrapper.Product();
                        product.name = ol.Product_Family_Product__c;
                        product.SFDCId=nameToSPCProductSFDCID.get(ol.Product_Family_Product__c);
                        if(ol.MRC_Total__c!=null){
                            if(product.total==null) product.total = 0;
                            else product.total += ol.MRC_Total__c;
                        }
                        else product.total=0;
                        
                        if(ol.NRC_Total__c != null){
                            if(product.NRCTotal == null) product.NRCTotal=0;
                            product.NRCTotal+=ol.NRC_Total__c;
                        }
                        else product.NRCTotal=0;
                        
                        product.productFamilyId=productNameToId.get(ol.Product_Family_Id__c);
                        for(OLI__c lineItem:productgroupAndSaleProductToOLI.get(oliKey)){
                            QuoteWrapper.QuoteLineItem qlt = new QuoteWrapper.QuoteLineItem(lineItem);
                            product.lines.add(qlt);
                        }
                        groupNameToProductFamily.get(ol.Product_Family_Id__c).products.add(product);
                        
                        Set<String> pfl = solutionIdToProductFamilylst.get(solID) != null ? solutionIdToProductFamilylst.get(solID) : new Set<String>();
                        pfl.add(ol.Product_Family_Id__c);
                        solutionIdToProductFamilylst.put(solID, pfl);
                        productAndSalesProductName.add(oliKey);
                    }
                }
            }
            if(groupNameToProductFamily.size() > 0)
                solutionIdToProductFamily.put(solId, groupNameToProductFamily);
        }
        
        //Setting the solution id to respective location
        for(OpportunityLocation op:opportunityLocations){
            //Setting all solution id from the location
            for(Solution s:op.solutions){
                solutionId.add(s.rawsolution.id);
                if(solutionIdToProductFamilylst.containskey(s.rawsolution.id)){
                    for(String prodf : solutionIdToProductFamilylst.get(s.rawsolution.id)){
                        if(s.productFamilies == null) s.productFamilies = new List<QuoteWrapper.ProductFamily>();
                        s.productFamilies.add(solutionIdToProductFamily.get(s.rawsolution.id).get(prodf));
                    }
                }
                //Sorting the families by prdoductname and sales product...
                if(s.productFamilies != null && s.productFamilies.size() > 0)
                    s.productFamilies = QuoteWrapper.sortListByProductName(s.productFamilies);
            }
        }
        
        setuptotalonLocation();
        if(!allexistingOli.isEmpty())
            setUpExpiredItems(allexistingOli);
    }
    
    public void setuptotalonLocation(){
        for(OpportunityLocation op:opportunityLocations){
            for(Solution sol:op.solutions){
                if(sol.productFamilies != null && !sol.productFamilies.isEmpty()){
                    for(QuoteWrapper.ProductFamily pdf:sol.productFamilies){
                        if(pdf.products != null && !pdf.products.isEmpty()){
                            for(QuoteWrapper.Product pro : pdf.products){
                                pro.total=0;
                                pro.NRCTotal=0;
                                if(pro.lines != null && !pro.lines.isEmpty()){
                                    for(QuoteWrapper.QuoteLineItem quo:pro.lines){
                                        pro.total += quo.rawOLI.MRC_Total__c;
                                        pro.NRCTotal += quo.rawOLI.NRC_Total__c;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @AuraEnabled
    public List<OLI__c> expiredLineItemlst{get;set;}
    
    public void setUpExpiredItems(List<OLI__c> allexistingOli){
        Map<String, Boolean> componentNameToExpireBoolean = new Map<String, Boolean>();
        
        List<String> currentPriceIds = new List<String>();
        for(OLI__c olie : allexistingOli)
            currentPriceIds.add(olie.Price_Id__c);
        
        List<SPC_Pricing__c> pricingForOLIs = CatalogUtils.GetPricingByPricingID(currentPriceIds);
        for(SPC_Pricing__c spcP : pricingForOLIs){
            if(spcP.Is_Expired__c)
                componentNameToExpireBoolean.put(spcP.Price_id__c,spcP.Is_Expired__c);
        }
        
        this.expiredLineItemlst = new List<OLI__c>();
        for(OpportunityLocation op:opportunityLocations){
            LIst<OLI__c> existingOLI = new List<OLI__c>();
            for(Solution sol:op.solutions){
                existingOLI = new List<OLI__c>();
                if(sol.productFamilies != null && !sol.productFamilies.isEmpty()){
                    for(QuoteWrapper.ProductFamily pdf:sol.productFamilies){
                        if(pdf.products != null && !pdf.products.isEmpty()){
                            for(QuoteWrapper.Product pro : pdf.products){
                                pro.total = 0;
                                pro.NRCTotal = 0;
                                if(pro.lines != null && !pro.lines.isEmpty()){
                                    for(QuoteWrapper.QuoteLineItem quo : pro.lines){
                                        pro.total += quo.rawOLI.MRC_Total__c;
                                        pro.NRCTotal += quo.rawOLI.NRC_Total__c;
                                        existingOLI.add(quo.rawOLI);
                                    }
                                }
                            }
                        }
                    }
                }
                
                if(!existingOLI.isEmpty()) sol.hasExpiredLineItems = hasexpiredlineItem(existingOLI, componentNameToExpireBoolean);
            }
        }
    }
    
    public boolean hasexpiredlineItem(List<OLI__c> existingOLI, Map<String, Boolean> componentNameToExpireBoolean){
        boolean expireditem=false;
        
        for(OLI__c oli:existingOLI) {
            if(componentNameToExpireBoolean.containskey(String.valueof(oli.Price_Id__c))){
                expiredLineItemlst.add(oli);
                expireditem = true;
            }
            else if(oli.Price_Id__c == null){
                expiredLineItemlst.add(oli);
                expireditem = true;
            }
        }
        
        return expireditem;
    }
    
    public Static Set<String> sortSetString(Set<String> lstToSort){
        List<String> sorttedString = new List<String>();
        sorttedString.addAll(lstToSort);
        sorttedString.sort();
        lstToSort.clear();
        lstToSort.addAll(sorttedString);
        return lstToSort;
    }
    
    //find the location corresponding to an account
    private OpportunityLocation findLocation(Id locId) {
        for(OpportunityLocation loc : this.opportunityLocations) {
            if(loc.rawLocation.Id == locId) return loc;
        }
        return null;
    }
    
    private void createDefaultDirectoryListing(List<Opportunity_Location__c> oppLocations) {
        RecordType rt = [select Id, Name from RecordType where DeveloperName = 'Directory_Listing' LIMIT 1];
        
        List<Opportunity_Location__c> oppLocs = [SELECT Id, Service_Location__r.Name, Service_Location__r.Phone__c, Service_Location__r.Location__r.Building__r.Address__c,
                                                 Service_Location__r.Location__r.Building__R.Serving_LSO__r.LSO_CLLI__c,Service_Location__r.Location__r.Building__r.City__c, Service_Location__r.Location__r.Building__r.State__c,
                                                 Service_Location__r.Location__r.Building__r.Postal_Code__c,Service_Location__r.Location__r.Name, Order__r.Opportunity__r.Id, Service_Location__r.Location__r.Building__r.Market_Area_Name__c FROM Opportunity_Location__c WHERE Id IN :oppLocations];
        
        List<Directory_Listing__c> dirList = new List<Directory_Listing__c>();
        for(Opportunity_Location__c oppLoc : oppLocs){
            Technical_Information__c techDL = new Technical_Information__c(RecordTypeID = rt.Id, Name= rt.Name, Opportunity_Site__c=oppLoc.Id);
            insert techDL;
            
            Directory_Listing__c dl = new Directory_Listing__c(Technical_Information__c=techDL.Id, Type__c='Complimentary Listing');
            dl.Company_Name__c = oppLoc.Service_Location__r.Name;
            dl.Address__c = oppLoc.Service_Location__r.Location__r.Building__r.Address__c;
            dl.City__c = oppLoc.Service_Location__r.Location__r.Building__r.City__c;
            dl.State__c = oppLoc.Service_Location__r.Location__r.Building__r.State__c;
            dl.Zip__c = oppLoc.Service_Location__r.Location__r.Building__r.Postal_Code__c;
            dl.Listing_Telephone_Number__c = oppLoc.Service_Location__r.Phone__c;
            dl.Main_Listing__c = true;
            dirList.add(dl);
        }
        insert dirList;
        return;
    }
    
    public OpportunityLocation findLocationByServLocation(Id servLocId){
        for(OpportunityLocation loc : this.opportunityLocations) {
            if(loc.rawLocation.Service_Location__r.Id == servLocId) return loc;
        }
        return null;
    }
    
    public PageReference cancelSolution() {
        //reload ManageLocationProducts page
        PageReference pageReference = null;
        if(!String.isEmpty(returnURL)){
            pageReference = new pageReference(returnURL);
        }
        else{
            pageReference = Page.ManageLocationProducts;
            pageReference.getParameters().put(PARAMETER_OPPORTUNITY_ID, this.opportunity.Id);
        }
        pageReference.setRedirect(true);
        return pageReference;
    }
    
    public PageReference createNewSolution() {
        try{
            List<Order__c> orderId = [Select Id From Order__c Where Opportunity__c = :opportunity.Id];
            if((orderId == null) || orderId.size() == 0 ){
                Order__c oOrder = new Order__c();
                oOrder.Opportunity__c = this.opportunity.Id;
                oOrder.OwnerId = this.opportunity.OwnerId;
                oOrder.Record_Status__c = 'New';
                insert oOrder;
            }
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
        }
        try{
            String selectedLocsString = EncodingUtil.urlDecode(Apexpages.currentPage().getParameters().get('sLocIDs'),'UTF-8');
            List<String> selectedLocs = selectedLocsString.split(',');
            
            List<Service_Location__c> servLocs = [Select Id From Service_Location__c Where id In :selectedLocs];
            Order__c orderId = [Select Id From Order__c Where Opportunity__c = :opportunity.Id];
            
            Boolean display = displayOnPDF == true;
            List<Opportunity_Location__c> oppLocs = new List<Opportunity_Location__c>();
            List<OpportunityLocationConfiguration__c> olocsToInsert = new List<OpportunityLocationConfiguration__c>();
            for(Service_Location__c sloc : servLocs){
                OpportunityLocation loc = findLocationByServLocation(sloc.Id);
                if(loc == null) {
                    //New up rawLocation if we can't find it, in the new hierarchy we aren't auto creating these in memory locations
                    //May need to figure out how to pass in Service Location instead of querying!!!!!!!!!!!!!!!!!!!
                    try{
                        Opportunity_Location__c oppLoc = new Opportunity_Location__c();
                        oppLoc.Service_Location__c = sloc.Id;
                        oppLoc.Name = newSolutionName;
                        oppLoc.Opportunity__c = opportunity.Id;
                        oppLoc.Order__c = orderId.Id;
                        oppLoc.Term__c = selectTerm;
                        oppLoc.On_Hold__c = false;
                        oppLoc.Status__c = 'pre-Sale';
                        oppLoc.Account__c = opportunity.AccountId;
                        oppLocs.add(oppLoc);
                    }
                    catch(Exception e){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
                    }
                }
                else {
                    loc.createNewSolution(newSolutionName, selectTerm, selectBandwidth, display);
                    olocsToInsert.addall(loc.solsToInsert);
                }
            }
            this.opportunityLocations = createOpportunityLocations(this.opportunity);
            insert oppLocs;
            
            List<Solution> sols = new List<Solution>();
            for(Opportunity_Location__c oloc : oppLocs){
                Solution s = new Solution(newSolutionName, selectTerm, true, oLoc.Id, selectBandwidth, display, null);
                sols.add(s);
                olocsToInsert.add(s.rawSolution);
            }
            
            insert olocsToInsert;
            
            //createDefaultDirectoryListing(oppLocs); //DL is created when there is DL product
        }
        catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            throw new lgt_ManageLocationProductsControllerException('Unable to create new solution.  Be sure all required fields are filled in on opportunity.');            
        }
        
        //reload ManageLocationProducts page
        PageReference pageReference = null;
        if(!String.isEmpty(returnURL)){
            pageReference = new pageReference(returnURL);
        }
        else{
            pageReference = Page.ManageLocationProducts;
            pageReference.getParameters().put(PARAMETER_OPPORTUNITY_ID, this.opportunity.Id);
        }
        pageReference.setRedirect(true);
        return pageReference;
    }
    
    public PageReference setProviders() {
        string oppLocID = Apexpages.currentPage().getParameters().get('oppLocID');
        string ldProvider = Apexpages.currentPage().getParameters().get('ldProvider');
        string localProvider = Apexpages.currentPage().getParameters().get('localProvider');
        string tfProvider = Apexpages.currentPage().getParameters().get('tollFreeProvider');
        
        List<Technical_Information__c> technicalInformations = [select id from Technical_Information__c where recordtype.Name ='05 – Toll Free Services' and Opportunity_Site__c =:oppLocID];
        for (Technical_Information__c t : technicalInformations){
            t.Toll_Free_Provider__c = tfProvider; 
        }
        update technicalInformations;
        
        for(OpportunityLocation opportunityLocation : this.opportunityLocations) {
            if(opportunityLocation.rawLocation.Id == oppLocID) {
                opportunityLocation.rawLocation.Current_LD_Provider__c = ldProvider;
                opportunityLocation.rawLocation.Current_Provider_Local__c = localProvider;
                opportunityLocation.rawLocation.Current_Toll_Free_Provider__c = tfProvider;
                update opportunityLocation.rawLocation;
                break;
            }
        }
        
        return null;
    }
    
    public pageReference renameSolution() {
        string newSolutionName = Apexpages.currentPage().getParameters().get('newSolutionName');
        
        for(OpportunityLocation opportunityLocation : this.opportunityLocations) {
            for(Solution nextSolution : opportunityLocation.solutions) {
                if(nextSolution.rawSolution.Id == param_solutionId) {
                    nextSolution.rawSolution.Name = newSolutionName;
                    update nextSolution.rawSolution;
                    setUpProductFamily();
                    return null;
                }
            }
        }
        
        //we should never get here (assumes no concurrency)
        throw new lgt_ManageLocationProductsControllerException('Unable to find configuration to update name!!!');
    }
    
    public pageReference makeSolutionActive() {
        List<OpportunityLocationConfiguration__c> updateSolutions = new List<OpportunityLocationConfiguration__c>();
        
        OpportunityLocation loc = findLocation(param_locationId);
        for(Solution nextSolution : loc.solutions) {
            nextSolution.rawSolution.Active__c = (nextSolution.rawSolution.Id == param_solutionId);
            updateSolutions.add(nextSolution.rawSolution);
        }
        ScoreDeal();
        
        update updateSolutions;
        
        //refresh the opp
        List<Opportunity> opportunities = [Select Id, Name, Deal_Score__c, AccountId, Account.Name, Account.ICC_Account_Number__c, RecordTypeId, Term__c, OwnerId,CPQ_Total__c,CPQ_NRC_Total__c,MRC_Floor_Total__c,CPQ_MRC_List_Total__c, Amount, NRR_Amount__c, (Select Id From Opportunity_Sites__r) From Opportunity Where Id = :this.Opportunity.Id];
        this.opportunity = opportunities.get(0);
        setUpProductFamily();
        return null;
    }
    
    public string param_solutionId {get;set;}
    
    /**
* Helper method to create term select options
*/
    private List<SelectOption> createTermSelectOptions() {
        List<SelectOption> l = new List<SelectOption>();
        for(Schema.PicklistEntry picklistEntry : Schema.sObjectType.Opportunity.fields.Term__c.getPicklistValues())
            l.Add(new SelectOption(picklistEntry.getLabel(), picklistEntry.getValue()));
        return l;
    }
    
    /**
* Helper method to create bandwidth select options
*/
    private List<SelectOption> createBandwidthSelectOptions() {
        List<SelectOption> l = new List<SelectOption>{new SelectOption('0','--None--')};
            for(Schema.PicklistEntry picklistEntry : Schema.sObjectType.OpportunityLocationConfiguration__c.fields.Bandwidth__c.getPicklistValues())
            l.Add(new SelectOption(picklistEntry.getLabel(), picklistEntry.getValue()));
        return l;
    }
    
    /**
* Helper method to create our view objects for the specified opportunity.
*/
    private List<OpportunityLocation> createOpportunityLocations(Opportunity opportunity) {
        //get locations
        Set<String> contractTypes = new Set<String>();
        List<Opportunity_Location__c> opportunityLocations = new List<Opportunity_Location__c>();
        Set<String> solutionId = new Set<String>();
        Map<String,OpportunityLocationConfiguration__c> IdToSolObject = new Map<String,OpportunityLocationConfiguration__c>();
        BaaByBldgId = new Map<Id, List<Building_Access_Availability__c>>();
        for(Opportunity_Location__c olocc : [select Id, Name, Opportunity__r.AccountId, Service_Location__c, Service_Location__r.Phone__c, 
                                             Current_LD_Provider__c, Current_Provider_Local__c, On_Hold__c, Turndown_Total__c,
                                             Current_Toll_Free_Provider__c, (select Toll_Free_Provider__c from Technical_Information__r where recordtype.Name ='05 – Toll Free Services'),
                                             Service_Location__r.Customer_Detail__r.Government_Contract_Type__c, 
                                             Service_Location__r.Location__r.Building__r.Id,
                                             Service_Location__r.Location__r.Building__r.Market_Area_ID__c,
                                             Service_Location__r.Location__r.Building__r.Market_Area_Name__c,
                                             Service_Location__r.Location__r.Building__r.Status__c,
                                             Service_Location__r.Location__r.Building__r.Net_Classification__c,
                                             Service_Location__r.Location__r.Building__r.Serving_LSO__r.LSO_CLLI__c,
                                             Service_Location__r.ICC_Subscriber_ID__c, 
                                             Service_Location__r.Account__r.ShippingStreet,
                                             Service_Location__r.Account__r.ParentId,  
                                             Order__r.Id, Order__r.Opportunity__r.Id,
                                             (select Id, Name, Active__c, IsPrintable__c, Approval_Requested_Date__c,
                                              LineItemCount__c, Term__c, MRC_Total__c,NRC_Total__c , nonPreferredAccess__c, PreferredAccessType__c,
                                              Bandwidth__c, Display_on_Solution__c,
                                              Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_Hash__c,
                                              Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c,
                                              Quote_Line_Item_Count__c,CreatedDate, Contract_Term_End_Date__c
                                              from OpportunityLocationConfigurations__r)
                                             from Opportunity_Location__c
                                             where Order__r.Opportunity__c = :opportunity.Id
                                             order by Service_Location__r.CreatedDate, Name
                                            ]){
                                                for (Technical_Information__c t : olocc.Technical_Information__r){
                                                    olocc.Current_Toll_Free_Provider__c = t.Toll_Free_Provider__c;	                                            
                                                }
                                                oppLocIds.add(olocc.id);
                                                if(olocc.Service_Location__r.Customer_Detail__r != null && olocc.Service_Location__r.Customer_Detail__r.Government_Contract_Type__c != null) contractTypes.add(olocc.Service_Location__r.Customer_Detail__r.Government_Contract_Type__c);
                                                opportunityLocations.add(olocc);
                                                BaaByBldgId.put(olocc.Service_Location__r.Location__r.Building__r.Id, new List<Building_Access_Availability__c>());
                                            }
        
        if(contractTypes.size() > 1)  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This opportunity has multiple Government Contract Types selected. Please correct the configured service locations\' customer information or start another opportunity for each contract before continuing.'));
        
        for(Building_Access_Availability__c b : [select Id, Building__c, Access_Technology_Name__c, Carrier__c, Maximum_Bandwidth__c, Minimum_Bandwidth__c, Status__c, Minimum_Required_Revenue__c, Building__r.Market_Area_Name__c from Building_Access_Availability__c where building__c in : BaaByBldgId.keyset()]){
            List<Building_Access_Availability__c> lb = BaaByBldgId.get(b.Building__c);
            lb.add(b);
            BaaByBldgId.put(b.Building__c, lb);
        }
        
        //get configs with expired items
        Set<Id> configIds = new Set<Id>();
        Set<Id> oServLocIds = new Set<Id>();
        for(Opportunity_Location__c  opportunityLocation : opportunityLocations) {
            oServLocIds.Add(opportunityLocation.Service_Location__c);
            for(OpportunityLocationConfiguration__c sol : opportunityLocation.OpportunityLocationConfigurations__r)
                oppSolutionIds.add(sol.id);
            if(opportunityLocation.Id != null) configIds.AddAll(getIds(opportunityLocation.OpportunityLocationConfigurations__r, 'Id'));
        }
        
        //Get List of All OLIs for solutions
        Map<Id,List<OLI__c>> oppSolOLIMap = getOLIsByConfigList(oppSolutionIds);
        Set<Id> configsWithExpiry = getIds([select OpportunityLocationConfiguration__c configId from OLI__c where OpportunityLocationConfiguration__c IN : configIds and (Price_Id__c = '') group by OpportunityLocationConfiguration__c], 'configId');
        
        //map to view objects
        List<OpportunityLocation> viewLocations = new List<OpportunityLocation>();
        List<Service_Location__c> opportunitySelectLocations = [select Name, ICC_Subscriber_ID__c, Billable__c, Location__r.Name, Location__r.Building__r.Net_Classification__c, Location__r.Building__r.Status__c, Location__r.Building__r.Address__c, Location__r.Building__r.City__c, Location__r.Building__r.State__c, Location__r.Building__r.Id, Location__r.Building__r.Market_Area_Name__c, Customer_Detail__r.Billing_ID__c from Service_Location__c  where Id in : oServLocIds];
        for(Opportunity_Location__c opportunityLocation : opportunityLocations)
            viewLocations.add(new OpportunityLocation(opportunityLocation, configsWithExpiry, opportunitySelectLocations, oppSolOLIMap));
        
        
        return viewLocations;
    }
    
    /**
* Returns all Id fields on the passed in SObject collection using
* the specified field path for retrieval.
*
* @param sObjects
*            list of SObjects from which Id fields will be returned
* @param fieldPath
*            the field path for each SObject
* @return a set of all Id fields found
*
* @author Scott Faucera
*/
    public static Set<Id> getIds(List<Sobject> objects, String fieldPath) {
        Set<Id> ids = new Set<Id>();
        
        String[] fields = fieldPath.split('\\.');
        for(SObject obj : objects) {
            for(Integer x = 0; x < fields.size() - 1 ; x++) {
                try { obj = (SObject)obj.get(fields[x]); }
                catch(Exception e) { obj = obj.getSObject(fields[x]); }
            }
            if(obj != null){
                Id id = ((Id)obj.get(fields[fields.size() - 1]));
                if(id != null) ids.add(id);
            }
        }
        return ids;
    }
    
    /**
* Action method that deletes an opportunity location config
*
* @param LocationConfigurationId */ public String LocationConfigurationId_deleteOpportunityLocationConfiguration{get; set;} /*
*       the Id of the opportunity location configuration to delete
*/
    public PageReference deleteSolution() {
        delete new OpportunityLocationConfiguration__c(Id = param_solutionId);
        
        //refresh collection
        this.opportunityLocations = createOpportunityLocations(this.opportunity);
        setUpProductFamily();
        ScoreDeal();
        
        return null;
    }
    
    public void updateSolutionStatus(){
        
        integer SMApprovableCount = 0;
        integer SMUnApprovableCount = 0;
        List<OLI__c> listOLI = new List<OLI__c>();
        
        Map<Id, OpportunityLocationConfiguration__c> solMap = new Map<Id, OpportunityLocationConfiguration__c>([select
                                                                                                                Id, Approval_Date__c, Approver__r.Name, Active__c, Approval_Requested_Date__c
                                                                                                                ,(select Approval_Status__c, Approved__c, PP_Sales_Rate_Plan_Description__c , OpportunityLocationConfiguration__r.Id, SPC_MRC_Is_Quote__c, Off_Footprint__c, Off_Footprint_Approved__c from Opportunity_Line_Items__r)
                                                                                                                from OpportunityLocationConfiguration__c
                                                                                                                where Opportunity_Location__c in :oppLocIds]);
        
        for(OpportunityLocation opploc : this.opportunityLocations) {
            for(Solution solution : opploc.solutions) {
                integer icbcnt = 0;
                integer ldrcnt = 0;
                Integer badcnt = 0;
                Integer cmptcnt = 0;
                OpportunityLocationConfiguration__c sol = solMap.get(solution.rawsolution.id) == null ? new OpportunityLocationConfiguration__c() :  solMap.get(solution.rawsolution.id);
                
                for(OLI__c oli :sol.Opportunity_Line_Items__r){
                    string status = oli.Approval_Status__c;
                    boolean isapproved = (!String.IsEmpty(String.valueOf(oli.Approved__c))) ? oli.Approved__c : false;
                    boolean isquoteitem = (!String.IsEmpty(String.valueOf(oli.SPC_MRC_Is_Quote__c))) ? oli.SPC_MRC_Is_Quote__c : false;
                    Boolean isbaditem = (!String.IsEmpty(String.valueOf(oli.Off_Footprint__c && !oli.Off_Footprint_Approved__c))) ? oli.Off_Footprint__c && !oli.Off_Footprint_Approved__c : false;
                    boolean iscomptitem = !String.IsEmpty(oli.PP_Sales_Rate_Plan_Description__c) && oli.PP_Sales_Rate_Plan_Description__c.containsIgnoreCase('Competitive Building');
                    
                    if(!String.IsEmpty(status) && !isapproved){
                        if(status.contains('Offer')) icbcnt++;
                        else if(status.contains('Sales')) ldrcnt++;
                    }
                    
                    //one off quote noted items
                    if(isquoteitem && !isapproved) icbcnt++;
                    
                    if(isbaditem) badcnt++;
                    if(iscomptitem && !isapproved) cmptcnt++;
                }
                
                solution.icbCount = (!String.IsEmpty(String.valueOf(icbcnt))) ? icbcnt : 0;
                solution.mgrCount = (!String.IsEmpty(String.valueOf(ldrcnt))) ? ldrcnt : 0;
                solution.badCount = (!String.IsEmpty(String.valueOf(badcnt))) ? badcnt : 0;
                solution.cmptCount = cmptcnt;
                solution.approvalRequested = sol.Approval_Requested_Date__c != null;
                solution.approvalRequestDate = sol.Approval_Requested_Date__c != null? sol.Approval_Requested_Date__c.format() : '';
                
                if(icbcnt > 0){
                    solution.approvalStatus = 'Offer Management Approval Required';
                    SMUnApprovableCount += sol.Active__c?1:0;
                }
                else if (ldrcnt > 0){
                    solution.approvalStatus = 'Sales Management Approval Required';
                    SMApprovableCount += sol.Active__c && !solution.approvalRequested?1:0;
                }
                else{
                    solution.approvalStatus = 'Approved';
                    solution.approvalDate = sol.Approval_Date__c;
                    solution.approver = sol.Approver__r.Name;
                }
            }
        }
        salesManagerApprovable = SMApprovableCount > 0;
    }
    
    /**************************************************************************/
    /*Do approval action                                                       */
    /**************************************************************************/
    public PageReference approveActiveSolutions() {
        List<OLI__c> listOLIs =  getActiveOLIs();
        SolutionApprovalUtils.ApproveSoluitonFromOLIs(listOLIs);
        //refresh solution
        this.opportunityLocations = createOpportunityLocations(this.opportunity);
        
        updateSolutionStatus();
        PageReference pageReference = Page.ManageLocationProducts;
        pageReference.getParameters().put(PARAMETER_OPPORTUNITY_ID, this.opportunity.Id);
        pageReference.setRedirect(true);
        return pageReference;
    }
    
    private List<OLI__c> getActiveOLIs(){
        Set<Id> ids = new Set<Id>();
        for(OpportunityLocation ol : this.opportunityLocations) {
            if(!ol.rawLocation.On_Hold__c){
                for(Solution sol : ol.solutions) {
                    if(sol.rawSolution.Active__c) ids.add(sol.rawSolution.Id);
                }
            }
        }
        
        return [Select OpportunityLocationConfiguration__c, Approval_Status__c, Approved__c, Off_Footprint__c, Off_Footprint_Approved__c From OLI__c o WHERE o.OpportunityLocationConfiguration__r.Id in:ids and (Approved__c = false or (Off_Footprint__c = true and Off_Footprint_Approved__c = false))];
    }
    
    /**************************************************************************/
    /* End approval action                                                     */
    /**************************************************************************/
    
    /*
* View object for displaying Opportunity Locations
*/
    public class OpportunityLocation {
        
        public OpportunityLocation(){}
        
        @AuraEnabled 
        public Opportunity_Location__c rawLocation {get;set;}
        @AuraEnabled
        public String displayName { get; set; }
        @AuraEnabled
        public String buildingRedirect { get; set; }
        @AuraEnabled
        public List<Solution> solutions { get; set; }
        @AuraEnabled
        public String buildingId {get;set;}
        @AuraEnabled
        public List<OpportunityLocationConfiguration__c> solsToInsert {get;set;}
        @AuraEnabled
        public Decimal score {get; private set;}
        @AuraEnabled
        public Boolean canBeScored {get;set;}
        @AuraEnabled
        public Boolean badDeal {get;set;}
        
        public OpportunityLocation(Opportunity_Location__c rawLocation, Set<Id> configsWithExpiry, List<Service_Location__c> opportunitySelectLocations, Map<Id, List<OLI__c>> oppSolOLIMap) {
            this.canBeScored = false;
            this.rawLocation = rawLocation;
            solsToInsert = new List<OpportunityLocationConfiguration__c>();
            String fullFileURL = system.URL.getSalesforceBaseUrl().toExternalForm();
            
            List<Building_Access_Availability__c> buildAccess = new List<Building_Access_Availability__c>();
            for(Service_Location__c oppLoc : opportunitySelectLocations) {
                if(oppLoc.Id == rawLocation.Service_Location__c){
                    this.displayName = oppLoc.Name + ' - '
                        + oppLoc.Location__r.Name
                        + (!String.IsEmpty(oppLoc.Location__r.Building__r.Net_Classification__c) ? ('; Net-Class: ' + oppLoc.Location__r.Building__r.Net_Classification__c) : '')
                        + (!String.IsEmpty(oppLoc.Location__r.Building__r.Status__c) ? ('; Status: ' + oppLoc.Location__r.Building__r.Status__c) : '')
                        + ('; Billable: ' + (oppLoc.Billable__c ? 'Yes' : 'No'))
                        + (!String.IsEmpty(oppLoc.Customer_Detail__r.Billing_ID__c) ? ('; Billing ID: ' + oppLoc.Customer_Detail__r.Billing_ID__c) : '')
                        + (!String.isEmpty(oppLoc.ICC_Subscriber_ID__c) ? ' [' + oppLoc.ICC_Subscriber_ID__c + ']' : '');
                    this.buildingId = oppLoc.Location__r.Building__r.Id;
                    this.buildingRedirect = fullFileURL + '/' + oppLoc.Location__r.Building__r.Id;
                }
            }
            
            solutions = new List<Solution>();
            for(OpportunityLocationConfiguration__c config : rawLocation.OpportunityLocationConfigurations__r) {
                Solution s = new Solution(config, false,oppSolOLIMap.get(config.Id));
                solutions.add(s);
            }
        }
        
        public void Score(){
            this.score = 0.0;
            for(Solution s : this.solutions){
                if(s.rawSolution.Active__c){
                    this.score = s.Score;
                    this.badDeal = s.badDeal;
                    this.canBeScored |= s.canBeScored;
                }
            }
        }
        
        public void createNewSolution(string name, string term, string bandwidth, boolean displayOnSol) {
            Boolean active = (solutions.size() == 0);
            Boolean display = displayOnSol;
            Solution s = new Solution(name, term, active, rawLocation.Id, bandwidth,display,null);
            solutions.add(s);
            solsToInsert.add(s.rawSolution);
        }
    }
    
    /**
* View object for displaying Opportunity Locations Configurations
*/
    public class Solution {
        
        public Solution(){}
        
        @AuraEnabled 
        public OpportunityLocationConfiguration__c rawSolution { get;set;}
        @AuraEnabled
        public Boolean hasLineItems { get; set; }
        @AuraEnabled
        public Boolean hasExpiredLineItems { get; set; }
        @AuraEnabled
        public transient List<QuoteWrapper.ProductFamily> productFamilies { get; set; }     //this does not persist between calls
        @AuraEnabled
        public integer icbCount { get; set; }
        @AuraEnabled
        public integer mgrCount { get; set; }
        @AuraEnabled
        public integer cmptCount {get;set;}
        @AuraEnabled
        public Integer badCount { get; set; }
        @AuraEnabled
        public string approvalStatus { get; set; }
        @AuraEnabled
        public string approvalDate {get; set;}
        @AuraEnabled
        public string approver {get; set;}
        @AuraEnabled
        public string preferredAccessType {get; set;}
        @AuraEnabled
        public Boolean nonPreferredPicked {get; set;}
        @AuraEnabled
        public Decimal Score {get; private set;}
        @AuraEnabled
        public Boolean canBeScored {get; private set;}
        @AuraEnabled
        public Boolean badDeal {get; private set;}
        @AuraEnabled
        public Boolean approvalRequested {get; set;}
        @AuraEnabled
        public string approvalRequestDate {get; set;}
        @AuraEnabled
        public date contractEndDate {get; set;}
        
        public Solution(String term, Boolean active, Id locId, Date contractEndDate) {
            this.rawSolution = new OpportunityLocationConfiguration__c(Name=DEFAULT_CONFIGURATION_NAME, Term__c=term, Active__c=active, Opportunity_Location__c = locId, Contract_Term_End_Date__c = contractEndDate);
            insert this.rawSolution;
            this.hasLineItems = false;
            this.hasExpiredLineItems = false;
            this.preferredAccessType = '';
            this.nonPreferredPicked = false;
            this.productFamilies = null;
            this.Score = 0.0;
            this.badDeal = false;
            this.canBeScored = false;
            Score(new List<OLI__c>());
        }
        
        public Solution(String name, String term, Boolean active, Id locId, string bandwidth, boolean display, Date contractEndDate) {
            this.rawSolution = new OpportunityLocationConfiguration__c(Name = name, Term__c = term, Active__c = active, Opportunity_Location__c = locId, Bandwidth__c = bandwidth, Display_on_Solution__c = display, Contract_Term_End_Date__c = contractEndDate);
            this.hasLineItems = false;
            this.hasExpiredLineItems = false;
            this.preferredAccessType = '';
            this.nonPreferredPicked = false;
            this.productFamilies = null;
            this.Score = 0.0;
            this.badDeal = false;
            this.canBeScored = false;
            Score(new List<OLI__c>());
        }
        
        public Solution(OpportunityLocationConfiguration__c rawSolution, Boolean hasExpiredItems, List<OLI__c> olis) {
            this.rawSolution = rawSolution;
            this.hasLineItems = (this.rawSolution.LineItemCount__c > 0);
            this.hasExpiredLineItems = hasExpiredItems;
            this.preferredAccessType = rawSolution.PreferredAccessType__c;
            this.nonPreferredPicked = rawSolution.nonPreferredAccess__c;
            this.Score = 0.0;
            this.badDeal = false;
            this.canBeScored = false;
            this.contractEndDate = rawSolution.Contract_Term_End_Date__c;
            Score(olis);
            if(this.rawSolution.LineItemCount__c > 0) this.productFamilies = new List<QuoteWrapper.ProductFamily>();
        }
        
        private void Score(List<OLI__c> myOLIs){
            this.Score = 0.0;
            Integer idx = 0;
            Boolean checkNonAccessBandwidth = true;
            Boolean hasPreferredScoringProduct = false;
            if(myOLIs != null && myOLIs.size() > 0){
                for(idx = 0; idx < myOLIs.size(); ++idx){
                    OLI__c oli = myOLIs[idx];
                    if(oli.spc_component__r.Component_Group__c == 'Access/Bandwidth'){
                        hasPreferredScoringProduct = oli.pp_Sales_Rate_Plan_Description__c.containsIgnoreCase('eof')
                            || oli.pp_Sales_Rate_Plan_Description__c.containsIgnoreCase('eoc')
                            || oli.pp_Sales_Rate_Plan_Description__c.containsIgnoreCase('eotdm')
                            || oli.pp_Sales_Rate_Plan_Description__c.containsIgnoreCase('extended');
                        this.canBeScored = true;
                        if((oli.OLI_Score__c == null ? 0.0 : oli.OLI_Score__c) > this.Score || (checkNonAccessBandwidth && hasPreferredScoringProduct))
                            this.Score = oli.OLI_Score__c == null ? 0.0 : oli.OLI_Score__c;
                        this.badDeal |= oli.Off_Footprint__c && !oli.Off_Footprint_Approved__c;
                        checkNonAccessBandwidth = !hasPreferredScoringProduct;
                    }
                    else if(checkNonAccessBandwidth &&
                            (oli.spc_component__r.Sales_Product__r.Sales_Product_Group__c == 'Security Services' ||
                             oli.spc_component__r.Sales_Product__r.Sales_Product_Group__c == 'Hosted Applications' ||
                             oli.pp_Sales_Product__c == 'Colocation Services' ||
                             oli.pp_Sales_Product__c == 'Hosted PBX')){
                                 this.canBeScored = true;
                                 if((oli.OLI_Score__c == null ? 0.0 : oli.OLI_Score__c) > this.Score)
                                     this.Score = oli.OLI_Score__c == null ? 0.0 : oli.OLI_Score__c;
                                 this.badDeal |= oli.Off_Footprint__c && !oli.Off_Footprint_Approved__c;
                             }
                }
            }
        }
    }
    
    private static Map<Id,List<OLI__c>> getOLIsByConfigList(List<id> configIds){
        Map<Id,List<OLI__c>> configOLIMap = new Map<Id,List<OLI__c>>();
        Boolean clearOffFootprintApprovals = false;
        clearOffFootprintApprovals = [select Id from OLI__c where Off_Footprint__c = true and Off_Footprint_Approved__c = false and OpportunityLocationConfiguration__c in :configIds
                                      AND PP_Package_Feature__c = false and OpportunityLocationConfiguration__r.Active__c = true and OpportunityLocationConfiguration__r.Opportunity_Location__r.on_hold__c = false].size() > 0;
        for(OLI__c o : [select
                        MRC__c,
                        MRC_Discount__c,
                        MRC_Total__c,
                        NRC__c,
                        NRC_Discount__c,
                        NRC_Total__c,
                        Qty__c,
                        Approval_Status__c,
                        Approved__c,
                        Off_Footprint__c,
                        Off_Footprint_Approved__c,
                        DQ__c,
                        PP_Feature_Group__c,
                        PP_Product_Pricing_Name__c,
                        PP_Sales_Product__c,
                        PP_Product_Family__c,
                        PP_Sales_Rate_Plan_Description__c,
                        PP_ServiceAgreementText__c,
                        PP_LD_Interstate__c,
                        PP_LD_Intrastate__c,
                        PP_Voice_Line__c,
                        PP_SalesProductExternalID__c,
                        PP_SalesRatePlanPricingExternalID__c,
                        Parent_Opportunity_Line_Item__c,
                        Parent_Opportunity_Line_Item__r.PP_SalesRatePlanPricingExternalID__c,
                        Price_Id__c,
                        SPC_Component_Id__c,
                        SPC_Sales_Product_Component_Id__c,
                        SPC_Feature_Group__c,
                        SPC_Sales_Selection_Rule_Name__c,
                        SPC_MaxQty__c,
                        SPC_MinQty__c,
                        SPC_MRC_Is_Quote__c,
                        SPC_Component__c,
                        SPC_Component__r.Component_Group__c,
                        SPC_Component__r.Sales_Product__c,
                        SPC_Component__r.Sales_Product__r.Sales_Product_Group__c,
                        MRC_Floor__c,
                        SPC_MRC_OnNet__c,
                        SPC_NRC_Is_Quote__c,
                        NRC_Floor__c,
                        Product_Family_Product__c,
                        Product_Family_Id__c,
                        OpportunityLocationConfiguration__c,
                        OLI_Score__c
                        From
                        OLI__c
                        Where
                        OpportunityLocationConfiguration__c in :configIds
                        AND PP_Package_Feature__c = false
                        Order by
                        PP_Product_Family_Sort__c,
                        PP_Sales_Product_Sort__c,
                        PP_Feature_Grouping_Sort__c,
                        PP_Sales_Rate_Plan_Description_Sort__c]){
                            if(clearOffFootprintApprovals) o.Off_Footprint_Approved__c = false;
                            
                            List<OLI__c> olis = configOLIMap.get(o.OpportunityLocationConfiguration__c) != null ? configOLIMap.get(o.OpportunityLocationConfiguration__c) : new List<OLI__c>();
                            olis.add(o);
                            configOLIMap.put(o.OpportunityLocationConfiguration__c, olis);
                        }
        return configOLIMap;
    }
    
    public Decimal ScoreDeal(){
        Decimal score = 0.0;
        Integer scoreNum = 0;
        Integer badNum = 0;
        Decimal badPercent = 0.0;
        this.isScored = false;
        for(OpportunityLocation op : this.opportunityLocations){
            op.Score();
            if(!op.rawLocation.On_Hold__c && op.canBeScored){
                isScored = true;
                score += op.score;
                ++scoreNum;
                if(op.badDeal) ++badNum;
            }
        }
        if(scoreNum > 0){
            badPercent = decimal.valueOf(badNum) / decimal.valueOf(scoreNum);
            score = score / decimal.valueOf(scoreNum);
        }
        if(score == null) score = 0.0;
        if(this.doScoring && this.isScored){
            Green_Light_Scoring__c glc = CustomSettingUtils.GetGreenLightScoringForScore(score);
            scoreName = glc.Image_Name__c;
            scoreHelpText = glc.Help_Text__c;
            helpText = glc.Help_Text__c;
            scorePercent = String.valueOf(score.setScale(2, RoundingMode.HALF_UP));
            if(opportunity.Deal_Score__c != score) saveOpp = true;
        }
        if(!this.isScored){
            score = -1.0;
            Green_Light_Scoring__c glc = CustomSettingUtils.GetGreenLightScoringForScore(score);
            scoreName = glc == null ? 'noscore' : glc.Image_Name__c;
            scoreHelpText = glc == null ? '' : glc.Help_Text__c;
            helpText = glc == null ? '' : glc.Help_Text__c;
            scorePercent = String.valueOf(score.setScale(2, RoundingMode.HALF_UP));
        }
        if(this.BlockPDFGen){
            badDeal = false;
            Bad_Deal_Percentage_Text__c bdpt = CustomSettingUtils.GetBadDealPercentageText(badPercent);
            if(bdpt != null){
                badDeal = true;
                badDealText = bdpt == null? '' : bdpt.text__c;
                helpText = bdpt == null? '' : bdpt.text__c;
            }
        }
        if(this.inCtor == null) this.inCtor = false;
        if(!this.inCtor) saveScore(score);
        return score;
    }
    
    public pageReference saveScoreToOpp(){
        //this whole thing is shady and should be revisited at some point.
        this.inCtor = false;
        scoreDeal();
        return null;
    }
    
    private void saveScore(Decimal score){
        Decimal s = score;
        if(s == null) s = ScoreDeal();
        if(this.saveOpp){
            this.opportunity.deal_score__c = s;
            update this.opportunity;
        }
    }
    
    public class lgt_ManageLocationProductsControllerException extends Exception { }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_ManageLocationProducts(); }
}