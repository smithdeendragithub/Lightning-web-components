@isTest
public with sharing class Test_PrintOrder extends TestUtils.TestClass {
	
    static testMethod void testController() {
        
        Mocks testData = new Mocks();
        RecordType rt = [select Id from RecordType WHERE SobjectType = 'Technical_Information__c' and DeveloperName != 'Features_Schedule' limit 1];
        List<Technical_Information__c> tis = new List<Technical_Information__c>{new Technical_Information__c(Name = '02-Features_Schedule', Opportunity_Site__c = testData.location.id,  RecordTypeId = rt.Id)};
		insert tis;
        
        List<CN__c> lstCN = new List<CN__c>{
		        	new CN__c(Opportunity_Location__c = testData.location.id, Opportunity_Line_Item__c = testData.lstLineItems[0].id, name='310-555-1111')
		        	,new CN__c(Opportunity_Location__c = testData.location.id, Opportunity_Line_Item__c = testData.lstLineItems[0].id, name='310-555-2222')
					,new CN__c(Opportunity_Location__c = testData.location.id, Opportunity_Line_Item__c = testData.lstLineItems[4].id, name='310-555-3333')
		        };
        insert lstCN;
        
		List<CN_Feature__c>   pLstCNFeature = new List<CN_Feature__c>{
            new CN_Feature__c(CN__c = lstCN[0].id, Opportunity_Line_Item__c = testData.lstLineItems[0].id, Additional_Info__c = 'Prompt Value', Name = '310-555-1111 - Feature 1')
                ,new CN_Feature__c(CN__c = lstCN[0].id, Opportunity_Line_Item__c = testData.lstLineItems[1].id, Additional_Info__c = '', Name = '310-555-1111 - Feature Package 1 - Line')
                ,new CN_Feature__c(CN__c = lstCN[1].id, Opportunity_Line_Item__c = testData.lstLineItems[1].id, Additional_Info__c = '', Name = '310-555-2222 - Feature Package 1 - Line')
                ,new CN_Feature__c(CN__c = lstCN[1].id, Opportunity_Line_Item__c = testData.lstLineItems[2].id, Additional_Info__c = '', Name = '310-555-2222 - Feature Package 2 - Account')
                ,new CN_Feature__c(CN__c = lstCN[0].id, Opportunity_Line_Item__c = testData.lstLineItems[3].id, Additional_Info__c = '', Name = '310-555-1111 - Feature Package Content 1 - Line')
                ,new CN_Feature__c(CN__c = lstCN[1].id, Opportunity_Line_Item__c = testData.lstLineItems[3].id, Additional_Info__c = '', Name = '310-555-2222 - Feature Package Content 1 - Line')
                ,new CN_Feature__c(CN__c = lstCN[1].id, Opportunity_Line_Item__c = testData.lstLineItems[3].id, Additional_Info__c = '', Name = '310-555-2222 - Feature Package Content 2 - Account')
                ,new CN_Feature__c(CN__c = lstCN[2].id, Opportunity_Line_Item__c = testData.lstLineItems[4].id, Additional_Info__c = '', Name = '310-555-2222 - Test Desc')
                };
        insert pLstCNFeature;
        
        
        test.startTest();
        
        PageReference pageReference = Page.PrintOrder;
        pageReference.getParameters().put('oppid', testData.opportunity.Id);
        pageReference.getParameters().put('solutionid', testData.lstconfig[0].Id);
        Test.setCurrentPage(pageReference);        
        
		string s = PrintOrderController.DEFAULT_RESPONSIBLE_PARTY;
		PrintOrderController.orderWrapper ow = new PrintOrderController.orderWrapper(testData.order);
		PrintOrderController.solutionWrapper sw = new PrintOrderController.solutionWrapper(testData.lstconfig[0]);
		List<QuoteWrapper.Product> qwps = new List<QuoteWrapper.Product>();
		QuoteWrapper.Product qwp = new QuoteWrapper.Product();
		qwp.Name = 'Test';
		qwp.ProductID = '1';
		qwp.externalID = '1';
		qwp.productFamilyId = '1';
		qwp.Salesproduct = 'Test Product';
		qwp.SalesProductGroup = 'Test Product Groups';
		QuoteWrapper.QuoteLineItem qli = new QuoteWrapper.QuoteLineItem(testData.lstLineItems[0]);
		qwp.lines.add(qli);
		qwps.add(qwp);
    
        PrintOrderController pc = new PrintOrderController();
		pc.configureProductApproval(qwps,sw);
     		
		PrintOrderController.contactWrapper cw = new PrintOrderController.contactWrapper(testData.parentAccountContact,'test');
    
		
        test.stopTest();
    }
}