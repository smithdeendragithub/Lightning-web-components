public class NewWorkstep {
	public Sub_Order__c suborder;
	
	public List<String> currentWorksteps { get; set; }
	public List<SelectOption> currentWorkstepList { get; set; }
	public List<String> selectedWorksteps { get; set; } 
	public List<SelectOption> selectedWorkstepList { get; set; }
	
	public Map<Id, Workstep_Library__c> allWorkstepsMap;
	public String subOrderId;
	public String orderId;
	
	public NewWorkstep() {
		subOrderId = ApexPages.currentPage().getParameters().get('id');
		orderId = ApexPages.currentPage().getParameters().get('oid');
		if(subOrderId != null) {
			suborder = [SELECT Id, Order__c FROM Sub_Order__c WHERE Id = :subOrderId];
			if(suborder != null)
				orderId = suborder.Order__c;
		}
		
		
		currentWorksteps = new List<String>();
		selectedWorkstepList = new List<SelectOption>();
		selectedWorksteps = new List<String>();
		currentWorkstepList = getWorkstepLibrary();
		allWorkstepsMap = getAllWorkstepsMap();
	}
	
	public List<SelectOption> getWorkstepLibrary() {
		List<SelectOption> options = new List<SelectOption>();
		for (Workstep_Library__c wsl : [SELECT Id, Name FROM Workstep_Library__c WHERE Id NOT IN :selectedWorksteps order by Name])
			options.add(new SelectOption(wsl.Id,wsl.Name));
		return options;
	}
	
	public Map<Id,Workstep_Library__c> getAllWorkstepsMap() {
		Map<Id,Workstep_Library__c> workstepsMap = new Map<Id,Workstep_Library__c>();
		for (Workstep_Library__c ws : [SELECT Id, Name, Non_Access_SLA__c, Non_Access_Lag__c, Non_Access_Duration__c, OwnerId, Work_Group__c, Attribute__c FROM Workstep_Library__c])
			workstepsMap.put(ws.Id, ws);
		return workstepsMap;
	}
	
	public void addWorksteps() {
		for (String ws : currentWorksteps)
			selectedWorkstepList.add(new SelectOption(ws, allWorkstepsMap.get(ws).Name));
		
		for (SelectOption so : selectedWorkstepList)
			selectedWorksteps.add(so.getValue());
		
		currentWorkstepList = getWorkstepLibrary();
		currentWorksteps = new List<String>();
		selectedWorksteps = new List<String>();
	}
	
	public void removeWorksteps() {
		Map<String, String> selectedWorkstepMap = new Map<String,String>();
		for (String ws : selectedWorksteps)
			selectedWorkstepMap.put(ws,ws);
		
		List<SelectOption> l = selectedWorkstepList;
		selectedWorksteps = new List<String>();
		selectedWorkstepList = new List<SelectOption>();
		for (SelectOption so : l) {
			if (!selectedWorkstepMap.containsKey(so.getValue())) {
				selectedWorkstepList.add(so);
				selectedWorksteps.add(so.getValue());
			}
		}
		currentWorkstepList = getWorkstepLibrary();
		currentWorksteps = new List<String>();
		selectedWorksteps = new List<String>();
	}
	
	public PageReference Save() {
		List<Workstep__c> wstList = new List<Workstep__c>();
		for (SelectOption so : selectedWorkstepList) {
			Workstep_Library__c lib = allWorkstepsMap.get(so.getValue());
			
			//calculate start and end date
			Date startd = Date.today();
			Date endd = startd;
			if(lib.Non_Access_Duration__c != null)
				endd = endd.addDays((Integer)lib.Non_Access_Duration__c);
			
			wstList.add(new Workstep__c(Order__c = orderId
								,Sub_Order__c = subOrderId
								,Name = lib.Name
								,Workstep_Library__c = lib.Id
								,Status__c = WorkstepUtils.STATUS_OPEN
								,Work_Group__c = lib.Work_Group__c
								,Lag__c = lib.Non_Access_Lag__c
								,Duration__c = lib.Non_Access_Duration__c
								,SLA__c = lib.Non_Access_SLA__c
								,Attribute__c = lib.Attribute__c
								,Start_Date__c = startd
								,End_Date__c = endd
								));
		}
		try {
			if (wstList.size() > 0)
				insert wstList;
			
			if(suborder != null)
		{
			return new PageReference('/' + subOrderId);
		}
		else{
			return new PageReference('/' + orderId);
		}
		} catch (DMLException e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
		}
		return null;
	}
	
	public PageReference Cancel() {
		if(suborder == null)
		{
			return new PageReference('/' + subOrderId);
		}
		else{
			return new PageReference('/' + orderId);
		}
		
	}
}