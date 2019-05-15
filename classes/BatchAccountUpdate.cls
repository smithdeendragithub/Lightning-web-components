global class BatchAccountUpdate implements  Database.Batchable<sObject> {

	global final string query;

	global BatchAccountUpdate (String q) {
	   query = q;
	}

	global Database.QueryLocator start(Database.BatchableContext BC){
	   return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){
	  
	  	Database.Saveresult[] result = database.update(scope, false);
	}

	global void finish(Database.BatchableContext BC){
		
	 AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
	   TotalJobItems, CreatedBy.Email
	   from AsyncApexJob where Id =:BC.getJobId()];
	
	  	ApexUtils.sendEmails(new List<Messaging.SingleEmailMessage>{ApexUtils.createEmailMessage(new String[] {a.CreatedBy.Email}, null, 'Account field update workflow hytration ' + a.Status, 'The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.', false, null)});
	}
}