public without sharing class OrderManagementController implements TestUtils.ITestableClass{
    
    public Account account {get; private set;}
    public Map<Id, Sub_Order__c> existingSubOrders {get; private set;}

    public String error {get; private set;}

    public List<OrderInfo> orderDisplay {get; set;}
    public List<SubOrderConfigurator> subOrderDisplay {get; set;}
    public List<SubOrderConfigurator> SubOrderDisplays {get; set;}
    public List<OrderConfigurator> iccOrderDisplay {get; set;}
    public List<Integer> iccOrderIds {get; set;}
    public Sub_Order__c subOrderConfig {get; set;}

    public List<Id> selectedFeatures {get; set;}
    public List<SelectOption> featuresOptions {get; set;}

    public OrderInfo selectedOrderInfo {get; set;}
    public List<SubOrderConfigurator> selectedSubOrders {get; set;}
    public List<OrderConfigurator> selectedICCOrders {get; set;}

    public Map<Id, SPC_Product__c> spcProductById {get; set;}
    public Map<String, SPC_Product__c> spcProductByExternalId {get; set;}

    private Set<String> SetOfEditedTempIds;
    public String EditedICCTempIds { 
        get { return JSON.serialize(SetOfEditedTempIds); }
        set { SetOfEditedTempIds = (!String.isEmpty(value)) ? (Set<String>)JSON.deserialize(value, Set<String>.class) : null; }
    }

    private Set<String> SetOfModifiedTempIds;
    public String ModifiedTempIds{
        get { return JSON.serialize(SetOfModifiedTempIds); }
        Set { SetOfModifiedTempIds = (Set<String>)JSON.deserialize(value, Set<String>.class); }
    }

    public String SelectedOrderId {get; set;}
    private Set<String> SetOfSelectedICCOrderIds;
    public String SelectedICCOrderIds { 
        get { return JSON.serialize(SetOfSelectedICCOrderIds); }
        set { SetOfSelectedICCOrderIDs = (Set<String>)JSON.deserialize(value, Set<String>.class); }
    }

    public String SelectedOwner {get; set;}
    public Boolean ProvPlan {get; set;}
    public Boolean needsTOV{get; set;}

    public Boolean hasWorkstepCreate{
        get { return Schema.sobjecttype.Workstep__c.isCreateable(); }
        set { hasWorkstepCreate = Schema.sobjecttype.Workstep__c.isCreateable(); }
    }

    public Boolean isOrderContext {get; set;}

    public class OrderConfigurator {
        public Order_Property__c orderProperty {get; set;}
        public String orderICCSubID {get; set;}
        
        public OrderConfigurator(){
            orderProperty = new Order_Property__c();
            orderICCSubID = '';
        }
    }

    public class SubOrderConfigurator implements Comparable{
        public Integer compareTo(Object compareTo){

            SubOrderConfigurator compareToSubOrderConfigurator = (SubOrderConfigurator)compareTo;

            if(subOrder != null && subOrder.SPC_Product__r.Name != null && compareToSubOrderConfigurator.subOrder.SPC_Product__r.Name != null)
                return (compareToSubOrderConfigurator.subOrder != null) ? subOrder.SPC_Product__r.Name.compareTo(compareToSubOrderConfigurator.subOrder.SPC_Product__r.Name) : 1;
            else
                return (compareToSubOrderConfigurator.subOrder == null) ? 0 : -1;
        }

        public Order_Property__c property {get; set;}
        public Sub_Order__c subOrder {get; set;}
        public Service_Location__c location {get; set;}
        public String tempId {get; set;}
        public String totalMRR {get; private set;}

        private List<Sub_Order_Group__c> groupList {get; set;}
        public String groupDisplay {get; private set;}
        public List<Sub_Order_Group__c> groups {
            get{ return groupList; }
            set{
                groupDisplay = '';
                totalMRR = '';
                Decimal tempTotalMRR = 0;
                if(value != null){
                    for(Integer i=0; i<value.size(); i++){
                        groupDisplay += (i > 0 ? ', ' : '') + string.format('{0} x{1} ({2})', new List<String>{value[i].Product__c, string.valueOf(value[i].Quantity__c), value[i].External_ID__c});
                        tempTotalMRR += value[i].MRR__c;
                    }
                }
                totalMRR = '$' + tempTotalMRR.setScale(2);
                groupList = value;
            }
        }

        private List<Feature__c> featuresList {get; set;}
        public String featureDisplay {get; private set;}
        public List<Feature__c> Features {
            get{ return featuresList; }
            set{
                featureDisplay = '';
                if(value != null){
                    for(Integer i=0; i<value.size(); i++)
                        featureDisplay += (i > 0 ? '<br/>' : '') + value[i].Name;
                }
                featuresList = value;
            }
        }

        public Boolean Modified {get; set;}

        public SubOrderConfigurator(Integer TemporaryId, Order_Property__c prop, Sub_Order__c so, List<Sub_Order_Group__c> soGroups, Service_Location__c sloc, SPC_Product__c product){
            tempId = string.valueOf(TemporaryId);
            property = prop;
            subOrder = so;
            if(sloc != null){
                subOrder.Service_Location__r = sloc;
                subOrder.Service_Location__c = sloc.Id;
                subOrder.Customer_Detail__c = sloc.Customer_Detail__c;
            }
            if(product != null){
                subOrder.SPC_Product__r = product;
                subOrder.SPC_Product__c = product.Id;
                if(prop.Type__c.contains('Install')){
                    subOrder.Provisioning_Product__c = product.Provisioning_Product__c;
                    subOrder.Provisioning_Product__r = product.Provisioning_Product__r;
                }
            }
            groups = soGroups;
            Modified = false;
            Features = new List<Feature__c>();
        }
    }

    public class OrderInfo implements Comparable{

        public Integer compareTo(Object compareTo){
            OrderInfo compareToOrderInfo = (OrderInfo)compareTo;
            if(Opp != null)
                return (compareToOrderInfo.Opp != null) ? Opp.Name.compareTo(compareToOrderInfo.Opp.Name) : 1;
            else
                return (compareToOrderInfo.Opp == null) ? 0 : -1;
        }

        public Order__c Order {get; set;}   
        public OppDisplay Opp {get; set;}
    }

    public class OppDisplay{

        public String Name {get; set;}
        public String Id {get; set;}

        public OppDisplay(){
            this.Name = '';
            this.Id = '';
        }

        public OppDisplay(Opportunity opp){
            if(opp == null){
                this.Name = '';
                this.Id = '';
            }
            else{
                this.Name = opp.Name == null ? '' : opp.Name;
                this.Id = opp.Id == null ? '' : String.ValueOf(opp.Id);
            }
        }
    }

    public OrderManagementController(){
        isOrderContext = false;
        String accountID = ApexPages.currentPage().getParameters().get('accountId');
        SelectedOrderId = ApexPages.currentPage().getParameters().get('orderId');

        if(!string.IsEmpty(accountID)){
            account = [select Id, ICC_Account_Number__c, Name from Account where Id = :accountID limit 1];
        }
        else if(string.IsEmpty(accountID) && SelectedOrderId != null){
            Order__c obj = [select Account__r.Id, Account__r.ICC_Account_Number__c, AccountName__c from Order__c where Name =: SelectedOrderId limit 1];
            account = [select Id, ICC_Account_Number__c, Name from Account where Name = :obj.AccountName__c limit 1];
        }
        else{
            error = 'There is no Account or Order context with which to view this page.';
        }
        
        List<Order_Property__c> exIds = new List<Order_Property__c>();
        if(string.Isempty(account.ICC_Account_Number__c))
            error = 'Orders cannot be managed through this page for hierarchies that have not been integrated';
        else{
            if(SelectedOrderId != '' && SelectedOrderId != null){
                isOrderContext = true;
                exIds = [select Order__r.Id, External_Id__c from Order_Property__c where Order__r.Name = :SelectedOrderId];

                if(exIds.size() > 0){
                    iccOrderIds = new List<Integer>();
                    selectedOrderInfo = new OrderInfo();
                    selectedOrderInfo.Order = new Order__c();
                    for(Order_Property__c ids : exIds){
                        iccOrderIds.add(Integer.ValueOf(ids.External_Id__c));
                        selectedOrderInfo.Order.Id = ids.Order__r.Id;
                    }
                }
            }
            else{
                selectedOrderInfo = new OrderInfo();
                selectedOrderInfo.Order = new Order__c();
                selectedOrderInfo.Order.Provisioning_Plan_Enabled__c = true;
            }
            
            orderDisplay = getOrdersByAccountID(account.Id);
            orderDisplay.sort();
            subOrderConfig = new Sub_Order__c();
            subOrderConfig.Access_Types__c = null;
            subOrderConfig.Provisioning_Product__c = null;
            subOrderConfig.Workplan_Start_Date__c = Date.today();

            featuresOptions = new List<SelectOption>();
            List<Schema.PicklistEntry> ple = Order__c.Features__c.getDescribe().getPicklistValues();
            Set<String> buildFeatures = new Set<String>();
            for (Schema.PicklistEntry pl : ple){
                if (pl.isActive()){
                    buildFeatures.add(pl.getValue());
                }
            }            
            for(Feature__c f : [select Id, Name from Feature__c where Name not in : buildFeatures order by Name])
                featuresOptions.add(new SelectOption(f.Id, f.Name));

            spcProductByExternalId = new Map<String, SPC_Product__c>();
            spcProductById = new Map<Id, SPC_Product__c>([select Id, SalesProductExternalID__c, Name, Provisioning_Product__c, Provisioning_Product__r.Name from SPC_Product__c]);
            for(SPC_Product__c product : spcProductById.values())
                spcProductByExternalId.put(string.valueOf(product.SalesProductExternalID__c), product);

            if(isOrderContext){
                try{
                    subOrderDisplay = getExternalSubOrdersBySubscriberID(Account.ICC_Account_Number__c);
                    PrepareConfigurationPage();
                }
                catch(Exception exp){
                    error = 'error';
                    createMessage('Exception: ICC returned no order properties to integrate or the process timed-out. Please try Integrating again.');
                }
            }
        }
    }

    private void createMessage(String message){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }

    public List<OrderInfo> getOrdersByAccountID(String AccountID){
        List<OrderInfo> retval = new List<OrderInfo>();
        existingSubOrders = new Map<Id, Sub_Order__c>([select (select Id, Name, Status__c, Product__c, Quantity__c, External_ID__c from sub_order_groups__r Order By Product__c), Id, Order__c, Actual_Due_Date__c, Changed_Reason__c, Customer_Acceptance_Date__c, Customer_Commit_Date__c, Customer_Requested_Date__c, Install_Date__c, Missed_Reason__c, Projected_Due_Date__c from Sub_Order__c where Service_Location__r.Account__c = :AccountID]);

        Map<Id, Order__c> ords = new Map<Id, Order__c>();
        for(Sub_Order__c subOrder : existingSubOrders.values())
            ords.put(subOrder.Order__c, null);
        ords = new Map<Id, Order__c>([select Id, Name, OwnerId, Opportunity__c, Provisioning_Plan_Enabled__c from Order__c where Account__c = :AccountID or Id in :ords.keyset() or Opportunity__r.AccountID = :AccountID]);

        Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        for(Order__c o : ords.values()){
            if(o.Opportunity__c != null)
                opps.put(o.Opportunity__c, null);
        }

        opps = new Map<Id,Opportunity>([select Id, Name from Opportunity where Id in: opps.keyset()]);
        for(Order__c o : ords.values()){
            OrderInfo moi = new OrderInfo();
            moi.Order = o;
            moi.Opp = opps.get(o.Opportunity__c) != null ? new OppDisplay(opps.get(o.Opportunity__c)) : null;
            retval.add(moi);
        }
        return retval;
    }

    public Map<String, Order_Property__c> properties {get; set;}

    public List<SubOrderConfigurator> getExternalSubOrdersBySubscriberID(String subscriberID){

        SubOrderDisplays = new List<SubOrderConfigurator>();
        integraWS.ArrayOfSFOrderPropertyView orderView = getSubOrderListBySubscriberID(Integer.ValueOf(subscriberID));

        List<Integer> oIds = new List<Integer>();
        Map<String, Order_Property__c> properties = new Map<String, Order_Property__c>();
        List<Order_Property__c> op = getOrderPropertiesFromView(orderView != null  ? orderView : new integraWS.ArrayOfSFOrderPropertyView());
        subOrderDisplay = new List<SubOrderConfigurator>();
        if(op.size() > 0){
            for(Order_Property__c p : op){
                properties.put(p.External_ID__c, p);
                oIds.add(Integer.valueof(p.External_ID__c)); 
            }
            integraWS.SFOrderView suborderView = (iccOrderIds == null)
                                                ? GetSubOrderSummaryByOrderIDs(oIds, Integer.ValueOf(subscriberID), getSubOrderViewFromExistingSubOrders())
                                                : GetSubOrderSummaryByOrderIDs(iccOrderIds, Integer.ValueOf(subscriberID), getSubOrderViewFromExistingSubOrders());

            Map<Integer, Sub_Order_Group__c> autoSaveGroups = new Map<Integer, Sub_Order_Group__c>();
            List<integraWS.SFSubOrderView> OrderViewsToDisplay = new List<integraWS.SFSubOrderView>();
            List<String> subscriberIDs = new List<String>();
            for(integraWS.SFSubOrderView v : (suborderView.SubOrders != null && suborderView.SubOrders.SFSubOrderView != null ? suborderView.SubOrders.SFSubOrderView : new List<integraWS.SFSubOrderView>())){
                if(v.SalesforceID == null && v.OrderPropertySalesforceID == null){
                    OrderViewsToDisplay.add(v);
                    subscriberIDs.add(string.valueof(v.SubscriberID));
                }
                else if(v.SalesforceID != null){
                    for(integraWS.SFSubOrderGroupView g : v.Groups.SFSubOrderGroupView){
                        if(g.SalesforceID == null){
                            Sub_Order_Group__c sog = getSubOrderGroupFromView(g);
                            sog.Sub_Order__c = v.SalesforceID;
                            autoSaveGroups.put(g.ExternalID, sog);
                        }
                    }
                }
            }
            
            Map<String, Service_Location__c> slocBySubID = new Map<String, Service_Location__c>();
            for(Service_Location__c sloc : [select Id, ICC_Subscriber_ID__c, Customer_Detail__c from Service_Location__c where ICC_Subscriber_ID__c in :subscriberIDs])
                slocBySubID.put(sloc.ICC_Subscriber_ID__c, sloc);
            
            Integer tempId = 1;      
            for(integraWS.SFSubOrderView v : OrderViewsToDisplay){
                Service_Location__c sloc = slocBySubID.get(String.valueOf(v.SubscriberID));
                if(sloc != null) SubOrderDisplays.add(getConfigurationItemFromSubOrder(tempId++, v, properties.get(string.valueOf(v.OrderPropertyExternalOrderID)), sloc, spcProductByExternalId.get(string.valueOf(v.SPCProductID))));         
            }
            
            if(autoSaveGroups.size() > 0){
                Boolean success = true;
                for(Database.SaveResult sr : Database.update(autoSaveGroups.values(), false))
                    success &= sr.isSuccess();

                if(success) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'One or more sub-orders already saved on this account has been updated with additional group information.'));
            }
            
            Map<integer,SubOrderConfigurator> ICCOrders = new Map<integer, SubOrderConfigurator>();
            if(SubOrderDisplays != null){
                Map<String, SubOrderConfigurator> preIntegratedOnly = new Map<String, SubOrderConfigurator>();
                for(SubOrderConfigurator soc : SubOrderDisplays)
                    preIntegratedOnly.put(soc.property.External_ID__c, soc );
                
                Set<String> nixIds = new Set<String>();
                for(Order_Property__c ops : [select Order__r.Id, External_Id__c from Order_Property__c where External_Id__c = :preIntegratedOnly.keyset()])
                    nixIds.add(ops.External_Id__c);
                
                for(SubOrderConfigurator soc : SubOrderDisplays){
                    if(ICCOrders.get(Integer.valueof(soc.property.External_ID__c)) == null && !nixIds.contains(soc.property.External_ID__c))
                        ICCOrders.put(Integer.valueof(soc.property.External_ID__c), soc);
                }
            }
            
            List<Integer> keyList  = new List<Integer>(new Set<Integer>(ICCOrders.keyset()));
            keyList.sort();
            
            Map<integer,SubOrderConfigurator> returnMap = new Map<integer, SubOrderConfigurator>(); 
            
            for (Integer i = 0; i < keyList.size(); i++){
                returnMap.put(keyList[i], ICCOrders.get(keyList[i]));
                subOrderDisplay.add(ICCOrders.get(keyList[i]));
            }
        }
        
        return subOrderDisplay.size() > 0 ? subOrderDisplay : new  List<SubOrderConfigurator>();
    }

    public PageReference PrepareConfigurationPage(){
        selectedSubOrders = new List<SubOrderConfigurator>();
        List<Sub_Order__c> subOrders = new List<Sub_Order__c>();
        
        if(!isOrderContext){
            UpdateSelectedOrder();

            for(SubOrderConfigurator soc : subOrderDisplays){
                if(setOfSelectedICCOrderIds.contains(soc.property.External_ID__c)){
                    subOrders.add(soc.subOrder);
                    selectedSubOrders.add(soc);
                }
            }
        }
        else{
            for(SubOrderConfigurator soc : subOrderDisplays){
                subOrders.add(soc.subOrder);
                selectedSubOrders.add(soc);
            }
        }
        
        List<Sub_Order_Feature__c> subOrderFeatures = [select Feature__c, Feature__r.Name, Sub_Order__c from Sub_Order_Feature__c where Sub_Order__c in :subOrders];
        for(SubOrderConfigurator soc : selectedSubOrders){
            List<Feature__c> Features = new List<Feature__c>();
            for(Sub_Order_Feature__c f : subOrderFeatures){
                if(f.Sub_Order__c == soc.subOrder.Id)
                    Features.add(f.Feature__r);
            }
            soc.Features.addAll(Features);
        }
        
        return null;
    }

    public PageReference EditSubOrders(){
        if(subOrderConfig.Workplan_Start_Date__c < Date.today()) {
            createMessage('Edits not saved.  Workplan start date cannot be before today.');
            return null;
        }

        List<Feature__c> Features = (selectedFeatures != null) ? [select Id, Name from Feature__c where Id in : selectedFeatures] : new List<Feature__c>();
        List<Access_Types__c> AccessTypes = (subOrderConfig.Access_Types__c != null) ? [select Id, Name from Access_Types__c where Id = : subOrderConfig.Access_Types__c] : new List<Access_Types__c>();
        List<Provisioning_Product__c> ProvProds = (subOrderConfig.Provisioning_Product__c != null) ? [select Id, Name from Provisioning_Product__c where Id = : subOrderConfig.Provisioning_Product__c] : new List<Provisioning_Product__c>();

        for(SubOrderConfigurator soc : selectedSubOrders){
            if(SetOfEditedTempIds.contains(soc.tempId)){
                soc.subOrder.Access_Types__r = AccessTypes.size() > 0 ? AccessTypes.get(0) : subOrderConfig.Access_Types__r;
                soc.subOrder.Access_Types__c = AccessTypes.size() > 0 ? AccessTypes.get(0).Id : subOrderConfig.Access_Types__c;
                soc.subOrder.Provisioning_Product__r = ProvProds.size() > 0 ? ProvProds.get(0) : soc.subOrder.Provisioning_Product__r;
                soc.subOrder.Provisioning_Product__c = ProvProds.size() > 0 ? ProvProds.get(0).Id : soc.subOrder.Provisioning_Product__c;
                soc.subOrder.Workplan_Start_Date__c = subOrderConfig.Workplan_Start_Date__c;

                soc.Features = (Features != null) ? Features : new List<Feature__c>();
                soc.Modified = true;
            }
        }

        subOrderConfig.Access_Types__c = null;
        subOrderConfig.Provisioning_Product__c = null;
        subOrderConfig.Workplan_Start_Date__c = Date.today();
        return null;
    }

    public void UpdateSelectedOrder(){
        if(!string.IsEmpty(SelectedOrderId)){
            for(OrderInfo moi : OrderDisplay){
                if(moi.Order.Id == SelectedOrderId){
                    selectedOrderInfo = moi;
                    break;
                }
            }
        }
        else if(selectedOrderInfo.Order != null && selectedOrderInfo.Order.Id != null && string.IsEmpty(SelectedOrderId)){
            selectedOrderInfo = new OrderInfo();
            selectedOrderInfo.Order = new Order__c();
        }
    }

    public PageReference GetICCOrders(){
        try{
            subOrderDisplay = getExternalSubOrdersBySubscriberID(Account.ICC_Account_Number__c);
        }
        catch(Exception exp){
            error = 'error';
            createMessage('Exception: ICC returned no order properties to integrate or the process timed-out. Please try Integrating again.');   
        }
        
        if(error == '') PrepareConfigurationPage();

        return null;
    }

    public Order__c IntegratedOrder {get; set;}
    public List<Sub_Order__c> IntegratedSubOrders {get; set;}
    public Map<Id, Order_Property__c> getOrderProperties(Id parentOrderId){
        Map<Id, Order_Property__c> orderProperties = new Map<Id, Order_Property__c>();
        for(Order_Property__c op : [select Id, Name, External_ID__c, Type__c from Order_Property__c where Order__c = :parentOrderId]){              
            orderProperties.put(op.Id, op);
        }
        return orderProperties;
    }
    
    public PageReference Save(){        
        try{
            Order__c parentOrder = selectedOrderInfo.Order;
            Map<Id, Order_Property__c> orderProperties = new Map<Id, Order_Property__c>();
            boolean opExists = false;           
            if(parentOrder.Id == null){
                parentOrder.Account__c = account.Id;
                parentOrder.RecordTypeId = OrderUtils.IntegrationOnlyRecordTypeID;
                parentOrder.OwnerId = SelectedOwner;
                parentOrder.Provisioning_Plan_Enabled__c = ProvPlan;
                parentOrder.TOV_Needed__c = needsTOV;
                
                insert parentOrder;
                parentOrder = [select Id, Name, OwnerId from Order__c where Id = :parentOrder.Id limit 1].get(0);
            }
            else if(ProvPlan == true && parentOrder.Provisioning_Plan_Enabled__c == false){
                parentOrder.Provisioning_Plan_Enabled__c = ProvPlan;
                parentOrder.OwnerId = SelectedOwner;
                update parentOrder;
            }
            else if(!string.IsEmpty(SelectedOwner)){
                parentOrder.OwnerId = SelectedOwner;
                update parentOrder;
            }
            orderProperties = getOrderProperties(parentOrder.Id);
            
            if(selectedSubOrders != null) {
                List<SubOrderConfigurator> modifiedSubOrders = new List<SubOrderConfigurator>();
                for(Integer i = selectedSubOrders.size() - 1; i >= 0; --i){
                    SubOrderConfigurator soc = selectedSubOrders.get(i);
                    if(soc.Modified && SetOfModifiedTempIds.contains(soc.tempId)){
                        OrderUtils.updateSubOrderStatusesFromSubOrderGroups(soc.subOrder, soc.groups);
                        modifiedSubOrders.add(soc);
                        selectedSubOrders.remove(i);
                    }
                }

                //possibly need to create order properties?
                
                Map<String, Order_Property__c> propsToSave = new Map<String, Order_Property__c>();
                Map<String, Order_Property__c> oProperties = new Map<String, Order_Property__c>();
                Map<String, Sub_Order__c> newSubOrders = new Map<String, Sub_Order__c>();   
                Id OrderExternalId = null;          
                for(SubOrderConfigurator so : modifiedSubOrders){
                    so.subOrder.Order__c = parentOrder.Id;
                    
                    so.property.Order__c = parentOrder.Id;
                    for(Order_Property__c op : orderProperties.values()){
                        oProperties.put(op.External_ID__c, op);                         
                        if(op.External_ID__c == so.property.External_ID__c && op.Type__c == so.property.Type__c){                       
                            OrderExternalId = op.Id;                            
                            opExists = true;
                        }                       
                    }               
                    newSubOrders.put(so.tempId, so.subOrder);
                    
                    if(!opExists)
                        propsToSave.put(so.property.External_ID__c, so.property);
                }
                
                if(propsToSave.size() > 0){
                    insert propsToSave.values();                    
                }
                
                for(SubOrderConfigurator so : modifiedSubOrders){   
                    if(oProperties.size() > 0)                              
                        so.subOrder.External_Order__c = so.property.Id != null ? so.property.Id : oProperties.get(so.property.External_ID__c).Id;
                    else
                        so.subOrder.External_Order__c = propsToSave.get(so.property.External_ID__c).Id;                                                     
                }
                
                if(newSubOrders.size() > 0)
                    insert newSubOrders.values();

                //Map the External_ID with Sub Order Group
                Map<String, Sub_Order_Group__c> newSubOrderGroups = new Map<String, Sub_Order_Group__c>();
                List<Sub_Order_Feature__c> newFeatures = new List<Sub_Order_Feature__c>();
                for(SubOrderConfigurator so : modifiedSubOrders){
                    for(Sub_Order_Group__c grp : so.groups){
                        if(grp.Id == null){
                            grp.Sub_Order__c = so.subOrder.Id;
                            newSubOrderGroups.put(grp.External_ID__c, grp);
                        }
                    }
                    for(Feature__c feature : so.Features)
                        newFeatures.add(new Sub_Order_Feature__c(Feature__c = feature.Id, Sub_Order__c = so.subOrder.Id));
                }

                if(newSubOrderGroups.size() > 0){
                    Database.UpsertResult[] srList = Database.upsert(newSubOrderGroups.values(), false);        //Don't fail the process because of dupes etc
                    for(Database.UpsertResult sr : srList){
                        if(!sr.isSuccess()){
                            for(Database.Error err : sr.getErrors())
                                createMessage('Database SaveResult error: ' + err.getMessage());
                            error = 'Problem inserting sub orders.  Please review the messages or send them to IT.';
                            return null;
                        }
                    }
                }

                if(newFeatures.size() > 0)
                    insert newFeatures;

                IntegratedOrder = parentOrder;
                IntegratedSubOrders = newSubOrders.values();
                subOrderConfig = new Sub_Order__c();
            }                       
            else if(SelectedICCOrderIds != null) {          
                //need to create a suborder for each order??
                Map<String, SubOrderConfigurator> iccIdMap = new Map<String, SubOrderConfigurator>();
                for(SubOrderConfigurator soc : subOrderDisplay)
                    iccIdMap.put(soc.property.External_ID__c, soc);
                
                Map<String, Order_Property__c> propsToSave = new Map<String, Order_Property__c>();
                for(String iccId : SetOfSelectedICCOrderIds){
                    SubOrderConfigurator so = iccIdMap.get(iccId);                  
                    so.property.Order__c = parentOrder.Id;
                    for(Order_Property__c op : orderProperties.values()){                           
                        if(op.External_ID__c == so.property.External_ID__c && op.Type__c == so.property.Type__c){                                                       
                            opExists = true;                        
                        }
                    }
                                                                    
                    if(!opExists)
                        propsToSave.put(so.property.External_ID__c, so.property);
                }
                
                if(propsToSave.size() > 0)
                    insert propsToSave.values();
                IntegratedOrder = parentOrder;
            }
        }
        catch(Exception exp){
            error = 'error';
            createMessage('Exception: ' + exp.getMessage());
        }
        return null;
    }

    private integraWS.SFSubOrderView getSubOrderViewFromSubOrder(Sub_Order__c subOrder){
        integraWS.SFSubOrderView sov = new integraWS.SFSubOrderView();
        sov.SalesForceID = subOrder.Id;
        sov.ActualDueDate = subOrder.Actual_Due_Date__c;
        sov.ChangedReason = subOrder.Changed_Reason__c;
        sov.CustomerAcceptanceDate = subOrder.Customer_Acceptance_Date__c;
        sov.CustomerCommitDate = subOrder.Customer_Commit_Date__c;
        sov.CustomerRequestedDate = subOrder.Customer_Requested_Date__c;
        sov.InstallDate = subOrder.Install_Date__c;
        sov.MissedReason = subOrder.Missed_Reason__c;
        sov.ProjectedDueDate = subOrder.Projected_Due_Date__c;
        sov.Groups = new integraWS.ArrayOfSFSubOrderGroupView();
        sov.Groups.SFSubOrderGroupView = new List<integraWS.SFSubOrderGroupView>();
        for(Sub_Order_Group__c sog : subOrder.Sub_Order_Groups__r){
            integraWS.SFSubOrderGroupView sogv = new integraWS.SFSubOrderGroupView();
            sogv.ProductDescription = sog.Name;
            //remove this try/catch, keep the sogv.ExternalID assignment.
            try{
                sogv.ExternalID = Integer.ValueOf(sog.External_ID__c);      //Let it error if this fails
            }

            catch(Exception exp){
                error = 'error';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Exception! ' + exp.getMessage()));    
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'subOrder: ' + subOrder));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'subOrderGroup: ' + sog));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'SessionID: ' + UserInfo.getSessionID()));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'SFDC Callback: ' + CustomSettingUtils.SFDCCallbackEndpoint));
            }
            sogv.Quantity = sog.Quantity__c != null ? Integer.ValueOf(sog.Quantity__c) : 0;
            sogv.Status = sog.Status__c;
            sogv.SalesforceID = sog.Id;
            sov.Groups.SFSubOrderGroupView.add(sogv);
        }  
        
        return sov;
    }


    private List<integraWS.SFSubOrderView> getSubOrderViewFromSubOrders(List<Sub_Order__c> subOrders){
        integraWS.ArrayOfSFSubOrderView retval = new integraWS.ArrayOfSFSubOrderView();
        retval.SFSubOrderView = new List<integraWS.SFSubOrderView>();
        for(Sub_Order__c so : subOrders)
            retval.SFSubOrderView.add(getSubOrderViewFromSubOrder(so));
        return retval.SFSubOrderView;
    }

    public static List<Sub_Order__c> getSubOrdersFromView(List<integraWS.SFSubOrderView> views){
        List<Sub_Order__c> retval = new List<Sub_Order__c>();
        for(integraWS.SFSubOrderView v : views){
            retval.add(new Sub_Order__c(Id = !string.IsEmpty(v.SalesforceID) ? v.SalesforceID : null
                                        ,Actual_Due_Date__c = v.ActualDueDate
                                        ,Changed_Reason__c = v.ChangedReason
                                        ,Customer_Acceptance_Date__c = v.CustomerAcceptanceDate
                                        ,Customer_Commit_Date__c = v.CustomerCommitDate
                                        ,Customer_Requested_Date__c = v.CustomerRequestedDate
                                        ,Install_Date__c = v.InstallDate
                                        ,Missed_Reason__c = v.MissedReason
                                        ,Projected_Due_Date__c = v.ProjectedDueDate));
        }
        return retval;
    }

    public static List<Sub_Order_Group__c> getSubOrderGroupsFromView(List<integraWS.SFSubOrderGroupView> views){
        List<Sub_Order_Group__c> retval = new List<Sub_Order_Group__c>();
        for(integraWS.SFSubOrderGroupView v : views)
            retval.add(getSubOrderGroupFromView(v));

        return retval;
    }

    public static Sub_Order_Group__c getSubOrderGroupFromView(integraWS.SFSubOrderGroupView view){
        return new Sub_Order_Group__c(Id = !string.IsEmpty(view.SalesforceID) ? view.SalesforceID : null
                                    ,Name = view.ProductDescription
                                    ,External_ID__c = string.valueOf(view.ExternalID)
                                    ,Product__c = view.ProductDescription
                                    ,Quantity__c = view.Quantity
                                    ,Status__c = view.Status
                                    ,MRR__c = view.MRC);
    }

    public static List<Order_Property__c> getOrderPropertiesFromView(integraWS.ArrayOfSFOrderPropertyView views){
        List<Order_Property__c> retval = new List<Order_Property__c>();
        try{
            RecordType externalOrderRecordType = [select Id from RecordType where Name = 'External Order'].get(0);
            for(integraWS.SFOrderPropertyView v : views.SFOrderPropertyView != null ? views.SFOrderPropertyView : new List<integraWS.SFOrderPropertyView>()){
                retval.add(new Order_Property__c(Id = !string.IsEmpty(v.SalesforceID) ? v.SalesforceID : null
                                                ,External_ID__c = string.valueOf(v.ExternalID)
                                                ,Type__c = v.OrderType
                                                ,RecordType = externalOrderRecordType));
            }
        }
        catch(Exception e){
            ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, 'Error acquiring ICC Order Properties! Please contact a system admin if the selected Order should be available for integration');
            ApexPages.addMessage(m);  
        }
        return retval;
    }

    private List<integraWS.SFSubOrderView> getSubOrderViewFromExistingSubOrders(){
        return getSubOrderViewFromSubOrders(existingSubOrders.values());
    }

    private SubOrderConfigurator getConfigurationItemFromSubOrder(Integer tempId, integraWS.SFSubOrderView soView, Order_Property__c oProp, Service_Location__c sloc, SPC_Product__c product){
        return new SubOrderConfigurator(tempId, oProp, getSubOrdersFromView(new List<integraWS.SFSubOrderView>{soView})[0], getSubOrderGroupsFromView(soView.Groups.SFSubOrderGroupView), sloc, product);
    }

    private integraWS.ArrayOfSFOrderPropertyView getSubOrderListBySubscriberID(Integer subscriberID) {
        if(!integraWSEndpointMediator.integrationEnabled()){            
            return test.IsRunningTest() ? Test_OrderManagement.getSubOrderListBySubscriberID(subscriberID) : new integraWS.ArrayOfSFOrderPropertyView();
            //return new integraWS.ArrayOfSFOrderPropertyView();
        }
        
        return integraWSEndpointMediator.Endpoint.GetSubOrderListBySubscriberID(subscriberID, UserInfo.getSessionID(), CustomSettingUtils.SFDCCallbackEndpoint);
    }

    private integraWS.SFOrderView getSubOrderSummaryByOrderIds(List<Integer> orderIDs,Integer subscriberID, List<integraWS.SFSubOrderView> existingSubOrders) {
        integraWS.ArrayOfSFSubOrderView arr = new integraWS.ArrayOfSFSubOrderView();
        arr.SFSubOrderView = existingSubOrders;

        schemasMicrosoftCom200310Serializat.ArrayOfint oIds = new schemasMicrosoftCom200310Serializat.ArrayOfint();
        oIds.int_x = orderIDs;

        if(!integraWSEndpointMediator.integrationEnabled()){
            return test.IsRunningTest() ? Test_OrderManagement.getSubOrderSummaryByOrderIds(orderIDs, subscriberID) : new integraWS.SFOrderView();
            //return new integraWS.SFOrderView();
        }

        return integraWSEndpointMediator.Endpoint.GetSubOrderSummaryByOrderIDs(oIds, arr, UserInfo.getSessionID(), CustomSettingUtils.SFDCCallbackEndpoint);
    }

    public PageReference SaveModifiedSubOrders(){

        try{
            List<SubOrderConfigurator> modifiedSubOrders = new List<SubOrderConfigurator>();    //gathered
            for(Integer i = selectedSubOrders.size() - 1; i >= 0; --i){
                SubOrderConfigurator soc = selectedSubOrders.get(i);
                if(soc.Modified && SetOfModifiedTempIds.contains(soc.tempId)){
                    OrderUtils.updateSubOrderStatusesFromSubOrderGroups(soc.subOrder, soc.groups);
                    //CreateMessage('subOrder Status: ' + soc.subOrder.Status__c);
                    modifiedSubOrders.add(soc);
                    selectedSubOrders.remove(i);
                }
            }

            Order__c parentOrder = selectedOrderInfo.Order;     //gathered
            if(parentOrder.Id == null){
                parentOrder.Account__c = account.Id;
                parentOrder.RecordTypeId = OrderUtils.IntegrationOnlyRecordTypeID;
                insert parentOrder;
                parentOrder = [select Id, Name from Order__c where Id = :parentOrder.Id limit 1].get(0);
            }

            Map<String, Order_Property__c> propsToSave = new Map<String, Order_Property__c>();
            Map<String, Sub_Order__c> newSubOrders = new Map<String, Sub_Order__c>();
            for(SubOrderConfigurator so : modifiedSubOrders){
                so.subOrder.Order__c = parentOrder.Id;
                newSubOrders.put(so.tempId, so.subOrder);
                if(!propsToSave.containsKey(so.property.External_ID__c)){
                    so.property.Order__c = parentOrder.Id;
                    propsToSave.put(so.property.External_ID__c, so.property);
                }
            }

            if(propsToSave.size() > 0){
                /* Existing properties should have already auto-saved all of their sub-orders
                for(Order_Property__c existing : [select Id, External_ID__c, Order__c from Order_Property__c where External_ID__c in: propsToSave.keyset()])
                    propsToSave.get(existing.External_ID__c).Id = existing.Id;*/

                insert propsToSave.values();
            }

            for(SubOrderConfigurator so : modifiedSubOrders){           
                if(propsToSave.size() > 0)              
                    so.subOrder.External_Order__c = propsToSave.get(so.property.External_ID__c).Id;
                else
                     so.subOrder.External_Order__c = so.property.External_ID__c;                
                //so.subOrder.Service_Location__c = so.location.Id;     
            }

            if(newSubOrders.size() > 0){
                insert newSubOrders.values();
            }

            List<Sub_Order_Group__c> newSubOrderGroups = new List<Sub_Order_Group__c>();
            for(SubOrderConfigurator so : modifiedSubOrders){
                for(Sub_Order_Group__c grp : so.groups){
                    grp.Sub_Order__c = so.subOrder.Id;
                    newSubOrderGroups.add(grp);
                }
            }

            if(newSubOrderGroups.size() > 0){
                //List<Sub_Order_Feature__c> newFeatures = new List<Sub_Order_Feature__c>();
                Database.SaveResult[] srList = Database.Insert(newSubOrderGroups, false);       //Don't fail the process because of dupes etc
                for(Database.SaveResult sr : srList){
                    if(!sr.isSuccess()){
                        for(Database.Error err : sr.getErrors()){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'error: ' + err.getMessage()));
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'error-fields: ' + err.getFields()));
                        }
                        error = 'Problem inserting sub orders.  Please review the messages or send them to IT.';
                        return null;
                    }
                    /*else{
                        for(SubOrderConfigurator soc : modifiedSubOrders){
                            Sub_Order__c so = newSubOrders.get(soc.tempId);
                            for(Feature__c feature : soc.featuresList){
                                Sub_Order_Feature__c soFeature = new Sub_Order_Feature__c();
                                soFeature.Feature__c = feature.Id;
                                soFeature.Sub_Order__c = so.Id;
                                newFeatures.add(soFeature);
                            }
                        }
                    }*/
                }
                /*if(newFeatures.size() > 0)
                    insert newFeatures;*/
            }

            IntegratedOrder = parentOrder;
            IntegratedSubOrders = newSubOrders.values();

            //subOrderConfig = new Sub_Order__c();
        }
        catch(Exception exp){
            error = 'error';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Exception! ' + exp.getMessage()));
        }
        
        return null;
    }

    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_OrderManagement(); }
}