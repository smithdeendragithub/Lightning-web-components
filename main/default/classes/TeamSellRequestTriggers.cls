public without sharing class TeamSellRequestTriggers {
	public static void TeamSellRequestModified(List<Team_Sell_Request__c> tNew, List<Team_Sell_Request__c> tOld, Boolean isBefore, Boolean isUpdate,  Boolean isDelete){
        if (!isBefore){
            if (!isDelete){
				if (isUpdate){
                    List<Id> accountIDs = new List<Id>();
                    List<String> partners = new List<String>();
                    
                    for (Team_Sell_Request__c tsr : tNew){
                        accountIDs.add(tsr.Account_Name__c);
                        partners.add(tsr.Partner_Name__c);
                    }
                    
                    List<AccountTeamMember> accTMs = new List<AccountTeamMember>();
                    Map<Id, Team_Sell_Request__c> tOldMap = tOld != null ? new Map<Id, Team_Sell_Request__c>(tOld) : new Map<Id, Team_Sell_Request__c>();
                    Map<Id, AccountReference__c> arMap = new Map<Id, AccountReference__c>([SELECT Id, Account__c FROM AccountReference__c WHERE Id in :accountIDs]);
                    Map<String, Id> userMap = new Map<String, Id>();
                    
                    for (User u : [SELECT Id, Name FROM User WHERE IsActive = true AND Name in :partners]){
                    	userMap.put(u.Name.toLowerCase(), u.Id);	    
                    }
                    
                    for (Team_Sell_Request__c tsr : tNew){
                        Team_Sell_Request__c oldTSR = tOldMap.get(tsr.Id);
                        if ((oldTSR.Status__c != 'Approved' && tsr.Status__c == 'Approved') && userMap.containsKey(tsr.Partner_Name__c.toLowerCase())){
                        	AccountTeamMember accTM = new AccountTeamMember();
                            AccountReference__c ar = arMap.get(tsr.Account_Name__c);
                            accTM.AccountId = ar.Account__c;
                            //accTM.AccountId = [SELECT Account__c FROM AccountReference__c WHERE Id =: tsr.Account_Name__c].Account__c;
                            accTM.TeamMemberRole = 'Team Member';
                            accTM.AccountAccessLevel = 'Edit';
                            accTM.UserId = userMap.get(tsr.Partner_Name__c.toLowerCase());
                            //accTM.UserId = tsr.Partner__c;
                            accTMs.add(accTM);
                        }
                    }
                    insert accTMs;
            	}                
            }            
        }
    }
}