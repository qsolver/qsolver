public with sharing class createVAESByOpportunity {
    
    @AuraEnabled
    public static List<ELM_Vaes__c> getVAESResults(List<String> selectedVAESIds, String filter, String opportunityId) {

        String searchFilter = '%'+filter+'%';

        Opportunity opp = [
            SELECT AccountId
            FROM Opportunity
            WHERE Id =: opportunityId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return [
            SELECT Id, ELM_Project_Name__c, Name 
            FROM ELM_Vaes__c 
            WHERE ( (ELM_Project_Name__c LIKE :searchFilter OR Name LIKE :searchFilter) 
            AND Id NOT IN :selectedVAESIds 
            AND ELM_Account__c =: opp.AccountId )
            WITH SECURITY_ENFORCED
        ];

    }

    @AuraEnabled
    public static List<OpportunityLineItem> getOpportunityProducts(String opportunityId) {


        return [SELECT Id,Product2.Id, Product2.Name, Product2.ProductCode FROM OpportunityLineItem  where OpportunityId =:opportunityId WITH SECURITY_ENFORCED];

    }

    @AuraEnabled
    public static void createProductByVAESJunctionRegisters(List<String> selectedProductIds, List<String> selectedVAESIds, String opportunityId) {

        List<ELM_ProductsByVAES__c> resultList = new List<ELM_ProductsByVAES__c>();
        Opportunity opp = [SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id =:opportunityId LIMIT 1];

        List<Product2> selectedProducts = [
            SELECT Id, Name
            FROM Product2 
            WHERE Id IN :selectedProductIds
            WITH SECURITY_ENFORCED
        ];

        for(String vs : selectedVAESIds){
            for(Product2 prd : selectedProducts){
                ELM_ProductsByVAES__c junctionRegister = new ELM_ProductsByVAES__c(
                    Name = prd.Name,
                    CurrencyIsoCode = opp.CurrencyIsoCode,
                    ELM_VAES__c = vs,
                    ELM_Product__c = prd.Id
                );
                System.debug('Name variable Apex VAES jusctionObject: '+junctionRegister);
                resultList.add(junctionRegister);
            }
        }

        System.debug('resultList => '+resultList);

        if(resultList.size() > 0){
            insert resultList;
        }

    }



    @AuraEnabled
    public static void createJunctionRegisters(String name,String opportunity, List<String> selectedVAESIds){

        List<VAES_by_Opportunity__c> resultList = new List<VAES_by_Opportunity__c>();
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id =:opportunity LIMIT 1];
    
        for(String vsId : selectedVAESIds){
            VAES_by_Opportunity__c junctionRegister = new VAES_by_Opportunity__c(
                Name = opp.Name,
                Opportunity__c = opportunity,
                VAES__c = vsId 
            );
            System.debug('Name variable Apex VAES jusctionObject: '+junctionRegister);
            resultList.add(junctionRegister);
        }
        System.debug('jusctionObject List VAES: '+resultList);
        insert resultList;

    }
}