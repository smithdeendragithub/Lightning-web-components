public class GlobysTransactionController {
/*
 * new customer detail and legacy id populated for first time - send linkage request
 * legacy id removed - send unlink request - maybe send link using ICC subscriber id
 * legacy id changed - send unlink and link requests
 * bpid on current parent is changed - send unlink and link for all child service locations
 * bpid on parent is blanked - send unlink for all service locations
 * market area changed from national to non-national and vise-versa
 * when customer detail is first integrated, need to send all the link information for first time
 */
    public static final String DEFAULT_STATUS = 'Pending';
 
    private static Id zMarketAreaNational = null;
	public static Id MarketAreaNational{
		get{
            if (UserInfo.getOrganizationId() == '00Dm000000055agEAA') {
				//This id will change each time the sandbox is refreshed and is unique to the sandbox
                zMarketAreaNational = 'a0Jm0000006odFs';
            } 
            else
                zMarketAreaNational = 'a0JC000000ESX5W';
                
            return zMarketAreaNational;
		}
	}
    
    public static void processCustomerDetailChanges(List<Customer_Detail__c> tNew, Map<Id, Customer_Detail__c> tOldMap, Boolean isDelete) {
        List<Globys_Transaction__c> insertGT = new List<Globys_Transaction__c>();
        Map<Id, List<Customer_Detail__c>> childCDs = new Map<Id, List<Customer_Detail__c>>();
        Map<Id, List<Customer_Detail__c>> parentCDs = new Map<Id, List<Customer_Detail__c>>();
           
        for (Customer_Detail__c cDetail: tNew) {
            if (cDetail.ICC_Subscriber_ID__c == null) continue; // we don't care until the cd is integrated

            Customer_Detail__c oldDetail = tOldMap.get(cDetail.Id);
            if (cDetail.Market_Area__c != MarketAreaNational && oldDetail.Market_Area__c != MarketAreaNational) continue; //only applies to National
            //let's think about a billable parent that is integrated where a non-billable parent is added above.
            //For the original parent, it would not have a parent_customer__r originally but now does
            //If that is the case, there is nothing to unlink but we need to create a link from original parent to
            //the new non-billable grandparent.
            if (cDetail.Parent_Customer__c == null && oldDetail.Parent_Customer__c != null && cDetail.Billable__c == true) {
            	//change parent was done and this customer detail is now a new account structure
            	//just unlink the old relationship for now
                parentCDs.put(oldDetail.Parent_Customer__c, new List<Customer_Detail__c>());
            } else if (cDetail.Parent_Customer__c == null) { //this is the CD associated directly to the account
            	childCDs.put(cDetail.id, new List<Customer_Detail__c>());
            } else { //we are working with billable parents, we don't want non-billable children
                if (cDetail.Billable__c == true) {
                	parentCDs.put(cDetail.parent_customer__c, new List<Customer_Detail__c>());
                    if (cDetail.parent_customer__c != oldDetail.Parent_Customer__c && oldDetail.Parent_Customer__c != null)
                        parentCDs.put(oldDetail.Parent_Customer__c, new List<Customer_Detail__c>());
                }
            }
        }

        if (childCDs.size() > 0) {
            //okay we have a list of ids of top level customer details, now we need all their children
            for (Customer_Detail__c childCD: [SELECT id, Acquired_Company_Biller__c, Legacy_ID__c, Parent_Customer__c, ICC_Subscriber_ID__c FROM Customer_Detail__c where ICC_Subscriber_ID__c != null AND Parent_Customer__c in : childCDs.keyset()]) {
                List<Customer_Detail__c> cds = childCDs.get(childCD.Parent_Customer__c);
                cds.add(childCD);
                childCDs.put(childCD.Parent_Customer__c, cds);
            }
        }

        if (parentCDs.size() > 0) {
            //okay we have a list of ids of billable parents, we need to get their parent customer details.
            for (Customer_Detail__c parentCD: [SELECT id, BPID__c, ICC_Subscriber_ID__c FROM Customer_Detail__c where ICC_Subscriber_ID__c != null AND id in : parentCDs.keyset()]) {
                List<Customer_Detail__c> cds = parentCDs.get(parentCD.id);
                cds.add(parentCD);
                parentCDs.put(parentCD.id, cds);
            }            
        }
        
        for (Customer_Detail__c cDetail: tNew) {
            Customer_Detail__c oldDetail = tOldMap.get(cDetail.Id);
            if (cDetail.Market_Area__c != MarketAreaNational && oldDetail.Market_Area__c != MarketAreaNational) continue; //only applies to National
			If (cDetail.ICC_Subscriber_ID__c == null) continue; //we don't care about non-integrated Customer Details

            if (cDetail.Parent_Customer__c == null && oldDetail.Parent_Customer__c != null) {
                //change parent making this CD a new account structure - unlink from old parent
                insertGT.add(createGlobysTransaction('unlink', 
                                                     oldDetail.Account_Business_Party_ID__c == null ? oldDetail.ICC_Subscriber_ID__c : oldDetail.Account_Business_Party_ID__c, 
                                                     oldDetail.parent_customer__c, 
                                                     cDetail.Legacy_ID__c, 
                                                     cDetail.Id, 
                                                     cDetail.Acquired_Company_Biller__c, 
                                                     oldDetail.Account_Business_Party_ID__c == null ? 'ICCS': 'BPID'));
            } else if (cDetail.Parent_Customer__c == null) {
                if (cDetail.BPID__c != oldDetail.BPID__c || cDetail.Market_Area__c != oldDetail.Market_Area__c || cDetail.ICC_Subscriber_ID__c != oldDetail.ICC_Subscriber_ID__c)
                    insertGT.addall(processBPIDChanges(cDetail, oldDetail, isDelete, childCDs.get(cDetail.id)));
            } else {
                if (cDetail.Legacy_ID__c != oldDetail.Legacy_ID__c || cDetail.Acquired_Company_Biller__c != oldDetail.Acquired_Company_Biller__c || cDetail.Market_Area__c != oldDetail.Market_Area__c || cDetail.ICC_Subscriber_ID__c != oldDetail.ICC_Subscriber_ID__c || cDetail.Parent_Customer__c != oldDetail.Parent_Customer__c)
                    insertGT.addall(processCustomerIdChanges(cDetail, oldDetail, isDelete, parentCDs.get(cDetail.Parent_Customer__c), parentCDs.get(oldDetail.Parent_Customer__c)));
            }
        }
        
        map<String, Globys_Transaction__c> distinctGTs = new map<String, Globys_Transaction__c>{};
        for (Globys_Transaction__c gt: insertGT)
        	distinctGTs.put(gt.Parent_Identifier__c + '-' + gt.Child_Identifer__c + '-' + gt.Action__c, gt);
        insertGT = distinctGTs.values();
            
        insert insertGT;    
        //return insertGT;
    }
    
    
    public static List<Globys_Transaction__c> processBPIDChanges(Customer_Detail__c cDetail, Customer_Detail__c oldDetail, Boolean isDelete, List<Customer_Detail__c> childCDs) {
        //You should only be in this method if the Customer Detail is the one associated directly with the Account.
        //If the BPID has changed here, we map have to unlink all the billable parents and relink them to a differen BPID
        //We also need to consider the market area being change from or to National.
        List<Globys_Transaction__c> insertGT = new List<Globys_Transaction__c>{};
        
        boolean linkMarketArea = false;
        boolean unlinkMarketArea = false;
        String unlinkBPID = null , linkBPID = null;
        String linkParentSource, unlinkParentSource = null;

        //if ICC_Subscriber_ID__c has just been populated, no need to look at anything else, write an link entry
// - commented out because the integration process is creating a duplicate transaction entry when the child integrates.
        if (cDetail.ICC_Subscriber_ID__c != oldDetail.ICC_Subscriber_ID__c) {
            if (cDetail.Account_Business_Party_ID__c == null) {
                linkBPID = cDetail.ICC_Subscriber_ID__c;
                linkParentSource = 'ICCS';
            } else {
                linkBPID = cDetail.Account_Business_Party_ID__c;
                linkParentSource = 'BPID';
            }
        } else if (cDetail.Account_Business_Party_ID__c != oldDetail.Account_Business_Party_ID__c) {
            if (String.isNotBlank(cDetail.Account_Business_Party_ID__c) && String.isBlank(oldDetail.Account_Business_Party_ID__c)) {
                unlinkParentSource = 'ICCS';
                unlinkBPID = cDetail.ICC_Subscriber_ID__c;
                linkBPID = cDetail.Account_Business_Party_ID__c; 
                linkParentSource = 'BPID';
            } else if (String.isBlank(cDetail.Account_Business_Party_ID__c) && String.isNotBlank(oldDetail.Account_Business_Party_ID__c)) {
                unlinkParentSource = 'BPID';
                unlinkBPID = oldDetail.Account_Business_Party_ID__c;
                linkParentSource = 'ICCS';
                linkBPID = cDetail.ICC_Subscriber_ID__c;
            } else {
                linkParentSource = 'BPID';
                linkBPID = cDetail.Account_Business_Party_ID__c;
                unlinkParentSource = 'BPID';                
                unlinkBPID = oldDetail.Account_Business_Party_ID__c;
            }
       
            if (cDetail.Market_Area__c == MarketAreaNational && oldDetail.Market_Area__c != MarketAreaNational )  
                linkMarketArea = true;
            else if (cDetail.Market_Area__c != MarketAreaNational && oldDetail.Market_Area__c == MarketAreaNational ) 
                unlinkMarketArea = true;
    	}
        
        for (Customer_Detail__c childDetail: childCDs) {
            if (unlinkMarketArea == true && oldDetail.id != null)
                insertGT.add(createGlobysTransaction('unlink', oldDetail.Account_Business_Party_ID__c, oldDetail.id, childDetail.Legacy_ID__c, childDetail.Id, childDetail.Acquired_Company_Biller__c, unlinkParentSource));
            else if (linkMarketArea == true)
                insertGT.add(createGlobysTransaction('link', cDetail.Account_Business_Party_ID__c, cDetail.id, childDetail.Legacy_ID__c, childDetail.Id, childDetail.Acquired_Company_Biller__c, linkParentSource));
            else {
                if (linkBPID != null) 
                    insertGT.add(createGlobysTransaction('link', linkBPID, cDetail.id, childDetail.Legacy_ID__c, childDetail.Id, childDetail.Acquired_Company_Biller__c, linkParentSource));    
                if (unlinkBPID != null)
                    insertGT.add(createGlobysTransaction('unlink', unlinkBPID, cDetail.id, childDetail.Legacy_ID__c, childDetail.Id, childDetail.Acquired_Company_Biller__c, unlinkParentSource));
            }
        }
       
        return insertGT;
    }
    
    public static List<Globys_Transaction__c> processCustomerIdChanges(Customer_Detail__c cDetail, Customer_Detail__c oldDetail, Boolean isDelete, List<Customer_Detail__c> parentCDs, List<Customer_Detail__c> oldParentCDs) {

        String linkParentSource, unlinkParentSource = null;
        String linkParentIdentifier, linkParentIdentifierSource = null;
        String unlinkParentIdentifier, unlinkParentIdentifierSource = null;
        
        List<Globys_Transaction__c> insertGT = new List<Globys_Transaction__c>{};
   
		if (parentCDs == null || parentCDs.size() < 1) return insertGT;

        Customer_Detail__c parentCD = parentCDs[0];
        if (String.isBlank(parentCD.BPID__c)) {
			linkParentIdentifier = parentCD.ICC_Subscriber_ID__c;
            linkParentIdentifierSource = 'ICCS';
        } else {
			linkParentIdentifier = parentCD.BPID__c;
            linkParentIdentifierSource = 'BPID';
        }

        if (oldParentCDs != null && oldParentCDs.size() > 0) {
            Customer_Detail__c oldParentCD = oldParentCDs[0];
            if (String.isBlank(oldParentCD.BPID__c)) {
                unlinkParentIdentifier = oldParentCD.ICC_Subscriber_ID__c;
                unlinkParentIdentifierSource = 'ICCS';
            } else {
                unlinkParentIdentifier = oldParentCD.BPID__c;
                unlinkParentIdentifierSource = 'BPID';
            }        
        }
            
        //if this customer detail is no longer National, then remove all information from Globys
        if (oldDetail.Market_Area__c == MarketAreaNational && cDetail.Market_Area__c != MarketAreaNational && oldDetail.Parent_Customer__c != null) 
            insertGT.add(createGlobysTransaction('unlink', unlinkParentIdentifier, oldDetail.Parent_Customer__c, oldDetail.Legacy_ID__c, oldDetail.Id, oldDetail.Acquired_Company_Biller__c, unlinkParentIdentifierSource));    

        //handle change of legacy ids & biller
        if (cDetail.Legacy_ID__c != oldDetail.Legacy_ID__c || cDetail.Acquired_Company_Biller__c != oldDetail.Acquired_Company_Biller__c || cDetail.ICC_Subscriber_ID__c != oldDetail.ICC_Subscriber_ID__c || cDetail.Parent_Customer__c != oldDetail.Parent_Customer__c) {
            String linkBiller, linkLegacyID = null;
            String unlinkBiller, unlinkLegacyID = null;
            if (cDetail.ICC_Subscriber_ID__c != oldDetail.ICC_Subscriber_ID__c) {
            	linkLegacyID = cDetail.Legacy_ID__c;    
                linkBiller = cDetail.Acquired_Company_Biller__c;
            } else {
                if (cDetail.Legacy_ID__c != oldDetail.Legacy_ID__c || cDetail.Parent_Customer__c != oldDetail.Parent_Customer__c) {
                	linkLegacyID = (String.isBlank(cDetail.Legacy_ID__c))  ? cDetail.ICC_Subscriber_ID__c: cDetail.Legacy_ID__c;
                    unlinkLegacyID = (String.isBlank(oldDetail.Legacy_ID__c)) ? oldDetail.ICC_Subscriber_ID__c: oldDetail.Legacy_ID__c;
                }
                
                if (cDetail.Acquired_Company_Biller__c != oldDetail.Acquired_Company_Biller__c && String.isNotBlank(cDetail.Acquired_Company_Biller__c)) {
                    linkBiller = cDetail.Acquired_Company_Biller__c;
                    unlinkBiller = oldDetail.Acquired_Company_Biller__c;
                    
                    linkLegacyID = (String.isBlank(cDetail.Legacy_ID__c))  ? cDetail.ICC_Subscriber_ID__c: cDetail.Legacy_ID__c;
                    unlinkLegacyID = (String.isBlank(oldDetail.Legacy_ID__c)) ? oldDetail.ICC_Subscriber_ID__c: oldDetail.Legacy_ID__c;
                } else if (cDetail.Acquired_Company_Biller__c != oldDetail.Acquired_Company_Biller__c) {
                    linkBiller = (String.isNotBlank(cDetail.Acquired_Company_Biller__c) && String.isBlank(oldDetail.Acquired_Company_Biller__c )) ? cDetail.Acquired_Company_Biller__c: null;
                    unlinkBiller = (String.isBlank(cDetail.Acquired_Company_Biller__c) && String.isNotBlank(oldDetail.Acquired_Company_Biller__c )) ? oldDetail.Acquired_Company_Biller__c: null;
                
                	linkLegacyID = (String.isBlank(cDetail.Legacy_ID__c))  ? cDetail.ICC_Subscriber_ID__c: cDetail.Legacy_ID__c;
                    unlinkLegacyID = (String.isBlank(oldDetail.Legacy_ID__c)) ? oldDetail.ICC_Subscriber_ID__c: oldDetail.Legacy_ID__c;
                }
            }
            
            if (linkLegacyID != unlinkLegacyID || linkBiller != unlinkBiller || linkParentIdentifier != unlinkParentIdentifier || cDetail.ICC_Subscriber_ID__c != oldDetail.ICC_Subscriber_ID__c) {
            	if (linkLegacyID != null || linkBiller != null) 
                	insertGT.add(createGlobysTransaction('link', linkParentIdentifier, cDetail.Parent_Customer__c, linkLegacyID, cDetail.Id, cDetail.Acquired_Company_Biller__c, linkParentIdentifierSource));
            
            	if (unlinkLegacyID != null || unlinkBiller != null &&  oldDetail.Parent_Customer__c != null) 
                	insertGT.add(createGlobysTransaction('unlink', unlinkParentIdentifier, oldDetail.Parent_Customer__c, unlinkLegacyID, cDetail.Id, oldDetail.Acquired_Company_Biller__c, unlinkParentIdentifierSource));
            }
        }       
      
        return insertGT;
    }
    
    public static Globys_Transaction__c createGlobysTransaction(String action, String parentIdentifier, id parentSubscriber, String childIdentifier, id childSubscriber, String biller, String parentIdentifierSource) {
        Globys_Transaction__c gTransaction = new Globys_Transaction__c();
        gTransaction.Action__c = action;
        gTransaction.Child_Identifer__c = childIdentifier;
        if (biller == 'Phoenix')
            gTransaction.Child_Legacy_Biller__c = 'ICCS';
        else 
        	gTransaction.Child_Legacy_Biller__c = biller;
        gTransaction.Child_Subscriber__c = childSubscriber;
        gTransaction.Parent_Identifier__c = parentIdentifier;
        gTransaction.Parent_Subscriber__c = parentSubscriber;
        gTransaction.Parent_Identifier_Source__c = parentIdentifierSource;
        gTransaction.Status__c = DEFAULT_STATUS;
       
        return gTransaction;
    }

    
    
}