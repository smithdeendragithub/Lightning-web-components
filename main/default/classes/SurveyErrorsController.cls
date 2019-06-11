public with sharing class SurveyErrorsController{

	public List<Integration_Error__c> errors {get;set;}
	
	private String surveyIdPrefix = Survey__c.sobjectType.getDescribe().getKeyPrefix() + '%';

	public SurveyErrorsController(){
		getData();
	}
	
	private void getData(){
		errors = new List<Integration_Error__c>();
		for(Integration_Error__c error : [select Id, Name, ObjectID__c, Info__c, Message__c, RelatedID__c, CreatedDate from Integration_Error__c where ObjectID__c like :surveyIdPrefix limit 1000]){
    		errors.add(error);
    	}
	}
	
	public PageReference resendSurveys(){
		CustomerSurveyUtils.resendFailedSurveys(errors);
		getData();
		return null;
	}
	
	public Id errorID {get; set;}
	public PageReference resendSingle(){
		Integration_Error__c oneToSend = null;
		for(Integration_Error__c e : errors){
			if(e.Id == errorID){
				oneToSend = e;
				break;
			}
		}
		if(oneToSend != null)
		CustomerSurveyUtils.resendFailedSurveys(new List<Integration_Error__c>{oneToSend});
		getData();
		return null;
	}
}