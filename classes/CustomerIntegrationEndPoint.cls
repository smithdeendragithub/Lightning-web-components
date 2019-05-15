global class CustomerIntegrationEndPoint {
    
   webservice static Integer integrateAccounts(Integer NumberOfAccounts, Boolean Billable) {
 
        List<Account> aList = [SELECT Id, Customer_Detail__c, 
                               (select Id, Customer_Detail__c from Account_Locations__r where ICC_Subscriber_ID__c = null and Customer_Detail__c != null), 
                               (select Id from Account_Based_Orders__r where RecordType.DeveloperName = 'Integration_Only_Order')
                              FROM Account where ICC_Account_Number__c = null and Customer_Detail__c != null 
                               	and Customer_Detail__r.Market_Area__r.Name = 'National' and CreatedById = '005C0000003NsFa' 
                                and Customer_Detail__r.Billable__c =: Billable
                                limit :NumberofAccounts];
    
        Set<Id> customerDetailIDs = new Set<Id>();
        Map<Id, Id> orderIDsByLocationID = new Map<Id, Id>();

        for(Account a : aList){
            if(a.Account_Locations__r.size() > 0 && a.Account_Based_Orders__r.size() > 0){
                for(Service_Location__c sLoc : a.Account_Locations__r) {
                    customerDetailIDs.add(a.Customer_Detail__c); 
                    customerDetailIDs.add(sLoc.Customer_Detail__c); 
                    orderIDsByLocationID.put(sLoc.Id, a.Account_Based_Orders__r[0].Id); 
                }
            }
        }

        //Integrate
        if(orderIDsByLocationID.size() > 0){
            List<string> errors = new List<string>{};
            If (!Test.isRunningTest())
             	errors = IntegrationUtils.createSubscribersFromOrderRelatedServiceLocations(orderIDsByLocationID, UserInfo.getSessionId());
            for(String error : errors) {
				system.debug(error);
            }
    	}
        
        return aList.size();
    }

	webservice static Integer integrateAccountServiceLocations(String AccountSFID, Boolean doBillable) {
 
        List<Customer_Detail__c> cdList = [SELECT id 
                      FROM Customer_Detail__c 
                      WHERE Parent_Account__c =: AccountSFID 
                      	AND ICC_Subscriber_ID__c = null
                        AND Billable__c =: doBillable
                      LIMIT 1];
    
        for (Customer_Detail__c cd: cdList) {
            Map<Id, Id> orderIDsByServiceLocationID = new Map<Id, Id>();
            
            Set<Id> sLocIDs = new Set<Id>();
            for(Service_Location__c sLoc : [select Id, Parent_Service_Location__c, Parent_Service_Location__r.Parent_Service_Location__c from Service_Location__c where Customer_Detail__c =: cd.id]){
                for(Id id : new List<Id>{ sLoc.Id, sLoc.Parent_Service_Location__c, sLoc.Parent_Service_Location__r != null ? sLoc.Parent_Service_Location__r.Parent_Service_Location__c : null }){
                    if(id != null) sLocIDs.add(id);
                }
            }
    
            for(Id sLocID : sLocIDs)
        		orderIDsByServiceLocationID.put(sLocID, null);
            
    		List<string> errors = new List<string>{};
            If (!Test.isRunningTest() && orderIDsByServiceLocationID.size() > 0)
            	errors = IntegrationUtils.createSubscribersFromOrderRelatedServiceLocations(orderIDsByServiceLocationID, UserInfo.getSessionId());
            for(String error : errors) {
				system.debug(cd.id + ' ' + error);
            }
    	}
        
        return cdList.size();
    }
 
    webservice static Integer integrateServiceLocation(Boolean doBillable, Boolean doNational) {
 
        List<Customer_Detail__c> cdList = new List<Customer_Detail__c>{};
        
        if (doNational)    
            cdList = [SELECT id FROM Customer_Detail__c WHERE ICC_Subscriber_ID__c = null
                        AND Billable__c =: doBillable and Market_Area__r.Name = 'National'
                        AND (Parent_Account__r.Customer_Detail__r.Integration_Status__c = 'Draft' OR Parent_Account__r.Customer_Detail__r.Integration_Status__c = 'Active') LIMIT 1];
    	else
            cdList = [SELECT id FROM Customer_Detail__c WHERE ICC_Subscriber_ID__c = null
                        AND Billable__c =: doBillable and Market_Area__r.Name != 'National' 
                        AND (Parent_Account__r.Customer_Detail__r.Integration_Status__c = 'Draft' OR Parent_Account__r.Customer_Detail__r.Integration_Status__c = 'Active') LIMIT 1];
 
        for (Customer_Detail__c cd: cdList) {
            Map<Id, Id> orderIDsByServiceLocationID = new Map<Id, Id>();
            Set<Id> sLocIDs = new Set<Id>();
            for(Service_Location__c sLoc : [select Id, Parent_Service_Location__c, Parent_Service_Location__r.Parent_Service_Location__c from Service_Location__c where Customer_Detail__c =: cd.id]){
                for(Id id : new List<Id>{ sLoc.Id, sLoc.Parent_Service_Location__c, sLoc.Parent_Service_Location__r != null ? sLoc.Parent_Service_Location__r.Parent_Service_Location__c : null }){
                    if(id != null) sLocIDs.add(id);
                }
            }
    
            for(Id sLocID : sLocIDs)
        		orderIDsByServiceLocationID.put(sLocID, null);
            
            List<string> errors = new List<string>{};
            If (!Test.isRunningTest() && orderIDsByServiceLocationID.size() > 0)
            	errors = IntegrationUtils.createSubscribersFromOrderRelatedServiceLocations(orderIDsByServiceLocationID, UserInfo.getSessionId());

            for(String error : errors) {
				system.debug(cd.id + ' ' + error);
            }
    	}
        
        return cdList.size();
    }    
}