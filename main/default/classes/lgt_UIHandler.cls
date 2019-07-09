/*
* @Author: Smithdeendra A P
* @Created Date: 18-Jun-2019
* @Modified Date: 8-July-2019
* @TestClass: lgt_DataFactory_Test
* Version     JIRA                  Author                        Comments
* 1.0         SEAL-2934            Smithdeendra A P              Initial Comments  
* 1.1         SEAL-3030/3031       Smithdeendra A P              Create method placeLocationOnHOld & takeLocationOffHold.
* 1.2         SEAL-2801            Smithdeendra A P              Create method setProviders.
*/
public with sharing class lgt_UIHandler {
    @AuraEnabled (cacheable=true)
    public static lgt_ManageLocationProductsController retrieveWrapperData(String opportunityId) {
        try{ 
           lgt_ManageLocationProductsController testRec =  new lgt_ManageLocationProductsController(opportunityId);
         
            return testRec;
        }
        catch(Exception e){
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
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void setProviders(string oppLocID, string ldProvider, string localProvider, string tfProvider) {
        try{ 
            lgt_ManageLocationProductsController.setProviders(oppLocID,ldProvider,localProvider,tfProvider);
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }    

}