public with sharing class CampaignMemberResponseScriptController {

public Id campaignMemberId {get;set;}

	public String CMName {get;set;}
	public String CMCompany {get;set;}
	public String CMEmail {get;set;}
	public String CMPhone {get;set;}
	
	public Boolean answer4 {get;set;} 
	public Boolean answer5 {get;set;} 
	public Boolean answer6 {get;set;} 
	public Boolean answer7 {get;set;} 
	public String answer8 {get;set;} 

	public String q4 {get;set;}
	public String q5 {get;set;}		
	public String q6 {get;set;}
	public String q7 {get;set;}
	public String q8 {get;set;}	

	public CampaignMemberResponseScriptController() {

	}

	public PageReference onLoad() {

		campaignMemberId = getParam('id'); 
		try {			
			// copying over info since CampaignMember object does not seem to be exposed to Sites
			CampaignMember c = [Select Id,
				Contact.Name, Contact.Account.Name, Contact.Email, Contact.Phone, 
				Campaign.Question_Text_4__c, Campaign.Question_Text_5__c, Campaign.Question_Text_6__c, 
				Campaign.Question_Text_7__c, Campaign.Question_Text_8__c
				FROM CampaignMember Where id=:campaignMemberId LIMIT 1];
				
			CMName = c.Contact.Name;
			CMCompany = c.Contact.Account.Name;
			CMEmail = c.Contact.Email;
			CMPhone = c.Contact.Phone;
			
			q4 = c.Campaign.Question_Text_4__c;
			q5 = c.Campaign.Question_Text_5__c;
			q6 = c.Campaign.Question_Text_6__c;
			q7 = c.Campaign.Question_Text_7__c;
			q8 = c.Campaign.Question_Text_8__c; 
		
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
		
		cm.Consultation_Completed__c = True;
		cm.Answer_Text_4__c = answer4;
		cm.Answer_Text_5__c = answer5;
		cm.Answer_Text_6__c = answer6;
		cm.Answer_Text_7__c = answer7;
		cm.Answer_Text_8__c = answer8;
		
		update cm;
		
		PageReference pageRef = Page.CampaignMemberThanksScript;
		pageRef.setRedirect(true);
		
		return pageRef;
	}

}