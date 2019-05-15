public class AssignWorkstepIssues extends WorkflowAssignmentControllerBase implements TestUtils.ITestableClass {
	
	public List<Workstep_Issue__c> issuesList;
	public List<IssueWrapper> issueWrapperList { get; set; }
	public Workstep_Issue__c dummyWSIssue {get; set;}
	
	public override List<sObjectWrapper> getWrapperCollection() {
		return (List<sObjectWrapper>)issueWrapperList;
	}
	
	public AssignWorkstepIssues(ApexPages.StandardSetController sc) {
		sObjType = Workstep_Issue__c.sObjectType;
		issuesList = (List<Workstep_Issue__c>)getRecords(sc);
		isError = issuesList.size() == 0;
		reselectIssues(issuesList, true);
		listViewURL = getListViewURL(sc, 'Workstep_Issue__c', 'Issue Assignment View');
		dummyWSIssue = new Workstep_Issue__c();
		dummySObject = (sObject)dummyWSIssue;
	}
	
	public void reselectIssues(List<Workstep_Issue__c> issuesList, boolean isSelected) {
		issuesList = [SELECT Id, Name, OwnerId, Owner.Name FROM Workstep_Issue__c WHERE Id IN :issuesList];
		issueWrapperList = new List<IssueWrapper>();
		for (Workstep_Issue__c is : issuesList)
			issueWrapperList.add(new IssueWrapper(is, isSelected));
	}
	
	public override void saveComplete(){
		reselectIssues(issuesList, false);
	}
	
	public class IssueWrapper extends sObjectWrapper {
		public Workstep_Issue__c issue { get; set; }
		
		public IssueWrapper(Workstep_Issue__c issue, boolean isSelected) {
			this.issue = issue;
			sObj = (sObject)issue;
			isSelected = isSelected;
		}
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_AssignWorkstepIssues(); }
}