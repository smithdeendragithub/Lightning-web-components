public without sharing class CatalogUtils{
	
	public class SPCPricingView{
		public SPC_Pricing__c pricing { get; set; }
		public List<SPCPricingView> children { get; set; }
		
		public SPCPricingView(SPC_Pricing__c pricing){
			this.pricing = pricing;
			children = new List<SPCPricingView>();
		}
	}
	
	public class DiscountAuthorityView{
		public Decimal DiscountAmountRemaining {get;Set;}
		public Boolean DealApproved {get;Set;}
		public String DealStatus {get;Set;}
		
		public DiscountAuthorityView(Decimal amt,Boolean approved,String status){
			DiscountAmountRemaining = amt;
			DealApproved = approved;
			DealStatus = status;
		}
	}
	
	private static String allPricingFields{ get{ return string.join(new List<String>(SchemaUtils.RetrieveFullObjectFieldSet(SPC_Pricing__c.getsObjectType())), ', '); } }
	
	public static List<SPC_Pricing__c> GetPricingByPricingID(List<string> priceIds){
        return Database.query('select ' + string.join(new List<String>(SchemaUtils.RetrieveFullObjectFieldSet(SPC_Pricing__c.getsObjectType())), ', ') + ' ,SPC_Component__r.Display_Name__c from SPC_Pricing__c where Price_ID__c in :priceIds');
    }

	public static List<PricingView> GetExpiredPricing(List<string> PriceIds){
        List<PricingView> pricing = new List<PricingView>();
        
		string mainquery = 'Select Available_In_Wizard__c, Bandwidth__c,Is_Expired__c, Is_OnNet_Price__c, Is_Quote_Price__c, MRR__c, '
							+ 'MRR_Floor__c, Market__c, NRR__c, NRR_Floor__c, Price_ID__c, Pricing_Name__c, Sales_Product_Component_ID__c, '
							+ 'Term__c, SPC_Component__c, Is_Non_Discountable__c, Z_Location_Required__c,'
							+ 'SPC_Component__r.Access_Technology_Name__c, SPC_Component__r.Component_Group__c, SPC_Component__r.Component_ID__c, '
							+ 'SPC_Component__r.Component_Name__c, SPC_Component__r.Feature_Schedule_Prompt__c, SPC_Component__r.Is_DID_Virtual_TN__c, SPC_Component__r.Is_LD_Interstate__c, '
							+ 'SPC_Component__r.Is_LD_Intrastate__c, SPC_Component__r.Is_Toll_Free__c, SPC_Component__r.Is_Voice_Line__c, SPC_Component__r.Is_Voice_Line_Option__c, '
							+ 'SPC_Component__r.Is_Per_Account__c,SPC_Component__r.Max_Qty__c, SPC_Component__r.Min_Qty__c, '
							+ 'SPC_Component__r.Sales_Product_Component_ID__c,SPC_Component__r.Sales_Product__r.Sales_Product_Group__c, SPC_Component__r.Sales_Product__r.SalesProductExternalID__c, '
							+ 'SPC_Component__r.Sales_Product__r.Name, SPC_Component__r.Sales_Product__c, SPC_Component__r.Display_Name__c '
							+ 'From SPC_Pricing__c s Where Is_Expired__c = true and Price_Id__c in :PriceIds';
        
        List<SPC_Pricing__c> priceRecords = database.query(mainquery);
        if(priceRecords != null){
			for(SPC_Pricing__c p : priceRecords){
				pricing.add(new PricingView(p));
			}
		}
		return pricing;
	}
	
	public static List<SPC_Pricing__c> GetProductFeaturePricing(List<Integer> accessTechIds, Decimal bandwidth, String wireCenterCLLI, String buildingHash, List<Integer> salesProductIDs, List<Integer> terms){
        
		Boolean isOnNet = false;
        string marketName = '';
        for(Building__c b : [select Id, Market_Area_Name__c, Net_Classification__c from Building__c where building_hash__c = :buildingHash]){
            marketName = b.Market_Area_Name__c;
			isOnNet = b.Net_Classification__c == 'On-net';
        }
		
		List<SPC_Pricing__c> pricing = getCoreProductFeaturePricing(accessTechIds, bandwidth, isOnNet, marketName, salesProductIDs, terms);
        pricing.addall(getDependentPricing(pricing, marketName));
		
		if(filterNetClass(salesProductIDs))
        	filterPricingByNetClass(pricing, isOnNet);
		
        return pricing;
    }
	
	public static List<SPCPricingView> GetProductFeaturePricingViews(List<Integer> accessTechIds, Decimal bandwidth, String buildingHash, List<Integer> salesProductIDs, List<Integer> terms){
		
		List<SPCPricingView> retval = new List<SPCPricingView>();
		
		Boolean isOnNet = false;
        string marketName = '';
		Boolean competitiveBuilding = false;
        for(Building__c b : [select Id, Market_Area_Name__c, Net_Classification__c, EoF_Competitive_Building__c from Building__c where building_hash__c = :buildingHash]){
            marketName = b.Market_Area_Name__c;
			isOnNet = b.Net_Classification__c == 'On-net';
			competitiveBuilding = b.EoF_Competitive_Building__c;
        }
		
		List<SPC_Pricing__c> pricing = getCoreProductFeaturePricing(accessTechIds, bandwidth, isOnNet, marketName, salesProductIDs, terms);
		List<SPC_Pricing__c> depPricing = getDependentPricing(pricing, marketName);
		
		//Remove top level that should not display in wizard
		for(Integer i=pricing.size()-1; i>=0; i--){
			if(pricing[i].Available_In_Wizard__c == false || (pricing[i].Pricing_Name__c != null && pricing[i].Pricing_Name__c.contains('Competitive Building') && !competitiveBuilding))
				pricing.remove(i);
		}
		
		if(filterNetClass(salesProductIDs)){
        	filterPricingByNetClass(pricing, isOnNet);
        	filterPricingByNetClass(depPricing, isOnNet);
		}
		
		Map<Decimal, List<SPC_Pricing__c>> componentPricingMap = new Map<Decimal, List<SPC_Pricing__c>>();
		for(SPC_Pricing__c dp : depPricing){
			Decimal cID = dp.Sales_Product_Component_ID__c;
			List<SPC_Pricing__c> l = componentPricingMap.get(cID) != null ? componentPricingMap.get(cID) : new List<SPC_Pricing__c>();
			l.add(dp);
			componentPricingMap.put(cID, l);
		}
		
		for(SPC_Pricing__c p : pricing){
			SPCPricingView v = new SPCPricingView(p);
			
			for(Decimal dpID : getDependentPricingIDs(p)){
				for(SPC_Pricing__c dp : componentPricingMap.get(dpID) != null ? componentPricingMap.get(dpID) : new List<SPC_Pricing__c>()){
					if(dp.Term__c == v.pricing.Term__c || dp.Term__c == 0){
						v.children.add(new SPCPricingView(dp));
					}
				}
			}
			
			retval.add(v);
		}
		
		return retval;
	}
	
	private static Boolean filterNetClass(List<Integer> salesProductIDs){
		return new Set<Integer>(salesProductIDs).contains(178);
	}
	
	private static List<SPC_Pricing__c> getCoreProductFeaturePricing(List<Integer> accessTechIds, Decimal bandwidth, Boolean isOnNet, String marketName, List<Integer> salesProductIDs, List<Integer> terms){
        
        List<SPC_Pricing__c> pricing = new List<SPC_Pricing__c>();
        
        //Get AccessTech descriptions based on ids
        List<string> accessTechStrings = new List<string>();
        for(Access_Technology__c atech : [Select Id, Name From Access_Technology__c Where Access_Technology_ID__c in :accessTechIds])
            accesstechStrings.add(atech.Name);
        
        string mainquery = 'select ' + allPricingFields + ' from SPC_Pricing__c s where Is_Expired__c = false and Sales_Product_ID__c in :salesProductIds';
        
		if(terms.size() > 0){
			terms.add(0);
			mainquery += ' and Term__c in: terms';
		}
		
		if(bandwidth != 0)
            mainquery += ' and (Bandwidth__c = :bandwidth or Bandwidth__c = null)';
		
        if(marketName != '')
            mainquery += ' and Market__c =: marketName';
		
 		if(accessTechStrings.size() > 0)
        	mainquery += ' and (Access_Technology_Name__c in :accesstechStrings or Access_Technology_Name__c = null)';
		
        List<SPC_Pricing__c> priceRecords = database.query(mainquery);
        if(priceRecords != null)
            pricing.addall(priceRecords);
		
		return pricing;
	}
	
	private static List<SPC_Pricing__c> getDependentPricing(List<SPC_Pricing__c> pricing, String marketName){
		List<SPC_Pricing__c> depPricing = new List<SPC_Pricing__c>();
		
		Set<Decimal> dependentPricingIds = new Set<Decimal>();
        for(SPC_Pricing__c p : pricing)
			dependentPricingIds.addAll(getDependentPricingIDs(p));
		
		if(dependentPricingIds.size() > 0)
        	depPricing.addall((List<SPC_Pricing__c>)Database.query('select ' + allPricingFields + ' from SPC_Pricing__c where Sales_Product_Component_ID__c in: dependentPricingIds and Market__c =: marketName and Is_Expired__c = false'));
        
		return depPricing;
	}
	
	private static Set<Decimal> getDependentPricingIDs(SPC_Pricing__c p){
		Set<Decimal> dependentPricingIds = new Set<decimal>();
		
        if(p.Dependent_Sales_Product_Components__c != null){
            List<String> parts = p.Dependent_Sales_Product_Components__c.split(',');
            for(String part : parts)
                dependentPricingIds.add(Decimal.valueof(part));
        }
		
		return dependentPricingIds;
	}
	
	private static void filterPricingByNetClass(List<SPC_Pricing__c> pricing, Boolean isOnNet){
		
		//If a mix of Near-Net and On-Net is found for certain products, return only the ones that match the building net class otherwise bring back both types of pricing
		Set<decimal> onNetPricingSPCIds = new Set<decimal>();
		for(Integer i=0; i<pricing.size(); i++){
			if(pricing[i].Sales_Product_ID__c == 178 && pricing[i].Is_OnNet_Price__c == isOnNet)
				onNetPricingSPCIds.add(pricing[i].Sales_Product_Component_ID__c);
		}
		
		for(Integer i=pricing.size()-1; i>=0; i--){
			if(pricing[i].Sales_Product_ID__c == 178 && pricing[i].Is_OnNet_Price__c != isOnNet && onNetPricingSPCIds.contains(pricing[i].Sales_Product_Component_ID__c))
				pricing.remove(i);
		}
	}
	
	// new methods for cpq 2015
	
	public static Map<decimal, LIst<SPC_Component_Relation__c>> relationsByComp2CompId = null;
	public static Map<String, List<SPC_Component_Relation__c>> GetRelations(List<OLI__c> olis){
		Set<Decimal> ComponentIds = new Set<Decimal>();
		Set<Decimal> salesProductIDs = new Set<Decimal>();
		for(OLI__c oli : OLIs){
			ComponentIds.add(oli.SPC_Component_Id__c);
			salesProductIDs.add(Decimal.valueOf(oli.PP_SalesProductExternalID__c));
		}
		
		return GetRelations(ComponentIds, salesProductIDs);
	}
	
	public static Map<String, List<SPC_Component_Relation__c>> GetRelations(Set<Decimal> ComponentIds, Set<Decimal> spIds){
				
		if(relationsByComp2CompId == null) relationsByComp2CompId = new Map<Decimal, List<SPC_Component_Relation__c>>();
		
		Map<Id, SPC_Component__c> CompIds = new Map<Id, SPC_Component__c>([select Id from SPC_Component__c where Sales_Product_Component_Id__c in : componentIds and Sales_Product_ID__c in : spIds]);
		Map<String, List<SPC_Component_Relation__c>> allComponentRelations = new Map<String, List<SPC_Component_Relation__c>>();
		List<SPC_Component_Relation__c> ComponentRelations = [select SPC_Component_1__c, SPC_Component_1__r.Component_ID__c, SPC_Component_1__r.Sales_Product_Component_ID__c, SPC_Component_2__c, SPC_Component_2__r.Component_ID__c, SPC_Component_2__r.Sales_Product_Component_ID__c, SPC_Component_2__r.Component_Group__c, Name, Relation_Type__c, Is_Multi_Select__c, Is_Pick_One__c, Is_Required__c, Default_Quantity__c from SPC_Component_Relation__c where SPC_Component_1__c in : compIds.keyset() or SPC_Component_2__c in :compIds.keyset()];
		for(SPC_Component_Relation__c rel : ComponentRelations){
			String prodId = rel.SPC_Component_1__r == null ? string.valueOf(rel.SPC_Component_2__r.Sales_Product_Component_ID__c) : string.valueOf(rel.SPC_Component_1__r.Sales_Product_Component_ID__c);
			List<SPC_Component_Relation__c> relList = allComponentRelations.containsKey(prodId)? allComponentRelations.get(prodId) : new List<SPC_Component_Relation__c>();
			relList.add(rel);
			allComponentRelations.put(prodId, relList);
			
			List<SPC_Component_Relation__c> compRelList = relationsByComp2CompId.get(rel.SPC_Component_2__r.Sales_Product_Component_Id__c);
			if(compRelList == null) compRelList = new List<SPC_Component_Relation__c>();
			compRelList.add(rel);
			relationsByComp2CompId.put(rel.SPC_Component_2__r.Sales_Product_Component_Id__c, compRElList);
		}
		
		return allComponentRelations;
	}
	
	private static List<SPC_Component_Relation__c> pAllValidations = null;
	public static List<SPC_Component_Relation__c> allValidations{
		get{
			if(pAllValidations == null){
				pAllValidations = Database.query('select ' + string.join(new List<String>(SchemaUtils.RetrieveFullObjectFieldSet(SPC_Component_Relation__c.getsObjectType())), ', ') 
														+ ', SPC_Component_1__r.' + String.join(new List<String>(SchemaUtils.RetrieveFullObjectFieldSet(SPC_Component__c.getsObjectType())), ', SPC_Component_1__r.')
														+ ', SPC_Component_2__r.' + String.join(new List<String>(SchemaUtils.RetrieveFullObjectFieldSet(SPC_Component__c.getsObjectType())), ', SPC_Component_2__r.')
														+ ' from SPC_Component_Relation__c');
			}
			return pAllValidations;
		}
	}
	
	public static Map<Decimal, Map<String, Set<Decimal>>> getRelationsByGroupByProductId(Set<Decimal> spcProdIds){
		Map<Decimal, Map<String, Set<Decimal>>> retval = new Map<Decimal, Map<String, Set<Decimal>>>();
		
		for(SPC_Component_Relation__c rel : allValidations){
			if(rel.SPC_Component_1__c == null && rel.is_Required__c && rel.SPC_Component_2__c != null && spcProdIds.contains(rel.SPC_Component_2__r.sales_product_id__c)){
				Map<String, Set<Decimal>> reqIdsByGroup = retval.get(rel.SPC_Component_2__r.sales_product_id__c);
				if(reqIdsByGroup == null) reqIdsByGroup = new Map<String, Set<Decimal>>();
				Set<Decimal> reqIds = reqIdsByGroup.get(rel.Name);
				if(reqIds == null) reqIds = new Set<Decimal>();
				reqIds.add(rel.SPC_Component_2__r.Sales_Product_Component_Id__c);
				reqIdsByGroup.put(rel.Name, reqIds);
				retval.put(rel.SPC_Component_2__r.sales_product_id__c, reqIdsByGroup);
			}
		}
		
		return retval;
	}
	
	public static Map<Decimal, Map<String, Set<Decimal>>> getRelationsByGroupByComponentId(Set<Decimal> CompIds){
		Map<Decimal, Map<String, Set<Decimal>>> retval = new Map<Decimal, Map<String, Set<Decimal>>>();
		
		for(SPC_Component_Relation__c rel : allValidations){
			if(rel.is_Required__c && rel.SPC_Component_1__c != null && rel.SPC_Component_2__c != null && CompIds.contains(rel.SPC_Component_1__r.Sales_Product_Component_Id__c)){
				Map<String, Set<Decimal>> reqIdsByGroup = retval.get(rel.SPC_Component_1__r.Sales_Product_Component_Id__c);
				if(reqIdsByGroup == null) reqIdsByGroup = new Map<String, Set<Decimal>>();
				Set<Decimal> reqIds = reqIdsByGroup.get(rel.Name);
				if(reqIds == null) reqIds = new Set<Decimal>();
				reqIds.add(rel.SPC_Component_2__r.Sales_Product_Component_Id__c);
				reqIdsByGroup.put(rel.Name, reqIds);
				retval.put(rel.SPC_Component_1__r.Sales_Product_Component_Id__c, reqIdsByGroup);
			}
		}
		
		return retval;
	}
	
	public static Map<decimal,List<SPCPricingView>> GetProductFeaturePricingWithFeatureRelationship(List<Integer> salesProductIDs, string market, set<decimal> parentSPCIds, boolean isOnNet){
		Map<decimal,List<SPCPricingView>> retval = new Map<decimal,List<SPCPricingView>>();
			
		Map<decimal,decimal> childFeatures = new Map<decimal,decimal>();
		for(SPC_Relationship__c r : [Select id,Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c,(Select Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c,Secondary_Sales_Product_Component__r.Sales_Product_Component_ID__c From SPC_Relationships__r) From SPC_Relationship__c Where Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c in :parentSPCIds and SPC_Relationship_Type__r.Feature_Package__c = true]){
			system.debug(r.SPC_Relationships__r);
			for(SPC_Relationship__c rc : r.SPC_Relationships__r)
				childFeatures.put(rc.Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c,r.Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c);
		}

		set<decimal> childFeaturesIds = childFeatures.keyset();
		List<SPC_Pricing__c> depPricing = new List<SPC_Pricing__c>();
		system.debug(childFeaturesIds);
		depPricing.addall((List<SPC_Pricing__c>)Database.query('select ' + allPricingFields + ' from SPC_Pricing__c where Sales_Product_Component_ID__c in: childFeaturesIds and Market__c =: market and Is_Expired__c = false'));

		if(filterNetClass(salesProductIDs)){
        	filterPricingByNetClass(depPricing, isOnNet);
		}
		

		for(SPC_Pricing__c dp : depPricing){
			if(childFeatures.containsKey(dp.Sales_Product_Component_ID__c)){
				List<SPCPricingView> l = retval.get(childFeatures.get(dp.Sales_Product_Component_ID__c)) != null ? retval.get(childFeatures.get(dp.Sales_Product_Component_ID__c)) : new List<SPCPricingView>();
				l.add(new SPCPricingView(dp));
				retval.put(childFeatures.get(dp.Sales_Product_Component_ID__c), l);
			}
		}
		
		return retval;
	}

	//New CPQ
	public class RelationshipView implements comparable{
		public string id {get;set;}
		public boolean autoInclude {get;Set;}
		public decimal defaultQuantity {get;Set;}
		public string primarySalesProductID {get;Set;}
		public decimal primarySalesProductExternalID {get;Set;}
		public string primarySalesProductName {get;Set;}
		public string primarySalesProductComponentID {get;Set;}
		public decimal primarySalesProductComponentExternalID {get;Set;}
		public decimal primarySalesProductComponentSalesProductExternalID {get;set;}
		public string displayName{get;Set;}
		public string relationshipExternalID {get;Set;}
		public string secondarySalesProductID {get;Set;}
		public decimal secondarySalesProductExternalID {get;Set;}
		public string secondarySalesProductName {get;Set;}
		public string secondarySalesProductComponentID {get;Set;}
		public decimal secondarySalesProductComponentExternalID {get;Set;}
		public decimal secondarySalesProductComponentSalesProductExternalID {get;set;}
		public string secondaryPriceID {get;set;}
		public string secondaryPriceExternalID {get;set;}
		public string relationshipTypeID {get;Set;}
		public boolean criteriaRequired {get;Set;}
		public boolean negativeRelationship {get;Set;}
		public boolean pickMulti {get;Set;}
		public boolean pickOne {get;set;}
		public boolean required {get;Set;}
		public boolean useParent {get;Set;}
		public string relationshipTypeExternalID {get;Set;}
		public string parentRelationshipID {get;set;}

		public List<RelationshipView> childRelationships {get;set;}

		public RelationshipView(SPC_Relationship__c r){
			id = r.Id == null ? 'optionalComponent' : r.id;
			defaultQuantity = r.Default_Quantity__c;
			primarySalesProductID = r.Primary_Sales_Product__c;
			primarySalesProductExternalID = r.Primary_Sales_Product__r.SalesProductExternalID__c;
			primarySalesProductName = r.Primary_Sales_Product__r.Name; 			
			primarySalesProductComponentID = r.Primary_Sales_Product_Component__c; 			
			primarySalesProductComponentExternalID = r.Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c; 	
			primarySalesProductComponentSalesProductExternalID = r.Primary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c;
			displayName = r.Relationship_Display_Name__c;								
			relationshipExternalID = r.Relationship_ID__c; 					
			secondarySalesProductID = r.Secondary_Sales_Product__c; 				
			secondarySalesProductExternalID = r.Secondary_Sales_Product__r.SalesProductExternalID__c ; 
			secondarySalesProductName = r.Secondary_Sales_Product__r.Name ; 		
			secondarySalesProductComponentID = r.Secondary_Sales_Product_Component__c ; 		
			secondarySalesProductComponentExternalID = r.Secondary_Sales_Product_Component__r.Sales_Product_Component_ID__c ;
			secondarySalesProductComponentSalesProductExternalID = r.Secondary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c;
			secondaryPriceID = r.Secondary_Pricing_ID__c;
			secondaryPriceExternalID = r.Secondary_Pricing_ID__r.Price_ID__c;
			relationshipTypeID = r.SPC_Relationship_Type__c ; 						
			criteriaRequired = r.SPC_Relationship_Type__r.Criteria_Required__c ; 						
			negativeRelationship = r.SPC_Relationship_Type__r.Negative__c ; 					
			pickMulti = r.SPC_Relationship_Type__r.Pick_Multi__c ; 								
			pickOne = r.SPC_Relationship_Type__r.Pick_One__c ; 								
			required = r.SPC_Relationship_Type__r.Required__c ; 								
			useParent = r.SPC_Relationship_Type__r.Use_parent__c ; 								
			relationshipTypeExternalID = r.SPC_Relationship_Type__r.Relationship_Type_ID__c ; 	
			parentRelationshipID = r.Parent_Relationship__c;	
			autoInclude = r.Auto_Include__c;		
			
			childRelationships = new List<RelationshipView>();
		}

		public integer compareTo(object compareTo){
			RelationshipView rv = (RelationshipView)compareTo;
			if(id == rv.id) return 0;
			if(id > rv.id) return 1;
			return -1;
		}

	}
	
	public class SalesProductView{
		public string id {get;set;}
		public string name {get;set;}
		public datetime expiration {get;set;}
		public boolean hideInWizard {get;set;}
		public integer salesProductID {get;set;}
		public string salesProductGroup {get;set;}
		public string zLocType {get;set;}

		public SalesProductView(SPC_Product__c p){
			this.id = p.id;
			this.name = p.name;
			this.expiration = p.Expiration__c;
			this.hideInWizard = p.Hide_In_Wizard__c;
			this.salesProductID = integer.valueof(p.SalesProductExternalID__c);
			this.salesProductGroup = p.Sales_Product_Group__c;
			this.zLocType = p.Z_Location_Type__c;
		}
	}

	public class PricingView extends ApexUtils.SortableClass{
		//public List<PricingView> autoIncludePricing {get;set;}
		//public Map<RelationshipView,List<SalesProductView>> relatedProducts {get;set;}
		//public Map<RelationshipView,List<PricingView>> relatedPricing {get;Set;}
		//public Map<RelationshipView,List<SalesProductView>> invalidProducts {get;set;}
		//public Map<RelationshipView,List<PricingView>> invalidPricing {get;Set;}


		public string accessTechName {get;set;}
		public boolean availableInWizard {get;set;}
		public decimal bandwidth {get;set;}
		public string componentGroup {get;set;}
		public decimal componentID {get;set;}
		public string componentDisplayName{get;set;}
		public string componentName {get;set;}
		public string componentPricingName {get;set;}
		public string featureSchedulePrompt {get;set;}
		public id id {get;set;}
		public boolean isDIDVirtualTN {get;set;}
		public boolean isExpired {get;set;}
		public boolean isLDInterstate {get;set;}
		public boolean isLDIntrastate {get;set;}
		public boolean isNonDiscountable {get;set;}
		public boolean isOnnetPrice {get;set;}
		public boolean isQuotePrice {get;set;}
		public boolean isTollFree {get;set;}
		public boolean isVoiceLine {get;set;}
		public boolean isVoiceLineOption {get;set;}
		public string market {get;set;}
		public decimal maxQty {get;set;}
		public decimal minQty {get;set;}
		public decimal mrr {get;set;}
		public decimal mrrFloor {get;set;}
		public decimal nrr {get;set;}
		public decimal nrrFloor {get;set;}
		public boolean isPerAccount {get;set;}
		public string priceID {get;set;}
		public string pricingName {get;set;}
		public decimal salesProductComponentID {get;set;}
		public string salesProductGroup {get;set;}
		public decimal salesProductID {get;set;}
		public string salesProductName {get;set;}
		public decimal term {get;set;}
		public boolean zLocRequired {get;set;}
		public id spcComponentID {get;set;}
		public id spcProductID {get;set;}

		public PricingView(SPC_Pricing__c p){
			accessTechName = p.SPC_Component__r.Access_Technology_Name__c;
			availableInWizard = p.Available_In_Wizard__c;
			bandwidth = p.Bandwidth__c;				
			componentGroup = p.SPC_Component__r.Component_Group__c;			
			componentID = p.SPC_Component__r.Component_ID__c;				
			componentDisplayName = p.SPC_Component__r.Display_Name__c;	
			componentName = p.SPC_Component__r.Component_Name__c;	
			componentPricingName = p.Pricing_Name__c == null ? p.SPC_Component__r.Component_Name__c :  p.SPC_Component__r.Component_Name__c + ' - ' + p.Pricing_Name__c;
			featureSchedulePrompt = p.SPC_Component__r.Feature_Schedule_Prompt__c;	
			id = p.id;
			isDIDVirtualTN = p.SPC_Component__r.Is_DID_Virtual_TN__c;			
			isExpired = p.Is_Expired__c;				
			isLDInterstate = p.SPC_Component__r.Is_LD_Interstate__c;			
			isLDIntrastate = p.SPC_Component__r.Is_LD_Intrastate__c;			
			isNonDiscountable = p.Is_Non_Discountable__c;		
			isOnnetPrice = p.Is_OnNet_Price__c;			
			isQuotePrice = p.Is_Quote_Price__c;			
			isTollFree = p.SPC_Component__r.Is_Toll_Free__c;				
			isVoiceLine = p.SPC_Component__r.Is_Voice_Line__c;				
			isVoiceLineOption = p.SPC_Component__r.Is_Voice_Line_Option__c;		
			market = p.Market__c;					
			maxQty = p.SPC_Component__r.Max_Qty__c;					
			minQty = p.SPC_Component__r.Min_Qty__c;					
			mrr	 = p.MRR__c == null ? 0 : p.MRR__c;					
			mrrFloor = p.MRR_Floor__c == null ? 0 : p.MRR_Floor__c;				
			nrr	 = p.NRR__c == null ? 0 : p.NRR__c;					
			nrrFloor = p.NRR_Floor__c == null ? 0 : p.NRR_Floor__c;				
			isPerAccount = p.SPC_Component__r.Is_Per_Account__c;			
			priceID = p.Price_ID__c;					
			pricingName = p.Pricing_Name__c;				
			salesProductComponentID  = p.SPC_Component__r.Sales_Product_Component_ID__c;
			salesProductGroup = p.SPC_Component__r.Sales_Product__r.Sales_Product_Group__c;		
			salesProductID = p.SPC_Component__r.Sales_Product__r.SalesProductExternalID__c;			
			salesProductName = p.SPC_Component__r.Sales_Product__r.Name;		
			spcComponentID = p.SPC_Component__c;
			spcProductID = p.SPC_Component__r.Sales_Product__c;
			term = p.Term__c;					
			zLocRequired  = p.Z_Location_Required__c;			

			//relatedPricing = new Map<RelationshipView,List<PricingView>>();
			//relatedProducts = new Map<RelationshipView,List<SalesProductView>>();

			//invalidPricing = new Map<RelationshipView,List<PricingView>>();
			//invalidProducts = new Map<RelationshipView,List<SalesProductView>>();
		}

		public override object getFieldImp(String fName){
			if(fName == 'componentName') return componentName;
			return null;
		}
		
	}

	//private static String PricingFields{ get{ return string.join(), ', '); } }
	
	public static List<integer> GetHiddenProducts(string marketName, List<integer> terms, boolean existingCustomer){
		List<integer> prods = new List<integer>();
		Set<string> availProds = getAvailableProductsWithPricing(marketName,terms);
		string wearClaws = '(Expiration__c = null and Hide_In_Wizard__c = true)' + (existingCustomer? ' or Hide_For_Existing_Customers__c = true' : '');
		system.debug('wearClaws: '+wearClaws);
		for(SPC_Product__c spc : (List<SPC_Product__c>)ApexUtils.retrieveFullObjects(SPC_Product__c.getsObjectType(), wearClaws)){
			if(availProds.contains(spc.id))
				prods.add(Integer.valueOf(spc.SalesProductExternalID__c));
		}
		return prods;
	}

	public static Map<integer,SalesProductView> GetProducts(string marketName, List<integer> terms, boolean existingCustomer){
		Map<integer,SalesProductView> prods = new Map<integer,SalesProductView>();
		Set<string> availProds = getAvailableProductsWithPricing(marketName,terms);
		string wearClaws = 'Expiration__c = null and Hide_In_Wizard__c = false' + (existingCustomer? ' and Hide_For_Existing_Customers__c = false' : ' and Hide_In_New_CPQ__c = false');
		system.debug('wearClaws: '+wearClaws);
		for(SPC_Product__c spc : (List<SPC_Product__c>)ApexUtils.retrieveFullObjects(SPC_Product__c.getsObjectType(), wearClaws)){
			if(availProds.contains(spc.id))
				prods.put(Integer.valueOf(spc.SalesProductExternalID__c),new SalesProductView(spc));
		}
		return prods;
	}

	public static Map<integer,SalesProductView> GetInitiallyAvailableProducts(string marketName, List<integer> terms, boolean existingCustomer){
		Map<integer,SalesProductView> prods = new Map<integer,SalesProductView>();
		Set<id> preReqProducts = GetPreReqProductRelationships();
		Set<string> availProds = getAvailableProductsWithPricing(marketName,terms);
		string wearClaws = 'Expiration__c = null and Hide_In_Wizard__c = false' + (existingCustomer? ' and Hide_For_Existing_Customers__c = false' : ' and Hide_In_New_CPQ__c = false');
		system.debug('wearClaws: '+wearClaws);
		for(SPC_Product__c spc : (List<SPC_Product__c>)ApexUtils.retrieveFullObjects(SPC_Product__c.getsObjectType(), wearClaws)){
			if(!preReqProducts.contains(spc.id) && availProds.contains(spc.id))
				prods.put(Integer.valueOf(spc.SalesProductExternalID__c),new SalesProductView(spc));
		}
		return prods;
	}

	public static Set<string> getAvailableProductsWithPricing(string marketName, List<integer> terms){
        Set<string> prodNames = new Set<string>();
		integer term = 1;            
        String query = 'SELECT SPC_Component__r.Sales_Product__r.id SalesProductID FROM SPC_Pricing__c Where Market__c = :marketName and is_expired__c = false ';
        for(integer i : terms){
			if(i == 1)
				query += 'and term__c = :term ';
        }
        query += 'Group By SPC_Component__r.Sales_Product__r.id';
		system.debug(query);
        for(AggregateResult ar : Database.query(query)){
            prodNames.add(string.valueof(ar.get('SalesProductID')));
        }
        return prodNames;
    }
	
	public static Map<Id,List<PricingView>> GetSalesProductComponentPricing(String marketAreaName, List<Integer> salesProductIDs, List<Integer> terms, boolean competitiveBuilding){
		Map<Id,List<PricingView>> pricing = new Map<Id,List<PricingView>>();
		
		string mainquery = 'Select Available_In_Wizard__c, Bandwidth__c,Is_Expired__c, Is_OnNet_Price__c, Is_Quote_Price__c, MRR__c, '
							+ 'MRR_Floor__c, Market__c, NRR__c, NRR_Floor__c, Price_ID__c, Pricing_Name__c, Sales_Product_Component_ID__c, '
							+ 'Term__c, SPC_Component__c, Is_Non_Discountable__c, Z_Location_Required__c,'
							+ 'SPC_Component__r.Access_Technology_Name__c, SPC_Component__r.Component_Group__c, SPC_Component__r.Component_ID__c, '
							+ 'SPC_Component__r.Component_Name__c, SPC_Component__r.Feature_Schedule_Prompt__c, SPC_Component__r.Is_DID_Virtual_TN__c, SPC_Component__r.Is_LD_Interstate__c, '
							+ 'SPC_Component__r.Is_LD_Intrastate__c, SPC_Component__r.Is_Toll_Free__c, SPC_Component__r.Is_Voice_Line__c, SPC_Component__r.Is_Voice_Line_Option__c, '
							+ 'SPC_Component__r.Is_Per_Account__c,SPC_Component__r.Max_Qty__c, SPC_Component__r.Min_Qty__c, '
							+ 'SPC_Component__r.Sales_Product_Component_ID__c,SPC_Component__r.Sales_Product__r.Sales_Product_Group__c, SPC_Component__r.Sales_Product__r.SalesProductExternalID__c, '
							+ 'SPC_Component__r.Sales_Product__r.Name, SPC_Component__r.Sales_Product__c, SPC_Component__r.Display_Name__c '
							+ 'From SPC_Pricing__c s Where Is_Expired__c = false and SPC_Component__r.Sales_Product__r.SalesProductExternalID__c in :salesProductIds and market__c = :marketAreaName';
        
		if(terms.size() > 0){
			terms.add(0);
			mainquery += ' and Term__c in: terms';
		}
		system.debug('mainquery: ' + mainquery);
        List<SPC_Pricing__c> priceRecords = database.query(mainquery);
		List<SPC_Pricing__c> retPricing = new List<SPC_Pricing__c>();
		Set<Id> compIds = new Set<Id>();		
        if(priceRecords != null){
			if(competitiveBuilding){
				for(SPC_Pricing__c p : priceRecords){
					if(p.Pricing_Name__c != null && p.Pricing_Name__c.contains('Competitive Building')){
						retPricing.add(p);
						compIds.add(p.SPC_Component__c);
					}
				}
				for(SPC_Pricing__c p : priceRecords){
					if(!compIds.contains(p.SPC_Component__c)) retPricing.add(p);
				}
				for(SPC_Pricing__c p : retPricing){
					if(pricing.containsKey(p.SPC_Component__c)){
						List<PricingView> pv = pricing.get(p.SPC_Component__c);
						pv.add(new PricingView(p));
						pricing.put(p.SPC_Component__c,pv);
					}
					else
						pricing.put(p.SPC_Component__c,new List<PricingView>{new PricingView(p)});
				}
			}
			else{
				//Remove top level that should not display in wizard
				for(Integer i=priceRecords.size()-1; i>=0; i--){
				  if((priceRecords[i].Pricing_Name__c != null && priceRecords[i].Pricing_Name__c.contains('Competitive Building') && !competitiveBuilding))
					priceRecords.remove(i);
				}
				for(SPC_Pricing__c p: pricerecords){
					if(pricing.containsKey(p.SPC_Component__c)){
						List<PricingView> pv = pricing.get(p.SPC_Component__c);
						pv.add(new PricingView(p));
						pricing.put(p.SPC_Component__c,pv);
					}
					else
						pricing.put(p.SPC_Component__c,new List<PricingView>{new PricingView(p)});
				}
			}
		}
		return pricing;
	}

	public static Map<Integer,Map<Id,List<PricingView>>> GetSalesProductComponentPricing2(String marketAreaName, List<Integer> salesProductIDs, List<Integer> terms, boolean competitiveBuilding){
		Map<Integer,Map<Id,List<PricingView>>> pricing = new Map<Integer,Map<Id,List<PricingView>>>();
		
		string mainquery = 'Select Available_In_Wizard__c, Bandwidth__c,Is_Expired__c, Is_OnNet_Price__c, Is_Quote_Price__c, MRR__c, '
							+ 'MRR_Floor__c, Market__c, NRR__c, NRR_Floor__c, Price_ID__c, Pricing_Name__c, Sales_Product_Component_ID__c, '
							+ 'Term__c, SPC_Component__c, Is_Non_Discountable__c, Z_Location_Required__c,'
							+ 'SPC_Component__r.Access_Technology_Name__c, SPC_Component__r.Component_Group__c, SPC_Component__r.Component_ID__c, '
							+ 'SPC_Component__r.Component_Name__c, SPC_Component__r.Feature_Schedule_Prompt__c, SPC_Component__r.Is_DID_Virtual_TN__c, SPC_Component__r.Is_LD_Interstate__c, '
							+ 'SPC_Component__r.Is_LD_Intrastate__c, SPC_Component__r.Is_Toll_Free__c, SPC_Component__r.Is_Voice_Line__c, SPC_Component__r.Is_Voice_Line_Option__c, '
							+ 'SPC_Component__r.Is_Per_Account__c,SPC_Component__r.Max_Qty__c, SPC_Component__r.Min_Qty__c, '
							+ 'SPC_Component__r.Sales_Product_Component_ID__c,SPC_Component__r.Sales_Product__r.Sales_Product_Group__c, SPC_Component__r.Sales_Product__r.SalesProductExternalID__c, '
							+ 'SPC_Component__r.Sales_Product__r.Name, SPC_Component__r.Sales_Product__c, SPC_Component__r.Display_Name__c '
							+ 'From SPC_Pricing__c s Where Is_Expired__c = false and SPC_Component__r.Sales_Product__r.SalesProductExternalID__c in :salesProductIds and market__c = :marketAreaName';
        
		if(terms.size() > 0){
			terms.add(0);
			mainquery += ' and Term__c in: terms';
		}

        List<SPC_Pricing__c> priceRecords = database.query(mainquery);
        if(priceRecords != null){
		
			Set<Id> compIds = new Set<Id>();		
			if(competitiveBuilding){
				for(SPC_Pricing__c p : priceRecords){
					if(p.Pricing_Name__c != null && p.Pricing_Name__c.contains('Competitive Building')){
						compIds.add(p.SPC_Component__c);
					}
				}
			}
			

			for(Integer i=priceRecords.size()-1; i>=0; i--){
				if((priceRecords[i].Pricing_Name__c != null && priceRecords[i].Pricing_Name__c.contains('Competitive Building') && !competitiveBuilding))
					priceRecords.remove(i);
			}

			for(SPC_Pricing__c p: pricerecords){				
				if(pricing.containsKey(integer.valueof(p.SPC_Component__r.Sales_Product__r.SalesProductExternalID__c))){
					//Map has product already added
					if((competitiveBuilding && ((p.Pricing_Name__c != null && p.Pricing_Name__c.contains('Competitive Building')) || !compIds.contains(p.SPC_Component__c))) || !competitiveBuilding){
						Map<Id,List<PricingView>> pm = pricing.get(integer.valueof(p.SPC_Component__r.Sales_Product__r.SalesProductExternalID__c));
					
						if(pm.containsKey(p.SPC_Component__c)){
							List<PricingView> pv = pm.get(p.SPC_Component__c);
							pv.add(new PricingView(p));
							pm.put(p.SPC_Component__c,pv);
						}
						else
							pm.put(p.SPC_Component__c,new List<PricingView>{new PricingView(p)});
					
						pricing.put(integer.valueof(p.SPC_Component__r.Sales_Product__r.SalesProductExternalID__c),pm);
					}
				}
				else{
					//Map doesn't have product
					if((competitiveBuilding && ((p.Pricing_Name__c != null && p.Pricing_Name__c.contains('Competitive Building')) || !compIds.contains(p.SPC_Component__c))) || !competitiveBuilding){
						Map<Id,List<PricingView>> pm = new map<Id,List<PricingView>>{p.SPC_Component__c => new List<PricingView>{new PricingView(p)}};
						pricing.put(integer.valueof(p.SPC_Component__r.Sales_Product__r.SalesProductExternalID__c), pm );
					}
				}
			}
		}
		return pricing;
	}

	public static Map<Id,List<PricingView>> GetSalesProductComponentPricingByComponentIds(String marketAreaName, set<id> componentIds, List<Integer> terms, boolean competitiveBuilding){
		Map<Id,List<PricingView>> pricing = new Map<Id,List<PricingView>>();
		
		string mainquery = 'Select Available_In_Wizard__c, Bandwidth__c,Is_Expired__c, Is_OnNet_Price__c, Is_Quote_Price__c, MRR__c, '
							+ 'MRR_Floor__c, Market__c, NRR__c, NRR_Floor__c, Price_ID__c, Pricing_Name__c, Sales_Product_Component_ID__c, '
							+ 'Term__c, SPC_Component__c, Is_Non_Discountable__c, Z_Location_Required__c,'
							+ 'SPC_Component__r.Access_Technology_Name__c, SPC_Component__r.Component_Group__c, SPC_Component__r.Component_ID__c, '
							+ 'SPC_Component__r.Component_Name__c, SPC_Component__r.Feature_Schedule_Prompt__c, SPC_Component__r.Is_DID_Virtual_TN__c, SPC_Component__r.Is_LD_Interstate__c, '
							+ 'SPC_Component__r.Is_LD_Intrastate__c, SPC_Component__r.Is_Toll_Free__c, SPC_Component__r.Is_Voice_Line__c, SPC_Component__r.Is_Voice_Line_Option__c, '
							+ 'SPC_Component__r.Is_Per_Account__c,SPC_Component__r.Max_Qty__c, SPC_Component__r.Min_Qty__c, '
							+ 'SPC_Component__r.Sales_Product_Component_ID__c,SPC_Component__r.Sales_Product__r.Sales_Product_Group__c, SPC_Component__r.Sales_Product__r.SalesProductExternalID__c, '
							+ 'SPC_Component__r.Sales_Product__r.Name, SPC_Component__r.Sales_Product__c, SPC_Component__r.Display_Name__c '
							+ 'From SPC_Pricing__c s Where Is_Expired__c = false and SPC_Component__c in :componentIds and market__c = :marketAreaName';
        
		if(terms.size() > 0){
			terms.add(0);
			mainquery += ' and Term__c in: terms';
		}

        List<SPC_Pricing__c> priceRecords = database.query(mainquery);

        if(priceRecords != null){
			//Remove top level that should not display in wizard
			for(Integer i=priceRecords.size()-1; i>=0; i--){
			  if((priceRecords[i].Pricing_Name__c != null && priceRecords[i].Pricing_Name__c.contains('Competitive Building') && !competitiveBuilding))
				priceRecords.remove(i);
			}
			for(SPC_Pricing__c p: pricerecords){
				if(pricing.containsKey(p.SPC_Component__c)){
					List<PricingView> pv = pricing.get(p.SPC_Component__c);
					pv.add(new PricingView(p));
					pricing.put(p.SPC_Component__c,pv);
				}
				else
					pricing.put(p.SPC_Component__c,new List<PricingView>{new PricingView(p)});
			}
		}
		return pricing;
	}

	public static Set<Id> GetPreReqProductRelationships(){
		Set<id> preReqProducts = new Set<id>();

		for(SPC_Relationship__c r : [Select Id,Secondary_Sales_Product__c From SPC_Relationship__c Where (Secondary_Sales_Product__c != null and SPC_Relationship_Type__r.Relationship_type_ID__c = '8') ]){
			preReqProducts.add(r.secondary_sales_product__c);
		}

		return preReqProducts;
	}

	public static List<RelationshipView> GetRelationships(Map<Id,List<CatalogUtils.PricingView>> pricing, id salesProduct){
		List<RelationshipView> relationships = new List<RelationshipView>();

		for(SPC_Relationship__c r : [Select 
														Id, 
														Auto_Include__c,
														Default_Quantity__c,
														Parent_Relationship__c,
														Primary_Sales_Product__c,
														Primary_Sales_Product__r.Id,
														Primary_Sales_Product__r.SalesProductExternalID__c,
														Primary_Sales_Product__r.Name,
														Primary_Sales_Product_Component__c,
														Primary_Sales_Product_Component__r.Id,
														Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c,
														Primary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c,
														Relationship_Display_Name__c,
														Relationship_ID__c,
														Secondary_Sales_Product__c,
														Secondary_Sales_Product__r.SalesProductExternalID__c,
														Secondary_Sales_Product__r.Name,
														Secondary_Sales_Product_Component__c,
														Secondary_Sales_Product_Component__r.Sales_Product_Component_ID__c,
														Secondary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c,
														Secondary_Pricing_ID__c,
														Secondary_Pricing_ID__r.Price_ID__c,
														SPC_Relationship_Type__c,
														SPC_Relationship_Type__r.Criteria_Required__c,
														SPC_Relationship_Type__r.Negative__c,
														SPC_Relationship_Type__r.Pick_Multi__c,
														SPC_Relationship_Type__r.Pick_One__c,
														SPC_Relationship_Type__r.Relationship_Type_ID__c,
														SPC_Relationship_Type__r.Required__c,
														SPC_Relationship_Type__r.Use_parent__c,
														SPC_Relationship_Type__r.Feature_Package__c,
														(
															Select 
																Id,
																Auto_Include__c,
																Default_Quantity__c,
																Parent_Relationship__c,
																Primary_Sales_Product__c,
																Primary_Sales_Product__r.SalesProductExternalID__c,
																Primary_Sales_Product__r.Name,
																Primary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c,
																Primary_Sales_Product_Component__c,
																Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c,
																Relationship_Display_Name__c,
																Relationship_ID__c,
																Secondary_Sales_Product__c,
																Secondary_Sales_Product__r.SalesProductExternalID__c,
																Secondary_Sales_Product__r.Name,
																Secondary_Sales_Product_Component__c,
																Secondary_Sales_Product_Component__r.Sales_Product_Component_ID__c,
																Secondary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c,
																Secondary_Pricing_ID__c,
																Secondary_Pricing_ID__r.Price_ID__c,
																SPC_Relationship_Type__c,
																SPC_Relationship_Type__r.Criteria_Required__c,
																SPC_Relationship_Type__r.Negative__c,
																SPC_Relationship_Type__r.Pick_Multi__c,
																SPC_Relationship_Type__r.Pick_One__c,
																SPC_Relationship_Type__r.Relationship_Type_ID__c,
																SPC_Relationship_Type__r.Required__c,
																SPC_Relationship_Type__r.Use_parent__c,
																SPC_Relationship_Type__r.Feature_Package__c

															From 
																SPC_Relationships__r
														)
													From 
														SPC_Relationship__c 
													Where 
														(Primary_Sales_Product__c = :salesProduct
														or Primary_Sales_Product_Component__c in :pricing.keyset()
														//or Secondary_Sales_Product_Component__c in :pricing.keyset()
														)
														and SPC_Relationship_Type__r.Feature_Package__c = false
														//and (Primary_Sales_Product__c = null or (Primary_Sales_Product__r.Hide_In_Wizard__c = false and Primary_Sales_Product__r.Hide_In_New_CPQ__c = false))
														//and (Secondary_Sales_Product__c = null or (Secondary_Sales_Product__r.Hide_In_Wizard__c = false and Secondary_Sales_Product__r.Hide_In_New_CPQ__c = false))
													]){
														List<RelationshipView> crs = new List<RelationshipView>();
														for(SPC_Relationship__c cr : r.SPC_Relationships__r){
															crs.add(new RelationshipView(cr));
														}

														RelationshipView rv = new RelationshipView(r);
														rv.childRelationships.addall(crs);


														relationships.add(rv);
													}



														
		return relationships;
	 
	}

	public static List<RelationshipView> GetRelationshipsByPriceIds(List<Id> priceIds){
		List<RelationshipView> relationships = new List<RelationshipView>();

		for(SPC_Relationship__c r : [Select 
														Id, 
														Auto_Include__c,
														Default_Quantity__c,
														Parent_Relationship__c,
														Primary_Sales_Product__c,
														Primary_Sales_Product__r.Id,
														Primary_Sales_Product__r.SalesProductExternalID__c,
														Primary_Sales_Product__r.Name,
														Primary_Sales_Product_Component__c,
														Primary_Sales_Product_Component__r.Id,
														Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c,
														Primary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c,
														Relationship_Display_Name__c,
														Relationship_ID__c,
														Secondary_Sales_Product__c,
														Secondary_Sales_Product__r.SalesProductExternalID__c,
														Secondary_Sales_Product__r.Name,
														Secondary_Sales_Product_Component__c,
														Secondary_Sales_Product_Component__r.Sales_Product_Component_ID__c,
														Secondary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c,
														Secondary_Pricing_ID__c,
														Secondary_Pricing_ID__r.Price_ID__c,
														SPC_Relationship_Type__c,
														SPC_Relationship_Type__r.Criteria_Required__c,
														SPC_Relationship_Type__r.Negative__c,
														SPC_Relationship_Type__r.Pick_Multi__c,
														SPC_Relationship_Type__r.Pick_One__c,
														SPC_Relationship_Type__r.Relationship_Type_ID__c,
														SPC_Relationship_Type__r.Required__c,
														SPC_Relationship_Type__r.Use_parent__c
													From 
														SPC_Relationship__c 
													Where 
														(Secondary_Pricing_ID__c in :priceIds)
														and SPC_Relationship_Type__r.Feature_Package__c = false
													]){
														relationships.add(new RelationshipView(r));
													}

		return relationships;
	}

		public static List<RelationshipView> GetFeaturePackageRelationships(){
		List<RelationshipView> relationships = new List<RelationshipView>();

		for(SPC_Relationship__c r : [Select 
														Id, 
														Auto_Include__c,
														Default_Quantity__c,
														Parent_Relationship__c,
														Primary_Sales_Product__c,
														Primary_Sales_Product__r.Id,
														Primary_Sales_Product__r.SalesProductExternalID__c,
														Primary_Sales_Product_Component__c,
														Primary_Sales_Product_Component__r.Id,
														Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c,
														Primary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c,
														Relationship_Display_Name__c,
														Relationship_ID__c,
														Secondary_Sales_Product__c,
														Secondary_Sales_Product__r.SalesProductExternalID__c,
														Secondary_Sales_Product_Component__c,
														Secondary_Sales_Product_Component__r.Sales_Product_Component_ID__c,
														Secondary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c,
														Secondary_Pricing_ID__c,
														Secondary_Pricing_ID__r.Price_ID__c,
														SPC_Relationship_Type__c,
														SPC_Relationship_Type__r.Criteria_Required__c,
														SPC_Relationship_Type__r.Negative__c,
														SPC_Relationship_Type__r.Pick_Multi__c,
														SPC_Relationship_Type__r.Pick_One__c,
														SPC_Relationship_Type__r.Relationship_Type_ID__c,
														SPC_Relationship_Type__r.Required__c,
														SPC_Relationship_Type__r.Use_parent__c,
														SPC_Relationship_Type__r.Feature_Package__c,
														(
															Select 
																Id,
																Auto_Include__c,
																Default_Quantity__c,
																Parent_Relationship__c,
																Primary_Sales_Product__c,
																Primary_Sales_Product__r.SalesProductExternalID__c,
																Primary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c,
																Primary_Sales_Product_Component__c,
																Primary_Sales_Product_Component__r.Sales_Product_Component_ID__c,
																Relationship_Display_Name__c,
																Relationship_ID__c,
																Secondary_Sales_Product__c,
																Secondary_Sales_Product__r.SalesProductExternalID__c,
																Secondary_Sales_Product_Component__c,
																Secondary_Sales_Product_Component__r.Sales_Product_Component_ID__c,
																Secondary_Sales_Product_Component__r.Sales_Product__r.SalesProductExternalID__c,
																Secondary_Pricing_ID__c,
																Secondary_Pricing_ID__r.Price_ID__c,
																SPC_Relationship_Type__c,
																SPC_Relationship_Type__r.Criteria_Required__c,
																SPC_Relationship_Type__r.Negative__c,
																SPC_Relationship_Type__r.Pick_Multi__c,
																SPC_Relationship_Type__r.Pick_One__c,
																SPC_Relationship_Type__r.Relationship_Type_ID__c,
																SPC_Relationship_Type__r.Required__c,
																SPC_Relationship_Type__r.Use_parent__c,
																SPC_Relationship_Type__r.Feature_Package__c

															From 
																SPC_Relationships__r
														)
													From 
														SPC_Relationship__c 
													Where 
														SPC_Relationship_Type__r.Feature_Package__c = true
													]){
														List<RelationshipView> crs = new List<RelationshipView>();
														for(SPC_Relationship__c cr : r.SPC_Relationships__r){
															crs.add(new RelationshipView(cr));
														}

														RelationshipView rv = new RelationshipView(r);
														rv.childRelationships.addall(crs);


														relationships.add(rv);
													}



														
		return relationships;
	 
	}


	public class CatalogUtilsException extends Exception{}
}