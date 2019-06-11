public with sharing class ManageLocationConfigurationsController implements TestUtils.ITestableClass {
    
    private static final String PARAMETER_OPPORTUNITY_ID = 'opportunityId';
    
    public Opportunity opportunity { get; private set; }
    public List<OpportunityLocation> opportunityLocations { get; private set; }
    
    public Boolean canIntegrate {get;set;}
	
    public static Map<String,DocuSettings__c> documentSettings {get;Set;}
    
    public ManageLocationConfigurationsController() {
        init();
    }
    
	/* UI Redirect Methods */
    public PageReference gotoOpportunity() { return (new ApexPages.StandardController(this.opportunity)).view(); }
    
    public PageReference gotoManageLocationProducts() {
        PageReference pageReference = Page.ManageLocationProducts;
        pageReference.getParameters().put('opportunityId', this.opportunity.Id);
        return pageReference;
    }
    
    public PageReference gotoGeneratePDF() {
        PageReference pageReference = Page.OpptyGeneratePDF;
        pageReference manageLocPage = Page.ManageLocationConfigurations;
        
        pageReference.getParameters().put('Id', this.opportunity.Id);
        string retUrl = manageLocPage.getUrl() + '?' + PARAMETER_OPPORTUNITY_ID + '=' + this.opportunity.Id;
        pageReference.getParameters().put('retURL', retURL);
        return pageReference;
    }
    
    /** Action methods that redirect to a Technical Information screen.
	* Includes lazy creation of the Technical Information record */
    
    public String TechInfoLinkString {get;Set;}
    public PageReference gotoTechInfoDocument(){
        Id docID = GlobalActions.GetSalesFormsContentVersionIDByTitle(TechInfoLinkString);
        Pagereference pageRef;
        if(docID != null){
            pageRef = new Pagereference('/' + docID);   
            pageRef.setRedirect(true);
        }
        
        return pageRef;
    }
    
	public String LocationId_gotoTechInfo {get; set;}
	public String TechInfoRecordTypeId_gotoTechInfo {get; set;}
	public String TechInfoId_gotoTechInfo {get; set;}
    public PageReference gotoTechInfo() {
        
        String techInfoId = TechInfoId_gotoTechInfo;
        system.debug('techInfoID: ' + techInfoId);
        if( String.IsEmpty(techInfoId) ) {
            
            // requery... the parent page doesn't pick up the inserts from here
            List<Technical_Information__c> lstTechInfo = [Select Id from Technical_Information__c where
                                                          Opportunity_Site__c =: LocationId_gotoTechInfo AND RecordTypeId =: TechInfoRecordTypeId_gotoTechInfo LIMIT 1];
            
            if( lstTechInfo.size() > 0 ) {
                techInfoId = lstTechInfo[0].Id;
            }
            else {
                system.debug('inserting techinfo');
                for(OpportunityLocation loc : this.opportunityLocations) {
                    if( loc.rawLocation.Id == LocationId_gotoTechInfo ) { 
                        techInfoId = loc.insertTechInfo(TechInfoRecordTypeId_gotoTechInfo);
                        break;
                    }
                }               
            }   
        }   
        
        //Now evaluate for Features Schedule
        RecordType rtFeatureSchedule = [select Id from RecordType WHERE SobjectType = 'Technical_Information__c' and DeveloperName = 'Features_Schedule' limit 1];
        
        PageReference pageRef = (TechInfoRecordTypeId_gotoTechInfo != rtFeatureSchedule.Id) ? new Pagereference('/' + techInfoId) : new Pagereference('/apex/managefeaturesschedule?id=' + techInfoId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public class ManageLocationConfigurationsControllerException extends Exception { }
	
    private void init() {       
        documentSettings = new map<string,DocuSettings__c>();
		if(DocuSettings__c.getAll() != null){
			for(DocuSettings__c ds :DocuSettings__c.getAll().values()){
				documentSettings.put(ds.Record_Type_Name__c,ds);
			}
		}
        
        // get/validate the opportunity ID from URL
        String opportunityId = Apexpages.currentPage().getParameters().get(PARAMETER_OPPORTUNITY_ID);
        System.debug('The opportunity ID passed to controller was: ' + (opportunityId == null ? '(null)' : opportunityId));
        if(opportunityId == null || opportunityId == '') {
            throw new ManageLocationConfigurationsControllerException('Missing or invalid opportunity ID.');
        }
        
        // get/validate the opportunity
        List<Opportunity> opportunities = [Select Id, Name, AccountId, Term__c, Can_Create_Order__c  From Opportunity Where Id = :opportunityId];
        if(opportunities.size() != 1) {
            throw new ManageLocationConfigurationsControllerException('Missing or invalid opportunity ID.');
        } 
        else {
            this.opportunity = opportunities.get(0);    
        }
        
        // set our integration flag
        this.canIntegrate = this.opportunity.Can_Create_Order__c == 'Yes';
        
        this.opportunityLocations = new List<OpportunityLocation>();
        for(Opportunity_Location__c l : [Select Id, Name, On_Hold__c, Opportunity__r.AccountId, Opportunity__r.Account.ICC_Account_Number__c, Turndown_Total__c, Order__r.Id, Order__r.Opportunity__c,
										            (Select Id, Name, Active__c, Term__c, LineItemCount__c, MRC_Total__c From OpportunityLocationConfigurations__r where Active__c = true), 
										            (Select Id, RecordTypeId, Name FROM Technical_Information__r Order By Name) 
													,Service_Location__r.Id, Service_Location__r.Name, Service_Location__r.Location__r.Name, Service_Location__r.Customer_Detail__r.Government_Contract_Type__c
										            From Opportunity_Location__c 
										            Where Order__r.Opportunity__c = :opportunity.Id and On_Hold__c != true
										            Order By Opportunity__r.Account.ParentId, Name]) {
			opportunityLocations.add(new OpportunityLocation(l));
        }
		
		setUpProductFamily();   
    }
    
    /* Helper method to create our view objects for the specified opportunity. */
    private  void setUpProductFamily(){
		
        Set<Id> solutionId = new Set<Id>();
        Map<Id, List<OLI__c>> solutionIdToOLI = new Map<Id, List<OLI__c>>();
        for(OpportunityLocation olc : opportunityLocations){
            if(olc.activeSolution != null) solutionId.add(olc.activesolution.rawSolution.Id);
        }
		
        Set<String> productFamily = new Set<String>();
        Set<String> productFamilyProduct = new Set<String>();
        for(OLI__c ol:[Select MRC__c, Name, Product_Family_Product__c, Product_Family_Id__c , MRC_Discount__c, MRC_Total__c, NRC__c, NRC_Discount__c,  
                       NRC_Total__c, Qty__c, PP_Product_Pricing_Name__c ,Approval_Status__c, OpportunityLocationConfiguration__c, Approved__c, DQ__c, PP_Package_Feature__c, Product_Pricing_Display_Name__c From OLI__c 
                       where OpportunityLocationConfiguration__c IN: solutionId Order by Product_Family_Id__c DESC]){
            List<OLI__c> l = solutionIdToOLI.get(ol.OpportunityLocationConfiguration__c) != null ? solutionIdToOLI.get(ol.OpportunityLocationConfiguration__c) : new List<OLI__c>();
            l.add(ol);
            solutionIdToOLI.put(ol.OpportunityLocationConfiguration__c, l);
            productFamily.add(ol.Product_Family_Id__c);
            productFamilyProduct.add(ol.Product_Family_Product__c);
        }
		
        productFamily = sortSetString(productFamily);
        ProductFamilyProduct = sortSetString(ProductFamilyProduct);
		
        Map<String, SPC_Product__c> nameToSPCProduct = new Map<String, SPC_Product__c>();
        Map<String, Id> nameToSPCProductSFDCID = new Map<String, ID>();
        for(SPC_Product__c sp:[Select Name,Sales_Product_Group__c From SPC_Product__c where name IN : productFamilyProduct]){
            nameToSPCProduct.put(sp.name,sp);
            nameToSPCProductSFDCID.put(sp.name,sp.id);
        }
		
        //All productfamil is set in this map accorting to the product family name                      
        Map<String, QuoteWrapper.ProductFamily> groupNameToProductFamily = new Map<String, QuoteWrapper.ProductFamily>(); 
		
        //All producty family is set on this map.All logic is executed while setting this map.
        Map<Id, Map<String, QuoteWrapper.ProductFamily>> solutionIdToProductFamily = new Map<Id, Map<String, QuoteWrapper.ProductFamily>>();
		
        Map<String, Set<String>> solutionIdToProductFamilylst = new Map<String, Set<String>>();
        Map<String, Id> productNameToId = new Map<String, Id>();
        for(Product_Families__c  pc : [Select Id, Name from Product_Families__c])
            productNameToId.put(pc.Name, pc.Id);
		
        for(Id solId:solutionIdToOLI.keyset()){
            Set<String> productAndSalesProductName=new Set<String>();
            groupNameToProductFamily = new Map<String, QuoteWrapper.ProductFamily>();
            Map<String, List<OLI__c>> productgroupAndSaleProductToOLI = new Map<String, List<OLI__c>>();
            for(OLI__c oli : solutionIdToOLI.get(solID)){
				String k = oli.Product_Family_Id__c + oli.Product_Family_Product__c;
				List<OLI__c> l = productgroupAndSaleProductToOLI.get(k) != null ? productgroupAndSaleProductToOLI.get(k) : new List<OLI__c>();
				l.add(oli);
				productgroupAndSaleProductToOLI.put(k, l);
            }
			
            system.debug('Product families' + productgroupAndSaleProductToOLI);
            for(OLI__C ol : solutionIdToOLI.get(solID)) {
				String k = ol.Product_Family_Id__c + ol.Product_Family_Product__c;
				if(!productAndSalesProductName.contains(k) && !ol.PP_Package_Feature__c){
					QuoteWrapper.Product product = new QuoteWrapper.Product();
					product.name = ol.Product_Family_Product__c;
					product.SFDCId = nameToSPCProductSFDCID.get(ol.Product_Family_Product__c);
					product.total = (ol.MRC_Total__c != null) ? ol.MRC_Total__c : 0;
	                product.productFamilyId = productNameToId.get(ol.Product_Family_Id__c);
					
                    for(OLI__c lineItem : productgroupAndSaleProductToOLI.get(k))
                        product.lines.add(new QuoteWrapper.QuoteLineItem(lineItem));
					
					if(!solutionIdToProductFamilylst.containskey(solId)) solutionIdToProductFamilylst.put(solId, new Set<String>{ol.Product_Family_Id__c});  
					else solutionIdToProductFamilylst.get(solID).add(ol.Product_Family_Id__c);
					
					QuoteWrapper.ProductFamily f = groupNameToProductFamily.get(ol.Product_Family_Id__c) != null ? groupNameToProductFamily.get(ol.Product_Family_Id__c) : new QuoteWrapper.ProductFamily(ol.Product_Family_Id__c, productNameToId.get(ol.Product_Family_Id__c));
					f.products.add(product);
	                groupNameToProductFamily.put(ol.Product_Family_Id__c, f);
					
	                productAndSalesProductName.add(k);
				}
            }
			
            if(groupNameToProductFamily.size() > 0) solutionIdToProductFamily.put(solId, groupNameToProductFamily);
        }
		
        system.debug('Product name to product QuoteWrapper'+solutionIdToProductFamily);        
        
        //Setting the solution id to respective location
        for(OpportunityLocation op : opportunityLocations){
            if(op.activeSolution != null){
                solutionId.add(op.activeSolution.rawsolution.id);
                if(solutionIdToProductFamilylst.containskey(op.activeSolution.rawsolution.id)){
                    op.activeSolution.productFamilies.clear();
                    for(String prodf : solutionIdToProductFamilylst.get(op.activeSolution.rawsolution.id))
						op.activeSolution.productFamilies.add(solutionIdToProductFamily.get(op.activeSolution.rawsolution.id).get(prodf));
                }
				
                if(op.activeSolution.productFamilies != null && op.activeSolution.productFamilies.size() > 0)
                    op.activeSolution.productFamilies = QuoteWrapper.sortListByProductName(op.activeSolution.productFamilies);
            }
        }
        
        system.debug('Opportuntiy Location' + opportunityLocations);           
        setuptotalonLocation();
        
    }
	
    public void setuptotalonLocation(){
        for(OpportunityLocation op:opportunityLocations){
            for(QuoteWrapper.ProductFamily pdf : op.activeSolution != null && op.activeSolution.productFamilies != null ? op.activeSolution.productFamilies : new List<QuoteWrapper.ProductFamily>()){
                for(QuoteWrapper.Product pro : pdf.products != null ? pdf.products : new List<QuoteWrapper.Product>()){
                    pro.total=0;
                    for(QuoteWrapper.QuoteLineItem quo : pro.lines != null ? pro.lines : new List<QuoteWrapper.QuoteLineItem>()){
                        pro.total += quo.rawOLI.MRC_Total__c;
                    }
                }
            }
        }
    }
    
    public Static Set<String> sortSetString(Set<String> s){
        List<String> l = new List<String>(s);
        l.sort();
        return new Set<String>(s);
    }
    
    public class OpportunityLocation {
        
        public Opportunity_Location__c rawLocation { get; set; }
        public Solution activeSolution { get; set; }
        public List<wrapTI> technicalInfos { get; set; }
        
        public OpportunityLocation(Opportunity_Location__c loc) {
            rawLocation = loc;
            
            if(rawLocation.Id != null) {
                technicalInfos = new List<wrapTI>();
		        for(Schema.RecordtypeInfo rti : Technical_Information__c.sObjectType.getDescribe().getRecordTypeInfos()) {
		            if(rti.isAvailable() && !(rti.getName().equalsIgnoreCase('Master'))){
	                    Technical_Information__c t = findExistingTechInfo(rti.getRecordTypeId());
	                    if(t == null) t = new Technical_Information__c(Name = rti.getName(), Opportunity_Site__c = loc.Id, RecordTypeId = rti.getRecordTypeId());
	                    technicalInfos.add(new wrapTI(t, rti.getName()));
					}         
		        }
                
                if (!loc.OpportunityLocationConfigurations__r.isEmpty()) {
                    activeSolution = new Solution(loc.OpportunityLocationConfigurations__r[0]);
                }
            }
        }
        
        private Technical_Information__c findExistingTechInfo(Id recordTypeId) {
            for(wrapTI wrapObject : technicalInfos) {
				Technical_Information__c t = wrapObject.rawTI;
                if(t.RecordTypeId == recordTypeId) return t;
            } 
            return null;
        }
        
        public Id insertTechInfo(Id recordTypeId ) {
            Technical_Information__c techInfo = findExistingTechInfo(recordTypeId);
			if(techInfo != null) insert techInfo;
            return (techInfo != null) ? techInfo.Id : null;
        }
    }
    
    public class Solution {
        public OpportunityLocationConfiguration__c rawSolution { get;set;}
        public Boolean hasLineItems { get; set; }
        public List<QuoteWrapper.ProductFamily> productFamilies { get; set; }        
        
        public Solution(OpportunityLocationConfiguration__c rawSolution) {
            this.rawSolution = rawSolution;
            this.hasLineItems = (this.rawSolution.LineItemCount__c > 0);
            this.productFamilies = QuoteWrapper.getConfigFamilies(rawSolution.Id);
        }
    }
    
    public class wrapTI {
        public Technical_Information__c rawTI {get;set;}
        public String displayName {get;set;}
        public boolean overrideLink {get;set;}
        public String documentName {get;set;}
        public String overrideDisplayName {get;set;}
        
        public wrapTI (Technical_Information__c ti, String display) {
            rawTI = ti;
            displayName = display;          
          	
			DocuSettings__c ds = documentSettings.get(display);
			overrideLink = ds != null;
			if(overrideLink){
                documentName = ds.Document_Name__c;
                overrideDisplayName = ds.Override_Name__c;
			}
        }
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_ManageLocationConfigurations(); }
}