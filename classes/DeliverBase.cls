public virtual with sharing class DeliverBase implements TestUtils.ITestableClass {

	public enum RecipientType { None, Signer, CertifiedDelivery, CC }

	public class MessageContact {
		public Contact rawContact {get;set;}
		public User rawUser {get;set;}
		public Integer routingOrder {get;set;}
		public RecipientType recipType {get;set;}
		public MessageContact() {
			this.recipType = RecipientType.None;
			this.routingOrder = 0;
		}		
	}

	public class MessageInfo {
		public String Subject {get;set;}
		public String Message {get;set;}
		public List<ContentVersion> documents {get;set;}
		public List<MessageContact> contacts {get;set;}
		public string TemplateId { get; set; }
		public string SenderEmail {get; set; }
		public string WhatID { get; set; }
	}
	
	/**
	* Thrown when an error occurs delivering a MessageInfo
	*/
	public class DeliveryException extends Exception {
	}
	
	public String LastError {get;set;}
	

	public virtual Boolean SendNow( DeliverBase.MessageInfo info ) {
		return true;
	}

	public Map<Id, EmailTemplate> findTemplates(String folderName) {
		
		Map<Id, EmailTemplate> retVal = new Map<Id, EmailTemplate>([Select Id, Name, DeveloperName, Subject, HtmlValue, Description, Body From EmailTemplate WHERE Folder.DeveloperName=:folderName]);		
		return retVal;
	}
	
	/* TestUtils.ITestableClass methods */
	public virtual TestUtils.TestClass getTestClass(){ return new Test_DeliverBase(); }
}