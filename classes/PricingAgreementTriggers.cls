public without sharing class PricingAgreementTriggers {
   private static final Set<String> wonICBStatusSet = new Set<String>{'Approved-Pending Sale'};
   public static void PricingAgreementModified(List<Pricing_Agreement__c> tNew, List<Pricing_Agreement__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
        Map<Id, Pricing_Agreement__c> tOldMap = tOld != null ? new Map<Id, Pricing_Agreement__c>(tOld) : new Map<Id, Pricing_Agreement__c>();

       if(isBefore){
          if(!isDelete){
              checkCanLockRecords(tNew, tOldMap);
          }
       }else{
          if(isUpdate){
             updateRelatedICBStatuses(tNew, tOldMap);
          }
       }
   }
   
   private static void checkCanLockRecords(List<Pricing_Agreement__c> tNew, Map<Id, Pricing_Agreement__c> tOldMap ){
       String userProfile = [select Name from Profile where Id =: UserInfo.getProfileId()].Name;
       for(Pricing_Agreement__c pa: tNew){
           if(pa.Record_Locked__c && userProfile != 'System Administrator'){
               pa.addError('This Wholesale Pricing Agreement record is locked. No change is allowed');
           }
           if(!pa.Record_Locked__c && pa.Contract_Signed_Date__c != null && pa.Contract_Signed_By__c != null){
               pa.Record_Locked__c = true;
           }
       }
   }
   public static void updateRelatedICBStatuses(List<Pricing_Agreement__c> tNew, Map<Id, Pricing_Agreement__c> tOldMap ){
        Set<Id> approvedIDs = new Set<id>();
        for(Pricing_Agreement__c pa: tNew){
            if(pa.Approval_Status__c!= tOldMap.get(pa.Id).Approval_Status__c&& pa.Approval_Status__c != null && pa.Approval_Status__c =='Approved'){
                approvedIDs.add(pa.Id);
            }
        }
        
        //  Removed ICB_Technical_Reason__c because this field is deleted
        if(approvedIDs.size() > 0){
            Map<Id, ICB__c> m = new Map<Id, ICB__c>([select Name, Id, Status__c, Pricing_Agreement__c, ICB_Pricing_Reason__c, ICB_Type__c from ICB__c where Pricing_Agreement__c in: approvedIDs]);
            Map<Id, ICB__c> updates = new Map<Id, ICB__c>();
            
            for(Pricing_Agreement__c pa : tNew){
                if(approvedIDs.contains(pa.id)){
                    for(ICB__c i : updateICBStatus(getICBsByPricingAgreementAndStatus(m, pa.id, wonICBStatusSet), 'Approved'))
                        updates.put(i.id, i);

                }
            }
            
            List<ICB__c> icbs = updates.values();
            if(icbs.size() > 0){
                List<String> errors = new List<String>();
                
                Database.SaveResult[] results = Database.update(icbs, false);
                for(Integer i=0; i<results.size(); i++){
                    Database.SaveResult result = results[i];
                    for(Database.Error error : result.getErrors())
                        errors.add(icbs[i].Id + ': ' + error.message);
                }
                
                if(errors.size() > 0)
                    ApexUtils.sendEmails(new List<Messaging.SingleEmailMessage>{ApexUtils.createEmailMessage(new List<String>{UserInfo.getUserEmail()}, CustomSettingUtils.IntegrationErrorEmailAddresses, 'ICB records failed to save from Pricing Agreement Approval Status change', string.join(errors, '\n'), false, null)});
            }
        }        
   
   }
   
    private static List<ICB__c> getICBsByPricingAgreementAndStatus(Map<Id, ICB__c> icbmap, Id paId, Set<String> statuses){
        List<ICB__c> icblist = new List<ICB__c>();
        for(ICB__c icb : icbmap.values()){
            string strPaid = icb.Pricing_Agreement__c;
            if(strPaid.contains(paId) && statuses.contains(icb.status__c))
                icblist.add(icb);
        }
        return icblist; 
    }
    private static List<ICB__c> updateICBStatus(List<ICB__c> icbs, String newStatus){
        
        for(icb__c icb : icbs){
            icb.Status__c = newStatus;
            
            icb.ICB_Pricing_Reason__c = (string.isEmpty(icb.ICB_Pricing_Reason__c) && icb.ICB_Type__c == 'Pricing') ? 'Other' : icb.ICB_Pricing_Reason__c;
        }
        
        return icbs;
    }    
   
}