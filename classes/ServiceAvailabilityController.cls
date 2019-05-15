public class ServiceAvailabilityController { 	

	private List<decimal> bWidths {get;private set;}
	public List<SelectOption> bandwidths {
		get{
			List<SelectOption> ops = new List<SelectOption>();
			for(decimal bw : bWidths){
				ops.add(new SelectOption(string.valueOf(bw),string.valueOf(bw)));
			}
			return ops;
		}
	}

	public class inputClass{
		public SPC_Product__c product {get;set;}
		public Building__c building {get;set;}
	}

	public inputClass inputs {get;set;}


	public ServiceAvailabilityController(){
		bWidths = GetBandwidths();
		inputs = new InputClass();
	}

	@RemoteAction
	public static string GetPricing(string productId, string bandwidth, string terms, string address){
		SFLocationProductPricingView pricingViews = null;

		system.debug('inpBandwidth: ' + bandwidth);
		system.debug('inpTerms: ' + terms);
		system.debug('inpProductId: ' + productId);
		double selBandwidth = (double)JSON.deserialize(bandwidth, double.class);
		List<integer> selTerms = (List<integer>)JSON.deserialize(terms, List<integer>.class);
		integer selProductId = (integer)JSON.deserialize(productId, integer.class);
		
		system.debug('bandwidth: ' + selBandwidth);
		system.debug('terms: ' + selTerms);
		system.debug('productId: ' + selProductId);
		system.debug('address: ' + address);
		if(integraWSEndpointMediator.integrationEnabled()){
			schemasMicrosoftCom200310Serializat.ArrayOfdouble arrBandwidth = new schemasMicrosoftCom200310Serializat.ArrayOfdouble();
			schemasMicrosoftCom200310Serializat.ArrayOfint arrTerms = new schemasMicrosoftCom200310Serializat.ArrayOfint();
			arrBandwidth.double_x = new List<Double>{selBandwidth};
			arrTerms.int_x = selTerms;
			integer intProductId = selProductId;
			//'3125 NW 35th Ave Portland OR 97210';
			integraWS.SFLocationProductPricingView wsView = integraWSEndpointMediator.Endpoint.GetPricingForBuilding(arrBandwidth, arrTerms, intProductId, address, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
			system.debug('wsView: ' + wsView);
			pricingViews = new SFLocationProductPricingView(wsView);
			system.debug('pricingViews: ' + pricingViews);
		}
		return JSON.serialize(pricingViews,true);
	}

	private List<decimal> GetBandwidths(){
		List<decimal> bws = new List<decimal>();
		
		for(AggregateResult ar :[Select Bandwidth_Text__c From SPC_Component__c Where Access_Technology_Name__c = 'EoF' and Bandwidth__c != 0 and Bandwidth__c != null Group BY Bandwidth_Text__c]){
			bws.add(decimal.valueOf(string.valueOf(ar.get('Bandwidth_Text__c'))));
		}
		return bws;
	}

	public class SFLocationProductPricingView{
		public Double HurdleRate{get;set;}
        public String LSO{get;set;}
        public String Location{get;set;}
        public Double MaxBandwidth{get;set;}
		public List<SFProductTermAccessTechPricingView> ProductPrices{get;set;}

		public SFLocationProductPricingView(integraWS.SFLocationProductPricingView wsView){
			if(wsView != null){
				this.HurdleRate = wsView.HurdleRate;
				this.LSO = wsView.LSO;
				this.Location = wsView.Location;
				this.MaxBandwidth = wsView.MaxBandwidth;
				this.ProductPrices = new List<SFProductTermAccessTechPricingView>();
				for(integraWS.SFProductTermAccessTechPricingView v : wsView.ProductPrices != null && wsView.ProductPrices.SFProductTermAccessTechPricingView != null? wsView.ProductPrices.SFProductTermAccessTechPricingView : new List<integraWS.SFProductTermAccessTechPricingView>()){
					this.productPrices.add(new SFProductTermAccessTechPricingView(v));
				}
			}
		}
	}
	public class SFProductTermAccessTechPricingView{
		public List<SFPricingAttributeView> ProductAttributes{get;set;}
        public Integer ProductID{get;set;}
        public String ProductName{get;set;}
        public List<SFProductTermPricingView> ProductTermAccessPrices{get;set;}
        public List<SFProductTermAccessTechPricingView> RelatedProductPricingViews{get;set;}

		public SFProductTermAccessTechPricingView(integraWS.SFProductTermAccessTechPricingView wsView){
			if(wsView != null){
				this.ProductAttributes = new List<SFPricingAttributeView>();
				for(integraWS.SFPricingAttributeView v : wsView.ProductAttributes != null && wsView.ProductAttributes.SFPricingAttributeView != null? wsView.ProductAttributes.SFPricingAttributeView : new List<integraWS.SFPricingAttributeView>()){
					this.ProductAttributes.add(new SFPricingAttributeView(v));
				}
				this.ProductID = wsView.ProductID;
				this.ProductName = wsView.ProductName;
				this.ProductTermAccessPrices = new List<SFProductTermPricingView>();
				for(integraWS.SFProductTermPricingView v : wsView.ProductTermAccessPrices != null && wsView.ProductTermAccessPrices.SFProductTermPricingView != null? wsView.ProductTermAccessPrices.SFProductTermPricingView : new List<integraWS.SFProductTermPricingView>()){
					this.ProductTermAccessPrices.add(new SFProductTermPricingView(v));
				}
				this.RelatedProductPricingViews = new List<SFProductTermAccessTechPricingView>();
				for(integraWS.SFProductTermAccessTechPricingView v :wsView.RelatedProductPricingViews != null && wsView.RelatedProductPricingViews.SFProductTermAccessTechPricingView != null? wsView.RelatedProductPricingViews.SFProductTermAccessTechPricingView : new List<integraWS.SFProductTermAccessTechPricingView>()){
					this.RelatedProductPricingViews.add(new SFProductTermAccessTechPricingView(v));
				}
			}
		}
	}
	public class SFProductTermPricingView{
		public List<SFBandwidthPricingView> BandwidthAccessTechPrices{get;set;}
        public Integer Term{get;set;}

		public SFProductTermPricingView(integraWS.SFProductTermPricingView wsView){
			if(wsView != null){
				this.BandwidthAccessTechPrices = new List<SFBandwidthPricingView>();
				for(integraWS.SFBandwidthPricingView v : wsView.BandwidthAccessTechPrices != null && wsView.BandwidthAccessTechPrices.SFBandwidthPricingView != null? wsView.BandwidthAccessTechPrices.SFBandwidthPricingView : new List<integraWS.SFBandwidthPricingView>()){
					this.BandwidthAccessTechPrices.add(new SFBandwidthPricingView(v));
				}
				this.Term = wsView.Term;
			}
		}
	}
	public class SFBandwidthPricingView{
		public List<SFAccessTechPricingView> AccessTechPrices{get;set;}
        public Double Bandwidth{get;set;}

		public SFBandwidthPricingView(integraWS.SFBandwidthPricingView wsView){
			if(wsView != null){
				this.AccessTechPrices = new List<SFAccessTechPricingView>();
				for(integraWS.SFAccessTechPricingView v : wsView.AccessTechPrices != null && wsView.AccessTechPrices.SFAccessTechPricingView != null? wsView.AccessTechPrices.SFAccessTechPricingView : new List<integraWS.SFAccessTechPricingView>()){
					this.AccessTechPrices.add(new SFAccessTechPricingView(v));
				}
				this.Bandwidth = wsView.Bandwidth;
			}
		}
	}
	public class SFPricingAttributeView{
		public String Name{get;set;}
        public Double Price{get;set;}

		public SFPricingAttributeView(integraWS.SFPricingAttributeView wsView){
			if(wsView != null){
				this.Name = wsView.Name;
				this.Price = wsView.Price;
			}
		}
	}
	public class SFAccessTechPricingView{
		public String AccessTechName{get;set;}
        public List<SFPricingView> Prices{get;set;}

		public SFAccessTechPricingView(integraWS.SFAccessTechPricingView wsView){
			if(wsView != null){
				this.AccessTechName = wsView.AccessTechName;
				this.Prices = new List<SFPricingView>();
				for(integraWS.SFPricingView v : wsView.Prices != null && wsView.Prices.SFPricingView != null? wsView.Prices.SFPricingView : new List<integraWS.SFPricingView>()){
					this.Prices.add(new SFPricingView(v));
				}
			}
		}
	}
	public class SFPricingView{
		public String LocationType{get;set;}
		public Double MRR{get;set;}
        public Double MRRFloor{get;set;}
        public Double NRR{get;set;}
        public Double NRRFloor{get;set;}
        public Integer QualificationStatus{get;set;}
        public String QualificationStatusDescription{get;set;}
        public Boolean QuotePrice{get;set;}
        public Integer RatePlanID{get;set;}
        public String RatePlanName{get;set;}
        public List<SFPricingView> RequiredPricing{get;set;}

		public SFPricingView(integraWS.SFPricingView wsView){
			if(wsView != null){
				this.LocationType = wsView.LocationType;
				this.MRR = wsView.MRR;
				this.MRRFloor = wsView.MRRFloor;
				this.NRR = wsView.NRR;
				this.NRRFloor = wsView.NRRFloor;
				this.QualificationStatus = wsView.QualificationStatus;
				this.QualificationStatusDescription = wsView.QualificationStatusDescription;
				this.QuotePrice = wsView.QuotePrice;
				this.RatePlanID = wsView.RatePlanID;
				this.RatePlanName = wsView.RatePlanName;
				this.RequiredPricing = new List<SFPricingView>();
				for(integraWS.SFPricingView v : wsView.RequiredPricing != null && wsView.RequiredPricing.SFPricingView != null? wsView.RequiredPricing.SFPricingView : new List<integraWS.SFPricingView>()){
					this.RequiredPricing.add(new SFPricingView(v));
				}
			}
		}
	}
}