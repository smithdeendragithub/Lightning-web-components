public class GlobalUtilities implements TestUtils.ITestableClass {

    public static final Long DOCGENBIT_COVER_PAGE = 1l << 0;  
    public static final Long DOCGENBIT_LETTER = 1l << 1; 
    public static final Long DOCGENBIT_EXECSUMMARY = 1l << 2; 
    public static final Long DOCGENBIT_QUOTE = 1l << 3; 
    public static final Long DOCGENBIT_COSTCOMPARISON = 1l << 4; 
    public static final Long DOCGENBIT_SERVICEAGREEMENT = 1l << 5; 
    public static final Long DOCGENBIT_LOA = 1l << 6; 
    public static final Long DOCGENBIT_DIRECTORYFORM = 1l << 7; 
    public static final Long DOCGENBIT_ROLOA = 1l << 8;     
    public static final Long DOCGENBIT_911FORM = 1l << 9;     
    public static final Long DOCGENBIT_ETFCREDIT = 1l << 10;    
    public static final Long DOCGENBIT_SATGUARANTEE = 1l << 11;    
    public static final Long DOCGENBIT_MOVE = 1l << 12;    
    public static final Long DOCGENBIT_BUSDOWNTURN_SR = 1l << 13; 
    public static final Long DOCGENBIT_SUMMARYOFWORK = 1l << 14;   
    public static final Long DOCGENBIT_MSA = 1l << 15;
    public static final Long DOCGENBIT_MSA_HVSADDENDUM = 1l << 16;
    public static final Long DOCGENBIT_MSA_COLLABORATIONADDENDUM = 1l << 17;
    public static final Long DOCGENBIT_MSA_COLOCATIONADDENDUM = 1l << 18;
    public static final Long DOCGENBIT_LOACPNI = 1l << 19;
    public static final Long DOCGENBIT_BUSDOWNTURN_LD = 1l << 20;
    public static final Long DOCGENBIT_INCENTIVE_MRC = 1l << 21;
    public static final Long DOCGENBIT_INCENTIVE_AMOUNT = 1l << 22;
    public static final Long DOCGENBIT_ITSERVICES = 1l << 23;
    public static final Long DOCGENBIT_WAVELENGTH = 1l << 24;
    public static final Long DOCGENBIT_PARTNERORDER = 1l << 25;
    public static final Long DOCGENBIT_ERATE = 1l << 26;
    public static final Long DOCGENBIT_INSIDEADDENDUM = 1l << 27;
    public static final Long DOCGENBIT_MSAFORVPN= 1l << 28;
    public static final Long DOCGENBIT_ERATESVCREQ= 1l << 29;
    public static final Long DOCGENBIT_CFSCB= 1l << 30;
    public static final Long DOCGENBIT_MSADDOSMIT= 1l << 31;
    public static final Long DOCGENBIT_CFSServiceLA= 1l << 32;
	public static final Long DOCGENBIT_MSA_WIRELESSBACKUPADDENDUM = 1l << 33;
	public static final Long DOCGENBIT_MSA_MONTHTOMONTHRENEWAL = 1l << 34;
	public static final Long DOCGENBIT_HSINTERNETADDENDUM = 1l << 35;
	public static final Long DOCGENBIT_PAPERLESSBILLING = 1l << 36;
	public static final Long DOCGENBIT_MSA_ETHERNETSERVICESADDENDUM = 1l << 37;
	public static final Long DOCGENBIT_MSA_HSISADDENDUM = 1l << 38;
	public static final Long DOCGENBIT_VOIPOVERID = 1l << 39;
	public static final Long DOCGENGIN_MSA_UC_CLOUDVOICE = 1l << 40;
	public static final Long DOCGENBIT_MSA_CPPOES = 1l << 41;
    
    public static final String RECIPIENT_TYPE_SIGNER = 'Signer';
    public static final String RECIPIENT_TYPE_COUNTERSIGNER = 'Countersigner';
    public static Map<Decimal,String> componentIDToTEXT = new Map<Decimal,String>();
    
    public static final Map<String, String> StateCodeToName = new Map<String, String>{'AL'=>'Alabama', 'AK'=>'Alaska', 'AZ'=>'Arizona', 'AR'=>'Arkansas', 'CA'=>'California',
                                                                                    'CO'=>'Colorado', 'CT'=>'Connecticut', 'DE'=>'Delaware', 'FL'=>'Florida', 'GA'=>'Georgia',
                                                                                    'HI'=>'Hawaii', 'ID'=>'Idaho', 'IL'=>'Illinois', 'IN'=>'Indiana', 'IA'=>'Iowa',
                                                                                    'KS'=>'Kansas', 'KY'=>'Kentucky', 'LA'=>'Louisiana', 'ME'=>'Maine', 'MD'=>'Maryland',
                                                                                    'MA'=>'Massachusetts', 'MI'=>'Michigan', 'MN'=>'Minnesota', 'MS'=>'Mississippi', 'MO'=>'Missouri',
                                                                                    'MT'=>'Montana', 'NE'=>'Nebraska', 'NV'=>'Nevada', 'NH'=>'New Hampshire', 'NJ'=>'New Jersey',
                                                                                    'NM'=>'New Mexico', 'NY'=>'New York', 'NC'=>'North Carolina', 'ND'=>'North Dakota', 'OH'=>'Ohio',
                                                                                    'OK'=>'Oklahoma', 'OR'=>'Oregon', 'PA'=>'Pennsylvania', 'RI'=>'Rhode Island', 'SC'=>'South Carolina',
                                                                                    'SD'=>'South Dakota', 'TN'=>'Tennessee', 'TX'=>'Texas', 'UT'=>'Utah', 'VT'=>'Vermont',
                                                                                    'VA'=>'Virginia', 'WA'=>'Washington', 'WV'=>'West Virginia', 'WI'=>'Wisconsin', 'WY'=>'Wyoming',
                                                                                    'DC'=>'District of Columbia'};
    
	public static final Map<Integer, String> MonthNumberToName = new Map<Integer, String>{
			1 => 'January',	2 => 'February', 3 => 'March', 4 => 'April', 5 => 'May', 6 => 'June',
			7 => 'July', 8 => 'August', 9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'};
	
    private static Map<Id, User> userMap;
    public static Map<Id, User> users{
        get{
            if(userMap == null){
                userMap = new Map<Id, User>();
                for(List<User> users : [select Id, NTID__c, Sales_Channel__c from User]){
                    for(User user : users)
                        userMap.put(user.Id, user);
                }
            }
            
            return userMap;
        }
    }
        
    public class Recipient { 
        
        private Boolean to = false;
        private Boolean cc = false;
        
        public Recipient() {
        }
        
        public Boolean getCC() {
            return this.cc;
        }
        public void setCC(Boolean cc) {
            this.cc = cc;
            if(cc) {
                this.to = false;
            }
        }
        public Boolean getTo() {
            return this.to;
        }
        public void setTo(Boolean to) {
            this.to = to;
            if(to) {
                this.cc = false;
            }
        }

        public Contact c {get;set;}
        public String opptyRole {get;set;}
        public String recipientType {get;set;}
        public String accRole {get;set;}
    }
    
    public static List<Recipient> LoadRecipients(Opportunity oppty) {
        List<Recipient> retVal = new List<Recipient>();
        
        if( oppty.AccountId == null )
            return retVal;
        
        try {
    
            List<OpportunityContactRole> opptyroles = [Select ContactId, Role From OpportunityContactRole Where OpportunityId=:oppty.Id];
            
            Set<Id> ocrs = new Set<Id>();
            for( OpportunityContactRole ocr : opptyroles ) {
                ocrs.add(ocr.ContactId);
            }
            
            /// begin mod jms 10/26/2011 add children contacts to list
            Set<Id> acnts = new Set<Id>();
            Set<Id> allAcnts = new Set<Id>();
            for (Account a : [select Id from Account where Id = :oppty.AccountId OR ParentId = :oppty.AccountId]){
                acnts.add(a.Id);
                allAcnts.add(a.Id);
            }
            for (Account a : [select Id from Account where ParentId IN :acnts])
                allAcnts.add(a.Id);
            //List<Contact> contacts = [Select Name, Email, Account.Name From Contact Where (AccountId=:oppty.AccountId) OR (Id in :ocrs)];
            List<Contact> contacts = [Select Name, Email, Account.Name, AssistantName from Contact Where (AccountId IN :allAcnts) OR (Account.ParentId in :allAcnts) OR (Id IN :ocrs)];
            /// end mod
            
            for(Contact c : contacts ) {
                Recipient r = new Recipient();
                r.c = c;
                for( OpportunityContactRole ocr : opptyroles ) {
                    if( ocr.ContactId == c.Id ) {
                        r.opptyRole = ocr.Role;
                    }
                }
                r.recipientType = RECIPIENT_TYPE_SIGNER;
                retVal.add(r);
            }
        }
        catch(Exception e) {
            system.debug('unable to load recipients');
            system.debug(e);
        }       
             
        return retVal;
    }
    
    public static List<Recipient> LoadRecipients(Pricing_Agreement__c acc) {
        List<Recipient> retVal = new List<Recipient>();
        
        if( acc.Account__c == null )
            return retVal;
        
        try {
    		List<AccountContactRole> accountroles = [Select ContactId, Role From AccountContactRole Where AccountId=:acc.Account__c];
            List<Contact> contacts = [Select Name, Email, Account.Name, AssistantName from Contact Where AccountId=:acc.Account__c];
            
            for(Contact c : contacts ) {
                Recipient r = new Recipient();
                r.c = c;
                for( AccountContactRole acr : accountroles ) {
                    if( acr.ContactId == c.Id ) {
                        r.accRole = acr.Role;
                    }
                }
                r.recipientType = RECIPIENT_TYPE_SIGNER;
                retVal.add(r);
            }
        }
        catch(Exception e) {
            system.debug('unable to load recipients');
            system.debug(e);
        }       
             
        return retVal;
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_GlobalUtilities(); }
}