public class PhoenixTransactionController {
    private static Id MarketAreaNational;
    public static string FieldHistory;
    private static List<Id> existingTransactionsInQueue;
    private static List<Id> failedCreateTransactions;
    private static List<Id> completedCreateTransactions;
    static {
        MarketAreaNational = [select Id From Market_Area__c Where Name = 'National'].Id;
    }
    public static void processCustomerDetailChanges(List<Customer_Detail__c> tNew, Map<Id, Customer_Detail__c> tOldMap, Boolean isDelete){
        Set<Id> cDetailsToBeProcessedSet = new Set<Id>();
        FieldHistory = '';
        System.debug('processCustomerDetailChanges Started');
        List<Customer_Detail__c> cDetailsToBeProcessed = new List<Customer_Detail__c>();
        for (Customer_Detail__c cDetail: tNew){
        	if (String.isBlank(cDetail.ICC_Subscriber_ID__c)) continue;
            if (cDetail.Market_Area__c != MarketAreaNational) continue;
            if (cDetail.Billable__c != true) continue;
            if (customerDetailAlreadyProcessedInThisBatch(cDetailsToBeProcessed, cDetail.Id)) continue;
            cDetailsToBeProcessed.add(cDetail);
            cDetailsToBeProcessedSet.add(cDetail.Id);
            System.debug('cDetail added to List: ' + cDetail.Id + ', name: ' + cDetail.Name);
        }
        
        existingTransactionsInQueue = new List<Id>();
        failedCreateTransactions = new List<Id>();
        completedCreateTransactions = new List<Id>();
        for (Phoenix_Account_Transaction__c t : [SELECT Customer_Detail__c, In_Queue__c, Action__c, Status__c FROM Phoenix_Account_Transaction__c WHERE Customer_Detail__c IN :cDetailsToBeProcessedSet]){
            if (t.In_Queue__c == 'Y'){
                existingTransactionsInQueue.add(t.Customer_Detail__c); 
            }
            
            if (t.Action__c == 'Create' && t.In_Queue__c == 'N' && t.Status__c == 'Failed'){
                failedCreateTransactions.add(t.Customer_Detail__c);
            }
            
             if (t.Action__c == 'Create' && t.In_Queue__c == 'N' && t.Status__c == 'Completed'){
                completedCreateTransactions.add(t.Customer_Detail__c);
            }	  
        }
        
        List<Phoenix_Account_Transaction__c> transactions = new List<Phoenix_Account_Transaction__c>();
        for (Customer_Detail__c cDetail: cDetailsToBeProcessed) {
            // Don't create new transaction if there's one that hasn't been processed by .Net app for this Customer Detail     
            if (!requireNewTransaction(cDetail.Id)) continue;
            Customer_Detail__c oldDetail = tOldMap.get(cDetail.Id);
            
            // Delete
            if (isDelete){
                
            }
            else {
                // Customer Detail just got ICC Subsriber ID, add new Create transaction
                if (String.isBlank(oldDetail.ICC_Subscriber_ID__c)) {
                    System.debug('Create transaction because ICC Subsriber ID was blank. oldDetail.ICC_Subsriber_ID__c: ' + oldDetail.ICC_Subscriber_ID__c + ', newDetail.ICC_Subsriber_ID__c: ' + cDetail.ICC_Subscriber_ID__c);
                	transactions.add(createTransactionObject(cDetail,'Create'));	    
                }
                else{
                    // Check if previous Create transaction failed
                    if (requireNewCreateTransaction(cDetail.Id)){
                        System.debug('Create transaction because of New Create');
                    	transactions.add(createTransactionObject(cDetail,'Create'));     
                    } else if (requirePhoenixUpdate(oldDetail, cDetail)){
                		transactions.add(createTransactionObject(cDetail,'Update'));    
                	}	    
                }
                
            }
    	}    
        
        insert transactions;
    }
    
    public static Phoenix_Account_Transaction__c createTransactionObject(Customer_Detail__c cDetail, String action){
        system.debug('FieldHistory: ' + FieldHistory);
    	Phoenix_Account_Transaction__c t = new Phoenix_Account_Transaction__c();
        t.Account__c = cDetail.Parent_Account__c;
        t.Action__c = action;    
        t.Customer_Detail__c = cDetail.Id;
        t.ICC_Subscriber_ID__c = cDetail.ICC_Subscriber_ID__c;
        t.In_Queue__c = 'Y';
        t.Status__c = 'Queued';
        t.Field_History__c = FieldHistory;
        return t;
    }
    
