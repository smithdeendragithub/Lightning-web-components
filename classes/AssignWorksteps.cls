public class AssignWorksteps extends WorkflowAssignmentControllerBase implements TestUtils.ITestableClass {
	
	public List<Workstep__c> workstepList;
	public List<WorkstepWrapper> workstepWrapperList { get; set; }
	public Workstep__c dummyWS {get; set;}
	
	public override List<sObjectWrapper> getWrapperCollection() {
		return (List<sObjectWrapper>)workstepWrapperList;
	}
	
	public AssignWorksteps(ApexPages.StandardSetController sc) {
		sObjType = Workstep__c.sObjectType;
		workstepList = (List<Workstep__c>)getRecords(sc);
		isError = workstepList.size() == 0;
		sendNotification = false;		//default to false
		reselectWorksteps(workstepList, true);
		listViewURL = getListViewURL(sc, 'Workstep__c', 'Worksteps Requiring Assignment');
		dummyWS = new Workstep__c();
		dummySObject = (sObject)dummyWS;
	}
	
	public void reselectWorksteps(List<Workstep__c> workstepList, boolean isSelected) {
		workstepList = [SELECT Id, Name, OwnerId, Owner.Name, Workstep_Number__c FROM Workstep__c WHERE Id IN :workstepList];
		workstepWrapperList = new List<WorkstepWrapper>();
		for (Workstep__c ws : workstepList)
			workstepWrapperList.add(new WorkstepWrapper(ws, isSelected));
	}
	
	public override void saveComplete(){
		reselectWorksteps(workstepList, false);
	}
	
	public class WorkstepWrapper extends sObjectWrapper {
		public Workstep__c ws { get; set; }
		
		public WorkstepWrapper(Workstep__c ws, boolean isSelected) {
			this.ws = ws;
			sObj = (sObject)ws;
			isSelected = isSelected;
		}
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_AssignWorksteps(); }
}