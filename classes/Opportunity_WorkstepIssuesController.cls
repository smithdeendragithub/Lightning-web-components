public with sharing class Opportunity_WorkstepIssuesController {
	
    public List<Order_WorkstepIssuesController.WorkStepIssue> wsi  {get; set;}
    public Opportunity opp {get; set;}
	
    public Opportunity_WorkstepIssuesController(ApexPages.StandardController controller) {
    	opp = (Opportunity)controller.getRecord();
		List<Order__c> ords = [select Id from Order__c where Opportunity__c =: opp.Id];
    	wsi = ords.size() > 0 ? Order_WorkstepIssuesController.getWorkstepIssuesByOrderID(ords[0].Id) : new List<Order_WorkstepIssuesController.WorkStepIssue>();
    }
}