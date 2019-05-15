public with sharing class IntegrationErrorsController {
	
	public String integrationEndpoint {get;set;}
	public String totalCount {get;set;}
	public String selectedCount {get;Set;}
	public Integer batchLimit {get; set;}
	public List<Integration_Error__c> errors {get;set;}
	public List<Integration_Error__c> selectedErrors {get;set;}
	public Map<String, String> objectTypes {get;set;}	//Local copy of ApexUtils.sObjectNameByID
	
	private final String AccountPrefix = Account.sObjectType.getDescribe().getKeyPrefix() + '%';
	private final String ContactPrefix = Contact.sObjectType.getDescribe().getKeyPrefix() + '%';
	private final String CustomerContactPrefix = Customer_Contact__c.sObjectType.getDescribe().getKeyPrefix() + '%';
	private final String CustomerDetailPrefix = Customer_Detail__c.sObjectType.getDescribe().getKeyPrefix() + '%';
	private final String CasePrefix = Case.sObjectType.getDescribe().getKeyPrefix() + '%';
	private final String CaseCommentPrefix = CaseComment.sObjectType.getDescribe().getKeyPrefix() + '%';
	private final String CapitalProjectPrefix = Capital_Project__c.sObjectType.getDescribe().getKeyPrefix() + '%';
	
	private final Set<String> ValidPrefixes = new Set<String>{ AccountPrefix, ContactPrefix, CustomerContactPrefix, CustomerDetailPrefix, CasePrefix, CaseCommentPrefix, CapitalProjectPrefix };
    
    public IntegrationErrorsController() {
    	batchLimit = 200;
    	integrationEndpoint = CustomSettingUtils.IntegraWSEndpoint;
        getErrors();
    }
    
    private void getErrors(){
    	errors = new List<Integration_Error__c>();
    	objectTypes = new Map<String, String>();
		
		String whereClause = 'ObjectID__c like :AccountPrefix'
								+ ' or ObjectID__c like :ContactPrefix'
								+ ' or ObjectID__c like :CustomerContactPrefix'
								+ ' or ObjectID__c like :CustomerDetailPrefix'
								+ ' or ObjectID__c like :CasePrefix'
								+ ' or ObjectID__c like :CaseCommentPrefix'
								+ ' or ObjectID__c like :CapitalProjectPrefix';
    	for(Integration_Error__c error : (List<Integration_Error__c>)Database.query('select Id, Name, ObjectID__c, Info__c, Message__c, Action__c, CreatedDate from Integration_Error__c where ' + whereClause + ' limit 10000')){
			//Double check to filter out case insensitive prefix matches
			//if(ValidPrefixes.contains(error.ObjectID__c.substring(0, 3) + '%')){
	    		objectTypes.put(error.ObjectID__c, SchemaUtils.GetSObjectNameByID(error.ObjectID__c));
	    		errors.add(error);
					
				if(errors.size() == 1000) break;
			//}
    	}
    	totalCount = string.valueOf(Database.countQuery('select COUNT() from Integration_Error__c where ' + whereClause));
        refresh();
    }
    
    public String objectTypeSelection {get;set;}
    public void refresh() {
    	selectedErrors = new List<Integration_Error__c>();
    	
    	system.debug(objectTypeSelection);
    	Boolean anyMode = String.IsEmpty(objectTypeSelection);
    	for(Integration_Error__c error : errors){
    		if(anyMode || objectTypeSelection == objectTypes.get(error.ObjectID__c)){
    			selectedErrors.add(error);
    		}
    	}
		selectedCount = String.valueOf(selectedErrors.size());
    }
    
    public String objectID {get; set;}
    public void integrateSingle() {
		if(!String.IsEmpty(objectID))
			integrateIDs(new Set<String>{objectID});
    }
    
    public void integrateBatch() {
    	Set<String> objIDs = new Set<String>();
    	
    	refresh();
    	for(Integration_Error__c error : selectedErrors){
    		objIDs.add(error.ObjectID__c);
	    		
	    	if(objIDs.size() == batchLimit) break;
    	}
    	
    	integrateIDs(objIDs);
    }
    
    private void integrateIDs(Set<String> ids){
    	if(ids.size() == 0) return;
    	
		List<String> messages = IntegrationUtils.reintegrateObjects(ids);
		for(String m : messages)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, m));
		
		getErrors();
    }
}