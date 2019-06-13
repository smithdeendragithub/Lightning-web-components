public class ConfigureNewSolution implements TestUtils.ITestableClass { 
  //the initial products.
  public Map<integer,CatalogUtils.SalesProductView> initialProducts {get;set;}
  public string jsonIniProds{
    get{
      return initialProducts!=null? JSON.serialize(initialProducts) : '';
    }
  }
  public List<integer> hiddenProductIds {get;set;}
  public string jsonHiddenProductIds{
    get{
      Map<integer,boolean> m = new Map<integer,boolean>();
      if(hiddenProductIds != null){
        for(integer i : hiddenProductIds){
          m.put(i,true);
        }
      }
      return JSON.serialize(m);
    }
  }
  public Boolean disableValidations {get;private set;}
  public string market {get;private set;}
  private List<integer> terms {get;private set;}
  public string jsonTerms{
    get{
      return JSON.serialize(terms,true);
    }
  }
  public static id configId {get;private set;}
  
  public OpportunityLocationConfiguration__c opportunityLocationConfiguration { get; private set; }
  public string jsonSolution{
    get{
      return JSON.serialize(opportunityLocationConfiguration,true);
    }
  }
 
  private Map<Id,OLIView> existingOLIs {get;private set;}
  public string jsonexistingOLIs{
    get{
      return JSON.serialize(existingOLIs,true);
    }
  }

  private Map<string,CatalogUtils.RelationshipView> featurePackageRels {get; private set;}
  public string jsonFeaturePackageRels{
    get{
      return JSON.serialize(featurePackageRels,true);
    }
  }

  private Map<String, Map<String, Map<String, Decimal>>> sortConfigMap {get;private set;}
  public string jsonSPCSortConfigMap{
    get{
      return JSON.serialize(sortConfigMap,true);
    }
  }

  public string jsonExistingOLIsDataObjs {get;set;}
  public string jsonSLocSelections {get;set;}
  public string jsonLocSelections {get;set;}

  public DiscountAuthorityLevels__c discountAuthorityLevel { get; set;}

  public Opportunity opp {get;set;}

  public List<Building_Access_Availability__c> baas {get;set;}

  private List<String> accessTechs {get;set;}
  public string jsonAccessTechs{
    get{
      return JSON.serialize(accessTechs,true);
    }
  }
  
  private Map<string,List<decimal>> bandwidthsByAccess{get;set;}
  public string jsonbandwidthsByAccess{
    get{
      return JSON.serialize(bandwidthsByAccess,true);
    }
  }

  private Map<string,decimal> accessBandwidthDefaults{get;set;}
  public string jsonAccessBandwidthDefaults{
    get{
      return JSON.serialize(accessBandwidthDefaults,true);
    }
  }
  
  public Decimal SMDiscountPercent {get;private set;}

  public class OLIView{
    public OLI__c oli { get; set; }
    public string productName {get;set;}
    public decimal productExternalID {get;set;}
    public string UUID {get;set;}
    public List<OLIView> configChildren {get;set;}
    public OLIView(OLI__c oli){
      this.oli = oli;
      this.productName = oli.SPC_Sales_Product__r.name;
      this.productExternalID = oli.SPC_Sales_Product__r.SalesProductExternalID__c;
      this.configChildren = new List<OLIView>();
    }
  }

  public ConfigureNewSolution(){
    string sTerm = ApexPages.currentPage().getParameters().get('term');
    market = ApexPages.currentPage().getParameters().get('market');
    configId = ApexPages.currentPage().getParameters().get('opportunityLocationConfigurationId');
    opportunityLocationConfiguration = getSolution(configId);
    opp = loadOpportunity();
    disableValidations = opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.ICC_Subscriber_ID__c != null;// opp.Account.ICC_Account_Number__c != null;
    baas = getBAA();
    terms = new List<Integer>{integer.valueOf((sTerm == 'Month to Month') ? '1' : ((sTerm == 'Coterminous') ? '0' :sTerm))};
    getInitialProducts();
    existingOLIs = getOlis();
    jsonExistingOLIsDataObjs = getPricingForConfiguredProducts();
    featurePackageRels = GetFeaturePackageRelationships();
    getSecLocSelections(opp.AccountId);
     discountAuthorityLevel = SolutionApprovalUtils.getApprovalLevel(UserInfo.getUserId());
    sortConfigMap = getSPCSortConfigMap();
    accessTechs = getAccessTechs();
    bandwidthsByAccess = getBandwidthsByAccess();
    accessBandwidthDefaults = getDefaultAccessTechByHierarchy(baas);
    SMDiscountPercent = SolutionApprovalUtils.GetSMCompetitiveBuildingDiscount();
    system.debug('existingOLIs1:'+existingOLIs);
  }

  public Opportunity loadOpportunity(){
    return [select Id, Name, AccountId, Account.Name, Account.ICC_Account_Number__c, UC_Specialist__r.Name from Opportunity where id = :opportunityLocationConfiguration.Opportunity_Location__r.Order__r.Opportunity__r.Id Limit 1];
  }

  public void getInitialProducts(){
    initialProducts = CatalogUtils.GetInitiallyAvailableProducts(market,terms,disableValidations);
    hiddenProductIds = CatalogUtils.GetHiddenProducts(market,terms,disableValidations);
  }

  @RemoteAction
  public static String getPricingForProduct(string prodId, string market, string terms, boolean competitiveBuilding, boolean showAllProducts){
    Map<string,CatalogUtils.RelationshipView> initialProductProductRelationships = new Map<string,CatalogUtils.RelationshipView>();
    Map<string,CatalogUtils.SalesProductView> initialProductProductRequirements = new Map<string,CatalogUtils.SalesProductView>();
    Map<string,CatalogUtils.RelationshipView> initialInvalidProductProductRelationships = new Map<string,CatalogUtils.RelationshipView>();
    Map<string,CatalogUtils.SalesProductView> initialInvalidProductProductRequirements = new Map<string,CatalogUtils.SalesProductView>();
  
    Map<string,CatalogUtils.RelationshipView> initialProductComponentRelationships = new Map<string,CatalogUtils.RelationshipView>();
    Map<string,List<CatalogUtils.PricingView>> initialProductComponentRequirements = new Map<string,List<CatalogUtils.PricingView>>();
  
    Map<string, CatalogUtils.RelationshipView> optionalPricingRelationships = new Map<string, CatalogUtils.RelationshipView>();
    Map<String,Map<string,List<CatalogUtils.PricingView>>> optionalPricing = new Map<String,Map<string,List<CatalogUtils.PricingView>>>();

    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalProductRelationships = new Map<string,Map<string,CatalogUtils.RelationshipView>>();
    Map<string,List<CatalogUtils.SalesProductView>> conditionalProductRequirements = new Map<string,List<CatalogUtils.SalesProductView>>();

    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalProductComponentRelationships = new Map<string,Map<string,CatalogUtils.RelationshipView>>();
    Map<string,List<CatalogUtils.PricingView>> conditionalProductComponentRequirements = new Map<string,List<CatalogUtils.PricingView>>();

    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalInvalidProductProductRelationships = new Map<string,Map<string,CatalogUtils.RelationshipView>>();
    Map<string,List<CatalogUtils.SalesProductView>> conditionalInvalidProductProductRequirements = new Map<string,List<CatalogUtils.SalesProductView>>();

    //may not need these
    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalInvalidProductComponentRelationships = new Map<string,Map<string,CatalogUtils.RelationshipView>>();
    Map<string,List<CatalogUtils.PricingView>> conditionalInvalidProductComponentRequirements = new Map<string,List<CatalogUtils.PricingView>>();

    Map<id,List<id>> conditionalValidProductPricing = new Map<id,List<id>>();
    Map<id,List<id>> conditionalInvalidProductPricing = new Map<id,List<id>>();
    
    List<CatalogUtils.PricingView> alreadyRelatedPricing = new List<CatalogUtils.PricingView>();
    //get the data
    List<Integer> termsList = (List<Integer>)JSON.deserialize(terms, List<Integer>.class);
    getPricing(Integer.valueOf(prodId), market, termsList, 
      initialProductProductRelationships,
      initialProductProductRequirements,  
      initialInvalidProductProductRelationships,
      initialInvalidProductProductRequirements,  
      initialProductComponentRelationships,
      initialProductComponentRequirements,  
      optionalPricingRelationships,
      optionalPricing,
      conditionalProductRelationships,
      conditionalProductRequirements,
      conditionalProductComponentRelationships,
      conditionalProductComponentRequirements,
      conditionalInvalidProductProductRelationships,
      conditionalInvalidProductProductRequirements,
      conditionalInvalidProductComponentRelationships,
      conditionalInvalidProductComponentRequirements, 
      conditionalValidProductPricing,
      conditionalInvalidProductPricing,
      alreadyRelatedPricing,
      competitiveBuilding,
      showAllProducts);
  
    //create the MASTER OBJECT
    Map<string,Object> MstrObj = new Map<String,Object>();
    MstrObj.put('IniProdCompReqs',initialProductComponentRequirements);
    MstrObj.put('IniProdCompRels',initialProductComponentRelationships);
    MstrObj.put('IniProdProdReqs',initialProductProductRequirements);
    MstrObj.put('IniProdProdRels',initialProductProductRelationships);
    MstrObj.put('IniInvalidProdProdReqs',initialInvalidProductProductRequirements);
    MstrObj.put('IniInvalidProdProdRels',initialInvalidProductProductRelationships);
    MstrObj.put('OptionalPricing',optionalPricing);
    MstrObj.put('OptionalPricingRels',optionalPricingRelationships);
    MstrObj.put('ConditionalProdReqs',conditionalProductRequirements);
    MstrObj.put('ConditionalProdRels',conditionalProductRelationships);
    MstrObj.put('ConditionalInvalidProdProdReqs',conditionalInvalidProductProductRequirements);
    MstrObj.put('ConditionalInvalidProdProdRels',conditionalInvalidProductProductRelationships);
    MstrObj.put('ConditionalInvalidProdCompReqs',conditionalInvalidProductComponentRequirements);
    MstrObj.put('ConditionalInvalidProdCompRels',conditionalInvalidProductComponentRelationships);
    MstrObj.put('ConditionalValidProductPricing',conditionalValidProductPricing);
    MstrObj.put('conditionalInvalidProductPricing',conditionalInvalidProductPricing);
    MstrObj.put('conditionalProductComponentRelationships',conditionalProductComponentRelationships);    
    MstrObj.put('conditionalProductComponentRequirements',conditionalProductComponentRequirements);
    //MstrObj.put('AlreadyRelatedPricing',alreadyRelatedPricing);
    //send it to the page
    return JSON.serialize(MstrObj,true);
  }
  
  // fill 'em up!
  private static void getPricing(Integer selectedProduct, string market, List<Integer> terms, 
    Map<string,CatalogUtils.RelationshipView> initialProductProductRelationships,
    Map<string,CatalogUtils.SalesProductView> initialProductProductRequirements,  
    Map<string,CatalogUtils.RelationshipView> initialInvalidProductProductRelationships,
    Map<string,CatalogUtils.SalesProductView> initialInvalidProductProductRequirements,  
    Map<string,CatalogUtils.RelationshipView> initialProductComponentRelationships,
    Map<string,List<CatalogUtils.PricingView>> initialProductComponentRequirements,  
    Map<string, CatalogUtils.RelationshipView> optionalPricingRelationships,
    Map<String,Map<string,List<CatalogUtils.PricingView>>> optionalPricing,
    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalProductRelationships,
    Map<string,List<CatalogUtils.SalesProductView>> conditionalProductRequirements,
    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalProductComponentRelationships,
    Map<string,List<CatalogUtils.PricingView>> conditionalProductComponentRequirements,
    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalInvalidProductProductRelationships,
    Map<string,List<CatalogUtils.SalesProductView>> conditionalInvalidProductProductRequirements,
    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalInvalidProductComponentRelationships,
    Map<string,List<CatalogUtils.PricingView>> conditionalInvalidProductComponentRequirements, 
    Map<id,List<id>> conditionalValidProductPricing,
    Map<id,List<id>> conditionalInvalidProductPricing,
    List<CatalogUtils.PricingView> alreadyRelatedPricing,
    Boolean competitiveBuilding,
    Boolean showAllProducts){
    
    Map<integer,CatalogUtils.SalesProductView> products = CatalogUtils.GetProducts(market,terms,showAllProducts);
    Map<id,List<CatalogUtils.PricingView>> pricing = CatalogUtils.GetSalesProductComponentPricing(market,new List<integer>{selectedProduct},terms, competitiveBuilding);
    List<CatalogUtils.RelationshipView> relationships = CatalogUtils.GetRelationships(pricing,products.get(selectedProduct).Id);
    
    //Need to split these into primary/secondary I think...
    //If something is in a secondary list at all we can't automatically display it, and then we need to show it as a child
    Map<Id,List<CatalogUtils.RelationshipView>> salesProductRelationships = new Map<Id,List<CatalogUtils.RelationshipView>>();
    Map<Id,List<CatalogUtils.RelationshipView>> salesProductComponentRelationships = new Map<Id,List<CatalogUtils.RelationshipView>>();
    set<id> crossProductComponentPricingNeeded = new set<id>();

    for(CatalogUtils.RelationshipView r : relationships){
      if(r.primarySalesProductID != null){
        if(salesProductRelationships.containskey(r.primarySalesProductID)){
          List<CatalogUtils.RelationshipView> rs = salesProductRelationships.get(r.primarySalesProductID);
          rs.add(r);
          salesProductRelationships.put(r.primarySalesProductID,rs);
        }
        else{
          salesProductRelationships.put(r.primarySalesProductID, new List<CatalogUtils.RelationshipView>{r});
        }
      }
      else if(r.primarySalesProductComponentID != null && r.parentRelationshipID == null){
        if(r.secondarySalesProductComponentID != null && r.secondarySalesProductComponentSalesProductExternalID != selectedProduct)
          crossProductComponentPricingNeeded.add(r.secondarySalesProductComponentID);

        if(salesProductComponentRelationships.containskey(r.primarySalesProductComponentID)){
          List<CatalogUtils.RelationshipView> rs = salesProductComponentRelationships.get(r.primarySalesProductComponentID);
          rs.add(r);
          salesProductComponentRelationships.put(r.primarySalesProductComponentID,rs);
        }
        else{
          salesProductComponentRelationships.put(r.primarySalesProductComponentID, new List<CatalogUtils.RelationshipView>{r});
        }
      }
    }

    List<id> priceIds = new List<id>();
    for(id key : pricing.keyset()){
      for(CatalogUtils.PricingView pv : pricing.get(key)){
        priceIds.add(pv.id);
      }
    }
    List<CatalogUtils.RelationshipView> secondaryPricingRelationships = CatalogUtils.GetRelationshipsByPriceIds(priceIds);


    //get pricing for any relationship where the product is not the selected product(any related component on another product)
    pricing.putall(CatalogUtils.GetSalesProductComponentPricingByComponentIds(market,crossProductComponentPricingNeeded,terms, competitiveBuilding));

    //get relationships
    alreadyRelatedPricing = new List<CatalogUtils.PricingView>();
    
    getProductProductRelationships(salesProductRelationships, products, selectedProduct, initialProductProductRelationships, initialProductProductRequirements, initialInvalidProductProductRelationships, initialInvalidProductProductRequirements);
    getComponentRelationships(salesProductRelationships, salesProductComponentRelationships, products, selectedProduct,pricing,
      initialProductComponentRelationships,
      initialProductComponentRequirements,
      conditionalProductRelationships,
      conditionalProductRequirements,
      conditionalProductComponentRelationships,
      conditionalProductComponentRequirements,
      conditionalInvalidProductProductRelationships,
      conditionalInvalidProductProductRequirements,
      conditionalInvalidProductComponentRelationships,
      conditionalInvalidProductComponentRequirements,
      conditionalValidProductPricing,
      conditionalInvalidProductPricing,
      alreadyRelatedPricing,
      secondaryPricingRelationships);
    getOptionalRemainingPricing(alreadyRelatedPricing,pricing,salesProductComponentRelationships,
      optionalPricingRelationships,
      optionalPricing);
    
  }

  public static void getProductProductRelationships(Map<Id,List<CatalogUtils.RelationshipView>> salesProductRelationships, Map<integer,CatalogUtils.SalesProductView> products, integer selectedProduct,
    Map<string,CatalogUtils.RelationshipView> initialProductProductRelationships,
    Map<string,CatalogUtils.SalesProductView> initialProductProductRequirements,
    Map<string,CatalogUtils.RelationshipView> initialInvalidProductProductRelationships,
    Map<string,CatalogUtils.SalesProductView> initialInvalidProductProductRequirements){
    //Map<CatalogUtils.RelationshipView,CatalogUtils.SalesProductView> prodViews = new Map<CatalogUtils.RelationshipView,CatalogUtils.SalesProductView>();
    if(salesProductRelationships.containskey(products.containsKey(selectedProduct)?products.get(selectedProduct).Id : '')){
      for (CatalogUtils.RelationshipView r : salesProductRelationships.get(products.get(selectedProduct).Id)){
        if(r.childRelationships.size() == 0){
          if(r.secondarySalesProductID != null && !r.negativeRelationship && products.containskey(integer.valueof(r.secondarySalesProductExternalID))){
            initialProductProductRelationships.put(r.id,r);
            initialProductProductRequirements.put(r.id,products.get(integer.valueof(r.secondarySalesProductExternalID)));
          }
          else if(r.secondarySalesProductID != null && r.negativeRelationship && products.containskey(integer.valueof(r.secondarySalesProductExternalID))){
            initialInvalidProductProductRelationships.put(r.id,r);
            initialInvalidProductProductRequirements.put(r.id,products.get(integer.valueof(r.secondarySalesProductExternalID)));
          }
        }
      }
    }
    
    //return prodViews;
  }

  //Get Component Related Items
  public static void getComponentRelationships(Map<Id,List<CatalogUtils.RelationshipView>> salesProductRelationships, Map<Id,List<CatalogUtils.RelationshipView>> salesProductComponentRelationships, Map<integer,CatalogUtils.SalesProductView> products, integer selectedProduct, Map<id,List<CatalogUtils.PricingView>> pricing,
    Map<string,CatalogUtils.RelationshipView> initialProductComponentRelationships,
    Map<string,List<CatalogUtils.PricingView>> initialProductComponentRequirements,
    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalProductRelationships,
    Map<string,List<CatalogUtils.SalesProductView>> conditionalProductRequirements,
    Map<string,Map<String,CatalogUtils.RelationshipView>> conditionalProductComponentRelationships,
    Map<string,List<CatalogUtils.PricingView>> conditionalProductComponentRequirements,
    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalInvalidProductProductRelationships,
    Map<string,List<CatalogUtils.SalesProductView>> conditionalInvalidProductProductRequirements,
    Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalInvalidProductComponentRelationships,
    Map<string,List<CatalogUtils.PricingView>> conditionalInvalidProductComponentRequirements,
    Map<id,List<id>> conditionalValidProductPricing,
    Map<id,List<id>> conditionalInvalidProductPricing,
    List<CatalogUtils.PricingView> alreadyRelatedPricing,
    List<CatalogUtils.RelationshipView> secondaryPricingRelationships){
    //Map<CatalogUtils.RelationshipView,List<CatalogUtils.PricingView>> relatedPricing = new Map<CatalogUtils.RelationshipView,List<CatalogUtils.PricingView>>();
    

    List<id> invalidProductPricing = new List<id>();
    List<id> validProductPricing = new List<id>();
    
    for(CatalogUtils.RelationshipView r : secondaryPricingRelationships){
      id productId = r.primarySalesProductID;
      if(r.negativeRelationship){
        if(conditionalInvalidProductPricing.containsKey(productId)){
          List<id> pricingids = conditionalInvalidProductPricing.get(productId);
          pricingids.add(r.secondaryPriceID);
          conditionalInvalidProductPricing.put(productId,pricingids);
        }
        else
          conditionalInvalidProductPricing.put(productId,new List<id>{r.secondaryPriceID});
      }
      else{
        if(conditionalValidProductPricing.containsKey(productId)){
          List<id> pricingids = conditionalValidProductPricing.get(productId);
          pricingids.add(r.secondaryPriceID);
          conditionalValidProductPricing.put(productId,pricingids);
        }
        else
          conditionalValidProductPricing.put(productId,new List<id>{r.secondaryPriceID});
      }

    }

    if(salesProductRelationships.containskey(products.get(selectedProduct).Id)){
      for (CatalogUtils.RelationshipView r : salesProductRelationships.get(products.get(selectedProduct).Id)){
        if(r.childRelationships.size() > 0){
          List<CatalogUtils.PricingView> requiredPricing = new List<CatalogUtils.PricingView>();
          for (CatalogUtils.RelationshipView rc : r.childRelationships){
            if (rc.primarySalesProductComponentID != null && pricing.get(rc.primarySalesProductComponentID) != null){
              requiredPricing.addAll(pricing.get(rc.primarySalesProductComponentID));
            } 
          }

          

          //Get all requirements based on something already in the required list
          for (CatalogUtils.PricingView pv : requiredPricing){
            List<CatalogUtils.RelationshipView> spcR = salesProductComponentRelationships.get(pv.spcComponentID);
            if (spcR != null){
              for (CatalogUtils.RelationshipView r2 : spcR){
                List<CatalogUtils.PricingView> relatedPricing2 = new List<CatalogUtils.PricingView>();
                List<CatalogUtils.SalesProductView> relatedProducts2 = new List<CatalogUtils.SalesProductView>();
                List<CatalogUtils.PricingView> invalidPricing2 = new List<CatalogUtils.PricingView>();
                List<CatalogUtils.SalesProductView> invalidProducts2 = new List<CatalogUtils.SalesProductView>();
                
                //Get Child related items
                for(CatalogUtils.RelationshipView rc2 : r2.childRelationships){
                  if(rc2.primarySalesProductComponentID != null && pricing.get(rc2.primarySalesProductComponentID) != null){
                    relatedPricing2.addAll(pricing.get(rc2.primarySalesProductComponentID));
                  }

                  
                  if(salesProductComponentRelationships.get(rc2.primarySalesProductComponentID) != null){
                    for(CatalogUtils.RelationshipView spcR2 : salesProductComponentRelationships.get(rc2.primarySalesProductComponentID)){
                      //relatedPricing2.addAll(pricing.get(spcR2.secondarySalesProductComponentID));
                      if(conditionalProductComponentRelationships.containskey(spcR2.primarySalesProductComponentID)){
                        Map<string,CatalogUtils.RelationshipView> rs = conditionalProductComponentRelationships.get(spcR2.primarySalesProductComponentID);
                        rs.put(spcR2.id,spcR2);
                        conditionalProductComponentRelationships.put(spcR2.primarySalesProductComponentID,rs);
                      }
                      else{
                        conditionalProductComponentRelationships.put(spcR2.primarySalesProductComponentID,new Map<string,CatalogUtils.RelationshipView>{spcR2.id=>spcR2});
                      }

                      conditionalProductComponentRequirements.put(spcR2.id,pricing.get(spcR2.secondarySalesProductComponentID));
                      if(pricing.containsKey(spcR2.SecondarySalesProductComponentID)) alreadyRelatedPricing.addAll(pricing.get(spcR2.secondarySalesProductComponentID));
                    }  
                  }
                }
                //Get required items
                if(r2.secondarySalesProductComponentID != null && pricing.containsKey(r2.secondarySalesProductComponentID))
                  if(r2.negativeRelationship)
                    invalidPricing2.addAll(pricing.get(r2.secondarySalesProductComponentID));
                  else
                    relatedPricing2.addAll(pricing.get(r2.secondarySalesProductComponentID));

                if(r2.secondarySalesProductID != null)
                  if(r2.negativeRelationship)
                    invalidProducts2.add(products.get(integer.valueof(r2.secondarySalesProductExternalID)));
                  else
                    relatedProducts2.add(products.get(integer.valueof(r2.secondarySalesProductExternalID)));
                
                if(relatedPricing2.size() > 0){
                  if(conditionalProductComponentRelationships.containskey(pv.spcComponentID)){
                    Map<string,CatalogUtils.RelationshipView> rs = conditionalProductComponentRelationships.get(pv.spcComponentID);
                    rs.put(r2.id,r2);
                    conditionalProductComponentRelationships.put(pv.spcComponentID,rs);
                  }
                  else{
                    conditionalProductComponentRelationships.put(pv.spcComponentID,new Map<string,CatalogUtils.RelationshipView>{r2.id=>r2});
                  }

                  conditionalProductComponentRequirements.put(r2.id,relatedPricing2);


                  for (CatalogUtils.PricingView rp2: relatedPricing2){
                    List<CatalogUtils.RelationshipView> spcR2 = salesProductComponentRelationships.get(rp2.spcComponentID);
                    if (spcR2 != null){
                      for (CatalogUtils.RelationshipView r22 : spcR2){
                        List<CatalogUtils.SalesProductView> relatedProducts22 = new List<CatalogUtils.SalesProductView>();
                        List<CatalogUtils.SalesProductView> invalidProducts22 = new List<CatalogUtils.SalesProductView>();
                        if(r22.secondarySalesProductID != null)
                          if(r22.negativeRelationship)
                          invalidProducts22.add(products.get(integer.valueof(r22.secondarySalesProductExternalID)));
                        else
                          relatedProducts22.add(products.get(integer.valueof(r22.secondarySalesProductExternalID)));

                        if(relatedProducts22.size() > 0){
                          if(conditionalProductRelationships.containskey(rp2.spcComponentID)){
                            Map<string,CatalogUtils.RelationshipView> rs = conditionalProductRelationships.get(rp2.spcComponentID);
                            rs.put(r22.id,r22);
                            conditionalProductRelationships.put(rp2.spcComponentID,rs);
                          }
                          else{
                            conditionalProductRelationships.put(rp2.spcComponentID,new Map<string,CatalogUtils.RelationshipView>{r22.id=>r22});
                          }

                          conditionalProductRequirements.put(r22.id,relatedProducts22);
                        }

                        if(invalidProducts22.size() > 0){
                          if(conditionalInvalidProductProductRelationships.containskey(rp2.spcComponentID)){
                            Map<string,CatalogUtils.RelationshipView> rs = conditionalInvalidProductProductRelationships.get(rp2.spcComponentID);
                            rs.put(r22.id,r22);
                            conditionalInvalidProductProductRelationships.put(rp2.spcComponentID,rs);
                          }
                          else{
                            conditionalInvalidProductProductRelationships.put(rp2.spcComponentID,new Map<string,CatalogUtils.RelationshipView>{r22.id=>r22});
                          }

                          conditionalInvalidProductProductRequirements.put(r22.id,invalidProducts22);
                        }

                      }
                    }

                    

                  }
                }

                if(relatedProducts2.size() > 0){
                  if(conditionalProductRelationships.containskey(pv.spcComponentID)){
                    Map<string,CatalogUtils.RelationshipView> rs = conditionalProductRelationships.get(pv.spcComponentID);
                    rs.put(r2.id,r2);
                    conditionalProductRelationships.put(pv.spcComponentID,rs);
                  }
                  else{
                    conditionalProductRelationships.put(pv.spcComponentID,new Map<string,CatalogUtils.RelationshipView>{r2.id=>r2});
                  }

                  conditionalProductRequirements.put(r2.id,relatedProducts2);
                }
                              
                
              
                
                if(invalidProducts2.size() > 0){
                  if(conditionalInvalidProductProductRelationships.containskey(pv.spcComponentID)){
                    Map<string,CatalogUtils.RelationshipView> rs = conditionalInvalidProductProductRelationships.get(pv.spcComponentID);
                    rs.put(r2.id,r2);
                    conditionalInvalidProductProductRelationships.put(pv.spcComponentID,rs);
                  }
                  else{
                    conditionalInvalidProductProductRelationships.put(pv.spcComponentID,new Map<string,CatalogUtils.RelationshipView>{r2.id=>r2});
                  }

                  conditionalInvalidProductProductRequirements.put(r2.id,invalidProducts2);
                }

                if(invalidPricing2.size() > 0){
                  if(conditionalInvalidProductComponentRelationships.containskey(pv.spcComponentID)){
                    Map<string,CatalogUtils.RelationshipView> rs = conditionalInvalidProductComponentRelationships.get(pv.spcComponentID);
                    rs.put(r2.id,r2);
                    conditionalInvalidProductComponentRelationships.put(pv.spcComponentID,rs);
                  }
                  else{
                    conditionalInvalidProductComponentRelationships.put(pv.spcComponentID,new Map<string,CatalogUtils.RelationshipView>{r2.id=>r2});
                  }

                  conditionalInvalidProductComponentRequirements.put(r2.id,invalidPricing2);
                }
                
                
                

                alreadyRelatedPricing.addall(relatedPricing2);
              }
            }
          }

          alreadyRelatedPricing.addAll(requiredPricing);
          ApexUtils.SortBy(requiredPricing, new List<String>{'ComponentName'});
        
          if(requiredPricing.size() > 0){
            initialProductComponentRelationships.put(r.id,r);
            initialProductComponentRequirements.put(r.id,requiredPricing);
          }
        }
      }
    }
    //return relatedPricing;
  }

  //Get Optional Pricing
  public static void getOptionalRemainingPricing(List<CatalogUtils.PricingView> alreadyRelatedPricing, Map<id,List<CatalogUtils.PricingView>> pricing, Map<Id,List<CatalogUtils.RelationshipView>> salesProductComponentRelationships,
    Map<string, CatalogUtils.RelationshipView> optionalPricingRelationships,
    Map<String,Map<string,List<CatalogUtils.PricingView>>> optionalPricing){
    //Map<String,Map<CatalogUtils.RelationshipView,List<CatalogUtils.PricingView>>> orp = new Map<String,Map<CatalogUtils.RelationshipView,List<CatalogUtils.PricingView>>>();
    
    set<string> alreadyRelatedPriceIds = new set<string>();
    for(CatalogUtils.PricingView pv : alreadyRelatedPricing){
      alreadyRelatedPriceIds.add(pv.priceid);
    }
    
    List<CatalogUtils.RelationshipView> defaultRelationshipView = new List<CatalogUtils.RelationshipView>{new CatalogUtils.RelationshipView(new SPC_Relationship__c())};
            
    for(id key :pricing.keyset()){
      for(CatalogUtils.PricingView pv : pricing.get(key)){
        if(!alreadyRelatedPriceIds.contains(pv.priceid)){
          List<CatalogUtils.RelationshipView> rs = null;
          if(salesProductComponentRelationships.containsKey(pv.spcComponentID))
            rs = salesProductComponentRelationships.get(pv.spcComponentID);
          else
            rs = defaultRelationshipView;
          for(CatalogUtils.RelationshipView r : rs){
            if(optionalPricing.containsKey(pv.componentgroup)){
              if(optionalPricing.get(pv.componentgroup).containsKey(r.id)){
                Map<string,List<CatalogUtils.PricingView>> relationshipPricing = optionalPricing.get(pv.componentgroup);
                List<CatalogUtils.PricingView> pvs = relationshipPricing.get(r.id);
                pvs.add(pv);
                relationshipPricing.put(r.id,pvs);
                optionalPricingRelationships.put(r.id,r);
                optionalPricing.put(pv.componentgroup,relationshipPricing);
              }
              else{
                optionalPricingRelationships.put(r.id,r);
                optionalPricing.put(pv.componentgroup,new Map<string,List<CatalogUtils.PricingView>>{r.id=>new List<CatalogUtils.PricingView>{pv}});
              }
            
            }
            else{
              optionalPricingRelationships.put(r.id,r);
              optionalPricing.put(pv.componentgroup,new Map<string,List<CatalogUtils.PricingView>>{r.id=>new List<CatalogUtils.PricingView>{pv}});
            }
          }
        }
      }
    }

    //return orp;
  }

  private static Map<string,OLI__c> GetAllOLIs(List<UIProdView> pvs){
    Map<string,OLI__c> oliMap = new Map<string,OLI__c>();
    for(UIProdView pv : pvs){
      oliMap.put(pv.UUID,pv.oli);
      oliMap.putAll(GetAllOLIs(pv.Children));
    }
    system.debug('olimap: ' + oliMap.size());
    return oliMap;
  }

  private static List<OLI__c> SetChildrenOLIs(UIProdView parent, List<UIProdView> pvs, Map<string,OLI__c> olis){
    List<OLI__c> childolis = new List<OLI__c>();
    Decimal count = 0;
    for(UIProdView pv : pvs){
      childolis.addAll(SetChildrenOLIs(pv, pv.Children, olis));
      if(parent != null){
        OLI__c cOli = olis.get(pv.UUID);
        system.debug('oliId: ' + pv.oli.id);
        system.debug('cOli: ' + cOli);
        count += 0.1;
        cOli.Config_Parent__c = parent.oli.id;
        cOli.Display_Order__c = parent.oli.Display_Order__c + count;
        childolis.add(cOli);
      }
    }
    system.debug('childolis: ' + childolis.size());
    return childolis;
  }

  @RemoteAction
  public static string UpsertOLIs(string prods,string solutionId, string locId/*, List<string> existingOLIIds*/){
    Map<string,OLI__c> olis = new Map<string,OLI__c>();
    List<OLI__c> configChildren = new List<OLI__c>();
    List<UIProdView> prodViews = (List<UIProdView>)JSON.deserialize(prods,List<UIProdView>.class);
    olis = GetAllOLIs(prodViews);
    system.debug(olis.keyset());
    //for(UIProdView pv : prodViews){
      //system.debug('OLI: ' + pv.oli);
      //olis.put(pv.UUID,pv.oli);
      //for(UIProdView pvc : pv.Children){
        //olis.put(pvc.UUID,pvc.oli);
      //}
    //}
    
    if(olis.size() > 0)
      upsert olis.values();

    //add config parent
    configChildren = SetChildrenOLIs(null, prodViews, olis);
    //for(UIProdView pv : prodViews){
      //for(UIProdView pvc : pv.Children){
        //OLI__c cOli = olis.get(pvc.UUID);
        //cOli.Config_Parent__c = pv.oli.id;
        //configChildren.add(cOli);
      //}
    //}

    if(configChildren.size() > 0)
      upsert configChildren;

    set<id> currentOlis = new set<id>();
    boolean hasDLProduct = false; 
    for(oli__c oli : olis.values()){
      currentOlis.add(oli.id);
      if(!hasDLProduct && oli.SPC_Feature_Group__c == 'Directory Listings'){
        hasDLProduct = true;        
      }
    }

    //Get existing olis:
    List<OLI__c> existingOlis = [Select Id,(Select Id From Opportunity_Line_Items__r) From OLI__c Where OpportunityLocationConfiguration__c = :solutionId  and PP_Package_Feature__c = false];
    List<OLI__c> olisToDelete = new List<OLI__c>();
    for(OLI__c oli: existingOlis){
      if(!currentOlis.contains(oli.id)){
        olisToDelete.add(oli);
        for(OLI__c cOli : oli.Opportunity_Line_Items__r)
          olisToDelete.add(cOli);
      }
    }
    if(olisToDelete.size() > 0)
      delete olisToDelete;
      
    //Check Directory Listing Techinical Information
    Id tiId = null;
    boolean hasDLTIs = false;        
    RecordType rt = [select Id, Name from RecordType where DeveloperName = 'Directory_Listing' LIMIT 1];
    List<Technical_Information__c> existingTIs = [select Id from Technical_Information__c where RecordTypeID = :rt.Id and Opportunity_Site__c = :locId];
    if(existingTIs.size() > 0){    
        hasDLTIs = true;
    }

    if(hasDLProduct){
        boolean canCreateDL = false;
        if(hasDLTIs){    
            Set<Id> tiIds = new Set<Id>();
            for(Technical_Information__c ti : existingTIs)
            {
                tiIds.add(ti.Id);
            }
            
            Map<Id, List<Directory_Listing__c>> existingDLs = new Map<Id, List<Directory_Listing__c>>();
            for(Directory_Listing__c existing : [select Technical_Information__c,Id from Directory_Listing__c where Technical_Information__c in :tiIds]){
               if(existingDLs.containsKey(existing.Technical_Information__c)){
                  List<Directory_Listing__c> dl = existingDLs.get(existing.Technical_Information__c);
                  dl.add(existing);
               }else{
                  existingDLs.put(existing.Technical_Information__c,new List<Directory_Listing__c>{existing});
               }
            }
            
            for(Technical_Information__c ti : existingTIs)
            {
                system.debug('EJDEBUG ti.Id:'+ti.Id);
                system.debug('EJDEBUG existingDLs.containsKey(ti.Id):'+existingDLs.containsKey(ti.Id));
                //system.debug('EJDEBUG existingDLs.get(ti.Id).size():'+existingDLs.get(ti.Id).size());
                
                if(!existingDLs.containsKey(ti.Id) ||(existingDLs.containsKey(ti.Id) && existingDLs.get(ti.Id).size() <= 0)){
                    canCreateDL = true;
                    tiId = ti.Id;                   
                }
            }
        }else{
            Technical_Information__c techDL = new Technical_Information__c(RecordTypeID = rt.Id, Name= rt.Name, Opportunity_Site__c = locId);
            insert techDL;  
            canCreateDL = true;
            tiId =  techDL.Id;      
        }
        if(canCreateDL){
            Opportunity_Location__c oppLoc = [SELECT Id, Service_Location__r.Name, Service_Location__r.Phone__c, Service_Location__r.Location__r.Building__r.Address__c,
                                                    Service_Location__r.Location__r.Building__R.Serving_LSO__r.LSO_CLLI__c,Service_Location__r.Location__r.Building__r.City__c, Service_Location__r.Location__r.Building__r.State__c,
                                                    Service_Location__r.Location__r.Building__r.Postal_Code__c,Service_Location__r.Location__r.Name, Order__r.Opportunity__r.Id, Service_Location__r.Location__r.Building__r.Market_Area_Name__c FROM Opportunity_Location__c WHERE Id = :locId];
            
            Directory_Listing__c dl = new Directory_Listing__c(Technical_Information__c=tiId, Type__c='Complimentary Listing');
            dl.Company_Name__c = oppLoc.Service_Location__r.Name;
            dl.Address__c = oppLoc.Service_Location__r.Location__r.Building__r.Address__c;
            dl.City__c = oppLoc.Service_Location__r.Location__r.Building__r.City__c;
            dl.State__c = oppLoc.Service_Location__r.Location__r.Building__r.State__c;
            dl.Zip__c = oppLoc.Service_Location__r.Location__r.Building__r.Postal_Code__c;
            dl.Listing_Telephone_Number__c = oppLoc.Service_Location__r.Phone__c;
            //dl.Main_Listing__c = true; // Commented out because of SEAL-1514
            insert dl;          
        }
    }else{
        if(hasDLTIs){
            delete existingTIs;
        }       
    }
    
    return JSON.serialize(prodViews,true);
  }

    public Map<Id,OLIView> GetOLIs(){
    Map<Id,OLIView> olis = new Map<Id,OLIView>();
    Map<Id,OLI__c> oliMap =  new Map<Id,OLI__c>([Select     AccessTechName__c
                      ,Active__c
                      ,Approval_Status__c
                      ,Approved__c
                      ,BandWidth__c
                      ,Config_Parent__c
                      ,DQ__c
                      ,Group_Name__c
                      ,Id
                      ,MRC__c
                      ,MRC_Discount__c
                      ,MRC_Floor__c
                      ,MRC_Floor_Total__c
                      ,MRC_List_Total__c
                      ,MRC_Total__c
                      ,MRCList__c
                      ,NAA_Total__c
                      ,Name
                      ,NRC__c
                      ,NRC_Discount__c
                      ,NRC_Floor__c
                      ,NRC_Total__c
                      ,NRCList__c
                      ,Off_Footprint__c
                      ,Off_Footprint_Approved__c
                      ,OLI_Score__c
                      ,OpportunityLocationConfiguration__c
                      ,Parent_Opportunity_Line_Item__c
                      ,Parent_Relationship__c
                      ,Parent_Relationship__r.Auto_Include__c
                      ,ParentName__c
                      ,PP_AdditionalInformationPrompt__c
                      ,PP_Feature_Group__c
                      ,PP_Feature_Grouping_Sort__c
                      ,PP_LD_Interstate__c
                      ,PP_LD_Intrastate__c
                      ,PP_NAA_Percent__c
                      ,PP_Package__c
                      ,PP_Package_Feature__c
                      ,PP_Per_Account__c
                      ,PP_Product_Family__c
                      ,PP_Product_Family_Sort__c
                      ,PP_Product_Grouping__c
                      ,PP_Product_Pricing_Name__c
                      ,PP_Sales_Product__c
                      ,PP_Sales_Product_Sort__c
                      ,PP_Sales_Rate_Plan_Description__c
                      ,PP_Sales_Rate_Plan_Description_Sort__c
                      ,PP_SalesProductExternalID__c
                      ,PP_SalesProductRatePlanExternalID__c
                      ,PP_SalesRatePlanPricingExternalID__c
                      ,PP_ServiceAgreementText__c
                      ,PP_Toll_Free__c
                      ,PP_Voice_Line__c
                      ,PP_Voice_Line_Option__c
                      ,Price_Id__c
                      ,Product_Family_Id__c
                      ,Product_Family_Product__c
                      ,Product_Pricing__c
                      ,Qty__c
                      ,Secondary_Location__c
                      ,Secondary_Location__r.Id
                      ,Secondary_Location__r.Name
                      ,Secondary_Service_Location__c
                      ,Secondary_Service_Location__r.Id
                      ,Secondary_Service_Location__r.Name
                      ,SPC_Component__c
                      ,SPC_Feature_Group__c
                      ,SPC_MaxQty__c
                      ,SPC_MinQty__c
                      ,SPC_MRC_Is_Quote__c
                      ,SPC_MRC_OnNet__c
                      ,SPC_NRC_Is_Quote__c
                      ,SPC_Sales_Product__c
                      ,SPC_Sales_Product__r.Name
                      ,SPC_Sales_Product__r.SalesProductExternalID__c
                      ,SPC_Sales_Product__r.Z_Location_Type__c
                      ,SPC_Sales_Product_Component_Id__c
                      ,SPC_Sales_Selection_Rule_Name__c
                      ,SystemModstamp
                      ,Tag__c
                      ,Tag_Name__c
                      ,Display_Order__c
                      ,(Select Id From Opportunity_Line_Items__r)
                      //,(select AccessTechName__c
                        //,Active__c
                        //,Approval_Status__c
                        //,Approved__c
                        //,BandWidth__c
                        //,Config_Parent__c
                        //,DQ__c
                        //,Group_Name__c
                        //,Id
                        //,MRC__c
                        //,MRC_Discount__c
                        //,MRC_Floor__c
                        //,MRC_Floor_Total__c
                        //,MRC_List_Total__c
                        //,MRC_Total__c
                        //,MRCList__c
                        //,NAA_Total__c
                        //,Name
                        //,NRC__c
                        //,NRC_Discount__c
                        //,NRC_Floor__c
                        //,NRC_Total__c
                        //,NRCList__c
                        //,Off_Footprint__c
                        //,Off_Footprint_Approved__c
                        //,OLI_Score__c
                        //,OpportunityLocationConfiguration__c
                        //,Parent_Opportunity_Line_Item__c
                        //,Parent_Relationship__c
                        //,Parent_Relationship__r.Auto_Include__c
                        //,ParentName__c
                        //,PP_AdditionalInformationPrompt__c
                        //,PP_Feature_Group__c
                        //,PP_Feature_Grouping_Sort__c
                        //,PP_LD_Interstate__c
                        //,PP_LD_Intrastate__c
                        //,PP_NAA_Percent__c
                        //,PP_Package__c
                        //,PP_Package_Feature__c
                        //,PP_Per_Account__c
                        //,PP_Product_Family__c
                        //,PP_Product_Family_Sort__c
                        //,PP_Product_Grouping__c
                        //,PP_Product_Pricing_Name__c
                        //,PP_Sales_Product__c
                        //,PP_Sales_Product_Sort__c
                        //,PP_Sales_Rate_Plan_Description__c
                        //,PP_Sales_Rate_Plan_Description_Sort__c
                        //,PP_SalesProductExternalID__c
                        //,PP_SalesProductRatePlanExternalID__c
                        //,PP_SalesRatePlanPricingExternalID__c
                        //,PP_ServiceAgreementText__c
                        //,PP_Toll_Free__c
                        //,PP_Voice_Line__c
                        //,PP_Voice_Line_Option__c
                        //,Price_Id__c
                        //,Product_Family_Id__c
                        //,Product_Family_Product__c
                        //,Product_Pricing__c
                        //,Qty__c
                        //,Secondary_Location__c
                        //,Secondary_Location__r.Id
                        //,Secondary_Location__r.Name
                        //,Secondary_Service_Location__c
                        //,Secondary_Service_Location__r.Id
                        //,Secondary_Service_Location__r.Name
                        //,SPC_Component__c
                        //,SPC_Feature_Group__c
                        //,SPC_MaxQty__c
                        //,SPC_MinQty__c
                        //,SPC_MRC_Is_Quote__c
                        //,SPC_MRC_OnNet__c
                        //,SPC_NRC_Is_Quote__c
                        //,SPC_Sales_Product__c
                        //,SPC_Sales_Product__r.Name
                        //,SPC_Sales_Product__r.SalesProductExternalID__c
                        //,SPC_Sales_Product__r.Z_Location_Type__c
                        //,SPC_Sales_Product_Component_Id__c
                        //,SPC_Sales_Selection_Rule_Name__c
                        //,SystemModstamp
                        //,Tag__c
                        //,Tag_Name__c 
                      //from Config_Children__r)
                  From OLI__C 
                  Where OpportunityLocationConfiguration__c = :configId
                  and PP_Package_Feature__c = false Order by Product_Family_Product__c desc, Display_Order__c desc]);
        
    Map<Id,OLI__c> oliConfigChildren = new Map<Id,OLI__c>();
    for(OLI__c oli: oliMap.values()){  
      if(oli.Config_Parent__c != null){
        oliConfigChildren.put(oli.id,oli);
      }
      if(string.isEmpty(oli.Group_Name__c)) oli.Group_Name__c = 'Default1';
    }


    for(OLI__c oli: oliMap.values()){
      system.debug('OLI: ' + oli);
      OLIView oView = new OLIView(oli);
      addChildren(oView, oliConfigChildren);
      olis.put(oli.id,oView);
    }
    return olis;
  }

  private void addChildren(OLIView oliv, Map<Id, OLI__c> children){
    for(OLI__c oli : children.values()){
        if(oli.Config_Parent__c == oliv.oli.id){
        OLIView oView = new OLIView(oli);
        addChildren(oView, children);
        oliv.configChildren.add(oView);
      }
    }
  }

  public string getPricingForConfiguredProducts(){
    
    Map<id,integer> productIds = new Map<id,integer>();
    List<String> OLIPriceIds = new List<String>();
    for(OLIView ov : existingOLIs.values()){
      if(!productIds.containsKey(ov.OLI.SPC_Sales_Product__c))
        productIds.put(ov.OLI.SPC_Sales_Product__c,integer.valueof(ov.OLI.SPC_Sales_Product__r.SalesProductExternalID__c));
      system.debug('priceId: ' + ov.OLI.Price_Id__c);
      OLIPriceIds.add(ov.OLI.Price_Id__c);
    }
    Map<integer,CatalogUtils.SalesProductView> products = CatalogUtils.GetProducts(market,terms,disableValidations);
    Map<Integer,Map<Id,List<CatalogUtils.PricingView>>> pricing = CatalogUtils.GetSalesProductComponentPricing2(market,productIds.values(),terms, opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.EoF_Competitive_Building__c);
    Map<Integer,List<CatalogUtils.RelationshipView>> productRelationships = new Map<Integer,List<CatalogUtils.RelationshipView>>();
    for(id prodId : productIds.keyset()){
      if(pricing.get(productIds.get(prodId)) == null) pricing.put(productIds.get(prodId),new Map<Id,List<CatalogUtils.PricingView>>());
      productRelationships.put(productIds.get(prodId),CatalogUtils.GetRelationships(pricing.get(productIds.get(prodId)),prodId));
    }

    Map<string,Map<string,Object>> MstrObj = new Map<String,Map<String,Object>>();
    for(id prodId : productIds.keyset()){ system.debug(prodId);
      if(prodId == null || products.get(productIds.get(prodId)) == null) continue;
      Map<string,CatalogUtils.RelationshipView> initialProductProductRelationships = new Map<string,CatalogUtils.RelationshipView>();
      Map<string,CatalogUtils.SalesProductView> initialProductProductRequirements = new Map<string,CatalogUtils.SalesProductView>();
      Map<string,CatalogUtils.RelationshipView> initialInvalidProductProductRelationships = new Map<string,CatalogUtils.RelationshipView>();
      Map<string,CatalogUtils.SalesProductView> initialInvalidProductProductRequirements = new Map<string,CatalogUtils.SalesProductView>();
  
      Map<string,CatalogUtils.RelationshipView> initialProductComponentRelationships = new Map<string,CatalogUtils.RelationshipView>();
      Map<string,List<CatalogUtils.PricingView>> initialProductComponentRequirements = new Map<string,List<CatalogUtils.PricingView>>();
  
      Map<string, CatalogUtils.RelationshipView> optionalPricingRelationships = new Map<string, CatalogUtils.RelationshipView>();
      Map<String,Map<string,List<CatalogUtils.PricingView>>> optionalPricing = new Map<String,Map<string,List<CatalogUtils.PricingView>>>();

      Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalProductRelationships = new Map<string,Map<string,CatalogUtils.RelationshipView>>();
      Map<string,List<CatalogUtils.SalesProductView>> conditionalProductRequirements = new Map<string,List<CatalogUtils.SalesProductView>>();

      Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalProductComponentRelationships = new Map<string,Map<string,CatalogUtils.RelationshipView>>();
      Map<string,List<CatalogUtils.PricingView>> conditionalProductComponentRequirements = new Map<string,List<CatalogUtils.PricingView>>();

      Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalInvalidProductProductRelationships = new Map<string,Map<string,CatalogUtils.RelationshipView>>();
      Map<string,List<CatalogUtils.SalesProductView>> conditionalInvalidProductProductRequirements = new Map<string,List<CatalogUtils.SalesProductView>>();

      //may not need these
      Map<string,Map<string,CatalogUtils.RelationshipView>> conditionalInvalidProductComponentRelationships = new Map<string,Map<string,CatalogUtils.RelationshipView>>();
      Map<string,List<CatalogUtils.PricingView>> conditionalInvalidProductComponentRequirements = new Map<string,List<CatalogUtils.PricingView>>();

      Map<id,List<id>> conditionalValidProductPricing = new Map<id,List<id>>();
      Map<id,List<id>> conditionalInvalidProductPricing = new Map<id,List<id>>();
    
      List<CatalogUtils.PricingView> alreadyRelatedPricing = new List<CatalogUtils.PricingView>();


      Map<Id,List<CatalogUtils.RelationshipView>> salesProductRelationships = new Map<Id,List<CatalogUtils.RelationshipView>>();
      Map<Id,List<CatalogUtils.RelationshipView>> salesProductComponentRelationships = new Map<Id,List<CatalogUtils.RelationshipView>>();
      set<id> crossProductComponentPricingNeeded = new set<id>();

      for(CatalogUtils.RelationshipView r : productRelationships.get(productIds.get(prodId))){
        if(r.primarySalesProductID != null){
          if(salesProductRelationships.containskey(r.primarySalesProductID)){
            List<CatalogUtils.RelationshipView> rs = salesProductRelationships.get(r.primarySalesProductID);
            rs.add(r);
            salesProductRelationships.put(r.primarySalesProductID,rs);
          }
          else{
            salesProductRelationships.put(r.primarySalesProductID, new List<CatalogUtils.RelationshipView>{r});
          }
        }
        else if(r.primarySalesProductComponentID != null && r.parentRelationshipID == null){
          if(r.secondarySalesProductComponentID != null && r.secondarySalesProductComponentSalesProductExternalID != productIds.get(prodId))
            crossProductComponentPricingNeeded.add(r.secondarySalesProductComponentID);

          if(salesProductComponentRelationships.containskey(r.primarySalesProductComponentID)){
            List<CatalogUtils.RelationshipView> rs = salesProductComponentRelationships.get(r.primarySalesProductComponentID);
            rs.add(r);
            salesProductComponentRelationships.put(r.primarySalesProductComponentID,rs);
          }
          else{
            salesProductComponentRelationships.put(r.primarySalesProductComponentID, new List<CatalogUtils.RelationshipView>{r});
          }
        }
      }

      List<id> priceIds = new List<id>();
      for(id key : pricing.get(productIds.get(prodId)).keyset()){
        for(CatalogUtils.PricingView pv : pricing.get(productIds.get(prodId)).get(key)){
          priceIds.add(pv.id);
        }
      }
      List<CatalogUtils.RelationshipView> secondaryPricingRelationships = CatalogUtils.GetRelationshipsByPriceIds(priceIds);


      //get pricing for any relationship where the product is not the selected product(any related component on another product)
      pricing.get(productIds.get(prodId)).putall(CatalogUtils.GetSalesProductComponentPricingByComponentIds(market,crossProductComponentPricingNeeded,terms, opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.EoF_Competitive_Building__c));

      //get relationships
    
      getProductProductRelationships(salesProductRelationships, products, productIds.get(prodId), initialProductProductRelationships, initialProductProductRequirements,initialInvalidProductProductRelationships, initialInvalidProductProductRequirements);
      getComponentRelationships(salesProductRelationships, salesProductComponentRelationships, products, productIds.get(prodId),pricing.get(productIds.get(prodId)),
        initialProductComponentRelationships,
        initialProductComponentRequirements,
        conditionalProductRelationships,
        conditionalProductRequirements,
        conditionalProductComponentRelationships,
        conditionalProductComponentRequirements,
        conditionalInvalidProductProductRelationships,
        conditionalInvalidProductProductRequirements,
        conditionalInvalidProductComponentRelationships,
        conditionalInvalidProductComponentRequirements,
        conditionalValidProductPricing,
        conditionalInvalidProductPricing,
        alreadyRelatedPricing,
        secondaryPricingRelationships);
      getOptionalRemainingPricing(alreadyRelatedPricing,pricing.get(productIds.get(prodId)),salesProductComponentRelationships,
        optionalPricingRelationships,
        optionalPricing);

      Map<string,Object> subMstrObj = new Map<string,Object>();
      subMstrObj.put('IniProdCompReqs',initialProductComponentRequirements);
      subMstrObj.put('IniProdCompRels',initialProductComponentRelationships);
      subMstrObj.put('IniProdProdReqs',initialProductProductRequirements);
      subMstrObj.put('IniProdProdRels',initialProductProductRelationships);
      subMstrObj.put('IniInvalidProdProdReqs',initialInvalidProductProductRequirements);
      subMstrObj.put('IniInvalidProdProdRels',initialInvalidProductProductRelationships);
      subMstrObj.put('OptionalPricing',optionalPricing);
      subMstrObj.put('OptionalPricingRels',optionalPricingRelationships);
      subMstrObj.put('ConditionalProdReqs',conditionalProductRequirements);
      subMstrObj.put('ConditionalProdRels',conditionalProductRelationships);
      subMstrObj.put('ConditionalInvalidProdProdReqs',conditionalInvalidProductProductRequirements);
      subMstrObj.put('ConditionalInvalidProdProdRels',conditionalInvalidProductProductRelationships);
      subMstrObj.put('ConditionalInvalidProdCompReqs',conditionalInvalidProductComponentRequirements);
      subMstrObj.put('ConditionalInvalidProdCompRels',conditionalInvalidProductComponentRelationships);
      subMstrObj.put('ConditionalValidProductPricing',conditionalValidProductPricing);
      subMstrObj.put('conditionalInvalidProductPricing',conditionalInvalidProductPricing);
      subMstrObj.put('conditionalProductComponentRelationships',conditionalProductComponentRelationships);    
      subMstrObj.put('conditionalProductComponentRequirements',conditionalProductComponentRequirements);
      subMstrObj.put('ExpiredPricing',CatalogUtils.GetExpiredPricing(OLIPriceIds));
      //subMstrObj.put('AlreadyRelatedPricing',alreadyRelatedPricing);

      MstrObj.put(products.get(productIds.get(prodId)).name, subMstrObj);

    }
    
    system.debug('MstrObj: ' + MstrObj);
    return JSON.serialize(MstrObj,true);
  }

  public void getSecLocSelections(Id accountId){
    Map<Id,String> sLocSelections = new Map<Id,String>();
    Map<Id,String> locSelections = new Map<Id,String>();
    List<Service_Location__c> sLocs = [select Id, Name, Location__c, Location__r.Name, ICC_Subscriber_ID__c from Service_Location__c where Account__c =: accountId order by Name];
    for(Service_Location__c sLoc : sLocs){
      sLocSelections.put(sLoc.Id, sLoc.Name + ' [' + sLoc.Location__r.Name + ']');
      locSelections.put(sLoc.Location__c, sLoc.Location__r.Name);
    }
    jsonSLocSelections = JSON.serialize(sLocSelections);
    jsonLocSelections = JSON.serialize(locSelections);
  }

  private static final Set<String> bldgFields = new Set<String>{
    'Id'
    ,'Market_Area_ID__c'
    ,'LSO_CLLI__c'
    ,'Address__c'
    ,'Building_Hash__c'
    ,'Net_Classification__c'
    ,'Serving_LSO__r.LSO_CLLI__c'
    ,'Serving_LSO__r.Net_Classification__c'
    ,'Name'
    ,'Status__c'
    ,'EoF_Competitive_Building__c'
  };

  private static final Set<String> olcFields = new Set<String>{
    'Id'
    ,'Name'
    ,'Term__c'
    ,'Bandwidth__c'
    ,'Active__c'
  };

  private static String getFieldsStringFromPath(String path, Set<String> fields){
    path = !String.isEmpty(path) ? (path + '.') : '';
    return path + String.join(new List<String>(fields), ',' + path);
  }

  private OpportunityLocationConfiguration__c getSolution(String olcID){
    String solQueryFields = getFieldsStringFromPath('', olcFields);
    solQueryFields += ',' + getFieldsStringFromPath('Opportunity_Location__r', new Set<String>{ 'Id', 'Name' });
    solQueryFields += ',' + getFieldsStringFromPath('Opportunity_Location__r.Order__r', new Set<String>{ 'Id','Name' });
    solQueryFields += ',' + getFieldsStringFromPath('Opportunity_Location__r.Order__r.Opportunity__r', new Set<String>{ 'Id' });
    solQueryFields += ',' + getFieldsStringFromPath('Opportunity_Location__r.Service_Location__r', new Set<String>{ 'Id', 'Billable__c', 'Name', 'ICC_Subscriber_ID__c' });
    solQueryFields += ',' + getFieldsStringFromPath('Opportunity_Location__r.Service_Location__r.Location__r.Building__r', bldgFields);
    
    List<OpportunityLocationConfiguration__c> sols = !String.isEmpty(olcID)
                            ? (List<OpportunityLocationConfiguration__c>)Database.query('select ' + solQueryFields + ' from OpportunityLocationConfiguration__c where Id = \'' + olcID + '\'')
                            : new List<OpportunityLocationConfiguration__c>();
    
    return (sols.size() > 0) ? sols.get(0) : null;
  }
  
  public List<Building_Access_Availability__c> getBAA(){
    return [select Access_Technology__r.Name, Access_Technology_Name__c, Maximum_Bandwidth__c, Minimum_Required_Revenue__c, Status__c from Building_Access_Availability__c where Building__c =: opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.Location__r.Building__c];
  }

  public class UIProdView{
    public string DisplayName {get;set;}
    public decimal MRR {get;set;}
    public decimal MRRList {get;set;}
    public decimal MRRTotal {get;set;}
    public decimal NRR {get;set;}
    public decimal NRRList {get;set;}
    public decimal NRRTotal {get;set;}
    public OLI__c OLI {get;set;}
    public string ParentRelId {get;set;}
    public string PriceId {get;set;}
    public integer ProdId {get;set;}
    public string ProdName {get;set;}
    public integer Qty {get;set;}
    public string SPCComponentID {get;set;}
    public string SPCProductID {get;set;}
    public string UUID {get;set;}
    public string ParentProdName {get;set;}
    public string GroupName {get;set;}
    public List<UIProdView> Children {get;set;}
  }

  @RemoteAction
  public static string GrantApproval(string prods, string discountAuthorityLevelName, OpportunityLocationConfiguration__c sol){
    //todo move into SolutionApprovalUtils
    Integer icbCnt = 0;
    Integer mgrCnt = 0;
    Integer cmptCnt = 0;
    
    List<UIProdView> prodViews = (List<UIProdView>)JSON.deserialize(prods,List<UIProdView>.class);
    List<OLI__c> olis = new List<OLI__c>();
    for(UIProdView pv : prodViews){
      if(pv.oli.Approval_Status__c == 'Sales Management Approval Required')
        ++mgrCnt;
      else if(pv.oli.Approval_Status__c == 'Offer Management Approval Required')
        ++icbCnt;
      if(pv.oli.PP_Sales_Rate_Plan_Description__c.containsIgnoreCase('Competitive Building'))
        ++cmptCnt;
      olis.add(pv.oli);
    }
        

    Map<string,OLI__c> olisToUpdate = new Map<String,OLI__c>();
    if(sol.Active__c && (discountAuthorityLevelName == 'Offer Management' || (discountAuthorityLevelName == 'Sales Director' && icbCnt == 0 && mgrCnt >= 0) || (discountAuthorityLevelName == 'Sales Manager' && icbCnt == 0 && mgrCnt > 0 && cmptCnt > 0))){
      sol.Approver__c = UserInfo.getUserId();
      sol.Approval_Date__c = System.today().format();
      update sol;
      
      //set the OLI Off footprint approval.
      for(UIProdView pv : prodViews){
        if(pv.oli.off_footprint__c  && !pv.oli.Off_Footprint_Approved__c){
          pv.oli.Off_Footprint_Approved__c = true;
          olisToUpdate.put(pv.UUID,pv.oli);
        }
        if(!pv.oli.Approved__c){
          pv.oli.Approved__c = true;
          olisToUpdate.put(pv.UUID,pv.oli); 
        }
        
        for(UIProdView pvc : pv.Children){
          if(pvc.oli.off_footprint__c  && !pvc.oli.Off_Footprint_Approved__c){
            pvc.oli.Off_Footprint_Approved__c = true;
            olisToUpdate.put(pvc.UUID,pv.oli);
          }
          if(!pvc.oli.Approved__c){
            pvc.oli.Approved__c = true;
            olisToUpdate.put(pvc.UUID,pvc.oli);
          }
        }
      
      }
      
      //Save OLIs
      if(olisToUpdate.size() > 0)
        update olisToUpdate.values();
      
    }
    system.debug('olisToUpdate: ' + olisToUpdate);
    
    for(UIProdView pv : prodViews){
      if(olisToUpdate.containsKey(pv.UUID))
        pv.oli = olisToUpdate.get(pv.UUID);
    }
      
    
    return JSON.serialize(prodViews,true);
  }

  @RemoteAction
  public static Map<String,String> SecondaryLocationParsed(String streetNum, String street, String subPremise, String city, String state, String postalCode, Decimal latitude, Decimal longitude, Boolean manualCreate){
    Map<String, String> ret = new Map<String,String>();
    try{
      integraWS.SFLocationView locView = AddressParser.parseAddress(streetNum, string.escapeSingleQuotes(street), subPremise, city, state, postalCode, latitude, longitude, manualCreate);
      Building__c secLocParseBuilding = null;
      Location__c secLocParseLocation = null;
      system.debug('locView: ' + locView);
      if(locView != null && locView.Success && !string.IsEmpty(locView.BuildingHash)){
        secLocParseBuilding = AddressUtils.CreateBuilding(locView, true);
        secLocParseLocation = AddressUtils.CreateLocation(secLocParseBuilding, locView, true);
        secLocParseLocation.Name = secLocParseBuilding.Address__c + '/' + secLocParseLocation.Room_Suite__c + '/' + secLocParseBuilding.City__c;
      }
      ret.put(secLocParseLocation.Id, SecLocParseLocation.Name);
      system.debug('RET: ' + ret);
    }
    catch(Exception ex){
      system.debug('SecondaryLocationParsed exception: ' + ex);
      ret.put('Error',ex.getMessage());
    }
    return ret;
  }
  
  public Map<string,CatalogUtils.RelationshipView> GetFeaturePackageRelationships(){
    Map<string,CatalogUtils.RelationshipView> rels = new Map<string,CatalogUtils.RelationshipView>();
    for(CatalogUtils.RelationshipView rv: CatalogUtils.GetFeaturePackageRelationships()){
      rels.put(rv.primarySalesProductComponentID, rv);
    }

    return rels;
  }

  public Map<String, Map<String, Map<String, Decimal>>> getSPCSortConfigMap(){
    Map<String, Map<String, Map<String, Decimal>>> spcSortConfigs = new Map<String, Map<String, Map<String, Decimal>>>();
    for(CPQ_Sort_Config__c c : CPQ_Sort_Config__c.getall().values()){
      Map<String, Map<String, Decimal>> scs = spcSortConfigs.get(c.Parent_Type__c) != null ? spcSortConfigs.get(c.Parent_Type__c) : new Map<String, Map<String, Decimal>>();
      Map<String, Decimal> sortKeys = scs.get(c.Parent_name__c) != null ? scs.get(c.Parent_name__c) : new Map<String, Decimal>();
      if(!sortKeys.containsKey(c.Sorted_Item_Name__c)){
        sortKeys.put(c.Sorted_Item_Name__c, c.Sort_Order__c);
      }
      scs.put(c.Parent_name__c, sortKeys);
      spcSortConfigs.put(c.Parent_Type__c, scs);
    }
    return spcSortConfigs;
  }

  public List<string> getAccessTechs(){
    List<String> atechs = new List<String>();
    for(Access_Technology__c atech : [select Name from Access_Technology__c Where Access_Technology_ID__c in (1, 3, 4, 17, 18, 19, 20, 21, 22, 23) order by Name]){
      atechs.add(atech.name);
    }
    return atechs;
  }

  public Map<string,List<decimal>> getBandwidthsByAccess(){
    Map<string,List<decimal>> bws = new Map<string,List<decimal>>();
    for(AggregateResult ar :[Select Access_Technology_Name__c, Bandwidth_Text__c From SPC_Component__c Where Access_Technology_Name__c in :accessTechs and Bandwidth__c != 0 and Bandwidth__c != null Group BY Access_Technology_Name__c, Bandwidth_Text__c]){
      if(bws.containsKey(string.valueof(ar.get('Access_Technology_Name__c')))){
        List<decimal> bwList = bws.get(string.valueof(ar.get('Access_Technology_Name__c')));
        bwList.add(decimal.valueof(string.valueof(ar.get('Bandwidth_Text__c'))));
        bws.put(string.valueof(ar.get('Access_Technology_Name__c')), bwList);
      }
      else {
        bws.put(string.valueof(ar.get('Access_Technology_Name__c')),new List<decimal>{decimal.valueof(string.valueof(ar.get('Bandwidth_Text__c')))});
      }
    }


    return bws;
  }

  private static Map<string,decimal> getDefaultAccessTechByHierarchy(List<Building_Access_Availability__c> baas){
    
    string accessTechValues = customSettingUtils.getSingleProcessConfigurationValue('CPQAccessTechDefaultSort', 'AccessTechHierarcy', false);
    List<String> accessTechsOrdered = accessTechValues != null ? accessTechValues.split(';') : new List<String>();
    
    for(string s : accessTechsOrdered){
      for(Building_Access_Availability__c baa : baas){
        if(baa.Access_Technology_Name__c == s)
          return new Map<string,decimal>{customSettingUtils.getSingleProcessConfigurationValue('CPQAccessTechDefault', s, false) => baa.Maximum_Bandwidth__c};
      }
    }
    
    return null;
  }

  /* TestUtils.ITestableClass methods */
  public TestUtils.TestClass getTestClass(){ return new Test_ConfigureNewSolution(); }
}