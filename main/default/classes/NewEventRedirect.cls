public with sharing class NewEventRedirect implements TestUtils.ITestableClass {

    /******** Properties ********/
    public String sourceId {get; set;}
    public String sourceObjType {get; set;}
    public ID id {get; set;}

    /******** Event Fields ******/
    private String subject {get; set;}
    private String location {get; set;}
    private String onyxId {get; set;}
    private String participant {get; set;}
    private String priPhone {get; set;}
    
    /****** objects to hydrate ***/
    public Account acct {get; set;}
    public Contact ct {get; set;}
    public Account relatedAcct {get; set;}
    public Lead ld {get; set;}
    
    private final Event event {get; set;}
    /****** End Properties ******/

    /*********** ctor ***********/    
    public newEventRedirect(ApexPages.StandardController controller) {
       this.event = (Event)controller.getRecord();
    }
    
    /*********** end ctor ***********/
    public Pagereference newEvent(){
        sourceId = !test.isRunningTest() ? ApexUtils.captureIdByPostion(ApexUtils.getParam('retURL'), 0) : sourceId;
                    
        sourceObjType = SchemaUtils.GetSObjectNameByID(sourceId);
        Boolean result = setPropByObjType();
             
        Pagereference pRef = new Pagereference('/00U/e?');
    
        if(sourceObjType == 'Contact' || sourceObjType == 'Lead')
            pRef.getParameters().put('who_id', sourceId);
        else
            pRef.getParameters().put('what_id', sourceId);
            
            pRef.getParameters().put('retURL', sourceId);
            pRef.getParameters().put('evt5', subject);
            pRef.getParameters().put('evt12', location);
            pRef.getParameters().put('evt6', getFormattedDescription());
            pRef.getParameters().put('00NC0000005Haz3', onyxId);
            pRef.getParameters().put('nooverride', '1');
            pRef.setRedirect(false);
                        
            return pRef; 
    }
    
    private Boolean setPropByObjType(){
        
        if(!String.IsEmpty(sourceObjType)){
            if(sourceObjType == 'Account'){        
            acct = null;
            List<Account> resultAccounts = [SELECT Id, Name, Phone, BillingCity, BillingCountry, BillingState, BillingStreet, 
                                            BillingPostalCode, OnyxCompanyID__c, ParentId FROM Account WHERE Id =: sourceId limit 1];
                                            
            if(resultAccounts.size() > 0){
                acct = resultAccounts.get(0); 
                
                this.loadProperties(acct.Name, formatAddress(acct.BillingStreet, acct.BillingCity, acct.BillingState, acct.BillingPostalCode), 
                                    acct.OnyxCompanyID__c, acct.Name, acct.Phone);               
                }   
            }
            
            if(sourceObjType == 'Contact'){        
            ct = null;
            List<Contact> resultCt = [SELECT AccountId, AssistantName, AssistantPhone, Phone, Description, Id, Department, 
                                        Email, FirstName, Name, HomePhone, LastName, MailingCity, MailingCountry, MailingState, 
                                        MailingStreet, MailingPostalCode, MasterRecordId, MobilePhone, OnyxIndividualID__c, 
                                        OwnerId, Salutation, Title FROM Contact where Id =: sourceId limit 1];
                                        
            if(resultCt.size() > 0){ 
                ct = resultCt.get(0);
                
                this.loadProperties(ct.Name, formatAddress(ct.MailingStreet, ct.MailingCity, ct.MailingState, ct.MailingPostalCode),
                                    ct.OnyxIndividualID__c, ct.Name,  !String.IsEmpty(ct.Phone) ? ct.Phone : ct.MobilePhone); 
                }   
            }
            
            if(sourceObjType == 'Opportunity'){        
            relatedAcct = null;
            
            //get related account, using relationship            
            Account resultRelAccount = ([SELECT Account.Name, Account.BillingStreet, Account.BillingCity, 
                                                Account.BillingState, Account.BillingPostalCode, Account.OnyxCompanyID__c,
                                                Account.Phone FROM Opportunity where Id =: sourceId limit 1].Account);
                                                    
            if(resultRelAccount != null){ 
                relatedAcct = resultRelAccount; 
                
                this.loadProperties(relatedAcct.Name, 
                                    formatAddress(relatedAcct.BillingStreet, relatedAcct.BillingCity, relatedAcct.BillingState, relatedAcct.BillingPostalCode), 
                                    relatedAcct.OnyxCompanyID__c, relatedAcct.Name, relatedAcct.Phone);
                }   
            }
            
            if(sourceObjType == 'Lead'){           
            ld = null;
            List<Lead> resultLd = [SELECT City, Company, ConvertedAccountId, ConvertedContactId, Country, Description, Email, 
                                    FirstName, Name, LastName, Id, MobilePhone, OnyxCompanyID__c, OwnerId, Phone, Salutation, 
                                    State, Status, Street, Title, PostalCode FROM Lead WHERE Id =: sourceId limit 1];
                                    
            if(resultLd.size() > 0){ 
                ld = resultLd.get(0);
                
                this.loadProperties(ld.Company, formatAddress(ld.Street, ld.City, ld.State, ld.PostalCode), ld.OnyxCompanyID__c, ld.Name, ld.Phone);
                }   
            }
            return true;
        }
        return false;       
    }
    
    private void loadProperties(String sub, String loc, String onyx, String participant, String phone){
        this.subject = sub;
        this.location = loc;
        this.onyxId = onyx;
        this.participant = participant;
        this.priPhone = phone;
    }
    
    private String getFormattedDescription(){  
        String phone = !String.IsEmpty(this.priPhone) ? ' - ' + this.priPhone : '';
        return 'Attendees:\n' + UserInfo.getName() + '\n' + this.participant + phone + '\n\n' + 'Meeting Agenda:'; 
    }
   
      private String formatAddress(String street, String city, String state, String postalCode){
        
        String addy = null;             
        addy =  !String.IsEmpty(street) ? street + ' ' : '';
        addy += !String.IsEmpty(city) ? city + ' ' : '';
        addy += !String.IsEmpty(state) ? state + ', ' : '';
        addy += !String.IsEmpty(postalCode) ? postalCode : '';
        
        return addy;
    }
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_NewEventRedirect(); }
}