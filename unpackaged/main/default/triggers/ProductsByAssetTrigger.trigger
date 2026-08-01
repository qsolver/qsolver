trigger ProductsByAssetTrigger on ELM_Products_by_Asset__c (before insert) {

    if(Trigger.isBefore){

        if (Trigger.isInsert) {

            List<Id> assetsIds = new List<Id>();

            for (ELM_Products_by_Asset__c productByAsset : Trigger.new) {

                assetsIds.add(productByAsset.ELM_Asset__c);
                
            }

            ProductsByAssetHelper.updateName(assetsIds, Trigger.new);
            
        }

    }

}