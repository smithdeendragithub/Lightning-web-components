public with sharing class ProposalQuoteController {
    
    public Opportunity currentOpportunity {get; set;}

    public Opportunity_Location__c opptyLoc { get;set; }
    public String term {get; set;} 
    public Boolean display {get; set;}
    public String solution {get; set;}
    public List<QuoteWrapper.Product> lstProducts {get;set;} 
	public Map<String,List<QuoteWrapper.Product>> mapProducts {get;set;}
    //public List<QuoteWrapper.QuoteLineItem> lstLongDistanceProducts {get;set;}   
    public CompanyInfo locationAddress {get;set;}
    public Boolean hasLongDistance {get;set;}
    public String ignoreFamilySortx {get;set;}
    
    public Decimal comparisonTotal { get; set; }
    public Decimal MonthlySavingsAmount { get; set; }
    public Decimal MonthlyPercentSavingsAmount { get; set; }
    public Decimal AnnualSavingsAmount { get; set; }            
    
    public Boolean showPercentageBox {get;set;}
    public map<id,opportunity_location__c> oppLocs {
    	get{
    		return oppLocs;
    	}
    	set{
    		oppLocs = new Map<Id,Opportunity_location__c>();
    		oppLocs = value;
    	}
    }
	
	//Setter hack
    public Map<Id, OLI__c> OppLocOLIsMap {
		get{ return OppLocOLIs != null ? new Map<Id, OLI__c>(OppLocOLIs) : null; }
		set{ if(value != null) OppLocOLIs = ((Map<Id, OLI__c>)value).values(); }
	}
    
    public List<OLI__c> OppLocOLIs {get;set;}
    
    public string currentOpportunityLocationId {
        get{
            return currentOpportunityLocationId;
        }
        set{
            currentOpportunityLocationId = value;
            //lstLongDistanceProducts= new List<QuoteWrapper.QuoteLineItem>();
           if(oppLocs!= null){
            opptyLoc = oppLocs.get(value);
			term = opptyLoc.OpportunityLocationConfigurations__r[0].Term__c;
			display = opptyLoc.OpportunityLocationConfigurations__r[0].Display_on_Solution__c;
			solution = opptyLoc.OpportunityLocationConfigurations__r[0].Name;
			
            Building__c b = opptyLoc.Service_Location__r.Location__r.Building__r;
            locationAddress = new CompanyInfo(b,opptyLoc.Service_Location__r.Name, opptyLoc.Service_Location__r.Location__r.Room_Suite__c);

			   

            if( (opptyLoc.OpportunityLocationConfigurations__r != null) && (opptyLoc.OpportunityLocationConfigurations__r.size() > 0) ) {
            	List<OLI__c> currentOLIs = new List<OLI__c>();
				Map<string,SPC_Pricing__c> mapPricingNamePrices = new map<String,SPC_Pricing__c>();
				List<String> currentPriceIds = new List<String>();
				for(OLI__c oli :OppLocOLIs){ 
					currentPriceIds.add(oli.Price_ID__c);
				}
				
				For(SPC_Pricing__c prices : CatalogUtils.GetPricingByPricingID(currentPriceIds)){
					if(prices.Pricing_Name__c != null || (prices.SPC_Component__c != null && prices.SPC_Component__r.Display_Name__c != null))
						mapPricingNamePrices.put(prices.Price_ID__c,prices);
				}
								
            	for(OLI__c oli :OppLocOLIs){ 
					if(mapPricingNamePrices.containskey(oli.Price_id__c)){
						SPC_Pricing__c priceNamePrice = mapPricingNamePrices.get(oli.Price_id__c);
						if(priceNamePrice.SPC_Component__c != null && priceNamePrice.SPC_Component__r.Display_Name__c != null)
							oli.PP_Product_Pricing_Name__c = priceNamePrice.SPC_Component__r.Display_Name__c;
						else
							oli.PP_Product_Pricing_Name__c = oli.PP_Product_Pricing_Name__c.replace(' - ' + priceNamePrice.Pricing_Name__c, '').replace('-' + priceNamePrice.Pricing_Name__c, '');
					}
					
            		if((oli.OpportunityLocationConfiguration__r.Opportunity_Location__c == currentOpportunityLocationId) && oli.OpportunityLocationConfiguration__r.Active__c == true){
            			currentOLIs.add(oli);
            		}
            	}
            	
				lstProducts = QuoteWrapper.getConfigProductsFromOLIs(currentOlis);
				mapProducts = new Map<String,List<QuoteWrapper.Product>>();
			    for (QuoteWrapper.Product prod : lstProducts) {
					for(string groupname : prod.linesMap.keyset()){
						string groupNameVal = groupname == '' ? prod.Name : groupname;
						if(mapProducts.containskey(groupNameVal)){
							mapProducts.get(groupNameVal).add(prod);
						}
						else{
							mapProducts.put(groupNameVal,new List<QuoteWrapper.Product>{prod});
						}
					}
				}
            }
            
            hasLongDistance = false;
            /*for (QuoteWrapper.Product prod : lstProducts) {
            	
            	for (QuoteWrapper.QuoteLineItem line : prod.lines) {
	            	if (line.rawOLI.PP_LD_Interstate__c || line.rawOLI.PP_LD_Intrastate__c) {
	            		hasLongDistance = true;
	            		
	            		lstLongDistanceProducts.add(line);
	            	}
            	}
            }*/
            
            
            //Once you added all the products, remove from the main list those that were added to the LD list
            /*for (QuoteWrapper.QuoteLineItem ldLine : lstLongDistanceProducts) {
            	Integer posProd = 0;
            	
            	for (QuoteWrapper.Product prod : lstProducts) {
            		Integer posLine = 0;
            		
	            	for (QuoteWrapper.QuoteLineItem line : prod.lines) {
	            		if (line.rawOLI.Id == ldline.rawOLI.id) {
	            			prod.lines.remove(posLine);
	            			break;
	            		}
	            		posLine += 1;
	            	}
	            	
	            	if (prod.lines.size() == 0) {
	            		lstProducts.remove(posProd);
	            		break;
	            	}
	            	
	            	posProd += 1;
            	}
            }*/
            
            comparisonTotal = 0;
            if( opptyLoc.Oppty_Cost_Comparisons__r != null ) {
                for( Oppty_Cost_Comparison__c occ : opptyLoc.Oppty_Cost_Comparisons__r ) {
                    comparisonTotal += occ.MRC__c * occ.Qty__c;
                }
            }
            
            if( opptyLoc.Disconnect_Line_Items__r != null ) {
                for( Disconnect_Line_Item__c occ : opptyLoc.Disconnect_Line_Items__r ) {
                    if( occ.MRC__c != null )
                        comparisonTotal += occ.MRC__c;
                }
            }

            MonthlySavingsAmount = Math.abs(comparisonTotal - opptyLoc.MRC_Total__c);
            AnnualSavingsAmount = MonthlySavingsAmount * 12;

            if( comparisonTotal == 0 )
                MonthlyPercentSavingsAmount = 0;
            else
                MonthlyPercentSavingsAmount = MonthlySavingsAmount / comparisonTotal * 100;
                
            showPercentageBox =  (MonthlySavingsAmount <= comparisonTotal);         
           }
        }
    }
}