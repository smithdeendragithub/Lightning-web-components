public with sharing class ImportDataFromCSVController {
    public Blob csvFileBody{get;set;}
    public String[] orderDataLines {get;set;}
    public List <Order__c> lstOrders {get;set;}
    public Map<String, Order__c> mapOrders{get; set;}
    public boolean readSuccess {get;set;}
    public List<SelectOption> currencies {get; set;}
    public String selectedCurrency {get; set;}    
    public String selectedFileType {get; set;}    
    public Integer numOfRenewal {get; set;}  

    Order__c ordObj;
    String orderDataAsString;
    String fieldValue;
    Integer fieldNumber;
    Map < String, Integer > fieldNumberMap = new Map < String, Integer > ();
    Map<String, String> columnMap = new Map<String, String>{'CUSTNO'=>'Account__c', 'CONTRACT'=>'Contract_ID__c'
                                                            ,'CTR_START'=>'Old_Contract_Start_Date__c' ,'CTR_END'=>'Old_Contract_End_Date__c'
                                                            ,'CTR_PRICE'=>'Original_Contract_MRC__c','NEXT_START'=>'New_Contract_Start_Date__c'
                                                             ,'NEXT_END'=>'New_Contract_End_Date__c','NEXT_PRICE'=>'New_Contract_MRC__c'};

    Map<String, String> churnColumnMap = new Map<String, String>{'CUSTNO'=>'Account__c', 'CONTRACT'=>'Contract_ID__c'
                                                            ,'CURRENTSTARTDATE'=>'Old_Contract_Start_Date__c' ,'CURRENTENDDATE'=>'Old_Contract_End_Date__c'
                                                            ,'MRR'=>'Original_Contract_MRC__c','CURRENTCANCELDATE'=>'Contract_Cancel_Date__c'
                                                             ,'CANCELLATIONDESCRIPTION' =>'Contract_Cancel_Reason__c'};

    Map<String, String> installColumnMap = new Map<String, String>{'CUSTNBR'=>'Account__c', 'CONTRACT'=>'Contract_ID__c', 'ORDER'=>'Order_ID_for_Install_Contract__c'
                                                            ,'CTR_START'=>'New_Contract_Start_Date__c' ,'CTR_END'=>'New_Contract_End_Date__c'
                                                            ,'MRR'=>'New_Contract_MRC__c' };
                                                                 
    List<String> dateFields = new List<String>{'Old_Contract_Start_Date__c','Old_Contract_End_Date__c','New_Contract_Start_Date__c','New_Contract_End_Date__c','Contract_Cancel_Date__c'};   
    List<String> currencyFields = new List<String>{'Original_Contract_MRC__c','New_Contract_MRC__c'};   
    public ImportDataFromCSVController() {
        readSuccess = FALSE;
        orderDataLines = new String[] {};
        lstOrders = new List <Order__c> ();
        mapOrders = new Map<String, Order__c>();
        numOfRenewal=0;
        currencies = new List<SelectOption>();
        List<CurrencyType> currencyTypes = [select ISOCode, ConversionRate, DecimalPlaces from CurrencyType where IsActive=TRUE];
        for (CurrencyType ct : [select ISOCode, ConversionRate, DecimalPlaces from CurrencyType where IsActive=TRUE]) {
            currencies.add(new SelectOption(ct.ISOCode, ct.ISOCode));
        }
    }
    public PageReference  readFromFile(){
        try{
            orderDataAsString = csvFileBody.toString();
            readCSVFile();            
        }
        catch(exception e){
            readSuccess = FALSE;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR,'Error reading CSV file :'+e.getMessage());
            ApexPages.addMessage(errorMessage);
        } 
        return null;                   
    }    
    
    public void readCSVFile() {
        lstOrders.clear();
        mapOrders = new Map<String, Order__c>();
        numOfRenewal = 0;
        Set<String> legacyIdSet = new Set<String>();
        Map<String, Id> accountIdMap = new Map<String, Id>();
        orderDataLines = orderDataAsString.split('\n');
        string[] csvFieldNames = orderDataLines[0].split(',');
        String objFieldName = '';
        Set<String> orderIdSet = new Set<String>();

        for (Integer i = 0; i < csvFieldNames.size(); i++) {
        //there are different columns for the different files
            if(selectedFileType.contains('Churn')){
                objFieldName =churnColumnMap.get(csvFieldNames[i].trim());
            }else if(selectedFileType.contains('Install')){
                objFieldName =installColumnMap.get(csvFieldNames[i].trim());
            }else{
                objFieldName =columnMap.get(csvFieldNames[i].trim());           
            }

            if(objFieldName != null || csvFieldNames[i].trim() =='RENEWAL_STATUS'){
                fieldNumberMap.put(objFieldName, i);
                 if(csvFieldNames[i].trim() =='RENEWAL_STATUS'){
                    fieldNumberMap.put(csvFieldNames[i].trim(), i);
                 }

            }
        }

        Id ctrRewRtID = Schema.SObjectType.Order__c.getRecordTypeInfosByDeveloperName().get('Contract_Renewal').getRecordTypeId();
        Integer rowCount = 0;
        for (Integer i = 1; i < orderDataLines.size(); i++) {                      
            string[] csvRecordData = orderDataLines[i].split(',');
            Boolean isRenewStatus = true;

             if(csvRecordData[0] != null && csvRecordData[0] != ''){
                ordObj = new Order__c();
                ordObj.RecordTypeId = ctrRewRtID;
                ordObj.SPC_Product__c = 'a2DC0000000TwPiMAK';
                ordObj.CurrencyIsoCode  = selectedCurrency;
                ordObj.Contract_Status__c= selectedFileType;
                if(selectedFileType != 'Renewal'){
                    ordObj.Order_Completion_Status__c = 'Complete';
                }else{
                    ordObj.Contract_Cancel_Reason__c = 'Contract Renewals';
                }
    
                String ordFieldName = '';
                
                for (String fieldName: csvFieldNames) { 
                    if(selectedFileType != 'Renewal' && fieldName == 'RENEWAL_STATUS'){
                        fieldNumber = fieldNumberMap.get(fieldName.trim());
                        fieldValue = csvRecordData[fieldNumber];
                        if(fieldValue != 'Renewed'){
                           isRenewStatus = false;
                           break;
                        }
                    }                 

                   if(selectedFileType.contains('Churn')){
                       ordFieldName =churnColumnMap.get(fieldName.trim());
                   }else if(selectedFileType.contains('Install')){
                       ordFieldName =installColumnMap.get(fieldName.trim());
                   }else{
                       ordFieldName =columnMap.get(fieldName.trim());           
                   }        

                    if(ordFieldName  != null){
                        fieldNumber = fieldNumberMap.get(ordFieldName);
                        fieldValue = csvRecordData[fieldNumber];

                        if(dateFields.contains(ordFieldName)){
                           Date x = null;
                           if(fieldValue != null &&  fieldValue.trim().length()>0 ){
                              x = Date.valueOf(fieldValue.trim());
                           }
                            ordObj.put(ordFieldName , x);
                        }else if(currencyFields.contains(ordFieldName)){
                            ordObj.put(ordFieldName ,Decimal.valueOf(fieldValue==null||fieldValue.trim()==''?'0':fieldValue.trim()) );                  
                        }else{
                            if(ordFieldName =='Account__c'){
                               legacyIdSet.add(fieldValue.trim());
                            }else if(ordFieldName =='Order_ID_for_Install_Contract__c'){
                               orderIdSet.add(fieldValue.trim());
                            }
                            ordObj.put(ordFieldName , fieldValue.trim());
                        }
                        
                     }
                }
            
                if((selectedFileType =='Renewal' && isRenewStatus ) || selectedFileType.contains('Churn') ||selectedFileType == 'Actual Install'){
                    mapOrders.put(ordObj.Contract_ID__c, ordObj);
                }else if(selectedFileType == 'Anticipated Install'){
                    mapOrders.put(ordObj.Order_ID_for_Install_Contract__c, ordObj); 
                }
              }          
        }
        numOfRenewal = mapOrders.size();
        //search whether there are the same contract Id within the same quarter of the same year. 
        List<Order__c> sameContractOrders = getSameContractOrders(ctrRewRtID , mapOrders.keyset(), selectedFileType );

        for(Order__c dupOrder : sameContractOrders){
            if(selectedFileType == 'Anticipated Install'){
                mapOrders.remove(dupOrder.Order_ID_for_Install_Contract__c);
            }else{
                mapOrders.remove(dupOrder.Contract_ID__c);
            }
        }
        
        //check whether there are anticipated churns/installs for the same contract #
        if(selectedFileType == 'Actual Install'){
            List<Order__c> antiOrders = getAnticipatedOrdersForSameContract(ctrRewRtID , orderIdSet, selectedFileType );

            for(Order__c antiOrder : antiOrders){
               for(Order__c actualOrder :mapOrders.values()){
                   if(actualOrder.Order_ID_for_Install_Contract__c == antiOrder.Order_ID_for_Install_Contract__c){
                       actualOrder.Id =  antiOrder.Id;
                       break;
                   }
               }
            }        
        }else if(selectedFileType == 'Actual Churn'){
            List<Order__c> antiOrders = getAnticipatedOrdersForSameContract(ctrRewRtID , mapOrders.keyset(), selectedFileType );

            Order__c actualOrder = new Order__c();
            for(Order__c antiOrder : antiOrders){
                actualOrder = mapOrders.get(antiOrder.Contract_ID__c);
                actualOrder.Id =  antiOrder.Id;
            }        
        }

        
        lstOrders = mapOrders.values();
        if(lstOrders.size() > 0){
            if(selectedCurrency == 'CAD'){
                for(Customer_Detail__c cd :[Select Legacy_Id__c, Parent_Account__c from Customer_Detail__c where Legacy_Id__c in :legacyIdSet]){
                    accountIdMap.put(cd.Legacy_Id__c, cd.Parent_Account__c);
                }
            }else{
                for(Customer_Detail__c cd :[Select ICC_Subscriber_ID__c, Parent_Account__c from Customer_Detail__c where ICC_Subscriber_ID__c in :legacyIdSet]){
                    accountIdMap.put(cd.ICC_Subscriber_ID__c, cd.Parent_Account__c);
                }                
            }
            
            for(Order__c o :lstOrders){
                 o.Account__c = accountIdMap.get(o.Account__c);
            }
            readSuccess = TRUE;
        } 
  }
   
  
  private List<Order__c> getSameContractOrders(Id reportyTypeId, Set<String> contractIds, String contractStatus) {
        Date today = Date.today();
        Integer q;
        
        if(today.month() != 3 && today.month() != 6 && today.month() != 9 && today.month() != 12){
            q = math.round((today.month())/3)*3;
        }else{
            q = math.round((today.month()-1)/3)*3;
        }
        Integer minQ = q + 1;
        Integer maxQ = q + 3;
        
        List<Order__c> sameOrders;
        if(contractStatus == 'Anticipated Install'){
           sameOrders=  [Select Id, Name, Contract_ID__c, createdDate, Order_ID_for_Install_Contract__c from Order__c where CALENDAR_YEAR(createdDate) = :today.year()
                and CALENDAR_MONTH(createdDate) >= :minQ and CALENDAR_MONTH(createdDate) <= :maxQ and RecordTypeId =:reportyTypeId
                and Order_ID_for_Install_Contract__c in :contractIds and Contract_Status__c = :contractStatus];

        }else{
           sameOrders= [Select Id, Name, Contract_ID__c, createdDate, Order_ID_for_Install_Contract__c from Order__c where CALENDAR_YEAR(createdDate) = :today.year()
                and CALENDAR_MONTH(createdDate) >= :minQ and CALENDAR_MONTH(createdDate) <= :maxQ and RecordTypeId =:reportyTypeId
                and Contract_ID__c in :contractIds and Contract_Status__c = :contractStatus];

        }
        
        return sameOrders;
  
  }
  
  private List<Order__c> getAnticipatedOrdersForSameContract(Id reportyTypeId, Set<String> contractIds, String contractStatus) {
        Date today = Date.today();
        Integer q;
        
        if(today.month() != 3 && today.month() != 6 && today.month() != 9 && today.month() != 12){
            q = math.round((today.month())/3)*3;
        }else{
            q = math.round((today.month()-1)/3)*3;
        }
        Integer minQ = q + 1;
        Integer maxQ = q + 3;
        
        String antiContractStatus;
        List<Order__c> antiOrders ;
        if(contractStatus == 'Actual Install'){
           antiContractStatus = 'Anticipated Install';
           antiOrders =   [Select Id, Name, Contract_ID__c, createdDate, Order_ID_for_Install_Contract__c from Order__c where CALENDAR_YEAR(createdDate) = :today.year()
                and CALENDAR_MONTH(createdDate) >= :minQ and CALENDAR_MONTH(createdDate) <= :maxQ and RecordTypeId =:reportyTypeId
                and Order_ID_for_Install_Contract__c in :contractIds and Contract_Status__c = :antiContractStatus];
           
           
        }else if(contractStatus == 'Actual Churn'){
           antiContractStatus = 'Anticipated Churn';    
           antiOrders =   [Select Id, Name, Contract_ID__c, createdDate, Order_ID_for_Install_Contract__c from Order__c where CALENDAR_YEAR(createdDate) = :today.year()
                and CALENDAR_MONTH(createdDate) >= :minQ and CALENDAR_MONTH(createdDate) <= :maxQ and RecordTypeId =:reportyTypeId
                and Contract_ID__c in :contractIds and Contract_Status__c = :antiContractStatus];

        }
        return antiOrders ;  
  }
  
 
  public void saveData() {
    try {
        Database.UpsertResult[] srList = Database.Upsert(lstOrders, false);  
      ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.INFO, lstOrders.size() +' Contract Renewal type Order records inserted successfully');
      ApexPages.addMessage(errorMessage);
      lstOrders.clear();
    } catch (Exception e) {
      ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR, 'An error has occured while saving data');
      ApexPages.addMessage(errorMessage);
    }
          readSuccess = FALSE;
          numOfRenewal =0;
  }
}