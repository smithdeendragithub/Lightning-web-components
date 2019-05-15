global class ACR_SchedulerClass implements Schedulable{

    global static String scheduleBatch() {
        return System.schedule('DOA Batch Job','0 0 0 ? * * *', new ACR_SchedulerClass());
    }

    global void execute(SchedulableContext sc) {  
		Id batchJobId = Database.executeBatch(new ACR_DOAProcessingBatch(), 200);
        
    }
}