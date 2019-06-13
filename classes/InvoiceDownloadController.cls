public class InvoiceDownloadController {
    public String token {get;set;}
    public String invoiceID {get;set;}
    public String pdfString {get;set;}
    public boolean hasError {get;set;}
    public string requesturl {get;set;}
    public string header {get;set;}
    
    public InvoiceDownloadController(){
        token = getToken();
    	invoiceID = Apexpages.currentPage().getParameters().get('invoiceID'); 
        Portal_Web_Service__c objWS = Portal_Web_Service__c.getValues('Allstream Invoices'); 
        string endpoint = objWS.End_Point__c; // be sure this is configured in "Remote Site Settings" 
        string resource = objWS.Resource__c + '/' + invoiceID + '/pdf'; 
        requesturl = endpoint + resource;
        header = 'bearer ' + token;
        //pdfString = getPDFString();
    }

    public String getToken(){
        Portal_Web_Service__c objWS = Portal_Web_Service__c.getValues('Allstream Token');
        string endpoint = objWS.End_Point__c; // be sure this is configured in "Remote Site Settings" 
        string resource = objWS.Resource__c; 
        string username = objWS.Username__c;  
        string password = objWS.Password__c; 
        string method = 'POST';   
        
        try{
        	HttpRequest request = new HttpRequest(); 
            HttpResponse response = new HttpResponse(); 
            Http h = new Http(); 
            
            // Configure the request 
            request.setEndpoint(endpoint + resource); 
            request.setMethod(method); 
            request.setTimeout(120000); 
            Blob headerValue = Blob.valueOf(username + ':' + password); 
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue); 
            request.setHeader('Authorization', authorizationHeader);             
            request.setHeader('Accept', '*/*');  
            request.setHeader('Content-Type', 'application/json'); 
            
            response = h.send(request); 
            Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String accessToken = String.valueOf(meta.get('access_token'));
            
            //System.debug('status code: ' + response.getStatusCode() + ', Status: ' + response.getStatus() + ' text: ' + response.getBody());
            return accessToken;    
        } catch (Exception e){
            System.debug('Unable to get token from ' + endpoint + resource);
        	return '';
        }
        
	}

/*    
    public pageReference DownloadPDF(){  
        Portal_Web_Service__c objWS = Portal_Web_Service__c.getValues('Allstream Invoices'); 
        string endpoint = objWS.End_Point__c; // be sure this is configured in "Remote Site Settings" 
        string resource = objWS.Resource__c + '/' + invoiceID + '/pdf'; 
        string method = 'GET';   
        
        HttpRequest request = new HttpRequest(); 
        HttpResponse response = new HttpResponse(); 
        Http h = new Http(); 
        
        request.setEndpoint(endpoint + resource); 
        request.setMethod(method); 
        request.setTimeout(120000); 
		request.setHeader('Authorization', 'bearer ' + token);             
              
        response = h.send(request); 
		String blobResult;
        Blob blb;
        blb = response.getBodyAsBlob();         
        blobResult = EncodingUtil.Base64Encode(blb); 
		System.debug('blobResult: ' + blobResult);        
                               
        Attachment at= new Attachment(ContentType = 'application/pdf');             
        at.ParentId = 'a2N1k000000Q9YS';           
        at.body = blb;             
        at.name = invoiceID + '.pdf';            
                 
        try{             
        	insert at;             
        }             
        catch (System.QueryException e){             
        	system.debug('System.QueryException of method attSave for insert operation'+ e);             
        }             
        
        id attachmentId = at.id;                                     
        PageReference pageRef= new pageReference('/servlet/servlet.FileDownload?file= '+attachmentid);            
        at=null;             
        blobResult=null;             
        return pageRef;         
       
    } 
*/

    
    public String getPDFString() {
        Portal_Web_Service__c objWS = Portal_Web_Service__c.getValues('Allstream Invoices'); 
        string endpoint = objWS.End_Point__c; // be sure this is configured in "Remote Site Settings" 
        string resource = objWS.Resource__c + '/' + invoiceID + '/pdf'; 
        string method = 'GET';   
        
        try {
        	HttpRequest request = new HttpRequest(); 
            HttpResponse response = new HttpResponse(); 
            Http h = new Http(); 
            
            request.setEndpoint(endpoint + resource); 
            request.setMethod(method); 
            request.setTimeout(120000); 
            request.setHeader('Authorization', 'bearer ' + token);             
                  
            response = h.send(request); 
            if (String.ValueOf(response.getStatusCode()).StartsWith('2')){
            	String blobResult;
            	blobResult = EncodingUtil.Base64Encode(response.getBodyAsBlob()); 
            	return blobResult;    
            }
            else {
                hasError = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Error calling Portal API. Please contact your system administrator. Response Status Code: ' + response.getStatusCode() + ', Status Text: ' + response.getStatus()));
                return null;
            }
        } catch (Exception e){
            hasError = true;
        	system.debug('getPDFString() error: '+ e);   
            if (e.getMessage().Contains('Exceeded max size limit')){
           		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'The PDF file is too large to be retrieved.'));
            }
            else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Error getting PDF. Please contact your administrator. Error: ' + e));
            }
            
			return null;  
        }
    }


}