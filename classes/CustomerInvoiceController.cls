public class CustomerInvoiceController {
    public List<Content> contentList {get;set;}
    public String token {get;set;}
    public String serviceLocationID {get;set;}
    public String serviceLocationName {get;set;}
    public String totalElements {get;set;}
    public String numberOfPages {get;set;}
    public String selectedPage {get;set;}
    public String selectedSearchBy {get;set;}
    public String selectedSortDirection {get;set;}
    
    public CustomerInvoiceController(){
        serviceLocationID = Apexpages.currentPage().getParameters().get('id');
        serviceLocationName = Apexpages.currentPage().getParameters().get('name');
        token = getToken();
        numberOfPages = '0';
        totalElements = '0';
       	//getInvoices(token, '?account=' + accountID + '&size=1'); 
        //contentList.clear();
    }
   
    public String getToken(){
        Portal_Web_Service__c objWS = Portal_Web_Service__c.getValues('Allstream Token');
        String token; 
        String endpoint = objWS.End_Point__c; // be sure this is configured in "Remote Site Settings" 
        String resource = objWS.Resource__c; 
        String username = objWS.Username__c;  
        String password = objWS.Password__c; 
        String method = 'POST';   
        
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
        }
        catch(Exception e){
        	System.debug('Unable to get token from ' + endpoint + resource);  
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Unable to get token from ' + endpoint + resource); 
			ApexPages.addMessage(myMsg); 
            return '';
        }
	}
    
    public void getInvoices(String token, String parameters){
        Portal_Web_Service__c objWS = Portal_Web_Service__c.getValues('Allstream Invoices');
        string endpoint = objWS.End_Point__c; // be sure this is configured in "Remote Site Settings" 
        string resource = objWS.Resource__c; 
        //string parameters = '?account=' + accountID;
        string method = 'GET';   
        try{
        	HttpRequest request = new HttpRequest(); 
            HttpResponse response = new HttpResponse(); 
            Http h = new Http(); 
            
            request.setEndpoint(endpoint + resource + parameters); 
            request.setMethod(method); 
            request.setTimeout(120000); 
            request.setHeader('Authorization', 'bearer ' + token);             
            request.setHeader('Accept', '*/*'); 
            request.setHeader('Content-Type', 'application/json'); 
            
            response = h.send(request); 
                   
            Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (meta.get('error') == null){
            	totalElements = String.ValueOf(meta.get('totalElements'));
            numberOfPages = String.ValueOf(meta.get('totalPages'));
            List<Object> contents = (List<Object>) meta.get('content');
                    
            contentList = new List<Content>();
            for (Object obj : contents){
                Map<String, Object> m = (Map<String, Object>) obj;
                Content c = new Content();
                c.id = String.ValueOf(m.get('id'));
                c.invoiceNum = String.valueOf(m.get('invoiceNum'));
                c.invoiceDt = String.valueOf(m.get('invoiceDt'));
                c.billingAccountNum = String.valueOf(m.get('billingAccountNum'));
                c.balanceForwardAmt = String.valueOf(m.get('balanceForwardAmt'));
                c.paymentReceivedAmt = String.valueOf(m.get('paymentReceivedAmt'));
                c.paymentDueDt = String.valueOf(m.get('paymentDueDt'));
                c.lastPaymentDt = String.valueOf(m.get('lastPaymentDt'));
                c.balanceDueAmt = String.valueOf(m.get('balanceDueAmt'));
                c.netAmt = String.valueOf(m.get('netAmt'));
				c.gstAmt = String.valueof(m.get('gstAmt'));
				c.pstAmt = String.valueOf(m.get('pstAmt'));
				c.hstAmt = String.valueOf(m.get('hstAmt'));
				c.lpcAmt = String.valueOf(m.get('lpcAmt'));
                c.URL = 'apex/DownloadPDF?invoiceID=' + c.id;
                contentList.add(c);
            }    
            }
                
        }
        catch (Exception e){
            contentList = new List<Content>();
            System.debug('Unable to get invoices: ' + e.getMessage());
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Unable to get invoices: ' + e.getMessage()); 
			ApexPages.addMessage(myMsg); 
        }
    }
    
    public void refreshTable(){
        getInvoices(token,'?account=' + serviceLocationID + '&size=200' + '&fromDate=' + Apexpages.currentPage().getParameters().get('fromDate') + '&toDate=' + Apexpages.currentPage().getParameters().get('toDate') + '&page=' + selectedPage + '&sort=' + selectedSearchBy + ',' + selectedSortDirection);    
    }
        
    public List<SelectOption> getPageItems() { 
        List<SelectOption> options = new List<SelectOption>();
        for (Integer i=0; i < Integer.valueOf(numberOfPages); i++){
        	options.add(new SelectOption(String.valueOf(i),String.valueOf(i+1)));    
        }
        return options; 
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
        public String balanceDueAmt {get;set;}
        public String URL {get;set;}
        public String netAmt {get;set;}
        public String gstAmt {get;set;}
        public String pstAmt {get;set;}
        public String hstAmt {get;set;}
        public String lpcAmt {get;set;}
    }
     
}