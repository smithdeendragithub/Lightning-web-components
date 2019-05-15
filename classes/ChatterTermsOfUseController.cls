public with sharing class ChatterTermsOfUseController{
	
	public Boolean userMustAgreeToTermsOfUse { get{ return !SecurityUtils.currentUserHasAgreedToChatterTerms(); } }
	public Boolean redirectMode {get; private set; }
	
	public ChatterTermsOfUseController(){
		redirectMode = ApexPages.currentPage().getParameters().get('redirect') == 'true';
	}
	
	public PageReference Agree(){
		User u = [select Id from User where Id =: UserInfo.getUserId()];
		u.Chatter_Terms_Last_Accepted__c = DateTime.now();
		new SecurityBypassProcessor().saveUser(u);
		
		return redirectMode ? new pagereference('/home/home.jsp') : null;
	}
	
	private without sharing class SecurityBypassProcessor{
		public void saveUser(User u){
			Database.Update(u, false);
		}
	}
}