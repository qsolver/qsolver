public with sharing class AccountsByOpportunityHelper {

    public static void updateName(List<Id> opportunitiesIds, List<Accounts_by_Opportunity__c> accountsByOpportunities) {

        List<Opportunity> opps = [
                SELECT Id, Name
                FROM Opportunity
                WHERE Id IN : opportunitiesIds
                WITH SECURITY_ENFORCED
            ];

        Map<Id, Opportunity> opportunitiesById = new Map<Id, Opportunity>(opps);

        for (Accounts_by_Opportunity__c accByOpp : accountsByOpportunities) {

            if(opportunitiesById.containsKey(accByOpp.Opportunity__c)){

                accByOpp.Name = opportunitiesById.get(accByOpp.Opportunity__c).Name;

            }
            
        }
        
    }

}