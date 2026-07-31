public with sharing class CreateProductsByVaesController {
    @AuraEnabled
    public static List<Product2> getProductResults(List<String> selectedProductsIds, String filter, String vaes) {
        String searchFilter = '%'+filter+'%';



       return [
    SELECT Id, Name, ProductCode, Description
    FROM Product2
    WHERE Id NOT IN (
        SELECT ELM_Product__c
        FROM ELM_ProductsByVAES__c
        WHERE ELM_VAES__c = :vaes
    )
    AND (
        Name LIKE :searchFilter
        OR ProductCode LIKE :searchFilter
    )
    AND (
        Id NOT IN :selectedProductsIds
    )
];
       
       
    }

    @AuraEnabled
    public static void createJunctionRegisters(String name, String isoCode, String vaes, List<String> selectedProductsIds){

        List<ELM_ProductsByVAES__c> resultList = new List<ELM_ProductsByVAES__c>();
    
        for(String prodId : selectedProductsIds){
            ELM_ProductsByVAES__c junctionRegister = new ELM_ProductsByVAES__c(
                Name = name,
                CurrencyIsoCode = isoCode,
                ELM_VAES__c = vaes,
                ELM_Product__c = prodId 
            );
            resultList.add(junctionRegister);
        }
        insert resultList;

    }
}