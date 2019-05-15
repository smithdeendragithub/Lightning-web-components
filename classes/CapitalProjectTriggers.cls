public with sharing class CapitalProjectTriggers{

	private static final string TASK_COMMENT_TEMPLATE = 'This Address is being added to the Electric Lightwave network. This is a great opportunity to contact prospects and current customers to engage them in discussions. The {{OBJECTTYPE}} {{OBJECTNAME}} is associated to this building.';
	private static Boolean DisableTrigger = false;
	
	public static void CapitalProjectModified(List<Capital_Project__c> tNew, List<Capital_Project__c> tOld, Boolean isBefore, Boolean isUpdate, Boolean isDelete){
		if(DisableTrigger || !ApexUtils.executeTriggerMethods('Capital_Project__c', isBefore, isDelete)) return;
		if(!isBefore){
			if(!isDelete){
				if(isUpdate){
					Map<Id,Capital_Project__c> tOldMap = new Map<Id,Capital_Project__c>(tOld);
					Set<Id> cProjsToAutoGen = new Set<Id>();
					List<Capital_Project__c> cProjsToTask = new List<Capital_Project__c>();
					for(Capital_Project__c CProj : tNew){
						if(CProj.Auto_Generate__c && string.isEmpty(CProj.iCERT_ID__c)){
							cProjsToAutoGen.add(CProj.Id);
						}
						Capital_Project__c oldCproj = tOldMap.get(CProj.id);
						if(oldCproj != null && CProj.Status__c == 'Approved' && CProj.Status__c != oldCproj.Status__c)
							cProjsToTask.add(CProj);
					}
					if(cProjsToAutoGen.size() > 0)
						AutoGenerateICert(cProjsToAutoGen, UserInfo.getSessionId());
					if(cProjsToTask.size() > 0)
						CreateTasks(cProjsToTask);
				}
			}			
			ApexUtils.afterTriggerComplete('Capital_Project__c', isDelete);
		}
		else{
			if (!isDelete) {
				updateRelatedFields(tNew);
			}
		}
	}

	private static void CreateTasks(List<Capital_Project__c> CProjs){
		List<Task> tasks = new List<Task>();
		Set<Id> actIds = new Set<Id>();
		Set<Id> oppIds = new Set<Id>();
		for(Capital_Project__c cproj : CProjs){
			actIds.add(cproj.Account__c);
			oppIds.add(cproj.Opportunity__c);
		}
		string objectType = '';
		string objectName = '';
		List<string> stages = new List<string>{OpportunityUtils.STAGE_CLOSED_LOST,OpportunityUtils.STAGE_CONTRACT_SIGNED,OpportunityUtils.STAGE_4};
		Map<Id,Account> acts = new Map<Id,Account>([select Id, Name, OwnerId, (select Id, Name, OwnerId from Leads__r where Status != 'Unqualified'), Type from Account where id in :actIds]);
		Map<Id,Opportunity> opps = new Map<Id,Opportunity>([select Id, Name, OwnerId from Opportunity where id in :oppIds and StageName not in :stages]);
		for(Capital_Project__c cproj : CProjs){
			Account a = acts.get(cproj.Account__c);
			Opportunity o = opps.get(cproj.Opportunity__c);
			string Subject = 'Approved Capital Project - Please Review';
			string Type = 'Approved Capital Project';
			Date ActivityDate = Date.today().addDays(3);
			Date ReminderDate = date.today();
			boolean SetReminder = true;
			string Status = '';
			Id Owner = null;
			Id WhatId = null;
			string Description = '';
			
			Boolean addIt = false;
			if(a.Type == 'Customer'){
				Owner = o != null? o.OwnerId : a.OwnerId;
				WhatId = o != null? o.Id : a.Id;
				addIt = true;
				objectType = 'Opportunity';
				objectName = o.Name;
			}
			if(a.Type == 'Prospect'){
				if(o != null){
					Owner = o.OwnerId;
					WhatId = o.Id;
					addIt = true;
					objectType = 'Opportunity';
					objectName = o.Name;
				}
				else if(a.Leads__r.size() > 0){
					Owner = a.Leads__r[0].OwnerId;
					WhatId = a.Leads__r[0].Id;
					addIt = true;
					objectType = 'Lead';
					objectName = a.Leads__r[0].Name;
				}
				else if(o == null || a.Leads__r.size() == 0){
					Owner = a.OwnerId;
					WhatId = a.Id;
					addIt = true;
					objectType = 'Account';
					objectName = a.Name;
				}
			}
			if(addIt){
				Task t = TaskUtils.CreateTask(Owner, Subject, WhatId, Type, ActivityDate, ReminderDate, Description, SetReminder,Status,null);
				t.description = TASK_COMMENT_TEMPLATE.replace('{{OBJECTTYPE}}',objectType).replace('{{OBJECTNAME}}',objectName);
				tasks.add(t);
			}
		}

		if(tasks.size() > 0) insert tasks;
	}
	
	private static void updateRelatedFields(List<Capital_Project__c> tNew){
		Map<Id,Set<Capital_Project__c>> OppIdToCapitalProjs = new Map<Id,Set<Capital_Project__c>>();
		for(Capital_Project__c cproj : tNew){
			if(cproj.Opportunity__c != null){
				Set<Capital_Project__c> cprojs = OppIdToCapitalProjs.containsKey(cproj.Opportunity__c)? OppIdToCapitalProjs.get(cproj.Opportunity__c) : new Set<Capital_Project__c>();
				cprojs.add(cproj);
				OppIdToCapitalProjs.put(cproj.Opportunity__c, cprojs);
			}
		}
		for(Opportunity opp : [select id, (select Id from Orders__r where RecordTypeId = :Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Opportunity Order').getRecordTypeId()), AccountId from Opportunity where id in :OppIdToCapitalProjs.keyset()]){
			Set<Capital_Project__c> cprojs = OppIdToCapitalProjs.containsKey(opp.Id)? OppIdToCapitalProjs.get(opp.Id) : null;
			if(cprojs != null){
				for(Capital_Project__c cproj : cprojs){
					if(cproj != null){
						cproj.Order__c = opp.Orders__r != null && opp.Orders__r.size() > 0? opp.Orders__r[0].Id : null;
						cproj.Account__c = opp.AccountId;
					}
				}
			}
		}
	}
	
	@future(callout=true)
	public static void AutoGenerateICert(Set<Id> CProjIds, String session){
		try{
			DisableTrigger = true;
			//gather needed info
			Map<Id,Capital_Project__c> cProjs = new Map<Id,Capital_Project__c>([select Id
															,Opportunity__c
															,(select Id, Capital_Project__c, Building__c, Building__r.Net_Classification__c, Building__r.Building_CLLI__c from Capital_Project_Buildings__r)
															,Request_Title__c
															,Requested_Due_Date__c
															,Description__c 
														from Capital_Project__c
														where Id in :CProjIds
														and (iCERT_ID__c = null or iCERT_ID__c = '')]);
			Set<Id> oppIds = new Set<Id>();
			Set<Id> bldgIds = new Set<Id>();
			for(Capital_Project__c cproj : cProjs.values()){
				oppIds.add(cproj.Opportunity__c);
				for(Capital_Project_Building__c cbldg : cproj.Capital_Project_Buildings__r){
					bldgIds.add(cbldg.Building__c);
				}
			}
			
			Map<Id, Opportunity> opps = new Map<Id, Opportunity>([select Id
																,Product_Family__c
																,Product__c
																,AccountID
																,Account.Name
//																,Account.Account_Sales_Channel__c
																,Account.Owner.Sales_Channel__c
																,Sales_Channel__c
																,Contract_Signed_Date__c
																,Owner.NTID__c
																,Customer_Requested_Due_Date__c
																,CPQ_Total__c
																,CPQ_NRC_Total__c
																,Term__c
																from Opportunity where Id in : oppIds]);
			
			Set<Id> acctIDs = new Set<Id>();
			for(Opportunity opp : opps.values()){
				acctIds.add(opp.AccountId);
			}
			
			Map<Id, List<Opportunity_Location__c>> oppLocsByOppId = new Map<Id, List<Opportunity_Location__c>>();
			for(Opportunity_Location__c oLoc : [select Id
													,Opportunity__c
													,Service_Location__r.Id
													,Service_Location__r.Location__r.Building__r.Id
													,Service_Location__r.Location__r.Building__r.Address__c
													,Service_Location__r.Location__r.Building__r.Building_CLLI__c
													,Service_Location__r.Location__r.Building__r.Net_Classification__c
													,Service_Location__r.Location__r.Building__r.State__c
													,Service_Location__r.Location__r.Building__r.City__c
													,Order__r.Id
													,Order__r.SE_Notes__c
													,Order__r.Name
													,MRC_Total__c
													,NRC_Total__c
													,Term__c
													,(select Id, Bandwidth__c from OpportunityLocationConfigurations__r where Bandwidth__c != null and Active__c = true limit 1)
												from Opportunity_Location__c 
												where Opportunity__c in : oppIds and Service_Location__r.Location__r.Building__r.Id in : bldgIds and on_hold__c = false]){
													List<Opportunity_Location__c> olocs = oppLocsByOppId.containsKey(oLoc.Opportunity__c) ? oppLocsByOppId.get(oLoc.Opportunity__c) : new List<Opportunity_Location__c>();
													olocs.add(oLoc);
													oppLocsByOppId.put(oLoc.Opportunity__c, oLocs);
												}	
			
			Map<Id, Id> salesEngineerIDsByOppID = OpportunityUtils.getSalesEngineersByOppID(opps.keyset());
			Map<Id, Id> salesEngineerIDsByAcctID = OpportunityUtils.getSalesEngineersByAcctID(acctIds);
			Set<Id> userIds = new Set<Id>();
			userIds.addAll(salesEngineerIDsByAcctID.values());
			userIds.addAll(salesEngineerIDsByOppID.values());
			Map<Id, User> usersById =  OpportunityUtils.getUsers(opps.values(), userIds);
												
			//process
			List<integraWS.CreateICertParamsObj> icertParams = new List<integraWS.CreateICertParamsObj>();
			for(Capital_Project__c cProj : cProjs.values()){
				List<Opportunity_Location__c> olocs = oppLocsByOppId.get(cProj.Opportunity__c);
				if(cProj.Opportunity__c != null && olocs != null && olocs.size() > 0){
					Opportunity opp = opps.get(cProj.Opportunity__c);
					User u = usersById.get(salesEngineerIDsByOppID.get(opp.Id));
					if(u == null)
						u = usersById.get(salesEngineerIDsByAcctID.get(opp.AccountId));
					String AEID = '';
					if(u!=null)
						AEID = u.NTID__c;
					if(String.isEmpty(AEID))
						AEID = CustomSettingUtils.GetICertSE('Default');
				
					Opportunity_Location__c oloc = olocs[0];
					String Description = oloc.Order__r.SE_Notes__c;
					if(Description == null || Description == '')
						Description = 'This is an auto-generated iCERT. For additional information, please contact the SE entered as Primary Contact above.';
					cproj.Description__c = Description;
				
					Building__c bldg = oloc.Service_Location__r.Location__r.Building__r;
					String title = bldg.Net_Classification__c + ' {products} ' + oloc.Order__r.Name + ' Closed Won';
				
					cproj.Requested_Due_Date__c = opp.Customer_Requested_Due_Date__c;
					//cproj.OwnerId = u!=null? u.id :opp.OwnerId;
					cproj.Submitted_On__c = Date.today();
					integraWS.CreateICertParamsObj paramObj = iCertUtils.getCustomerBuildTemplate(opp.Account, opp, bldg, AEID, title, cproj.Description__c, true);
					cproj.Request_Title__c = paramObj.title.length() > 50 ? paramObj.title.substring(0,50) : paramObj.title;
					paramObj.ProductBandwidth = oloc != null && oloc.OpportunityLocationConfigurations__r != null && oloc.OpportunityLocationConfigurations__r.size() > 0 ? oloc.OpportunityLocationConfigurations__r[0].Bandwidth__c : '';
					paramObj.SalesForceID = cproj.Id;
					paramObj.Address = bldg.Address__c + ', ' + bldg.City__c;
					icertParams.add(paramObj);
				}
			}
			List<ICertUtils.SFICertView> response = ICertUtils.CreateICerts(iCertParams, session);
			if(response != null){
				for(ICertUtils.SFICertView v : response){
					if(v.Id <= 0){
						String msg = '';
						for(String s : v.Messages)
							msg += s + ' : ';
						CapitalProjectException ex = new CapitalProjectException('Id not returned by calout for CapitalProject: ' + v.SalesForceId);
						String detailString = IntegrationUtils.emailIntegrationException(ex, UserInfo.getUserEmail(), 'Failed to autogen iCert ' + msg);
						IntegrationUtils.createUpdateIntegrationErrors(new Set<Id>{v.SalesForceId}, detailString, null);
					}
					else{
						for(Capital_Project__c cProj : cProjs.values()){
							cProj.Auto_Generate__c = false;
							if(cProj.Id == v.SalesForceId)
								cProj.ICert_ID__c = string.valueOf(v.Id);
						}
					}
				}
				update cProjs.values();
			}
		}
		catch(Exception e){
			String detailString = IntegrationUtils.emailIntegrationException(e, UserInfo.getUserEmail(), 'iCert integration exception');
			IntegrationUtils.createUpdateIntegrationErrors(CProjIds, detailString, null);
		}
		DisableTrigger = false;
	}
	
	public class CapitalProjectException extends Exception{}
}