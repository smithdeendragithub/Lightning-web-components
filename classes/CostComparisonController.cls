public with sharing class CostComparisonController implements TestUtils.ITestableClass {
	private final Opportunity_Location__c oppLocation;
	private final ApexPages.StandardController ctr;
	public List<wrapCostComparison> CostComparisons {get;set;}
	public Decimal GrandTotal {get;set;}
	
	public CostComparisonController(ApexPages.StandardController stdController) {
		try{
			this.oppLocation = (Opportunity_Location__c)stdController.getRecord();
			this.ctr = stdController;
			 
			CostComparisons = new List<wrapCostComparison>();
			Integer i = 0;
			
			for(Oppty_Cost_Comparison__c occ : [Select Qty__c, Name, NRC__c, MRC__c, Id, Description__c 
			From Oppty_Cost_Comparison__c Where Opportunity_Location__c = :oppLocation.Id]){
				wrapCostComparison wcc = new wrapCostComparison(occ);
				wcc.Index = i++;
				CostComparisons.Add(wcc);
			} 
			
			AddMoreRows(10);
			Recalculate();
			
		} catch(Exception e){
			apexUtils.messageDisplay(e.getMessage()); 
		}
    }
    
	//Wrapper class for the Cost Comparison and Sub-Total Field
	//to used in the data table on Vf page.
	public class wrapCostComparison{
		public Oppty_Cost_Comparison__c opptyCostComparison {get;set;}
		public Decimal SubTotal {
			get{
				Decimal ret_val = 0;
				if((opptyCostComparison.Qty__c!=null)&&(opptyCostComparison.MRC__c!=null)){
					ret_val = opptyCostComparison.Qty__c * opptyCostComparison.MRC__c;
				}
				return ret_val;
			}
			private set;
		}
		public Integer Index {get;set;}
		
		public wrapCostComparison(Oppty_Cost_Comparison__c occ){
			opptyCostComparison = occ;
		}
	}
	
	public void AddTenRows(){
		AddMoreRows(10);
	}
    
    private void AddMoreRows(Integer numberOfRows){
    	Integer size = CostComparisons.size();
    	
		for(Integer i=0; i<numberOfRows; i++){
			Oppty_Cost_Comparison__c occ = new Oppty_Cost_Comparison__c();
			occ.Opportunity_Location__c = oppLocation.Id;
			occ.Qty__c = 0;
			occ.MRC__c = 0;
			wrapCostComparison wcc = new wrapCostComparison(occ);
			wcc.Index = i+size;
			CostComparisons.add(wcc); 
		}
    }
    
    public void Recalculate(){
    	GrandTotal = 0;
    	
    	for(wrapCostComparison w : CostComparisons){
    		Oppty_Cost_Comparison__c cc = w.opptyCostComparison;
    		GrandTotal += w.SubTotal;
    	}
    }

	public PageReference saveComparison(){
		Boolean cancelSave = false;
		
		List<Oppty_Cost_Comparison__c> insertComparisons = new List<Oppty_Cost_Comparison__c>();
		List<Oppty_Cost_Comparison__c> updateComparisons = new List<Oppty_Cost_Comparison__c>();
		
		for(wrapCostComparison w : CostComparisons){
			Oppty_Cost_Comparison__c cc = w.opptyCostComparison;
			
			if( (cc.Description__c!=null) && (w.SubTotal>0) ){
				if(cc.Id!=null){
					updateComparisons.add(cc);
				}else{
					insertComparisons.add(cc);
				}
			}else if( (cc.Description__c!=null) && (w.SubTotal==0) ){
				apexUtils.messageDisplay('All Sub Totals should be non-zero for comparisons.');
				cancelSave = true;
				break;
			}else if(w.SubTotal>0){
				if(cc.Description__c==null){
					apexUtils.messageDisplay('A Product description is required on all non-zero comparisons.');
					cancelSave = true;
					break;
				}
			}
		}
		
		if(updateComparisons.size()>0){
			update updateComparisons;
		}
		if(insertComparisons.size()>0){
			insert insertComparisons;
		}
		
		if(cancelSave){
			return null;
		}else{
			return ctr.cancel();
		}
	}
    
    public PageReference cloneComparison() {
    	PageReference pageReference = Page.CloneCostComparison;
        Map<String, String> params = pageReference.getParameters();
        params.put('Id', oppLocation.Id);
        params.put('retURL', '/apex/CostComparison?Id=' + oppLocation.Id); 
        pageReference.setRedirect(true);
    	
    	return pageReference;
    }
    
    public void deleteComparison(){
    	String selectedIndexParam = ApexUtils.getParam('selectedComparisonIndex');
    	
    	if( !String.IsEmpty(selectedIndexParam)){
    		Integer selectedIndex = Integer.valueOf(selectedIndexParam);
    		Oppty_Cost_Comparison__c cc = CostComparisons[selectedIndex].opptyCostComparison;
    		if( (cc != null) && (cc.Id != null)){    			
    			delete cc;
    		}
    		CostComparisons.remove(selectedIndex);
    	}
    	
    	Integer i = 0;
    	for(wrapCostComparison wcc : CostComparisons){
    		wcc.Index = i++;
    	}
    	Recalculate();
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_CostComparison(); }
}