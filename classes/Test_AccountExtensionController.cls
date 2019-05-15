@isTest
public with sharing class Test_AccountExtensionController extends TestUtils.TestClass {
	
	static testMethod void testController(){
        Mocks testData = new Mocks();
    	Account a = testData.parentAccount;
		
		AccountExtensionController aec = setupController(a);
		aec.addCustomMessage(true, 'error');
		aec.addCustomMessage(false, 'info');
		aec.reactivateAccount();
		//aec.createLocationAndReactivateAccount();
		System.debug(aec.getTestClass() != null);
	}
	
	static testMethod void testGenerateDetails(){
        Mocks testData = new Mocks();
    	Account a = testData.parentAccount;
		
		AccountExtensionController aec = setupController(a);
		
    	aec.generateDetails();
    	a = [select Id, Customer_Detail__c from Account where Id =: a.Id];
    	system.assertNotEquals(a.Customer_Detail__c, null, 'Customer detail failed to generate');
	}
	
 	static testMethod void testCreateNonBillableParent() {
        Mocks testData = new Mocks();
    	Account a = testData.parentAccount;
		
    	Customer_Detail__c detail = new Customer_Detail__c(ICC_Subscriber_ID__c = '-9999'
															,Customer_Main_Address__c = testData.loc.Id
															,Service_Address__c = testData.loc.Id);
    	insert detail;
		
		a.Customer_Detail__c = detail.Id;
		update a;
		
		AccountExtensionController aec = setupController(a);
    	aec.createNonBillableParent();
    }
	
 	static testMethod void testCreateNonBillableParentAndLocation() {
        Mocks testData = new Mocks();
    	Account a = testData.parentAccount;
		
    	Customer_Detail__c detail = new Customer_Detail__c(ICC_Subscriber_ID__c = '-9999'
															,Customer_Main_Address__c = testData.loc.Id
															,Service_Address__c = testData.loc.Id);
    	insert detail;
		
		a.Customer_Detail__c = detail.Id;
		update a;
		
		AccountExtensionController aec = setupController(a);
		
		PageReference pageReference = ApexPages.currentPage();
        pageReference.getParameters().put('streetNumber', '1234');
        pageReference.getParameters().put('street', 'fake');
        pageReference.getParameters().put('suite', '1');
        pageReference.getParameters().put('city', 'Coolsville');
        pageReference.getParameters().put('country','US');
        pageReference.getParameters().put('state', 'OR');
        pageReference.getParameters().put('postalCode', '54321');
        pageReference.getParameters().put('latitude', '54');
        pageReference.getParameters().put('longitude', '-111');
    	aec.createNonBillableParentAndLocation();
    }
	
 	/*static testMethod void testCreateHierarchy() {
        Mocks testData = new Mocks();
    	Account a = testData.parentAccount;
		
		AccountExtensionController aec = setupController(a);
    	aec.CreateHierarchy();
		System.assert(ApexPages.getMessages().size() == 1, 'CreateHierarchy succeeded in expected error state: "No contact"');
		
		Contact c = testData.parentAccountContact;
		c.Default_Responsible_Party__c = true;
		update c;
		
    	aec.CreateHierarchy();
		System.assert(ApexPages.getMessages().size() == 2, 'CreateHierarchy succeeded in expected error state: "No service loc"');
		
		System.debug(testData.serviceLocation);
		
    	aec.CreateHierarchy();
		
		aec.ValidateAddressesAndRedirectToOppIntegrationPage();
		aec.VerifyContactsAndRedirectToOppGen();
    }*/
	
 	static testMethod void testAccountTeam() {
        Mocks testData = new Mocks();
    	Account a = testData.parentAccount;
		
		AccountExtensionController aec = setupController(a);
		//aec.addDefaultAccountTeamMembers();
		
		aec.newTeamMember.UserId = testData.user.Id;
		aec.addAccountTeamMember();
		
		Integer errorCount = aec.customErrorMessages.size();
		System.assert(errorCount > 0, 'Account team member create succeeded without team member role or share settings selected');
		
		aec.newTeamMember.TeamMemberRole = ICCWrapper.roleAccountConsultant;
		aec.newTeamMemberShare.AccountAccessLevel = 'Read';
		aec.newTeamMemberShare.OpportunityAccessLevel = 'Read';
		aec.addAccountTeamMember();
		System.assert(aec.customErrorMessages.size() == errorCount, 'Account team member create failed');
		
		AccountTeamMember atm = [select Id from AccountTeamMember where AccountId =: a.Id and UserId =: testData.user.Id limit 1];
        ApexPages.currentPage().getParameters().put('atmIDs', atm.Id);
		aec.updateAccountSharing();
		aec.removeAccountTeamMembers();
		System.assert([select Id from AccountTeamMember where Id =: atm.Id].size() == 0, 'Account team member delete failed');
    }
	
	private static AccountExtensionController setupController(Account a){
    	
        PageReference pageReference = Page.AccountExtensionController;
        Test.setCurrentPage(pageReference);
        
		Apexpages.StandardController sc = new Apexpages.StandardController(a);
    	AccountExtensionController aec = new AccountExtensionController(sc);
		
    	Test.startTest();
		
		return aec;
	}
}