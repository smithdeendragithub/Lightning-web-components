public without sharing class CaseforOrderController{
    public String caseId {get; set;}
    public String returnURL {get; set;}
    public Case currentCase {get; set;}
    public Boolean canCreateOrder {get; set;}

    
    
    public CaseforOrderController(){
        caseId = ApexPages.currentPage().getParameters().get('caseId');            

        canCreateOrder =true;        
        currentCase = [Select Id, CaseNumber, AccountId,Account.name, Subject, Description, Order__c, Order__r.Name from Case where Id =:caseId];        
        if(!String.isEmpty(currentCase.Order__c)|| String.isEmpty(currentCase.AccountId)){
            returnURL = ApexPages.currentPage().getParameters().get('retURL');
            if(currentCase.Order__c != null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'This Case has already been attached to an Order. You cannot create a new order.'));
                canCreateOrder = false;
            }
            if(String.isEmpty(currentCase.AccountId)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please select an account before creating an order.'));
                canCreateOrder = false;            
            }
        }
    }
    
    public void createOrder(){
        Id integrationOnlyRecordTypeID = OrderUtils.IntegrationOnlyRecordTypeID;
        Order__c caseOrder = new Order__c(Account__c = currentCase.AccountId, RecordTypeID = integrationOnlyRecordTypeID);
        insert caseOrder;

        if (caseOrder.Id != null){
        currentCase.Status = 'Working';
            currentCase.Order__c = caseOrder.Id;
            update currentCase;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'An Order has been created'));
            canCreateOrder = false;
        }
    
    }
    
}