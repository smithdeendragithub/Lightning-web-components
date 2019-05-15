public with sharing class PricingAgreementPDFDisplayController {
    public transient ApexPages.Component comp {get; private Set;}
    public String paId {get;set;}
    
    public PricingAgreementPDFDisplayController(){
        comp = new Component.Apex.OutputPanel();
       	paId = ApexPages.currentPage().getParameters().get('pricingAgreementId');   
        Pricing_Agreement__c pa = [SELECT Id, Name, Account__c, Account__r.Name, Contract_Term__c FROM Pricing_Agreement__c WHERE Id=:paId]; 
        Component.Apex.OutputPanel op = new Component.Apex.OutputPanel(layout='block');
        op.childComponents.add(new Component.c.PDF_PricingAgreement(currentPA = pa));
        //ApexPages.Component c = 
        comp.childComponents.add(op);
    }

}