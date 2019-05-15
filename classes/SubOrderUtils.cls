public without sharing class SubOrderUtils {
	
	public class SubOrder{
		public Id SubOrderID { get; set; }
		public Id BuildingID { get; set; }
		
		public SubOrder(){ }
		
		public SubOrder(Id soid, Id bid){
			SubOrderID = soid;
			BuildingID = bid;
		}
	}
	
	public static List<SubOrder> GetSubOrderBuilding(Id sOrd){
		List<SubOrder> sorder = new List<SubOrder>();
		for(Sub_Order__c so :[SELECT Id, Service_Location__r.Location__r.Building__r.Id FROM Sub_Order__c WHERE Id =: sOrd]){	
			if(so.Service_Location__r.Location__r.Building__r.Id != null)		
	    		sorder.add(new SubOrder(so.id, so.Service_Location__r.Location__r.Building__r.Id));
	    }
	    
		return sorder;
	}
	 
		public static List<Sub_Order__c> GetBuildingSubOrder(List<Id> bldId){
		List<Sub_Order__c> sorder = new List<Sub_Order__c>();
		for(Sub_Order__c so :[Select Sub_Order_Number__c, Status__c, Order__r.AccountName__c, Service_Location__c, SPC_Product__r.Name, 
    		Customer_Commit_Date__c, Name, Location__c, Id, Service_Location__r.Location__r.Building__r.Id, 
    		Order__r.Id, Order__r.RecordTypeId, Order__c
    		From Sub_Order__c WHERE Service_Location__r.Location__r.Building__r.Id =: bldId]){   	
			if(so.Service_Location__r.Location__r.Building__r.Id != null)		
	    		sorder.add(so);
	    }
	    
		return sorder;
	}
}