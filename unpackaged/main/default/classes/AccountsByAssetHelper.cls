public with sharing class AccountsByAssetHelper {

    public static void updateName(List<Id> assetsIds, List<ELM_Accounts_By_Asset__c> accountsByAssets) {
        
        List<Asset> assets = [
                SELECT Id, Name
                FROM Asset
                WHERE Id IN : assetsIds
                WITH SECURITY_ENFORCED
            ];

        Map<Id, Asset> assetsById = new Map<Id, Asset>(assets);

        for (ELM_Accounts_By_Asset__c accountByAsset : accountsByAssets) {

            if(assetsById.containsKey(accountByAsset.Asset__c)){

                accountByAsset.Name = assetsById.get(accountByAsset.Asset__c).Name;

            }
            
        }

    }
}