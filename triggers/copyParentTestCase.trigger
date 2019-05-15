trigger copyParentTestCase on Test_Case__c (after insert) {
       
       id testCaseAssignmentRecordType = Schema.SObjectType.Test_Case__c.getRecordTypeInfosByName().get('Test Case Assignment').getRecordTypeId();
       id testCaseAssignExistingTestCaseRecordType = Schema.SObjectType.Test_Case__c.getRecordTypeInfosByName().get('Assign Existing Test Case').getRecordTypeId();

        List<Test_Case__c> testCases = [
            SELECT Id, Test_Case__r.Test_Summary__c, Test_Case__r.Test_Instructions__c, Test_Case__r.Expected_Result__c, Test_Case__r.Functional_Testing_Areas__c, Test_Case__r.Audience__c 
            FROM Test_Case__c 
            WHERE Id IN: Trigger.newMap.keySet() 
                AND RecordTypeId = :testCaseAssignExistingTestCaseRecordType
                AND Test_Case__c <> null
            ];
        
        for (Test_Case__c t : testCases ){
                t.RecordTypeId                = testCaseAssignmentRecordType;
                t.Test_Summary__c             = t.Test_Case__r.Test_Summary__c;
                t.Test_Instructions__c        = t.Test_Case__r.Test_Instructions__c;
                t.Expected_Result__c          = t.Test_Case__r.Expected_Result__c;
                t.Functional_Testing_Areas__c = t.Test_Case__r.Functional_Testing_Areas__c;
                t.Audience__c                 = t.Test_Case__r.Audience__c;
                update t;
        }   
}