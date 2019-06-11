@isTest
public with sharing class Test_DocuSignService {
	
    static testMethod void testAPI() {
    	try { new DocuSignService(null,'','','','','',''); } catch(Exception e) {}
        DocuSignService docuSignService = new DocuSignService('','','','','','','');
        try { docuSignService.addCurrentUserAsAccountMember(); } catch(Exception e) {}
        try { docuSignService.authenticateUser('', ''); } catch(Exception e) {} 
        try { docuSignService.isCurrentUserAnAccountMember(); } catch(Exception e) {} 
        try { docuSignService.isCurrentUserAnActiveCompanyMember(); } catch(Exception e) {}

        try { docuSignService.authenticateUser(null, ''); } catch(Exception e) {} 
        try { docuSignService.isUserAnAccountMember(null); } catch(Exception e) {} 
    }
}