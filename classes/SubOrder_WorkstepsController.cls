public with sharing class SubOrder_WorkstepsController {
    public Boolean standAlonePage {get; set;}
    public Boolean viewZeroDuration {get; set;}
    public Boolean isWSI {get; set;}
    public List<Workstep__c> defaultWorksteps {get; set;}
    public List<Workstep__c> zeroDurWorksteps {get; set;}
    public List<Workstep_Issue__c> wsi  {get; set;}
    public SubOrder_WorkstepsController(ApexPages.StandardController controller) {
        String cPage = ApexPages.currentPage().getparameters().get('so');
        if(cPage != null)       
            standAlonePage = cPage == 'true' ? true : false; 
        toggleZeroWorksteps();
        wsi = getWorkstepIssues();        
    } 
           
    Id myId = apexpages.currentpage().getparameters().get('id');      
//Get the API name of the sObject (Order__c or SubOrder__c) for query below //
    String objectType = myId.getSObjectType().getDescribe().getName();

    public List<Workstep__c> getWorksteps() {

        List<Workstep__c> results = Database.query(
            'SELECT Name, Start_Date__c, End_Date__c, Owner.Name, Owner.Type, Duration__c, SLA__c, Status__c, Attribute__c, workstep_tag__c  ' +
            'FROM Workstep__c ' +
            'WHERE Workstep__c.' + objectType + ' = ' + '\'' + (string)myId + '\'' +
            ' ORDER BY ' + sortOrder
        );
        return results;
    }

    public PageReference toggleZeroWorksteps() {
        if(viewZeroDuration == null){viewZeroDuration = false;}
        
        if(viewZeroDuration){            
            defaultWorksteps = Database.query(
            'SELECT Name, Start_Date__c, End_Date__c, Owner.Name, Owner.Type, Duration__c, SLA__c, Status__c, Attribute__c, workstep_tag__c  ' +
            'FROM Workstep__c ' +
            'WHERE Workstep__c.' + objectType + ' = ' + '\'' + (string)myId + '\'' +   
            ' ORDER BY ' + sortOrder
        	);           
        }
        else if(!viewZeroDuration){             
			defaultWorksteps = Database.query(
            'SELECT Name, Start_Date__c, End_Date__c, Owner.Name, Owner.Type, Duration__c, SLA__c, Status__c, Attribute__c, workstep_tag__c  ' +
            'FROM Workstep__c ' +
            'WHERE Duration__c != 0 AND Workstep__c.' + objectType + ' = ' + '\'' + (string)myId + '\'' +
            ' ORDER BY ' + sortOrder
        	);                 
       }
        viewZeroDuration = viewZeroDuration == true ? false : true;
        
        return null;
    }
        
    public List<Workstep_Issue__c> getWorkstepIssues() {
    
        List<Workstep_Issue__c> results = Database.query(
            'SELECT Name, Status__c, Expected_Follow_Up_Date__c, Reason__c, Estimated_Resolution__c, Workstep__r.Name, Workstep__r.Id, Owner.Name, Owner.Type ' +
            'FROM Workstep_Issue__c ' +
            'WHERE Workstep_Issue__c.Workstep__r.' + objectType + ' = ' + '\'' + (string)myId + '\'' +
            ' ORDER BY ' + sortWSIOrder 
        );
        return results;
    }

 /* -- WORKSTEP COLUMN SORTING -- */        
    public String sortColumn { get; set; }
    private String sortOrder = 'End_Date__c ASC';
    
     public void sortResults() {  
         if ( this.sortOrder != sortColumn + ' ASC') {
                   this.sortOrder = sortColumn + ' ASC' ;
                    }
                else {
                    this.sortOrder = sortColumn + ' DESC';
                }
    }
    
 /* -- WSI COLUMN SORTING -- */    
    public String sortWSIColumn { get; set; }
    private String sortWSIOrder = 'Expected_Follow_Up_Date__c ASC';
    
     public void sortWSIResults() {  
         if ( this.sortWSIOrder != sortWSIColumn + ' ASC') {
                   this.sortWSIOrder = sortWSIColumn + ' ASC' ;
                    }
                else {
                    this.sortWSIOrder = sortWSIColumn + ' DESC';
                }
    }
    
}