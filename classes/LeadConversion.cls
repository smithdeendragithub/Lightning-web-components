global without sharing class LeadConversion{
    global class convertLeadResult{
        webservice String error {get;Set;}
        webService Id oppid {get;Set;}
        public convertLeadResult(String e, Id oid){
            error = e;
            oppid = oid;
        }
    }
    webservice static convertLeadResult convertLead(Id leadId,string leadEmail,Id relatedAccountID,Boolean readyToConvert){
        List<Contact> contacts = [Select id From Contact where AccountID = :relatedAccountID and email=:leadEmail limit 1];
                    
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setConvertedStatus('Converted');
        lc.setAccountId(relatedAccountID);
        lc.setOwnerId(UserInfo.getUserId());
        if(contacts.size() > 0)
            lc.setContactId(contacts[0].Id);
        try{
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            return new convertLeadResult(lcr.getErrors().size() > 0 ? lcr.getErrors()[0].getMessage() : '', lcr.getOpportunityId());
        }
        catch(DmlException e) {
            return new convertLeadResult('Failed to convert lead. ' + e.getMessage() ,null);
        }            
        
    }

}