public without sharing class AttachmentTriggers{
	
 	public static void AttachmentAdded(List<Attachment> tNew, List<Attachment> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		if(isBefore){
			if(!isUpdate){
				changeNameFromDocusign(tNew);
			}
		}
		else{
			if(isDelete){
				//Nothing to do
			}
			else{
				if(!isUpdate){
					handleDocuSignAttachmentInsert(tNew);
				}
			}
		}
	}

	public static void changeNameFromDocusign(List<Attachment> tNew){
		Set<Id> parentIDs = new Set<Id>();
		for(Attachment att : tNew)
			parentIDs.add(att.parentID);
		
		List<Attachment> dsAttachments = new List<Attachment>();
		string cName = 'Contract ' + date.today().format().replaceAll('/','-');
		Map<Id, dsfs__DocuSign_Status__c> statusMap = new Map<Id, dsfs__DocuSign_Status__c>([select Id
														,CreatedById
														,PDF__c
														,dsfs__Completed_Date_Time__c
														,dsfs__Company__c
														,dsfs__Opportunity__c
														,dsfs__Opportunity__r.AccountId
														,dsfs__Opportunity__r.StageName
														,dsfs__Opportunity__r.RecordType.DeveloperName
													from dsfs__DocuSign_Status__c where Id in :parentIDs]);
		for(Attachment att : tNew){
			dsfs__DocuSign_Status__c ds = statusMap.get(att.parentID);
			if(ds != null){
				Opportunity opp = (ds.dsfs__Opportunity__c != null) ? ds.dsfs__Opportunity__r : null;
				if(opp != null){
					if(!((opp.StageName == OpportunityUtils.STAGE_CONTRACT_NEGOTIATION || opp.StageName == OpportunityUtils.STAGE_CONTRACT_SIGNED || opp.StageName == OpportunityUtils.STAGE_4) && opp.RecordType.DeveloperName == 'External')){
						att.Name = cName;

					}
				}
			}
		}
	}
	
	public static void handleDocuSignAttachmentInsert(List<Attachment> tNew){
		
		Set<Id> parentIDs = new Set<Id>();
		for(Attachment att : tNew)
			parentIDs.add(att.parentID);
		
		Map<Id, Attachment> dsAttachments = new Map<Id, Attachment>();
		Map<Id, Id> AcctIdByAttId = new Map<Id, Id>();
		Map<Id, Opportunity> externalOpps = new Map<Id, Opportunity>();
		Map<Id, dsfs__DocuSign_Status__c> statusMap = new Map<Id, dsfs__DocuSign_Status__c>([select Id
													,CreatedById
													,PDF__c
													,dsfs__Completed_Date_Time__c
													,dsfs__Company__c
													,dsfs__Opportunity__c
													,dsfs__Opportunity__r.AccountId
													,dsfs__Opportunity__r.StageName
													,dsfs__Opportunity__r.RecordType.DeveloperName
												from dsfs__DocuSign_Status__c where Id in :parentIDs]);
		for(Attachment att : tNew){
			dsfs__DocuSign_Status__c ds = statusMap.get(att.parentID);
			if(ds != null){
				Opportunity opp = (ds.dsfs__Opportunity__c != null) ? ds.dsfs__Opportunity__r : null;
				if(opp != null){
					if((opp.StageName == OpportunityUtils.STAGE_CONTRACT_NEGOTIATION || opp.StageName == OpportunityUtils.STAGE_CONTRACT_SIGNED || opp.StageName == OpportunityUtils.STAGE_4) && opp.RecordType.DeveloperName == 'External')
						externalOpps.put(opp.Id, opp);
					else{
						if(ds.dsfs__Company__c != null){
							AcctIdByAttId.put(att.Id, ds.dsfs__Company__c);
							dsAttachments.put(att.Id, att);
						}
						if(opp != null){
							AcctIdByAttId.put(att.Id, opp.AccountId);
							dsAttachments.put(att.Id, att);
						}
					}
				}
			}
		}
		
		Map<Id, Account> aMap = new Map<Id, Account>([select Owners_Sales_Channel__c, (select Id from Integra_Contracts__r) from Account where Id in : AcctIdByAttId.values()]);
		
		Map<Id, Integra_Contract__c> updatedContracts = new Map<Id, Integra_Contract__c>();
		List<FeedItem> feedItems = new List<FeedItem>();
		Map<Id, PDF__c> pdfs = new Map<Id, PDF__c>();
		Map<Id,Id> atIdToPDF = new Map<Id,Id>();
		for(Attachment att : dsAttachments.values()){
			dsfs__DocuSign_Status__c ds = statusMap.get(att.parentID);
			
			Set<Id> feedParents = new Set<Id>();
			if(ds.PDF__c != null){
				//feedParents.add(ds.PDF__c);
				PDF__c pdf = pdfs.get(ds.PDF__c) != null ? pdfs.get(ds.PDF__c) : new PDF__c(Id = ds.PDF__c);
				pdf.Name = 'Contract ' + date.today().format().replaceAll('/','-');
				pdf.DocuSign_Completed__c = true;
				pdfs.put(ds.PDF__c, pdf);
				atIdToPDF.put(att.Id, ds.PDF__c);
			}
			
			Account a = AcctIdByAttId.get(att.id) != null ? aMap.get(AcctIdByAttId.get(att.id)) : null;
			if(a != null && a.Integra_Contracts__r != null && a.Integra_Contracts__r.size() > 0){
				Integra_Contract__c ctrct = a.Integra_Contracts__r[0];
				ctrct.Integra_Signed_Date__c = ds.dsfs__Completed_Date_Time__c != null ? ds.dsfs__Completed_Date_Time__c.date() : null;
				updatedContracts.put(ctrct.Id, ctrct);
				
				feedParents.add(ctrct.Id);
			}
			
			for(Id fID : feedParents){
				feedItem fi = new feedItem();
				fi.ParentId = fID;
				fi.ContentData = att.Body;
				fi.ContentFileName = 'SIGNED:' + att.Name;
				fi.Title = 'SIGNED - ' + (string.isEmpty(att.Description) ? att.Name.replaceAll('\\.[a-zA-Z]{3,4}','') : att.Description);
				
				feedItems.add(fi);
			}
		}
		
		if(feedItems.size() > 0) insert feedItems;
		if(updatedContracts.size() > 0) update updatedContracts.values();
		if(pdfs.size() > 0) update pdfs.values();
		if(externalOpps.size() > 0) handleExternalOpportunityDocuSignAttachments(externalOpps);
		if(atIdToPDF.size() > 0) reparentDocusignedAttachments(atIdToPDF);
	}

	@future
	public static void reparentDocusignedAttachments(Map<Id,Id> attIdToParentId){
		List<Attachment> ats = [select Id from Attachment where Id in :attIdToParentId.keyset()];
		for(Attachment at : ats){
			at.parentId = attIdToParentId.get(at.Id);
		}
		update ats;
	}
	
	public static void handleExternalOpportunityDocuSignAttachments(Map<Id, Opportunity> opps){
		
		for(Opportunity opp: opps.values())
		{
			//opp.StageName = OpportunityUtils.STAGE_CLOSED_WON;
			opp.StageName = OpportunityUtils.STAGE_5;
			opp.Order_Status__c = 'Sales Complete';
		}
		update opps.values();
		
		asynch_integrateExternalOpportunities(opps.keyset(), UserInfo.getSessionId());
	}
	
	@future(callout=true)
	private static void asynch_integrateExternalOpportunities(Set<Id> oppIDs, string sessionID){
		integrateExternalOpportunities(oppIDs, sessionID);
	}
		
	public static void integrateExternalOpportunities(Set<Id> oppIDs, string sessionID){
		
		Set<Id> convertedOrderIDs = new Set<Id>();
		
		List<OpportunityLocationConfiguration__c> olcs = [select Id, Opportunity_Location__r.Order__c from OpportunityLocationConfiguration__c where Opportunity_Location__r.Order__r.Opportunity__c in: oppIDs limit 10];
		Datetime dt = Datetime.now();	//Process Order Properties added to the associated Orders after now
		for(Integer i=0; i<olcs.size() && i<10; i++){	//First 10 (callout limit)
			List<String> errors = integraWSEndpointMediator.integrationEnabled() ? integraWSEndpointMediator.Endpoint.CreateSolutionInstallOrderHeader(olcs[i].Id, sessionID, CustomSettingUtils.SFDCCallbackEndpoint).ListOfStringEntry : new List<String>();
			if(errors == null || errors.size() == 0) convertedOrderIDs.add(olcs[i].Opportunity_Location__r.Order__c);
		}
		
		if(convertedOrderIDs.size() > 0){
			List<Workplan_Template__c> wpt = [select Id from Workplan_Template__c where Name = 'External Opportunity Integration' and Active__c = true];
			List<Workstep_Template__c> wstList = [select Id, Name, OwnerId, Workstep_Library__c from Workstep_Template__c where Workplan_Template__c in: wpt];
			
			List<Workstep__c> wsList = new List<Workstep__c>();
			for(Order_Property__c op : [select Id, Name, Order__c from Order_Property__c where Order__c in: convertedOrderIDs and Type__c = 'Install Order' and CreatedDate >: dt]){
				for(Workstep_Template__c wst : wstList){
					String name = wst.Name;
					if(name.contains('{Order_Property__c}')) name = name.replace('{Order_Property__c}', op.Name);
					
					wsList.add(new Workstep__c(Order__c = op.Order__c
									,Name = name.length() > 80 ? name.substring(80) : name
									,OwnerId = wst.OwnerId
									,Template__c = wst.Id
									,Workstep_Library__c = wst.Workstep_Library__c));			//Let the triggers handle the other defaults
				}
			}
			
			if(wsList.size() > 0)
				insert wsList;
		}
	}
}