@isTest
public with sharing class Mocks {

    public Mocks(){
    	List<Market_Area__c> maList = [SELECT ID FROM Market_Area__c WHERE NAME='National'];
        if (maList.size() == 0) {
            Market_Area__c ma = new Market_Area__c();
            ma.Name = 'National';
        	ma.MarketAreaExternalID__c = 'test36';
        	insert ma; 
        }
    }
    
    private User pUser;
    public User user {
    	get{
    		if(pUser == null){
    			system.debug('Building Mocks.user');
		        Profile p_standard = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
    			pUser = new User(FirstName = 'Test'
    							,LastName = 'Engineer'
    							,Email = 'standarduser@integra.com'
    							,Username = 'employee.standarduser@integra.com'
    							,Alias = 'sutest'
    							,ProfileId = p_standard.Id
    							,TimeZoneSidKey = 'America/Los_Angeles'
    							,LocaleSidKey = 'en_US'
    							,EmailEncodingKey = 'ISO-8859-1'
    							,LanguageLocaleKey = 'en_US'
    							,NTID__c = 'sutest');
    			insert pUser;
    		}
    		return pUser;
    	}
    }
    
    private Market_Area__c pMarketArea;
    public Market_Area__c marketArea {
    	get{
    		if(pMarketArea == null){
    			system.debug('Building Mocks.marketArea');
		        pMarketArea = new Market_Area__c(Name='asdf', MarketAreaExternalId__c='qwer1234', ICCMarketAreaID__c=1);
    			insert pMarketArea;
    		}
    		return pMarketArea;
    	}
    }
    
    private Customer_Detail__c pcustomerDetail;
    public Customer_Detail__c customerDetail {
    	get{
    		if(pcustomerDetail == null){
    			system.debug('Building Mocks.customerDetail');
        		pcustomerDetail = new Customer_Detail__c(ICC_Subscriber_ID__c = '-1');
    			insert pcustomerDetail;
    		}
    		return pcustomerDetail;
    	}
    }
    
    private Account pParentAccount;
    public Account parentAccount {
    	get{
    		if(pParentAccount == null){
    			system.debug('Building Mocks.parentAccount');
        		pParentAccount = new Account(Name = 'parent1'
                                            ,ShippingCountry = 'US'
        									,ShippingState = 'OR'
        									,ShippingCity = 'Portland'
        									,ShippingPostalCode = '97124'
        									,ShippingStreet = '1234 Test'
        									,Phone = '800-123-1234'
        									,Industry = 'Z - Unclassified');
    			insert pParentAccount;
    		}
    		return pParentAccount;
    	}
    }
    
    private List<Account> pAccounts;
    public List<Account> accounts {
    	get{
    		if(pAccounts == null){
    			system.debug('Building Mocks.accounts');
		        pAccounts = new List<Account>{
		        	new Account(Name = 'parent1 - loc1', ParentId = parentAccount.Id, ShippingCountryCode = 'US', ShippingState = 'OR', ShippingCity = 'Portland', ShippingPostalCode = '97124', ShippingStreet = '1234 Test', Industry = 'Z - Unclassified')
		        	,new Account(Name = 'parent1 - loc2', ParentId = parentAccount.Id, ShippingCountryCode = 'US', ShippingState = 'OR', ShippingCity = 'Portland', ShippingPostalCode = '97124', ShippingStreet = '1234 Test', Industry = 'Z - Unclassified')
		        };
    			insert pAccounts;
    		}
    		return pAccounts;
    	}
    }
    
    private Account pGrandChildAccount;
    public Account grandChildAccount {
    	get{
    		if(pGrandChildAccount == null){
    			system.debug('Building Mocks.grandChildAccount');
		        pGrandChildAccount = new Account(Name = 'grandChild1', ParentId = accounts[0].Id, ShippingCountryCode = 'US', ShippingState = 'OR', ShippingCity = 'Portland', ShippingPostalCode = '97124', ShippingStreet = '1234 Test' );
		        insert pGrandChildAccount;
    		}
    		return pGrandChildAccount;
    	}
    }
    
    private Contact pParentAccountContact;
    public Contact parentAccountContact {
    	get{
    		if(pParentAccountContact == null){
    			system.debug('Building Mocks.parentAccountContact');
    			pParentAccountContact = new Contact(LastName='test', email='test@test.com', AccountId=parentAccount.Id, Title = 'test', Phone = '5555555555');
        		insert pParentAccountContact;
    		}
    		return pParentAccountContact;
    	}
    }
    
    private Opportunity pOpportunity;
    public Opportunity opportunity {
    	get{
    		if(pOpportunity == null){
    			system.debug('Building Mocks.opportunity');
		        RecordType rt = [Select r.SobjectType, r.Name, r.Id From RecordType r where r.SobjectType = 'Opportunity' and r.Name = 'Retail'];
		        pOpportunity = new Opportunity(AccountId = parentAccount.Id
		        							,RecordTypeId = rt.Id
		        							,Product_Family__c = 'Data Services'
		        							,Product__c = 'Elan'
		        							,Name = 'Test Opp'
		        							,StageName = OpportunityUtils.STAGE_CONTRACT_NEGOTIATION
		        							,CloseDate = Date.today().addDays(30)
		        							,Customer_Requested_Due_Date__c = Date.today()
											,Amount = 0
											,CPE_Amount__c = 0
											,Term__c = '12'
											,Type ='New Logo'
											,Oppty_Sub_Type__c ='New Logo'
											,Initial_Appointment_Held_Date__c =Date.today().addDays(-5));
				Boolean oldVal = OpportunityTriggers.triggerDisabled;
				OpportunityTriggers.triggerDisabled = true;
    			insert pOpportunity;
				OpportunityTriggers.triggerDisabled = oldVal;
    		}
    		return pOpportunity;
    	}
    }
    
    private Order__c pOrder;
    public Order__c order {
    	get{
    		if(pOrder == null){
    			system.debug('Building Mocks.order');
		        pOrder = new Order__c(Opportunity__c = opportunity.Id);
		        insert pOrder;
    		}
    		return pOrder;
    	}
    }
    
    private Sub_Order__c pSubOrder;
    public Sub_Order__c suborder {
    	get{
    		if(pSubOrder == null){
		        pSubOrder = new Sub_Order__c(Service_Location__c = serviceLocation.Id, Sub_Sequence__c = 000000, Order__c = order.Id);
		        insert pSubOrder;
    		}
    		return pSubOrder;
    	}
    }
    
    // Opportunity Location and below
    private Opportunity_Location__c pLocations;
    public Opportunity_Location__c location {
    	get{
    		if(pLocations == null){
    			system.debug('Building Mocks.location');
		        pLocations = new Opportunity_Location__c(Opportunity__c = opportunity.Id, Order__c = order.Id, Name = parentAccount.Name, Service_Location__c = serviceLocation.Id, On_Hold__c = false);
		        insert pLocations;
    		}
    		return pLocations;
    	}
    }
    
    private List<OpportunityLocationConfiguration__c> pLstConfig;
    public List<OpportunityLocationConfiguration__c> lstconfig {
    	get{
    		if(pLstConfig == null){
    			system.debug('Building Mocks.lstconfig');
		        pLstConfig = new List<OpportunityLocationConfiguration__c>{
		        	new OpportunityLocationConfiguration__c(Name = 'Solution', Active__c = true, Opportunity_Location__c = location.Id, Market_Independent__c  = true, Term__c='36')
		        	,new OpportunityLocationConfiguration__c(Name = 'Solution 2', Active__c = false, Opportunity_Location__c = location.Id, Market_Independent__c  = true, Term__c='36')
		        };
		        insert pLstConfig;
    		}
    		return pLstConfig;
    	}
    }
    
    private List<OLI__c> pLstLineItems;
    public List<OLI__c> lstLineItems {
    	get{
    		if(pLstLineItems == null){
    			system.debug('Building Mocks.lstLineItems');
		        pLstLineItems = new List<OLI__c>{
		        	new OLI__c(MRC__c = 123, OpportunityLocationConfiguration__c=lstconfig[0].Id,  Qty__c=3, Price_Id__c='SP185CO65321TM0A876AV2291', PP_SalesProductExternalID__c='185', PP_Product_Pricing_Name__c='product1', Product_Family_Product__c='Basic Voice Services', DQ__c = 'Test Desc', PP_Sales_Rate_Plan_Description__c = 'Test Desc')
		        	,new OLI__c(MRC__c = 123, OpportunityLocationConfiguration__c=lstconfig[0].Id, Qty__c=1, Price_Id__c='SP185CO65321TM0A876AV2291', PP_SalesProductExternalID__c='185', PP_Product_Pricing_Name__c='product1', Product_Family_Product__c='Basic Voice Services', DQ__c = 'Test Desc', PP_Sales_Rate_Plan_Description__c = 'Test Desc')
		        	,new OLI__c(MRC__c = 123, OpportunityLocationConfiguration__c=lstconfig[0].Id, Qty__c=2, Price_Id__c='SP185CO65321TM0A876AV2291', PP_SalesProductExternalID__c='185', PP_Product_Pricing_Name__c='product1', Product_Family_Product__c='Basic Voice Services', DQ__c = 'Test Desc', PP_Sales_Rate_Plan_Description__c = 'Test Desc')
		        	,new OLI__c(MRC__c = 123, OpportunityLocationConfiguration__c=lstconfig[0].Id, Qty__c=1, Price_Id__c='SP185CO65321TM0A876AV2291', PP_SalesProductExternalID__c='185', PP_Product_Pricing_Name__c='product1', Product_Family_Product__c='Basic Voice Services', DQ__c = 'Test Desc', PP_Sales_Rate_Plan_Description__c = 'Test Desc')
		        };
		        //pLstLineItems = GlobalUtilities.updateOLIswithProductPricingInformation(pLstLineItems,lstconfig[0]);
    			insert pLstLineItems;
		        system.debug('Mocks debug1' + lstconfig);
		        system.debug('Mocks debug3' + lstLineItems);
		        pLstLineItems.add(new OLI__c(MRC__c = 123, OpportunityLocationConfiguration__c=lstconfig[0].Id, Qty__c=2, Parent_Opportunity_Line_Item__c = pLstLineItems[2].Id, Price_Id__c='SP185CO65321TM0A876AV2291', PP_SalesProductExternalID__c='185', PP_Product_Pricing_Name__c='product1', Product_Family_Product__c='Basic Voice Services', DQ__c = 'Test Desc', PP_Sales_Rate_Plan_Description__c = 'Test Desc'));
		        //pLstLineItems.add(new OLI__c(MRC__c = 123, OpportunityLocationConfiguration__c=lstconfig[0].Id, Qty__c=1, Parent_Opportunity_Line_Item__c = pLstLineItems[3].Id));
		        //pLstLineItems = GlobalUtilities.updateOLIswithProductPricingInformation(pLstLineItems,lstconfig[0]);
		        upsert pLstLineItems;
    		}
    		return pLstLineItems;
    	}
    }
    
    // Technical Information
    private List<Technical_Information__c> pLstTI;
    public List<Technical_Information__c> lstTI {
    	get{
    		if(pLstTI == null){
    			system.debug('Building Mocks.lstTI');
		        pLstTI = new List<Technical_Information__c>{
		        	new Technical_Information__c(Opportunity_Site__c=location.Id)
		        	,new Technical_Information__c(Opportunity_Site__c=location.Id)
		        };
    			insert pLstTI;
    		}
    		return pLstTI;
    	}
    }
    
    private List<Toll_Free_Number__c> pLstTollFreeNumbers;
    public List<Toll_Free_Number__c> lstTollFreeNumbers {
    	get{
    		if(pLstTollFreeNumbers == null){
    			system.debug('Building Mocks.lstTollFreeNumbers');
		        pLstTollFreeNumbers = new List<Toll_Free_Number__c>{
		        	new Toll_Free_Number__c(Technical_Information__c=lstTI[0].Id, X8XX_555_5555_Number__c='800-123-1234', Ring_to_Number__c='123-123-1234')
		        	,new Toll_Free_Number__c(Technical_Information__c=lstTI[0].Id, X8XX_555_5555_Number__c='800-123-1235', Ring_to_Number__c='123-123-1235')
		        };
    			insert pLstTollFreeNumbers;
    		}
    		return pLstTollFreeNumbers;
    	}
    }
    
    private List<Directory_Listing__c> pLstDirectoryListings;
    public List<Directory_Listing__c> lstDirectoryListings {
    	get{
    		if(pLstDirectoryListings == null){
    			system.debug('Building Mocks.lstDirectoryListings');
		        pLstDirectoryListings = new List<Directory_Listing__c>{
		        	new Directory_Listing__c(Technical_Information__c=lstTI[0].Id, Company_Name__c='asdf', Address__c='1234 main st', City__c='asdf', State__c='OR', 
		            						Zip__c='12345', Listing_Telephone_Number__c='123-123-1234', Type__c='Complementary', Main_Listing__c=true)
		            ,new Directory_Listing__c(Technical_Information__c=lstTI[0].Id, Main_Listing__c=false)
		        };
    			insert pLstDirectoryListings;
    		}
    		return pLstDirectoryListings;
    	}
    }
        
    // Additional Opportunity Location Information
    private Disconnect_Line_Item__c pDLI;
    public Disconnect_Line_Item__c dli {
    	get{
    		if(pDLI == null){
    			system.debug('Building Mocks.dli');
		        pDLI = new Disconnect_Line_Item__c(ServiceProductID__c='99999', Opportunity_Location__c = location.Id, MRC__c=10.0, FirstCN__c='Test', EPCProductID__c='999', EPCProductDescription__c='test desc');
		        insert pDLI;
    		}
    		return pDLI;
    	}
    }
    
    private Oppty_Cost_Comparison__c pOCC;
    public Oppty_Cost_Comparison__c occ {
    	get{
    		if(pOCC == null){
    			system.debug('Building Mocks.occ');
		        pOCC = new Oppty_Cost_Comparison__c(Qty__c=1, MRC__c=1, Description__c='test cc 2', Opportunity_Location__c=location.Id);
    			insert pOCC;
    		}
    		return pOCC;
    	}
    }         
    
    //Opportunity Product
    private Opportunity_Product__c pOpptyPrd;
    public Opportunity_Product__c opptyPrd {
    	get{
    		if(pOpptyPrd == null){
    			system.debug('Building Mocks.opptyPrd');
		        pOpptyPrd = new Opportunity_Product__c(Primary_Service_Location__c = servicelocation.Id, Sales_Product__c = 'Basic Voice Services', MRC__c = 129.0, Opportunity__c = opportunity.Id, bandwidth__c = '3', access_method__c = 'EoC');
		        insert pOpptyPrd;
    		}
    		return pOpptyPrd;
    	}
    }
    
    // CN and Features
    private List<CN__c> pLstCN;
    public List<CN__c> lstCN {
    	get{
    		if(pLstCN == null){
    			system.debug('Building Mocks.lstCN');
		        pLstCN = new List<CN__c>{
		        	new CN__c(Opportunity_Location__c = location.id, Opportunity_Line_Item__c = lstLineItems[0].id, name='310-555-1111')
		        	,new CN__c(Opportunity_Location__c = location.id, Opportunity_Line_Item__c = lstLineItems[0].id, name='310-555-2222')
					,new CN__c(Opportunity_Location__c = location.id, Opportunity_Line_Item__c = lstLineItems[4].id, name='310-555-3333')
		        };
    			insert pLstCN;
    		}
    		return pLstCN;
    	}
    }
    
    private List<CN_Feature__c> pLstCNFeature;
    public List<CN_Feature__c> lstCNFeature {
    	get{
    		if(pLstCNFeature == null){
    			system.debug('Building Mocks.lstCNFeature');
		        pLstCNFeature = new List<CN_Feature__c>{
		        	new CN_Feature__c(CN__c = lstCN[0].id, Opportunity_Line_Item__c = lstLineItems[0].id, Additional_Info__c = 'Prompt Value', Name = '310-555-1111 - Feature 1')
		        	,new CN_Feature__c(CN__c = lstCN[0].id, Opportunity_Line_Item__c = lstLineItems[1].id, Additional_Info__c = '', Name = '310-555-1111 - Feature Package 1 - Line')
		        	,new CN_Feature__c(CN__c = lstCN[1].id, Opportunity_Line_Item__c = lstLineItems[1].id, Additional_Info__c = '', Name = '310-555-2222 - Feature Package 1 - Line')
		        	,new CN_Feature__c(CN__c = lstCN[1].id, Opportunity_Line_Item__c = lstLineItems[2].id, Additional_Info__c = '', Name = '310-555-2222 - Feature Package 2 - Account')
		        	,new CN_Feature__c(CN__c = lstCN[0].id, Opportunity_Line_Item__c = lstLineItems[3].id, Additional_Info__c = '', Name = '310-555-1111 - Feature Package Content 1 - Line')
		        	,new CN_Feature__c(CN__c = lstCN[1].id, Opportunity_Line_Item__c = lstLineItems[3].id, Additional_Info__c = '', Name = '310-555-2222 - Feature Package Content 1 - Line')
		        	,new CN_Feature__c(CN__c = lstCN[1].id, Opportunity_Line_Item__c = lstLineItems[3].id, Additional_Info__c = '', Name = '310-555-2222 - Feature Package Content 2 - Account')
					,new CN_Feature__c(CN__c = lstCN[2].id, Opportunity_Line_Item__c = lstLineItems[4].id, Additional_Info__c = '', Name = '310-555-2222 - Test Desc')
		        };
    			insert pLstCNFeature;
    		}
    		return pLstCNFeature;
    	}
    }
    
    private Service_Location__c pServiceLocation;
    public Service_Location__c serviceLocation {
    	get{
    		if(pServiceLocation == null){
    			system.debug('Building Mocks.serviceLocation');
		        pServiceLocation = new Service_Location__c(Account__c = parentAccount.Id, Name = 'Test Loc', Location__c = loc.Id);
		        insert pServiceLocation;
    		}
    		return pServiceLocation;
    	}
    }

    
    private Building__c pBuilding;
    public Building__c building {
    	get{
    		if(pBuilding == null){
    			system.debug('Building Mocks.building');
        		pBuilding = new Building__c(Address__c = '1234 fake st'
        									,City__c = 'Coolsville'
                                            ,Country__c = 'US'
        									,State__c = 'OR'
        									,Postal_Code__c = '12345'
        									,Market_Area__c = marketArea.Id
											,Latitude__c = 45.5000
											,Longitude__c = -120.000
											,Net_Classification__c = 'On-net'
											,Building_Type__c = 'Commercial Building');
    			insert pBuilding;
    		}
    		return pBuilding;
    	}
    }
		
	private Access_Technology__c pAccessTec;
	public Access_Technology__c accessTec {
		get{
			if(pAccessTec == null){
				System.debug('building Mocs.accessTec');
				pAccessTec = new Access_Technology__c(
													Name = 'Test Access Tec'
													,Access_Technology_ID__c = 999
													,Client_Interface__c = 'Test if'
													,Friendly_Name__c = 'Test Access Tec');
				insert pAccessTec;
			}
			return pAccessTec;
		}
	}
	
	
	private Building_Access_Availability__c pBAA;
	public Building_Access_Availability__c BAA {
		get{
			if(pBAA == null){
				System.debug('Building Mocs.BAA');
				pBAA = new Building_Access_Availability__c(
														Name = 'Test BAA'
														,Building__c = building.Id
														,Access_Technology__c = accessTec.Id);
				insert pBAA;
			}
			return pBAA;
		}
	}
	
	
    
    private Location__c pLoc;
    public Location__c loc {
    	get{
    		if(pLoc == null){
    			system.debug('Building Mocks.loc');
        		pLoc = new Location__c(Building__c = building.Id);
    			insert pLoc;
    		}
    		return pLoc;
    	}
    }
    
    private Map<String, Provisioning_Product__c> pMpProvProd;
    public Map<String, Provisioning_Product__c> mpProvProd{
    	get{
    		if(pMpProvProd == null){
    			system.debug('Building Mocks.provProdMap');
    			pMpProvProd = new Map<String, Provisioning_Product__c>{
    					'Standard' => new Provisioning_Product__c(Name = 'Standard', External_ID__c = 1)
    					,'BO' => new Provisioning_Product__c(Name = 'BO', External_ID__c = 2)
    					};
    			insert pMpProvProd.values();
    		}
    		return pMpProvProd;
    	}
    }
    
    public List<Account> getAccountList(Integer numOfAccounts) {
        List<Account> accts = new List<Account>();
        
        for (Integer i = 0; i < numOfAccounts; i++) {
            Account a = new Account(name='Account ' + i, ShippingStreet='123 Main St', ShippingCity='Anytown', ShippingState='CA', ShippingPostalCode='00000', ShippingCountry='US');
            accts.add(a);
        }
        
        insert accts;
        
        return accts;
    }
}