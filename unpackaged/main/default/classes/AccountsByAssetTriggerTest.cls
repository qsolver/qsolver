@isTest
public with sharing class AccountsByAssetTriggerTest {

    @TestSetup
    static void makeData(){
        
        Account anAccount = BuilderController.anAccount()
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

        insert anAccount;

        Asset anAsset;
        anAsset = BuilderController.anAsset()
        .withIsCompetitorProduct(false)
        .withCurrentlyInstalled(true)
        .withIsInternal(true)
        .withLineofBusiness('Alerta Temprana')
        .withMEElecmetalEquipment(true)
        .withName('Test Asset')
        .withNeverInstalled(true)
        .withPreviouslyInstalled(false)
        .withAccountId(anAccount)
        .build();

        insert anAsset;

    }

    @IsTest
    static void correctAssignmentOfAssetNameToAccountsNameTest(){

        Asset anAsset = [
            SELECT Id, Name
            FROM Asset
            LIMIT 1
        ];

        Account anAccount = [
            SELECT Id, Name
            FROM Account
            LIMIT 1
        ];

        ELM_Accounts_By_Asset__c anAccByAsset;
        anAccByAsset = BuilderController.anELMAccountsByAsset()
        .withAccount(anAccount)
        .withAsset(anAsset)
        .build();
        
        Test.startTest();
        insert anAccByAsset;
        Test.stopTest();
        
        ELM_Accounts_By_Asset__c result = [
            SELECT Id, Name
            FROM ELM_Accounts_By_Asset__c
            LIMIT 1
        ];

        System.assertEquals(anAsset.Name, result.Name, 'The names are equal when they shouldnt be');
    }

}