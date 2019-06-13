@isTest(SeeAllData=true)
global class Test_CustomerInvoice {
    public static testMethod void testCustomerInvoiceController() {
    	PageReference pageRef = Page.CustomerInvoices;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id','a1h0h00000553R7AAI');
        ApexPages.currentPage().getParameters().put('name','BOOTLEGGER%20(COMARK)%20INC.');
        //Portal_Web_Service__c objWS = new Portal_Web_Service__c();
        //objWS.Name = 'Allstream Token';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        CustomerInvoiceController controller = new CustomerInvoiceController();
        controller.getInvoices(controller.token, '?account=a1h0h00000553R7AAI');
        controller.refreshTable();
        
    }
    
    public static testMethod void testCustomerInvoiceDetailController() {
        test.startTest();
    	PageReference pageRef = Page.CustomerInvoiceDetail;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id','335051');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        CustomerInvoiceDetailController controller = new CustomerInvoiceDetailController();
        CustomerInvoiceDetailController.Content c = controller.getInvoiceDetail(controller.token);   
        
    }
    
    public static testMethod void testInvoiceDownloadController(){
        test.startTest();
    	PageReference pageRef = Page.DownloadPDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('invoiceID','335051');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        InvoiceDownloadController controller = new InvoiceDownloadController();
        String pdfJSON = controller.getPDFString();
        
    }
    
 
    global class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            //System.assertEquals('https://auth.dev.portal.allstreamit.net/token/endpoint', req.getEndpoint());
            //System.assertEquals('POST', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint() == 'http://core.dev.portal.allstreamit.net/api/v1/invoices?account=a1h0h00000553R7AAI'){
                res.setBody('{   "content": [   {      "id": 335051,      "invoiceNum": "IES75322",      "invoiceDt": "2018-05-01",      "billingAccountNum": "120773",      "balanceForwardAmt": 15924.38,      "paymentReceivedAmt": -15924.38,      "paymentDueDt": "2018-05-31",      "lastPaymentDt": null,      "balanceDueAmt": 7825.25   }],   "last": false,   "totalPages": 53,   "totalElements": 53,   "sort": [   {      "direction": "DESC",      "property": "invoiceDt",      "ignoreCase": false,      "nullHandling": "NATIVE",      "ascending": false,      "descending": true   }],   "first": true,   "numberOfElements": 1,   "size": 1,   "number": 0}');
            } else if (req.getEndpoint() == 'https://auth.dev.portal.allstreamit.net/token/endpoint'){
                res.setBody('{"access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsib2F1dGgyLXJlc291cmNlIl0sInVzZXJfbmFtZSI6ImN0YXlsb3JAbXRjY2MuY29tIiwidXNlcl9kZXRhaWxzIjp7ImZpcnN0TmFtZSI6IkJpbGwiLCJsYXN0TmFtZSI6Ik1jRG9uYWxkIn0sInNjb3BlIjpbInRydXN0Il0sImV4cCI6MTUyNjQ1NzY3OCwianRpIjoiMzE3ZWQ5N2UtYTZhYy00MjhjLTlkNjYtZjE3YmU0ZGI2NTk4IiwiY2xpZW50X2lkIjoicG9ydGFsLWNvcmUifQ.rd6jH7tIy1mIx95tQ6Y4jlyPURJwpb8guW3nKJxssxQ",   "token_type": "bearer",   "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsib2F1dGgyLXJlc291cmNlIl0sInVzZXJfbmFtZSI6ImN0YXlsb3JAbXRjY2MuY29tIiwidXNlcl9kZXRhaWxzIjp7ImZpcnN0TmFtZSI6IkJpbGwiLCJsYXN0TmFtZSI6Ik1jRG9uYWxkIn0sInNjb3BlIjpbInRydXN0Il0sImF0aSI6IjMxN2VkOTdlLWE2YWMtNDI4Yy05ZDY2LWYxN2JlNGRiNjU5OCIsImV4cCI6MTUyOTAwNjQ3OCwianRpIjoiZDdhMGEwMTctMjMxNy00MzYyLThhODgtNDJjZTAyZGRkZTY3IiwiY2xpZW50X2lkIjoicG9ydGFsLWNvcmUifQ.TMjqFP1BMlgIvxjt4ItXazeBe6AqpAVyXkFTmeJqZ5I",   "expires_in": 43199,   "scope": "trust",   "jti": "317ed97e-a6ac-428c-9d66-f17be4db6598"}');
            }
            else if (req.getEndpoint() == 'http://core.dev.portal.allstreamit.net/api/v1/invoices/a1h0h00000553R7AAI'){
            	res.setBody('{   "id": 335051,   "invoiceNum": "IES75322",   "invoiceDt": "2018-05-01",   "billingAccountNum": "120773",   "balanceForwardAmt": 15924.38,   "paymentReceivedAmt": -15924.38,   "paymentDueDt": "2018-05-31",   "lastPaymentDt": null,   "adjustmentAmt": null,   "discountAmt": null,   "netAmt": 6925,   "gstAmt": 0,   "pstAmt": 0,   "hstAmt": 900.25,   "lpcAmt": 0,   "gstAdjustmentAmt": null,   "pstAdjustmentAmt": null,   "hstAdjustmentAmt": null,   "lpcReversalAmt": 0,   "balanceDueAmt": 7825.25,   "billerPlatform": "ASAP"}');
            }
            else {
                res.setBody('{   "content": [   {      "id": 335051,      "invoiceNum": "IES75322",      "invoiceDt": "2018-05-01",      "billingAccountNum": "120773",      "balanceForwardAmt": 15924.38,      "paymentReceivedAmt": -15924.38,      "paymentDueDt": "2018-05-31",      "lastPaymentDt": null,      "balanceDueAmt": 7825.25   }],   "last": false,   "totalPages": 53,   "totalElements": 53,   "sort": [   {      "direction": "DESC",      "property": "invoiceDt",      "ignoreCase": false,      "nullHandling": "NATIVE",      "ascending": false,      "descending": true   }],   "first": true,   "numberOfElements": 1,   "size": 1,   "number": 0}');
            }
            res.setStatusCode(200);
            
            return res;
        }
    }

}