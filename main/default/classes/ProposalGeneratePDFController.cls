public class ProposalGeneratePDFController {

    public Opportunity currentOppty{get; set;}
    public List<Opportunity_Location__c> currentOpptyLocs{get; set;}
    public Contact decisionMaker { get; set; }
    public CompanyInfo integraDecisionMaker {get;set;}
    public String salesChannel {get;Set;}
    public String brandingURL {get;Set;}
    
    public boolean isParam(Long param) { return (documentBits & param) != 0; } 

    public boolean GenerateCoverPage{ get{ return isParam(GlobalUtilities.DOCGENBIT_COVER_PAGE); } }
    public boolean GenerateLetter{ get{ return isParam(GlobalUtilities.DOCGENBIT_LETTER); } }
    public boolean GenerateExecutiveSummary{ get{ return isParam(GlobalUtilities.DOCGENBIT_EXECSUMMARY); } } 
    public boolean GenerateQuote{ get { return isParam(GlobalUtilities.DOCGENBIT_QUOTE); } }
    public boolean GenerateCostComparison{ get{ return isParam(GlobalUtilities.DOCGENBIT_COSTCOMPARISON); } }
    public boolean GenerateServiceAgreement{ get{ return isParam(GlobalUtilities.DOCGENBIT_SERVICEAGREEMENT); } }
    public boolean GenerateLOA{ get{ return isParam(GlobalUtilities.DOCGENBIT_LOA); } }
    public boolean GenerateDirectoryForm{ get{ return isParam(GlobalUtilities.DOCGENBIT_DIRECTORYFORM); } }
    public boolean GenerateROLOA{ get{ return isParam(GlobalUtilities.DOCGENBIT_ROLOA); } }
    public boolean Generate911Form{ get{ return isParam(GlobalUtilities.DOCGENBIT_911FORM); } }
    public boolean GenerateETFCredit{ get{ return isParam(GlobalUtilities.DOCGENBIT_ETFCREDIT); } }
    public boolean GenerateSatGuarantee{ get{ return isParam(GlobalUtilities.DOCGENBIT_SATGUARANTEE); } }
    public boolean GenerateMove{ get{ return isParam(GlobalUtilities.DOCGENBIT_MOVE); } }
    public boolean GenerateBusinessDownturnSR{ get{ return isParam(GlobalUtilities.DOCGENBIT_BUSDOWNTURN_SR); } }
    public boolean GenerateSummaryOfWork{ get{ return isParam(GlobalUtilities.DOCGENBIT_SUMMARYOFWORK); } }
    
    public boolean GenerateINSIDEWADDENDUM{ get{ return isParam(GlobalUtilities.DOCGENBIT_INSIDEADDENDUM); } }
    
    public boolean GenerateMSAFORVPN{ get{ return isParam(GlobalUtilities.DOCGENBIT_MSAFORVPN); } }
    
    public boolean GenerateMSA{ get{ return isParam(GlobalUtilities.DOCGENBIT_MSA); } }
    public boolean GenerateMSAHVS{ get{ return isParam(GlobalUtilities.DOCGENBIT_MSA_HVSADDENDUM); } }
    public boolean GenerateMSACollaboration{ get{ return isParam(GlobalUtilities.DOCGENBIT_MSA_COLLABORATIONADDENDUM); } }
    public boolean GenerateMSAColocation{ get{ return isParam(GlobalUtilities.DOCGENBIT_MSA_COLOCATIONADDENDUM); } }
    public boolean GenerateLOACPNI{ get{ return isParam(GlobalUtilities.DOCGENBIT_LOACPNI); } } 
    public boolean GenerateBusinessDownturnLD{ get{ return isParam(GlobalUtilities.DOCGENBIT_BUSDOWNTURN_LD); } }
    public boolean GenerateIncentiveMRC{ get{ return isParam(GlobalUtilities.DOCGENBIT_INCENTIVE_MRC); } }
    public boolean GenerateIncentiveAmount{ get{ return isParam(GlobalUtilities.DOCGENBIT_INCENTIVE_AMOUNT); } }
    public boolean GenerateITServices{ get{ return isParam(GlobalUtilities.DOCGENBIT_ITSERVICES); } }
    public boolean GenerateWavelength{ get{ return isParam(GlobalUtilities.DOCGENBIT_WAVELENGTH); } }
    public boolean GeneratePartner{ get{ return isParam(GlobalUtilities.DOCGENBIT_PARTNERORDER); } }
    public boolean GenerateERate{ get{ return isParam(GlobalUtilities.DOCGENBIT_ERATE); } }
    public boolean GenerateERateServiceAgreement{ get{ return isParam(GlobalUtilities.DOCGENBIT_ERATESVCREQ); } }
    public boolean GenerateCFSConfig{ get{ return isParam(GlobalUtilities.DOCGENBIT_CFSCB); } }
    public boolean GenerateMSADDoSMitigation{ get{ return isParam(GlobalUtilities.DOCGENBIT_MSADDOSMIT); } }
    public boolean GenerateCFSSLA{ get{ return isParam(GlobalUtilities.DOCGENBIT_CFSServiceLA); } }
    public Boolean GenerateMSAWirelessBackupAddendum{ get{ return isParam(GlobalUtilities.DOCGENBIT_MSA_WIRELESSBACKUPADDENDUM); } }
    public Boolean GenerateMSAMonthToMonthRenewal{ get { return isParam(GlobalUtilities.DOCGENBIT_MSA_MONTHTOMONTHRENEWAL); } }
    
    public Boolean GeneratePaperless {get { return isParam(GlobalUtilities.DOCGENBIT_PAPERLESSBILLING);}}
    public Boolean GenerateEthernetServicesAddendum {get { return isParam(GlobalUtilities.DOCGENBIT_MSA_ETHERNETSERVICESADDENDUM); } }
    public Boolean GenerateHighSpeedInternetServiceAddendum {get { return isParam(GlobalUtilities.DOCGENBIT_MSA_HSISADDENDUM); } }
    public Boolean GenerateMSAUCCloudVoiceAddendum {get{return isParam(GlobalUtilities.DOCGENGIN_MSA_UC_CLOUDVOICE);}}
    public Boolean GenerateMSACPPoES {get{return isParam(GlobalUtilities.DOCGENBIT_MSA_CPPOES);}}
    
    public String ErateWCLTPageBreak { get { return                 (GenerateCoverPage) ? 'always' : ''; } }
    public String ErateSAPageBreak { get { return                   (GenerateCoverPage || GenerateERate) ? 'always' : ''; } }
    public string LTPageBreak { get { return                        (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement) ? 'always' : ''; } } 
    public string ESPageBreak { get { return                        (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter) ? 'always' : ''; } } 
    public string QTPageBreak { get { return                        (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary) ? 'always' : ''; } }
    public string CCPageBreak { get { return                        (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote) ? 'always' : ''; } }
    public string SAPageBreak { get { return                        (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison) ? 'always' : ''; } }
    public string LOAPageBreak { get { return                       (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement) ? 'always' : ''; } }
    public string DFPageBreak { get { return                        (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA) ? 'always' : ''; } }
    public string FormMSA { get { return                            (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm) ? 'always' : ''; } }
    public string FormMSACollaboration { get { return               (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA) ? 'always' : ''; } }
    public string FormMSAColocation { get { return                  (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration) ? 'always' : ''; } }
    public string FormMSADDos { get { return                        (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation) ? 'always' : ''; } }
    public string FormMSADEthernetServices { get { return           (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation) ? 'always' : ''; } }
    public String FormMSAHSISPageBreak { get { return               (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum) ? 'always' : ''; } }
    public string FormMSA_HVS { get { return                        (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum) ? 'always' : ''; } }
    public String FormMSAUCCloudVoicePageBreak { get { return       (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS) ? 'always' : ''; } }
    public String FormMSACPPoES {get{ return                        (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum) ? 'always' : ''; } }
    public String FormMSAVPNPageBreak {get { return                 (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES) ? 'always' : ''; } }
    public string FormWaveLengthPageBreak { get { return            (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN) ? 'always' : ''; } }
    public String FormMSAWirelessBackupAddendum { get { return      (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength) ? 'always' : ''; } }
    public String FormMSAMonthToMonthRenewal { get { return         (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum) ? 'always' : ''; } }
    public String FormInsideWirePageBreak { get { return            (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal) ? 'always' : ''; } }
    public string Form911PageBreak { get { return                   (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM) ? 'always' : ''; } }
    public string FormSummaryOfWork { get { return                  (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form) ? 'always' : ''; } }
    public String FormPaperlessPageBreak {get { return              (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork) ? 'always' : ''; } }
    public string ROLOAPageBreak { get { return                     (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless) ? 'always' : ''; } }
    public string FormETFCreditPageBreak { get { return             (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA) ? 'always' : ''; } }
    public string FormIncentiveMRCPageBreak { get { return          (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit) ? 'always' : ''; } }
    public string FormIncentiveAmountPageBreak { get { return       (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit || GenerateIncentiveMRC) ? 'always' : ''; } }
    public string FormSatGuaranteePageBreak { get { return          (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit || GenerateIncentiveMRC || GenerateIncentiveAmount) ? 'always' : ''; } }
    public string FormMovePageBreak { get { return                  (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit || GenerateIncentiveMRC || GenerateIncentiveAmount || GenerateSatGuarantee) ? 'always' : ''; } }
    public string FormBusinessDownturnSRPageBreak { get { return    (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit || GenerateIncentiveMRC || GenerateIncentiveAmount || GenerateSatGuarantee || GenerateMove) ? 'always' : ''; } }
    public string FormBusinessDownturnLDPageBreak { get { return    (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit || GenerateIncentiveMRC || GenerateIncentiveAmount || GenerateSatGuarantee || GenerateMove || GenerateBusinessDownturnSR) ? 'always' : ''; } }
    public string FormCFSCB { get { return                          (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit || GenerateIncentiveMRC || GenerateIncentiveAmount || GenerateSatGuarantee || GenerateMove || GenerateBusinessDownturnSR || GenerateBusinessDownturnLD) ? 'always' : ''; } }
    public string FormCFSServiceSLA { get { return                  (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit || GenerateIncentiveMRC || GenerateIncentiveAmount || GenerateSatGuarantee || GenerateMove || GenerateBusinessDownturnSR || GenerateBusinessDownturnLD || GenerateCFSConfig) ? 'always' : ''; } }
    public string LOACPNIPageBreak { get { return                   (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit || GenerateIncentiveMRC || GenerateIncentiveAmount || GenerateSatGuarantee || GenerateMove || GenerateBusinessDownturnSR || GenerateBusinessDownturnLD || GenerateCFSConfig || GenerateCFSSLA) ? 'always' : ''; } }
    public string FormPartnerPageBreak { get { return               (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit || GenerateIncentiveMRC || GenerateIncentiveAmount || GenerateSatGuarantee || GenerateMove || GenerateBusinessDownturnSR || GenerateBusinessDownturnLD || GenerateCFSConfig || GenerateCFSSLA || GenerateLOACPNI) ? 'always' : ''; } }
    public string FormITServicesPageBreak { get { return            (GenerateCoverPage || GenerateERate || GenerateERateServiceAgreement || GenerateLetter || GenerateExecutiveSummary || GenerateQuote || GenerateCostComparison || GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateMSA || GenerateMSACollaboration || GenerateMSAColocation || GenerateMSADDoSMitigation || GenerateEthernetServicesAddendum || GenerateHighSpeedInternetServiceAddendum || GenerateMSAHVS || GenerateMSAUCCloudVoiceAddendum || GenerateMSACPPoES || GenerateMSAFORVPN || GenerateWavelength || GenerateMSAWirelessBackupAddendum || GenerateMSAMonthToMonthRenewal || GenerateINSIDEWADDENDUM || Generate911Form || GenerateSummaryOfWork || GeneratePaperless || GenerateROLOA || GenerateETFCredit || GenerateIncentiveMRC || GenerateIncentiveAmount || GenerateSatGuarantee || GenerateMove || GenerateBusinessDownturnSR || GenerateBusinessDownturnLD || GenerateCFSConfig || GenerateCFSSLA || GenerateLOACPNI || GeneratePartner) ? 'always' : ''; } }
    
    
    public Long documentBits {get;set;}
    
    public ICB__c icb {get;set;}
    public Technical_Information__c  techInfo {get;set;}
    public String businessdownturn {get;set;}
    public String etfmax {get;set;}
    public String moveaddendum {get;set;}
    
    public String uniqueDocId {get;set;}
    public Map<Id,Opportunity_Location__c> oppLocMap {get;set;}
    public List<Opportunity_Location__c> oppLocList {get;set;}
    public List<OLI__c> oppLocOLIs {get;set;}
    
    public class OppLocOLIView{
        public string OppLocID{get;set;}
        public List<OLI__c> OliList{get;set;}
        public OppLocOLIView(string id, list<oli__c> olis){
            OppLocID = id;
            OliList = olis;
        }
    }
    List<OppLocOLIView> OppLocOliViews {get;set;}

    public ProposalGeneratePDFController(ApexPages.StandardController controller) {
        Opportunity ctrOppty = (opportunity)controller.getRecord();

        string docParam; 
        try {
            docParam = ApexUtils.getParam('document');
            documentBits = Long.valueOf(docParam);
        }
        catch(Exception e) {
            system.debug('unable to determine documents: ' + docParam);
            documentBits = 0;
        }

        currentOppty = 
            [Select Term__c, Amount, Current_Connection_Provider__c, Account.Customer_Detail__r.Government_Contract_Type__c, 
            Business_Objectives__c,Proposed_Solutions__c, AccountId, Proposal_Letter__c, Account2__r.Name,
            Account.Name, Account.ShippingState, Account.ShippingCity, Account.ShippingStreet, Account.ShippingPostalCode, 
            Account.BillingState, Account.BillingCity, Account.BillingStreet, Account.BillingPostalCode,
            //Account.Phone, Account.Fax, Account.Local_Service_Provider__c, Account.ICC_Account_Number__c, Account.Account_Sales_Channel__c, Account.AccountNumber,     
            Account.Phone, Account.Fax, Account.Local_Service_Provider__c, Account.ICC_Account_Number__c, Account.Account_Sales_Channel__c, Account.Owners_Sales_Channel__c, Account.AccountNumber,
            Owner.Name, Owner.Preferred_First_Name__c, Owner.LastName, Owner.Street, Owner.State, Owner.PostalCode, Owner.Email, Owner.City, Owner.Phone, Owner.MobilePhone, Owner.Fax, Owner.Title, 
            (Select Id, Opportunity__r.AccountId From Opportunity_Sites__r WHERE On_Hold__c=false and MRC_Total__c > 0 ORDER BY Opportunity__r.Account.Account_Depth__c, Opportunity__r.Account.Name)
            From Opportunity where id =: ctrOppty.Id];
      
        currentOpptyLocs = [Select Id, Opportunity__r.AccountId, Order__r.Id From Opportunity_Location__c WHERE On_Hold__c=false and MRC_Total__c > 0 AND Order__r.Opportunity__r.Id = :ctrOppty.Id ORDER BY Opportunity__r.Account.Account_Depth__c, Opportunity__r.Account.Name];
        
//      salesChannel = String.IsEmpty(currentOppty.Account.Account_Sales_Channel__c) ? 'IntegraBusiness' : currentOppty.Account.Account_Sales_Channel__c.replaceAll(' ', '');
//      List<String>brandingURLs = CustomSettingUtils.getProcessConfigurationValues('SalesChannelBrandingURL', currentOppty.Account.Account_Sales_Channel__c);
        salesChannel = String.IsEmpty(currentOppty.Account.Owners_Sales_Channel__c) ? 'IntegraBusiness' : currentOppty.Account.Owners_Sales_Channel__c.replaceAll(' ', '');
        List<String>brandingURLs = CustomSettingUtils.getProcessConfigurationValues('SalesChannelBrandingURL', currentOppty.Account.Owners_Sales_Channel__c);
        List<String>defaultBrandingURLs = CustomSettingUtils.getProcessConfigurationValues('SalesChannelBrandingURL', 'Default');
        String defaultBrandingURL = defaultBrandingURLs != null && defaultBrandingURLs.size() > 0 ? defaultBrandingURLs[0] : '';
        brandingURL = brandingUrls != null && brandingURLs.size() > 0? brandingURLs[0] : defaultBrandingURL; 
        Id recipId = ApexUtils.getParam('recipient');
        if( String.IsEmpty(recipId) ) {
            ApexUtils.messageDisplay('Recipient is not selected');
            return;
        }
        
        decisionMaker = [SELECT Id, Name, Title, Email,Phone from Contact where Id = :recipId];
        
        //Indirect or Integra
        integraDecisionMaker = new CompanyInfo(currentOppty, currentOppty.Owner);
        if(integraDecisionMaker.Name == null){
            integraDecisionMaker = new CompanyInfo(currentOppty.Owner);
        }
        
        try{
             Id winningICB;
             for(Opportunity o : [Select Winning_ICB__c From Opportunity Where Id = :ctrOppty.Id Limit 1]){
                winningICB = o.Winning_ICB__c;
                 System.debug('winning icb: ' + winningICB);
             }
             if(winningICB == null){
                for(List<ICB__c> icbs : [select Id, Name, Description__c, Approval_Status__c, Offer_Management_Approver__c, CommissionAdjustment__c,
                Contract_Changes_Needed_del__c, iCert_Required__c, ICB_Code__c, Number_of_Days__c, Comments__c,
                Number_of_Months__c, Incentive_Credit_Type__c, NRC_Credit_Amount__c, Additional_Conditions_Required__c, Credit_Amount_Approved__c from ICB__c where Opportunity__c = :ctrOppty.Id]){
                    if(icbs.size() <= 1){
                        for(ICB__c oneICB : icbs){
                        icb = oneICB;
                             System.debug('non winning icb: ' + oneICB);
                        }
                    }
                }
             }
             else{
             icb = [select Id, Name, Description__c, Approval_Status__c, Offer_Management_Approver__c, CommissionAdjustment__c,
                Contract_Changes_Needed_del__c, iCert_Required__c, ICB_Code__c, Number_of_Days__c, Comments__c,
                Number_of_Months__c, Incentive_Credit_Type__c, NRC_Credit_Amount__c, Additional_Conditions_Required__c, Credit_Amount_Approved__c from ICB__c where Opportunity__c = :ctrOppty.Id AND Id = : winningICB LIMIT 1];
                 System.debug('winning icb: ' + icb);
             }
             
             
             techInfo = [Select Business_Downturn_Decrease_Revenue_Pct__c, ETF_Assistance_Credit_Max_Amount__c, Move_Addendum_Months__c From Technical_Information__c  Where Opportunity_Site__r.Order__r.Opportunity__c=:ctrOppty.Id And (Business_Downturn_Decrease_Revenue_Pct__c != null Or ETF_Assistance_Credit_Max_Amount__c != null Or Move_Addendum_Months__c != null) limit 1];

                businessdownturn = techInfo.Business_Downturn_Decrease_Revenue_Pct__c != null ? techInfo.Business_Downturn_Decrease_Revenue_Pct__c : 'twenty percent (20%)';

                etfmax = techInfo.ETF_Assistance_Credit_Max_Amount__c != null ? techInfo.ETF_Assistance_Credit_Max_Amount__c : '';
                moveaddendum = techInfo.Move_Addendum_Months__c != null ? techInfo.Move_Addendum_Months__c : '';

            }catch(exception e) {
                ApexUtils.messageDisplay(e.getMessage());
            }
            businessdownturn = businessdownturn != null ? businessdownturn : 'twenty percent (20%)';
                
        if(GenerateCostComparison || GenerateQuote){
            oppLocMap = new Map<Id,Opportunity_Location__c>();
            oppLocList = new List<Opportunity_Location__c>();
            //Get Opp Locations and OLI's in one batch vs 2 queries for each loc
              for(Opportunity_Location__c oploc :[Select Id, Order__r.Opportunity__r.Id, Name, NRC_Total__c, MRC_Total__c, Order__r.Opportunity__r.Term__c, Order__r.Opportunity__r.Proposed_Solutions__c,
                Opportunity__r.Account.Name, Opportunity__r.Account.ShippingState, Opportunity__r.Account.ShippingCity, Opportunity__r.Account.ShippingStreet, Opportunity__r.Account.ShippingPostalCode, Opportunity__r.Account.Phone, Opportunity__r.Account.Fax,
                Service_Location__r.Location__r.Building__r.Address__c,Service_Location__r.Location__r.Building__r.City__c,Service_Location__r.Location__r.Building__r.State__c,
                Service_Location__r.Location__r.Building__r.Postal_Code__c,Service_Location__r.Location__r.Building__r.Id,Service_Location__r.Name, Service_Location__r.Location__r.Room_Suite__c,                                                    
                (Select Description__c, Qty__c, MRC__c From Oppty_Cost_Comparisons__r),              
                (Select EPCProductDescription__c, FirstCN__c, Quantity__c, MRC__c From Disconnect_Line_Items__r),
                (Select Id, Term__c, Display_on_Solution__c, Name, Active__c from OpportunityLocationConfigurations__r Where Active__c=true)      
                from Opportunity_Location__c       
                where Order__r.Opportunity__r.Id = :currentOppty.Id]){
                    oppLocMap.put(opLoc.Id, opLoc);
                }
            oppLocList = oppLocMap.values();
            
            oppLocOLIs = new List<OLI__c>();
            oppLocOLIs = getOLIs(oppLocMap.keyset(),true,false);
            /*for(OLI__c oli :getOLIs(oppLocMap.keyset(),true,false)){
                List<OLI__c> oppLocOLIList = oppLocOLIs.get(oli.OpportunityLocationConfiguration__r.Opportunity_Location__c);
                if(oppLocOLIList != null){
                    oppLocOLIList.add(oli);
                }                   
                else{
                    List<OLI__c> olis = new List<OLI__c>();
                    olis.add(oli);
                    oppLocOLIs.put(oli.OpportunityLocationConfiguration__r.Opportunity_Location__c,olis);
                }
            }*/
            
            //oppLocOLIViews = new List<OppLocOLIView>();
            //for(id oppLocId : oppLocOLIs.keyset()){
            //  oppLocOLIViews.add(new OppLocOLIView(oppLocId,oppLocOLIs.get(oppLocId)));
            //}
        }
        
        if( GenerateServiceAgreement || GenerateLOA || GenerateDirectoryForm || GenerateROLOA  || Generate911Form ) {
            uniqueDocId = 'DocumentID: ' + DateTime.Now().getTime() + Math.random().format();
        }
    }       
    
    private static List<OLI__c> getOLIs(Set<Id> configIds, Boolean sortForPrint, Boolean ignoreFamilySort) {
        return ApexUtils.retrieveObjectsFromFieldSets(OLI__c.getsObjectType()
                                                            ,new List<Set<String>>
                                                            {
                                                                SchemaUtils.RetrieveFullObjectFieldSet(OLI__c.getsObjectType())
                                                                ,new Set<String> {
                                                                    'Parent_Opportunity_Line_Item__r.PP_SalesRatePlanPricingExternalID__c'
                                                                    ,'OpportunityLocationConfiguration__r.Opportunity_Location__c'
                                                                    ,'OpportunityLocationConfiguration__r.Active__c'
                                                                    ,'Secondary_Location__r.Building__r.Name'
                                                                    ,'Secondary_Service_Location__r.Location__r.Building__r.Name'
                                                                }
                                                            }
                                                            ,'OpportunityLocationConfiguration__r.Opportunity_Location__c in (\'' + string.join(new List<Id>(configIds), '\',\'') + '\') AND PP_Package_Feature__c = false'
                                                            ,'Product_Family_Product__c, MRC__c DESC, Qty__c DESC'
                                                            /*sortForPrint
                                                                ? (!ignoreFamilySort ? 'PP_Product_Family_Sort__c,  PP_Sales_Product_Sort__c, ' : '') + 'MRC__c DESC, Qty__c DESC'
                                                                : 'PP_Product_Family_Sort__c,  PP_Sales_Product_Sort__c,  PP_Feature_Grouping_Sort__c, PP_Sales_Rate_Plan_Description_Sort__c'*/
                                                            );
    }
}