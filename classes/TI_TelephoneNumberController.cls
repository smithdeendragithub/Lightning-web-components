public with sharing class TI_TelephoneNumberController implements TestUtils.ITestableClass {
	private final Technical_Information__c currentTI;
	public List<wrapTelephoneNumber> TelephoneNumbers {get;set;}
	
	public void messageDisplay(String Msg){
		ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, Msg);
        ApexPages.addMessage(m);
	}
	
	public TI_TelephoneNumberController(ApexPages.StandardController stdController) {
		try{
			this.currentTI = (Technical_Information__c)stdController.getRecord();
			TelephoneNumbers = new List<wrapTelephoneNumber>();
			Integer i = 0;
			
			List<Telephone_Number__c> lstTN = (List<Telephone_Number__c>) ApexUtils.retrieveFullObjects(Telephone_Number__c.sObjectType, 'Technical_Information__c=\'' + currentTI.Id + '\'');
			
			
			for(Telephone_Number__c t : lstTN){
				wrapTelephoneNumber wt = new wrapTelephoneNumber(t);
				wt.Index = i++;
				TelephoneNumbers.Add(wt);
			}
			
			AddMoreRows(10);
		
		} catch (Exception e){
			System.debug(e);
		}
	}
	
	//Wrapper class for the Cost Comparison and Sub-Total Field
	//to used in the data table on Vf page.
	public class wrapTelephoneNumber{
		public Telephone_Number__c telephone {get;set;}
		public Boolean selected {get;set;}
		public Integer Index {get;set;}
		
		public wrapTelephoneNumber(Telephone_Number__c t){
			telephone = t;
			
			selected = false;
		}
	}
	
	public void AddTenRows(){
		AddMoreRows(10);
	}
	
    private void AddMoreRows(Integer numberOfRows){
    	Integer size = TelephoneNumbers.size();
    	
		for(Integer i=0; i<numberOfRows; i++){
			Telephone_Number__c t = new Telephone_Number__c();
			t.Technical_Information__c = currentTI.Id;
			wrapTelephoneNumber wt = new wrapTelephoneNumber(t);
			wt.Index = i+size;
			TelephoneNumbers.add(wt);
		}
    }
    
	public PageReference saveNumbers(){
		try{
			List<Telephone_Number__c> insertNumbers = new List<Telephone_Number__c>();
			List<Telephone_Number__c> updateNumbers = new List<Telephone_Number__c>();
			List<Telephone_Number__c> deleteNumbers = new List<Telephone_Number__c>();
			
			for(wrapTelephoneNumber w : TelephoneNumbers){
				Telephone_Number__c tn = w.telephone;
				
				if((tn.Id == null)&&(tn.Telephone_Number__c != null)){
					//Insert Telephone Number
					insertNumbers.add(tn);
				}else if((tn.Id != null)&&(tn.Telephone_Number__c != null)){
					//Update Telephone Number
					updateNumbers.add(tn);
				}else if((tn.Id != null)&&(tn.Telephone_Number__c == null)){
					//Delete Telephone Number
					deleteNumbers.add(tn);
				}
			}
			
			if(insertNumbers.size()>0){
				insert insertNumbers;
			}
			if(updateNumbers.size()>0){
				update updateNumbers;
			}
			if(deleteNumbers.size()>0){
				delete deleteNumbers;
			}
			
			return returnTechInfo();
			
		} catch (Exception e){
			System.debug(e);
			return null;
		}
	}
	
	public PageReference returnTechInfo(){
		PageReference p = new PageReference('/' + currentTI.Id);
		p.SetRedirect(true);
		return p;
	}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_TI_TelephoneNumber(); }
}