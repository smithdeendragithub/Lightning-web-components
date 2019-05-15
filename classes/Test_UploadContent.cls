@isTest
public with sharing class Test_UploadContent extends TestUtils.TestClass {
	
    static testMethod void testStandardUpload() {
        //Testing the file upload of content to an account
        
        Test.startTest();
        
        Mocks testData = new Mocks();
        
        //Get a Workspace
        List<ContentWorkspace> retVal = new List<ContentWorkspace>(); 
        retVal = [Select Id, Name from ContentWorkspace LIMIT 1];
        
        //Get a content record to re-upload (anything works, really)
        List<ContentVersion> retCV = new List<ContentVersion>(); 
        //retCV = [Select Id, VersionData, PathOnClient from ContentVersion LIMIT 1];
        ContentVersion c = new ContentVersion();
        retCV.add(c);
       
        
        PageReference pageReference = Page.AccountUploadContent;
        pageReference.getParameters().put('Id', testData.parentAccount.id);
        Test.setCurrentPage(pageReference);
        
        UploadContentController ctr = new UploadContentController();
        
        ctr.parentId=testData.parentAccount.id;
        
        ctr.isGeneratedContent = false;
        //Trying to trigger as much code as possible (going through getter/setter)
        ctr.setisGeneratedContent(false);
        Boolean b = ctr.getisGeneratedContent();
        
        ContentVersion cv = ctr.cv;
        
        cv.FirstPublishLocationId = retVal[0].Id;
        cv.Asset_Type__c = 'Marketing Resources';
        cv.Asset_SubType__c = 'Address Validation';
        
        //Trying to cover as much code as possible, thus triggering the exceptions.
        try {
            ctr.save();
        } catch (Exception e) {
            
        }
        
        cv.Title='CPQ Test - test';
        try {
            ctr.save();
        } catch (Exception e) {
            
        }
        
        cv.Description='Test';
        try {
            ctr.save();
        } catch (Exception e) {
            
        }
        
        ctr.fileContents = retCV[0].VersionData;
        
        //Since we can't read the members of a workspace from apex
        //This test covers the "fail" part of the save, as there aren't enough permissions for the test user to actually publish in that workspace.
        try {
            ctr.save();
        } catch (Exception e) {
            
        }
        
        ctr.cancel();
        
        Test.stopTest();
        
    }
    
   static testMethod void testGeneratedUpload() {
       //Testing the file upload of content to an account
        
        Mocks testData = new Mocks();
        
        //Get a Workspace
        List<ContentWorkspace> retVal = new List<ContentWorkspace>(); 
        retVal = [Select Id, Name from ContentWorkspace LIMIT 1];
        
        
        //Get a Document to Save
        string url = '/apex/ProposalGeneratePDF?id=' + testData.opportunity.id + '&recipient=' + testData.parentAccountContact.id + '&document=' + String.valueOf(GlobalUtilities.DOCGENBIT_COVER_PAGE) + '&rand=' + Math.random(); 
        
        PageReference pdfPage = New Pagereference(url);
        Blob pdfBlob; // =  Blob.valueOf('Empty Blob');
        try{ 
            pdfBlob = pdfPage.getContent(); 
        }catch(VisualforceException e){
            pdfBlob = Blob.valueOf('BLob when occur error');
        }

        //Now Set up the actual test
        PageReference pageReference = Page.AccountUploadContent;
        pageReference.getParameters().put('Id', testData.opportunity.id);
        Test.setCurrentPage(pageReference);
        
        UploadContentController ctr = new UploadContentController();
        
        ctr.parentId=testData.opportunity.id;
        ctr.fileContentsUpload= pdfBlob;
        
        ctr.isGeneratedContent = true;
        //Trying to trigger as much code as possible (going through getter/setter)
        ctr.setisGeneratedContent(true);
        
        ContentVersion cv = ctr.cv;
        
        cv.FirstPublishLocationId = retVal[0].Id;
        cv.Asset_SubType__c = 'Address Validation';
        cv.Title='CPQ Test - test';
        cv.Description='Test';
        
        //Since we can't read the members of a workspace from apex
        //This test covers the "fail" part of the save, as there aren't enough permissions for the test user to actually publish in that workspace.
        try {
            ctr.saveAndNew();
        } catch (Exception e) {
            
        }
    }
}