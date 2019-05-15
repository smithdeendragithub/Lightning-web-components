public without sharing class Schedule_IntegrationErrorsRetry implements Schedulable {
	public void execute(SchedulableContext sc) {
		retryIntegrationErrors();
	}
	
	public static void retryIntegrationErrors(){
		Set<String> ids = new Set<String>();
		for(Integration_Error__c error : [select ObjectID__c from Integration_Error__c limit 2000])
			ids.add(error.ObjectID__c);
		
		if(ids.size() > 0)
			IntegrationUtils.reintegrateObjects(ids);
	}
}