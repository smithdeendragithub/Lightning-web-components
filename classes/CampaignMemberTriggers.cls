public class CampaignMemberTriggers {
  
  public static void CreateTaskOnContact(Map<Id, CampaignMember> tOld, Map<Id, CampaignMember> tNew) {
    
    List<Task> tasks = new List<Task>{};
    
    List<Id> contactIds = new List<Id>();
    
    for (CampaignMember cm : tNew.Values()) {
      if( cm.HasResponded ) {
        CampaignMember oldCm = tOld.get(cm.Id);
        if( !oldCm.HasResponded ) {
              Task t = new Task(WhoId=cm.ContactId, Status = 'Not Started', Subject='Call');
              tasks.add(t);
              contactIds.add(cm.ContactId);
        }
      }
    }

    Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, OwnerId from Contact Where Id in :contactIds]);    
    
    if(tasks !=null && !tasks.isEmpty()) {
//      BusinessHours bh = [select id from businesshours where IsDefault=true];
      // 3 days in advance
//      Datetime ad = BusinessHours.add(bh.id, Datetime.now(), Math.roundToLong(3 * 24 * 60 * 60 * 1000));
      List<User> u = [Select Id From User Where FirstName='Jessica' and LastName='Roufs'];
      
      for( Task t : tasks ) {
        Contact c = contacts.get(t.WhoId);
        t.ActivityDate = Date.Today().addDays(3);
        t.Subject = 'Base Ethernet Upgrade Campaign - Consultation Call';
        //t.OwnerId = c.OwnerId;
        if(u.size()>0){
          t.OwnerId = u[0].Id;
        }         
      }
        Database.insert(tasks);
    }
    
    return;
  }
  
}