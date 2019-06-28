/**
 * Author - Santoshi (Perficient)
 * Purpose - This class will act as a domain class and basis for all the DML operations.
 */
public virtual  class ACR_DomainLayer 
{
    public List<SObject> Records { get; private set;}
    public static List<SObject> staticRecords { get; private set;}
    
    public Schema.DescribeSObjectResult SObjectDescribe {get; private set;}
    
    public   User CurrentUserInfo  {get ; private set;}
    public  static User CurrentUserInfoStatic  {get ; private set;}
    public static final string WEB_SERVICE_CALLOUT = 'WebService Callout';
    public static final string SALESFORCE = 'Salesforce'; 
    public static final string OMNI_ROUTING = 'Omni-Routing Logic';
    public static final string OMNI_ASSIGNMENT = 'Omni-Assignment Logic';
    
    public ACR_DomainLayer(List<SObject> sObjectList)
    { 
        Records = sObjectList;
        staticRecords = sObjectList;
    }
    
    public ACR_DomainLayer(){}
    
    // Class processing query.
    public class QueryEditor{
        public String QUERY_WHERE {get;private set;}
        public string objName {get; private set;}
        public string QUERY_FIELDS {get; private set;}
        public string QUERY_SELECT {get;private set;}
        public string QUERY_FROM {get;private set;}
        public List<SObject> ResultSet { get; private set;}
        public string QUERY {get; private set;}
        
        // Contructor  to only create query
        public QueryEditor(String obName , String whereQuery){
            objName = obName;
            QUERY_WHERE = whereQuery;
            QUERY_SELECT = ' Select ';
            QUERY_FROM = ' FROM ';
            QUERY = buildQueryAllString();
            System.debug('Inside this constructor--'+QUERY);
         }
        public QueryEditor(String obName , String whereQuery , String querySelect){
            objName = obName;
            QUERY_WHERE = whereQuery;
            QUERY_SELECT = 'Select ';
            QUERY_FROM = ' FROM ';
            ResultSet = executeQuery();
        } 
        
        public QueryEditor(String obName , String whereQuery , String qs, boolean hasRelationFields){
            objName = obName;
            QUERY_WHERE = whereQuery;
            QUERY_SELECT = 'Select ';
            QUERY_FROM = ' FROM ';
            if(hasRelationFields){
                QUERY_SELECT = qs;
            }
            ResultSet = executeQuery();
        } 
        
        public QueryEditor(String obName , String whereQuery , String querySelect, String queryFields){
            objName = obName;
            QUERY_WHERE = whereQuery;
            QUERY_FIELDS  = queryFields;
            QUERY_SELECT = 'Select ';
            QUERY_FROM = ' FROM ';
            ResultSet = executeQueryWithFields();
        } 
        
        // Retrievs the field definition for a given object.
        public List<Schema.DescribeFieldResult> getFieldMap(){
            List<Schema.DescribeFieldResult> fields = new List<Schema.DescribeFieldResult>();
            SObjectType accountType = Schema.getGlobalDescribe().get(objName);
            Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();
            for(Schema.SObjectField sof : mfields.values())
            {
                fields.add(sof.getDescribe());
            } 
            return fields;
        }
        
        //Build the Query String
        private String buildQueryAllString()
        {
            String query = QUERY_SELECT;
            List<Schema.DescribeFieldResult> queryFields = getFieldMap();
            for(Schema.DescribeFieldResult dfr : queryFields)
            {
                query = query + dfr.getName() + ',';
            }
            query = query.subString(0,query.length() - 1);
            query = query + QUERY_FROM + ' ';
            query = query + objName + ' ';
            query = query + QUERY_WHERE;
             system.debug('Build Query11 == ' + QUERY_WHERE);
            system.debug('Build Query == ' + query);
            return query;
        }
        
        //Build the Query String
        private String buildQueryFields()
        {
            String query = QUERY_SELECT;
            query = query + QUERY_FIELDS;  
            query = query.subString(0,query.length() - 1);
            query = query + QUERY_FROM + ' ';
            query = query + objName + ' ';
            query = query + QUERY_WHERE;
            system.debug('Build Query == ' + query);
            return query;
        }
        
        //Build the Query String
        private List<SObject> executeQuery()
        {
            datetime dt = System.now()-1;  
            List<SObject> recList =  Database.query(buildQueryAllString());
            return recList;
        }
        
        //Build the Query String
        private List<SObject> executeQueryWithFields()
        {  
            List<SObject> recList =  Database.query(buildQueryFields());
            return recList;
        }
    }
    // public class Error Class
   public class PRFT_Error {
        public String endpoint_URL{get;private set;}
        public String requestBody {get;private set;}
        public String errorType {get;private set;}
        public String errorCode {get;private set;}
        public String recordURL {get;private set;}
        public String responseMessage {get;private set;} 
        public String functionality {get;private set;}
        public String stackTrace {get;private set;} 
        public String actionName {get;private set;} 
        public String objectId {get;private set;}
        public PRFT_Error(String endpointURL,String request, String errorMessage, String response,String errorTypeStr){
            endpoint_URL = endpointURL;
            requestBody = request;
            errorCode = errorMessage;
            errorType = errorTypeStr;
            responseMessage = response;
            insertLogs();  
        }
        
        /** public PRFT_Error(String endpointURL,String request, String errorMessage, String response){
            endpoint_URL = endpointURL;
            requestBody = request;
            errorCode = errorMessage;
            //response = EncodingUtil.URLENCODE(response,'UTF-8');
            responseMessage = response;
            insertBackEndExceptionLogs();
        }
        
        
        
        public PRFT_Error(String functionalityName,String description, String errorMessage, String recURL,Boolean salesforce){
            functionality = functionalityName;
            stackTrace = description;
            errorCode = errorMessage;
            objectId = recURL;
            if(!String.isblank(recURL)){
                recURL = System.Url.getSalesforceBaseURL().toExternalForm() +'/'+ recURL;
            }
            recordURL = recURL;
            insertSalesforceExceptionLogs();
        }*/
        
        // created a new constructor ( trigger  handler context)
      

        public PRFT_Error(String functionalityName,String stackTrace, String errorCode,String operationName,String recURL,Boolean salesforce){
            functionality = functionalityName;
            stackTrace = stackTrace;
            errorCode = errorCode;
            actionName = operationName;
             objectId = recURL;
            if(!String.isblank(recURL)){
                recURL = System.Url.getSalesforceBaseURL().toExternalForm() +'/'+ recURL;
            }
            recordURL = recURL;
            insertSalesforceExceptionLogs();
        }

          // meesage - comma separated record ids for batch apex
            public PRFT_Error(String functionalityName,String concatenatedObjectIds, String errorCode,String operationName){
            functionality = functionalityName;
            stackTrace = concatenatedObjectIds;
            errorCode = errorCode;
            actionName = operationName;
            insertSalesforceExceptionLogs();
        }

        
        public void insertLogs(){
            if(errorType == WEB_SERVICE_CALLOUT)
                insertBackEndExceptionLogs();
            else if(errorType == SALESFORCE){
                insertSalesforceExceptionLogs();
            }
        }
        public void insertBackEndExceptionLogs(){
            try{
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.allowFieldTruncation = true;
              // Integration_Error__c errorLog = new Integration_Error__c(Json_Request__c = requestBody, 
             //  Error_Code__c = errorCode, Response__c = responseMessage, EndPointURL__c = endpoint_URL,Error_Type__c = WEB_SERVICE_CALLOUT);
           //   errorLog.setOptions(dml);
                
           //   insert errorLog;
            } catch (Exception e){
                System.debug('Error in inserting error records ..'+e);
                System.debug(LOGGINGLEVEL.INFO,'Error in inserting error records ..'+e);
            }
        }
        
        public void insertSalesforceExceptionLogs(){ 
            try{
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.allowFieldTruncation = true;
             	Integration_Error__c errorLog = new Integration_Error__c(Functionality_Name__c = functionality, 
                Error_Code__c = errorCode, 	Message__c = stackTrace,   Record_URL__c = recordURL,Error_Type__c = SALESFORCE,
                Action__c = actionName, ObjectID__c = objectId);
                errorLog.setOptions(dml);
                insert errorLog; 
                
            } catch (Exception e){ 
                System.debug('Error in inserting error records ..'+e);
                System.debug(LOGGINGLEVEL.INFO,'Error in inserting error records ..'+e); 
            }
        } 
        
    }  
    
    //Class to process http request
    public class PRFT_Http{
        public String gateway{get;private set;}
        public String endpoint{get;private set;}
        public String body {get;private set;}
        public String contentType {get;private set;}
        public String method {get;private set;}
        public String accessToken {get;private set;}
        public Boolean islogin {get;private set;}
        public String singleFieldParser {get; set;}
        public String parserFieldValue {get;private set;}
        public HTTPResponse res { get; private set;}
        public String responseBody { get; private set;}
        public String errorMessage { get; private set;}
        public Integer statusCode { get; private set;}
        public Boolean doNotEncode {get;private set;}
        public Boolean chatAPI {get;private set;}
        public Map<String,String> headerMap {get;private set;}
        Boolean parseSingleField;
        public  PRFT_Http(){
            
        }
        public  PRFT_Http(String gw,String endp,String bdy,String contentT, String meth,String accessT, Boolean login){
            gateway = gw;
            endpoint = endp;
            body = bdy;
            contentType = contentT;
            method = meth;
            accessToken= accessT;
            islogin = login;
            parseSingleField = false;
            doNotEncode = false;
            res = getHttpResponse();
            
        }

       
        public  PRFT_Http(String gw,String endp,String bdy,String contentT, String meth,String accessT, Boolean login, String parser){
            gateway = gw;
            endpoint = endp;
            body = bdy;
            contentType = contentT;
            method = meth;
            accessToken= accessT;
            islogin = login;
            parseSingleField = true;
            singleFieldParser = parser;
            doNotEncode = false;
            res = getHttpResponse();
            
        }
        
        public  PRFT_Http(String gw,String endp,String bdy,String contentT, String meth,String accessT, Boolean login, Boolean dne){
            gateway = gw;
            endpoint = endp;
            body = bdy;
            contentType = contentT;
            method = meth;
            accessToken= accessT;
            islogin = login;
            parseSingleField = false;
            //  singleFieldParser = parser;
            doNotEncode = dne;
            res = getHttpResponse();
            
        } 
        public  HTTPResponse getHttpResponse(){
            try{
                HttpRequest req = new HttpRequest();
                String bodyStr = '';
                if(!doNotEncode){
                    if(!String.isblank(endpoint)){
                        endpoint = EncodingUtil.URLENCODE(endpoint,'UTF-8');
                        endpoint = endpoint.replace('%2F','/');
                    }
                    else{
                        endpoint = '';
                    }
                }
                endpoint = gateway+endpoint;  
                System.debug('checking endpoint--' +endpoint );
                req.setEndpoint(endpoint);
                req.setMethod(method);
                if(islogin == false){
                    req.setHeader('Authorization', 'Basic '+ accessToken);
                }

            

                 System.debug('checking headerMap--' +headerMap );
                    System.debug('checking contentType--' +contentType );
                if(!String.isblank(contentType))
                    req.setHeader('Content-Type',contentType);
                req.setTimeout(120000);
                if(method == 'POST' || method == 'PUT' ){
                    if(!String.isblank(body)){
                        req.setBody(body);   
                    }
                }  
                Http http = new Http();
                System.debug('Final Request Endpoint Before Callout: ' + req.getEndpoint());
                System.debug('Final Request Body Before Callout: ' + req.getBody());
                res = http.send(req);
                responseBody= (String) res.getBody();
                errorMessage = 'Error:-'+res.getStatusCode()+'-'+res.getStatus();
                statusCode =  res.getStatusCode();
                System.debug('checking parsesingle field--'+parseSingleField);
                if(parseSingleField != null && parseSingleField){
                    if(res.getStatusCode() >= 200 && res.getStatusCode() < 300){
                        parserFieldValue = parseString();
                    }else {
                        parserFieldValue = errorMessage;
                    }
                } 
               if(res.getStatusCode() > 300){
                   // String description = parseString(true,responseBody,'message');
                    errorMessage = responseBody;
                    parserFieldValue = errorMessage;
                    //PRFT_Error err = new PRFT_Error(endpoint,body,errorMessage,responseBody);
                    //ARC_DomainLayer.sendEmailToAdmin(endpoint,body,errorMessage,responseBody);
                    System.debug(Logginglevel.ERROR,'checking errorMessage--'+errorMessage);
                } 
            } catch(Exception e){
                system.debug(Logginglevel.ERROR,'Callout Exception logging error logs---'+e+'---'+e.getStacktraceString());
                //PRFT_Error err = new PRFT_Error(endpoint,body,errorMessage,responseBody);
                //ARC_DomainLayer.sendEmailToAdmin(endpoint,body,errorMessage,responseBody);
            }
            return res;
        }
        
        
        
        public string parseString(){
            JSONParser parser = JSON.createParser(res.getBody()); 
            String parserValue =''; 
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && parser.getText().tolowercase()== singleFieldParser){
                    parser.nextToken(); 
                    parserValue = parser.getText();
                    System.debug('parserValue--'+parserValue);
                    return parserValue;
                }
            }
            return '';  
        }
        
        public string parseString(Boolean ignoreCase ,String resBody){
            JSONParser parser = JSON.createParser(resBody); 
            String parserValue =''; 
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && parser.getText() == singleFieldParser){
                    parser.nextToken(); 
                    parserValue = parser.getText();
                    System.debug('parserValue--'+parserValue);
                    return parserValue;
                }
            }  
            return '';
        }
        
        public string parseString(Boolean ignoreCase ,String resBody,String singleFieldParesers){
            if(resBody == null)
            return 'Callout Exception'; 
            JSONParser parser = JSON.createParser(resBody); 
            String parserValue =''; 
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && parser.getText() == singleFieldParesers){
                    parser.nextToken(); 
                    parserValue = parser.getText();
                    System.debug('parserValue--'+parserValue);
                    return parserValue;
                }
            }
            return ''; 
        }
    }
    
  
    /**
    * Helper to send email to Admin in case of error
    **/
    @future
    public static void sendEmailToAdmin(String endpoint,String body,String errorMessage,String responseBody){
            String msgBody = 'End Point: ' + endpoint + '\r\n';
            msgBody += 'Body: ' + body + '\r\n';
            msgBody += 'Error Message: ' + errorMessage + '\r\n';
            msgBody += 'Response Body: ' + responseBody + '\r\n';
            
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] {  };
            message.subject = 'Error:' +  errorMessage;
            message.plainTextBody = msgBody;
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }
    
    // Create Activity History for the record passed.
    public virtual void createActivityHistory(String parentId, String description , String subject){
        
    }
    /**
* Accesses current user records.
**/
    public void retrieveUserInfo() {  
        String userId = UserInfo.getUserId();
        QueryEditor qr = new QueryEditor('User','WHERE Id = \''+userId+'\' ','Select');
        CurrentUserInfo = (User) qr.ResultSet[0];
    }
    
    /**
* Accesses current user records.
**/
    public void retrieveUserInfo(Boolean hasrelationFields) {  
        String userId = UserInfo.getUserId();
        QueryEditor qr = new QueryEditor('User','WHERE Id = \''+userId+'\' ','Select Profile.Name,',true);
        CurrentUserInfo = (User) qr.ResultSet[0];
    }
    
    /**
* Accesses current user records.
**/
    public static User retrievesCurrentUserInfo() {  
        String userId = UserInfo.getUserId();
        QueryEditor qr = new QueryEditor('User','WHERE Id = \''+userId+'\' ','Select');
        CurrentUserInfoStatic = (User) qr.ResultSet[0];
        return CurrentUserInfoStatic;
    }
    
    /**
* Accesses current user records.
**/ 
    public static User retrieveStaticUserInfo() {  
        String userId = UserInfo.getUserId();
        QueryEditor qr = new QueryEditor('User','WHERE Id = \''+userId+'\' ','Select');
        User CurrentUserInfo = (User) qr.ResultSet[0];
        return CurrentUserInfo;
    }
    
    
    /**
* Accesses current user records.
**/ 
    public static User retrieveNonStaticUserInfo(String query) {  
        String userId = UserInfo.getUserId();
        QueryEditor qr = new QueryEditor('User','WHERE Id = \''+userId+'\' ',query,true);
        User CurrentUserInfo = (User) qr.ResultSet[0];
        return CurrentUserInfo;
    }
    public class DomainException extends Exception
    {
    } 

    /**
     * Retrieves recordtype id for the given sobject.
     *
     * @param sobject name and recordtype name
     * @return recordtype Id
     */
    public String getSobjectsRecordtypeId(String objName,String RecordtypeName){
        //Generate a map of tokens for the sObjects in your organization
         Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        //Retrieve the describe result for the desired object
        DescribeSObjectResult result = gd.get(objName).getDescribe();
        //Generate a map of tokens for all the Record Types for the desired object
        Map <String,Schema.RecordTypeInfo> recordTypeInfo = result.getRecordTypeInfosByName();
        system.debug('RECORD TYPES:' + recordTypeInfo);
        String recId = recordTypeInfo.get(RecordtypeName).getRecordTypeId();
        return recId;
    } 
   /**
    * This Method logs an error in cutom object
    * @param String - exception , message, code, functionality
    * @return void method 
    */
    public  void logError(Exception e, String functionalityName, String recId) {
        PRFT_Error err;
     // err = new PRFT_Error(functionalityName,e.getStackTraceString(),String.valueof(e),recId,true);
      System.debug(LOGGINGLEVEL.INFO+'Logged error in Integration Object'+e.getStackTraceString());

     } 

    /**
     *  Queries salesforce to get results based on search entered
     *  
     *  @param String :- Where condition
     *  @param String - Object Name
     */
    public  List<Sobject> querySearch(String whereCond, String objName){
        System.debug('whereCond::::'+whereCond);
        QueryEditor qr = new QueryEditor(objName,whereCond,'Select');
        System.debug('qr::::'+qr);
        return qr.ResultSet;
    
    }

     /**
     *  Queries salesforce to get results based on search entered
     *  
     *  @param String :- Where condition
     *  @param String - Object Name
     */
    public  List<Sobject> querySearchRelation(String whereCond, String objName,String selectClause){
        System.debug('whereCond::::'+whereCond);
        QueryEditor qr = new QueryEditor(objName,whereCond,selectClause,true);
        System.debug('qr::::'+qr);
        return qr.ResultSet;
    
    }

    /**
     * Converts set to String
     */
    public String quoteKeySet(Set<String> mapKeySet)
    {
        String newSetStr = '' ;
        for(String str : mapKeySet)
            newSetStr += '\'' + str + '\',';
        newSetStr = newSetStr.lastIndexOf(',') > 0 ? '(' + newSetStr.substring(0,newSetStr.lastIndexOf(',')) + ')' : newSetStr ;
        System.debug('quoteKeySet() :  newSetStr ============ ' + newSetStr);   
        return newSetStr;

    }

}