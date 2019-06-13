/**************************************************************************************************
*    OpportunityProductTriggers.cls
*
*    Modifications:
*    Developer Name       Date        Brief description
*    -------------------  ----------  ------------------------------------------------------------
*    Eunjung Ju           01/10/2018  SEAL-636 - Change the MRR calculation based on Opportunity Type(Oppty_Sub_Type__c)
*    Eunjung Ju           01/12/2018  SEAL-249 - Fix to apply the conversion rate the Currency fields
*    Eunjung Ju           04/05/2018  SEAL-1020 - Add Manual Turndown/Writedown
**************************************************************************************************/
public with sharing class OpportunityProductTriggers {
    
    public static void OpportunityProductModified(List<Opportunity_Product__c> tNew, List<Opportunity_Product__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete) {
        
        if(!ApexUtils.executeTriggerMethods('Opportunity_Product__c', isBefore, isDelete)) return;

        if(isBefore) {
            if(!isDelete){
                Map<Id, Opportunity_Product__c> tOldMap = (tOld != null) ? new Map<Id, Opportunity_Product__c>(tOld) : new Map<Id, Opportunity_Product__c>();
                updateSalesProduct(tNew, tOldMap);
                updateNAAProductAndEstimatedNAA(isUpdate, tNew);
            }
        }
        else {
            if(!isDelete){
                //assign opp product to olis that match service loc and spc product id
                for(Opportunity_Product__c oppProd : tNew){
                    if(oppProd.RecordTypeId == Schema.SObjectType.Opportunity_Product__c.getRecordTypeInfosByName().get('CPQ Entry').getRecordTypeID()){
                        Map<String,Object> params = new Map<String,Object>{'OppProdId'=>oppProd.Id};
                        Flow.Interview.Assign_Opp_Prod_To_OLIs oppProdFlow = new Flow.Interview.Assign_Opp_Prod_To_OLIs(params);
                        oppProdFlow.start();
                    }               
                }
            }
            setOpportunityFields(isDelete ? tOld : tNew);
            
            
            ApexUtils.afterTriggerComplete('Opportunity_Product__c', isDelete);
        }
    }
    
    private static void setOpportunityFields(List<Opportunity_Product__c> tNew) {
        //MNK added to reduce SOQL calls
        //Map<String, currencytype> conversionRateMap = new Map<String, currencytype>([SELECT isocode, conversionrate FROM currencytype]);
        Map<String, currencytype> conversionRateMap = new Map<String, currencytype>();
        for (currencyType ct: [SELECT isocode, conversionrate FROM currencytype]) {
            conversionRateMap.put(ct.IsoCode,ct);        
        }
        
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        for(Opportunity_Product__c op :tNew)
            opps.put(op.Opportunity__c, null);
        
        Map<Id, Map<Boolean, List<AggregateResult>>> opAgg = new Map<Id, Map<Boolean, List<AggregateResult>>>();
        for(Opportunity o : [select Id, RecordType.Name,Current_MRR_del__c,New_MRR_del__c, Oppty_Sub_Type__c, CurrencyIsoCode   from Opportunity where Id in: opps.keyset()]) {
            opps.put(o.Id, o);
            opAgg.put(o.Id, new Map<Boolean, List<AggregateResult>>{ true=>new List<AggregateResult>(), false=>new List<AggregateResult>() });
        }
        
        for(AggregateResult ar : [select SUM(MRC__c) sumAmount, SUM(NRC__c) sumNRRAmount, SUM(CPE_Amount__c) sumCPEAmount, Opportunity__c, Sales_Product__c, RecordType.Name recordType, Is_CPE_Product__c from Opportunity_Product__c where Active__c = true and Opportunity__c in: opps.keyset() group by Opportunity__c, Sales_Product__c, RecordType.Name, Is_CPE_Product__c])
            opAgg.get((Id)ar.get('Opportunity__c')).get(ar.get('recordType') == 'Turndown/Writedown' || ar.get('recordType') == 'Manual Turndown/Writedown' || ar.get('Sales_Product__c') == 'Turndown').add(ar);
        
        for(Opportunity opp : opps.values()){
            Decimal sumAmount = 0.00;
            Decimal nrrAmount = 0.00;
            Decimal cpeAmount = 0.00;
            Set<String> products = new Set<String>();
            
            Decimal tdSumAmount = 0.00;
            Set<String> tdProducts = new Set<String>();
            
            Map<Boolean, List<AggregateResult>> aggMap = opAgg.get(opp.Id); 
            for(Boolean isTurnDown : aggMap.keyset()){
                for(AggregateResult agg : aggMap.get(isTurnDown)){
                    if(isTurnDown){
                        tdSumAmount -= agg.get('sumAmount') != null ? (Decimal)agg.get('sumAmount') : 0.00;
                        tdProducts.add(string.valueOf(agg.get('Sales_Product__c')));
                    }
                    else{
                        sumAmount += agg.get('sumAmount') != null ? (Decimal)agg.get('sumAmount') : 0.00;
                        nrrAmount += agg.get('sumNRRAmount') != null ? (Decimal)agg.get('sumNRRAmount') : 0.00;
                        cpeAmount += (Boolean)agg.get('Is_CPE_Product__c') == true ? (Decimal)agg.get('sumCPEAmount') : 0.00;
                        products.add(string.valueOf(agg.get('Sales_Product__c')));
                    }
                }
            }
            
            List<String> prds = new List<String>(products);
            prds.sort();
            
            Decimal conversionRate = conversionRateMap.get(opp.CurrencyIsoCode).conversionRate;
            //Decimal conversionRate = [SELECT conversionrate FROM currencytype WHERE isocode = :opp.CurrencyIsoCode].conversionRate;

            
            //opp.New_MRR_del__c = sumAmount;
            opp.New_MRR_del__c = sumAmount*conversionRate ;
            
            //opp.NRR_Amount__c = nrrAmount;
            opp.NRR_Amount__c = nrrAmount*conversionRate;
            
            //opp.CPE_Amount__c = cpeAmount;
            opp.CPE_Amount__c = cpeAmount*conversionRate;
            
            opp.Opportunity_Product__c = String.join(prds, '; ');
            
            prds = new List<String>(tdProducts);
            prds.sort();
            //if renewal type don't sum td amount
            //if(opp.RecordType.Name != 'Renewal')
            //opp.Current_MRR_del__c = tdSumAmount;
            opp.Current_MRR_del__c = tdSumAmount*conversionRate;
            
            opp.Turndown_Product__c = String.join(prds, '; ');
            
            Decimal oppNewMRRDel = opp.New_MRR_del__c == null ? 0.00 : opp.New_MRR_del__c;
            Decimal oppCurrentMRRDel = opp.Current_MRR_del__c == null ? 0.00 : opp.Current_MRR_del__c;
            
            if(opp.Oppty_Sub_Type__c == 'Product Change' || opp.Oppty_Sub_Type__c == 'New Logo'){
                opp.Amount = oppNewMRRDel;
            }else{
                opp.Amount = (oppNewMRRDel - oppCurrentMRRDel ) > 0 ?(oppNewMRRDel - oppCurrentMRRDel ) : 0.00 ;
            }
        }
        
        update opps.values();
    }
    
    private static Map<String, Id> spLookupMap = null;
    private static Map<String, Id> opspMap{
        get{
            if(spLookupMap == null){
                spLookupMap = new Map<String, Id>();
                for(Opportunity_Product_Sales_Product__c opsp :[select Id, Name, SPC_Product__r.Name from Opportunity_Product_Sales_Product__c]){
                    spLookupMap.put(opsp.Name, opsp.id);
                }
            }
            
            return spLookupMap;
        }
    }
    
    private static void updateSalesProduct(List<Opportunity_Product__c> tNew, Map<Id, Opportunity_Product__c> tOldMap) {
        //Map of those we need to update
        Set<String> oppPrd = new Set<String>();
        for(Opportunity_Product__c op : tNew) {
            if(op.Sales_Product__c != null) oppPrd.add(op.Sales_Product__c);
        }
        
        for(Opportunity_Product__c op :tNew) {
            if(op.Sales_Product__c != null && (op.Id == null || tOldMap.get(op.Id).Sales_Product__c != op.Sales_Product__c)) {
                op.Opportunity_Product_Sales_Product__c = opspMap.get(op.Sales_Product__c);
            }
        }
    }

    /*
    private static void updateNAAProduct(List<Opportunity_Product__c> tNew){
        Map<String, Id> NAAProductMapping = new Map<String, Id>();
        for (NAA_Product__c np : [SELECT Id, Product_Name__c FROM NAA_Product__c]){
        	NAAProductMapping.put(np.Product_Name__c, np.Id);    
        }
        
        List<Opportunity_Product__c> SalesProduct = new List<Opportunity_Product__c>();
    	for(Opportunity_Product__c op :tNew) {
            if(op.Sales_Product__c != null){
                if (NAAProductMapping.containsKey(op.Sales_Product__c)){
                    op.NAA_Product__c = NAAProductMapping.get(op.Sales_Product__c);
                }	    
            }
        }	    
    }
*/
    
    private static void updateNAAProductAndEstimatedNAA(Boolean isUpdate, List<Opportunity_Product__c> tNew){
        Map<String, NAA_Product__c> NAAProductMapping = new Map<String, NAA_Product__c>();
        for (NAA_Product__c np : [SELECT Id, Product_Name__c, NAA_CA_Rate__c, NAA_AZMN_Rate__c, NAA_Default_Rate__c FROM NAA_Product__c]){
            NAAProductMapping.put(np.Product_Name__c, np);    
        }
        
        List<Id> opIds = new List<Id>();
        List<Id> opportunityIds = new List<Id>();
        List<Id> svcLocIds = new List<Id>();
        for (Opportunity_Product__c op : tNew){
        	opIds.add(op.Id);
            opportunityIds.add(op.Opportunity__c);
            svcLocIds.add(op.Primary_Service_Location__c);
        }
        
        Map<Id, Opportunity> opportunityMap;
        Map<Id, Service_Location__c> svcLocMap;
        
        opportunityMap = new Map<Id, Opportunity>([SELECT Id, Account.Default_NAA_Exempt__c, Service_Country__c FROM Opportunity WHERE Id in :opportunityIds]);
        svcLocMap = new Map<Id, Service_Location__c>([SELECT Id, Location__r.Building__r.State__c FROM Service_Location__c WHERE Id in :svcLocIds]);
        
        //System.debug('Primary_Service_Location__r.Location__r.Building__r.State__c: ' + op.Primary_Service_Location__r.Location__r.Building__r.State__c + ', ' + op.Opportunity__r.Account.Default_NAA_Exempt__c + ', ' + op.Opportunity__r.Service_Country__c);
            
        for(Opportunity_Product__c op :tNew) {
            op.Estimated_NAA_for_Roll_Up__c = 0;
            op.NAA_Product__c = null;
            if(op.Sales_Product__c != null){
                if (NAAProductMapping.containsKey(op.Sales_Product__c)){
                    NAA_Product__c naa = NAAProductMapping.get(op.Sales_Product__c);
                    op.NAA_Product__c = naa.Id;
                    //System.debug('Primary_Service_Location__r.Location__r.Building__r.State__c: ' + op.Primary_Service_Location__r.Location__r.Building__r.State__c + ', ' + op.Opportunity__r.Account.Default_NAA_Exempt__c + ', ' + op.Opportunity__r.Service_Country__c);
                    Opportunity tmpOpp = opportunityMap.get(op.Opportunity__c);
                    Service_Location__c tmpSvcLoc = svcLocMap.get(op.Primary_Service_Location__c);
                    String state = '';
                    if (tmpSvcLoc != null){
	                    state = tmpSvcLoc.Location__r.Building__r.State__c;
                    }
					op.Estimated_NAA_for_Roll_Up__c = calculateEstimatedNAA(op, tmpOpp.Account.Default_NAA_Exempt__c, tmpOpp.Service_Country__c,  State, naa);                          
                }       
            }
        }       
    }

    private static Decimal calculateEstimatedNAA(Opportunity_Product__c op, Boolean NAAExempt, String ServiceCountry, String State, NAA_Product__c naaProduct){
        if (NAAExempt == true || ServiceCountry == 'CA'){
            return 0;
        }
        switch on State {
            when 'CA'{
            	return naaProduct.NAA_CA_Rate__c * op.MRC__c;	    
            }
            when 'AZ'{
            	return naaProduct.NAA_AZMN_Rate__c * op.MRC__c;    
            }
            when 'MN'{
            	return naaProduct.NAA_AZMN_Rate__c * op.MRC__c;    
            }
            when else {
                return naaProduct.NAA_Default_Rate__c * op.MRC__c;
            }   
        }
    }
}