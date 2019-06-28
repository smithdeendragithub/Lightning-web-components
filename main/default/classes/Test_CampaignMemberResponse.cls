@isTest
public with sharing class Test_CampaignMemberResponse extends TestUtils.TestClass {

	static testMethod void testCampaignMembers(){

		CampaignMember cm = createCampaignMember();

		cm.Status = 'Responded - Web';
		update cm;
	}		

	static testMethod void testCampaignMemberPage(){

		CampaignMember cm = createCampaignMember();

        PageReference pageRef = Page.CampaignMemberResponse;
        
        pageRef.getParameters().put('id', cm.Id);
        
        Test.setCurrentPage(pageRef);
        CampaignMemberResponseController ctr = new CampaignMemberResponseController();
        ctr.onLoad();
        ctr.UpdateMemberStatus();
	}

	static testMethod void testCampaignMemberScriptPage(){

		CampaignMember cm = createCampaignMember();

        PageReference pageRef = Page.CampaignMemberResponseScript;
        
        pageRef.getParameters().put('id', cm.Id);
        
        Test.setCurrentPage(pageRef);
        CampaignMemberResponseScriptController ctr = new CampaignMemberResponseScriptController();
        ctr.onLoad();
        
        ctr.answer4 = true;
        ctr.answer5 = true;
        ctr.answer6 = true;
        ctr.answer7 = true;
        ctr.answer8 = 'test';
        ctr.UpdateMemberStatus();
	}

	static testMethod void testCampaignMemberPageBadURL(){

        PageReference pageRef = Page.CampaignMemberResponse;
        
        pageRef.getParameters().put('id', 'bad id');
        
        Test.setCurrentPage(pageRef);
        CampaignMemberResponseController ctr = new CampaignMemberResponseController();
        ctr.onLoad();
	}
	
	private static CampaignMember createCampaignMember() {
		Mocks testData = new Mocks();
		
		Campaign c = createCampaign();
		
		insert c;
				
		CampaignMember cm = new CampaignMember();
		cm.ContactId = testData.parentAccountContact.Id;
		cm.CampaignId = c.Id;
		insert cm;
        
		return cm;
	}
	
	private static Campaign createCampaign(){
		
		User marketingUser = [SELECT Title, Id, Username, Name FROM User WHERE IsActive = true AND UserType LIKE:'%Standard%' LIMIT 1];
		
		return new Campaign(Description = 'Test Campaign for CampaignMemberResponseControllerTest', Name='Test Campaign', Status = 'In Progress', Type = 'Other', OwnerId = marketingUser.Id);									
		
	}
}