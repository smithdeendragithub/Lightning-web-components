public class ReportHelper {
        @future()
        public static void generateReport(Date fromDate, Date toDate, Boolean isForSplit){
            Map<Id, User> users =  new Map<Id, User>([select Id, Name,Email, isActive, Sales_Channel__c, ManagerId from User where isActive = true]);

            String query ='Select Id, Opportunity__r.Name, Name,  Opportunity__r.Oppty_Sub_Type__c,Opportunity__r.Term__c, Opportunity__r.Split_Percent_1__c, Opportunity__r.Split_Owner_1__c, Opportunity__r.Split_Percent_2__c,Opportunity__r.Split_Owner_2__c, Opportunity__r.ForecastCategoryName, Opportunity__r.Sales_Channel__c , Opportunity__r.Owner.ManagerId, Opportunity__r.Type, Opportunity__r.SF_Opportunity_ID__c, Sales_Product__c, CPE_Amount__c, Opportunity__r.CPE_Amount__c, Opportunity__r.CPQ_NRC_Total__c, Opportunity__r.NRR_Amount__c, NRC__c, MRC__c, Opportunity__r.Amount, Opportunity__r.CloseDate, Opportunity__r.Order_Pending_Date__c,Opportunity__r.Contract_Term_End_Date__c, Opportunity__r.StageName, Opportunity__r.OwnerId, Opportunity__r.Account.OwnerId, Opportunity__r.Account.Name, Opportunity__r.Account.Care_Organization_Name__c ,Opportunity__r.CurrencyIsoCode, CurrencyIsoCode from Opportunity_Product__c '+
        'where  Active__c = true and Opportunity__r.ForecastCategoryName != \'Omitted\' and Opportunity__r.Order__r.Order_Pending_Date__c >= :fromDate and Opportunity__r.Order__r.Order_Pending_Date__c < :toDate' +(isForSplit?' and Opportunity__r.Split_Owner_1__c != null ':'') ;

            List<Opportunity_Product__c> ops =  Database.query(query);

            String csv = 'Opportunity Name, Opportunity Type,   Contract Term,  Split % 1,  Split Owner Split Sub Owner 1,  Split % 2,  Split Owner Split Sub Owner 2,Forecast Category ,Sales Channel, Opportunity Owner Manager,  Customer Type,  SF Opportunity ID,  Sales Product,  CPE Amount - NRO,   CPE Amount / NRO,   CPQ NRC Total,  NRR / NRI,  NRC - NRI,  MRC,    MRR Amount, Close Date, Order Pedning Date, Contract Term End Date, Stage,  Opportunity Owner,  Account Owner,  Account Name,   Care Organization \n';
            Decimal tempValue = 0;
            
            for(Opportunity_Product__c o : ops)
            {
                csv += o.Opportunity__r.Name.replaceFirst(',',' ').escapeCsv()+ ',';
                //csv += o.Name.replaceFirst(',',' ').escapeCsv() + ',';           
                csv += (o.Opportunity__r.Oppty_Sub_Type__c!= null?o.Opportunity__r.Oppty_Sub_Type__c:'')+ ',';
                csv += (o.Opportunity__r.Term__c!=null?o.Opportunity__r.Term__c:'')+ ',';
                if(o.Opportunity__r.Split_Percent_1__c != null && o.Opportunity__r.Split_Percent_1__c >0){                               
                    csv += o.Opportunity__r.split_Percent_1__c +',,,,';
                }else{
                    csv += ',,,,';
                }
                csv += o.Opportunity__r.ForecastCategoryName+ ',';
                csv += (o.Opportunity__r.Sales_Channel__c!= null?o.Opportunity__r.Sales_Channel__c:'')+ ',';
                csv += (users.get(o.Opportunity__r.Owner.ManagerId) != null?users.get(o.Opportunity__r.Owner.ManagerId).Name:'')+ ',';
                csv += (o.Opportunity__r.Type != null? o.Opportunity__r.Type:'')+ ',';
                csv += o.Opportunity__r.SF_Opportunity_ID__c+ ',';
                csv += o.Sales_Product__c+ ',';
                if(o.Opportunity__r.Split_Percent_1__c != null && o.Opportunity__r.Split_Percent_1__c >0){                               
                    tempValue = (o.CPE_Amount__c!= null) ?(o.Opportunity__r.split_Percent_1__c*o.CPE_Amount__c/100).setScale(2):0.0;
                    csv +=  (tempValue != null?o.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.Opportunity__r.CPE_Amount__c !=null)?(o.Opportunity__r.split_Percent_1__c*o.Opportunity__r.CPE_Amount__c/100).setScale(2) :0.0;
                    csv +=  (tempValue.toPlainString()!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';                        
                    tempValue = (o.Opportunity__r.CPQ_NRC_Total__c !=null)?(o.Opportunity__r.split_Percent_1__c*o.Opportunity__r.CPQ_NRC_Total__c/100).setScale(2) :0.0;
                    csv +=  (tempValue.toPlainString()!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.Opportunity__r.NRR_Amount__c!= null)?(o.Opportunity__r.split_Percent_1__c*o.Opportunity__r.NRR_Amount__c/100).setScale(2):0.0;
                    csv +=  (tempValue!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.NRC__c!= null)?(o.Opportunity__r.split_Percent_1__c*o.NRC__c/100).setScale(2):0.0;
                    csv +=  (tempValue!= null?o.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue =(o.MRC__c != null)?(o.Opportunity__r.split_Percent_1__c*o.MRC__c/100).setScale(2):0.0;
                    csv +=  (tempValue!= null?o.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue =  (o.Opportunity__r.Amount != null)?(o.Opportunity__r.split_Percent_1__c*o.Opportunity__r.Amount/100).setScale(2):0.0;
                    csv +=  (tempValue!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                }else{
                    tempValue = (o.CPE_Amount__c!= null) ?o.CPE_Amount__c.setScale(2):0.0;
                    csv +=  (tempValue!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.Opportunity__r.CPE_Amount__c !=null)?o.Opportunity__r.CPE_Amount__c.setScale(2) :0.0;
                    csv +=  (tempValue.toPlainString()!= null?o.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';                        
                    tempValue = (o.Opportunity__r.CPQ_NRC_Total__c != null? o.Opportunity__r.CPQ_NRC_Total__c.setScale(2):0.0);
                    csv +=  (tempValue!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.Opportunity__r.NRR_Amount__c!= null)?o.Opportunity__r.NRR_Amount__c.setScale(2):0.0;
                    csv +=  (tempValue!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.NRC__c != null)?o.NRC__c.setScale(2):0.0;
                    csv +=  (tempValue!= null?o.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.MRC__c != null)?o.MRC__c.setScale(2):0.0;
                    csv +=  (tempValue!= null?o.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.Opportunity__r.Amount != null )?o.Opportunity__r.Amount.setScale(2):0.0;
                    csv +=  (tempValue!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';                       
                }
                csv +=  (o.Opportunity__r.CloseDate!= null?o.Opportunity__r.CloseDate.format():'')+ ',';
                csv +=  (o.Opportunity__r.Order_Pending_Date__c!= null?o.Opportunity__r.Order_Pending_Date__c.format():'')+ ',';
                csv +=  (o.Opportunity__r.Contract_Term_End_Date__c!= null?o.Opportunity__r.Contract_Term_End_Date__c.format():'')+ ',';
                csv +=  o.Opportunity__r.StageName+ ',';
                if(o.Opportunity__r.Split_Percent_1__c != null && o.Opportunity__r.Split_Percent_1__c >0){                               
                    csv += (users.get(o.Opportunity__r.Split_Owner_1__c)!= null?users.get(o.Opportunity__r.Split_Owner_1__c).Name.escapeCsv():'')+ ',';
                }else{
                    csv += (users.get(o.Opportunity__r.OwnerId)!= null?users.get(o.Opportunity__r.OwnerId).Name.escapeCsv():'')+ ',';
                }
                csv += (users.get(o.Opportunity__r.Account.OwnerId)!= null?users.get(o.Opportunity__r.Account.OwnerId).Name.escapeCsv():'')+ ',';
                csv += o.Opportunity__r.Account.Name.replaceFirst(',',' ').escapeCsv()+ ',';
                csv += (o.Opportunity__r.Account.Care_Organization_Name__c!=null?o.Opportunity__r.Account.Care_Organization_Name__c:'')+ '\n';
    
                if(o.Opportunity__r.Split_Percent_2__c != null  && o.Opportunity__r.Split_Percent_2__c >0){
                    csv += o.Opportunity__r.Name.replaceFirst(',',' ').escapeCsv()+ ',';
                    //csv += o.Name.replaceFirst(',',' ').escapeCsv() + ',';           
                    csv += (o.Opportunity__r.Oppty_Sub_Type__c!= null?o.Opportunity__r.Oppty_Sub_Type__c:'')+ ',';
                    csv += (o.Opportunity__r.Term__c!=null?o.Opportunity__r.Term__c:'')+ ',';
                    csv += ',';
                    csv += ',';
                    csv += o.Opportunity__r.split_Percent_2__c+ ',';              
                    csv += ',';
                    csv += o.Opportunity__r.ForecastCategoryName+ ',';
                    //csv += (o.Opportunity__r.Sales_Channel__c!= null?o.Opportunity__r.Sales_Channel__c:'')+ ',';
                    //csv += (users.get(o.Opportunity__r.Owner.ManagerId) != null?users.get(o.Opportunity__r.Owner.ManagerId).Name:'')+ ',';
                    csv += (users.get(o.Opportunity__r.Split_Owner_2__c).Sales_Channel__c!= null?users.get(o.Opportunity__r.Split_Owner_2__c).Sales_Channel__c:'')+ ',';
                    csv += (users.get(users.get(o.Opportunity__r.Split_Owner_2__c).ManagerId)!=null?users.get(users.get(o.Opportunity__r.Split_Owner_2__c).ManagerId).Name:'')+ ',';
                    csv += (o.Opportunity__r.Type != null? o.Opportunity__r.Type:'')+ ',';
                    csv += o.Opportunity__r.SF_Opportunity_ID__c+ ',';
                    csv += o.Sales_Product__c+ ',';
                    tempValue = (o.CPE_Amount__c!= null) ?(o.Opportunity__r.split_Percent_2__c*o.CPE_Amount__c/100).setScale(2):0.0;
                    csv +=  (tempValue!= null?o.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.Opportunity__r.CPE_Amount__c !=null)?(o.Opportunity__r.split_Percent_2__c*o.Opportunity__r.CPE_Amount__c/100).setScale(2) :0.0;
                    csv +=  (tempValue.toPlainString()!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';                        
                    tempValue = (o.Opportunity__r.CPQ_NRC_Total__c !=null)?(o.Opportunity__r.split_Percent_2__c*o.Opportunity__r.CPQ_NRC_Total__c/100).setScale(2) :0.0;
                    csv +=  (tempValue!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.Opportunity__r.NRR_Amount__c!= null)?(o.Opportunity__r.split_Percent_2__c*o.Opportunity__r.NRR_Amount__c/100).setScale(2):0.0;
                    csv +=  (tempValue!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue = (o.NRC__c!= null)?(o.Opportunity__r.split_Percent_2__c*o.NRC__c/100).setScale(2):0.0;
                    csv +=  (tempValue!= null?o.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue =(o.MRC__c != null)?(o.Opportunity__r.split_Percent_2__c*o.MRC__c).setScale(2)/100:0.0;
                    csv +=  (tempValue!= null?o.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    tempValue =  (o.Opportunity__r.Amount != null)?(o.Opportunity__r.split_Percent_2__c*o.Opportunity__r.Amount/100).setScale(2):o.Opportunity__r.Amount;
                    csv +=  (tempValue!= null?o.Opportunity__r.CurrencyIsoCode+' '+tempValue.toPlainString():'')+',';
                    csv +=  (o.Opportunity__r.CloseDate!= null?o.Opportunity__r.CloseDate.format():'')+ ',';
                    csv +=  (o.Opportunity__r.Order_Pending_Date__c!= null?o.Opportunity__r.Order_Pending_Date__c.format():'')+ ',';
                    csv +=  (o.Opportunity__r.Contract_Term_End_Date__c!= null?o.Opportunity__r.Contract_Term_End_Date__c.format():'')+ ',';
                    csv += o.Opportunity__r.StageName+ ',';
                    csv += (users.get(o.Opportunity__r.Split_Owner_2__c)!=null?users.get(o.Opportunity__r.Split_Owner_2__c).Name.escapeCsv():'')+ ',';
                    csv += (users.get(o.Opportunity__r.Account.OwnerId)!= null?users.get(o.Opportunity__r.Account.OwnerId).Name.escapeCsv():'')+ ',';
                    csv += o.Opportunity__r.Account.Name.replaceFirst(',',' ').escapeCsv()+ ',';
                    csv += (o.Opportunity__r.Account.Care_Organization_Name__c!=null?o.Opportunity__r.Account.Care_Organization_Name__c:'')+ '\n';
                    
                }
    
            }
            DateTime now= Datetime.now();
            String dateOutput = now.format('dd-MM-yyyy_hh-mm');
            String fileName = 'SHS-Comp Opp Level US/CAN_'+dateOutput+'.csv';
            
            ContentVersion file = new ContentVersion(
                                  title = fileName,
                                  versionData = Blob.valueOf( csv ),
                                  pathOnClient = '/'+fileName
                                );
            
            
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { UserInfo.getUserEmail() };
            message.optOutPolicy = 'FILTER';
            try{
                insert file;
                message.subject = 'SalesComp File '+fileName +' has been created.';
                message.plainTextBody = 'Please checked the file under Files->All Files.';

            }catch (Exception e) {
                message.subject = 'ERORR : can not create SalesComp File '+fileName +'.';
                message.plainTextBody = 'Please reduce the search criteria.';
            
            }
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            
            if (results[0].success) {
                System.debug('The email was sent successfully.');
            } else {
                System.debug('The email failed to send: ' + results[0].errors[0].message);
            }            
                    
        }
    
    private static String formatDate(Date d) {
        return  d.month() + '-' + d.day() + '-' + d.year();
    }
}