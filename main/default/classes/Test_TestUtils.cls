@isTest
public with sharing class Test_TestUtils{

	static testMethod void instantiateTestClasses(){
		for(List<ApexClass> apexClassList : [select Id, Body, Name from ApexClass]){
			for(ApexClass apexClass : apexClassList){
				if(apexClass.Body.contains('TestUtils.ITestableClass')){
					try{
						Type t = Type.forName(apexClass.Name);
						TestUtils.ITestableClass i = (TestUtils.ITestableClass)t.newInstance();
						i.getTestClass();
					}
					catch(Exception e){}
				}
			}
		}
	}
}