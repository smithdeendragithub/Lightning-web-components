@isTest
public with sharing class Test_DSUtils extends TestUtils.TestClass {
	
    static testMethod void testSendEnvelope() {
		
		Mocks testData = new Mocks();
		
		Id opportunityID = testData.opportunity.Id;
		Contact c = new Contact(FirstName='Test'
								,LastName='Person'
								,Phone='(000) 000-0000'
								,Email='test@test.com');
		insert c;
		
		User u = testData.user;
		
		test.startTest();
		
		DSUtils.EnvelopeRequest er = new DSUtils.EnvelopeRequest('Test Subject', 'Test Notes', null);
		DSUtils.DocuSignContent d = er.AddDocument(null);
		d.SignerTabs.put(DSUtils.TAB_XMARK, 'Custom');
		d.CounterSignerTabs.put(DSUtils.TAB_XMARK, 'Custom');
		d.CCTabs.put(DSUtils.TAB_XMARK, 'Custom');
		
		er.Signers.add(new DSUtils.DSContact(c));
		er.CCs.add(new DSUtils.DSContact(c));
		er.CounterSigner = new DSUtils.DSContact(u);
		
		DSUtils.EnvelopeSendResult result = DSUtils.Send(er);
		Id statusID = DSUtils.CreateDocusignStatusRecord(result, er, new Set<Id>{opportunityID});
	}
	
	public static DocuSignAPI.EnvelopeStatus getEnvelopeStatus(){
		DocuSignAPI.EnvelopeStatus es = new DocuSignAPI.EnvelopeStatus();
		es.EnvelopeID = '0000-1111-2222-3333';
		es.Status = 'Sent';
		return es;
	}
}