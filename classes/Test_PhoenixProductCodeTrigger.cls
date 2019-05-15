@isTest
public with sharing class Test_PhoenixProductCodeTrigger {
    
    private class WebServiceMockImpl implements WebServiceMock 
    {
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType) 
        {
            if(request instanceof MetadataService.retrieve_element)
                response.put('response_x', new MetadataService.retrieveResponse_element());
            else if(request instanceof MetadataService.updateMetadata_element)
                response.put('response_x', new MetadataService.updateMetadataResponse_element());
            return;
        }
    }
    
	static testmethod void testTriggers(){
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        Test.startTest(); 
        List<Phoenix_Product_Code__c> ppcs = new List<Phoenix_Product_Code__c>();
        ppcs.add(new Phoenix_Product_Code__c(name='ATestProduct', Product_Code_Value__c='111'));
        ppcs.add(new Phoenix_Product_Code__c(name='BTestProduct', Product_Code_Value__c='222'));
		
        insert ppcs;
        Test.stopTest();
    }
}