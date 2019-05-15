@isTest
public with sharing class Test_DocuSignCredentialAPI {

    static testMethod void testAPI() {
       	new DocuSignCredentialAPI();
		new DocuSignCredentialAPI.LoginResult_element();
		//new DocuSignCredentialAPI.RequestCorrectToken_element();
		//new DocuSignCredentialAPI.PingResponse_element();
		new DocuSignCredentialAPI.ArrayOfAccount();
		new DocuSignCredentialAPI.Account_element();
		//new DocuSignCredentialAPI.Ping_element();
		//new DocuSignCredentialAPI.GetAuthenticationToken_element();
		//new DocuSignCredentialAPI.RequestCorrectTokenResponse_element();
		new DocuSignCredentialAPI.Login_element();
		new DocuSignCredentialAPI.LoginResponse_element();
		//new DocuSignCredentialAPI.GetAuthenticationTokenResponse_element();
		//new DocuSignCredentialAPI.RequestSenderTokenResponse_element();
		//new DocuSignCredentialAPI.RequestSenderToken_element();
		
		DocuSignCredentialAPI.CredentialSoap client = new DocuSignCredentialAPI.CredentialSoap();
		//try { client.GetAuthenticationToken(null, null, null, null); } catch(Exception e){}
		try { client.Login(null, null); } catch(Exception e){}
		//try { client.Ping(); } catch(Exception e){}
		//try { client.RequestCorrectToken(null, null, null, null, null); } catch(Exception e){}
		//try { client.RequestSenderToken(null, null, null, null, null); } catch(Exception e){}
    }
}