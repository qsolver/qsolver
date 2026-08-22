public class createAssetsByMaintenance {
    @AuraEnabled
    public static List<Asset> getAssetsResults(List<String> selectedAssetsIds, String filter, String maintenanceId) {

        String searchFilter = '%'+filter+'%';

        Maintenance__c mtn = [SELECT Id, Name, Account__c FROM Maintenance__c WHERE Id =: maintenanceId LIMIT 1];

        return [
            SELECT Id, Name, ELM_ExternalId__c
            FROM Asset 
            WHERE ( Name LIKE :searchFilter 
            AND Id NOT IN :selectedAssetsIds) AND AccountId = :mtn.Account__c 
            
        ];

    }

    @AuraEnabled
    public static void createJunctionRegisters(String name, String maintenance, List<String> selectedAssetsIds){

        List<Asset_by_Maintenance__c> resultList = new List<Asset_by_Maintenance__c>();
        
    
        for(String assetId : selectedAssetsIds){
                Asset_by_Maintenance__c junctionRegister = new Asset_by_Maintenance__c(
                Maintenance__c = maintenance,
                Asset__c = assetId 
            );
           
            resultList.add(junctionRegister);
        }
       
        insert resultList;

    }
}