public without sharing class ICertUtils{

    public static integraWS.CreateICertParamsObj getCustomerBuildTemplate(Account act, Opportunity opp, Building__c bldg, String AEID, String title, String description, Boolean isPreProfiled){        
        User u = [select id, NTID__c from user where id = :UserInfo.getUserId() limit 1];
        
        //opp products from opportunity
        List<Opportunity_Product__c> oppProds = [select Id
                                                        ,Sales_Product__c
                                                        ,Opportunity__r.Id
                                                        from Opportunity_Product__c
                                                        where Opportunity__r.Id = :opp.Id
                                                        and RecordType.Name != 'Turndown'
                                                        and Solution__r.Active__c = true
                                                        and Solution__r.Opportunity_Location__r.On_Hold__c = false];
        String product = '';
        if(oppProds != null && oppProds.size() > 0){
            String comma = '';
            for(Opportunity_Product__c oppProd : oppProds){
                if(oppProd.Sales_Product__c != null && oppProd.Sales_Product__c != ''){
                    product += comma + oppProd.Sales_Product__c;
                    comma = ', ';
                }
            }
        }
        
        //info from opp
        DateTime contractSignedDate = opp.Contract_Signed_Date__c;
        datetime estCompletion = opp.Customer_Requested_Due_Date__c;
        decimal RevenueMRC = opp.CPQ_Total__c;
        decimal NRC = opp.CPQ_NRC_Total__c;
        Integer term = opp.Term__c == null ? null : Integer.valueOf(opp.Term__c);
        
        //info from account
        String salesChannel = '';
        String businessUnit = '';
        salesChannel = CustomSettingUtils.GetICertSalesChannelMapping(act.Owner.Sales_Channel__c);
//      businessUnit = CustomSettingUtils.GetICertBusinessUnitMapping(act.Account_Sales_Channel__c);

        String careOrgName =  act.Customer_Detail__r.Care_Organization__c!=null?CustomerDetailUtils.getCareOrgById(act.Customer_Detail__r.Care_Organization__c).Name:null;
        businessUnit = CustomSettingUtils.GetICertBusinessUnitMapping(careOrgName);
        string CustomerName = act.Name;
        
        //info from building
        string LocalGeographicalArea = GlobalUtilities.StateCodeToName.get(bldg.State__c.toUpperCase());
        //paramObj.Address = bldg.Address__c + ', ' + bldg.City__c; address to be set by caller!
        List<String> cllis = new List<String>();
        String locationType = bldg.Net_Classification__c == 'On-net'? 'Existing' : 'New';
        
        //info from solution
        //paramObj.ProductBandwidth = solution != null ? solution.Bandwidth__c : ''; bandwidth to be set by caller!
                
        //static assignment
        string RequestType = 'Customer Build' + (isPreProfiled ?' - ' + bldg.Net_Classification__c.replace('-net', '-Net') + ' - Pre-Profiled : (SOLD)' : '');
        string BuildCategory = 'Customer';
        string RoutingProcess = 'Standard';
        datetime StartDate = DateTime.now();
        string AccountManager = opp.Owner.NTID__c;
        
        //others
        string UserNTID = u.NTID__c;
        string ContactNTID = AEID;
        string requestTitle = title.replace('{products}', product);
        string detaileddescription = description;       
        
        return createParamObjFromInputs(product, contractSignedDate, estCompletion, RevenueMRC, NRC, term, salesChannel, businessUnit, CustomerName, LocalGeographicalArea, cllis, locationType, requestType, buildCategory, routingProcess, StartDate, accountManager, UserNTID, ContactNTId, requestTitle, description);
    }
    
    public static integraWS.CreateICertParamsObj getNetworkBuildTemplate(Building__c bldg, String AEID, String title, String description, string ownerSalesChannel, string businessUnit, string department, Date estCompleteDate){      
        User u = [select id, NTID__c from user where id = :UserInfo.getUserId() limit 1];
                
        //info from opp
        String product = '';
        DateTime contractSignedDate = null;//Datetime.now(); //need contract signed date;
        datetime estCompletion = estCompleteDate; //need estimated completion date opp.Customer_Requested_Due_Date__c;
        decimal RevenueMRC = 0.0; //need revenueMRC
        decimal NRC = 0.0; //need NRC
        Integer term = 0; // need term
        
        //info from account
        String salesChannel = '';
        string CustomerName = ''; //need customer name
        salesChannel = CustomSettingUtils.GetICertSalesChannelMapping(ownerSalesChannel);
        CustomerName = department;
        
        //info from building
        string LocalGeographicalArea = GlobalUtilities.StateCodeToName.get(bldg.State__c.toUpperCase());
        //paramObj.Address = bldg.Address__c + ', ' + bldg.City__c; address to be set by caller!
        List<String> cllis = new List<String>();
        String locationType = bldg.Net_Classification__c == 'On-net'? 'Existing' : 'New';
        
        //info from solution
        //paramObj.ProductBandwidth = solution != null ? solution.Bandwidth__c : ''; bandwidth to be set by caller!
                
        //static assignment
        string RequestType = 'Network Build';
        string BuildCategory = 'Network';
        string RoutingProcess = 'Standard';
        datetime StartDate = DateTime.now(); //need start date
        string AccountManager = ''; //need account manager
        
        //others
        string UserNTID = u.NTID__c;
        string ContactNTID = AEID;
        string requestTitle = title;
        string detaileddescription = description;       
        
        return createParamObjFromInputs(product, contractSignedDate, estCompletion, RevenueMRC, NRC, term, salesChannel, businessUnit, CustomerName, LocalGeographicalArea, cllis, locationType, requestType, buildCategory, routingProcess, StartDate, accountManager, UserNTID, ContactNTId, requestTitle, description);
    }
    
    private static integraWS.CreateICertParamsObj createParamObjFromInputs(String product, Datetime contractSignedDate, Datetime estCompletion, Decimal revenueMRC, Decimal NRC, Integer term, String salesChannel, String businessUnit, String customerName, String LocalGeographicalArea, List<String> cllis, String locationType, String RequestType, String buildCategory, String routingProcess, Datetime StartDate, string accountManager, string UserNTID, String ContactNTID, string title, String Description){
        integraWS.CreateICertParamsObj paramObj = new integraWS.CreateICertParamsObj();
        
        paramObj.Product = product;
        paramObj.ContractSignedDate = contractSignedDate;
        paramObj.EstCompletion = estCompletion;
        paramObj.RevenueMRC = revenueMRC;
        paramObj.NRC = NRC;
        paramObj.ContractTerm = term;
        
        paramObj.BusinessUnit = businessUnit;
        paramObj.BusinessUnitID = 0;
        paramObj.SalesChannel = salesChannel;
        paramObj.SalesChannelID = 0;
        paramObj.CustomerName = customerName;
        
        paramObj.LocalGeographicalArea = LocalGeographicalArea;
        paramObj.LocalGeographicalAreaID = 0;
        //paramObj.Address = bldg.Address__c + ', ' + bldg.City__c; address to be set by caller!
        schemasMicrosoftCom200310Serializat.ArrayOfstring aosCllis = new schemasMicrosoftCom200310Serializat.ArrayOfstring();
        aosCllis.string_x = cllis;
        paramObj.CLLIs = aoscllis;
        paramObj.LocationType = locationType;
        
        //info from solution
        //paramObj.ProductBandwidth = solution != null ? solution.Bandwidth__c : ''; bandwidth to be set by caller!
                
        //static assignment
        paramObj.RequestType = RequestType;
        paramObj.RequestTypeID = 0;
        paramObj.BuildCategory = buildCategory;
        paramObj.BuildCategoryID = 0;       
        paramObj.RoutingProcess = routingProcess;
        paramObj.RoutingProcessID = 0;
        paramObj.Expedite = false;
        paramObj.Strategic = false;
        paramObj.StartDate = StartDate;
        paramObj.ProductId = 0;
        paramObj.AccountManager = accountManager;
        
        //others
        paramObj.UserNTID = UserNTID;
        paramObj.ContactNTID = ContactNTID;
        paramObj.title = title;
        paramObj.detaileddescription = Description;     
        return paramObj;
    }
    
    public static List<SFICertView> CreateICerts(List<integraWS.CreateICertParamsObj> params, String session){
        integraWS.ArrayOfSFICertResponseView a = null;
        if(params != null && params.size() > 0 && integraWSEndpointMediator.integrationEnabled()){
            integraWS.ArrayOfCreateICertParamsObj paramsObjs = new integraWS.ArrayOfCreateICertParamsObj();
            paramsObjs.CreateICertParamsObj = params;
            a = integraWSEndpointMediator.Endpoint.CreateICerts(paramsObjs, session, CustomSettingUtils.SFDCCallbackEndpoint);
        }
        return a == null ? (integraWSEndpointMediator.integrationEnabled()? null : new List<SFICertView>{new SFICertView()}) : GetICertViews(a.SFICertResponseView);
    }
    
    public static List<SFICertView> CreateICertsAndCompleteRequestOrigStep(List<integraWS.CreateICertParamsObj> params, String session){
        integraWS.ArrayOfSFICertResponseView a = null;
        if(params != null && params.size() > 0 && integraWSEndpointMediator.integrationEnabled()){
            integraWS.ArrayOfCreateICertParamsObj paramsObjs = new integraWS.ArrayOfCreateICertParamsObj();
            paramsObjs.CreateICertParamsObj = params;
            a = integraWSEndpointMediator.Endpoint.CreateICertsAndCompleteRequestOrigStep(paramsObjs, session, CustomSettingUtils.SFDCCallbackEndpoint);
        }

        return a == null ? (integraWSEndpointMediator.integrationEnabled()? null : new List<SFICertView>{new SFICertView()}) : GetICertViews(a.SFICertResponseView);
    }
    
    public static List<SFICertView> GetICertsByIds(List<Integer> icertIds){
        integraWS.ArrayOfSFICertResponseView a = null;
        if(icertIds != null && icertIds.size() > 0 && integraWSEndpointMediator.integrationEnabled()){
            schemasMicrosoftCom200310Serializat.ArrayOfint aois = new schemasMicrosoftCom200310Serializat.ArrayOfint();
            aois.int_x = icertIds;
            a = integraWSEndpointMediator.Endpoint.GetICertsByIds(aois, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
        }
        return a == null ? (integraWSEndpointMediator.integrationEnabled()? null : new List<SFICertView>{new SFICertView()}) : GetICertViews(a.SFICertResponseView);
    }
    
    public static List<SFICertView> GetICertViews(List<integraWS.SFICertResponseView> rvs){
        List<SFICertView> views = new List<SFICertView>();
        for(integraWS.SFICertResponseView rv: rvs){
            views.add(new SFICertView(rv));
        }
        return views;
    }
    
    public static List<SFRoutingStepView> GetRoutingStepsByICertId(Integer icertId){
        integraWS.SFGetRequestApprovalsResponseView a = null;
        if(icertId > 0 && integraWSEndpointMediator.integrationEnabled()){
            a = integraWSEndpointMediator.Endpoint.GetRequestApprovals(icertId, UserInfo.getSessionId(), CustomSettingUtils.SFDCCallbackEndpoint);
        }
        return a == null ? null : a.RoutingSteps == null ? null : GetRoutingStepViews(a.RoutingSteps.SFRequestApprovalView);
    }
    
    public static List<SFRoutingStepView> GetRoutingStepViews(List<integraWS.SFRequestApprovalView> rvs){
        List<SFRoutingStepView> views = new List<SFRoutingStepView>();
        for(integraWS.SFRequestApprovalView rv : rvs){
            views.add(new SFRoutingStepView(rv));
        }
        return views;
    }

    public class SFICertView{       
        public SFICertView(){
            if(Test.isRunningTest()) this.Id = 1;
        }
        public SFICertView(integraWS.SFICertResponseView rv){
            this.AccountExecutiveID = rv.AccountExecutiveID;
            this.Address = rv.Address;
            this.AssignedToNTId = rv.AssignedToNTId;
            this.BuildCategoryDesc = rv.BuildCategoryDesc;
            this.BuildCategoryID = rv.BuildCategoryID;
            this.BusinessUnit = rv.BusinessUnit;
            this.BusinessUnitID = rv.BusinessUnitID;
            this.ContactEmail = rv.ContactEmail;
            this.ContactNTId = rv.ContactNTId;
            this.ContactPhone = rv.ContactPhone;
            this.CreateDate = rv.CreateDate;
            this.CreateUser = rv.CreateUser;
            this.CreateUserFullName = rv.CreateUserFullName;
            this.CustomerOrDepartment = rv.CustomerOrDepartment;
            this.Description = rv.Description;
            this.DetailedDescription = rv.DetailedDescription;
            this.EstimatedCompletionDate = rv.EstimatedCompletionDate;
            this.Expedite = rv.Expedite;
            this.ExpediteNote = rv.ExpediteNote;
            this.Expense = rv.Expense;
            this.ExpireDate = rv.ExpireDate;
            this.Id = rv.Id;
            this.IsComplete = rv.IsComplete;
            this.LocalGeographicalArea = rv.LocalGeographicalArea;
            this.LocalGeographicalAreaID = rv.LocalGeographicalAreaID;
            this.LocationTypeDesc = rv.LocationTypeDesc;
            this.LocationTypeID = rv.LocationTypeID;
            this.ModDate = rv.ModDate;
            this.ModUser = rv.ModUser;
            this.NextAppRole = rv.NextAppRole;
            this.NextApprovalGroup = rv.NextApprovalGroup;
            this.NextStep = rv.NextStep;
            this.NextStepId = rv.NextStepId;
            this.OMCurrentOrComplete = rv.OMCurrentOrComplete;
            this.Originator = rv.Originator;
            this.ProductDesc = rv.ProductDesc;
            this.ProductID = rv.ProductID;
            this.Project = rv.Project;
            this.ProjectGroupProject = rv.ProjectGroupProject;
            this.ProjectManagerNTId = rv.ProjectManagerNTId;
            this.RequestStateId = rv.RequestStateId;
            this.RequestType = rv.RequestType;
            this.RequestTypeId = rv.RequestTypeId;
            this.RoutingProcessDesc = rv.RoutingProcessDesc;
            this.RoutingProcessID = rv.RoutingProcessID;
            this.SalesChannelDesc = rv.SalesChannelDesc;
            this.SalesChannelID = rv.SalesChannelID;
            this.SalesForceID = rv.SalesForceID;
            this.StartDate = rv.StartDate;
            this.StateName = rv.StateName;
            this.Strategic = rv.Strategic;
            this.Messages = (rv.Messages != null ? rv.Messages.String_x : new List<String>());
        }
        
        public Integer AccountExecutiveID {get;set;}
        public String Address{get;set;}
        public String AssignedToNTId{get;set;}
        public String BuildCategoryDesc{get;set;}
        public Integer BuildCategoryID{get;set;}
        public String BusinessUnit{get;set;}
        public Integer BusinessUnitID{get;set;}
        public String ContactEmail{get;set;}
        public String ContactNTId{get;set;}
        public String ContactPhone{get;set;}
        public DateTime CreateDate{get;set;}
        public String CreateUser{get;set;}
        public String CreateUserFullName{get;set;}
        public String CustomerOrDepartment{get;set;}
        public String Description{get;set;}
        public String DetailedDescription{get;set;}
        public DateTime EstimatedCompletionDate{get;set;}
        public Boolean Expedite{get;set;}
        public String ExpediteNote{get;set;}
        public Decimal Expense{get;set;}
        public DateTime ExpireDate{get;set;}
        public Integer Id{get;set;}
        public Boolean IsComplete{get;set;}
        public String LocalGeographicalArea{get;set;}
        public Integer LocalGeographicalAreaID{get;set;}
        public String LocationTypeDesc{get;set;}
        public Integer LocationTypeID{get;set;}
        public DateTime ModDate{get;set;}
        public String ModUser{get;set;}
        public String NextAppRole{get;set;}
        public String NextApprovalGroup{get;set;}
        public String NextStep{get;set;}
        public Integer NextStepId{get;set;}
        public Boolean OMCurrentOrComplete{get;set;}
        public String Originator{get;set;}
        public String ProductDesc{get;set;}
        public Integer ProductID{get;set;}
        public String Project{get;set;}
        public String ProjectGroupProject{get;set;}
        public String ProjectManagerNTId{get;set;}
        public Integer RequestStateId{get;set;}
        public String RequestType{get;set;}
        public Integer RequestTypeId{get;set;}
        public String RoutingProcessDesc{get;set;}
        public Integer RoutingProcessID{get;set;}
        public String SalesChannelDesc{get;set;}
        public Integer SalesChannelID{get;set;}
        public String SalesForceID{get;set;}
        public DateTime StartDate{get;set;}
        public String StateName{get;set;}
        public Boolean Strategic{get;set;}
        public List<String> Messages {get;Set;}
        public Boolean Success {get;Set;}
    }
    
    public class SFRoutingStepView{
        public SFRoutingStepView(){}
        public SFRoutingStepView(integraWS.SFRequestApprovalView view){
            this.ActualCompletionDate = view.ActualCompletionDate;
            this.ApprovalGroupId = view.ApprovalGroupId;
            this.AssignedTo = view.AssignedTo;
            this.ClassId = view.ClassId;
            this.CreateDate = view.CreateDate;
            this.CreateUser = view.CreateUser;
            this.EstimatedCompletionDate = view.EstimatedCompletionDate;
            this.ID = view.ID;
            this.IsActive = view.IsActive;
            this.IsComplete = view.IsComplete;
            this.ModDate = view.ModDate;
            this.ModUser = view.ModUser;
            this.ProcessOrder = view.ProcessOrder;
            this.ReqApprovalJuncID = view.ReqApprovalJuncID;
            this.ReqBuildApprovalJunctionID = view.ReqBuildApprovalJunctionID;
            this.RequestHeaderID = view.RequestHeaderID;
            this.RequiredCompletionDate = view.RequiredCompletionDate;
            this.StepStateID = view.StepStateID;
        }
        public DateTime ActualCompletionDate{get;set;}
        public Integer ApprovalGroupId{get;set;}
        public String AssignedTo{get;set;}
        public Integer ClassId{get;set;}
        public DateTime CreateDate{get;set;}
        public String CreateUser{get;set;}
        public DateTime EstimatedCompletionDate{get;set;}
        public Integer ID{get;set;}
        public Boolean IsActive{get;set;}
        public Boolean IsComplete{get;set;}
        public DateTime ModDate{get;set;}
        public String ModUser{get;set;}
        public Integer ProcessOrder{get;set;}
        public Integer ReqApprovalJuncID{get;set;}
        public Integer ReqBuildApprovalJunctionID{get;set;}
        public Integer RequestHeaderID{get;set;}
        public DateTime RequiredCompletionDate{get;set;}
        public Integer StepStateID{get;set;}
    }
    
    public TestUtils.TestClass getTestClass(){ return new Test_ICertUtils(); }
}