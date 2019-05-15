public class SolutionApprovalUtils implements TestUtils.ITestableClass{

	private static Map<Id,DiscountAuthorityLevels__c> approvalLevels = null;

	public static DiscountAuthorityLevels__c getApprovalLevel(Id UserId) {
        //load property with user instance
		if(approvalLevels == null) approvalLevels = new Map<Id,DiscountAuthorityLevels__c>();
		if(!approvalLevels.containsKey(UserId)){
			String userlvl = string.valueOf([SELECT Discount_Level_Authority__c FROM User WHERE Id =: UserId].Discount_Level_Authority__c);
			approvalLevels.put(UserId,!String.IsEmpty(userlvl)? DiscountAuthorityLevels__c.getInstance(userlvl) : new DiscountAuthorityLevels__c(Allowed_Level_Percentage__c=100,IsApprovalLevel__c=false,Name='Sales Rep'));
		}
        return approvalLevels.get(UserId);
    }

	public static void ApproveSoluitonFromOLIs(List<OLI__c> olis){
		//need to find one's that need updating so can set approver/date on opportunityLocationConfiguration
		Set<Id> olc = new Set<Id>();
		for(OLI__c oli : olis){
			olc.add(oli.OpportunityLocationConfiguration__c);
			oli.Approved__c = true;
			oli.Off_Footprint_Approved__c = oli.Off_Footprint__c && true;
		}
		
		update olis;
		
		List<OpportunityLocationConfiguration__c> listOLCs =  new List<OpportunityLocationConfiguration__c>();
		for(OpportunityLocationConfiguration__c oppLC : [Select Approval_Date__c, Approver__c From  OpportunityLocationConfiguration__c  Where Id In : olc]){
			oppLC.Approval_Date__c = System.today().format();
			oppLC.Approver__c = UserInfo.getUserId();
			listOLCs.add(oppLC);
		}
		
		update listOLCs;
	}

	public static void RequestApprovals(Id oppId){
		Opportunity opp = [select Id, Owner.Sales_Channel__c, Owner.ManagerId from Opportunity where Id = :oppId];
		Id sendToId = opp.Owner.Sales_Channel__c == 'Indirect Sales'? GetIndirectSalesManagerId():opp.Owner.ManagerId;
		Messaging.SingleEmailMessage email = ApexUtils.createTemplatedEmailMessage(sendToId, GetApprovalRequestTemplateId(), oppId);
		ApexUtils.sendEmails(new List<Messaging.SingleEmailMessage>{email});
	}

	private static Id IndirectSalesManagerId = null;
	public static Id GetIndirectSalesManagerId(){
		if(IndirectSalesManagerId == null){
			string ntid = CustomSettingUtils.getSingleProcessConfigurationValue('ApprovalProcess','Indirect',false);
			IndirectSalesManagerId = [select Id from User where NTID__c = :ntid limit 1].Id;
		}
		return IndirectSalesManagerId;
	}

	private static Id ApprovalRequestTemplateId = null;
	public static Id GetApprovalRequestTemplateId(){
		if(ApprovalRequestTemplateId == null){
			ApprovalRequestTemplateId = [Select Id from EmailTemplate where DeveloperName = 'Solution_Approval_Request' limit 1].Id;
		}
		return ApprovalRequestTemplateId;
	}

	private static Decimal SMCompetitiveBuildingDiscount = null;
	public static Decimal GetSMCompetitiveBuildingDiscount(){
		if(SMCompetitiveBuildingDiscount == null){
			string decimalValue = CustomSettingUtils.getSingleProcessConfigurationValue('CompetitiveBuildingDiscount', 'Discount', false);
			SMCompetitiveBuildingDiscount = string.isEmpty(decimalValue)? 0.0d : decimal.ValueOf(decimalValue);
		}
		return SMCompetitiveBuildingDiscount;
	}

	public TestUtils.TestClass getTestClass(){ return new Test_SolutionApprovalUtils(); }
}