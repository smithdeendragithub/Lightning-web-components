public class OpportunitySummaryController implements TestUtils.ITestableClass {

	public Account account{get;set;}
	
	public class OpportunitySummary{
		public String Name{get;set;}
		public String Stage{get;set;}
		public String Owner{get;set;}
		public DateTime CreatedDate{get;set;}
		public DateTime CloseDate{get;set;}
		public DateTime LastModifiedDate{get;set;}
	}
	
	public List<OpportunitySummary> opportunities{get;set;}
    
    public OpportunitySummaryController(ApexPages.StandardController stdController) {
        account = (Account) stdController.getRecord();
        opportunities = new List<OpportunitySummary>();
        
    	for(Opportunity op : [select Name, StageName, Owner.FirstName, Owner.LastName, CreatedDate, CloseDate, LastModifiedDate from Opportunity where AccountId = :account.Id]){
    		OpportunitySummary s = new OpportunitySummary();
    		s.Name = op.Name;
    		s.Stage = op.StageName;
    		s.Owner = op.Owner.FirstName + ' ' + op.Owner.LastName;
    		s.CreatedDate = op.CreatedDate;
    		s.CloseDate = op.CloseDate;
    		s.LastModifiedDate = op.LastModifiedDate;
    		
    		opportunities.add(s);
    	}
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_OpportunitySummary(); }
}