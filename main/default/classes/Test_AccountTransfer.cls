@isTest
public with sharing class Test_AccountTransfer extends TestUtils.TestClass {

    static testMethod void testController() {
        Mocks testData = new Mocks();
        
        User toOwner = [select Id from User where UserType LIKE:'%Standard%' and IsActive = true limit 1];
        User fromOwner = [select Id from User where UserType LIKE:'%Standard%' and IsActive = true and Id !=: toOwner.Id limit 1];
        
        Account a1 = getAccount(toOwner.Id);
        Account a2 = getAccount(fromOwner.Id);
        Service_Location__c sLoc = getServiceLoc(a2.Id, testData.loc.Id, fromOwner.Id);
        
        insert new List<AccountTeamMember>{new AccountTeamMember(UserId = toOwner.Id, AccountId = a1.Id, TeamMemberRole = ICCWrapper.roleAccountConsultant)
                                        ,new AccountTeamMember(UserId = fromOwner.Id, AccountId = a2.Id)};
        
        test.starttest();
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.parentAccount);
        AccountTransferController atc = new AccountTransferController();
        
        atc.toAccount = a1;
        atc.fromAccount = a2;
        
        Account_Partner__c ap = new Account_Partner__c();
        ap.Account__c = a2.id;
        ap.Partner__c = a2.id;
        
        insert ap;
        
        atc.fromLoc.Owner__c = fromOwner.Id;
        atc.search();
        
        atc.toLoc.Owner__c = toOwner.Id;
        atc.ownerChanged();
        
        Accounttransfercontroller.accountWrapper aw1 = new Accounttransfercontroller.AccountWrapper(a2);
        aw1.selected = true;
        Accounttransfercontroller.serviceLocationWrapper slw1 = new Accounttransfercontroller.ServiceLocationWrapper(sLoc);
        slw1.selected = true;
        atc.accounts = new List<Accounttransfercontroller.accountWrapper>{aw1};
        atc.sLocs = new List<Accounttransfercontroller.serviceLocationWrapper>{slw1};
        
        atc.toPartner.Partner__c = a2.Id;
        atc.transferOwnership();
        
        atc.toCAM.UserId = toOwner.Id;
        atc.toCAM.TeamMemberRole = ICCWrapper.roleCustomerAccountManager;
        atc.transferCAM();
        
        system.debug(atc.getTestClass());
    }
    
    static testMethod void testBatch_CalculateAccountOwnership(){
        Mocks testData = new Mocks();
        
        User toOwner = [select Id from User where UserType LIKE:'%Standard%' and IsActive = true limit 1];
        
        Account a = getAccount(toOwner.Id);
        
        Database.executeBatch(new Batch_CalculateAccountOwnership(new Set<Id>{a.Id}), Batch_CalculateAccountOwnership.DefaultBatchSize);
    }
    
    private static Account getAccount(Id ownerID){
        Account a = new Account(Name='Account', OwnerId=ownerID, ShippingStreet='1', ShippingCity='Nowhwere', ShippingCountryCode = 'US', ShippingState='WA', ShippingPostalCode='12345', Phone='(000) 000-0000', Industry='Z - Unclassified');
        insert a;
        return a;
    }
    
    private static Service_Location__c getServiceLoc(Id accountID, Id locationID, Id ownerID){
        Service_Location__c sLoc = new Service_Location__c(Name='Service Loc', Account__c=accountID, Location__c=locationID, Owner__c=ownerID, Phone__c='(000) 000-0000');
        insert sLoc;
        return sLoc;
    }
}