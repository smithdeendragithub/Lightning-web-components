/**************************************************************************************************

LeadTriggers.cls
*
Modifications: In 'preventInvalidUpdates' method added conditions to filter out 'Unqualified' Leads;
In 'updateProspectAccounts' method, deleted the process of syncing the Lead's ownership field and the associated Account's ownership
Developer Name Date Brief description
------------------- ---------- ------------------------------------------------------------
Elaine Gong 12/19/2017   SEAL-605  - Changes to Target Leads
**************************************************************************************************/

public without sharing class LeadTriggers {
	
    public static Boolean DisableTrigger = false;
	public static Boolean SynchronizingAccountFields = false;
	
	public static void LeadModified(List<Lead> tNew, List<Lead> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(DisableTrigger) return;
		
		Map<Id, Lead> tOldMap = tOld != null ? new Map<Id, Lead>(tOld) : new Map<Id, Lead>();
		if(isBefore){
			if(!isDelete){
				preventInvalidUpdates(tNew, tOldMap);
				if(!isUpdate){
					UpdateLeadWithGRData(tNew);
				}
			}
		}
		else{
			updateGeoResultsBusinesses(tNew, tOldMap);
			
			if(!isDelete){
				if(isUpdate){
					updateProspectAccounts(tNew, tOldMap);
				}
				OpportunityUtils.updateRelatedDateTasks(tNew, tOldMap);
			}
		}
	}

	private static void preventInvalidUpdates(List<Lead> tNew, Map<Id, Lead> tOldMap){
		
		Set<Id> invalidAccountIDs = new Set<Id>();
		Map<Id, Id> aMap = new Map<Id, Id>();
		for(Lead lNew : tNew){
			Lead lOld = tOldMap != null ? tOldMap.get(lNew.Id) : null;
			//Check if not converted, account is associated and we either changed that association or somehow "unconverted"
			// Add AND and OR condition so that new Lead can be created when old ones are marked as ‘Unqualified’
			if(!lNew.IsConverted && lNew.Related_Account__c != null && lNew.Status != 'Unqualified' && (lOld == null || lNew.Related_Account__c != lOld.Related_Account__c || lOld.IsConverted || lOld.Status == 'Unqualified')){
                if(aMap.containsKey(lNew.Related_Account__c)) invalidAccountIDs.add(lNew.Related_Account__c); 
                else aMap.put(lNew.Related_Account__c, lNew.Id); 
			}
		}
		
        //Added a condition in SQL statment to filter out the Unqualified Lead
		if(invalidAccountIDs.size() > 0 || aMap.size() > 0){
			for(Lead l : [select Id, Related_Account__c, Status, IsConverted from Lead where Related_Account__c in: aMap.keyset() and IsConverted = false and Id not in: tNew and Status != 'Unqualified']){
                if(aMap.containsKey(l.Related_Account__c)) invalidAccountIDs.add(l.Related_Account__c);
			}
			
			for(Lead lNew : tNew){
                ///chanchev
                //if(invalidAccountIDs.contains(lNew.Related_Account__c)) lNew.addError('Multiple unconverted leads cannot be associated with one Account.');
			}
		}
	}
	
	private static void UpdateLeadWithGRData(List<Lead> leads){
		Map<Id, Lead> grDataNeededLeads = new Map<Id, Lead>();
		for(Lead l: leads){
			if(DetermineGRDataNeeded(l))
				grDataNeededLeads.put(l.GeoResults_Business__c, l);
		}
		if(grDataNeededLeads.size() > 0 ){
			Map<Id, Georesults_business__c> grMap = new Map<Id, Georesults_business__c>();
			for(Georesults_business__c gb : [Select  g.busid__c,g.Id, g.Zip__c, g.TotalTelSpend__c, g.TotalTelSpendPerMonth__c, g.TotalTelSpendCategory__c, g.State__c, g.NAICS6__c,g.NAICS6desc__c, g.NAICS2__c, g.GeoResults_Family_ID__c, g.Family_Name__c, g.FamilyID__c, g.CleanAddress__c, g.City__c, g.BusinessType__c, g.BldgID__c,g.Emps__c,g.FortuneRank__c,g.High_Tech_Flag__c,g.TotalBW__c, g.ITSpend__c, g.ServingLEC__c,g.BldgType__c, g.BldgBus__c,g.BldgTotalBW__c, g.Lat__c,g.Long__c,GeoId__c,Gender__c,Exec_Title__c,Unit__c  From Georesults_business__c g Where id in :grDataNeededLeads.keyset()]){
				grMap.put(gb.id,gb);
			}
			
			//Fill in lead data with GR data from maps
			for(Lead l :grDataNeededLeads.values()){
				Georesults_Business__c gb = grMap.get(l.GeoResults_Business__c);
				if(gb != null){
					l.Total_Tel_Spend__c = gb.TotalTelSpend__c; 
					l.Street = String.isEmpty(gb.Unit__c) ? gb.CleanAddress__c : gb.CleanAddress__c + ' ' + gb.Unit__c;
					l.State = gb.State__c; 
					l.PostalCode = string.valueof(gb.Zip__c); 
					l.City = gb.City__c;
					/* changed to map from businesstype
					if(gb.NAICS6desc__c!= null && gb.NAICS6desc__c.length() > 40)
						l.Industry = gb.NAICS6desc__c.SubString(0,40);
					else
						l.Industry = gb.NAICS6desc__c;*/
					l.TelcoMonthlySpendBand__c = string.valueof(gb.TotalTelSpendPerMonth__c);
					l.NumberOfEmployees = integer.valueof(gb.Emps__c);
					l.Fortune_Rank__c = gb.FortuneRank__c;
					l.High_Tech_Flag__c = (gb.High_Tech_Flag__c == '1');
					l.Total_Bandwidth__c = gb.TotalBW__c;
					l.IT_Spend__c = gb.ITSpend__c;
					l.Local_Service_Provider__c = gb.ServingLEC__c;
					l.Building_Type__c = gb.BldgType__c;
					l.Total_Businesses_in_Building__c = gb.BldgBus__c;
					l.Total_Building_Bandwidth__c = gb.BldgTotalBW__c;
					l.Latitude__c = string.valueof(gb.Lat__c);
					l.Longitude__c = string.valueof(gb.Long__c);
					l.GeoResultsFamilyID__c = gb.GeoResults_Family_ID__c;
					l.GeoResults_Family__c = gb.GeoResults_Family_ID__c;
					if(gb.GeoId__c != null)
						l.Geo_Id__c = string.valueOf(gb.busid__c);
					l.TotalTelSpendPerMonth__c = gb.TotalTelSpendPerMonth__c;
					l.Industry = gb.BusinessType__c;
					l.Gender__c = gb.Gender__c;
					l.Title = gb.Exec_Title__c;
				}
			}
		}
	}
	
	private static Boolean DetermineGRDataNeeded(Lead l){
		return(l.LeadSource == 'Simplified Prospect Management' && l.GeoResults_Business__c != null);
	}
	
	private static void updateGeoResultsBusinesses(List<Lead> tNew, Map<Id, Lead> tOldMap){
		if(tNew == null){
			//isDelete
			tNew = tOldMap.values();
			tOldMap = new Map<Id, Lead>();
		}
		
		Map<Id, Georesults_business__c> grMap = new Map<Id, Georesults_business__c>();
        for(Lead lNew : tNew){
	        Lead lOld = tOldMap.get(lNew.Id);
			if((lOld == null && lNew.GeoResults_Business__c != null)
				|| (lOld != null
						&& (lOld.GeoResults_Business__c != lNew.GeoResults_Business__c
							|| lOld.ConvertedAccountId != lNew.ConvertedAccountId
							|| lOld.Status != lNew.Status))){
				if(lNew.GeoResults_Business__c != null) grMap.put(lNew.GeoResults_Business__c, null);
				if(lOld != null && lOld.GeoResults_Business__c != null) grMap.put(lOld.GeoResults_Business__c, null);
			}
        }
		
		if(grMap.size() > 0){
			grMap = new Map<Id, Georesults_business__c>([select Id, Account__c, (select ConvertedAccountId, Status from Leads__r) from Georesults_business__c where Id in: grMap.keyset()]);
			for(Georesults_business__c gb : grMap.values()){
				gb.Converted_Lead_Exists__c = false;
				gb.Open_Lead_Exists__c = false;
				gb.Unqualled_Lead_Exists__c = false;
				
				for(Lead l : (gb.Leads__r != null) ? gb.Leads__r : new List<Lead>()){
					gb.Account__c = (l.ConvertedAccountId != null && gb.Account__c == null) ? l.ConvertedAccountId : gb.Account__c;
					gb.Converted_Lead_Exists__c |= (l.Status == 'Converted');
					gb.Open_Lead_Exists__c |= (l.Status != 'Converted' && l.Status != 'Unqualified');
					gb.Unqualled_Lead_Exists__c |= (l.Status == 'Unqualified');
				}
			}
			
			if(grMap.size() > 0) update grMap.values();
		}
	}

    // SEAL – 605: Deleted updateOwners and syncOwner variables since no longer updating the Owner field
	private static void updateProspectAccounts(List<Lead> tNew, Map<Id, Lead> tOldMap){
		
		if(AccountTriggers.SynchronizingLeadFields) return;
		
		Map<Id, Lead> updateUnqualifiedFields = new Map<Id, Lead>();
		
		for(Lead lNew : tNew){
			Lead lOld = tOldMap != null ? tOldMap.get(lNew.Id) : null;
			if(!lNew.IsConverted && lNew.Related_Account__c != null){
				Boolean setUnqualifiedFields = (lOld == null && (lNew.Unqualified_Disposition__c != null
																|| lNew.Unqualified_Disp_Detail__c != null
																|| lNew.Unqualified_Disp_Other__c != null))
												|| (lOld != null && (lNew.Unqualified_Disposition__c != lOld.Unqualified_Disposition__c
																|| lNew.Unqualified_Disp_Detail__c != lOld.Unqualified_Disp_Detail__c
																|| lNew.Unqualified_Disp_Other__c != lOld.Unqualified_Disp_Other__c));
				if(setUnqualifiedFields) updateUnqualifiedFields.put(lNew.Related_Account__c, lNew);
			}
		}
		
		if(updateUnqualifiedFields.size() > 0){
			List<Account> accounts = [select Id from Account where ICC_Account_Number__c = null and Id in: updateUnqualifiedFields.keyset()/*)*/];
			for(Account a : accounts){
				if(updateUnqualifiedFields.get(a.Id) != null){
					Lead l = updateUnqualifiedFields.get(a.Id);
					a.Unqualified_Dispostion__c = l.Unqualified_Disposition__c;
					a.Unqualified_Disp_Detail__c = l.Unqualified_Disp_Detail__c;
					a.Unqualified_Disp_Other__c = l.Unqualified_Disp_Other__c;
				}
			}
			
			Boolean oSynch = SynchronizingAccountFields;
			Boolean oldVal = SecurityUtils.AllowTemporaryOwnershipUpdates;
			SynchronizingAccountFields = true;
			SecurityUtils.AllowTemporaryOwnershipUpdates = true;
			if(accounts.size() > 0) SecurityUtils.BypassProcesser.saveObjects(accounts, true);
			SecurityUtils.AllowTemporaryOwnershipUpdates = oldVal;
			SynchronizingAccountFields = oSynch;
		}
	}
}