@isTest
public with sharing class Test_DisconnectOrder extends TestUtils.TestClass {
	
    static testMethod void testDisconnectOrderController(){

        Mocks testData = new Mocks();

        test.startTest();

        //Creating Disconnected Line Items
        Pagereference pageRef = Page.DisconnectOrder;
        pageRef.getParameters().put('id', testData.location.id);        
        Test.setCurrentPage(pageRef);
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.location);
        DisconnectOrderController ctr = new DisconnectOrderController(sc);
        
        DisconnectOrderController.wrapTransaction wt = new DisconnectOrderController.wrapTransaction();
        
        ctr.retrieveOrders('11022'); 
        
        try {
        	ctr.displayOrders[0].selected = true;
            
        	ctr.DisconnectSelected();
        } catch (Exception e) {
        	
        }
        
        ApexUtils.messageDisplay('test message');
        test.stopTest();
    }

    public static List<integraWS.SFServiceProductView> getMockProducts() {
        integraWS.ArrayOfSFServiceProductView test_products = new integraWS.ArrayOfSFServiceProductView();
        test_products.SFServiceProductView = new list<integraWS.SFServiceProductView>();
        integraWS.SFServiceProductView v = new integraWS.SFServiceProductView();
             
        v.EPCProductDescription = 'Test 1 Product Desc';
        v.FirstCN = 'Test11111';
        v.MRR = 1.0;
        v.ServiceProductID = 99999;
        v.EPCProductID = 1;
		v.transNames = getTransNames('Test1');
        
        test_products.SFServiceProductView.add(v);
		
		v = new integraWS.SFServiceProductView();
        v.EPCProductDescription = 'Test 2 Product Desc';
        v.FirstCN = 'Test22222';
        v.MRR = 1.0;
        v.ServiceProductID = 1;
        v.EPCProductID = 1;
		v.transNames  = getTransNames('Test2');

        test_products.SFServiceProductView.add(v);
            
        return test_products.SFServiceProductView;
    }
	
	private static integraWS.ArrayOfSFServiceProductTransactionView getTransNames(String name){
		integraWS.ArrayOfSFServiceProductTransactionView tn = new integraWS.ArrayOfSFServiceProductTransactionView();
		tn.SFServiceProductTransactionView = new List<integraWS.SFServiceProductTransactionView>();
		
		integraWS.SFServiceProductTransactionView spt = new integraWS.SFServiceProductTransactionView();
		spt.BillingTransName = name;
		spt.MRR = 100;
		tn.SFServiceProductTransactionView.add(spt);
		return tn;
	}
}