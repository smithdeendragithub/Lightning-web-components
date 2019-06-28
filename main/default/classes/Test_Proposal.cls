@isTest
public with sharing class Test_Proposal extends TestUtils.TestClass {
	
    static testMethod void testGenericController() {
        Mocks testData = new Mocks();
        
        ProposalGenericController ctr = new ProposalGenericController();
        ctr.currentOpportunity = testData.opportunity;
        //loopThroughAddress(ctr.integraDecisionMaker);
        loopThroughAddress(ctr.clientMainAddress);
        
        List<User> lstUsers = [SELECT Id, Name, FirstName, LastName, Preferred_First_Name__c, Street, City, State, PostalCode, Phone, MobilePhone, Fax, Email, Title from User limit 1];
        
        CompanyInfo address = new CompanyInfo(lstUsers[0]);
    }
    
    static void loopThroughAddress(CompanyInfo address) {
        String temp = address.Name;
        temp = address.Street;
        temp = address.City;
        temp = address.CityStateZip;
        temp = address.Email;
        temp = address.Phone;
        temp = address.State;
        temp = address.Title;
        temp = address.Zip;     
    }

    static testMethod void testLOA() {
        Mocks testData = new Mocks();
		
		Opportunity opp = testData.opportunity;
		Opportunity_Location__c loc = testData.location;
		List<OLI__c> olis = testData.lstLineItems;
		
		RecordType rt = [select Id from RecordType where SObjectType = 'Technical_Information__c' and DeveloperName = 'DID'];
		List<Technical_Information__c> tis = new List<Technical_Information__c>{
																	        	new Technical_Information__c(Opportunity_Site__c = loc.Id, RecordTypeId = rt.Id)
																	        	,new Technical_Information__c(Opportunity_Site__c = loc.Id, RecordTypeId = rt.Id)
																			};
		insert tis;
		
		test.startTest();
        
        ProposalLOAController ctr = new ProposalLOAController();
        ctr.currentOpportunity = opp;
    }

    static testMethod void testDirectoryForm() {
        Mocks testData = new Mocks();
        
        ProposalDirectoryForm ctr = new ProposalDirectoryForm();
        ctr.currentOpportunity = testData.opportunity;
    } 
    
    static testMethod void testServiceAgreement() {
        Mocks testData = new Mocks();
		
		Order__c ord = testData.Order;
		Opportunity opp = testData.opportunity;
		List<OLI__c> olis = testData.lstLineItems;
		
		test.startTest();
		
        ProposalServiceAgreementController ctr = new ProposalServiceAgreementController();
        ctr.currentOpportunity = opp;
		
		ProposalServiceAgreementController.Location l = new ProposalServiceAgreementController.Location();
    }

    static testMethod void testQuote() {
        Mocks testData = new Mocks();
		
		List<OpportunityLocationConfiguration__c> sols = testData.lstconfig;
		List<OLI__c> olis = testData.lstLineItems;
		Opportunity_Location__c oppLoc = testData.location;
		oppLoc = [select Id, MRC_Total__c
						,Service_Location__r.Name, Service_Location__r.Location__r.Room_Suite__c
						,Service_Location__r.Location__r.Building__r.Id, Service_Location__r.Location__r.Building__r.Address__c, Service_Location__r.Location__r.Building__r.City__c
							,Service_Location__r.Location__r.Building__r.State__c, Service_Location__r.Location__r.Building__r.Postal_Code__c
						,(select Id, Term__c, Display_on_Solution__c, Name from OpportunityLocationConfigurations__r) from Opportunity_Location__c where Id =: oppLoc.Id];
		test.startTest();
        
        ProposalQuoteController ctr = new ProposalQuoteController();
		ctr.oppLocs = new Map<Id, Opportunity_Location__c>{ oppLoc.Id => oppLoc };
		ctr.OppLocOLIs = olis;
        ctr.currentOpportunityLocationId = oppLoc.Id;
		
        system.debug(ctr.comparisonTotal);
        system.debug(ctr.currentOpportunityLocationId);
        system.debug(ctr.lstProducts);
        system.debug(ctr.MonthlySavingsAmount);
        system.debug(ctr.MonthlyPercentSavingsAmount);
        system.debug(ctr.AnnualSavingsAmount);
    }
    
    
    static testMethod void testProposalGeneratePDFController() {
        Mocks testData = new Mocks();
		
		Opportunity opp = testData.opportunity;
		Contact c = testData.parentAccountContact;
		
		test.startTest();
		
    	PageReference pageReference = Page.ProposalGeneratePDF;
        pageReference.getParameters().put('recipient', c.Id);
        Test.setCurrentPage(pageReference);

        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp);
        ProposalGeneratePDFController ctr = new ProposalGeneratePDFController(sc);
		
		//Pull the page elements
		system.debug('ErateWCLTPageBreak: ' + ctr.ErateWCLTPageBreak);
		system.debug('ErateSAPageBreak: ' + ctr.ErateSAPageBreak);
		system.debug('LTPageBreak: ' + ctr.LTPageBreak);
		system.debug('ESPageBreak: ' + ctr.ESPageBreak);
		system.debug('QTPageBreak: ' + ctr.QTPageBreak);
		system.debug('CCPageBreak: ' + ctr.CCPageBreak);
		system.debug('SAPageBreak: ' + ctr.SAPageBreak);
		system.debug('LOAPageBreak: ' + ctr.LOAPageBreak);
		system.debug('DFPageBreak: ' + ctr.DFPageBreak);
		system.debug('FormMSA: ' + ctr.FormMSA);
		system.debug('FormMSACollaboration: ' + ctr.FormMSACollaboration);
		system.debug('FormMSAColocation: ' + ctr.FormMSAColocation);
		system.debug('FormMSADDos: ' + ctr.FormMSADDos);
		system.debug('FormMSADEthernetServices: ' + ctr.FormMSADEthernetServices);
		system.debug('FormMSAHSISPageBreak: ' + ctr.FormMSAHSISPageBreak);
		system.debug('FormMSA_HVS: ' + ctr.FormMSA_HVS);
		system.debug('FormMSAUCCloudVoicePageBreak: ' + ctr.FormMSAUCCloudVoicePageBreak);
		system.debug('FormMSAVPNPageBreak: ' + ctr.FormMSAVPNPageBreak);
		system.debug('FormWaveLengthPageBreak: ' + ctr.FormWaveLengthPageBreak);
		system.debug('FormMSAWirelessBackupAddendum: ' + ctr.FormMSAWirelessBackupAddendum);
		system.debug('FormMSAMonthToMonthRenewal: ' + ctr.FormMSAMonthToMonthRenewal);
		system.debug('FormInsideWirePageBreak: ' + ctr.FormInsideWirePageBreak);
		system.debug('Form911PageBreak: ' + ctr.Form911PageBreak);
		system.debug('FormSummaryOfWork: ' + ctr.FormSummaryOfWork);
		system.debug('FormPaperlessPageBreak: ' + ctr.FormPaperlessPageBreak);
		system.debug('ROLOAPageBreak: ' + ctr.ROLOAPageBreak);
		system.debug('FormETFCreditPageBreak: ' + ctr.FormETFCreditPageBreak);
		system.debug('FormIncentiveMRCPageBreak: ' + ctr.FormIncentiveMRCPageBreak);
		system.debug('FormIncentiveAmountPageBreak: ' + ctr.FormIncentiveAmountPageBreak);
		system.debug('FormSatGuaranteePageBreak: ' + ctr.FormSatGuaranteePageBreak);
		system.debug('FormMovePageBreak: ' + ctr.FormMovePageBreak);
		system.debug('FormBusinessDownturnSRPageBreak: ' + ctr.FormBusinessDownturnSRPageBreak);
		system.debug('FormBusinessDownturnLDPageBreak: ' + ctr.FormBusinessDownturnLDPageBreak);
		system.debug('FormCFSCB: ' + ctr.FormCFSCB);
		system.debug('FormCFSServiceSLA: ' + ctr.FormCFSServiceSLA);
		system.debug('LOACPNIPageBreak: ' + ctr.LOACPNIPageBreak);
		system.debug('FormPartnerPageBreak: ' + ctr.FormPartnerPageBreak);
		system.debug('FormITServicesPageBreak: ' + ctr.FormITServicesPageBreak);
		
		//Now load a doc
        pageReference.getParameters().put('document', string.valueOf(GlobalUtilities.DOCGENBIT_QUOTE));
        ctr = new ProposalGeneratePDFController(sc);
		
		ProposalGeneratePDFController.OppLocOLIView v = new ProposalGeneratePDFController.OppLocOLIView(null, null);
    }
    
    static testMethod void testProposalGenericController() {
        Mocks testData = new Mocks();
        PageReference pageReference = Page.ProposalGeneratePDF;
        pageReference.getParameters().put('recipient', testData.parentAccountContact.Id);
        pageReference.getParameters().put('id', testData.opportunity.Id);
        Test.setCurrentPage(pageReference);
        
        ProposalGenericController ctr = new ProposalGenericController();        
    }

    static testMethod void testGeneratePDF() {
        Mocks testData = new Mocks();
		
		Opportunity opp = testData.opportunity;
		
		SPC_Product__c p = new SPC_Product__c(SalesProductExternalID__c = 185, Expiration__c = null, Hide_In_Wizard__c = false);
		insert p;
		
		OLI__c oli = new OLI__c(MRC__c = 123, OpportunityLocationConfiguration__c=testData.lstconfig[0].Id,  Qty__c=3, SPC_Sales_Product__c = p.Id);
		insert oli;
		
		Contact c = testData.parentAccountContact;
		OpportunityContactRole ocr = new OpportunityContactRole(ContactId = c.Id, OpportunityId = opp.Id, Role = 'Some Jerk');
		insert ocr;
		
		PDF_Mapping__c pdf = new PDF_Mapping__c(Name = 'Peetie F', Selected_PDFS__c = 'TheLunchCodes.pdf', SPC_Product__c = p.Id);
		insert pdf;
		
		ICB__c icb = new ICB__c(ICB_Type__c = 'AiShiBi', ICB_Pricing_Reason__c = 'Ballin', Sales_Engineer__c = testData.user.Id, Opportunity__c = opp.Id);
		insert icb;
		
		test.startTest();
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp);
		OpptyGeneratePDFController ctr = new OpptyGeneratePDFController(sc);
		ctr.currentOppty = opp;
        ctr.fileContents = Blob.valueOf('test');
        ctr.fileContentsUpload = Blob.valueOf('test');
        ctr.pageBytes = Blob.valueOf('test');
        ctr.selectedDocType = 'test';
        ctr.ShowDisplayButton = false;
        ctr.oTypeName = 'test';
        ctr.JSONSelectedProps = JSON.serialize(new List<String>{'1', '2'});
		ctr.selectedAction = 'Store';
		ctr.cv.Title = 'Content';
		ctr.cv.Description = 'Description';
		OpptyGeneratePDFController.storeDocURL = URL.getSalesforceBaseUrl().toExternalForm() + '/home/home.jsp';
		//ctr.bytes = Blob.valueOf('Don\'t let the bed bugs');
		
        system.debug(ctr.potentialRecipients);
        system.debug(ctr.recipients);
        system.debug(ctr.selectedContactRecipent);
        system.debug(ctr.documentActions);
		system.debug(ctr.indirectSections);
        system.debug(ctr.proposalSections);
        system.debug(ctr.contractSections);
        system.debug(ctr.otherSections);
        //ctr.getPageBytes();
        ctr.generate();
        ctr.generateNextPageUrl();
        
        ctr.selectedContactRecipent = null;
        ctr.generate();
		ctr.createProposalElements();
        //ctr.getObjectProperties();
   	}
            
    static testMethod void testGeneratePDFStore() {
        Mocks testData = new Mocks();
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testData.opportunity);
		System.debug(testData.order);
		
        OpptyGeneratePDFController ctr = new OpptyGeneratePDFController(sc);
		ctr.JSONSelectedProps = JSON.serialize(new List<String>());
        ctr.selectedProposalSections.add(ctr.proposalSections[0].getValue() );
        ctr.selectedProposalSections.add(ctr.proposalSections[1].getValue() );
        ctr.selectedProposalSections.add(ctr.proposalSections[2].getValue() );
        ctr.generateNextPageUrl();

        ctr.selectedAction = 'Store';
        ctr.generate();     
    }
	
	static testMethod void testCompanyInfo(){
        Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		Opportunity opp = testData.opportunity;
		User u = testData.user;
		
		Building__c b = testData.building;
		Location__c loc = testData.loc;
		Service_Location__c sLoc = testData.serviceLocation;
		
		Directory_Listing__c dl = new Directory_Listing__c();
		
		test.startTest();
		
		CompanyInfo ci = new CompanyInfo(a, true);
		ci = new CompanyInfo(a, false);
		
		ci = new CompanyInfo(opp, u);
		
		ci = new CompanyInfo(b, sLoc.Name);
		ci = new CompanyInfo(b, sLoc.Name, loc.Room_Suite__c);
		
		ci = new CompanyInfo(dl);
	}
	
	static testMethod void testPDFMapping(){
		test.startTest();
		
		PDFMapping m = new PDFMapping();
		system.assert(m.AvailablePDFS.size() > 0, 'No available PDFs found');
		system.assert(m.existingMappings.size() == 0, 'Existing custom PDF mappings encountered');
		m.NewMapping();
		m.SaveData();
		m.SelectedID = m.SelectedPDF.Id;
		m.GatherData();
		m.DeleteSelected();
	}
}