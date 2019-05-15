public without sharing class CaseNetXWorkFlow {
    private static Boolean DisableTrigger = false;
    private static Map<Id, RecordType> ccaseRts = null;
//    private static Map<Id, RecordType> CaseRts{
//        get{
//            if(ccaseRts == null) ccaseRts = new Map<Id, RecordType>([select Id, DeveloperName from RecordType where sObjectType = 'Case']);
//            return ccaseRts;
//        }
//        Set{}
//    }
//    
//NetX cases //    
//      
   public static void CaseNetXWorkFlow(List<Case> tNew, List<Case> tOld, Boolean isBefore, Boolean isUpdate, Boolean isDelete){     
       String strRecordTypeNetX = [Select Id From RecordType Where SobjectType = 'Case' and Name = 'NetEx Case'].Id; 
       set<Id> IDs = new set<Id>();
       for(Case c : tNew){
           if(c.Netx__c != Null && c.NetEx_Business_Unit__c == Null) {
 				IDs.add(c.NetX__c);
           }
       }
       List<Expense__c> ze = [SELECT Id, NAME,Business_Unit_Owner__c  FROM Expense__c WHERE ID in :IDs];
       for(Case c : tNew){  
       		//String strRecordTypeNetX = [Select Id From RecordType Where SobjectType = 'Case' and Name = 'NetEx Case'].Id;
          	if (isBefore && c.RecordTypeId == strRecordTypeNetX ){
                // Net ExBUsiness Unit
                if(c.Netx__c != Null && c.NetEx_Business_Unit__c == Null) {
                    if(ze.size() > 0){
                        for (Expense__c ThisExpense : ze) {
                            if (c.NetX__c == ThisExpense.Id) {
                                c.NetEx_Business_Unit__c = ThisExpense.Business_Unit_Owner__c;         
                            }
                        }
                    }   
                }   
                // NetX Vendor Account Lookup
                if(c.WS_Vendor_Account_ID__c != null && c.Vendor_Account__c == null){
                    c.Vendor_Account__c = c.WS_Vendor_Account_ID__c;
                    //             c.description = 'TEST';
                }                      
                // NetX InProgress Date Time
                if(c.In_Progress_Date_Time__c == null && c.Status == 'In Progress'){
                    c.In_Progress_Date_Time__c = (system.Now());
                } 
                // NetX Type
                if(c.Type != 'NetX'){
                    c.Type = 'NetX';
                }           
// 
       		} // end if NetX
     	}               
   	}        
//                  
// End NetX    
//
}