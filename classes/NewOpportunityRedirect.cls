public with sharing class NewOpportunityRedirect implements TestUtils.ITestableClass {
    
    /******** properties ********/
    public String sourceId {get; set;}
    private final ID rType {get; set;}
    private final Opportunity oppt {get; set;}
    
    private String OpptName {get; set;}
    
    private String accountId {
        get { 
                if(accountId.length() > 15)
                    return accountId.substring(0, 15);
                else
                    return accountId; 
            }
        set { accountId = value; }
    }
    
    /*********** ctor ***********/      
    public newOpportunityRedirect(ApexPages.StandardController controller) {        
        this.oppt = (Opportunity)controller.getRecord();
        rType = ApexUtils.getParam('RecordType');
    }
    
    /*********** action ***********/
    public Pagereference newOpportunity(){
        sourceId =  !test.isRunningTest() ? ApexUtils.captureIdByPostion(ApexUtils.getParam('retURL'), 0) : sourceId;
        Pagereference opptRef = new Pagereference('/006/e?');
        
        if(ApexUtils.isValidId(sourceId)){             
            if(setPropByObj(sourceId)){
                            
                if(!String.IsEmpty(OpptName))
                    opptRef.getParameters().put('opp3', OpptName);          
                
                opptRef.getParameters().put('accid', accountId);    
            }     
                
            opptRef.getParameters().put('retURL', sourceId);                                
        }
        
        opptRef.getParameters().put('nooverride', '1');
        opptRef.getParameters().put('RecordType', rType);
        
        //so, i guess i'll just add other potential options here... i don't like this at all.
        String caseId = ApexUtils.getParam('CF00N1A000006ZXt4_lkid');
        String caseNumber = ApexUtils.getParam('CF00N1A000006ZXt4');
        if(!String.isEmpty(caseId) && !String.isEmpty(caseNumber)){
            opptRef.getParameters().put('CF00N1A000006ZXt4_lkid', caseId);
            opptRef.getParameters().put('CF00N1A000006ZXt4', caseNumber);   
        }
        return opptRef;
    }

    /*********** utility ***********/
    private Boolean setPropByObj(string id){
        
        List<Account> rootAccount = new List<Account>();
        
        string typename = SchemaUtils.GetSObjectNameByID(id);
            
        if(typename == 'Account')
            rootAccount = ([SELECT Id, Name FROM Account where Id =: id limit 1]);
        else if(typename == 'Opportunity')          
            rootAccount.add([SELECT Account.Id, Account.Name FROM Opportunity where Id =: id limit 1].Account);
        else
            return false;
                                              
        if(rootAccount.size() > 0){
            Account acct = rootAccount.get(0); 
            this.OpptName = acct.Name;
            this.accountId = acct.Id;
            return true;
        }   
        return false;
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_NewOpportunityRedirect(); }
}