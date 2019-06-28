public with sharing class ProposalServiceAgreementController {

    public class Location{

        public Id locationId { get; set; }
        public List<QuoteWrapper.Product> productList { get; set; }
    public Map<string,List<QuoteWrapper.Product>> mapProductList {get;set;}
      //public List<QuoteWrapper.QuoteLineItem> lstLongDistanceProducts {get;set;}
       public Boolean hasLongDistance {get;set;}
       public Boolean hasVoice {get;set;}
        public Opportunity_Location__c rawLocation { get; set; }
        public String Term {get; set; }
        //MNK added Sept 2017
        public Date contractEndDate {get; set; }

    public boolean displayOnProposal {get;set;}
    public string solutionName {get;set;}
        public Directory_Listing__c primaryListing { get; set; }
        public CompanyInfo locationAddress {get;set;}
        public CompanyInfo listingAddress {get;set;}
        public location(){
            productList = new List<QuoteWrapper.Product>();
      mapProductList = new Map<string,List<QuoteWrapper.Product>>();
        }

    }

    public CompanyInfo mainClientAddress { get; set; }
    public List<Location> locations { get; set; }
    //public String specialServiceAgreementText {get;set;}
    public Boolean mrcDiscountTotal {get;set;}
    public Boolean nrcDiscountTotal {get;set;}
    public Decimal mrcGrandTotal {get;set;}
    public Decimal nrcGrandTotal {get;set;}
    public Decimal mdt {get;set;}
    public Decimal ndt {get;set;}
    public Integer locationCount {get;set;}
  public Set<String> specialText {get;Set;}
    public Set<String> specialFrenchText {get;set;}
  public String contractType { get; set; }
    public String languagePreference { get; set;}
    public String serviceCountry {get; set;}
    public Boolean hasSIPTrunking {get;set;}

  private static Map<Decimal, List<ServiceAgreement_Junction__c>> saJunctionsBySalesProductComponentComponentID = null;
  public static Map<Decimal, List<ServiceAgreement_Junction__c>> ServiceAgreementJunctionsBySalesProductComponentComponentID{
    get{
      if(saJunctionsBySalesProductComponentComponentID == null){
        saJunctionsBySalesProductComponentComponentID = new Map<Decimal, List<ServiceAgreement_Junction__c>>();
        for(ServiceAgreement_Junction__c spj : [select Sales_Product_Component_Id__c, Sales_Service_Agreement_Text__r.Text__c, Sales_Service_Agreement_French_Text__r.Text__c from ServiceAgreement_Junction__c where Sales_Product_Component_Id__c != null]){
          if(spj.Sales_Service_Agreement_Text__r.Text__c != null){
            List<ServiceAgreement_Junction__c> l = (saJunctionsBySalesProductComponentComponentID.get(spj.Sales_Product_Component_Id__c) != null) ? saJunctionsBySalesProductComponentComponentID.get(spj.Sales_Product_Component_Id__c) : new List<ServiceAgreement_Junction__c>();
            l.add(spj);
            saJunctionsBySalesProductComponentComponentID.put(spj.Sales_Product_Component_Id__c, l);
          }
        }
      }
      return saJunctionsBySalesProductComponentComponentID;
    }
  }

  private void getSpecialTextSet(Set<Decimal> salesproductComponentIDs){
    specialText = new Set<String>();
        specialFrenchText = new Set<String>();
    Map<Decimal, List<ServiceAgreement_Junction__c>> m = ServiceAgreementJunctionsBySalesProductComponentComponentID;
    for(Decimal d : salesproductComponentIDs){
            if(m.get(d) != null && m.get(d).size() > 0){
                if (serviceCountry != null && serviceCountry.equals('CA')){
                    for (Integer i=0; i <m.get(d).size(); i++){
                        specialText.add(m.get(d)[i].Sales_Service_Agreement_Text__r.Text__c);
                        if (m.get(d)[i].Sales_Service_Agreement_French_Text__r.Text__c != null)
                            specialFrenchText.add(m.get(d)[i].Sales_Service_Agreement_French_Text__r.Text__c);
                  }
                } else{
                  specialText.add(m.get(d)[0].Sales_Service_Agreement_Text__r.Text__c);
                        if (m.get(d)[0].Sales_Service_Agreement_French_Text__r.Text__c != null)
                            specialFrenchText.add(m.get(d)[0].Sales_Service_Agreement_French_Text__r.Text__c);
                }
            }
    }
  }

    public Opportunity currentOpportunity {
        get{
            return currentOpportunity;
        }
        set{
            currentOpportunity = value;
            serviceCountry = currentOpportunity.Service_Country__c;
            mainClientAddress = new CompanyInfo(currentOpportunity.Account);
            languagePreference = currentOpportunity.Account.Language_Preference__c;
            getLocationsForOpportunity();
        }
    }

    public void getLocationsForOpportunity(){
    mrcDiscountTotal = true;
    nrcDiscountTotal = true;
        locations = new List<Location>();
        List<Opportunity_Location__c> lstLocations =
            [Select Id, Name, NRC_Total__c, MRC_Total__c, Turndown_Total__c, Order__r.Id,
            Service_Location__r.Account__r.Name, Service_Location__r.Account__r.Phone, Service_Location__r.Account__r.Fax
        ,Service_Location__r.Account__r.ShippingStreet, Service_Location__r.Account__r.ShippingCity, Service_Location__r.Account__r.ShippingState, Service_Location__r.Account__r.ShippingPostalCode,
            (Select EPCProductDescription__c, FirstCN__c, MRC__c From Disconnect_Line_Items__r ORDER BY FirstCN__c),
            (Select Id, Term__c, Name, Display_on_Solution__c, Contract_Term_End_Date__c from OpportunityLocationConfigurations__r Where Active__c=true)
            from Opportunity_Location__c
            where Order__r.Opportunity__c=:currentOpportunity.Id AND On_Hold__c=false
            ORDER BY Service_Location__r.Account__r.Name];

        List<Directory_Listing__c> listings =
            [Select Company_Name__c, Address__c, City__c, State__c, Zip__c, Listing_Telephone_Number__c, Type__c, Which_Directory__c,
            Technical_Information__r.Opportunity_Site__c
            From Directory_Listing__c
            where Main_Listing__c = true AND Technical_Information__r.Opportunity_Site__r.Order__r.Opportunity__c=:currentOpportunity.Id];

    mrcGrandTotal = 0.00;
    nrcGrandTotal = 0.00;
    locationCount = lstLocations.size();


    Map<String, Service_Location__c> mapServLoc =  new Map<String, Service_Location__c>();
    Map<String, Building__c> mapBuildings = new Map<String, Building__c>();
    Map<Id,List<OLI__c>> solOLIMap = new Map<Id,List<OLI__c>>();
    List<OLI__c> listOLI = new List<OLI__c>();

    if(locationCount > 0){

      Set<Id> ids = new Set<Id>();
      Set<Id> buildids = new Set<Id>();
      Set<Id> olcId = new Set<Id>();
      List<Id> solIds = new List<Id>();

      for(Opportunity_Location__c loc : lstLocations){
        ids.Add(loc.Service_Location__c);
        olcId.Add(loc.OpportunityLocationConfigurations__r[0].Id);
      }
      solIds.addall(olcId);
      solOLIMap = getOLIsByConfigList(solIds);

      for(Service_Location__c servLoc : [SELECT Name, Location__r.Building__r.Id, Location__r.Room_Suite__c, Customer_Detail__r.Government_Contract_Type__c, (Select Id From Opportunity_Locations__r) FROM Service_Location__c WHERE Id IN: ids]){
         mapServLoc.put(servLoc.Id, servLoc);
         buildids.Add(servLoc.Location__r.Building__r.Id);
      }

       for(Building__c b : [SELECT Address__c, City__c, State__c, Postal_Code__c FROM Building__c WHERE Id IN: buildids]){
           mapBuildings.put(b.Id, b);
       }
       listOLI = [SELECT MRC_Discount__c, NRC_Discount__c, OpportunityLocationConfiguration__c FROM OLI__c WHERE OpportunityLocationConfiguration__c IN: olcId];

    }

        for( Opportunity_Location__c ol : lstLocations ) {
          Service_Location__c sLoc = mapServLoc.get(ol.Service_Location__c);

            //If the opportunity location does not have a service loc, do not factor in this location
            if(sLoc == null) continue;

      if(contractType == null && sLoc.Customer_Detail__r != null) contractType = sLoc.Customer_Detail__r.Government_Contract_Type__c;

          mrcGrandTotal += ol.MRC_Total__c;
            nrcGrandTotal += ol.NRC_Total__c;
            mdt = 0.00;
      ndt = 0.00;

            for (OLI__c oli : listOLI){
              if(oli.OpportunityLocationConfiguration__c == ol.OpportunityLocationConfigurations__r[0].Id){
                mdt += (Decimal)oli.MRC_Discount__c;
              }
            }
            if( (ol.OpportunityLocationConfigurations__r != null) && (ol.OpportunityLocationConfigurations__r.size() > 0) ) {
                Location nextLocation = new Location();
                nextLocation.productList = QuoteWrapper.getConfigProductsWithLineItems(ol.OpportunityLocationConfigurations__r[0].Id, true, false,solOLIMap.get(ol.OpportunityLocationConfigurations__r[0].Id));
                nextLocation.term = ol.OpportunityLocationConfigurations__r[0].Term__c;
        nextLocation.displayOnProposal = ol.OpportunityLocationConfigurations__r[0].Display_on_Solution__c;
        nextLocation.solutionName = ol.OpportunityLocationConfigurations__r[0].Name;
                nextLocation.primaryListing = findPrimaryListing(ol, listings);
                nextLocation.rawLocation = ol;
                //MNK Added Sept 2017
                nextLocation.contractEndDate = ol.OpportunityLocationConfigurations__r[0].Contract_Term_End_Date__c;

                //nextLocation.locationAddress = new CompanyInfo(ol.Service_Location__r.Account__r);
                //nextLocation.locationAddress = [SELECT Service_Location__r.Name, Service_Location__r.Location__r.Building__r.Street__c, Service_Location__r.Location__r.Building__r.City__c, Service_Location__r.Location__r.Building__r.State__c, Service_Location__r.Location__r.Building__r.Postal_Code__c, Service_Location__r.Account__r.Phone FROM Opportunity_Location__c WHERE Id = :ol.Id ];

                String serviceLocName = '';
                String serviceLocSuite = '';
                String serviceLocId = '';
                serviceLocName = sLoc.Name;
          serviceLocSuite = sLoc.Location__r.Room_Suite__c;
          serviceLocId = sLoc.Location__r.Building__r.Id;

               /*
                 mholcombe merge UAT -ORDER with above 3 lines
                 Service_Location__c sName = mapServLoc.get(ol.Service_Location__c);
          serviceLocName = sName.Name;
          serviceLocSuite = sName.Location__r.Room_Suite__c;
          serviceLocId = sName.Location__r.Building__r.Id;
             */
             Building__c bldg = mapBuildings.get(serviceLocId);
                nextLocation.locationAddress = new CompanyInfo(bldg, serviceLocName, serviceLocSuite);
                nextLocation.listingAddress = new CompanyInfo(nextLocation.primaryListing);

                nextLocation.hasLongDistance = false;
                nextLocation.hasVoice = false;
                //nextLocation.lstLongDistanceProducts= new List<QuoteWrapper.QuoteLineItem>();

              for (QuoteWrapper.Product prod : nextLocation.productList) {
          			for(string groupname : prod.linesMap.keyset()){
                        if (prod.Name == 'NGN SIP Trunking' || prod.Name == 'SIP Business Lines') hasSIPTrunking = true;
            			string groupNameVal = groupname == '' ? prod.Name : groupname;
            			if(nextLocation.mapProductList.containskey(groupNameVal)){
              				nextLocation.mapProductList.get(groupNameVal).add(prod);
            			}
            			else{
              				nextLocation.mapProductList.put(groupNameVal,new List<QuoteWrapper.Product>{prod});
            			}
          			}
                	for (QuoteWrapper.QuoteLineItem line : prod.lines) {
                  		if (line.rawOLI.PP_LD_Interstate__c || line.rawOLI.PP_LD_Intrastate__c) {
                    		nextLocation.hasLongDistance = true;
                    		//nextLocation.lstLongDistanceProducts.add(line);
                  		}

                  		if (line.rawOLI.PP_Voice_Line__c) {
                    		nextLocation.hasVoice = true;
                  		}

                  		mdt += line.rawOLI.MRC_Discount__c;
            			ndt += line.rawOLI.NRC_Discount__c;
                	}
              }
              if (mdt != 0.00){
          mrcDiscountTotal = false;
        }
        if (ndt != 0.00){
          nrcDiscountTotal = false;
              }

        mrcGrandTotal = mrcGrandTotal;
        nrcGrandTotal = nrcGrandTotal;
                //Once you added all the products, remove from the main list those that were added to the LD list
                /*for (QuoteWrapper.QuoteLineItem ldLine : nextLocation.lstLongDistanceProducts) {
                  Integer posProd = 0;

                  for (QuoteWrapper.Product prod : nextLocation.productList) {
                  Integer posLine = 0;

                  for (QuoteWrapper.QuoteLineItem line : prod.lines) {
                    if (line.rawOLI.Id == ldline.rawOLI.id) {
                      prod.lines.remove(posLine);
                      break;
                    }
                    posLine += 1;
                  }

                  if (prod.lines.size() == 0) {
                    nextLocation.productList.remove(posProd);
                    break;
                  }

                  posProd += 1;
                  }
                }*/

                locations.add(nextLocation);
            }
        }
        getSpecialText( locations );
    }


    //  some line items require special text appended to the service agreement
    //  loop through all locations
    //      loop through all products
    //          loop through all line items
    //  gather component ids and load special text.
    public void getSpecialText(List<Location> lstLocations) {

    Set<Decimal> compIds = new Set<Decimal>();
        for( Location nextLocation : lstLocations ) {
            for( QuoteWrapper.Product nextProduct : nextLocation.productList ) {
                for( QuoteWrapper.QuoteLineItem nextLine : nextProduct.lines ) {
          compIds.add(nextLine.rawOLI.SPC_Sales_Product_Component_Id__c);
                    /*if( nextLine.rawOLI.PP_ServiceAgreementText__c != null ) {
                        saText = nextLine.rawOLI.PP_ServiceAgreementText__c;
                        break;*/
                }
            }
        }

    getSpecialTextSet(compIds);

    }

    private static Map<Id,List<OLI__c>> getOLIsByConfigList(List<id> configIds)
   {
     Map<Id,List<OLI__c>> configOLIMap = new Map<Id,List<OLI__c>>();
     List<OLI__c> olisQueried = [
       Select
          MRC__c
          , MRC_Discount__c
          , MRC_Total__c
          , NRC__c
          , NRC_Discount__c
          , NRC_Total__c
          , Qty__c,
          Approval_Status__c,
           Approved__c,
        DQ__c,
        //DQ_FR__c,
        PP_Product_Pricing_Name__c,
        //PP_Product_Pricing_Name_FR__c,
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
        SPC_Sales_Product__c,
        MRC_Floor__c,
        SPC_MRC_OnNet__c,
        SPC_NRC_Is_Quote__c,
        NRC_Floor__c,
        Product_Family_Product__c,
        Product_Family_Id__c,
        OpportunityLocationConfiguration__c,
        Secondary_Location__r.Building__r.Name,
        Secondary_Location__c,
        Secondary_Service_Location__r.Location__r.Building__r.Name,
        Secondary_Service_Location__c,
        Group_Name__c,
        SPC_Component__r.Display_Name__c,
        SPC_Component__c,
        Product_Pricing_Display_Name__c,
        Product_Pricing_Display_French_Name__c
      From
        OLI__c
         Where
           OpportunityLocationConfiguration__c in :configIds
           AND  PP_Package_Feature__c = false Order by Product_Family_Product__c, Display_Order__c];

        List<String> currentPriceIds = new List<String>();
        for(OLI__c o: olisQueried){
          currentPriceIds.add(o.price_id__c);
        }

        Map<string,SPC_Pricing__c> mapPricingNamePrices = new map<String,SPC_Pricing__c>();
        For(SPC_Pricing__c prices : CatalogUtils.GetPricingByPricingID(currentPriceIds)){
          if(prices.Pricing_Name__c != null || (prices.SPC_Component__c != null && prices.SPC_Component__r.Display_Name__c != null))
            mapPricingNamePrices.put(prices.Price_ID__c,prices);
        }

        for(OLI__c o : olisQueried)
        {
            o.Product_Pricing_Display_Name__c = o.PP_Product_Pricing_Name__c;
        	if(mapPricingNamePrices.containskey(o.Price_id__c)){
            	SPC_Pricing__c priceNamePrice = mapPricingNamePrices.get(o.Price_id__c);

            	if(priceNamePrice.SPC_Component__c != null && priceNamePrice.SPC_Component__r.Display_Name__c != null){
                	o.PP_Product_Pricing_Name__c = priceNamePrice.SPC_Component__r.Display_Name__c;
                    o.Product_Pricing_Display_Name__c = priceNamePrice.SPC_Component__r.Display_Name__c;
            	}
            	else{
            		o.PP_Product_Pricing_Name__c = o.PP_Product_Pricing_Name__c.replace(' - ' + priceNamePrice.Pricing_Name__c, '').replace('-' + priceNamePrice.Pricing_Name__c, '');      
            	}
          	}
            if(configOLIMap.get(o.OpportunityLocationConfiguration__c) != null){
                List<OLI__c> olis = configOLIMap.get(o.OpportunityLocationConfiguration__c);
                olis.add(o);
            }
            else{
            	List<OLI__c> olis = new List<OLI__c>();
                olis.add(o);
                configOLIMap.put(o.OpportunityLocationConfiguration__c,olis);
            }

          }

          return configOLIMap;

   }


    public Directory_Listing__c findPrimaryListing(Opportunity_Location__c ol, List<Directory_Listing__c> listings) {

        for( Directory_Listing__c dl : listings ) {
            if( dl.Technical_Information__r.Opportunity_Site__c == ol.Id )
                return dl;
        }

        return null;
    }
}