public with sharing class AccountScheduledTaskUtils implements TestUtils.ITestableClass{ 
	
	
	public static Date getASTNextRunDateForQuarter(){
		return getASTNextRun(3.0d);
	}
	public static Date getASTNextRunDateForBiAnnual(){
		return getASTNextRun(6.0d);
	}
	private static Date getASTNextRun(double threeOrSix){
		Map<Integer, Integer> moToLastDay = new Map<Integer, Integer>{3=>31,6=>30,9=>30,12=>31};
		
		Integer curMonth = Date.today().Month();
		Integer runMonth = integer.valueOf((math.ceil((curMonth+1.0)/threeOrSix)*threeOrSix) - (math.floor(curMonth/12.0)*12));
		Integer runDay = moToLastDay.get(runMonth);
		Integer runYear = Date.today().Year();
		runYear = runMonth < curMonth? runYear + 1 : runYear;
		return Date.newInstance(runYear, runMonth, runDay);
	}
	public static Date getASTNextRunDateForYear(){
		Integer curMonth = Date.Today().Month();
		Integer runMonth = 12;
		Integer runDay = 31;
		Integer runYear = Date.Today().Year() + 1;		
		if(curMonth < 12) --runYear;
		return Date.newInstance(runYear, runMonth, runDay);
	}
	public static Account_Scheduled_Task__c createASTForAccount(id aId, string abs, decimal mrr){
		Account_Scheduled_Task__c ast = new Account_Scheduled_Task__c();
		ast.Account__c = aId;
		ast.Starting_on__c = Date.today();
		ast.Automation_Enabled__c = true;
		updateASTFromABSandMRR(ast, abs, mrr);
		return ast;
	}
	public static void updateASTFromABSandMRR(Account_Scheduled_Task__c ast, string abs, decimal mrr){
		Proactive_Case_Occurrence_Setting__c setToUse = getSettingForABSAndMRR(abs,mrr);
		system.debug('setting: ' + setToUse);
		system.debug('current activity: ' + ast.Previous_Proactive_Activity__c);
		if(setToUse == null) return;

		ast.Current_Activity_Required__c = ast.Previous_Proactive_Activity__c == setToUse.Starting_Activity__c && setToUse.Rotating_Proactive_Type__c ? (setToUse.Starting_Activity__c == 'Contact'? 'Account Review' : 'Contact') : setToUse.Starting_Activity__c;
		ast.Occurrence_Category__c = setToUse.Occurrence_Category__c;
		ast.Occurrence_Day_of_the_Week_Offset__c = setToUse.Occurrence_Day_Offset__c;					
		ast.Occurrence_Frequency__c = setToUse.Frequency__c;
		ast.Next_Run__c = (ast.Occurrence_Frequency__c == 1? getASTNextRunDateForYear() : (ast.Occurrence_Frequency__c == 3? getASTNextRunDateForQuarter() : getASTNextRunDateForBiAnnual()));
		ast.Skip_Workflow_Field_Updates__c = true;
	}
	private static List<Proactive_Case_Occurrence_Setting__c> sSettings;
	public static Proactive_Case_Occurrence_Setting__c getSettingForABSAndMRR(string abs, decimal mrr){
		Proactive_Case_Occurrence_Setting__c setting = null;
		if(sSettings == null) sSettings = [select Account_Business_Segment__c, Frequency__c, Minimum_MRR__c, Maximum_MRR__c, Occurrence_Category__c, Occurrence_Day_Offset__c, Rotating_Proactive_Type__c, Starting_Activity__c from Proactive_Case_Occurrence_Setting__c];
		for(Proactive_Case_Occurrence_Setting__c pcos : sSettings){
			if(pcos.Minimum_MRR__c <= mrr && (pcos.Maximum_MRR__c > mrr || pcos.Maximum_MRR__c == null) && (pcos.Account_Business_Segment__c == abs || pcos.Account_Business_Segment__c == 'Default')) {
				setting = pcos;
				if(pcos.Account_Business_Segment__c == abs) break;
			}
		}
		return setting;
	}

	public TestUtils.TestClass getTestClass(){ return new Test_AccountScheduledTaskUtils(); }
}