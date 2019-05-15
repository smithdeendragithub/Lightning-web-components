public with sharing class BuildingGoogleMapsController implements TestUtils.ITestableClass {
	public Building__c building{get;set;}

	public BuildingGoogleMapsController(ApexPages.StandardController stdController) {
        try{
        	stdController.addFields(new List<string>{'Latitude__c','Longitude__c','Address__c','City__c','State__c','Postal_Code__c','Name'});
            this.building = (Building__c) stdController.getRecord();
        } catch(Exception e){
    	    ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage());
			ApexPages.addMessage(m);
        }
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_BuildingGoogleMaps(); }
}