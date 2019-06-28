@isTest	//todo: fix this test
public with sharing class Test_ManageFeaturesSchedule extends TestUtils.TestClass {

    static testMethod void testManageFeaturesScheduleController(){

        Mocks testData = new Mocks();
		system.debug(testData.location);
        system.debug(testData.order);
        system.debug(testData.lstconfig);
        system.debug(testData.lstCN);
		System.debug(testData.lstCNFeature);
		
        test.startTest();
		
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.lstTI[0]);
        ManageFeaturesScheduleController test_ctl = new ManageFeaturesScheduleController(sc);
        
        //Test the Initializing
        test_ctl.initScreen();
        
        ManageFeaturesScheduleController.wrapNumber tel;
        
        //Grab the newly created line
        for (ManageFeaturesScheduleController.wrapNumber mytel : test_ctl.TelephoneNumbers) {
            
            //if (mytel.cn.name.startsWith('TN')) {
                tel = mytel;
                break;
            //}
        }

        tel.cn.Name = '310-555-3333';
                    
        //Select a feature (part of a package)
        
        for (ManageFeaturesScheduleController.wrapFeature myfeat : tel.features) {
          if (myfeat.selected == false && myfeat.feature == null && myfeat.isPartOfPackage/* && myfeat.productPricingId == testData.lstpricing[6].id*/) {
            myfeat.selected = true;
            break;
          }
        }
        
        //test_ctl.saveFeatures();
        
        //Re initialize
        test_ctl.initScreen();
        
        
        for (ManageFeaturesScheduleController.wrapNumber mytel : test_ctl.TelephoneNumbers) {
            
            if (! mytel.isTotalLine) {
                tel = mytel;
            }
        }
        
        //delete a line
        test_ctl.cnRemoveId = tel.cn.id;
        //test_ctl.deleteLine();
    
    	test_ctl.saveOnly();
        test_ctl.saveFeatures();
        
        //Show a sample error message
        test_ctl.messageDisplay('test message');

        test.stopTest();

    }
    
    @isTest	//Used to have SeeAllData
    static void testparentFeaturemethod(){
		  //ProductWizardController productWizardController = null;
        
       // create test data
        Mocks testData = new Mocks();
        // test controller config constructor validation
        //PageReference pageReference = Page.SelectProductFamilies;
        //Test.setCurrentPage(pageReference);

         // test controller constructor page 2
         /*pageReference = Page.SelectProductFamilies;
         pageReference.getParameters().put('opportunityLocationConfigurationId', testData.lstconfig[0].Id);
         Test.setCurrentPage(pageReference);*/
        
         //try {
          //productWizardController pw = simulateNavigation();
           //pw.gotoLineItemNextStep(); 
          List<OLI__c> alloli=createLineItem();
           List<OLI__c> newoli=new List<OLI__c>();
           for(OLI__c ol:alloli)
           {
           	if (ol.DQ__c!='Multi Line Hunting') 
           	{
	           	ol.OpportunityLocationConfiguration__c=testdata.lstconfig[0].id;
	           	ol.PP_LD_Interstate__C=false;
	           	ol.PP_LD_Intrastate__C=false;
				ol.SPC_MRC_Is_Quote__c=false;
				ol.SPC_MRC_OnNet__c=false;
				ol.SPC_NRC_Is_Quote__c=false;
				ol.Qty__c=1;
				newoli.add(ol);
				 system.debug(logginglevel.warn,'All value'+ol); 
           	}
           }
           
           upsert newoli;
          
           for(OLI__c ol:[Select id,DQ__c,QTy__c,PP_Package__c,PP_Per_Account__c,PP_Voice_LIne__c,PP_Voice_Line_Option__c 
           				from oLI__C where opportunityLocationConfiguration__c=:testdata.lstconfig[0].id] )
           				{
           					
           					system.debug(logginglevel.warn,'This value'+ol);
           				}
						
        Test.startTest();
						
           ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.lstTI[0]);
           ManageFeaturesScheduleController test_ctl = new ManageFeaturesScheduleController(sc);
           test_ctl.initScreen();
           for(ManageFeaturesScheduleController.wrapNumber mfeature:test_ctl.TelephoneNumbers )
           {
           			
					if(mfeature.cn!=NULL)
					{
						for(ManageFeaturesScheduleController.wrapFeature feature:mfeature.features)
						{
							if(feature.name=='Multi Line Hunting')
								{
									feature.selected=true;
								}
							system.debug('This value'+feature.name);
						}
					}
           		
           }
          
          test_ctl.saveOnly();
          test_ctl.initScreen();
          for(ManageFeaturesScheduleController.wrapNumber mfeature:test_ctl.TelephoneNumbers )
           {
           			
					if(mfeature.cn!=NULL)
					{
						for(ManageFeaturesScheduleController.wrapFeature feature:mfeature.features)
						{
							if(feature.name=='Multi Line Hunting')
								{
									system.debug('In a loop value'+feature.selected);
								}
							
						}
					}
           		
           }
            test_ctl.saveOnly();
             List<OLI__c> lineitemlst=new List<OLI__c>();
            
            for(OLI__c lineitem:test_ctl.features )  
           {
           			
				lineitemlst.add(lineitem);	
           		
           } 
           system.debug(logginglevel.warn,'The value from the product'+lineitemlst);
           test_ctl.parentfeature(lineitemlst);
           Test.stopTest();
        
    }
    
    static testMethod void testdeleteline(){
		//  ProductWizardController productWizardController = null;
        
       // create test data
        Mocks testData = new Mocks();
        // test controller config constructor validation
        //PageReference pageReference = Page.SelectProductFamilies;
        //Test.setCurrentPage(pageReference);

         // test controller constructor page 2
         /*pageReference = Page.SelectProductFamilies;
         pageReference.getParameters().put('opportunityLocationConfigurationId', testData.lstconfig[0].Id);
         Test.setCurrentPage(pageReference);*/
        
        
          List<OLI__c> alloli=createLineItem();
           List<OLI__c> newoli=new List<OLI__c>();
           for(OLI__c ol:alloli)
           {
           	if (ol.DQ__c!='Multi Line Hunting') 
           	{
	           	ol.OpportunityLocationConfiguration__c=testdata.lstconfig[0].id;
	           	ol.PP_LD_Interstate__C=false;
	           	ol.PP_LD_Intrastate__C=false;
				ol.SPC_MRC_Is_Quote__c=false;
				ol.SPC_MRC_OnNet__c=false;
				ol.SPC_NRC_Is_Quote__c=false;
				ol.Qty__c=2;
				newoli.add(ol);
				 system.debug(logginglevel.warn,'All value'+ol); 
           	}
           }
           
           upsert newoli;
		   
        Test.startTest();
          
          
           ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.lstTI[0]);
           ManageFeaturesScheduleController test_ctl = new ManageFeaturesScheduleController(sc);
           test_ctl.initScreen();
            List<OLI__c> updateOli=new List<OLI__c>();
            for(OLI__c ol:[Select id,DQ__c,QTy__c,PP_Package__c,PP_Per_Account__c,PP_Voice_LIne__c,PP_Voice_Line_Option__c 
           				from oLI__C where opportunityLocationConfiguration__c=:testdata.lstconfig[0].id] )
           				{
           					ol.Qty__c=1;
           					system.debug(logginglevel.warn,'Change value'+ol.Qty__c);
           					updateOli.add(ol);
           				}
           	update updateOli;
           ManageFeaturesScheduleController test_ctl1 = new ManageFeaturesScheduleController(sc);
           test_ctl1.initScreen();
           Integer counter=0;
           for(ManageFeaturesScheduleController.wrapNumber mfeature:test_ctl.TelephoneNumbers )
           {
           			
					if(counter==1)
						test_ctl1.cnRemoveId=mfeature.cn.id;
					counter++;
           		
           }
           test_ctl1.deleteLine();
           Test.stopTest();
        
    }
    
	static testMethod void testFeatureValidations(){
        //  ProductWizardController productWizardController = null;
        
       // create test data
        Mocks testData = new Mocks();
        // test controller config constructor validation
        //PageReference pageReference = Page.SelectProductFamilies;
        //Test.setCurrentPage(pageReference);

         // test controller constructor page 2
         //pageReference = Page.SelectProductFamilies;
         //pageReference.getParameters().put('opportunityLocationConfigurationId', testData.lstconfig[0].Id);
         //Test.setCurrentPage(pageReference);
        
         //try {
          //productWizardController pw = simulateNavigation();
           //pw.gotoLineItemNextStep(); 
          List<OLI__c> alloli=createLineItem();
           List<OLI__c> newoli=new List<OLI__c>();
           for(OLI__c ol:alloli)
           {
            if (ol.DQ__c!='Multi Line Hunting') 
            {
                ol.OpportunityLocationConfiguration__c=testdata.lstconfig[0].id;
                ol.PP_LD_Interstate__C=false;
                ol.PP_LD_Intrastate__C=false;
                ol.SPC_MRC_Is_Quote__c=false;
                ol.SPC_MRC_OnNet__c=false;
                ol.SPC_NRC_Is_Quote__c=false;
                ol.Qty__c=2;
                newoli.add(ol);
                 system.debug(logginglevel.warn,'All value'+ol); 
            }
           }
           
           upsert newoli;
          
        Test.startTest();
          
           ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.lstTI[0]);
           ManageFeaturesScheduleController test_ctl = new ManageFeaturesScheduleController(sc);
           test_ctl.initScreen();
            List<OLI__c> updateOli=new List<OLI__c>();
            for(OLI__c ol:[Select id,DQ__c,QTy__c,PP_Package__c,PP_Per_Account__c,PP_Voice_LIne__c,PP_Voice_Line_Option__c 
                        from oLI__C where opportunityLocationConfiguration__c=:testdata.lstconfig[0].id] )
                        {
                            ol.Qty__c=1;
                            system.debug(logginglevel.warn,'Change value'+ol.Qty__c);
                            updateOli.add(ol);
                        }
            update updateOli;
           ManageFeaturesScheduleController test_ctl1 = new ManageFeaturesScheduleController(sc);
           test_ctl1.initScreen();
           Integer counter=0;
           for(ManageFeaturesScheduleController.wrapNumber mfeature:test_ctl.TelephoneNumbers )
           {
                    
                    if(counter==1)
                        test_ctl1.cnRemoveId=mfeature.cn.id;
                    counter++;
                
           }
           List<CN__c> lstcn=new List<CN__c>();
           List<CN_Feature__c> lstcnFeature=new List<CN_Feature__c>(); 
         for( ManageFeaturesScheduleController.wrapNumber mwrap:test_ctl1.TelephoneNumbers)
         {
         	if(mwrap.cn!=NULL)
         		lstcn.add(mwrap.cn);
         }
        test_ctl1.validations.validate(lstcn, lstcnFeature); 
        test_ctl1.validations.validateOverallLineQty(lstcn);  
         test_ctl1.validations.validateLineQty(lstcn); 
         test_ctl1.validations.validateInactiveFeatures(lstcnFeature);       
           Test.stopTest();
        
    }
    
	/*public static ProductWizardController simulateNavigation()
    {
    	 productWizardController pw = new ProductWizardController();
			for(ProductWizardController.customSelectList cl:pw.customProductFamilySelectOption)
			{
				if(cl.label=='Data Services')
				   cl.checkbox=true;
			}
			//Method called
			pw.gotoSelectProductFamilyProducts();
			
			for(ProductWizardController.customSelectList cw:pw.customProductFamilySelectOption)
			{
				if(cw.display==true)
				{
					
					for(Selectoption options:cw.productFamilyProductsSelectOptions)
					{
						system.debug(logginglevel.warn,'@@@@salesproductname'+options.getLabel());
						if(options.getLabel()=='VPN Solutions' || options.getLabel()=='Dedicated Internet')
						{
							pw.selectedProductFamilyProducts.add(options.getvalue());
						}
					}
				}
			}
		pw.gotoSelectProductRatePlans();
		for(ProductWizardController.FeatureGroup fw:pw.featureGroups)
		{
			if(fw.name=='F1')
			{
				for(OLI__c ol:fw.lineItems)
				{
					if(ol.PP_Product_Pricing_Name__c=='product1')
					{
		system.debug(logginglevel.warn,'Quantity changed'+fw.name);
						ol.Qty__C=1;
						ol.PP_LD_Interstate__c=true;
						//ol.PP_LD_Interstate__c=false;
						ol.PP_LD_Intrastate__C=false;
						ol.PP_Per_Account__c=false;
						ol.PP_Voice_Line_Option__c=false;
						ol.PP_Voice_Line__c=false;
						ol.SPC_MRC_Is_Quote__c=false;
						ol.SPC_MRC_OnNet__c=false;
						ol.SPC_NRC_Is_Quote__c=false;
					}
					else
					{
						ol.PP_LD_Interstate__c=true;
						ol.PP_LD_Intrastate__C=false;
						ol.PP_Per_Account__c=false;
						ol.PP_Voice_Line_Option__c=false;
						ol.PP_Voice_Line__c=false;
						ol.SPC_MRC_Is_Quote__c=false;
						ol.SPC_MRC_OnNet__c=false;
						ol.SPC_NRC_Is_Quote__c=false;
					}
				}
			}
			
			//system.debug(logginglevel.warn,'%%%%%% Feature Group'+fw.name);
		}
		
		 return pw;
    }*/
    
    public static List<OLI__c> createLineItem()
    {
    	List<OLI__c> newlineItem=new List<OLI__c>();
    	for(integraWS.SFSPCPricingView pview: callDummyMethod().SFSPCPricingView) 
    	
    	{
    		OLI__c oli=setLineItems(pview);
    		newlineItem.add(oli);
    		if(pview.ChildViews!=NULL && pview.childViews.SFSPCPricingView.size()>0)
    		{
    			for(integraWS.SFSPCPricingView cview:pview.ChildViews.SFSPCPricingView)
    			{
    				if(cview.ComponentGroup!='Included')
    				{
	    				OLI__c olichld=setLineItems(cview);
	    				newlineItem.add(olichld);
    				}
    			}
    		}
    		
    	}
    	system.debug('All new line item'+newlineItem);
    	return newlineItem;
    }
    
	public static OLI__c setLineItems(integraWS.SFSPCPricingView pricingView)
	    {
	        OLI__c lineItem=new OLI__c();  
	        lineItem.Qty__c = 0;
	        lineItem.DQ__c= pricingView.ComponentName;
	        lineItem.PP_Product_Pricing_Name__c= pricingView.ComponentName;                                                 
	        lineItem.PP_Sales_Rate_Plan_Description__c= pricingView.ComponentName;
	        lineItem.PP_SalesProductExternalID__c=String.valueof(pricingView.SalesProductID);
			lineItem.PP_Per_Account__c=pricingview.IsPerAccount;
	        if( pricingView.MRR!= Null)
	        {
	            lineItem.MRC__c = pricingView.MRR;
	            lineItem.MRCList__c=pricingView.MRR;
	        }
	        if( pricingView.NRR!= Null)
	            lineItem.NRC__c = pricingView.NRR;
	        if(pricingView.MRRFloor!=null)
	            lineItem.MRC_Floor__c=pricingView.MRRFloor;
	        system.debug('@setLineItems'+pricingView.ComponentName);
	        lineitem.PP_Voice_Line__c=  pricingView.IsVoiceLine       ;
	        lineitem.PP_Voice_Line_Option__c= pricingView.IsVoiceLineOption   ;
	        if(pricingView.componentName=='Feature Package Plus 1 - 2 Lines - per account')
				lineitem.PP_Package__c=true;
			else
			   lineitem.PP_Package__c=false;
	        lineItem.NRC_Floor__c=pricingView.NRRFloor;
	        if(pricingView.pricingName!=NULL)
	            lineItem.DQ__c = pricingView.ComponentName+pricingView.pricingName;
	        else
	           lineItem.DQ__c = pricingView.ComponentName;
	        
	        lineItem.Tag_Name__c=pricingView.SalesSelectionRuleValue;
	        lineItem.Price_Id__c = String.valueof(pricingView.PriceId);
	       //lineItem.OpportunityLocationConfiguration__c = this.opportunityLocationConfiguration.Id;
	        lineItem.AccessTechName__c = pricingView.AccessTechName;
	        lineItem.SPC_Feature_Group__c=pricingView.ComponentGroup;
	        lineItem.PP_Feature_Group__c=pricingView.ComponentGroup;
	        
	        lineItem.SPC_Sales_Selection_Rule_Name__c=pricingView.SalesSelectionRuleValue;
	        lineItem.SPC_MaxQty__c=pricingView.MaxQty;
	        lineItem.SPC_MinQty__c=pricingView.MinQty;
	        lineItem.SPC_MRC_OnNet__c=pricingView.IsOnnetPrice;
	        lineItem.SPC_NRC_Is_Quote__c=pricingView.IsQuotePrice;
	        lineItem.SPC_MRC_Is_Quote__c=pricingView.IsQuotePrice;
	        if(pricingView.Bandwidth!=NULL) 
	            lineItem.Bandwidth__c=pricingView.Bandwidth;
	        
	        if(pricingView.ComponentID!= NULL)
	        {
	            lineItem.SPC_Component_Id__c=pricingView.ComponentID;
	            
	        }
	        
	        lineItem.PP_LD_Interstate__c=pricingView.IsLDInterstate;                                                        
	        lineItem.PP_LD_Intrastate__c = pricingView.IsLDIntraState ;
	        
	        
	        lineitem.PP_Sales_Product__c='Basic Voice';
	        return lineItem;  
	}

    static testMethod void testFeaturesScheduleValidationsBasic() {
        
        User u = [Select u.UserPermissionsSFContentUser, u.Profile.Name, u.ProfileId, u.Name, u.Id From User u where UserPermissionsSFContentUser = true AND IsActive=true limit 1];
        system.runAs(u){
            Mocks testData = new Mocks();
           
            test.startTest();
            
            try {
            	FeaturesScheduleValidations validationEngine = new FeaturesScheduleValidations(); 
            }  catch (Exception e) {
            	//Obvious failure. I used the "wrong" constructor;
            }
            
            system.debug('OL-->' + testData.location);
            system.debug(testData.lstconfig);
            FeaturesScheduleValidations validationEngine = new FeaturesScheduleValidations(testData.location.id); 
            system.debug(testData.lstCN);
            Boolean result = validationEngine.validate(testData.lstCN, testData.lstCNFeature);
            
            //system.assertEquals(result, true);
            
            //Now let's make it fail (we can make all these validations regardless of how many fail, so we'll just do everything and test one time)
            CN__c cn;
            CN_Feature__c cnFeature;
             
            //Add a 3rd line
            cn = new CN__c(Opportunity_Location__c = testdata.location.id, Opportunity_Line_Item__c = testdata.lstLineItems[0].id, name='310-555-3333' );
            insert cn;
			testData.lstCN.add(cn);
			//Add an extra feature
            cnFeature = new CN_Feature__c(CN__c = testData.lstCN[0].id, Opportunity_Line_Item__c = testData.lstLineItems[1].id, Additional_Info__c = 'Prompt Value', Name = '310-555-1111 - Feature 1');
			insert cnFeature;
			testData.lstCNFeature.add(cnFeature);
			
			result = validationEngine.validate(testData.lstCN, testData.lstCNFeature);
            
            system.assertEquals(result, false);
           
            test.stopTest();
        }
        
    }
    
    static void testFeaturesScheduleValidationsAdvanced() {
        
        User u = [Select u.UserPermissionsSFContentUser, u.Profile.Name, u.ProfileId, u.Name, u.Id From User u where UserPermissionsSFContentUser = true AND IsActive=true limit 1];
        system.runAs(u){
            Mocks testData = new Mocks();
           
            test.startTest();
            
            try {
            	FeaturesScheduleValidations validationEngine = new FeaturesScheduleValidations(); 
            }  catch (Exception e) {
            	//Obvious failure. I used the "wrong" constructor;
            }
            
            system.debug('OL-->' + testData.location);
            
            //These validations require changes to either the solution or the underlying OLIs
            //Make a feature orphan
			testdata.lstLineItems[4].Parent_Opportunity_Line_Item__c = null;
			update testdata.lstLineItems[4];
			//Make a feature without Product Pricing
			testdata.lstLineItems[2].Product_Pricing__c = null;
			update testdata.lstLineItems[2];
			
            FeaturesScheduleValidations validationEngine = new FeaturesScheduleValidations(testData.location.id); 
            
            Boolean result = validationEngine.validate(testData.lstCN, testData.lstCNFeature);
            
            system.assertEquals(result, false);
           
            
            test.stopTest();
        }
        
    }
    
    static testMethod void testFeaturesScheduleValidationsInactiveSolution() {
        
        User u = [Select u.UserPermissionsSFContentUser, u.Profile.Name, u.ProfileId, u.Name, u.Id From User u where UserPermissionsSFContentUser = true AND IsActive=true limit 1];
        system.runAs(u){
            Mocks testData = new Mocks();
           
            test.startTest();
            
            try {
            	FeaturesScheduleValidations validationEngine = new FeaturesScheduleValidations(); 
            }  catch (Exception e) {
            	//Obvious failure. I used the "wrong" constructor;
            }
            
            //These validations require changes to either the solution or the underlying OLIs
            //Make inactive
			testdata.lstconfig[1].Active__c = true;
			update testdata.lstconfig[1];
			
			testdata.lstconfig[0].Active__c = false;
			update testdata.lstconfig[0];
			
			
            FeaturesScheduleValidations validationEngine = new FeaturesScheduleValidations(testData.location.id); 
            
            Boolean result = validationEngine.validate(testData.lstCN, testData.lstCNFeature);
            
            system.assertEquals(result, false);
            /*
            Opportunity_Location__c OL = [select Id,
 										  		(Select Id from OpportunityLocationConfigurations__r Where Active__c=true)
										from Opportunity_Location__c
										where Id = :testData.location.id];
           
            system.debug('Size 1-->' + OL.OpportunityLocationConfigurations__r.size());
            
            List<OLI__c> oli = [select Id, Sales_Rate_Plan_Description__c,
										OpportunityLocationConfiguration__c,
										Qty__c,
										Product_Pricing__r.Sales_Product__c
										from OLI__c
										where OLI__c.OpportunityLocationConfiguration__c = :OL.OpportunityLocationConfigurations__r[0].Id
										and OLI__c.Product_Pricing__r.Voice_Line__c = 'Yes'
										order by Product_Pricing__r.Sales_Rate_Plan_Description_Sort__c];
            
            system.debug('Size-->' + oli.size());
            */
            test.stopTest();
        }

    }
	 static testMethod void testFeaturesScheduleValidationsController() {
		 	 Mocks testData = new Mocks();
           System.debug('test');
            test.startTest();
		 //PageReference pageReference = Page.SelectProductFamilies;
         //pageReference.getParameters().put('opportunityLocationConfigurationId', testData.lstconfig[0].Id);
         //Test.setCurrentPage(pageReference);
		 testData.lstTI[0].Opportunity_Site__c = testData.lstconfig[0].Opportunity_Location__c;
		 update testData.lstTI[0];
		 
		 	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.lstTI[0]);
		 	ManageFeaturesScheduleController mfsc = new ManageFeaturesScheduleController(sc);
		 
		 
	        mfsc.initScreen();
			Technical_Information__c ti = mfsc.currentTI;
    		string ds = mfsc.DebugString;
			string hv = mfsc.hostedVoice;
			boolean hoo = mfsc.hasOrphanOLIs;
		   	List<ManageFeaturesScheduleController.wrapFeatureTitle> dfs = mfsc.displayFeatures;
		    List<SelectOption> ls = mfsc.lines;
		    List<SelectOption> cbl = mfsc.callBlocklines;
		 	mfsc.nameToCn=new Map<String,CN__c>();
		 	
		 
		 List<ManageFeaturesScheduleController.wrapNumber> tns = new List<ManageFeaturesScheduleController.wrapNumber>();
		 
		 	ManageFeaturesScheduleController.wrapNumber tn1 = new ManageFeaturesScheduleController.wrapNumber();
		 	ManageFeaturesScheduleController.wrapFeature wf1 = new ManageFeaturesScheduleController.wrapFeature();
		 	wf1.name = 'Test';
		 	tn1.features.add(wf1);
		 	tns.add(tn1);
		 
		 	ManageFeaturesScheduleController.wrapNumber tn2 = new ManageFeaturesScheduleController.wrapNumber();
		 	ManageFeaturesScheduleController.wrapFeature wf2 = new ManageFeaturesScheduleController.wrapFeature();
		 	wf2.name = 'Test2';
		 	wf2.isPartOfPackage = true;
		 	wf2.selected = true;
		 	wf2.parentOLI = testData.lstLineItems[0];
		 	tn2.features.add(wf2);
		 	tn2.cn = testData.lstCN[0];
		 	tns.add(tn2);
		 
		 	mfsc.TelephoneNumbers = tns;
		 	   	
		 
		    string mds = mfsc.myDebugString; 
		    string ms = mfsc.warnings;
		 
		 	mfsc.parentfeature(testData.lstLineItems);
		 	mfsc.saveFeatures();
		 	mfsc.setupField(testData.lstLineItems[0]);
		 mfsc.updateFeatureAvailability();
		 mfsc.returnTechInfo();
		 mfsc.getTestClass();
		 	
		 	test.stopTest();
	}
	
	public static integraWS.ArrayOfSFSPCPricingView callDummyMethod(){
		
		integraWS.SFSPCPricingView tview = buildDummySPCPricingView('Voice', 'Basic Business Line - Zone 1', 2, 3, 3, 0, 'Voice-Pick One', '4855', 185);
		tview.IsVoiceLineOption=false;
		tview.IsVoiceLine=true;
		tview.IsPerAccount=false;
		
		integraWS.SFSPCPricingView tviewc = buildDummySPCPricingView('Voice', 'IAC - Zone 1 & 3', 2, 3, 3, 0, 'Voice-Pick One', '4856', 185);
		tviewc.IsVoiceLineOption=false;
		tviewc.IsVoiceLine=false;
		tviewc.IsPerAccount=false;
		tview.ChildViews.SFSPCPricingView.add(tviewc);
		
		integraWS.SFSPCPricingView tview3 = buildDummySPCPricingView('Features', '3 Way Calling - Zone 1 & 3', 2, 3, 3, 0, '', '4857', 185);
		tview3.IsVoiceLineOption=true;
		tview3.IsVoiceLine=false;
		tview3.IsPerAccount=false;
		
		integraWS.SFSPCPricingView tview4 = buildDummySPCPricingView('Features', 'Feature Package Plus 1 - 2 Lines - per account', 2, 3, 3, 0, 'Rule 1', '4855', 185);
		tview4.IsVoiceLineOption=true;
		tview4.IsVoiceLine=false;
		tview4.IsPerAccount=true;
		
		integraWS.SFSPCPricingView tviewc1 = buildDummySPCPricingView('Included', 'Multi Line Hunting', 2, 3, 0, 0, 'Rule 1', '4855', 185);
		tviewc1.FeatureSchedulePrompt='Hunting Sequence';
		tview4.ChildViews.SFSPCPricingView.add(tviewc1);
		
		integraWS.ArrayOfSFSPCPricingView retval = new integraWS.ArrayOfSFSPCPricingView();
		retval.SFSPCPricingView = new List<IntegraWs.SFSPCPricingView>{tview, tview3, tview4};
		
		return retval;
	}
	
	private static integraWS.SFSPCPricingView buildDummySPCPricingView(String componentGroup, String componentName, Integer mrr, Integer nrr, Integer mrrFloor, Integer nrrFloor, String salesSelectionRuleValue, String priceId, Integer salesProductID){
		
		integraWS.SFSPCPricingView view = new integraWS.SFSPCPricingView();
		view.ComponentGroup = componentGroup;
		view.ComponentName = componentName;
		view.MRR = mrr;
		view.NRR = nrr;
		view.MRRFloor = mrrFloor;
		view.NRRFloor = nrrFloor;
		view.SalesSelectionRuleValue = salesSelectionRuleValue;
		view.PriceId = priceId;
		view.SalesProductID = salesProductID;
		
		//Defaults
		view.IsExpired = false;
		view.ChildViews = new integraWs.ArrayOfSFSPCPricingView();
		view.ChildViews.SFSPCPricingView = new List<integraWs.SFSPCPricingView>();
		
		return view;
	}
    
    static testMethod void testFeaturesScheduleValidationsArray() {
        
        User u = [Select u.UserPermissionsSFContentUser, u.Profile.Name, u.ProfileId, u.Name, u.Id From User u where UserPermissionsSFContentUser = true AND IsActive=true limit 1];
        system.runAs(u){
            Mocks testData = new Mocks();
            
           List<OLI__c> alloli=createLineItem();
           List<OLI__c> newoli=new List<OLI__c>();
           for(OLI__c ol:alloli)
           {
            if (ol.DQ__c!='Multi Line Hunting') 
            {
                ol.OpportunityLocationConfiguration__c=testdata.lstconfig[0].id;
                ol.PP_LD_Interstate__C=false;
                ol.PP_LD_Intrastate__C=false;
                ol.SPC_MRC_Is_Quote__c=false;
                ol.SPC_MRC_OnNet__c=false;
                ol.SPC_NRC_Is_Quote__c=false;
                ol.PP_Voice_Line_Option__c = true;
                ol.Qty__c=2;
                newoli.add(ol);
                 system.debug(logginglevel.warn,'All value'+ol); 
            }
           }
           
           upsert newoli;

            test.startTest();
            
            try {
            	FeaturesScheduleValidations validationEngine = new FeaturesScheduleValidations(); 
            }  catch (Exception e) {
            	//Obvious failure. I used the "wrong" constructor;
            }
            
            system.debug('OL-->' + testData.location);
            
            //These validations require changes to either the solution or the underlying OLIs
            //Make a feature orphan
			testdata.lstLineItems[4].Parent_Opportunity_Line_Item__c = null;
			update testdata.lstLineItems[4];
			//Make a feature without Product Pricing
			testdata.lstLineItems[2].Product_Pricing__c = null;
			update testdata.lstLineItems[2];
            
            Set<Id> olIds = new Set<Id>();
            olIds.add(testData.location.id);          
			
            FeaturesScheduleValidations validationEngine = new FeaturesScheduleValidations(olIds); 
            
            validationEngine.errors = new List<String>();
            Boolean result = validationEngine.validate(testData.lstCN, testData.lstCNFeature);
            
            system.assertEquals(result, false);
           
            
            test.stopTest();
        }
        
    }   

}