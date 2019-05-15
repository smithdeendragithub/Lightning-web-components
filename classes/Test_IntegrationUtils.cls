@isTest
public with sharing class Test_IntegrationUtils extends TestUtils.TestClass {
	
    class SuperException extends Exception {}
	
	static testMethod void testUtils(){
		
		insert new Email_Lists__c(Name='testEmailList', Type__c='IntegrationError', Email__c='email@email.com');
		
		Test.startTest();
		
		System.debug(IntegrationUtils.CustomerDetailIntegrationFieldSet);
		
		try{
			throw new SuperException('Testing exception handling');
		}
		catch(Exception e){
			IntegrationUtils.emailIntegrationException(e, 'email@email.com', 'Something blowed up');
		}
		
		System.debug(new IntegrationUtils().getTestClass());
	}
	
	static testMethod void testIntegrationErrors(){
		Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		Service_Location__c sLoc = testData.serviceLocation;
		Contact c = testData.parentAccountContact;
		Customer_Detail__c cd = testData.customerDetail;
		
		Customer_Contact__c cc = new Customer_Contact__c(Contact__c = c.Id, Customer_Detail__c = cd.Id, Contact_Type__c = 'Big Jerk');
		insert cc;
		
		Opportunity_Location__c oppLoc = testData.location;
		
		IntegrationUtils.createUpdateIntegrationErrors(new Set<Id>{a.Id, sLoc.Id, c.Id, cc.Id, cd.Id, oppLoc.Id}, 'ERROR ERROR ERROR', null);
		
		Test.startTest();
		
		IntegrationUtils.reintegrateObjects(new Set<String>{a.Id, sLoc.Id, c.Id, cc.Id, cd.Id, oppLoc.Id});
	}
	
	/*static testMethod void testSchedule_IntegrationErrorsRetry(){
		Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		
		IntegrationUtils.createUpdateIntegrationErrors(new Set<Id>{a.Id}, 'ERROR ERROR ERROR', null);
		
		Test.startTest();
		
		Schedule_IntegrationErrorsRetry.retryIntegrationErrors();
	}*/
	
	static testMethod void testReactivateAccounts(){
		Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		a.Customer_Detail__c = testData.customerDetail.Id;
		a.Type = 'Former Customer';
		AccountTriggers.DisableTrigger = true;
		update a;
		AccountTriggers.DisableTrigger = false;
		
		Service_Location__c sLoc = testData.serviceLocation;
		Contact c = testData.parentAccountContact;
		
		insert new Customer_Contact__c(Contact__c = c.Id, Customer_Detail__c = a.Customer_Detail__c, Contact_Type__c = 'Master of Disaster');
		
		Test.startTest();
		
		IntegrationUtils.reactivateAccounts(new Set<Id>{a.Id});
	}
	
	private static Integer subID = 0;
	public static List<integraWS.SFSubscriberView> getMockSubscriberResults(List<integraWS.SFSubscriberView> subs){
		for(integraWS.SFSubscriberView s : subs){
			s.SubscriberID = 9000 + subID++;
			if(s.Children != null && s.Children.SFSubscriberView != null)
				getMockSubscriberResults(s.Children.SFSubscriberView);
		}
		return subs;
	}
}