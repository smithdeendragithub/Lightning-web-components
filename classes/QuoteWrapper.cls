public with sharing class QuoteWrapper {
    public static List<LanguageTranslation__c> lang = [Select Original_Text__c, French_Text__c from LanguageTranslation__c];
    
    public class QuoteLineItem {
        
        public QuoteLineItem(OLI__c oli) {
            rawOLI = oli;           
            printDescription = cleanDescriptionSuffix(oli.PP_Product_Pricing_Name__c);
            oli.Product_Pricing_Display_French_Name__c = getFrenchText(oli.Product_Pricing_Display_Name__c);
            //oli.PP_Product_Pricing_Name_FR__c = getFrenchText(oli.PP_Product_Pricing_Name__c);
            //System.debug('PP_Product_Pricing_Name_c: ' + oli.PP_Product_Pricing_Name__c + ', FR:' + oli.PP_Product_Pricing_Name_FR__c);
            //System.debug('DQ_C: ' + oli.DQ__c + ', FR: ' + oli.DQ_FR__c);
            //System.debug('PP_Product_Pricing_Name_c: ' + oli.Product_Pricing_Display_Name__c + ', FR:' + oli.Product_Pricing_Display_French_Name__c);
        }
        
        public QuoteLineItem() {
          rawOLI = new OLI__c();
          rawOLI.Qty__c = 0;
          printDescription = '';
        }
    
      private String cleanDescriptionSuffix(String originalString) {
          String cleanString = originalString;
          
          for(String suffix : RemoveSuffixes__c.getAll().keySet()) {
              if (originalString.endsWith(suffix)) {
                  String replaceWith = RemoveSuffixes__c.getAll().get(suffix).NewSuffix__c;
                  replaceWith = (replaceWith == null) ? '' : replaceWith;
                  cleanString = originalString.replace(suffix, replaceWith);
                  break;
              }
          }
      
          return cleanString;
      }
        
        public OLI__c rawOLI {get;set;}
        public String printDescription {get;set;} 
        public List<SelectOption> groupselectOption{get;set;}
        public String selectedgroup{get;set;}
    }

    public class Product {
        public string Name {get;set;}
        public string FrenchName {get;set;}
        public string ProductId {get;set;}
        public string SFDCId {get;set;}
        public string externalID{get;set;}
        public String productFamilyId{get;set;}
        public String Salesproduct{get;set;}  
        public String salesproductgroup{get;set;}
        public List<QuoteLineItem> lines {get;set;}
    	public Map<string,List<QuoteLineItem>> linesMap {get;set;}
        public Set<String> lstoftagname{get;set;}
        public Decimal total {get;set;}
        public boolean validatePickVal{get;set;}
        public Decimal NRCTotal {get;Set;}
        public Product() {
          lines = new List<QuoteLineItem>();
        }
        
        public Product(string in_name, string externalId, string internalId) {
        	Name = in_name;
          	ProductId = externalId;
          	SFDCId = internalId;
          	lines = new List<QuoteLineItem>();
      		linesMap = new Map<string,List<QuoteLineItem>>();
          	total = 0;
      		NRCTotal = 0;
        }
    }
    
    public class ProductFamily {
      public string Name {get;set;}
      public string SFDCId {get;set;}
      public List<Product> products {get;set;}
      public List<SPC_Product__c> spcproducts{get;set;}
      public Decimal total {get;set;}
      
      public ProductFamily(string in_Name, Id in_Id ) {
        Name = in_Name;
        SFDCId = in_Id;
        products = new List<Product>();
        total = 0;
      }
    }
    
    public static String getFrenchText(String text){
        String frenchText = text;
        for (LanguageTranslation__c obj : lang){
            if (obj.Original_Text__c == text){
            	frenchText = obj.French_Text__c;
                break;
            }	    
        }
        return frenchText;
    }
    
    public static List<Product> getConfigProductsWithLineItems(Id configId, Boolean sortForPrint, Boolean ignoreFamilySort,  List<OLI__c> oppyLineItems){
        List<Product> lstProducts = new List<Product>();
        if(oppyLineItems != null){
          Product currentProduct = null;
          for( OLI__C oli : oppyLineItems ) {
              if  (oli.Product_Family_Product__c != null)  {
                  if( (currentProduct == null) || (!currentProduct.Name.equals(oli.Product_Family_Product__c))) {
                  		currentProduct = new Product(oli.Product_Family_Product__c, oli.PP_SalesProductExternalID__c, oli.SPC_Sales_Product__c);
            			currentProduct.FrenchName = getFrenchText(oli.Product_Family_Product__c);
                      	lstProducts.add(currentProduct);
                  }
          QuoteLineItem qli = new QuoteLineItem(oli);
          currentProduct.lines.add(qli);
          string oliGroupName = oli.Group_Name__c == null ? oli.Product_Family_Product__c : oli.Group_Name__c;
          if(currentProduct.linesMap.containskey(oliGroupName)){
            List<QuoteLineItem> qlis = currentProduct.linesMap.get(oliGroupName);
            qlis.add(qli);
            currentProduct.linesMap.put(oliGroupName,qlis);
          }
          else{
            currentProduct.linesMap.put(oliGroupName,new List<QuoteLineItem>{qli});
          }
                  currentProduct.total += oli.MRC_Total__c;
              }
          }
        }
        
        return lstProducts;
    }
    
    public static List<Product> getConfigProductsFromOLIs(List<OLI__c> oppyLineItems){
        List<Product> lstProducts = new List<Product>();
        Product currentProduct = null;
    Map<id,Product> currentProductMap = new Map<id,Product>();

        for( OLI__C oli : oppyLineItems ) {
            if  (oli.PP_Sales_Product__c != null)  {
                if( !currentProductMap.containsKey(oli.SPC_Sales_Product__c)) {
          			system.debug('create new current prod: ' + oli.PP_Sales_Product__c + ' ' +  oli.PP_SalesProductExternalID__c + ' ' +  oli.SPC_Sales_Product__c);
                    currentProduct = new Product(oli.PP_Sales_Product__c, oli.PP_SalesProductExternalID__c, oli.SPC_Sales_Product__c);
          			currentProduct.FrenchName = getFrenchText(oli.Product_Family_Product__c);
                    currentProductMap.put(oli.SPC_Sales_Product__c,currentProduct);
          			lstProducts.add(currentProduct);
                }
        		else
          			currentProduct = currentProductMap.get(oli.SPC_Sales_Product__c);
                
        		QuoteLineItem qli = new QuoteLineItem(oli);
                currentProduct.lines.add(qli);
        		string oliGroupName = oli.Group_Name__c == null ? oli.PP_Sales_Product__c : oli.Group_Name__c;
                if(currentProduct.linesMap.containskey(oliGroupName)){
                  	List<QuoteLineItem> qlis = currentProduct.linesMap.get(oliGroupName);
                  	qlis.add(qli);
                  	currentProduct.linesMap.put(oliGroupName,qlis);
                }
                else{
                  	currentProduct.linesMap.put(oliGroupName,new List<QuoteLineItem>{qli});
                }
          
                currentProduct.total += oli.MRC_Total__c;
            }
        }
    
        return lstProducts;
    }
    
    public static List<ProductFamily> getConfigFamilies(Id configId){
      
    List<OLI__c> oppyLineItems = getOLIs(configId, false, false);
        
        List<ProductFamily> lstFamilies = new List<ProductFamily>();
        
        ProductFamily currentFamily = null;
        for( OLI__C oli : oppyLineItems ) {
    
            if  (oli.PP_Product_Family__c != null)  {
                if( (currentFamily == null) || (!currentFamily.Name.equals(oli.PP_Product_Family__c))) {
                  currentFamily = new ProductFamily(oli.PP_Product_Family__c, oli.id);
                  lstFamilies.add(currentFamily);
                }
        
              if  (oli.PP_Sales_Product__c != null)  {
                  if( (currentFamily.products.isEmpty()) || (!currentFamily.products[currentFamily.products.size()-1].Name.equals(oli.PP_Sales_Product__c))) {
                      Product currentProduct = new Product(oli.PP_Sales_Product__c, oli.PP_SalesProductExternalID__c, oli.id);
                      
                      currentFamily.Products.add(currentProduct);
                  }
                  currentFamily.Products[currentFamily.Products.size()-1].lines.add(new QuoteLineItem(oli)); 
                  currentFamily.Products[currentFamily.Products.size()-1].total += oli.MRC_Total__c;
                  currentFamily.total += oli.MRC_Total__c;
              }
            }
        }
      
      return lstFamilies;
    }
  
  private static List<OLI__c> getOLIs(Id configId, Boolean sortForPrint, Boolean ignoreFamilySort) {
    return ApexUtils.retrieveObjectsFromFieldSets(OLI__c.getsObjectType()
                                  ,new List<Set<String>>
                                  {
                                    SchemaUtils.RetrieveFullObjectFieldSet(OLI__c.getsObjectType())
                                    ,new Set<String> { 'Parent_Opportunity_Line_Item__r.PP_SalesRatePlanPricingExternalID__c' }
                                  }
                                  ,'OpportunityLocationConfiguration__c=\'' + configId + '\' AND (PP_Package_Feature__c = false OR PP_Package_Feature__c = null)'
                                  ,sortForPrint
                                ? (!ignoreFamilySort ? 'PP_Product_Family_Sort__c,  PP_Sales_Product_Sort__c, ' : '') + 'MRC__c DESC, Qty__c DESC'
                                : 'PP_Product_Family_Sort__c,  PP_Sales_Product_Sort__c,  PP_Feature_Grouping_Sort__c, PP_Sales_Rate_Plan_Description_Sort__c');
  }
  
  public static List<ProductFamily> sortListByProductName(List<ProductFamily> unsortedList) {
    
    Map<String, ProductFamily> productNameToProductFamily = new Map<String, ProductFamily>();
    for(ProductFamily QPF : unsortedList)
      productNameToProductFamily.put(QPF.name,QPF);
    
    List<String> productNamelst = new List<String>(productNameToProductFamily.keyset());
    productNamelst.sort();
    
    List<ProductFamily> sortedList = new List<ProductFamily>();
    for(String s : productNamelst)
      sortedList.add(productNameToProductFamily.get(s));
    
    return sortedList;
  }
}