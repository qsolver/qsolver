trigger UpdateOpportunityLastModifiedByCustomField on Task (after insert, after update) {
    // Lista para almacenar los Ids de las oportunidades que necesitan actualización
    Set<Id> opportunityIds = new Set<Id>();
    
    // Consultar los Ids de los perfiles permitidos que pueden actualizar campo LastModifiedById desde TASK
    Set<Id> allowedProfileIds = new Set<Id>();
    for (Profile prof : [SELECT Id FROM Profile WHERE Name IN ('Sales Reps', 'Manager', 'USC', 'Country Manager')]) {
        allowedProfileIds.add(prof.Id);
    }
    
    // Recorrer los registros de Task recién insertados o actualizados
    for (Task task : Trigger.new) {
        // Verificar si la tarea está asociada con una oportunidad
        if (task.WhatId != null && task.WhatId.getSObjectType() == Opportunity.SObjectType) {
            // Verificar el perfil del usuario que realizó la actualización
            if (allowedProfileIds.contains(UserInfo.getProfileId())) {
                opportunityIds.add(task.WhatId);
            }
        }
    }
    
    if (!opportunityIds.isEmpty()) {
        // Consultar las oportunidades relacionadas con las tareas
        List<Opportunity> opportunitiesToUpdate = [SELECT Id, LastModifiedByCustomField__c FROM Opportunity WHERE Id IN :opportunityIds];
        
        // Iterar sobre las oportunidades y actualizar el campo LastModifiedByCustomField
        for (Opportunity opp : opportunitiesToUpdate) {
            opp.LastModifiedByCustomField__c = UserInfo.getUserId(); 
        }
        
        // Actualizar las oportunidades
        update opportunitiesToUpdate;
    }
}