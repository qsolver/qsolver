trigger AssetTrigger on Asset (before insert, before update) {


    if (Trigger.isBefore) {

        if (Trigger.isInsert) {
            
            Map<Id, Account> accountsById = new Map<Id, Account>();

            for (Asset asset : Trigger.new) {
                
                accountsById.put(asset.AccountId, null);
            }

            AssetHelper.validateInsertionByUser(Trigger.new, accountsById);
        }else if(Trigger.isUpdate){

            AssetHelper.validateUpdateByUser(Trigger.new);
        }
        
    }
}