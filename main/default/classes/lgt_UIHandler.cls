/*
* @Author: Smithdeendra A P
* @Created Date: 18-Jun-2019
* @Modified Date: 18-Jun-2019
* @TestClass: lgt_DataFactory_Test
* Version     JIRA                  Author                        Comments
* 1.0         SEAL-2934            Smithdeendra A P              Initial Comments  
* 1.1         SEAL-3030/3031       Smithdeendra A P              Create method placeLocationOnHOld & takeLocationOffHold.
*/
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

    @AuraEnabled
    public static lgt_ManageLocationProductsController placeLocationOnHOld(lgt_ManageLocationProductsController inputObject, String locationId) {
        try{ 
            inputObject.placeOnHold(locationId);
            return inputObject;
        }
        catch(Exception e){
            System.debug(Logginglevel.ERROR, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static lgt_ManageLocationProductsController takeLocationOffHold(lgt_ManageLocationProductsController inputObject, String locationId) {
        try{ 
            inputObject.takeOffHold(locationId);
            return inputObject;
        }
        catch(Exception e){
            System.debug(Logginglevel.ERROR, e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }


     
    // public static void superCheck(lgt_ManageLocationProductsController inputObject) {
    //     try{ 
    //         System.debug('before');
    //         System.debug('before =>'+inputObject);
    //        //inputObject.placeOnHold(locationId);
    //        System.debug('after');
    //         //return inputObject;
    //     }
    //     catch(Exception e){
    //         System.debug(Logginglevel.ERROR, e.getMessage());
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }
    // public class uiWrapper{
    //     @AuraEnabled
    //     public  Map<String,lgt_ManageLocationProductsController> sampleMap {get;set;}
    //     public uiWrapper(Id OppId){
    //         this.sampleMap = new Map<String,lgt_ManageLocationProductsController>();
    //         this.sampleMap.put('Controller',new lgt_ManageLocationProductsController(OppId));
    //     }
    // }
}