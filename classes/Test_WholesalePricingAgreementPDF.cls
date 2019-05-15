@isTest
public class Test_WholesalePricingAgreementPDF extends TestUtils.TestClass{
    static testMethod void testGeneratePage() {
        Mocks testData = new Mocks();
        Pricing_Agreement__c wpa = new Pricing_Agreement__c();
        wpa.Account__c = testData.parentAccount.Id;
        wpa.Name = 'Test Wholesale Pricing Agreement';
        insert wpa;
        Contact c = testData.parentAccountContact;
        Test.startTest();
        PageReference pageReference = Page.PricingAgreementPDFGeneration;
        Test.setCurrentPage(pageReference);
        pageReference.getParameters().put('paId', wpa.Id);
        PricingAgreementPDFController  pac = new PricingAgreementPDFController();
        pageReference.getParameters().put('contactID', c.Id);
		pac.selectContact();
		pac.getPDF();
		String pdfContents = EncodingUtil.base64Decode(pac.pdfString).toString();
		pac.savePDF();
        Test.stopTest();
    }
    
    static testMethod void testDisplayPage() {
		Mocks testData = new Mocks();
		Pricing_Agreement__c wpa = new Pricing_Agreement__c();
        wpa.Account__c = testData.parentAccount.Id;
        wpa.Name = 'Test Wholesale Pricing Agreement';
        insert wpa;
		Contact c = testData.parentAccountContact;
		
		Test.startTest();
		
        PageReference pageReference = Page.PricingAgreementPDFDisplay;
        Test.setCurrentPage(pageReference);
		
        pageReference.getParameters().put('pricingAgreementId', wpa.Id);
       
		PricingAgreementPDFDisplayController padc = new PricingAgreementPDFDisplayController();
		
			
		Test.stopTest();
	}
}