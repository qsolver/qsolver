public with sharing class createAssetsByOpportunity {
    
    @AuraEnabled
    public static List<Asset> getAssetsResults(List<String> selectedAssetsIds, String filter, String opportunityId) {

        String searchFilter = '%'+filter+'%';

        Opportunity opp = [
            SELECT AccountId
            FROM Opportunity
            WHERE Id =: opportunityId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return [
            SELECT Id, Name, ELM_ExternalId__c
            FROM Asset 
            WHERE ( Name LIKE :searchFilter 
            AND Id NOT IN :selectedAssetsIds 
            AND AccountId =: opp.AccountId )
            WITH SECURITY_ENFORCED
        ];

    }

    @AuraEnabled
    public static void createJunctionRegisters(String isoCode, String opportunity, List<String> selectedAssetsIds){

        List<Assets_by_Opportunity__c> resultList = new List<Assets_by_Opportunity__c>();

        Opportunity selectedOpportunity = [SELECT Id, Opportunity_Number__c FROM Opportunity WHERE Id =: opportunity LIMIT 1];

        System.debug('Opp Number => '+selectedOpportunity.Opportunity_Number__c);
        
    
        for(String accId : selectedAssetsIds){
                Assets_by_Opportunity__c junctionRegister = new Assets_by_Opportunity__c(
                Name = selectedOpportunity.Opportunity_Number__c,
                CurrencyIsoCode = isoCode,
                Opportunity__c = opportunity,
                Asset__c = accId 
            );
           
            resultList.add(junctionRegister);
        }


       System.debug('resultList => '+resultList);
        insert resultList;

    }
}