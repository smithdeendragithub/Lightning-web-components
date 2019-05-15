public with sharing class CapitalProjectController{

	private final String AUTO_MSG = 'Are you sure you want to manually create this location?  If you meet hurdle rate in CPQ your icert will be auto generated and you will not want two icerts.  If you will not meet the hurdle rate and would like to continue on ICB basis, please continue.';
    public Capital_Project__c capitalProject {get;private Set;}
    private Map<Id,OpportunityLocationConfiguration__c> sLocToSolution  {get;private Set;}
    public List<Id> sLocIds {get;private Set;}
	public List<BuildingSelectionElement> bldgSelectElementsConfigured {get; private Set;}
	public List<BuildingSelectionElement> bldgSelectElementsUnConfigured {get; private Set;}
	public Boolean displayBuildingWarning {get;private set;}
	public Boolean haveOppBuildings {
		get{
			return bldgSelectElementsConfigured != null && bldgSelectElementsConfigured.size() > 0;
		}
	}
	public Boolean haveActBuildings{
		get{
			return bldgSelectElementsUnConfigured != null && bldgSelectElementsUnConfigured.size() > 0;
		}
	}
    
    public List<ICertUtils.SFICertView> iCerts {get; Set;}
    public List<ICertUtils.SFRoutingStepView> RoutingSteps {get;Set;}
    public Boolean canCreate {get; private Set;} 
    public Boolean getOppBuildings {get;private Set;}
    public Boolean canAddBuildings {get;private Set;}
	public Boolean hasICertReqFields {get;private Set;}
    public String createICertTitle {get;private Set;}
	public Boolean isWholesale {get;private Set;}
	public Boolean isNetworkBuild {
		get{
			if(capitalProject != null) return capitalProject.RecordTypeId == Schema.SObjectType.Capital_Project__c.getRecordTypeInfosByName().get('Network Build').getRecordTypeID();
			else return false;
		}
	}
    
    public CapitalProjectController(ApexPages.StandardController sc){
		displayBuildingWarning = false;
        loadCapitalProject(sc.getId());
        
        string messages = ApexPages.currentPage().getParameters().get('msgs');
        if(!String.isEmpty(messages)) ApexUtils.infoMessageDisplay('messages: ' + messages);
        loadSolutions();
        
		//functionality flags
		boolean haveBuildings = !(capitalProject.Capital_Project_Buildings__r == null || capitalProject.Capital_Project_Buildings__r.size() == 0);
		hasICertReqFields = !(string.isEmpty(capitalProject.Request_Title__c) || String.isEmpty(capitalProject.Description__c) || capitalProject.Requested_Due_Date__c == null || (isNetworkBuild && capitalProject.Business_Unit__c == null));
		getOppBuildings = !haveBuildings && !hasICertReqFields;
        canAddBuildings = String.isEmpty(capitalProject.iCERT_ID__c);
        canCreate = canAddBuildings && haveBuildings && hasICertReqFields;
        createICertTitle = canCreate? '' : !string.isEmpty(capitalProject.iCERT_ID__c)? 'iCert already created' : 'Request Title, Description,' + (isNetworkBuild? ' Business Unit,' : '') + ' and Requested Due Date are required.';
		isWholesale = capitalProject.opportunity__r != null && capitalProject.Opportunity__r.Sales_Channel__c == 'Wholesale';
		displayBuildingWarning &= String.isEmpty(capitalProject.iCERT_ID__c);
		if (displayBuildingWarning)
			ApexUtils.messageDisplay(AUTO_MSG);
    }
    
    public PageReference GoToCreateCapitalProjectBuilding(){
        Schema.DescribeSObjectResult describe = Capital_Project_Building__c.SObjectType.getDescribe();
        PageReference pr = new PageReference('/' + describe.getKeyPrefix() + '/e');
        pr.getParameters().put('CF00NC0000005hdF5_lktp', capitalProject.Id);
        pr.getParameters().put('CF00NC0000005hdF5', capitalProject.Name);
        pr.getParameters().put('saveURL', '/'+capitalProject.Id);
        pr.setRedirect(true);
        return pr;
    }
    
    public string selBldgs {get;Set;}
    public PageReference AddBuildings_Click(){
        if(!string.isEmpty(selBldgs)){
            List<Id> selBldgIds = selBldgs.split(',');
            createBuildingsIfNeeded(selBldgIds);
        }
        return redirectToViewPage();
    }
	
	public String selSLocId {get;Set;}
	public PageReference AddCapitalProjectBuilding_Click(){
		if(!String.isEmpty(selSLocId)){
			Id bldgId = null;
			Service_Location__c sLoc = null;
			if (capitalProject.RecordTypeId == Schema.SObjectType.Capital_Project__c.getRecordTypeInfosByName().get('Customer Build').getRecordTypeID())
			{
				bldgId = [select Id, Location__r.Building__c from Service_Location__c where Id = :selSLocId limit 1].Location__r.Building__c;
			}
			else
			{
				bldgId = [select Id, Building__c from Location__c where id = :selSLocId limit 1].Building__c;
			}
			Capital_Project_Building__c cbldg = createCapitalProjectBuilding(bldgId);
			insert cbldg;
		}
		return redirectToViewPage();
	}
	
	public String capBldgId {get;Set;}
	public PageReference DeleteCapitalProjectBuilding_Click(){
		if(!String.isEmpty(capBldgId)){
			delete [select id from capital_project_building__c where id = :capBldgId];
		}
		return redirectToViewPage();
	}
    
    public PageReference CreateICert_Click(){
        if(capitalProject.RecordTypeId == Schema.SObjectType.Capital_Project__c.getRecordTypeInfosByName().get('Customer Build').getRecordTypeID())
			return createCustomerBuild();
		else if(capitalProject.RecordTypeId == Schema.SObjectType.Capital_Project__c.getRecordTypeInfosByName().get('Network Build').getRecordTypeID())
			return createNetworkBuild();
		else
			return null;
    }
    
    public PageReference GetRoutingSteps_Click(){       
        GetRoutingSteps();
        return null;
    }
	
	private PageReference createCustomerBuild(){
		PageReference pr = null;
        try{
            double maxBandwidth = 0.0;
            for(OpportunityLocationConfiguration__c sol : sLocToSolution.values()){
                if(sol.Bandwidth__c != null)
                    maxBandwidth = double.valueOf(sol.Bandwidth__c) > maxBandwidth ? double.valueOf(sol.Bandwidth__c) : maxBandwidth;
            }
			Building__c bldg = capitalProject.capital_Project_Buildings__r != null && capitalProject.capital_Project_buildings__r.size() > 0 ? capitalProject.capital_project_Buildings__r[0].Building__r : null;
			if(bldg == null){
				ApexUtils.messageDisplay('No building found to create icert on.');
				return pr;
			}
            //create icert
            CreateCustomerBuildICert(capitalProject.Opportunity__r.Account, capitalProject.Opportunity__r, bldg, bldg.Name, string.valueOf(maxBandwidth), capitalProject.Requested_Due_Date__c);
            pr = processCreatedICerts();
        }
        catch(Exception ex){
            handleException(ex);
        }
        loadCapitalProject(capitalProject.Id);
        return pr;
	}
    
	private PageReference createNetworkBuild(){
		PageReference pr = null;
        try{
            double maxBandwidth = 0.0;
			Building__c bldg = capitalProject.capital_Project_Buildings__r != null && capitalProject.capital_Project_buildings__r.size() > 0 ? capitalProject.capital_project_Buildings__r[0].Building__r : null;
			if(bldg == null){
				ApexUtils.messageDisplay('No building found to create icert on.');
				return pr;
			}
            //create icert
			List<User> users = [select Id, Sales_Channel__c from User where id = :capitalProject.OwnerId];
			User u = null;
			if (users != null && users.size() > 0)
				u = users[0];
            CreateNetworkBuildICert(bldg, bldg.Name, string.valueOf(maxBandwidth), capitalProject.Requested_Due_Date__c, u != null? u.Sales_Channel__c : '', capitalProject.Business_Unit__c, capitalProject.Department__c, capitalProject.Estimated_Completion_Date__c);
            pr = processCreatedICerts();
            
        }
        catch(Exception ex){
            handleException(ex);
        }
        loadCapitalProject(capitalProject.Id);
        return pr;
	}
    
    private void CreateCustomerBuildICert(Account act, Opportunity opp, Building__c bldg, String address, String bandwidth, Date reqDueDate){
        User u = null;
        Map<Id,Id> seByOppId = OpportunityUtils.getSalesEngineersByOppID(new Set<Id>{opp.Id});
        Map<Id,Id> seByAcctId = OpportunityUtils.getSalesEngineersByAcctID(new Set<Id>{act.Id});
        Set<Id> allUIds = new Set<Id>(seByOppId.values());
        allUIds.addAll(seByAcctId.values());
        Map<Id,User> usersById = new Map<Id,User>([select Id, NTID__c from User where Id in :allUIds]);
        u = usersById.get(seByOppId.get(opp.Id)) == null ? (usersById.get(seByAcctId.get(act.Id)) == null ? null : usersById.get(seByAcctId.get(act.Id))) : usersById.get(seByOppId.get(opp.Id));
        String AEID = u == null ? CustomSettingUtils.GetICertSE('Default') : u.NTID__c;
        integraWS.CreateICertParamsObj param = ICertUtils.getCustomerBuildTemplate(act, opp, bldg, AEID, capitalProject.Request_Title__c, capitalProject.Description__c, false);
        param.Address = address;
        param.ProductBandwidth = bandwidth;
        param.EstCompletion = reqDueDate;
        iCerts = ICertUtils.CreateICertsAndCompleteRequestOrigStep(new List<integraWS.CreateICertParamsObj>{param}, UserInfo.getSessionId());
    }
	
	private void CreateNetworkBuildICert(Building__c bldg, String Address, String bandwidth, Date reqDueDate, string ownerSalesChannel, string businessUnit, string department, Date estCompleteDate){
		User u = null;
        String AEID = CustomSettingUtils.GetICertSE('Default');
        integraWS.CreateICertParamsObj param = ICertUtils.getNetworkBuildTemplate(bldg, AEID, capitalProject.Request_Title__c, capitalProject.Description__c, ownerSalesChannel, businessUnit, department, estCompleteDate);
        param.Address = address;
        param.ProductBandwidth = bandwidth;
        param.EstCompletion = reqDueDate;
        iCerts = ICertUtils.CreateICerts(new List<integraWS.CreateICertParamsObj>{param}, UserInfo.getSessionId());
	}
	
	private PageReference processCreatedICerts(){
		PageReference pr = null;
		System.debug('ABS iCerts : ' +iCerts);
		System.debug('ABS Test.isRunningTest() : ' +Test.isRunningTest());
		if((iCerts != null && iCerts.size() > 0) || Test.isRunningTest()){
                iCerts = Test.isRunningTest() ? new List<ICertUtils.SFICertView>{new ICertUtils.SFICertView()} : iCerts;
                System.debug('ABS iCerts : ' +iCerts);
                if(iCerts[0].Id > 0){
                    updateCapitalProjectFromICert(iCerts[0]);
                    pr = redirectToViewPage();
                    System.debug('ABS pr : ' +pr);
                    if(iCerts[0].Messages != null && iCerts[0].Messages.size() > 0)
                        pr.getParameters().put('msgs', ''+iCerts[0].Messages);
                }
                else if(iCerts[0].Messages.size() > 0)
                    ApexUtils.messageDisplay('message: ' + iCerts[0].Messages);
                else ApexUtils.messageDisplay('Unknown error during icert creation.  please send the Url to Support.');
            }
            else
                ApexUtils.messageDisplay('Failed to create icert see messages (if available)');
		return pr;
	}
    
    private void createCapitalProjectBuildings(Set<Id> bldgs){
        List<Capital_Project_Building__c> bldgsToCreate = new List<Capital_Project_Building__c>();
        for(Id bldg : bldgs){
            Capital_Project_Building__c cbldg = createCapitalProjectBuilding(bldg);
            bldgsToCreate.add(cbldg);
        }
        insert bldgsToCreate;
    }
    
	private Capital_Project_Building__c createCapitalProjectBuilding(Id BldgId){
		Capital_Project_Building__c cbldg = new Capital_Project_Building__c();
        cbldg.Building__c = bldgId;
        cbldg.Capital_Project__c = capitalProject.Id;
		return cbldg;
	}
    
    private void createBuildingsIfNeeded(List<Id> bldgs){
		Set<Id> bldgsToCreate = new Set<Id>();
		Set<Id> bldgIds = new Set<Id>();
        for(Capital_Project_Building__c cbldg : capitalProject.Capital_Project_Buildings__r){
            bldgIds.add(cbldg.Building__c);
        }
        for(Id bldg : bldgs){
            if(!bldgIds.contains(bldg))
                bldgsToCreate.add(bldg);
        }
        createCapitalProjectBuildings(bldgsToCreate);
    }
    
    private Id createOrderProperty(String iCertid, Id sLocId, Id ordId){
        Id rtID = [select Id from RecordType where sObjectType = 'Order_Property__c' and DeveloperName='ICert'].Id;
        Order_Property__c op = new Order_Property__c();
        op.Type__c = 'iCert';
        op.Order__c = ordId;
        op.External_ID__c = iCertId;
        op.Service_Location__c = sLocId;
        op.RecordTypeId = rtID;
        insert op;
        return op.Id;
    }
    
    private void loadSolutions(){
        sLocIds = new List<Id>();
        sLocToSolution = new Map<Id, OpportunityLocationConfiguration__c>();
		Set<Id> buildingIds = new Set<Id>();
		Set<Id> configuredBuildingIds = new Set<Id>();
		Set<Id> unConfiguredBuildingId = new Set<Id>();
        OpportunityLocationConfiguration__c firstSol = null;
		if(capitalProject != null && capitalProject.Opportunity__r != null)
        for(OpportunityLocationConfiguration__c sol : [select Bandwidth__c, CreatedDate
                                                    ,Opportunity_Location__c
                                                    ,Opportunity_Location__r.Id
                                                    ,Opportunity_Location__r.MRC_Total__c
                                                    ,Opportunity_Location__r.NRC_Total__c
                                                    ,Opportunity_Location__r.Term__c
                                                    ,Opportunity_Location__r.Order__c
                                                    ,Opportunity_Location__r.Service_Location__c
                                                    ,Opportunity_Location__r.Service_Location__r.Id
                                                    ,Opportunity_Location__r.Service_Location__r.Name
                                                    ,Opportunity_Location__r.Service_Location__r.Location__c
                                                    ,Opportunity_Location__r.Service_Location__r.Location__r.Id
                                                    ,Opportunity_Location__r.Service_Location__r.Location__r.Name
                                                    ,Opportunity_Location__r.Service_Location__r.Location__r.Building__c
                                                    ,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Id
													,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Name
                                                    ,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.State__c
                                                    ,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Address__c
                                                    ,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.City__c
                                                    ,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Building_CLLI__c
                                                    ,Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Net_Classification__c
                                                    ,Opportunity_Location__r.Opportunity__c
                                                    ,Opportunity_Location__r.Opportunity__r.Id
                                                    ,Opportunity_Location__r.Opportunity__r.Contract_Signed_Date__c
                                                    ,Opportunity_Location__r.Opportunity__r.Customer_Requested_Due_Date__c
                                                    ,Opportunity_Location__r.Opportunity__r.CPQ_NRC_Total__c
                                                    ,Opportunity_Location__r.Opportunity__r.CPQ_Total__c
                                                    ,Opportunity_Location__r.Opportunity__r.Term__c
													,Opportunity_Location__r.Opportunity__r.Sales_Channel__c
                                                    ,Opportunity_Location__r.Opportunity__r.Account.Id
                                                    ,Opportunity_Location__r.Opportunity__r.Account.Name
                                                    ,Opportunity_Location__r.Opportunity__r.Account.Sales_Channel__c
//                                                    ,Opportunity_Location__r.Opportunity__r.Account.Account_Sales_Channel__c
                                                    ,Opportunity_Location__r.Opportunity__r.Account.Owner.Sales_Channel__c
                                                    ,Opportunity_Location__r.Opportunity__r.Owner.NTID__c
                                                from OpportunityLocationConfiguration__c 
                                                where opportunity_Location__r.Opportunity__r.Id = :capitalProject.opportunity__r.Id
                                                    and Active__c = true
                                                    and opportunity_Location__r.On_Hold__c = false]){
                                                        sLocToSolution.put(sol.Opportunity_Location__r.Service_Location__r.Id, sol);
                                                        //Boolean foundIt = false;
														//only add if it's not already in the list of capital project buildings.
                                                        //for(Capital_Project_Building__c cbldg : capitalProject.Capital_Project_Buildings__r){
                                                        //   if(cbldg.Building__c == sol.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Id)
                                                        //        foundIt = true;
                                                        //}
                                                        //if(!foundIt)
                                                        //    sLocIds.add(sol.Opportunity_Location__r.Service_Location__r.Id);
                                                        
                                                        //firstSol = firstSol == null ? sol : (firstSol.CreatedDate > sol.CreatedDate ? sol : firstSol);
														configuredBuildingIds.add(sol.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Id);
														buildingIds.add(sol.Opportunity_Location__r.Service_Location__r.Location__r.Building__r.Id);
                                                    }
                                                    
                                                    //primaryLoc = firstSol != null? firstSol.Opportunity_Location__r.Service_Location__r.Location__r : null;
													
													
		Set<Id> unconfiguredBldgIds = new Set<Id>();
		for(Service_Location__c sloc : [select Id
                                              ,Name
                                              ,Location__c
                                              ,Location__r.Id
                                              ,Location__r.Name
                                              ,Location__r.Building__c
                                              ,Location__r.Building__r.Id
											  ,Location__r.Building__r.Name
                                              ,Location__r.Building__r.State__c
                                              ,Location__r.Building__r.Address__c
                                              ,Location__r.Building__r.City__c
                                              ,Location__r.Building__r.Building_CLLI__c
                                              ,Location__r.Building__r.Net_Classification__c
										from Service_Location__c 
										where Location__r.Building__r.Id not in :configuredBuildingIds
											and Account__c = :capitalProject.Opportunity__r.Account.Id]){
											unconfiguredBldgIds.add(sloc.Location__r.Building__r.Id);
											buildingIds.add(sloc.Location__r.Building__r.Id);
										}
		bldgSelectElementsConfigured = new List<BuildingSelectionElement>();
		bldgSelectElementsUnConfigured = new List<BuildingSelectionElement>();
		if(buildingIds != null)
		for(Building__c bldg : [select id, Name, Address__c, City__c, State__c, Postal_Code__c, (select Id, Access_Method__c, Access_Technology_Name__c, Net_Classification__c, Maximum_Bandwidth__c, Minimum_Required_Revenue__c, Wholesale_Hurdle__c from Access_Availabilities__r) from building__c where id in :buildingIds]){
			//only add if it's not already in the list of capital project buildings.
			Boolean foundIt = false;
            for(Capital_Project_Building__c cbldg : capitalProject.Capital_Project_Buildings__r){
                if(cbldg.Building__c == bldg.Id)
                    foundIt = true;
            }
            if(!foundIt){
				BuildingSelectionElement bldgSelectElement = new BuildingSelectionElement(bldg);
				if(unconfiguredBldgIds.contains(bldg.Id)) bldgSelectElementsUnConfigured.add(bldgSelectElement);
				else bldgSelectElementsConfigured.add(bldgSelectElement);
			}
		}
    }
    
    private void loadCapitalProject(Id capId){
        Set<String> fields = SchemaUtils.RetrieveFullObjectFieldSet(Capital_Project__c.SObjectType);
        fields.add('(select Name, Id, Is_Auto_Eligible__c, Building__c, Building__r.Name, Building__r.Address__c, Building__r.City__c, Building__r.State__c, Building__r.Building_CLLI__c, Building__r.Building_Type__c, Building__r.Net_Classification__c, Building__r.EoF__c, Building__r.EoC__c from Capital_Project_Buildings__r)');
        fields.addAll(new List<String> {'Opportunity__r.Contract_Signed_Date__c'
                                        ,'Opportunity__r.Customer_Requested_Due_Date__c'
                                        ,'Opportunity__r.CPQ_NRC_Total__c'
                                        ,'Opportunity__r.CPQ_Total__c'
                                        ,'Opportunity__r.Term__c'
										,'Opportunity__r.Sales_Channel__c'
                                        ,'Opportunity__r.Account.Id'
                                        ,'Opportunity__r.Account.Name'
                                        ,'Opportunity__r.Account.Sales_Channel__c'
//                                        ,'Opportunity__r.Account.Account_Sales_Channel__c'
                                        ,'Opportunity__r.Account.Customer_Detail__r.Care_Organization__c'                                        
                                        ,'Opportunity__r.Account.Owner.Sales_Channel__c'
                                        ,'Opportunity__r.Owner.NTID__c'
                                        ,'Opportunity__r.Id'});
        List<SObject> sobjs = ApexUtils.retrieveObjectsFromFieldSet(Capital_Project__c.SObjectType, fields,'Id = \''+capId+'\'', null);
        if(sobjs.size() > 0)
            capitalProject = (Capital_Project__c)sobjs[0];
		if(capitalProject != null){
			for(Capital_Project_Building__c cbldg : capitalProject.Capital_Project_Buildings__r){
				displayBuildingWarning |= cbldg.Is_Auto_Eligible__c;
			}
		}
    }
    
    private PageReference redirectToViewPage(){
        PageReference pr = new PageReference('/'+capitalProject.Id);
        pr.setRedirect(true);
        return pr;
    }
    
    private void updateCapitalProjectFromICert(ICertUtils.SFICertView v){
        capitalProject.iCERT_ID__c = string.valueOf(v.Id);
        capitalProject.Status__c = v.StateName;
        capitalProject.Current_Step__c = v.NextStep;
        capitalProject.Expiration_Date__c = v.ExpireDate != null? Date.newInstance(v.ExpireDate.year(), v.ExpireDate.month(), v.ExpireDate.day()) : Date.today();
        capitalProject.Submitted_On__c = Date.today();
        update capitalProject;
    }
    
    public void GetICert(){
        if(!string.isEmpty(capitalProject.iCERT_ID__c))
            iCerts = ICertUtils.GetICertsByIds(new List<Integer> {integer.valueOf(capitalProject.iCERT_ID__c)});
    }
    
    public void GetRoutingSteps(){
        if(!String.isEmpty(capitalProject.iCERT_ID__c))
            RoutingSteps = ICertUtils.GetRoutingStepsByICertId(Integer.valueOf(capitalProject.iCERT_ID__c));
    }
	
	private void handleException(Exception ex){
		apexUtils.messageDisplay(ex.getMessage());
            while(ex.getCause() != null){
                ex = ex.getCause();
                ApexUtils.messageDisplay('Exception message: ' + ex.getMessage());
                ApexUtils.messageDisplay('Exception Line Number: ' + ex.getLineNumber());
                ApexUtils.messageDisplay('Exception Stack Trace: ' + ex.getStackTraceString());
            }
            throw ex;
	}
    
    public class BuildingSelectionElement{
        public Id BldgId {get;private Set;}
        public String Address {get;private set;}
        public String City {get; private Set;}
        public String State {get;private Set;}
        public String Zip {get;private Set;}
        public String AccessMethod {get;private Set;}
        public String NetStatus {get;private Set;}
        public Decimal MaxBandwidth {get;private Set;}
        public Decimal MinimumRevenue {get;private Set;}
        public Decimal Hurdle {get;private Set;}
        
        public BuildingSelectionElement(Building__c bldg){
            BldgId = bldg.Id;
            Address = bldg.Address__c;
            City = bldg.City__c;
            State = bldg.State__c;
            Zip = bldg.Postal_Code__c;
            Building_Access_Availability__c selBaa = null;
            for(Building_Access_Availability__c baa : bldg.Access_Availabilities__r){
                selBaa = selBaa == null ? baa : getBetterBaa(selBaa, baa);
            }
			if(selBaa != null){
				AccessMethod = selBaa.Access_Technology_Name__c;
				NetStatus = selBaa.Net_Classification__c;
				MaxBandwidth = selBaa.Maximum_Bandwidth__c;
				MinimumRevenue = selBaa.Minimum_Required_Revenue__c;
				Hurdle = selBaa.Wholesale_Hurdle__c;
			}
        }
        
        private Building_Access_Availability__c getBetterBaa(Building_Access_Availability__c baa1, Building_Access_Availability__c baa2){
            Integer baa1Rank = rankBaa(baa1.Access_Method__c);
            Integer baa2Rank = rankBaa(baa2.Access_Method__c);
            return baa1Rank < baa2Rank ? baa1 : baa2;
        }
        
        private Integer rankBaa(string AccessAvail){
            return AccessAvail == 'EoF'? 0 : AccessAvail == 'EoC'? 1 : AccessAvail == 'EoNNI'? 2 : AccessAvail == 'EoTDM'? 3 : AccessAvail == 'Broadband'? 4 : AccessAvail == 'DSL'? 5 : 6;
        }
    }

    public TestUtils.TestClass getTestClass(){ return new Test_CapitalProjectController(); }
}