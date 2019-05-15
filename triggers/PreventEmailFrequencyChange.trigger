trigger PreventEmailFrequencyChange on CollaborationGroupMember (before update, before insert) {
    // Prevent users in Allstream - Critical Group from changing their email frequencies 
    if (Trigger.isUpdate){
        List<CollaborationGroup> criticalGroup = [SELECT Id, Name from CollaborationGroup WHERE Name = 'Allstream - Critical' limit 1];
        if (!criticalGroup.isEmpty()){
            for (CollaborationGroupMember c : Trigger.New) {
                System.debug('CollaborationGroupId: ' + c.CollaborationGroupId + ', criticalGroup[0].Id: ' + criticalGroup[0].Id);
            	if (c.CollaborationGroupId == criticalGroup[0].Id && c.NotificationFrequency != Trigger.OldMap.get(c.Id).NotificationFrequency) {
                	c.adderror('You cannot change your email frequency for this group.');
            	}
        	}
        }      
    } // This should set default email frequency for a group when the user joins that group 
    else if (Trigger.isInsert) {
        for (CollaborationGroupMember c : Trigger.New) { 
            List<CollaborationGroup> a = [SELECT Id,Name FROM CollaborationGroup WHERE Id=:c.CollaborationGroupId];
            for (Chatter_Auto_Follow__c o : Chatter_Auto_Follow__c.getall().values()) {
                if (a[0].Name == o.Group__c){
                    if (o.Email_Frequency__c == 'D') {
                        c.NotificationFrequency = 'D';
                    }  else if (o.Email_Frequency__c == 'P') {
                        c.NotificationFrequency = 'P';
                    } else if (o.Email_Frequency__c == 'W') {
                        c.NotificationFrequency = 'W';
                    } else if (o.Email_Frequency__c == 'N') {
                        c.NotificationFrequency = 'N';
                    }
                }   
            }
        }
    }
}