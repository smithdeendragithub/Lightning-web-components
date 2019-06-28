global class CatalogEndpoint implements TestUtils.ITestableClass {
    webservice static List<Product_Family__c> GetProductFamilyByID(integer externalid){
        
        string extidstring = string.valueof(externalid);
        return [Select Id, NeedsBandwidthQual__c, NeedsLSOQual__c, ProductFamilyExternalID__c, Description__c from Product_Family__c where ProductFamilyExternalID__c = :extidstring];
    }
    
    global class PricingProductView{
        webservice integer AccessTypeID {get;set;}
        webservice decimal Bandwidth {get;set;}
        webservice string ProductName {get;set;}
        webservice integer ProductID {get;set;}
        webservice string RatePlanName {get;set;}
        webservice double MRR {get;set;}
        webservice double NRR {get;set;}
        webservice integer RatePlanID {get;set;}
    }
    
    webservice static List<PricingProductView> GetPricingforProduct(integer[] productIDs, string lsoClli, integer accessTypeID, decimal bandwidth, integer term){
        //Parameters: AccessTypeID and Bandwidth Optional
        //Return: AccessTypeID, Bandwidth, ProductName, ProductID, RatePlanName, MRR, NRR
        //string productfamily = string.valueof(productFamilyID);
        List<string> prodids = new List<string>();
        for(integer i :productIds){
            prodids.add(string.valueof(i));
        }
        string termString = string.valueof(term);
        List<Building__c> coloBuilding = [Select Id,LSO_CLLI__c,Market_Area__r.Id From Building__c Where LSO_CLLI__C = :lsoClli and (Building_Type__c = 'ILEC LSO' or Building_Type__c = 'ILEC LSO: Collocated' or Building_Type__c = 'ILEC Remote Switch') limit 1];
        if(!coloBuilding.isEmpty())
        {
            List<decimal> ColoAccessTypes = new List<decimal>(); 
           for(Access_Types__c atc :[Select Access_Type_ID__c From Access_Types__c Where Access_Technology__c in
            (Select Access_Technology__c  From Building_Access_Availability__c b Where Building__r.LSO_CLLI__C = :lsoClli and (Building__r.Building_Type__c = 'ILEC LSO' or Building__r.Building_Type__c = 'ILEC LSO: Collocated' or Building__r.Building_Type__c = 'ILEC Remote Switch'))]){
                ColoAccessTypes.add(atc.Access_Type_ID__c);
            } 
            
            ID coloMarketID = coloBuilding[0].Market_Area__r.Id;
            List<id> coloSps = new List<id>();
            for(Building_Sales_Product__c bsp :[Select Id,Sales_Product__c,LSOCLLI__c From Building_Sales_Product__c Where LSOCLLI__c = :lsoClli and SalesProductExternalID__c in :productIds]){
                coloSps.add(bsp.Sales_Product__c);
            }
            
            string noClause = 'No';
            string mainquery = 'Select p.Sales_Product_Rate_Plan__r.Access_Type_ID__c, p.Sales_Product_Rate_Plan__r.Bandwidth__c, p.Sales_Product_Rate_Plan__r.Sales_Product_Name__c, p.Sales_Rate_Plan_Description__c  , p.Sales_Product_Rate_Plan__c, p.NRC__c, p.MRC__c, p.Term__c,p.Market_Area__r.Id, Sales_Rate_Plan_ExternalID__c,p.Sales_Product_External_ID__c From    Product_Pricing__c p Where p.Expired__c = :noClause and (p.Term__c = :termString or p.Term__c = null) and p.Market_Area__r.Id = :coloMarketID and p.Sales_Product_External_ID__c in :prodIds ';
            if(accessTypeID > 0)
                mainquery += ' and (Sales_Product_Rate_Plan__r.Access_Type_ID__c = :accessTypeID or Sales_Product_Rate_Plan__r.Access_Type_ID__c = 0)';
            if(bandwidth != null){
                List<Product_Pricing__c> sprp = database.query(mainquery + ' and Sales_Product_Rate_Plan__r.Bandwidth__c <= :bandwidth order by Sales_Product_Rate_Plan__r.Bandwidth__c desc limit 1');
                if(!sprp.isEmpty())
                    mainquery += ' and (Sales_Product_Rate_Plan__r.Bandwidth__c <= ' + sprp[0].Sales_Product_Rate_Plan__r.Bandwidth__c + ' or Sales_Product_Rate_Plan__r.Bandwidth__c = null) ';
                else
                    mainquery += ' and (Sales_Product_Rate_Plan__r.Bandwidth__c <= :bandwidth or Sales_Product_Rate_Plan__r.Bandwidth__c = null) ';
            }   
            /*Else{
                    List<Product_Pricing__c> sprp = database.query(mainquery + ' and Sales_Product_Rate_Plan__r.Bandwidth__c <= :bandwidth order by Sales_Product_Rate_Plan__r.Bandwidth__c desc limit 1');
                    if(!sprp.isEmpty())
                        mainquery += ' and Sales_Product_Rate_Plan__r.Bandwidth__c = ' + sprp[0].Sales_Product_Rate_Plan__r.Bandwidth__c + ' or Sales_Product_Rate_Plan__r.Bandwidth__c = null) ';
                    else
                        mainquery += ' and (Sales_Product_Rate_Plan__r.Bandwidth__c = bandwidth or  Sales_Product_Rate_Plan__r.Bandwidth__c = null) ';  
            }*/
            
            mainquery += ' and (Sales_Product_Rate_Plan__r.Access_Type_ID__C in :ColoAccessTypes or Sales_Product_Rate_Plan__r.Access_Type_ID__c = 0)';
                 
            List<PricingProductView> views = new List<PricingProductView>();        
            for(Product_Pricing__c pp : database.query(mainquery)){
                PricingProductView view = new PricingProductView();
                view.AccessTypeID = integer.valueof(pp.Sales_Product_Rate_Plan__r.Access_Type_ID__c);
                view.Bandwidth = pp.Sales_Product_Rate_Plan__r.Bandwidth__c;
                view.MRR = pp.MRC__c;
                view.NRR = pp.NRC__c;
                
                
                view.ProductName = pp.Sales_Product_Rate_Plan__r.Sales_Product_Name__c;
                
                
                view.ProductID = integer.valueof(pp.Sales_Product_External_ID__c);  
                view.RatePlanName = pp.Sales_Rate_Plan_Description__c;
                view.RatePlanID = integer.valueof(pp.Sales_Rate_Plan_ExternalID__c);
                views.add(view);
            }
            return views;
        }   
        else
            return new List<PricingProductView>();
    } 
    
     webservice static List<PricingProductView> GetPricingforProductWithAncillaryProducts(integer[] productIDs, string lsoClli, integer accessTypeID, decimal bandwidth, integer term, boolean showMPLS){
        //Parameters: AccessTypeID and Bandwidth Optional
        //Return: AccessTypeID, Bandwidth, ProductName, ProductID, RatePlanName, MRR, NRR
        //string productfamily = string.valueof(productFamilyID);
        List<string> prodids = new List<string>();
        for(integer i :productIds){
            prodids.add(string.valueof(i));
        }
        string termString = string.valueof(term);
        List<Building__c> coloBuilding = [Select Id,LSO_CLLI__c,Market_Area__r.Id,zone__c,Extended_Classification__c From Building__c Where LSO_CLLI__C = :lsoClli and (Building_Type__c = 'ILEC LSO' or Building_Type__c = 'ILEC LSO: Collocated' or Building_Type__c = 'ILEC Remote Switch')];
        if(!coloBuilding.isEmpty())
        {
            string zone = coloBuilding[0].Zone__c;
            boolean isEEL = coloBuilding[0].Extended_Classification__c == 'Extended – EEL' ? true : false;

            
            List<decimal> ColoAccessTypes = new List<decimal>(); 
           for(Access_Types__c atc :[Select Access_Type_ID__c From Access_Types__c Where Access_Technology__c in
            (Select Access_Technology__c  From Building_Access_Availability__c b Where Building__r.LSO_CLLI__C = :lsoClli and (Building__r.Building_Type__c = 'ILEC LSO' or Building__r.Building_Type__c = 'ILEC LSO: Collocated' or Building__r.Building_Type__c = 'ILEC Remote Switch'))]){
                ColoAccessTypes.add(atc.Access_Type_ID__c);
            } 
            
            ID coloMarketID = coloBuilding[0].Market_Area__r.Id;
            List<id> coloSps = new List<id>();
            for(Building_Sales_Product__c bsp :[Select Id,Sales_Product__c,LSOCLLI__c From Building_Sales_Product__c Where LSOCLLI__c = :lsoClli and SalesProductExternalID__c in :productIds]){
                coloSps.add(bsp.Sales_Product__c);
            }
            
            //Add ancillary products to the original product list
           for(SalesProduct__c AncillarySP :[Select Id,SalesProductExternalID__c From SalesProduct__c Where Ancillary_Product__c = True]){
                prodids.add(AncillarySP.SalesProductExternalID__c);
           }
           
            string noClause = 'No';            
            string mainquery = 'Select p.Sales_Product_Rate_Plan__r.Access_Type_ID__c, p.Sales_Product_Rate_Plan__r.Bandwidth__c, p.Sales_Product_Rate_Plan__r.Sales_Product_Name__c, p.Sales_Rate_Plan_Description__c  , p.Sales_Product_Rate_Plan__c, p.NRC__c, p.MRC__c, p.Term__c,p.Market_Area__r.Id, Sales_Rate_Plan_ExternalID__c,p.Sales_Product_External_ID__c From    Product_Pricing__c p Where Expired__c = :noClause and (p.Term__c = :termString or p.Term__c = null) and p.Market_Area__r.Id = :coloMarketID and p.Sales_Product_External_ID__c in :prodIds ';
            if(accessTypeID > 0)
                mainquery += ' and (Sales_Product_Rate_Plan__r.Access_Type_ID__c = :accessTypeID or Sales_Product_Rate_Plan__r.Access_Type_ID__c = 0)';
            if(bandwidth != null){
                List<Product_Pricing__c> sprp = database.query(mainquery + ' and Sales_Product_Rate_Plan__r.Bandwidth__c <= :bandwidth order by Sales_Product_Rate_Plan__r.Bandwidth__c desc limit 1');
                if(!sprp.isEmpty())
                    mainquery += ' and (Sales_Product_Rate_Plan__r.Bandwidth__c <= ' + sprp[0].Sales_Product_Rate_Plan__r.Bandwidth__c + ' or Sales_Product_Rate_Plan__r.Bandwidth__c = null) ';
                else
                    mainquery += ' and (Sales_Product_Rate_Plan__r.Bandwidth__c <= :bandwidth or Sales_Product_Rate_Plan__r.Bandwidth__c = null) ';
            }   

            if(zone != null){
                //add zone filtering to query
                mainquery += ' and (Sales_Product_Rate_Plan__r.Zone__c = null or Sales_Product_Rate_Plan__r.Zone__c like \'%' + zone + '%\') '; 
            }   
            else{
                mainquery += ' and Sales_Product_Rate_Plan__r.Zone__c = null ';
            }
            if(isEEL)
                mainquery += ' and (Sales_Product_Rate_Plan__r.IsEEL__C = null or Sales_Product_Rate_Plan__r.IsEEL__c = \'No\' or Sales_Product_Rate_Plan__r.IsEEL__c = \'Yes\') ';
            else
                mainquery += ' and (Sales_Product_Rate_Plan__r.IsEEL__C = null or Sales_Product_Rate_Plan__r.IsEEL__c = \'No\') ';
            
            if(!showMPLS)
                mainquery += ' and (Sales_Product_Rate_Plan__r.isMPLS__c = null or Sales_Product_Rate_Plan__r.isMPLS__c = \'No\') ';
                     
            mainquery += ' and (Sales_Product_Rate_Plan__r.Access_Type_ID__C in :ColoAccessTypes or Sales_Product_Rate_Plan__r.Access_Type_ID__c = 0)';
                 
            List<PricingProductView> views = new List<PricingProductView>();        
            for(Product_Pricing__c pp : database.query(mainquery)){
                PricingProductView view = new PricingProductView();
                view.AccessTypeID = integer.valueof(pp.Sales_Product_Rate_Plan__r.Access_Type_ID__c);
                view.Bandwidth = pp.Sales_Product_Rate_Plan__r.Bandwidth__c;
                view.MRR = pp.MRC__c;
                view.NRR = pp.NRC__c;
                
                
                view.ProductName = pp.Sales_Product_Rate_Plan__r.Sales_Product_Name__c;
                
                
                view.ProductID = integer.valueof(pp.Sales_Product_External_ID__c);  
                view.RatePlanName = pp.Sales_Rate_Plan_Description__c;
                view.RatePlanID = integer.valueof(pp.Sales_Rate_Plan_ExternalID__c);
                views.add(view);
            }

            return views;
        }   
        else
            return new List<PricingProductView>();
    } 
          
     global class SalesProductRatePlanView{
            webservice string Access {get;set;}
            webservice decimal Bandwidth {get;set;}
            webservice string ProductFamilyName {get;set;}
            webservice string ProductName {get;set;}
            webservice string ProductID {get;set;}
            webservice boolean EVPL {get;set;}
            webservice boolean MPLS {get;set;}
            webservice integer AccessTypeID {get;set;}
            webservice string ExtendedClassification {get;set;}
            
           public SalesProductRatePlanView(Sales_Product_Rate_Plan__c s, SalesProductSalesFamily__c spsf, Building__c b){
              string prodOverride = '';
              string familyName = '';
              if(spsf != null){
                    prodOverride = spsf.Name;
                    familyName = spsf.Product_Family__r.Name;
              }
            Access = s.Access_Type__c;
            Bandwidth = s.Bandwidth__c;
            ProductFamilyName = familyName == '' ? s.Sales_Product__r.Product_Family__r.Name : familyName;
            
            ProductName = prodOverride == '' ? s.Sales_Product_name__c : prodOverride;
            
            
            ProductID = s.Sales_Product__r.SalesProductExternalID__c;
            EVPL = s.Sales_Product__r.EVPL__c;
            MPLS = s.Sales_Product__r.MPLS__c;
            AccessTypeID = integer.valueof(s.Access_Type_ID__c);     
            ExtendedClassification = b == null ? '' : b.Extended_Classification__c;      
        }
      }
    
    
    
    
    global class AccessTechBandwidthView{
        webservice integer AccessTechID {get;set;}
        webservice decimal Bandwidth {get;set;}
    }
    
    public class AccessTypeTechView{
        public integer AccessTypeID {get;set;}
        public integer AccessTechID {get;set;}
        public AccessTypeTechView(integer atype,integer tech){
            AccessTypeID = atype;
            AccessTechID = tech;
        }
    }
    webservice static List<SalesProductRatePlanView> GetSalesProductRatePlans(AccessTechBandwidthView[] accessTechs, string colo, integer productFamilyID){
        string productfamily = string.valueof(productFamilyID);
        List<integer> accessTechIds = new List<integer>();
        for(AccessTechBandwidthView v : accessTechs){
            accessTechIds.add(v.AccessTechId);
        }   
        
        
        List<AccessTypeTechView> accessTypeViews = new List<AccessTypeTechView>();
        for(Access_Technology__c at :[Select Access_Technology_ID__c,(Select Access_Type_ID__c From Access_Types__r) From Access_Technology__c a Where Access_Technology_ID__c in :accessTechIds]){
            for(Access_Types__c atc :at.Access_types__r){
                accessTypeViews.add(new AccessTypeTechView(integer.valueof(atc.Access_Type_ID__c),integer.valueof(at.Access_Technology_ID__c)));
            }
        }
        accessTypeViews.add(new AccessTypeTechView(0,0));
        AccessTechBandwidthView at0 = new AccessTechBandwidthView();
        at0.bandwidth = 0;
        at0.AccessTechID = 0;
        accessTechs.add(at0);
        
       List<Building__c> coloBuildings = [Select Id, Extended_Classification__c From Building__c Where LSO_CLLI__C = :colo and (Building_Type__c = 'ILEC LSO' or Building_Type__c = 'ILEC LSO: Collocated') limit 1];
       Building__c coloBuilding = null;
       
       if(coloBuildings.size() > 0)
            coloBuilding = coloBuildings[0];
             
       List<decimal> ColoAccessTypes = new List<decimal>(); 
       for(Access_Types__c atc :[Select Access_Type_ID__c From Access_Types__c Where Access_Technology__c in
        (Select Access_Technology__c  From Building_Access_Availability__c b Where Building__r.LSO_CLLI__C = :colo and (Building__r.Building_Type__c = 'ILEC LSO' or Building__r.Building_Type__c = 'ILEC LSO: Collocated'))]){
            ColoAccessTypes.add(atc.Access_Type_ID__c);
           //Need to return max bandwidth for ds1 if its available on the CO
            if(atc.Access_Type_ID__c == 7){
                accessTypeViews.add(new AccessTypeTechView(7,7));
                AccessTechBandwidthView atDS1 = new AccessTechBandwidthView();
                atDS1.bandwidth = 1000;
                atDS1.AccessTechID = 7;
                accessTechs.add(atDS1);
            }
            if(atc.Access_Type_ID__c == 13){
                accessTypeViews.add(new AccessTypeTechView(13,4));
                AccessTechBandwidthView atDS1 = new AccessTechBandwidthView();
                atDS1.bandwidth = 1000;
                atDS1.AccessTechID = 4;
                accessTechs.add(atDS1);
            }
        } 
 
        
        //for(Access_Types__c at :[Select Id,Access_Type_ID__c From Access_Types__c Where Access_Type_ID__c in :accessTypeIds]){
        //  accessTypes.add(at.Access_Type_ID__c);
        //}

        
        List<SalesProduct__c> salesProds = [Select Id From SalesProduct__c Where Product_Family__r.ProductFamilyExternalID__c = :productfamily and Expired__c = 'No'];
        
        List<SalesProductSalesFamily__c> SalesProductSalesFamilies = [Select s.Sales_Product__c,s.Sales_Product__r.id, s.Name, s.Id, s.Product_Family__r.Name From SalesProductSalesFamily__c s Where s.Product_Family__r.ProductFamilyExternalID__c = :productfamily];
        
        Map<decimal, decimal> accessMap = new Map<decimal, decimal>();
        
        
        //Landers - 10/15/2012 - 1. Need to create a map of type ID,SalesProductSalesFamily 
        Map<string, SalesProductSalesFamily__c> salesProductSalesFamilyMap = new Map<string, SalesProductSalesFamily__c>();
        
        //Landers - 10/15/2012 - add these items to the map created.  Using the key of sales product id, value of sales product sales family record.
        for(SalesProductSalesFamily__c spsf : SalesProductSalesFamilies){
            salesProds.add(spsf.Sales_Product__r);  
            salesProductSalesFamilyMap.put(spsf.Sales_Product__r.Id, spsf);  
        }
        
        List<SalesProductRatePlanView> sprpv = new List<SalesProductRatePlanView>();
        for(AccessTechBandwidthView v : accessTechs){
            List<Sales_Product_Rate_Plan__c> sps = new List<Sales_Product_Rate_Plan__c>();
            decimal bandwidth = v.Bandwidth;
            List<integer> accessTypes = new List<integer>();
            for(AccessTypeTechView att :accessTypeViews){
                if(att.AccessTechID == v.AccessTechID)
                    accessTypes.add(att.AccessTypeID);
            }
            
            if(colo == ''){
                string mainquery = 'select Id, Access_Type__c, Bandwidth__c, Sales_Product_Name__c,Sales_Product__r.Product_Family__r.Name, Sales_Product__r.SalesProductExternalID__c,Access_Type_ID__c,Sales_Product__r.MPLS__c, Sales_Product__r.EVPL__c  From Sales_Product_Rate_Plan__c Where Sales_Product__r.Id in :salesProds';
                if(!accessTypes.isEmpty())
                    mainquery += ' and (Access_Type_ID__c in :accessTypes )';
                if(bandwidth != null){
                    List<Sales_Product_Rate_Plan__c> sprp = database.query(mainquery + ' and Bandwidth__c <= :bandwidth order by Bandwidth__c desc limit 1');
                    if(!sprp.isEmpty())
                        mainquery += ' and Bandwidth__c = ' + sprp[0].Bandwidth__c; 
                }
                //add access availability limiting to mainquery
                mainquery += ' and (Access_Type_ID__C in :ColoAccessTypes or Access_Type_ID__c = 0)';
                sps = database.query(mainquery);
            }
            else{
                List<id> coloSps = new List<id>();
                for(Building_Sales_Product__c bsp :[Select Id,Sales_Product__c,LSOCLLI__c From Building_Sales_Product__c Where LSOCLLI__c = :colo and Sales_Product__c in :salesProds]){
                    coloSps.add(bsp.Sales_Product__c);
                }
                
                string mainquery = 'select Id, Access_Type__c, Bandwidth__c, Sales_Product_Name__c,Sales_Product__r.Product_Family__r.Name, Sales_Product__r.SalesProductExternalID__c, Access_Type_ID__c,Sales_Product__r.MPLS__c, Sales_Product__r.EVPL__c  From Sales_Product_Rate_Plan__c Where Sales_Product__r.Id in :coloSps';
                if(!accessTypes.isEmpty())
                    mainquery += ' and (Access_Type_ID__c  in :accessTypes)';
                if(bandwidth != null){
                    List<Sales_Product_Rate_Plan__c> sprp = database.query(mainquery + ' and Bandwidth__c <= :bandwidth order by Bandwidth__c desc limit 1');
                    if(!sprp.isEmpty())
                        mainquery += ' and (Bandwidth__c <= ' + sprp[0].Bandwidth__c + ' or Bandwidth__c = null) ';
                    else
                        mainquery += ' and (Bandwidth__c <= :bandwidth or Bandwidth__c = null) ';    
                }
                //add access availability limiting to mainquery
                mainquery += ' and (Access_Type_ID__C in :ColoAccessTypes or Access_Type_ID__c = 0)';
                
                sps = database.query(mainquery);
            }
            for(Sales_Product_Rate_Plan__c sp  :sps){
               SalesProductRatePlanView spv = new SalesProductRatePlanView(sp, salesProductSalesFamilyMap.get(sp.Sales_Product__r.id),coloBuilding);
                sprpv.add(spv);
            }

        }
        return sprpv;
    }
    
    webservice static List<Sales_product_rate_plan__c>  GetAccessBandwidthSalesRatePlanInfo(){
        return [Select s.Sales_Product__r.Id, s.Sales_Product__c, s.Bandwidth__c, s.Access_Types__r.AccessTechName__c 
                From Sales_Product_Rate_Plan__c s
                Where s.Sales_Product__r.Expired__c = 'No' and s.Bandwidth__c != null and s.Access_Types__r.AccessTechName__c != null];
    }
    
global class SalesProductClliView{
        webservice string LSOClli {get;set;}
        webservice ID SalesProductID {get;set;}
        webservice ID BuildingID {get;set;}
        webservice List<decimal> AccessTypes {get;set;}
    }
    
    webservice static List<SalesProductClliView> GetSalesProductClliInfo(){
        List<SalesProductClliView> spcv = new List<SalesProductClliView>();
        for(SalesProduct__c sp :[Select Id,(Select LSOCLLI__c, Building__c From Building_Sales_Products__r) From SalesProduct__c s Where Expired__c = 'No']){
            List<decimal> AccessTypes = new List<decimal>();
            for(Sales_Product_Rate_Plan__c sprp :[Select Access_Type_ID__c From Sales_Product_Rate_Plan__c Where Sales_Product__c = :sp.Id]){
                AccessTypes.add(sprp.Access_Type_ID__c);
            }
            
            for(Building_Sales_Product__c bsp :sp.Building_Sales_Products__r){
                SalesProductClliView v = new SalesProductClliView();
                v.LSOClli = bsp.LSOCLLI__c;
                v.SalesProductID = sp.ID;
                v.BuildingID = bsp.Building__c;
                v.AccessTypes = AccessTypes;
                spcv.add(v);
            }
        }
        
        return spcv;
    }

    
        global class BuildingAccessTypeView{
        webservice ID BuildingID{get;set;}
        webservice decimal AccessTypeID{get;set;}
    }
    
    webservice static List<BuildingAccessTypeView> GetBuildingAccessTypeInfo(){
        List<BuildingAccessTypeView> retValue = new List<BuildingAccessTypeView>();
        
        Map<decimal, decimal> accessMap = new Map<decimal, decimal>();
        for (Access_Types__c a :[Select a.Access_Type_ID__c, a.Access_Technology__r.Access_Technology_ID__c From Access_Types__c a]){
            accessMap.put(a.Access_Technology__r.Access_Technology_ID__c, a.Access_Type_ID__c);
        }
        
        for (Building_Access_Availability__c bav :[Select Id, Access_Technology__r.Access_Technology_ID__c, Building__c From Building_Access_Availability__c]){
            BuildingAccessTypeView view = new BuildingAccessTypeView();
            view.BuildingID = bav.Building__c;
            view.AccessTypeID = accessMap.get(bav.Access_Technology__r.Access_Technology_ID__c);
            retValue.add(view);
        }
        
        return retValue;
    }
    
    webservice static List<Product_Family__c> GetProductFamilies(){
		return [Select Id, NeedsBandwidthQual__c, NeedsLSOQual__c, ProductFamilyExternalID__c, Description__c from Product_Family__c Where Expired__c = 'No'];
    }
    
    webservice static List<SPC_Pricing__c> GetProductFeaturePricing(integer[] accessTechIds, Decimal bandwidth, String wireCenterCLLI, String buildingHash,integer[] salesProductIDs, integer[] terms){
        return CatalogUtils.GetProductFeaturePricing(accessTechIds, bandwidth, wireCenterCLLI, buildingHash, salesProductIDs, terms);
    }
    
    webservice static List<SPC_Pricing__c> GetPricingByPricingID(List<string> priceIds){
        return CatalogUtils.GetPricingByPricingID(priceIds);
    }
    
    webservice static List<SPC_Product__c> GetActiveSPCProducts(){
		return [Select id, Name, Sales_Product_Group__c, SalesProductExternalID__c From spc_product__c Where expiration__c = null and Hide_In_Wizard__c = false];
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_CatalogEndpoint(); }
}