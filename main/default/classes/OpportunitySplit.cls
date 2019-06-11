/**************************************************************************************************
*    OpportunitySplit.cls
*
*    Modifications:
*    Developer Name       Date        Brief description
*    -------------------  ----------  ------------------------------------------------------------
*    Eunjung Ju           03/02/2018  SEAL-839 - Add NRO and Partner Users to Split Opportunities
**************************************************************************************************/
public without sharing class OpportunitySplit {

    //constants 
    public static final String SP_ERROR_AMOUNT = 'MRR Amount is required if opportunity is in proposed stage or above.';
    public static final String SP_ERROR_TERM = 'Term is required if opportunity is in proposed stage or above.';
    public static final String SP_ERROR_PARENT = 'You may only create and split opportunities at the top level';
    public static final String SP_ERROR_PCT = 'If Splits are entered, the percentage must add up from 100% to 150%. Current Total is: ';
    public static final String SP_ERROR_NAME_PCT = 'If a Split Percentage is entered, a name must be selected as well';
    public static final String SP_ERROR_NAME_ONE_PERSON = 'To split this opportunity, enter Split Percentages for at least two users.';
    public static final String SP_ERROR_NAME_ZERO = 'Split Percentage must be a number between 0 and 150.';
    
    //auto properties
    public static List<Opportunity> upsertList { get; set;}
    public static List<Opportunity> deleteList { get; set; }
    public static Opportunity instanceOpty {get; set;}
    public static  List<Opportunity> prototypelist {get; set;}
    public static Map<Integer, String> names {get; set;}
    public static Map<Integer, Double> amounts {get; set;}
    public static Map<Integer, Double> nrrAmounts {get; set;}
    public static Map<Integer, Double> nroAmounts {get; set;}    
    public static Map<string, RecordType> recordTypeMap {get; set;}
    public static Map<id, User> splitUserMap {get; set;}
    public static Boolean isSaving = false; // hack for split opp icert generation
    
    /*****************************************************************************************/
    /*Main function to create opportunity splits                                              */
    /*****************************************************************************************/
     
    public static void splitOpportunity(List<Opportunity> newOppt, List<Opportunity> oldOppt, Boolean isUpdate) {
        
        if(isSaving) return;
        
        upsertList = new List<Opportunity>();
        deleteList = new List<Opportunity>();
        names = new Map<Integer, String>();
        amounts = new Map<Integer, Double>();
        nrrAmounts = new Map<Integer, Double>();
        nroAmounts = new Map<Integer, Double>();
         
        recordTypeMap = setRecordTypeMapByLikeName('Split Opportunity');
       
        Set<Id> parentIDs = new Set<Id>();
        if(isUpdate){
            for( Opportunity o : newOppt) {
                if(recordTypeMap.isEmpty())
                    newOppt.get(0).addError('There is no appropriate recordtype in this environment for the split, please contact your administration to resolve this matter.');
                if(o.Opportunity_Parent__c == null)
                    parentIDs.add(o.Id);
            }
            nonSplitParents.removeAll(parentIDs);   //Sync/check from now on
        }
        
        setChildMaps(parentIDs);
        Map<Id, Opportunity> tOldMap = oldOppt != null ? new Map<Id, Opportunity>(oldOppt) : new Map<Id, Opportunity>();
        for( Opportunity o : newOppt) {
            Map<Id, Opportunity> childMap = getChildMap(o.Id);
            Opportunity oldOpp = tOldMap.get(o.Id);
            
            if(isSplitEligible(o) && isUpdate){
                if(ValidateSplitOpportunity(o)){
                    createValueMaps(o);
                    
                    if(childMap.size() == 0){      
                        upsertList = prototypelist.Clone();
                    }else if (childMap.size() > 0){
                        
                        if(childMap.size() == 3){
                            for(Opportunity co : childMap.values()){ 
                                if(updateFields(co, o, oldOpp)){
                                    co = instanceOpty;
                                    upsertList.add(co);
                                }
                            }
                        } else if(!isEqual(oldOppt.get(0), o) || childMap.size() != 3){
                            for(Opportunity co : childMap.values()){
                                deleteList.add(co);
                            } 
                            upsertList = prototypelist.Clone();
                        }
                    }
                }
            } else{
                if(childMap.size() > 0){
                    for(opportunity opt : childMap.values()){
                        //only touch split records and don't touch other records or self
                        if(recordTypeMap.keySet().contains(opt.RecordTypeId))
                            deleteList.add(opt);
                    }
                }
           }                    
       }
        if(!deleteList.isEmpty()){
            try{
                delete deleteList;      
            }catch (Exception e) { 
                system.debug(e.getMessage());
            }
        }
        if(!upsertList.isEmpty()){
            isSaving = true; // hack for split opp icert generation
            try{
                for(Opportunity o :upsertList){
                    if(childMaps.get(o.Opportunity_Parent__c) == null)
                        childMaps.put(o.Opportunity_Parent__c, new Map<Id, Opportunity>());
                    
                    childMaps.get(o.Opportunity_Parent__c).put(o.Id, o);
                }
                upsert upsertList;      
            }catch (Exception e) { 
                system.debug(e.getMessage());
            }
            isSaving = false; // hack for split opp icert generation
        }              
    } 
    
    private static Set<Id> nonSplitParents = new Set<Id>();
    public static void synchChildFields(Map<Id, Opportunity> tNewMap){
        Set<Id> oppParentIDs = new Set<Id>();
        for(Id oppID : tNewMap.keySet()){
            if(!nonSplitParents.contains(oppID)) oppParentIDs.add(oppID);
        }
        
        if(oppParentIDs.size() > 0){
            nonSplitParents.addAll(oppParentIDs);   //Assume each opp isn't a parent, remove from list within for loop
            
            List<Opportunity> cOppsToUpdate = new List<Opportunity>();
            for(Opportunity cOpp : [select id, Opportunity_Parent__c, ForecastCategoryName from Opportunity where Opportunity_Parent__c in: oppParentIDs]){
                ApexUtils.deepCopyFields(Opportunity.sObjectType, tNewMap.get(cOpp.Opportunity_Parent__c), cOpp, new Set<String>{
                    'Split_Percent_1__c',
                    'Split_Percent_2__c',
                    'Split_Percent_3__c',
                    'Split_Amount_1__c',
                    'Split_Amount_2__c',
                    'Split_Opp_Name__c',
                    'Split_Owner_1__c',
                    'Split_Owner_2__c',
                    'Split_Owner_3__c',
                    'Opportunity_Parent__c',
                    'OwnerId',
                    'Name',
                    'Id',
                    'RecordTypeId',
                    'Amount','NRR_Amount__c','CPE_Amount__c','UC_Specialist__c'
                });
                cOppsToUpdate.add(cOpp);
                cOpp.Bypass_Validation__c = true;
                nonSplitParents.remove(cOpp.Opportunity_Parent__c);
            }
            if(cOppsToUpdate.size() > 0) update cOppsToUpdate;
        }
    }
    
    private static Opportunity createSplitOpportunity(Opportunity parent, integer position){
        
        Opportunity o = new Opportunity();
        
        o.RecordTypeId = getSplitRecordType().Id;
        o.AccountId = parent.AccountId;
        o.Opportunity_Parent__c = parent.Id;
        o.Type = parent.Type;
        Double sumOfSplitPercent = parent.Split_Percent_1__c + parent.Split_Percent_2__c;
        
        if (position == 0) {
           if(sumOfSplitPercent >100){
               o.Split_Percent_1__c = sumOfSplitPercent;
           }else{
               o.Split_Percent_1__c = 100; 
           }
        } else if (position == 1) {
            
            o.Split_Percent_1__c = parent.Split_Percent_1__c;
        } else if (position == 2) {
            o.Split_Percent_2__c = parent.Split_Percent_2__c;
        }
         
        updateFields(o, parent, null);
        
        return o;
    }
      
    private static Boolean updateFields(Opportunity splitOpty, Opportunity parentOpty, Opportunity oldOpp){
    
        integer position = splitPosition(splitOpty,parentOpty,oldOpp);
        if(position == -1) return false;
        
        instanceOpty = (Opportunity)splitOpty;
        Double sumOfSplitPercent = parentOpty.Split_Percent_1__c + parentOpty.Split_Percent_2__c;
        
        if(position == 0){
            instanceOpty.OwnerId = parentOpty.OwnerId;
            if(sumOfSplitPercent >100){
               instanceOpty.Split_Percent_1__c = sumOfSplitPercent;
            }else{
               instanceOpty.Split_Percent_1__c = 100;
            }
        }
            
        if(position == 1){
            instanceOpty.Split_Percent_1__c = parentOpty.Split_Percent_1__c;
            instanceOpty.OwnerId = parentOpty.Split_Owner_1__c;
        }
            
        if(position == 2){
            instanceOpty.Split_Percent_2__c = parentOpty.Split_Percent_2__c;
            instanceOpty.OwnerId = parentOpty.Split_Owner_2__c;
        }
    
        instanceOpty.name = names.get(position);
        instanceOpty.Split_Opp_Name__c = names.get(position);
        instanceOpty.Amount = amounts.get(position);
        instanceOpty.NRR_Amount__c = nrrAmounts.get(position);  
        instanceOpty.CPE_Amount__c = nroAmounts.get(position);  
        instanceOpty.CloseDate = parentOpty.CloseDate;
        instanceOpty.StageName = parentOpty.StageName;
        instanceOpty.Term__c = parentOpty.Term__c;
        instanceOpty.Lost_Reason__c = parentOpty.Lost_Reason__c;
        instanceOpty.Oppty_Sub_Type__c = parentOpty.Oppty_Sub_Type__c;
        instanceOpty.Term__c = parentOpty.Term__c;
        instanceOpty.UC_Specialist__c = parentOpty.UC_Specialist__c;
        instanceOpty.Opportunity_Product__c = parentOpty.Opportunity_Product__c;
        if (parentOpty.Oppty_Sub_Type__c == 'In-Flight Order Change') instanceOpty.Related_Opportunites__c = parentOpty.Related_Opportunites__c;
        
        
        return true;
    }
    
    private static void createValueMaps(Opportunity o){
        
        //get the split user 1 and split user 2 from this opportunity
        setSplitUserMap(o);
        
        // names with position index
        names.put(0, generateSplitName(o, splitUserMap, 1));
        names.put(1, generateSplitName(o, splitUserMap, 1));
        names.put(2, generateSplitName(o, splitUserMap, 1));
        
        // amounts by percentage & position 
        Double rootamount = 0;
        Double nrrRootamount = 0;
        Double nroRootamount = 0;
        Double sumOfSplitPercent = o.Split_Percent_1__c + o.Split_Percent_2__c;
        
        if(o.Amount != null)
            rootamount = o.Amount;
            
        if(o.NRR_Amount__c != null)
            nrrRootamount = o.NRR_Amount__c;

        if(o.CPE_Amount__c != null)
            nroRootamount = o.CPE_Amount__c;
                        
/*        if(sumOfSplitPercent >100){
           amounts.put(0, (rootamount * ((o.Split_Percent_1__c+o.Split_Percent_2__c) / 100) * -1));
        }else{
           amounts.put(0, (rootamount * -1));
        }*/
        amounts.put(0, (rootamount * -1));
        amounts.put(1, rootamount *(o.Split_Percent_1__c / 100));
        amounts.put(2, rootamount *(o.Split_Percent_2__c / 100));       

        /*if(sumOfSplitPercent >100){
           nrrAmounts.put(0, (nrrRootamount * ((o.Split_Percent_1__c+o.Split_Percent_2__c) / 100) * -1));
        }else{
           nrrAmounts.put(0, (nrrRootamount * -1));
        }*/
        nrrAmounts.put(0, (nrrRootamount * -1));
        nrrAmounts.put(1, nrrRootamount *(o.Split_Percent_1__c / 100));
        nrrAmounts.put(2, nrrRootamount *(o.Split_Percent_2__c / 100));     

      /*  if(sumOfSplitPercent >100){
            nroAmounts.put(0, (nroRootamount * ((o.Split_Percent_1__c+o.Split_Percent_2__c) / 100) * -1));
        }else{
            nroAmounts.put(0, (nroRootamount * -1));
        }*/
        nroAmounts.put(0, (nroRootamount * -1));
        nroAmounts.put(1, nroRootamount *(o.Split_Percent_1__c / 100));
        nroAmounts.put(2, nroRootamount *(o.Split_Percent_2__c / 100));     

        prototypelist = new List<Opportunity>();
        prototypelist.add(createSplitOpportunity(o, 1));
        prototypelist.add(createSplitOpportunity(o, 2));
        prototypelist.add(createSplitOpportunity(o, 0));
    }
    
    private static integer splitPosition(Opportunity o, Opportunity parent, Opportunity oldOpp){
        integer retval = -1;        
        Double sumOfSplitPercent = parent.Split_Percent_1__c + parent.Split_Percent_2__c;
        Double sumOfOldSplitPercent=0;
        if(oldOpp != null){
           sumOfOldSplitPercent = oldOpp.Split_Percent_1__c + oldOpp.Split_Percent_2__c;
        }

        if((o.Split_Percent_1__c > 100 ||o.Split_Percent_1__c == 100 ) 
        && (((sumOfOldSplitPercent == 0 && o.Split_Percent_1__c == sumOfSplitPercent )|| o.Split_Percent_1__c == sumOfOldSplitPercent))){
            retval = 0;
        }else if(o.Split_Percent_1__c != null)
            retval = 1;
        else if(o.Split_Percent_2__c != null)
            retval = 2;

        return retval;          
    }
    
    private static Boolean isEqual(Opportunity optyA, Opportunity optyB){
        
        Double aPercent1 = optyA.Split_Percent_1__c != null ? optyA.Split_Percent_1__c : 0;
        Double bPercent1 = optyB.Split_Percent_1__c != null ? optyB.Split_Percent_1__c : 0;
        Double aPercent2 = optyA.Split_Percent_2__c != null ? optyA.Split_Percent_2__c : 0;
        Double bPercent2 = optyB.Split_Percent_2__c != null ? optyB.Split_Percent_2__c : 0;
        
        return optyB.Split_Owner_1__c == optyA.Split_Owner_1__c
            && optyB.Split_Owner_2__c == optyA.Split_Owner_2__c
            && bPercent1 == aPercent1
            && bPercent2 == aPercent2
            && optyB.CloseDate == optyA.CloseDate
            && optyB.StageName == optyA.StageName
            && optyB.Term__c == optyA.Term__c
            && optyB.Lost_Reason__c == optyA.Lost_Reason__c
            && optyB.AccountId == optyA.AccountId;
    }  
    
    private static RecordType getSplitRecordType(){
            
            RecordType rtype = null;
            for(RecordType tRecord : recordTypeMap.values()){
                String s = tRecord.Name;
                if(s.contains('Split Opportunity')){
                    rtype = tRecord;
                    break;  
                }   
            }
    
            return rtype;
    }
    
    private static String generateSplitName(Opportunity parent, Map<id, User> users, integer position) {
                        
        string suffix, posOne, posTwo;
        decimal perOne, perTwo;
        
        posOne = (position == 1) ? users.get(parent.Split_Owner_1__c).LastName : users.get(parent.Split_Owner_2__c).LastName;
        posTwo = (position == 2) ? users.get(parent.Split_Owner_1__c).LastName : users.get(parent.Split_Owner_2__c).LastName;
        perOne = (position == 1) ? parent.Split_Percent_1__c : parent.Split_Percent_2__c;
        perTwo = (position == 2) ? parent.Split_Percent_1__c : parent.Split_Percent_2__c;
        
        if(posOne != null)
            suffix = ' - Split ' + posOne;
        
        if(posTwo != null)
            suffix += '/' + posTwo;
        
        if(perOne != null)
            suffix += ' - ' + perOne;
            
        if(perTwo != null)
            suffix += '/' + perTwo;
        
        String generatedSplitName = parent.Name + suffix;
        return (generatedSplitName.length() > 100) ? generatedSplitName.substring(0, 100) : generatedSplitName; //Trackit #307591
    }
    
    private static Boolean isSplitEligible(Opportunity o){
        //return o.Split_Percent_1__c != null && o.Split_Percent_2__c != null && o.Split_Owner_1__c != null && o.Split_Owner_2__c != null && o.Opportunity_Parent__c == null;
        return (o.Split_Percent_1__c != null || o.Split_Percent_2__c != null || o.Split_Owner_1__c != null || o.Split_Owner_2__c != null) && o.Opportunity_Parent__c == null;        
    }
    
    private static Map<Id, Map<Id, Opportunity>> childMaps = new Map<Id, Map<Id, Opportunity>>();
    private static void setChildMaps(Set<Id> parentIDs){
        
        if(parentIDs.size() > 0){
            for(Opportunity o : [SELECT Amount, Opportunity_Parent__c, CloseDate, StageName, Term__c, 
                                        Lost_Reason__c, RecordTypeId, Name, OwnerId, AccountId, 
                                        Split_Opp_Name__c, Split_Percent_1__c, Split_Percent_2__c,NRR_Amount__c,CPE_Amount__c,UC_Specialist__c
                                        FROM Opportunity WHERE Opportunity_Parent__c in: parentIDs]){
                                            
                if(childMaps.get(o.Opportunity_Parent__c) == null)
                    childMaps.put(o.Opportunity_Parent__c, new Map<Id, Opportunity>());
                
                childMaps.get(o.Opportunity_Parent__c).put(o.Id, o);
            }
        }
    }
    
    private static Map<Id, Opportunity> getChildMap(Id parentID){
        if(childMaps.get(parentID) == null)
            return new Map<Id, Opportunity>();
        else
            return childMaps.get(parentID);
    }
     
    private static void setSplitUserMap(Opportunity o){
        Set<Id> instanceIds = new Set<Id>();
        
        if(o.Split_Owner_1__c != null)
            instanceIds.add(o.Split_Owner_1__c);

        if(o.Split_Owner_2__c != null)          
            instanceIds.add(o.Split_Owner_2__c);
       
        splitUserMap = new Map<id, User>([SELECT Id, LastName FROM User WHERE Id IN :instanceIds limit 10]);
    }
     
     private static Map<string, Map<string, RecordType>> recordTypeMapByLikeName = new Map<string, Map<string, RecordType>>();
     private static Map<string, RecordType> setRecordTypeMapByLikeName(String name){
        string condition = '%' + name + '%';
        
        if(recordTypeMapByLikeName.get(condition) == null)
            recordTypeMapByLikeName.put(condition, new Map<string, RecordType>([Select Id, Name from RecordType where IsActive = true and Name LIKE:condition limit 10]));
            
        return recordTypeMapByLikeName.get(condition);
     }
     
     private static Boolean ValidateSplitOpportunity(Opportunity o) {
        if(o != null) {
            
            if(recordTypeMap.keySet().contains(o.RecordTypeId))
                return false;
            
            if ( o.Account.Parent != null) {
                handleError(o,'' , SP_ERROR_PARENT);
                return false;
            } 
                
            if (o.Split_Percent_1__c >0 && o.Split_Owner_1__c == null) {
                handleError(o, 'Split_Owner_1__c', SP_ERROR_NAME_PCT);
                return false;
            }
            
            if (o.Split_Percent_2__c >0 && o.Split_Owner_2__c == null) {
                handleError(o, 'Split_Owner_2__c', SP_ERROR_NAME_PCT);
                return false;
            }
            
            if (o.Split_Percent_1__c == 150 && (o.Split_Percent_2__c == 0 ||o.Split_Percent_2__c == null )) {
                handleError(o, 'Split_Owner_1__c', SP_ERROR_NAME_ONE_PERSON);
                return false;
            }
            
            if (o.Split_Percent_2__c == 150&& (o.Split_Percent_1__c == 0 ||o.Split_Percent_1__c == null )) {
                handleError(o, 'Split_Owner_2__c', SP_ERROR_NAME_ONE_PERSON);
                return false;
            }
            
            if(o.Split_Percent_1__c == null || o.Split_Percent_2__c == null){
                handleError(o, '', SP_ERROR_NAME_ONE_PERSON);
                return false;
            }
            
            if ((o.Split_Percent_1__c == null || o.Split_Percent_1__c <= 0 || o.Split_Percent_1__c >= 150) && (!String.IsEmpty(o.Split_Owner_1__c)) ) {
                handleError(o, 'Split_Owner_1__c', SP_ERROR_NAME_ZERO);
                return false;
            }
            
            if ((o.Split_Percent_2__c == null || o.Split_Percent_2__c <= 0 || o.Split_Percent_2__c >= 150)  && (!String.IsEmpty(o.Split_Owner_2__c)) ) {
                handleError(o, 'Split_Owner_2__c', SP_ERROR_NAME_ZERO);
                return false;
            }
            
            Double pctAdd = 0;
            if(o.Split_Percent_1__c != null){
                pctAdd += o.Split_Percent_1__c;
            }
            if(o.Split_Percent_2__c != null){
                pctAdd += o.Split_Percent_2__c;
            }
            
            if ( pctAdd != 0 && (pctAdd < 100 || pctAdd > 150)) {
                handleError(o, '', SP_ERROR_PCT + pctAdd);
                return false;
            }
            
            double newAmount = o.Amount;                    
            if(newAmount == null){
                newAmount = 0.00;
            }
        }
        return true;
     }
     
     private static void handleError(Opportunity opp, String fieldName, String errorMessage) {
         Validation_Rule_Settings__c vrs = Validation_Rule_Settings__c.getInstance(UserInfo.getUserId());
         boolean disableValidation = vrs.Disable_Validation_Rules__c;
         if (!disableValidation){
             opp.addError(errorMessage);
         }
     }
}