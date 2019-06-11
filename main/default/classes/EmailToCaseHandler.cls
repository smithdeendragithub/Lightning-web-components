global class EmailToCaseHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        try {
            List<Contact> contacts= [SELECT Id, Name, Email, Account.Id  FROM Contact    WHERE Email = :envelope.fromAddress limit 1];
            
            String routingEmail = CustomSettingUtils.getSingleProcessConfigurationValue('EmailToCaseRoutingLookup','Order', false);
            if(routingEmail != null && envelope.toAddress.contains(routingEmail )){
                Id caseToOrderRt = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Case_To_Order_Support').getRecordTypeId();
                Id queueId = [Select Id, Name, DeveloperName from Group where Type =  'Queue' and developerName = 'Voice_Orders'].Id;
                Case ca = new Case(subject = email.subject,Description=email.plainTextBody,recordTypeId = caseToOrderRt, Origin='Email', OwnerId= queueId);  

                if( contacts != null && contacts.size() >0){

                    Contact ct = contacts.get(0);
                    ca.ContactId = ct.Id;
                    ca.AccountId = ct.Account.Id;
                }
                insert ca; 
                
                if (ca.Id != null && email.binaryAttachments != null && email.binaryAttachments.size() > 0){
                    for (integer i=0; i<email.binaryAttachments.size(); i++){
                        Attachment a = new Attachment(ParentId = ca.Id,
                        Name = email.binaryAttachments[i].filename,
                        Body = email.binaryAttachments[i].body);
                        insert a;    
                    }
                }
                if (ca.Id != null){
                    EmailMessage em = new EmailMessage(Subject = email.subject, TextBody=email.plainTextBody,RelatedToId=ca.Id, ParentId=ca.Id, 
                    fromAddress= envelope.fromAddress, fromName= email.fromName, toAddress=envelope.toAddress, status ='0', Incoming=true, htmlBody = email.htmlBody);
                    insert em;
                }                
                
            }
        }
        catch (System.QueryException e) {
            System.debug('Contact Query Issue: ' + e);
        }   

        return result;
    }
}