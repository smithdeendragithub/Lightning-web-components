public with sharing class CustomerHierarchyController {
    
    public static final String act_OpenCustomerDetail = 'Open Customer Detail';
    public static final String act_OpenCustomerDetailInNewTab = 'Open Customer Detail in new tab';
    public static final String act_OpenServiceLocation = 'Open Service Location';
    public static final String act_OpenServiceLocationInNewTab = 'Open Service Location in new tab';
    
    public static String actDef_OpenCustomerDetail { get { return 'openDetail'; } }
    public static String actDef_OpenCustomerDetailInNewTab { get { return 'openDetailInNewTab'; } }
    public static String actDef_OpenServiceLocation { get { return 'openServiceLoc'; } }
    public static String actDef_OpenServiceLocationInNewTab { get { return 'openServiceLocInNewTab'; } }
    
    public CustomerHierarchyController(){
        //Default constructor so this can be used by the common javascript component
    }
    
    transient public static Map<String, String> iconMapping {get; private set;}
    
    public class TreeViewImplementation extends TreeViewController.TreeViewImplementation{
        private Set<Id> IDs {get; set;}
        
        public TreeViewImplementation(Id id){
            IDs = new Set<Id>{id};
            loadMoreEnabled = true;
        }

        public override Boolean getCanLoadTree(){
            try {
                for (Id i : IDs){
                    Integer numServiceLocation = [select count() from Service_Location__c where Account__c = :i];
                    system.debug('numServiceLocation: ' + numServiceLocation);
                    if (numServiceLocation > 1000){
                        return false;
                    }
                    else {
                        return true;
                    }
                }
                return false;
            }
            catch (Exception e){
                return false; 
            }   
        }
        
        public override List<TreeNode> getNodes(){
            initializeCollections();
            return GetIntegrationHierarchiesFromIDs(IDs);
        }
        
        public override List<TreeNode> getMoreNodes(String path){
            initializeCollections();
            GetIntegrationHierarchiesFromIDs(IDs);
            return nodesByPath.get(path);
        }
        
        public override Map<String, String> getActionMap(){
            return new Map<String, String>{
                actDef_OpenCustomerDetail=>act_OpenCustomerDetail
                ,actDef_OpenCustomerDetailInNewTab=>act_OpenCustomerDetailInNewTab
                ,actDef_OpenServiceLocation=>act_OpenServiceLocation
                ,actDef_OpenServiceLocationInNewTab=>act_OpenServiceLocationInNewTab
            };
        }
        
        public override Map<String, String> getIconMap(){
            return mapSObjectIcons();
        }
        
        private void initializeCollections(){
            mapSObjectIcons();
        }
        
        transient private Map<String, List<TreeNode>> nodesByPath {get; private set;}
    
        private transient Map<Id, List<Customer_Contact__c>> customerContactsByDetailID;
        private List<TreeNode> GetIntegrationHierarchiesFromIDs(Set<Id> ids){
            List<TreeNode> nodes = new List<TreeNode>();
            
            try{
                Map<Id, Account> accounts = new Map<Id, Account>([select Id
                                                                    ,Name
                                                                    ,ICC_Account_Number__c
                                                                    ,ICC_Account_Type__c
                                                                    ,Billable__c
                                                                    ,Customer_Detail__c
                                                                    ,RecordType.DeveloperName
                                                                from Account where Id in : ids
                                                                or RecordType.DeveloperName = 'System']);
                //Always load the system account so we can remove it from the set
                for(Account a : new List<Account>(accounts.values())){
                    if(a.RecordType.DeveloperName == 'System'){
                        ids.remove(a.Id);
                        accounts.remove(a.Id);
                    }
                }
                if(ids.size() == 0) return nodes;
                
                Map<Id, TreeNode> flattenedCoreNodesByID = new Map<Id, TreeNode>();
                Map<Id, Id> nodeParents = new Map<Id, Id>();
                Map<Id, Id> previousAccounts = new Map<Id, Id>();
                
                Map<Id, Customer_Detail__c> customerDetails = new Map<Id, Customer_Detail__c>();
                Set<Id> contactIDs = new Set<Id>();
                Map<Id, List<Contact>> contactsByAccountID = new Map<Id, List<Contact>>();
                if(accounts.size() > 0){
                    for(Account a : accounts.values()){
                        flattenedCoreNodesByID.put(a.Id, new TreeNode(a.Name + (!string.IsEmpty(a.ICC_Account_Number__c) ? ' [' + a.ICC_Account_Number__c + ']' : ''), a.Id));
                        nodeParents.put(a.Id, null);
                        
                        if(a.Customer_Detail__c != null)
                            customerDetails.put(a.Customer_Detail__c, null);
                    }
                    
                    for(Contact c : [select Id
                                            ,Name
                                            ,Phone
                                            ,Email
                                            ,AccountId
                                            ,Default_Responsible_Party__c
                                            ,Default_Contact_Types__c
                                            ,MobilePhone
                                            ,Fax
                                            ,Extension__c
                                            ,Authorized_User_Password__c
                                            ,DoNotCall
                                            ,(select Opportunity.Name, Opportunity.Id, Role from OpportunityContactRoles)
                                    from Contact
                                    where AccountId in : accounts.keyset()
                                    order by LastName, FirstName, Phone nulls first]){
                        List<Contact> contacts = contactsByAccountID.get(c.AccountId) != null ? contactsByAccountID.get(c.AccountId) : new List<Contact>();
                        contacts.add(c);
                        contactsByAccountID.put(c.AccountId, contacts);
                        contactIDs.add(c.Id);
                    }
                }

                Integer numServiceLocation = [select count() from Service_Location__c where Account__c in : accounts.keyset()];
                System.debug('# of service locations: ' + numServiceLocation);
                If (numServiceLocation < 1000){
                	Map<Id, Service_Location__c> sLocs = new Map<Id, Service_Location__c>();
                    for(Service_Location__c sLoc : [select Id
                                                            ,Account__c
                                                            ,Account__r.Customer_Detail__c
                                                            ,Name
                                                            ,ICC_Subscriber_ID__c
                                                            ,Parent_Service_Location__c
                                                            ,Parent_Service_Location__r.Customer_Detail__c
                                                            ,Parent_Service_Location__r.Account__c
                                                            ,Parent_Service_Location__r.Account__r.Customer_Detail__c
                                                            ,Billable__c
                                                            ,Customer_Detail__c
                                                        from Service_Location__c where Account__c in : accounts.keyset()]){
                        sLocs.put(sLoc.Id, sLoc);
                        
                        if(sloc.Customer_Detail__c != null)
                            customerDetails.put(sloc.Customer_Detail__c, null);
                        
                        Id parentID = null;
                        if(sLoc.Parent_Service_Location__c != null) parentID = (sLoc.Parent_Service_Location__r.Customer_Detail__c == sLoc.Parent_Service_Location__r.Account__r.Customer_Detail__c) ? sLoc.Parent_Service_Location__r.Account__c : sLoc.Parent_Service_Location__c;
                        else if(sLoc.Customer_Detail__c == null || sLoc.Customer_Detail__c != sLoc.Account__r.Customer_Detail__c) parentID = sLoc.Account__c;
                        else continue;
                        
                        nodeParents.put(sLoc.Id, parentID);
                        flattenedCoreNodesByID.put(sLoc.Id, new TreeNode(sLoc.Name + (!string.IsEmpty(sLoc.ICC_Subscriber_ID__c) ? ' [' + sLoc.ICC_Subscriber_ID__c + ']' : ''), sLoc.Id));
                    }
                    
                    Set<Id> cdIDs = new Set<Id>(ids);
                    cdIDs.addAll(customerDetails.keyset());
                    System.debug('# of customer details: ' + [select count()
                                                    from Customer_Detail__c
                                                    where Id in: cdIDs
                                                        or Parent_Account__c in: ids
                                                        or Parent_Customer__c in: cdIDs
                                                        or Parent_Customer__r.Parent_Account__c in: ids
                                                        or Parent_Customer__r.Parent_Customer__c in: cdIDs
                                                        or Parent_Customer__r.Parent_Customer__r.Parent_Account__c in: ids
                                                        or Former_Account__c in: ids
                                                        or Parent_Customer__r.Former_Account__c in: ids
                                                        or Parent_Customer__r.Parent_Customer__r.Former_Account__c in: ids]);
                    for(Customer_Detail__c cd : [select Id
                                                        ,ICC_Subscriber_ID__c
                                                        ,Name
                                                        ,Billable__c
                                                        ,Inactive_Date__c
                                                        ,Integration_Status__c
                                                        ,Former_Account__c
                                                        ,Parent_Customer__c
                                                        ,Suspended__c
                                                        ,(select Id from Accounts__r)
                                                        ,(select Id from Service_Locations__r)
                                                        ,(select Id, External_ID__c, Product_Name__c, Product_Term__c, Product_Term_Start_Date__c, Product_Term_End_Date__c, MRR__c, Status__c, First_CN__c from Services__r where Status__c != 'Inactive' order by Product_Name__c, External_ID__c)
                                                    from Customer_Detail__c
                                                    where Id in: cdIDs
                                                        or Parent_Account__c in: ids
                                                        or Parent_Customer__c in: cdIDs
                                                        or Parent_Customer__r.Parent_Account__c in: ids
                                                        or Parent_Customer__r.Parent_Customer__c in: cdIDs
                                                        or Parent_Customer__r.Parent_Customer__r.Parent_Account__c in: ids
                                                        or Former_Account__c in: ids
                                                        or Parent_Customer__r.Former_Account__c in: ids
                                                        or Parent_Customer__r.Parent_Customer__r.Former_Account__c in: ids]){
                        //If it's not already in the map, we haven't loaded a front-end object for it yet
                        if(!customerDetails.containsKey(cd.Id)){
                            nodeParents.put(cd.Id, cd.Parent_Customer__c);
                            flattenedCoreNodesByID.put(cd.Id, new TreeNode(cd.Name + (!string.IsEmpty(cd.ICC_Subscriber_ID__c) ? ' [' + cd.ICC_Subscriber_ID__c + ']' : ''), cd.Id));
                        }
                        if(cd.Former_Account__c != null) previousAccounts.put(cd.Id, cd.Former_Account__c);
                        customerDetails.put(cd.Id, cd);
                    }
                    
                    Map<Id, Map<Id, List<Customer_Contact__c>>> customerContactsByDetailIDAndContactID = new Map<Id, Map<Id, List<Customer_Contact__c>>>();
                    customerContactsByDetailID = new Map<Id, List<Customer_Contact__c>>();
                    for(Customer_Contact__c cc : [select Name
                                                        ,Id
                                                        ,Contact__c
                                                        ,Contact__r.Name
                                                        ,Contact__r.Default_Responsible_Party__c
                                                        ,Contact_Type__c
                                                        ,Contact__r.Phone
                                                        ,Contact__r.Email
                                                        ,Phone__c
                                                        ,Email__c
                                                        ,Customer_Detail__c
                                                        ,Contact__r.Account.Customer_Detail__c
                                                    from Customer_Contact__c
                                                    where Contact__c in : contactIDs
                                                    or Customer_Detail__c in : customerDetails.keyset()
                                                    order by Contact__r.LastName, Contact__r.FirstName, Contact_Type__c ]){
                        if(cc.Contact__c != null){
                            if(customerContactsByDetailIDAndContactID.get(cc.Customer_Detail__c) == null)
                                customerContactsByDetailIDAndContactID.put(cc.Customer_Detail__c, new Map<Id, List<Customer_Contact__c>>());
                            List<Customer_Contact__c> ccs = customerContactsByDetailIDAndContactID.get(cc.Customer_Detail__c).get(cc.Contact__c) != null ? customerContactsByDetailIDAndContactID.get(cc.Customer_Detail__c).get(cc.Contact__c) : new List<Customer_Contact__c>();
                            ccs.add(cc);
                            customerContactsByDetailIDAndContactID.get(cc.Customer_Detail__c).put(cc.Contact__c, ccs);
                        }
                        if(cc.Customer_Detail__c != null){
                            List<Customer_Contact__c> ccs = customerContactsByDetailID.get(cc.Customer_Detail__c) != null ? customerContactsByDetailID.get(cc.Customer_Detail__c) : new List<Customer_Contact__c>();
                            ccs.add(cc);
                            customerContactsByDetailID.put(cc.Customer_Detail__c, ccs);
                        }
                    }
                    
                    Set<Id> orderIDs = new Set<Id>();
                    Map<Id, List<Order__c>> ordersByAccountID = new Map<Id, List<Order__c>>();
                    for(Order__c o : [select Id, Name, Account__c, Opportunity__r.AccountId, CreatedDate, RecordType.Name from Order__c where Opportunity__r.AccountId in : accounts.keyset() or Account__c in : accounts.keyset() order by Name]){
                        Id accountID = o.Account__c != null ? o.Account__c : o.Opportunity__r.AccountId;
                        List<Order__c> orders = ordersByAccountID.get(accountID) != null ? ordersByAccountID.get(accountID) : new List<Order__c>();
                        orders.add(o);
                        ordersByAccountID.put(accountID, orders);
                        orderIDs.add(o.Id);
                    }
                    
                    Map<Id, List<Order_Property__c>> orderProps = new Map<Id, List<Order_Property__c>>();
                    for(Order_Property__c op : [select Id, Name, Order__c, External_ID__c, Type__c from Order_Property__c where Order__c in: orderIDs order by Name]){
                        List<Order_Property__c> ops = orderProps.get(op.Order__c) != null ? orderProps.get(op.Order__c) : new List<Order_Property__c>();
                        ops.add(op);
                        orderProps.put(op.Order__c, ops);
                    }
                    
                    Map<Id, List<Sub_Order_Group__c>> sogMap = new Map<Id, List<Sub_Order_Group__c>>();
                    Map<Id, List<Sub_Order__c>> subOrdersByParentID = new Map<Id, List<Sub_Order__c>>();
                    for(Sub_Order__c so : [select Id
                                                ,Name
                                                ,Customer_Detail__c
                                                ,Service_Location__c
                                                ,External_Order__c
                                                ,External_Order__r.External_ID__c
                                                ,External_Order__r.Name
                                                ,Customer_Commit_Date__c
                                                ,Status__c
                                            from Sub_Order__c where Order__c in: orderIDs and (Customer_Detail__c != null or Service_Location__c != null) and External_Order__c != null
                                            order by External_Order__r.External_ID__c, Sub_Sequence__c]){
                        Id parentID = so.Customer_Detail__c != null ? so.Customer_Detail__c : so.Service_Location__c;
                        List<Sub_Order__c> sos = subOrdersByParentID.get(parentID) != null ? subOrdersByParentID.get(parentID) : new List<Sub_Order__c>();
                        sos.add(so);
                        subOrdersByParentID.put(parentID, sos);
                        sogMap.put(so.Id, null);
                    }
                    
                    for(Sub_Order_Group__c sog : [select Id, Sub_Order__c, External_ID__c, Name, MRR__c, Status__c, Cancel_Reason__c from Sub_Order_Group__c where Sub_Order__c in: sogMap.keyset() order by External_ID__c]){
                        List<Sub_Order_Group__c> l = sogMap.get(sog.Sub_Order__c) != null ? sogMap.get(sog.Sub_Order__c) : new List<Sub_Order_Group__c>();
                        l.add(sog);
                        sogMap.put(sog.Sub_Order__c, l);
                    }
                    
                    Map<Id, Account> aMap = new Map<Id, Account>();
                    Map<Id, Customer_Detail__c> cMap = new Map<Id, Customer_Detail__c>();
                    Map<Id, Service_Location__c> sMap = new Map<Id, Service_Location__c>();
                    Map<Id, TreeNode> allRecordNodes = new Map<Id, TreeNode>();
                    
                    //Loop once to map out the nodes to all representing entities
                    Map<Id, Set<Id>> parentChildSubs = new Map<Id, Set<Id>>();
                    for(Id id : flattenedCoreNodesByID.keyset()){
                        TreeNode n = flattenedCoreNodesByID.get(id);
                        
                        Account a = accounts.get(id);
                        Service_Location__c sLoc = sLocs.get(id);
                        Customer_Detail__c cd = customerDetails.get(id);
                        
                        if(a != null && a.Customer_Detail__c != null){
                            cd = customerDetails.get(a.Customer_Detail__c);
                            if(cd.Service_Locations__r != null && cd.Service_Locations__r.size() > 0)
                                sLoc = sLocs.get(cd.Service_Locations__r[0].Id);
                        }
                        else if(sLoc != null && sLoc.Customer_Detail__c != null)
                            cd = customerDetails.get(sLoc.Customer_Detail__c);
                        
                        if(a != null){
                            allRecordNodes.put(a.Id, n);
                            aMap.put(Id, a);
                        }
                        if(sLoc != null){
                            allRecordNodes.put(sLoc.Id, n);
                            sMap.put(Id, sLoc);
                        }
                        if(cd != null) {
                            allRecordNodes.put(cd.Id, n);
                            cMap.put(Id, cd);
                            
                            if(cd.Parent_Customer__c != null && !string.isEmpty(cd.ICC_Subscriber_ID__c)){
                                Set<Id> s = parentChildSubs.get(cd.Parent_Customer__c) != null ? parentChildSubs.get(cd.Parent_Customer__c) : new Set<Id>();
                                s.add(cd.Id);
                                parentChildSubs.put(cd.Parent_Customer__c, s);
                            }
                        }
                    }
                    
                    //Loop a second time to place in the correct location
                    Set<Id> addAsFormerHierarchy = new Set<Id>();
                    for(Id id : flattenedCoreNodesByID.keyset()){
                        TreeNode n = flattenedCoreNodesByID.get(id);
                        
                        Id parentID = nodeParents.get(id);
                        Id parentAccountID = previousAccounts.get(id);
                        if(parentID != null && allRecordNodes.get(parentID) != null){
                            allRecordNodes.get(parentID).addChildNode(n, '');
                        }
                        else if(parentAccountID != null && flattenedCoreNodesByID.get(parentAccountID) != null){
                            addAsFormerHierarchy.add(id);
                        }
                        else{
                            nodes.add(n);
                        }
                    }
                    
                    //Loop a third time to build out child folders
                    for(Id id : flattenedCoreNodesByID.keyset()){
                        TreeNode n = flattenedCoreNodesByID.get(id);
                        
                        Account a = aMap.get(id);
                        Service_Location__c sLoc = sMap.get(id);
                        Customer_Detail__c cd = cMap.get(id);
                        
                        if(cd != null && !string.IsEmpty(cd.ICC_Subscriber_ID__c)){
                            Boolean childExists = parentChildSubs.containsKey(cd.Id);
                            Boolean grandChildExists = false;
                            if(childExists){
                                for(Id c : parentChildSubs.get(cd.Id)){
                                    if(parentChildSubs.containsKey(c) && parentChildSubs.get(c).size() > 0){
                                        grandChildExists = true;
                                        break;
                                    }
                                }
                            }
                            
                            n.setAttribute('Subscriber ID', cd.ICC_Subscriber_ID__c);
                            n.setAttribute('Subscriber Type', cd.Billable__c
                                                                        ? (childExists ? (grandChildExists ? 'INVALID BILLABLE TYPE' : ICCWrapper.BillableParentType) : (cd.Parent_Customer__c == null ? ICCWrapper.StandAloneType : ICCWrapper.BillableChildType))
                                                                        : (childExists ? (grandChildExists ? ICCWrapper.NonBillableGrandParentType : ICCWrapper.NonBillableParentType) : (cd.Parent_Customer__c == null ? 'INVALID NON-BILLABLE TYPE' : ICCWrapper.NonBillableChildType)));
                            n.setAttribute('Inactive Date', string.valueOf(cd.Inactive_Date__c));
                            
                            if(!n.attributes.get('Subscriber Type').startsWith('INVALID'))
                                n.iconID = n.attributes.get('Subscriber Type');
                            
                            if(!String.isEmpty(cd.Integration_Status__c) && IntegrationUtils.inactiveSubscriberStatuses.contains(cd.Integration_Status__c)) n.iconID = 'Inactive';
                            else if(cd.Suspended__c) n.iconID = 'Suspended';
                        }
                        
                        n.setAttribute('Billable', (cd != null && cd.Billable__c) || (a != null && a.Billable__c) || (sLoc != null && sLoc.Billable__c) ? 'Yes' : 'No');
                        
                        if(a != null && sLoc != null){
                            addActionsToNode(n, new List<String>{actDef_OpenServiceLocation, actDef_OpenServiceLocationInNewTab});
                            n.hiddenAttributes.put('sLoc', sLoc.Id);
                        }
                        
                        if(cd != null){
                            if(a != null || sLoc != null){
                                addActionsToNode(n, new List<String>{actDef_OpenCustomerDetail, actDef_OpenCustomerDetailInNewTab});
                                n.hiddenAttributes.put('cDetail', cd.Id);
                            }
                            
                            if(a != null) getContactNodes(n, contactsByAccountID.get(a.Id), customerContactsByDetailIDAndContactID.get(a.Customer_Detail__c));
                            else getContactNodes(n, customerContactsByDetailID.get(cd.Id));
                            
                            for(Service__c s : cd.Services__r != null ? cd.Services__r : new List<Service__c>()){
                                TreeNode sNode = new TreeNode(s.Product_Name__c, s.Id);
                                sNode.setAttribute('External ID', s.External_ID__c);
                                sNode.setAttribute('Status', s.Status__c);
                                sNode.setAttribute('Term', string.valueOf(s.Product_Term__c));
                                sNode.setAttribute('Term Start Date', string.valueOf(s.Product_Term_Start_Date__c));
                                sNode.setAttribute('Term End Date', string.valueOf(s.Product_Term_End_Date__c));
                                sNode.setAttribute('MRR', string.valueOf(s.MRR__c));
                                //sNode.setAttribute('1st CN', s.First_CN__c);
                                n.addChildNode(sNode, 'Active Services');
                            }
                            
                            n.setAttribute('Integration Status', cd.Integration_Status__c);
                        }
                        
                        if(a != null){
                            for(Order__c o : ordersByAccountID.get(a.Id) != null ? ordersByAccountID.get(a.Id) : new List<Order__c>()){
                                TreeNode orderNode = new TreeNode(o.Name, o.Id);
                                for(Order_Property__c op : orderProps.get(o.Id) != null ? orderProps.get(o.Id) : new List<Order_Property__c>()){
                                    TreeNode opNode = new TreeNode(op.Name, op.Id);
                                    opNode.setAttribute('External ID', op.External_ID__c);
                                    opNode.setAttribute('Type', op.Type__c);
                                    orderNode.addChildNode(opNode, 'Properties');
                                }
                                orderNode.setAttribute('Record Type', o.RecordType.Name);
                                orderNode.setAttribute('Created Date', string.valueOf(o.CreatedDate));
                                n.addChildNode(orderNode, 'Orders');
                            }
                        }
                        
                        if(cd != null) getExternalOrders(n, subOrdersByParentID.get(cd.Id), sogMap);
                        
                        if(addAsFormerHierarchy.contains(id)) flattenedCoreNodesByID.get(previousAccounts.get(id)).addChildNode(n, 'Former Hierarchies');
                    }
                }               
                system.debug('Integration hierarchy: ' + nodes);
            }
            catch(Exception e){
                nodes.clear();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The customer hierarchy failed to load: ' + e.getMessage()));
            }
            
            nodesByPath = TreeNode.getNodeMap(nodes);
            return nodes;
        }
        
        private void getExternalOrders(TreeNode node, List<Sub_Order__c> sos, Map<Id, List<Sub_Order_Group__c>> sogMap){
            Map<Integer, Order_Property__c> externalOrders = new Map<Integer, Order_Property__c>();
            Map<Integer, List<Sub_Order__c>> soMap = new Map<Integer, List<Sub_Order__c>>();
            for(Sub_Order__c so : sos != null ? sos : new List<Sub_Order__c>()){
                if(sogMap.get(so.Id) != null){
                    try{
                        Integer orderID = Integer.valueOf(so.External_Order__r.External_ID__c);
                        
                        externalOrders.put(orderID, so.External_Order__r);
                        List<Sub_Order__c> sol = soMap.get(orderID) != null ? soMap.get(orderID) : new List<Sub_Order__c>();
                        sol.add(so);
                        soMap.put(orderID, sol);
                    }
                    catch(Exception e){ /* Junk in, junk out */ }
                }
            }
            
            for(Integer orderID : externalOrders.keyset()){
                Order_Property__c op = externalOrders.get(orderID);
                
                Datetime ccd = null;
                Boolean isCompleted = true;
                for(Sub_Order__c so : soMap.get(orderID)){
                    isCompleted &= (so.Status__c == 'Cancelled' || so.Status__c == 'Closed');
                    ccd = (ccd == null || (so.Customer_Commit_Date__c != null && ccd < so.Customer_Commit_Date__c)) ? so.Customer_Commit_Date__c : ccd;
                }
                
                TreeNode eoNode = new TreeNode(op.Name, op.Id);
                if(!isCompleted){
                    eoNode.setAttribute('Customer Commit Date', ccd != null ? String.format('{0}/{1}/{2}', new List<String>{string.valueOf(ccd.month()), string.valueOf(ccd.day()), string.valueOf(ccd.year())}) : null);
                }
                node.addChildNode(eoNode, isCompleted ? 'Completed External Orders' : 'External Orders');
                
                for(Sub_Order__c so : soMap.get(orderID)){
                    for(Sub_Order_Group__c sog : sogMap.get(so.Id)){
                        TreeNode sogNode = new TreeNode(sog.Name + (!string.isEmpty(sog.External_ID__c) ? (' (' + sog.External_ID__c + ')') : ''), sog.Id);
                        sogNode.setAttribute('External ID', sog.External_ID__c);
                        sogNode.setAttribute('MRR', '$' + string.valueOf(sog.MRR__c));
                        sogNode.setAttribute('Status', sog.Status__c);
                        sogNode.setAttribute('Cancel Reason', sog.Cancel_Reason__c);
                        sogNode.setAttribute('Sub-Order', so.Name);
                        eoNode.addChildNode(sogNode, '');
                    }
                }
            }
        }
        
        private Customer_Contact__c getContactNodes(TreeNode node, List<Contact> contacts, Map<Id, List<Customer_Contact__c>> customerContactsByContactID){
            Customer_Contact__c respParty = null;
            
            Contact defaultResponsibleParty = null;
            for(Contact c : contacts != null ? contacts : new List<Contact>()){
                TreeNode contactNode = new TreeNode(c.Name, c.Id);
                List<Customer_Contact__c> ccs = customerContactsByContactID != null && customerContactsByContactID.get(c.Id) != null ? customerContactsByContactID.get(c.Id) : new List<Customer_Contact__c>();
                
                Customer_Contact__c ccRespParty = getCustomerContactNodes(contactNode, ccs);
                respParty = respParty == null ? ccRespParty : respParty;
                contactNode.setAttribute('Phone', string.valueOf(c.get('Phone')));
                contactNode.setAttribute('Extension', String.valueOf(c.get('Extension__c')));
                contactNode.setAttribute('Fax', String.valueOf(c.get('Fax')));
                contactNode.setAttribute('Mobile', String.valueOf(c.get('MobilePhone')));
                contactNode.setAttribute('Email', string.valueOf(c.get('Email')));
                contactNode.setAttribute('Password', String.valueOf(c.get('Authorized_User_Password__c')));
                contactNode.setAttribute('Do not call list', String.valueOf(c.get('DoNotCall')));
                Map<Id, TreeNode> oppNodes = new Map<Id, TreeNode>();
                for(OpportunityContactRole r : c.OpportunityContactRoles != null ? c.OpportunityContactRoles : new List<OpportunityContactRole>()){
                    TreeNode oppNode = oppNodes.get(r.Opportunity.Id);
                    
                    if(oppNode == null){
                        oppNode = new TreeNode(r.Opportunity.Name, r.Opportunity.Id);
                        oppNode.iconID = 'config';
                        oppNodes.put(r.Opportunity.Id, oppNode);
                        contactNode.addChildNode(oppNode, 'Opportunity Roles');
                    }
                    TreeNode roleNode = new TreeNode(r.Role, null);
                    roleNode.iconID = 'config';
                    oppNode.addChildNode(roleNode, '');
                }
                Set<String> contactTypes = new Set<String>(c.Default_Contact_Types__c == null ? new List<String>() : c.Default_Contact_Types__c.split(';'));
                if(c.Default_Responsible_Party__c || contactTypes.contains('Authorized User') || contactTypes.contains('Authorized Agent')){
                    defaultResponsibleParty = c;
                    contactNode.hiddenAttributes.put('styleClass', 'mainContact');
                }
                node.addChildNode(contactNode, 'Contacts');
            }
            setResponsiblePartyInfo(node, respParty, defaultResponsibleParty);
            
            return respParty;
        }
    }
    
    public static Customer_Contact__c getContactNodes(TreeNode node, List<Customer_Contact__c> ccs){
        Customer_Contact__c respParty = null;
        
        Contact defaultResponsibleParty = null;
        Map<Id, TreeNode> contactNodes = new Map<Id, TreeNode>();
        for(Customer_Contact__c cc : ccs != null ? ccs : new List<Customer_Contact__c>()){
            TreeNode contactNode = contactNodes.get(cc.Contact__c);
            
            if(contactNode == null){
                contactNode = new TreeNode(cc.Contact__r.Name, cc.Contact__r.Id);
                contactNodes.put(cc.Contact__r.Id, contactNode);
                node.addChildNode(contactNode, 'Contacts');
                if(cc.Contact__r.Default_Responsible_Party__c)
                    defaultResponsibleParty = cc.Contact__r;
            }
            Customer_Contact__c ccRespParty = getCustomerContactNodes(contactNode, new List<Customer_Contact__c>{cc});
            respParty = respParty == null ? ccRespParty : respParty;
        }
        setResponsiblePartyInfo(node, respParty, defaultResponsibleParty);
        
        return respParty;
    }
    
    public static Customer_Contact__c getCustomerContactNodes(TreeNode contactNode, List<Customer_Contact__c> customerContacts){
        Customer_Contact__c respParty = null;
        
        for(Customer_Contact__c cc : customerContacts != null ? customerContacts : new List<Customer_Contact__c>()){
            TreeNode ccNode = new TreeNode(cc.Contact_Type__c, contactNode.objectId);
            Boolean isRP = cc.Contact_Type__c == ICCWrapper.ResonsiblePartyContactType;
            respParty = isRP ? cc : respParty;
            ccNode.setAttribute('Phone', string.IsEmpty(cc.Phone__c) ? cc.Contact__r.Phone : cc.Phone__c);
            ccNode.setAttribute('Email', string.IsEmpty(cc.Email__c) ? cc.Contact__r.Email : cc.Email__c);
            ccNode.iconID = 'config';
            contactNode.addChildNode(ccNode, '');
            
            if(isRP || cc.Contact_Type__c == 'Authorized User' || cc.Contact_Type__c == 'Authorized Agent'){
                ccNode.hiddenAttributes.put('styleClass', 'mainContactType');
                contactNode.hiddenAttributes.put('styleClass', 'mainContact');
            }
        }
        
        return respParty;
    }
    
    public static Map<String, String> mapSObjectIcons(){
        if(iconMapping == null){
            iconMapping = new Map<String, String>();
            
            mapSObjectIcon(Account.sObjectType);
            mapSObjectIcon(Service_Location__c.sObjectType);
            mapSObjectIcon(Customer_Detail__c.sObjectType);
            
            mapSObjectIcon(Contact.sObjectType);
            mapSObjectIcon(Order__c.sObjectType);
            mapSObjectIcon(Order_Property__c.sObjectType);
            mapSObjectIcon(Service__c.sObjectType);
            mapSObjectIcon(Sub_Order__c.sObjectType);
            mapSObjectIcon(Sub_Order_Group__c.sObjectType);
            
            mapSubscriberIcon(ICCWrapper.StandAloneType);
            mapSubscriberIcon(ICCWrapper.BillableParentType);
            mapSubscriberIcon(ICCWrapper.NonBillableParentType);
            mapSubscriberIcon(ICCWrapper.BillableChildType);
            mapSubscriberIcon(ICCWrapper.NonBillableChildType);
            mapSubscriberIcon(ICCWrapper.NonBillableGrandparentType);
            mapSubscriberIcon('Inactive');
            mapSubscriberIcon('Suspended');
            
            iconMapping.put('config', CustomSettingUtils.getSingleProcessConfigurationValue('CustomerHierarchyIcon', 'Order__c', true));
        }
        
        return iconMapping;
    }
    
    private static String mapSObjectIcon(sObjectType objType){
        Schema.DescribeSObjectResult d = objType.getDescribe();
        string prefix = d.getKeyPrefix();
        string val = CustomSettingUtils.getSingleProcessConfigurationValue('CustomerHierarchyIcon', d.getName(), true);
        if(!string.IsEmpty(val))
            iconMapping.put(prefix, val);
        
        return prefix;
    }
    
    private static void mapSubscriberIcon(String s){
        String v = CustomSettingUtils.getSingleProcessConfigurationValue('CustomerHierarchyIcon', 'Subscriber: ' + s, false);
        if(!String.isEmpty(v)) iconMapping.put(s, v);
    }
    
    private static void setResponsiblePartyInfo(TreeNode node, Customer_Contact__c respParty, Contact defaultResponsibleParty){
        if(respParty != null && respParty.Contact__c != null){
            node.setAttribute('Responsible Party', respParty.Contact__r.Name);
            node.setAttribute('Responsible Party Phone', (!string.IsEmpty(respParty.Phone__c)
                                                        ? respParty.Phone__c
                                                        : respParty.Contact__r.Phone));
        }
        
        if(defaultResponsibleParty != null && defaultResponsibleParty.Id != (respParty != null ? respParty.Contact__c : null)){
            node.setAttribute('Default Responsible Party', defaultResponsibleParty.Name);
            node.setAttribute('Default Responsible Party Phone', defaultResponsibleParty.Phone);
        }
    }
}