@isTest
public with sharing class Test_OpportunityTriggers {
	
	static testMethod void testOwnershipChange(){
		//mock ownership change with non shallow clone
        List<Opportunity> oppts1 = createOpportunityPrototypeList(1);
        List<Opportunity> oppts2 = oppts1.deepClone();
        
        upsertOpps(oppts2, true);
        
        List<User> newUser = ([SELECT Id, LastName, Name FROM User WHERE UserType = 'Standard' limit 5]);
        
        //check that they are the same owner id
        System.assertEquals(oppts1.get(0).OwnerId, oppts2.get(0).OwnerId);
        
        oppts2.get(0).OwnerId = getStandardUser().Id;
        
        Boolean isDifferent = (oppts1.get(0).OwnerId == oppts2.get(0).OwnerId);
        system.assert(!isDifferent);
		
        upsertOpps(oppts2, false);
	}
    
    /*static testMethod void assignPreviousOwnerIdTest(){
        
        //mock ownership change with non shallow clone
        List<Opportunity> oppts1 = createOpportunityPrototypeList(1);
        List<Opportunity> oppts2 = oppts1.deepClone();
        
        upsertOpps(oppts2, true);
        
        List<User> newUser = ([SELECT Id, LastName, Name FROM User WHERE UserType = 'Standard' limit 5]);
        
        //check that they are the same owner id
        System.assertEquals(oppts1.get(0).OwnerId, oppts2.get(0).OwnerId);
        
        oppts2.get(0).OwnerId = getStandardUser().Id;
        
        Boolean isDifferent = (oppts1.get(0).OwnerId == oppts2.get(0).OwnerId);
        system.assert(!isDifferent);
        
        OpportunityTriggers.assignPreviousOwnerId(oppts1, oppts2);
        
        OpportunityTriggers.sendOwnerChangeNotification(oppts1, oppts2);        
        OpportunityTriggers.assignLookUpOwnerId(oppts1);
        OpportunityTriggers.createOrderIfNeeded(oppts1);
        //System.assertEquals(null, oppts1.get(0).PreviousOwner__c);
        
        upsertOpps(oppts2, false);
    }*/
    
    /*static testMethod void updateRelatedICBStatusesTest(){
        
        List<Opportunity> opps = createOpportunityPrototypeList(1);
        
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
        
        system.debug(opps);
        
        for(Opportunity o : opps.deepClone()){
            newMap.put(o.id, o);
        }
        
        oldMap = newMap.deepClone();
        
        for(Opportunity statusOpp : newMap.values()){
            statusOpp.StageName = OpportunityUtils.STAGE_CLOSED_LOST;
        }
        
        OpportunityTriggers.updateRelatedICBStatuses(newMap, oldMap);
        
        for(Opportunity o : newMap.values()) {
            o.StageName = OpportunityUtils.STAGE_CLOSED_LOST;
            o.Lost_Reason__c = 'No Opportunity or No Decision';
            o.Lost_Sub_Reason__c = 'Lost Funding';
        }
        
        upsertOpps(newMap.values(), false);
        
        Map<Id, Opportunity> oldMap2 = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newMap2 = new Map<Id, Opportunity>(); 
        
        newMap2 = newMap.deepClone();
        oldMap2 = newMap2.deepClone();
        
        date mockDate = date.newinstance(2013, 10, 17);
        date mockDate2 = mockDate.addDays(2);
        string mockcurrencystr = '1200.566';
        decimal currencyvalue = decimal.valueOf(mockcurrencystr);
        
        for(Opportunity o : newMap2.values()) {
            o.StageName = OpportunityUtils.STAGE_CLOSED_WON;
            o.Contract_Signed_Date__c = mockDate;
            o.Customer_Requested_Due_Date__c = mockDate2;
            o.Product_Family__c = 'PBX Services';
            o.Product__c = 'Phone Systems & Equipment'; 
            
            o.CPE_Amount__c = currencyvalue;
        }
        
        OpportunityTriggers.updateRelatedICBStatuses(newMap2, oldMap2);
        
        upsertOpps(newMap2.values(), false);
    }*/
    
    static testMethod void opportunitySplitTest(){
    	
        Mocks testData = new Mocks();
        
        Opportunity o = testData.opportunity;
        o.Split_Percent_1__c = 99;
        o.Split_Percent_2__c = 1;
        o.Split_Owner_1__c = testData.user.Id;
        o.Split_Owner_2__c = testData.user.Id;
        
        upsertOpps(new List<Opportunity>{o}, false);
    }
    
    static testMethod void updateOpportunityTest(){
        Mocks testData = new Mocks();  
        Account acc =testData.parentAccount;
        Opportunity opp=testData.opportunity;
        LIst<Opportunity> lstopp=new LIst<Opportunity> ();
        Opportunity oppNew=new Opportunity(id=opp.id);
        update oppNew;
        upsertOpps(new List<opportunity>{opp}, false);
    }
    
 	static testMethod void testcheckForMissingResponsibleParty(){
        Map<Id, Opportunity> mapopp = new Map<Id, Opportunity>();
        Mocks testData = new Mocks(); 
        
        Account acc = testData.parentAccount;
        Opportunity opp1 = testData.opportunity; 
        //opp1.StageName = OpportunityUtils.STAGE_CLOSED_WON;
        opp1.StageName = OpportunityUtils.STAGE_5;
		
		Service_Location__c sLoc = testData.serviceLocation;
		
        Opportunity_Product__c op = new Opportunity_Product__c(Active__c = true
																,Sales_Product__c = 'Dark Fiber'
																,Opportunity__c = opp1.id
																,MRC__c = 100
																,Bandwidth__c = '50000000'
																,Access_Method__c = 'Dark Fiber'
																,RecordTypeId = GetTypeIdByName(Opportunity_Product__c.sObjectType, 'Manual Entry')
																,Primary_Service_Location__c = sLoc.Id);
		insert op;
		
        mapopp.put(opp1.id,opp1);
		
     	Test.startTest();
		
        OpportunityTriggers.checkForMissingResponsibleParty(mapopp);
		
		Contact c = testdata.parentAccountContact;
		
        OpportunityContactRole oppcont = new OpportunityContactRole();
        oppcont.OpportunityId = opp1.id;
        oppcont.contactId = c.id;
        insert oppcont;
		
        OpportunityTriggers.checkForMissingResponsibleParty(mapopp);
		
		c.Email = null;
		update c;
		
        OpportunityTriggers.checkForMissingResponsibleParty(mapopp);
		
     	Test.stopTest();
    }
	
	static testmethod void testClosedWon(){
		Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		Service_Location__c sLoc = testData.serviceLocation;
		
		Contact c = testData.parentAccountContact;
		c.Default_Responsible_Party__c = true;
		update c;
		
        Opportunity o = new Opportunity(Name = 'Test Opp'
										,AccountId = a.Id
										,RecordTypeId = GetTypeIdByName(Opportunity.sObjectType ,'Retail')
										,CloseDate = Date.today().addDays(-1)
										,StageName = 'Identification'
										,Term__c = '12');
		insert o;
		
        Opportunity_Product__c op = new Opportunity_Product__c(Active__c = true
																,Sales_Product__c = 'Dark Fiber'
																,Opportunity__c = o.Id
																,MRC__c = 100
																,Bandwidth__c = '50000000'
																,Access_Method__c='Dark Fiber'
																,RecordTypeId = GetTypeIdByName(Opportunity_Product__c.sObjectType, 'Manual Entry')
																,Primary_Service_Location__c=sLoc.Id);
		insert op;
		
		Test.startTest();
		
		//o.StageName = OpportunityUtils.STAGE_CLOSED_WON;
		o.StageName = OpportunityUtils.STAGE_5;
		o.Amount = 9999;
		o.Contract_Signed_Date__c = Date.today();
		o.Customer_Requested_Due_Date__c = Date.today();
		o.LOA_Signed_By__c = c.Id;
		o.Opportunity_Product__c = 'stuff';
		o.Bypass_Validation__c = true;
		upsertOpps(new List<Opportunity>{o}, false);
		
		Test.stopTest();
	}
	
	public static testmethod void testSurvey(){
		Mocks testData = new Mocks();
        
		Account a = new Account(Name = 'surveyTest'
                                			,ShippingCountry='US'
                                			,ShippingState = 'OR'
        									,ShippingCity = 'Portland'
        									,ShippingPostalCode = '97124'
        									,ShippingStreet = '1234 Test'
        									,Phone = '800-123-1234'
        									,Industry = 'Z - Unclassified');
		insert a;
		
		Opportunity op = new Opportunity(AccountId = a.Id
		        							,RecordTypeId = GetTypeIdByName(Opportunity.sObjectType ,'Retail')
		        							,Product_Family__c = 'Data Services'
		        							,Product__c = 'Elan'
		        							,Name = 'Survey Test Opp'
		        							,StageName = OpportunityUtils.STAGE_QUALIFIED
		        							,CloseDate = Date.today().addDays(30)
		        							,Customer_Requested_Due_Date__c = Date.today());
		
		
    	upsertOpps(new List<Opportunity>{op}, true);
		
		
		Order__c o = new Order__c(Opportunity__c = op.Id, Account__c = a.id);
		
		insert o;		
		
		Service_Location__c sloc = new Service_Location__c(Account__c = a.Id, Name = 'Surve Test Loc', Location__c = testData.loc.Id);
		
		insert sloc;
		
		Opportunity_Location__c location = new Opportunity_Location__c(Opportunity__c = op.Id, Order__c = o.Id, Name = a.Name, Service_Location__c = sloc.Id, On_Hold__c = false);
		
		insert location;
		
		OpportunityLocationConfiguration__c locConfig = new OpportunityLocationConfiguration__c(Name = 'Surve Solution', Active__c = true, Opportunity_Location__c = location.Id, Market_Independent__c  = true, Term__c='36');
		
		insert locConfig;
		
		OLI__c oli = new OLI__c(MRC__c = 375.00, OpportunityLocationConfiguration__c=locConfig.Id,  Qty__c=3, Price_Id__c='SP185CO65321TM0A876AV2291', PP_SalesProductExternalID__c='185', PP_Product_Pricing_Name__c='product1', Product_Family_Product__c='Basic Voice Services');
		
		insert oli;
		
		Contact con = new Contact();
		con.AccountId = a.Id;
		con.Default_Responsible_Party__c = true;
		con.Email = 'kit.randall@integratelecom.com';
		con.HasOptedOutOfEmail = false;
		con.FirstName = 'kit';
		con.LastName = 'randall';
		
		insert con;
		
		Survey__c s = new Survey__c();
		s.Name = 'Order Completion Survey';
		s.Survey_Name__c = 'Sales Experience';
		s.Sent_Date__c = Date.today().addDays(-90);
		s.Account__c = a.id;
		s.Opportunity__c = op.id;
		s.Surveyed_Contact__c = con.Id;
		
		insert s;
		
		//op.StageName = OpportunityUtils.STAGE_CLOSED_WON;
		op.StageName = OpportunityUtils.STAGE_5;
		op.Amount = 9999;
		op.Contract_Signed_Date__c = Date.today();
		op.Customer_Requested_Due_Date__c = Date.today();
		op.Opportunity_Product__c = 'stuff';
		op.Order_Status__c = 'Order to Pending';
		op.Term__c = '36';
		op.AccountId = a.Id;
		op.LOA_Signed_By__c = con.Id;
		op.Bypass_Validation__c = true;
		
		Test.startTest();
		
		upsertOpps(new List<Opportunity>{ op}, false);
		
		test.stopTest();
		
	}
    
    /* Utility methods */
    
    static void upsertOpps(List<Opportunity> opps, boolean doInsert){
        /*OpportunityTriggers.beforeRun = OpportunityTriggers.afterRun = true;
		OpportunityTriggers.lastRunMap.clear();*/
        
        if(doInsert) upsert opps;
        else update opps;
    }
    
    public static List<Opportunity> createOpportunityPrototypeList(Integer numOppt){
        
        List<Opportunity> oppts = new List<Opportunity>();
        Id typeid = GetTypeIdByName(Opportunity.sObjectType ,'Retail');
        
        User u = getStandardUser();   
        
        Mocks testData = new Mocks();
        for (Integer i = 0; i < numOppt; i++) {
            
            Opportunity oppt = testData.opportunity;           
            oppt.RecordTypeId = typeid;
            oppt.StageName = OpportunityUtils.STAGE_CLOSED_LOST;
            oppt.LeadSource = 'Jigsaw';
            oppt.Lost_Reason__c = 'Network';
            oppt.Term__c = '36';
            oppt.Name = 'Acme Explosives ' + date.today();
            oppt.CloseDate = date.today().addDays(10);
            
            //insert oppt;
            
            ICB__c pricingicb = new ICB__c();
            pricingicb.ICB_Type__c = 'Pricing';
            //icb.ICB_Pricing_Reason__c = 'Capital Build';
            pricingicb.Description__c = 'unit test value';              
            pricingicb.Sales_Engineer__c = u.Id;
            
            //insert pricingicb;
            
            ICB__c techincalicb = new ICB__c();
            techincalicb.ICB_Type__c = 'Technical';
            //icb.ICB_Pricing_Reason__c = 'Capital Build';
            techincalicb.Description__c = 'unit test value';                
            techincalicb.Sales_Engineer__c = u.Id;
            
            //insert techincalicb;
            
            oppts.add(oppt);                    
        }
        
        return oppts;
    }
    
    static List<ICB__c> createICBPrototypeList(Integer numIcbs){
        
        List<ICB__C> icbs = new List<ICB__C>();
        User u = getStandardUser();   
        
        for (Integer i = 0; i < numIcbs; i++) {
            
            ICB__c icb = new ICB__c();
            icb.ICB_Type__c = 'Pricing';
            icb.Description__c = 'Test Pricing ICB';                
            icb.Sales_Engineer__c = u.Id;
            
            icbs.add(icb);
        }
        return icbs;
    }
    
    static Id GetTypeIdByName(SObjectType so, string name){
        Schema.DescribeSObjectResult d = so.getDescribe(); 
        Map<String,Schema.RecordTypeInfo> typeMapByName = d.getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtByName =  typeMapByName.get(name);
        return rtByName.getRecordTypeId();
    }
	
    private static User getStandardUser(){
		return [SELECT Title, Id, Username, Name FROM User WHERE IsActive = true AND UserType LIKE:'%Standard%' LIMIT 1];
    }
}