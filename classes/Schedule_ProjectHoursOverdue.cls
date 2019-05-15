public without sharing class Schedule_ProjectHoursOverdue implements Schedulable {
	public void execute(SchedulableContext sc) {
		alertUsersWithoutWeeklyHoursSet();
	}
	
	public static void alertUsersWithoutWeeklyHoursSet(){
		Set<Id> userRoleIDs = new Set<Id>();
		for(User u : [select UserRoleId from User where Project_Hours_Manager__c = true and IsActive = true])
			userRoleIDs.add(u.UserRoleId);
		
		Boolean queryMore = false;
		do{
			queryMore = false;
			for(UserRole u : [select Id from UserRole where ParentRoleId != null and ParentRoleId in: userRoleIDs and Id not in: userRoleIDs]){
				userRoleIDs.add(u.Id);
				queryMore = true;
			}
		}while(queryMore);
		
		List<User> userList = [select Id, Email from User where UserRoleId in: userRoleIDs and IsActive = true];
		
		Date last4WeekStart = getMonday(Date.today()).addDays(-28);
		Map<Id, Map<Date, Integer>> hoursByWeek = new Map<Id, Map<Date, Integer>>();
		for(AggregateResult ag : [select Resource__r.Resource_User__c UserID, Resource_Week__c ResourceWeek, SUM(Actual_Hours__c) Hours from Project_Resource_Hours__c
									where Resource__r.Resource_User__c in: userList
									and Resource_Week__c >= :last4WeekStart and Resource_Week__c < :last4WeekStart.addDays(28)
									and Actual_Hours__c != null
									group by Resource__r.Resource_User__c, Resource_Week__c]){
			Id userID = string.valueOf(ag.get('UserID'));
			Map<Date, Integer> m = hoursByWeek.get(userID) != null ? hoursByWeek.get(userID) : new Map<Date, Integer>();
			m.put(Date.valueOf(ag.get('ResourceWeek')), Integer.valueOf(ag.get('Hours')));
			hoursByWeek.put(userID, m);
		}
		
		Map<Id, Messaging.Singleemailmessage> emails = new Map<Id, Messaging.Singleemailmessage>();
		for(User u : userList){
			Map<Date, Integer> m = hoursByWeek.get(u.Id);
			
			List<String> missingWeeks = new List<String>();
			for(Integer i=0; i<4; i++){
				Date d = last4WeekStart.addDays(i*7);
				if((m == null) || (m.get(d) == null) || (m.get(d) < 40))
					missingWeeks.add(d.format());
			}
			
			if(missingWeeks.size() > 0){
				emails.put(u.Id, ApexUtils.createEmailMessage(u.Id
															,null
															,'Salesforce project hours required for last week'
															,'You have not finished setting your project hours in Salesforce for the weeks of: ' + String.join(missingWeeks, ', ')
															+ '. Please navigate to ' + System.Url.getSalesforceBaseUrl().toExternalForm() + '/apex/Hours to complete your hours.'
															,false
															,null));
			}
		}
		
		if(emails.size() > 0)
			ApexUtils.sendEmails(emails.values());
	}
	
	private static Date getMonday(Date d){
		while(Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('EEEE') != 'Monday'){
			d = d.addDays(-1);
		}
		return d;
	}
}