public with sharing class ConfigureSolutionController implements TestUtils.ITestableClass {
	
	//Page mode
	public Boolean renderPage { get; set; }
	public Boolean multiSolutionMode { get; set; }
	public Boolean doValidation {get;Set;}
	public Boolean isFiltered {get;Set;}
	
	public String ICCSubscriberID {get;Set;}
	
	//For single solution
	public String olcID { get; set; }
	public OpportunityLocationConfiguration__c opportunityLocationConfiguration { get; private set; }
	
	//For multi-solutions
	public String oppID { get; set; }
	
	//Related objects
	public Account account { get; set; }
	public Opportunity opportunity { get; set; }
	public Order__c order { get; set; }
	public List<Building_Access_Availability__c> locationBAA { get; set; }
	
	//Pricing, products, OLIs
	public Map<String, List<OLIView>> loadedPricing { get; set; }	//Persisted and new OLIs that have been loaded for the page by product external ID
	private Map<String, List<OLIView>> persistedOLIs { get; private set; }	//Persisted OLI list that has not been loaded for the page yet by product external ID
	public List<String> sortedProductGroups { get; set; }
	public Map<String, List<String>> sortedProductsByGroup { get; set; }
	
	//Dummy objects
	public OpportunityLocationConfiguration__c configOLC { get; private set; }
	public OLI__c dummyOLI { get; set; }
	
	//SelectOption related
	public List<SelectOption> availableBandwidths { get; set; }
	public List<SelectOption> availableTerms { get; set; }
	
	public List<SelectOption> accessTechs {
		get{
			List<SelectOption> l = new List<SelectOption>{new SelectOption('', 'All Selected')};
			for(Access_Technology__c at : [select Name from Access_Technology__c Where Access_Technology_ID__c in (1, 2, 3, 4) order by Name])
				l.add(new SelectOption(at.Name, at.Name));
			return l;
		}
	}
	
	public Component.Apex.SelectList viewList {
		get{
			Component.Apex.SelectList retval;
			
			if(!renderPage) return retval;
			
			DynamicVisualforceBuilder b = new DynamicVisualforceBuilder();
			retval = b.buildSelectList(false
										,1
										,new List<ApexPages.Component>{(selectedProduct == null) ? b.buildSelectListOption('Choose a product', '', null) : b.buildSelectListOption('Current Solution', 'SOLUTION', null)}
										,new Map<String, String>{'id'=>'selectView', 'value'=>'{!selectedProduct}'});
			
			Map<String, List<SPC_Product__c>> pm = getProductsByGroupMap();
			for(String productGroup : sortedProductGroups){
				List<SPC_Product__c> products = pm.get(productGroup);
				if(products != null){
					retval.childComponents.add(b.buildSelectListOption(productGroup, productGroup, new Map<String, String>{'disabled'=>'true'}));
					
					for(String sortedProduct : sortedProductsByGroup.get(productGroup)){
						for(SPC_Product__c prd : products){
							if(prd.Name == sortedProduct && !prd.hide_in_wizard__c)
								retval.childComponents.add(b.buildSelectListOption(prd.Name, string.valueOf(prd.SalesProductExternalID__c), null));
						}
					}
				}
			}
			
			return retval;
		}
	}
	
	//Selection state
	public String selectedAccessTech { get; set; }
	public List<string> selectedBandwidths { get; set; }
	public String selectedProduct { get; set; }
	
	//Discount Authority
	public DiscountAuthorityLevels__c discountAuthorityLevel { get; set;}
	
	/* DTOs */
	public class OLIView extends ApexUtils.SortableClass{
		public OLI__c oli { get; set; }
		public Integer term { get; set; }
		public List<OLIView> children { get; private set; }
		public OLIView parent { get; private set; }
		
		public Id secondaryLocID { get; set; }
		public Boolean requireZLocation { get; private set; }
		
		public Boolean isPickOne { get; private set; }
		public String salesSelectionRule {
			get;
			private set{
				salesSelectionRule = value;
				isPickOne = value != null && !value.Contains('or More') && value.replace('-', ' ').Contains('Pick One');
			}
		}
		
		public Boolean updated { get; set; }
		public Boolean isAutoInclude { get; private set; }
		public Boolean isFeature { get; private set; }
		public Boolean isExpired { get; set; }
		public Boolean isNonDiscountable {get; set;}
		public Boolean availableInWizard {get;Set;}
		public Boolean canDuplicate { get; private set; }
		public Boolean canRemove { get; private set; }
		
		public Boolean persist {get; set;}	//Don't throw away in the viewstate
		
		public OLIView(OLI__c oli, Integer term, String salesSelectionRule){
			this.oli = oli;
			this.term = term;
			this.salesSelectionRule = salesSelectionRule;
			secondaryLocID = oli.Secondary_Location__c != null ? oli.Secondary_Location__c : oli.Secondary_Service_Location__c;
			requireZLocation = secondaryLocID != null;
			canDuplicate = false;
			persist = false;
			setDefaults();
		}
		
		public OLIView(OLIView cloneFrom){
			oli = cloneFrom.oli;
			term = cloneFrom.term;
			salesSelectionRule = cloneFrom.salesSelectionRule;
			secondaryLocID = null;
			requireZLocation = cloneFrom.requireZLocation;
			canDuplicate = cloneFrom.canDuplicate;
			persist = true;
			availableInWizard = cloneFrom.availableInWizard;
			cloneFrom.persist = true;
			setDefaults();
		}
		
		private void setDefaults(){
			children = new List<OLIView>();
			updated = false;
			isAutoInclude = false;
			isFeature = false;
			canRemove = false;
		}
		
		public void autoInclude(OLIView child){
			children.add(child);
			child.parent = this;
			child.isAutoInclude = true;
		}
		
		public void addFeature(OLIView child){
			children.add(child);
			child.parent = this;
			child.isFeature = true;
		}
		
		private String pathName(){
			return (parent != null ? parent.pathName() + ': ' : '') + oli.PP_Product_Pricing_Name__c;
		}
		
		public override object getFieldImp(String fName){
			if(fName == 'Term') return term;
			if(fName == 'ProductPathName') return pathName();
			if(fName == 'SalesSelectionRule'){
				String ssr = (parent != null ? parent : this).salesSelectionRule;
				return ssr != null ? ssr : '';
			}
			return null;
		}
	}
	
	public ConfigureSolutionController() {
		
		renderPage = SecurityUtils.checkObjectAccess(OLI__c.getsObjectType(), false, true);
		renderPage &= SecurityUtils.checkObjectAccess(SPC_Pricing__c.getsObjectType(), true, true);
		renderPage &= SecurityUtils.checkObjectAccess(SPC_Product__c.getsObjectType(), true, true);
		
		if(!renderPage) return;
		
		loadedPricing = new Map<String, List<OLIView>>();
		persistedOLIs = new Map<String, List<OLIView>>();
		configOLC = new OpportunityLocationConfiguration__c(Term__c='0');
		olcID = Apexpages.currentPage().getParameters().get('opportunityLocationConfigurationId');
		doValidation = CustomSettingUtils.getOverrideSettingValue('Enable CPQ Validations');

		if(!string.isEmpty(olcID)){
			opportunityLocationConfiguration = getSolution(olcID);
			doValidation &= opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.ICC_Subscriber_ID__c == null;
			ICCSubscriberID = String.isEmpty(opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.ICC_Subscriber_ID__c)?'None':opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.ICC_Subscriber_ID__c;
			configOLC.Bandwidth__c = opportunityLocationConfiguration.Bandwidth__c;
			configOLC.Term__c = opportunityLocationConfiguration.Term__c;
			configOLC.Name = opportunityLocationConfiguration.Name;
			oppID = opportunityLocationConfiguration != null ? opportunityLocationConfiguration.Opportunity_Location__r.Order__r.Opportunity__c : null;
		}
		else oppID = Apexpages.currentPage().getParameters().get('opportunityId');
		
		if(!string.isEmpty(oppID)){
			List<Opportunity> o = [select Id, Name, AccountId,CPQ_Total__c, MRC_Floor_Total__c,CPQ_MRC_List_Total__c  from Opportunity where Id =: oppID];
			if(o.size() == 1){
				opportunity = o[0];
				account = [select Id, Name from Account where Id =: opportunity.AccountId];
				
				if(opportunityLocationConfiguration != null && opportunityLocationConfiguration.Opportunity_Location__r.Order__c != null)
					order = [select Id, Name from Order__c where Id =: opportunityLocationConfiguration.Opportunity_Location__r.Order__c];
			}
		}
		
		if(opportunityLocationConfiguration == null && opportunity == null){
			ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'A valid solution or opportunity ID is required to configure pricing'));
			renderPage = false;
		}
		else{
			dummyOLI = new OLI__c();
			multiSolutionMode = opportunityLocationConfiguration == null && opportunity != null;
			
			Map<String, List<SPC_Product__c>> productMap = getProductsByGroupMap();
			
			//Sort the product groups
			sortedProductGroups = getSPCSortOrder('None', 'None', productMap.keySet());
			
			//Sort the products under their groups and retrieve their Z-Location modes
			sortedProductsByGroup = new Map<String, List<String>>();
			zLocModes = new Map<Id, String>();
			for(String productGroup : sortedProductGroups){
				Set<String> productNames = new Set<String>();
				for(SPC_Product__c spc : productMap.get(productGroup)){
					productNames.add(spc.Name);
					zLocModes.put(spc.Id, spc.Z_Location_Type__c);
				}
				
				sortedProductsByGroup.put(productGroup, getSPCSortOrder('Product Group', productGroup, productNames));
			}
			
			Set<Id> secLocIDs = new Set<Id>();
			persistedOLIs = getPersistedPricingOLIMap(opportunityLocationConfiguration, secLocIDs);
			
			List<Service_Location__c> sLocs = [select Id, Name, Location__c, Location__r.Name, ICC_Subscriber_ID__c from Service_Location__c where Account__c =: account.Id order by Name];
			for(Service_Location__c sLoc : sLocs)
				secLocIDs.add(sLoc.Location__c);
			
			secLocNames = new Map<Id, String>();
			secondaryLocationOptions = getSecondaryLocationSelectOptions([select Id, Name from Location__c where Id in: secLocIDs order by Name], false, secLocNames);
			secondaryServiceLocationOptions = getSecondaryLocationSelectOptions(sLocs, true, secLocNames);
			
			availableTerms = getAvailableTerms(Integer.valueOf(configOLC.Term__c == 'Month to Month' ? '1' : configOLC.Term__c));
			availableBandwidths = getAvailableBandwidths();
			
			locationBAA = getDefaultAccessTechs(opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.Location__r.Building__c);
			selectedAccessTech = getDefaultAccessTechByHierarchy(locationBAA);
			
            //If we already have some saved OLIs, default to the current solution
			if(persistedOLIs.size() > 0){
				selectedProduct = 'SOLUTION';
				GetPricing();
			}
            
			approvalBtnVisability();
			
			renderPage = true;
		}
	}
	
	/* Setup methods */
	private List<SelectOption> getAvailableBandwidths(){
		List<SelectOption> l = new List<SelectOption>();
		
		for(Schema.PicklistEntry pe : OpportunityLocationConfiguration__c.fields.Bandwidth__c.getDescribe().getPicklistValues()){
			try{
				l.add(new SelectOption(pe.getLabel(), pe.getLabel()));
			} catch(Exception e){ }
		}
		
		return l;
	}
	
	private List<SelectOption> getAvailableProductBandwidths(String selectedProduct, String sat, Map<String, Map<String, Set<Decimal>>> availableATProductBandwidths){
		List<SelectOption> l = new List<SelectOption>();
		Set<Decimal> bandwidths = new Set<Decimal>();
		
		//No selected AccessTech return all BW's for product
		
		List<Set<Decimal>> CoolBandwidths = String.isEmpty(sat) ? availableATProductBandwidths.get(selectedProduct).values() : new List<Set<Decimal>>{availableATProductBandwidths.get(selectedProduct).get(sat), availableATProductBandwidths.get(selectedProduct).get('')};
		for(Set<Decimal> s : CoolBandwidths){
			if(s != null) bandwidths.addAll(s);
		}
		
		/*if(String.IsEmpty(sat)){
			for(Set<Decimal> bws : availableATProductBandwidths.get(selectedProduct).values()){
                bandwidths.addAll(bws);
			}
		}
		else{
			
		}*/
		
		List<Decimal> bwsL = new List<Decimal>(bandwidths);
		bwsl.sort();
		//remove trailing 0's.
		String regex = '(\\d*\\.\\d+?)(0+)';
		Pattern pat = Pattern.compile(regex);
		for(Decimal bw :bwsl){
			String val = String.valueOf(bw);
			Matcher m = pat.matcher(val);
			if(m.matches())
				val = m.group(1);
			l.add(new SelectOption(val,val));
		}
		
		return l;
	}
	
	private List<SelectOption> getAvailableTerms(Integer maxTerm){
		List<SelectOption> l = new List<SelectOption>();
		for(Schema.PicklistEntry pe : OpportunityLocationConfiguration__c.fields.Term__c.getDescribe().getPicklistValues()){
			try{
				Integer t = Integer.valueOf(pe.getLabel());
				if(maxTerm == 0 || t <= maxTerm)
					l.add(new SelectOption(pe.getLabel(), pe.getLabel()));
			} catch(Exception e){ }
		}
		return l;
	}
	
	private static String getDefaultAccessTechByHierarchy(List<Building_Access_Availability__c> baas){
		
		string accessTechValues = customSettingUtils.getSingleProcessConfigurationValue('CPQAccessTechDefaultSort', 'AccessTechHierarcy', false);
		List<String> accessTechsOrdered = accessTechValues != null ? accessTechValues.split(';') : new List<String>();
		
		for(string s : accessTechsOrdered){
			for(Building_Access_Availability__c baa : baas){
				if(baa.Access_Technology_Name__c == s)
					return customSettingUtils.getSingleProcessConfigurationValue('CPQAccessTechDefault', s, false);
			}
		}
		
		return null;
	}
	
	private static List<Building_Access_Availability__c> getDefaultAccessTechs(Id buildingID){
		return (buildingID != null)
            			? [select Access_Technology__r.Name, Access_Technology_Name__c, Maximum_Bandwidth__c, Minimum_Required_Revenue__c, Status__c from Building_Access_Availability__c where Building__c =: buildingID]
            			: new List<Building_Access_Availability__c>();
	}
	
	private static final Set<String> oliFields = SchemaUtils.RetrieveFullObjectFieldSet(OLI__c.getsObjectType());
	private Map<String, List<OLIView>> getPersistedPricingOLIMap(OpportunityLocationConfiguration__c olc, Set<Id> secLocIDs){
		Map<String, List<OLIView>> retval = new Map<String, List<OLIView>>();
		
		if(olc != null){
			Integer term = Integer.valueOf(olc.Term__c == 'Month to Month' ? '1' : olc.Term__c);
			
			List<OLI__c> oliList =  (List<OLI__c>)(ApexUtils.retrieveObjectsFromFieldSets(
																OLI__c.getsObjectType()
																,new List<Set<String>>{ oliFields }
																,'OpportunityLocationConfiguration__c = \'' + olc.Id + '\''
																,null));
			Map<Id, OLIView> allViews = new Map<Id, OLIView>();
			Set<String> pricingIDs = new Set<String>();
			for(OLI__c oli : oliList){
				OLIView v = new OLIView(oli, term, null);
				allViews.put(oli.Id, v);
				pricingIDs.add(oli.Price_Id__c);
				
				if(oli.Secondary_Location__c != null && secLocIDs != null) secLocIDs.add(oli.Secondary_Location__c);
				
				if(oli.Parent_Opportunity_Line_Item__c == null){
					List<OLIView> l = retval.get(oli.PP_SalesProductExternalID__c) != null ? retval.get(oli.PP_SalesProductExternalID__c) : new List<OLIView>();
					l.add(v);
					retval.put(oli.PP_SalesProductExternalID__c, l);
				}
			}
			
			Set<Decimal> componentIDs = new Set<Decimal>();
			Set<Decimal> spcIds = new Set<Decimal>();
			Map<String, SPC_Pricing__c> spcMap = new Map<String, SPC_Pricing__c>();
			for(SPC_Pricing__c spc : CatalogUtils.GetPricingByPricingID(new List<String>(pricingIDs))){
				spcMap.put(spc.Price_ID__c, spc);
				componentIDs.add(spc.Component_ID__c);
				spcIds.add(spc.Sales_Product_ID__c);
			}
			
			CatalogUtils.GetRelations(componentIDs, spcIds);
			
			//Set pricing values
			for(OLIView v : allViews.values()){
				SPC_Pricing__c p = spcMap.get(string.valueOf(v.oli.Price_Id__c));
				if(p != null){
					SPC_Product__c prd = getSPCProductByExternalID(p.Sales_Product_ID__c);
					v.salesSelectionRule = getSelectionRule(p.Sales_Product_Component_ID__c, null);
					v.requireZLocation = p.Z_Location_Required__c;
					v.isNonDiscountable = p.Is_Non_Discountable__c;
					v.canDuplicate = prd == null ? false : prd.Allow_Duplicate_Price_OLIs__c == null ? false : prd.Allow_Duplicate_Price_OLIs__c;
					v.isExpired = p.Is_Expired__c;
					v.availableInWizard = p.Available_In_Wizard__c;
				}
				else{
					//OLI Pricing no longer exists
					v.isExpired = true;
				}
			}
			
			//Set child values
			for(OLIView v : allViews.values()){
				OLIView pv = v.oli.Parent_Opportunity_Line_Item__c != null ? allViews.get(v.oli.Parent_Opportunity_Line_Item__c) : null;
				if(pv != null)
					addOLIChild(pv, v, spcMap.get(pv.oli.Price_Id__c));
			}
		}
		
		return retval;
	}
	
	private static final Set<String> bldgFields = new Set<String>{
		'Id'
		,'Market_Area_ID__c'
		,'LSO_CLLI__c'
		,'Address__c'
		,'Building_Hash__c'
		,'Net_Classification__c'
		,'Serving_LSO__r.LSO_CLLI__c'
		,'Serving_LSO__r.Net_Classification__c'
		,'Name'
		,'Status__c'
	};
	
	private static final Set<String> olcFields = new Set<String>{
		'Id'
		,'Name'
		,'Term__c'
		,'Bandwidth__c'
		,'Active__c'
	};
	
	private OpportunityLocationConfiguration__c getSolution(String olcID){
		String solQueryFields = getFieldsStringFromPath('', olcFields);
		solQueryFields += ',' + getFieldsStringFromPath('Opportunity_Location__r', new Set<String>{ 'Id', 'Name' });
		solQueryFields += ',' + getFieldsStringFromPath('Opportunity_Location__r.Order__r.Opportunity__r', new Set<String>{ 'Id' });
		solQueryFields += ',' + getFieldsStringFromPath('Opportunity_Location__r.Service_Location__r', new Set<String>{ 'Id', 'Billable__c', 'Name', 'ICC_Subscriber_ID__c' });
		solQueryFields += ',' + getFieldsStringFromPath('Opportunity_Location__r.Service_Location__r.Location__r.Building__r', bldgFields);
		
		List<OpportunityLocationConfiguration__c> sols = !String.isEmpty(olcID)
														? (List<OpportunityLocationConfiguration__c>)Database.query('select ' + solQueryFields + ' from OpportunityLocationConfiguration__c where Id = \'' + olcID + '\'')
														: new List<OpportunityLocationConfiguration__c>();
		
		return (sols.size() > 0) ? sols.get(0) : null;
	}
	
	/* Callback methods */
	public void AddRemovePriceRow(){
		String priceID = Apexpages.currentPage().getParameters().get('priceID');
		Boolean addMode = Apexpages.currentPage().getParameters().get('addMode') == 'true';
		
		Integer offset = Integer.valueOf(Apexpages.currentPage().getParameters().get('offset'));
		Integer currentOffset = 0;
		
		system.debug((addMode ? 'Adding' : 'Removing') + ' price with ID "' + priceID + '" at position ' + offset);
		List<OLIView> l = loadedPricing.get(selectedProduct);
		for(Integer i=0; i<l.size(); i++){
			if(l[i].oli.Price_ID__c == priceID){
				if(currentOffset == offset){
					if(addMode){
						OLIView cloneView = new OLIView(l[i]);
						cloneView.oli = cloneOLI(l[i].oli);
						for(OLIView child : l[i].children){
							OLIView cloneChildView = new OLIView(child);
							cloneChildView.parent = cloneView;
							cloneChildView.oli = cloneOLI(child.oli);
							cloneView.children.add(cloneChildView);
						}
						l.add(cloneView);
					}
					else{
						l.remove(i);
					}
					break;
				}
				else{
					currentOffset++;
				}
			}
		}
	}
	
	public Boolean displaySecondaryLocation { get; set; }
	public transient String JSONCurrentRelationsBySalesProdExtId { get; set; }
	
	public Map<String, Map<String, List<OLIView>>> pricingSortOrder { get; set; }
	public List<String> pricingSortOrderKeys { get; set; }
	public void GetPricing(){
		pricingSortOrder = new Map<String, Map<String, List<OLIView>>>();
		pricingSortOrderKeys = new List<String>();
		displaySecondaryLocation = false;
		isFiltered = false;
		
		if(String.isEmpty(selectedProduct)) return;	//Nothing to do, display nothing
		system.debug('Retrieving pricing for "' + selectedProduct + '"');
		
		List<OLIView> selectedPricing = new List<OLIView>();
		Boolean filterMaxTerms = true;
		Map<String, Map<String, Set<Decimal>>> availableATProductBandwidths = new Map<String, Map<String, Set<Decimal>>>();
		Map<String, Set<decimal>> accessProdBandwidths = new Map<String, Set<decimal>>();
		
		//Required component IDs based on selected product
		Map<String, List<SPC_Component_Relation__c>> currentRelationsBySalesProdExtId = null;
        
        //Dump all pricing that is not persisted or selected
		for(String key : loadedPricing.keySet()){
			List<OLIView> p2s = new List<OLIView>();
			for(OLIView lPricing : loadedPricing.get(key)){
				if((lPricing.oli.Qty__c > 0 || lPricing.oli.Id != null || lPricing.persist) && lPricing.parent == null){
					p2s.add(lPricing);
				}
			}
			loadedPricing.put(key, p2s);
		}
		
		Boolean isCurrentSolution = selectedProduct == 'SOLUTION';
		if(isCurrentSolution){
			getActiveSolutionOLIs(persistedOLIs, selectedPricing);
			getActiveSolutionOLIs(loadedPricing, selectedPricing);
			
			Map<String, List<OLIView>> olisToValidate = multiSolutionMode ? getOLIsByTerm() : getOLIsToValidate(selectedPricing, olcID);
			validateOLISet(olisToValidate);
			
			filterMaxTerms = false;	
		}
		else{
			//Pull the persisted OLIs
			List<OLIView> persisted = persistedOLIs.get(selectedProduct);
			List<OLIView> selected = loadedPricing.get(selectedProduct);
			persistedOLIs.remove(selectedProduct);
			
			//Get the pricing by product and replace with anything we have persisted already
			string buildingHash = opportunityLocationConfiguration != null ? opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_Hash__c : null;
			List<CatalogUtils.SPCPricingView> retval = CatalogUtils.GetProductFeaturePricingViews(new List<Integer>(), 0, buildingHash, new List<Integer>{integer.valueOf(selectedProduct)}, new List<integer>());
			
			Set<Decimal> componentIDs = new Set<Decimal>();
			Set<Decimal> spcIds = new Set<Decimal>();
			for(CatalogUtils.SPCPricingView v : retval){
				componentIDs.add(v.pricing.Sales_Product_Component_ID__c);
				spcIds.add(v.pricing.Sales_Product_ID__c);
				for(CatalogUtils.SPCPricingView cv : v.children){
					componentIDs.add(cv.pricing.Sales_Product_Component_ID__c);
					spcIds.add(cv.pricing.Sales_Product_ID__c);
				}
			}
			currentRelationsBySalesProdExtId = CatalogUtils.GetRelations(componentIDs, spcIds);	//Get component relations now for use in building OLIs
			
			for(CatalogUtils.SPCPricingView v : retval){
				
				String featureGroup = v.pricing.Component_Group__c;
				if(v.pricing.bandwidth__c != null){
					String accessTech = v.pricing.Access_Technology_Name__c == null ? '' : v.pricing.Access_Technology_Name__c;
					
					Set<Decimal> bws = accessProdBandwidths.get(accessTech) != null ? accessProdBandwidths.get(accessTech) : new Set<Decimal>();
					bws.add(v.pricing.bandwidth__c.setScale(3));
					accessProdBandwidths.put(accessTech, bws);
				}
				
				getLineItem(v, selectedPricing, (persisted != null) ? persisted : ((selected != null) ? selected : new List<OLIView>()));
			}
			
			//Re-add any OLIs that we didn't match on in getLineItem
			if(persisted != null) selectedPricing.addAll(persisted);
			if(selected != null) selectedPricing.addAll(selected);
			
			availableATProductBandwidths.put(selectedProduct, accessProdBandwidths);
			availableBandwidths = getAvailableProductBandwidths(selectedProduct,selectedAccessTech,availableATProductBandwidths);
			
			loadedPricing.put(selectedProduct, selectedPricing);
		}
			
		ApexUtils.SortBy(selectedPricing, new List<String>{'Term', 'ProductPathName', 'SalesSelectionRule'});
		
		selectedPricing = filterLineItems(selectedPricing, isCurrentSolution, filterMaxTerms);
		
		if(currentRelationsBySalesProdExtId == null){
			List<OLI__c> currentOLIs = new List<OLI__c>();
			for (OLIView oliv : selectedPricing)
				currentOLIs.add(oliv.oli);
			
			currentRelationsBySalesProdExtId = CatalogUtils.GetRelations(currentOLIs);
		}
		
		
		//Finalize the display
		selectedPricing = placeChildrenUnderParents(selectedPricing);
		
		JSONCurrentRelationsBySalesProdExtid = JSON.serialize(CurrentRelationsBySalesProdExtId);
		
		//Group by feature group (product) or product name (solution)
		Map<String, List<OLIView>> groupedSelectedPricing = new Map<String, List<OLIView>>();
		for(OLIView v : selectedPricing){
			String grp = (!isCurrentSolution)
							? (v.Parent != null ? v.parent.oli.SPC_Feature_Group__c : v.oli.SPC_Feature_Group__c)
							: AllSPCProducts.get(v.oli.SPC_Sales_Product__c) == null ? '' : AllSPCProducts.get(v.oli.SPC_Sales_Product__c).Name;
			grp = (grp != null) ? grp : '';
			List<OLIView> l = groupedSelectedPricing.get(grp) != null ? groupedSelectedPricing.get(grp) : new List<OLIView>();
			l.add(v);
			groupedSelectedPricing.put(grp, l);
		}
		
		//Build the sort order by group key and sales selection rule (product) or all available pricing (solution)
		for(String k : groupedSelectedPricing.keyset()){
			Set<String> s = new Set<String>();
			if(!isCurrentSolution){
				for(OLIView v : groupedSelectedPricing.get(k) == null ? new List<OLIView>() : groupedSelectedPricing.get(k)){
					s.add(!string.isEmpty(v.salesSelectionRule) ? v.salesSelectionRule : '');
				}
			}
			else s.add('ALL');
			
			List<String> l = new List<String>(s);
			l.sort();
			
			Map<String, List<OLIView>> m = new Map<String, List<OLIView>>();
			for(String sortBy : l){
				String sb = (sortBy != '') ? sortBy : '';
				List<OLIView> olis = new List<OLIView>();
				for(OLIView v : groupedSelectedPricing.get(k)){
					displaySecondaryLocation |= (v.requireZLocation || v.secondaryLocID != null);
					String sr = (v.parent != null)
											? (!string.isEmpty(v.parent.salesSelectionRule) ? v.parent.salesSelectionRule : '')
											: (!string.isEmpty(v.salesSelectionRule) ? v.salesSelectionRule : '');
					if(sb == 'ALL' || sr == sb){
						olis.add(v);
					}
				}
				
				if(olis.size() > 0) m.put(sb, olis);
			}
			
			if(m.size() > 0) pricingSortOrder.put(k, m);
		}
		
		if(!isCurrentSolution) {
			pricingSortOrderKeys = getSPCSortOrder('SPC_Product__c', getSPCProductByExternalID(Integer.valueOf(selectedProduct)).Name, pricingSortOrder.keySet());
			//we got filters?
			if(!String.isEmpty(selectedAccessTech) || (selectedBandwidths != null && selectedBandwidths.size() > 0))
				isFiltered = true;
		}
		else{
			Map<String, List<SPC_Product__c>> pm = getProductsByGroupMap();
			for(String pg : sortedProductGroups){
				List<SPC_Product__c> groupProducts = pm.get(pg);
				for(SPC_Product__c prod : groupProducts){
					if(pricingSortOrder.containsKey(prod.Name))
						pricingSortOrderKeys.add(prod.Name);
				}
			}
			pricingSortOrderKeys.sort();	//Sort alphabetically since the group is not shown
		}
	}
	
	private Boolean SaveLineItems(){
		List<OLIView> selectedPricing = new List<OLIView>();
		getActiveSolutionOLIs(persistedOLIs, selectedPricing);
		getActiveSolutionOLIs(loadedPricing, selectedPricing);
		
		Map<String, List<OLIView>> olisToValidate = multiSolutionMode ? getOLIsByTerm() : getOLIsToValidate(selectedPricing, olcID);
		Boolean invalidSolutionConfig = !validateOLISet(olisToValidate);
		if(!invalidSolutionConfig){
			if(multiSolutionMode){
				//saveLineItemsToMultipleSolutions();
			}
			else
				saveLineItemsToCurrentSolution();
		}
		
		if(invalidSolutionConfig) ApexUtils.messageDisplay('You cannot save with errors.');
		return !invalidSolutionConfig;
	}
	
	public PageReference Save(){
		SaveLineItems();
		getPricing();
		return null;
	}
		
	public PageReference SaveLineItemsAndExit(){
		Boolean saved = SaveLineItems();
		
		PageReference pr = null;
		if(saved) {
			pr = new PageReference('/apex/ManageLocationProducts?opportunityId=' + oppID);
			pr.setRedirect(true);
		}
		else
			getPricing();
		
		return pr;
	}
	
	public PageReference GrantApproval(){
		Integer icbCnt = 0;
		Integer mgrCnt = 0;
		//loop through and make sure we can approve
		for(String k : loadedPricing.keySet()){
			for(OLIView ohLeeView : loadedPricing.get(k)){
				if(ohLeeView.oli.Approval_Status__c == 'Sales Management Approval Required')
					++mgrCnt;
				else if(ohLeeView.oli.Approval_Status__c == 'Offer Management Approval Required')
					++icbCnt;
			}
		}
		for(String k : persistedOLIs.keySet()){
			for(OLIView ohLeeView : persistedOLIs.get(k)){
				if(ohLeeView.oli.Approval_Status__c == 'Sales Management Approval Required')
					++mgrCnt;
				else if(ohLeeView.oli.Approval_Status__c == 'Offer Management Approval Required')
					++icbCnt;
			}
		}
		if(selectedProduct == 'SOLUTION' && opportunityLocationConfiguration.Active__c && (discountAuthorityLevel.Name == 'Offer Management' || (discountAuthorityLevel.Name == 'Sales Director' && icbCnt == 0 && mgrCnt >= 0))){
			opportunityLocationConfiguration.Approver__c = UserInfo.getUserId();
			opportunityLocationConfiguration.Approval_Date__c = System.today().format();
			update opportunityLocationConfiguration;
			
			//set the OLI Off footprint approval.
			for(String k : loadedPricing.keySet()){
				for(OLIView ohLeeView : loadedPricing.get(k)){
					if(ohLeeView.oli.off_footprint__c  && !ohLeeView.oli.off_footprint_approved__c){
						ohLeeView.oli.off_footprint_approved__c = true;
					}
				}
			}
			for(String k : persistedOLIs.keySet()){
				for(OLIView ohLeeView : persistedOLIs.get(k)){
					if(ohLeeView.oli.off_footprint__c  && !ohLeeView.oli.off_footprint_approved__c){
						ohLeeView.oli.off_footprint_approved__c = true;
					}
				}
			}
			
			SaveLineItems();
			getPricing();
		}
		return null;
	}
	
	public PageReference doValidate(){
		List<OLIView> selectedPricing = new List<OLIView>();
		getActiveSolutionOLIs(persistedOLIs, selectedPricing);
		getActiveSolutionOLIs(loadedPricing, selectedPricing);
		
		Map<String, List<OLIView>> olisToValidate = multiSolutionMode ? getOLIsByTerm() : getOLIsToValidate(selectedPricing, olcID);
		Boolean invalidSolutionConfig = !validateOLISet(olisToValidate);
		
		getPricing();
		return null;
	}
	
	/* Component Relations */
	private SPC_Component_Relation__c getComponentRelation(Decimal SPCComponentId, String ProdId){
		SPC_Component_Relation__c retVal = null;
		List<SPC_Component_Relation__c> rels = CatalogUtils.relationsByComp2CompId.get(SPCComponentId);//CurrentRelationsBySalesProdExtId.get(ProdId);
		for(SPC_Component_Relation__c rel : rels == null? new List<SPC_Component_Relation__c>() : rels){
			if(rel.SPC_Component_2__c != null && rel.SPC_Component_2__r.Sales_Product_Component_Id__c == SPCComponentId){
				retVal = rel;//selectionRule = rel.Name;
				break;
			}
		}
		return retVal;
	}
	
	private Decimal getDefaultQty(Decimal SPCComponentId, String ProdId){
		SPC_Component_Relation__c rel = getComponentRelation(SPCComponentId, ProdId);
		Decimal retVal = 0;
		if(rel != null && rel.Default_Quantity__c != null && rel.SPC_Component_1__c == null && rel.SPC_Component_2__c != null){
			retVal = rel.Default_Quantity__c;
		}
		return retVal;
	}
	
	private String getSelectionRule(decimal SPCComponentId, String ProdId){
		SPC_Component_Relation__c rel = getComponentRelation(SPCComponentId, ProdId);
		return rel == null ? '' : rel.Name;
	}
	
	/* Discounting */
	
		
	/* OLI methods */
	private void addOLIChild(OLIView parent, OLIView child, SPC_Pricing__c parentPricing){
		if(parentPricing.Validation_Constraint_Type__c != 'SFDC - Feature')
			parent.autoInclude(child);
		else
			parent.addFeature(child);
	}
	
	
	private static OLI__c cloneOLI(OLI__c cloneFrom){	
		return (OLI__c)ApexUtils.deepCopyFields(cloneFrom.getSobjectTYpe(), cloneFrom, new OLI__c(OpportunityLocationConfiguration__c = cloneFrom.OpportunityLocationConfiguration__c), new Set<String>(), true);
	}
	
	private List<OLIView> filterLineItems(List<OLIView> allOLIs, Boolean currentSolutionView, Boolean filterMaxTerms){
		
		Integer term = Integer.valueOf(configOLC.Term__c == 'Month to Month' ? '1' : configOLC.Term__c);
		Decimal bandwidth = configOLC.Bandwidth__c != null ? Decimal.valueOf(configOLC.Bandwidth__c) : null;
		Set<String> accessTechSet = new Set<String>();
		if(selectedAccessTech != null && selectedAccessTech != '')
			accessTechSet.add(selectedAccessTech);
		
		//Get the maximum term available
		Map<Decimal, Integer> maxTerm = new Map<Decimal, Integer>();
		if(filterMaxTerms){
			for(OLIView v : allOLIs){
				Integer t = maxTerm.get(v.oli.SPC_Sales_Product_Component_Id__c) != null ? maxTerm.get(v.oli.SPC_Sales_Product_Component_Id__c) : 0;
				maxTerm.put(v.oli.SPC_Sales_Product_Component_Id__c, (t > v.term || v.term > term) ? t : v.term);
			}
		}
		
		//Filter 
		Set<Decimal> selectedBandwidthsSet = new Set<Decimal>();
		for(String s : selectedBandwidths != null ? selectedBandwidths : new List<String>()){
			selectedBandwidthsSet.add(Decimal.valueOf(s).setScale(3));
		}
		
		Set<String> displayedPriceIDs = new Set<String>();
		List<OLIView> filtered = new List<OLIView>();
		for(OLIView v : allOLIs){
			if(v != null && v.oli != null){
				OLI__c oli = v.oli;
				
				Boolean add = true;
				
				if(!currentSolutionView){
					add &= (oli.Bandwidth__c == null || (selectedBandwidthsSet.contains(oli.Bandwidth__c.setScale(3)) || selectedBandwidthsSet.size() == 0));
					add &= (v.Term == null || v.Term == 0 || (v.Term <= term));
					add &= (accessTechSet.size() == 0 || string.isEmpty(oli.AccessTechName__c) ||  accessTechSet.contains(oli.AccessTechName__c) || oli.qty__c > 0);
				}
				
				if(filterMaxTerms)
					add &= (v.Term == maxTerm.get(oli.SPC_Sales_Product_Component_Id__c) || v.Term == 0);
				
				if(add){
					if(v.canDuplicate){
						v.canRemove = v.oli.Id == null && displayedPriceIDs.contains(v.oli.Price_Id__c);		//The line is removable if it is not persisted and is not the first instance of the line
					}
					displayedPriceIDs.add(v.oli.Price_Id__c);
					filtered.add(v);
				}
			}
		}
		
		return filtered;
	}
	
	private void getActiveSolutionOLIs(Map<String, List<OLIView>> pricing, List<OLIView> outList){
		for(String k : pricing.keyset()){
			for(OLIView v : pricing.get(k)){
				if(v.oli.Qty__c > 0)
					outList.add(v);
			}
		}
	}
	
	private void getLineItem(CatalogUtils.SPCPricingView pricingView, List<OLIView> targetList, List<OLIView> persistedList){
		SPC_Pricing__c pricing = pricingView.pricing;
		String priceID = string.valueOf(pricing.Price_ID__c);
		
		OLIView v = null;
		if(persistedList != null){
			for(Integer i=persistedList.size() -1; i>=0; i--){
				if(persistedList[i].oli.Price_Id__c == priceID){
					v = persistedList[i];
					v.term = Integer.valueOf(pricing.Term__c);
					v.SalesSelectionRule = getSelectionRule(pricingView.pricing.Sales_Product_Component_ID__c, null);
					persistedList.remove(i);
					break;
				}
			}
		}
		
		if(v == null)
			v = getNewOLI(pricingView);
		
		targetList.add(v);
		
		List<OLIView> childViews = new List<OLIView>();
		for(CatalogUtils.SPCPricingView c : pricingView.children){
			if(c.pricing.Component_Group__c != 'Included')
				getLineItem(c, childViews, v.children);
		}
		
		for(OLIView cv : childViews){
			if(cv != null && cv.oli != null){
				cv.oli.ParentName__c = v.oli.DQ__c;
				addOLIChild(v, cv, pricing);
			}
		}
	}
	
	private Boolean isPackageIncluded(CatalogUtils.SPCPricingView pricingView){
		if(pricingView.Children != null){
			for(CatalogUtils.SPCPricingView chldview :  pricingView.children) {
				if(chldview.pricing != null && chldview.pricing.Component_Group__c =='Included')
					return true;
			}
		}
		return false;
	}
	
	private OLIView getNewOLI(CatalogUtils.SPCPricingView pricingView){
		SPC_Pricing__c pricing = pricingView.pricing;
		SPC_Product__c spc = getSPCProductByExternalID(pricing.Sales_Product_ID__c);
		if(spc == null) return null;
		String ppName = getPricingName(pricing);
		
		OLI__c lineItem = new OLI__c(AccessTechName__c = pricing.Access_Technology_Name__c
									,Bandwidth__c = pricing.Bandwidth__c
									,DQ__c = ppName
									,MRC__c = pricing.MRR__c
									,MRC_Floor__c = pricing.MRR_Floor__c
									,MRCList__c = pricing.MRR__c
									,NRC__c = pricing.NRR__c
									,NRCList__c = pricing.NRR__c
									,NRC_Floor__c = pricing.NRR_Floor__c
									,OpportunityLocationConfiguration__c = olcID
									,PP_Package__c = isPackageIncluded(pricingView)
									,PP_Package_Feature__c = pricing.component_group__c == 'Included' ? true : false
									,PP_Product_Pricing_Name__c = ppName
									,PP_SalesProductExternalID__c = string.valueOf(pricing.Sales_Product_ID__c)
									,Price_Id__c = string.valueOf(pricing.Price_ID__c)
									,Qty__c = getDefaultQty(pricing.Sales_Product_Component_ID__c, string.valueOf(pricing.Price_ID__c))
									,SPC_Component__c = pricing.SPC_Component__c
									,SPC_Feature_Group__c = pricing.Component_Group__c
									,SPC_MaxQty__c = pricing.Max_Qty__c
									,SPC_MinQty__c = pricing.Min_Qty__c
									,SPC_MRC_Is_Quote__c = pricing.Is_Quote_Price__c
									,SPC_Sales_Product_Component_Id__c = pricing.Sales_Product_Component_ID__c
									,SPC_Sales_Product__c = spc.Id
									);
		
		OLIView v = new OLIView(lineItem, Integer.valueOf(pricing.Term__c), getSelectionRule(pricing.Sales_Product_Component_ID__c, null));
		v.availableInWizard = pricing.available_in_wizard__c;
		v.requireZLocation = pricing.Z_Location_Required__c;
		v.isNonDiscountable = pricing.Is_Non_Discountable__c;
		v.canDuplicate = spc.Allow_Duplicate_Price_OLIs__c;
		v.isExpired = pricing.Is_Expired__c;
		return v;
	}
	
	private void populateOLISaveDefaults(OLI__c o, SPC_Product__c spc, SPC_Pricing__c pricing){
		o.PP_Feature_Group__c = pricing.Component_Group__c;
		o.PP_LD_Interstate__c = pricing.Is_LD_Interstate__c;
		o.PP_LD_Intrastate__c = pricing.Is_LD_Intrastate__c;
		
		o.PP_Toll_Free__c = pricing.Is_Toll_Free__c;
		o.PP_Per_Account__c = pricing.Is_Per_Account__c;
		o.PP_Product_Family__c = spc.Sales_Product_Group__c;
		o.PP_Sales_Product__c = spc.Name;
		o.PP_Sales_Rate_Plan_Description__c = getPricingName(pricing);
		o.PP_Voice_Line__c = pricing.Is_Voice_Line__c;
		o.PP_Voice_Line_Option__c = pricing.Is_Voice_Line_Option__c;
		o.Product_Family_Id__c = spc.Sales_Product_Group__c;
		o.Product_Family_Product__c = spc.Name;
		o.SPC_Component_Id__c = pricing.Component_ID__c;
		o.SPC_MRC_OnNet__c = pricing.Is_OnNet_Price__c;
		o.SPC_NRC_Is_Quote__c = pricing.Is_Quote_Price__c;
		o.SPC_Sales_Selection_Rule_Name__c = pricing.Sales_Selection_Rule__c;
		o.PP_DID_Virtual_TN__c = pricing.Is_DID_Virtual_TN__c;
	}
	
	private Map<String, List<OLIView>> getOLIsByTerm(){
		
		Map<String, List<OLIView>> olisByTerm = new Map<String, List<OLIView>>();
		for(String k : loadedPricing.keyset()){
			for(OLIView v : loadedPricing.get(k)){
				if(v.oli.Qty__c > 0){
					String ts = String.valueOf(v.term);
					List<OLIView> l2 = olisByTerm.get(ts) != null ? olisByTerm.get(ts) : new List<OLIView>();
					l2.add(v);
					olisByTerm.put(ts, l2);
				}
			}
		}
		
		if(olisByTerm.containsKey('0') && olisByTerm.size() > 1){
			//todo: move zero terms to other solutions?
		}
		
		return olisByTerm;
	}
	
	private List<OLIView> placeChildrenUnderParents(List<OLIView> oliList){
		List<OLIView> l = new List<OLIView>();
		for(OLIView v : oliList){
			l.add(v);
			l.addAll(v.children);
		}
		
		return l;
	}
	
	/* Secondary Location */
	public Map<Id, String> secLocNames { get; set; }
	public List<SelectOption> secondaryLocationOptions { get; set; }
	public List<SelectOption> secondaryServiceLocationOptions { get; set; }
	public Map<Id, String> zLocModes { get; set; }
	
	private static List<SelectOption> getSecondaryLocationSelectOptions(List<sObject> secondaryLocations, Boolean serviceLocMode, Map<Id, String> secLocNames){
		List<SelectOption> retval = new List<SelectOption>{new SelectOption('', '')};
		for(sObject l : secondaryLocations){
			Service_Location__c sLoc = serviceLocMode ? (Service_Location__c)l : null;
			String secLocName = sLoc != null ? sLoc.Name + ' [' + (!String.isEmpty(sLoc.ICC_Subscriber_ID__c) ? sLoc.ICC_Subscriber_ID__c : sLoc.Location__r.Name) + ']' : string.valueOf(l.get('Name'));
			secLocNames.put(l.Id, secLocName);
			if(retval.size() < 500) retval.add(new SelectOption(l.Id, secLocName));
		}
		retval.sort();
		return retval;
	}
	
	public transient String secLocParseResult{ get; set; }
	public Building__c secLocParseBuilding { get; set; }
	public Location__c secLocParseLocation { get; set; }
	public void SecondaryLocationParsed(){
		Boolean success = Apexpages.currentPage().getParameters().get('success') == 'true';
		String error = Apexpages.currentPage().getParameters().get('error');
		
		if(success){
	        integraWS.SFLocationView locView = AddressParser.addressParsed();
			
			if(locView != null && locView.Success && !string.IsEmpty(locView.BuildingHash)){
				secLocParseBuilding = AddressUtils.CreateBuilding(locView, false);
				secLocParseLocation = AddressUtils.CreateLocation(secLocParseBuilding, locView, false);
				
				secLocParseResult = String.format('Validated Address: {0}, {1}, {2}, {3}{4}'
												,new List<string>{
													secLocParseBuilding.Address__c
													,secLocParseBuilding.City__c
													,secLocParseBuilding.State__c
													,secLocParseBuilding.Postal_Code__c
													,(secLocParseLocation.Room_Suite__c != null ? (', ' + secLocParseLocation.Room_Suite__c) : '')
												});
            }
		}
		else secLocParseResult = 'Error: ' + error;
	}
	
	public PageReference SaveParsedSecondaryLocation(){
		if(secLocParseBuilding != null && secLocParseLocation != null){
			if(secLocParseBuilding.Id == null){
				insert secLocParseBuilding;
				secLocParseLocation.Building__c = secLocParseBuilding.Id;
			}
			
			if(secLocParseLocation.Id == null){
				insert secLocParseLocation;
				secLocParseLocation = [select Id, Name from Location__c where Id =: secLocParseLocation.Id];
			}
			
			dummyOLI.Secondary_Location__c = secLocParseLocation.Id;
			secondaryLocationOptions = getSecondaryLocationSelectOptions([select Id, Name from Location__c where Id in: secLocNames.keyset() or Id =: secLocParseLocation.Id order by Name], false, secLocNames);
		}
		
		return null;
	}
	
	/* Save/Validation */
	private Map<String, List<OLIView>> getOLIsToValidate(List<OLIView> pricing, String key){
		List<OLIView> l = new List<OLIView>();
		l.addAll(pricing);
		return new Map<String, List<OLIView>>{key=>l};
	}
	
	private void saveLineItemsToCurrentSolution(){
		List<OLI__c> updatedOLIs = new List<OLI__c>();
		List<OLIView> newChildOLIs = new List<OLIView>();
		List<OLI__c> deletedOLIs = new List<OLI__c>();
		
		for(Map<String, List<OLIView>> m : new List<Map<String, List<OLIView>>>{loadedPricing, persistedOLIs}){
			for(String k : m.keySet()){
				for(OLIView v : m.get(k)){
					if(v.oli.qty__c > 0 && v.oli.SPC_MRC_Is_Quote__c){
						if(v.oli.MRC__c == null) v.oli.MRC__c = 0;
						if(v.oli.NRC__c == null) v.oli.NRC__c = 0;
					}
				}
			}
		}
		
		sortOLIUpdatesIntoGroups(loadedPricing, updatedOLIs, newChildOLIs, deletedOLIs, true);
		sortOLIUpdatesIntoGroups(persistedOLIs, updatedOLIs, newChildOLIs, deletedOLIs, false);
		
		List<OLI__c> newChildOLIsRaw = new List<OLI__c>();
		for(OLIView o : newChildOLIs)
			newChildOLIsRaw.add(o.oli);
		
		//Gather save defaults right before insert to save some viewstate space
		List<OLI__c> allInserts = new List<OLI__c>();
		Map<String, SPC_Pricing__c> pricings = new Map<String, SPC_Pricing__c>();
		for(List<OLI__c> l : new List<List<OLI__c>>{updatedOLIs, newChildOLIsRaw}){
			for(OLI__c o : l){
				if(o.Id == null){
					allInserts.add(o);
					pricings.put(o.Price_ID__c, null);
				}
			}
		}
		
		if(allInserts.size() > 0){
			for(SPC_Pricing__c p : CatalogUtils.GetPricingByPricingID(new List<String>(pricings.keyset())))
				pricings.put(p.Price_ID__c, p);
			
			for(OLI__c o : allInserts)
				populateOLISaveDefaults(o, AllSPCProducts.get(o.SPC_Sales_Product__c), pricings.get(o.Price_ID__c));
		}
		
		try{
			if(updatedOLIs.size() > 0){
				upsert updatedOLIs;
				
				List<OLI__c> insertOLIs = new List<OLI__c>();
				for(OLIView v : newChildOLIs){
					OLI__c c = v.oli;
					if(v.parent.oli.Id != null){
						c.Parent_Opportunity_Line_Item__c = v.parent.oli.Id;
						insertOLIs.add(c);
					}
				}
				
				if(insertOLIs.size() > 0) insert insertOLIs;
			}
			
			if(deletedOLIs.size() > 0) delete deletedOLIs;
			
			for(List<OLIView> l : loadedPricing.values()){
				for(OLIView v : l != null ? l : new List<OLIView>())
					v.updated = false;
			}
		}
		catch(Exception e){
			ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Exception: ' + e.getMessage()));
		}
	}
	
	/*private void saveLineItemsToMultipleSolutions(){
		Map<String, List<OLI__c>> validateList = getOLIsByTerm();
		
		//todo: add to service locs
		ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Solution generation by service location is not coded yet'));
	}*/
	
	public List<String> validationErrors { get; set; }
	private Boolean validateOLISet(Map<String, List<OLIView>> oliSet){
		validationErrors = new List<String>();
		
		Map<String, SPC_Pricing__c> allPricing = new Map<String, SPC_Pricing__c>();
		for(String setKey : oliSet.keyset()){
			for(OLIView v : oliSet.get(setKey)){
				allPricing.put(v.oli.Price_Id__c, null);
			}
		}
		
		for(SPC_Pricing__c p : CatalogUtils.GetPricingByPricingID(new List<String>(allPricing.keyset())))
			allPricing.put(p.Price_ID__c, p);
		
		for(String setKey : oliSet.keyset()){
			Map<String, Integer> pickOnes = new Map<String, Integer>();
			Map<Decimal, Decimal> selectedComponentIdToSelectedProductId = new Map<Decimal, Decimal>();
			Set<Decimal> selectedComponentIds = new Set<Decimal>();
			Set<Decimal> selectedProductIds = new Set<Decimal>();
			
			Set<String> groupedErrors = new Set<String>();
			for(OLIView v : oliSet.get(setKey)){
				SPC_Pricing__c p = allPricing.get(v.oli.Price_Id__c);
				
				if(p == null) continue;		//Unknown/expired pricing, move on
				
				if(v.requireZLocation && string.isEmpty(v.secondaryLocID)) groupedErrors.add('One or more line item requires that a secondary location be set');
				
				String k = String.valueOf(p.Sales_Product_Component_ID__c);
				
				if(!string.isEmpty(p.Sales_Selection_Rule__c) && p.Sales_Selection_Rule__c.contains('Pick One')){
					k = p.Sales_Product_ID__c + '_' + p.Sales_Selection_Rule__c + '_' + p.Component_ID__c;
					pickOnes.put(k, pickOnes.get(k) != null ? (pickOnes.get(k)+1) : 1);
				}
				selectedComponentIds.add(v.oli.SPC_Sales_Product_Component_Id__c);
				selectedProductIds.add(Decimal.valueOf(v.oli.PP_SalesProductExternalID__c));
				selectedComponentIdToSelectedProductId.put(v.oli.SPC_Sales_Product_Component_Id__c, Decimal.valueOf(v.oli.PP_SalesProductExternalID__c));
			}
			
			if(groupedErrors.size() > 0) validationErrors.addAll(groupedErrors);
			groupedErrors = new Set<String>();
			
			//More than one pick one in the same set selected
			for(String k : pickOnes.keyset()){
				if(pickOnes.get(k) > 1){
					groupedErrors.add(k);
				}
			}
			
			if(groupedErrors.size() > 0) validationErrors.add('The following pick ones groups have multiple selections<br/>' + string.join(new List<String>(groupedErrors), '<br/>'));
			groupedErrors = new Set<String>();
			
			//not doing these if validation is turned off
			if(doValidation){
				//ValidationType => ExternalID being validated against => Requirement groups => Required component IDs
				Map<String, Map<Decimal, Map<String, Set<Decimal>>>> componentValidations = new Map<String, Map<Decimal, Map<String, Set<Decimal>>>>{
																									'PRODUCT'=>CatalogUtils.getRelationsByGroupByProductId(selectedProductIds)	//required components for selected product groups
																									,'COMPONENT'=>CatalogUtils.getRelationsByGroupByComponentId(selectedComponentIds)	//required components for selected components
																									};
				for(String validationType : componentValidations.keyset()){
					Map<Decimal, Map<String, Set<Decimal>>> m = componentValidations.get(validationType);
					for(Decimal k : m.keyset()){
						for(String grp : m.get(k).keyset()){
							Set<Decimal> reqIds = m.get(k).get(grp);
							Boolean requirementMet = false;
							for(Decimal selectedComponent : selectedComponentIds){
								if(reqIds.contains(selectedComponent)){
									requirementMet = true;
									break;
								}
							}
							if(!requirementMet){
								Decimal productID = k;
								if(validationType == 'COMPONENT'){
									productID = selectedComponentIdToSelectedProductId.get(k);
								}
								
								
								SPC_Product__c prd = (productID != null) ? getSPCProductByExternalID(productID) : null;
								groupedErrors.add((prd != null) ? (prd.Sales_Product_Group__c + '>' + prd.Name + ' > ' + grp) : 'Error' + k + ', ' + productID);
							}
						}
					}
				}
			}
			
			if(groupedErrors.size() > 0) validationErrors.add('You need to select from the following groups<br/>' + string.join(new List<String>(groupedErrors), '<br/>'));
		}
		
		return validationErrors.size() == 0;
	}
	
	/* Sorting */
	private static Map<String, Map<String, Map<String, Decimal>>> spcSortConfigs {get; set;}
	private static Map<String, Map<String, Map<String, Decimal>>> getSPCSortConfigMap(){
		if(spcSortConfigs == null){
			spcSortConfigs = new Map<String, Map<String, Map<String, Decimal>>>();
			for(CPQ_Sort_Config__c c : CPQ_Sort_Config__c.getall().values()){
				Map<String, Map<String, Decimal>> scs = spcSortConfigs.get(c.Parent_Type__c) != null ? spcSortConfigs.get(c.Parent_Type__c) : new Map<String, Map<String, Decimal>>();
				Map<String, Decimal> sortKeys = scs.get(c.Parent_name__c) != null ? scs.get(c.Parent_name__c) : new Map<String, Decimal>();
	            if(!sortKeys.containsKey(c.Sorted_Item_Name__c)){
	                sortKeys.put(c.Sorted_Item_Name__c, c.Sort_Order__c);
	            }
		        scs.put(c.Parent_name__c, sortKeys);
		        spcSortConfigs.put(c.Parent_Type__c, scs);
			}
		}
		
		return spcSortConfigs;
	}
	
	private List<String> getSPCSortOrder(String parentCategory, String parentName, Set<String> unsorted){
		List<String> retval = new List<String>();
		
		Map<Decimal, String> sortedConfigs = new Map<Decimal, String>();
		List<Decimal> configSortKeys = new List<Decimal>();
		
		Map<String, Map<String, Decimal>> configs = getSPCSortConfigMap().get(parentCategory);
		if(configs != null && configs.containsKey(parentName)){
			Map<String, Decimal> sortKeys = configs.get(parentName);
			for(String s : sortKeys.keyset()){
				if(unsorted.contains(s)){
					configSortKeys.add(sortKeys.get(s));
					sortedConfigs.put(sortKeys.get(s), s);
				}
			}
		}
		configSortKeys.sort();
		
		for(Decimal d : configSortKeys){
			retval.add(sortedConfigs.get(d));
		}
		
		//Add all that are not configured to the end
		Set<String> sortSet = new Set<String>(retval);
		for(String u : unsorted){
			if(!sortSet.contains(u))
				retval.add(u);
		}
		
		return retval;
	}
	
	private static void sortOLIUpdatesIntoGroups(Map<String, List<OLIView>> m, List<OLI__c> updatedOLIs, List<OLIView> newChildOLIs, List<OLI__c> deletedOLIs, Boolean cloneDeleted){
		for(String k : m.keyset()){
			sortOLIUpdatesIntoGroups(m.get(k), updatedOLIs, newChildOLIs, deletedOLIs, cloneDeleted);
		}
	}
	
	private static void sortOLIUpdatesIntoGroups(List<OLIView> l, List<OLI__c> updatedOLIs, List<OLIView> newChildOLIs, List<OLI__c> deletedOLIs, Boolean cloneDeleted){
		if(l != null){
			for(Integer i=0; i<l.size(); i++){
				OLIView v = l[i];
				if(v.updated){
					if(v.oli.Qty__c > 0){
						if(v.parent != null && v.oli.Id == null)
							newChildOLIs.add(v);
						else
							updatedOLIs.add(v.oli);
						
						String secLocObjectName = !String.isEmpty(v.secondaryLocID) ? SchemaUtils.GetSObjectNameByID(v.secondaryLocID) : null;
						v.oli.Secondary_Location__c = (secLocObjectName == 'Location__c') ? v.secondaryLocID : null;
						v.oli.Secondary_Service_Location__c = (secLocObjectName == 'Service_Location__c') ? v.secondaryLocID : null;
					}
					else if(v.oli.Id != null){
						deletedOLIs.add(v.oli);
						if(cloneDeleted)
							l[i].oli = cloneOLI(l[i].oli);
					}
				}
				
				sortOLIUpdatesIntoGroups(v.children, updatedOLIs, newChildOLIs, deletedOLIs, cloneDeleted);
			}
		}
	}
	
	/* Static helper methods */
	private static String getFieldsStringFromPath(String path, Set<String> fields){
		path = !String.isEmpty(path) ? (path + '.') : '';
		return path + String.join(new List<String>(fields), ',' + path);
	}
	
	private static String getPricingName(SPC_Pricing__c pricing){
		return (pricing.Pricing_Name__c != null) ? (pricing.Component_Name__c + '-' + pricing.Pricing_Name__c) : pricing.Component_Name__c;
	}
	
	private Set<String> getAvailableProductsWithPricing(){
		Set<string> prodNames = new Set<string>();
		
		string buildingHash = opportunityLocationConfiguration != null ? opportunityLocationConfiguration.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_Hash__c : null;
		string marketName = '';
		integer term = opportunityLocationConfiguration != null ? integer.valueOf(opportunityLocationConfiguration.Term__c == 'Month to Month' ? '1' : opportunityLocationConfiguration.Term__c) : 0;
		System.debug('TERM: ' + term + ' OppLoc: ' + opportunityLocationConfiguration);
        for(Building__c b : [select Id, Market_Area_Name__c, Net_Classification__c from Building__c where building_hash__c = :buildingHash]){
            marketName = b.Market_Area_Name__c;
        }
		
		String query = 'SELECT Sales_Product_Name__c FROM SPC_Pricing__c Where Market__c = :marketName and is_expired__c = false ';
		if(term == 1)
			query += 'and term__c = :term ';
		
		query += 'Group By Sales_Product_Name__c';
		for(AggregateResult ar : Database.query(query)){
    		prodNames.add(string.valueof(ar.get('Sales_Product_Name__c')));
		}
		return prodNames;
	}
	
	private static Map<String, List<SPC_Product__c>> productByGroupMap = null;
	private Map<String, List<SPC_Product__c>> getProductsByGroupMap(){
		if(productByGroupMap == null){
			productByGroupMap = new Map<String, List<SPC_Product__c>>();
			Set<string> availProds = getAvailableProductsWithPricing();
			System.debug('availProds: ' + availProds);
			for(SPC_Product__c p : (List<SPC_Product__c>)ApexUtils.sortByComparableField(AllSPCProducts.values(), 'Name', true, true)){
				if(availProds.contains(p.Name) && !p.Hide_In_Wizard__c){
					String spg = p.Sales_Product_Group__c;
					if(spg != null) {
						List<SPC_Product__c> ps = productByGroupMap.get(spg) != null ? productByGroupMap.get(spg) : new List<SPC_Product__c>();
						ps.add(p);
						productByGroupMap.put(spg, ps);
					}
					System.debug('productByGroupMap: ' + productByGroupMap);
				}
			}
			
			for(Product_Families__c f : [select Name from Product_Families__c where Status__c = 'Disable'])
				productByGroupMap.remove(f.Name);
		}
		
		return productByGroupMap;
	}
	
	private static Map<Id, SPC_Product__c> allSPCProductsMap = null;
	public static Map<Id, SPC_Product__c> AllSPCProducts{
		get{
			if(allSPCProductsMap == null)
				allSPCProductsMap = new Map<Id, SPC_Product__c>((List<SPC_Product__c>)ApexUtils.retrieveFullObjects(SPC_Product__c.getsObjectType(), 'Expiration__c = null'));
			
			return allSPCProductsMap;
		}
	}
	
	private static Map<Decimal, SPC_Product__c> spcProductsByExternalID = null;
	private static SPC_Product__c getSPCProductByExternalID(Decimal externalID){
		if(spcProductsByExternalID == null){
			spcProductsByExternalID = new Map<Decimal, SPC_Product__c>();
			for(SPC_Product__c spc : AllSPCProducts.values())
				spcProductsByExternalID.put(spc.SalesProductExternalID__c, spc);
		}
		
		return spcProductsByExternalID.get(externalID);
	}
	
	public void approvalBtnVisability() {
        //load property with user instance
        String userlvl = string.valueOf([SELECT Discount_Level_Authority__c FROM User WHERE Id =: UserInfo.getUserId()].Discount_Level_Authority__c);
        if(!String.IsEmpty(userlvl)){
            discountAuthorityLevel = DiscountAuthorityLevels__c.getInstance(userlvl);
		}
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return null;/*new Test_ConfigureSolution();*/ }	//todo
}