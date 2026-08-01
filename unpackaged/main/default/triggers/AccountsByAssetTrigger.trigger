trigger AccountsByAssetTrigger on ELM_Accounts_By_Asset__c (before insert) {

    if(Trigger.isBefore){

        if(Trigger.isInsert){

            List<Id> assetsId = new List<Id>();

            for (ELM_Accounts_By_Asset__c accByAsset : Trigger.new) {

                assetsId.add(accByAsset.Asset__c);
                
            }

            AccountsByAssetHelper.updateName(assetsId, Trigger.new);

        }

    }

}