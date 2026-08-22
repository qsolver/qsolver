trigger OpportunityTrigger on Opportunity (before insert, before update) {

    if (Trigger.isBefore) {

        if (Trigger.isInsert) {

            Map<Id, Account> accounts = new Map<Id, Account>();

            for (Opportunity opportunity : Trigger.new) {
                
                accounts.put(Opportunity.AccountId, null);
            }

            OpportunityHelper.validateInsertionByUser(Trigger.new, accounts);           
        }else if (Trigger.isUpdate) {
            
            Map<Id, Opportunity> opportunitiesByIdOld = new Map<Id, Opportunity>(Trigger.old);
            OpportunityHelper.validateProducts(opportunitiesByIdOld, Trigger.new);
        }    
    }
}