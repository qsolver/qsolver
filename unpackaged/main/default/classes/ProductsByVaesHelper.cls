public with sharing class ProductsByVaesHelper {

    public static void updateName(List<Id> vaesIds, List<ELM_ProductsByVAES__c> productsByVaes) {
        
        List<ELM_Vaes__c> vaes = [

            SELECT Name
            FROM ELM_Vaes__c
            WHERE Id IN : vaesIds

        ];

        Map<Id, ELM_Vaes__c> vaesById = new Map<Id, ELM_Vaes__c>(vaes);

        for (ELM_ProductsByVAES__c productByVaes : productsByVaes) {
            
            if (vaesById.containsKey(productByVaes.ELM_VAES__c)) {

                productByVaes.Name = vaesById.get(productByVaes.ELM_VAES__c).Name;
                
            }

        }

    }

}