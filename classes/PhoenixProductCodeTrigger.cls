public without sharing class PhoenixProductCodeTrigger{
   
   public static void PhoenixProductCodeModified (List<Phoenix_Product_Code__c> tNew, List<Phoenix_Product_Code__c> tOld, Boolean isUpdate, Boolean isBefore, Boolean isDelete){
       if(!ApexUtils.executeTriggerMethods('Phoenix_Product_Code__c', isBefore, isDelete)) return;
       
       if(isBefore){
        }
        else{
            Map<Id, Phoenix_Product_Code__c> tOldMap = tOld != null ? new Map<Id, Phoenix_Product_Code__c>(tOld) : new Map<Id, Phoenix_Product_Code__c>();
            if(!isUpdate && !isDelete){
                List<String> phoenixProductCode = new List<String>();
                for(Phoenix_Product_Code__c pc : tNew){
                   phoenixProductCode.add(pc.Name+'-'+pc.Product_Code_Value__c);
                }
                updateBSBProductCode(phoenixProductCode);
            }
            
            ApexUtils.afterTriggerComplete('Phoenix_Product_Code__c', isDelete);
        }
   }
   @future(callout=true)
   public static void updateBSBProductCode(List<String> phoenixProductCode){
        MetadataService.MetadataPort service = createService();
        MetadataService.CustomField customField = new MetadataService.CustomField();
        customField.fullName = 'BSB_Discount_Product__c.Product_Code__c';
        customField.label = 'picklist';
        customField.type_x = 'Picklist';
        metadataservice.Picklist pt = new metadataservice.Picklist();
        pt.sorted= false;
        
        List<metadataservice.PicklistValue> listValues= new list<metadataservice.PicklistValue>();
        MetadataService.PicklistValue custValue= null;
        for(String pc : phoenixProductCode){
            custValue = new MetadataService.PicklistValue();                      
            custValue.fullName = pc;  
            custValue.default_x = false;
            
            listValues.add(custValue);  
        }

        pt.picklistValues = listValues;
        customField.picklist = pt ;
        List<MetadataService.SaveResult> results =
            service.updateMetadata(
                new MetadataService.Metadata[] { customField });
           if(results!= null && results[0] !=null && !results[0].success && results[0].errors!=null){
              system.debug('Error occured processing component ' + results[0].fullName + '.:'+results[0].errors);
           }
                
   }
    private static MetadataService.MetadataPort createService(){ 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();

        return service;     
    }
}