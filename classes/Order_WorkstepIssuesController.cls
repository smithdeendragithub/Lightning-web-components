public without sharing class Order_WorkstepIssuesController {
	
    public List<WorkStepIssue> wsi  {get; set;}
    public Order__c ord {get; set;}
	
	public class WorkStepIssue{
		public Id Id {get;Set;}
		public String Name {get;Set;}
		public String Status {get;Set;}
		public Datetime ExpectedFollowUpDate {get;Set;}
		public String Reason {get;Set;}
		public Datetime EstimatedResolution {get;Set;}
		public String WorkstepName {get;Set;}
		public Id WorkStepId {get;Set;}
		public String SubOrderName {Get;Set;}
		public String OrderName {get;Set;}
		public Id SubOrderId {get;Set;}
		public Id OrderId {Get;Set;}
		public String OwnerName {get;Set;}
		public String OwnerType {get;Set;}
		public Id OwnerId {Get;Set;}
		public WorkStepIssue(Workstep_Issue__c w){
			Id = w.id;
			Name = w.Name;
			Status = w.Status__c;
			ExpectedFollowUpDate = w.Expected_Follow_Up_Date__c;
			Reason = w.Reason__c;
			EstimatedResolution = w.Estimated_Resolution__c;
			WorkstepName = w.Workstep__r.Name;
			WorkStepId = w.Workstep__r.Id;
			SubOrderName = w.Workstep__r.Sub_Order__r.Name;
			OrderName = w.Workstep__r.Sub_Order__r.Order__r.Name;
			SubOrderId = w.Workstep__r.Sub_Order__c;
			OrderId = w.Workstep__r.Sub_Order__r.Order__c;
			OwnerName = w.Owner.Name;
			OwnerType = w.Owner.Type;
			OwnerId = w.Owner.Id;
		}
	}
	

    public Order_WorkstepIssuesController(ApexPages.StandardController controller) {
    	ord = (Order__c)controller.getRecord();
    	wsi = getWorkstepIssuesByOrderID(ord.Id);        
    }
 	
    @AuraEnabled
	public static List<WorkStepIssue> getWorkstepIssuesByOrderID(Id orderID) {
		String whereClause = CustomSettingUtils.getSingleProcessConfigurationValue('Order_WorkstepIssuesWhereClause', 'User', false);
		
		Set<Id> userIDs = new Map<Id, User>((List<User>)Database.query('select Id from User' + (string.isEmpty(whereClause) ? '' : (' where ' + whereClause)))).keyset();
		
		Set<Id> wsIDs = new Set<Id>();
		for(Workstep__c ws : [select Id from Workstep__c where Order__c =: orderId]) wsIDs.add(ws.Id);
		List<WorkStepIssue> wsis = new List<WorkStepIssue>();
        for(Workstep_Issue__c w : [SELECT Id, Name, Status__c, Expected_Follow_Up_Date__c, Reason__c, Estimated_Resolution__c, 
										        Workstep__r.Name, Workstep__r.Id, Workstep__r.Sub_Order__r.Name, Workstep__r.Sub_Order__r.Order__r.Name, 
										        Workstep__r.Sub_Order__c, Workstep__r.Sub_Order__r.Order__c, Owner.Name, Owner.Type, Owner.Id        
										            FROM Workstep_Issue__c 
										            WHERE Workstep__c in: wsIDs and OwnerId in: userIDs
													//and Workstep__r.Sub_Order__r.Order__r.Opportunity_Status__c = 'Sales Working'
													and Status__c = 'Open'])
		{
			wsis.add(new WorkStepIssue(w));
		}
		
		return wsis;
    }
}