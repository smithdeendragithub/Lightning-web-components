public without sharing class ICBTriggers {  
    
    //pub prop
    public static Map<Id, Opportunity> OpportunityMap {get; set;}
    public static Map<Id, OpportunityTeamMember> MemberMap {get; set;}
    
    //pri prop
    private static Set<Id> idset {get; set;}
    private static Set<string> stringset{get;set;}
    private static final String TEST_VIOLATION_MSG = 'This method can only be called from a test.';
    
    public static void updateFormFields(List<ICB__c> newICBs, Boolean isUpdate){
        
        
        Init(newICBs);

        setProductManager(newICBs); 
        setAccountExecutive(newICBs);
        
        if(!isUpdate){
            setTermValue(newICBs);
        }   
    }
    
    public static void Init(List<ICB__c> icbs){
        
        setRelationMaps(getRelationOpportunityIdSet(icbs));
        
    }
    
    public static void setTermValue(List<ICB__c> icbs){     
        for(ICB__c icb : icbs){
                        
            if(icb.Opportunity__c == null) continue;            
            icb.Term__c = OpportunityMap.get(icb.Opportunity__c).Term__c;
            
        }
    }
    
    public static void setAccountExecutive(List<ICB__c> icbs){
        
        for(ICB__c icb : icbs){
            
            if(icb.Opportunity__c == null) continue;
            icb.AccountExecutive__c = OpportunityMap.get(icb.Opportunity__c).OwnerId;
            
        }
    }
    
        public static void setProductManager(List<ICB__c> icbs){
        
        stringset = new Set<string>();
                
        for(ICB__c icb : icbs){
            if(!String.IsEmpty(icb.Product__c)){
                string v = icb.Product__c;
                stringset.add(v.normalizeSpace());              
            }
        }
        
        Map<string, ICBProduct__c> products = new Map<string, ICBProduct__c>(); 
            
        List<ICBProduct__c> items = [SELECT Id, Name, ProductManager__c FROM ICBProduct__c WHERE IsDeleted != true AND Name IN: stringset];
        
        for(ICBProduct__c item : items){
            products.put(item.Name, item);
        }
        
        for(ICB__c icb : icbs){
            if(products.containsKey(icb.Product__c)){
                icb.Product_Manager__c = products.get(icb.Product__c).ProductManager__c;                
            }
        }       
    }
    
    //private methods
    private static void setRelationMaps(Set<Id> ids){
        
        OpportunityMap = new Map<Id, Opportunity>();
        MemberMap = new Map<Id, OpportunityTeamMember>();
        
        for(Opportunity o : [SELECT Id, Name, OwnerId, Term__c, (SELECT Id, UserId, OpportunityId from OpportunityTeamMembers WHERE TeamMemberRole = 'Sales Engineer') FROM Opportunity WHERE Id IN:ids]){
            OpportunityMap.put(o.Id, o);
            
            for(OpportunityTeamMember m : o.OpportunityTeamMembers){
                MemberMap.put(m.OpportunityId, m);
            }
        }
    }
    

    private static Set<Id> getRelationOpportunityIdSet(List<ICB__c> icbs){
        
        idset = new Set<id>();
        
        //load opportunity id set reference
        for(ICB__c icb : icbs){
            idset.add(icb.Opportunity__c);
        }
        system.debug(idset);
        
        return idset;
    }
    
    //private method test wrappers  
    public static Set<Id> test_getRelationOpportunityIdSet(List<ICB__c> icbs){
        return test.isRunningTest() ? getRelationOpportunityIdSet(icbs) : null;
    }
    
    public static void test_setRelationMaps(Set<Id> ids){
        if(test.isRunningTest())
        	setRelationMaps(ids);
        
    }
}