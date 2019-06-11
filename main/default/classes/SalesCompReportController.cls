public class SalesCompReportController{
    public Boolean requestSent {get; set;}
    public Date startDate{get;set;}
    public Date endDate{get;set;}    

    public SalesCompReportController() {
        requestSent = false;
    }

    public void generateReport(){
        ReportHelper.generateReport(startDate, endDate, false);            
        requestSent = true;
    }
    
    public void generateReportForSplit(){
        ReportHelper.generateReport(startDate, endDate, true);
        requestSent = true;
    }
    

}