@isTest
public with sharing class Test_integraWS {

    static testMethod void testIntegraWS() {
        new integraWS();
        new integraWS.CreateICertParamsObj();
        new integraWS.Document();
		new integraWS.DocumentListResultContract();
        new integraWS.DocumentMetaData();
		new integraWS.LocationAccessAndBandwithResults();
		new integraWS.MSSCircuitView();
        new integraWS.PicTCSIView();
        new integraWS.SFBatchLocationView();
        new integraWS.SFBulkQualView();
		//new integraWS.SFEoNNIView();
		//new integraWS.SFEoNNIViews();
		new integraWS.SFGetRequestApprovalsResponseView();
		new integraWS.SFHistoryView();
		new integraWS.SFICertResponseView();
        new integraWS.SFLocationView();
		new integraWS.SFMSAGAddress();
        new integraWS.SFMSAGAddressView();
		new integraWS.SFOrderPropertyView();
		new integraWS.SFOrderView();
		new integraWS.SFOverriddenAddresses();
        new integraWS.SFRemarkView();
		new integraWS.SFRequestApprovalView();
        new integraWS.SFServiceProductTransactionView();
        new integraWS.SFServiceProductView();
		new integraWS.SFServiceResponseView();
		new integraWS.SFSPCPricingView();
		new integraWS.SFSubOrderGroupStatusView();
		new integraWS.SFSubOrderGroupView();
		new integraWS.SFSubOrderView();
        new integraWS.SFSubscriberAddressView();
        new integraWS.SFSubscriberContactAliasView();
        new integraWS.SFSubscriberContactView();
        new integraWS.SFSubscriberSettingView();
        new integraWS.SFSubscriberTaxInformationView();
        new integraWS.SFSubscriberView();
		new integraWS.SFTaxMainAddress();
		
        new integraWS.ArrayOfCreateICertParamsObj();
		new integraWS.ArrayOfDocumentListResultContract();
        new integraWS.ArrayOfDocumentMetaData();
		new integraWS.ArrayOfLocationAccessAndBandwithResults();
		new integraWS.ArrayOfMSSCircuitView();
        new integraWS.ArrayOfPicTCSIView();
        new integraWS.ArrayOfSFBatchLocationView();
		//new integraWS.ArrayOfSFEoNNIView();
		new integraWS.ArrayOfSFHistoryView();
		new integraWS.ArrayOfSFICertResponseView();
		new integraWS.ArrayOfSFLocationView();
        new integraWS.ArrayOfSFMSAGAddressView();
		new integraWS.ArrayOfSFOrderPropertyView();
		new integraWS.ArrayOfSFSPCPricingView();
        new integraWS.ArrayOfSFRemarkView();
		new integraWS.ArrayOfSFRequestApprovalView();
        new integraWS.ArrayOfSFServiceProductTransactionView();
        new integraWS.ArrayOfSFServiceProductView();
		new integraWS.ArrayOfSFSubOrderGroupStatusView();
		new integraWS.ArrayOfSFSubOrderGroupView();
		new integraWS.ArrayOfSFSubOrderView();
        new integraWS.ArrayOfSFSubscriberAddressView();
        new integraWS.ArrayOfSFSubscriberContactAliasView();
        new integraWS.ArrayOfSFSubscriberContactView();
        new integraWS.ArrayOfSFSubscriberSettingView();
        new integraWS.ArrayOfSFSubscriberTaxInformationView();
        new integraWS.ArrayOfSFSubscriberView();
		
		new integraWS.ArrayOfDictionaryOfIntAndNullableIntEntry();
		new integraWS.ArrayOfDictionaryOfStringAndStringEntry();
		new integraWS.DictionaryOfIntAndNullableInt();
		new integraWS.DictionaryOfIntAndNullableIntEntry();
		new integraWS.DictionaryOfStringAndString();
		new integraWS.DictionaryOfStringAndStringEntry();
		new integraWS.ListOfInt();
		new integraWS.ListOfString();
		
        integraWS.BasicHttpBinding_ISalesForceServiceEndPoint ep = new integraWS.BasicHttpBinding_ISalesForceServiceEndPoint();
		
        try {ep.BulkGeoCodeFromContent(null, null, null, null, null);}catch(Exception e){}
        new integraWS.BulkGeoCodeFromContentResponse_element();
		
		//try {ep.BulkUpdateENNIFromContent(null, null, null, null, null, null);}catch(Exception e){}
		//new integraWS.BulkUpdateENNIFromContentResponse_element();
		new integraWS.BulkUpdateENNIFromContent_element();
        
        try {ep.CreateICerts(null, null, null);}catch(Exception e){}
        new integraWS.CreateICertsResponse_element();
        
        try {ep.CompleteStep(null, null, null, null);}catch(Exception e){}
        new integraWS.CompleteStepResponse_element();
        
        try {ep.CreateICertsAndCompleteRequestOrigStep(null, null, null);}catch(Exception e){}
        new integraWS.CreateICertsAndCompleteRequestOrigStepResponse_element();
        
        try {ep.createRemarks(null, null, null, null);}catch(Exception e){}
        new integraWS.createRemarksResponse_element();
		
		try {ep.CreateSolutionInstallOrderHeader(null, null, null);}catch(Exception e){}
		new integraWS.CreateSolutionInstallOrderHeaderResponse_element();
        
        try {ep.DeleteSubscriberContacts(null, null, null);}catch(Exception e){}
        new integraWS.DeleteSubscriberContactsResponse_element();
        
        try {ep.DeleteSubscriberSettings(null, null, null);}catch(Exception e){}
        new integraWS.DeleteSubscriberSettingsResponse_element();
        
        try {ep.GetBatchAddressProcessingResults(0, null, null);}catch(Exception e){}
        new integraWS.GetBatchAddressProcessingResultsResponse_element();
        
        try {ep.GetDocument(null, null, null);}catch(Exception e){}
        new integraWS.GetDocumentResponse_element();
        
        try {ep.GetDocumentList(1,1,1,'aa','aa');}catch (Exception e){}
        new integraWS.GetDocumentListResponse_element();
        
		try {ep.GetDocumentsBySubscriberID(null, null, null, null, null);}catch(Exception e){}
		new integraWS.GetDocumentsBySubscriberIDResponse_element();
        
		try {ep.GetICertsByIds(null, null, null);}catch(Exception e){}
		new integraWS.GetICertsByIdsResponse_element();
        
		try {ep.GetMSSCircuitsByESONumber(null, null, null);}catch(Exception e){}
		new integraWS.GetMSSCircuitsByESONumberResponse_element();
		
		try {ep.GetOverrideAddressesByBuildingHashText(null, null, null);}catch(Exception e){}
		new integraWS.GetOverrideAddressesByBuildingHashTextResponse_element();
		
		try {ep.GetProductFeaturePricing(null, null, null, null, null, null, null, null);}catch(Exception e){}
		new integraWS.GetProductFeaturePricingResponse_element();
		
		try {ep.GetProductFeaturePricingByPriceIDs(null, null, null);}catch(Exception e){}
		new integraWS.GetProductFeaturePricingByPriceIDsResponse_element();
		
        try {ep.GetRequestApprovals(null, null, null);}catch (Exception e){}
        new integraWS.GetRequestApprovalsResponse_element();
		
        try {ep.getRemarksByParentRecordIDs(null, null, null, null, null, null, null);}catch (Exception e){}
        new integraWS.getRemarksByParentRecordIDsResponse_element();
		
        //try {ep.GetSimilarBuildingsWithinRadius(null, null, null, null, null, null);}catch (Exception e){}
        //new integraWS.GetSimilarBuildingsWithinRadiusResponse_element();
        
        try {ep.GetServiceProductViewBySubscriberID(0,null,null);}catch(Exception e){}
        new integraWS.GetServiceProductViewBySubscriberIDResponse_element();
		
		try {ep.GetSubOrderListBySubscriberID(null, null, null);}catch(Exception e){}
		new integraWS.GetSubOrderListBySubscriberIDResponse_element();
		
		try {ep.GetSubOrderSummaryByOrderIDs(null, null, null, null);}catch(Exception e){}
		new integraWS.GetSubOrderSummaryByOrderIDsResponse_element();
        
        try {ep.GetSubOrderSummaryBySubscriberID(null,null,null,null);}catch(Exception e){}
        new integraWS.GetSubOrderSummaryBySubscriberIDResponse_element();
        
        try {ep.ProcessWorkFlowICCCallout(null,null,null,null,null);}catch(Exception e){}
        new integraWS.ProcessWorkFlowICCCalloutResponse_element();
        
        try {ep.SearchMSAGAddresses(null, null, null, null, null);}catch(Exception e){}
        new integraWS.SearchMSAGAddressesResponse_element();
		
		try {ep.UpdateMasterAddressIDByBuildingHash(null, null, null, null);}catch(Exception e){}
		new integraWS.UpdateMasterAddressIDByBuildingHashResponse_element();
        
        //try {ep.UpdateSubOrders(null,null,null);}catch(Exception e){}
        //new integraWS.UpdateSubOrdersResponse_element();
        
        try {ep.UpdateSubscriber(null,null,null);}catch(Exception e){}
        new integraWS.UpdateSubscriberResponse_element();
        
        try {ep.UpdateSubscriberAddresses(null, null, null);}catch(Exception e){}
        new integraWS.UpdateSubscriberAddressesResponse_element();
        
        try {ep.UpdateSubscriberContacts(null, null, null);}catch(Exception e){}
        new integraWS.UpdateSubscriberContactsResponse_element();
        
        try {ep.UpdateSubscriberHierarchies(null, null, null);}catch(Exception e){}
        new integraWS.UpdateSubscriberHierarchiesResponse_element();
        
        try {ep.UpdateSubscriberSettings(null, null, null);}catch(Exception e){}
        new integraWS.UpdateSubscriberSettingsResponse_element();
        
        try {ep.UpdateSubscriberTaxInformation(null, null, null);}catch(Exception e){}
        new integraWS.UpdateSubscriberTaxInformationResponse_element();
		
		try {ep.UploadDocument(null, null, null, null, null);}catch(Exception e){}
		new integraWS.UploadDocumentResponse_element();
		
		try {ep.UpsertOverriddenAddresses(null, null, null);}catch(Exception e){}
		new integraWS.UpsertOverriddenAddressesResponse_element();
        
        try {ep.ValidateBuildingAddress(null, null, null, null);}catch(Exception e){}
        new integraWS.ValidateBuildingAddressResponse_element();
        
        try {ep.ValidateSubscriberAddresses(null, null, null);}catch(Exception e){}
        new integraWS.ValidateSubscriberAddressesResponse_element();
    }

    static testMethod void testSecondarySchema() {
        new schemasMicrosoftCom200310Serializat();
        new schemasMicrosoftCom200310Serializat.ArrayOfKeyValueOfstringstring();
        new schemasMicrosoftCom200310Serializat.ArrayOfstring();
        new schemasMicrosoftCom200310Serializat.KeyValueOfstringstring_element();
    }
}