public with sharing class SubOrderTriggers {
	
    public static void SubOrderModified(List<Sub_Order__c> tNew, List<Sub_Order__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
		
    	if(!ApexUtils.executeTriggerMethods('Sub_Order__c', isBefore, isDelete)) return;
		
        if(isBefore){
        	if(isDelete){
        		//Nothing to do
            }
            else{
            	if(isUpdate){
        			Map<Id, Sub_Order__c> tOldMap = new Map<Id, Sub_Order__c>(tOld);
        			handleProvisioningProductUpdates(tNew, tOldMap, true);
            	}
            	else{
            		setSubSequenceNumbers(tNew);
        			setProvisioningProducts(tNew);
            	}
            }
        }
        else{
        	if(isDelete){
        		//Nothing to do
        	}
        	else{
        		Map<Id, Sub_Order__c> tOldMap = tOld != null ? new Map<Id, Sub_Order__c>(tOld) : new Map<Id, Sub_Order__c>();
        		if(isUpdate)
        			handleProvisioningProductUpdates(tNew, tOldMap, false);		//Do first
        		
				evaluateSubOrder(tNew, tOldMap);
				
        		if(!isUpdate){
        			WorkstepUtils.recalculatePDD(new Map<Id, Sub_Order__c>(tNew).keyset());
        		}
        	}
     	
	        fixFieldsAfter(tNew);	        	
			ApexUtils.afterTriggerComplete('Sub_Order__c', isDelete);
    	}
    }
    
    private static List<Workstep__c> wsToDelete = null;
    private static void handleProvisioningProductUpdates(List<Sub_Order__c> tNew, Map<Id, Sub_Order__c> tOldMap, Boolean isBefore){
    	if(isBefore){
	    	Map<Id, Sub_Order__c> changes = new Map<Id, Sub_Order__c>();
	    	for(Sub_Order__c so : tNew){
	    		if(so.Provisioning_Product__c != tOldMap.get(so.Id).Provisioning_Product__c){
	    			if(so.Provisioning_Product__c == null)
	    				so.addError('You cannot clear the provisioning product value once it has been set');
	    			else
	    				changes.put(so.Id, so);
	    		}
	    	}
	    	
	    	if(changes.size() > 0){
	    		wsToDelete = [select Id, Status__c, Sub_Order__c from Workstep__c where Sub_Order__c in: changes.keyset()];
	    		
	    		for(Workstep__c ws : wsToDelete){
	    			if(ws.Status__c != 'Open' && ws.Status__c != 'Pending'){
		    			if(changes.containskey(ws.Sub_Order__c)){
		    				Sub_Order__c so = changes.get(ws.Sub_Order__c);
		    				so.addError('The provisioning product cannot be changed because the current workstep process has been started');
		    				changes.remove(so.Id);
		    			}
	    			}
	    		}
	    	}
    	}
    	else{
    		List<Workstep__c> wsList = wsToDelete;	//Recursion insurance
			wsToDelete = null;
			if(wsList != null && wsList.size() > 0)
				SecurityUtils.BypassProcesser.deleteObjects(wsList, false);
    	}
    }
    
    private static void setSubSequenceNumbers(List<Sub_Order__c> tNew){
    	Map<Id, Decimal> orderSubSequenceMax = new Map<Id, Decimal>();
    	for(Sub_Order__c sNew : tNew)
    		orderSubSequenceMax.put(sNew.Order__c, 0);
    	
    	for(Sub_Order__c so : [select Id, Sub_Sequence__c, Order__c from Sub_Order__c where Order__c in: orderSubSequenceMax.keyset()]){
    		if(orderSubSequenceMax.get(so.Order__c) < so.Sub_Sequence__c)
    			orderSubSequenceMax.put(so.Order__c, so.Sub_Sequence__c);
    	}
    	
    	for(Sub_Order__c sNew : tNew){
    		Decimal sequence = orderSubSequenceMax.get(sNew.Order__c) + 1;
    		sNew.Sub_Sequence__c = sequence;
    		orderSubSequenceMax.put(sNew.Order__c, sequence);
    	}
    }
	
	private static void setProvisioningProducts(List<Sub_Order__c> tNew) {
		Map<Id, Order_Property__c> p = new Map<Id, Order_Property__c>();
		for (Sub_Order__c so : tNew) {
			if (so.External_Order__c != null)
				p.put(so.External_Order__c, null);
		}
		
		if(p.size() > 0)
			p = new Map<Id, Order_Property__c>([select Id, Type__c from Order_Property__c where Id in : p.keyset()]);
		
		Map<Id, Id> spcToPPMap = new Map<Id, Id>();
		for (SPC_Product__c spc : [SELECT Id, Provisioning_Product__c FROM SPC_Product__c])
			spcToPPMap.put(spc.Id, spc.Provisioning_Product__c);
		
		for (Sub_Order__c so : tNew) {
			if (so.Provisioning_Product__c == null && so.SPC_Product__c  != null && spcToPPMap.get(so.SPC_Product__c) != null && (so.External_Order__c == null || p.get(so.External_Order__c).Type__c == 'Install Order'))
				so.Provisioning_Product__c = spcToPPMap.get(so.SPC_Product__c);
		}
	}
    
	private static void fixFieldsAfter(List<Sub_Order__c> tNew){
		List<Sub_Order__c> updates = new List<Sub_Order__c>();
		for(Sub_Order__c sNew : [select Id, Name, Sub_Order_Number__c from Sub_Order__c where Id in : tNew]){
			Boolean updated = false;
			if(sNew.Sub_Order_Number__c != null && sNew.Name != sNew.Sub_Order_Number__c){
				sNew.Name = sNew.Sub_Order_Number__c;
				updated = true;
			}
			
			if(updated)
				updates.add(sNew);
		}

		if(updates.size() > 0)
			update updates;
    }
	
	private static void evaluateSubOrder(List<Sub_Order__c> tNew, Map<Id, Sub_Order__c> tOldMap) {
		Map<Id, Sub_Order__c> soMap = new Map<Id, Sub_Order__c>();
		Map<String, Map<Id, Sub_Order__c>> updateMaps = new Map<String, Map<Id, Sub_Order__c>>{'AccessTypes'=>new Map<Id, Sub_Order__c>()
																								,'Cancelled'=>new Map<Id, Sub_Order__c>()
																								,'CreateWS'=>new Map<Id, Sub_Order__c>()
																								,'Expedited'=>new Map<Id, Sub_Order__c>()
																								,'StartDate'=>new Map<Id, Sub_Order__c>()};
		
		Set<String> dateDrivingFields = WorkstepUtils.SubOrderDateDrivingFields;
		Set<String> checkFieldUpdates = new Set<String>{'Access_Types__c'
														,'Expedited__c'
														,'Provisioning_Product__c'
														,'Status__c'
														,'Workplan_Start_Date__c'};
		checkFieldUpdates.addAll(dateDrivingFields);
		for (Sub_Order__c so :tNew) {
			Sub_Order__c soOld = tOldMap.get(so.Id);
			Set<String> s = new Set<String>();
			if(soOld == null)
				s = checkFieldUpdates;
			else{
				for(String field : checkFieldUpdates){
					if(soOld == null || soOld.get(field) != so.get(field))
						s.add(field);
				}
			}
			
			if(s.size() > 0){
				soMap.put(so.Id, so);
				
				if(s.contains('Access_Types__c') && soOld != null){
					System.debug(LoggingLevel.DEBUG, 'Access Type update Map');
					updateMaps.get('AccessTypes').put(so.Id, so);}
				
				if ((s.contains('Provisioning_Product__c') || s.contains('Workplan_Start_Date__c')) && so.Workplan_Start_Date__c != null)
					updateMaps.get('CreateWS').put(so.Id, so);
				
				for(String f : dateDrivingFields){
					if (s.contains(f)){
						updateMaps.get('StartDate').put(so.Id, so);
						break;
					}
				}
					
				if(s.contains('Status__c') && so.Status__c == 'Cancelled' && soOld != null)	//Cancelling an insert doesn't require any work
					updateMaps.get('Cancelled').put(so.Id, so);
				
				if(s.contains('Expedited__c'))
					updateMaps.get('Expedited').put(so.Id, so);
			}
		}
		
		createWorkstepsIfNeeded(updateMaps.get('CreateWS'));
		
		Map<Id, Workstep__c> wsForUpdate = new Map<Id, Workstep__c>();
		
		List<Workstep__c> wsList = [SELECT Id, Name, Attribute__c, Sub_Order__c, Status__c, Start_Date__c, End_Date__c, Lag__c, Duration__c, SLA__c, Template__c, Workstep_Library__c FROM Workstep__c WHERE Sub_Order__c IN :soMap.keySet()];
		if(updateMaps.get('AccessTypes').size() > 0){
			List<Workstep__c> updated = WorkstepUtils.calculateRelatedWorkstepOffsets(new Map<Id, Sub_Order__c>(updateMaps.get('AccessTypes')), wsList);
			for(Workstep__c ws : updated)
				wsForUpdate.put(ws.Id, ws);
		}
		
		if(updateMaps.get('StartDate').size() > 0){
			for(Workstep__c ws : wsList){
				if(updateMaps.get('StartDate').containsKey(ws.Sub_Order__c)){
					WorkstepUtils.WorkstepDates d = new WorkstepUtils.WorkstepDates();
					if(WorkstepUtils.tryGetAttributeDates(ws, soMap.get(ws.Sub_Order__c), d)){
						if(d.StartDate != null)
							ws.Start_Date__c = d.StartDate;
						
						ws.End_Date__c = d.EndDate;		//Always set end date to force a recalc if anything changes						
						wsForUpdate.put(ws.Id, ws);
					}
				}
			}
		}		
		wsForUpdate.putAll(updateExpedited(wsList, soMap, updateMaps.get('Expedited').keyset()));
		wsForUpdate.putAll(setStatusForCancelSO(wsList, updateMaps.get('Cancelled').keyset()));
	
		List<Workstep__c> newAntiWsList = createAntiWS(updateMaps.get('Cancelled').keyset());
		if (!wsForUpdate.isEmpty())
			update wsForUpdate.values();
		if (newAntiWsList.size() > 0)
			insert newAntiWsList;
	}
	
	private static List<Workstep__c> createAntiWS(Set<Id> canceledSO) {
		List<Workstep__c> antiWSList = new List<Workstep__c>();
		if(canceledSO.size() > 0){
			for (Workstep__c ws : [SELECT Id
										,Duration__c
										,Name
										,Sub_Order__c
										,Sub_Order__r.Order__c
										,OwnerId
										,Workstep_Library__c
										,Workstep_Library__r.Attribute__c
										,Workstep_Library__r.Non_Access_Duration__c
										,Workstep_Library__r.Non_Access_SLA__c
										,Workstep_Library__r.OwnerId
								FROM Workstep__c WHERE Sub_Order__c IN :canceledSO AND Workstep_Library__r.Anti_Workstep__c = true AND Duration__c != 0 AND (Status__c =: WorkstepUtils.STATUS_COMPLETE OR Status__c =: WorkstepUtils.STATUS_OPEN OR Status__c =: WorkstepUtils.STATUS_BLOCKED)]){
				antiWSList.add(new Workstep__c(Name = 'Cancelled ' + ws.Name
										,Workstep_Library__c = ws.Workstep_Library__c
										,Attribute__c = ws.Workstep_Library__r.Attribute__c
										,Duration__c = ws.Duration__c
										,SLA__c = ws.Workstep_Library__r.Non_Access_SLA__c
										,Sub_Order__c = ws.Sub_Order__c
										,Status__c = 'Open'
										,Order__c = ws.Sub_Order__r.Order__c
										,Original_Workstep__c = ws.Id
										,Start_Date__c = WorkstepUtils.calculateAfterDate(date.today(), 0, true)
										,OwnerId = ws.OwnerId
										));
			}
		}
		
		return antiWSList;
	}
	
	private static Map<Id, Workstep__c> updateExpedited(List<Workstep__c> wsList, Map<Id, Sub_Order__c> soMap, Set<Id> expeditedSo) {
		Map<String, Boolean> compressibilityMap = WorkstepUtils.getAttributesCompressibility();
		Map<Id, Workstep__c> wsForUpdate = new Map<Id, Workstep__c>();
		for (Workstep__c ws : wsList) {
			if (ws.Status__c != WorkstepUtils.STATUS_COMPLETE) {
				Decimal oldDuration = ws.Duration__c;
				if (expeditedSo.contains(ws.Sub_Order__c) && (ws.Attribute__c == null || compressibilityMap.get(ws.Attribute__c.toLowerCase()) == true))
					ws.Duration__c = soMap.get(ws.Sub_Order__c).Expedited__c == true ? (((Integer)ws.SLA__c + 1) / 2) : ws.SLA__c;
				
				if (ws.Duration__c != oldDuration && !wsForUpdate.containsKey(ws.Id))
					wsForUpdate.put(ws.Id, ws);
			}
		}
		return wsForUpdate;
	}
	
	private static Map<Id, Workstep__c> setStatusForCancelSO(List<Workstep__c> wsList, Set<Id> canceledSO) {
		Map<Id, Workstep__c> modifiedWs = new Map<Id, Workstep__c>();
		Map<Id, Workstep__c> cancelBlocked = new Map<Id, Workstep__c>();
		List<Workstep_Issue__c> updateWSI = new List<Workstep_Issue__c>();
		
		for (Workstep__c ws : wsList) {
			if(canceledSO.contains(ws.Sub_Order__c) && ws.Status__c == WorkstepUtils.STATUS_BLOCKED){
					cancelBlocked.put(ws.Id, ws);
			}
			if (canceledSO.contains(ws.Sub_Order__c) && ws.Status__c != WorkstepUtils.STATUS_COMPLETE) {
				ws.Status__c = WorkstepUtils.STATUS_CANCELLED;
				modifiedWs.put(ws.Id,ws);
			}
		}
		if(cancelBlocked.size() > 0){
    		for(Workstep_Issue__c wsi: [select Id, Workstep__c, Reason__c, Resolution_Comments__c from Workstep_Issue__c WHERE   Workstep__c in: cancelBlocked.keyset()]){
    			wsi.Reason__c = 'Order Canceled';
    			wsi.Status__c = 'Resolved';
    			wsi.Resolution_Comments__c = 'Cancelling Sub-Order';
    			wsi.Resolution_Code__c = 'Order Canceled';
    			wsi.Date_Resolved__c = date.today();
   			
    			updateWSI.add(wsi);
    		}
    	}
    	update updateWSI;
		return modifiedWs;
	}
	
	private static void createWorkstepsIfNeeded(Map<Id, Sub_Order__c> soForStartDateMap){
		Map<Id, Sub_Order__c> updated = new Map<Id, Sub_Order__c>();
		for(Sub_Order__c so : soForStartDateMap.values()){
			if(so.Provisioning_Product__c != null && (so.Status__c != 'Closed' && so.Status__c != 'Cancelled'))
				updated.put(so.Id, so);
		}
		
		if(updated.size() > 0)
			WorkstepUtils.createWorksteps(updated);
	}
}