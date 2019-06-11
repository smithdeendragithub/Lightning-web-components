@isTest
public with sharing class Test_ServiceLocationExtensionController extends TestUtils.TestClass {
	
	static testMethod void testController(){
        Mocks testData = new Mocks();
		
		Service_Location__c sLoc = testData.serviceLocation;
		
		Test.startTest();
		
		Apexpages.StandardController sc = new Apexpages.StandardController(sLoc);
    	ServiceLocationExtensionController slec = new ServiceLocationExtensionController(sc);
		slec.reactivateLocation();
	}
	
 	static testMethod void testNewCustomerDetails() {
        Mocks testData = new Mocks();
		
		Service_Location__c sLoc = testData.serviceLocation;
		
		Test.startTest();
		
		Apexpages.StandardController sc = new Apexpages.StandardController(sLoc);
    	ServiceLocationExtensionController slec = new ServiceLocationExtensionController(sc);
    	slec.generateDetails();
    	slec = new ServiceLocationExtensionController(sc);
		
		System.debug(slec.getTestClass());
    }
	
 	static testMethod void testCloneParentCustomerDetails() {
        Mocks testData = new Mocks();
		
		Service_Location__c sLoc = testData.serviceLocation;
		
		Test.startTest();
		
		Apexpages.StandardController sc = new Apexpages.StandardController(sLoc);
    	ServiceLocationExtensionController slec = new ServiceLocationExtensionController(sc);
		
		CustomerDetailUtils.updateCustomerDetails(new List<Set<Id>>{new Set<Id>{sLoc.Account__c}}, null);
		
    	PageReference pageReference = Page.ServiceLocationExtensionController;
        pageReference.getParameters().put('cloneFromParent', 'true');
        Test.setCurrentPage(pageReference);
		
    	slec.generateDetails();
    	slec = new ServiceLocationExtensionController(sc);
		
		System.debug(slec.getTestClass());
    }
		
	static testMethod void testMove(){
        Mocks testData = new Mocks();
		
		Service_Location__c sLoc = testData.serviceLocation;
		sLoc.Billable__c = true;
		update sLoc;
		
		CustomerDetailUtils.updateCustomerDetails(new List<Set<Id>>{new Set<Id>{sLoc.Account__c}, new Set<Id>{sLoc.Id}}, null);
		
		List<Customer_Detail__c> cdList = [select Id from Customer_Detail__c];
		for(Integer i=0; i<cdList.size(); i++){
			cdList[i].ICC_Subscriber_ID__c = String.valueOf(-999 - i);
		}
		update cdList;
		
		sObjectType sLocType = Service_Location__c.getsObjectType();
		sLoc = ((List<Service_Location__c>)ApexUtils.retrieveFullObjects(sLocType, 'Id = \'' + sLoc.Id + '\''))[0];
		
		Account a = [select Id, ICC_Account_Number__c, Customer_Detail__c from Account where Id =: sLoc.Account__c];
		a.Billable__c = false;
		update a;
		
		AccountTeamMember atm = new AccountTeamMember(AccountId = a.Id
													,TeamMemberRole = ICCWrapper.roleCustomerAccountManager
													,UserId = testData.user.Id);
		insert atm;
		
		Contact c = testData.parentAccountContact;
		Customer_Contact__c cc = new Customer_Contact__c(Contact__c=c.Id
														,Contact_Type__c='Type'
														,Customer_Detail__c=sLoc.Customer_Detail__c);
		insert cc;
		
		Test.startTest();
		
		Apexpages.StandardController sc = new Apexpages.StandardController(sLoc);
    	ServiceLocationExtensionController slec = new ServiceLocationExtensionController(sc);
		System.assert(slec.canMove, 'Service location cannot be moved');
		
    	PageReference pageReference = Page.ServiceLocationExtensionController;
        //pageReference.getParameters().put('id', sLoc.Id);
        Test.setCurrentPage(pageReference);
		
		//Detach
        pageReference.getParameters().put('parentSubscriberID', '');
		slec.move();
		System.assert([select Account__c from Service_Location__c where Id =: sLoc.Id].Account__c != a.Id, 'Service location did not detach');
		
		//Attach/merge
		sc = new Apexpages.StandardController(sLoc);
    	slec = new ServiceLocationExtensionController(sc);
		System.assert(slec.canMove, 'Service location cannot be moved');
		
		pageReference.getParameters().clear();
        pageReference.getParameters().put('parentSubscriberID', a.ICC_Account_Number__c);
		slec.move();
	}
	
	public static List<integraWS.SFSubscriberView> simulateHierarchyUpdate(Map<Integer, Integer> parentSubscriberIDBySubscriberID){
		Set<String> ids = new Set<String>();
		for(Integer i : parentSubscriberIDBySubscriberID.keySet())
			ids.add(String.valueOf(i));
		
		for(Integer i : parentSubscriberIDBySubscriberID.values()){
			if(i != null)
				ids.add(String.valueOf(i));
		}
		
		List<Service_Location__c> sLocs = [select Id, Account__r.Id, Account__r.ICC_Account_Number__c, ICC_Subscriber_ID__c from Service_Location__c where ICC_Subscriber_ID__c in: ids];
		
		List<integraWS.SFSubscriberView> results = new List<integraWS.SFSubscriberView>();
		Map<Id, Account> accounts = new Map<Id, Account>();
		for(Service_Location__c sLoc : sLocs){
			accounts.put(sLoc.Account__r.Id, sLoc.Account__r);
			
			integraWS.SFSubscriberView r = new integraWS.SFSubscriberView();
			r.SubscriberID = Integer.valueOf(sLoc.ICC_Subscriber_ID__c);
			r.SalesforceID = sLoc.Id;
			r.SubscriberType = 'SubType';
			results.add(r);
		}
		
		for(Account acc : accounts.values()){
			integraWS.SFSubscriberView r = new integraWS.SFSubscriberView();
			r.SubscriberID = Integer.valueOf(acc.ICC_Account_Number__c);
			r.SalesforceID = acc.Id;
			r.SubscriberType = 'SubType';
			results.add(r);
		}
		
		return results;
	}
}