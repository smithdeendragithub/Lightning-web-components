public with sharing class BuildingTriggers{

  //public static Set<String> camTeamMemberRoles { get { return ICCWrapper.CamTeamMemberRoles; } }
    public static String verbiage = 'This address is being added to the Electric Lightwave network. This is a great opportunity to contact prospects and current customers to engage them in discussions.';
  
  public static void BuildingModified(List<Building__c> tNew, List<Building__c> tOld, Boolean isUpdate, Boolean isBefore){
    
    Map<Id, Building__c> tNewMap = new Map<Id, Building__c>(tNew);
    Map<Id, Building__c> tOldMap = tOld != null ? new Map<Id, Building__c>(tOld) : new Map<Id, Building__c>();
   
    Map<Id, Building__c> firstTaskBuilds = new Map<Id, Building__c>();
    Map<Id, Building__c> secondTaskBuilds = new Map<Id, Building__c>();
    
    //First Notification, if Building goes On-Net && Pending Build
    for(Building__c b : tNewMap.values()){
      if(tOldMap.containsKey(b.Id)){
        Building__c bOld = tOldMap.get(b.Id);
        
        if(b.Net_Classification__c == 'On-net' && b.Status__c == 'Pending Build' && bOld.Status__c != 'Pending Build')
          firstTaskBuilds.put(b.Id,b);
      }
    }
        
    //Second Notification, if Building is On-net and goes to Active
    for(Building__c b : tNewMap.values()){
      if(tOldMap.containsKey(b.Id)){
        Building__c bOld = tOldMap.get(b.Id);

        if(b.Net_Classification__c == 'On-net' && b.Status__c == 'Active' && bOld.Status__c != 'Active')
          secondTaskBuilds.put(b.Id,b);
      }
    }
    
    List<Task> TasksToInsert = new List<Task>();

	if(firstTaskBuilds.size() > 0)
    //Pending
        TasksToInsert.addAll(CreateTasks(firstTaskBuilds,'Building: Pending Build - Please Review','Building: Pending Build','Not Started', Date.today().addDays(3),verbiage,date.today(),true));
	if(secondTaskBuilds.size() > 0)
    //Active
        TasksToInsert.addAll(CreateTasks(secondTaskBuilds,'Building: Active Build - Please Review','Building: Active Build','Not Started', Date.today().addDays(3),verbiage,date.today(),true));

    system.debug(TasksToInsert);

    if(TasksToInsert.size() > 0){
      insert TasksToInsert;
      
      //Set the send notification field on tasks
      Database.DMLOptions dmlo = new Database.DMLOptions();
      dmlo.EmailHeader.triggerUserEmail = true;       

      database.update(TasksToInsert, dmlo);
    }
  }

  private static List<Task> CreateTasks(Map<Id,Building__c> builds, string subject, string activityType, string status,Date activityDate,string description, Date reminderDate, boolean setReminder){
    List<Task> tasks = new List<Task>();
    Map<Id,Set<Account>> mapBuildingAccounts = new Map<Id,Set<Account>>();
    id ProspectRTID = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
    id SubscriberRTID = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Subscriber').getRecordTypeId();
    List<string> oppStages = new List<string>{OpportunityUtils.STAGE_CLOSED_LOST,OpportunityUtils.STAGE_CONTRACT_SIGNED,OpportunityUtils.STAGE_CLOSED_WON,OpportunityUtils.STAGE_4,OpportunityUtils.STAGE_5};
    Set<Id> acctIds = new set<id>();
    //for(Service_Location__c sl :[Select Account__r.Id, Account__r.Name, Account__r.Type, Account__r.Owner.Name,Account__r.OwnerId,Id, Name, Location__r.Id, Location__r.Name, Account__r.Account_Sales_Channel__c,Location__r.Building__c, Account__r.RecordType.Name From Service_Location__c Where Location__r.Building__c in :builds.keyset()]){
    for(Service_Location__c sl :[Select Account__r.Id, Account__r.Name, Account__r.Type, Account__r.Owner.Name,Account__r.OwnerId,Id, Name, Location__r.Id, Location__r.Name,Location__r.Building__c, Account__r.RecordType.Name From Service_Location__c Where Location__r.Building__c in :builds.keyset()]){    	
      if(mapBuildingAccounts.containsKey(sl.Location__r.Building__c)){
        Set<Account> accts = mapBuildingAccounts.get(sl.Location__r.Building__c);
        accts.add(sl.Account__r);
        acctIds.add(sl.Account__c);
      }
      else{
        mapBuildingAccounts.put(sl.Location__r.Building__c,new Set<Account>{sl.Account__r});
        acctIds.add(sl.Account__c);
      }
    }

    Map<Id,Set<Opportunity>> acctsWithOpenOpps = new Map<Id,Set<Opportunity>>();
    Map<Id,Set<Lead>> acctsWithTargetLeads = new Map<Id,Set<Lead>>();
        
    for(Account a : [Select Id, (Select Id, OwnerId From Leads__r Where Status = 'Target') From Account Where id in :acctIds]){
      for(Lead l : a.Leads__r){
        if(acctsWithTargetLeads.containskey(a.id)){
          acctsWithTargetLeads.get(a.id).add(l);
        }
        else{
          acctsWithTargetLeads.put(a.id,new Set<Lead>{l});
        }
      }
    }

        for(Opportunity_location__c oloc : [Select Id,Opportunity__c,Opportunity__r.OwnerId, Opportunity__r.AccountId From Opportunity_Location__c Where On_Hold__c = false and Opportunity__r.StageName not in :oppStages and Opportunity__r.Opportunity_Parent__c = null and Opportunity__r.AccountId in :acctIds and Service_Location__r.Location__r.Building__c in :builds.keyset()]){
            if(acctsWithOpenOpps.containskey(oloc.Opportunity__r.AccountId)){
                acctsWithOpenOpps.get(oloc.Opportunity__r.AccountId).add(oloc.Opportunity__r);
            }
            else{
                acctsWithOpenOpps.put(oloc.Opportunity__r.AccountId,new Set<Opportunity>{oloc.Opportunity__r});
            }
        }
        for(Opportunity_Product__c oprod : [Select Id,Account__c,Opportunity__r.OwnerId,Opportunity__c From Opportunity_Product__c Where Active__c = true and Opportunity__r.StageName not in :oppStages and Opportunity__r.Opportunity_Parent__c = null and Account__c in :acctIds and  Primary_Service_Location__r.Location__r.Building__c in :builds.keyset()]){
            if(acctsWithOpenOpps.containskey(oprod.Account__c)){
                acctsWithOpenOpps.get(oprod.Account__c).add(oprod.Opportunity__r);
            }
            else{
                acctsWithOpenOpps.put(oprod.Account__c,new Set<Opportunity>{oprod.Opportunity__r});
            }
        }

    for(Id bid : mapBuildingAccounts.keySet()){
      for(Account a : mapBuildingAccounts.get(bid)){
        /*
        Subscriber Account Type
          Priority 1- Open Opportunity with service location related to Building: Opportunity Level Task
          Priority 2- NO open Opportunity with Service location related to Building: Account Level Task
        */
        if(a.RecordTypeID == SubscriberRTID){
          if(acctsWithOpenOpps.containskey(a.id)){
            for(Opportunity o : acctsWithOpenOpps.get(a.id)){
              //opp level task
                            tasks.add(TaskUtils.CreateTask(o.OwnerId, Subject + ' - ' + builds.get(bid).Name, o.id, activityType, ActivityDate, ReminderDate, Description, SetReminder, status, null));
            }
          }
          else{
            //Account level task
                        tasks.add(TaskUtils.CreateTask(a.OwnerId, Subject + ' - ' + builds.get(bid).Name, a.id, activityType, ActivityDate, ReminderDate, Description, SetReminder, status, null));
          }
        }
        /*
        Prospect Account Type
          Priority 1- With open Opportunity:  Opportunity Level Task
          Priority 2- With  open Lead (target lead profile where prospect account is related to lead):  Lead Level Task
          Priority 3- With NO open Opportunity:  Account Level Task
          Priority 4- With NO open Lead (target Lead profile where prospect Account is related to Lead):  Account Level Task
        */
        else if(a.RecordTypeID == ProspectRTID){
          if(acctsWithOpenOpps.containskey(a.id)){
            for(Opportunity o : acctsWithOpenOpps.get(a.id)){
              //opp level task
                            tasks.add(TaskUtils.CreateTask(o.OwnerId, Subject + ' - ' + builds.get(bid).Name, o.id, activityType, ActivityDate, ReminderDate, Description, SetReminder, status, null));
            }
          }
          else if(acctsWithTargetLeads.containskey(a.id)){
            for(Lead l : acctsWithTargetLeads.get(a.id)){
              //lead level task
                            tasks.add(TaskUtils.CreateTask(l.OwnerId, Subject + ' - ' + builds.get(bid).Name, null, activityType, ActivityDate, ReminderDate, Description, SetReminder, status, l.id));
            }
          }
          else{
            //acct level task
                        tasks.add(TaskUtils.CreateTask(a.OwnerId, Subject + ' - ' + builds.get(bid).Name, a.id, activityType, ActivityDate, ReminderDate, Description, SetReminder, status, null));
          }
        }
      }
    } 
    return tasks;
  }

    public static void BuildingInserted(List<Building__c> tNew) {
    
        List<Building__c> insertBuildings = new List<Building__c>();
        for (Building__c newBuilding : tNew) {
            if (newBuilding.Country__c.touppercase() == 'CA'||newBuilding.Country__c.touppercase() == 'CAN'||newBuilding.Country__c.touppercase() == 'CANADA') {
                Building__c updateBuilding = new Building__c();
                updateBuilding.id = newBuilding.id;
                Market_Area__c marketArea = [SELECT id FROM Market_Area__c WHERE Name = 'National'][0];
                updateBuilding.Market_Area__c = marketArea.id;
                insertBuildings.add(updateBuilding);
            }   
        }
        update insertBuildings;
    }
  
}