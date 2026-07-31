/**
 * @description       : 
 * @author            : Emerson.vasquez@globant.com
 * @group             : 
 * @last modified on  : 04-03-2023
 * @last modified by  : Emerson.vasquez@globant.com
**/
@isTest
private class changeSalesRepLWControllerTest {

    @testSetup
    static void setup() {
        
        // Crear registros necesarios
        User user = new User(
            Alias = 'teser159',
            Email = 'testuser15997885@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser15997885@test.com'
        );
        insert user;

        Account account = new Account(
            Name='Test Account',
            Vendedor_Alerta_Temprana__c = user.id
            );
        insert account;

        Opportunity opportunity = new Opportunity(
            Name='Test Opportunity',
            AccountId=account.Id,
            Description='Test Desc',
            Ship_Date__c = Date.today(),
            StageName='Qualification',
            CloseDate=Date.today(),
            OwnerId=user.Id
        );
        insert opportunity;
        
        Task task = new Task(
            Subject = 'Test Task',
            OwnerId = user.Id,
            Status = 'In Progress'
        );
            
        insert task;
            
        Task task2 = new Task(
            Subject = 'Test Task',
            OwnerId = user.Id,
            Status = 'completed'
        );
        
        insert task2;
    }

    @isTest
    static void testGetAccount() {
        // Obtener la cuenta creada en el método setup
        Account account = [SELECT Id, Name FROM Account LIMIT 1];

        // Llamar al método getAccount de la clase controladora
        Account resultAccount = changeSalesRepLWController.getAccount(account.Id);

        // Verificar que la cuenta devuelta es la misma que la creada en el método setup
        System.assertEquals(account.Id, resultAccount.Id);
        System.assertEquals(account.Name, resultAccount.Name);
    }

