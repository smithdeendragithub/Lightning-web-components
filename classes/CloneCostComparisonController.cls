/**
* Controller for cloning a Cost Comparison.
* Modeled after the Clone Solution screen by Scott Faucera.
*
* @author Sebastian Kessel
*
*/
public with sharing class CloneCostComparisonController implements TestUtils.ITestableClass {
    
    /**
    * Default search constants
    */
    private static final String DEFAULT_SEARCH_OPPORTUNITY_NAME = 'CPQ Template';
    private static final String DEFAULT_SEARCH_ACCOUNT_NAME = '';
    private static final Boolean DEFAULT_SEARCH_EXCLUDE_EMPTY_SOLUTIONS = false;
    private static final Boolean DEFAULT_SEARCH_INCLUDE_ONLY_MY_OPPORTUNITIES = false;
    private static final Integer DEFAULT_SEARCH_MAX_RESULTS = 50;
    
    /**
    * Search parameters from the search form
    */
    public Boolean searchMySolutionsOnly { get; set; }
    public String searchOpportunityName { get; set; }
    public String searchAccountName { get; set; }
    public Integer searchMaxResults { get; set; }
    
    /**
    * The current location configuration instance
    */
    public Opportunity_Location__c opportunityLocation { get; private set; }
    
    /**
    * Holds the current results from the last search
    */
    public List<wrapOpportunityLocation> searchResults { get; private set; }    
    
    
	/**
    * Sole constructor
    */
    public CloneCostComparisonController() {
        
        // initialize controller
        init();
    }
    
    /**
    * Action method that redirects into the manage location products page
    */
    public PageReference gotoCostComparison() {
        
        // redirect to manage location products page
        PageReference pageReference = Page.CostComparison;
        pageReference.getParameters().put('Id', this.opportunityLocation.Id);
        pageReference.setRedirect(true);
        return pageReference;
    }
    
    /**
    * Action method that redirects into the manage location products page
    */
    public PageReference searchSolutions() {
    	
    	// build soql statement
        String selectStatement = 'Select Order__r.Opportunity__r.Name, Service_Location__r.Account__r.Name, '
        	+ ' (SELECT Description__c,MRC__c,Name,NRC__c,Opportunity_Location__c,Qty__c FROM Oppty_Cost_Comparisons__r)' 
        	+ ' From Opportunity_Location__c';
        String whereStatement = '';
        String orderByStatement = 'Order By Order__r.Opportunity__r.Name';
        String limitStatement = 'Limit ' + searchMaxResults;
       
        if(searchMySolutionsOnly) {
        	whereStatement += ' AND Order__r.Opportunity__r.OwnerId = \'' + UserInfo.getUserId() + '\'';
        }
        if(searchOpportunityName.trim() != '') {
        	whereStatement += ' AND Order__r.Opportunity__r.Name LIKE \'%' + searchOpportunityName.trim() + '%\'';
        }
        if(searchAccountName.trim() != '') {
        	whereStatement += ' AND Service_Location__r.Account__r.Name LIKE \'%' + searchAccountName.trim() + '%\'';
        }
        if(whereStatement != '') {
        	whereStatement = 'Where ' + whereStatement.substring(4);
        }
        String soql = selectStatement + ' ' + whereStatement + ' ' + orderByStatement + ' ' + limitStatement;
		System.debug('Dynamic SOQL prepares as: ' + soql);
		
		// execute the search
		searchResults = new OpportunityLocationAssembler().fromNativeOpportunityLocations(Database.query(soql));
		
		// stay on page
		return null;
    }
    
    /**
	* Action method that imports line items from a config
	*
	* @param configId */ public String ConfigId_cloneConfig {get; set;} /**
	*		id configuration to import
	*/
	public PageReference cloneConfig() {

		// delete existing line items as compensating logic for the long running transaction
		List<Oppty_Cost_Comparison__c> deleteLineItems = [Select Id From Oppty_Cost_Comparison__c Where Opportunity_Location__c = :this.opportunityLocation.Id];
		if(!deleteLineItems.isEmpty()) {
    		delete deleteLineItems;
		}
    	
		// find config to clone
		wrapOpportunityLocation clone = null;
		for(wrapOpportunityLocation olc : searchResults) {
			if(olc.id == ConfigId_cloneConfig) {
				clone = olc;
				break;
			}	
		}
		if(clone == null) {
			// we should never get here
			throw new CloneCostComparisonControllerException('Invalid config ID for cloning.');	
		}
		
		// create line items from clone
		List<Oppty_Cost_Comparison__c> insertLineItems = new List<Oppty_Cost_Comparison__c>();
        for(LineItem lineItem : clone.lineItems) {
        	
        	insertLineItems.add(new Oppty_Cost_Comparison__c(
        		Qty__c = lineItem.quantity, 
				MRC__c = lineItem.mrc, 
				NRC__c = lineItem.nrc, 
				Description__c = lineItem.description,
				Opportunity_Location__c = this.opportunityLocation.Id));
        	
        }

        // persist changes
        if(!insertLineItems.isEmpty()) {
        	
        	// add line items
        	insert insertLineItems;
        	
        	update this.opportunityLocation;
        }
        
        return gotoCostComparison();
	}

    /**
    * Initializes the controller using the passed in configuration ID.  
    */
    private void init() {
        
        // get/validate the configuration from parameter
        String OpportunityLocationId = Apexpages.currentPage().getParameters().get('Id');
        if(OpportunityLocationId == null || OpportunityLocationId == '') {
            throw new CloneCostComparisonControllerException('Missing or invalid OpportunityLocationId parameter.');
        }
        
        // get the config   
        List<Opportunity_Location__c> opportunityLocations = [
                Select Id, Name, Opportunity__r.AccountId, Service_Location__r.Account__r.Name,  
                Order__r.Opportunity__r.Id, Order__r.Opportunity__r.Name
                From Opportunity_Location__c 
                Where Id = :OpportunityLocationId
        ];
        if(opportunityLocations.size() != 1) {
            throw new CloneCostComparisonControllerException('Invalid OpportunityLocationId ID.');
        } 
        else {
            this.opportunityLocation = opportunityLocations.get(0);   
        }
        
        // init search parameters
        searchMySolutionsOnly = DEFAULT_SEARCH_INCLUDE_ONLY_MY_OPPORTUNITIES;
        searchOpportunityName = DEFAULT_SEARCH_OPPORTUNITY_NAME;
        searchAccountName = DEFAULT_SEARCH_ACCOUNT_NAME;
        searchMaxResults = DEFAULT_SEARCH_MAX_RESULTS;
        
        // perform initial search
        searchSolutions();
    }
    
    
     
    /**
    * Assembler for OpportunityLocation objects
    */
    public class OpportunityLocationAssembler {
    	
    	/**
		* Assembles a LineItem from an OLI__c
		*
		* @param nativeConfig
		* 		the native config to create a OpportunityLocation from
		* @returns
		*		a mapped OpportunityLocation from the given native config instance
		*/
    	public wrapOpportunityLocation fromNativeOpportunityLocation(Opportunity_Location__c nativeConfig) {
    	
    		// map config
    		wrapOpportunityLocation opportunityLocation = 
    			new wrapOpportunityLocation(nativeConfig.Id, 
    					nativeConfig.Order__r.Opportunity__r.Name, 
    					nativeConfig.Service_Location__r.Account__r.Name);
    					
    		// map config line items
    		opportunityLocation.lineItems.addAll(new LineItemAssembler(OpportunityLocation).fromCostComparisons(nativeConfig.Oppty_Cost_Comparisons__r));
    		
    		// return mapped config
    		return opportunityLocation;
    	}
    	
    	/**
		* Assembles a list of OpportunityLocation objects from a 
		* native list of Opportunity_Location__c objects
		*
		* @param nativeConfigs
		* 		the list of native opportunity location configs to create
		*		OpportunityLocation objects from
		* @returns
		*		a list of mapped OpportunityLocation objects from the given 
		*		Opportunity_Location__c list
		*/
    	public List<wrapOpportunityLocation> fromNativeOpportunityLocations(List<Opportunity_Location__c> nativeConfigs) {
    	
    		List<wrapOpportunityLocation> opportunityLocations = new List<wrapOpportunityLocation>();
    		
    		for(Opportunity_Location__c nativeConfig : nativeConfigs) {
    			opportunityLocations.add(fromNativeOpportunityLocation(nativeConfig));
    		}
    		
    		return opportunityLocations;
    	}
    }
    
    /**
    * Assembler for LineItem objects
    */
    public class LineItemAssembler {
    	
    	private wrapOpportunityLocation opportunityLocation;
    	
    	/**
    	* Overload ctor
    	*/
    	public LineItemAssembler() {	
    	}
    	
    	/**
    	* Overload ctor
    	*
    	* @param OpportunityLocation the parent config for the mapped line item (can be null)
    	*/
    	public LineItemAssembler(wrapOpportunityLocation opportunityLocation) {
    		this.opportunityLocation = opportunityLocation;
    	}
    	
    	/**
		* Assembles a LineItem from an OLI__c
		*
		* @param oli
		* 		the opportunity line item to create a LineItem from
		* @returns
		*		a mapped LineItem from the given OLI__c instance
		*/
    	public LineItem fromCostComparison(Oppty_Cost_Comparison__c cc) {
    		
    		LineItem lineItem = new LineItem();
    		lineItem.opportunityLocation = opportunityLocation;
    		lineItem.id = cc.Id;
    		lineItem.description = cc.Description__c;
	    	lineItem.quantity = cc.Qty__c;
	    	lineItem.mrc = cc.MRC__c;
	    	lineItem.nrc = cc.NRC__c;
	    	
	    	return lineItem;
    	}
    	
    	/**
		* Assembles a list of LineItem objects from a list of OLI__c objects
		*
		* @param olis
		* 		the list of opportunity line items to create a LineItem list from
		* @returns
		*		a list of mapped LineItem objects from the given OLI__c list
		*/
    	public List<LineItem> fromCostComparisons(List<Oppty_Cost_Comparison__c> ccs) {
    	
    		// list for return
    		List<LineItem> lineItems = new List<LineItem>();
    		
    		// reference maps
    		Map<Id, LineItem> itemMap = new Map<Id, LineItem>();
    		Map<Id, Id> parentReferenceMap = new Map<Id, Id>();
    		Map<Id, List<LineItem>> childMap = new Map<Id, List<LineItem>>();
    		
    		// iterate and map accordingly
    		for(Oppty_Cost_Comparison__c cc : ccs) {
    			
    			// assemble line item
    			LineItem lineItem = fromCostComparison(cc);
    			
    			// map references
    			itemMap.put(cc.Id, lineItem);
    			
    			// add item to list
    			lineItems.add(lineItem);
    		}
    		    		
    		// return map to caller
    		return lineItems;
    	}
    }
    
    /**
    * Custom wrapper exception used by controller
    */
    public class CloneCostComparisonControllerException extends Exception {
    }
	
	/**
	* View object for the line item
    */
    public class wrapOpportunityLocation {
    	
    	public Id id {get; set;}
    	public String opportunityName {get; set;}
    	public String accountName {get; set;}
    	public List<LineItem> lineItems  {get; private set;}
    	
    	public wrapOpportunityLocation(Id id, String opportunityName, String accountName) {
    		this.id = id;
    		this.opportunityName = opportunityName;
    		this.accountName = accountName;
    		this.lineItems = new List<LineItem>();
    	}
    }
  	
    /**
    * View object for the line item
    */
    public class LineItem {
    	
    	public Id id {get; set;}
    	public String description {get; set;}
    	public Decimal quantity {get; set;}
    	public Double mrc {get; set;}
    	public Double nrc {get; set;}
    	public wrapOpportunityLocation opportunityLocation {get; set;}
    	
    	/**
    	* Default ctor
    	*/
    	public LineItem() {
    	}
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_CloneCostComparison(); }
}