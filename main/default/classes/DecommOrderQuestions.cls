public with sharing class DecommOrderQuestions {
	public Order__c dummyOrder { get; set; }
	public String bldgId;
	public Id rt;
		
	public DecommOrderQuestions() {
		bldgId = Apexpages.currentPage().getParameters().get('id');
		dummyOrder = new Order__c();
		dummyOrder.OwnerId = UserInfo.getUserId();
		dummyOrder.Action__c = 'Remove';
		dummyOrder.ESO_Number__c = '';
		dummyOrder.Building__c = bldgId;
		dummyOrder.Order_Completion_Status__c = 'In Progress';
		dummyOrder.Build_Category__c = 'Network';			
	}
	
	public PageReference Save() {
		return SaveAction();
	}
	
	public PageReference Cancel() {
		PageReference pr = new PageReference('/' + bldgId);
        pr.setRedirect(true);

		return pr;
	}
	
	public PageReference QuickSave() {
		return SaveAction();		
	}
	
	public PageReference SaveAction() {
		try {
			List<String> errors = new List<String>();
			
			if (string.IsEmpty(dummyOrder.Project_Name__c))
				errors.add('Project Name: You must enter a value');
			if (dummyOrder.ESO_Classification__c == null)
				errors.add('ESO Classification: You must select a value');
			if (string.IsEmpty(dummyOrder.Scope__c))
				errors.add('Comments: You must enter a value');

			if (errors.size() > 0) {
				system.debug('errors: ' + errors);
				for(String error : errors)
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, error));
				return null;
			}			
		} 
		catch (DMLException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
			return null;
		}
		Order__c decom = new Order__c();
		Schema.Describesobjectresult r = Order__c.sObjectType.getDescribe();
		Boolean hasAccess = r.isCreateable();
		
		for(Schema.RecordtypeInfo rti : Order__c.sObjectType.getDescribe().getRecordTypeInfos()) {						
			if(rti.getName().equalsIgnoreCase('Decomm Order')){
				rt = rti.getRecordTypeId();
				if(!hasAccess || !rti.isAvailable()){
					return null;
				}
			}
		}
		try{
					decom.Project_Name__c = dummyOrder.Project_Name__c;
					decom.OwnerId = dummyOrder.OwnerId;
					decom.ESO_Classification__c = dummyOrder.ESO_Classification__c;
					decom.Action__c = dummyOrder.Action__c;
					decom.ESO_Number__c = dummyOrder.ESO_Number__c;
					decom.Building__c = dummyOrder.Building__c;					
					decom.Order_Completion_Status__c = dummyOrder.Order_Completion_Status__c;
					decom.Field_Owner__c = dummyOrder.Field_Owner__c;
					decom.Build_Category__c = dummyOrder.Build_Category__c;
					decom.iCert_Number__c = dummyOrder.iCert_Number__c;
					decom.Third_Party__c = dummyOrder.Third_Party__c;
					decom.OSP_Required__c = dummyOrder.OSP_Required__c;
					decom.Scope__c = dummyOrder.Scope__c;
					decom.RecordTypeId = rt;					
					List<Location__c> locName = [select Name from Location__c where Building__c = :bldgId limit 1];				
					decom.Location__c = locName.size() == 0 ? Null : locName[0].Name;					
					decom.Order_Create_Date__c = Date.today();
					decom.Workplan_Start_Date__c = Date.today();
					decom.Provisioning_Plan_Enabled__c = true;
					if(decom.OSP_Required__c){
						List<Provisioning_Product__c> pp = [select Id from Provisioning_Product__c where Name = 'Standard Build Decommission' limit 1];
						decom.Provisioning_Product__c = pp.size() > 0 ? pp[0].Id : null;
					}
					else{
						List<Provisioning_Product__c> pp = [select Id from Provisioning_Product__c where Name = 'Build Decommission - no OSP' limit 1];
						decom.Provisioning_Product__c = pp.size() > 0 ? pp[0].Id : null;
					}											
				insert decom;
		}
		catch(Exception e){			
			return null;
		}
		
		PageReference pr = new PageReference('/' + decom.Id);
        pr.setRedirect(true);
        
		return pr;
	}	
}