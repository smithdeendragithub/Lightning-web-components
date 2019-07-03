public with sharing class lgt_printOrderController implements TestUtils.ITestableClass {
    
    @AuraEnabled public Map<Id,orderWrapper> currentOrders {get;set;}
    // @AuraEnabled public String hello = 'Hello World';
    public Account account {get; private set;}
    public Opportunity opportunity {get; private set;}
    public Map<Id, List<Directory_Listing__c>> DirectoryListing {get; set;}
    public boolean hasDirectoryListing {get; set;}
    @AuraEnabled public List<Contact> contacts {get; set;}
    @AuraEnabled public List<Contact> contactTypes {get; set;}
    @AuraEnabled public Map<Id, List<Technical_Information__c>> techInfos {get; private set;}
    public Map<Id, List<Phone_Location_Matrix__c>> matrices {get; private set;}
    public Map<Id, List<Voicemail_Menu_Option__c>> vmos {get; private set;}
    public Map<Id, List<NNS_Num__c>> nnss {get; private set;}
    public Map<Id, List<Equipment__c>> equips {get; private set;}
    public Map<Id, List<Configuration__c>> configs {get; private set;}
    public Map<Id,List<String>> contactToContactRole{get;set;}
    public Map<ID,List<Order_Property__c>> orderSummaryToProperties{get;set;}
    public boolean Isfiltercontact{get;set;}
    private String oppID {get; private set;}
    private String solutionID {get; private set;}
    public static final String DEFAULT_RESPONSIBLE_PARTY = 'Default Responsible Party';
    @AuraEnabled public List<contactWrapper> conWrap {get; set;}
    @AuraEnabled public List<OpportunityTeamMember> opportunityTeams {get; set;}
    
    @AuraEnabled public Map<Id,featureWrapper> currentOppLocFeats {get;set;}
    
    public lgt_printOrderController(String opportunityId, String solutionId){
        try{
            contacts = new List<Contact>();
            conWrap = new List<contactWrapper>();
            contactToContactRole=new Map<Id,List<String>>();
            orderSummaryToProperties=new  Map<ID,List<Order_Property__c>>();
            oppID = opportunityId;
            solutionID = solutionId;
            opportunityTeams = new List<OpportunityTeamMember>();
            
            /*           opportunity = [select Id
,Name
,AccountId
,Customer_Requested_Due_Date__c
,Split_Owner_1__c
,Split_Owner_2__c
,Split_Percent_1__c
,Split_Percent_2__c
,Split_Amount_1__c
,Split_Amount_2__c
,SF_Opportunity_ID__c
,Winning_ICB__r.Name
,(Select Id, Name From Orders__r)
,(select Id, Name, ICB_Type__c,ICB_Pricing_Reason__c, ICB_Technical_Reason__c,Description__c, Status__c, Approval_Status__c, Offer_Management_Approver__c, CommissionAdjustment__c,
Contract_Changes_Needed_del__c, iCert_Required__c, ICB_Code__c, Credit_Type_Approval__c, Incentive_Credit_Type__c, NRC_Credit_Amount__c, Number_of_Months__c, Credit_Amount_Approved__c, 
Additional_Conditions_Required__c, Comments__c, Number_of_Days__c from ICB_Requests__r),
(Select ContactId, Role From OpportunityContactRoles)
from Opportunity where Id = :oppID];*/
            
            List<String> fields = new List<String>();
            for(Schema.FieldSetMember fsm : SObjectType.ICB__c.FieldSets.ICB_Order_Summary.getFields()){
                fields.add(fsm.getFieldPath());
            }
            
            string oppQuery = 'select Id ,Name,AccountId,Customer_Requested_Due_Date__c,Promotion_Code__c,RecordType.DeveloperName,Split_Owner_1__c,Split_Owner_2__c,Split_Percent_1__c,Split_Percent_2__c,Split_Amount_1__c,Split_Amount_2__c,SF_Opportunity_ID__c,Winning_ICB__r.Name,(Select Id, Name From Orders__r),(Select ContactId, Role From OpportunityContactRoles),(Select ' + string.join(new List<String>(fields), ', ') + ' from ICB_Requests__r), Type, Oppty_Sub_Type__c , OwnerId, CloseDate, Term__c, Contract_Term_End_Date__c from Opportunity where Id = :oppID';
            
            opportunity = Database.query(oppQuery);
            
            account = [select
                       Name
                       ,Owner.ManagerId
                       ,RecordTypeId
                       ,Owner.Id
                       ,ICC_Account_Number__c
                       ,Phone
                       ,ParentId
                       ,Fax
                       ,Website
                       ,CAM_SAM__c
                       ,ShippingStreet
                       ,ShippingCity
                       ,ShippingState
                       ,ShippingPostalCode
                       ,Owned_By_Indirect_Agent__c
                       ,Related_Companies__c
                       ,Customer_Detail__r.Government_Contract_Type__c
                       ,Customer_Detail__r.Government_Segment__c
                       ,Type
                       ,Industry
                       ,Customer_Billed_revenue__c
                       ,Description
                       ,BillingStreet
                       ,BillingCity
                       ,BillingState
                       ,BillingPostalCode
                       ,Sales_Family_Text__c
                       ,Care_Organization_Name__c
                       ,Owner.Partner_ICBS_Booking_ID__c
                       ,Owner.Partner_IBIS_Booking_ID__c
                       from Account
                       where Id = :opportunity.AccountId];
            
            
            contacts = (List<Contact>) ApexUtils.retrieveFullObjects(Contact.sObjectType, 'AccountId=\'' + account.Id + '\'');
            contacts=filterContactByOpportunity(contacts,opportunity);
            this.currentOrders = new Map<Id,orderWrapper>();
            for(Order__c o :[Select Id, Name,(Select Service_Location__r.name, Type__c, External_ID__c From Order_Properties__r) From Order__c Where Opportunity__c = :oppID]){               
                for(Order_Property__c orderProp: o.Order_Properties__r)
                {               
                    if(!orderSummaryToProperties.containskey(o.id))                 
                        orderSummaryToProperties.put(o.id,new List<Order_Property__c>{orderProp});
                    
                    else
                        orderSummaryToProperties.get(o.id).add(orderProp);
                }
                this.currentOrders.put(o.id, new orderWrapper(o));           
            }
            
            opportunityTeams = new List<OpportunityTeamMember>([select Id, UserId, User.Name, TeamMemberRole from OpportunityTeamMember WHERE OpportunityId = :oppID]);
            
            //Get Associated Locations/Solutions for selection for printing
            GetSolutionsForOrder(this.currentOrders);
            
            retrieveOutboundCIDDetails();
            
        } catch(Exception e){
            system.debug(e);
            System.debug(e.getStackTraceString());
            apexUtils.messageDisplay(e.getMessage()); 
        }
    }
    
    private List<Contact> filterContactByOpportunity(List<Contact> contacts,Opportunity opportunity)
    { 
        Set<String> ContactIdForDecisionMaker=new Set<String>();
        List<Contact> filtercontact=new List<Contact>();
        List<Contact> contactType =new List<Contact>();
        
        IsFiltercontact=false;
        if(!opportunity.OpportunityContactRoles.isEmpty())
        {
            for(OpportunityContactRole ocr:opportunity.OpportunityContactRoles)
            {
                
                ContactIdForDecisionMaker.add(ocr.ContactId);              
                if(!contactToContactRole.containskey(ocr.ContactId))
                    contactToContactRole.put(ocr.ContactId,new List<String>{ocr.Role});
                else
                    contactToContactRole.get(ocr.ContactId).add(ocr.Role);              
                IsFiltercontact=true;                
            }
        }
        //Set the map from account to Opportunity
        
        Set<Contact> setContacts = new Set<Contact>();
        List<Contact> totalContacts = new List<Contact>();
        conWrap = new List<contactWrapper>();
        List<String> cRoles = new List<String>();
        //Now filter contact by its role and set role in Map as per Contact.Also add the contact on filtercontact list
        for(Contact c:contacts){
            cRoles = new List<String>();
            if(contactToContactRole.size() > 0 && contactToContactRole.containsKey(c.Id)){              
                Contact currentContact = c;
                for(String s:contactToContactRole.get(c.id)){
                    cRoles.add(s);          
                }
                System.debug('contactToContactRole: ' + contactToContactRole);
                System.debug('cRoles: ' + cRoles);
                if(cRoles.size() > 0){                  
                    for(String role: cRoles){   
                        contactWrapper cw = new contactWrapper(currentContact, role);                   
                        conWrap.add(cw);                            
                    }
                }
            }
            if(ContactIdForDecisionMaker.size() > 0){           
                if( ContactIdForDecisionMaker.contains(c.id) && c.Default_Contact_Types__c != null){
                    setContacts.add(c);
                }
            }
            if(c.Default_Responsible_Party__c){
                c.Default_Contact_Types__c = 'DEFAULT_RESPONSIBLE_PARTY';
                setContacts.add(c);
            }
            
            if(c.Default_Contact_Types__c != null && !c.Default_Responsible_Party__c){              
                setContacts.add(c);
            }
            
            
        }
        
        if(setContacts.size() >0){
            for(Contact con : setContacts){
                totalContacts.add(con);
            }
        }
        else if(conWrap.size() == 0){
            for(Contact c:contacts){
                totalContacts.add(c);
            }
        }
        
        return totalContacts;
    }
    
    private List<Contact> sortContactByName(List<Contact> contacts)
    {   
        
        List<Contact> sortedContact=new List<Contact>();
        //Sorting Contact Role list by Contact id
        for(String s:contactToContactRole.keyset())
        {
            contactToContactRole.get(s).sort();
        }
        Set<String> contactname=new Set<String>();
        List<String> contactnamelst=new List<String>();
        Map<String,List<String>> contactNameToContactId=new Map<String,List<String>>();
        Map<String,Contact> contatctIdToContact=new Map<String,Contact>();
        for(Contact con:contacts)
        {
            if(!contactNameToContactId.containskey(con.name.toUppercase()))
                contactNameToContactId.put(con.name.toUppercase(),new List<String>{con.id});
            else
                contactNameToContactId.get(con.name.toUppercase()).add(con.id);
            contatctIdToContact.put(con.id,con);
            contactname.add(con.name.toUppercase());
        }
        contactnamelst.addAll(contactname);
        contactnamelst.sort();
        for(String name:contactnamelst)
        {
            for(String conId:contactNameToContactId.get(name))
            {
                sortedContact.add(contatctIdToContact.get(conID));
            }
        }
        return sortedContact;
    }
    
    public void GetSolutionsForOrder(Map<Id,orderWrapper> orders){
        List<SolutionWrapper> swList = new List<SolutionWrapper>(); 
        Map<Id, Opportunity_Location__c> oppLocs = new Map<Id, Opportunity_Location__c>([select Id
                                                                                         ,Name
                                                                                         ,Service_Location__c
                                                                                         ,Order__c
                                                                                         ,NRC_Total__c
                                                                                         ,MRC_Total__c
                                                                                         ,Term__c
                                                                                         ,Status__c
                                                                                         ,On_Hold__c
                                                                                         ,Opportunity__r.AccountId
                                                                                         ,CreatedById
                                                                                         ,CreatedDate
                                                                                         ,(select Id from Technical_Information__r)
                                                                                         from Opportunity_Location__c
                                                                                         where Order__c in :orders.keyset()
                                                                                         and On_Hold__c = false]);
        
        techInfos = new Map<Id, List<Technical_Information__c>>();
        Boolean tiFound = false;
        String ids = '';
        
        currentOppLocFeats = new Map<Id,featureWrapper>(); 
        FeaturesScheduleValidations validations = new FeaturesScheduleValidations(oppLocs.keyset());
        for(Id id : oppLocs.keyset()){
            Opportunity_Location__c oppLoc = oppLocs.get(id);
            techInfos.put(oppLoc.Id, new List<Technical_Information__c>());
            for(Technical_Information__c ti : oppLoc.Technical_Information__r){
                if(tiFound) ids += ',';
                ids += '\'' + ti.Id + '\'';
                tiFound = true;
            }
            featureWrapper fw = new featureWrapper(oppLoc);
            FeaturesScheduleValidations.wrapFeatureforOrderSummary featuresForOrderSummary = validations.featureforOrderSummary.get(oppLoc.Id);
            fw.products = featuresForOrderSummary.products;
            fw.features = featuresForOrderSummary.features;
            fw.packageFeatures = featuresForOrderSummary.packageFeatures;
            fw.totalLines = featuresForOrderSummary.totalLines ;
            currentOppLocFeats.put(oppLoc.id, fw);
        }
        
        //populating Tech form #2
        populateFeatureScheduleForm();
        
        matrices = new Map<Id, List<Phone_Location_Matrix__c>>();
        vmos = new Map<Id, List<Voicemail_Menu_Option__c>>();
        nnss = new Map<Id, List<NNS_Num__c>>();
        equips = new Map<Id, List<Equipment__c>>();
        configs = new Map<Id, List<Configuration__c>>();
        
        if(tiFound){
            List<Technical_Information__c> tis = ApexUtils.retrieveFullObjects(Technical_Information__c.sObjectType, 'Id in (' + ids +')', 'Name');
            
            for(Technical_Information__c ti : tis){
                matrices.put(ti.Id, new List<Phone_Location_Matrix__c>());
                vmos.put(ti.Id, new List<Voicemail_Menu_Option__c>());
                nnss.put(ti.Id, new List<NNS_Num__c>());
                equips.put(ti.Id, new List<Equipment__c>());
                configs.put(ti.Id, new List<Configuration__c>());
                
                Opportunity_Location__c oppLoc = oppLocs.get(ti.Opportunity_Site__c);
                techInfos.get(oppLoc.Id).add(ti);          
            }
            
            for(Phone_Location_Matrix__c plm : (List<Phone_Location_Matrix__c>)ApexUtils.retrieveFullObjects(Phone_Location_Matrix__c.sObjectType, 'Technical_Information__c in (' + ids +')'))
                matrices.get(plm.Technical_Information__c).add(plm);
            
            for(Voicemail_Menu_Option__c vmo : (List<Voicemail_Menu_Option__c>)ApexUtils.retrieveFullObjects(Voicemail_Menu_Option__c.sObjectType, 'Technical_Information__c in (' + ids +')'))
                vmos.get(vmo.Technical_Information__c).add(vmo);
            
            for(NNS_Num__c n : (List<NNS_Num__c>)ApexUtils.retrieveFullObjects(NNS_Num__c.sObjectType, 'Technical_Information__c in (' + ids +')'))
                nnss.get(n.Technical_Information__c).add(n);
            
            for(Equipment__c e : (List<Equipment__c>)ApexUtils.retrieveFullObjects(Equipment__c.sObjectType, 'Technical_Information__c in (' + ids +')'))
                equips.get(e.Technical_Information__c).add(e);
            
            for(Configuration__c c : (List<Configuration__c>)ApexUtils.retrieveFullObjects(Configuration__c.sObjectType, 'Technical_Information__c in (' + ids +')'))
                configs.get(c.Technical_Information__c).add(c);
        }
        
        for(OpportunityLocationConfiguration__c c :[
            Select 
            Id, Name, Term__c, Active__c, MRC_Total__c, NRC_Total__c, Opportunity_Location__c
            //OLIs
            ,(
                Select 
                Id,PP_Sales_Product__c, PP_SalesProductExternalID__c, Product_Family_Product__c
                , MRC_Total__c, PP_Product_Pricing_Name__c,Approved__c, PP_Sales_Rate_Plan_Description__c, Qty__c, MRC__c, MRC_Discount__c 
                , NRC__c, NRC_Discount__c, Approval_Status__c,SPC_MRC_Is_Quote__c,Order_Grouping__c
                ,Secondary_Location__c,Secondary_Location__r.Building__r.Name, Secondary_Service_Location__c,Secondary_Service_Location__r.Location__r.Building__r.Name
                ,Group_Name__c,SPC_Sales_Product__c,//PP_Sales_Product_FR__c,Product_Family_Product_FR__c,
                Parent_Opportunity_Line_Item__c, DQ__c, Parentname__c, Product_Family_Id__c, PP_AdditionalInformationPrompt__c,
                PP_Package__c, PP_Per_Account__c, PP_Package_Feature__c,PP_Product_Family__c,PP_SalesProductRatePlanExternalID__c,
                PP_Voice_Line_Option__c,SPC_Sales_Product_Component_Id__c, SPC_Component_Id__c, Product_Pricing_Display_Name__c                
                From Opportunity_Line_Items__r
                order by Order_Grouping__c
            )
            From OpportunityLocationConfiguration__c o 
            Where Opportunity_Location__r.Order__c in :orders.keyset()]){
                c.Opportunity_Location__r = oppLocs.get(c.Opportunity_Location__c);
                orderWrapper ow = orders.get(c.Opportunity_Location__r.Order__c);
                if(ow != null){
                    solutionWrapper sw = new solutionWrapper(c);                    
                    sw.products = QuoteWrapper.getConfigProductsFromOLIs(c.Opportunity_Line_Items__r);
                    for (QuoteWrapper.Product prod : sw.products) {
                        for(string groupname : prod.linesMap.keyset()){
                            string groupNameVal = groupname == '' ? prod.Name : groupname;
                            if(sw.productsMap.containskey(groupNameVal)){
                                sw.productsMap.get(groupNameVal).add(prod);
                            }else{
                                sw.productsMap.put(groupNameVal,new List<QuoteWrapper.Product>{prod});
                            }
                        }  
                    }                
                    configureProductApproval(sw.products,sw);
                    sw.selected = String.IsEmpty(solutionID) ? sw.rawSolution.Active__c : (sw.rawSolution.Id == solutionID);
                        ow.sols.add(sw);
                    system.debug('swproductsmap: ' + sw.productsMap);
                }                    
            }
        
        getSelected();
    }
    
    public void retrieveOutboundCIDDetails(){
        DirectoryListing = new Map<Id, List<Directory_Listing__c>>();
        try {
            List<Directory_Listing__c> DLs = [Select Id, Name, Company_Name__c, Address__c, City__c, State__c, Zip__c, Listing_Telephone_Number__c,
                                              Type__c, Omit_Address__c, Which_Directory__c, Outbound_CID_Name__c, Outbound_CID_Name_Same_as_Primary_DL__c, Main_Listing__c
                                              , Technical_Information__r.Opportunity_Site__r.Opportunity__r.Id, Technical_Information__c 
                                              From Directory_Listing__c where Technical_Information__r.Opportunity_Site__r.Opportunity__c =: oppId];
            List<Directory_Listing__c> d;
            for (Directory_Listing__c DL: DLs){
                if (DirectoryListing.containsKey(DL.Technical_Information__r.Id)){
                  d = DirectoryListing.get(DL.Technical_Information__r.Id);
                     d.add(DL);          
                }
                else{
                d = new List<Directory_Listing__c>();
                    d.add(DL);
                }
                DirectoryListing.put(DL.Technical_Information__r.Id, d);
            }
            hasDirectoryListing = !DirectoryListing.isEmpty();
        }
        catch (Exception e){
            System.debug(e);
            System.debug(e.getStackTraceString());
            apexUtils.messageDisplay(e.getMessage());
        }
    }
    
    public void configureProductApproval(List<QuoteWrapper.Product> lstProducts,solutionWrapper sw){
        //Moved logic from PrintOrderPage
        integer icbcnt = 0;
        integer ldrcnt = 0;
        for (QuoteWrapper.Product prd : lstProducts) {
            //Need to check for hosted voice products and seperate track them - 08292012
            /*if (prd.Name.contains('Hosted Voice')){
hostedVoice = 'Hosted Voice';
} else {
hostedVoice = 'Not Hosted Voice';
}
mholcombe commented out didn't see the original page even using this
*/
            
            for(QuoteWrapper.QuoteLineItem oli : prd.lines){
                
                string status = oli.rawOLI.Approval_Status__c;
                boolean isapproved = (!String.IsEmpty(String.valueOf(oli.rawOLI.Approved__c))) ? oli.rawOLI.Approved__c : false;
                boolean isquoteitem = (!String.IsEmpty(String.valueOf(oli.rawOLI.SPC_MRC_Is_Quote__c))) ? oli.rawOLI.SPC_MRC_Is_Quote__c : false; 
                
                if(!String.IsEmpty(status) && !isapproved){
                    if(status.contains('Offer')){
                        icbcnt++;
                        system.debug('Offer icbcnt: ' + status + icbcnt);
                    } 
                    else if(status.contains('Sales')){                      
                        ldrcnt++;
                        system.debug('Sales icbcnt: ' + status + icbcnt);
                    }
                }
                
                //one off quote noted items
                if(isquoteitem && !isapproved){
                    icbcnt++;
                    system.debug('Quote icbcnt: ' + status + icbcnt);
                }
            }
            //Need to calculate this at an order level now, not just solution
            if(icbcnt > 0){
                sw.approvalStatus = 'Offer Management Approval Required';
            }else if (ldrcnt > 0){
                sw.approvalStatus = 'Sales Management Approval Required';
            }else{
                sw.approvalStatus = 'Approved';
            }
        }
    }
    
    public PageReference getSelected(){
        for(orderWrapper ow : currentOrders.values()){
            ow.selectedSols.clear();
            for(solutionWrapper sw :ow.sols){
                if(sw.selected)
                    ow.selectedSols.add(sw);
            }
        }
        
        //Get All the Items needed to display based on selectedSols
        getOrderInfo();
        
        return null;
    }
    
    public void getOrderInfo(){
        getServLocs();  
    }
    
    public void getServLocs(){
        map<Id,Id> servLocIds = new map<Id,Id>();
        for(orderWrapper ow :currentOrders.values()){
            for(SolutionWrapper sw: ow.selectedSols){
                sw.servLocs.clear();
                servLocIds.put(sw.rawSolution.id,sw.rawSolution.Opportunity_Location__r.Service_Location__c);
            } 
        }               
        
        Map<Id,Service_Location__c> sls = new Map<Id,Service_Location__c>([Select 
                                                                           Id,Account__c,Billable__c,Name
                                                                           ,ICC_Subscriber_ID__c,Location__r.Building__r.Address__c
                                                                           ,Location__r.Building__r.City__c,Location__r.Building__r.State__c
                                                                           ,Location__r.Building__r.Building_Type__c
                                                                           ,Location__r.Building__r.Postal_Code__c,Location__r.Room_Suite__c
                                                                           ,Net_Classification__c,Phone__c,Building_Status__c
                                                                           ,Legacy_ID__c, BillingID__c, Acquired_Company_or_Biller__c, Customer_Detail__r.BPID__c
                                                                           From 
                                                                           Service_Location__c 
                                                                           Where 
                                                                           id in :servLocIds.values()]);  
        
        for(orderWrapper ow :currentOrders.values()){
            for(SolutionWrapper sw: ow.selectedSols){
                sw.servLocs.add(sls.get(servLocIds.get(sw.rawSolution.id)));
            } 
        }       
    }
    
    public class orderWrapper{
        @AuraEnabled public Order__c rawOrder {get;set;}
        @AuraEnabled public List<solutionWrapper> sols {get;set;}
        @AuraEnabled public List<solutionWrapper> selectedSols {get;set;}
        @AuraEnabled public string approvalStatus {get;set;} 
        public orderWrapper(Order__c o){
            rawOrder = o;
            sols = new List<solutionWrapper>();
            selectedSols = new List<solutionWrapper>();
        }
    }
    
    
    public class solutionWrapper{
        @AuraEnabled public OpportunityLocationConfiguration__c rawSolution {get;set;}
        @AuraEnabled public List<Service_Location__c> servLocs {get;set;}
        @AuraEnabled public List<QuoteWrapper.Product> products {get;set;}
        @AuraEnabled public Map<string,List<QuoteWrapper.Product>> productsMap {get;set;}
        @AuraEnabled public string approvalStatus {get;set;}
        @AuraEnabled public boolean selected {get;set;}
        public solutionWrapper(OpportunityLocationConfiguration__c o){
            rawSolution = o;
            selected = false;
            servLocs = new List<Service_Location__c>();
            products = new List<QuoteWrapper.Product>();
            productsMap = new Map<string,List<QuoteWrapper.Product>>();
        }
    }
    
    public contactWrapper contactWrap{get;set;}
    public class contactWrapper{
        @AuraEnabled public Contact contact{get;set;}
        @AuraEnabled public String contactRole{get;set;}
        public contactWrapper(Contact c, string role){
            contact = c;
            contactRole = role;
        }
    }
    
    public void populateFeatureScheduleForm(){     
        //this section is for populating the detail of 02 – Features Schedule Technical Information
        List <OLI__c> allExistingPackageContentOLIs =  new List<OLI__c>();         
        String query = '';
        String objectFields = '';
        objectFields = SchemaUtils.RetrieveFullObjectFields(CN__c.sObjectType);
        query = 'Select ';
        query +=objectFields + ',';
        query +=' Opportunity_Line_Item__r.Qty__c, '+ 'Opportunity_Line_Item__r.PP_Package_Feature__c , '+ 'Opportunity_Line_Item__r.OpportunityLocationConfiguration__c, '+ 'Opportunity_Line_Item__r.PP_Sales_Rate_Plan_Description__c, '+ 'Opportunity_Line_Item__r.PP_Sales_Product__c, '+ 'Opportunity_Line_Item__r.PP_Package__c, '+ 'Opportunity_Line_Item__r.SPC_Sales_Product_Component_Id__c, '+ 'Opportunity_Line_Item__r.SPC_Component_Id__c, '+ '(Select Id,  '+ '       Name,  '+ '       Opportunity_Line_Item__c, '+ '       Additional_Info__c, '+ '       Opportunity_Line_Item__r.PP_SalesProductRatePlanExternalID__c, '+ '       Opportunity_Line_Item__r.PP_Package_Feature__c '+ '       from CN_Features__r) '+ 'from   CN__c '+ 'where  Opportunity_Location__c in (\'' + string.join(new List<Id>(currentOppLocFeats.keyset()), '\',\'') + '\')order by Name';
        List <CN__c> cns= Database.query(query);        
        
        //Add Telephone numbers
        for(CN__c cn : cns){
            ManageFeaturesScheduleController.wrapNumber tel = new ManageFeaturesScheduleController.wrapNumber(cn);
            if(!currentOppLocFeats.containsKey(cn.Opportunity_Location__c)){
                currentOppLocFeats.put(cn.Opportunity_Location__c,new featureWrapper());
            }
            featureWrapper fw = currentOppLocFeats.get(cn.Opportunity_Location__c);
            if (fw.telephoneNumbers.size()+1>fw.totalLines) {
                tel.deletable = true;
            }
            else {
                tel.deletable = false;
            }
            fw.telephoneNumbers.add(tel);             
            
            if (cn.CN_Features__r.size()>0) {
                for (CN_Feature__c cncfeatures :cn.CN_Features__r) {
                    if (fw.cncToCnCFeatures.containsKey(cn.Name)) {
                        Map <String , CN_Feature__c >tempMap = fw.cncToCnCFeatures.get(cn.Name);
                        tempMap.put(cncfeatures.name, cncfeatures);
                        fw.cncToCnCFeatures.put(cn.Name, tempMap);
                    }
                    else {
                        Map <String , CN_Feature__c >tempMap = new Map <String , CN_Feature__c >();
                        tempMap.put(cncfeatures.name, cncfeatures);
                        fw.cncToCnCFeatures.put(cn.Name, tempMap);
                    }
                }
            }
            
        } 
        
        for (Id locId: currentOppLocFeats.keySet()){
            featureWrapper fw = currentOppLocFeats.get(locId);
            for (OLI__c oli :fw.products) {
                //Need to check for hosted voice products and seperate track them - 08292012
                if (oli.PP_Sales_Product__c.contains('Hosted Voice')) {
                    fw.hostedVoice = 'Hosted Voice';
                }
                else {
                    fw.hostedVoice = 'Not Hosted Voice';
                }
                fw.oliQty.put(oli.id, oli.Qty__C);
            }
            
            if (fw.totalLines <fw.TelephoneNumbers.size()) {
                fw.warnings='The number of Telephone lines in the active solution is less than the amount in the Database. Please delete the excess lines';
            }                       
            for (OLI__c oli :fw.features) {
                //Only do the titles for those who aren't part of the "Package Feature"
                //The features will have to be added in the next step, when I find values for the checkboxes
                if (!oli.PP_Package_Feature__c) {
                    addToTitles(fw, oli);
                    //Add each feature as a feature in the list
                    for (ManageFeaturesScheduleController.wrapNumber tel :fw.TelephoneNumbers) {
                        addToColumnFeatures(tel, oli,fw.packageFeatures);
                    }
                }
                else {
                    //If I created this OLI solely for the features within a package, add it to this list.
                    fw.existingPackageContentOLIs.add(oli);
                    allExistingPackageContentOLIs.add(oli);
                }
            }
            //Now go through the collection, and add the right values based on the features
            for (ManageFeaturesScheduleController.wrapNumber tel :fw.telephoneNumbers) {
                try {
                    for (CN_Feature__C cnfeat :tel.cn.CN_Features__r) {
                        //For each existing feature find the corresponding column (added before)
                        ManageFeaturesScheduleController.wrapFeature feat = findFeature(cnfeat, tel.features);
                        if (feat != null) {
                            //If I found it, set it up properly
                            feat.feature = cnfeat;
                            feat.selected = true;
                            feat.additionalInformation = cnfeat.Additional_Info__c;
                            //If found something but I didn't have an OLI, this means that the feature 
                            //is part of a package. We need to tell the feature which OLI it was associated with
                            if (feat.oli == null) {
                                feat.oli = cnfeat.Opportunity_Line_Item__r;
                            }
                        }
                        // else {
                        //If I can't find the column, then it no longer exists and the CNFeatures must be deleted from when saving
                        //   deleteFeatures.add(cnfeat);
                        //}
                    }
                }
                catch (Exception e) {
                    //messageDisplay(e.getMessage() + ' ' + tel.features);
                    System.debug(e);
                }
            }
        }
        Set<Id>allexitingOliId = new Set<Id>();            
        for (OLI__c ol :allExistingPackageContentOLIs) {
            allexitingOliId.add(ol.id);                
        }
        
        Map<Id, List<CN_Feature__c>> oliForOppnameToCnFeaturelst = new Map<Id, List<CN_Feature__c>>();
        for (OLI__c ol :[Select id,DQ__C,OpportunityLocationConfiguration__c, OpportunityLocationConfiguration__r.Opportunity_Location__c, (Select id,name,Additional_Info__c,CN__c from CN_Features__r) from OLI__c where id IN:allexitingOliId]) {
            List<CN_Feature__c> oliCnFeatures = null;
            if(!oliForOppnameToCnFeaturelst.containsKey(ol.Id)){
                oliForOppnameToCnFeaturelst.put(ol.Id, new List<CN_Feature__c>());
            }
            oliCnFeatures = oliForOppnameToCnFeaturelst.get(ol.Id);
            for (CN_Feature__c cnc :ol.CN_Features__r) {
                oliCnFeatures.add(cnc);
            } 
        }           
        for (Id locId: currentOppLocFeats.keySet()){
            featureWrapper fw = currentOppLocFeats.get(locId);
            
            Map<Id, OLI__c >allexitingOlis = new Map<Id, OLI__c >();
            for (OLI__c ol :fw.existingPackageContentOLIs) {
                allexitingOlis.put(ol.id, ol);                
            }
            fw.oppnameToCnFeature = new Map <String , CN_Feature__c >();
            
            //Setting a map from itemname to cnc package from existing oli...
            for (Id id : allexitingOlis.keySet()) {
                OLI__c ol = allexitingOlis.get(id);             
                if(oliForOppnameToCnFeaturelst.get(ol.id) != null){
                    for (CN_Feature__c cnc :oliForOppnameToCnFeaturelst.get(ol.id)) {
                        fw.oppnameToCnFeature.put(ol.DQ__c, cnc);
                        if (!fw.oppnameToCnFeaturelst.containskey(ol.DQ__c)){
                            fw.oppnameToCnFeaturelst.put(ol.DQ__c, new List <CN_Feature__c >{cnc});
                        }else{
                            fw.oppnameToCnFeaturelst.get(ol.DQ__c).add(cnc);
                        }
                    }
                }
            }
            //Find the existing package and set the selected
            for (ManageFeaturesScheduleController.wrapNumber tel :fw.telephoneNumbers) {
                Set <String >allcn = new Set <String >();
                for (ManageFeaturesScheduleController.wrapFeature feature :tel.features) {
                    if (feature.isPartOfPackage) {
                        if (fw.oppnameToCnFeature.containskey(feature.name)) {
                            List <CN_Feature__c >cnclst = fw.oppnameToCnFeaturelst.get(feature.name);
                            for (CN_Feature__c cnc :cnclst) {
                                if (tel.cn != NULL &&tel.cn.id != NUll &&tel.cn.id == cnc.cn__C) {
                                    if (feature.additionalInformationPrompt != '')feature.additionalInformation = cnc.Additional_Info__c;
                                    feature.selected = true;
                                }
                            }
                        }
                    }
                }
            }
            //Disable all the checkboxes
            //Checkbox  disability is controlled from here .....
            if (fw.hostedVoice != 'Hosted Voice') {
                preselectCheckboxes(fw);
                fw.hostedVoice = 'Not HV';
            }                
        } //end of for location for loop        
        
    }    
    //Copied from ManageFeaturesScheduleController
    private void addToColumnFeatures(ManageFeaturesScheduleController.wrapNumber tel, OLI__c oli,Map <Id, List <FeaturesScheduleValidations.wrapFeatureContent >>packageFeatures) {
        ManageFeaturesScheduleController.wrapFeature feat = new ManageFeaturesScheduleController.wrapFeature();
        feat.OLI = oli;
        feat.name = oli.PP_Sales_Rate_Plan_Description__c;
        feat.additionalInformationPrompt = (oli.PP_AdditionalInformationPrompt__c == null)?'':oli.PP_AdditionalInformationPrompt__c;
        feat.maxQty = oli.Qty__c;
        feat.isPartOfPackage = false;
        feat.parentFeature = null;
        feat.parentOLI = null;
        if (!oli.PP_Per_Account__c) {
            feat.salesProduct = oli.PP_Sales_Product__c;
        }
        else {
            feat.salesProduct = '_ALL_';
        }
        feat.salesProductRatePlanExternalId = oli.PP_SalesProductRatePlanExternalID__c;
        //feat.productPricingId = oli.Product_Pricing__c;
        feat.selected = false;
        feat.additionalInformation = '';
        feat.childrenNumber = 0;
        feat.spcSalesProductComponentId = string.valueof(oli.SPC_Sales_Product_Component_Id__c);
        feat.spcComponentId = string.valueof(oli.SPC_Component_Id__c);
        tel.features.add(feat);
        //Now see if I have to enter features from within a package.
        if (packageFeatures.containsKey(oli.Id)) {
            List <FeaturesScheduleValidations.wrapFeatureContent >myFeatures = packageFeatures.get(oli.Id);
            for (FeaturesScheduleValidations.wrapFeatureContent packageFeat :myFeatures) {
                ManageFeaturesScheduleController.wrapFeature featcontent = new ManageFeaturesScheduleController.wrapFeature();
                featcontent.OLI = null;
                featcontent.name = packageFeat.title;
                featcontent.additionalInformationPrompt = (packageFeat.additionalInformationPrompt == null)?'':packageFeat.additionalInformationPrompt;
                featcontent.maxQty = oli.Qty__c;
                featcontent.isPartOfPackage = true;
                featcontent.parentFeature = feat;
                featcontent.parentOLI = oli;
                featcontent.spcSalesProductComponentId = string.valueof(oli.SPC_Sales_Product_Component_Id__c);
                featcontent.spcComponentId = string.valueof(oli.SPC_Component_Id__c);
                if (!oli.PP_Per_Account__c) {
                    featcontent.salesProduct = oli.PP_Sales_Product__c;
                }
                else {
                    featcontent.salesProduct = '_ALL_';
                }
                featcontent.salesProductRatePlanExternalId = packageFeat.salesProductRatePlanExternalId;
                featcontent.productPricingId = packageFeat.productPricingId;
                featcontent.selected = false;
                featcontent.additionalInformation = '';
                feat.childrenNumber +=1;
                if (featcontent.additionalInformationPrompt != '') {
                    //add another child b/c of the textbox that we add
                    feat.childrenNumber +=1;
                }
                tel.features.add(featcontent);
            }
        }        
    }
    
    private void addToTitles(featureWrapper fw, OLI__c oli) {
        List<ManageFeaturesScheduleController.wrapFeatureTitle> displayFeats = fw.displayFeatures;
        ManageFeaturesScheduleController.wrapFeatureTitle tit = new ManageFeaturesScheduleController.wrapFeatureTitle();
        tit.displayTitle = oli.PP_Sales_Rate_Plan_Description__c;
        if (!oli.PP_Per_Account__c ||!oli.PP_Package__c) {
            tit.displaySubTitle = '(Max: '+ oli.Qty__c + ')';
        }
        tit.additionalInformationPrompt = (oli.PP_AdditionalInformationPrompt__c == null)?'':oli.PP_AdditionalInformationPrompt__c;
        tit.isFeaturePackage = false;
        displayFeats.add(tit);
        //Now do the display part
        if (fw.packageFeatures.containsKey(oli.Id)) {
            List <FeaturesScheduleValidations.wrapFeatureContent >myFeatures = fw.packageFeatures.get(oli.Id);
            for (FeaturesScheduleValidations.wrapFeatureContent feat :myFeatures) {
                ManageFeaturesScheduleController.wrapFeatureTitle featTit = new ManageFeaturesScheduleController.wrapFeatureTitle();
                featTit.displayTitle = feat.title;
                if (!oli.PP_Per_Account__c ||!oli.PP_Package__c) {
                    featTit.displaySubTitle = '(Max: '+ oli.Qty__c + ')';
                }
                featTit.additionalInformationPrompt = (feat.additionalInformationPrompt == null)?'':feat.additionalInformationPrompt;
                featTit.isFeaturePackage = true;
                tit.childrenNumber +=1;
                if (featTit.additionalInformationPrompt != '') {
                    //add another child b/c of the textbox that we add
                    tit.childrenNumber +=1;
                }
                displayFeats.add(featTit);
            }
        }        
    }
    
    
    private ManageFeaturesScheduleController.wrapFeature findFeature(CN_Feature__c cnfeat, List <ManageFeaturesScheduleController.wrapFeature> features) {
        String sprtId = cnfeat.Opportunity_Line_Item__r.PP_SalesProductRatePlanExternalID__c;
        for (ManageFeaturesScheduleController.wrapFeature feat :features) {
            if (feat.OLI != null &&feat.OLI.Id == cnfeat.Opportunity_Line_Item__c) {
                return feat;
            }
            else if (feat.OLI == null &&feat.isPartOfPackage == true&&feat.salesProductRatePlanExternalId == sprtId) {
                //if this is a feature that is part of a package, then the OpptyLineItem was defaulted to null above
                //therefore, we have to compare differently
                return feat;
            }
        }
        return null;
    }
    
    private void preselectCheckboxes(featureWrapper fw) {
        //Iterate through all the features
        //If the qty of the feature = qty of the line they belong to
        //then preselect
        for (ManageFeaturesScheduleController.wrapNumber tel :fw.telephoneNumbers) {
            if (!tel.isTotalLine) {
                if (tel.cn.Opportunity_Line_Item__c != null) {
                    //Always find the proper SP based on the selection just made (the retrieved one could be old)
                    String salesProduct = findSalesProduct(tel.cn.Opportunity_Line_Item__c, fw.products);
                    //If the line has been assigned, check all its features for the possibility  
                    for (ManageFeaturesScheduleController.wrapFeature feat :tel.features) {
                        if ((feat.salesProduct == salesProduct)||(feat.salesProduct == '_ALL_')) {
                            if (fw.oliQty.containsKey(tel.cn.Opportunity_Line_Item__c)&&!feat.isPartOfPackage) {
                                Decimal qty = fw.oliQty.get(tel.cn.Opportunity_Line_Item__c);
                                if (feat.maxQty == qty) {
                                    feat.selected = true;
                                }
                            }
                        }
                        if (fw.cncToCnCFeatures.containskey(tel.cn.Name)) {
                            if (fw.cncToCnCFeatures.get(tel.cn.Name).containskey(tel.cn.Name + ' - '+ feat.name)&&(feat.additionalInformationPrompt == NULL ||feat.additionalInformationPrompt.trim().isWhitespace()))feat.selected = true;
                            else if (fw.cncToCnCFeatures.get(tel.cn.Name).containskey(tel.cn.Name + ' - '+ feat.name))feat.additionalInformation = fw.cncToCnCFeatures.get(tel.cn.Name).get(tel.cn.Name + ' - '+ feat.name).Additional_Info__c;
                        }
                    }
                }
            }
        }
    }
    
    private String findSalesProduct(Id oliID, List <OLI__c>products) {
        for (OLI__c prod :products) {
            if (prod.Id == oliID) {
                return prod.PP_Sales_Product__c;
            }
        }
        return '';
    }
    
    public class featureWrapper{
        public Opportunity_Location__c oppLoc {get;set;}
        public List <ManageFeaturesScheduleController.wrapNumber> telephoneNumbers {get;set;}
        public Map <Id, List <CN_Feature__c >> telephoneFeatures {get;set;}
        public List <ManageFeaturesScheduleController.wrapFeatureTitle > displayFeatures {get;set;}
        public Map <String , Map <String , CN_Feature__c >> cncToCnCFeatures {get;set;}
        public Map <String , CN_Feature__c > oppnameToCnFeature {get;set;}
        public Map <String , List <CN_Feature__c >> oppnameToCnFeaturelst {get;set;}                
        public String hostedVoice {get;set;}
        public List <OLI__c >products {get;set;}
        public List <OLI__c >features {get;set;}
        public Map <Id, List <FeaturesScheduleValidations.wrapFeatureContent >>packageFeatures {get;set;}
        public List <OLI__c> existingPackageContentOLIs {get;set;}
        public Map <Id, Decimal> oliQty {get;set;}
        public Decimal totalLines {get;set;}
        public String warnings {get;set;}
        
        
        public featureWrapper(Opportunity_Location__c o){
            oppLoc = o;
            telephoneNumbers = new List<ManageFeaturesScheduleController.wrapNumber>();
            displayFeatures  = new List<ManageFeaturesScheduleController.wrapFeatureTitle>();
            cncToCnCFeatures = new Map <String , Map <String , CN_Feature__c >>();
            oppnameToCnFeature = new Map <String , CN_Feature__c >();
            oppnameToCnFeaturelst = new Map <String , List <CN_Feature__c >>();
            existingPackageContentOLIs = new List <OLI__c >();
            oliQty = new Map <Id, Decimal >();
            totalLines = 0;
            warnings = '';
        }
        public featureWrapper(){
            telephoneNumbers = new List<ManageFeaturesScheduleController.wrapNumber>();
            displayFeatures  = new List<ManageFeaturesScheduleController.wrapFeatureTitle>();
            cncToCnCFeatures = new Map <String , Map <String , CN_Feature__c >>();
            oppnameToCnFeature = new Map <String , CN_Feature__c >();
            oppnameToCnFeaturelst = new Map <String , List <CN_Feature__c >>();
            existingPackageContentOLIs = new List <OLI__c >();
            oliQty = new Map <Id, Decimal >();
            totalLines = 0;
            warnings = '';
        }        
    }
    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_PrintOrder(); }
}