    private static boolean requirePhoenixUpdate(Customer_Detail__c oldCD, Customer_Detail__c newCD){
        boolean hasChanges = false;
        FieldHistory = '';
        if (newCD.Billing_Main_Name__c == null && oldCD.Name != newCD.Name){
        	return true;    
        }
        //if (oldCD.Legacy_ID__c != newCD.Legacy_ID__c || oldCD.Language_Preference__c != newCD.Language_Preference__c || oldCD.Invoice_PLL__c != newCD.Invoice_PLL__c || oldCD.Billing_Main_Room_Suite__c != newCD.Billing_Main_Room_Suite__c || oldCD.Billing_Main_City__c != newCD.Billing_Main_City__c || oldCD.Billing_Main_Street__c != newCD.Billing_Main_Street__c || oldCD.Billing_Main_State__c != newCD.Billing_Main_State__c || oldCD.Billing_Main_Postal_Code__c != newCD.Billing_Main_Postal_Code__c || oldCD.Billing_Main_Name__c != newCD.Billing_Main_Name__c || oldCD.Billing_Main_Country__c != newCD.Billing_Main_Country__c || oldCD.Customer_Reference__c != newCD.Customer_Reference__c || oldCD.CurrencyIsoCode != newCD.CurrencyIsoCode) 
        if (oldCD.Legacy_ID__c != newCD.Legacy_ID__c)
        {
            FieldHistory += 'Legacy ID has changed from "' + oldCD.Legacy_ID__c + '"" to "' + newCD.Legacy_ID__c + '"" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.Language_Preference__c != newCD.Language_Preference__c)
        {
            FieldHistory += 'Language Preference has changed from "' + oldCD.Language_Preference__c + '"" to "' + newCD.Language_Preference__c + '"" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.Invoice_PLL__c != newCD.Invoice_PLL__c)
        {
            FieldHistory += 'Invoice PLL Indicator has changed from "' + oldCD.Invoice_PLL__c + '" to "' + newCD.Invoice_PLL__c + '" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.Billing_Main_Room_Suite__c != newCD.Billing_Main_Room_Suite__c)
        {
            FieldHistory += 'Billing Main Room/Suite has changed from "' + oldCD.Billing_Main_Room_Suite__c + '" to "' + newCD.Billing_Main_Room_Suite__c + '" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.Billing_Main_City__c != newCD.Billing_Main_City__c)
        {
            FieldHistory += 'Billing Main City has changed from "' + oldCD.Billing_Main_City__c + '" to "' + newCD.Billing_Main_City__c + '" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.Billing_Main_Street__c != newCD.Billing_Main_Street__c)
        {
            FieldHistory += 'Billing Main Street has changed from "' + oldCD.Billing_Main_Street__c + '" to "' + newCD.Billing_Main_Street__c + '" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.Billing_Main_State__c != newCD.Billing_Main_State__c)
        {
            FieldHistory += 'Billing Main State has changed from "' + oldCD.Billing_Main_State__c + '" to "' + newCD.Billing_Main_State__c + '" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.Billing_Main_Postal_Code__c != newCD.Billing_Main_Postal_Code__c)
        {
            FieldHistory += 'Billing Main Postal Code has changed from "' + oldCD.Billing_Main_Postal_Code__c + '" to "' + newCD.Billing_Main_Postal_Code__c + '" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.Billing_Main_Name__c != newCD.Billing_Main_Name__c)
        {
            FieldHistory += 'Billing Main Name has changed from "' + oldCD.Billing_Main_Name__c + '" to "' + newCD.Billing_Main_Name__c + '" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.Billing_Main_Country__c != newCD.Billing_Main_Country__c)
        {
            FieldHistory += 'Billing Main Country has changed from "' + oldCD.Billing_Main_Country__c + '" to "' + newCD.Billing_Main_Country__c + '" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.Customer_Reference__c != newCD.Customer_Reference__c)
        {
            FieldHistory += 'Customer Reference has changed from "' + oldCD.Customer_Reference__c + '" to "' + newCD.Customer_Reference__c + '" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        if (oldCD.CurrencyIsoCode != newCD.CurrencyIsoCode)
        {
            FieldHistory += 'Currency has changed from "' + oldCD.CurrencyIsoCode + '" to "' + newCD.CurrencyIsoCode + '" by ' + newCD.LastModifiedById + ' on ' + newCD.LastModifiedDate + '\n';
        	hasChanges = true;    
        }
        //System.debug('FieldHistory: ' + FieldHistory);
        if (hasChanges){
            return true;
        }
        else {
            return false;
        }
        
    }
    
    private static boolean requireNewTransaction(Id CDId){
        if (existingTransactionsInQueue.isEmpty() || !existingTransactionsInQueue.contains(CDId)){
            return true;
        }
        else{
            return false; 
        }
    }
    
     private static boolean requireNewCreateTransaction(Id CDId){
        if (!failedCreateTransactions.contains(CDId)){
            return false;
        }
        else{
            if (!completedCreateTransactions.contains(CDId)){
           		return true;
            }
            else{
            	return false;    
            }
        }
    }
    
    private static boolean customerDetailAlreadyProcessedInThisBatch(List<Customer_Detail__c> cDetails, Id customerDetailId){
        for (Customer_Detail__c cd : cDetails){
            if (cd.Id == customerDetailId) return true;
        }
        return false;
    }
}