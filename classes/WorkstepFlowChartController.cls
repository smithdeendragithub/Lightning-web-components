public with sharing class WorkstepFlowChartController implements TestUtils.ITestableClass{
	
	public String jsonPCWorkstepList { get; set; }
	public String jsonPCDependentMap { get; set; }
	public String jsonReversedWorkstepLevelMap { get; set; }
	public Integer wsCount { get; set; }

	public WorkstepFlowChartController(){
		Id recordID = (Id)ApexPages.currentPage().getParameters().get('id');
		
		String recordName = SchemaUtils.GetSObjectNameByID(recordID);
		Set<Id> wsIDs = null;
		if(recordName == 'Workstep__c') wsIDs = new Set<Id>{recordID};
		else if(recordName == 'Order__c' || recordName == 'Sub_Order__c') wsIDs = (new Map<Id, Workstep__c>([select Id from Workstep__c where Order__c =: recordID or Sub_Order__c =: recordID])).keyset();	//Just get one to return the whole chain
		
		WorkstepUtils.PredecessorChain pc = WorkstepUtils.getPredecessorChain(wsIDs);	
		jsonPCWorkstepList = JSON.serialize(new Map<Id, Workstep__c>([select Id, Name, Start_Date__c, End_Date__c, Status__c, Duration__c, On_time_Late_Workstep__c from Workstep__c where Id in: pc.WorkstepList.keyset()]), true);	
		jsonPCDependentMap = JSON.serialize(pc.DependentMap, true);
		jsonReversedWorkstepLevelMap = JSON.serialize(pc.GetReversedWorkstepLevelMap(), true);
		wsCount = pc.WorkstepList.size();		
		/*System.debug(pc);
		System.debug(jsonPCWorkstepList);
		System.debug(jsonPCDependentMap);
		System.debug(jsonReversedWorkstepLevelMap);*/
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_WorkstepFlowChart(); }
}