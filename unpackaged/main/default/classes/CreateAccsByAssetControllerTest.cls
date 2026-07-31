@isTest
public with sharing class CreateAccsByAssetControllerTest {

    @TestSetup
    static void makeData(){

        Account anAccount1 = BuilderController.anAccountCompetitor()
        .withName('Tost')
        .withPhone('8888')
        .withRegion('NA')
        .withType('Competitor')
        .withBillingCity('Burns Harbor')
        .withBillingCountry('USA')
        .withBillingPostalCode('46304')
        .withBillingState('IN')
        .withBillingStreet('250 West Us Hghway 12')
        .withCopyBillingAddresstoShippingAddress(false)
        .withIELMCompetitorndustry('Mining')
        .withELMCompetitorPhone('2222222')
        .build();

        insert anAccount1;

        Asset anAsset = BuilderController.anAsset()
        .withAccountId(anAccount1)
        .withCurrentlyInstalled(true)
        .withIsCompetitorProduct(true)
        .withIsInternal(true)
        .withLineofBusiness('Alerta Temprana')
        .withMEElecmetalEquipment(true)
        .withName('Test Asset')
        .withNeverInstalled(true)
        .withPreviouslyInstalled(false)
        .build();

        insert anAsset;

        Account anAccount2 = BuilderController.anAccount()
        .withName('Test')
        .withPhone('8888')
        .withRegion('NA')
        .withType('Competitor')
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
    static void checkGetAccountResultsTest(){

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
        List<Account> result = CreateAccountsByAsset.getAccountResults(selectedAccountsIds, filter);
        Test.stopTest();

        System.assertNotEquals(anAccount.Name, result[0].Name, 'The account is the same when it should not be');
        
    }

    @IsTest
    static void creationOfJunctionRegisterTest(){

        String name = 'junction name';
        String isoCode = 'USD';
        Asset anAsset = [
            SELECT Id, Name
            FROM Asset
            LIMIT 1
        ];
        List<Account> accounts = [
            SELECT Id, Name
            FROM Account
        ];

        List<String> accIds = new List<String>();

        for (Account acc : accounts) {

            accIds.add(acc.Id);
            
        }
        
        Test.startTest();
        CreateAccountsByAsset.createJunctionRegisters(name, isoCode, (String)anAsset.Id, accIds);
        Test.stopTest();

        List<ELM_Accounts_By_Asset__c> result = [
            SELECT Id, Name
            FROM ELM_Accounts_By_Asset__c
        ];

        System.assertEquals(2, result.size(), 'Registries where no created');
        
    }

}