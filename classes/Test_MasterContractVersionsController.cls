@isTest
private class Test_MasterContractVersionsController extends TestUtils.TestClass {
	static testMethod void testController() {
		Mocks testData = new Mocks();
     	MasterContractVersionsController mcvc  = new MasterContractVersionsController();
		mcvc.getselectedContract();
		mcvc.setisGeneratedContent(true);
		mcvc.getisGeneratedContent();
		List<SelectOption> sos = new List<SelectOption>();
		sos.add(new SelectOption('Test1','Test1'));
		sos.add(new SelectOption('Test2','Test2'));
		sos.add(new SelectOption('Test3','Test3'));
		mcvc.selectOptionSorter(sos);
	}
	
	static testMethod void testSave() {
		MasterContractVersionsController mcvc  = new MasterContractVersionsController();
		List<ContentVersion> cvs = new List<ContentVersion>();
		cvs.add(new ContentVersion());
		mcvc.listCV = cvs;
		mcvc.selectedContract = '-NewContract-';
		mcvc.save();
	}
	
	static testMethod void testSaveAndNew() {
		MasterContractVersionsController mcvc  = new MasterContractVersionsController();
		mcvc.saveAndNew();
	}
	
	static testMethod void testCancel() {
		MasterContractVersionsController mcvc  = new MasterContractVersionsController();
		mcvc.cancel();
	}
}