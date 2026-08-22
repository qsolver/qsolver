trigger Product2Trigger on Product2 (after insert, after update, before insert, before update) {
    
    Product2TriggerHandler handler = new Product2TriggerHandler(Trigger.isExecuting, Trigger.size);
    
    if( Trigger.isInsert ){
        if(Trigger.isBefore) {
            //handler.OnBeforeInsert(trigger.New);
        }
        else {
            if(trigger.New[0].ELM_ASSETS__c != null){
                handler.OnAfterInsert(trigger.New);
            }
        }
    }
    else if ( Trigger.isUpdate ) {
        if(Trigger.isBefore){
            //handler.OnBeforeUpdate(trigger.New ,trigger.Old,Trigger.NewMap,Trigger.OldMap);
        }
        else{
            if(trigger.New[0].ELM_ASSETS__c != null){
                handler.OnAfterUpdate(trigger.New ,trigger.Old,Trigger.NewMap,Trigger.OldMap);
            }
        }
    }    
    
}