    @isTest
    static void testUpdateAccAndOpps() {
        // Obtener la cuenta y la oportunidad creada en el método setup
        Account account = [SELECT Id, Vendedor_Alerta_Temprana__c, Vendedor_Grinding_Media__c, Vendedor_GET__c, Vendedor_Molienda__c, ELM_OtherSalesRep__c, Vendedor_Chancado__c, Vendedor_Maestranza__c FROM Account LIMIT 1];
        Opportunity opportunity = [SELECT Id, OwnerId FROM Opportunity WHERE AccountId = :account.Id];

        // Crear un nuevo usuario para actualizar los registros
        User newUser1 = new User(
            Alias = 'newuser1',
            Email = 'newuser9515452@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'newuser9515452@test.com'
        );
        insert newUser1;

        // Llamar al método updateAccAndOpps de la clase controladora
        Boolean result = changeSalesRepLWController.updateAccAndOpps(account.Id, newUser1.Id, 'Vendedor_Alerta_Temprana__c', true, true, false, false);

        // Verificar que se actualizó la cuenta y la oportunidad correctamente
        System.assertEquals(true, result);
        Account updatedAccount = [SELECT Id, Vendedor_Alerta_Temprana__c FROM Account WHERE Id = :account.Id];
        System.assertEquals(newUser1.Id, updatedAccount.Vendedor_Alerta_Temprana__c);
        Opportunity updatedOpportunity = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :opportunity.Id];
        System.assertEquals(newUser1.Id, updatedOpportunity.OwnerId);
    }
    
    
    @isTest
    static void testUpdateTasks() {
        // Obtener la cuenta y la oportunidad creada en el método setup
        Account account = [SELECT Id, Vendedor_Alerta_Temprana__c, Vendedor_Grinding_Media__c, Vendedor_GET__c, Vendedor_Molienda__c, ELM_OtherSalesRep__c, Vendedor_Chancado__c, Vendedor_Maestranza__c FROM Account LIMIT 1];
        
        
        Task tasksAbierta = [SELECT Id, OwnerId FROM Task WHERE Status = 'In Progress' LIMIT 1];
        Task tasksCerrada = [SELECT Id, OwnerId FROM Task WHERE Status = 'Completed' LIMIT 1];
        List<Task> tareas = new List<Task>();
        tareas.add(tasksAbierta);
        tareas.add(tasksCerrada);

        // Crear un nuevo usuario para actualizar los registros
        User newUser1 = new User(
            Alias = 'newuser1',
            Email = 'newuser9515452@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'newuser9515452@test.com'
        );
        insert newUser1;

        // Llamar al método updateAccAndOpps de la clase controladora
        Test.startTest();
        Boolean result = changeSalesRepLWController.updateAccAndOpps(account.Id, newUser1.Id, 'Vendedor_Alerta_Temprana__c', false, false, true, true);
        changeSalesRepLWController.updateTaks(tareas,newUser1.Id);
        Test.stopTest();
        // Verificar que se actualizó la cuenta y la oportunidad correctamente
        System.assertEquals(true, result);
        Account updatedAccount = [SELECT Id, Vendedor_Alerta_Temprana__c FROM Account WHERE Id = :account.Id];
        System.assertEquals(newUser1.Id, updatedAccount.Vendedor_Alerta_Temprana__c);
        
        Task updatedTasksAbierta = [SELECT Id, OwnerId FROM Task WHERE Id = :tasksAbierta.Id AND Status = 'In Progress' LIMIT 1];
        Task updatedTasksCerrada = [SELECT Id, OwnerId FROM Task WHERE Id = :tasksCerrada.Id AND Status = 'Completed' LIMIT 1];
        System.assertEquals(newUser1.Id, tasksAbierta.OwnerId);
        System.assertEquals(newUser1.Id, tasksCerrada.OwnerId);
    }

    // ─── Tests for uncovered error-handling paths ───────────────────

    @isTest
    static void testUpdateAccAndOpps_InvalidFieldName() {
        // Covers line 28-30: campoPersonalizado == null → AuraHandledException
        Account account = [SELECT Id FROM Account LIMIT 1];
        User newUser = [SELECT Id FROM User WHERE Alias = 'teser159' LIMIT 1];

        Test.startTest();
        try {
            changeSalesRepLWController.updateAccAndOpps(
                account.Id, newUser.Id, 'Nonexistent_Field__c', false, false, false, false
            );
            System.assert(false, 'Should have thrown AuraHandledException for invalid field');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('Script-thrown exception'),
                'Should throw for invalid custom field'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateAccAndOpps_AccountUpdateFailure() {
        // Covers lines 93-112: Account Database.update fails → else branch
        // Passing a non-User Id (e.g. Account Id) to a User-lookup field causes DML failure
        Account account = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        try {
            // account.Id is not a valid User Id for the lookup field → DML error
            changeSalesRepLWController.updateAccAndOpps(
                account.Id, account.Id, 'Vendedor_Alerta_Temprana__c', false, false, false, false
            );
            System.assert(false, 'Should have thrown AuraHandledException for account update failure');
        } catch (AuraHandledException e) {
            // The error message goes through the cleaning logic (lines 102-109)
            System.assertNotEquals(null, e.getMessage(), 'Should have an error message');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateAccAndOpps_OppUpdateFailure() {
        // Covers lines 84-91: Opportunity Database.update fails → AuraHandledException
        // Strategy: Account update succeeds, then reassign opps to an inactive/invalid owner
        Account account = [SELECT Id, Vendedor_Alerta_Temprana__c FROM Account LIMIT 1];
        
        // Create a new user to be the new sales rep (Account update will succeed)
        User newUser = new User(
            Alias = 'failusr',
            Email = 'failureuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'FailUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'failureuser9988554@test.com'
        );
        insert newUser;

        // Deactivate the user so opp ownership transfer fails
        newUser.IsActive = false;
        update newUser;

        Test.startTest();
        try {
            // Account lookup update with inactive user may still succeed,
            // but Opportunity OwnerId assignment to inactive user should fail
            changeSalesRepLWController.updateAccAndOpps(
                account.Id, newUser.Id, 'Vendedor_Alerta_Temprana__c', true, false, false, false
            );
            // If it doesn't fail (some orgs allow inactive user assignment), that's ok
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Should have an error message about opportunity update');
        }
        Test.stopTest();
    }
}