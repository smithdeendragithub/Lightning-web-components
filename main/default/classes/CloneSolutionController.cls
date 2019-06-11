/**
* Controller for cloning a solution.
*
* @author Scott Faucera
*
*/
public with sharing class CloneSolutionController implements TestUtils.ITestableClass { 
    
    /**
    * Default search constants
    */
    private static final String DEFAULT_SEARCH_OPPORTUNITY_NAME = '';
    private static final String DEFAULT_SEARCH_ACCOUNT_NAME = '';
    private static final String DEFAULT_SEARCH_SOLUTION_NAME = '';
    private static final Boolean DEFAULT_SEARCH_EXCLUDE_EMPTY_SOLUTIONS = false;
    private static final Boolean DEFAULT_SEARCH_INCLUDE_ONLY_MY_OPPORTUNITIES = false;
    private static final Integer DEFAULT_SEARCH_MAX_RESULTS = 50;
    
    /**
    * Search parameters from the search form
    */
    public Boolean searchMySolutionsOnly { get; set; }
    public String searchSolutionName { get; set; }
    public String searchOpportunityName { get; set; }
    public String searchAccountName { get; set; }
    public Boolean searchExcludeEmptySolutions  { get; set; }
    public Integer searchMaxResults { get; set; }
    
    /**
    * The current location configuration instance
    */
    //public OpportunityLocationConfiguration__c opportunityLocationConfiguration { get; private set; }
    
    public String opportunityID {get;Set;}
    
    public Map<string,OpportunityLocationConfiguration__c> cloneableSolutions {get;Set;}

	public string cloneableSolutionsJSON{
		get{
			return JSON.serialize(cloneableSolutions,true);
		}
	}
    public List<String> solutionsToCloneTo {get;Set;}
    
    public List<SelectOption> availableSolutions {get;Set;}
    
    /**
    * Holds the current results from the last search
    */
    public List<OpportunityLocationConfiguration> searchResults { get; private set; }    
    
    //page parameter populates this, used as a default search parameter when passed in
    public String cloneFromSolutionID {get;Set;}
    
	public Set<String> allSolsWithFailedItems {	get; private set;}
	public Map<String, List<lineItem>> solNameToNotClonedLineItems {get; private Set;}
    /**
    * Sole constructor
    */
    public CloneSolutionController() {
        
        // initialize controller
        init();
    }
    
    
    /**
    * Action method that redirects into the manage location products page
    */
    public PageReference gotoManageLocationProducts() {
        
        // redirect to manage location products page
        PageReference pageReference = Page.ManageLocationProducts;
        pageReference.getParameters().put('opportunityId', opportunityID);
        pageReference.setRedirect(true);
        return pageReference;
    }
	
	public PageReference createNewSolution(){
		PageReference pr = Page.CreateSolution;
		pr.getParameters().put('opportunityID', opportunityID);
		pr.getParameters().put('retUrl', Page.CloneSolution.getUrl() + '?opportunityID=' + opportunityID + (!String.isEmpty(cloneFromSolutionID) ? '&opportunityLocationConfigurationId=' + cloneFromSolutionID : ''));
		pr.setRedirect(true);
		return pr;
	}
    
    /**
    * Action method that redirects into the manage location products page
    */
    public PageReference searchSolutions() {
        
        // build soql statement
        // added myID__c field in soql statement
        String selectStatement = 'Select Name, Opportunity_Location__r.Order__r.Opportunity__r.Name, Opportunity_Location__r.Service_Location__r.Account__r.Name, Term__c, Opportunity_Location__r.Service_Location__r.Name,Opportunity_Location__r.Service_Location__r.ICC_Subscriber_ID__c,CreatedDate,'
            + ' (Select Id, myID__c, DQ__c,Qty__c, MRC__c,PP_SalesProductExternalID__c, MRC_Discount__c, MRC_Total__c,MRC_Floor__c, NRC__c, NRC_Discount__c,NRC_Floor__c,SPC_Sales_Selection_Rule_Name__c,Price_Id__c,AccessTechName__c,SPC_Feature_Group__c,SPC_Component_Id__c,SPC_Sales_Product_Component_Id__c,SPC_MaxQty__c,SPC_MinQty__c,Bandwidth__c,PP_Per_Account__c,SPC_MRC_OnNet__c,SPC_NRC_Is_Quote__c,PP_Voice_Line__c,PP_Voice_Line_Option__c,PP_Package__c,  PP_LD_Interstate__c,  PP_LD_Intrastate__c,NRC_Total__c,Parent_Opportunity_Line_Item__c,Product_Family_Id__c,MRCList__c,PP_Feature_Group__c,SPC_Sales_Product__c,Product_Family_Product__c, ParentName__c, Approval_Status__c, Approved__c,SPC_MRC_Is_Quote__c,Config_Parent__c,Group_Name__c,Parent_Relationship__c,SPC_Component__c  from Opportunity_Line_Items__r)' 
            + ' From OpportunityLocationConfiguration__c';
        String whereStatement = 'Where LineItemCount__c != 0';
        String orderByStatement = 'Order By Name';
        String limitStatement = 'Limit ' + searchMaxResults;
        
        //Removing this line to remove the market specific logic, we will handle cloning between markets
        //whereStatement = 'Where (OpportunityLocationConfiguration__c.Market_Independent__c = true or Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_ID__c = \'' + opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_ID__c + '\' ) ';
        
        if(searchExcludeEmptySolutions) {
            whereStatement += ' AND LineItemCount__c > 0';
        }
        if(searchMySolutionsOnly) {
            whereStatement += ' AND Opportunity_Location__r.Order__r.Opportunity__r.OwnerId = \'' + UserInfo.getUserId() + '\'';
        }
        if(searchSolutionName.trim() != '') {
            whereStatement += ' AND Name LIKE \'%' + string.escapeSingleQuotes(searchSolutionName.trim()) + '%\'';
        }
        if(searchOpportunityName.trim() != '') {
            whereStatement += ' AND Opportunity_Location__r.Order__r.Opportunity__r.Name LIKE \'%' + string.escapeSingleQuotes(searchOpportunityName.trim()) + '%\'';
        }
        if(searchAccountName.trim() != '') {
            whereStatement += ' AND Opportunity_Location__r.Service_Location__r.Account__r.Name LIKE \'%' + string.escapeSingleQuotes(searchAccountName.trim()) + '%\'';
        }
        if(cloneFromSolutionID != null && cloneFromSolutionID.toLowerCase() != 'null'){
            whereStatement += ' AND Id = \'' + cloneFromSolutionID + '\'';
        }
        
        String soql = selectStatement + ' ' + whereStatement + ' ' + orderByStatement + ' ' + limitStatement;
        System.debug('Dynamic SOQL prepares as: ' + soql);
        
        // execute the search
         
            Map<String,Boolean> componentNameToExpireBoolean=new Map<String,Boolean>(); 
            List<OpportunityLocationConfiguration__c> opportunityLocationlst=Database.query(soql);
            List<OLI__c> olilst=new List<OLI__c>();
            for(OpportunityLocationConfiguration__c oloc:opportunityLocationlst)
            {
                for(OLI__c oli:oloc.Opportunity_Line_Items__r)
                {
                    olilst.add(oli);
                }
            }
            componentNameToExpireBoolean=getPricingByPriceIDs(olilst);

        searchResults = new OpportunityLocationConfigurationAssembler().fromNativeOpportunityLocationConfigurations(opportunityLocationlst,componentNameToExpireBoolean);
        // searchResults=new List<OpportunityLocationConfiguration>();
        // process results
        Map<Id, List<LineItem>> remediates = new Map<Id, List<LineItem>>();
        if(searchResults.size()>0)
        {
                    for(OpportunityLocationConfiguration config : searchResults) {
                        config.hasExpiredLines = false;
                        config.hasOutOfAreaLines = false;
                        config.hasNoTermLines = false;
                        for(LineItem lineItem : config.lineItems) {
                            
                            // find items needing remediation
                            if(lineItem.expired){
                               /*lineItem.marketAreaId != opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_ID__c ||
                                lineItem.opportunityLocationConfiguration.term != opportunityLocationConfiguration.Term__c ){*/
                                
                                List<LineItem> lineItems = remediates.get(lineItem.salesProductRatePlanId);
                                if(lineItems == null) {
                                    lineItems = new List<LineItem>();
                                    lineItems.add(lineItem);
                                    remediates.put(lineItem.salesProductRatePlanId, lineItems);
                                } else {
                                    lineItems.add(lineItem);
                                }
                                
                                //if(lineItem.marketAreaId != opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_ID__c) {
                                //    lineItem.outsideMarketArea = true;
                                //}
                                
                                //if(config.term != opportunityLocationConfiguration.Term__c) {
                                //    lineItem.noTerm = true;
                                //}
                            }
                        }
                    }
        }
        
        // if we have items...
        if(!remediates.isEmpty()) {
            
                    }
        
        // order items by reference
        for(OpportunityLocationConfiguration config : searchResults) {
            List<LineItem> roughItems = config.lineItems.clone();
            config.lineItems.clear();
            for(LineItem roughItem : roughItems) {
                if(roughItem.parentLineItem == null) {
                    config.lineItems.add(roughItem);
                    config.lineItems.addAll(roughItem.childLineItems);
                }
            }
        }
        
        for(OpportunityLocationConfiguration config : searchResults) {
            for(LineItem item : config.lineItems) {
                if (item.expired) {
                    config.hasExpiredLines = true;
                }
                
                if (item.outsideMarketArea) {
                    config.hasOutOfAreaLines = true;
                }
                
                if (item.noTerm) {
                    config.hasNoTermLines = true;
                }
            }
        }
        

        // stay on page
        return null;
    }
	
	private Map<string,Boolean> getPricingByPriceIDs(List<OLI__c> existingoli){
		Map<String, Boolean> componentNameToExpireBoolean = new Map<String, Boolean>();
		List<String> priceIds = new List<String>();
		
		for(OLI__c ol:existingoli)
			priceIds.add(ol.Price_Id__c);
		
		List<SPC_Pricing__c> pricingReturn = CatalogUtils.GetPricingByPricingID(priceIds);
				
		for(SPC_Pricing__c price : pricingReturn) {			
			if(price.is_expired__c)
				componentNameToExpireBoolean.put(price.price_id__c,price.is_expired__c);
		}		
		
		return componentNameToExpireBoolean;
	}
    
    /**
    * Action method that imports line items from a config
    *
    * @param configId */ public String ConfigId_cloneConfig {get; set;} /**
    *       id configuration to import
    * @param mode */ public String Mode_cloneConfig {get; set;} /**
    *       mode for action
    */
    public PageReference cloneConfig() {
		allSolsWithFailedItems = new Set<String>(); 
		solNameToNotClonedLineItems = new Map<String, List<lineItem>>();
		
		//get products that shouldn't clone because they are hidden in cpq
		Set<decimal> invalidProductIds = new Set<decimal>();
		for(SPC_Product__c prod : [Select Id,SalesProductExternalID__c From SPC_Product__c Where Hide_In_Wizard__c = true or Hide_In_New_CPQ__c = true]){
			invalidProductIds.add(prod.SalesProductExternalID__c);
		}


        // delete existing line items as compensating logic for the long running transaction
        List<OLI__c> deleteLineItems = [Select Id From OLI__c Where OpportunityLocationConfiguration__c in :solutionsToCloneTo];
        if(!deleteLineItems.isEmpty()) {
            delete deleteLineItems;
        }
        
        // find config to clone
        OpportunityLocationConfiguration clone = null;
        for(OpportunityLocationConfiguration olc : searchResults) {
            if(olc.id == ConfigId_cloneConfig) {
                clone = olc;
                break;
            }   
        }
        if(clone == null) {
            // we should never get here
            throw new CloneSolutionControllerException('Invalid config ID for cloning.');   
        }
		
        
        // create line items from clone
       
        system.debug('Clone value'+clone);
        
        //Get all SPCIds from solution cloning from
        Map<Id,Decimal> oliSPCIdsToCloneFrom = new Map<Id,Decimal>();

        for(LineItem lineItem : clone.lineItems) {
            oliSPCIdsToCloneFrom.put(lineItem.id,lineItem.SalesProductComponentID);
        }
        
        //If the market doesnt' have the SPCID then don't clone it
        Map<Id,String> solMarkets = new Map<Id,String>();
        Map<Id,Decimal> solTerms = new Map<Id,Decimal>();
        for(String s : solutionsToCloneTo){
            solMarkets.put(s,cloneableSolutions.get(s).Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c);
            solTerms.put(s,cloneableSolutions.get(s).Term__c == null ? 0 : decimal.valueOf(cloneableSolutions.get(s).Term__c));
            
        }
        
        
        //String market = opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c;
        //Decimal term = Decimal.valueof(opportunityLocationConfiguration.Term__c);
        
        //Map Market Map Term Map SalesProductComponentID, PricingRow
        Map<String,Map<string,Map<Decimal,SPC_Pricing__c>>> spcPricingMap = new Map<String,Map<string,Map<Decimal,SPC_Pricing__c>>>();
        List<Decimal> spcIdsFromMap = oliSPCIdsToCloneFrom.values();
        List<Decimal> solTermList = solTerms.values();
        //Include 0 term items
        List<String> solMarketList = solMarkets.values();

        for(SPC_Pricing__c spcP : Database.query('select ' + string.join(new List<String>(SchemaUtils.RetrieveFullObjectFieldSet(SPC_Pricing__c.getsObjectType())), ', ') + ' from SPC_Pricing__c Where Sales_Product_Component_ID__c in :spcIdsFromMap and Market__c in :solMarketList and (Term__c in :solTermList or Term__c = 0) and is_expired__c = false ')){
            if(spcPricingMap.get(spcP.Market__c) != null){
				Map<string,Map<Decimal,SPC_Pricing__c>> termPricing = spcPricingMap.get(spcP.Market__c);
				if(termPricing.get(string.valueOf(spcP.term__c)) != null){
					termPricing.get(string.valueOf(spcP.term__c)).put(spcP.Sales_Product_Component_ID__c,spcP);
				}
				else{
                    Map<Decimal,SPC_Pricing__c> tempPricing = new Map<Decimal,SPC_Pricing__c>();
					tempPricing.put(spcP.Sales_Product_Component_ID__c,spcP);
					spcPricingMap.get(spcP.Market__c).put(string.valueOf(spcP.Term__c),tempPricing);	
				}
            }
            else{
                Map<Decimal,SPC_Pricing__c> spcPriceMap = new Map<Decimal,SPC_Pricing__c>();
                spcPriceMap.put(spcP.Sales_Product_Component_ID__c,spcP);
				Map<string,Map<Decimal,SPC_Pricing__c>> termPricing = new Map<string,Map<Decimal,SPC_Pricing__c>>();
                
				termPricing.put(string.valueOf(spcP.term__c),spcPriceMap);
				
				spcPricingMap.put(spcP.Market__c, termPricing);
				
            }
        }
        
        System.debug(spcPricingMap);
         
        Map<OpportunityLocationConfiguration__c,List<OLI__c>> solInsertLineItems = new Map<OpportunityLocationConfiguration__c,List<OLI__c>>();
        //Loop through each solution cloning to
        for(String s : solutionsToCloneTo){
        //Loop through cloning from solution items
            List<OLI__c> insertLineItems = new List<OLI__c>();
            opportunityLocationConfiguration__c sol = cloneableSolutions.get(s);
            
            for(LineItem lineItem : clone.lineItems) {
				if(invalidProductIds.contains(lineItem.salesproductId)){
					allSolsWithFailedItems.add(sol.Name);
					List<lineItem> oLis = solNameToNotClonedLineItems.get(sol.Name);
					if(oLis == null) oLis = new List<lineItem>();
					oLis.add(lineItem);
					for(lineItem li : lineItem.childLineItems){
						oLis.add(li);
					}
					solNameToNotClonedLineItems.put(sol.Name, oLis);
				}
				else{
					if(spcPricingMap.containskey(sol.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c)){
						Map<string,Map<Decimal,SPC_Pricing__c>> spcPricingMarket = spcPricingMap.get(sol.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c);
						if(spcPricingMarket.containsKey(sol.Term__c) || spcPricingMarket.containsKey('0')){
							Map<Decimal,SPC_Pricing__c> termPricing = spcPricingMarket.get(sol.Term__c) == null ? new Map<Decimal,SPC_Pricing__c>() : spcPricingMarket.get(sol.Term__c);
							Map<Decimal,SPC_Pricing__c> zeroTermPricing = spcPricingMarket.get('0') == null ? new Map<Decimal,SPC_Pricing__c>() : spcPricingMarket.get('0');
							if((termPricing != null && termPricing.containsKey(lineItem.SalesProductComponentID)) || (zeroTermPricing != null && zeroTermPricing.containsKey(lineItem.SalesProductComponentID))){
								SPC_Pricing__c priceRow = termPricing.get(lineItem.SalesProductComponentID) == null ? zeroTermPricing.get(lineItem.SalesProductComponentID) : termPricing.get(lineItem.SalesProductComponentID);

								//Different market apply discount amt to this markets list
								Decimal lineItemList = lineItem.mrclist == null ? 0 : lineItem.mrclist;
								Decimal lineItemMRC = lineItem.mrc == null ? 0 : lineItem.mrc;
								decimal discountAmt = lineItemList - lineItemMRC;
							
								Decimal MRC = (lineItem.mrclist == null || lineItem.mrclist == 0) ? lineItem.MRR : (priceRow.MRR__c - lineItem.mrcdiscount);

								String approvalStatus = (priceRow.Is_Quote_Price__c || MRC < priceRow.MRR_Floor__c) ? 'Offer Management Approval Required' : lineItem.ApprovalStatus;
							
								insertLineItems.add(new OLI__c(
								Qty__c= lineItem.quantity,                  
								MRC__c= MRC, 
								MRC_Discount__c=lineItem.mrcDiscount,
								MRC_Floor__c=priceRow.MRR_Floor__c,
								NRC__c= priceRow.NRR__c,
								NRCList__c = priceRow.NRR__c,
								NRC_Discount__c=lineItem.nrcDiscount, 
								NRC_Floor__c=priceRow.NRR_Floor__c,
								Product_Family_Id__c=lineItem.productFamilyName,
								PP_Product_Family__c=lineItem.productFamilyName,
								Product_Family_Product__c=lineItem.productName,
								PP_Sales_Product__c=lineItem.productName,
                            // Added the following line to record the current lineItem's id, used to match parent and child relationship later
								myID__c=lineItem.id,
                                DQ__c=lineItem.itemName,
								PP_Product_Pricing_Name__c=lineItem.itemName,
								PP_Sales_Rate_Plan_Description__c=lineItem.itemName,
								PP_SalesProductExternalID__c=String.valueof(lineItem.salesproductId),
								SPC_Sales_Selection_Rule_Name__c=priceRow.Sales_Selection_Rule__c ,
								Price_Id__c=priceRow.Price_ID__c,
								AccessTechName__c=lineItem.AccessTechName,
								SPC_Feature_Group__c=lineItem.ComponentGroup,
								SPC_Component_Id__c=lineItem.ComponentID,
								SPC_Sales_Product_Component_Id__c=lineItem.SalesProductComponentID,
								SPC_MaxQty__c=lineItem.MaxQty ,
								SPC_MinQty__c=lineItem.MinQty ,
								Bandwidth__c=lineItem.Bandwidth,
								PP_Per_Account__c=lineItem.IsPerAccount ,
								SPC_MRC_OnNet__c=lineItem.IsOnnetPrice,
								SPC_NRC_Is_Quote__c=lineItem.IsQuotePrice ,
								SPC_MRC_Is_Quote__c = priceRow.Is_Quote_Price__c,
								PP_Voice_Line__c=lineItem.IsVoiceLine ,
								PP_Voice_Line_Option__c=lineItem.IsVoiceLineOption ,
								PP_Package__c=lineItem.isPackageIncluded ,
								PP_LD_Interstate__c=lineItem.IsLDInterstate ,                           
								PP_LD_Intrastate__c=lineItem.IsLDIntraState ,
								MRCList__c=priceRow.MRR__c,
								PP_Feature_Group__c=lineItem.featuregroup,
								SPC_Sales_Product__c=lineItem.saleProductSpcId,
								ParentName__c = lineItem.parentName,
								Approval_Status__c = ApprovalStatus,
								Config_Parent__c = lineItem.ConfigParent,
								Group_Name__c = lineItem.GroupName,
								Parent_Relationship__c = lineItem.ParentRelationship,
								SPC_Component__c = lineItem.SPCComponent,
								Approved__c = (approvalStatus.containsIgnoreCase('approval required') ? false : lineItem.Approved),
								Parent_Opportunity_Line_Item__c= lineItem.parentLineItem == null ? null : lineItem.parentLineItem.id,
								OpportunityLocationConfiguration__c= sol.id));  
                            }
							else{
								allSolsWithFailedItems.add(sol.Name);
								List<lineItem> oLis = solNameToNotClonedLineItems.get(sol.Name);
								if(oLis == null) oLis = new List<lineItem>();
								oLis.add(lineItem);
								for(lineItem li : lineItem.childLineItems){
									oLis.add(li);
								}
								solNameToNotClonedLineItems.put(sol.Name, oLis);
							}
						}
						else{
							allSolsWithFailedItems.add(sol.Name);
							List<lineItem> oLis = solNameToNotClonedLineItems.get(sol.Name);
							if(oLis == null) oLis = new List<lineItem>();
							oLis.add(lineItem);
							for(lineItem li : lineItem.childLineItems){
								oLis.add(li);
							}
							solNameToNotClonedLineItems.put(sol.Name, oLis);
						}
					}
					else{
						allSolsWithFailedItems.add(sol.Name);
						List<lineItem> oLis = solNameToNotClonedLineItems.get(sol.Name);
						if(oLis == null) oLis = new List<lineItem>();
						oLis.add(lineItem);
						for(lineItem li : lineItem.childLineItems){
							oLis.add(li);
						}
						solNameToNotClonedLineItems.put(sol.Name, oLis);
					}
				}
			}
            solInsertLineItems.put(sol,insertLineItems);
        }

		Map<Id,List<OLI__c>> parentLineItems = new Map<Id,List<OLI__c>>();
        Map<id,List<OLI__c>> childLineItems = new Map<Id,List<OLI__c>>();
        
        List<OLI__c> parentTochldlst = new List<OLI__c>();
        // persist changes
        
        // storing all the childrenItems in a list
        LIST<OLI__c> childrenItems = new LIST<OLI__c>();
       
        for(OpportunityLocationConfiguration__c sol : solInsertLineItems.keySet()){
            List<OLI__c> insertLineItems = solInsertLineItems.get(sol);
           /* if(!insertLineItems.isEmpty()) {
                insertLineItems = GlobalUtilities.updateOLIswithProductPricingInformation(insertLineItems,sol);
            }*/
            
            LIST<OLI__c> localParentRows = new List<OLI__c>();
            LIST<OLI__c> localChildRows = new List<OLI__c>(); 
            for(OLI__c oli : insertLineItems){
                // Replaced following code because ParentName is set to Null for every item
                /*if(oli.ParentName__c == null){
                    localParentRows.add(oli);
                }
                else{
                    localChildRows.add(oli);
                }*/ 
                // using Config_Parent__c to check whether it's a child item or not
                if(oli.Config_Parent__c == null){
                    localParentRows.add(oli);
                }
                else{
                    localChildRows.add(oli);
                    childrenItems.add(oli); // store each childlineItem into the childrenItems list
                } 
            }
            
            parentLineItems.put(sol.id,localParentRows);
            childLineItems.put(sol.id,localChildRows);
        }
        
        //Insert Parents
        
        List<OLI__c> inserts = new List<OLI__c>();
        for(List<OLI__c> oliParentsToInsert : parentLineItems.values()){
            inserts.addAll(oliParentsToInsert);
        }
        if(inserts.size() > 0) {
            insert inserts;
        }
        
        // created a list for middle level lineItems
        LIST<OLI__c> midLineItems = new LIST<OLI__c>();
        // finding the middle level component, which has both a parent and children
        for (OLI__c oliMid :childrenItems){
                for (OLI__c oliCheck :childrenItems){
                    if (oliMid.myID__c == oliCheck.Config_Parent__c) {
                        midLineItems.add(oliMid);
                    }
            	}
            }
            
        //need to query back Top parents and store the result in parents list
        LIST<OLI__c> parents = new LIST<OLI__c>();
        // added search field myID__c
        for(OLI__c oli: [Select Id, myID__c, SPC_Sales_Product__c, PP_Product_Pricing_Name__c,OpportunityLocationConfiguration__c From OLI__c Where OpportunityLocationConfiguration__c in :parentLineItems.keyset()]){
                parents.add(oli);
        }
        
         // Changed the list that the forloop loops through, since parents are saved as list so that it can be used later as well
         /*for(OLI__c op: [Select Id, myID__c, SPC_Sales_Product__c, PP_Product_Pricing_Name__c,OpportunityLocationConfiguration__c From OLI__c Where OpportunityLocationConfiguration__c in :parentLineItems.keyset()]){ */

        
         //need to match the Top Parents with the top level children to update 
        for(OLI__c op: parents) {
            for(OLI__c co: childLineItems.get(op.OpportunityLocationConfiguration__c)){
                    // Replaced the followingline because ParentName__c is not set properly, myID__c was set to match the Config_Parent__C of each childlineitem
                    //if(co.ParentName__c==op.PP_Product_Pricing_Name__c && co.SPC_Sales_Product__c == op.SPC_Sales_Product__c) {
                    if (co.Config_Parent__c == op.myID__c && co.SPC_Sales_Product__c == op.SPC_Sales_Product__c) {
                        co.ParentName__c=op.PP_Product_Pricing_Name__c;  // set proper ParentName__C for each child
                        co.Parent_Opportunity_Line_Item__c = op.Id;
                        parentTochldlst.add(co);
                        co.Config_Parent__c = op.Id; // adjusting the Config_Parent__c to the new Id of op
                    }
            }
        }
        
        //need to match mid level lineItems with their child
        for(OLI__c op: midLineItems) {
            for(OLI__c co:childrenItems){
                    // Replaced the followingline because ParentName__c is not set properly, myID__c was set to match the Config_Parent__C of each childlineitem
                    //if(co.ParentName__c==op.PP_Product_Pricing_Name__c && co.SPC_Sales_Product__c == op.SPC_Sales_Product__c) {
                    if (co.Config_Parent__c == op.myID__c && co.SPC_Sales_Product__c == op.SPC_Sales_Product__c) {
                        co.ParentName__c=op.PP_Product_Pricing_Name__c;  // set mid lineItem's child's parent to the top parent of the line, since we only deal with one level parent-child relationship
                        co.Parent_Opportunity_Line_Item__c = op.Config_Parent__c;
                        parentTochldlst.add(co);
                        co.Config_Parent__c = op.Config_Parent__c; // set mid lineItem's child's parent to the top parent of the line, since we only deal with one level parent-child relationship
                    }
                }
            }
        
        //Insert Children
        if(parentTochldlst.size() > 0)
            insert parentTochldlst;
        
        // goto wizard
		if(allSolsWithFailedItems.isEmpty()){
	
   	        return gotoManageLocationProducts();
		}
		else
			return null;
    }
	public PageReference dismissDialogAndContinue(){
		return gotoManageLocationProducts();
    }
    

    /**
    * Initializes the controller using the passed in configuration ID.  
    */
    private void init() {
        
        // get/validate the configuration from parameter
        //String opportunityLocationConfigurationId = Apexpages.currentPage().getParameters().get('opportunityLocationConfigurationId');
        opportunityID = Apexpages.currentPage().getParameters().get('opportunityID');
        cloneFromSolutionID = Apexpages.currentPage().getParameters().get('opportunityLocationConfigurationId');
        
        //Mholcombe - Change to take opportunity id and show missing Opportunity id error
       // if(opportunityLocationConfigurationId == null || opportunityLocationConfigurationId == '') {
        //    throw new CloneSolutionControllerException('Missing or invalid opportunityLocationConfigurationId parameter.');
       // }
        
        //Mholcombe get the configs for the opportunity passed in
        cloneableSolutions = new Map<String,OpportunityLocationConfiguration__c>();
        for(OpportunityLocationConfiguration__c sol : [
                Select Id, Name, Term__c, Opportunity_Location__r.Id, Opportunity_Location__r.Opportunity__r.AccountId, Opportunity_Location__r.Service_Location__r.Account__r.Name, Opportunity_Location__r.Name, 
                Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_ID__c, Opportunity_Location__r.Service_Location__r.Location__r.Building__r.LSO_CLLI__c, 
                Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Street__c, Opportunity_Location__r.Order__r.Opportunity__r.Id, 
                Opportunity_Location__r.Order__r.Opportunity__r.Name,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_Hash__c,
                Bandwidth__c,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Serving_LSO__r.LSO_CLLI__c,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c,
                Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Name,CreatedDate, Opportunity_Location__r.Service_Location__r.ICC_Subscriber_ID__c
                From OpportunityLocationConfiguration__c 
                Where Opportunity_Location__r.Order__r.Opportunity__r.Id = :opportunityID
                and LineItemCount__c = 0
        ]){
            cloneableSolutions.put(sol.id,sol);
        }
        
        availableSolutions = getAvailableSolutions(cloneableSolutions.values());
        //this.opportunityLocationConfiguration = cloneableSolutions.values().get(0);   
        
        //get the config
       /* List<OpportunityLocationConfiguration__c> opportunityLocationConfigurations = [
                Select Id, Name, Term__c, Opportunity_Location__r.Id, Opportunity_Location__r.Opportunity__r.AccountId, Opportunity_Location__r.Service_Location__r.Account__r.Name, Opportunity_Location__r.Name, 
                Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_ID__c, Opportunity_Location__r.Service_Location__r.Location__r.Building__r.LSO_CLLI__c, 
                Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Street__c, Opportunity_Location__r.Order__r.Opportunity__r.Id, 
                Opportunity_Location__r.Order__r.Opportunity__r.Name,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_Hash__c,
                Bandwidth__c,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Serving_LSO__r.LSO_CLLI__c,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c
                From OpportunityLocationConfiguration__c 
                Where Id = :opportunityLocationConfigurationId
        ];
        if(opportunityLocationConfigurations.size() != 1) {
            throw new CloneSolutionControllerException('Invalid opportunityLocationConfigurationId ID.');
        } 
        else {
            this.opportunityLocationConfiguration = opportunityLocationConfigurations.get(0);   
        }
        */
        
        // init search parameters
        searchMySolutionsOnly = DEFAULT_SEARCH_INCLUDE_ONLY_MY_OPPORTUNITIES;
        searchExcludeEmptySolutions = DEFAULT_SEARCH_EXCLUDE_EMPTY_SOLUTIONS;
        searchSolutionName = DEFAULT_SEARCH_SOLUTION_NAME;
        searchOpportunityName = DEFAULT_SEARCH_OPPORTUNITY_NAME;
        searchAccountName = DEFAULT_SEARCH_ACCOUNT_NAME;
        searchMaxResults = DEFAULT_SEARCH_MAX_RESULTS;
        
        if(cloneFromSolutionID != null){
            searchOpportunityName = '';
			searchSolutions();
        }
        
        // perform initial search
        
		
    }
    
    private List<SelectOption> getAvailableSolutions(List<OpportunityLocationConfiguration__c> sols){
        List<SelectOption> sos = new List<SelectOption>();
        
        for(OpportunityLocationConfiguration__c sol : sols){
            sos.add(new SelectOption(sol.Id,sol.Name + ' - ' + sol.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Name));
        }
        
        return sos;
    }
    
    
    /**
    * View object for the line item
    */
    public class OpportunityLocationConfiguration {
        
        public Id id {get; set;}
        public String name {get; set;}
        public String opportunityName {get; set;}
		public String serviceLocationName {get;Set;}
        public String accountName {get; set;}
        public String term {get; set;}
        public List<LineItem> lineItems  {get; private set;}
        public Boolean hasExpiredLines {get; set;}
        public Boolean hasOutOfAreaLines {get; set;}
        public Boolean hasNoTermLines {get; set;}
		public Boolean canCloneToNewSolutions {get;set;}
        
        public OpportunityLocationConfiguration(Id id, String name, String opportunityName, String accountName, String servicelocationName, String term, string iccSubID, datetime createdDate) {
            this.id = id;
            this.name = name;
            this.opportunityName = opportunityName;
			this.serviceLocationName = servicelocationName;
            this.accountName = accountName;
            this.term = term;
            this.lineItems = new List<LineItem>();
            this.hasExpiredLines = false;
            this.hasOutOfAreaLines = false;
            this.hasNoTermLines = false;
			Date newUIDate = date.newinstance(2016, 10, 08);
			Date solDate = date.newinstance(createdDate.year(), createdDate.month(), createdDate.day());
			this.canCloneToNewSolutions = (iccSubID == null &&  solDate> newUIDate);
        }
    }
    
    /**
    * View object for the line item
    */
    public class LineItem {
        
        public Id id {get; set;}
        public Id salesProductRatePlanId {get; set;}
        public Id productPricingId {get; set;}
        public Id marketAreaId {get; set;}
        public String productFamilyName {get; set;}
        public String productName {get; set;}
        public String itemName {get; set;}
        public Decimal quantity {get; set;}
        public Double mrc {get; set;}
        public Double mrcDiscount {get; set;}
        public Double mrcTotal {get; set;}
        public Double MRRFloor{get;set;}
        public Double nrc {get; set;}
        public Double nrcDiscount {get; set;}
        public Double nrcTotal {get; set;}
        public Double NRRFloor{get;set;}
        public Boolean expired {get; set;}
        public Boolean outsideMarketArea {get; set;}
        public Boolean noTerm {get; set;}
        public Decimal salesproductId{get;set;}
        
        public OpportunityLocationConfiguration opportunityLocationConfiguration {get; set;}
        public LineItem parentLineItem  {get; set;}
        public List<LineItem> childLineItems  {get; private set;}
        
        public Decimal mrclist{get;set;}
        public String featuregroup{get;set;}
        public  String SalesSelectionRuleValue{get;set;}
        public  String  PriceId{get;set;}
        public  String AccessTechName{get;set;}
        public  String  ComponentGroup{get;set;}
        public  Decimal ComponentID{get;set;}
        public  Decimal SalesProductComponentID{get;set;}
        public  Decimal MaxQty{get;set;}
        public  Decimal MinQty{get;set;}
        public  Decimal MRR{get;set;}
        public  Decimal NRR{get;set;}
        public  Decimal Bandwidth{get;set;}
        public  boolean IsPerAccount{get;set;}
        public  boolean IsOnnetPrice{get;set;}
        public  boolean IsQuotePrice{get;set;}
		public Boolean IsMRCQuotePrice {get;Set;}
        public  boolean IsVoiceLine       {get;set;} 
        public  boolean  IsVoiceLineOption   {get;set;}
        public  boolean  isPackageIncluded{get;set;}
        public boolean IsLDInterstate{get;set;}                                                        
        public boolean IsLDIntraState {get;set;}
        public String saleProductSpcId{get;set;}
        public String parentName {get;Set;}
        public String ApprovalStatus {get;Set;}
        public Boolean Approved {get;Set;}
		public string ConfigParent {get;set;}
		public string GroupName {get;set;}
		public string ParentRelationship {get;set;}
		public string SPCComponent {get;set;}


        /**
        * Default ctor
        */
        public LineItem() {
            outsideMarketArea = false;
            noTerm = false;
            childLineItems = new List<LineItem>();
        }
    }
     
    /**
    * Assembler for OpportunityLocationConfiguration objects
    */
    public class OpportunityLocationConfigurationAssembler {
        
        /**
        * Assembles a LineItem from an OLI__c
        *
        * @param nativeConfig
        *       the native config to create a OpportunityLocationConfiguration from
        * @returns
        *       a mapped OpportunityLocationConfiguration from the given native config instance
        */
        public OpportunityLocationConfiguration fromNativeOpportunityLocationConfiguration(OpportunityLocationConfiguration__c nativeConfig,Map<String,Boolean> componentNameToExpireBoolean) {
        
            // map config
            OpportunityLocationConfiguration opportunityLocationConfiguration = 
                new OpportunityLocationConfiguration(nativeConfig.Id, nativeConfig.Name, 
                        nativeConfig.Opportunity_Location__r.Order__r.Opportunity__r.Name, 
                        nativeConfig.Opportunity_Location__r.Service_Location__r.Account__r.Name,
						nativeConfig.Opportunity_Location__r.Service_Location__r.Name,
                        nativeConfig.Term__c,
						nativeConfig.Opportunity_Location__r.Service_Location__r.ICC_Subscriber_ID__c,
						nativeConfig.CreatedDate);
                        
            // map config line items
            opportunityLocationConfiguration.lineItems.addAll(new LineItemAssembler(opportunityLocationConfiguration).fromOLIs(nativeConfig.Opportunity_Line_Items__r,componentNameToExpireBoolean));
            
            // return mapped config
            return opportunityLocationConfiguration;
        }
        
        /**
        * Assembles a list of OpportunityLocationConfiguration objects from a 
        * native list of OpportunityLocationConfiguration__c objects
        *
        * @param nativeConfigs
        *       the list of native opportunity location configs to create
        *       OpportunityLocationConfiguration objects from
        * @returns
        *       a list of mapped OpportunityLocationConfiguration objects from the given 
        *       OpportunityLocationConfiguration__c list
        */
        public List<OpportunityLocationConfiguration> fromNativeOpportunityLocationConfigurations(List<OpportunityLocationConfiguration__c> nativeConfigs,Map<String,Boolean> componentNameToExpireBoolean) {

            List<OpportunityLocationConfiguration> opportunityLocationConfigurations = new List<OpportunityLocationConfiguration>();
            
            for(OpportunityLocationConfiguration__c nativeConfig : nativeConfigs) {
                opportunityLocationConfigurations.add(fromNativeOpportunityLocationConfiguration(nativeConfig,componentNameToExpireBoolean));
            }
            
            return opportunityLocationConfigurations;
        }
    }
    
    /**
    * Assembler for LineItem objects
    */
    public class LineItemAssembler {
        
        private OpportunityLocationConfiguration opportunityLocationConfiguration;
        
        /**
        * Overload ctor
        */
        public LineItemAssembler() {    
        }
        
        /**
        * Overload ctor
        *
        * @param opportunityLocationConfiguration the parent config for the mapped line item (can be null)
        */
        public LineItemAssembler(OpportunityLocationConfiguration opportunityLocationConfiguration) {
            this.opportunityLocationConfiguration = opportunityLocationConfiguration;
        }
        
        /**
        * Assembles a LineItem from an OLI__c
        *
        * @param oli
        *       the opportunity line item to create a LineItem from
        * @returns
        *       a mapped LineItem from the given OLI__c instance
        */
        public LineItem fromOLI(OLI__c oli,String Marketarea) {
            
            LineItem lineItem = new LineItem();
            lineItem.opportunityLocationConfiguration = opportunityLocationConfiguration;
            lineItem.id = oli.Id;
            lineItem.productFamilyName = oli.Product_Family_Id__c;
            lineItem.productName = oli.Product_Family_Product__c;
            lineItem.itemName = oli.DQ__c; 
            lineItem.quantity = oli.Qty__c;
            lineItem.mrc = oli.MRC__c;
            lineItem.mrcDiscount = oli.MRC_Discount__c;
            lineItem.mrcTotal = oli.MRC_Total__c;
            lineItem.nrc = oli.NRC__c;
            lineItem.nrcDiscount = oli.NRC_Discount__c;
            lineItem.nrcTotal = oli.NRC_Total__c;
            lineItem.MRRFloor=oli.MRC_Floor__c;
            lineItem.NRRFloor=oli.NRC_Floor__c;
            lineItem.salesproductId=oli.PP_SalesProductExternalID__c == null ? 0 : Decimal.valueof(oli.PP_SalesProductExternalID__c);
            lineItem.expired=false;
            lineItem.marketAreaId=Marketarea;
            
            lineItem.featuregroup=oli.PP_Feature_Group__c;
            lineItem.mrclist=oli.MRCList__c == null ? 0 : oli.MRCList__c;
            lineItem.SalesSelectionRuleValue=oli.SPC_Sales_Selection_Rule_Name__c;
            lineItem.PriceId=oli.Price_Id__c;
            lineItem.AccessTechName=oli.AccessTechName__c;
            lineItem.ComponentGroup=oli.SPC_Feature_Group__c;
            lineItem.ComponentID=oli.SPC_Component_Id__c;
            lineItem.SalesProductComponentID=oli.SPC_Sales_Product_Component_Id__c;
            lineItem.MaxQty=oli.SPC_MaxQty__c;
            lineItem.MinQty=oli.SPC_MinQty__c;
            lineItem.Bandwidth=oli.Bandwidth__c;
            lineItem.IsPerAccount=oli.PP_Per_Account__c;
            lineItem.IsOnnetPrice=oli.SPC_MRC_OnNet__c;
			lineItem.IsMRCQuotePrice = oli.SPC_MRC_Is_Quote__c;
            lineItem.IsQuotePrice=oli.SPC_NRC_Is_Quote__c;
            lineItem.IsVoiceLine=oli.PP_Voice_Line__c;
            lineItem.IsVoiceLineOption=oli.PP_Voice_Line_Option__c;
            lineItem.isPackageIncluded=oli.PP_Package__c;
            lineItem.IsLDInterstate=oli.PP_LD_Interstate__c;                                                        
            lineItem.IsLDIntraState =oli.PP_LD_Intrastate__c;
            lineItem.saleProductSpcId=oli.SPC_Sales_Product__c;
            LineItem.parentName = oli.ParentName__c;
            LineItem.Approved = oli.Approved__c;
            LineItem.ApprovalStatus = oli.Approval_Status__c;
			lineItem.ConfigParent = oli.Config_Parent__c;
			lineItem.GroupName = oli.Group_Name__c;
			lineItem.ParentRelationship	= oli.Parent_Relationship__c;
			lineItem.SPCComponent = oli.SPC_Component__c;
            return lineItem;
        }
        
        /**
        * Assembles a list of LineItem objects from a list of OLI__c objects
        *
        * @param olis
        *       the list of opportunity line items to create a LineItem list from
        * @returns
        *       a list of mapped LineItem objects from the given OLI__c list
        */
        public List<LineItem> fromOLIs(List<OLI__c> olis,Map<String,Boolean> componentNameToExpireBoolean) {
        
            // list for return
            List<LineItem> lineItems = new List<LineItem>();
            Map<String,String> oliToMarketId=new Map<String,String>();
            Set<String> oliIDSet=new Set<String>();
            for(OLI__c oli:olis )
            {
                oliIDSet.add(oli.id);
            }
            for(OLI__c op:[SELECT id,
                            opportunityLocationConfiguration__r.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_ID__c 
                          FROM OLI__c Where ID IN:oliIDSet])
            {
                oliToMarketId.put(op.id,op.opportunityLocationConfiguration__r.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_ID__c );
            }

            // reference maps
            Map<Id, LineItem> itemMap = new Map<Id, LineItem>();
            Map<Id, Id> parentReferenceMap = new Map<Id, Id>();
            Map<Id, List<LineItem>> childMap = new Map<Id, List<LineItem>>();
            
            // iterate and map accordingly
            for(OLI__c oli : olis) {
                
                // assemble line item
                LineItem lineItem = fromOLI(oli,oliToMarketId.get(oli.id));
                
                // map references
                itemMap.put(oli.Id, lineItem);
                if(oli.Parent_Opportunity_Line_Item__c != null) {
                    parentReferenceMap.put(oli.Id, oli.Parent_Opportunity_Line_Item__c);
                    List<LineItem> children = childMap.get(oli.Parent_Opportunity_Line_Item__c);
                    if(children == null) {
                        children = new List<LineItem>();
                        childMap.put(oli.Parent_Opportunity_Line_Item__c, children);
                    }
                    children.add(lineItem);
                }
                
                // add item to list
                lineItems.add(lineItem);
            }
            
            // wire up list references
            for(LineItem lineItem : lineItems) {
                List<LineItem> children = childMap.get(lineItem.Id);
                if(children != null) {
                    lineItem.childLineItems.addAll(children);
                }
                if(parentReferenceMap.containsKey(lineItem.Id)) {
                    lineItem.parentLineItem = itemMap.get(parentReferenceMap.get(lineItem.Id));
                }
            }
            
            // return map to caller
            return lineItems;
        }
    }
    
    /**
    * Custom wrapper exception used by controller
    */
    public class CloneSolutionControllerException extends Exception {
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_CloneSolution(); }
}