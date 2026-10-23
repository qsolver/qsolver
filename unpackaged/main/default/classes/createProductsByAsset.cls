public with sharing class createProductsByAsset {

    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductResults(List<String> selectedProductsIds, String filter) {

        String searchFilter = '%'+filter+'%';

        Pricebook2 pricebook = [
            SELECT Id
            FROM Pricebook2
            WHERE IsStandard = TRUE
                AND IsActive = TRUE
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

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
    public static void createJunctionRegisters(
        String name,
        String isoCode,
        String asset,
        List<String> selectedProductsIds,
        List<String> industryRequirements,
        String recordTypeId
    ){
        System.debug('Name : '      + name);
        System.debug('IsoCode : '   + isoCode);
        System.debug('Asset : '     + asset);
        System.debug('Products : '  + selectedProductsIds);
        System.debug('IndustryRequirements : ' + industryRequirements);
        System.debug('RecordType : '+ recordTypeId);

        List<ELM_Products_by_Asset__c> resultList = new List<ELM_Products_by_Asset__c>();

        for (Integer i = 0; i < selectedProductsIds.size(); i++) {

            ELM_Products_by_Asset__c junctionRegister = new ELM_Products_by_Asset__c(
                Name            = name,
                CurrencyIsoCode = isoCode,
                ELM_Asset__c    = asset,
                ELM_Product__c  = selectedProductsIds[i]
            );

            if (String.isNotBlank(recordTypeId)) {
                junctionRegister.RecordTypeId = recordTypeId;
            }

            if (industryRequirements != null && i < industryRequirements.size() && String.isNotBlank(industryRequirements[i])) {
                junctionRegister.Requerimiento_industria__c = industryRequirements[i];
            }

            resultList.add(junctionRegister);
        }

        insert resultList;
    }
}