@isTest
public with sharing class Test_ConfigureSolution extends TestUtils.TestClass {
	static testMethod void TestConfigureSoluiton() {
		Mocks testData = new Mocks();
		SPC_Product__c product = new SPC_Product__c(
			SalesProductExternalID__c = 185
			,Expiration__c = null
			,Hide_In_Wizard__c = false);
		insert product;
		SPC_Component__c comp1 = new SPC_Component__c(
			Component_Name__c = 'EoC Access - 40 Mbps'
			,Component_Group__c = 'Access/Bandwidth'
			,Sales_Product__c = product.id
			,Sales_Product_Component_ID__c = 13172
		);		
		insert comp1;
		List<SPC_Pricing__c> pricings = new List<SPC_Pricing__c>();
		SPC_Pricing__c pricing = new SPC_Pricing__c(
			sales_product_id__c = 185
			,Is_Expired__c = false
			,Validation_Constraint_Type__c = 'test'
			,Price_ID__c = 'SP185CO65321TM0A876AV2291'
			,Market__c = 'asdf'
			,Available_In_Wizard__c = true
			,SPC_Component__c = comp1.id
		);
		pricings.add(pricing);
		SPC_Pricing__c pricing2 = new SPC_Pricing__c(
			sales_product_id__c = 185
			,Is_Expired__c = false
			,Validation_Constraint_Type__c = 'test'
			,Price_ID__c = 'SP185CO65321TM0A876AV2292'
			,Market__c = 'asdf'
			,Available_In_Wizard__c = true
			,SPC_Component__c = comp1.id
		);
		pricings.add(pricing2);
		insert pricings;
	
		List<OLI__c> olees = testData.lstLineItems;
		test.startTest();
		
		PageReference pageReference = Page.ConfigureSolution;
        pageReference.getParameters().put('opportunityLocationConfigurationId', testData.lstconfig[0].Id);
        Test.setCurrentPage(pageReference);
		ConfigureSolutionController controller = new ConfigureSolutionController();
		List<SelectOption> ats = controller.accessTechs;
		Component.Apex.SelectList sl = controller.viewList;
		
		controller.selectedProduct = '185';
		controller.GetPricing();
		
		String cloneKey = '';
		for(string pg : controller.pricingSortOrder.keyset()){
			for(String priceSortKey : controller.pricingSortOrder.get(pg).keyset()){
				for(ConfigureSolutionController.OLIView v : controller.pricingSortOrder.get(pg).get(priceSortKey)){
					v.oli.qty__c = 2;
					v.updated = true;
					if(cloneKey == '')
						cloneKey = v.oli.price_id__c;
				}
			}
		}
		pageReference.getParameters().put('priceID', cloneKey);
		pageReference.getParameters().put('addMode', 'true');
		pageReference.getParameters().put('offset', '0');
		controller.AddRemovePriceRow();
		controller.doValidation = true;
		controller.doValidate();
		
		pageReference.getParameters().put('streetNumber', '5486');
		pageReference.getParameters().put('street', 'sw norris terrace');
		pageReference.getParameters().put('suite', '');
		pageReference.getParameters().put('city', 'Beaverton');
        //MNK added Aug 2017
        pageReference.getParameters().put('country', 'US');
		pageReference.getParameters().put('state', 'OR');
		pageReference.getParameters().put('postalCode', '97007');
		pageReference.getParameters().put('latitude', '0');
		pageReference.getParameters().put('longitude', '0');
		pageReference.getParameters().put('success', 'true');
		controller.SecondaryLocationParsed();
		controller.SaveParsedSecondaryLocation();
		//controller.recalcDiscount();
		controller.save();
		controller.SaveLineItemsAndExit();
		controller.GrantApproval();
		
		test.stopTest();
	}
}