public with sharing abstract class RelatedRecordViewerBaseController{
	
	//Params
	public Id objectID {get; set;}
	public List<RelatedObject> relatedObjects {get; set;}
	
	//Derived params
	public String objectName { get; set;}
	public Boolean singleObject { get; set; }
	public String singleObjectName { get; set;}
	
	protected final Map<String, String> additionalFields = new Map<String, String>{'Account'=>'ICC_Account_Number__c'
																				,'Customer_Detail__c'=>'ICC_Subscriber_ID__c'
																				,'Order_Property__c'=>'External_ID__c'
																				,'Sub_Order_Group__c'=>'External_ID__c'
																				,'Service_Location__c'=>'ICC_Subscriber_ID__c'};
	
	public DateTime StartDate { get; set; }
	public DateTime EndDate { get; set; }
	
	public String StartDateString { get; set; }
	public String EndDateString { get; set; }
	
	public Map<Id, nObject> nObjects { get; set;}
	
	public class nObject{
		public String name {get; set;}
		public Id id {get; set;}
		public object externalID {get; set;}
		
		public nObject(String name, Id id, object externalID){
			this.name = name;
			this.id = id;
			this.externalID = externalID;
		}
	}
	
	public class RelatedObject{
		public String name {get; set;}
		public List<RelatedObject> related {get; set;}
		public String sObjectName {get; set;}
		public String parentField {get; set;}
	}
	
	public void initialize(){
		initialize(null);
	}
	
	public void initialize(Map<String, String> relatedJSONMap){
		String oID = ApexPages.currentPage().getParameters().get('id');
		objectID = (Id)(!string.IsEmpty(oID) ? oID : null);
		if(objectID != null) objectName = SchemaUtils.GetSObjectNameByID(objectID);
		
		String r = relatedJSONMap != null && relatedJSONMap.get(objectName) != null ? relatedJSONMap.get(objectName) : ApexPages.currentPage().getParameters().get('related');
		
		try{
			r = r.replace('\'', '"').replace('%27', '"');
			relatedObjects = !string.isEmpty(r) ? (List<RelatedObject>)JSON.deserialize(r, List<RelatedObject>.class) : null;
		}
		catch(Exception e){ }
		
		if(relatedObjects == null){
			relatedObjects = new List<RelatedObject>();
			singleObject = true;
		}
		else{
			getRelatedObjectSchema(SchemaUtils.GetSObjectTypeByID(objectID).getDescribe(), relatedObjects);
			singleObject = false;
		}
		
		String nameField = SchemaUtils.GetNameField(SchemaUtils.GetType(objectName));
		if(nameField != null && nameField != 'Id'){
			sObject o = Database.query('select Id, ' + nameField + ' from ' + objectName + ' where Id = \'' + objectID + '\' limit 1')[0];
			singleObjectName = string.valueOf(o.get(nameField));
		}
		else singleObjectName = objectID;
		
		system.debug('relatedObjects: ' + relatedObjects);
		
		nObjects = null;
	}
	
	protected Boolean reset(){
		nObjects = new Map<Id, nObject>();
		try {
			if(EndDateString != null && EndDateString != '') {
				EndDate = (DateTime)Date.valueOf(EndDateString);
				EndDate = EndDate.addHours(23);
				EndDate = EndDate.addMinutes(59);
				EndDate = EndDate.addSeconds(59);
			}
			else EndDate = null;
		}
		catch(Exception ex) {	
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Unable to parse a end date from: "'+ EndDateString + '"'));
			return false;
		}
		
		try {
			StartDate = (StartDateString != null && StartDateString != '') ? (DateTime)Date.valueOf(StartDateString) : null;
		}
		catch(Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Unable to parse an start date from: "'+ StartDateString + '"'));
			return false;
		}
		
		if(StartDate > EndDate) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Start date is after the end date.  Cannot fetch notes.'));
			return false;
		}
		
		String externalIDField = getExternalIDField(objectName);
		sObject sObj = Database.query('select Id, Name ' + (additionalFields.get(objectName) != null ? (',' + additionalFields.get(objectName)) : '') + ' from ' + objectName + ' where Id = \'' + objectID + '\'')[0];
		
		nObjects.put(objectID, new nObject(singleObjectName, objectID, externalIDField != null ? sObj.get(externalIDField) : null));
		
		gatherExternalIDs(objectName, sObj);
		getRelatedObjects(relatedObjects, new Set<Id>{objectID});
		
		return true;
	}
	
	private transient Map<SObjectType, Set<String>> objParentMapping;
	private void getRelatedObjectSchema(Schema.DescribeSObjectResult parentObjDescribe, List<RelatedObject> defs){
		if(defs == null) return;
		
		Set<Id> newParentIDs = new Set<Id>();
		for(ChildRelationship cr : parentObjDescribe.childRelationships){
			for(RelatedObject ro : defs){
				if(ro.name == cr.relationshipName){
					Schema.DescribeSObjectResult d = cr.childSObject.getDescribe();
					ro.sObjectName = d.getName();
					ro.parentField = cr.field.getDescribe().getName();
					getRelatedObjectSchema(d, ro.related);
				}
			}
		}
	}
	
	private void getRelatedObjects(List<RelatedObject> defs, Set<Id> parentIDs){
		if(defs == null || parentIDs.size() == 0) return;
		
		for(RelatedObject ro : defs){
			String externalIDField = getExternalIDField(ro.sObjectName);
			if(!string.isEmpty(ro.parentField)){
				Set<Id> newIDs = new Set<Id>();
				for(sObject o : Database.query('select Id, Name ' + (additionalFields.get(ro.sObjectName) != null ? (',' + additionalFields.get(ro.sObjectName)) : '') + ' from ' + ro.sObjectName + ' where ' + ro.parentField + ' in: parentIDs')){
					nObjects.put(o.Id, new nObject(string.valueOf(o.get('Name')), o.Id, externalIDField != null ? o.get(externalIDField) : null));
					gatherExternalIDs(ro.sObjectName, o);
					newIDs.add(o.Id);
				}
				
				if(newIDs.size() > 0)
					getRelatedObjects(ro.related, newIDs);
			}
		}
	}
	
	protected String getExternalIDField(String sObjectType){
		if(sObjectType == 'Account' || sObjectType == 'Customer_Detail__c' || sObjectType == 'Service_Location__c')
			return (sObjectType == 'Account') ? 'ICC_Account_Number__c' : 'ICC_Subscriber_ID__c';
		else if(sObjectType == 'Order_Property__c') return 'External_ID__c';
		else if(sObjectType == 'Sub_Order_Group__c') return 'External_ID__c';
		
		return null;
	}
	
	protected transient Map<String, Map<String, Id>> externalIDMap;
	private void gatherExternalIDs(String sObjectType, sObject sObj){
		if(externalIDMap == null){
			externalIDMap = new Map<String, Map<String, Id>>{'SubID'=>new Map<String, Id>()
															,'OrderID'=>new Map<String, Id>()
															,'OrderGroupID'=>new Map<String, Id>()};
		}
		
		String externalIDField = getExternalIDField(sObjectType);
		if(externalIDField != null)
			getExternalID((externalIDField == 'ICC_Account_Number__c' || externalIDField == 'ICC_Subscriber_ID__c')
							? 'SubID'
							: (externalIDField == 'External_ID__c'
								? (sObjectType == 'Order_Property__c' ? 'OrderID' : (sObjectType == 'Sub_Order_Group__c' ? 'OrderGroupID' : ''))
								: '')
							, externalIDField, sObj);
	}
	
	protected void getExternalID(String idName, String fieldName, sObject sObj){
		String i = string.valueOf(sObj.get(fieldName));
		if(!string.isEmpty(i))
			externalIDMap.get(idName).put(i, sObj.Id);
	}
	
	protected String getCaseName(Case c){
		return (c.Status != 'Closed' ? 'Open' : 'Closed') + ' Case ' + c.CaseNumber;
	}
	
	protected String formatDate(DateTime d) {
		string formattedDate = prefixZero(d.year());
		formattedDate += '-' + prefixZero(d.month());
		formattedDate += '-' + prefixZero(d.dayGmt());
		return formattedDate;
	}
	
	private String prefixZero(integer i) {
		return ((i < 10) ? '0' : '') + string.valueOf(i);
	}
}