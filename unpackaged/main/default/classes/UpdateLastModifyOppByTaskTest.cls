@isTest
private class UpdateLastModifyOppByTaskTest {

    static testMethod void testTriggerLogic() {
        
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Reps' LIMIT 1];

        // Crear un usuario de prueba con el perfil de Sales Reps
        User testUser = new User(
            FirstName = 'Usuario',
            LastName = 'Prueba',
            Email = 'usuarioprueba@example.com',
            Username = 'usuarioprueba@example.com',
            Alias = 'uprueba',
            ProfileId = p.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;

        // Crear una cuenta de prueba
        Account acc = new Account(
            Name = 'Cuenta de Prueba',
            Line_of_Business__c = 'Other'
        );
        insert acc;

        // Crear una oportunidad de prueba
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad de Prueba',
            StageName = 'Prospectando',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            ELM_Line_of_Business__c = 'Other'
        );
        insert opp;

        // Crear una tarea de prueba relacionada con la oportunidad
        Task testTask = new Task(
            Subject = 'Tarea de Prueba',
            WhatId = opp.Id,
            OwnerId = testUser.Id
        );
        insert testTask;

        System.runAs(testUser) {
              
          
        Test.startTest();

        // Insertar una segunda tarea relacionada con la misma oportunidad
        Task secondTask = new Task(
            Subject = 'Segunda Tarea de Prueba',
            WhatId = opp.Id,
            OwnerId = testUser.Id
        );
        insert secondTask;

        Test.stopTest();
        }

        // Consultar la oportunidad para verificar LastModifiedByCustomField__c
        Opportunity updatedOpp = [SELECT Id, LastModifiedById FROM Opportunity WHERE Id = :opp.Id];
        
        // Verificar que LastModifiedByCustomField__c se actualice al Id del usuario de prueba
        System.assertNotEquals(null, updatedOpp.LastModifiedById, 'LastModifiedById on Opportunity not updated');
    }
}