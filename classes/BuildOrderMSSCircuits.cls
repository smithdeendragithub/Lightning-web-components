public with sharing class BuildOrderMSSCircuits {

	public Order__c ord {get; set;}
	public RecordType recordType {get; set;}
	public String ESONumber {get; set;}
	public String PageMessage {get; set;}
	public List<MSSCircuit> Circuits {get; set;}
	public Boolean HasCircuits {
		get
		{
			Boolean result = false;
			if(Circuits != null && !Circuits.isEmpty()){
				result = true;
			}
			return result;
		}
	}
	
	public Boolean HasMessage {
		get
		{
			return !HasCircuits;
		}
	}
	public BuildOrderMSSCircuits(ApexPages.StandardController controller){
		ord = (Order__c)controller.getRecord();
		PageMessage = '';
		if(ord != null){
			recordType = [SELECT Id, Name FROM RecordType WHERE Id =: ord.RecordTypeId ];
			if(recordType != null && (recordType.Name == 'Build Order' || recordType.Name == 'Decomm Order')){
				ESONumber = [Select ESO_Number__c FROM Order__c WHERE Id =: ord.Id].ESO_Number__c;
				if(ESONumber != null && ESONumber.length() > 0){
					//ESONumber = 'ESO16-1005';
					integraWS.ArrayOfMSSCircuitView mssCircuits = getMSSCircuitsByEsoNumber(ESONumber);
					Circuits = getMSSCircuitsFromArray(mssCircuits);
					PageMessage = 'No Results were found in MSS for your ESO Number.';
				}
			else{
				PageMessage = 'There is no ESO Number associated with this Order.';
			}
			}
			else{
				PageMessage = 'This is not a Order. MSS Circuits are only available for Build/Decomm Orders.';
			}
			
		}
	}
	
	private static integraWS.ArrayOfMSSCircuitView getMSSCircuitsByEsoNumber(String esoNumber) {
		
		/*if(!integraWSEndpointMediator.integrationEnabled()){
			return test.IsRunningTest() ? Test_BuildOrderMSSCircuits.getMSSCircuitsByEsoNumber(esoNumber) : new integraWS.ArrayOfMSSCircuitView();
			
		}*/
		return integraWSEndpointMediator.Endpoint.GetMSSCircuitsByESONumber(esoNumber, UserInfo.getSessionID(), CustomSettingUtils.SFDCCallbackEndpoint);
	}
	
	public static List<MSSCircuit> getMSSCircuitsFromArray(integraWS.ArrayOfMSSCircuitView circuits){
		List<MSSCircuit> result = new List<MSSCircuit>();
		try{
			for(integraWS.MSSCircuitView v : circuits.MSSCircuitView){
				result.add(new MSSCircuit(v.CircuitDesignId, v.CircuitId, v.OrderNumber));
			}
		}
		catch(Exception e){
			ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, 'Error acquiring MSS Circuits! Please contact a system admin about the selected Build Order.');
			ApexPages.addMessage(m);  
		}
		return result;
	}
	
	public class MSSCircuit {
		public Integer CircuitDesignId {get; set;}
		public String OrderNumber {get; set;}
		public String CircuitName {get; set;}
		
		public MSSCircuit(){
			this.CircuitDesignId = 0;
			this.OrderNumber = '';
			this.CircuitName = '';
		}
		
		public MSSCircuit(Integer circuitDesignId, String circuitId, String orderNumber){
			this.CircuitDesignId = circuitDesignId;
			this.OrderNumber = orderNumber;
			this.CircuitName = circuitId;
		}
	}
	
	/* TestUtils.ITestableClass methods */
	//public TestUtils.TestClass getTestClass(){ return new Test_BuildOrderMSSCircuits(); }
}