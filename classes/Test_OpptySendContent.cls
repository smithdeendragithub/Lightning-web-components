@isTest
public with sharing class Test_OpptySendContent extends TestUtils.TestClass {
       
    private static final String ROLE_INTERNAL_SIGNER = 'Countersigner';
    
    //ContentWorkspace requires SeeAllData because you cannot create them via unit tests >:(
    @isTest(SeeAllData=true) static void testSendContent(){
        Mocks testData = new Mocks();
            
         /*  
        ContentWorkspace cw = [select id from ContentWorkspace where Name = 'Sales workspace - ELI' LIMIT 1];
            
        ContentVersion newCV = new ContentVersion();
        newCV.Intended_Audience__c = 'Customer Facing';
        newCV.Title = 'Test';
        newCV.Opportunity__c = testData.opportunity.id;
        newCV.FirstPublishLocationId = cw.id;
        newCV.ContentUrl = 'http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_objects_contentversion.htm';
        insert newCV;
        */
        //Just to cover the code (if I do it as "system" (below) this select does not work for lack of permissions)
        List<ContentVersion> retCV = new List<ContentVersion>(); 
        retCV = [Select Id, Title, VersionData, ContentSize, Opportunity__c from ContentVersion where Intended_Audience__c='Customer Facing' AND IsLatest=true LIMIT 1];
  		        
        //for (ContentVersion cv: retCV) {
        //    cv.Opportunity__c = testData.opportunity.id; Commented out, Causing problems
        //}       
        
        update retCV;
        
        /**/
        
          
        //User u = [Select u.UserPermissionsSFContentUser, u.Profile.Name, u.ProfileId, u.Name, u.Id From User u where UserPermissionsSFContentUser = true AND IsActive=true limit 1];
        //system.runAs(u){
            
            
            ApexPages.StandardController stdController = new ApexPages.StandardController(testData.opportunity); 
            OpptySendContentController ctr = new OpptySendContentController(stdController);
            
            boolean isEnabled = ctr.isDocuSignEnabled;
            
            ctr.currentOppty = testData.opportunity;
            
            //ctr.InitOppty();
            ctr.selectedCase.ContactId = testData.parentAccountContact.Id;
               
            //let's make sure it is of the proper role so the code doesn't exit
            for(GlobalUtilities.Recipient recipient : ctr.selectedRecipients) {
              if(recipient.opptyRole != ROLE_INTERNAL_SIGNER) {
                recipient.opptyRole = ROLE_INTERNAL_SIGNER;
              }
            }   
            
            PageReference pr = ctr.addRecipient();
            
            //Add another contact
            List<User> users = [Select Id, Name, Email From User limit 1];
            
            ctr.selectedOpportunity.InternalSigner__c = users[0].Id;
            
            pr = ctr.addUserAsRecipient();
            
            //Search Docs
            //ctr.searchTitle = 'Sales';
            //ctr.searchDocs();
            
            //Add Docs
            ctr.selectedDocId = retCV[0].Id;
            pr = ctr.addDoc();
            
            //Reorder Docs
            ctr.sortOrder = retCV[0].Id;
            ctr.reorderDocs();
            
            //Search Docs (again, to cover more code)
            //ctr.maxDocsFound = 1;
            //ctr.searchTitle = retCV[0].title;
            //ctr.searchDocs();
            
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
            ctr.selectedDocs.add(new OpptySendContentController.ContentDoc(retCV[0]));
            
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
        //}
    }
}