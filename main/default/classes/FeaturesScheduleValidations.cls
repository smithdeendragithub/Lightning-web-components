/*  
  @author = Sebastian Kessel
  @date = Jan, 3rd 2012

  This class contains all the methods needed to validate that the FeaturesSchedule (PhoneNumbers) selected match
  correctly against the active solution entered 
*/
public class FeaturesScheduleValidations implements TestUtils.ITestableClass {

    public class ValidationException extends Exception {}

    public OpportunityLocationConfiguration__c OL {get;set;}
    public List<OLI__c> products {get;set;}
    public List<OLI__c> features {get;set;}
    public Boolean hasOrphanOLIs {get;set;}
    public Map<Id, List<wrapFeatureContent>> packageFeatures {get;set;}
    public Decimal totalLines {get;set;}
    public boolean isWebserviceCalled{get;set;}
    
    public List<String> errors {get;set;}
    public List<CatalogUtils.SPCPricingView> newview{get;set;}
    public Map<String,String> packageItemToPriceId{get;set;}  
    public Map<Id, wrapFeatureforOrderSummary> featureforOrderSummary{get;set;}
    public Set<Id> parentOliIds {get;set;}
    public Map<String, List<OLI__c>> childFeatureMap{get;set;}
    
    public FeaturesScheduleValidations(){
      
      throw new ValidationException('Must Specify an Id on the constructor');
    }
    
    public FeaturesScheduleValidations(Id olID){
        isWebserviceCalled=false;
        totalLines = 0;
        products = new List<OLI__c>();
        features = new List<OLI__c>();
        packageFeatures = new Map<Id, List<wrapFeatureContent>>();
        errors = new List<String>();
        //newview=new List<CatalogUtils.SPCPricingView>();
        hasOrphanOLIs = false;
        packageItemToPriceId=new  Map<String,String>();
        
        OL = [Select Id,Term__c,Bandwidth__c,Opportunity_Location__r.Opportunity__C,
                         Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_Hash__c,
                         Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c,
                         Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Net_Classification__c,
                         Opportunity_Location__r.Service_Location__r.Location__r.Building__R.Serving_LSO__r.LSO_CLLI__c,Opportunity_Location__r.Term__c
                      from OpportunityLocationConfiguration__c Where Active__c=true AND Opportunity_Location__c=:olID LIMIT 1 ];
            
        
        getProducts();
        getFeatures();
    }
    
    public FeaturesScheduleValidations(Set<Id> olIDs){
        
        featureforOrderSummary = new Map<Id, wrapFeatureforOrderSummary>();
        Set<Id> solutionIds = new Set<Id>();
        List<OpportunityLocationConfiguration__c> solutions = [Select Id,Term__c,Bandwidth__c,Opportunity_Location__c,Opportunity_Location__r.Opportunity__C,
                         Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_Hash__c,
                         Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c,
                         Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Net_Classification__c,
                         Opportunity_Location__r.Service_Location__r.Location__r.Building__R.Serving_LSO__r.LSO_CLLI__c,Opportunity_Location__r.Term__c
                      from OpportunityLocationConfiguration__c Where Active__c=true AND Opportunity_Location__c in :olIDs ];
        
        for(OpportunityLocationConfiguration__c ol :solutions){
            if(!featureforOrderSummary.containskey(ol.Opportunity_Location__c)){
                wrapFeatureforOrderSummary wf = new wrapFeatureforOrderSummary(ol);
                wf.OL =ol;
                featureforOrderSummary.put(ol.Opportunity_Location__c,wf);
                solutionIds.add(ol.ID);
            }           
        }
        
        Map<Id, List<OLI__c>> productMap = getProducts(solutionIds);
        Map<Id, List<OLI__c>> featureMap = getFeatures(solutionIds) ;        
        childFeatureMap = getChildFeatures(solutionIds) ;
        for(Id id : featureforOrderSummary.keyset()){
            wrapFeatureforOrderSummary wf =featureforOrderSummary.get(id);
            wf.products = productMap.get(wf.OL.Id)!= null?productMap.get(wf.OL.Id):new List<OLI__c>();         
            wf.features = featureMap.get(wf.OL.Id) != null?featureMap.get(wf.OL.Id):new List<OLI__c>();         
            getMoreFeatures(wf);  
            for (OLI__c oli : wf.products) {  
                if (oli.Qty__c != null && oli.Qty__c>0) {
                  wf.totalLines += oli.Qty__c;
                }
            }              
        }            
        
    }
    
    
    private void getProductFeaturePricing(String salesproductExternalId)
    {
        system.debug('getProductFeaturePricing: ' + OL);
        system.debug('getProductFeaturePricing: ' + Integer.valueof(salesProductExternalId));
        if(!isWebserviceCalled)
        {
            newView = filterExpiredItem(getProductFeaturePricing(OL, Integer.valueof(salesProductExternalId)));
            isWebserviceCalled=true;
        }
        system.debug('Web service call'+newView);
    }
    
