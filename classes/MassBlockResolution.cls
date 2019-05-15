public with sharing class MassBlockResolution implements TestUtils.ITestableClass {
	
	public String orderId;
	public List<wsiWrapper> wsiWrapperList { get; set; }
	public List<Workstep_Issue__c> iss {get; set;}
	public Workstep_Issue__c dummyWSI { get; set; }
	public List<Sub_Order__c> so {get; set;}

	public MassBlockResolution() {
		dummyWSI = new Workstep_Issue__c();
		orderId = ApexPages.currentPage().getParameters().get('id');
		wsiWrapperList = new List<wsiWrapper>();
		so = new List<Sub_Order__c>([Select Id From Sub_Order__c Where Order__c =: orderId]);
		sObjectType objType = Workstep_Issue__c.getsObjectType();

		iss = [Select Id, Workstep__r.Sub_Order__r.Name, Workstep__r.Name, Name, Risk_Type__c, Reason__c, Reason_Subcategory__c, 
									   Expected_Follow_Up_Date__c, Resolution_Code__c, Resolution_Comments__c, Carrier__c, OwnerId, Owner.Name
									   FROM Workstep_Issue__c Where Workstep__r.Sub_Order__c IN: so AND Status__c =: 'Open'];
		for(Workstep_Issue__c wsi : iss){ 			      													
			wsiWrapperList.add(new wsiWrapper(wsi, false));
		}
	}
	
	public PageReference Save() {
		return SaveAction(new PageReference('/' + orderId));
	}
	
	public PageReference Cancel() {
		return new PageReference('/' + orderId);
	}
	
	public PageReference QuickSave() {
		PageReference pageReference = Page.MassBlockResolution;
        pageReference.getParameters().put('Id', orderId);
        pageReference.setRedirect(true);
		return SaveAction(PageReference);		
	}

	public PageReference ExitSave() {
		return SaveAction(new PageReference('/' + orderId));
	}
	
	private final Set<String> modifiableFields = new Set<String>{'Date_Resolved__c'
																,'Resolution_Code__c'
																,'Resolution_Comments__c'
																,'Estimated_Resolution__c'
																,'OwnerId'};
	public PageReference SaveAction(PageReference pageRef) {
		List<Workstep_Issue__c> wsiForInsert = new List<Workstep_Issue__c>();
		List<Workstep_Issue__c> sWorksteps = new List<Workstep_Issue__c>();
		Boolean anyChecked = false;
		for (wsiWrapper wss : wsiWrapperList) {			
			if (wss.isSelected) {				
				wss.wsi.Status__c = 'Open';
				sWorksteps.add(wss.wsi);
			}
		}	
		try {
			List<String> errors = new List<String>();
			for(Workstep_Issue__c work : sWorksteps){ 								
				if (string.IsEmpty(dummyWSI.Resolution_Code__c) && work.Resolution_Code__c == null)
					errors.add('Resolution Code: You must enter a value');
				if (string.IsEmpty(dummyWSI.Resolution_Comments__c) && work.Resolution_Comments__c == null)
					errors.add('Resolution Comments: You must enter a value');
				for (wsiWrapper wss : wsiWrapperList) {
					if (wss.isSelected) 
						anyChecked = true;
				}
				if(!anyChecked)
					errors.add('Please check at least 1 checkbox to perform Resolution on!');
				if (errors.size() > 0) {
					for(String error : errors)
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, error));
					return null;
				}
			}
			
		} 
		catch (DMLException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
			return null;
		}

		try{
			if (sWorksteps.size() > 0){
				for(Workstep_Issue__c work : sWorksteps){ 
					work.Resolution_Code__c = dummyWSI.Resolution_Code__c != null ? dummyWSI.Resolution_Code__c : work.Resolution_Code__c;
					work.Resolution_Comments__c = dummyWSI.Resolution_Comments__c != null ? dummyWSI.Resolution_Comments__c : work.Resolution_Comments__c;
					work.OwnerId = dummyWSI.OwnerId != null ? dummyWSI.OwnerId : work.OwnerId;
					work.Status__c = 'Resolved';
					work.Estimated_Resolution__c = dummyWSI.Estimated_Resolution__c != null ? dummyWSI.Estimated_Resolution__c : work.Estimated_Resolution__c;
					wsiForInsert.add(work);
				}				
				update wsiForInsert;
			}	
		}
		catch(Exception e){			
			return null;
		}		
		return pageRef;
	}
	
	public void ResolveSelected() {
		for (wsiWrapper wsis : wsiWrapperList) {
			if (wsis.isSelected) {
				wsis.isSelected = false;

				for(String f : modifiableFields){
					if(dummyWSI.get(f) != null && string.valueOf(dummyWSI.get(f)) != '')
						wsis.wsi.put(f, dummyWSI.get(f));
				}
			}
		}

		for(String f : modifiableFields)
			dummyWSI.put(f, null);
	}
	
	public class wsiWrapper extends ApexUtils.SortableClass {
		public Workstep_Issue__c wsi { get; set; }
		public Workstep_Issue__c wsiOld { get; set; }
		public boolean isSelected { get; set; }
		
		public wsiWrapper(Workstep_Issue__c wsi, boolean isSelected) {
			this.wsi = wsi;
			this.wsiOld = wsi.clone();
			this.isSelected = isSelected;
		}
	}
	
	public String sortColumn { get; set; }
    private String sortOrder = 'Sub_Order__c ASC';
	public List<Workstep_Issue__c> wIss = new List<Workstep_Issue__c>();
    public void sortResults() {  
    if ( this.sortOrder != sortColumn + ' ASC') {
		this.sortOrder = sortColumn + ' ASC' ;
    }
    else {
        this.sortOrder = sortColumn + ' DESC';
    }
	List<Id> sid = new List<Id>();
	for(Sub_Order__c soi : so){
		sid.add(soi.Id);
	}

	String query = 'Select Id, Workstep__r.Sub_Order__r.Name, Workstep__r.Name, Name, Risk_Type__c, Reason__c, Reason_Subcategory__c, ' +
									'Expected_Follow_Up_Date__c, Resolution_Code__c, Resolution_Comments__c, Carrier__c, OwnerId, Owner.Name '+
									'FROM Workstep_Issue__c '+
									'Where Workstep__r.Sub_Order__c IN: sid  AND Status__c = \'Open\' '+
									'Order By ' + this.sortOrder;

	wIss = database.query(query);
	wsiWrapperList.clear();
	for(Workstep_Issue__c works : wIss){ 					      													
		wsiWrapperList.add(new wsiWrapper(works, false));
	}
    }
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_MassBlockResolution(); }
}