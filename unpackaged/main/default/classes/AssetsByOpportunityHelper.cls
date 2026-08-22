public with sharing class AssetsByOpportunityHelper {

    public static void updateName(List<Id> opportunitiesId, List<Assets_by_Opportunity__c> assetsByOpportunities) {

        List<Opportunity> opportunities = [
                SELECT Id, Name
                FROM Opportunity
                WHERE Id IN : opportunitiesId
                WITH SECURITY_ENFORCED
            ];

        Map<Id, Opportunity> opportunitiesById = new Map<Id, Opportunity>(opportunities);

        for (Assets_by_Opportunity__c assetByOpp : assetsByOpportunities) {

            if (opportunitiesById.containsKey(assetByOpp.Opportunity__c)) {

                assetByOpp.Name = opportunitiesById.get(assetByOpp.Opportunity__c).Name;
                
            }
            
        }

        
    }

}