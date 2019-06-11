public class TreeNode {
	private static Integer treeNodeID = 0;
	public static Integer MaxTreeNodeID{
		get{ return treeNodeID; }
	}
	
	public String nodeId {get; set;}
	public Id objectId {get; set;}
	public String label {get; set;}
	public Map<String, String> attributes {get; private set;}
	public List<String> attributeOrder {get; private set;}
	public Map<String, String> hiddenAttributes {get; set;}
	public Map<String, List<List<TreeNode>>> childNodeGroups {get; private set;}
	public List<String> childNodeGroupOrder {get; private set;}
	public List<String> errors {get; private set;}
	public String iconID {get; set;}
	public String actionIDs {get;set;}
	
	public TreeNode(){
		initializeCollections();
		nodeId = string.valueOf(treeNodeID++);
	}
	
	public TreeNode(String labelText, Id id){
		label = labelText;
		objectId = id;
		initializeCollections();
		nodeId = string.valueOf(treeNodeID++);
	}
	
	private void initializeCollections(){
		attributes = new Map<String, String>();
		attributeOrder = new List<String>();
		hiddenAttributes = new Map<String, String>();
		childNodeGroups = new Map<String, List<List<TreeNode>>>();
		childNodeGroupOrder = new List<String>();
		errors = new List<String>();
	}
	
	public void addChildNode(TreeNode node, String groupName){
		List<List<TreeNode>> children = ChildNodeGroups.get(groupName);
		if(children == null){
			children = new List<List<TreeNode>>();
			ChildNodeGroupOrder.add(groupName);
		}
		if(children.size() == 0 || children[children.size()-1].size() == 1000)
			children.add(new List<TreeNode>());
		
		children[children.size()-1].add(node);
		
		ChildNodeGroups.put(groupName, children);
	}
	
	public void setAttribute(String name, String val){
		if(val == null)
			return;
		
		if(attributes.get(name) != null){
			for(Integer i=attributeOrder.size()-1; i>=0; i--){
				if(attributeOrder[i] == name)
					attributeOrder.remove(i);
			}
		}
		
		attributeOrder.add(name);
		attributes.put(name, val);
	}
	
	public static Map<String, List<TreeNode>> getNodeMap(List<TreeNode> nodes){
		Map<String, List<TreeNode>> m = new Map<String, List<TreeNode>>();
		getNodeMap(nodes, m, '');
		return m;
	}
	
	public static void getNodeMap(List<TreeNode> nodes, Map<String, List<TreeNode>> m, String path){
		for(TreeNode n : nodes)
			n.getNodeMap(m, path);
	}
	
	private void getNodeMap(Map<String, List<TreeNode>> m, String path){
		List<TreeNode> l = m.get(path) != null ? m.get(path) : new List<TreeNode>();
		l.add(this);
		m.put(path, l);
		
		for(String g : childNodeGroupOrder){
			String childPath = path + (!string.isEmpty(path) ? ':' : '') + (objectId != null ? String.valueOf(objectId) : ('"' + label + '"')) + (!String.isEmpty(g) ? (':{' + g + '}') : '');
			for(List<TreeNode> sl : childNodeGroups.get(g))
				getNodeMap(sl, m, childPath);
		}
	}
}