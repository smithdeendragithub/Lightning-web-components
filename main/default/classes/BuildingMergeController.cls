public with sharing class BuildingMergeController implements TestUtils.ITestableClass{

	public Building__c mergeFrom {get;Set;}
	public Building__c mergeTo {get;Set;}
	public string buildingID {get;Set;}
	public string mergeType {get;Set;}
	
	public BuildingMergeController(){
		mergeFrom = new Building__c();
		mergeTo = new Building__c();
	}

	public PageReference GetBuildingData(){
		Building__c b = getBuilding(buildingID);
		if(mergeType == 'from')
			mergeFrom = b;
		else
			mergeTo = b;
		return null;
	}
	
	private Building__c getBuilding(string bldgID){
		return [Select Id,Name,Building_Hash__c,Address__c,City__c,State__c,Postal_Code__c,Building_Type__c,Net_classification__c,building_clli__c,latitude__c,longitude__c
						,(Select Id,Name,Access_Technology_Name__c,Maximum_Bandwidth__c,Minimum_Required_Revenue__c,Status__c From Access_Availabilities__r)
						,(Select Id,Name,CleanBusiness__c,Contact__c,GeoID__c From Georesults_Businesses__r)
						,(Select Id,Name,Building_Hash__c,Address__c,City__c,State__c,Postal_Code__c,Building_Type__c,Net_classification__c,building_clli__c From Buildings__r)
						,(Select Id,Name,Room_Suite__c from Locations__r)	
						From Building__c where Id = :bldgID];
	}
	
	public PageReference mergeObjs(){
		Boolean failed = false;
		
		try{
			Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get('Building__c').getDescribe();
			
			//Chunk them together by object type so they can be saved together
			Map<String, Map<Id, sObject>> childObjs = new Map<String, Map<Id, sObject>>();
			for(Schema.ChildRelationship cr : d.getChildRelationships()){
				DescribeFieldResult fDesc = cr.getField().getDescribe();
				Schema.DescribeSObjectResult child = cr.getChildSObject().getDescribe();
				if(fDesc.isUpdateable() && child.isQueryable() && child.isUpdateable()){
					String f = fDesc.getName();
					String childObjName = child.getName();
					Map<Id, sObject> m = childObjs.get(childObjName) != null ? childObjs.get(childObjName) : new Map<Id, sObject>();
					for(sObject o : Database.query('select Id from ' + childObjName + ' where ' + f + ' = \'' + mergeFrom.id + '\'')){
						sObject obj = m.get(o.Id) != null ? m.get(o.Id) : o;
						o.put(f, mergeTo.id);
						m.put(o.id, obj);
					}
					
					if(m.size() > 0) childObjs.put(childObjName, m);
				}
			}
			//Callout to update master addressid
			integraWSEndpointMediator.Endpoint.UpdateMasterAddressIDByBuildingHash(mergeFrom.Building_Hash__c,mergeTo.Building_Hash__c,UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
			
			for(String childObjName : childObjs.keyset())
				update childObjs.get(childObjName).values();
			
			update mergeTo;
			delete mergeFrom;
			
			
		}
		catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			failed = true;
		}
		
		return !failed ? new PageReference('/' + mergeTo.id) : null;
	}
	
	/* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_BuildingMerge(); }
}