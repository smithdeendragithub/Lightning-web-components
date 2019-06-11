public without sharing class ContactEmailOptOutController implements TestUtils.ITestableClass {
	public Contact con {get;private Set;}

	public Boolean HasContact {get;Set;}
	
	public String ContactName {get; private Set;}
	public Boolean HasOptedOut {get;private Set;}
	
	public ContactEmailOptOutController(){
		con = null;
		string ContactID = ApexUtils.getParam('cid');
		HasContact = !String.IsEmpty(ContactID);
		if(HasContact){
			con = [select Id, Name, Email, HasOptedOutOfEmail from Contact where Id = :ContactID limit 1];
			HasContact = con != null;
			ContactName = con.Name;
			HasOptedOut = con.HasOptedOutOfEmail;
		}
	}
	
	public PageReference OptOut(){
		List<Contact> contacts = null;
		if(!String.IsEmpty(con.Email))
			contacts = [Select Id, Name, Email, HasOptedOutOfEmail from Contact where email = :con.email];
		else
			contacts = new List<Contact>{con};
		for(Contact c : contacts){
			c.HasOptedOutOfEmail = true;
		}
		HasOptedOut = true;
		
		update contacts;
		
		return null;
	}
	
	public TestUtils.TestClass getTestClass(){ return new Test_ContactEmailOptOutController(); }
}