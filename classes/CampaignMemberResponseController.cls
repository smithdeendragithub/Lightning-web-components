public class CampaignMemberResponseController implements TestUtils.ITestableClass {
	
	public Id campaignMemberId {get;set;}

	public String CMName {get;set;}
	public String CMCompany {get;set;}
	public String CMEmail {get;set;}


	public String answer1 {get;set;} 
	public String answer2 {get;set;} 
	public String answer3 {get;set;} 

	
	public String q1 {get;set;}
	public String q2 {get;set;}
	public String q3 {get;set;}	
	
	
	public CampaignMemberResponseController() {

	}

	public PageReference onLoad() {

		try {			
			campaignMemberId = getParam('id');
			
			// copying over info since CampaignMember object does not seem to be exposed to Sites
			CampaignMember c = [Select Id,
				Contact.Name, Contact.Account.Name, Contact.Email,
				Campaign.Question_Text_1__c, Campaign.Question_Text_2__c, Campaign.Question_Text_3__c    
				FROM CampaignMember Where id=:campaignMemberId LIMIT 1];
				
			CMName = c.Contact.Name;
			CMCompany = c.Contact.Account.Name;
			CMEmail = c.Contact.Email;
			
			q1 = c.Campaign.Question_Text_1__c;
			q2 = c.Campaign.Question_Text_2__c;
			q3 = c.Campaign.Question_Text_3__c;
			
		}
		catch(Exception e) {			
			PageReference pageRef = Page.CampaignMemberThanks;
			pageRef.getParameters().put('status', 'error');
			return pageRef;
			
		}

		return null;
	}

	private String getParam(String paramName) {
		return Apexpages.currentPage().getParameters().get(paramName);
	}

	public PageReference UpdateMemberStatus() {
		
		CampaignMember cm = new CampaignMember(Id=campaignMemberId);
		cm.Status = 'Responded - Web';
		cm.Answer_Text_1__c = answer1;
		cm.Answer_Text_2__c = answer2;
		cm.Answer_Text_3__c = answer3;
		
		update cm;
		
		PageReference pageRef = Page.CampaignMemberThanks;
		pageRef.setRedirect(true);
		
		return pageRef;
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_CampaignMemberResponse(); }
}