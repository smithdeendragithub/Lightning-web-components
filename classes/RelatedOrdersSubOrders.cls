public with sharing class RelatedOrdersSubOrders{
	public String error {get; private set;}
	public Order__c ord {get; set;}
	
	public List<Order__c> oList {get; set;}
	public List<Order__c> rList {get; set;}
	public List<OrderWrapper> ritem {get; set;}
	public List<OrderWrapper> oitem {get; set;}
	public List<Sub_Order__c> aList {get; set;}
	public List<Sub_Order__c> relList {get; set;}
	public List<SubOrderWrapper> relitem {get; set;}
	public List<SubOrderWrapper> aitem {get; set;}
	public Sub_Order__c subOrder {get; set;}
	public Order__c o {get; set;}
	public ApexPages.StandardController controller;
	
	public List<Order__c> tList {get; set;}
	public List<Sub_Order__c> soList {get; set;}
	public Boolean isSubOrder {get; set;}
	
	public List<sObjectWrapper> getRelatedWrapperCollection() {
		return (List<sObjectWrapper>)ritem;
	}
	public List<sObjectWrapper> getWrapperCollection() {
		return (List<sObjectWrapper>)oitem;
	}
	
	private Set<String> SetOfModifiedTempIds;
	public String ModifiedTempIds{
		get { return JSON.serialize(SetOfModifiedTempIds); }
		Set { SetOfModifiedTempIds = (Set<String>)JSON.deserialize(value, Set<String>.class); }
	}
	
	private String ManualSubOrder;
	public String AddSubOrder{
		get { return ManualSubOrder; }
		Set { ManualSubOrder = value; }
	}
	
	public class OrderWrapper extends sObjectWrapper {
		public Order__c sub { get; set; }
		public Boolean isSelected { get; set; }
		
		public OrderWrapper(Order__c sub, Boolean isSelected) {		
			this.sub = sub;
			sObj = (sObject)sub;
			this.isSelected = isSelected;
		}
	}
	
	public class SubOrderWrapper extends sObjectWrapper {
		public Sub_Order__c sub { get; set; }
		public Boolean isSelected { get; set; }
		
		public SubOrderWrapper(Sub_Order__c sub, Boolean isSelected) {		
			this.sub = sub;
			sObj = (sObject)sub;
			this.isSelected = isSelected;
		}
	}

	public virtual class sObjectWrapper {
		public boolean isSelected { get; set; }
		public sObject sObj {get; set;}
		
		public sObjectWrapper(){}
		public sObjectWrapper(sObject sObj, Boolean isSelected){
			this.sObj = sObj;
			this.isSelected = isSelected;
		}
		
		public virtual List<sObjectWrapper> getSubWrapperLists(){ return new List<sObjectWrapper>(); }
	}
	
	public Schema.sObjectType sObjType { get; set; }
	

    public RelatedOrdersSubOrders(ApexPages.StandardController controller) { 
    	subOrder = new Sub_Order__c();   	
    	ord = (Order__c)controller.getRecord();
		DetermineRelationOfOrderOrSub(ord);
	}
	
	public void DetermineRelationOfOrderOrSub(Order__c ord){ 
		//If the user is on a Build Order page, show possible related SO's. 
		//If the user is on an Oppty Order page, show possible related Build Orders 	
		tList = new List<Order__c>();
		soList = new List<Sub_Order__c>();
		isSubOrder = false;
    	Id rtBuildOrderId = Schema.Sobjecttype.Order__c.getRecordTypeInfosByName().get('Build Order').getRecordTypeId();
    	List<Id> bldg = new List<Id>();
		
		for(Order__c oOrder :[SELECT Id, Building__c, Name FROM Order__c WHERE Id =: ord.Id]){			
			if(oOrder.Building__c != null)		
    			bldg.add(oOrder.Building__c);
    	}
 	
    	if(rtBuildOrderId == ord.RecordTypeId && bldg.size() > 0){    		    		     		
    		//Get suborders by location->building for possible relation BO that user is currently viewing.
    		isSubOrder = true;
    		soList = [Select Sub_Order_Number__c, Status__c, Order__r.AccountName__c, Service_Location__c, SPC_Product__r.Name, 
    		Customer_Requested_Date__c, Name, Location__c, Id, Service_Location__r.Location__r.Building__r.Id, 
    		Order__r.Id,  Order__c
    		From Sub_Order__c WHERE Order__r.RecordTypeId != :rtBuildOrderId AND Service_Location__r.Location__r.Building__r.Id =: bldg];
    	}
    	else if(rtBuildOrderId != ord.RecordTypeId){
    		//Get build orders related to OpptyOrder  
    		Set<Id> rSo = getSOSetForMO(ord.Id);
    		tList = [Select Record_Status__c, iCert_Number__c, Site_Survey_Date__c, Projected_Network_Ready_Date__c, ESO_Number__c, Name, Location__c, Id, Building__c		
    		From Order__c WHERE RecordTypeId = :rtBuildOrderId AND Building__c =: rSo];
    	}
    	else{
    		error = 'There is no building associated with this Order and thus no related orders/suborders can be identified';
    	}
	
	//must add junction table Manual relationships
		if (isSubOrder == false)
			RelatedOrder(tList);
		else if (isSubOrder == true)
			RelatedSubOrders(soList);    	
	}
	
	public void RelatedOrder(List<Order__c> tList){
		ritem = new List<OrderWrapper>();
		oitem = new List<OrderWrapper>();
		Map<Id, Order__c> mapSO = new Map<Id, Order__c>();
		Set<String> sRelated = new Set<String>();
		List<String> rManual = new List<String>();
		Set<Id> sourceIds = new Set<Id>();
		Set<Id> targetIds = new Set<Id>();
		
		for(Order__c so : tList){
			mapSO.put(so.Id, so);
    	}
		
		//Get related suborders from Junction Class
		List<Sub_Order__c> so = [Select Id From Sub_Order__c Where Order__c =: ord.Id];
		for(Sub_Order__c sub : so){
			sourceIds.add(sub.Id);
		}

		for(Order__c lOrd : tList){
			targetIds.add(lOrd.Id);
		}

		List<JunctionUtils.Junction> junc = JunctionUtils.GetSOrTBasedJunctions(sourceIDs, targetIDs);
		if(junc.size() > 0){
			for(JunctionUtils.Junction j : junc){						
				sRelated.add(String.valueOf(j.Target.Id));
			}
		}

		oList = new List<Order__c>();
		rList = new List<Order__c>();	
		if(sRelated.size() == 0){			
			oList.addAll(tList);			
		}		
		else{			
			for(String soid : sRelated){							
				Order__c sOrder = mapSO.get(soid);
			
				if(sOrder != null){
					mapSO.remove(soid);				
					rList.add(sOrder);
				}
				else{
					rManual.add(soid);
				}		
			}
			oList.addAll(mapSO.values());
		}	
		for(Order__c os : [Select Record_Status__c, iCert_Number__c, Site_Survey_Date__c, Projected_Network_Ready_Date__c, ESO_Number__c, Name, Location__c, Id, Building__c		
    		From Order__c WHERE Id =: rManual]){
    			rList.add(os);
    		}	

		for(Order__c rSO : rList != null ? rList : new List<Order__c>()){
    		boolean selected = true;
    		OrderWrapper sow = new OrderWrapper(rSO, selected);  		    		
    		ritem.add(sow);    		
		}
		for(Order__c oSO : oList != null ? oList : new List<Order__c>()){
    		boolean selected = false;
    		OrderWrapper sop = new OrderWrapper(oSO, selected);
    		oitem.add(sop);     		
		}
	}
	
	private Set<Id> getSOSetForMO(Id ordId){
		Set<Id> rSo = new Set<Id>();
		List<Sub_Order__c> so = [Select Service_Location__r.Location__r.Building__r.Id From Sub_Order__c Where Order__c =: ordId];
		for(Sub_Order__c sub : so){
			rSo.add(sub.Service_Location__r.Location__r.Building__r.Id);
		}
		return rSo;
	}
	public void RelatedSubOrders(List<Sub_Order__c> tList){				
		relitem = new List<SubOrderWrapper>();
		aitem = new List<SubOrderWrapper>();
		Map<String, Sub_Order__c> mapSO = new Map<String, Sub_Order__c>();
		Set<String> sRelated = new Set<String>();
		List<String> rManual = new List<String>();
		Set<Id> sourceIds = new Set<Id>();
		Set<Id> targetIds = new Set<Id>();
		
		for(Sub_Order__c so : tList){
			mapSO.put(so.Id, so);
    	}
		
		//Get related suborders
		sourceIds.add(ord.Id);
		for(Sub_Order__c lOrd : tList){
			targetIds.add(lOrd.Id);
		}

		List<JunctionUtils.Junction> junc = JunctionUtils.GetSOrTBasedJunctions(sourceIDs, targetIDs);

		if(junc.size() > 0){
			for(JunctionUtils.Junction j : junc){						
				sRelated.add(String.valueOf(j.Target.Id));
			}
		}
			
		aList = new List<Sub_Order__c>();
		relList = new List<Sub_Order__c>();	
		if(sRelated.size() == 0){			
			aList.addAll(tList);			
		}
		else{
			for(String soid : sRelated){						
				Sub_Order__c sOrder = mapSO.get(soid);
				
				if(sOrder != null){
					mapSO.remove(soid);					
					relList.add(sOrder);
				}
				else{
					rManual.add(soid);
				}	
			}
			aList.addAll(mapSO.values());
		}
		for(Sub_Order__c so : [Select Sub_Order_Number__c, Status__c, Order__r.AccountName__c, Service_Location__c, SPC_Product__r.Name, 
    		Customer_Requested_Date__c, Name, Location__c, Id, Service_Location__r.Location__r.Building__r.Id, 
    		Order__r.Id,  Order__c
    		From Sub_Order__c WHERE Id =: rManual]){
    			relList.add(so);
    		}					

		for(Sub_Order__c rSO : relList != null ? relList : new List<Sub_Order__c>()){
    		boolean selected = true;
    		SubOrderWrapper sow = new SubOrderWrapper(rSO, selected);
   		  		    		
    		relitem.add(sow);    		
		}
		for(Sub_Order__c oSO : aList != null ? aList : new List<Sub_Order__c>()){
    		boolean selected = false;
    		SubOrderWrapper sop = new SubOrderWrapper(oSO, selected);
    		aitem.add(sop);     		
		}		
	}
	
	public PageReference Save(){
		List<JunctionUtils.Junction> junc = new List<JunctionUtils.Junction>();
		if(SetOfModifiedTempIds != null){
			for(Sub_Order__c soc : [SELECT Id FROM Sub_Order__c WHERE Id IN : SetOfModifiedTempIds]){	
				Schema.SObjectType sOt = SchemaUtils.GetSObjectTypeByID(ord.Id);
				Schema.SObjectType tOt = SchemaUtils.GetSObjectTypeByID(soc.Id);

				if(sOt != null && tOt != null){
					junc.add(new JunctionUtils.Junction(sOt.newSObject(ord.Id), tOt.newSObject(soc.Id), null));
					junc.add(new JunctionUtils.Junction(tOt.newSObject(soc.Id), sOt.newSObject(ord.Id), null));
				}
			}							

		}			

		//update otherSideRelated;	
		List<Database.UpsertResult> jUpsertResults = JunctionUtils.SaveJunctions(junc);		
			
		PageReference nextPage = Page.RelatedOrdersSubOrders;
		nextPage.getParameters().put('Id', ord.Id);
		nextPage.setRedirect(true);
		return nextPage;
	}
	
	public PageReference SaveManual(){
		Set<Id> sourceIds = new Set<Id>();
		Set<Id> targetIds = new Set<Id>();
		Sub_Order__c sOrder = new Sub_Order__c();
		List<JunctionUtils.Junction> junc = new List<JunctionUtils.Junction>();
		sOrder = null;
		for(Sub_Order__c b : [Select  Id
    		From Sub_Order__c WHERE Name =: ManualSubOrder AND Status__c IN ('In Progress', 'New')]){			
			sOrder = b;
		}
			
		if(sOrder == null){
			ApexPages.Message noSubOrder = new ApexPages.Message(ApexPages.Severity.Error, 'Error: The SubOrder Name you entered is either not a Sub Order or not In Progress.');
			ApexPages.addMessage(noSubOrder);
			return null;
		}
		else{	
			sourceIds.add(ord.Id);
		    targetIds.add(sOrder.Id);		
			List<JunctionUtils.Junction> juncs = JunctionUtils.GetJunctions(sourceIds, targetIds);

			if(juncs.size() == 0){
				Schema.SObjectType sOt = SchemaUtils.GetSObjectTypeByID(ord.Id);
				Schema.SObjectType tOt = SchemaUtils.GetSObjectTypeByID(sOrder.Id);						
				juncs.add(new JunctionUtils.Junction(sOt.newSObject(ord.Id), tOt.newSObject(sOrder.Id), null));
				juncs.add(new JunctionUtils.Junction(tOt.newSObject(sOrder.Id), sOt.newSObject(ord.Id), null));	
									
				List<Database.UpsertResult> jUpsertResults = JunctionUtils.SaveJunctions(juncs);	
			}
			else{
				ApexPages.Message dupSubOrder = new ApexPages.Message(ApexPages.Severity.Error, 'Error: The SubOrder Name you entered is already related to this Build Order.');
				ApexPages.addMessage(dupSubOrder);
				return null;
			}
		}
		PageReference nextPage = Page.RelatedOrdersSubOrders;
		nextPage.getParameters().put('Id', ord.Id);
		nextPage.setRedirect(true);
		return nextPage;
	}
	
	public PageReference Remove(){
		Set<Id> sourceIds = new Set<Id>();
		Set<Id> targetIds = new Set<Id>();

		sourceIds.add(ord.Id);
		targetIds.add(ord.Id);
		
		if(SetOfModifiedTempIds != null){
			for(String tId : SetOfModifiedTempIds){
				sourceIds.add(tId);
				targetIds.add(tId);
			}
			List<JunctionUtils.Junction> junc = JunctionUtils.GetJunctions(sourceIDs, targetIDs);	
			List<Database.DeleteResult> jUpsertResults = JunctionUtils.DeleteJunctions(junc);						
		}

			PageReference nextPage = Page.RelatedOrdersSubOrders;
			nextPage.getParameters().put('Id', ord.Id);
			nextPage.setRedirect(true);
			return nextPage;    
		 
	}
}