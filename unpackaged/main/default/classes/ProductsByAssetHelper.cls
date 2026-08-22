public with sharing class ProductsByAssetHelper {

    public static void updateName(List<Id> assetsIds, List<ELM_Products_by_Asset__c> productsByAsset) {
        
        List<Asset> assets = [

            SELECT Id, Name
            FROM Asset
            WHERE Id IN : assetsIds

        ];

        Map<Id, Asset> assetsById = new Map<Id, Asset>(assets);

        for (ELM_Products_by_Asset__c prodByAsset : productsByAsset) {

            if(assetsById.containsKey(prodByAsset.ELM_Asset__c)){

                prodByAsset.Name = assetsById.get(prodByAsset.ELM_Asset__c).Name;

            }
 
        }

    }
}