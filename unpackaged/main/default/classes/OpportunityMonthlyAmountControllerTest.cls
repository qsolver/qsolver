@isTest
public class OpportunityMonthlyAmountControllerTest {

    @testSetup
    static void setupTestData() {
        // Create Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            Amount = 10000,
            CloseDate = Date.today().addMonths(1),
            Ship_Date__c = Date.today().addMonths(1),
            Cantidad_de_entregas_de_venta__c = '2',
            CurrencyIsoCode = 'USD',
            StageName = 'Prospecting',
            ELM_GM_Opp_Type__c = 'Product Test',
            ELM_Line_of_Business__c = 'Bolas (Grinding Media)',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Grinding Media / GET').getRecordTypeId()
        );
        insert testOpportunity;

        // Create Users with Profile 'Sales Reps GM'
        Profile gmProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Reps GM' LIMIT 1];
        User gmUser1 = new User(
            Alias = 'user1',
            Email = 'testuser1@example.com',
            Username = 'testuser***###@example.com',
            LastName = 'User1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = gmProfile.Id,
            LanguageLocaleKey = 'en_US',
            Division = 'GM', // Non-'GET Chile' Division
            CompanyName = 'Test Company'
        );
        insert gmUser1;

        User gmUser2 = new User(
            Alias = 'user2',
            Email = 'testuser2###***@example.com',
            Username = 'testuser231@example.com',
            LastName = 'User2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = gmProfile.Id,
            LanguageLocaleKey = 'en_US',
            Division = 'GM', // Non-'GET Chile' Division
            CompanyName = 'Test Company'
        );
        insert gmUser2;
    }

    @isTest
    static void testGetOpportunities() {
        // Call the method to test
        Test.startTest();
        List<Opportunity> opportunities = OpportunityMonthlyAmountController.getOpportunities();
        Test.stopTest();

        // Validate the result
        System.assertNotEquals(0, opportunities.size(), 'There should be at least one opportunity returned');
        System.assertEquals('Test Opportunity', opportunities[0].Name, 'The opportunity name should match the test data');
    }

    @isTest
    static void testGetGMUsers() {
        // Call the method to test
        Test.startTest();
        List<User> gmUsers = OpportunityMonthlyAmountController.getGMUsers();
        Test.stopTest();

        // Validate the result
        System.assertNotEquals(0, gmUsers.size(), 'There should be at least one GM user returned');
        System.assertEquals('Sales Reps GM', gmUsers[0].Profile.Name, 'The user should match the test data');
    }
}