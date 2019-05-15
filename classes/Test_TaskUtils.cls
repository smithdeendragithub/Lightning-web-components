@isTest
public class Test_TaskUtils { 
	static testMethod void testTaskUtils(){
		Mocks testData = new Mocks();
		test.startTest();

		TaskUtils.CreateTask(UserInfo.getUserId(), 'subject', testData.parentAccount.Id, 'Type', Date.today(), Date.today(), 'Description', false, 'Status', UserInfo.getUserId());
		test.stopTest();
	}
}