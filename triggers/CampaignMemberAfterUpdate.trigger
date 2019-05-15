trigger CampaignMemberAfterUpdate on CampaignMember (after Update) {

	CampaignMemberTriggers.CreateTaskOnContact(Trigger.oldMap, Trigger.newMap); 
}