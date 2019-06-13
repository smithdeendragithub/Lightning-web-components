public with sharing class lgt_UIHandler {
 
   
    public lgt_UIHandler() {

    }

     @AuraEnabled (Cacheable=true)
    public static lgt_ManageLocationProductsController getWrapperData(String opportunityId) {
        lgt_ManageLocationProductsController mlpRecord = new lgt_ManageLocationProductsController(opportunityId);

        return mlpRecord;
    }

}
