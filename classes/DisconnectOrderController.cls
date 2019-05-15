public with sharing class DisconnectOrderController implements TestUtils.ITestableClass {
 
    private final Opportunity_Location__c oppLocation;
    private final ApexPages.StandardController ctr;
    public List<wrapDisconnectOrder> displayOrders {get;set;}
    public map<integer, string> transNames {get;set;} 
    public List<Disconnect_Line_Item__c> existingLineItems {get;set;} 

    public DisconnectOrderController(ApexPages.StandardController stdController) {
        try{
            this.oppLocation = (Opportunity_Location__c) stdController.getRecord();
            this.ctr = stdController;
            
            //Retrieving Customer information               
            retrieveLineItems();
            retrieveOrders(oppLocation.Service_Location__r.ICC_Subscriber_ID__c);
        } catch(Exception e){
            apexUtils.messageDisplay(e.getMessage());
        }
    }

    public class wrapTransaction{
    	public string billTransName {get;set;}
    	public decimal MRR {get;set;}
    }
    
    //Wrapper class for the Disconnect Order and Selected flag
    //to used in the data table on Vf page.
    public class wrapDisconnectOrder{
        public Decimal MRR {get;set;}
        public String EPCProductDescription {get;set;}
        public Integer EPCProductID {get;set;}
        public String FirstCN {get;set;}
        public Integer ServiceProductID {get;set;}
        public Disconnect_Line_Item__c dli {get;set;}
        public Boolean selected {get;set;}
        public Integer EPCRatePlanID {get;set;}
        public String TransactionName {get;set;}
        public List<wrapTransaction> transViews {get;set;}
        
        public wrapDisconnectOrder(integraWS.SFServiceProductView dis_con, Disconnect_Line_Item__c existing){
            this.MRR = dis_con.MRR;
            this.EPCProductDescription = dis_con.EPCProductDescription;
            this.EPCProductID = dis_con.EPCProductID;
            this.FirstCN = dis_con.FirstCN;
            this.ServiceProductID = dis_con.ServiceProductID;
            this.dli = existing;          
            selected = (existing != null);
       }
    }
    
    private List<wrapTransaction> getTransNamesFromSFObject(List<integraWS.SFServiceProductTransactionView> transView){
    	List<wrapTransaction> tnames = new List<wrapTransaction>();  
    	
    	for(integraws.SFServiceProductTransactionView tv :transView){
    		wrapTransaction tn = new wrapTransaction();
    		tn.billTransName = tv.BillingTransName;
    		tn.MRR = tv.MRR;
    		tnames.add(tn);
    	}
    	return tnames;
    }
    
    private void retrieveLineItems(){
        existingLineItems = 
            [Select Id, ServiceProductID__c From Disconnect_Line_Item__c Where Opportunity_Location__c = :oppLocation.Id];
    }
    
    private List<integraWS.SFServiceProductView> getProducts(Integer subscriberId){
        try{
        	return !Test.isRunningTest()
        			? integraWSEndpointMediator.Endpoint.GetServiceProductViewBySubscriberID(subscriberId, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint).SFServiceProductView
        			: Test_DisconnectOrder.getMockProducts(); 
        } catch(Exception e){
            apexUtils.messageDisplay(e.getMessage());
            return null;
        }
    }
    
        
    public void retrieveOrders( String subscriberId ){
        try{ 
            if( String.IsEmpty(subscriberId) ){
                apexUtils.messageDisplay('No ICC Subscriber ID Available, Product Services cannot be retrieved.');
                return;
            }
            
            List<integraWS.SFServiceProductView> views = getProducts(Integer.valueOf(subscriberId));
            
            if( views != null ){
                displayOrders = new List<wrapDisconnectOrder>();
                    
                for( integraWS.SFServiceProductView v : views ){
                    wrapDisconnectOrder o = null;
                    for( Disconnect_Line_Item__c dli : existingLineItems ) {
                        if( dli.ServiceProductID__c == String.valueOf(v.ServiceProductID) ) {
                            o = new wrapDisconnectOrder(v, dli);  
                        }
                    }
                    if( o == null )
                    {
                        o = new wrapDisconnectOrder(v, null);
                    }
                    o.transViews = getTransNamesFromSFObject(v.transNames != null && v.transNames.SFServiceProductTransactionView != null ? v.transNames.SFServiceProductTransactionView : new List<integraWS.SFServiceProductTransactionView>());
                    displayOrders.add(o);
                }
            }else{
                apexUtils.messageDisplay('No Product Services were retrieved.');
            }
            
        } catch(Exception e){
            apexUtils.messageDisplay(e.getMessage());
        }
    }

    public PageReference DisconnectSelected(){
        try{
            List<Disconnect_Line_Item__c> newLineItems = new List<Disconnect_Line_Item__c>();
            List<Disconnect_Line_Item__c> deleteLineItems = new List<Disconnect_Line_Item__c>();
            
            //Checking to see if there are orders to Disconnect
            if( displayOrders != null ){
                for( wrapDisconnectOrder o : displayOrders ){
                    if( (o.selected) && (o.dli == null) ) {
                        Disconnect_Line_Item__c line_item = new Disconnect_Line_Item__c();
                        line_item.ServiceProductID__c = String.valueOf(o.ServiceProductID);
                        line_item.EPCProductID__c = String.valueOf(o.EPCProductID);
                        line_item.EPCProductDescription__c = o.EPCProductDescription;
                        line_item.FirstCN__c = o.FirstCN;
                        line_item.MRC__c = o.MRR;
                        line_item.Opportunity_Location__c = oppLocation.Id;                  
                        newLineItems.add(line_item);
                    }
                    else {
                        if( (!o.selected) && (o.dli != null) ) {
                            deleteLineItems.add(o.dli);
                        }
                    }
                }                   
            }else{
                //No Orders displaying message
                apexUtils.messageDisplay('There are no orders to disconnect.');
            }
            
            if(newLineItems.size() > 0){
                insert newLineItems;
            }
            
            if( deleteLineItems.size() > 0) {
                delete deleteLineItems;
            }
            
            return ctr.cancel();
            
        } catch(Exception e){
            apexUtils.messageDisplay(e.getMessage());
            return null;
        }
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_DisconnectOrder(); }
}