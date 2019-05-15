public with sharing class SubOrderGroupTriggers {
	
    public static void SubOrderGroupModified(List<Sub_Order_Group__c> tNew, List<Sub_Order_Group__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('Sub_Order_Group__c', isBefore, isDelete)) return;
		
        if(isBefore){
        }
        else{
        	Map<Id, Sub_Order_Group__c> tOldMap = isUpdate ? new Map<Id, Sub_Order_Group__c>(tOld) : new Map<Id, Sub_Order_Group__c>();
        	updateSubOrderFields(isDelete ? tOld : tNew, tOldMap);
        	
			ApexUtils.afterTriggerComplete('Sub_Order_Group__c', isDelete);
    	}
    }
    
    public static void updateSubOrderFields(List<Sub_Order_Group__c> tNew, Map<Id, Sub_Order_Group__c> tOldMap){
    	
    	Set<Id> updateStatus = new Set<Id>();
    	Set<Id> updateProducts = new Set<Id>();
		
    	for(Sub_Order_Group__c sog : tNew){
    		Sub_Order_Group__c sogOld = tOldMap.get(sog.Id);
			Boolean newOrMoved = (sogOld == null || sog.Sub_Order__c != sogOld.Sub_Order__c);
			getSubOrdersToUpdate(newOrMoved || sog.Status__c != sogOld.Status__c, sog, sogOld, updateStatus);
			getSubOrdersToUpdate(newOrMoved || sog.Product__c != sogOld.Product__c, sog, sogOld, updateProducts);
    	}
		
		if(updateStatus.size() > 0)
    		OrderUtils.refreshOrderStatusesBySubOrderID(updateStatus);
		
		if(updateProducts.size() > 0)
			setSubOrderExternalProducts(updateProducts);
    }
	
	private static void getSubOrdersToUpdate(Boolean updated, Sub_Order_Group__c sog, Sub_Order_Group__c sogOld, Set<Id> out){
		if(updated){
			out.add(sog.Sub_Order__c);
			if(sogOld != null) out.add(sogOld.Sub_Order__c);
		}
	}
    
	private static void setSubOrderExternalProducts(Set<Id> soIDs){
    	List<Sub_Order__c> soUpdates = new List<Sub_Order__c>();
		for(Sub_Order__c so : [select Id, External_Products__c, (select Id, Product__c from Sub_Order_Groups__r) from Sub_Order__c where Id in: soIDs]){
			Set<String> products = new Set<String>();
			for(Sub_Order_Group__c sog : so.Sub_Order_Groups__r != null ? so.Sub_Order_Groups__r : new List<Sub_Order_Group__c>())
				products.add(sog.Product__c);
			
			String productString = String.join(new List<String>(products), '; ');
			if(so.External_Products__c != productString){
				so.External_Products__c = productString;
				soUpdates.add(so);
			}
		}
		
		if(soUpdates.size() > 0) update soUpdates;
    }
}