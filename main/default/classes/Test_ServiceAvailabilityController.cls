@isTest
private class Test_ServiceAvailabilityController {

	@isTest
	private static void testController() {
		string productid = JSON.Serialize(247);
		string bandwidth = JSON.Serialize(10);
		string terms = JSON.Serialize(new list<integer>{36});
		ServiceAvailabilityController ac = new ServiceAvailabilityController();
		ServiceAvailabilityController.GetPricing(productid, bandwidth, terms, '18110 SE 34th St Vancouver WA 98683');

		ServiceAvailabilityController.inputClass ic = new ServiceAvailabilityController.inputClass();
		ic.Building = new Building__c();
		ic.product = new SPC_Product__c();

		ServiceAvailabilityController.SFLocationProductPricingView lppv = new ServiceAvailabilityController.SFLocationProductPricingView(new integraWS.SFLocationProductPricingView());
		ServiceAvailabilityController.SFProductTermAccessTechPricingView ptatpv = new ServiceAvailabilityController.SFProductTermAccessTechPricingView(new integraWS.SFProductTermAccessTechPricingView());
		ServiceAvailabilityController.SFProductTermPricingView ptpv = new ServiceAvailabilityController.SFProductTermPricingView(new integraWS.SFProductTermPricingView());
		ServiceAvailabilityController.SFBandwidthPricingView bpv = new ServiceAvailabilityController.SFBandwidthPricingView(new integraWS.SFBandwidthPricingView());
		ServiceAvailabilityController.SFPricingAttributeView pav = new ServiceAvailabilityController.SFPricingAttributeView(new integraWS.SFPricingAttributeView());
		ServiceAvailabilityController.SFAccessTechPricingView atpv = new ServiceAvailabilityController.SFAccessTechPricingView(new integraWS.SFAccessTechPricingView());
		ServiceAvailabilityController.SFPricingView pv = new ServiceAvailabilityController.SFPricingView(new integraWS.SFPricingView());
	}
}