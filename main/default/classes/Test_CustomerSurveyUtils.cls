@isTest
public with sharing class Test_CustomerSurveyUtils extends TestUtils.TestClass {
	private static Mocks testData = new Mocks();
	private static Contact zOCCon = null;
	private static Contact OCcon {
		get{
			if(zOCCon == null){
				Contact c = new Contact();
				c.AccountId = testData.parentAccount.Id;
				c.Default_Responsible_Party__c = true;
				c.Email = 'kit.randall@integratelecom.com';
				c.HasOptedOutOfEmail = false;
				c.FirstName = 'kit';
				c.LastName = 'randall';
				insert c;
				zOCCon = c;
			}
			return zOCCon;
		}
	}
	private static Contact zSECon = null;
	private static Contact SEcon {
		get{
			if(zSECon == null){
				Contact c = new Contact();
				c.AccountId = testData.parentAccount.Id;
				c.Default_Responsible_Party__c = true;
				c.Email = 'kit.randall@integratelecom.com';
				c.HasOptedOutOfEmail = false;
				c.FirstName = 'kit';
				c.LastName = 'randall';
				insert c;
				zSECon = c;
			}
			return zSECon;
		}
	}
	private static Contact zCAMCon = null;
	private static Contact CAMcon {
		get{
			if(zCAMCon == null){
				Contact c = new Contact();
				c.AccountId = testData.parentAccount.Id;
				c.Default_Responsible_Party__c = true;
				c.Email = 'kit.randall@integratelecom.com';
				c.HasOptedOutOfEmail = false;
				c.FirstName = 'kit';
				c.LastName = 'randall';
				insert c;
				zCAMCon = c;
			}
			return zCAMCon;
		}
	}
	private static Contact xCon = null;
	private static Contact noEmailCon{
		get{
			if(xCon == null){
				Contact c = new Contact();
				c.AccountId = testData.parentAccount.Id;
				c.Default_Responsible_Party__c = true;
				c.Email = '';
				c.HasOptedOutOfEmail = false;
				c.FirstName = 'kit';
				c.LastName = 'randall';
				insert c;
				xCon = c;
			}
			return xCon;
		}
	}
	private static Contact xOptedOutCon = null;
	private static Contact optedOutCon{
		get{
			if(xOptedOutCon == null){
				Contact c = new Contact();
				c.AccountId = testData.parentAccount.Id;
				c.Default_Responsible_Party__c = true;
				c.Email = 'kit.randall@integratelecom.com';
				c.HasOptedOutOfEmail = true;
				c.FirstName = 'kit';
				c.LastName = 'randall';
				insert c;
				xOptedOutCon = c;
			}
			return xOptedOutCon;
		}
	}
	
	static testMethod void TestOrderSurveys(){
		
		//general setup
		Account a = testData.parentAccount;
		Order__c o = testData.order;
		o.Account__c = a.Id;
		
		//setup objects for post install surveys
		Id rtExternalOrder = [select Id from RecordType where DeveloperName = 'External_Order' limit 1][0].Id;	
		Order_Property__c op = new Order_Property__c(RecordTypeId = rtExternalOrder, Type__c = 'Install Order', Order__c = o.Id);
		insert op;
		Sub_Order__c so = new Sub_Order__c(External_Order__r = op, Order__c = o.Id, External_Products__c='UC Cloud Voice DID Service');
		//Sub_Order__c so = new Sub_Order__c(External_Order__r = op, Order__c = o.Id);        
		insert so;
		Workstep__c ws = new Workstep__c(Name = 'Confirm Customer Acceptance', Order__c = o.Id);
		insert ws;
		
		Map<Id, Order__c> Ords = new Map<Id, Order__c>();
		Ords.put(o.Id, o);
		List<Sub_Order__c> soList = new List<Sub_Order__c>{so};
		Map<Id, List<Workstep__c>> soWSMap = new Map<Id, List<Workstep__c>>();
		soWSMap.put(so.Id, new List<Workstep__c>{ws});
		
		Test.startTest();
		//call CustomerSurveyUtils Method
		CustomerSurveyUtils.sendOrderSurveys(Ords, soList, soWSMap);
		
		Survey__c svy = new Survey__c(Account__c = a.Id, Name = 'Order Completion Survey', Survey_Name__c = 'Order Completion Survey', Surveyed_Contact__c = OCcon.Id, Sent_Date__c = (Date.today() - 90));
		insert svy;	
		
		CustomerSurveyUtils.sendOrderSurveys(Ords, soList, soWSMap);
		Test.stopTest();
	}
	
	static testMethod void TestOpportunitySurveys(){
		
		//general setup
		Account a = testData.parentAccount;
		Order__c o = testData.order;
		o.Account__c = a.Id;
		Opportunity opp = testData.opportunity;
		Map<Id, Opportunity> tOld = new Map<Id, Opportunity>( [select Id, AccountId, StageName, Order_Status__c, Type, Contract_Signed_Date__c, Amount, Opportunity_Product__c, Term__c from Opportunity where Id = :opp.Id]);
		
		Service_Location__c sloc = testData.serviceLocation;
		sloc.Account__c = a.Id;
		update sloc;
		
		Survey__c svy = new Survey__c(Account__c = a.Id, Name = 'Order Completion Survey', Survey_Name__c = 'Sales Experience Survey', Surveyed_Contact__c = SECon.Id, Sent_Date__c = (Date.today() - 90));
		insert svy;
	
		Opportunity_Product__c oppProd = testData.opptyPrd;
	
		//Opportunity_Location__c oppLoc = testData.location;
		List<OLI__c> olis = testData.lstLineItems;

		OpportunityLocationConfiguration__c oppLocCfg = [select Id, Opportunity_Location__c, MRC_Total__c, opportunity_Location__r.opportunity__r.CPQ_Total__c from OpportunityLocationConfiguration__c where Id = :testData.lstconfig[0].Id limit 1];
		Opportunity_Location__c oppLoc = [select Opportunity__c, MRC_Total__c from Opportunity_Location__c where Id = :testData.location.Id limit 1];
		opp = [select Id, CPQ_Total__c from Opportunity where Id = :opp.Id limit 1];
		
		System.debug('KIT: location matches: ' + String.valueOf(oppLoc.Opportunity__c == opp.Id));
		System.debug('KIT: sol matches: ' + String.valueOf(oppLocCfg.Opportunity_Location__c == oppLoc.Id));
		System.debug('KIT: CPQTotal: ' + opp.CPQ_Total__c);
		System.debug('KIT: MRCTotal: ' + oppLoc.MRC_Total__c);
		System.debug('KIT: solMRCTotal: ' + oppLocCfg.MRC_Total__c);
		for(OLI__c oli : olis){
			System.debug('KIT: oli matches sol: ' + String.valueOf(oli.OpportunityLocationConfiguration__c == oppLocCfg.Id));
			System.debug('KIT: oli total: ' + String.valueOf(oli.qty__c * oli.MRC__c));
		}

		Test.startTest();
		//update the opp to trigger the survey loogic.
		//setup objects for sales experience surveys
		opp.AccountId = a.Id;
		//opp.StageName = OpportunityUtils.STAGE_CLOSED_WON;
		opp.StageName = OpportunityUtils.STAGE_5;
		opp.Order_Status__c = 'Order to Pending';
		opp.Type = 'New Logo';
		opp.Contract_Signed_Date__c = Date.today();
		opp.Amount = 1000;
		opp.Opportunity_Product__c = 'test product';
		opp.Term__c = '36';
		

		//OpportunityTriggers.lastRunMap.clear();
		//ApexUtils.triggerCounts.get('Opportunity').clear();
		//update opp;
		
		CustomerSurveyUtils.sendOpportunitySurveys(new List<Opportunity>{opp}, tOld);
		Test.stopTest();
	}
	/*
	static testMethod void TestCaseSurveys(){
		
		//general setup
		Account a = testData.parentAccount;
		
		//setup objects for customer account manager surveys
		Case cNew = new Case(Status = 'New', Commit_Date__c = Date.today(), Origin = 'Account Review Visit', Type = 'Proactive', ContactId = SEcon.Id, AccountId = a.Id);
		insert cNew;
		cNew.Status = 'Closed';
		
		Test.startTest();
		//update the case to trigger the survey logic.
		update cNew;
		
		Survey__c svy = new Survey__c(Account__c = a.Id, Name = 'Customer Account Manager Survey', Survey_Name__c = 'Order Completion Survey', Surveyed_Contact__c = optedOutCon.Id, Sent_Date__c = (Date.today() - 90));
		insert svy;
		
		cNew.Status = 'New';
		cNew.ContactId = CAMcon.Id;
		cNew.Closed_Case_Change_Confirmation__c = true;
		update cNew;
		//a.Account_Sales_Channel__c = 'Government and Education';
		update a;
		cNew.Status = 'Closed';
		update cNew;
		
		cNew.Status = 'New';
		cNew.Origin = 'Email';
		cNew.Type = 'Billing';
		cNew.Closed_Case_Change_Confirmation__c = true;
		update cNew;
		//a.Account_Sales_Channel__c = 'Integra Business';
		update a;
		cNew.Status = 'Closed';
		update cNew;
		
		Test.stopTest();
	}
	*/
	static testMethod void testSurveyError(){
		Account a = testData.parentAccount;
		Order__c o = testData.order;
		o.Account__c = a.Id;
		
		Survey__c svy = new Survey__c(Account__c = a.Id, Name = 'Order Completion Survey', Survey_Name__c = 'Order Completion Survey', Surveyed_Contact__c = CAMcon.Id, Sent_Date__c = (Date.today() - 90));
		insert svy;	
		
		Integration_Error__c error = new Integration_Error__c(Message__c = 'test', Info__c = 'test', ObjectID__c = svy.Id, RelatedID__c = o.Id);
		insert error;
		
		Test.startTest();
		CustomerSurveyUtils.resendFailedSurveys(new List<Integration_Error__c>{error});
		Test.stopTest();
	}

    static testMethod void TestContactSurveys(){

    	Contact c = new Contact();
		c.AccountId = testData.parentAccount.Id;
		c.Email = 'marc.kirouac@allstream.com';
		c.HasOptedOutOfEmail = false;
		c.FirstName = 'Marc';
		c.LastName = 'Kirouac';
		insert c;

		Test.startTest();
        CustomerSurveyUtils.createContactSurveys(new List<Contact> {c}, CustomerSurveyUtils.SurveyType.RECOMMEND_ALLSTREAM_SURVEY_NAME);
		Test.stopTest();
	}
    
}