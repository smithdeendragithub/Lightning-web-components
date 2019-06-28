trigger assignTestCaseOwner on Test_Case__c (after insert, after update) {

    List<Test_Case__c> testCases = [
        SELECT OwnerId, Assigned_To__c
        FROM Test_Case__c 
        WHERE Id IN: Trigger.newMap.keySet() 
            AND Assigned_To__c != null
    ];
        
    for (Test_Case__c t : testCases ){
        IF( t.Assigned_To__c != t.OwnerId ) {
            t.OwnerId = t.Assigned_To__c;
            update t;
        } else {}
    }               
}