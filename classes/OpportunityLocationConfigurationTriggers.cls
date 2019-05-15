public with sharing class OpportunityLocationConfigurationTriggers {
	
	public static void OpportunityLocationConfigurationModified(List<OpportunityLocationConfiguration__c> tNew, List<OpportunityLocationConfiguration__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
		if(!ApexUtils.executeTriggerMethods('OpportunityLocationConfiguration__c', isBefore, false)) return;
		
		if(isBefore){
			if(isDelete){
				//Delete opp prods
				delete [select Id from Opportunity_Product__c where Solution__c in: tOld];
			}
			else{
				updateAccessFields(tNew);
			}
		}
		else{
			if(!isDelete){
				if(isUpdate){
					updateOpportunityProducts(tNew); 
					updateOpportunityProductStatus(tNew);
				}
			}
			
			ApexUtils.afterTriggerComplete('OpportunityLocationConfiguration__c', false);
		}
	}

	private static void updateAccessFields(List<OpportunityLocationConfiguration__c> tNew){
		Map<Id, List<OLI__c>> oppSolOLIMap = getOLIsByConfigList(tNew);
		
		Set<Id> ol = new Set<Id>();
		for(OpportunityLocationConfiguration__c  olc : tNew) {
			ol.add(olc.Opportunity_Location__c);
		}
		
		Map<Id, Opportunity_Location__c> bAccess = new Map<Id, Opportunity_Location__c>();
		for(Opportunity_Location__c opLoc : [select Id, Service_Location__r.Location__r.Building__r.Id from Opportunity_Location__c where Id in: ol])
			bAccess.put(opLoc.Service_Location__r.Location__r.Building__r.Id, opLoc);
		
		if(bAccess.size() > 0){
			Map<Id, Building_Access_Availability__c> baaMap = new Map<Id, Building_Access_Availability__c>([select Building__c
																												,Minimum_Required_Revenue__c
																												,Access_Technology__r.Id
																												,Access_Technology__r.Access_Technology_ID__c
																												,Access_Technology__r.Name
																												,Building__r.Net_Classification__c
																												from Building_Access_Availability__c
																												where Building__c in : bAccess.keyset()]);
			
			for(OpportunityLocationConfiguration__c config : tNew) {
				
				List<OLI__c> olis = oppSolOLIMap.get(config.Id) != null ? oppSolOLIMap.get(config.Id) : new List<OLI__c>();
				
				List<Building_Access_Availability__c> buildAccess = new List<Building_Access_Availability__c>(); 
				for(Opportunity_Location__c opLoc : bAccess.values()){
					for(Building_Access_Availability__c access : baaMap.values()){
						if(opLoc.Service_Location__r.Location__r.Building__r.Id == access.Building__c)
							buildAccess.add(access);
					}
				}
				
				String preferredAccessType = null;
				if(buildAccess.size() > 0 && olis.size() > 0){
					//Get the first preferredAccessType
					for(Building_Access_Availability__c bAvailable : buildAccess){
						//EOF if any of the following are true
						//
						//On-net = EOF preferredAccessType
						//Near-net & Hurdle met = EOF preferredAccessType
						//Other Net Class & Hurdle met, if an EOF then = EOF preferredAccessType
						if(bAvailable.Building__r.Net_Classification__c == 'On-net'
							|| (bAvailable.Building__r.Net_Classification__c == 'Near-net' && bAvailable.Minimum_Required_Revenue__c <= config.MRC_Total__c)
							|| (bAvailable.Building__r.Net_Classification__c != 'On-net' && bAvailable.Building__r.Net_Classification__c != 'Near-net' && bAvailable.Minimum_Required_Revenue__c <= config.MRC_Total__c && bAvailable.Access_Technology__r.Access_Technology_ID__c == 2)){
							preferredAccessType = 'EOF';
							break;
						}
						
						//EOC if any of the following are true
						//
						//Near-net & Hurdle NOT met = EOC preferredAccessType
						//Other Net Class & NOT an EOF, but an EOC then = EOC preferredAccessType
						if((bAvailable.Building__r.Net_Classification__c == 'Near-net' && bAvailable.Minimum_Required_Revenue__c > config.MRC_Total__c)
							|| (bAvailable.Building__r.Net_Classification__c != 'On-net' && bAvailable.Building__r.Net_Classification__c != 'Near-net' && bAvailable.Access_Technology__r.Access_Technology_ID__c == 1)){
							preferredAccessType = 'EOC';
							break;
						}
					}
				}
				
				Boolean nonPreferredPicked = false;
				if(preferredAccessType != null){
					for(OLI__c oli : olis)
						nonPreferredPicked |= (oli.AccessTechName__c != preferredAccessType);
				}
				
				config.nonPreferredAccess__c = nonPreferredPicked;
				config.PreferredAccessType__c = preferredAccessType;
			}
		}
	}
	
	private static Map<Id,List<OLI__c>> getOLIsByConfigList(List<OpportunityLocationConfiguration__c> tNew){
		Map<Id, List<OLI__c>> retval = new Map<Id, List<OLI__c>>();
		for(OLI__c o : [select AccessTechName__c
								,OpportunityLocationConfiguration__c
								from OLI__c
								where OpportunityLocationConfiguration__c in: tNew and PP_Package_Feature__c = false and AccessTechName__c != null
								order by PP_Product_Family_Sort__c, PP_Sales_Product_Sort__c, PP_Feature_Grouping_Sort__c, PP_Sales_Rate_Plan_Description_Sort__c]){
			List<OLI__c> olis = (retval.get(o.OpportunityLocationConfiguration__c) != null) ? retval.get(o.OpportunityLocationConfiguration__c) : new List<OLI__c>();
			olis.add(o);
			retval.put(o.OpportunityLocationConfiguration__c, olis);
		}
		return retval;
	}
	
	private static RecordType cpqEntryRecordType = null;
	private static Map<Id, Opportunity_Product_Sales_Product__c> spMap = null;
	private static Map<string, Opportunity_Product_Sales_Product__c> spMapName = null;
	private static void updateOpportunityProducts(List<OpportunityLocationConfiguration__c> tNew){
		//MNK added to reduce SOQL calls
        Map<String, currencytype> conversionRateMap = new Map<String, currencytype>();
        for (currencyType ct: [SELECT isocode, conversionrate FROM currencytype]) {
        	conversionRateMap.put(ct.IsoCode,ct);        
        }
        
		//Get Record type for CPQ Entry
		if(cpqEntryRecordType == null)
			cpqEntryRecordType = [Select id From  RecordType  Where Name = 'CPQ Entry' and SobjectType = 'Opportunity_Product__c' Limit 1];
		
		//Get any existing OpportunityProducts for this solution
		Map<Id, Map<Id, Opportunity_Product__c>>  solOppProducts = new Map<Id, Map<Id, Opportunity_Product__c>>();
		for(Opportunity_Product__c op : [select Id, SPC_Product_Id__c, Opportunity_Product_Sales_Product__r.SPC_Product__c, Solution__c from Opportunity_Product__c where Solution__c in: tNew and RecordTypeId = :cpqEntryRecordType.Id]){
			Map<Id, Opportunity_Product__c> m = (solOppProducts.get(op.Solution__c) != null) ? solOppProducts.get(op.Solution__c) : new Map<Id, Opportunity_Product__c>();
			m.put(op.Opportunity_Product_Sales_Product__r.SPC_Product__c, op);
			solOppProducts.put(op.Solution__c, m);
		}
		
		if(spMap == null){
			spMap = new Map<id,Opportunity_Product_Sales_Product__c>();
			spMapName = new Map<string,Opportunity_Product_Sales_Product__c>();
			for(Opportunity_Product_Sales_Product__c opsp :[Select SPC_Product__c,Id,Name From Opportunity_Product_Sales_Product__c Order by Name, SPC_Product__c]){
				spMap.put(opsp.SPC_Product__c,opsp);
				spMapName.put(opsp.Name,opsp);
			}
		}
		
		Map<Id, OpportunityLocationConfiguration__c> tNewMap = new Map<Id, OpportunityLocationConfiguration__c>(tNew);
		Map<Id, Set<Id>> solProdMap = new Map<Id, Set<Id>>();
		Decimal conversionRate = 1.00;
		List<Opportunity_Product__c> upsertOPs = new List<Opportunity_Product__c>();
		for(AggregateResult ar : [select Sum(MRC_Total__c) SumMRC
										,Sum(NRC_Total__c) SumNRC
										,SPC_Sales_Product__c SPId
										,OpportunityLocationConfiguration__c
										,OpportunityLocationConfiguration__r.Opportunity_Location__r.Service_Location__c
										,OpportunityLocationConfiguration__r.Opportunity_Location__r.Order__r.Opportunity__c
										,PP_Sales_Product__c
										,CurrencyIsoCode
										from OLI__c
										where OpportunityLocationConfiguration__c in :tNewMap.keyset()
										group By SPC_Sales_Product__c, OpportunityLocationConfiguration__c, OpportunityLocationConfiguration__r.Opportunity_Location__r.Service_Location__c, OpportunityLocationConfiguration__r.Opportunity_Location__r.Order__r.Opportunity__c, PP_Sales_Product__c, CurrencyIsoCode]){
			
			string solutionId = string.valueOf(ar.get('OpportunityLocationConfiguration__c'));
			string currencyIsoCode = string.valueOf(ar.get('CurrencyIsoCode'));
			Set<Id> prodSet = (solProdMap.get(solutionId) != null) ? solProdMap.get(solutionId) : new Set<Id>();
			prodSet.add(string.valueOf(ar.get('SPId')));
			solProdMap.put(solutionId, prodSet);
			
			Map<Id, Opportunity_Product__c> opMap = solOppProducts.get(solutionId);
			Opportunity_Product__c op = (opMap != null) ? opMap.get(string.valueOf(ar.get('SPId'))) : null;
			if(op != null)
				op.Active__c = tNewMap.get(solutionId).Active__c;
			else{
				Opportunity_Product_Sales_Product__c opsp = null;
				if(string.valueOf(ar.get('SPId')) != null)
					opsp = spMap.get(string.valueOf(ar.get('SPId')));
				else{
					opsp = spMapName.get(string.valueOf(ar.get('PP_Sales_Product__c')));
					if(opsp == null) opsp = spMapName.get('Expired Product');
				}
				
				if(opsp != null){
					op = new Opportunity_Product__c(Primary_Service_Location__c = string.valueOf(ar.get('Service_Location__c'))
													,Opportunity__c = string.valueOf(ar.get('Opportunity__c'))
													,Opportunity_Product_Sales_Product__c = opsp.Id
													,RecordTypeId = cpqEntryRecordType.Id
													,Sales_Product__c = opsp.Name
													,Solution__c = string.valueof(ar.get('OpportunityLocationConfiguration__c')));
				}
			}
			
			if(op != null){
           		conversionRate = conversionRateMap.get(currencyIsoCode).conversionRate;
 				//conversionRate = [SELECT conversionrate FROM currencytype WHERE isocode = :currencyIsoCode].conversionRate;
				op.MRC__c = decimal.valueOf(string.valueof(ar.get('SumMRC')))*conversionRate;
				op.NRC__c = decimal.valueOf(string.valueof(ar.get('SumNRC')))*conversionRate;
				//op.MRC__c = decimal.valueOf(string.valueof(ar.get('SumMRC')));
				//op.NRC__c = decimal.valueOf(string.valueof(ar.get('SumNRC')));
				
				upsertOPs.add(op);
			}
		}
		
		//Delete opportunity products if any OLIs are on the solution and the product sets don't match
		List<Opportunity_Product__c> deleteOPs = new List<Opportunity_Product__c>();
		for(Id solID : solOppProducts.keyset()){
			for(Opportunity_Product__c op : solOppProducts.get(solID).values()){
				Set<Id> prodSet = (solProdMap.get(solID) != null) ? solProdMap.get(solID) : null;
				if(op.SPC_Product_Id__c != null && (prodSet == null || !prodSet.contains(op.SPC_Product_Id__c)))
					deleteOPs.add(op);
			}
		}
		
		if(upsertOPs.size() > 0) upsert upsertOPs;
		if(deleteOPs.size() > 0) delete deleteOPs;
	}
	
	private static void updateOpportunityProductStatus(List<OpportunityLocationConfiguration__c> tNew){
		
		Map<Id, Id> SolServLocs = new Map<Id, Id>();
		for(OpportunityLocationConfiguration__c oloc : [select Id, Opportunity_Location__r.Service_Location__c from OpportunityLocationConfiguration__c where Id in: tNew])
			SolServLocs.put(oloc.Id, oloc.Opportunity_Location__r.Service_Location__c);
		
		List<Id> activeSolOpps = new List<Id>();
		List<Id> activeSolServLocs = new List<Id>();
		Map<Id, OpportunityLocationConfiguration__c> inactiveSols = new Map<Id, OpportunityLocationConfiguration__c>();
		for(OpportunityLocationConfiguration__c sol : tNew){
			if(sol.Active__c){
				activeSolOpps.add(sol.OpportunityId__c);
				if(SolServLocs.get(sol.Id) != null)
					activeSolServLocs.add(SolServLocs.get(sol.Id));
			}
			else
				inactiveSols.put(sol.Id, sol);
		}
		
		//Get opportunity products that are manual and active
		//Get opportunity products that are cpq entered and active, that need to be inactive
		List<Opportunity_Product__c> oppProds = [select Id from Opportunity_Product__c
													where Active__c = true
													and ((Solution__c in :inactiveSols.values() and RecordType.Name = 'CPQ Entry')
														or (Opportunity__c in : activeSolOpps and Primary_Service_Location__c in :activeSolServLocs and RecordType.Name = 'Manual Entry'))];
		for(Opportunity_Product__c op : oppProds)
			op.Active__c = false;
		
		update oppProds;
	}
}