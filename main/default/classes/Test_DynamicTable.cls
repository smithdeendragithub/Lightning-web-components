@isTest
public with sharing class Test_DynamicTable extends TestUtils.TestClass {
	
	private class TestController extends DynamicTable.DynamicTableController{ }
	
	static testMethod void testTable(){
		Mocks testData = new Mocks();
		
		Account a = testData.parentAccount;
		Contact c = testData.parentAccountContact;
		
		test.startTest();
		
		PageReference pageReference = ApexPages.currentPage();
		
		DynamicTable dt = new DynamicTable(new ApexUtils.SortableClassConfig());	//With sortable config
		dt = new DynamicTable();	//Without sortable config
		
		dt.configSection.unsupportedFilterFields = new Set<String>{'Account.Name'};
		dt.customPicklistValues = new Map<String, List<String>>{ 'Account.Name'=>new List<String>{'Account A', 'Account B'} };
		dt.customStyleClass = new Map<String, String>{'Account.Name'=>'{!IF({0}.CreatedDate > TODAY, "oldbusted", "")}'};
		dt.checkBoxProperty = 'selected';
		
		dt.EnablePaging();
		dt.BuildConfig('dt', 'selfRef', '{!collection}', '', Contact.sObjectType);
		dt.BuildConfig('dt', 'selfRef', '{!collection}', '', Contact.sObjectType, new Set<String>{'Account'});
		dt.BuildConfig('dt', 'selfRef', '{!collection}', '', Contact.sObjectType, new Set<String>{'Account'}, new Map<String, String>{'owner.name'=>'Contact Owner'});
		dt.configSection.UpdateOptions(new List<String>{'Name','CreatedDate','OwnerId','Default_Contact_Types__c','Default_Responsible_Party__c'});
		dt.customButtonColumns = new Map<String, List<DynamicTable.CustomLink>>{
										'Actions'=>new List<DynamicTable.CustomLink>{new DynamicTable.CustomLink('Link', '/apex/SomeCustomPage?id={!{0}.Id}', '{!NOT(ISNULL({0}))}')}
										};
		dt.customColumns = new List<DynamicTable.CustomColumn>{new DynamicTable.CustomColumn('Errors', '{!{0}.error}', '{!0 == 0}', 'errored')};
		
		TestController tc = new TestController();
		tc.tables = new Map<String, DynamicTable>{'dt'=>dt};
		
		pageReference.getParameters().put('mode', 'dt');
		pageReference.getParameters().put('add', 'true');
		dt.configSection.selectedVals = new List<String>{'lastname'};
		tc.UpdateColumnSelection();
		
		tc.arg_Mode = 'dt';
		tc.filterArg_FieldPath = 'lastname';
		tc.filterArg_Add = true;
		tc.AddRemoveFilter();
		tc.AddRemoveFilter();
		
		DynamicTable.FieldConfiguration fc = dt.configSection.fieldConfigs.get('lastname');
		System.assertEquals(2, fc.filters.size(), 'Field filters could not be added to Contact.LastName');
		fc.filters[0].val = c.LastName;
		fc.filters[0].option = '{comp}=\'{path}\'';
		fc.filters[1].val = 'blahblahblah';
		fc.filters[1].option = '{comp}!=\'{path}\'';
		
		tc.filterArg_FieldPath = 'createddate';
		tc.AddRemoveFilter();
		
		fc = dt.configSection.fieldConfigs.get('createddate');
		System.assertEquals(1, fc.filters.size(), 'Field filter could not be added to Contact.CreatedDate');
		fc.filters[0].val = Date.today().format();
		fc.filters[0].option = '>';
		
		tc.filterArg_FieldPath = 'default_contact_types__c';
		tc.AddRemoveFilter();
		
		fc = dt.configSection.fieldConfigs.get('default_contact_types__c');
		System.assertEquals(1, fc.filters.size(), 'Field filter could not be added to Contact.Default_Contact_Types__c');
		fc.filters[0].option = 'Some Guy';
		
		tc.filterArg_FieldPath = 'default_responsible_party__c';
		tc.AddRemoveFilter();
		
		fc = dt.configSection.fieldConfigs.get('default_responsible_party__c');
		System.assertEquals(1, fc.filters.size(), 'Field filter could not be added to Contact.	Default_Responsible_Party__c');
		fc.filters[0].option = 'true';
		
		List<String> whereClauses = new List<String>();
		dt.BuildWhereClauses(whereClauses);
		
		System.assertEquals(4, whereClauses.size());
		
		tc.filterArg_Num = String.valueOf(fc.filters[0].num);
		tc.filterArg_Add = false;
		tc.AddRemoveFilter();
		
		whereClauses = new List<String>();
		dt.BuildWhereClauses(whereClauses);
		
		System.assertEquals(3, whereClauses.size());
		
		dt.configSection.showRowPositionControls = dt.configSection.showSOQLSortControls = true;
		system.assertNotEquals(null, dt.configSection.GetSelectedTable);
		
		dt.configSection.showRowPositionControls = dt.configSection.showSOQLSortControls = false;
		system.assertNotEquals(null, dt.configSection.GetSelectedTable);
		
		system.assertNotEquals(null, dt.GetDynamicTable);
		
		dt.configSection.VerifySelectionOrder();
		System.assertNotEquals(null, DynamicTable.logicDelimiterOptions);
		System.assertNotEquals(null, dt.configSection.SortingSelectOptions);
		System.assertNotEquals(null, dt.GetFieldConfigOptions);
		System.assertEquals(null, dt.GetSortFieldValue(true));
		System.assertEquals(null, dt.GetSortFieldValue(false));
		System.assertNotEquals(null, tc.sharedDynamicComponents);
		
		tc.pageArg_Next = true;
		tc.UpdatePage();
		tc.DynamicTableRefreshed('dt');
		
		tc.UpdateSorting();
	}
	
	static testMethod void testPresetData(){
		Custom_List_View__c clv = new Custom_List_View__c(Label__c='Test CLV', Category__c='testCategory', Object__c='Account');
		insert clv;
		
		Custom_List_View_Field__c clvfld = new Custom_List_View_Field__c(Custom_List_View__c=clv.Id, Field_Path__c='Name');
		insert clvfld;
		
		Custom_List_View_Filter__c clvflt = new Custom_List_View_Filter__c(Custom_List_View_Field__c=clvfld.Id, Filter_Number__c=1, Filter_Option__c='=', Filter_Value__c='some name');
		insert clvflt;
		
		DynamicTable dt = new DynamicTable();
		dt.BuildConfig('dt', 'selfRef', '{!collection}', 'namespace', Account.sObjectType);
		dt.GetPreselectData('WorkstepManagement', 'WorkstepManagement_wsTable', true);
		dt.RefreshConfigFromFieldConfig(clv.Id);
		
		dt.currentFieldConfig = 'CUSTOM';
		//dt.SaveFieldConfigurationToCookie();
	}
	
	static testMethod void testPaging(){
		DynamicTable.Paging p = new DynamicTable.Paging();
		Integer rpp = p.RecordsPerPage;
		
		List<User> uList = (List<User>)Database.query('select Id from User limit ' + string.valueOf(rpp + 1));
		p.Reset(uList.size(), true);
		System.assertEquals(p.RecordsTotal, rpp + 1, 'Not enough users could be loaded to test multiple pages');
		
		//Test defaults
		System.assertEquals(0, p.CurrPage);
		System.assertEquals(p.MaxPage, 1);
		
		//Test first page size
		System.assertEquals(rpp, p.GetPagedsObjectList(uList).size());
		System.assertEquals(1, p.RecordsFrom);
		System.assertEquals(rpp, p.RecordsTo);
		
		//Test page change (next)
		p.UpdateCurrentPage(true);
		System.assertEquals(1, p.CurrPage);
		
		//Test second page size
		System.assertEquals(1, p.GetPagedsObjectList(uList).size());
		System.assertEquals(rpp+1, p.RecordsFrom);
		System.assertEquals(rpp+1, p.RecordsTo);
		
		//Test reset without paging reset
		p.Reset(uList.size(), false);
		System.assertEquals(rpp+1, p.RecordsFrom);
		System.assertEquals(rpp+1, p.RecordsTo);
		
		//Test page change (previous)
		p.UpdateCurrentPage(false);
		System.assertEquals(0, p.CurrPage);
		System.assertEquals(1, p.RecordsFrom);
		System.assertEquals(rpp, p.RecordsTo);
		
		//Test reset to lower value without paging reset (should snap back)
		p.UpdateCurrentPage(true);
		System.assertEquals(1, p.CurrPage);
		p.Reset(uList.size()-1, false);
		System.assertEquals(0, p.CurrPage);
	}
}