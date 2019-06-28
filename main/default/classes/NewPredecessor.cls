public class NewPredecessor {
	
	public String workstepId { get; set; }
	public Workstep__c currentWorkstep { get; set; }
	public List<Workstep__c> allWorksteps;
	public List<Predecessor__c> predList;
	public List<Predecessor__c> successorsList;
	public Map<Id,String> allWorkstepsMap;
	
	public List<String> currentPredecessors { get; set; }
	public List<String> selectedPredecessors { get; set; }
	public List<SelectOption> currentPredecessorsList { get; set; }
	public List<SelectOption> selectedPredecessorsList { get; set; }
	public List<String> initialPredecessorsList = new List<String>();
	public List<String> initialSelectedPredecessorsList = new List<String>();
	public Set<String> predForDelete = new Set<String>();
	public Set<String> predForInsert = new Set<String>();
	
	public List<String> currentSuccessors { get; set; }
	public List<String> selectedSuccessors { get; set; }
	public List<SelectOption> currentSuccessorsList { get; set; }
	public List<SelectOption> selectedSuccessorsList { get; set; }
	public List<String> initialSuccessorsList = new List<String>();
	public List<String> initialSelectedSuccessorsList = new List<String>();
	public Set<String> successorsForDelete = new Set<String>();
	public Set<String> successorsForInsert = new Set<String>();
	
	public String wmp { get; set; }
	
	public NewPredecessor() {
		Map<String, String> params = ApexPages.currentPage().getParameters();
		wmp = params.get('wmp');
		workstepId = params.get('id');
		currentWorkstep = [SELECT Id, Name, Order__c, Sub_Order__c FROM Workstep__c WHERE Id = :workstepId];
		allWorkstepsMap = getAllWorkstepsMap();
		
		initPredecessorsAndSuccessors();
	}
	
	private void initPredecessorsAndSuccessors() {
		predList = (currentWorkstep.Sub_Order__c == null)
					? [SELECT Dependent_Workstep__c, Predecessor_Workstep__c, Predecessor_Workstep__r.Name FROM Predecessor__c 
						WHERE Dependent_Workstep__c = :workstepId AND Dependent_Workstep__r.Order__c = :currentWorkstep.Order__c
						order by Predecessor_Workstep__r.Name asc]
					: [SELECT Dependent_Workstep__c, Predecessor_Workstep__c, Predecessor_Workstep__r.Name FROM Predecessor__c 
						WHERE Dependent_Workstep__c = :workstepId AND Dependent_Workstep__r.Sub_Order__c = :currentWorkstep.Sub_Order__c
						order by Predecessor_Workstep__r.Name asc];
		
		selectedPredecessors = new List<String>();
		selectedPredecessorsList = new List<SelectOption>();
		if (predList.size() > 0) {
			for (Predecessor__c p : predList) {
				selectedPredecessors.add(p.Predecessor_Workstep__c);
				selectedPredecessorsList.add(new SelectOption(p.Predecessor_Workstep__c, p.Predecessor_Workstep__r.Name));
				initialSelectedPredecessorsList.add(p.Predecessor_Workstep__c);
			}
		}
		
		successorsList = (currentWorkstep.Sub_Order__c == null)
						? [SELECT Dependent_Workstep__c, Dependent_Workstep__r.Name, Predecessor_Workstep__r.Name, Predecessor_Workstep__c FROM Predecessor__c 
							WHERE Predecessor_Workstep__c = :workstepId AND Predecessor_Workstep__r.Order__c = :currentWorkstep.Order__c
							order by Dependent_Workstep__r.Name asc]
						: [SELECT Dependent_Workstep__c, Dependent_Workstep__r.Name, Predecessor_Workstep__r.Name, Predecessor_Workstep__c FROM Predecessor__c 
							WHERE Predecessor_Workstep__c = :workstepId AND Predecessor_Workstep__r.Sub_Order__c = :currentWorkstep.Sub_Order__c
							order by Dependent_Workstep__r.Name asc];
		
		selectedSuccessors = new List<String>();
		selectedSuccessorsList = new List<SelectOption>();
		if (successorsList.size() > 0) {
			for (Predecessor__c p : successorsList) {
				selectedSuccessors.add(p.Dependent_Workstep__c);
				selectedSuccessorsList.add(new SelectOption(p.Dependent_Workstep__c, p.Dependent_Workstep__r.Name));
				initialSelectedSuccessorsList.add(p.Dependent_Workstep__c);
			}
		}
		
		List<String> selected = new List<String>();
		selected.addAll(selectedPredecessors);
		selected.addAll(selectedSuccessors);
		currentPredecessorsList = getWorksteps(selected);
		for (SelectOption so : currentPredecessorsList)
			initialPredecessorsList.add(so.getValue());
		
		selectedPredecessors = new List<String>();
		
		currentSuccessorsList = getWorksteps(selected);
		for (SelectOption so : currentSuccessorsList)
			initialSuccessorsList.add(so.getValue());
		
		selectedSuccessors = new List<String>();
	}
	
	public Map<Id,String> getAllWorkstepsMap() {
		allWorksteps = [SELECT Id, Name FROM Workstep__c WHERE Sub_Order__c = :currentWorkstep.Sub_Order__c];
		Map<Id, String> workstepsMap = new Map<Id, String>();
		for (Workstep__c ws : allWorksteps)
			workstepsMap.put(ws.Id, ws.Name);
		
		return workstepsMap;
	}
	
	public List<SelectOption> getWorksteps(List<String> selectedIds) {
		List<SelectOption> options = new List<SelectOption>();
		for (Workstep__c ws : (currentWorkstep.Sub_Order__c != null)
									? [SELECT Id, Name FROM Workstep__c WHERE Id NOT IN :selectedIds AND Id != :workstepId AND Sub_Order__c = :currentWorkstep.Sub_Order__c order by Name]
									: [SELECT Id, Name FROM Workstep__c WHERE Id NOT IN :selectedIds AND Id != :workstepId AND Order__c = :currentWorkstep.Order__c order by Name])
			options.add(new SelectOption(ws.Id, ws.Name));
		return options;
	}
	
	public PageReference Save() {
		/*if (selectedPredecessorsList.size() > 0 || selectedSuccessorsList.size() > 0)
			return (wmp != null) ? saveAction(new PageReference('/apex/PredecessorDependencyType?wmp=' + wmp)) : saveAction(new PageReference('/apex/PredecessorDependencyType'));*/
		
		return (wmp != null) ? saveAction(new PageReference('/apex/WorkstepManagement')) : saveAction(new PageReference('/' + workstepId));
	}
	
	private PageReference saveAction(PageReference pageRef) {
		Set<String> selectedPredecessorSet = new Set<String>();
		selectedPredecessorSet.add(currentWorkstep.Id);
		for (SelectOption so : selectedPredecessorsList)
			selectedPredecessorSet.add(so.getValue());
		
		if (selectedPredecessorSet.size() > 0) {
			Set<String> selectedSuccessorSet = new Set<String>();
			for (SelectOption so : selectedSuccessorsList)
				selectedSuccessorSet.add(so.getValue());
			
			String workstepError = checkPredecessorAndSuccessorsRelations(selectedPredecessorSet, selectedSuccessorSet);
			if (workstepError != null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Workstep ' + workstepError + ' makes a circular relation between worksteps!'));
				return null;
			}
		}
		
		predForInsert.removeAll(initialSelectedPredecessorsList);
		predForDelete.removeAll(initialPredecessorsList);
		
		successorsForInsert.removeAll(initialSelectedSuccessorsList);
		successorsForDelete.removeAll(initialSuccessorsList);
		
		Predecessor__c newPred;
		List<Predecessor__c> newPredList = new List<Predecessor__c>();
		if (successorsForInsert.size() > 0) {
			for (String successor : successorsForInsert) {
				newPred = new Predecessor__c();
				newPred.Predecessor_Workstep__c = workstepId;
				newPred.Dependent_Workstep__c = successor;
				newPredList.add(newPred);
			}
		}
		
		if (predForInsert.size() > 0) {
			for (String pred : predForInsert) {
				newPred = new Predecessor__c();
				newPred.Predecessor_Workstep__c = pred;
				newPred.Dependent_Workstep__c = workstepId;
				newPredList.add(newPred);
			}
		}

		try {
			if (newPredList.size() > 0)
				insert newPredList;
			
			if (predForDelete.size() > 0 || successorsForDelete.size() > 0) 
				delete [Select Id FROM Predecessor__c where (Dependent_Workstep__c = :workstepId AND Predecessor_Workstep__c IN :predForDelete) OR (Predecessor_Workstep__c = :workstepId AND Dependent_Workstep__c IN :successorsForDelete)];
		} catch (DMLException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
			return null;
		}
		pageRef.getParameters().put('workstepId', workstepId);
		return pageRef;
	}
	
	public String checkPredecessorAndSuccessorsRelations(Set<String> selectedPredecessorSet, Set<String> selectedSuccessorSet) {
		List<Predecessor__c> pList = [SELECT Id, Dependent_Workstep__c, Dependent_Workstep__r.Name FROM Predecessor__c WHERE Predecessor_Workstep__c IN :selectedSuccessorSet];
		Set<String> relatedSuccessorsSet = new Set<String>();
		for (Predecessor__c p : pList) {
			if (selectedPredecessorSet.contains(p.Dependent_Workstep__c))
				return p.Dependent_Workstep__r.Name;
			else
				relatedSuccessorsSet.add(p.Dependent_Workstep__c);
		}
		if (relatedSuccessorsSet.size() > 0)
			return checkPredecessorAndSuccessorsRelations(selectedPredecessorSet, relatedSuccessorsSet);
		
		return null;
	}
	
	public PageReference Cancel() {
		return (wmp != null) ? new PageReference('/apex/WorkstepManagement') : new PageReference('/' + workstepId);
	}
	
	public void addPredecessors() {
		predForInsert.addAll(currentPredecessors);
		predForDelete.removeAll(currentPredecessors);
		for (String pred : currentPredecessors)
			selectedPredecessorsList.add(new SelectOption(pred, allWorkstepsMap.get(pred)));
		
		for (SelectOption so : selectedPredecessorsList)
			selectedPredecessors.add(so.getValue());
		
		for (SelectOption so : selectedSuccessorsList)
			selectedSuccessors.add(so.getValue());
		
		List<String> selected = new List<String>();
		selected.addAll(selectedPredecessors);
		selected.addAll(selectedSuccessors);
		currentPredecessorsList = getWorksteps(selected);
		currentPredecessors = new List<String>();
		selectedPredecessors = new List<String>();
		selectedSuccessors = new List<String>();
	}
	
	public void removePredecessors() {
		predForInsert.removeAll(selectedPredecessors);
		predForDelete.addAll(selectedPredecessors);
		
		Map<String, String> selectedPredMap = new Map<String,String>();
		for (String pred : selectedPredecessors)
			selectedPredMap.put(pred,pred);
		
		List<SelectOption> helperList = selectedPredecessorsList;
		selectedPredecessors = new List<String>();
		selectedPredecessorsList = new List<SelectOption>();
		for (SelectOption so : helperList) {
			if (!selectedPredMap.containsKey(so.getValue())) {
				selectedPredecessorsList.add(so);
				selectedPredecessors.add(so.getValue());
			}
		}
		for (SelectOption so : selectedSuccessorsList)
			selectedSuccessors.add(so.getValue());
		
		List<String> selected = new List<String>();
		selected.addAll(selectedPredecessors);
		selected.addAll(selectedSuccessors);
		
		currentPredecessorsList = getWorksteps(selected);
		currentPredecessors = new List<String>();
		selectedPredecessors = new List<String>();
		selectedSuccessors = new List<String>();
	}
	
	public void addSuccessors() {
		successorsForInsert.addAll(currentSuccessors);
		successorsForDelete.removeAll(currentSuccessors);
		for (String s : currentSuccessors)
			selectedSuccessorsList.add(new SelectOption(s, allWorkstepsMap.get(s)));
		
		for (SelectOption so : selectedSuccessorsList)
			selectedSuccessors.add(so.getValue());
	
		for (SelectOption so : selectedPredecessorsList)
			selectedPredecessors.add(so.getValue());
		
		List<String> selected = new List<String>();
		selected.addAll(selectedPredecessors);
		selected.addAll(selectedSuccessors);
		
		currentPredecessorsList = getWorksteps(selected);
		currentSuccessors = new List<String>();
		selectedSuccessors = new List<String>();
		selectedPredecessors = new List<String>();
	}
	
	public void removeSuccessors() {
		successorsForInsert.removeAll(selectedSuccessors);
		successorsForDelete.addAll(selectedSuccessors);
		
		Map<String, String> selectedSuccessorsMap = new Map<String,String>();
		for (String s : selectedSuccessors)
			selectedSuccessorsMap.put(s,s);
		
		List<SelectOption> helperList = selectedSuccessorsList;
		selectedSuccessors = new List<String>();
		selectedSuccessorsList = new List<SelectOption>();
		for (SelectOption so : helperList) {
			if (!selectedSuccessorsMap.containsKey(so.getValue())) {
				selectedSuccessorsList.add(so);
				selectedSuccessors.add(so.getValue());
			}
		}
		
		for (SelectOption so : selectedPredecessorsList)
			selectedPredecessors.add(so.getValue());
		
		List<String> selected = new List<String>();
		selected.addAll(selectedPredecessors);
		selected.addAll(selectedSuccessors);
		
		currentPredecessorsList = getWorksteps(selected);
		currentSuccessors = new List<String>();
		selectedSuccessors = new List<String>();
		selectedPredecessors = new List<String>();
	}
}