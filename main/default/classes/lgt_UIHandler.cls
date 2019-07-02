public with sharing class lgt_UIHandler {
    @AuraEnabled (cacheable=true)
    public static lgt_ManageLocationProductsController retrieveWrapperData(String opportunityId) {
        //   uiWrapper mlpRecord;
        try{ 
            // uiWrapper mlpRecord = new uiWrapper(opportunityId);
           lgt_ManageLocationProductsController testRec =  new lgt_ManageLocationProductsController(opportunityId);
         
            return testRec;
        }
        catch(Exception e){
            System.debug(Logginglevel.ERROR, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled (cacheable=true)
    public static lgt_ManageLocationProductsController placeLocationOnHOld(lgt_ManageLocationProductsController inputObject, String locationId) {
        try{ 
           //inputObject.placeOnHold(locationId);
            return inputObject;
        }
        catch(Exception e){
            System.debug(Logginglevel.ERROR, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    // public class uiWrapper{
    //     @AuraEnabled
    //     public  Map<String,lgt_ManageLocationProductsController> sampleMap {get;set;}
    //     public uiWrapper(Id OppId){
    //         this.sampleMap = new Map<String,lgt_ManageLocationProductsController>();
    //         this.sampleMap.put('Controller',new lgt_ManageLocationProductsController(OppId));
    //     }
    // }
}