public class TeamSellRequestControllerExtension {
    private final Team_Sell_Request__c tsr;
    public TeamSellRequestControllerExtension(ApexPages.StandardController stdController){
        this.tsr = (Team_Sell_Request__c)stdController.getRecord();
        if (tsr.Requestor__c == null){
            tsr.Requestor__c = UserInfo.getUserId();
        }
    }
}