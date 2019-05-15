public with sharing class RelatedSubOrders {
	public String Error {get; private set;}
	public Sub_Order__c subOrd {get; set;}
	
	public List<Order__c> oList {get; set;}
	public List<Order__c> rList {get; set;}
	public Order__c buildOrder { get; set; }
	public List<OrderWrapper> ritem {get; set;}
	public List<OrderWrapper> oitem {get; set;}
	public Order__c o {get; set;}
	public Sub_Order__c so {get; set;}
	public ApexPages.StandardController controller;
	
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
	
	private String ManualBldOrder;
	public String AddBldOrder{
		get { return ManualBldOrder; }
		Set { ManualBldOrder = value; }
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
	

    public RelatedSubOrders(ApexPages.StandardController controller) {
    	buildOrder = new Order__c();
    	subOrd = (Sub_Order__c)controller.getRecord();  	
		returnRelated(subOrd);
	}
	
	public void returnRelated(Sub_Order__c subOrd){  	
		List<Order__c> tList = new List<Order__c>();
    	List<Id> bldg = new List<Id>();
    	List<SubOrderUtils.SubOrder> so = SubOrderUtils.GetSubOrderBuilding(subOrd.Id);

		if(so.size() > 0){
			for(SubOrderUtils.SubOrder sub : so){			
				bldg.add(sub.BuildingID);
			}
		}
  	
    	if(bldg.size() > 0){
    		//Get build orders related to OpptyOrder    		
    		tList = [Select Record_Status__c, iCert_Number__c, Site_Survey_Date__c, Projected_Network_Ready_Date__c, ESO_Number__c, Name, Location__c, Id, Building__c		
    		From Order__c WHERE Building__c =: bldg AND Record_Status__c != 'Closed'];  		
    	}
    	else{
    		Error = 'There is no building associated with this Order and thus no related orders/suborders can be identified';
    	}    	    	
    	
    	ritem = new List<OrderWrapper>();
		oitem = new List<OrderWrapper>();
		Map<Id, Order__c> mapSO = new Map<Id, Order__c>();
		Set<String> sRelated = new Set<String>();
		List<String> rManual = new List<String>();
		Set<Id> sourceIds = new Set<Id>();
		Set<Id> targetIds = new Set<Id>();
		
    	for(Order__c tOrder : tList){
			mapSO.put(tOrder.Id, tOrder);
    	}
		
		//Get related suborders
		sourceIds.add(subOrd.Id);
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
	
	
	public PageReference Save(){
		List<JunctionUtils.Junction> junc = new List<JunctionUtils.Junction>();				
		if(SetOfModifiedTempIds != null){	
			for(Order__c oc : [SELECT Id FROM Order__c WHERE Id IN : SetOfModifiedTempIds]){	
				Schema.SObjectType sOt = SchemaUtils.GetSObjectTypeByID(subOrd.Id);
				Schema.SObjectType tOt = SchemaUtils.GetSObjectTypeByID(oc.Id);
	
				if(sOt != null && tOt != null){
					junc.add(new JunctionUtils.Junction(sOt.newSObject(subOrd.Id), tOt.newSObject(oc.Id), null));
					junc.add(new JunctionUtils.Junction(tOt.newSObject(oc.Id), sOt.newSObject(subOrd.Id), null));
				}
			}
		}	
	
		List<Database.UpsertResult> jUpsertResults = JunctionUtils.SaveJunctions(junc);
				
		PageReference nextPage = Page.RelatedSubOrders;
		nextPage.getParameters().put('Id', subOrd.Id);
		nextPage.setRedirect(true);
		return nextPage;
	}
	
		public PageReference SaveManual(){
			Set<Id> sourceIds = new Set<Id>();
			Set<Id> targetIds = new Set<Id>();
			Order__c bldOrder = new Order__c();
			List<JunctionUtils.Junction> junc = new List<JunctionUtils.Junction>();
			bldOrder = null;
			Id rtBuildOrderId = Schema.Sobjecttype.Order__c.getRecordTypeInfosByName().get('Build Order').getRecordTypeId();
			for(Order__c b : [Select Id From Order__c Where Name =: ManualBldOrder AND RecordTypeId =: rtBuildOrderId AND Order_Completion_Status__c =: 'In Progress']){			
				bldOrder = b;
			}
			
			if(bldOrder == null){
			// msg
				ApexPages.Message noBldOrder = new ApexPages.Message(ApexPages.Severity.Error, 'Error: The Order Name you entered is either not a Build Order or not In Progress.');
				ApexPages.addMessage(noBldOrder);
				return null;
			}
			else{
				//Save the relationship to the junction table and reload section including the new relationship as an available option.
				sourceIds.add(subOrd.Id);
		    	targetIds.add(bldOrder.Id);		
				List<JunctionUtils.Junction> juncs = JunctionUtils.GetJunctions(sourceIds, targetIds);

				if(juncs.size() == 0){					
					Schema.SObjectType sOt = SchemaUtils.GetSObjectTypeByID(subOrd.Id);
					Schema.SObjectType tOt = SchemaUtils.GetSObjectTypeByID(bldOrder.Id);
					juncs.add(new JunctionUtils.Junction(sOt.newSObject(subOrd.Id), tOt.newSObject(bldOrder.Id), null));
					juncs.add(new JunctionUtils.Junction(tOt.newSObject(bldOrder.Id), sOt.newSObject(subOrd.Id), null));					
					
					List<Database.UpsertResult> jUpsertResults = JunctionUtils.SaveJunctions(juncs);
				}
				else{
					ApexPages.Message dupOrder = new ApexPages.Message(ApexPages.Severity.Error, 'Error: The Order Name you entered is already related to this SubOrder.');
					ApexPages.addMessage(dupOrder);
					return null;
				}
			}
			PageReference nextPage = Page.RelatedSubOrders;
			nextPage.getParameters().put('Id', subOrd.Id);
			nextPage.setRedirect(true);
			return nextPage;
	}
	
	public PageReference Remove(){
		Set<Id> sourceIds = new Set<Id>();
		Set<Id> targetIds = new Set<Id>();

		sourceIds.add(subOrd.Id);
		targetIds.add(subOrd.Id);
		if(SetOfModifiedTempIds != null){
			for(String tId : SetOfModifiedTempIds){
				sourceIds.add(tId);
				targetIds.add(tId);
			}
			List<JunctionUtils.Junction> junc = JunctionUtils.GetJunctions(sourceIDs, targetIDs);
		
			List<Database.DeleteResult> jUpsertResults = JunctionUtils.DeleteJunctions(junc);						
		}

		
		PageReference nextPage = Page.RelatedSubOrders;
		nextPage.getParameters().put('Id', subOrd.Id);
		nextPage.setRedirect(true);
		return nextPage;
	}     
}