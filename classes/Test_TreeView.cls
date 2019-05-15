@isTest
public with sharing class Test_TreeView extends TestUtils.TestClass {
	
	private class RawTreeView extends TreeViewController.TreeViewImplementation{
		public RawTreeView(){
			divID = 'raw';
			loadMoreEnabled = true;
		}
		
		public override List<TreeNode> getNodes(){
			TreeNode t = new TreeNode('a node', null);
			t.setAttribute('att', 'val');
			t.hiddenAttributes.put('hidden', 'hiddenval');
			
			TreeNode c = new TreeNode();
			t.addChildNode(c, '');
			return new List<TreeNode>{t};
		}
	}
	
	static testMethod void testController(){
        TreeViewController tvc = new TreeViewController();
		tvc.TreeViewsByDivID = new Map<String, TreeViewController.TreeViewImplementation>{'raw'=>new RawTreeView()};
		tvc.loadMore_divID = 'raw';
		System.debug(tvc.loadNodes());
		tvc.loadMore_path = 'nowhere';
		tvc.loadMore_currentlyLoaded = '1,2';
		System.debug(tvc.loadNodes());
		System.debug(tvc.ActionMappings);
		System.debug(tvc.IconMappings);
		System.debug(tvc.AllJSONTrees);
		System.debug(tvc.TreesNodeCounts);
		
		TreeNode t = new TreeNode(null, null);
		TreeViewController.addActionsToNode(t, new List<String>{'action'});
	}
	
	static testMethod void testCustomerHierarchy(){
		Mocks testData = new Mocks();
		Account a = testData.parentAccount;
		
		Contact c = testData.parentAccountContact;
		c.Default_Responsible_Party__c = true;
		update c;
		
		Service_Location__c sLoc = testData.serviceLocation;
		
		sObjectType sLocType = Service_Location__c.getsObjectType();
		sLoc = ((List<Service_Location__c>)ApexUtils.retrieveFullObjects(sLocType, 'Id = \'' + sLoc.Id + '\''))[0];
		
		List<Service_Location__c> sLocs = new List<Service_Location__c>();
		for(Integer i=0; i<500; i++){
			Service_Location__c child = (Service_Location__c)ApexUtils.deepCopyFields(sLocType, sLoc, new Service_Location__c(), null);
			child.Parent_Service_Location__c = sLoc.Id;
			sLocs.add(child);
		}
		upsert sLocs;
		
		CustomerDetailUtils.updateCustomerDetails(new List<Set<Id>>{new Set<Id>{a.Id, sLoc.Id}, new Set<Id>{sLocs[0].Id}, new Set<Id>{sLocs[1].Id}}, new Map<Id, List<Customer_Contact__c>>{sLocs[1].Id=>new List<Customer_Contact__c>{new Customer_Contact__c(Contact__c=c.Id, Contact_Type__c=ICCWrapper.ResonsiblePartyContactType), new Customer_Contact__c(Contact__c=c.Id, Contact_Type__c='Authorized User')}});
		Customer_Detail__c cd = [select Id, Customer_Detail__r.Id from Service_Location__c where Id=: sLoc.Id limit 1].Customer_Detail__r;
		cd.ICC_Subscriber_ID__c = '-999';
		update cd;
		
		Test.startTest();
		
        TreeViewController tvc = new TreeViewController();
		tvc.TreeViewsByDivID = new Map<String, TreeViewController.TreeViewImplementation>{'hierarchy'=>new CustomerHierarchyController.TreeViewImplementation(a.Id)};
		tvc.loadMore_divID = 'hierarchy';
		System.debug(tvc.loadNodes());
		tvc.loadMore_path = a.Id + ':{Contacts}';
		tvc.loadMore_currentlyLoaded = '1,2';
		System.debug(tvc.loadNodes());
		System.debug(tvc.ActionMappings);
		System.debug(tvc.IconMappings);
		System.debug(tvc.AllJSONTrees);
		System.debug(tvc.TreesNodeCounts);
		
		CustomerHierarchyController chc = new CustomerHierarchyController();
	}
}