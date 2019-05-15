@isTest
public with sharing class Test_Hours extends TestUtils.TestClass{
	
	static testMethod void testController(){
        Mocks testData = new Mocks();
		
		User u = testData.user;
		
		Project__c p = new Project__c(Name='World Peace');
		insert p;
		
		Project_Resource__c pr = new Project_Resource__c(Project__c=p.Id, Resource_User__c=u.Id, Resource_Role__c='A Somebody');
		insert pr;
		
		Project_Resource_Hours__c prh = new Project_Resource_Hours__c(Resource__c=pr.Id, Actual_Hours__c=0, Resource_Week__c=Date.today());
		insert prh;
		
    	test.startTest();
    	
		PageReference pageReference = Page.Hours;
		pageReference.getParameters().put('ntids', testData.user.NTID__c);
		test.setCurrentPage(pageReference);
		
		HoursController hc = new HoursController();
		hc.selectedProjectOption = 'All projects';
		hc.getUserResources();
		
		hc.saveChanges();
		
		System.debug(hc.projectViewOptions);
		System.debug(hc.projectSelectionOptions);
		System.debug(hc.getTestClass());
		
		test.stopTest();
	}
	
	static testMethod void testSchedule_ProjectHoursOverdue(){
        Mocks testData = new Mocks();
		
		User u = testData.user;
		u.Project_Hours_Manager__c = true;
		update u;
		
		test.startTest();
		
		Schedule_ProjectHoursOverdue.alertUsersWithoutWeeklyHoursSet();
	}
}