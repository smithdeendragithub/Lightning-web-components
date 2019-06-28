public without sharing class ExternalUserTriggers{
	
    public static Boolean SynchingFields = false;
	
    public static void ExternalUserModified(List<External_User__c> tNew, List<External_User__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('External_User__c', isBefore, isDelete)) return;
		
        if(isBefore){
        	if(isDelete){
            }else{
				setName(tNew);
				if(isUpdate){
					setContactFields(tNew);
				}
            }
        }
        else{
			ApexUtils.afterTriggerComplete('External_User__c', isDelete);
    	}
    }
	
	private static void setName(List<External_User__c> tNew){
		for(External_User__c eu : tNew)
			eu.Name = eu.First_Name__c + ' ' + eu.Last_Name__c;
	}
	
	private static void setContactFields(List<External_User__c> tNew){
		Map<Id, External_User__c> tNewMap = new Map<Id, External_User__c>(tNew);
		List<Contact> cList = [select Id, External_User__c from Contact where External_User__c in: tNew];
		for(Contact c : cList){
			External_User__c eu = tNewMap.get(c.External_User__c);
			c.FirstName = eu.First_Name__c;
			c.LastName = eu.Last_Name__c;
			c.Phone = eu.Phone__c;
			c.Email = eu.Email__c;
		}
		
		Boolean sVal = SynchingFields;
		SynchingFields = true;
		update cList;
		SynchingFields = sVal;
	}
}