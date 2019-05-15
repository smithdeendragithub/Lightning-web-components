@isTest
private class Test_BuildOrderMSSCircuits  extends TestUtils.TestClass{
	static testMethod void testController() {
		// TO DO: implement unit test
		Mocks testData = new Mocks();
		test.startTest();
    	
    	Order__c o = testData.order;
    	Building__c bld = testData.building;
    	Id rtBuildOrderId = Schema.Sobjecttype.Order__c.getRecordTypeInfosByName().get('Build Order').getRecordTypeId();
    	o.RecordTypeId = rtBuildOrderId;
    	o.Building__c = bld.Id;
    	//update o;
    	Apexpages.StandardController sc = new Apexpages.StandardController(o);
    	BuildOrderMSSCircuits mss = new BuildOrderMSSCircuits(sc);

		BuildOrderMSSCircuits.MSSCircuit tm = new BuildOrderMSSCircuits.MSSCircuit();
		BuildOrderMSSCircuits.MSSCircuit tm2 = new BuildOrderMSSCircuits.MSSCircuit(1,'1','1');
		BuildOrderMSSCircuits.getMSSCircuitsFromArray(new integraWS.ArrayOfMSSCircuitView());
		mss.circuits = new List<BuildOrderMSSCircuits.MSSCircuit>();
		boolean tb = mss.HasCircuits;
		test.stopTest();
	}
	
	public static integraWS.ArrayOfMSSCircuitView getMSSCircuitsByEsoNumber(String esoNumber){
    	integraWS.ArrayOfMSSCircuitView c = new integraWS.ArrayOfMSSCircuitView();
    	c.MSSCircuitView = new List<integraWS.MSSCircuitView>();
    	c.MSSCircuitView.add(getMockCircuit(esoNumber + 'Test', 'Test Circuit/ Mock', 123456));
    	return c;
	} 
	
	 private static integraWS.MSSCircuitView getMockCircuit(String OrderNumber, String CircuitName, Integer CircuitDesignId){
    	integraWS.MSSCircuitView result = new integraWS.MSSCircuitView();
    	result.CircuitDesignId = CircuitDesignId; 
		result.CircuitId = CircuitName;
		result.OrderNumber = OrderNumber;
    	return result;
    }
}