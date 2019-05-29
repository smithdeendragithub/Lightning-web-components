public without sharing class Order_WorkstepIssuesController {
	@AuraEnabled
    public List<WorkStepIssue> wsi  {get; set;}
    public Order__c ord {get; set;}
	
	public class WorkStepIssue{

		@AuraEnabled public Id Id {get;Set;}
		@AuraEnabled public String Name {get;Set;}
		@AuraEnabled public String Status {get;Set;}
		@AuraEnabled public Datetime ExpectedFollowUpDate {get;Set;}
		@AuraEnabled public String Reason {get;Set;}
		@AuraEnabled public Datetime EstimatedResolution {get;Set;}
		@AuraEnabled public String WorkstepName {get;Set;}
		@AuraEnabled public Id WorkStepId {get;Set;}
		@AuraEnabled public String SubOrderName {Get;Set;}
		@AuraEnabled public String OrderName {get;Set;}
		@AuraEnabled public Id SubOrderId {get;Set;}
		@AuraEnabled public Id OrderId {Get;Set;}
		@AuraEnabled public String OwnerName {get;Set;}
		@AuraEnabled public String OwnerType {get;Set;}
		@AuraEnabled public Id OwnerId {Get;Set;}
		public WorkStepIssue(Workstep_Issue__c w){
			this.Id = w.id;
			this.Name = w.Name;
			this.Status = w.Status__c;
			this.ExpectedFollowUpDate = w.Expected_Follow_Up_Date__c;
			this.Reason = w.Reason__c;
			this.EstimatedResolution = w.Estimated_Resolution__c;
			this.WorkstepName = w.Workstep__r.Name;
			this.WorkStepId = w.Workstep__r.Id;
			this.SubOrderName = w.Workstep__r.Sub_Order__r.Name;
			this.OrderName = w.Workstep__r.Sub_Order__r.Order__r.Name;
			this.SubOrderId = w.Workstep__r.Sub_Order__c;
			this.OrderId = w.Workstep__r.Sub_Order__r.Order__c;
			this.OwnerName = w.Owner.Name;
			this.OwnerType = w.Owner.Type;
			this.OwnerId = w.Owner.Id;
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
	@AuraEnabled(cacheable=true)
	public static List<Workstep__c> deleteMethod(String orderID){
		String whereClause = CustomSettingUtils.getSingleProcessConfigurationValue('Order_WorkstepIssuesWhereClause', 'User', false);
		Set<Id> userIDs = new Map<Id, User>((List<User>)Database.query('select Id from User' + (string.isEmpty(whereClause) ? '' : (' where ' + whereClause)))).keyset();
		
		Set<Id> wsIDs = new Set<Id>();

		for(Workstep__c ws : [select Id from Workstep__c where Order__c =: orderId]) wsIDs.add(ws.Id);
			List<WorkStepIssue> wsis = new List<WorkStepIssue>();
		List<Workstep__c> retVal = [select Id,Name from Workstep__c where Order__c =: orderID];
		system.debug('retVal=> '+retVal);
		return retVal;
	}
}