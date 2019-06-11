public without sharing class Schedule_AccountScheduledTaskProcess implements Schedulable {
    public void execute(SchedulableContext sc) {
		//check and see if it's a holiday.  we aren't going to process on holidays
		if(!ApexUtils.isHoliday()){
        	processTasks();
		}
    }
	
	private static Map<String, Case> templateCasesMap;
	private static Map<String, Case> TemplateCasesByType{
		get{
			if(templateCasesMap == null){				
				templateCasesMap = new Map<String, Case>();
				String q = 'Select ' + SchemaUtils.RetrieveFullObjectFields(Case.sObjectType) + ', RecordType.DeveloperName From Case Where is_Template__c = true';
				for(Case c : (List<Case>)Database.query(q)){
					String activityName = c.RecordType.DeveloperName == 'Proactive_Review_Visit_Virtual' ? 'Account Review' : 'Contact';
					templateCasesMap.put(activityName, c);
				}
			}
			return templateCasesMap;
		}
		Set;
	}
		
	public static Case GetCaseForTemplate(Account_Scheduled_Task__c ast){
		Case c = new Case();
		//use previous because we should have updated this already.
		Case template = TemplateCasesByType.get(ast.Previous_Proactive_Activity__c);
		if(template != null) ApexUtils.deepCopyFields(c.getSobjectType(), template, c, null);
		c.Is_Template__c = false;
		return c;
	}
    
    public static void processTasks(){
		List<Case> newCases = new List<Case>();
		List<Case> casesToClose = new List<Case>();
		List<Account_Scheduled_Task__c> asts = [select Id, (Select Id, Status, Reason, IsClosed, Commit_Date__c from Cases__r ORDER BY CreatedDate DESC)
														//,Account__c, Account__r.Account_Sales_Channel__c, Account__r.MRR__c, Current_Activity_Required__c, Next_Run__c, Previous_Proactive_Activity__c
														,Account__c, Account__r.Customer_Detail__r.Care_Organization__c, Account__r.MRR__c, Current_Activity_Required__c, Next_Run__c, Previous_Proactive_Activity__c														
														,Occurrence_Frequency__c
													from Account_Scheduled_Task__c where Automation_Enabled__c = true and Disabled__c = false and Next_Run__c <= TODAY limit 10000];
		
		Map<Id, Id> actIdToACId = new Map<Id,Id>();
		for(Account_Scheduled_Task__c ast : asts){
			actIdToACId.put(ast.Account__c, null);
		}
		for(AccountTeamMember atm : [select UserId, AccountId from AccountTeamMember where AccountId in :actIdToACId.keyset() and TeamMemberRole = 'Account Consultant']){
			actIdToACId.put(atm.AccountId, atm.UserID);
		}
		//need these to have their workflows run before creating cases.
		List<Account_Scheduled_Task__c> actionableCaseTasks = new List<Account_Scheduled_Task__c>();
		Set<Id> actionableIds = new Set<Id>();
		for(Account_Scheduled_Task__c ast : asts){
			if(actIdToACId.get(ast.Account__c) != null){
				Boolean incomplete = false;
				if(ast.Cases__r != null && ast.Cases__r.size() > 0 && !ast.Cases__r[0].IsClosed && ast.Cases__r[0].Commit_Date__c <= Date.today()){
					Case c = ast.Cases__r[0];
					c.Status = 'Incomplete';
					casesToClose.add(c);
					incomplete = true;
				}
				
				ast.Last_Run__c = ast.Next_Run__c;//Date.today();
				ast.Previous_Proactive_Activity__c = ast.Current_Activity_Required__c;

                String careOrgName =  ast.Account__r.Customer_Detail__r.Care_Organization__c!=null?CustomerDetailUtils.getCareOrgById(ast.Account__r.Customer_Detail__r.Care_Organization__c).Name:null;
				AccountScheduledTaskUtils.updateASTFromABSandMRR(ast, careOrgName, ast.Account__r.MRR__c);
				//AccountScheduledTaskUtils.updateASTFromABSandMRR(ast, ast.Account__r.Account_Sales_Channel__c, ast.Account__r.MRR__c);				
				if(incomplete){
					string current = ast.Current_Activity_Required__c;
					ast.Current_Activity_Required__c = ast.Previous_Proactive_Activity__c;
					ast.Previous_Proactive_Activity__c = current;
				}
				actionableCaseTasks.add(ast);
				actionableIds.add(ast.Id);
			}
		}
		Database.SaveResult[] sResults = Database.update(actionableCaseTasks,false);
		actionableCaseTasks = [select Id
										,Account__c, Current_Activity_Required__c, Next_Run__c, Previous_Proactive_Activity__c
									from Account_Scheduled_Task__c where Id in :actionableIds];
		
		for(Account_Scheduled_Task__c ast : actionableCaseTasks){
			//create new case.
			Id di = actIdToACId.get(ast.Account__c);
			if(di == null) continue;
			Case c = GetCaseForTemplate(ast);
			c.OwnerId = actIdToACId.get(ast.Account__c);
			c.Commit_Date__c = ast.Next_Run__c;
			c.AccountId = ast.Account__c;
			c.Account_Scheduled_Task__c = ast.Id;
			newCases.add(c);
			
		}
		insert newCases;
		update casesToClose;
		string errMsg = '';
		for(integer i = 0; i < sResults.size(); ++i){
			Database.SaveResult sr = sResults[i];
			Account_Scheduled_Task__c ast = actionableCaseTasks[i];
			if(!sr.isSuccess()){
				errMsg += string.isEmpty(errMsg)? '' : '\n';
				errMsg += 'Error updating AST: ' + ast.Id + ' - Errors: ';
				for(Database.Error err : sr.getErrors()){
					errMsg += err.getStatusCode() + ': ' + err.getMessage();
				}
			}
		}
		if(!string.isEmpty(errMsg)){
			Messaging.SingleEmailMessage msg = ApexUtils.createEmailMessage(ApexUtils.ITAdminId, new List<String>(), 'Account Scheduled Task Process Exception', errMsg, false, '');
			ApexUtils.sendEmails(new List<Messaging.SingleEmailMessage>{msg});
		}
	}
	
	
}