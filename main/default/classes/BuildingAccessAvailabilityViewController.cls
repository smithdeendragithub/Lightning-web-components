public with sharing class BuildingAccessAvailabilityViewController {
	public List<Building_Access_Availability__c> baas {get;set;}
	
	public BuildingAccessAvailabilityViewController(ApexPages.StandardController stdController){
		ApexPages.Standardcontroller sc = stdController;
		Building__c b = (Building__c)sc.getRecord();
			
		baas = GetBAA(b);
	}
	
	public List<Building_Access_Availability__c> GetBAA(Building__c b){
		return [Select Id, Access_Technology__r.Name, Maximum_Bandwidth__c, Minimum_Required_Revenue__c, Status__c,Building__r.Net_Classification__c,Access_Technology__r.Client_Interface__c,Access_Technology__r.Friendly_Name__c 
                From Building_Access_Availability__c 
                Where building__c = :b.id and (Access_Technology__r.Name in ('EoF','10G CE Ring','10G CE Interface','DS1/DS3 SONET','10G DWDM','Zayo Ethernet','Zayo EPIC','Rogers','Comcast','Beanfield')
                OR Access_Technology__r.Name like 'Zayo IP%')];
	}
}