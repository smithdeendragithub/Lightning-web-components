@isTest
global class Test_TeamSellRequest {
    public static testMethod void testTeamSellRequestModified() {
        Mocks testData = new Mocks();
        User u = testData.user;
        AccountReference__c accRef = new AccountReference__c(Account__c=testData.parentAccount.Id);
        insert accRef;
        
    	Team_Sell_Request__c tsr = new Team_Sell_Request__c();
        tsr.Account_Name__c = accRef.Id;
        tsr.Allstream_Relationship__c = 'test';
        tsr.Partner_Relationship__c = 'test';
        tsr.Approval_Request_Notes__c = 'test note';
        tsr.Opportunity_Discovery_Party__c = 'Partner';
        tsr.Partner_Name__c = 'Test Engineer';
        tsr.Projected_New_Revenue__c = 100;
        tsr.Proposed_services__c = 'Access Service';
        tsr.Requestor__c = u.Id;
        tsr.Status__c = 'New';
        insert tsr;
        
        test.startTest();
        tsr.Status__c = 'Approved';
        update tsr;
        test.stopTest();
    }
    
    public static testMethod void testTeamSellRequestControllerExtension(){
        Mocks testData = new Mocks();
        User u = testData.user;
        AccountReference__c accRef = new AccountReference__c(Account__c=testData.parentAccount.Id);
        insert accRef;
        
    	Team_Sell_Request__c tsr = new Team_Sell_Request__c();
        tsr.Account_Name__c = accRef.Id;
        tsr.Allstream_Relationship__c = 'test';
        tsr.Partner_Relationship__c = 'test';
        tsr.Approval_Request_Notes__c = 'test note';
        tsr.Opportunity_Discovery_Party__c = 'Partner';
        tsr.Partner_Name__c = 'Test Engineer';
        tsr.Projected_New_Revenue__c = 100;
        tsr.Proposed_services__c = 'Access Service';
        tsr.Status__c = 'New';
        insert tsr;
        
        PageReference pageRef = Page.TeamSellRequestEdit;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('Id', String.valueOf(tsr.Id));
		ApexPages.StandardController sc = new ApexPages.StandardController(tsr);
		TeamSellRequestControllerExtension testAccPlan = new TeamSellRequestControllerExtension(sc);
    }
    
}