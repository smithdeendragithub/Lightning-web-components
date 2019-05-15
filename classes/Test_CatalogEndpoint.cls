@isTest
public with sharing class Test_CatalogEndpoint extends TestUtils.TestClass {
	
	static testMethod void testEndpoint(){
		Mocks testData = new Mocks();
		test.startTest();
		
		CatalogEndpoint.PricingProductView ppv = new CatalogEndpoint.PricingProductView();
		CatalogEndpoint.SalesProductClliView spcv = new CatalogEndpoint.SalesProductClliView();
		CatalogEndpoint.BuildingAccessTypeView batv = new CatalogEndpoint.BuildingAccessTypeView();
		
		Sales_Product_Rate_Plan__c sprp = new Sales_Product_Rate_Plan__c(Sales_Product__r = new SalesProduct__c(SalesProductExternalID__c = '0', Product_Family__r = new Product_Family__c()));
		SalesProductSalesFamily__c spsf = new SalesProductSalesFamily__c(Product_Family__r=new Product_Family__c());
		Building__c b = new Building__c();
		CatalogEndpoint.SalesProductRatePlanView sprpv = new CatalogEndpoint.SalesProductRatePlanView(sprp, spsf, b);

		CatalogUtils.SPCPricingView spv = new CatalogUtils.SPCPricingView(new spc_pricing__c());
		CatalogUtils.DiscountAuthorityView dal = new CatalogUtils.DiscountAuthorityView(100,true,'Testing');
		CatalogUtils.GetProductFeaturePricing(new List<Integer>{2},10,'PLTDOR13','test',new List<Integer>{247},new List<Integer>{36});
		CatalogUtils.GetRelations(new List<OLI__c>());
		CatalogUtils.getRelationsByGroupByComponentId(new Set<Decimal>());
		CatalogUtils.getRelationsByGroupByProductId(new Set<Decimal>());


		QuoteWrapper.QuoteLineItem qli = new QuoteWrapper.QuoteLineItem();
		QuoteWrapper.getConfigFamilies(testData.lstconfig[0].Id);
		QuoteWrapper.sortListByProductname(new List<QuoteWrapper.ProductFamily>());
	}
	
	static testMethod void testGetAccessBandwidthSalesRatePlanInfo(){
       	CatalogEndpoint.GetAccessBandwidthSalesRatePlanInfo();
	}
	
	static testMethod void testGetActiveSPCProducts(){
		CatalogEndpoint.GetActiveSPCProducts();
	}
	
	static testMethod void testGetBuildingAccessTypeInfo(){
		CatalogEndpoint.GetBuildingAccessTypeInfo();
        
        test.startTest();
        Building__c Building = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US');
        insert Building;
        Access_Technology__c ATech = new Access_Technology__c(Access_Technology_ID__c = 123);
        insert ATech;
        Building_Access_Availability__c BAA = new Building_Access_Availability__c(Building__c = Building.Id, Access_Technology__c = ATech.id);
        insert BAA;
        
        CatalogEndpoint.GetBuildingAccessTypeInfo();
        test.stopTest();
	}
	
	static testMethod void testGetPricingByPricingID(){
       	CatalogEndpoint.GetPricingByPricingID(new List<String>());
	}
	
	static testMethod void testGetPricingforProduct(){
		Mocks testdata = new Mocks();
		
		test.startTest();
        
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345');
        insert MArea;
        
		Building__c b = testdata.building;
		b.Building_Type__c = 'ILEC LSO';
		b.LSO_CLLI__C = 'PTLDOR13';
        b.Market_Area__c = MArea.Id;
		update b;
        
        Product_Family__c family = new Product_Family__c(Name = 'Test', Description__c = '12345', ProductFamilyExternalId__c = '12345');
        insert family;
        SalesProduct__c prod = new SalesProduct__c(SalesProductExternalID__c = '147', Product_Family__c = family.Id);
        insert prod;
        Feature_Grouping__c FGroup = new Feature_Grouping__c(FeatureGroupExternalID__c = '12345');
        insert FGroup;
        Sales_Rate_Plan_Description__c PlanDesc = new Sales_Rate_Plan_Description__c(SalesRatePlanDescExternalID__c = '12345', Feature_Grouping__c = FGroup.Id);
        insert PlanDesc;
        Sales_Product_Rate_Plan__c plan = new Sales_Product_Rate_Plan__c(Sales_Product__c = prod.Id, Sales_Rate_Plan_Description__c = PlanDesc.Id,  SalesProductRatePlanExternalID__c = '12345', Bandwidth__c = null);
        insert plan;
        Product_Pricing__c sampleData = new Product_Pricing__c(
            Term__c = null,
            Expiration_Date__c = Datetime.now().addDays(5),
            Market_Area__c = MArea.Id,
            Sales_Product_Rate_Plan__c = plan.Id,
            SalesRatePlanPricingExternalID__c = '147'
        );
        insert sampleData;
        
        System.Assert(!CatalogEndpoint.GetPricingforProduct(new integer[]{147,50},'PTLDOR13',1,10,36).isEmpty());
		System.Assert(CatalogEndpoint.GetPricingforProduct(new integer[]{147,50},'FAKECLLI',1,10,36).isEmpty());
        System.Assert(!CatalogEndpoint.GetPricingforProduct(new integer[]{147},'PTLDOR13',null,null,null).isEmpty());
        
        test.stopTest();
	}
	
	static testMethod void testGetPricingforProductWithAncillaryProducts(){
		Mocks testdata = new Mocks();
		
		test.startTest();
        
        Market_Area__c MArea = new Market_Area__c(MarketAreaExternalID__c = '12345');
        insert MArea;
        
		Building__c b = testdata.building;
		b.Building_Type__c = 'ILEC LSO';
		b.LSO_CLLI__C = 'PTLDOR13';
        b.Market_Area__c = MArea.Id;
		update b;
        
        System.Assert(CatalogEndpoint.GetPricingforProductWithAncillaryProducts(new integer[]{147},'PTLDOR13',1,10,36,false).isEmpty());
        System.Assert(CatalogEndpoint.GetPricingforProductWithAncillaryProducts(new integer[]{147},'PTLDOR13',1,10,36,true).isEmpty());
                      
        Product_Family__c family = new Product_Family__c(Name = 'Test', Description__c = '12345', ProductFamilyExternalId__c = '12345');
        insert family;
        SalesProduct__c prod = new SalesProduct__c(SalesProductExternalID__c = '147', Product_Family__c = family.Id);
        insert prod;
        Feature_Grouping__c FGroup = new Feature_Grouping__c(FeatureGroupExternalID__c = '12345');
        insert FGroup;
        Sales_Rate_Plan_Description__c PlanDesc = new Sales_Rate_Plan_Description__c(SalesRatePlanDescExternalID__c = '12345', Feature_Grouping__c = FGroup.Id);
        insert PlanDesc;
        Sales_Product_Rate_Plan__c plan = new Sales_Product_Rate_Plan__c(Sales_Product__c = prod.Id, Sales_Rate_Plan_Description__c = PlanDesc.Id,  SalesProductRatePlanExternalID__c = '12345', Bandwidth__c = null);
        insert plan;
        Product_Pricing__c sampleData = new Product_Pricing__c(
            Term__c = null,
            Expiration_Date__c = Datetime.now().addDays(5),
            Market_Area__c = MArea.Id,
            Sales_Product_Rate_Plan__c = plan.Id,
            SalesRatePlanPricingExternalID__c = '147'
        );
        insert sampleData;
		               
        System.Assert(CatalogEndpoint.GetPricingforProductWithAncillaryProducts(new integer[]{147},'FAKECLLI',1,10,36,false).isEmpty());
        System.Assert(!CatalogEndpoint.GetPricingforProductWithAncillaryProducts(new integer[]{147},'PTLDOR13',null,null,null,false).isEmpty());
        
        test.stopTest();
	}
	
	static testMethod void testGetProductFamilies(){
       	CatalogEndpoint.GetProductFamilies();
	}
	
	static testMethod void testGetProductFamilyByID(){
        CatalogEndpoint.GetProductFamilyByID(43);
	}
	
	static testMethod void testGetProductFeaturePricing(){
		CatalogEndpoint.GetProductFeaturePricing(new List<Integer>(), 0, '', '', new List<Integer>(), new List<Integer>());
	}
	
	static testMethod void testGetSalesProductClliInfo(){
       	CatalogEndpoint.GetSalesProductClliInfo();
        
        test.startTest();
        Product_Family__c family = new Product_Family__c(Name = 'Test', Description__c = '12345', ProductFamilyExternalId__c = '12345');
        insert family;
        SalesProduct__c SaleProd = new SalesProduct__c(SalesProductExternalID__c = '12345', Product_Family__c = family.Id);
        insert SaleProd;
   		Building__c Building = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US');
        insert Building;
        SPC_Product__c SPCProd = new SPC_Product__c(SalesProductExternalID__c = 12345);
        insert SPCProd;
        Building_Sales_Product__c BSaleProd = new Building_Sales_Product__c(Sales_Product__c = SaleProd.Id, Building__c = Building.Id, SPC_Product__c = SPCProd.Id);
        insert BSaleProd;
        
        CatalogEndpoint.GetSalesProductClliInfo();
        test.stopTest();
	}
	
	static testMethod void testGetSalesProductRatePlans(){
        CatalogEndpoint.AccessTechBandwidthView atbv = new CatalogEndpoint.AccessTechBandwidthView();
        atbv.AccessTechID = 6;
        atbv.Bandwidth = 10;
        
        test.startTest();
        
        Building__c Building = new Building__c(City__c = 'Toronto', State__c = 'ON', Address__c = '123 Address Street', Country__c = 'US', LSO_CLLI__C = 'PTLDOR13', Building_Type__c = 'ILEC LSO');
        insert Building;
        Access_Technology__c ATech = new Access_Technology__c(Access_Technology_ID__c = 123);
        insert ATech;
        Building_Access_Availability__c BAA = new Building_Access_Availability__c(Building__c = Building.Id, Access_Technology__c = ATech.id);
        insert BAA;
        Access_Types__c AType = new Access_Types__c(Access_Technology__c = ATech.Id, Access_Type_ID__c = 1);
        insert AType;
        
       	System.Assert(CatalogEndpoint.GetSalesProductRatePlans(new CatalogEndpoint.AccessTechBandwidthView[]{atbv}, 'PTLDOR13', 43).isEmpty());
		CatalogEndpoint.GetSalesProductRatePlans(new CatalogEndpoint.AccessTechBandwidthView[]{atbv}, '', 43);
        
        AType.Access_Type_ID__c = 7;
        update AType;
        CatalogEndpoint.GetSalesProductRatePlans(new CatalogEndpoint.AccessTechBandwidthView[]{atbv}, 'PTLDOR13', 43);
		AType.Access_Type_ID__c = 13;
        update AType;
        CatalogEndpoint.GetSalesProductRatePlans(new CatalogEndpoint.AccessTechBandwidthView[]{atbv}, 'PTLDOR13', 43);
        
        test.stopTest();
    }		
    
    static testMethod void testPricingProductView(){
        CatalogEndPoint.PricingProductView ppv = new CatalogEndPoint.PricingProductView();
        ppv.AccessTypeID = 6789;
        ppv.Bandwidth = 0.8517;
        ppv.MRR = 3.14159;
        ppv.NRR = 2.7132;
        ppv.ProductID = 1926734114;
        ppv.ProductName = 'NameOfProduct';
        ppv.RatePlanID = 10937892;
        ppv.RatePlanName = 'SomePlanName';
       	System.AssertEquals(ppv.AccessTypeID,6789);
        System.AssertEquals(ppv.Bandwidth,0.8517);
        System.AssertEquals(ppv.MRR,3.14159);
        System.AssertEquals(ppv.NRR,2.7132);
        System.AssertEquals(ppv.ProductID,1926734114);
        System.AssertEquals(ppv.ProductName,'NameOfProduct');
        System.AssertEquals(ppv.RatePlanID,10937892);
        System.AssertEquals(ppv.RatePlanName,'SomePlanName');
    }
    
    static testMethod void testSalesProductClliView(){
        CatalogEndpoint.SalesProductClliView spv = new CatalogEndpoint.SalesProductClliView();
        spv.LSOClli = 'Test';
        spv.SalesProductID = '01IC0000000tlmq';
        spv.BuildingID = '01IC0000000tlmq';
        spv.AccessTypes = new List<Decimal>{0.5,0.987};
        System.AssertEquals(spv.LSOClli,'Test');
        System.AssertEquals(spv.SalesProductID,'01IC0000000tlmq');
        System.AssertEquals(spv.BuildingID,'01IC0000000tlmq');
        System.AssertEquals(spv.AccessTypes, new List<Decimal>{0.5,0.987});
    }
}