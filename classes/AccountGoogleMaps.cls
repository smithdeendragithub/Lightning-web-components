public with sharing class AccountGoogleMaps {
    public Account account{get;set;}
    public List<Service_Location__c> servLocs {get;set;}
    public AccountGoogleMaps(ApexPages.StandardController stdController) {
        try{
            this.account = (Account) stdController.getRecord();
            servLocs = new List<service_location__c>();
            List<Service_Location__c> sls = [Select Id,Name,Location__r.Building__r.Latitude__c,Location__r.Building__r.Longitude__c,Location__r.Building__r.Address__c,Location__r.Building__r.City__c From Service_Location__c Where Account__r.Id = :account.id];
            if(sls.size() > 0)
                servLocs = sls;
        } catch(Exception e){
            ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage());
            ApexPages.addMessage(m);
        }
    }
}