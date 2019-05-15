public with sharing class UploadContentController implements TestUtils.ITestableClass {

    public String parentId {get;set;}
    public string oTypeName {get; set;}
	public string orderId {get;set;}
    public List<SelectOption> workspaces {get;set;}
    public Id selectedWorkspace {get;set;}
    public string AcctName {get;set;}
    
    private String defaultWorkspaceSelection {get;set;}
    
    public ContentVersion cv {get;set;}
    public transient Blob fileContents {get;set;}  
    public transient Blob fileContentsUpload {get;set;}  
    
    //We do it this way (with custom getter/setters) because if we call InitContentVersion on the constructor
    //the isGeneratedContent variable has not been initialized yet and we get an error
    public Boolean isGeneratedContent;
    public Boolean isOrderContent {get;set;}
	public Boolean isIntegraContract {get;Set;}
    
    public void setisGeneratedContent (Boolean b) {
        isGeneratedContent = b;
        
        if (isGeneratedContent) {
          cv.Asset_Type__c = 'Customized or Client-Specific';
          
        }
    }
    
    public Boolean getisGeneratedContent() {
        return isGeneratedContent;
    }

    public string titlePrefix { get; set; }
    public string objectId { get; set; }

    public class DisplayField {
        public Boolean required {get;set;}
        public String boundName {get;set;}
    }
    
	private static Id pcontractRecordType = null;
	public static Id contractRecordType{
		get{
			if(pcontractRecordType == null){
				pcontractRecordType = [select Id from RecordType where sObjectType = 'ContentVersion' and DeveloperName = 'Associated_Order_Documents' limit 1].Id;	
			}
			return pcontractRecordType;
		}
		set{
			pcontractRecordType = value;	
		}
	}
	
	private string orderName = '';

	
    public UploadContentController(){
      	objectId = getObjectId();
		getObjectProperties();

        isGeneratedContent = (ApexPages.currentPage().getParameters().get('isGeneratedContent') == 'true');

        if(oTypeName == 'ICB__c')
        	workspaces = LoadWorkspaces('ICB%');
		else{
		    workspaces = LoadWorkspaces('Sales Workspace%');
			workspaces.addAll(LoadWorkspaces('Contract Management%'));
		}
		
		if(!String.IsEmpty(defaultWorkspaceSelection)){
			for(SelectOption so : workspaces){
				if(so.getLabel() == defaultWorkspaceSelection)
					selectedWorkspace = so.getValue();
			}
		}
		        	
        cv = InitContentVersion();  
    }
    
    private boolean getObjectProperties(){
    	
    	string retVal;
    	Boolean flag = false;
		isOrderContent = false;
		isIntegraContract = false;
    	
    	if(objectId.startsWith(Account.SObjectType.getDescribe().getKeyPrefix())){
            Account a = [Select Name, Id, OwnerId from Account where Id = : objectId];
            
            defaultWorkspaceSelection = CustomSettingUtils.getSingleProcessConfigurationValue('UploadContentSalesChannelLibrary-Account', [select Id, Sales_Channel__c from User where Id = : a.OwnerId].Sales_Channel__c, true);
            titlePrefix = a.Name + ' - ';            
    		retVal = 'Account';
    	}
    	else if( objectId.startsWith(Opportunity.SObjectType.getDescribe().getKeyPrefix())){
            Opportunity o = [Select Name, Id, OwnerId, Account.Name from Opportunity where Id = : objectId];
            AcctName = o.Account.Name;
            defaultWorkspaceSelection = CustomSettingUtils.getSingleProcessConfigurationValue('UploadContentSalesChannelLibrary-Opportunity', [select Id, Sales_Channel__c from User where Id = : o.OwnerId].Sales_Channel__c, true);
            titlePrefix = o.Name + ' - ';
    		retVal = 'Opportunity';
    	}
    	else if(objectId.startsWith(ICB__c.SObjectType.getDescribe().getKeyPrefix())){
        	List<ICB__c> icbs = new List<ICB__c>();
    		Opportunity o = [SELECT Id, Name, OwnerId, (Select Id, Name From ICB_Requests__r) From Opportunity WHERE Id in (SELECT Opportunity__c FROM ICB__c WHERE Id =: objectId)];
    		
    		
    		for(ICB__c icb : o.ICB_Requests__r)
    			icbs.add(icb);

            defaultWorkspaceSelection = CustomSettingUtils.getSingleProcessConfigurationValue('UploadContentSalesChannelLibrary-ICB', [select Id, Sales_Channel__c from User where Id = : o.OwnerId].Sales_Channel__c, true);
			titlePrefix = !String.IsEmpty(o.Name) ? (o.Name +  ' - ' +  icbs.get(0).Name + ' - ') : (icbs.get(0).Name + ' - ');
    		retVal = 'ICB__c';
    	}
		else if(objectId.startsWith(Integra_Contract__c.SObjectType.getDescribe().getKeyPrefix())){
			Integra_Contract__c ic = [Select I.Account__r.Name from Integra_Contract__c I where I.Id = :objectId limit 1][0];
			titlePrefix = ic.Account__r.Name + ' - ';
			retVal = 'Integra_Contract__c';
			isIntegraContract = true;
			AcctName = ic.Account__r.Name;
		}
		else if(objectId.startsWith(Order__c.SObjectType.getDescribe().getKeyPrefix())){
			Order__c ord = [Select Account_Search__c, Account__r.Name, Id, OwnerId from Order__c where Id = : objectId];
			isOrderContent = true;
			titlePrefix = '';
			orderId = objectId;
			retVal = 'Order__c';
			AcctName = ord.Account_Search__c == null ? ord.Account__r.Name : ord.Account_Search__c;		
		}
    	else{
    		 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Must be associated to Account, Integra Contract, Opportunity, or ICB'));
    	}
    	
    	oTypeName = retVal;
    	
    	if(!String.IsEmpty(oTypeName)){
    		flag = true;
    	}  
    	return flag;
    }
    
    public string getObjectId(){
    	return ApexPages.currentPage().getParameters().get('id');  
    }

    public static List<SelectOption> LoadWorkspaces(string filter) {
    	
        List<SelectOption> retVal = new List<SelectOption>();
        
	    for( ContentWorkspace cw : [Select Id, Name from ContentWorkspace where Name LIKE:filter])
	        retVal.add( new SelectOption(cw.Id, cw.Name));
	    
        if(retVal.size() < 1 && filter != 'Contract Management%')
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have access to contribute to the Sales Workspace'));
  
        return retVal;
    }
    
    private ContentVersion InitContentVersion() {
        
        ContentVersion c = new ContentVersion();
        if(isIntegraContract)
			c.Asset_Type__c = 'Customized or Client-Specific';
        return c;
    }
    
    private Boolean SaveContentVersion() {
        if (isGeneratedContent)
            fileContents = fileContentsUpload;
        
        if( ((cv.Title == null) || (cv.Title == ''))  && !isOrderContent) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Title'));
            return false;               
        }
                
        if( ((cv.Description == null) || (cv.Description == '')) && !isOrderContent ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Description'));
            return false;               
        }
        
        if( (fileContents == null) || (fileContents.size() == 0) ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select file to upload'));
            return false;               
        }
        
        Schema.DescribeSObjectResult r = Account.SObjectType.getDescribe();
		System.debug(System.LoggingLevel.DEBUG, 'isOrderContent: ' + isOrderContent + ' -- parentId: ' + parentId);
		if(isOrderContent && parentId == null){		
			parentId = orderId;
		}	
        if(parentId.startsWith(Account.SObjectType.getDescribe().getKeyPrefix()))
            cv.Account__c = parentId;
        else if(parentId.startsWith(Opportunity.SObjectType.getDescribe().getKeyPrefix()))
            cv.Opportunity__c = parentId;
        else if(parentId.startsWith(ICB__c.SObjectType.getDescribe().getKeyPrefix()))
            cv.ICB__c = parentId;
        else if(parentId.startsWith(Order__c.SObjectType.getDescribe().getKeyPrefix()))
            cv.Order__c = parentId;
		else if(parentId.startsWith(Integra_Contract__c.SObjectType.getDescribe().getKeyPrefix())){
			//default is general
			//cv.RecordTypeId = [select Id from RecordType where sObjectType = 'ContentVersion' and DeveloperName = 'General' limit 1].Id;
			cv.Integra_Contract__c = parentId;
			cv.Intended_Audience__c = 'Internal Only';
			cv.OwnerId = UserInfo.getUserId();
		}
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Must be associated to Account, Integra Contract, Opportunity, or ICB'));
            return false;                           
        }       
        
        cv.VersionData = fileContents;  
        cv.FirstPublishLocationId = selectedWorkspace;
		
        if(!isIntegraContract)
        	cv.Intended_Audience__c = 'Customer Facing';
        if(!isOrderContent && !isIntegraContract){
        	cv.Asset_Type__c = 'Sales Forms and Pricing';
        	cv.Asset_SubType__c = 'Technical Supporting Documents';
        }
        if (isGeneratedContent && !isOrderContent && !isIntegraContract)
            cv.PathOnClient = cv.Title + '.pdf';
        
        if(isOrderContent){
        	cv.Account__c = cv.Account__c != null ? cv.Account__c : null;
        	cv.Opportunity__c = cv.Opportunity__c != null ? cv.Opportunity__c : null;
        	cv.Order__c = orderId;
        	cv.Asset_Type__c = 'Customized or Client Specific';
        	cv.Asset_SubType__c = cv.Asset_SubType__c;
        	cv.RecordTypeId = contractRecordType;
        	cv.Product_Category__c = cv.Product_Category__c;
        	titlePrefix = '';
        	orderName = [Select Name From Order__c Where Id =: orderId Limit 1].Name;        	
        	titlePrefix = AcctName != null ? AcctName + '-' + orderName + '-' + cv.Asset_Type__c + '-' + cv.Asset_SubType__c + '-' : orderName + '-' + cv.Asset_Type__c + '-' + cv.Asset_SubType__c + '-';
        }
        cv.Title = !isOrderContent ? (titlePrefix + cv.Title) : (titlePrefix + cv.PathOnClient);
        
        try{       	
            insert cv;
            return true;
        }
        catch(Exception e){
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'You do not have publish persmissions in the selected library.'));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
        return false;
    }
    
    public PageReference save() {
        if( !SaveContentVersion() )
            return null;

        return cancel();
    }

    public PageReference saveAndNew() {
        SaveContentVersion();
     
        if(parentId.startsWith(ICB__c.SObjectType.getDescribe().getKeyPrefix()))
        	return new PageReference('/apex/ICBUploadContent?id=' + objectId);
        else if(parentId.startsWith(Account.SObjectType.getDescribe().getKeyPrefix()))	
			return new PageReference('/apex/AccountUploadContent?id=' + objectId);
		else if(parentId.startsWith(Order__c.SObjectType.getDescribe().getKeyPrefix()))	
			return new PageReference('/apex/OrderUploadContent?id=' + objectId);
		else if(parentId.startsWith(Integra_Contract__c.SObjectType.getDescribe().getKeyPrefix()))
			return new PageReference('/apex/IntegraContractUpload?id=' + objectId);
		else
        	return new PageReference('/apex/OpptyUploadContent?id=' + objectId);
    }
    
    public PageReference cancel() {
        PageReference currentPage = new PageReference('/' + parentId);
        currentPage.setRedirect(true);
		return currentPage;
    }
  /*  	else{
    		PageReference currentPage = new PageReference('/' + orderId);
        	currentPage.setRedirect(false);
        	return currentPage; 
    	}       */
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_UploadContent(); }
}