@isTest
public with sharing class CreateAccsByOppControllerTest {
    @TestSetup
    static void makeData(){

        Account anAccount1 = BuilderController.anAccount()
        .withName('Test')
        .withPhone('8888')
        .withType('Competitor')
        .withRegion('NA')
        .withBillingCity('Burns Harbor')
        .withBillingCountry('USA')
        .withBillingPostalCode('46304')
        .withBillingState('IN')
        .withBillingStreet('250 West Us Hghway 12')
        .withCopyBillingAddresstoShippingAddress(false)
        .build();

        insert anAccount1;

        Opportunity anOpportunity = BuilderController.anOpportunity()
        .withAccountId(anAccount1)
        .withName('Opportunity Test')
        .withCurrencyIsoCode('USD')
        .withStageName('Qualification')
        .withType('Liners')
        .build();
        
        insert anOpportunity;

        Account anAccount2 = BuilderController.anAccount()
        .withName('Tost')
        .withPhone('8888')
        .withType('Competitor')
        .withRegion('NA')
        .withBillingCity('Burns Harbor')
        .withBillingCountry('USA')
        .withBillingPostalCode('46304')
        .withBillingState('IN')
        .withBillingStreet('250 West Us Hghway 12')
        .withCopyBillingAddresstoShippingAddress(false)
        .build();

        insert anAccount2;
        
    }

    @IsTest
    static void checkGetAccountResultMethod(){

        Account anAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Name =: 'Test'
            LIMIT 1
        ];

        String filter = 'o';
        List<Id> selectedAccountsIds = new List<Id>();
        selectedAccountsIds.add(anAccount.Id);
        
        Test.startTest();
        List<Account> result = CreateAccountsByOpportunity.getAccountResults(selectedAccountsIds, filter);
        Test.stopTest();

        System.assertNotEquals(anAccount.Name, result[0].Name, 'The account is the same when it should not be');

    }

    @IsTest
    static void creationOfTheJunctionRegisterTest(){

        String name = 'junction name';
        String isoCode = 'USD';
        Opportunity anOpportunity = [
            SELECT Id, Name
            FROM Opportunity
            LIMIT 1
        ];
        List<Account> accounts = [
            SELECT Id
            FROM Account
        ];

        List<String> accIds = new List<String>();

        for (Account acc : accounts) {

            accIds.add(acc.Id);
            
        }
        
        Test.startTest();
        CreateAccountsByOpportunity.createJunctionRegisters(name, isoCode, (String)anOpportunity.Id, accIds);
        Test.stopTest();

        List<Accounts_by_Opportunity__c> result = [
            SELECT Id, Name
            FROM Accounts_by_Opportunity__c
        ];

        System.assertEquals(anOpportunity.Name, result[0].Name, 'The register was not created');
        
    }


}