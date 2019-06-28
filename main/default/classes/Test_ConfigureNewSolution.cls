@isTest
public with sharing class Test_ConfigureNewSolution extends TestUtils.TestClass {
	static testMethod void TestConfigureSoluiton() {
		Mocks testData = new Mocks();
		List<OLI__c> olees = testData.lstLineItems;
		SPC_Product__c product = new SPC_Product__c(
			SalesProductExternalID__c = 185
			,Expiration__c = null
			,Hide_In_Wizard__c = false
			,Name = 'Access Service');
		insert product;
		for(OLI__c oli : olees){
			oli.SPC_Sales_Product__c = product.id;
		}
		update olees;

		SPC_Component__c comp1 = new SPC_Component__c(
			Component_Name__c = 'EoC Access - 40 Mbps'
			,Component_Group__c = 'Access/Bandwidth'
			,Sales_Product__c = product.id
			,Sales_Product_Component_ID__c = 13172
		);		
		insert comp1;
		SPC_Relationship_Type__c rt = new SPC_Relationship_Type__c(
			Relationship_Type_ID__c = '1'
			,Pick_One__c = true
			,Required__c = true
		);
		SPC_Relationship_Type__c rt2 = new SPC_Relationship_Type__c(
			Relationship_Type_ID__c = '2'
			,Use_Parent__c = true
		);
		insert new List<SPC_Relationship_Type__c>{rt,rt2};

		SPC_Relationship__c r = new SPC_Relationship__c(
			Primary_Sales_Product__c = product.id
			,SPC_Relationship_Type__c = rt.id
		);
		insert r;

		SPC_Relationship__c r2 = new SPC_Relationship__c(
			SPC_Relationship_Type__c = rt2.id
			,Parent_Relationship__c = r.id
			,Primary_Sales_Product_Component__c = comp1.id
		);
		insert r2;

		SPC_Pricing__c pricing = new SPC_Pricing__c(
			sales_product_id__c = 185
			,Is_Expired__c = false
			,Validation_Constraint_Type__c = 'test'
			,Price_ID__c = 'SP185CO65321TM0A876AV2291'
			,Market__c = 'Southwest Washington'
			,Available_In_Wizard__c = true
			,SPC_Component__c = comp1.id
			,term__c = 36
		);
		insert new List<SPC_Pricing__c>{pricing};


		test.startTest();
		PageReference pageReference = Page.ConfigureNewSolution;
        pageReference.getParameters().put('opportunityLocationConfigurationId', testData.lstconfig[0].Id);
		pageReference.getParameters().put('term', '36');
		pageReference.getParameters().put('market', 'Southwest Washington');
		
		Test.setCurrentPage(pageReference);
		ConfigureNewSolution controller = new ConfigureNewSolution();

		ConfigureNewSolution.getPricingForProduct('185','Southwest Washington',json.serialize(new List<String>{'36'}),false, false);

		List<ConfigureNewSolution.UIProdView> views = new List<ConfigureNewSolution.UIProdView>();
		for(OLI__c oli : olees){
			ConfigureNewSolution.UIProdView v = new ConfigureNewSolution.UIProdView();
			v.oli = oli;
			v.Children = new List<ConfigureNewSolution.UIProdView>();
			v.MRR = oli.MRC__c;
			v.MRRList = oli.MRC__c;
			v.MRRTotal = oli.MRC__c;
			v.NRR = oli.NRC__c;
			v.NRRList = oli.NRC__c;
			v.NRRTotal = oli.NRC__c;
			v.ParentRelID = '';
			v.PriceId = oli.Price_Id__c;
			v.ProdName = product.Name;
			v.Qty = integer.valueof(oli.Qty__c);
			v.SPCComponentID = '';
			v.SPCProductID = product.id;
			v.UUID = '';
			v.ParentProdName = product.Name;
			v.GroupName = '';
			v.DisplayName = '';
			v.ProdId = 0;
			views.add(v);
		}
		ConfigureNewSolution.GrantApproval(json.serialize(views),'Offer Management',testData.lstconfig[0]);
		ConfigureNewSolution.UpsertOLIs(json.serialize(views),testData.lstconfig[0].Id,testData.lstconfig[0].Opportunity_Location__c );

		
		test.stopTest();
	}
}