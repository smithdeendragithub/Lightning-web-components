global without sharing class Schedule_PNR_TrueUp implements Schedulable{
	public void execute(SchedulableContext sc) {
		getActiveBuildOrders(null);	
	}
	webservice static void getActiveBuildOrders(Id ord){
		//Id testId = 'a2F1A0000016DPNUA2';
		Set<Id> lateOs = new Set<Id>();
		Set<Id> lateOnly = new Set<Id>();
		Set<Id> blockedOs = new Set<Id>();
		Set<Id> blockedOnly = new Set<Id>();
		Set<Id> blkAndLateOs = new Set<Id>();
		List<Order__c> lOs = new List<Order__c>();
		Map<Id, Order__c> mapOs = new Map<Id, Order__c>();
		Map<Id, Workstep__c> mapAWSWSs = new Map<Id, Workstep__c>();
		Map<Id, Id> mapBlkd = new Map<Id, Id>();
		Map<Id, Id> mapBAndL = new Map<Id, Id>();
		Id rtBuildOrderId = Schema.Sobjecttype.Order__c.getRecordTypeInfosByName().get('Build Order').getRecordTypeId();
		//Page button
		if(ord != null){		
			for(Order__c o : [Select Id
								    From Order__c 
									Where Id =:ord AND RecordTypeId =: rtBuildOrderId AND Order_Completion_Status__c =: 'In Progress']){

				mapOs.put(o.Id, o);						
			}	
		}
		//Nightly job
		else{				
			for(Order__c o : [Select Id
								    From Order__c 
									Where RecordTypeId =: rtBuildOrderId AND Order_Completion_Status__c =: 'In Progress']){

				mapOs.put(o.Id, o);						
			}							
		}
		
		if(mapOs.size() > 0){
			for(Workstep__c ws : [Select Order__c, End_Date__c From Workstep__c Where Name =: WorkstepUtils.APPLY_REDLINES AND Order__c IN: mapOs.keyset()]){
				mapAWSWSs.put(ws.Order__c, ws);
			}
			
			//Get all bldOrds with a blk 
			for(Workstep__c ws : [Select Order__c From Workstep__c 
										Where Order__c IN: mapOs.keyset() AND Duration__c != 0 AND Status__c ='Blocked']){				
				blockedOs.add(ws.Order__c);	
				mapBlkd.put(ws.Order__c, ws.Order__c);							
			}
			
			if(blockedOs.size() > 0){				
				//Blk and Late			
				for(Workstep__c ws : [Select Order__c  From Workstep__c 
										Where Status__c =: 'Open' AND Duration__c != 0 AND On_time_Late_Workstep__c < 0 AND Order__c IN: blockedOs
										]){
					blkAndLateOs.add(ws.Order__c);					
					mapBAndL.put(ws.Order__c, ws.Order__c);
				}
			}
			else{
				//Late
				for(Workstep__c ws : [Select Order__c  From Workstep__c 
										Where Status__c =: 'Open' AND Duration__c != 0 AND On_time_Late_Workstep__c < 0 AND Order__c IN: mapOs.keyset()
										]){
					lateOs.add(ws.Order__c);
				}
			}
					
			for(Id b : blockedOs){
				//Determine of all the blocked, which are only blocked (and not late also)
				if(mapBAndL.get(b) == null){
					blockedOnly.add(b);					
				}
			}
			//Determine of the Late, which are late only (and not blocked also);
			for(Id b : lateOs){
				if(mapBlkd.get(b) == null){
					lateOnly.add(b);					
				}
			}	
				
			//Late only worksteps
			if(lateOnly.size() > 0){			
				for(AggregateResult ag : [Select Order__r.Id ord, MIN(On_time_Late_Workstep__c) Dayz From Workstep__c 
										Where Status__c =: 'Open' AND Duration__c != 0 AND On_time_Late_Workstep__c < 0 AND Order__c IN: lateOnly
										Group By Order__r.Id, Status__c]){
		
					if(mapAWSWSs.get(String.valueOf(ag.get('ord'))) != null){								
							Date edate = mapAWSWSs.get(String.valueOf(ag.get('ord'))).End_Date__c;							
							Integer convert = Integer.valueOf(ag.get('Dayz')) * -1;					
							Date trueUp =  edate.addDays(convert);						
							Date validTrueUp = validateDate(trueUp);							
							Order__c tSO = mapOs.get(String.valueOf(ag.get('ord')));																									
							tSO.Projected_Network_Ready_Date__c = validTrueUp;												
							lOs.add(tSO);								
					}
				}
			}
			//blocked only
			if(blockedOnly.size() > 0){
				for(AggregateResult ag : [Select Order__c ord, MAX(Duration__c) Dayz From Workstep__c 
										Where Status__c =: 'Blocked' AND Duration__c != 0  AND Order__c IN: blockedOnly
										Group By Order__c
										Having MIN(On_time_Late_Workstep__c) >= 0]){
		
					if(mapAWSWSs.get(String.valueOf(ag.get('ord'))) != null){									
						Date edate = mapAWSWSs.get(String.valueOf(ag.get('ord'))).End_Date__c;																		
						Integer convert = Integer.valueOf(ag.get('Dayz')) != null ? Integer.valueOf(ag.get('Dayz')) : 0;																			
						Date trueUp =  edate.addDays(convert);																
						Date validTrueUp = validateDate(trueUp);																		
						Order__c tSO = mapOs.get(String.valueOf(ag.get('ord')));																			
						tSO.Projected_Network_Ready_Date__c = validTrueUp;																				
						lOs.add(tSO);
					}	
				}
			}
			//both late and blocked
			if(blkAndLateOs.size() > 0){
				for(AggregateResult ag : [Select Order__c ord, MAX(Duration__c) DurDayz, MIN(On_time_Late_Workstep__c) Dayz From Workstep__c 
										Where Status__c =: 'Blocked' AND Duration__c != 0 AND Order__c IN: blkAndLateOs
										Group By Order__c
										Having MIN(On_time_Late_Workstep__c) < 0 ]){
			
					if(mapAWSWSs.get(String.valueOf(ag.get('ord'))) != null){								
						Integer comboDayz = Integer.valueOf(ag.get('Dayz')) != null && Integer.valueOf(ag.get('DurDayz')) != null ? Integer.valueOf(ag.get('DurDayz')) + (Integer.valueOf(ag.get('Dayz')) * -1) : 0;												
						Date edate = mapAWSWSs.get(String.valueOf(ag.get('ord'))).End_Date__c;													
						Date trueUp = edate.addDays(comboDayz);										
						Date validTrueUp = validateDate(trueUp);												
						Order__c tSO = mapOs.get(String.valueOf(ag.get('ord')));																																		
						tSO.Projected_Network_Ready_Date__c = validTrueUp;							
						lOs.add(tSO);
					}						
				}
			}
			
			if(lOs.size() > 0){			
				update lOs;
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