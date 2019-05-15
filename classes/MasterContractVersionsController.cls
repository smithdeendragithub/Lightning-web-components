public with sharing class MasterContractVersionsController {

    public List<SelectOption> workspaces {get;set;}
    public Id selectedWorkspace {get;set;}
    public List<SelectOption> contracts {get;set;}
    public String selectedContract {get;set;}
    public String getselectedContract(){
    	if(selectedContract==null){selectedContract='NewContract';}
            return selectedContract;
    }
    
    public void setselectedContract(String sContract){
        selectedContract = sContract;
    }
    
    private String defaultWorkspaceSelection {get;set;}
    
    public ContentVersion cv {get;set;}
    public List<ContentVersion> listCV {get;set;}
    public Map<Id, ContentVersion> aContracts {get;set;}
    public Blob fileContents {get;set;}  
    public Blob fileContentsUpload {get;set;}  
    
    //We do it this way (with custom getter/setters) because if we call InitContentVersion on the constructor
    //the isGeneratedContent variable has not been initialized yet and we get an error
    public Boolean isGeneratedContent;
    public void setisGeneratedContent (Boolean b) {
        isGeneratedContent = b;
        
        if (isGeneratedContent) {
          cv.Asset_Type__c = 'Technical Supporting Documents';
        }
    }
    
    public Boolean getisGeneratedContent() {
        return isGeneratedContent;
    }

    public string objectId { get; set; }

    public class DisplayField {
        public Boolean required {get;set;}
        public String boundName {get;set;}
    }

	public List<SelectOption> getContracts(){
		return this.contracts;
	}
    public MasterContractVersionsController(){
    	
      	//objectId = getObjectId();
        isGeneratedContent = (ApexPages.currentPage().getParameters().get('isGeneratedContent') == 'true');
		workspaces = LoadWorkspaces('MasterContracts');

		for(SelectOption so : workspaces){
				selectedWorkspace = so.getValue();
		}
		
		this.contracts = createContractSelections();
		/*for(SelectOption sc : contracts){
system.debug('sc: ' + sc); 			
					selectedContract = sc.getValue();
system.debug('selectedContract: ' + selectedContract); 					
		}   */    	
        cv = InitContentVersion();
    }
    
    private List<SelectOption> createContractSelections() {
        aContracts = new Map<Id,ContentVersion>();
        for(ContentVersion cVersion : [Select Id, Title, PathOnClient, ContractStartDate__c, ContractEndDate__c, IsActiveVersion__c, Integra_Contract_Version__c From ContentVersion Where Intended_Audience__c = 'Master Contract' Order By Title]){
			aContracts.put(cVersion.Id, cVersion);
		}

        List<SelectOption> selectOptions = new List<SelectOption>();
        List<SelectOption> selectOptionsSort = new List<SelectOption>();
        selectOptions.add(new SelectOption('0', '-NewContract-'));
		Set<Id> cvIds = new Set<Id>();
	     AggregateResult[] ar = [Select Max(Id) Id, Title t from ContentVersion where Intended_Audience__c='Master Contract' GROUP BY Title];
	     if(ar.size() > 0){
	        for(AggregateResult conver : ar){	        	
	        	cvIds.add(conver.Id); 	        	
	        }
	     }
	      if(cvIds.size() > 0){
	      	listCV = new List<ContentVersion>();

			for(Id mv : cvIds){
				listCV.add(aContracts.get(mv));
			}
			for(ContentVersion versions : listCV){
				selectOptions.add(new SelectOption(versions.Id, versions.Title));
			}
	      }
	      selectOptionsSort = selectOptionSorter(selectOptions);     
        return selectOptionsSort;
    }   

//SelectOption sort method --takes a List<SelectOption>. If case-sensitive labels, this will need more to manage that.    
	public List<SelectOption> selectOptionSorter(List<SelectOption> ListToSort){

		if(ListToSort == null || ListToSort.size() <= 1)
            return ListToSort;
         
        Map<String, Selectoption> mapping = new Map<String, Selectoption>(); 
        for(SelectOption so : ListToSort){
        	mapping.put(so.getLabel(), so);
        }
        List<String> sortKeys = new List<String>();
        sortKeys.addAll(mapping.keySet());
        sortKeys.sort();
        // clear the original collection to rebuilt it
        ListToSort.clear();
        
        for (String key : sortKeys) {
            ListToSort.add(mapping.get(key));
        }       
        return ListToSort;
	}
	
    public string getObjectId(){
    	return ApexPages.currentPage().getParameters().get('id');  
    }

    public static List<SelectOption> LoadWorkspaces(string filter) {
    	
        List<SelectOption> retVal = new List<SelectOption>();
        
	    for( ContentWorkspace cw : [Select Id, Name from ContentWorkspace where Name LIKE:filter])
	        retVal.add( new SelectOption(cw.Id, cw.Name));
	    
        if(retVal.size() < 1)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have access to contribute to the Master Contracts workspace'));
  
        return retVal;
    }
    
    private ContentVersion InitContentVersion() {
        
        ContentVersion c = new ContentVersion();
        
        return c;
    }
    
    
    private Boolean SaveContentVersion() {
        if (isGeneratedContent)
            fileContents = fileContentsUpload;
        
        if( (selectedContract == '-NewContract-' && (cv.Title == null) || (cv.Title == '') )) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Title'));
            return false;               
        }
        
        if( (fileContents == null) || (fileContents.size() == 0) ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select file to upload'));
            return false;               
        } 
       if(listCV != null){
	       for(ContentVersion cVer : listCV){
	
	        if(cVer.Title == cv.Title && selectedContract == '0'){       	
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select existing contract title or a different Title name as your title already exists.'));
	            return false;
	        }
	        }
       }
        string version = ''; 
        boolean newContract = false; 
        List<ContentVersion> updateContent = new List<ContentVersion>();

for(Selectoption so : this.contracts){
	if(so.getValue() == selectedContract)
	{
		selectedContract = so.getLabel();
	}
}
	        	if(selectedContract == '-NewContract-')
	        		newContract = true;
	        		
	        	else if(selectedContract != '-NewContract-'){
	        		if(listCV.size() > 0){
	        		for(ContentVersion content : listCV){
	        			if(content.Title == selectedContract){
	        			decimal vNum = integer.valueof(content.Integra_Contract_Version__c);
	            		version = string.valueof(vNum + 1);
						content.IsActiveVersion__c = false;
						content.ContractEndDate__c = datetime.now();
						updateContent.add(content);
	        			}
	        		}
	        	}
	        	}
	        	else
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An Active Master Version of the Contract Title you selected doesnt exist or is unavailable. Please confirm your selection, select NewContract or contact your SF Administrator.'));
	        	
        if(newContract){
        	cv.Integra_Contract_Version__c = 1;
        	cv.Title = cv.Title;
        }
        else{
        	cv.Integra_Contract_Version__c = decimal.valueof(version);
        	cv.Title = selectedContract;
        }
        cv.ContractStartDate__c = datetime.now();
        cv.VersionData = fileContents; 
        cv.IsActiveVersion__c = true; 
        cv.FirstPublishLocationId = selectedWorkspace;
        
        cv.Intended_Audience__c = 'Master Contract';
        cv.Asset_Type__c = 'Sales Forms and Pricing';
        cv.Asset_SubType__c = 'Technical Supporting Documents';
        
        if (isGeneratedContent)
            cv.PathOnClient = cv.Title + '.pdf';
       
        try{
            insert cv;
            if(updateContent.size() > 0)
            update updateContent;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Contract Upload Complete.'));
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
        return new PageReference('/apex/MasterContractVersions');
    }
    
    public PageReference cancel() {
        PageReference currentPage = new PageReference('/apex/MasterContractVersions');
        currentPage.setRedirect(true);      
        return currentPage;     
    }
    
}