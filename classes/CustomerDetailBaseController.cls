public with sharing abstract class CustomerDetailBaseController extends TreeViewController{
    
    protected sObject baseObject {get; set;}
    public Customer_Detail__c detail {get; private set;}
    
    public Customer_Setting__c eRate { get; private set; }
    public Boolean eRateFlag { get; set; }
    
    public List<SelectOption> GovernmentContractTypes{ get{ return SchemaUtils.GetPicklistValues(Schema.Customer_Detail__c.sObjectType.fields.Government_Contract_Type__c, true); } }
    public List<SelectOption> GovernmentSegments{ get{ return SchemaUtils.GetPicklistValues(Schema.Customer_Detail__c.sObjectType.fields.Government_Segment__c, true); } }
    
    protected void loadDetails(){
        
        Id cdID = (SchemaUtils.GetSObjectNameByID(baseObject.Id) == 'Account') ? [select Id, Customer_Detail__c from Account where Id =: baseObject.Id][0].Customer_Detail__c : [select Id, Customer_Detail__c from Service_Location__c where Id =: baseObject.Id][0].Customer_Detail__c;
        detail = [select Id
                        ,Name
                        ,ICC_Subscriber_ID__c
                        ,Integration_Status__c
                        ,(select Id, Name from Accounts__r)
                        ,(select Id, Name from Service_Locations__r)
                        ,(select Id, Contact__r.Id, Contact__r.Name from Customer_Contacts__r where Contact_Type__c =: ICCWrapper.ResonsiblePartyContactType order by CreatedDate, Id)
                        ,(select Id, External_ID__c from Customer_Settings__r where RecordType.DeveloperName = 'Subscriber_Setting' and Reference_ID__c = '41')
                  		,Bill_Cycle__r.Name
                        ,Collection_Code__r.Name
                        ,Customer_Account_Manager__c
                        ,Exchange__r.Name
                        ,Government_Contract_Type__c
                        ,Government_Segment__c
                        ,Market_Type__r.Name
                        ,Care_Organization__r.Name
                        ,Service_Address__c
                        from Customer_Detail__c where Id =: cdID];
        
        
                
        eRate = detail != null && detail.Customer_Settings__r != null && detail.Customer_Settings__r.size() > 0 ? detail.Customer_Settings__r[0] : null;
        eRateFlag = eRate != null;
    }
    
    public PageReference generateDetails(){
        Boolean cloneFromParent = ApexPages.currentPage().getParameters().get('cloneFromParent') == 'true';
        
        Set<Id> frontEndIDs = null;
        if(baseObject.get('Customer_Detail__c') == null){
            CustomerDetailUtils.triggerDetailAddressValidation = false; //Run Synchronous
            
            if(SchemaUtils.GetSObjectNameByID(baseObject.Id) == 'Account'){
                Account a = (Account)baseObject;
                List<Service_Location__c> sLocs = [select Id, Customer_Detail__c from Service_Location__c where Account__c =: a.Id];
                frontEndIDs = (a.ICC_Account_Number__c == null && sLocs.size() == 1) ? new Set<Id>{sLocs[0].Id, baseObject.Id} : new Set<Id>{baseObject.Id};
            }
            else{
                Service_Location__c sLoc = (Service_Location__c)baseObject;
                Account a = sLoc.Account__c != null ? [select Id, ICC_Account_Number__c, Customer_Detail__c, CurrencyISOCode from Account where Id =: sLoc.Account__c] : null;
                if(cloneFromParent){
                    for(Customer_Detail__c cd : CustomerDetailUtils.cloneCustomerDetailsFromParent(new Set<Id>{sLoc.Id}))   //Should only return one
                        sLoc.Customer_Detail__c = cd.Id;
                }
                else frontEndIDs = (a != null && a.ICC_Account_Number__c == null && [select COUNT() from Service_Location__c where Account__c =: sLoc.Account__c] == 1) ? new Set<Id>{sLoc.Id, sLoc.Account__c} : new Set<Id>{sLoc.Id};
                    
            }
            
            if(frontEndIDs != null) CustomerDetailUtils.updateCustomerDetails(new List<Set<Id>>{frontEndIDs});
        }
        
        UpdateGovernmentAndBPIDFields();        
        loadDetails();
        
        return null;
    }
    
    public PageReference updateDetails(){
        if(!eRateFlag && eRate != null){
            if(String.isEmpty(eRate.External_ID__c) || ICCWrapper.deleteSubscriberSettings(new List<Integer>{integer.valueOf(eRate.External_ID__c)}, UserInfo.getSessionID()).size() > 0){
                Database.delete(eRate, false);
            }
            else addCustomMessage(true, 'The E-Rate setting could not be deleted.');
        }
        else if(eRateFlag && eRate == null){
            Id rtID = [select Id from RecordType where DeveloperName = 'Subscriber_Setting'][0].Id;
            List<Customer_Setting_Reference__c> refs = [select Description__c from Customer_Setting_Reference__c where ID__c = '41' and Category__c = 'SubscriberSetting'];
            Customer_Setting__c setting = new Customer_Setting__c(Name = refs[0].Description__c, Customer_Detail__c = detail.Id, RecordTypeId = rtID, Reference_ID__c = '41');
            
            String errorMessage = CustomerDetailUtils.integrateSubscriberSetting(detail, setting);
            if(String.isEmpty(errorMessage)) Database.insert(setting);
            else addCustomMessage(true, errorMessage);
        }
        
        UpdateGovernmentAndBPIDFields();
            
        Database.update(detail, false);
        loadDetails();
        return null;
    }
    
    private void UpdateGovernmentAndBPIDFields(){
        if(SchemaUtils.GetSObjectNameByID(baseObject.Id) == 'Service_Location__c'){ 
            Service_Location__c sLocation = [Select Id, Customer_Detail__r.Id, Account__r.Customer_Detail__r.BPID__c, Account__r.Customer_Detail__r.Government_Contract_Type__c, Account__r.Customer_Detail__r.Government_Segment__c From Service_Location__c Where Id =: baseObject.Id Limit 1];
            Customer_Detail__c sLocDetail = [Select BPID__c, Government_Contract_Type__c, Government_Segment__c From Customer_Detail__c Where Id =: sLocation.Customer_Detail__r.Id Limit 1];
            sLocDetail.BPID__c = sLocation.Account__r.Customer_Detail__r.BPID__c;
            sLocDetail.Government_Contract_Type__c = sLocation.Account__r.Customer_Detail__r.Government_Contract_Type__c;
            sLocDetail.Government_Segment__c = sLocation.Account__r.Customer_Detail__r.Government_Segment__c;
            Database.update(sLocDetail);
        }
    }
    
    protected PageReference refresh(){
        PageReference nextPage = ApexPages.currentPage();
        nextPage.getParameters().clear();
        nextPage.getParameters().put('Id', baseObject.Id);
        nextPage.setRedirect(true);
        return nextPage;
    }
    
    public virtual void addCustomMessage(Boolean isError, String message){
        ApexPages.addMessage(new ApexPages.Message(isError ? ApexPages.Severity.ERROR : ApexPages.Severity.INFO, message));
    }
}