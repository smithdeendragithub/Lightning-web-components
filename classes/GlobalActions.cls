global class GlobalActions {
	webService static Id CreateBuildOrder(Id buildingID) {
		return createBuildOrder(buildingID, false);
    }
    
@AuraEnabled
    webService static Id CreateAdditionalBuildOrder(Id orderID, boolean extraOrder) {
        List<Order__c> ord = [select Id, Building__c, Location__c from Order__c where Id =: orderID];
		return createBuildOrder(ord[0].Building__c, true);
    }
	
	private static Id createBuildOrder(Id buildingID, boolean extraOrder){
		Schema.Describesobjectresult r = Order__c.sObjectType.getDescribe();
		Boolean hasAccess = r.isCreateable();
		//fix this to getRecordTypeInfos and loop thru to find build order instead in case Build Order changes...loop using DeveloperName Build_Order
		for(Schema.RecordtypeInfo rti : Order__c.sObjectType.getDescribe().getRecordTypeInfos()) {
			if(rti.getName().equalsIgnoreCase('Build Order')){
				if(!hasAccess || !rti.isAvailable()){
					return null;
				}
				else{
			        List<Order__c> ord = !extraOrder ? [select Id from Order__c where Building__c =: buildingID] : new List<Order__c>();
			        if(extraOrder || ord.size() == 0){
			        	List<Provisioning_Product__c> pp = [select Id from Provisioning_Product__c where Name = 'Standard Build' limit 1];
			        	ord = new List<Order__c>{new Order__c(Building__c = buildingID
								        						,RecordTypeId = rti.getRecordTypeId()
								        						,Location__c = [select Name from Location__c where Building__c = :buildingID limit 1].Name
								        						,Provisioning_Product__c = pp.size() > 0 ? pp[0].Id : null
								        						,Provisioning_Plan_Enabled__c = true
								        						,Order_Create_Date__c = Date.today()
								        						,Workplan_Start_Date__c = Date.today())};
			        	insert ord;
			        }
		        	return ord.size() > 0 ? ord[0].Id : null;
				}
			}
		}
		return null;	
	}
	
	webService static Boolean CurrentUserHasAgreedToChatterTerms(){
		return SecurityUtils.currentUserHasAgreedToChatterTerms();
	}
	
	webService static List<String> GetPicklistValues(String obj, String field){
		List<String> l = new List<String>();
		for(Schema.PicklistEntry pe : SchemaUtils.GetType(obj).getDescribe().fields.getMap().get(field).getDescribe().getPicklistValues()) l.add(pe.getLabel());
		return l;
	}
	
	webService static Id GetSalesFormsContentVersionIDByTitle(String title){
		List<ContentVersion> docs = [Select Id From ContentVersion Where title = :title and (Asset_Type__c = 'Sales Forms and Pricing' or Asset_Type__c = 'Sales Process/Procedure' or Asset_Type__c = 'Process/Procedure') limit 1];
		return (docs.size() > 0) ? docs[0].Id : null;
	}
	
	webService static void CreateLeadFromGeoResultsBusiness(Id grbID){
		AddressUtils.CreateLeadsFromGeoResultsBusinesses(new Map<Id, Id>{ grbID => null });
	}
	
	webservice static Id CreateCustomerBuildFromOpp(Id oppId, string title, string description){
		List<PermissionSetAssignment> pSetAssignments = [select Id from permissionSetAssignment where assigneeId = :UserInfo.getUserId() and permissionSetId = '0PS1A000000TMfY'];
		Id oppOrdRTID = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Opportunity Order').getRecordTypeID();
		Map<Id,Id> orderIdByOppId = new Map<Id,Id>();
		for(Order__c ord : [select id, Opportunity__c from order__c where recordTypeId = :oppOrdRTID and opportunity__c = :oppId]){
			orderIdByOppId.put(ord.Opportunity__c, ord.Id);
		}
		if(pSetAssignments.size() > 0){
			Capital_Project__c cproj = new Capital_Project__c();
			cproj.RecordTypeId = Schema.SObjectType.Capital_Project__c.getRecordTypeInfosByName().get('Customer Build').getRecordTypeID();
			cproj.Opportunity__c = oppId;
			cproj.Request_Title__c = title;
			cproj.Description__c = description;
			cproj.Order__c = orderIdByOppId.containsKey(oppId)?orderIdByOppId.get(oppId):null;
			//insert cproj;
			SecurityUtils.BypassProcesser.saveObjects(new List<Capital_Project__c>{cproj}, false);
			return cproj.Id;
		}
		else
			return null;
	}

	webservice static Id CreateNetworkBuildFromBldg(Id bldgId){
		List<PermissionSetAssignment> pSetAssignments = [select Id from permissionSetAssignment where assigneeId = :UserInfo.getUserId() and permissionSetId = '0PS1A0000000YXi'];
		if(pSetAssignments.size() > 0){
			Capital_Project__c cproj = new Capital_Project__c();
			cproj.RecordTypeId = Schema.SObjectType.Capital_Project__c.getRecordTypeInfosByName().get('Network Build').getRecordTypeID();
			SecurityUtils.BypassProcesser.saveObjects(new List<Capital_Project__c>{cproj}, false);
			Capital_Project_Building__c cbldg = new Capital_Project_Building__c();
			if(cproj.Id != null){
				cbldg.Capital_Project__c = cproj.Id;
				cbldg.Building__c = bldgId;
				SecurityUtils.BypassProcesser.saveObjects(new List<Capital_Project_Building__c>{cbldg}, false);
			}
			return cproj.Id;
		}
		else
			return null;
	}

	@InvocableMethod
	public static List<String> CreateCustomerBuildFromFlow(List<Id> oppIds){
		List<Capital_Project__c> cprojs = new List<Capital_Project__c>();
		Id oppOrdRTID = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Opportunity Order').getRecordTypeID();
		Map<Id,Id> orderIdByOppId = new Map<Id,Id>();
		for(Order__c ord : [select id, Opportunity__c from order__c where recordTypeId = :oppOrdRTID and opportunity__c in :oppIds]){
			orderIdByOppId.put(ord.Opportunity__c, ord.Id);
		}
		for(Id oppId : oppIds){
			Capital_Project__c cproj = new Capital_Project__c();
			cproj.RecordTypeId = Schema.SObjectType.Capital_Project__c.getRecordTypeInfosByName().get('Customer Build').getRecordTypeID();
			cproj.Opportunity__c = oppId;
			cproj.Order__c = orderIdByOppId.containsKey(oppId)?orderIdByOppId.get(oppId):null;
			cprojs.add(cproj);
		}
		SecurityUtils.BypassProcesser.saveObjects(cprojs, false);
		List<String> retVals = new List<String>();
		for(Capital_Project__c cproj : cprojs) retVals.add(cproj.Id);
		return retVals;
	}
}