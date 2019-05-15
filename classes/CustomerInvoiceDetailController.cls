public class CustomerInvoiceDetailController {
    public Content content {get;set;}
	public String token {get;set;}
    public String invoiceID {get;set;}
    
    public CustomerInvoiceDetailController(){
        invoiceID = Apexpages.currentPage().getParameters().get('Id'); 
        token = getToken();
       	content = getInvoiceDetail(token); 
    }
   
    public String getToken(){
        Portal_Web_Service__c objWS = Portal_Web_Service__c.getValues('Allstream Token');
        String token; 
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
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Unable to get token from ' + endpoint + resource); 
			ApexPages.addMessage(myMsg); 
            return '';
        }
        
	}
    
    public Content getInvoiceDetail(String token){
        Portal_Web_Service__c objWS = Portal_Web_Service__c.getValues('Allstream Invoices');
        string endpoint = objWS.End_Point__c; // be sure this is configured in "Remote Site Settings" 
        string resource = objWS.Resource__c + '/' + String.ValueOf(invoiceID); 
        string method = 'GET'; 
        Content c = new Content();
        
        try{
        	HttpRequest request = new HttpRequest(); 
            HttpResponse response = new HttpResponse(); 
            Http h = new Http(); 
            
            request.setEndpoint(endpoint + resource); 
            request.setMethod(method); 
            request.setTimeout(120000); 
            request.setHeader('Authorization', 'bearer ' + token);             
            request.setHeader('Accept', '*/*'); 
            request.setHeader('Content-Type', 'application/json'); 
            
            response = h.send(request); 
                   
            Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            c.id = String.ValueOf(meta.get('id'));
            c.invoiceNum = String.valueOf(meta.get('invoiceNum'));
            c.invoiceDt = (meta.get('invoiceDt')!=null) ? String.valueOf(meta.get('invoiceDt')) : 'N/A';
            c.billingAccountNum = (meta.get('billingAccountNum')!=null) ? String.valueOf(meta.get('billingAccountNum')) : 'N/A';
            c.balanceForwardAmt = (meta.get('balanceForwardAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('balanceForwardAmt'))).setScale(2)) : 'N/A';
            c.paymentReceivedAmt = (meta.get('paymentReceivedAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('paymentReceivedAmt'))).setScale(2)) : 'N/A';
            c.paymentDueDt = (meta.get('paymentDueDt')!=null) ? String.valueOf(meta.get('paymentDueDt')) : 'N/A';
            c.lastPaymentDt = (meta.get('lastPaymentDt')!=null) ? String.valueOf(meta.get('lastPaymentDt')) : 'N/A';
            c.adjustmentAmt = (meta.get('adjustmentAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('adjustmentAmt'))).setScale(2)) : 'N/A';
            c.discountAmt = (meta.get('discountAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('discountAmt'))).setScale(2)) : 'N/A';
            c.netAmt = (meta.get('netAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('netAmt'))).setScale(2)) : 'N/A';
            c.gstAmt = (meta.get('gstAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('gstAmt'))).setScale(2)) : 'N/A';
            c.pstAmt = (meta.get('pstAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('pstAmt'))).setScale(2)) : 'N/A';
            c.hstAmt = (meta.get('hstAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('hstAmt'))).setScale(2)) : 'N/A';
            c.lpcAmt = (meta.get('lpcAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('lpcAmt'))).setScale(2)) : 'N/A';
            c.gstAdjustmentAmt = (meta.get('gstAdjustmentAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('gstAdjustmentAmt'))).setScale(2)) : 'N/A';
            c.pstAdjustmentAmt = (meta.get('pstAdjustmentAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('pstAdjustmentAmt'))).setScale(2)) : 'N/A';
            c.hstAdjustmentAmt = (meta.get('hstAdjustmentAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('hstAdjustmentAmt'))).setScale(2)) : 'N/A';
            c.lpcReversalAmt = (meta.get('lpcReversalAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('lpcReversalAmt'))).setScale(2)) : 'N/A';
            c.balanceDueAmt = (meta.get('balanceDueAmt')!=null) ? String.valueOf(Decimal.valueOf(String.valueOf(meta.get('balanceDueAmt'))).setScale(2)) : 'N/A';
            c.billerPlatform = (meta.get('billerPlatform')!=null) ? String.valueOf(meta.get('billerPlatform')) : 'N/A';
            return c;    
        } catch (Exception e){
        	System.debug('Unable to get Customer Invoice Detail: ' + e.getMessage());  
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Unable to get Customer Invoice Detail: ' + e.getMessage()); 
			ApexPages.addMessage(myMsg); 
            return c;    
        }
        
    }
    
    public class Content{
     	public String id {get;set;}
        public String invoiceNum  {get;set;}
        public String invoiceDt {get;set;}
        public String billingAccountNum {get;set;}
        public String balanceForwardAmt {get;set;}
        public String paymentReceivedAmt {get;set;}
        public String paymentDueDt {get;set;}
        public String lastPaymentDt {get;set;}
        public String adjustmentAmt {get;set;}
		public String discountAmt {get;set;}
        public String netAmt {get;set;}
        public String gstAmt {get;set;}
        public String pstAmt {get;set;}
        public String hstAmt {get;set;}
        public String lpcAmt {get;set;}
        public String gstAdjustmentAmt {get;set;}
        public String pstAdjustmentAmt {get;set;}
        public String hstAdjustmentAmt {get;set;}
        public String lpcReversalAmt {get;set;}
        public String balanceDueAmt {get;set;}
        public String billerPlatform {get;set;}
    }
}