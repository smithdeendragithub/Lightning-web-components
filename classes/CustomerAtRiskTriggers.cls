public with sharing class CustomerAtRiskTriggers{

	public static void CustomerAtRiskModified(List<Customer_At_Risk__c> tNew, List<Customer_At_Risk__c> tOld, Boolean isUpdate, Boolean isBefore){
		Map<Id, Customer_At_Risk__c> tNewMap = new Map<Id, Customer_At_Risk__c>(tNew);
		Map<Id, Customer_At_Risk__c> tOldMap = tOld != null ? new Map<Id, Customer_At_Risk__c>(tOld) : new Map<Id, Customer_At_Risk__c>();
		
		List<Note> notesToInsert = new List<Note>();
		for(Customer_At_Risk__c car : tNewMap.values()){
			if(tOldMap.containsKey(car.Id)){
				if(car.Actions_Taken_to_Resolve__c != tOldMap.get(car.id).Actions_Taken_to_Resolve__c && !String.isEmpty(car.Actions_Taken_to_Resolve__c)){
					notesToInsert.add(GetNoteFromAction(car.Actions_Taken_to_Resolve__c,car.id));
				}
			}
			else{
				if(!String.isEmpty(car.Actions_Taken_to_Resolve__c)){
					notesToInsert.add(GetNoteFromAction(car.Actions_Taken_to_Resolve__c,car.id));
				}
			}
		}
		
		if(notesToInsert.size() > 0)
			insert notesToInsert;
	}
	
	private static Note GetNoteFromAction(String s, Id customerAtRiskID){
		Note n = new Note();
		n.Body = s;
		n.Title = 'Action taken ' + Datetime.now();
		n.ParentId = customerAtRiskID;
		return n;
	}
}