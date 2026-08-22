/**
 * @description       : 
 * @author            : Emerson.vasquez@globant.com
 * @group             : 
 * @last modified on  : 03-29-2023
 * @last modified by  : Emerson.vasquez@globant.com
**/
public with sharing class changeSalesRepLWController {

    @AuraEnabled(cacheable=true)
    public static Account getAccount(String oAccountId) { 

        String oMethod = 'getAccount';

        return [Select Id, Name, Vendedor_Alerta_Temprana__c, Vendedor_Grinding_Media__c, Vendedor_GET__c, Vendedor_Molienda__c, ELM_OtherSalesRep__c, Vendedor_Chancado__c, Vendedor_Maestranza__c, High_Value_Manager__c From Account Where Id = :oAccountId];

    }

    @AuraEnabled
    public static Boolean updateAccAndOpps(Id oAccountId, String oNewSalesRep, String oLineOfBus, Boolean oCheckOpen, Boolean oCheckClosed, Boolean oCheckTasksOpen, Boolean oCheckTasksclosed) { 
        // Obtenemos una descripción del objeto Account para encontrar el campo personalizado

        System.debug('oCheckTasksOpen => '+oCheckTasksOpen);
        Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
        Schema.SObjectField campoPersonalizado = accountFields.get(oLineOfBus);

        // Verificamos que el campo personalizado existe en Account
        if (campoPersonalizado == null || !campoPersonalizado.getDescribe().isCustom()) {
            throw new AuraHandledException('El campo personalizado // The custom field: ' + oLineOfBus + ' no existe en Account // does not exists in the account');
        }

        // Construimos la consulta SOQL dinámicamente utilizando el campo personalizado
        String query = 'SELECT Id, Name, ' + campoPersonalizado + ' FROM Account WHERE Id = \'' + oAccountId + '\'';

        // Ejecutamos la consulta SOQL utilizando Database.query()
        Account cuenta = Database.query(query);
        Id valorCampoPersonalizado = (Id) cuenta.get(campoPersonalizado);
        // Actualizamos el campo personalizado de búsqueda con el valor proporcionado
        cuenta.put(oLineOfBus, oNewSalesRep);
        System.debug('New SalesREP - > '+oNewSalesRep);
        Database.SaveResult sr = Database.update(cuenta, false);

        // Verificamos si hubo errores al guardar la cuenta
        if (sr.isSuccess()) {
            // Creamos una lista vacía para almacenar las oportunidades que se actualizarán
            List<Opportunity> oportunidadesAActualizar = new List<Opportunity>();

            // Si se proporciona el parámetro "actualizarOportunidadesAbiertas" como verdadero, buscamos las oportunidades abiertas relacionadas con la cuenta y las agregamos a la lista
            if (oCheckOpen) {
                System.debug('Campo Personalizado -> '+valorCampoPersonalizado);
                List<Opportunity> oportunidadesAbiertas = [SELECT Id, AccountId, OwnerId FROM Opportunity WHERE AccountId = :oAccountId AND StageName != 'Closed Won' AND StageName != 'Closed Lost' AND OwnerId = :valorCampoPersonalizado];
                oportunidadesAActualizar.addAll(oportunidadesAbiertas);
            }

            // Si se proporciona el parámetro "actualizarOportunidadesCerradas" como verdadero, buscamos las oportunidades cerradas relacionadas con la cuenta y las agregamos a la lista
            if (oCheckClosed) {
                List<Opportunity> oportunidadesCerradas = [SELECT Id, AccountId, OwnerId FROM Opportunity WHERE AccountId = :oAccountId AND (StageName = 'Closed Won' OR StageName = 'Closed Lost') AND OwnerId = :valorCampoPersonalizado];
                oportunidadesAActualizar.addAll(oportunidadesCerradas);
            }

            //Si el checkbox de transferir tasks abiertas esta marcado buscamos las tasks abiertas relacionadas al usuario
            if (oCheckTasksOpen) {
                List<Task> tasksAbiertas = [SELECT Id, OwnerId FROM Task WHERE OwnerId = :valorCampoPersonalizado AND Status = 'In Progress' AND WhatId =:oAccountId];
                updateTaks(tasksAbiertas, oNewSalesRep);
            }

            //Si el checkbox de transferir tasks cerradas esta marcado buscamos las tasks cerradas relacionadas al usuario
            if (oCheckTasksclosed) {
                List<Task> tasksCerradas = [SELECT Id, OwnerId FROM Task WHERE OwnerId = :valorCampoPersonalizado AND Status = 'Completed' AND WhatId =:oAccountId];
                updateTaks(tasksCerradas, oNewSalesRep);
            }

            // Actualizamos el campo personalizado de búsqueda en cada oportunidad de la lista
            for (Opportunity oportunidad : oportunidadesAActualizar) {
                oportunidad.OwnerId = null;
                oportunidad.OwnerId = oNewSalesRep;
            }

            // Guardamos los cambios en las oportunidades
            List<Database.SaveResult> srOpps = Database.update(oportunidadesAActualizar, false);
            
            // Verificamos si hubo errores al guardar las oportunidades
            for (Database.SaveResult srOpp : srOpps) {
                if (!srOpp.isSuccess()) {
                    System.debug('Error al actualizar la oportunidad => '+srOpp);
                    for(Database.Error error : srOpp.getErrors()){
                        System.debug(error.getMessage());
                        throw new AuraHandledException('Error al actualizar la oportunidad // There was an error trying to update the opportunity: '+error.getMessage()+' -- REVISE LAS OPORTUNIDADES QUE QUIERE TRANSFERIR // CHECK THE OPPORTUNITIES TO TRANSFER => '+srOpp.Id);
                    }
                }
            }
            return true;
        } else {
            String finalMessage = '';
    
    		// We access the first error specifically as you requested
    		if (!sr.getErrors().isEmpty()) {
        		Database.Error err = sr.getErrors()[0];
        		String rawMsg = err.getMessage();

        		// 3. Clean the message (Universal Filter)
        		String cleanMsg = rawMsg;
        		
        		cleanMsg = cleanMsg.substringBefore('---');
        		cleanMsg = cleanMsg.substringBefore('. You can look up');

        		// 4. Concatenate: [Object Name] (ID): Error Message
        		// Example: "VAES (a018W00000Xyz): La Fecha debe ser anterior..."
        		finalMessage = cleanMsg.trim();
    		}

    		throw new AuraHandledException(finalMessage);
            
        }
    }   

    public static void updateTaks(List<Task> tasks, String newSalesRep){

        for(Task tarea : tasks){
            tarea.OwnerId = newSalesRep;
        }

        try{
            // Guardamos los cambios en las oportunidades
            List<Database.SaveResult> srTasks = Database.update(tasks, false);

            // Verificamos si hubo errores al guardar las tasks
            for (Database.SaveResult srTask : srTasks) {
                if (!srTask.isSuccess()) {
                    for(Database.Error error : srTask.getErrors()){
                        System.debug(error.getMessage());
                        throw new AuraHandledException('Error al actualizar la tarea // There was an error trying to update the task: '+error.getMessage()+' -- REVISE LAS OPORTUNIDADES QUE QUIERE TRANSFERIR // CHECK THE OPPORTUNITIES TO TRANSFER => '+srTask.Id);
                    }
                    
                }
            }
            

        }catch(Exception e){
            throw new AuraHandledException('Error al actualizar las tareas // Error trying to update the tasks: '+e);
        }
        



    }

}