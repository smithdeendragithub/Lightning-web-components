public with sharing class PDFMapping{
	public List<SelectOption> AvailablePDFS{
		get {
	            
	            List<SelectOption> retVal = new List<SelectOption>();
	            
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_COVER_PAGE), 'Cover Page'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_ERATE), 'eRate Welcome Letter'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_LETTER), 'Letter'));            
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_EXECSUMMARY), 'Executive Summary'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_QUOTE), 'Quote'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_COSTCOMPARISON), 'Cost Comparison'));
				retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_SERVICEAGREEMENT), 'Service Agreement')); 
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_LOA), 'LOA'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_DIRECTORYFORM), 'Directory Listing Form'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_MSA), 'MSA'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_MSA_HVSADDENDUM), 'MSA Hosted Voice Services Addendum'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_MSA_COLLABORATIONADDENDUM), 'MSA Collaboration and Messaging Service Addendum'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_MSA_COLOCATIONADDENDUM), 'MSA Colocation Service Addendum'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_WAVELENGTH), 'MSA Wavelength Service Addendum'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_MSAFORVPN), 'MSA VPN Solutions Service Addendum'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_INSIDEADDENDUM), 'Inside Wiring Addendum'));
				retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_ROLOA), 'Records Only LOA')); 
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_911FORM), '911 Form'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_ETFCREDIT), 'ETF Assistance Credit Addendum'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_INCENTIVE_MRC), 'Incentive Credit MRC Multiple Addendum'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_INCENTIVE_AMOUNT), 'Incentive Credit Dollar Amount Addendum'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_SATGUARANTEE), 'Customer Satisfaction Guarantee'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_MOVE), 'Move Addendum'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_BUSDOWNTURN_SR), 'Business Downturn Addendum Service Reduction'));
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_BUSDOWNTURN_LD), 'Business Downturn Addendum Location Downturn'));
	            
	            retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_SUMMARYOFWORK), 'Summary of Work'));
				retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_LOACPNI), 'LOA CPNI'));
            	retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_PARTNERORDER), 'Partner Order Profile'));
            	retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_CFSCB), 'Cloud Firewall Service - Configuration Brief'));
            	retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_MSADDOSMIT), 'MSA DDoS Mitigation Addendum'));      
				retVal.add(new SelectOption(String.valueOf(GlobalUtilities.DOCGENBIT_CFSServiceLA), 'Cloud Firewall Service - Service Level Agreement'));
	        	retVal.add(new SelectOption(String.valueOf(GlobalUtilities.DOCGENBIT_MSA_WIRELESSBACKUPADDENDUM), 'MSA Wireless Backup Addendum'));
				retVal.add(new SelectOption(String.valueof(GlobalUtilities.DOCGENBIT_MSA_ETHERNETSERVICESADDENDUM), 'MSA Ethernet Services Addendum'));
				retVal.add(new SelectOption(String.valueOf(GlobalUtilities.DOCGENBIT_MSA_HSISADDENDUM), 'MSA High Speed Internet Service Addendum'));
				retVAl.add(new SelectOption(String.valueOf(GlobalUtilities.DOCGENGIN_MSA_UC_CLOUDVOICE), 'MSA UC Cloud Voice Addendum'));
				retVal.add(new SelectOption(String.valueOf(GlobalUtilities.DOCGENBIT_MSA_CPPOES), 'MSA UC Cloud Voice Customer Provided POE Addendum'));
			return retVal; 
	        }
	}
	public string SelectedPDFS {get;Set;}
	
	public PDF_Mapping__c SelectedPDF {get;Set;}
	public String ChoosenPDFS{get;Set;}
	
	
	public List<PDF_Mapping__c> existingMappings {
		get{
			return [Select Id,Name, Sales_Channel__c, Selected_PDFS__c, SPC_Product__c From PDF_Mapping__c];
		}
		Set;
	}
	
	public Id SelectedID {get;Set;}
	public string SelectedPDFMap {get;Set;}
	
	
	public PDFMapping(){
		SelectedPDF = new PDF_Mapping__c();
		SelectedPDFS = '';
	}
	
	public PageReference NewMapping(){
		SelectedPDF = new PDF_Mapping__c();
		SelectedPDFMap = '';
		SelectedPDF.Selected_PDFS__c = '';
		return null;
	}
	
	public pageReference GatherData(){
		PDF_Mapping__c sm = [Select Id,Name, Sales_Channel__c, Selected_PDFS__c, SPC_Product__c From PDF_Mapping__c Where Id = :SelectedID];
		SelectedPDF = sm;
		SelectedPDFMap = json.serialize(sm);
		return null;
	}
	
	public void SaveData(){
		try{
			SelectedPDF.Selected_PDFS__c = ChoosenPDFS;
			upsert SelectedPDF;
			
		}
		 catch(Exception e){
            ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, 'Error Upserting: ' + e.getMessage());
        	ApexPages.addMessage(m);
        }
	}
	
	public void DeleteSelected(){
		try{
			PDF_Mapping__c dMapping = new PDF_Mapping__c();
			dMapping.id = SelectedID;
			if(dMapping.Id != null)
				delete dMapping;
		}
		 catch(Exception e){
            ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, 'Error Deleting: ' + e.getMessage());
        	ApexPages.addMessage(m);
        }
	}
}