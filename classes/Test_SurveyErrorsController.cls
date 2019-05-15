@isTest
public class Test_SurveyErrorsController { 
	static testMethod void testSurveyErrors(){
		mocks testData = new Mocks();
		Survey__c s = new Survey__c();
		s.Account__c = testData.parentAccount.Id;
		s.Survey_Name__c = 'Test Name';
		insert s;

		Integration_Error__c e = new Integration_Error__c();
		e.ObjectID__c = s.Id;
		insert e;

		test.startTest();
		SurveyErrorsController sec = new SurveyErrorsController();
		sec.resendSurveys();
		sec.errorID = e.Id;
		sec.resendSingle();
		test.stopTest();
	}
}