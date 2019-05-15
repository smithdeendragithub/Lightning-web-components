@isTest
public with sharing class Test_OpportunityPDF extends TestUtils.TestClass {
	
	private static String BLOBCONTENTS = 'ALL\'S RIGHT WITH THE WORLD.';
	
	static testMethod void testGeneratePage() {
		Mocks testData = new Mocks();
		
		Opportunity opp = testData.opportunity;
		
		Contact c = testData.parentAccountContact;
		
		String section1 = Ref_PDF_Element__c.Section__c.getDescribe().getPicklistValues()[0].getLabel();
		String section2 = Ref_PDF_Element__c.Section__c.getDescribe().getPicklistValues()[1].getLabel();
		List<Ref_PDF_Element__c> rpes =  new List<Ref_PDF_Element__c>{
												new Ref_PDF_Element__c(Active__c = true, Document_Name__c = 'MSA', Name = 'MSA', Display_Criteria__c = '1', Section__c = section1)
												,new Ref_PDF_Element__c(Active__c = true, Document_Name__c = 'MSNay', Name = 'MSNay', Display_Criteria__c = '1 AND 2 AND 3 AND 4 AND 5 AND 6 AND 7 AND 8', Hide_When_Invalid__c = true, Section__c = section2)
											};
		insert rpes;
		
		List<Dynamic_SOQL_Criteria__c> soql = new List<Dynamic_SOQL_Criteria__c>{
													new Dynamic_SOQL_Criteria__c(Name = 'Opportunity-Exists', sObject__c = 'Opportunity', Unique_ID__c = 1)
													,new Dynamic_SOQL_Criteria__c(Name = 'OLI-Exists', sObject__c = 'OLI__c', Unique_ID__c = 2)
													,new Dynamic_SOQL_Criteria__c(Name = 'OCC-Exists', sObject__c = 'Oppty_Cost_Comparison__c', Unique_ID__c = 3)
													,new Dynamic_SOQL_Criteria__c(Name = 'ICB-Exists', sObject__c = 'ICB__c', Unique_ID__c = 4)
													,new Dynamic_SOQL_Criteria__c(Name = 'IC-Exists', sObject__c = 'Integra_Contract__c', Unique_ID__c = 5)
													,new Dynamic_SOQL_Criteria__c(Name = 'OppLoc-Exists', sObject__c = 'Opportunity_Location__c', Unique_ID__c = 6)
													,new Dynamic_SOQL_Criteria__c(Name = 'OLC-Exists', sObject__c = 'OpportunityLocationConfiguration__c', Unique_ID__c = 7)
													,new Dynamic_SOQL_Criteria__c(Name = 'TI-Exists', sObject__c = 'Technical_Information__c', Unique_ID__c = 8)
												};
		insert soql;
		
		Test.startTest();
		
        PageReference pageReference = Page.OpportunityPDFGeneration;
        Test.setCurrentPage(pageReference);
		
        pageReference.getParameters().put('oppId', opp.Id);
		
		OpportunityPDFController opc = new OpportunityPDFController();
		
        pageReference.getParameters().put('contactID', c.Id);
		opc.selectContact();
		
		System.assert(opc.selectableElements.size() == 1 && opc.selectableElements.containsKey(section1), 'Expected section "' + section1 + '" and not "' + section2 + '" in selectable elements map');
		opc.selectableElements.get(section1)[0].Selected = true;
		
		opc.getPDF();
		String pdfContents = EncodingUtil.base64Decode(opc.pdfString).toString();
		System.assert(pdfContents == BLOBCONTENTS, 'Error retrieving test PDF content. Expected "' + BLOBCONTENTS + '" but received "' + pdfContents + '"');
		
		opc.savePDF();
		
		Test.stopTest();
	}
	
	static testMethod void testDisplayPage() {
		Mocks testData = new Mocks();
		
		Opportunity opp = testData.opportunity;
		
		Contact c = testData.parentAccountContact;
		
		String section1 = Ref_PDF_Element__c.Section__c.getDescribe().getPicklistValues()[0].getLabel();
		List<Ref_PDF_Element__c> rpes =  new List<Ref_PDF_Element__c>{
												new Ref_PDF_Element__c(Active__c = true, Document_Name__c = 'PartnerOrderProfile', Name = 'PartnerOrderProfile', Display_Criteria__c = '1', Section__c = section1)
											};
		insert rpes;
		
		Test.startTest();
		
        PageReference pageReference = Page.OpportunityPDFDisplay;
        Test.setCurrentPage(pageReference);
		
        pageReference.getParameters().put('oppId', opp.Id);
        pageReference.getParameters().put('contId', c.Id);
        pageReference.getParameters().put('pdfComps', rpes[0].Id);
		
		OpportunityPDFDisplayController opdc = new OpportunityPDFDisplayController();
		
		//System.debug(opdc.salesChannel);
		System.debug(opdc.brandingURL);
		System.debug(opdc.businessDownturn);
		System.debug(opdc.currentOpptyLocs);
		System.debug(opdc.iCText);
		System.debug(opdc.techInfo);
		System.debug(opdc.oppLocOLIs);
		System.debug(opdc.oppLocMap);
		
		Test.stopTest();
	}
	
	public static Blob getTestPDFResults(){
		return Blob.valueOf(BLOBCONTENTS);
	}
}