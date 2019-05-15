public with sharing class OppProdRecordTypeSelectController implements TestUtils.ITestableClass 
{
    public List<SelectOption> recordTypes {get; set;}
    public Id selectedRecordType {get; set;}
    public Opportunity_Product__c oppProdObj;
    private String wholesaleRecordTypeName {
        get{return Opportunity_Product__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Manual_Entry_Wholesale').getName();}
        set;
    }    
    private String wholesaleRecordTypeId {
        get{return Opportunity_Product__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Manual_Entry_Wholesale').getRecordTypeId();}
        set;
    }
    
    public OppProdRecordTypeSelectController(ApexPages.StandardController controller){
        selectedRecordType = Opportunity_Product__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Manual_Entry').getRecordTypeId();
        recordTypes = new List<SelectOption>();
        List<Schema.RecordTypeInfo> rts = Opportunity_Product__c.sObjectType.getDescribe().getRecordTypeInfos();
        if(rts.size()>0){
            for(Schema.RecordTypeInfo rti : rts){
                if(rti.isAvailable() &&  !String.valueOf(rti.getRecordTypeId()).endsWith('AAA') && rti.getDeveloperName() != 'Manual_Entry_Wholesale'){
                    recordTypes.add(new SelectOption(rti.getRecordTypeId(), rti.getName()));
                }
            }
        }
        oppProdObj = (Opportunity_Product__c)controller.getRecord();
        if(oppProdObj != null && oppProdObj.Opportunity__c != null){
            Opportunity op =[Select Id, Name, Sell_To_Through__c, RecordTypeId, Account.Care_Organization_Name__c from Opportunity where Id = :oppProdObj.Opportunity__c];
            String careOrg = op.Account.Care_Organization_Name__c != null?op.Account.Care_Organization_Name__c:'';
            
            if(op.RecordTypeId == Opportunity.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Wholesale').getRecordTypeId()){
                recordTypes.clear();
                recordTypes.add(new SelectOption(wholesaleRecordTypeId, wholesaleRecordTypeName));
            }else if(op.RecordTypeId == Opportunity.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Retail').getRecordTypeId()
                    && careOrg.toLowerCase().contains('wholesale')
                     && op.Sell_To_Through__c =='Sell Through'){
                recordTypes.clear();
                recordTypes.add(new SelectOption(wholesaleRecordTypeId, wholesaleRecordTypeName));
                recordTypes.add(new SelectOption(Opportunity_Product__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Manual_Turndown').getRecordTypeId()
                              , Opportunity_Product__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Manual_Turndown').getName()));
                

            }
        }
    }
    
    public PageReference continueMethod(){
        PageReference p = new PageReference('/a23/e?');
        p.getParameters().put('CF00NC0000005gStS',ApexPages.currentPage().getParameters().get('CF00NC0000005gStS'));
        p.getParameters().put('CF00NC0000005gStS_lkid',ApexPages.currentPage().getParameters().get('CF00NC0000005gStS_lkid'));        
        p.getParameters().put('retURL', ApexPages.currentPage().getParameters().get('retURL'));
        p.getParameters().put('RecordType',selectedRecordType);        
        p.getParameters().put('ent','Opportunity_Product__c');
        p.getParameters().put('nooverride','1');        
        return p;        
    }

   /* TestUtils.ITestableClass methods */
   public TestUtils.TestClass getTestClass(){ return new Test_OppProdRecordTypeSelectController(); }    
}