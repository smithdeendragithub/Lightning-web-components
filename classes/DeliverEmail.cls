public with sharing class DeliverEmail extends DeliverBase {

	public override Boolean SendNow( DeliverBase.MessageInfo info ) {
		
		for(MessageContact c : info.contacts){
        	Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();               
        	if(info.TemplateId == null || info.TemplateId == '-Not using a template-'){
				email.setToAddresses( new List<string>{c.RawContact.Email} );
				email.setPlainTextBody(info.Message);
				email.setSubject( info.Subject );
			}else{
				email.setTemplateId(info.TemplateId);
				if(c.RawContact != null)
					email.setTargetObjectId(c.RawContact.Id);
				else if(c.rawUser != null){
					email.setTargetObjectId(c.rawUser.Id);
				}
				email.setSaveAsActivity(false);
				email.setWhatId(info.whatId);
			}
			email.setReplyTo(info.SenderEmail);
			email.setBccSender(false);
			email.setUseSignature(false);
			List<Messaging.Emailfileattachment> fileList = new List<Messaging.Emailfileattachment>(); 
			List<string> fileNames = new List<string>();
			if(info.documents.size() > 0){
				for(ContentVersion attachment : info.documents){
					Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
					efa.setBody(attachment.VersionData);
					string fileName = attachment.PathOnClient;
					if(fileName.lastIndexOf('\\') != -1){
						fileName = fileName.substring(fileName.lastIndexOf('\\') + 1, fileName.length());	
					}
					fileNames.add(fileName);					
					efa.setFileName(fileName);
					fileList.add(efa);
				}
			}
			
			email.setFileAttachments(fileList);
	        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
	        for(Messaging.SendEmailResult emailResult : r){
	        	if(emailResult.isSuccess()){
					if(c.rawContact != null)
	        			addActivityForContentDelivery(c.rawContact.Id, info.WhatID, info, fileNames);
	        	}	        	
	        }       
	        
        }
		return true;
	}
	private void addActivityForContentDelivery(string whoId, string whatId, DeliverBase.MessageInfo info, List<string> fileNames){
		Task t = new Task();
		t.ActivityDate = Date.today();
		string descriptionSuffix = '\nAttached Files: \n';
		for(string file : fileNames){
			descriptionSuffix += file + '\n';
		}
		/*
		if(descriptionSuffix.endsWith(', ')){
			descriptionSuffix = descriptionSuffix.substring(0, descriptionSuffix.lastIndexOf(', '));
		}
		*/
		t.Description = info.Message + descriptionSuffix;
		t.Status = 'Completed';
		t.Subject = info.Subject;
		t.WhatId = whatId;
		t.WhoId = whoId;
		t.Type = 'Email';
		
		try{
			insert t;
		}
		catch(Exception exp){
			System.debug(System.LoggingLevel.DEBUG, 'Error Creating Task: ' + exp);	
		}
	}
	
	/* TestUtils.ITestableClass methods */
	public override TestUtils.TestClass getTestClass(){ return new Test_DeliverEmail(); }
}