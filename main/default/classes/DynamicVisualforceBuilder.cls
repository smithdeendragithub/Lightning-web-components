public without sharing class DynamicVisualforceBuilder {
	
	public Component.Apex.ActionFunction buildActionFunction(String name, Map<String, String> params){
		Component.Apex.ActionFunction c = new Component.Apex.ActionFunction(name=name);
		if(params != null){
			if(params.get('action') != null) c.expressions.action = params.get('action');
			if(params.get('oncomplete') != null) c.oncomplete = params.get('oncomplete');
			if(params.get('rerender') != null) c.rerender = new Set<String>(params.get('rerender').split(','));
			if(params.get('status') != null) c.status = params.get('status');
		}
		return c;
	}
	
	public Component.Apex.OutputLink buildOutputLink(String text, Map<String, String> params){
		Component.Apex.OutputLink c = new Component.Apex.OutputLink();
		setStandardValues(c, new List<ApexPages.Component>{buildOutputText('{!"' + text + '"}', null)}, params);
		if(params != null){
			if(params.get('style') != null) c.style = params.get('style');
			if(params.get('styleClass') != null) c.expressions.styleClass = params.get('styleClass');
			if(params.get('rendered') != null) c.expressions.rendered = params.get('rendered');
		}
		
		return c;
	}
	
	public Component.Apex.CommandButton buildCommandButton(String text, Map<String, String> params){
		Component.Apex.CommandButton c = new Component.Apex.CommandButton(value=text);
		setStandardValues(c, null, params);
		if(params != null){		
			if(params.get('rendered') != null) c.expressions.rendered = params.get('rendered');
		}
		
		return c;
	}
	
	public Component.Apex.OutputPanel buildOutputPanel(List<ApexPages.Component> childComponents, Map<String, String> params){
		Component.Apex.OutputPanel c = new Component.Apex.OutputPanel();
		setStandardValues(c, childComponents, params);
		if(params != null){
			if(params.get('style') != null) c.style = params.get('style');
			if(params.get('styleClass') != null) c.expressions.styleClass = params.get('styleClass');
			if(params.get('rendered') != null) c.expressions.rendered = params.get('rendered');
		}
		
		return c;
	}
	
	public Component.Apex.Column buildColumn(List<ApexPages.Component> childComponents, Map<String, String> params){
		return buildColumn(childComponents, params, null);
	}
	
	public Component.Apex.Column buildColumn(List<ApexPages.Component> childComponents, Map<String, String> params, ApexPages.Component header){
		Component.Apex.Column c = new Component.Apex.Column();
		
		setStandardValues(c, childComponents, params);
		if(params != null){
			if(params.get('header') != null) c.headerValue = params.get('header');
			if(params.get('rendered') != null) c.expressions.rendered = params.get('rendered');
			if(params.get('style') != null) c.style = params.get('style');
		}
		if(header != null) c.facets.header = header;
		
		return c;
	}
	
	public Component.Apex.InputCheckbox buildInputCheckbox(String valExpr, Map<String, String> params){
		Component.Apex.InputCheckbox c = new Component.Apex.InputCheckbox();
		c.expressions.value = valExpr;
		setStandardValues(c, null, params);
		return c;
	}
	
	public Component.Apex.Image buildImage(String value, Map<String, String> params){
		Component.Apex.Image c = new Component.Apex.Image(value=value);
		setStandardValues(c, null, params);
		if(params != null){
			if(params.get('rendered') != null) c.expressions.rendered = params.get('rendered');
			if(params.get('style') != null) c.style = params.get('style');
		}
		return c;
	}
	
	public Component.Apex.InputText buildInputText(String valExpr, Map<String, String> params){
		Component.Apex.InputText c = new Component.Apex.InputText();
		c.expressions.value = valExpr;
		setStandardValues(c, null, params);
		if(params != null){
			if(params.get('rendered') != null) c.expressions.rendered = params.get('rendered');
			if(params.get('style') != null) c.style = params.get('style');
			if(params.get('onchange') != null) c.childComponents.add(new Component.Apex.ActionSupport(event='onchange', onsubmit=params.get('onchange') + ' return false;'));
		}
		return c;
	}
	
	public Component.Apex.OutputText buildOutputText(String valExpr, Map<String, String> params){
		Component.Apex.OutputText c = new Component.Apex.OutputText();
		c.expressions.value = valExpr;
		setStandardValues(c, null, params);
		if(params != null){
			if(params.get('escape') != null) c.escape = params.get('escape') == 'true';
			if(params.get('rendered') != null) c.expressions.rendered = params.get('rendered');
			if(params.get('style') != null) c.style = params.get('style');
			if(params.get('styleClass') != null) c.expressions.styleClass = params.get('styleClass');
		}
		return c;
	}
		public Component.Apex.SelectList buildSelectList(Boolean multiSelect, Integer size, String selectedValue, List<ApexPages.Component> childComponents, Map<String, String> params){
		Component.Apex.SelectList c = new Component.Apex.SelectList(multiselect=multiSelect, size=size, value=selectedValue);
		setStandardValues(c, childComponents, params);
		if(params != null){
			if(params.get('value') != null) c.expressions.value = params.get('value');			
			if(params.get('rendered') != null) c.expressions.rendered = params.get('rendered');
			if(params.get('style') != null) c.style = params.get('style');
			if(params.get('onchange') != null) c.childComponents.add(new Component.Apex.ActionSupport(event='onchange', rerender='pbs_worksteps', onsubmit=params.get('onchange') + ' return true;'));
					
		}		
		return c;
	}
	
	public Component.Apex.SelectList buildSelectList(Boolean multiSelect, Integer size, List<ApexPages.Component> childComponents, Map<String, String> params){
		Component.Apex.SelectList c = new Component.Apex.SelectList(multiselect=multiSelect, size=size);
		setStandardValues(c, childComponents, params);

		if(params != null){
			if(params.get('value') != null) c.expressions.value = params.get('value');			
			if(params.get('rendered') != null) c.expressions.rendered = params.get('rendered');
			if(params.get('style') != null) c.style = params.get('style');
			if(params.get('onchange') != null) c.childComponents.add(new Component.Apex.ActionSupport(event='onchange', onsubmit=params.get('onchange') + ' return false;'));		
		}
		return c;
	}
	
	public Component.Apex.SelectOption buildSelectListOption(String label, String value, Map<String, String> params){
		Component.Apex.SelectOption so = new Component.Apex.SelectOption();
		so.itemLabel = label;
		so.itemValue = value;
		if(params != null){
			if(params.get('disabled') != null) so.itemDisabled = (params.get('disabled') == 'true');
			if(params.get('styleclass') != null) so.styleClass = params.get('styleclass');
		}
		return so;
	}
	
	public Component.Apex.SelectOptions buildSelectListOptions(String valExpr, Map<String, String> params){
		Component.Apex.SelectOptions sos = new Component.Apex.SelectOptions();
		sos.expressions.value = valExpr;
		return sos;
	}
	
	public void setStandardValues(ApexPages.Component c, List<ApexPages.Component> childComponents, Map<String, String> params){
		if(childComponents != null) c.childComponents.addAll(childComponents);
		if(params != null){
			if(params.get('id') != null) c.id = params.get('id');
			if(params.get('onclick') != null) c.childComponents.add(new Component.Apex.ActionSupport(event='onclick', onsubmit=params.get('onclick') + ' return false;'));
			if(params.get('onfocus') != null) c.childComponents.add(new Component.Apex.ActionSupport(event='onfocus', onsubmit=params.get('onfocus') + ' return false;'));
		}
	}
}