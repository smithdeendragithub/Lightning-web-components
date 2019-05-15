@isTest
public with sharing class Test_CustomSettingUtils extends TestUtils.TestClass {
	
	static testMethod void testUtils(){
		String x = CustomSettingUtils.getPrimaryContactByState('WA');
		x = CustomSettingUtils.getICertBusinessUnitFromOppSalesChannel('TestSalesChannel');
		x = CustomSettingUtils.getICertSalesChannelFromOppSalesChannel('TestSalesChannel');
		//x = CustomSettingUtils.GetDocumentDownLoadURL('docID', 'session', 'url');
		
		Boolean b = CustomSettingUtils.getOverrideSettingValue('ovr');
		b = CustomSettingUtils.currentUserHasCustomPermission('do stuff');
		
		system.debug(new CustomSettingUtils().getTestClass());
	}
	
	static testMethod void testEmailLists(){
		system.assert(CustomSettingUtils.BillingChangeNotificationEmailAddresses.size() == 0, 'Existing billing change notification emails found');
		system.assert(CustomSettingUtils.IntegrationErrorEmailAddresses.size() == 0, 'Existing integration error emails found');
		system.assert(CustomSettingUtils.TaskInternalKickoffCall.size() == 0, 'Existing task internal kickoff emails found');
		
		insert new Email_Lists__c(Name='email', Type__c='IntegrationError', Email__c='test@test.com');
		system.assert(CustomSettingUtils.IntegrationErrorEmailAddresses.size() > 0, 'No integration error emails found');
	}
	
	static testMethod void testIntegraServiceSettings(){
		String x = CustomSettingUtils.IntegraDocumentDownloadURL;
		x = CustomSettingUtils.IntegraWSEndpoint;
		x = CustomSettingUtils.SFDCCallbackEndpoint;
		Integer i = CustomSettingUtils.WSTimeout;
	}
	
	static testMethod void testProcessConfigurations(){
		Mocks testData = new Mocks();
		User u = testData.user;
		
		insert new List<Process_Configuration__c>{new Process_Configuration__c(Name='ProcessConfig1', Process__c='process', Key__c='key', Value__c='val')
												,new Process_Configuration__c(Name='ProcessConfig2', Process__c='InternalKickoffSalesChannelManager', Key__c='Enterprise', Value__c=u.NTID__c)
												,new Process_Configuration__c(Name='ProcessConfig3', Process__c='RegionAE', Key__c='WA', Value__c=u.NTID__c)};
		
		Test.startTest();
		
		System.assert(CustomSettingUtils.getiCertProcessConfigurations('process').size() > 0, 'No process configuration found');
		System.assert(CustomSettingUtils.getProcessConfigurationValues('process', 'key').size() > 0, 'No process configuration found');
		
		User x = CustomSettingUtils.getInternalKickoffSalesChannelManager('Enterprise');
		x = CustomSettingUtils.getRegionalAE('WA');
	}
}