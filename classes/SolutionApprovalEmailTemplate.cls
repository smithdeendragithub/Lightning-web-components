public class SolutionApprovalEmailTemplate {
	
	public string OpportunityId {get;set;}
	public List<ApprovalView> getApprovalViews(){
		system.debug('oppId: ' + OpportunityId);
		Map<Id, Opportunity_Location__c> oppLocs = new Map<Id,Opportunity_Location__c>([SELECT Id, Service_Location__r.Location__r.Building__r.Market_Area_Name__c, Service_Location__r.Location__r.Building__r.Id, Service_Location__r.Location__r.Building__r.Name FROM Opportunity_Location__c where Opportunity__c = :OpportunityId]);
		Map<Id, OpportunityLocationConfiguration__c> sols = new Map<Id,OpportunityLocationConfiguration__c>([SELECT Id, Name, Term__c, Opportunity_Location__c, (SELECT Approval_Status__c, Approved__c, Id, MRC_Total__c, MRCList__c, PP_Sales_Rate_Plan_Description__c, Qty__c FROM Opportunity_Line_Items__r where Approval_Status__c = 'Sales Management Approval Required') FROM OpportunityLocationConfiguration__c where Opportunity_Location__c in :oppLocs.keyset() and Active__c = true]);
		List<ApprovalView> views = new List<ApprovalView>();
		for(OpportunityLocationConfiguration__c sol : sols.values()){
			if(sol.Opportunity_Line_Items__r.size() > 0){
				Opportunity_Location__c loc = oppLocs.get(sol.Opportunity_Location__c);
				views.add(new ApprovalView(loc,sol));
			}
		}
		return views;
	}
	public string getSize(){
		return OpportunityId;
	}

	public SolutionApprovalEmailTemplate(){
	}

	public class ApprovalView{
		public Id SolutionId {get;set;}
		public string SolutionName {get;set;}
		public string SolutionTerm {get;set;}
		public Id BuildingId {get;set;}
		public string BuildingName {get;set;}
		public string MarketName {get;set;}
		public List<OLI__c> Olis {get;set;}

		public ApprovalView(){}
		public ApprovalView(Opportunity_Location__c loc, OpportunityLocationConfiguration__c sol){
			SolutionId = sol.Id;
			SolutionName = sol.Name;
			SolutionTerm = sol.Term__c;
			BuildingId = loc.Service_Location__r.Location__r.Building__r.Id;
			BuildingName = loc.Service_Location__r.Location__r.Building__r.Name;
			MarketName = loc.Service_Location__r.Location__r.Building__r.Market_Area_Name__c;
			Olis = sol.Opportunity_Line_Items__r;
		}
	}

}