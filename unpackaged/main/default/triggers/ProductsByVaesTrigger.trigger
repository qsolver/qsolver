trigger ProductsByVaesTrigger on ELM_ProductsByVAES__c (before insert) {

    if(Trigger.isBefore){

        if(Trigger.isInsert){

            List<Id> vaesIds = new List<Id>();

            for (ELM_ProductsByVAES__c productByVaes : Trigger.new) {
                
                vaesIds.add(productByVaes.ELM_VAES__c);

            }

            ProductsByVaesHelper.updateName(vaesIds, Trigger.new);

        }

    }

}