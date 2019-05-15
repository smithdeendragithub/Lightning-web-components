public without sharing class ObjectPropertyController{

	public Boolean ResponsibleParty {get;Set;}
	public Boolean OrderID {get;Set;}
	public Boolean CollectionRep {get;Set;}
	public Boolean SignedBy {get;Set;}
	public Boolean OppName {get;Set;}
	public Boolean OppSFID {get;Set;}
	public Boolean AccountName {get;Set;}
	public Boolean AccountTeamMember {get;Set;}
	public String TeamMemberRole {get;Set;}
	public Id sObjectID {get;Set;}
		
	public String AccountNameDisplay{
		get{
			String output = '';
			try{
				Id AccountID = null;
				if(IsOrder(sObjectID)){
					Order__c ord = [select Opportunity__c from Order__c where Id = :sObjectID limit 1];
					AccountID = [select o.AccountId from Opportunity o where o.Id = :ord.Opportunity__c limit 1].AccountId;
				}
				else if(IsOpportunity(sObjectID)){
					AccountID = [select o.AccountId from Opportunity o where o.Id = :sObjectID limit 1].AccountId;
				}
				Account a = [Select Name from Account where Id = :AccountID limit 1];
				output = a.Name;
			}
			catch(Exception exp){
				output = '' + exp;
			}
			return output;
		}
	}
	public String OppNameDisplay{
		get{
			String output = '';
			try{
				if(IsOrder(sObjectID)){
					Order__c ord = [select Opportunity__c from Order__c where Id = :sObjectID limit 1];
					Opportunity o = [select Name from Opportunity where Id = :ord.Opportunity__c limit 1];
					output = o.Name;
				}
				else if(IsOpportunity(sObjectID)){
					Opportunity o = [select Name from Opportunity where Id = :sObjectID limit 1];
					output = o.Name;
				}
			}
			catch(Exception exp){
				output = '' + exp;
			}
			return output;
		}
	}
	public String OppSFIDDisplay{
		get{
			String output = '';
			try{
				if(IsOrder(sObjectID)){
					Order__c ord = [select Opportunity__c from Order__c where Id = :sObjectID limit 1];
					Opportunity o = [Select O.SF_Opportunity_ID__c from Opportunity O where O.Id = :ord.Opportunity__c limit 1];
					output = o.SF_Opportunity_ID__c;
				}
				else if(IsOpportunity(sObjectID)){
					Opportunity o = [Select O.SF_Opportunity_ID__c from Opportunity O where O.Id = :sObjectID limit 1];
					output = o.SF_Opportunity_ID__c;
				}
			}
			catch(Exception exp){
				output = '' + exp;
			}
			return output;
		}
	}
	public String CollectionRepDisplay
	{
		get{
			String output = '';
			try{
				User u = null;
				if(IsOrder(sObjectId)){
					Order__c ord = [select Opportunity__c from Order__c where Id = :sObjectID limit 1];
					u = getCollectionRepFromOpp(ord.Opportunity__c);
				}
				else if(IsOpportunity(sObjectID)){
					u = getCollectionRepFromOpp(sObjectID);
				}
				if(u != null)
					output = u.Name + ' : ' + u.Phone;
			}
			catch(Exception exp){
				output = '' + exp;	
			}
			return output;
		}
	}
	public String OrderIDDisplay{
		get{
			String output = '';
			try{
				if(IsOrder(sObjectID)){
					Order__c ord = [select Id, Opportunity__c from Order__c where Id = :sObjectID limit 1];
					output = ord.Id;
				}
				if(IsOpportunity(sObjectID)){
					Order__c o = getOrderFromOpp(sObjectID);
					output = o.Id;
				}
			}
			catch(Exception exp){
				output = '' + exp;	
			}
			return output;
		}
	}
	public String ResponsiblePartyDisplay{
		get{
			String output = '';
			try{
				Id AccountID = null;
				if(IsOrder(sObjectID)){
					Order__c ord = [select Opportunity__c from Order__c where Id = :sObjectID limit 1];
					AccountID = [select o.AccountId from Opportunity o where o.Id = :ord.Opportunity__c limit 1].AccountId;
				}
				if(IsOpportunity(sObjectID)){
					AccountID = [select o.AccountId from Opportunity o where o.Id = :sObjectID limit 1].AccountId;
				}
				output =  getResponsiblePartyFromAccountId(AccountID);
			}
			catch(Exception exp){
				output = '' + exp;	
			}
			return output;
		}
	}
	
	public String SignedByDisplay{
		get{
			String output = '';
			try{
				if(IsOrder(sObjectId)){
					Order__c ord = [select Opportunity__c from Order__c where Id = :sObjectID limit 1];
					Opportunity op = [select O.LOA_Signed_By__c, O.LOA_Signed_By__r.Name from Opportunity O where O.Id = :ord.Opportunity__c Limit 1][0];
					if(op.LOA_Signed_By__c != null)
						output = op.LOA_Signed_By__r.Name;
				}
				if(IsOpportunity(sObjectID)){
					Opportunity op = [select O.LOA_Signed_By__c, O.LOA_Signed_By__r.Name from Opportunity O where O.Id = :sObjectID Limit 1][0];
					if(op.LOA_Signed_By__c != null)
						output = op.LOA_Signed_By__r.Name;
				}
			}
			catch(Exception exp){
				output = '' + exp;	
			}
			return output;
		}
	}
	
	public String AccountTeamMemberDisplay{
		get{
			String output = '';
			if(IsAccount(sobjectId)){
				List<AccountTeamMember> atms = [select UserId from AccountTeamMember where AccountId = :sobjectId and TeamMemberRole = :TeamMemberRole];
				if(atms.size() > 0){
					AccountTeamMember atm = atms[0];
					User u = [select Name from User where Id = :atm.UserId];
					if(u != null)
						output = u.Name;
				}
			}
			return output;
		}
	}
	
	public ObjectPropertyController(){
	}
	
	private String getResponsiblePartyFromAccountId(Id AccountID){
		String res = '';
		String nl = '';
		List<Contact> cs = [select (Select Contact_Type__c from Customer_Contacts__r), c.Name, c.Default_Responsible_Party__c from Contact c where c.AccountId = :AccountID];
		for(Contact c : cs){
			if(c.Default_Responsible_Party__c){
				res += nl + c.Name;
				nl = '\n';
			}
			else{
				for(Customer_Contact__c cc : c.Customer_Contacts__r){
					if(cc.Contact_Type__c == 'Responsible Party'){
						res += nl + c.Name;
						nl = '\n';
					}
				}
			}
		}
		return res;
		
	}
		
	private Order__c getOrderFromOpp(Id oppId){
		Order__c o = [select o.Id from Order__c o where o.Opportunity__c = :oppId limit 1];
		return o;
	}
	private User getCollectionRepFromOpp(Id oppId){
		Order__c o = [select O.Credit_Check_Rep__r.Name, O.Credit_Check_Rep__r.Phone from Order__c O where O.opportunity__c = :oppId limit 1];
		return o.credit_check_rep__r;
	}
	
	private Boolean IsOpportunity(String objectId){
		return objectId.startsWith(Opportunity.SObjectType.getDescribe().getKeyPrefix());
	}
	
	private Boolean IsOrder(String objectId){
		return objectId.startsWith(Order__c.SObjectType.getDescribe().getKeyPrefix());
	}
	
	private Boolean IsCase(String objectId){
		return objectId.startsWith(Case.SObjectType.getDescribe().getKeyPrefix());
	}
	
	private Boolean IsAccount(String objectId){
		return objectId.startsWith(Account.SObjectType.getDescribe().getKeyPrefix());
	}
	public TestUtils.TestClass getTestClass(){ return new Test_ObjectPropertyController(); }
}