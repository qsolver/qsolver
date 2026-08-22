trigger AssetsByOpportunityTrigger on Assets_by_Opportunity__c (before insert) {

    if(Trigger.isBefore){

        if(Trigger.isInsert){

            List<Id> opportunitiesId = new List<Id>();

            for (Assets_by_Opportunity__c assetByOpportunity : Trigger.new) {

                opportunitiesId.add(assetByOpportunity.Opportunity__c);
                
            }

            AssetsByOpportunityHelper.updateName(opportunitiesId, Trigger.new);
        }

    }

}