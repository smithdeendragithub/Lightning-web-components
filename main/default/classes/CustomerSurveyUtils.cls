/**************************************************************************************************
*    CustomerSurveyUtils.cls
*
*    Modifications:
*    Developer Name       Date        Brief description
*    -------------------  ----------  ------------------------------------------------------------
*    Eunjung Ju           01/16/2019  SOM-270 - UC Survey Request
**************************************************************************************************/

public without sharing class CustomerSurveyUtils extends TestUtils.TestClass {

    
    public static final String OPTED_OUT_STATUS_MSG = 'Contact was opted out at the time of this survey';
    public static final String SURVEY_SENT_MSG = 'Survey sent to contact';
    public static final String NULL_CONTACT_MSG = 'No contact was found to survey';
    public static final String NO_EMAIL_MSG = 'Contact does not have a valid email';
    public static final String ALLSTREAM_INSTALLATION_SURVEY_NAME = 'Allstream Installation Survey'; // UC Survey
    public static final String ORDER_COMPLETION_SURVEY_NAME = 'Order Completion Survey';
    public static final String CUSTOMER_ACCOUNT_MANAGER_SURVEY_NAME = 'Customer Account Manager Survey';
    public static final String SALES_EXPERIENCE_WON_SURVEY_NAME = 'Sales Experience Survey Won';
    public static final String SALES_EXPERIENCE_LOST_SURVEY_NAME = 'Sales Experience Survey Lost';
    public static final String ACCOUNT_CONSULTANT_SURVEY_NAME = 'Account Consultant Survey';
    public static final String CUSTOMER_CARE_SURVEY_NAME = 'Customer Care Survey';
    public static final String RECOMMEND_ALLSTREAM_SURVEY_NAME = 'Would you recommend Allstream';
    public static final String RECOMMEND_ALLSTREAM_REMINDER_SURVEY_NAME = 'Would you recommend Allstream Reminder';
    public static final String ALLSTREAM_CUSTOMER_CARE_SURVEY_NAME = 'Allstream Customer Care Survey';
    public static final String ALLSTREAM_CUSTOMER_SATISFACTION_SURVEY_NAME='Allstream Customer Satisfaction Survey';
    
    public Enum SurveyType { SALES_EXPERIENCE_WON, SALES_EXPERIENCE_LOST, POST_INSTALL, CUSTOMER_ACCOUNT_MANAGER, ACCOUNT_CONSULTANT, CUSTOMER_CARE, RECOMMEND_ALLSTREAM_SURVEY_NAME, RECOMMEND_ALLSTREAM_REMINDER_SURVEY_NAME, POST_INSTALL_UC, ALLSTREAM_CUSTOMER_CARE,ALLSTREAM_CUSTOMER_SATISFACTION }       
    
    private static Set<Id> custDetailIdsForSurvey {get;set;}
    private static Id zMarketingOrgWideId = null;
    public static Id MarketingOrgWideId{
        get{
            if(zMarketingOrgWideId == null){
                List<OrgWideEmailAddress> addrs = [select Id from OrgWideEmailAddress where DisplayName = 'Marketing'];
                if(addrs.size() > 0)
                    zMarketingOrgWideId = addrs[0].id;
            }
            return zMarketingOrgWideId;
        }
    }

    private static Id zCustomerExperienceOrgWideId = null;
    public static Id CustomerExperienceOrgWideId{
        get{
            if(zCustomerExperienceOrgWideId == null){
                List<OrgWideEmailAddress> addrs = [select Id from OrgWideEmailAddress where DisplayName = 'Allstream Customer Experience'];
                if(addrs.size() > 0)
                    zCustomerExperienceOrgWideId = addrs[0].id;
            }
            return zCustomerExperienceOrgWideId;
        }
    }
    
    private static Id zAllstreamInstallationOrgWideId = null;
    public static Id AllstreamInstallationOrgWideId{
        get{
            if(zAllstreamInstallationOrgWideId == null){
                List<OrgWideEmailAddress> addrs = [select Id from OrgWideEmailAddress where DisplayName = 'Allstream Installation Experience'];
                if(addrs.size() > 0)
                    zAllstreamInstallationOrgWideId = addrs[0].id;
            }
            return zAllstreamInstallationOrgWideId;
        }
    }
    
    public static void sendOrderSurveys(Map<Id, Order__c> Ords, List<Sub_Order__c> soList, Map<Id, List<Workstep__c>> soWSMap){
        List<SurveyCreatorParams> ordsToSurvey = getOrdersToSurvey(soList, Ords, soWSMap);
        Map<Id, List<Survey__c>> svysByParentId = crtSvysFrmOrds(ordsToSurvey);
        if(!svysByParentId.isEmpty()){
            InsertSurveysAndSendMail(svysByParentId);
        }
    }
    
    public static void sendCaseSurveys(List<Case> Cases, Map<Id, Case> oldCases){
        List<SurveyCreatorParams> casesToSurvey = getCasesToSurvey(Cases, oldCases);
        Map<Id, List<Survey__c>> svysByParentId = crtSvysFrmCs(casesToSurvey);
        if(!svysByParentId.isEmpty()){
            InsertSurveysAndSendMail(svysByParentId);
        }
    }
    
    public static void sendOpportunitySurveys(List<Opportunity> tNew, Map<Id,Opportunity> tOld){
        List<SurveyCreatorParams> oppsToSurvey = getOppsToSurvey(tNew, tOld);
        Map<Id, List<Survey__c>> svysByParentId = crtSvysFrmOpps(oppsToSurvey);
        if(!svysByParentId.isEmpty()){
            InsertSurveysAndSendMail(svysByParentId);
        }
    }
    
    public static void resendFailedSurveys(List<Integration_Error__c> errors){
        Map<Id, List<Survey__c>> svysByParentId = new Map<Id, List<Survey__c>>();
        
        List<Id> surveyIds = new List<Id>();
        for(Integration_Error__c e : errors){
            surveyIds.add(e.ObjectID__c);
        }
        Map<Id, Survey__c> svyById = new Map<Id, Survey__c>([select Survey_Name__c, Sent_Date__c, Surveyed_Contact__c, Sent_Status__c from Survey__c where Id in :surveyIds]);
        for(Integration_Error__c e : errors){
            List<Survey__c> svys = svysByParentId.get(e.RelatedID__c);
            if(svys == null) svys = new List<Survey__c>();
            svys.add(svyById.get(e.ObjectID__c));
            svysByParentId.put(e.RelatedID__c, svys);
        }
        SendSurveyEmails(svysByParentId);
        //we'll create new ones if they fail again.
        delete errors;
    }
    
    private static List<SurveyCreatorParams> getOppsToSurvey(List<Opportunity> tNew, Map<Id, Opportunity> tOld){
        List<SurveyCreatorParams> ret = new List<SurveyCreatorParams>();
        if(!CustomSettingUtils.getOverrideSettingValue('Send Sales Experience Survey')){
            
            for(Opportunity opp : tNew){
                Opportunity oldOpp = tOld.get(opp.Id);
                if(opp.StageName == OpportunityUtils.STAGE_CLOSED_WON || opp.StageName == OpportunityUtils.STAGE_5){
                    if(opp.Order_Status__c == 'Order to Pending' && oldOpp.Order_Status__c != 'Order to Pending'){
                        if(opp.Type == 'New Logo' && opp.CPQ_Total__c > 300){
                            SurveyCreatorParams param = new SurveyCreatorParams();
                            param.daObject = opp;
                            param.OpportunityId = opp.Id;
                            param.AccountId = opp.AccountId;
                            param.SurveyType = SurveyType.SALES_EXPERIENCE_WON;
                            ret.add(param);
                        }
                    }
                }
            }
            for(Opportunity opp : OpportunityUtils.getChangedStagedOpportunities(tNew, tOld, new Set<String>{OpportunityUtils.STAGE_CLOSED_LOST}).values()){
                if(opp.Lost_Reason__c != 'System Clean Up'){
                    if(opp.Type == 'New Logo' && opp.CPQ_Total__c > 300){
                        SurveyCreatorParams param = new SurveyCreatorParams();
                        param.daObject = opp;
                        param.OpportunityId = opp.Id;
                        param.AccountId = opp.AccountId;
                        param.SurveyType = SurveyType.SALES_EXPERIENCE_LOST;
                        ret.add(param);
                    }
                }
            }
        }
        return ret;
    }
    
    private static Map<Id, List<Survey__c>> crtSvysFrmOpps(List<SurveyCreatorParams> params){
        List<SurveyCreatorParams> surveysToSend = new List<SurveyCreatorParams>();
        List<Opportunity> opps = new List<Opportunity>();
        Set<Id> acctIds = new Set<Id>();    
        for(SurveyCreatorParams param : params){
            acctIds.add(param.AccountId);
            opps.add((Opportunity)param.daObject);
        }
        
        Map<Id, Contact> contacts = OpportunityUtils.getResponsiblePartyForOpportunity(opps);
        
        Integer daysBetweenSurveys = getSurveyDelay('SalesExperience');
        Map<Id,Date> LastSurveyedDateByAcctId = getLastSurveyedDates(acctIds, 'Sales Experience');
        
        for(SurveyCreatorParams param : params){
            Id acctId = param.AccountId;
            if(canSurvey(daysBetweenSurveys, LastSurveyedDateByAcctID.get(acctId))){
                Contact con = contacts.get(param.daObject.Id);
                if(con != null)
                    param.contacts = new Set<Contact>{con};
                LastSurveyedDateByAcctID.put(acctId, Date.today());
                surveysToSend.add(param);
            }
        }
        List<SurveyCreatorParams> fails = new List<SurveyCreatorParams>();
        return new SurveyCreator().Create(surveysToSend, fails);
    }   

    private static List<SurveyCreatorParams> getCasesToSurvey(List<Case> Cases, Map<Id, Case> oldCases){
        List<SurveyCreatorParams> ret = new List<SurveyCreatorParams>();
        Boolean sendCAMSurvey = !CustomSettingUtils.getOverrideSettingValue('Send Customer Account Manager Survey');
        Boolean sendCSSurvey = !CustomSettingUtils.getOverrideSettingValue('Send Customer Care Survey');
        Boolean sendACSurvey = !CustomSettingUtils.getOverrideSettingValue('Send Account Consultant Survey');
    
        Set<String> invalidCaseTypes = new Set<String>(CustomSettingUtils.getProcessConfigurationValues('SurveyExclude', 'Case.Type'));
        Set<String> invalidCaseOrigins = new set<string>(CustomSettingUtils.getProcessConfigurationValues('SurveyExclude', 'Case.Origin'));
        Set<String> validCSRCaseOrigins = new Set<String>(CustomSettingUtils.getProcessConfigurationValues('CSRSurveyInclude', 'Case.Origin'));
        Set<String> invalidCareCaseTypes = new Set<String>(CustomSettingUtils.getProcessConfigurationValues('CareSurveyExclude', 'Case.Type'));
        Set<Id> acctIds = new Set<Id>();
        
        String strRecordTypeNetX = [Select Id From RecordType Where SobjectType = 'Case' and Name = 'NetEx Case'].Id;
        for(Case c : Cases){
            if (c.RecordTypeId != strRecordTypeNetX )
                acctIds.add(c.AccountId);
        }
        
        //Map<Id, Account> accounts = new Map<Id, Account>([select Id, Account_Sales_Channel__c from account where Id in :acctIds]);
        Map<Id, Account> accounts = new Map<Id, Account>([select Id, Account_Sales_Channel__c, Care_Organization_Name__c from account where Id in :acctIds]);
        user currentUser = [select Id, Title, Department from User where Id = :UserInfo.getUserId() limit 1];
        Set<Id> ACIds = new Set<Id>();
        Set<Id> CAMIds = new Set<Id>();
        Boolean userIsCSR = currentUser.Title.startsWithIgnoreCase('Client Services Representative');
        
        for(AccountTeamMember atm : [Select UserId, TeamMemberRole from AccountTeamMember where (TeamMemberRole = 'Account Consultant' or TeamMemberRole = 'Customer Account Manager') and UserId = :currentUser.Id]){
            Set<Id> daSet = atm.TeamMemberRole == 'Account Consultant'? ACIds : atm.TeamMemberRole == 'Customer Account Manager'? CAMIds : null;
            daSet.add(atm.UserId);
        }
        for(Case c : Cases){
            Case oldC = oldCases.get(c.Id);
            Account act = accounts.get(c.AccountId);
            
            if(oldC.Status != 'Closed' && c.Status == 'Closed' && act != null && act.Account_Sales_Channel__c != 'Wholesale' && act.Account_Sales_Channel__c != 'ILEC' && act.Care_Organization_Name__c != 'Small Business'){
                if (currentUser.Department == 'Allstream - Care' && !invalidCareCaseTypes.contains(c.Type)) { //this should look at case owner department but that is not easily available without doing another lookup
                    SurveyCreatorParams param = new SurveyCreatorParams();
                    param.daObject = c;
                    param.CaseId = c.Id;
                    param.AccountId = c.AccountId;
                    SurveyType st = SurveyType.ALLSTREAM_CUSTOMER_CARE;
                    param.SurveyType = st;
                    ret.add(param);                            
                }   
            }
                
                
            if(oldC != null && !invalidCaseTypes.contains(c.Type) && !invalidCaseOrigins.contains(c.Origin)){
                //Account act = accounts.get(c.AccountId);
                Boolean userIsAC = ACIds.contains(currentUser.Id);
                Boolean userIsCAM = CAMIds.contains(currentUser.Id);
               
                /*  
                if(oldC.Status != 'Closed' && c.Status == 'Closed' && act != null && act.Account_Sales_Channel__c != 'Wholesale' && act.Account_Sales_Channel__c != 'ILEC'){
                    if(sendCAMSurvey && act.Account_Sales_Channel__c == 'Integra Business' && (c.Origin == 'Account Review Virtual' || c.Origin == 'Account Review Visit') && c.Type == 'Proactive' && userIsCAM && !userIsCSR && !userIsAC){
                        SurveyCreatorParams param = new SurveyCreatorParams();
                        param.daObject = c;
                        param.CaseId = c.Id;
                        param.AccountId = c.AccountId;
                        SurveyType st = SurveyType.CUSTOMER_ACCOUNT_MANAGER;
                        param.SurveyType = st;
                        ret.add(param);
                    }
                    else if(sendACSurvey && (act.Account_Sales_Channel__c == 'Government and Education' || act.Account_Sales_Channel__c == 'Electric Lightwave Premier') && c.Origin == 'Account Review Visit' && c.Type == 'Proactive' && userIsAC && !userIsCAM && !userIsCSR){
                        SurveyCreatorParams param = new SurveyCreatorParams();
                        param.daObject = c;
                        param.CaseId = c.Id;
                        param.AccountId = c.AccountId;
                        SurveyType st = SurveyType.ACCOUNT_CONSULTANT;
                        param.SurveyType = st;
                        ret.add(param); 
                    }
                    else if(sendCSSurvey && validCSRCaseOrigins.contains(c.Origin) && c.Type != 'Proactive' && userIsCSR && !userIsCAM && !userIsAC && !act.Account_Sales_Channel__c.startsWithIgnoreCase('integra')){
                        SurveyCreatorParams param = new SurveyCreatorParams();
                        param.daObject = c;
                        param.CaseId = c.Id;
                        param.AccountId = c.AccountId;
                        SurveyType st = SurveyType.CUSTOMER_CARE;
                        param.SurveyType = st;
                        ret.add(param); 
                    }
                }
                */ //commented out based on Terrie's response
            }
        }
        return ret;
    }
    
    private static Map<Id, List<Survey__c>> crtSvysFrmCs(List<SurveyCreatorParams> params){
        List<SurveyCreatorParams> surveysToSend = new List<SurveyCreatorParams>();
        Map<Id, List<Survey__c>> newSvys = new Map<Id, List<Survey__c>>();
        List<Case> Cases = new List<Case>();
        Set<Id> acctIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        
        for(SurveyCreatorParams param : params){
            Cases.add((Case)param.daObject);
            Id actId = param.AccountId;
            if(actId != null)
                acctIds.add(actId);
            
            if (param.Contacts != null) {
                for(Contact c: param.Contacts)
                    contactIds.add(c.id);  
            }
        }
        Map<Id, Set<Contact>> contactsByCaseId = CustomerSurveyUtils.getSurveyableContactForCases(cases);
            
        Integer daysBetweenCAMSurveys = getSurveyDelay('CustomerAccountManager');
        Map<Id,Date> LastCAMSurveyedDateByAcctId = getLastSurveyedDates(acctIds, CUSTOMER_ACCOUNT_MANAGER_SURVEY_NAME);
        Integer daysBetweenACSurveys = getSurveyDelay('AccountConsultant');
        Map<Id,Date>LastACSurveyedDateByAcctId = getLastSurveyedDates(acctIds, ACCOUNT_CONSULTANT_SURVEY_NAME);
        Integer daysBetweenCSSurveys = getSurveyDelay('CustomerCare');
        Map<Id,Date>LastCSSurveyedDateByAcctId = getLastSurveyedDates(acctIds, CUSTOMER_CARE_SURVEY_NAME);
        
        for (Id CaseID: contactsByCaseId.keySet()) {
            Set<Contact> contacts =  contactsByCaseId.get(CaseID);
            for (Contact contact: contacts)
                contactIds.add(contact.id);
        }
        Map<Id,Date>LastNewCSSurveyedDateByContactId = getLastSurveyedDatesByContact(contactIds, ALLSTREAM_CUSTOMER_CARE_SURVEY_NAME);

        
        for(SurveyCreatorParams param : params){
            param.contacts = contactsByCaseId.get(param.daObject.Id);
            if(param.SurveyType == SurveyType.CUSTOMER_ACCOUNT_MANAGER){
                if(param.AccountId != null && canSurvey(daysBetweenCAMSurveys, LastCAMSurveyedDateByAcctId.get(param.AccountId))){
                    LastCAMSurveyedDateByAcctId.put(param.AccountId, Date.today());
                    surveysToSend.add(param);
                }
            }
            else if(param.SurveyType == SurveyType.ACCOUNT_CONSULTANT){
                if(param.AccountId != null && canSurvey(daysBetweenACSurveys, LastACSurveyedDateByAcctId.get(param.AccountId))){
                    LastACSurveyedDateByAcctId.put(param.AccountId, Date.today());
                    surveysToSend.add(param);
                }
            }
            else if(param.SurveyType == SurveyType.CUSTOMER_CARE) {
                if(param.AccountId != null && canSurvey(daysBetweenCSSurveys, LastCSSurveyedDateByAcctId.get(param.AccountId))){
                    LastCSSurveyedDateByAcctId.put(param.AccountId, Date.today());
                    surveysToSend.add(param);
                }
            }
            else if(param.SurveyType == SurveyType.ALLSTREAM_CUSTOMER_CARE && param.Contacts != null){
                for (Contact c: param.Contacts) {
                    if(c != null && canSurvey(daysBetweenCSSurveys, LastNewCSSurveyedDateByContactId.get(c.Id))){
                        LastNewCSSurveyedDateByContactId.put(c.Id, Date.today());
                        //if there are multiple contacts to survey, if could be possible one was recently surveyed and one was not
                        //if this is the case, we are still surveying all contacts, I beleive.
                        surveysToSend.add(param);
                    }
                }
            }                   
        }
        List<SurveyCreatorParams> fails = new List<SurveyCreatorParams>();
        return new SurveyCreator().Create(surveysToSend, fails);
    }
    
    
    private static List<SurveyCreatorParams> getOrdersToSurvey(List<Sub_Order__c> soList, Map<Id, Order__c> Ords, Map<Id, List<Workstep__c>> soWSMap){
        List<SurveyCreatorParams> ret = new List<SurveyCreatorParams>();
        custDetailIdsForSurvey = new Set<Id>();
        Set<String> excludeWholeSaleCareOrgs = new Set<String>(CustomSettingUtils.getProcessConfigurationValues('SurveyExclude', 'WholesaleCareOrg'));
        if(!CustomSettingUtils.getOverrideSettingValue('Send Post Install Survey')){
            for (Sub_Order__c so : soList) {
                Order__c ord = ords.get(so.order__c);
                for(Workstep__c ws : soWSMap.get(so.Id)){
                    String wsName = ws.Name.toLowerCase();  //todo: we shouldn't be string checking a modifyable name
                    if (wsName == ('Confirm Customer Acceptance').toLowerCase()) {
                        if(ord != null && so.External_Order__r != null && so.External_Order__r.Type__c == 'Install Order'){
                            if((so.External_Products__c != null && so.External_Products__c.contains('UC Cloud')) || !excludeWholeSaleCareOrgs.contains(ord.Care_Organization__c)){
                                SurveyCreatorParams param = new SurveyCreatorParams();
                                param.daObject = ord;
                                param.OpportunityId = ord.Opportunity__c;
                                param.AccountId = OrderUtils.getAccountIdFromOrder(ord);
                                param.orderId = ord.Id;
                                if(so.External_Products__c != null && so.External_Products__c.contains('UC Cloud')){
                                    param.SurveyType = SurveyType.POST_INSTALL_UC;
                                }else{
                                    //param.SurveyType = SurveyType.POST_INSTALL;
                                    param.SurveyType = SurveyType.ALLSTREAM_CUSTOMER_SATISFACTION;
                                }
                                ret.add(param);
                                custDetailIdsForSurvey.add(so.Service_Location__r.Customer_Detail__c);
                                custDetailIdsForSurvey.add(so.Service_Location__r.Account__r.Customer_Detail__c);
                            }    
                        }
                    }
                }
            }
        }
        return ret;
    }
    
    private static Map<Id, List<Survey__c>> crtSvysFrmOrds(List<SurveyCreatorParams> params){
        List<SurveyCreatorParams> surveysToSend = new List<SurveyCreatorParams>();
        List<Order__c> Ords = new List<Order__c>();
        Set<Id> acctIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();         
        for(SurveyCreatorParams  param : params){
            Ords.add((order__c)param.daObject);
            Id actId = param.AccountId;
            if(actId != null)
                acctIds.add(actId);
            if(param.orderId != null){
                orderIds.add(param.orderId);
            }                
        }
        Map<Id, Set<Contact>> contactsByOrdId = getSurveyableContactsForOrder(Ords);
            
        Integer daysBetweenSurveys = getSurveyDelay('PostInstall');
        Map<Id,Date> LastSurveyedDateByAcctId = getLastSurveyedDates(acctIds, ORDER_COMPLETION_SURVEY_NAME);
        
        Integer daysBetweenUCSurveys = getSurveyDelay('PostInstallUC');
        Map<Id,Date> LastUCSurveyedDateByAcctId = getLastSurveyedDates(acctIds, ALLSTREAM_INSTALLATION_SURVEY_NAME);
        
        Integer daysBetweenNonUCSurveys = 0; //SEAL-2267, no delay for non UC survey
        Map<Id,Date> lastUCSurveyedDateByOrderId = getLastSurveyedDatesByOrder(orderIds, ALLSTREAM_CUSTOMER_SATISFACTION_SURVEY_NAME);
        
        for(SurveyCreatorParams param : params){
            param.Contacts = contactsByOrdId.get(param.daObject.Id);
            if(param.SurveyType == SurveyType.POST_INSTALL){
                if(param.AccountId != null && canSurvey(daysBetweenSurveys, LastSurveyedDateByAcctID.get(param.AccountId))){
                    LastSurveyedDateByAcctID.put(param.AccountId, Date.today());
                    surveysToSend.add(param);
                }
            }else if(param.SurveyType == SurveyType.POST_INSTALL_UC){
                if(param.AccountId != null && canSurvey(daysBetweenUCSurveys, LastUCSurveyedDateByAcctID.get(param.AccountId))){
                    LastSurveyedDateByAcctID.put(param.AccountId, Date.today());
                    surveysToSend.add(param);
                }
            }else if(param.SurveyType == SurveyType.ALLSTREAM_CUSTOMER_SATISFACTION ){
                if(param.AccountId != null && canSurvey(daysBetweenNonUCSurveys, lastUCSurveyedDateByOrderId.get(param.daObject.Id))){
                    lastUCSurveyedDateByOrderId.put(param.daObject.Id, Date.today());
                    surveysToSend.add(param);
                }                
            }
        }
        List<SurveyCreatorParams> fails = new List<SurveyCreatorParams>();
        return new SurveyCreator().Create(surveysToSend, fails);
    }
        
    private static void InsertSurveysAndSendMail(Map<Id, List<Survey__c>> svysByParentId){
        List<Survey__c> svys = new List<Survey__c>();
        for(Id parentId : svysByParentId.keyset()){
            for(Survey__c svy : svysByParentId.get(parentId)){
                svys.add(svy);
            }
        }
        try{
            SecurityUtils.BypassProcesser.saveObjects(svys, true);
        }
        catch(Exception exp){
            
        }
        SendSurveyEmails(svysByParentId);
    }
    
    private static void SendSurveyEmails(Map<Id, List<Survey__c>> svysByParentId){
        List<Survey__c> Surveys = new List<Survey__c>();
        List<Integration_Error__c> errors = new List<Integration_Error__c>();
        Map<Id, Id> contactIdBySvyId = new Map<Id, Id>();
        for(List<Survey__c> svys : svysByParentId.values()){
            for(Survey__c svy : svys){
                contactIdBySvyId.put(svy.Id, svy.Surveyed_Contact__c);
            }
        }
        Map<Id, Contact> contactById = new Map<Id, Contact>([select c.Name, c.Email, c.HasOptedOutOfEmail, c.Default_Responsible_Party__c, c.AccountId, c.Default_Contact_Types__c from Contact c where c.id in :contactIdBySvyId.values()]);
        for(Id parentId : svysByParentId.keySet()){
            for(Survey__c svy : svysByParentId.get(parentId)){
                Contact con = contactById.get(contactIdBySvyId.get(svy.Id));
                String templateName = svy.Survey_Name__c.replaceAll(' ', '_');
                String errorMsg = '';
                if(con != null && !String.isEmpty(con.Email) && !con.HasOptedOutOfEmail)
                    errorMsg = sendCustomerSurveyEmail(parentId, new Set<Id>{svy.Surveyed_Contact__c}, templateName);
                else{
                    if(con == null) errorMsg = NULL_CONTACT_MSG;
                    else if(String.isEmpty(con.Email)) errorMsg = NO_EMAIL_MSG;
                    else if(con.HasOptedOutOfEmail) errorMsg = OPTED_OUT_STATUS_MSG;
                }
                
                if(!String.isEmpty(errorMsg)){
                    Integration_Error__c e = new Integration_Error__c();
                    e.Message__c = errorMsg;
                    e.Info__c = svy.sent_status__c;
                    e.ObjectID__c = svy.Id;
                    e.RelatedID__c = parentId;
                    svy.sent_status__c = 'Error sending. View survey errors for more information.';
                    errors.add(e);
                }
                else
                    svy.sent_status__c = SURVEY_SENT_MSG;
                
                Surveys.add(svy);
            }
        }
        if(Surveys.size() > 0)
            SecurityUtils.BypassProcesser.saveObjects(Surveys, true);
        if(errors.size() > 0)
            insert errors;
    }
    
    private static Map<String, Id> templateIDsByName = null;
    private static String sendCustomerSurveyEmail(Id parentObjectID, Set<Id> contacts, String TemplateName){
        if(templateIDsByName == null){
            templateIDsByName = new Map<String, Id>();
            for(EmailTemplate et : [select Id, DeveloperName from EmailTemplate where Folder.DeveloperName = 'Workflow_and_Approval_Templates'])
                templateIDsByName.put(et.DeveloperName, et.Id);
        }
        
        Id etID = templateIDsByName.get(TemplateName);
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Id cid : contacts){
            if(etID != null){
                Messaging.SingleEmailMessage email = ApexUtils.createTemplatedEmailMessage(cid, etID, parentObjectID);
                if (TemplateName == RECOMMEND_ALLSTREAM_SURVEY_NAME.replaceAll(' ', '_') || TemplateName == RECOMMEND_ALLSTREAM_REMINDER_SURVEY_NAME.replaceAll(' ', '_') || TemplateName == ALLSTREAM_CUSTOMER_CARE_SURVEY_NAME.replaceAll(' ', '_') || TemplateName == ALLSTREAM_CUSTOMER_SATISFACTION_SURVEY_NAME.replaceAll(' ', '_'))
                    email.setOrgWideEmailAddressId(CustomerExperienceOrgWideId);
                else If(TemplateName == ALLSTREAM_INSTALLATION_SURVEY_NAME.replaceAll(' ', '_'))
                    email.setOrgWideEmailAddressId(AllstreamInstallationOrgWideId);
                else
                    email.setOrgWideEmailAddressId(MarketingOrgWideId);
                emails.add(email);
            }
            else{
                return 'Couldn\'t find template named: "' + TemplateName + '". email not sent.';
            }
        }
        
        if(emails.size() > 0){
            try{
                ApexUtils.sendEmails(emails);
            }
            catch(Exception exp){
                return exp.getMessage();
            }
        }
        return '';
    }
        
    private static Map<Id, Date> getLastSurveyedDates(Set<Id> accountIds, String svyName){
        Map<Id, Date> ret = new Map<Id, Date>();
        for(Id aid : accountIds) ret.put(aid, null);
        List<AggregateResult> svys = [select max(Sent_Date__c) sd, Account__c from Survey__c where Name = :svyName and Account__c in :accountIds group by Account__c];
        for(AggregateResult svy : svys){
            Id aid = String.valueOf(svy.get('Account__c'));
            Date d = Date.valueOf(svy.get('sd'));
            ret.put(aid, d);
        }
        return ret;
    }

    private static Map<Id, Date> getLastSurveyedDatesByContact(Set<Id> contactIds, String svyName){
        Map<Id, Date> ret = new Map<Id, Date>();
        for(Id cid : contactIds) ret.put(cid, null);
        List<AggregateResult> svys = [select max(Sent_Date__c) sd, Surveyed_Contact__c from Survey__c where Name = :svyName and Surveyed_Contact__c in :contactIds group by Surveyed_Contact__c];
        for(AggregateResult svy : svys){
            Id cid = String.valueOf(svy.get('Surveyed_Contact__c'));
            Date d = Date.valueOf(svy.get('sd'));
            ret.put(cid, d);
        }
        return ret;
    }

    private static Map<Id, Date> getLastSurveyedDatesByOrder(Set<Id> orderIds, String svyName){
        Map<Id, Date> ret = new Map<Id, Date>();
        for(Id oid : orderIds) ret.put(oid, null);
        List<AggregateResult> svys = [select max(Sent_Date__c) sd, Order__c from Survey__c where Name = :svyName and Order__c in :orderIds group by Order__c];
        for(AggregateResult svy : svys){
            Id oid = String.valueOf(svy.get('Order__c'));
            Date d = Date.valueOf(svy.get('sd'));
            ret.put(oid, d);
        }
        return ret;
    }    
    
    private static Integer getSurveyDelay(String svyNm){
        Integer daysBetweenSurveys = 30; //default value
        List<String> vals = customSettingUtils.getProcessConfigurationValues('SurveyDelay', svyNm);
        if(vals.size() > 0)
            daysBetweenSurveys = Integer.valueOf(vals[0]);
        return daysBetweenSurveys;
    }
    
    private static Boolean canSurvey(Integer minDays, Date lastSurveyed){
        Boolean ret = false;
        if(lastSurveyed == null)
            ret = true;
        else{
            Integer daysBetween = Math.abs(Date.today().daysBetween(lastSurveyed));
            if(daysBetween > minDays)
                ret = true;
            else
                ret = false;
        }
        return ret;
    }
    
    private static Map<Id, Set<Contact>> getSurveyableContactsForOrder(List<Order__c> ords){
        Map<Id, Set<Contact>> ContactsByOrdId = new Map<Id, Set<Contact>>();
        Map<Id, Id> OrdIdByAccountId = new Map<Id, Id>();
        for(Order__c ord : ords){
            Id actId = OrderUtils.getAccountIdFromOrder(ord);
            if(actId != null)
                OrdIdByAccountId.put(actId, ord.Id);
        }
        
        List<Contact> cs = new List<Contact>();
        cs = [select (Select Contact_Type__c from Customer_Contacts__r where Customer_Detail__c in :custDetailIdsForSurvey and Contact_Type__c = 'Responsible Party'), c.Name, c.Email, c.HasOptedOutOfEmail, c.Default_Responsible_Party__c, c.AccountId, c.Default_Contact_Types__c from Contact c where c.AccountId in :OrdIdByAccountId.keyset()];
        for(Contact c : cs){
            Id ordId = OrdIdByAccountId.get(c.AccountId);
            Set<Contact> cts = ContactsByOrdId.get(ordId);
            if(cts == null) cts = new Set<Contact>();
            if(c.Customer_Contacts__r.size() >0 && !cts.contains(c)){
                cts.add(c);
            }
            ContactsByOrdId.put(ordId, cts);
        }
        return ContactsByOrdId;
    }
    
    /*private static Map<Id, Set<Contact>> getSurveyableContactsForAccount(Set<Id> accountIds){
        Map<Id, Set<Contact>> ret = new Map<Id, Set<Contact>>();
        
        List<Contact> cs = new List<Contact>();
        cs = [select (Select Contact_Type__c from Customer_Contacts__r), c.Name, c.Email, c.HasOptedOutOfEmail, c.Default_Responsible_Party__c, c.AccountId, c.Default_Contact_Types__c from Contact c where c.AccountId in :accountIds];
        for(Contact c : cs){
            Id actId = c.AccountId;
            Set<Contact> cts = ret.get(actId);
            if(cts == null) cts = new Set<Contact>();
            if(!cts.contains(c) && (c.Default_Responsible_Party__c || (c.Default_Contact_Types__c != null && ( c.Default_Contact_Types__c.contains('Local Contact') || c.Default_Contact_Types__c.contains('Authorized User')))))
                cts.add(c);
            ret.put(actId, cts);
        }
        
        return ret;
    }*/
    
    private static Map<Id, Set<Contact>> getSurveyableContactForCases(List<Case> Cases){
        Map<Id, Set<Contact>> ret = new Map<Id, Set<Contact>>();
        Set<Id> conIds = new Set<Id>();
        for(Case c : cases){
            conIds.add(c.contactId);
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>([select (Select Contact_Type__c from Customer_Contacts__r), c.Name, c.Email, c.HasOptedOutOfEmail, c.Default_Responsible_Party__c, c.AccountId, c.Default_Contact_Types__c from Contact c where id in :conIds]);
        for(Case c : cases){
            Set<contact> cts = ret.get(c.Id);
            if(cts == null) cts = new Set<Contact>();
            Contact con = contacts.get(c.ContactId);
            if(con != null){
                cts.add(con);
                ret.put(c.Id, cts);
            }
        }
        return ret;
    }
    
    public class SurveyCreatorParams{
        public SObject daObject {get;Set;}
        public SurveyType SurveyType {get;Set;}
        public Id AccountId {get;Set;}
        public Id OpportunityId {get;Set;}
        public Id CaseId {get;Set;}
        public Id orderId {get;Set;} 
        public Set<Contact> Contacts {get;Set;}
                        
        public SurveyCreatorParams(){
            daObject = null;
            SurveyType = null;
            AccountId = null;
            OpportunityId = null;
            CaseId = null;
            orderId = null;
            contacts = null;
        }
    }
    
    public class SurveyCreator{
        public SurveyCreator(){}
        
        public Map<Id, List<Survey__c>> Create(List<SurveyCreatorParams> params, List<SurveyCreatorParams> failedList){
            Map<Id, List<Survey__c>> ret = new Map<Id, List<Survey__c>>();
            for(SurveyCreatorParams param : params){
                List<Survey__c> newSurveys = Create(param);
                if(newSurveys != null && newSurveys.size() > 0){
                    List<Survey__c> svys = ret.get(param.daObject.Id);
                    if(svys == null) svys = new List<Survey__c>();
                    svys.addAll(newSurveys);
                    ret.put(param.daObject.Id, svys);
                }
                else
                    failedList.add(param);
            }
            return ret;
        }
        
        private List<Survey__c> Create(SurveyCreatorParams param){
            List<Survey__c> ret = new List<Survey__c>();
            String SurveyName = '';
            String ShortName = '';
            if(param.SurveyType == SurveyType.POST_INSTALL){
                SurveyName = ShortName = ORDER_COMPLETION_SURVEY_NAME;
            }
            else if(param.SurveyType == SurveyType.CUSTOMER_ACCOUNT_MANAGER){
                SurveyName = ShortName = CUSTOMER_ACCOUNT_MANAGER_SURVEY_NAME;
            }
            else if(param.SurveyType == SurveyType.SALES_EXPERIENCE_WON){
                SurveyName = SALES_EXPERIENCE_WON_SURVEY_NAME;
                ShortName = 'Sales Experience';
            }
            else if(param.SurveyType == SurveyType.SALES_EXPERIENCE_LOST){
                SurveyName = SALES_EXPERIENCE_LOST_SURVEY_NAME;
                ShortName = 'Sales Experience';
            }
            else if(param.SurveyType == SurveyType.ACCOUNT_CONSULTANT){
                SurveyName = ShortName = ACCOUNT_CONSULTANT_SURVEY_NAME;
            }
            else if(param.SurveyType == SurveyType.CUSTOMER_CARE){
                SurveyName = ShortName = CUSTOMER_CARE_SURVEY_NAME;
            }
            else if(param.SurveyType == SurveyType.ALLSTREAM_CUSTOMER_CARE){
                SurveyName = ShortName = ALLSTREAM_CUSTOMER_CARE_SURVEY_NAME;
            }
            else if(param.SurveyType == SurveyType.RECOMMEND_ALLSTREAM_SURVEY_NAME){
                SurveyName = ShortName = RECOMMEND_ALLSTREAM_SURVEY_NAME;
            }
            else if(param.SurveyType == SurveyType.RECOMMEND_ALLSTREAM_REMINDER_SURVEY_NAME){
                SurveyName = ShortName = RECOMMEND_ALLSTREAM_REMINDER_SURVEY_NAME;
            }
            else if(param.SurveyType == SurveyType.POST_INSTALL_UC){
                SurveyName = ShortName = ALLSTREAM_INSTALLATION_SURVEY_NAME;
            }
            else if(param.SurveyType == SurveyType.ALLSTREAM_CUSTOMER_SATISFACTION){
                SurveyName = ShortName = ALLSTREAM_CUSTOMER_SATISFACTION_SURVEY_NAME;
            }
            if(param.contacts == null || param.contacts.size() == 0){
                Survey__c newSurvey = new Survey__c();
                newSurvey.Name = ShortName;
                newSurvey.Survey_Name__c = SurveyName;
                newSurvey.Sent_Date__c = Date.today();
                newSurvey.Account__c = param.AccountId;
                newSurvey.Opportunity__c = param.OpportunityId;
                newSurvey.Case__c = param.CaseId;
                 newSurvey.Order__c = param.orderId;
                newSurvey.Surveyed_Contact__c = null;
                ret.add(newSurvey);
            }
            else{
                for(Contact contact : param.contacts){
                    if(contact != null){
                        Survey__c newSurvey = new Survey__c();
                        newSurvey.Name = ShortName;
                        newSurvey.Survey_Name__c = SurveyName;
                        newSurvey.Sent_Date__c = Date.today();
                        newSurvey.Account__c = param.AccountId;
                        newSurvey.Opportunity__c = param.OpportunityId;
                        newSurvey.Case__c = param.CaseId;
                        newSurvey.Order__c = param.orderId;
                        newSurvey.Surveyed_Contact__c = contact.Id;
                        ret.add(newSurvey); 
                    }
                }
            }
            
            return ret;
        }
        
    }
   
    
    public static void createContactSurveys(List<Contact> contacts, SurveyType SurveyName) {
         
        List<SurveyCreatorParams> scps = new List<SurveyCreatorParams>();   
        for (Contact contact : contacts) {
            SurveyCreatorParams param = new SurveyCreatorParams();
            param.daObject = contact;
            param.OpportunityId = null;
            param.AccountId = contact.AccountID;
            param.Contacts = new Set<Contact> {contact};
            param.SurveyType = SurveyName;
            scps.add(param);
        }
        List<SurveyCreatorParams> fails = new List<SurveyCreatorParams>();
        Map<Id, List<Survey__c>> surveys = new SurveyCreator().Create(scps, fails);
        if(!surveys.isEmpty()){
            InsertSurveysAndSendMail(surveys);
        }

    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_CustomerSurveyUtils(); }
}