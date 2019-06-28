@isTest
private class Test_copyParentTestCase {

    @isTest static void assignTest() {
    
     id testCaseAssignmentRecordType = Schema.SObjectType.Test_Case__c.getRecordTypeInfosByName().get('Test Case Assignment').getRecordTypeId();
     id testAssignExistingTestCaseRecordType = Schema.SObjectType.Test_Case__c.getRecordTypeInfosByName().get('Assign Existing Test Case').getRecordTypeId();
     id testCaseTemplate = Schema.SObjectType.Test_Case__c.getRecordTypeInfosByName().get('Test Case Template').getRecordTypeId();
     id assignedUser = UserInfo.getUserId();
    
        Test_Case__c template = new Test_Case__c();         
            template.RecordTypeId                = testCaseTemplate;
            template.Test_Summary__c             = 'testing';
            template.Functional_Testing_Areas__c = 'Case Management;Lead Management;Opportunity Management';
            template.Test_Instructions__c        = 'testing test instructions';
            template.Expected_Result__c          = 'testing expected result';
        insert template; 
        
        Test_Case__c assignment = new Test_Case__c();               
            assignment.RecordTypeId   = testAssignExistingTestCaseRecordType;
            assignment.Test_Case__c   = template.Id; 
            assignment.Assigned_To__c = assignedUser;
        insert assignment;    

        assignment = [
            SELECT RecordTypeId,Test_Summary__c,Test_Instructions__c,Expected_Result__c,Functional_Testing_Areas__c,Assigned_To__c,OwnerId 
            FROM Test_Case__c
            WHERE Id=:assignment.id
            ];
        
        System.assertEquals(testCaseAssignmentRecordType, assignment.RecordTypeId);      
        System.assertEquals(template.Test_Summary__c, assignment.Test_Summary__c);
        System.assertEquals(template.Test_Instructions__c, assignment.Test_Instructions__c);
        System.assertEquals(template.Expected_Result__c, assignment.Expected_Result__c);
        System.assertEquals(template.Functional_Testing_Areas__c, assignment.Functional_Testing_Areas__c); 
        System.assertEquals(assignment.Assigned_To__c, assignment.OwnerId);
    }
}