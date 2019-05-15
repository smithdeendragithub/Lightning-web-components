public virtual class TreeViewController {
	
	public Map<String, TreeViewImplementation> TreeViewsByDivID {get; set;}

	public virtual class TreeViewImplementation{
		public String divID {get; set;}
		public Boolean loadMoreEnabled {get; set;}
		
		public virtual List<TreeNode> getNodes(){ return new List<TreeNode>(); }
	    public virtual List<TreeNode> getMoreNodes(String path){ return new List<TreeNode>(); }
	    public virtual Map<String, String> getActionMap(){ return new Map<String, String>(); }
	    public virtual Map<String, String> getIconMap(){ return new Map<String, String>(); }
        public virtual Boolean getCanLoadTree(){ return true; }
	}
	
	public TreeViewController(){
		TreeViewsByDivID = new Map<String, TreeViewImplementation>();
	}
    
    public Boolean canLoadTree{
        get{
            try{
                Boolean canLoadTreeFlag = false;
            	for(String k : TreeViewsByDivID.keyset()){
                TreeViewImplementation i = TreeViewsByDivID.get(k);
				canLoadTreeFlag = i.getCanLoadTree();	
                if (!canLoadTreeFlag)
                    break;
				}
                return canLoadTreeFlag;
            }
            catch (Exception e){
                system.debug('error: ' + e.getMessage());
            	return false;    
            }
            
            
        }
    }
	
	public String ActionMappings{
		get{
			List<String> defs = new List<String>();
			for(String divID : TreeViewsByDivID.keyset()){
				Map<String, String> m = TreeViewsByDivID.get(divID).getActionMap();
				List<String> aDefs = new List<String>();
				for(String k : m.keyset()){
					if(m.get(k) != null)
						aDefs.add('key: "' + k + '",value: "' + m.get(k) + '"');
				}
				
				if(aDefs.size() > 0)
					defs.add(divID + ':[{' + string.join(aDefs, '},{') + '}]');
			}
			return '{' + string.join(defs, ',') + '}';
		}
	}
	
	public String IconMappings{
		get{
			List<String> defs = new List<String>();
			for(String divID : TreeViewsByDivID.keyset()){
				Map<String, String> m = TreeViewsByDivID.get(divID).getIconMap();
				List<String> aDefs = new List<String>();
				for(String k : m.keyset()){
					if(m.get(k) != null)
						aDefs.add('key: "' + k + '",value: "' + m.get(k) + '"');
				}
				
				if(aDefs.size() > 0)
					defs.add(divID + ':[{' + string.join(aDefs, '},{') + '}]');
			}
			return '{' + string.join(defs, ',') + '}';
		}
	}
	
	private Map<String, Integer> treeNodeCountMap {get; set;}
	public Map<String, Integer> TreesNodeCounts{
		get{
			String str = AllJSONTrees;	//Build it/get cache
			system.debug('treeNodeCountMap:' + treeNodeCountMap);
			return treeNodeCountMap;
		}
	}
	
	private String allJSONTreeString {get; set;}		//Set the first time this runs
	public String AllJSONTrees{
		get{
            if(string.IsEmpty(allJSONTreeString)){
                List<String> l = new List<String>();
				for(String k : TreeViewsByDivID.keyset()){
		    		Integer beginNodeCount = TreeNode.MaxTreeNodeID;
		    		TreeViewImplementation i = TreeViewsByDivID.get(k);
		    		List<TreeNode> nodes = i.getNodes();
		    		if(treeNodeCountMap == null)
		    			treeNodeCountMap = new Map<String, Integer>();
		    		treeNodeCountMap.put(k, nodes != null ? nodes.size() : 0);
		    		resetCounts();
		    		Integer asynchMode = GetNodeThreshold(TreeNode.MaxTreeNodeID - beginNodeCount);
					l.add('"' + k + '":{asynchMode:' + string.valueOf(asynchMode) + ',nodes:' + (!i.loadMoreEnabled || asynchMode == 0 ? getJSONNodes(nodes, null, i.loadMoreEnabled) : '[]') + '}');
				}
				allJSONTreeString = '{' + string.join(l, ',') + '}';
			}
			return allJSONTreeString;
		}
	}
	
	transient public String loadMore_divID{get; set;}
	transient public String loadMore_path{get; set;}
	transient public String loadMore_parentNodeId{get; set;}
	transient public String loadMore_currentlyLoaded{get; set;}
	
	transient public String loadedNodes {get; private set;}
	
	public PageReference loadNodes(){
		resetCounts();
		if(!string.isEmpty(loadMore_path))
			loadedNodes = loadMoreNodes();
		else
			loadedNodes = getJSONNodesByImplementation(TreeViewsByDivID.get(loadMore_divID));
		return null;
	}
	
	private String loadMoreNodes(){
		List<TreeNode> l = TreeViewsByDivID.get(loadMore_divID).getMoreNodes(loadMore_path);
		
		if(loadMore_currentlyLoaded != null && l != null){
			Set<String> currentlyLoaded = new Set<String>();
			for(String str : loadMore_currentlyLoaded.split(','))
				currentlyLoaded.add(str.replace('#COMMA#', ','));
			
			for(Integer i=l.size()-1; i>=0; i--){
				if(l[i].objectId != null && currentlyLoaded.contains(l[i].objectId)
					|| l[i].label != null && currentlyLoaded.contains(l[i].label)){
					l.remove(i);
				}
				else
					l[i].nodeId = loadMore_parentNodeId + '_' + l[i].nodeId;
			}
		}
		
		return getJSONNodes(l, null, true);
	}
	
	public String getJSONNodesByImplementation(TreeViewImplementation imp){
		return getJSONNodes(imp.getNodes(), null, imp.loadMoreEnabled);
	}
	
	transient private Integer currentCount;
	transient private Boolean jsonLimitHit;
	transient private Integer lvl2Threshold;
	
	private void resetCounts(){
		if(lvl2Threshold == null)
			lvl2Threshold = getNodeThreshold(false);
		currentCount = 0;
		jsonLimitHit = false;
	}
	
	private String getJSONNodes(List<TreeNode> nodes, String parentNodeId, Boolean enforceNodeLimit){
		Map<String, Map<String, List<TreeNode>>> subNodes = new Map<String, Map<String, List<TreeNode>>>();
		
		List<String> nodeList = new List<String>();
		List<String> jsonList = new List<String>();
        
		for(TreeNode node : nodes != null ? nodes : new List<TreeNode>()){
			Boolean doBreak = false;
			String json = 'key:"' + node.nodeId + '"';
			
			if(enforceNodeLimit && ++currentCount > lvl2Threshold){
				jsonLimitHit = true;
				json += ',isLoadMore:true';
				doBreak = true;
			}
			else{
				json += ',title:"' + escape(node.label) + '"';
				
				if(node.objectId != null)
					json += ',sfid:"' + node.objectId + '"';
				
				if(!string.isEmpty(node.actionIDs))
					json += ',act:"' + node.actionIDs + '"';
				
				if(!string.isEmpty(node.iconID))
					json += ',ico:"' + node.iconID + '"';
				
				if(node.attributes.size() > 0){
					String tooltip = '';
					for(String attrName : node.attributeOrder){
						if(tooltip.length() > 0)
							tooltip += '#NEWLINE#';
	
						tooltip += escape(attrName) + '#TAB#' + escape(node.attributes.get(attrName));
					}
					json += ',tt:"' + tooltip + '"';
				}
				
				if(node.hiddenAttributes.size() > 0){
					List<String> h = new List<String>();
					for(String k : node.hiddenAttributes.keyset())
						h.add('"' + escape(k) + '":"' + escape(node.hiddenAttributes.get(k)) + '"');
					json += ',hidden:{' + string.join(h, ',') + '}';
				}
				
				if(node.errors.size() > 0)
					json += ',errors:"' + string.join(node.errors, '#NEWLINE#') + '"';
				
				Map<String, List<TreeNode>> sn = new Map<String, List<TreeNode>>();
				for(String grp : node.ChildNodeGroupOrder){
					List<TreeNode> snl = new List<TreeNode>();
					for(List<TreeNode> l : node.ChildNodeGroups.get(grp))
						snl.addAll(l);
					sn.put(grp, snl);
				}
				subNodes.put(node.nodeId, sn);
			}
			nodeList.add(node.nodeId);
			jsonList.add(json);
			
			if(doBreak)
				break;
		}
		
		for(Integer i=0; i<nodeList.size(); i++){
			String nodeId = nodeList[i];
			String json = jsonList[i];
			if(nodes[i].ChildNodeGroupOrder.size() > 0){
				Map<String, List<TreeNode>> sn = subNodes.get(nodeId);
				List<String> childJSON = new List<String>();
				for(String grp : nodes[i].ChildNodeGroupOrder){
					String j = (jsonLimitHit == true) ? '{isLoadMore:true}' : getJSONNodes(sn.get(grp), nodeId, enforceNodeLimit);
					                    
					if(!string.IsEmpty(grp))
						childJSON.add('{title:"' + grp + '",isFolder:true,isGroup:true,children:[' + j + ']}');
					else
						childJSON.add(j);
				}
				
				json += ',children:[' + string.join(childJSON, ', ') + ']';
			}
			jsonList[i] = '{' + json + '}';
		}
		
		return !string.isEmpty(parentNodeId) ? string.join(jsonList, ',') : ('[' + string.join(jsonList, ',') + ']');
	}
	
	private String escape(String str){
		return str != null ? str.escapeHtml4() : null;
	}
	
	private Integer getNodeThreshold(Integer nodeCount){
		Integer level1 = getNodeThreshold(true);
		Integer level2 = getNodeThreshold(false);
		return nodeCount > level1 ? (nodeCount > level2 ? 2 : 1) : 0;
	}
	
	private Integer getNodeThreshold(Boolean level1){
		String nodeThreshold = CustomSettingUtils.getSingleProcessConfigurationValue('HierarchyNodeThreshold', level1 ? 'Level1' : 'Level2', false);
		Integer retval = level1 ? 500 : 1000;
		
		if(!string.isEmpty(nodeThreshold)){
			try{
				retval = Integer.valueOf(nodeThreshold);
			}
			catch(Exception e){}
		}
		
		return retval;
	}
	
    public static void addActionsToNode(TreeNode node, List<String> actionCodes){
    	node.actionIDs = (string.IsEmpty(node.actionIDs) ? '' : (node.actionIDs + '|')) + string.join(actionCodes, '|');
    }
}