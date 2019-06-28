public with sharing class HoursController implements TestUtils.ITestableClass {
	
	public List<User> users {get; set;}
	public Map<Id, List<Project_Resource__c>> resourcesByUserID {get; private set;}
	public Map<Id, Project__c> projects {get; private set;}
	public Map<Id, Project_Resource_Hours__c> projectResourceHours {get; private set;}
	public Integer year {get; set;}
	
	private Id getByUserID {get; set;}
	private set<String> getByNTIDs {get; set;}
	public Boolean includeTeam {get; set;}
	
	public Boolean hasPageAccess {get; set;}
	public Boolean readOnlyMode {get; set;}
	public Boolean isProjectManager {get; set;}
	public Boolean isTeamManager {get; set;}
	public Map<Id, String> projectLeads {get; set;}
	
    public List<SelectOption> userSelections {get; private set;}
    public List<String> currentUserSelections {get; set;}
    public List<SelectOption> projectSelections {get; private set;}
    public List<String> currentProjectSelections {get; set;}
    public Project_Resource__c dummyPR {get; set;}
	
	private final String PROJECTS_MINE_OPEN = 'Open projects I\'m on';
	private final String PROJECTS_MINE = 'All projects I\'m on';
	public List<SelectOption> projectViewOptions{
		get{ return new List<SelectOption>{ new SelectOption(PROJECTS_MINE_OPEN,PROJECTS_MINE_OPEN), new SelectOption(PROJECTS_MINE,PROJECTS_MINE)}; }
	}
	
	private final String PROJECTS_ALL = 'All projects';
	private final String PROJECTS_OPEN = 'All open projects';
	public List<SelectOption> projectSelectionOptions{
		get{
			List<SelectOption> l = new List<SelectOption>{new SelectOption(PROJECTS_ALL,PROJECTS_ALL), new SelectOption(PROJECTS_OPEN,PROJECTS_OPEN)};
			l.addAll(projectViewOptions);
			return l;
		}
	}
	public String selectedProjectOption {get; set;}
    
    public List<SelectOption> weekSelections {get; private set;}
    public Date currentWeek {get; set;}
    public String currentWeekStr {get; set;}
    
    private final Set<String> projectCompleteStatuses = new Set<String>{'On Hold', 'Cancelled', 'Backlog', 'Completed'};
	
	public HoursController(){
		hasPageAccess = SecurityUtils.checkObjectAccess(Project__c.getsObjectType(), true, false)
			&& SecurityUtils.checkObjectAccess(Project_Resource__c.getsObjectType(), false, false)
			&& SecurityUtils.checkObjectAccess(Project_Resource_Hours__c.getsObjectType(), false, false);
		if(hasPageAccess) {
			year = Date.today().year();
			dummyPR = new Project_Resource__c();
			selectedProjectOption = PROJECTS_MINE_OPEN;
			getWeeks();
			
			User u = [select Id
							,(select Id from ManagedUsers limit 1)
							,(select Id from Managers_Manager__r limit 1)
							,(select Id from Projects__r where Status__c not in :projectCompleteStatuses limit 1)
						from User where Id =: UserInfo.getUserId()];
			isTeamManager = (u.ManagedUsers != null && u.ManagedUsers.size() > 0) || (u.Managers_Manager__r != null && u.Managers_Manager__r.size() > 0);
			isProjectManager = (u.Projects__r != null && u.Projects__r.size() > 0);
			
	    	String ntidList = ApexPages.currentPage().getParameters().get('ntids');
	    	if(!string.isEmpty(ntidList))
	    		getByNTIDs = new Set<String>(ntidList.split(','));
	    	else
				getByUserID = UserInfo.getUserId();
			
			if(isTeamManager)
				includeTeam = ApexPages.currentPage().getParameters().get('includeTeam') == 'true';
			
			getUserResources();
		}
		else ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have access to set project hours. Please contact an administrator to correct your permission sets.'));
	}
	
	public Map<Id, Decimal> plannedHours {get; set;}
	public Map<Id, Decimal> actualHours {get; set;}
	public void getUserResources(){
		
		plannedHours = new Map<Id, Decimal>();
		actualHours = new Map<Id, Decimal>();
		
		Id userID = UserInfo.getUserId();
		users = (List<User>)Database.query('select Id, Name, ManagerId, Managers_Manager__c'
											+ ' from User where NTID__c != null and ('
											+ (getByNTIDs != null ? 'NTID__c in: getByNTIDs' : 'Id =: getByUserID')
											+ (includeTeam == true ? ' or ManagerId =: userID or Managers_Manager__c =: userID' : '')
											+ ') and IsActive = true order by LastName, FirstName');
		readOnlyMode = users.size() > 1;
		resourcesByUserID = new Map<Id, List<Project_Resource__c>>();
		projects = new Map<Id, Project__c>();
		projectResourceHours = new Map<Id, Project_Resource_Hours__c>();
		
		userSelections = new List<SelectOption>();
		for(User u : users){
			if(u.Id == userID || u.ManagerId == userID || u.Managers_Manager__c == userID)
				userSelections.add(new SelectOption(u.Id, u.Name));
			
			resourcesByUserID.put(u.Id, new List<Project_Resource__c>());
			actualHours.put(u.Id, 0);
			plannedHours.put(u.Id, 0);
		}
		
		currentWeek = Date.parse(currentWeekStr);
		projects = new Map<Id, Project__c>();
		
		Set<String> excludeProjectStatuses = (selectedProjectOption == PROJECTS_OPEN || selectedProjectOption == PROJECTS_MINE_OPEN)
												? projectCompleteStatuses
												: new Set<String>();
		
		Map<Id, Id> resourceIDToUserID = new Map<Id, Id>();
		for(Project_Resource__c pr : [select Id, Name, Project__c, Project__r.Status__c, Resource_User__c, Resource_Role__c,
										(select Actual_Hours__c, Planned_Hours__c, Resource_Week__c, Notes__c
											from Resource_Hours__r
											where Resource_Week__c >=: currentWeek
												and Resource_Week__c <: currentWeek.addDays(7)
											order by Resource_Week__c limit 1)
										from Project_Resource__c
										where Resource_User__c in: resourcesByUserID.keyset()
										order by Project__r.Name, Resource_Role__c]){
			Boolean hoursExist = (pr.Resource_Hours__r != null && pr.Resource_Hours__r.size() > 0);
			projectResourceHours.put(pr.Id, hoursExist ? pr.Resource_Hours__r[0] : new Project_Resource_Hours__c(Resource__c = pr.Id, Resource_Week__c = currentWeek));
			if(hoursExist || pr.Project__r.Status__c == null || !excludeProjectStatuses.contains(pr.Project__r.Status__c)){
				resourcesByUserID.get(pr.Resource_User__c).add(pr);
				resourceIDToUserID.put(pr.Id, pr.Resource_User__c);
			}
			projects.put(pr.Project__c, null);
		}
		
		for(Project_Resource_Hours__c prh : projectResourceHours.values()){
			prh.Actual_Hours__c = prh.Actual_Hours__c == null ? 0 : prh.Actual_Hours__c;
			prh.Planned_Hours__c = prh.Planned_Hours__c == null ? 0 : prh.Planned_Hours__c;
			
			Id uID = resourceIDToUserID.get(prh.Resource__c);
			if(uID != null){
				actualHours.put(uID, actualHours.get(uID)+prh.Actual_Hours__c);
				plannedHours.put(uID, plannedHours.get(uID)+prh.Planned_Hours__c);
			}
		}
		
		projectLeads = new Map<Id, String>();
		projectSelections = new List<SelectOption>();
		List<SelectOption> psList = new List<SelectOption>();
		for(Project__c p : [select Id, Name, Project_Lead__c, (select Id, Resource_User__c, Resource_Role__c from Resources__r where Resource_User__c =: userID)
								from Project__c where Status__c not in: excludeProjectStatuses or Id in: projects.keyset() order by CreatedDate desc]){
			Set<String> l = new Set<String>{p.Project_Lead__c};
			
			Boolean userInProject = false;
			for(Project_Resource__c pr : (p.Resources__r != null ? p.Resources__r : new List<Project_Resource__c>())){
				userInProject |= (pr.Resource_User__c == userID);
				if(pr.Resource_Role__c == 'Project Leader')
					l.add(pr.Resource_User__c);
			}
			
			if(((selectedProjectOption != PROJECTS_MINE && selectedProjectOption != PROJECTS_MINE_OPEN) || userInProject) && projectSelections.size() < 1000)
				psList.add(new SelectOption(p.Name, p.Id));
			
			if(projects.containsKey(p.Id)){
				projects.put(p.Id, p);
				
				if(l.contains(null))
					l.remove(null);
				
				projectLeads.put(p.Id,  string.join(new List<String>(l), ','));
			}
		}
		
		psList.sort();
		for(SelectOption so : psList)
			projectSelections.add(new SelectOption(so.getLabel(), so.getValue()));
	}
	
	public void getWeeks(){
		weekSelections = new List<SelectOption>();
		Date d = getMonday(Date.newInstance(year, 1, 1));
		
		Date today = Date.today();
		do{
			weekSelections.add(new SelectOption(d.format(), (d.month() + '/' + d.day())));
			if(d <= today && d.addDays(7) > today)
				currentWeek = d;
			d = d.addDays(7);
		}while(d.year() == year);
		
		if(year != today.year())
			currentWeek = Date.parse(weekSelections[0].getValue());
		
		currentWeekStr = currentWeek.format();
	}
	
	private Date getMonday(Date d){
		while(Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('EEEE') != 'Monday'){
			d = d.addDays(-1);
		}
		return d;
	}
	
	public void saveChanges(){
		List<Project_Resource_Hours__c> hours = new List<Project_Resource_Hours__c>();
		for(Project_Resource_Hours__c prh : projectResourceHours.values()){
			if(prh.Id != null
				|| (prh.Actual_Hours__c != null && prh.Actual_Hours__c != 0)
				|| (prh.Planned_Hours__c != null && prh.Planned_Hours__c != 0)
				|| !string.IsEmpty(prh.Notes__c))
				hours.add(prh);
		}
		
		SecurityUtils.BypassProcesser.saveObjects(hours, false);
		
		getUserResources();
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_Hours(); }
}