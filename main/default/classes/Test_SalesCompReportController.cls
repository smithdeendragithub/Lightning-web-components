@isTest
public with sharing class Test_SalesCompReportController extends TestUtils.TestClass {
    private static List<User> users = null;    
    
    private static void getTestData(){
        users = getUserList();
        
        Account acct =  new Account(Name = 'parent1'
                                    ,ShippingCountry = 'US'
                                    ,ShippingState = 'OR'
                                    ,ShippingCity = 'Portland'
                                    ,ShippingPostalCode = '97124'
                                    ,ShippingStreet = '1234 Test'
                                    ,Phone = '800-123-1234'
                                    ,Industry = 'Z - Unclassified'
                                    , OwnerId = users[0].Id);
        insert acct;
        Contact ct = new Contact(LastName='test', email='test@test.com', AccountId=acct.Id, Title = 'test', Phone = '5555555555');
        insert ct;
        Id typeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Retail').getRecordTypeId();
            
        Opportunity oppt = new Opportunity(OwnerId = users[0].Id
            ,RecordTypeId = typeid
            ,AccountId = acct.Id
            ,LeadSource = 'Jigsaw'
            ,Term__c = '36'
            ,Name = 'Acme Explosives 2'
            ,CloseDate = date.today().addDays(10)
            ,Amount = 243.39
            ,Split_Owner_1__c = users[0].Id
            ,Split_Owner_2__c = users[1].Id
            ,Split_Percent_1__c = 20
            ,Split_Percent_2__c = 80
            ,ForecastCategoryName = 'Pipeline'   
            ,StageName = 'Stage 4 - Contract Signed / Won'
            ,Customer_Requested_Due_Date__c = date.today().addDays(-2)
            ,Contract_Signed_Date__c = date.today().addDays(-1)
            ,Proposal_Meeting_Held_Date__c = date.today().addDays(-1)
            ,Initial_Appointment_Held_Date__c =date.today().addDays(-5)
            ,Initial_Appointment_Set_Date__c = date.today().addDays(-5)
            ,Proposal_Meeting_Set_Date__c = date.today().addDays(-2)
            ,LOA_Signed_By__c =   ct.Id
            ,Opportunity_Product__c = 'test product');
        insert oppt; 

        List<Order__c> orders  = [Select Id, Opportunity__c from Order__c where Opportunity__c  =:oppt.Id];
        Order__c tO = orders[0]!= null?orders[0]:new Order__c(Opportunity__c = oppt.Id);
        tO.Credit_Check_Approval__c = 'Credit Approved';
        tO.Credit_Commitment_Met__c = Date.today();        
        to.Order_Pending_Date__c = Date.today().addDays(-1);
        to.Status__c = 'Order Accepted';
        if(orders[0]!=null){
            update tO;
        }else{
            insert tO;
        }

        Market_Area__c marketArea = new Market_Area__c(Name='asdf', MarketAreaExternalId__c='qwer1234', ICCMarketAreaID__c=1);
		insert marketArea;
        Building__c building = new Building__c(Address__c = '1234 fake st'
        									,City__c = 'Coolsville'
                                            ,Country__c = 'US'
        									,State__c = 'OR'
        									,Postal_Code__c = '12345'
        									,Market_Area__c = marketArea.Id
											,Latitude__c = 45.5000
											,Longitude__c = -120.000
											,Net_Classification__c = 'On-net'
											,Building_Type__c = 'Commercial Building');
    	insert building;
        Location__c loc  = new Location__c(Building__c = building.Id);
    	insert loc;
        Service_Location__c sLoc = new Service_Location__c(Account__c = acct.Id, Name = 'Test Loc', Location__c = loc.Id);
		insert sLoc;

		RecordType oppProdManual = [select Id from RecordType where sObjectType='Opportunity_Product__c' and DeveloperName='Manual_Entry'];
	 	Opportunity_Product__c oppProd = new Opportunity_Product__c(Opportunity__c=oppt.Id, Primary_Service_Location__c=sLoc.Id, Sales_Product__c='Some Product', RecordTypeId=oppProdManual.Id,  Active__c = true);
		insert oppProd;        
    }
    static List<User> getUserList(){    
        List<User> users = ([SELECT IsActive, Name, Id FROM User WHERE IsActive = true and  profile.Name = 'Sales' limit 2]);
        
        return (users.size() > 0) ? users : null;    
    }    
    
    static testmethod void testGenerateReport(){
        getTestData();
        Test.startTest();      

        SalesCompReportController  scrc = new SalesCompReportController();        
        scrc.startDate = Date.toDay().addDays(-2);
        scrc.endDate = Date.toDay().addDays(3);
        scrc.generateReport();
        
        Test.stopTest();        
    }
    
    static testmethod void testGenerateReportForSplit(){
        getTestData();
        Test.startTest();       

        SalesCompReportController  scrc = new SalesCompReportController();
        scrc.startDate = Date.toDay().addDays(-2);
        scrc.endDate = Date.toDay().addDays(3);
        scrc.generateReportForSplit();
        
        Test.stopTest();        
    }
}