    private List<CatalogUtils.SPCPricingView> getProductFeaturePricing(OpportunityLocationConfiguration__c oppLocation, Integer salesProductExternalId) {
        /*Set<Integer> productExternalIDs = new Set<Integer>{salesProductExternalId};*/
/*      String wirecenterCLLI = oppLocation.Opportunity_Location__r.Service_Location__r.Location__r.Building__R.Serving_LSO__r.LSO_CLLI__c;
        
        integraWS.ListOfInt accessTechsList = new integraWS.ListOfInt();
        accessTechsList.ListOfIntEntry = getaccesstech(oppLocation);
        
        integraWS.ListOfInt spIdsList = new integraWS.ListOfInt();
        spIdsList.ListOfIntEntry = new List<Integer>(productExternalIDs);
        
        integraWS.ListOfInt termsList = new integraWS.ListOfInt();
        termsList.ListOfIntEntry = new List<integer>{Integer.valueof(oppLocation.Term__c)};
        
        integraWS.ArrayOfSFSPCPricingView retval = new integraWS.ArrayOfSFSPCPricingView();*/
        List<CatalogUtils.SPCPricingView> retval = new List<CatalogUtils.SPCPricingView>();
        if (salesProductExternalId != null){
            try{
                /*System.debug('Calling to get Pricing - Build Hash: ' + oppLocation.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_Hash__c);
                System.debug('Calling to get Pricing - spIdsList: ' + spIdsList);
                System.debug('Calling to get Pricing - termsList: ' + termsList);
                System.debug('Calling to get Pricing - wirecenterCLLI: ' + wirecenterCLLI);*/
                 retval = CatalogUtils.GetProductFeaturePricingViews(new List<Integer>(), 0, oppLocation.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_Hash__c, new List<Integer>{(salesProductExternalId)}, new List<integer>());
            /*  retval = !Test.isRunningTest()
                            ? integraWSEndpointMediator.Endpoint.GetProductFeaturePricing(accessTechsList
                                                                ,(oppLocation.Bandwidth__c!= NULL) ? Decimal.valueof(oppLocation.Bandwidth__c) : 0
                                                                ,wirecenterCLLI
                                                                ,oppLocation.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_Hash__c
                                                                ,spIdsList
                                                                ,termsList
                                                                ,UserInfo.getSessionId()
                                                                ,CustomSettingUtils.SFDCCallbackEndpoint)
                            : Test_ManageFeaturesSchedule.callDummyMethod();*/
            }
            catch(Exception ex){
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.info, 'Web service Call Failed:' + ex.getmessage()));
            }
        }       
        return retval;
    }
    
    private List<Integer> getaccesstech(OpportunityLocationConfiguration__c oppLocation) {
        
        List<integer> accessTechs = new List<integer>();
        //accessTechs.add(2);
        /*   List<integer> newaccessTechs = new List<integer>();
        Building__c building =[Select id,(Select Access_Technology__r.Access_Technology_ID__c From Access_Availabilities__r)
        From Building__c where id=:oppLocation.Opportunity_Location__r.Service_Location__r.Location__r.Building__c] ; 
        if(building.Access_Availabilities__r.size()>0)
        {
            for(Building_Access_Availability__c BAA:building.Access_Availabilities__r)
                newaccessTechs.add(Integer.valueof(BAA.Access_Technology__r.Access_Technology_ID__c));
            
            for(Integer access:newaccessTechs)
                accessTechs.add(access);
        }
        else
        {
            //accessTechs.add(0);
        }*/
        return accessTechs;
    }
    
    private List<CatalogUtils.SPCPricingView> filterExpiredItem(List<CatalogUtils.SPCPricingView> view){    
        Integer count = (view != NULL ) ? view.size() : 0;      
        for(Integer i=count-1; i>=0; i--){
            if(view[i].pricing.is_expired__c)
                view.remove(i);
        }
        return view;
    }
    
    private void getProducts(){
        //Get the products I need to validate against
        for (OLI__c oli : [select  Id,DQ__c,  
                                   PP_Sales_Rate_Plan_Description__c, 
                                   OpportunityLocationConfiguration__c, 
                                   Qty__c,
                                   PP_Sales_Product__c,
                                   SPC_Sales_Product_Component_Id__c,
                                   SPC_Component_Id__c
                            from   OLI__c
                            where  OLI__c.OpportunityLocationConfiguration__c = :OL.Id
                            and    OLI__c.PP_Voice_Line__c = true
                            order by PP_Sales_Rate_Plan_Description_Sort__c]) {        
            products.add(oli);  
            
            //Set this false for now Note for H.G..Most likely intead of Product_PricingId will be checking with PP_External_ID
            hasOrphanOLIs=false;
            if (oli.Qty__c != null && oli.Qty__c>0) {
              totalLines += oli.Qty__c;
            }
        }
    }
    
    
    private void getFeatures(){
        //Get the features (for the products) I need to validate against
        //I want the packages to go first (per account, then per line), so that's how I query them
       
         map<String,ID> productDescriptionNameToId=new Map<String,Id>();
         List<integer> productIds = new List<integer>();
        for (OLI__c oli : [select  Id,  
                                   OpportunityLocationConfiguration__c, 
                                   Parent_Opportunity_Line_Item__c,
                                   Qty__c,DQ__c,Parentname__c,
                                   Product_Family_Id__c,Product_Family_Product__C,
                                   PP_AdditionalInformationPrompt__c,
                                   PP_Sales_Product__c,
                                   PP_Sales_Rate_Plan_Description__c, 
                                   PP_Package__c,
                                   PP_Per_Account__c,
                                   PP_Package_Feature__c,
                                   PP_Product_Family__c,
                                   PP_SalesProductRatePlanExternalID__c,
                                   PP_SalesProductExternalID__c,
                                   PP_Voice_Line_Option__c,
                                   SPC_Sales_Product_Component_Id__c,
                                   SPC_Component_Id__c
                            from   OLI__c
                            where  OLI__c.OpportunityLocationConfiguration__c = :OL.Id
                            and    (OLI__c.PP_Voice_Line_Option__c = true
                                    or OLI__c.PP_Package_Feature__c = true)
                            order by OLI__c.PP_Package__c desc,
                                     OLI__c.PP_Per_Account__c desc,
                                     OLI__c.PP_Sales_Rate_Plan_Description_Sort__c]) {
        

            features.add(oli);
            
            List<wrapFeatureContent> myFeatures = new List<wrapFeatureContent>();
            
          
             if (oli.PP_Package__c  && oli.PP_SalesProductRatePlanExternalID__c== null) {
                   hasOrphanOLIs = false;

                   if(newView==NULL)
                   {
                        system.debug('oli.PP_SalesProductExternalID__c: ' + oli.PP_SalesProductExternalID__c);
                        if(oli.PP_SalesProductExternalID__c != null)
                            productIds.add(integer.valueof(oli.PP_SalesProductExternalID__c));

                         getProductFeaturePricing(oli.PP_SalesProductExternalID__c);

                   }
                //Add the child OLIs from whatever has been saved
                productDescriptionNameToId.put(oli.PP_Sales_Rate_Plan_Description__c,oli.id);
                for (OLI__c olif : [select  Id,  
                                           PP_Sales_Rate_Plan_Description__c, 
                                           Parent_Opportunity_Line_Item__c,
                                           Qty__c,
                                           PP_SalesProductRatePlanExternalID__c,
                                           PP_AdditionalInformationPrompt__c,
                                           SPC_Sales_Product_Component_Id__c,
                                           SPC_Component_Id__c
                                    from   OLI__c
                                    where  OLI__c.OpportunityLocationConfiguration__c = :OL.Id
                                    and    OLI__c.PP_Package_Feature__c = true
                                    and    OLI__c.Parent_Opportunity_Line_Item__c = :oli.Id
                                    order by OLI__c.PP_Package__c  desc,
                                             OLI__c.PP_Per_Account__c desc,
                                             OLI__c.PP_Sales_Rate_Plan_Description_Sort__c]) {
                  
                   
                    wrapFeatureContent oneContent = new wrapFeatureContent();
                    
                    oneContent.title = olif.PP_Sales_Rate_Plan_Description__c;
                    oneContent.salesProductRatePlanExternalId = olif.PP_SalesProductRatePlanExternalID__c;
                    //oneContent.productPricingId = olif.Product_Pricing__c;
                    oneContent.additionalInformationPrompt = oli.PP_AdditionalInformationPrompt__c;
                    oneContent.spcSalesProductComponentId = string.valueof(olif.SPC_Sales_Product_Component_Id__c);
                    oneContent.spcComponentId = string.valueof(olif.SPC_Component_Id__c);                    
                    myFeatures.add(oneContent);                 
                  }
                
                 packageFeatures.put(oli.Id, myFeatures);
            }
                        
        }
        System.debug('newview: ' + newview);
        if(newView != NULL)
        {
            Set<decimal> parentSalesProdComponentIds = new Set<decimal>();
            for(CatalogUtils.SPCPricingView pricingView:newView)
            {
                List<wrapFeatureContent> myFeatures = new List<wrapFeatureContent>();
                if(productDescriptionNameToId.containsKey(pricingView.pricing.Component_name__c))
                {
                    if(pricingView.children != null && pricingView.children.size() > 0)
                    {
                            for(CatalogUtils.SPCPricingView childView :pricingView.children)
                            {
                                if(childView.pricing.Component_Group__c =='Included')
                                {
                                    System.debug('Child: ' + childView);
                                    packageItemToPriceId.put(childView.pricing.Component_Name__c,childView.pricing.Price_id__c);
                                    wrapFeatureContent oneContent = new wrapFeatureContent();
                                    oneContent.title = childView.pricing.Component_Name__c;
                                    oneContent.salesProductRatePlanExternalId = String.valueof(childView.pricing.Sales_Product_Id__c);
                                    oneContent.spcSalesProductComponentId = String.valueof(childView.pricing.Sales_Product_Component_Id__c);
                                    oneContent.spcComponentId = String.valueof(childView.pricing.Component_ID__c);
                                     if(childView.pricing.Feature_Schedule_Prompt__c!=NULL)
                                        oneContent.additionalInformationPrompt = childView.pricing.Feature_Schedule_Prompt__c;                                      
                                    myFeatures.add(oneContent);        
                                }
                            }
                            
                             packageFeatures.put(productDescriptionNameToId.get(pricingView.pricing.Component_Name__c), myFeatures);
                    }
                    else{
                        //Check if the parent row has features using the new relationship records
                        parentSalesProdComponentIds.add(pricingView.pricing.Sales_Product_Component_ID__c);
                    }
                }
            }
            Map<decimal,List<CatalogUtils.SPCPricingView>> childFeaturePricing = CatalogUtils.GetProductFeaturePricingWithFeatureRelationship(productIds,OL.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c,parentSalesProdComponentIds,OL.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Net_Classification__c == 'On-net');

            //get features for parent row if they have relationship records
            for(CatalogUtils.SPCPricingView pricingView:newView)
            {
                List<wrapFeatureContent> myFeatures = new List<wrapFeatureContent>();
                if(productDescriptionNameToId.containsKey(pricingView.pricing.Component_name__c))
                {
                    if(pricingView.children == NULL || pricingView.children.size() == 0)
                    {
                        if(childFeaturePricing.containsKey(pricingView.pricing.Sales_Product_Component_Id__c)){
                            for(CatalogUtils.SPCPricingView childView :childFeaturePricing.get(pricingView.pricing.Sales_Product_Component_Id__c)){
                                if(childView.pricing.Component_Group__c =='Included'){
                                        System.debug('Child: ' + childView);
                                        packageItemToPriceId.put(childView.pricing.Component_Name__c,childView.pricing.Price_id__c);
                                        wrapFeatureContent oneContent = new wrapFeatureContent();
                                        oneContent.title = childView.pricing.Component_Name__c;
                                        oneContent.salesProductRatePlanExternalId = String.valueof(childView.pricing.Sales_Product_Id__c);
                                        oneContent.spcSalesProductComponentId = String.valueof(childView.pricing.Sales_Product_Component_Id__c);
                                        oneContent.spcComponentId = String.valueof(childView.pricing.Component_ID__c);
                                         if(childView.pricing.Feature_Schedule_Prompt__c!=NULL)
                                            oneContent.additionalInformationPrompt = childView.pricing.Feature_Schedule_Prompt__c;                                      
                                        myFeatures.add(oneContent);        
                                }
                            }
                            packageFeatures.put(productDescriptionNameToId.get(pricingView.pricing.Component_Name__c), myFeatures);
                        }

                    }
                }
            }

        }
    }
    
    public Boolean validate(List<CN__c> CNs, List<CN_Feature__c> CNFeatures) {
        Boolean result = true;
        
        errors.clear();
        
        //Validate for Total Qty of Lines = Total CNs
        result = validateOverallLineQty(CNs);
        
        //Validate that the Number of lines matches the Qty on the OLI      
        result = validateLineQty(CNs) && result;
        
        //Validate for features that are no longer selected on the active solution
        result = validateInactiveFeatures(CNFeatures) && result;
        
        //Validate that the Number of features matches the Qty on the OLI       
        result = validateFeatureQty(CNFeatures) && result;
        
        return result;
    }
    
    public Boolean validateOverallLineQty(List<CN__c> CNs) {
        Boolean result = true;  
        
        //This evaluation could be done in the next step. It is done here for the sake of clarity. Performance/limits impact is minimal
        try {
            Decimal Qty = 0;
            Decimal lineCount = 0;
                
            for (OLI__c prod : products) {
                Qty += prod.Qty__c;
            }
                        
            //Now Count how many CNs were entered per product
            for (CN__c cn : CNs) {
                lineCount += 1;
            }
            
            if (lineCount > Qty) {
                errors.add('There are ' + lineCount + ' Phone Lines saved. Maximum is : ' + Qty );
                result = result && false;
            }

            
        } catch (Exception e) {
            errors.add(e.getMessage());
            result = false;
        }
        
        return result;
    }
    
    public Boolean validateLineQty(List<CN__c> CNs) {
        Boolean result = true;  
        
        try {
            for (OLI__c prod : products) {
                Decimal Qty = prod.Qty__c;
                Decimal lineCount = 0;
                
                //Now Count how many CNs were entered per product
                for (CN__c cn : CNs) {
                    if (cn.Opportunity_Line_Item__c == prod.id) {
                        lineCount += 1;
                    }
                }
                
                if (lineCount > Qty) {
                    errors.add('There are ' + lineCount + ' lines assigned to ' + prod.PP_Sales_Rate_Plan_Description__c + '. The Maximum is : ' + Qty );
                    result = result && false;
                }
            }
            
        } catch (Exception e) {
            errors.add(e.getMessage());
            result = false;
        }
            
        return result;
    }
    
    
    public Boolean validateFeatureQty(List<CN_Feature__c> CNFeatures) {
        Boolean result = true;
            
        try {
            for (OLI__c feat : features) {
                Decimal Qty = 0;
                Decimal lineCount = 0;
                String description = '';
                Boolean perAccount = false; 
                
                if (! feat.PP_Package_Feature__c ) {
                    Qty = feat.Qty__c; 
                    description = feat.PP_Sales_Rate_Plan_Description__c;
                    perAccount = feat.PP_Per_Account__c ;
                } else {
                    //If it's a package feature, then the Qty to validate against is its parent's.
                    //Instead of SOQL, get the parent by iterating through the existing features
                    OLI__c parentOLI = findParentOLI(feat);
                    
                    description = feat.PP_Sales_Rate_Plan_Description__c;
                    perAccount = parentOLI.PP_Per_Account__c;
                    
                    
                    
                    
                    if (parentOLI != null) {
                        Qty = parentOLI.Qty__c;
                    } else {
                        Qty = 0;
                        errors.add('Opportunity Line Item ' + description + ' refers to a parent that does not exist or it is a Package Feature that is orphan.');
                        result = false;
                    }
                }
                    
                //Now Count how many CNs were entered per product
                for (CN_Feature__c cnfeat : CNFeatures) {
                    if (cnfeat.Opportunity_Line_Item__c == feat.id) {
                        lineCount += 1;
                    }
                }
                
                //Only validate for items that are NOT "per Account Packages". 
                //Those ara available for all lines
                if (lineCount > Qty && (!perAccount)) {
                    errors.add('There are ' + lineCount + ' lines with the feature ' + description + ' selected. The Maximum is : ' + Qty );
                    result = false;
                }
            }
        
        } catch (Exception e) {
            errors.add(e.getMessage());
            result = false;
        }   
            
        return result;
    }
    
    public Boolean validateInactiveFeatures(List<CN_Feature__c> CNFeatures) {
        Boolean result = true;  
        
        try {
            for (CN_Feature__c cnfeat : CNFeatures) {
                //For each feature being passed, ensure that it correspond to an existing feature
                OLI__c matchingOLI = findOLI(cnfeat.Opportunity_Line_Item__c);
                
                if (matchingOLI == null) {
                    //The OLI being passed is not found
                    errors.add('Feature ' + cnfeat.Name + ' no longer exists in the Active Solution');
                    result = false;
                } else {
                    //If I found something, must check that the parent ALSO exists. 
                    //Otherwise, that means that the feature matches an artifically created OLI that no longer exists
                    
                    //First evaluate the parent
                    if (matchingOLI.Parent_Opportunity_Line_Item__c != null) {
                        OLI__c matchingParentOLI = findOLI(matchingOLI.Parent_Opportunity_Line_Item__c);
                        
                        if (matchingParentOLI == null) {
                            //The OLI being passed is not found
                            errors.add('Feature ' + cnfeat.Name + ' no longer exists in the Active Solution');
                            result = false;
                        }
                    } else {
                        //If it's null, then just check that it is a package feature
                        //package features should never exist without a Parent OLI
                        /*
                        if (matchingOLI.PP_Package_Feature__c == 'Yes') {
                            //The OLI being passed is not found
                            errors.add('Feature ' + cnfeat.Name + ' no longer exists in the Active Solution');
                            result = false;
                        }
                        */
                    }
                    
                }
            }
        
        } catch (Exception e) {
            errors.add(e.getMessage());
            result = false;
        }
        
        return result;
    }
    
    private OLI__c findOLI(Id oliIdToFind) {
                        
        for (OLI__c oli : features) {
            
            if (oli.Id == oliIdToFind) {
                return oli;
            } 
        }
        
        return null;
    }
    
    private OLI__c findParentOLI(OLI__c child) {
                        
        for (OLI__c oli : features) {
            
            if (oli.Id == child.Parent_Opportunity_Line_Item__c) {
                return oli;
            } 
        }
        
        return null;
    }
    
    public class wrapFeatureContent {
        public String title {get;set;}
        public String additionalInformationPrompt {get;set;}
        public string salesProductRatePlanExternalId {get;set;}
        public Id productPricingId {get;set;}
        public string spcSalesProductComponentId {get;set;}
        public string spcComponentId {get;set;}
        
        public wrapFeatureContent(){
            title = '';
            additionalInformationPrompt='';
            salesProductRatePlanExternalId=null;
            productPricingId=null;
            spcSalesProductComponentId = '';
            spcComponentId = '';
        }
    }
    
    public class wrapFeatureforOrderSummary {
        public OpportunityLocationConfiguration__c OL {get;set;}
        public List<OLI__c> products {get;set;}
        public List<OLI__c> features {get;set;}
        public Map<Id, List<wrapFeatureContent>> packageFeatures {get;set;}
        public Boolean hasOrphanOLIs {get;set;}
        public Decimal totalLines {get;set;}
        public boolean isWebserviceCalled{get;set;}
        
        public List<String> errors {get;set;}
        public List<CatalogUtils.SPCPricingView> newview{get;set;}
        public Map<String,String> packageItemToPriceId{get;set;}  
                
        public wrapFeatureforOrderSummary(OpportunityLocationConfiguration__c ol){
            OL = ol;
            products = new List<OLI__c>();
            features = new List<OLI__c>();
            packageFeatures=new Map<Id, List<wrapFeatureContent>>();

            isWebserviceCalled=false;
            totalLines = 0;
            errors = new List<String>();
 
            hasOrphanOLIs = false;
            packageItemToPriceId=new  Map<String,String>();
        }
    } 
    
    private Map<Id, List<OLI__c>> getProducts(Set<Id> solutionIds){
        //Get the products I need to validate against
        Map<Id, List<OLI__c>> productMap = new Map<Id, List<OLI__c>>();        
        for (OLI__c oli : [select  Id,DQ__c,  
                                   PP_Sales_Rate_Plan_Description__c, 
                                   OpportunityLocationConfiguration__c, 
                                   Qty__c,
                                   PP_Sales_Product__c,
                                   SPC_Sales_Product_Component_Id__c,
                                   SPC_Component_Id__c
                            from   OLI__c
                            where  OLI__c.OpportunityLocationConfiguration__c in :solutionIds
                            and    OLI__c.PP_Voice_Line__c = true
                            order by PP_Sales_Rate_Plan_Description_Sort__c]) {  
            if(!productMap.containskey(oli.OpportunityLocationConfiguration__c))                 
               productMap.put(oli.OpportunityLocationConfiguration__c,new List<OLI__c>{oli});                    
            else
              productMap.get(oli.OpportunityLocationConfiguration__c).add(oli);                                   
        }
        
        return productMap;
    }
    
    
    private Map<Id, List<OLI__c>> getFeatures(Set<Id> solutionIds){
        //Get the features (for the products) I need to validate against
        //I want the packages to go first (per account, then per line), so that's how I query them
        Map<Id, List<OLI__c>> featureMap = new Map<Id, List<OLI__c>>(); 
         map<String,ID> productDescriptionNameToId=new Map<String,Id>();
         List<integer> productIds = new List<integer>();
         parentOliIds = new Set<Id>();
        for (OLI__c oli : [select  Id,  
                                   OpportunityLocationConfiguration__c, 
                                   Parent_Opportunity_Line_Item__c,
                                   Qty__c,DQ__c,Parentname__c,
                                   Product_Family_Id__c,Product_Family_Product__C,
                                   PP_AdditionalInformationPrompt__c,
                                   PP_Sales_Product__c,
                                   PP_Sales_Rate_Plan_Description__c, 
                                   PP_Package__c,
                                   PP_Per_Account__c,
                                   PP_Package_Feature__c,
                                   PP_Product_Family__c,
                                   PP_SalesProductRatePlanExternalID__c,
                                   PP_SalesProductExternalID__c,
                                   PP_Voice_Line_Option__c,
                                   SPC_Sales_Product_Component_Id__c,
                                   SPC_Component_Id__c
                            from   OLI__c
                            where  OLI__c.OpportunityLocationConfiguration__c in :solutionIds
                            and    (OLI__c.PP_Voice_Line_Option__c = true
                                    or OLI__c.PP_Package_Feature__c = true)
                            order by OLI__c.PP_Package__c desc,
                                     OLI__c.PP_Per_Account__c desc,
                                     OLI__c.PP_Sales_Rate_Plan_Description_Sort__c]) {
        

//            features.add(oli);
            if(!featureMap.containskey(oli.OpportunityLocationConfiguration__c))                 
               featureMap.put(oli.OpportunityLocationConfiguration__c,new List<OLI__c>{oli});                    
            else
              featureMap.get(oli.OpportunityLocationConfiguration__c).add(oli);                                   

            parentOliIds.add(oli.Id);
        }
        return featureMap;
    }
    
    private Map<String, List<OLI__c>> getChildFeatures(Set<Id> solutionIds){
        //Get the features (for the products) I need to validate against
        //I want the packages to go first (per account, then per line), so that's how I query them
        Map<String, List<OLI__c>> childFeatureMap = new Map<String, List<OLI__c>>(); 
         map<String,ID> productDescriptionNameToId=new Map<String,Id>();
         List<integer> productIds = new List<integer>();
         String key ='';
        for (OLI__c olif : [select  Id, 
                                    OpportunityLocationConfiguration__c, 
                                   PP_Sales_Rate_Plan_Description__c, 
                                   Parent_Opportunity_Line_Item__c,
                                   Qty__c,DQ__c,
                                   PP_SalesProductRatePlanExternalID__c,
                                   PP_AdditionalInformationPrompt__c,
                                   SPC_Sales_Product_Component_Id__c,
                                   SPC_Component_Id__c
                            from   OLI__c
                            where  OLI__c.OpportunityLocationConfiguration__c in :solutionIds
                            and    OLI__c.PP_Package_Feature__c = true
                            and    OLI__c.Parent_Opportunity_Line_Item__c in :parentOliIds
                            order by OLI__c.OpportunityLocationConfiguration__c,
                                     OLI__c.Parent_Opportunity_Line_Item__c,
                                     OLI__c.PP_Package__c  desc,
                                     OLI__c.PP_Per_Account__c desc,
                                     OLI__c.PP_Sales_Rate_Plan_Description_Sort__c]) {
            key= String.valueOf(olif.OpportunityLocationConfiguration__c)+String.valueOf(olif.Parent_Opportunity_Line_Item__c);
            if(!childFeatureMap.containskey(key))                 
               childFeatureMap.put(key,new List<OLI__c>{olif});                    
            else
              childFeatureMap.get(key).add(olif);
       } 
       
       return childFeatureMap;                   
        
    }
    
    
    private void getMoreFeatures(wrapFeatureforOrderSummary wf){
        //Get the features (for the products) I need to validate against
        //I want the packages to go first (per account, then per line), so that's how I query them          
        map<String,ID> productDescriptionNameToId=new Map<String,Id>();
        List<integer> productIds = new List<integer>();
        for (OLI__c oli : wf.features) {
            List<wrapFeatureContent> myFeatures = new List<wrapFeatureContent>();            
          
             if (oli.PP_Package__c  && oli.PP_SalesProductRatePlanExternalID__c== null) {
                   hasOrphanOLIs = false;

                   if(wf.newView==NULL)
                   {
                        system.debug('oli.PP_SalesProductExternalID__c: ' + oli.PP_SalesProductExternalID__c);
                        if(oli.PP_SalesProductExternalID__c != null)
                            productIds.add(integer.valueof(oli.PP_SalesProductExternalID__c));

                         getProductFeaturePricing(wf, oli.PP_SalesProductExternalID__c);

                   }
                //Add the child OLIs from whatever has been saved
                productDescriptionNameToId.put(oli.PP_Sales_Rate_Plan_Description__c,oli.id);
                if(childFeatureMap.get(String.valueOf(wf.OL.Id)+ String.valueOf(oli.Id))!= null){ 
                    for (OLI__c olif : childFeatureMap.get(String.valueOf(wf.OL.Id)+ String.valueOf(oli.Id))) {                   
                        wrapFeatureContent oneContent = new wrapFeatureContent();
                        oneContent.title = olif.PP_Sales_Rate_Plan_Description__c;
                        oneContent.salesProductRatePlanExternalId = olif.PP_SalesProductRatePlanExternalID__c;
                        //oneContent.productPricingId = olif.Product_Pricing__c;
                        oneContent.additionalInformationPrompt = oli.PP_AdditionalInformationPrompt__c;
                        oneContent.spcSalesProductComponentId = string.valueof(olif.SPC_Sales_Product_Component_Id__c);
                        oneContent.spcComponentId = string.valueof(olif.SPC_Component_Id__c);                    
                        myFeatures.add(oneContent);                        
                      }
                 }
                
                 wf.packageFeatures.put(oli.Id, myFeatures);
            }
                        
        }
        System.debug('newview: ' + wf.newview);
        if(wf.newView != NULL)
        {
            Set<decimal> parentSalesProdComponentIds = new Set<decimal>();
            for(CatalogUtils.SPCPricingView pricingView:wf.newView)
            {
                List<wrapFeatureContent> myFeatures = new List<wrapFeatureContent>();
                if(productDescriptionNameToId.containsKey(pricingView.pricing.Component_name__c))
                {
                    if(pricingView.children != null && pricingView.children.size() > 0)
                    {
                        for(CatalogUtils.SPCPricingView childView :pricingView.children)
                        {
                            if(childView.pricing.Component_Group__c =='Included')
                            {
                                System.debug('Child: ' + childView);
                                wf.packageItemToPriceId.put(childView.pricing.Component_Name__c,childView.pricing.Price_id__c);
                                wrapFeatureContent oneContent = new wrapFeatureContent();
                                oneContent.title = childView.pricing.Component_Name__c;
                                oneContent.salesProductRatePlanExternalId = String.valueof(childView.pricing.Sales_Product_Id__c);
                                oneContent.spcSalesProductComponentId = String.valueof(childView.pricing.Sales_Product_Component_Id__c);
                                oneContent.spcComponentId = String.valueof(childView.pricing.Component_ID__c);
                                if(childView.pricing.Feature_Schedule_Prompt__c!=NULL)
                                   oneContent.additionalInformationPrompt = childView.pricing.Feature_Schedule_Prompt__c;                                      
                                myFeatures.add(oneContent);        
                            }
                        }
                        wf.packageFeatures.put(productDescriptionNameToId.get(pricingView.pricing.Component_Name__c), myFeatures);
                    }
                    else{
                        //Check if the parent row has features using the new relationship records
                        parentSalesProdComponentIds.add(pricingView.pricing.Sales_Product_Component_ID__c);
                    }
                }
            }
            Map<decimal,List<CatalogUtils.SPCPricingView>> childFeaturePricing = CatalogUtils.GetProductFeaturePricingWithFeatureRelationship(productIds,wf.OL.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Market_Area_Name__c,parentSalesProdComponentIds,wf.OL.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Net_Classification__c == 'On-net');

            //get features for parent row if they have relationship records
            for(CatalogUtils.SPCPricingView pricingView:wf.newView)
            {

                List<wrapFeatureContent> myFeatures = new List<wrapFeatureContent>();
                if(productDescriptionNameToId.containsKey(pricingView.pricing.Component_name__c))
                {
                    if(pricingView.children == NULL || pricingView.children.size() == 0)
                    {
                        if(childFeaturePricing.containsKey(pricingView.pricing.Sales_Product_Component_Id__c)){
                            for(CatalogUtils.SPCPricingView childView :childFeaturePricing.get(pricingView.pricing.Sales_Product_Component_Id__c)){
                                if(childView.pricing.Component_Group__c =='Included'){
                                        System.debug('Child: ' + childView);
                                        wf.packageItemToPriceId.put(childView.pricing.Component_Name__c,childView.pricing.Price_id__c);
                                        wrapFeatureContent oneContent = new wrapFeatureContent();
                                        oneContent.title = childView.pricing.Component_Name__c;
                                        oneContent.salesProductRatePlanExternalId = String.valueof(childView.pricing.Sales_Product_Id__c);
                                        oneContent.spcSalesProductComponentId = String.valueof(childView.pricing.Sales_Product_Component_Id__c);
                                        oneContent.spcComponentId = String.valueof(childView.pricing.Component_ID__c);
                                        if(childView.pricing.Feature_Schedule_Prompt__c!=NULL)
                                           oneContent.additionalInformationPrompt = childView.pricing.Feature_Schedule_Prompt__c;                                      
                                        myFeatures.add(oneContent);        
                                }
                            }
                            wf.packageFeatures.put(productDescriptionNameToId.get(pricingView.pricing.Component_Name__c), myFeatures);
                        }

                    }
                }
            }

        }
    }
    
    private void getProductFeaturePricing(wrapFeatureforOrderSummary wf, String salesproductExternalId)
    {
        system.debug('getProductFeaturePricing: ' + wf.OL);
        system.debug('getProductFeaturePricing: ' + Integer.valueof(salesProductExternalId));
        if(!wf.isWebserviceCalled)
        {
            wf.newView = filterExpiredItem(getProductFeaturePricing(wf.OL, Integer.valueof(salesProductExternalId)));
            wf.isWebserviceCalled=true;
        }
        system.debug('Web service call'+wf.newView);
    }
       
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_ManageFeaturesSchedule(); }
}