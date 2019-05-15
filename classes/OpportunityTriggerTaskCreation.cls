public with sharing class OpportunityTriggerTaskCreation implements TestUtils.ITestableClass {
	
	public static void determineClosedWonTasksNeeded(Map<Id, Opportunity> opps){
		
		//Spin off future methods
		//Disabled per Chris Pike - capital projects no longer apply
		//Map<Id,Id> OppToCapProj = createICertsFromClosedWonOpportunities(opps.keyset());
		//createOppProductTaskReminders(opps.keyset(), OppToCapProj);
		//determineBuildingAccessAvailabilityActions(opps.keyset(), oppToCapProj);
	}
	
	private static Map<String, Opportunity_Task_Definition__c> oppTaskDefMap = null;
	private static Map<String, Opportunity_Task_Definition__c> OpportunityTaskDefinitionMap{
		get{
			if(oppTaskDefMap == null){
				oppTaskDefMap = new Map<String, Opportunity_Task_Definition__c>();
				for(Opportunity_Task_Definition__c def : [select Name, Task_Subject__c, Task_Description__c, Task_Type__c, Task_Activity_Date_Offset__c, Task_Reminder_Date_Offset__c from Opportunity_Task_Definition__c])
					oppTaskDefMap.put(def.Name, def);
			}
			
			return oppTaskDefMap;
		}
	}
	
	private static User getTaskOwnerByOpportunityOwnerRegion(User opportunityOwner){
		User regionAE;
		if(opportunityOwner != null)
			regionAE = CustomSettingUtils.GetRegionalAE(opportunityOwner.State);

		return regionAE != null ? regionAE : opportunityOwner;
	}
	
	
	
	private static String replaceInlineTaskText(String value, String objName, sObject obj){
		try{
			if(value.contains('{' + objName + '}'))
				value = value.replace('{' + objName + '}', string.valueOf(obj.get('name')));
		} catch(Exception e){ system.debug('Replace error in text: "' + value + '" with error "' + e.getMessage() + '"'); }
		
		return value;
	}
	
	/* BAA actions section */
	public class OpportunityBAAActionMap{
		
		public Opportunity opp {get; set;}
		public Order__c order {get; set;}
		public Set<Id> oliIDs {get; set;}
		public Set<Id> buildingIDs {get; set;}
		public Map<Id, Set<Id>> criteriaPassedForBuildingIDs {get; set;}
		
		public OpportunityBAAActionMap(Opportunity opp){
			this.opp = opp;
			oliIDs = new Set<Id>();
			buildingIDs = new Set<Id>();
			criteriaPassedForBuildingIDs = new Map<Id, Set<Id>>();
		}
	}
	
	@future(callout=false)
	public static void determineBuildingAccessAvailabilityActions(Set<Id> oppIDs, Map<Id, Id> OppToCapProj){
		
		Map<Id, Opportunity> opps = new Map<Id, Opportunity>([select Id, OwnerId, Name from Opportunity where Id in: oppIDs]);
		
		Map<Id, OpportunityBAAActionMap> actionMapByOppID = new Map<Id, OpportunityBAAActionMap>();
		for(Opportunity opp : opps.values())
			actionMapByOppID.put(opp.Id, new OpportunityBAAActionMap(opp));
		
		Map<Id, Id> salesEngineersByOppID = opportunityUtils.getSalesEngineersByOppID(opps.keyset());
		Map<Id, User> users = OpportunityUtils.getUsers(opps.values(), new Set<Id>(salesEngineersByOppID.values()));
		
		for(Order__c o : [select Id, Name, Assigned_CPM__c, Assigned_CPM__r.Id, Opportunity__c from Order__c where Opportunity__c in : opps.keyset()])
			actionMapByOppID.get(o.Opportunity__c).order = o;
		
		Map<Id, List<OpportunityLocationConfiguration__c>> olcsByOppID = OpportunityUtils.getOLCsFromOpportunities(opps, new Set<String>{'Location__r.Building__r.Id'
																																		,'Location__r.Building__r.Name'
																																		,'Location__r.Building__r.Net_Classification__c'
																																		,'Location__r.Building__r.Building_CLLI__c'});
		Set<Id> olcIDs = new Set<Id>();
		for(List<OpportunityLocationConfiguration__c> l : olcsByOppID.values()){
			for(OpportunityLocationConfiguration__c olc : l)
				olcIDs.add(olc.Id);
		}
		
		//Gather opps by building
		Map<Id, List<Opportunity_Location__c>> oppLocs = OpportunityUtils.getOpportunityLocationsFromOLCMap(olcsByOppID);
		Map<Id, Building__c> buildings = new Map<Id, Building__c>();
		Map<Id, Set<Id>> oppIDsByBuildingID = new Map<Id, Set<Id>>();
		for(Id oppID : oppLocs.keyset()){
			for(Opportunity_Location__c oLoc : oppLocs.get(oppID)){
				Building__c building = oLoc.Service_Location__r.Location__r.Building__r;
				actionMapByOppID.get(oppID).buildingIDs.add(building.Id);
				buildings.put(building.Id, building);
	
				Set<Id> oIDs = oppIDsByBuildingID.get(building.Id) != null ? oppIDsByBuildingID.get(building.Id) : new Set<Id>();
				oIDs.add(oppID);
				oppIDsByBuildingID.put(building.Id, oIDs);
			}
		}
		
		/* Get OLIs */
		Set<Id> oliIDs = new Set<Id>();
		Map<Id, Set<OLI__c>> olisByBuildingID = new Map<Id, Set<OLI__c>>();
    	for(OLI__c oli : [select Id
								,OpportunityLocationConfiguration__r.Opportunity_Location__r.Opportunity__c
								,OpportunityLocationConfiguration__r.Opportunity_Location__r.Service_Location__r.Location__r.Building__c
							from OLI__c where OpportunityLocationConfiguration__c in: olcIDs]){
			Id oppID = oli.OpportunityLocationConfiguration__r.Opportunity_Location__r.Opportunity__c;
			actionMapByOppID.get(oppID).oliIDs.add(oli.Id);
			oliIDs.add(oli.Id);
			
			Id buildingID = oli.OpportunityLocationConfiguration__r.Opportunity_Location__r.Service_Location__r.Location__r.Building__c;
			Set<OlI__c> olis = olisByBuildingID.get(buildingID) != null ? olisByBuildingID.get(buildingID) : new Set<OlI__c>();
			olis.add(oli);
			olisByBuildingID.put(buildingID, olis);
    	}
		
		Map<Id, Opportunity_BAA_Based_Action__c> baaBasedActions = new Map<Id, Opportunity_BAA_Based_Action__c>([select Id
																														,Name
																														,BAA_Criteria__c
																														,Building_Criteria__c
																														,OLI_Criteria__c
																														,Solution_Hurdle_Rate_Requirement__c
																														,Send_Task_Email__c
																														,Task_Assignee__c
																														,Task_Definition__c
																														,Task_Parent__c
																													from Opportunity_BAA_Based_Action__c]);
		
		Map<Id, Building_Access_Availability__c> baaMap = new Map<Id, Building_Access_Availability__c>([select Id, Status__c, Building__c, Minimum_Required_Revenue__c, Access_Technology__r.Access_Technology_ID__c from Building_Access_Availability__c where Building__c in : buildings.keyset()]);
		
		Map<Id, Set<Id>> baaFlags = getFilteredObjectIDs('Building_Access_Availability__c', baaMap.keyset(), baaBasedActions.values(), 'BAA_Criteria__c');
		Map<Id, Set<Id>> buildingFlags = getFilteredObjectIDs('Building__c', buildings.keyset(), baaBasedActions.values(), 'Building_Criteria__c');
		Map<Id, Set<Id>> oliFlags = getFilteredObjectIDs('OLI__c', oliIDs, baaBasedActions.values(), 'OLI_Criteria__c');
		
		//Map opportunities to criteria
		for(Building_Access_Availability__c baa : baaMap.values()){
			
			for(Id baaf : baaFlags.get(baa.Id)){
				Opportunity_BAA_Based_Action__c bba = baaBasedActions.get(baaf);
				
				Set<Id> bPassed = new Set<Id>();
				for(Id bf : buildingFlags.get(baa.Building__c)){
					if(bf == baaf) bPassed.add(baa.Building__c);
				}
				
				Set<Id> oIDs = new Set<Id>();
				for(Id buildingID : bPassed){
					for(OLI__c oli : olisByBuildingID.get(buildingID) != null ? olisByBuildingID.get(buildingID) : new Set<OLI__c>()){
						Id oppID = oli.OpportunityLocationConfiguration__r.Opportunity_Location__r.Opportunity__c;
						for(Id olif : oliFlags.get(oli.Id)){
							if(olif == baaf) oIDs.add(oppID);
						}
					}
				}
				
				for(Id oppID : oIDs){
					
					Boolean hurdleRateAttained = false;
					boolean ignoreHurdleRate = bba.Solution_Hurdle_Rate_Requirement__c == 'Ignore' || string.isEmpty(bba.Solution_Hurdle_Rate_Requirement__c);
					if(baa.Minimum_Required_Revenue__c != null && !ignoreHurdleRate){
						for(OpportunityLocationConfiguration__c olc : olcsByOppID.get(oppId)){
							decimal total = (olc.Opportunity_Location__r.MRC_Total__c - olc.Opportunity_Location__r.Turndown_Total__c);
							hurdleRateAttained |= (bba.Solution_Hurdle_Rate_Requirement__c == 'Above' && total >= baa.Minimum_Required_Revenue__c) || (bba.Solution_Hurdle_Rate_Requirement__c == 'Below' && total < baa.Minimum_Required_Revenue__c);
						}
					}
					
					if(ignoreHurdleRate || hurdleRateAttained)
						actionMapByOppID.get(oppID).criteriaPassedForBuildingIDs.put(baaf, bPassed);
				}
			}
		}
		
		//Build tasks and send emails
		List<Task> newTasks = new List<Task>();
		Set<String> tasksCreated = new Set<String>();
		for(OpportunityBAAActionMap m : actionMapByOppID.values()){
			for(Id criteriaID : m.criteriaPassedForBuildingIDs.keyset()){
				Opportunity_BAA_Based_Action__c bba = baaBasedActions.get(criteriaID);
				Opportunity_Task_Definition__c tDef = OpportunityTaskDefinitionMap.get(bba.Task_Definition__c);
				
				for(Id buildingID : m.criteriaPassedForBuildingIDs.get(criteriaID)){
					Opportunity opp = m.opp;
					Order__c oppOrder = m.order;
					Building__c b = buildings.get(buildingID);
					Id capProjId = OppToCapProj.get(m.opp.Id);
					
					System.debug('Processing tasks for Opportunity: "' + opp.Id + '" Building: "' + b.Id + '" Action: ' + bba.Name);
					
					//Do actions
					String subject = replaceInlineBBATaskText(tDef.Task_Subject__c, opp, oppOrder, b);
					String description = replaceInlineBBATaskText(tDef.Task_Description__c, opp, oppOrder, b);
					
					Id whatID = null;
					for (string parent : bba.Task_Parent__c.split(','))	{
						if (parent == 'Capital Project') whatId = OppToCapProj.get(opp.Id);
						else if(parent == 'Opportunity') whatID = opp.Id;
						else if(parent == 'Building') whatID = b.Id;
						else if(parent == 'Order') whatId = oppOrder.Id;
						if (whatId != null) break;
					}
					if (whatID == null)	{
						System.debug('Skipping: no parent assigned');
						continue;
					}
					User assignee = getAssignee(opp, oppOrder, users, salesEngineersByOppID.get(opp.Id), bba);
					
					if(assignee == null){
						System.debug('Skipping: no valid assignee');
						continue;
					}
					
                    if (subject.equals('Confirm if iCERT is needed for building')){
						System.debug('Disable iCert Task creation');
						continue;	
					}
                    
					newTasks.add(new Task(OwnerId = assignee.Id
							,Subject = subject
							,Type = tDef.Task_Type__c
							,Description = description
							,ActivityDate = Date.Today().addDays(Integer.valueOf(tDef.Task_Activity_Date_Offset__c))
							,ReminderDateTime = Date.Today().addDays(Integer.valueOf(tDef.Task_Reminder_Date_Offset__c))
							,WhatId = whatID));
					
					if(bba.Send_Task_Email__c){
						String email = null;
						
						Boolean internalKickOff = false;/*bba.Task_Assignee__c.startsWith('InternalKickoffSalesChannelManager') && (assignee.Sales_Channel__c == 'Enterprise' || assignee.Sales_Channel__c == 'GovEd');
						if(internalKickOff){
							List<String> sUser = CustomSettingUtils.TaskInternalKickoffCall;
							for(string sUr : sUser)
								email = sUr;
						}*/
						
						if(email == null) email = assignee.Email;
						
						if(!Test.isRunningTest())
							Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
																ApexUtils.createEmailMessage(new String[]{email}, null, subject, '<table><tr><td>' + description + '</td></tr><tr><td></td></tr></table>', true, null)
															});
					}
				}
			}
		}
		
		system.debug('newTasks count: ' + newTasks.size());
		
		if(newTasks.size() > 0)
			Database.insert(newTasks);
	}
	
	private static Map<Id, Set<Id>> getFilteredObjectIDs(String objectName, Set<Id> baseIDs, List<Opportunity_BAA_Based_Action__c> baaBasedActions, String criteriaName){
		Map<Id, Set<Id>> retval = new Map<Id, Set<Id>>();
		for(Id id : baseIDs)
			retval.put(id, new Set<Id>());
		
		Map<String, Set<Id>> distinctCriteria = new Map<String, Set<Id>>();
		for(Opportunity_BAA_Based_Action__c bba : baaBasedActions){
			String criteria = string.valueOf(bba.get(criteriaName));
			if(!string.isEmpty(criteria)){
				Set<Id> bbaIDs = distinctCriteria.get(criteria) != null ? distinctCriteria.get(criteria) : new Set<Id>();
				bbaIDs.add(bba.Id);
				distinctCriteria.put(criteria, bbaIDs);
			}
			else{
				for(Id id : baseIDs)
					retval.get(id).add(bba.Id);
			}
		}
		
		for(String criteria : distinctCriteria.keyset()){
			try{
				for(sObject o : Database.query('select Id from ' + objectName + ' where Id in: baseIDs and (' + criteria + ')'))
					retval.get(o.Id).addAll(distinctCriteria.get(criteria));
			}
			catch(Exception e){ system.debug('Opportunity_BAA_Based_Action__c exception: ' + e.getMessage());}
		}
		
		return retval;
	}
	
	private static User getAssignee(Opportunity opp, Order__c ord, Map<Id, User> userMap, Id salesEngineerID, Opportunity_BAA_Based_Action__c bba){
		return getAssignee(opp, ord, userMap.get(opp.OwnerId), salesEngineerID != null ? userMap.get(salesEngineerID) : null, bba);
	}
	
	private static User getAssignee(Opportunity opp, Order__c ord, User oppOwner, User salesEngineer, Opportunity_BAA_Based_Action__c bba){
		User u = null;
		
		for(String assignee : bba.Task_Assignee__c.split(',')){
			if(assignee == 'RegionalAE') u = (User)getTaskOwnerByOpportunityOwnerRegion(oppOwner);
			else if(assignee == 'CPM') u = ord.Assigned_CPM__r;
			else if(assignee == 'SalesChannelManager') u = CustomSettingUtils.getInternalKickoffSalesChannelManager(oppOwner.Sales_Channel__c);
			else if(assignee == 'SalesEngineer') u = salesEngineer;
			else if(assignee == 'Owner') u = oppOwner;
			else if(!string.IsEmpty(assignee)) u = CustomSettingUtils.getSingleUserFromProcessConfiguration(assignee, 'Assignee', false);
			
			if(u != null) break;
		}
		
		return u;
	}
	
	private static String replaceInlineBBATaskText(String value, Opportunity opp, Order__c order, Building__c building){
		return (value != null) ? replaceInlineTaskText(replaceInlineTaskText(replaceInlineTaskText(value, 'Opportunity', opp), 'Order__c', order), 'Building__c', building) : value;
	}
	/* End: BAA actions section */
	
	/* Opportunity Product task reminders section */
	@future(callout=false)
	public static void createOppProductTaskReminders(Set<Id> oppIDs, Map<Id,Id> OppToCapProj){
		
		Map<Id, Opportunity> opps = new Map<Id, Opportunity>([select Id, OwnerId, Name from Opportunity where Id in: oppIDs]);
		
		Map<Id, Id> salesEngineersByOppID = opportunityUtils.getSalesEngineersByOppID(opps.keyset());
		Map<Id, User> users = OpportunityUtils.getUsers(opps.values(), new Set<Id>(salesEngineersByOppID.values()));
	
		Map<Id, Order__c> ordersByOpportunityID = new Map<Id, Order__c>();  //this will NOT work when we go to multi-order
		for(Order__c o : [select Id, Name, Opportunity__c from Order__c where Opportunity__c in : opps.keyset()])
			ordersByOpportunityID.put(o.Opportunity__c, o);
		
		//TFS: 13827 (1)& 13828(1)
		Map<Id, Set<String>> oppToProductTypes = new Map<Id, Set<String>>();
		for(Opportunity_Product__c op : [select Sales_Product__c, Opportunity__c, Id from Opportunity_Product__c where Opportunity__c in: opps.keyset() and Active__c = true]){
			Set<String> s = oppToProductTypes.get(op.Opportunity__c) != null ? oppToProductTypes.get(op.Opportunity__c) : new Set<String>();
			s.add(op.Sales_Product__c);
			oppToProductTypes.put(op.Opportunity__c, s);
		}
		
		List<Opportunity_Product_Task_Mapping__c> maps = [select Product_Name__c, Task_Definition__c from Opportunity_Product_Task_Mapping__c];
		Map<String, Set<Id>> oppTaskMapping = new Map<String, Set<Id>>();
		for(Id oppID : oppToProductTypes.keyset()){
			Set<String> productTypes = oppToProductTypes.get(oppID) != null ? oppToProductTypes.get(oppID) : new Set<String>();
			for(Opportunity_Product_Task_Mapping__c m : maps){
				if(productTypes.contains(m.Product_Name__c)){
					Set<Id> s = oppTaskMapping.get(m.Task_Definition__c) != null ? oppTaskMapping.get(m.Task_Definition__c) : new Set<Id>();
					s.add(oppID);
					oppTaskMapping.put(m.Task_Definition__c, s);
				}
			}
		}
		
		List<Task> newTasks = new List<Task>();
		if(oppTaskMapping.size() > 0){
			
			for(String defName : oppTaskMapping.keyset()){
				Opportunity_Task_Definition__c def = OpportunityTaskDefinitionMap.get(defName);
				
				if(def == null) continue;
				
				for(Id oppID : oppTaskMapping.get(defName)){
					Opportunity opp = opps.get(oppID);
					Order__c oppOrder = ordersByOpportunityID.get(oppID);
					User oppOwner = users.get(opp.OwnerId);
					Id seID = salesEngineersByOppID.get(oppID);
					
					System.debug('Processing opportunity product task for Opportunity: "' + opp.Id + '" Definition: ' + defName);
					
					User u = (seID != null && users.get(seID) != null) ? users.get(seID) : getTaskOwnerByOpportunityOwnerRegion(users.get(opp.OwnerId));
					
					createTaskAndSendEmail(replaceInlineOppProdTaskText(def.Task_Subject__c, opp, oppOrder), replaceInlineOppProdTaskText(def.Task_Description__c, opp, oppOrder), opp, oppOrder, u, newTasks, def.Task_Type__c, Integer.valueOf(def.Task_Activity_Date_Offset__c), Integer.valueOf(def.Task_Reminder_Date_Offset__c));
				}
			}
		}
		
		for(Id oppID : getSIPOppIDs(opps, 'SIP Trunking Sessions%')){
			Opportunity opp = opps.get(oppID);
			Order__c oppOrder = ordersByOpportunityID.get(oppID);
			User oppOwner = users.get(opp.OwnerId);
			Id seID = salesEngineersByOppID.get(opp.Id);
			
			User u = (seID != null && users.get(seID) != null) ? users.get(seID) : getTaskOwnerByOpportunityOwnerRegion(users.get(opp.OwnerId));
			
			createTaskAndSendEmail('Complete SIP Vendor Checklist', 'SIP Solutions Sale - Vendor Contact Required: ' + opp.Name, opp, oppOrder, u, newTasks, 'SIP Solutions Sale', 1, 3);
		}
		
		if(newTasks.size() > 0)
			Database.insert(newTasks);
	}
	
	private static String replaceInlineOppProdTaskText(String value, Opportunity opp, Order__c order){
		return (value != null) ? replaceInlineTaskText(replaceInlineTaskText(value, 'Opportunity', opp), 'Order__c', order) : value;
	}
    
    private static Set<Id>/*Map<Id, List<OLI__c>>*/ getSIPOppIDs(Map<Id, Opportunity> opps, String sPrdFields){
    	Set<Id> retval = new Set<Id>();
		//Map<Id, List<OLI__c>> retval = new Map<Id, List<OLI__c>>();
    	for(OLI__c op : [select Id, OpportunityLocationConfiguration__r.Opportunity_Location__r.Opportunity__c from OLI__c where OpportunityLocationConfiguration__r.Opportunity_Location__r.Opportunity__c in: opps.keyset() and OpportunityLocationConfiguration__r.Active__c = true and PP_Sales_Rate_Plan_Description__c LIKE:sPrdFields]){
    		Id oppID = op.OpportunityLocationConfiguration__r.Opportunity_Location__r.Opportunity__c;
			/*List<OLI__c> ops = retval.get(oppID) != null ? retval.get(oppID) : new List<OLI__c>();
    		ops.add(op);
    		retval.put(oppID, ops);*/
			retval.add(oppID);
    	}
    	return retval;
    }
	
	private static void createTaskAndSendEmail(String subject, String body, Opportunity opp, Order__c ord, User u, List<Task> newTaskList, String taskType, Integer activityDateOffset, Integer reminderDateOffset){
		newTaskList.add(new Task(Subject = subject
									,OwnerId = (u != null) ? u.Id : opp.OwnerId
									,Type = taskType
									,Description = body
									,WhatId = ord.Id
									,ActivityDate = Date.Today().addDays(activityDateOffset)
									,ReminderDateTime = Date.Today().addDays(reminderDateOffset)));
	
		if(u != null)
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
												ApexUtils.createEmailMessage(new String[]{u.Email}, null, subject, '<table><tr><td>' + body + '</td></tr><tr><td></td></tr></table>', true, null)
											});
	}
	/* End: Opportunity Product task reminders section */
	
	/* ICERT section */
	public static Map<Id,Id> createICertsFromClosedWonOpportunities(Set<Id> oppIds){
		Map<Id,Id> oppToCapProj = new Map<Id,Id>();
		for(Id oppId : oppIds){
			Map<String,Object> params = new Map<String,Object>{'OppId'=>oppId};
			Flow.Interview.Create_ICerts icertFlow = new Flow.Interview.Create_ICerts(params);
			icertFlow.start();
			object capProjId = icertFlow.getVariableValue('CapitalProjectId');
			if(capProjId != null)
				oppToCapProj.put(oppId,string.valueOf(capProjId));
		}
		return oppToCapProj;
	}
	/* End: ICERT section */

	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_OpportunityTriggerTaskCreation(); }
}