public with sharing class ProposalPricingAgreementController {
    public String CustomerName {get;set;}
    public String ContractTerm {get;set;}
    public String contactName {get;set;}
    //public List<Pricing_Agreement_Product__c > PricingAgreementProducts {get;set;}
    public List<PricingAgreementProductWrapper > PricingAgreementProductWrappers {get;set;}
    
    public Pricing_Agreement__c currentPricingAgreement {
        get{
            return currentPricingAgreement;
        }
        set{
            boolean color = true;
            currentPricingAgreement = value;
            CustomerName = currentPricingAgreement.Account__r.Name;
            ContractTerm = currentPricingAgreement.Contract_Term__c;
            //PricingAgreementProducts = [SELECT Product__c, MRC_1__c, MRC_2__c, MRC_3__c, NRC_1__c, NRC_2__c, NRC_3__c FROM Pricing_Agreement_Product__c WHERE Pricing_Agreement__c = :currentPricingAgreement.Id order by Product__c];
            PricingAgreementProductWrappers = new List<PricingAgreementProductWrapper>();
            for(Pricing_Agreement_Product__c p : [SELECT Product__c, MRC_1__c, MRC_2__c, MRC_3__c, NRC_1__c, NRC_2__c, NRC_3__c FROM Pricing_Agreement_Product__c WHERE Pricing_Agreement__c = :currentPricingAgreement.Id order by Product__c]){
                PricingAgreementProductWrapper pap = new PricingAgreementProductWrapper(p, color);  
                PricingAgreementProductWrappers.add(pap);
                color = !color;
            }
        }
    }

    public class PricingAgreementProductWrapper {
        public boolean Color {get;set;}
        public string Product {get;set;}
        public decimal MRC1 {get;set;}
        public decimal MRC2 {get;set;}
        public decimal MRC3 {get;set;}
        public decimal NRC1 {get;set;}
        public decimal NRC2 {get;set;}
        public decimal NRC3 {get;set;}
        
        public PricingAgreementProductWrapper(Pricing_Agreement_Product__c pap, boolean b){
            Color = b;
            Product = pap.Product__c;
            MRC1 = pap.MRC_1__c;
            MRC2 = pap.MRC_2__c;
            MRC3 = pap.MRC_3__c;
            NRC1 = pap.NRC_1__c;
            NRC2 = pap.NRC_2__c;
            NRC3 = pap.NRC_3__c;
        }
    }
}