public with sharing class BuildingSalesProducts {
	public List<Building_Sales_Product__c> bsps {get;set;}

	public BuildingSalesProducts(ApexPages.StandardController stdController){
		ApexPages.Standardcontroller sc = stdController;
        sc.addFields(new List<String>{'serving_lso__r.id'});
		Building__c b = (Building__c)sc.getRecord();
		
		bsps = GetBuildingSalesProducts(b);
	}
	
	public List<Building_Sales_Product__c> GetBuildingSalesProducts(Building__c b){
		if(b.Serving_LSO__c != null)
			return [Select Id,SPC_Product__r.Name, Name From Building_Sales_Product__c Where Building__c = :b.serving_lso__r.id and SPC_Product__r.name != null Order by SPC_Product__r.Name];
		else
			return new List<Building_Sales_Product__c>();
	}
}