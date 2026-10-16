public with sharing class createProductsByAsset {

    @AuraEnabled
    public static List<Product2> getProductResults(List<String> selectedProductsIds, String filter) {
        String searchFilter = '%'+filter+'%';

        // Asset asset = [
        //     SELECT Id, AccountId
        //     FROM Asset
        //     WHERE Id = : assetId
        //     LIMIT 1
        // ];

        // Account account = [
        //     SELECT Price_Book__c
        //     FROM Account
        //     WHERE Id = : asset.AccountId
        //     LIMIT 1
        // ];
        Pricebook2 pricebook = [
            SELECT Id
            FROM Pricebook2
            WHERE IsStandard = TRUE
                AND IsActive = TRUE
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        List<PricebookEntry> priceBookEntries = [
            SELECT Product2Id
            FROM PricebookEntry
            WHERE Pricebook2Id = : pricebook.Id
            WITH SECURITY_ENFORCED
        ];

        Set<Id> productIds = new Set<Id>();

        for (PricebookEntry pricebookEntry : priceBookEntries) {

            productIds.add(pricebookEntry.Product2Id);

        }

        return [
            SELECT Id, Name 
            FROM Product2 
            WHERE (Name LIKE :searchFilter AND Id NOT IN :selectedProductsIds AND Id IN : productIds)
            OR (ProductCode LIKE :searchFilter AND Id NOT IN :selectedProductsIds AND Id IN : productIds)
            WITH SECURITY_ENFORCED
        ];
    }

    @AuraEnabled
    public static void createJunctionRegisters(String name, String isoCode, String asset, List<String> selectedProductsIds){

        List<ELM_Products_by_Asset__c> resultList = new List<ELM_Products_by_Asset__c>();
    
        for(String prodId : selectedProductsIds){
            ELM_Products_by_Asset__c junctionRegister = new ELM_Products_by_Asset__c(
                Name = name,
                CurrencyIsoCode = isoCode,
                ELM_Asset__c = asset,
                ELM_Product__c = prodId 
            );
            resultList.add(junctionRegister);
        }
        insert resultList;

    }
}