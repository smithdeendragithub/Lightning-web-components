@isTest
public with sharing class Test_ICBTriggers {

    static testMethod void testGetRelatedOpportunityIdSet() {
        
        List<ICB__c> l = getICBList();      
        system.debug(l);
        
        Set<Id>ids = ICBTriggers.test_getRelationOpportunityIdSet(l);       
        system.debug(ids);      
    }
    
     static testMethod void testSetRelationMaps() {

        Set<Id>idset = ICBTriggers.test_getRelationOpportunityIdSet(getICBList());       
        system.debug(idset);
         
        ICBTriggers.test_setRelationMaps(idset);
        
        system.debug('OpporotunityMap: ' + ICBTriggers.OpportunityMap);
        system.debug('MemberMap: ' + icbtriggers.MemberMap);
        
            
     }
     
     static testMethod void testUpdateFormFields(){
        List<ICB__c> l = getICBList();      
        system.debug(l);
        
        ICBTriggers.updateFormFields(l, true);
        
        system.debug(l);
     }
     
     static testMethod void testICBBeforeUpsertTrigger(){
        Mocks testData = new Mocks();
        List<ICB__c> l = getICBList();
        
        ICB__c icb1 = l.get(0);
        system.debug(icb1);
        
        ICB__c icb2 = icb1.clone(false,true);
        system.debug(icb2);
        icb2.OwnerId = getStandardUser().Id;
        icb2.Product__c = 'SIP';
        icb2.Opportunity__c = testData.opportunity.Id;
        system.debug(icb2);
        system.assertNotEquals(icb1.OwnerId, icb2.OwnerId);
        
        test.startTest();
        
        insert icb2;
        system.debug('RETVAL ' + icb2);
        
        test.stopTest();
     }
   

     //helper methods
     private static List<ICB__c> getICBList(){      
        return createICBPrototypeList(4);
     }
     
     private static List<ICB__c> createICBPrototypeList(Integer numIcbs){
            
            List<ICB__C> icbs = new List<ICB__C>();
            User u = getStandardUser();   
        
            for (Integer i = 0; i < numIcbs; i++) {
                
                ICB__c icb = new ICB__c();
                icb.ICB_Type__c = 'Pricing';
                icb.ICB_Pricing_Reason__c = 'Capital Build';
                icb.Description__c = 'Test Pricing ICB';                
                icb.Sales_Engineer__c = u.Id;
                
                icbs.add(icb);
            }
                return icbs;
    }
    
     
    private static OpportunityTeamMember createOppTeamMember(String role, Opportunity o){
        User u = getStandardUser(); 
                     
        return new OpportunityTeamMember(TeamMemberRole = role, Userid = u.id, OpportunityId = o.Id);
    }
    
    private static Integer GetRandomBySize(Integer size){
        return Math.mod(Math.abs(Crypto.getRandomInteger()), size);
    }
    
    private static ICB__c createRelatedICB(Id acctId, Id OppId){
        
        ICB__c icb = new ICB__c();
        
        icb.ICB_Type__c = 'Pricing';
        icb.Description__c = 'This is a test pricing request for unit testing ICB triggers';
        icb.Account__c = acctId;
        icb.Opportunity__c = OppId;
        
        return icb;
    }
	
    private static User getStandardUser(){
		return [SELECT Title, Id, Username, Name FROM User WHERE IsActive = true AND UserType LIKE:'%Standard%' LIMIT 1];
    }
}