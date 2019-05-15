public class AssignOrders extends WorkflowAssignmentControllerBase implements TestUtils.ITestableClass {
	
	public List<Order__c> ordersList { get; set; }
	public List<OrderWrapper> orderWrapperList { get; set; }
	public Order__c dummyOrd {get; set;}
	
	public override List<sObjectWrapper> getWrapperCollection() {
		return (List<sObjectWrapper>)orderWrapperList;
	}
	
	
	public AssignOrders(ApexPages.StandardSetController sc) {
		sObjType = Order__c.sObjectType;
		ordersList = (List<Order__c>)getRecords(sc);
		isError = ordersList.size() == 0;
		reselectOrders(ordersList, true);
		listViewURL = getListViewURL(sc, 'Order__c', 'All');
		dummyOrd = new Order__c();
		dummySObject = (sObject)dummyOrd;
		
	}
	
	public void reselectOrders(List<Order__c> ordersList, boolean isSelected) {
		ordersList = [SELECT Id, OwnerId, Owner.Name, Name FROM Order__c WHERE Id IN :ordersList];
		List<Workstep__c> workstepList = [Select Id, Name, OwnerId, Owner.Name, Order__r.Name from Workstep__c WHERE Order__r.Id IN :ordersList AND Owner.Name = 'Unassigned'];
		orderWrapperList = new List<OrderWrapper>();
		for (Order__c o : ordersList) {
			OrderWrapper ow = new OrderWrapper(o, isSelected);
			for (Workstep__c ws : workstepList) {
				if(ws.Order__r.Id == o.Id)
					ow.workstepWrapperList.add(new sObjectWrapper((sObject)ws, true));
			}
			orderWrapperList.add(ow);
		}
	}
	
	public override void saveComplete(){
		reselectOrders(ordersList, false);
	}
	
	public class OrderWrapper extends sObjectWrapper {
		public Order__c ord { get; set; }
		public List<sObjectWrapper> workstepWrapperList {get; set;}
		
		public OrderWrapper(Order__c order, boolean isSelected) {
			ord = order;
			sObj = (sObject)order;
			isSelected = isSelected;
			workstepWrapperList = new List<sObjectWrapper>();
		}
		
		public override List<sObjectWrapper> getSubWrapperLists(){
			return (List<sObjectWrapper>)workstepWrapperList;
		}
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_AssignOrders(); }
}