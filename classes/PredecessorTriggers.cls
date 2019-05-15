public with sharing class PredecessorTriggers {
	
	public static boolean DisableTrigger = false;
	
 	public static void PredecessorModified(List<Predecessor__c> tNew, List<Predecessor__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(DisableTrigger || !ApexUtils.executeTriggerMethods('Predecessor__c', isBefore, isDelete)) return;
		
        if(isBefore){
        	//Nothing to do
        }
        else{
        	Map<Id, Predecessor__c> tOldMap = tOld != null ? new Map<Id, Predecessor__c>(tOld) : new Map<Id, Predecessor__c>();
        	updateWorksteps(tNew, tOldMap, isDelete);
        	
			ApexUtils.afterTriggerComplete('Predecessor__c', isDelete);
    	}
    }
    
    private static void updateWorksteps(List<Predecessor__c> tNew, Map<Id, Predecessor__c> tOldMap, Boolean isDelete) {
		Set<Id> wsIDs = new Set<Id>();
		for (Predecessor__c p : isDelete ? tOldMap.values() : tNew) {
system.debug('pred in predTrigger: ' + p);			
			wsIDs.add(p.Dependent_Workstep__c);			
			wsIDs.add(p.Predecessor_Workstep__c);
		}		
		WorkstepUtils.updateWorkstepSuccessors(wsIDs);
	}
}