public with sharing class createProductsByAsset {

    @AuraEnabled
    public static List<Product2> getProductResults(List<String> selectedProductsIds, String filter) {

        //if (String.isBlank(filter) || filter.length() < 2) {
        //    return new List<Product2>();
       // }

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

        

        //return [
        //    SELECT Id, Name 
        //    FROM Product2 
        //    WHERE (Name LIKE :searchFilter AND Id NOT IN :selectedProductsIds AND Id IN : productIds)
        //    OR (ProductCode LIKE :searchFilter AND Id NOT IN :selectedProductsIds AND Id IN : productIds)
        //    WITH SECURITY_ENFORCED LIMIT 1000
        //];

        // Optimized query: Get Product2s that have entries in the standard pricebook
        return [
            SELECT Id, Name
            FROM Product2
            WHERE Id IN (
                SELECT Product2Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :pricebook.Id
            )
            AND Id NOT IN :selectedProductsIds
            AND (Name LIKE :searchFilter OR ProductCode LIKE :searchFilter)
            WITH SECURITY_ENFORCED
            LIMIT 20
        ];

        
    }

    @AuraEnabled
    public static void createJunctionRegisters(String name, String isoCode, String asset, List<String> selectedProductsIds){

        System.debug('Name : '+name);
        System.debug('IsoCode : '+isoCode);
        System.debug('Asset : '+asset);
        System.debug('Product : '+selectedProductsIds);

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