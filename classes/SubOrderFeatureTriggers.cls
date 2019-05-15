public with sharing class SubOrderFeatureTriggers {
	
   public static void SubOrderFeatureModified(List<Sub_Order_Feature__c> tNew, List<Sub_Order_Feature__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('Sub_Order_Feature__c', isBefore, false)) return;
	   	
    	if(isBefore){
			if(isDelete)
				preventCompletedWorkstepFeatureDeletion(tOld);
    	}
    	else{
    		Map<Id, Sub_Order_Feature__c> tOldMap = tOld != null ? new Map<Id, Sub_Order_Feature__c>(tOld) : new Map<Id, Sub_Order_Feature__c>();
            updateWorkstep(tNew, tOldMap, isDelete);
    		
			ApexUtils.afterTriggerComplete('Sub_Order_Feature__c', false);
    	}
    }
	
	private static void updateWorkstep(List<Sub_Order_Feature__c> tNew, Map<Id, Sub_Order_Feature__c> tOldMap, Boolean isDelete) {
		List<Sub_Order_Feature__c> l = (isDelete ? tOldMap.values() : tNew);
		Set<Id> subordersSet = new Set<Id>();
		for (Sub_Order_Feature__c sof : l) {
			subordersSet.add(sof.Sub_Order__c);
		}
		
		if(subordersSet.size() > 0) {
			List<Workstep__c> wsUpdates = WorkstepUtils.calculateRelatedWorkstepOffsets(subordersSet);
		
			/*List<Workstep__c> workStep = new List<Workstep__c>();
			for(Sub_Order_Feature__c sof : l){
				for(Workstep__c ws : wsUpdates){
					if(sof.Sub_Order__c == ws.Sub_Order__c){
						workStep.add(ws);
					}
				}
				update workStep;
			}*/
			
			if(wsUpdates.size() > 0) update wsUpdates;
		}
	}
	
	private static void preventCompletedWorkstepFeatureDeletion(List<Sub_Order_Feature__c> tOld){
		
		Map<Id, Boolean> soMap = new Map<Id, Boolean>();		//SubOrderId=>ValidForDelete
		Map<Id, Set<Id>> deleteMap = new Map<Id, Set<Id>>();	//FeatureId=>Set<SubOrderId>
		for(Sub_Order_Feature__c sof : tOld){
			soMap.put(sof.Sub_Order__c, true);
			
			Set<Id> s = deleteMap.get(sof.Feature__c) != null ? deleteMap.get(sof.Feature__c) : new Set<Id>();
			s.add(sof.Sub_Order__c);
			deleteMap.put(sof.Feature__c, s);
		}
		
		Map<Id, Set<Id>> featureDurationMap = new Map<Id, Set<Id>>();	//WorkstepLibraryId=>Set<FeatureId>
		for(Feature_Duration__c fd : [select Feature__c, Workstep_Library__c from Feature_Duration__c where Feature__c in: deleteMap.keyset()]){
			Set<Id> s = featureDurationMap.get(fd.Workstep_Library__c) != null ? featureDurationMap.get(fd.Workstep_Library__c) : new Set<Id>();
			s.add(fd.Feature__c);
			featureDurationMap.put(fd.Workstep_Library__c, s);
		}
		
		if(featureDurationMap.size() > 0){
			for(Workstep__c ws : [select Id, Sub_Order__c, Workstep_Library__c from Workstep__c where Sub_Order__c in: soMap.keyset() and Workstep_Library__c in : featureDurationMap.keyset() and Status__c =: WorkstepUtils.STATUS_COMPLETE]){
				for(Id featureID : featureDurationMap.get(ws.Workstep_Library__c)){
					if(deleteMap.get(featureID).contains(ws.Sub_Order__c))
						soMap.put(ws.Sub_Order__c, false);
				}
			}
		}
		
		for(Sub_Order_Feature__c sof : tOld){
			if(soMap.get(sof.Sub_Order__c) != true)
				sof.addError('Sub-Order features cannot be removed once they are associated with a completed workstep.');
		}
	}
}