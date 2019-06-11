global class IntegrationEndpoint implements TestUtils.ITestableClass {

	global class IntegrationResultWrapper {
		webservice Id ID;
		webservice String ExternalID;
		webservice Boolean Success;
		webservice List<String> Errors;
		
		public IntegrationResultWrapper(Id id, String externalId){
			this.ID = id;
			this.ExternalID = externalID;
			Errors = new List<String>();
			Success = true;
		}
	}
	
	global class SubscriberUpdate{
		webservice String SubscriberID;
		webservice String Status;
		webservice String CollectionRepNTID;
		webservice Integer ReportingCompanyID;
		webservice Boolean PastDue;
		webservice Boolean Suspended;
	}
	
	webservice static List<IntegrationResultWrapper> UpdateSubscribers(List<SubscriberUpdate> subscribers){
		List<IntegrationResultWrapper> retval = new List<IntegrationResultWrapper>();
		
		Map<String, SubscriberUpdate> updatesBySubscriberID = new Map<String, SubscriberUpdate>();
		for(SubscriberUpdate sub : subscribers)
			updatesBySubscriberID.put(sub.SubscriberID, sub);
		
	    RecordType rt = [select Id from RecordType where sObjectType = 'Customer_Setting__c' and DeveloperName = 'Reporting_Company'];
		Map<String, Id> reportingCompanyIDByExternalID = new Map<String, Id>();
		for(Customer_Setting__c setting : [select Id, External_ID__c from Customer_Setting__c where RecordTypeId =: rt.Id and External_ID__c != null])
			reportingCompanyIDByExternalID.put(setting.External_ID__c, setting.Id);
		
		List<Account> updatedAccounts = new List<Account>();
		//List<Service_Location__c> updatedLocs = new List<Service_Location__c>();
		List<Customer_Detail__c> updatedDetails = new List<Customer_Detail__c>();
		for(Customer_Detail__c detail : [select Id
												,ICC_Subscriber_ID__c
												,Integration_Status__c
												,(select Id, ICC_Account_Number__c from Accounts__r)
												/*,(select Id, ICC_Subscriber_ID__c from Service_Locations__r)*/
												from Customer_Detail__c
												where ICC_Subscriber_ID__c in : updatesBySubscriberID.keyset()]){
			SubscriberUpdate subUpdate = updatesBySubscriberID.get(detail.ICC_Subscriber_ID__c);
			
			if(subUpdate.Status != null && integrationUtils.inactiveSubscriberStatuses.contains(subUpdate.Status) && (detail.Integration_Status__c == null || !integrationUtils.inactiveSubscriberStatuses.contains(detail.Integration_Status__c))){
				detail.Inactive_Date__c = Date.today();
				for(Account a : detail.Accounts__r != null ? detail.Accounts__r : new List<Account>()){
					a.Type = 'Former Customer';
					//a.Account_Inactive_Date__c = Date.today();
					updatedAccounts.add(a);
				}
				/*for(Service_Location__c sLoc : detail.Service_Locations__r != null ? detail.Service_Locations__r : new List<Service_Location__c>()){
					sLoc.Active__c = false;
					sLoc.Inactive_Date__c = Date.today();
					updatedLocs.add(sLoc);
				}*/
			}
			detail.Integration_Status__c = subUpdate.Status;
			detail.Past_Due__c = subUpdate.PastDue;
			detail.Suspended__c = subUpdate.Suspended;
			detail.Reporting_Company__c = subUpdate.ReportingCompanyID != null ? reportingCompanyIDByExternalID.get(string.valueOf(subUpdate.ReportingCompanyID)) : null;
			if(string.IsEmpty(subUpdate.CollectionRepNTID))
				detail.Collection_Rep__c = null;
			else
				detail.Collection_Rep__r = new User(NTID__c = subUpdate.CollectionRepNTID);
			
			updatedDetails.add(detail);
		}
		
		Map<String, IntegrationResultWrapper> resultMap = new Map<String, IntegrationResultWrapper>();
		if(updatedAccounts.size() > 0){
			AccountTriggers.DisableIntegration = true;
			Database.SaveResult[] updateResults = Database.update(updatedAccounts, false);
			for(Integer i=0; i<updateResults.size(); i++) {
				String subID = updatedAccounts[i].ICC_Account_Number__c;
				IntegrationResultWrapper w = resultMap.get(subID) != null ? resultMap.get(subID) : new IntegrationResultWrapper(updatedAccounts[i].Id, subID);
				for(Database.Error e : updateResults[i].getErrors()){
					if(e.Message != null)
						w.Errors.add(e.Message);
				}
				w.Success &= w.Errors.size() == 0;
				resultMap.put(subID, w);
			}
		}
		
		/*if(updatedLocs.size() > 0){
			ServiceLocationTriggers.DisableIntegration = true;
			Database.SaveResult[] updateResults = Database.update(updatedLocs, false);
			for(Integer i=0; i<updateResults.size(); i++) {
				String subID = updatedLocs[i].ICC_Subscriber_ID__c;
				IntegrationResultWrapper w = resultMap.get(subID) != null ? resultMap.get(subID) : new IntegrationResultWrapper(updatedLocs[i].Id, subID);
				for(Database.Error e : updateResults[i].getErrors()){
					if(e.Message != null)
						w.Errors.add(e.Message);
				}
				w.Success &= w.Errors.size() == 0;
				resultMap.put(subID, w);
			}
		}*/
		
		CustomerDetailTriggers.IntegrationDisabled = true;
		Database.SaveResult[] updateResults = Database.update(updatedDetails, false);
		for(Integer i=0; i<updateResults.size(); i++) {
			String subID = updatedDetails[i].ICC_Subscriber_ID__c;
			IntegrationResultWrapper w = resultMap.get(subID) != null ? resultMap.get(subID) : new IntegrationResultWrapper(updatedDetails[i].Id, subID);
			for(Database.Error e : updateResults[i].getErrors()){
				if(e.Message != null)
					w.Errors.add(e.Message);
			}
			w.Success &= w.Errors.size() == 0;
			resultMap.put(updatedDetails[i].ICC_Subscriber_ID__c, w);
		}
		
		for(SubscriberUpdate sub : subscribers){
			IntegrationResultWrapper w = resultMap.get(sub.SubscriberID) != null ? resultMap.get(sub.SubscriberID) : new IntegrationResultWrapper(null, sub.SubscriberID);
			retval.add(w);
		}
		
		//Fire and forget the reactivate process
		/*Set<Id> inactivatedAccounts = new Map<Id, Account>([select Id from Account where ICC_Account_Number__c in: updatesBySubscriberID.keyset()
																					and Customer_Detail__r.Integration_Status__c in: integrationUtils.inactiveSubscriberStatuses]).keyset();
		Set<Id> inactivatedServiceLocs = new Map<Id, Service_Location__c>([select Id from Service_Location__c where ICC_Subscriber_ID__c in: updatesBySubscriberID.keyset()
																												and Customer_Detail__r.Integration_Status__c in: integrationUtils.inactiveSubscriberStatuses
																												and Account__c not in: inactivatedAccounts]).keyset();
		if(inactivatedAccounts.size() > 0)
			IntegrationUtils.reactivateAccounts(inactivatedAccounts);
		if(inactivatedServiceLocs.size() > 0)
			IntegrationUtils.reactivateServiceLocs(inactivatedServiceLocs);*/
		
		return retval;
	}
	
	webservice static List<Opportunity> GetOrderReindexingOpportunitiesBySubscriberID(List<String> subscriberIDs){
		Set<Id> accountIDs = new Set<Id>();
		for(Service_Location__c sLoc : [select Account__c from Service_Location__c where ICC_Subscriber_ID__c in : subscriberIDs])
			accountIDs.add(sLoc.Account__c);
		
		RecordType rt = [select Id from RecordType where sObjectType = 'Opportunity' and DeveloperName = 'Order_Reindexing'];
		Map<Id, Account> accountsByID = new Map<Id, Account>([select Id
																	,(select Id
																			,Name
																			,RecordTypeId
																			,Account.Id
																			,Account.ICC_Account_Number__c
																		from Opportunities where RecordTypeId =: rt.Id)
																	from Account where ICC_Account_Number__c in : subscriberIDs or Id in : accountIDs]);
		
		Map<Id, Opportunity> oppsByAccountID = new Map<Id, Opportunity>();
		for(Account a : accountsByID.values()){
			for(Opportunity opp : a.Opportunities != null ? a.Opportunities : new List<Opportunity>())
				oppsByAccountID.put(opp.AccountId, opp);
		}
		
		Map<Id, Opportunity> newOppsByAccountID = new Map<Id, Opportunity>();
		for(Id id : accountsByID.keyset()){
			if(oppsByAccountID.get(id) == null){
				newOppsByAccountID.put(id, new Opportunity(
													Name = 'Order Reindexing'
													,AccountId = id
													,RecordTypeId = rt.Id
													,Type = 'Existing'
													//,StageName = OpportunityUtils.STAGE_CLOSED_WON
													,StageName = OpportunityUtils.STAGE_5
													,CloseDate = Date.today()
													,Bypass_Validation__c = true
												));
			}
		}
		
		if(newOppsByAccountID.size() > 0){
			insert newOppsByAccountID.values();
			for(Id id : newOppsByAccountID.keyset())
				oppsByAccountID.put(id, newOppsByAccountID.get(id));
		}
		
		return [select Id, Account.ICC_Account_Number__c from Opportunity where Id in: oppsByAccountID.values()];
	}
	
	webService static Id SendExternalOpportunityDocusignDocument(Id opportunityID, String processConfigName){
		Id statusID = null;
		
		List<Opportunity> opp = [select Id, Owner.Id, Owner.IsActive, Owner.Email, Owner.Name, Owner.Manager.Id, Owner.Manager.IsActive, Owner.Manager.Email, Owner.Manager.Name, StageName from Opportunity where Id =: opportunityID];
		if(opp.size() == 0) return null;
		
		List<OpportunityContactRole> ocr = [select Contact.Id, Contact.Name, Contact.Email from OpportunityContactRole where OpportunityId =: opportunityID and Role = 'Order Confirmation' and Contact.Email != null limit 1];
		User counterSigner = (opp[0].Owner.ManagerId != null && opp[0].Owner.Manager.IsActive) ? opp[0].Owner.Manager : opp[0].Owner;
		
		String pdfKey = CustomSettingUtils.getSingleProcessConfigurationValue(processConfigName, 'PDFKey', false);
		String emailSubject = CustomSettingUtils.getSingleProcessConfigurationValue(processConfigName, 'Subject', false);
		String emailBody = CustomSettingUtils.getSingleProcessConfigurationValue(processConfigName, 'Body', false);
		String title = CustomSettingUtils.getSingleProcessConfigurationValue(processConfigName, 'Title', false);
		
		String cwName = CustomSettingUtils.getSingleProcessConfigurationValue('UploadContentSalesChannelLibrary-Opportunity', [select Id, Sales_Channel__c from User where Id = : opp[0].OwnerId].Sales_Channel__c, true);
		List<ContentWorkspace> cw = [Select Id, Name from ContentWorkspace where Name =: cwName limit 1];
		if(ocr.size() > 0 && !String.isEmpty(pdfKey) && !String.isEmpty(emailSubject) && !String.isEmpty(title) && cw.size() > 0){
			
			String genPDFURL = '/apex/ProposalGeneratePDF?id=' + opportunityID + '&recipient=' + ocr[0].Contact.Id + '&document=' + pdfKey + '&rand=' + Math.random();
			Blob pageBytes = new Pagereference(genPDFURL).getContent();
			
			if(pageBytes.size() > 0){
				ContentVersion cv = new ContentVersion(
										Opportunity__c = opportunityID
										,VersionData = pageBytes
										,FirstPublishLocationId = cw[0].Id
										,Asset_Type__c = 'Sales Forms and Pricing'
										,Asset_SubType__c = 'Technical Supporting Documents'
										,PathOnClient = title + '.pdf'
										,Title = title
									);
				
				DSUtils.EnvelopeRequest er = new DSUtils.EnvelopeRequest(emailSubject, emailBody, null);
				DSUtils.DocuSignContent dsc = er.AddDocument(cv);
				dsc.AddStandardTabs();
				er.Signers.add(new DSUtils.DSContact(ocr[0].Contact));
				er.CounterSigner = new DSUtils.DSContact(counterSigner);
				
				DSUtils.EnvelopeSendResult result = DSUtils.Send(er);
				System.debug('Errors: ' + result.Errors);
				statusID = DSUtils.CreateDocusignStatusRecord(result, er, new Set<Id>{opportunityID});
				
				//insert cv;
				
				/*//If we've succeeded, update the opportunity status
				if(statusID != null && opp[0].StageName == OpportunityUtils.STAGE_CONTRACT_NEGOTIATION)
				{
					opp[0].StageName = OpportunityUtils.STAGE_CONTRACT_DELIVERED;
					Database.update(opp, false);
				}*/
			}
		}
		
		return statusID;
	}
	
	webservice static List<Building__c> GetServingBuildings(){
		return [Select Id,LSO_CLLI__c From Building__c Where Building_Type__c = 'ILEC LSO: Collocated' or Building_Type__c = 'ILEC Remote Switch' or Building_Type__c = 'ILEC LSO: Off Footprint' or Building_Type__c ='ILEC LSO: Extended' or Building_Type__c = 'ILEC LSO: Extended Special' ];
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_IntegrationEndpoint(); }
}