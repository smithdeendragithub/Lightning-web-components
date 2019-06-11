global class BuildingEndPoint {

    webservice static List<Building__c> GetBuildingByCLLI(string buildingCLLI){
        
        return [Select Id, Address__c, city__c,Is_Serving_LSO__c, Building_Type__c,net_classification__C, (select Maximum_Bandwidth__c, Minimum_Required_Revenue__c, Access_Technology__c from Access_Availabilities__r) from Building__c where Building_CLLI__c = :buildingCLLI];
        
    }

	webservice static Building__c GetBuildingByHash(string buildingHash){
        
        return AddressUtils.GetBuildingByHash(buildingHash);
        
    }

    //webservice static List<Building__c> GetBuildingByCLLIBasic(string buildingCLLI){
    //    return [Select Id, Address__c, city__c,Is_Serving_LSO__c, Building_Type__c from Building__c where Building_CLLI__c  = :buildingCLLI];
    //}


    
}