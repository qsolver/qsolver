trigger AccountsByOpportunityTrigger on Accounts_by_Opportunity__c (before insert) {
    
    if(Trigger.isBefore){

        if(Trigger.isInsert){

            List<Id> opportunitiesIds = new List<Id>();

            for (Accounts_by_Opportunity__c accountByOpp : Trigger.new) {
                
                opportunitiesIds.add(accountByOpp.Opportunity__c);

            }

            AccountsByOpportunityHelper.updateName(opportunitiesIds, Trigger.new);

        }
    }
}