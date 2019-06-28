global without sharing class Schedule_PDD_TrueUp implements Schedulable{
	public void execute(SchedulableContext sc) {
		getActiveSubOrders(null);	
	}
	webservice static void getActiveSubOrders(Id sub){
		//Id testId = 'a2F1A0000016DPNUA2';
		Set<Id> possiblylateSOs = new Set<Id>();
		Set<Id> blockedSOs = new Set<Id>();
		Set<Id> lateSOs = new Set<Id>();
		List<Sub_Order__c> lSOs = new List<Sub_Order__c>();
		List<Sub_Order__c> lateBAndLSOs = new List<Sub_Order__c>();
		Map<Id, Sub_Order__c> mapSOs = new Map<Id, Sub_Order__c>();
		Map<Id, Workstep__c> mapAWSWSs = new Map<Id, Workstep__c>();
		Map<Id, Workstep__c> mapWSs = new Map<Id, Workstep__c>();
		//Page button
		if(sub != null){		
			for(Sub_Order__c so : [Select Id, Status__c, On_Off_Track__c, Has_Blocked_Workstep__c, Projected_Due_Date__c
								    From Sub_Order__c 
									Where Id =: sub]){
					
				if(so.Has_Blocked_Workstep__c)
					blockedSOs.add(so.Id);
				else if(!so.Has_Blocked_Workstep__c)
					possiblylateSOs.add(so.Id);
					
				mapSOs.put(so.Id, so);						
			}	
		}
		//Nightly job
		else{				
			for(Sub_Order__c so : [Select Id, Status__c, On_Off_Track__c, Has_Blocked_Workstep__c, Projected_Due_Date__c
								    From Sub_Order__c 
									Where Status__c IN ('Blocked', 'IN PROGRESS')]){
					
				if(so.Has_Blocked_Workstep__c)
					blockedSOs.add(so.Id);
				else if(!so.Has_Blocked_Workstep__c)
					possiblylateSOs.add(so.Id);
					
				mapSOs.put(so.Id, so);						
			}
		}
		
		if(mapSOs.size() > 0){
			for(Workstep__c ws : [Select Sub_Order__c, End_Date__c From Workstep__c Where Name =: WorkstepUtils.SEND_TO_BILLING AND Sub_Order__c IN: mapSOs.keyset()]){
				mapAWSWSs.put(ws.Sub_Order__c, ws);
			}				
			for(Workstep__c ws : [Select Id, Sub_Order__c From Workstep__c 
										Where Status__c =: 'Open' AND Duration__c != 0 AND On_time_Late_Workstep__c < 0 AND Sub_Order__c IN: possiblylateSOs LIMIT 1200]){				
				lateSOs.add(ws.Sub_Order__c);								
			}		
				
			//Late worksteps
			if(lateSOs.size() > 0){			
				for(AggregateResult ag : [Select Sub_Order__r.Id sub, MIN(On_time_Late_Workstep__c) Dayz From Workstep__c 
										Where Status__c =: 'Open' AND Duration__c != 0 AND On_time_Late_Workstep__c < 0 AND Sub_Order__c IN: lateSOs
										Group By Sub_Order__r.Id, Status__c]){
		
					if(mapAWSWSs.get(String.valueOf(ag.get('sub'))) != null){								
							Date edate = mapAWSWSs.get(String.valueOf(ag.get('sub'))).End_Date__c;							
							Integer convert = Integer.valueOf(ag.get('Dayz')) * -1;					
							Date trueUp =  edate.addDays(convert);						
							Date validTrueUp = validateDate(trueUp);							
							Sub_Order__c tSO = mapSOs.get(String.valueOf(ag.get('sub')));							
							DateTime zinc = validTrueUp;																			
							tSO.Projected_Due_Date__c = zinc.addHours(20);												
							lSOs.add(tSO);	
					}
				}
			}
			//blocked
			if(blockedSOs.size() > 0){
				for(AggregateResult ag : [Select Sub_Order__c sub, MAX(Duration__c) Dayz From Workstep__c 
										Where Status__c =: 'Blocked' AND Duration__c != 0  AND Sub_Order__c IN: blockedSOs
										Group By Sub_Order__c
										Having MIN(On_time_Late_Workstep__c) >= 0]){
		
					if(mapAWSWSs.get(String.valueOf(ag.get('sub'))) != null){									
						Date edate = mapAWSWSs.get(String.valueOf(ag.get('sub'))).End_Date__c;																		
						Integer convert = Integer.valueOf(ag.get('Dayz')) != null ? Integer.valueOf(ag.get('Dayz')) : 0;																			
						Date trueUp =  edate.addDays(convert);																
						Date validTrueUp = validateDate(trueUp);																		
						Sub_Order__c tSO = mapSOs.get(String.valueOf(ag.get('sub')));
						DateTime zinc = validTrueUp;																			
						tSO.Projected_Due_Date__c = zinc.addHours(20);	//have to do this convert to dateTIME and add time as timezone is messed up otherwise.																					
						lSOs.add(tSO);
					}	
				}
				//both late and blocked
				for(AggregateResult ag : [Select Sub_Order__c sub, MAX(Duration__c) DurDayz, MIN(On_time_Late_Workstep__c) Dayz From Workstep__c 
										Where Status__c =: 'Blocked' AND Duration__c != 0 AND Sub_Order__c IN: blockedSOs
										Group By Sub_Order__c
										Having MIN(On_time_Late_Workstep__c) < 0 ]){
			
					if(mapAWSWSs.get(String.valueOf(ag.get('sub'))) != null){								
						Integer comboDayz = Integer.valueOf(ag.get('Dayz')) != null && Integer.valueOf(ag.get('DurDayz')) != null ? Integer.valueOf(ag.get('DurDayz')) + (Integer.valueOf(ag.get('Dayz')) * -1) : 0;												
						Date edate = mapAWSWSs.get(String.valueOf(ag.get('sub'))).End_Date__c;													
						Date trueUp = edate.addDays(comboDayz);										
						Date validTrueUp = validateDate(trueUp);												
						Sub_Order__c tSO = mapSOs.get(String.valueOf(ag.get('sub')));										
						DateTime zinc = validTrueUp;																									
						tSO.Projected_Due_Date__c = zinc.addHours(20);							
						lateBAndLSOs.add(tSO);
					}						
				}
			}
			
			if(lSOs.size() > 0){			
				update lSOs;
			}
			if(lateBAndLSOs.size() > 0){
				update lateBAndLSOs;
			}
		} 
	}
	
	private static Date validateDate(Date d){
		if (d == d.toStartOfWeek()){			
			Date nd = d.addDays(1);			
			return nd;
		}
		else if (d ==(d.toStartOfWeek() + 6)){
			Date nd = d.addDays(2);		
			return nd;
		}		
		return d;
	}	
}