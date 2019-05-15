public with sharing class OrderWorkstepsController {
    public Order__c ord {get; set;}
    
    public List<Workstep__c> wsList {get; set;}

    public OrderWorkstepsController(ApexPages.StandardController controller) {
        ord = (Order__c)controller.getRecord();
        wsList = [Select  Name, Start_Date__c, End_Date__c, Owner.Name, Status__c, Duration__c, SLA__c, Actual_Completion_Date__c from Workstep__c WHERE Workstep__c.Sub_Order__c = null AND Workstep__c.Order__c = :ord.Id];
    }
}