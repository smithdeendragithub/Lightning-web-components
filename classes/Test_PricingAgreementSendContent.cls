@isTest
public with sharing class Test_PricingAgreementSendContent extends TestUtils.TestClass {
       
    private static final String ROLE_INTERNAL_SIGNER = 'Countersigner';
    
    //ContentWorkspace requires SeeAllData because you cannot create them via unit tests >:(
    @isTest(SeeAllData=true) static void testSendContent(){
        Mocks testData = new Mocks();
            
        List<ContentVersion> retCV = [Select Id, Title, VersionData, ContentSize, Opportunity__c from ContentVersion where Intended_Audience__c='Customer Facing' AND IsLatest=true LIMIT 1];
  		Pricing_Agreement__c wpa = new Pricing_Agreement__c();
        wpa.Account__c = testData.parentAccount.Id;
        wpa.Name = 'Test Wholesale Pricing Agreement';
        insert wpa;
        ApexPages.StandardController stdController = new ApexPages.StandardController(wpa); 
        PricingAgreementSendContentController ctr = new PricingAgreementSendContentController(stdController);
        boolean isEnabled = ctr.isDocuSignEnabled;
        ctr.currentPricingAgreement = wpa;
        ctr.selectedCase.ContactId = testData.parentAccountContact.Id;
        PageReference pr = ctr.addRecipient();
            
            //Add another contact
            List<User> users = [Select Id, Name, Email From User limit 1];
            
            ctr.selectedPricingAgreement.InternalSigner__c = users[0].Id;
            
            pr = ctr.addUserAsRecipient();
            
            //Add Docs
            ctr.selectedDocId = retCV[0].Id;
            pr = ctr.addDoc();
            
            //Reorder Docs
            ctr.sortOrder = retCV[0].Id;
            ctr.reorderDocs();
            
            //Remove Docs
            ctr.selectedDocId = retCV[0].Id;
            pr = ctr.removeDoc();
            
            ctr.selectedTemplate = ctr.lstTemplates[0].getValue();
            ctr.updateCurrentTemplate();
            
            ctr.selectedDeliveryMethod = ctr.DELIVERY_METHOD_TYPE_DOCUSIGN;
            ctr.changeDeliveryMethod();
            
            //We'll do this multiple times so we can cover the code of the exception throwing as well
            try {
                ctr.sendNow();
            } catch (Exception e) {
                
            }
            
            ctr.subject = 'test';
            try {
                ctr.sendNow();
            } catch (Exception e) {
                
            }
             
            ctr.message = 'test';
            try {
                ctr.sendNow();
            } catch (Exception e) {
                
            }   
            
            ctr.selectedRecipients[0].setTo(true);
            ctr.selectedRecipients[0].recipientType = GlobalUtilities.RECIPIENT_TYPE_SIGNER;
            
            ctr.selectedRecipients[1].setTo(true);
            ctr.selectedRecipients[1].recipientType = GlobalUtilities.RECIPIENT_TYPE_COUNTERSIGNER;
            
            try {
                ctr.sendNow();
            } catch (Exception e) {
         	}  
            
        //Add Docs again so there is something to send.
            ctr.selectedDocs.add(new PricingAgreementSendContentController.ContentDoc(retCV[0]));
            
            try {
                ctr.sendNow();
            } catch (Exception e) {
                
            }
            
            ctr.selectedDeliveryMethod = ctr.DELIVERY_METHOD_TYPE_EMAIL;
            ctr.changeDeliveryMethod();
            
            
            try {
                ctr.sendNow();
            } catch (Exception e) {
                
            }
    }
}