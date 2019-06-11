public with sharing class MassUpdateSubOrders implements TestUtils.ITestableClass {
	
	public String orderId;
	public List<SubOrderWrapper> subOrderWrapperList { get; set; }
	//public boolean isCanceled { get; set; }
	public Boolean adminControls {get; private set;}
	
	public Sub_Order__c dummySO { get; set; }
	
	public MassUpdateSubOrders() {
		dummySO = new Sub_Order__c();
		orderId = ApexPages.currentPage().getParameters().get('id');
		Profile p = [select Name from Profile where Id =: userInfo.getProfileId()];
		adminControls = p.Name == 'System Administrator' || p.Name == 'Power User';			//todo: drop and let the page determine security
		
		subOrderWrapperList = new List<SubOrderWrapper>();
		sObjectType objType = Sub_Order__c.getsObjectType();
		for (Sub_Order__c so : (List<Sub_Order__c>)ApexUtils.retrieveObjectsFromFieldSets(objType
        													,new List<Set<String>>
        														{
        															SchemaUtils.RetrieveFullObjectFieldSet(objType)
        														}
        													,'Order__c=\'' + orderId + '\''
        													,null))
			subOrderWrapperList.add(new SubOrderWrapper(so, false));
	}
	
	public PageReference Save() {
		return SaveAction(new PageReference('/' + orderId));
	}
	
	public PageReference Cancel() {
		return new PageReference('/' + orderId);
	}
	
	public PageReference QuickSave() {
		return SaveAction(new PageReference('/' + orderId));
	}
	
	private final Set<String> modifiableFields = new Set<String>{'Activate_with_Customer_Date__c'
																,'Customer_Acceptance_Date__c'
																,'Customer_Commit_Date__c'
																,'Customer_Commit_Date_Change_Reason__c'
																,'Customer_Requested_Date__c'
																,'Customer_Requested_Date_Change_Reason__c'
																,'Expedited__c'
																,'Hardware_Install_and_Test_Date__c'
																,'Status__c'
																,'Workplan_Start_Date__c'};
	public PageReference SaveAction(PageReference pageRef) {
		List<Sub_Order__c> soForUpdate = new List<Sub_Order__c>();
		for (SubOrderWrapper sow : subOrderWrapperList) {
			Boolean updated = false;
			for(String f : modifiableFields)
				updated = updated || sow.so.get(f) != sow.soOld.get(f);
			if(updated)
				soForUpdate.add(sow.so);
		}
		try{
			if (soForUpdate.size() > 0)
				update soForUpdate;
		}
		catch(Exception e){
			return null;
		}
		
		return pageRef;
	}
	
	public void UpdateSelected() {
		for (SubOrderWrapper sow : subOrderWrapperList) {
			if (sow.isSelected) {
				sow.isSelected = false;
				
				/*if (isCanceled)
					sow.so.Status__c = 'Cancelled';*/
				
				for(String f : modifiableFields){
					if(f != 'Status__c' && dummySO.get(f) != null && string.valueOf(dummySO.get(f)) != '')
						sow.so.put(f, dummySO.get(f));
				}
			}
		}
		
		
		for(String f : modifiableFields)
			dummySO.put(f, null);
		//isCanceled = null;
	}
	
	public class SubOrderWrapper {
		public Sub_Order__c so { get; set; }
		public Sub_Order__c soOld { get; set; }
		public boolean isSelected { get; set; }
		
		public SubOrderWrapper(Sub_Order__c so, boolean isSelected) {
			this.so = so;
			this.soOld = so.clone();
			this.isSelected = isSelected;
		}
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_MassUpdateSubOrders(); }
}