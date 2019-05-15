@isTest
public with sharing class Test_DocuSignAPI {

    static testMethod void testAPI() {
     
	    new DocuSignAPI();
	    //new DocuSignAPI.EnvelopeInformation();
	    //new DocuSignAPI.ArrayOfTemplateReference();
	    new DocuSignAPI.Reminders();
	    //new DocuSignAPI.ArrayOfInlineTemplate();
	    new DocuSignAPI.SSN9Information();
	    new DocuSignAPI.ArrayOfCustomField();
	    new DocuSignAPI.Attachment();
	    new DocuSignAPI.SSN9InformationInput();
	    new DocuSignAPI.FormDataXfdfField();
	    //new DocuSignAPI.CreateEnvelopeFromTemplatesAndForms_element();
	    //new DocuSignAPI.TemplateReferenceFieldDataDataValue();
	    //new DocuSignAPI.TemplateReference();
	    //new DocuSignAPI.SendEnvelope_element();
	    //new DocuSignAPI.CreateEnvelopeFromTemplates_element();
	    new DocuSignAPI.ArrayOfAttachment();
	    new DocuSignAPI.RecipientPhoneAuthentication();
	    new DocuSignAPI.DocumentStatus();
	    //new DocuSignAPI.CreateEnvelopeFromTemplatesAndFormsResponse_element();
	    //new DocuSignAPI.InlineTemplate();
	    new DocuSignAPI.RecipientStatusEsignAgreementInformation();
	    new DocuSignAPI.Tab();
	    new DocuSignAPI.EnvelopeStatus();
	    //new DocuSignAPI.ArrayOfRecipient1();
	    new DocuSignAPI.Recipient();
	    //new DocuSignAPI.CompositeTemplate();
	    //new DocuSignAPI.CreateEnvelopeResponse_element();
	    new DocuSignAPI.EventResult();
	    new DocuSignAPI.ArrayOfFormDataXfdfField();
	    new DocuSignAPI.SSN4Information();
	    new DocuSignAPI.DOBInformationInput();
	    new DocuSignAPI.Expirations();
	    new DocuSignAPI.CustomField();
	    //new DocuSignAPI.ArrayOfTemplateReferenceRoleAssignment();
	    new DocuSignAPI.ArrayOfString();
	    //new DocuSignAPI.TemplateReferenceFieldData();
	    new DocuSignAPI.Notification();
	    new DocuSignAPI.ArrayOfTabStatus();
	    new DocuSignAPI.FormDataXfdf();
	    new DocuSignAPI.ArrayOfDocument();
	    //new DocuSignAPI.RequestRecipientTokenAuthenticationAssertion();
	    new DocuSignAPI.RecipientCaptiveInfo();
	    //new DocuSignAPI.RequestSenderToken_element();
	    //new DocuSignAPI.CreateEnvelopeFromTemplatesResponse_element();
	    new DocuSignAPI.DOBInformation();
	    new DocuSignAPI.ArrayOfString1();
	    new DocuSignAPI.CreateAndSendEnvelope_element();
	    new DocuSignAPI.AddressInformationInput();
	    new DocuSignAPI.ArrayOfMatchBox();
	    //new DocuSignAPI.RequestRecipientToken_element();
	    //new DocuSignAPI.TemplateReferenceRoleAssignment();
	    new DocuSignAPI.ArrayOfDocumentStatus();
	    new DocuSignAPI.AuthenticationStatus();
	    //new DocuSignAPI.RequestRecipientTokenClientURLs();
	    new DocuSignAPI.ArrayOfEnvelopeEvent();
	    //new DocuSignAPI.ArrayOfCompositeTemplate();
	    //new DocuSignAPI.SendEnvelopeResponse_element();
	    new DocuSignAPI.IDCheckInformation();
	    new DocuSignAPI.SSN4InformationInput();
	    new DocuSignAPI.RecipientStatus();
	    //new DocuSignAPI.ServerTemplate();
	    //new DocuSignAPI.ArrayOfServerTemplate();
	    //new DocuSignAPI.RequestSenderTokenResponse_element();
	    new DocuSignAPI.IDCheckInformationInput();
	    new DocuSignAPI.Document();
	    new DocuSignAPI.EventNotification();
	    new DocuSignAPI.ArrayOfRecipient();
	    new DocuSignAPI.FormData();
	    new DocuSignAPI.Envelope();
	    new DocuSignAPI.TabStatus();
	    new DocuSignAPI.ArrayOfTab();
	    new DocuSignAPI.ArrayOfRecipientStatus();
	    new DocuSignAPI.VaultingOptions();
	    new DocuSignAPI.EnvelopeEvent();
	    //new DocuSignAPI.CreateEnvelope_element();
	    new DocuSignAPI.AddressInformation();
	    new DocuSignAPI.AnchorTab();          
	    new DocuSignAPI.VaultingDetails();
	    new DocuSignAPI.MatchBox();
	    //new DocuSignAPI.PDFMetaDataTemplate();
	    new DocuSignAPI.RecipientSignatureInfo();
	    new DocuSignAPI.CreateAndSendEnvelopeResponse_element();
	    //new DocuSignAPI.RequestRecipientTokenResponse_element();
	    //new DocuSignAPI.ArrayOfTemplateReferenceFieldDataDataValue();
	    DocuSignAPI.APIServiceSoap client = new DocuSignAPI.APIServiceSoap();
	
		//try { client.RequestRecipientToken(null,null,null,null,null,null); } catch(Exception e) {}
	    //try { client.CreateEnvelopeFromTemplates(null,null,null,null); } catch(Exception e) {}
	    try { client.CreateAndSendEnvelope(null); } catch(Exception e) {}
	    //try { client.CreateEnvelopeFromTemplatesAndForms(null,null,null); } catch(Exception e) {}
	    //try { client.SendEnvelope(null,null); } catch(Exception e) {}
		//try { client.CreateEnvelope(null); } catch(Exception e) {}
		//try { client.RequestSenderToken(null,null,null); } catch(Exception e) {}
    }
}