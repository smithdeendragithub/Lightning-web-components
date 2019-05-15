public with sharing class NotesViewerController extends RelatedRecordViewerBaseController implements TestUtils.ITestableClass {
	
	public Boolean opDerived {get; set;}
	
	public String ClientTimeZoneOffset {get; set;}
	
	public List<NotesHelper> notes {get; set;}
	
	public class NotesHelper extends ApexUtils.SortableClass {
		public String ApplicationName { get; set; }
		public String Remark { get; set; }
		public String CreatedBy { get; set; }
		public DateTime CreateDate { get; set; }
		public String CreateDateFormat { get; set; }
		public nObject sfObject { get; set; }
		public nObject parent { get; set; }
		
		public NotesHelper(String ApplicationName, String Remark, String CreatedBy, DateTime CreateDate, nObject sfObject, nObject parent){
			this.ApplicationName = ApplicationName;
			this.Remark = Remark;
			this.CreatedBy = CreatedBy;
			this.CreateDate = CreateDate;
			this.CreateDateFormat = CreateDate.format();
			this.sfObject = sfObject;
			this.parent = parent;
		}
		
		public override object getFieldImp(String fName){
			if(fName == 'ApplicationName') return ApplicationName;
			if(fName == 'Remark') return Remark;
			if(fName == 'CreatedBy') return CreatedBy;
			if(fName == 'CreateDate') return CreateDate;
			if(fName == 'ObjectName') return (sfObject != null ? sfObject.name : null);
			if(fName == 'ParentName') return (parent != null ? parent.name : null);
			return null;
		}
	}
	
	public ApexUtils.SortableClassConfig sortConfig { get; set; }
		
	public NotesViewerController() {
		initialize();
		
		String op = ApexPages.currentPage().getParameters().get('op');
		opDerived = op == '1';
		
		StartDate = date.today();
		EndDate = StartDate;
		
		StartDateString = !opDerived ? formatDate(StartDate) : null;
		EndDateString = formatDate(EndDate);
		
		ClientTimeZoneOffset = 'Z';
		
		notes = new List<NotesHelper>();
		sortConfig = new ApexUtils.SortableClassConfig('', 'CreateDate', true);
	}
	
	public transient Map<String, String> IdToUserName {get; set;}
	public void GetNotes() {
		notes = new List<NotesHelper>();
		
		if(objectID != null && reset()){
			IdToUserName = new Map<String, String>();
			
			getExternalNotes('SubID', 'Subscriber', null, null);
			getExternalNotes('OrderID', 'Order', 'ICC', new Map<String, String>{'OrderIDOnly'=>'true'});
			getExternalNotes('OrderGroupID', 'OrderProductGroup', 'ICC', null);
			
			DateTime s = StartDate != null ? StartDate : DateTime.newInstance(1700, 1, 1);	//API min
			DateTime e = EndDate;
			for(Note__c note : [select Id, Name, Account__c, Description__c, Private__c, CreatedDate, CreatedById
									from Note__c where CreatedDate >=: s and CreatedDate <=: e and Account__c in: nObjects.keyset()]) {
				notes.add(new NotesHelper('SFDC', findAndCreateLinks(note.Description__c), note.CreatedById, note.CreatedDate, new nObject(note.Name, note.Id, null), nObjects.get(note.Account__c)));
			}
			
			for(Note note : [select Id, ParentId, Title, Body, CreatedById, CreatedDate from Note where ParentId in: nObjects.keyset() and CreatedDate >=: s and CreatedDate <=: e]){
				notes.add(new NotesHelper('SFDC', findAndCreateLinks(note.Body), note.CreatedById, note.CreatedDate, new nObject(note.Title, note.Id, null), nObjects.get(note.ParentId)));
			}
			
			Map<Id, Case> cases = new Map<Id, Case>();
			for(Case c : [select Id, CaseNumber, Status, CreatedById, CreatedDate, ClosedDate, (select CreatedById, NewValue from Histories where Field = 'Status') from Case where AccountId in: nObjects.keyset()]){
				cases.put(c.Id, c);
				
				Boolean createdAsClosed = c.CreatedDate == c.ClosedDate;
				notes.add(new NotesHelper('SFDC', (createdAsClosed ? 'Closed case created' : 'Case opened'), c.CreatedById, c.CreatedDate, new nObject(getCaseName(c), c.Id, null), nObjects.get(c.Id)));
				if(!createdAsClosed && c.ClosedDate != null){
					Id closedByID = c.CreatedById;
					for(CaseHistory ch : c.Histories){
						if(ch.NewValue != null && string.valueOf(ch.NewValue).contains('Closed'))
							closedByID = ch.CreatedById;
					}
					
					notes.add(new NotesHelper('SFDC', 'Case closed', closedByID, c.ClosedDate, new nObject(getCaseName(c), c.Id, null), nObjects.get(c.Id)));
				}
			}
			
			for(CaseComment cc : [select Id, ParentId, CommentBody, CreatedById, CreatedDate from CaseComment where ParentId in: cases.keyset()]){
				Case c = cases.get(cc.ParentId);
				notes.add(new NotesHelper('SFDC', findAndCreateLinks(cc.CommentBody), cc.CreatedById, cc.CreatedDate, new nObject(getCaseName(c), cc.ParentId, null), nObjects.get(cc.ParentId)));
			}
			
			for(NotesHelper n : notes){
				if(ApexUtils.isValidId(n.CreatedBy))
					IdToUserName.put(n.CreatedBy, null);
			}
			
			for(User u : [select Id, name, NTID__c from User where id in :IDToUserName.keySet() or NTID__c in :IdToUserName.keySet()]) {
				IdToUserName.put(u.Id, u.Name);
				if(u.NTID__c != null)
					IdToUserName.put(u.NTID__c.toLowercase(), u.Name);
			}
			
			for(NotesHelper n : notes){
				n.CreatedBy = (n.CreatedBy != null)
								? (IdToUserName.get(n.CreatedBy.toLowercase()) != null
									? IdToUserName.get(n.CreatedBy.toLowercase())
									: (IdToUserName.get(n.CreatedBy) != null
										? IdToUserName.get(n.CreatedBy)
										: n.CreatedBy))
								: 'Unknown';
			}
			
			ApexUtils.Sort(notes, sortConfig);
		}
	}
	
	private void getExternalNotes(String mapKey, String mode, String applicationID, Map<String, String> additionalFields){
		Map<String, Id> m = externalIDMap.get(mapKey);
		if(m != null && m.size() > 0){
			List<Integer> ids = new List<Integer>();
			for(String val : m.keyset())
				ids.add(Integer.valueOf(val));
			
			if(additionalFields == null)
				additionalFields = new Map<String, String>();
			
			additionalFields.put('limit', '1000');
			List<integraWS.SFRemarkView> remarkViews = getExternalNotes(ids, mode, additionalFields);
			for(integraWS.SFRemarkView r : remarkViews != null ? remarkViews : new List<integraWS.SFRemarkView>()) {
				notes.add(new NotesHelper(applicationID != null ? applicationID : mapApplicationId(ICCWrapper.getAdditionalFieldFromRemark(r, 'ApplicationID')), findAndCreateLinks(r.Remark), r.CreateUser, r.CreateDate, null, nObjects.get(m.get(string.valueOf(r.ParentExternalID)))));
				IdToUserName.put(r.CreateUser, r.CreateUser);
			}
		}
	}
	
	private List<integraWS.SFRemarkView> getExternalNotes(List<Integer> parentIDs, String mode, Map<String, String> additionalFields) {
		try{
			return ICCWrapper.getRemarksByParentRecordIDs(parentIDs, mode, StartDate, EndDate, additionalFields);
		}
		catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error while attempting to load external notes: "' + e.getMessage() + '"'));
			return null;
		}
	}
	
	public void changeSort() {
		String sortColumn = ApexPages.currentPage().getParameters().get('sortColumn');
		sortConfig.changeSort('', sortColumn);
		ApexUtils.Sort(notes, sortConfig);
	}
	
	private final Map<String, String> applicationIds = new Map<String, String>
													{
														'1'=>'ICUST'
														,'2'=>'ICOLLECT'
														,'3'=>'Call Log'
														,'4'=>'ACHSystem'
														,'5'=>'ICC'
														,'6'=>'iCreditReq'
														,'7'=>'IntegraCare'
														,'8'=>'Automated Welcome Kit'
														,'9'=>'Contract Renewal Wizard'
														,'10'=>'SMP'
													};
	private String mapApplicationId(String ApplicationId) {
		return (!applicationIds.containskey(ApplicationId)) ? 'Unknown' : applicationIds.get(ApplicationId);
	}
	
	private String findAndCreateLinks(String text) {
		if(text == null || text.length() >= 1000) return (text == null? '' : text.replace('\n', '<br />'));		//avoiding "regex too complicated" error
		
		Pattern linkFinder = Pattern.compile('(?i)(href\\s*=\\s*)?\\s*["|\']?\\s*(https?://\\S*)');
		Matcher linkMatcher = linkFinder.matcher(text);
		while(linkMatcher.find()) {
			if(linkMatcher.groupCount() == 2 && (linkMatcher.group(1) == '' || linkMatcher.group(1) == null) && linkMatcher.group(2) != '') {
				String link = '&nbsp;<a style="font-weight:bold;" target="_blank" href="' + linkMatcher.group(2) + '">' + linkMatcher.group(2) + '</a>';
				text = text.replace(text.substring(linkMatcher.start(), linkMatcher.end()), link);
			}
		}
		return text.replace('\n', '<br />');
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_NotesViewer(); }
}