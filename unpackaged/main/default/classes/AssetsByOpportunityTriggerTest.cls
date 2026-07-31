@isTest
public with sharing class AssetsByOpportunityTriggerTest {
    
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
        
        Opportunity anOpportunity = BuilderController.anOpportunity()
        .withName('Opportunity Test')
        .withCurrencyIsoCode('USD')
        .withStageName('Qualification')
        .withType('Liners')
        .withAccountId(anAccount)
        .build();
        
        insert anOpportunity;

        Asset anAsset;
        anAsset = BuilderController.anAsset()
        .withIsCompetitorProduct(false)
        .withCurrentlyInstalled(true)
        .withIsInternal(true)
        .withLineofBusiness('Alerta Temprana')
        .withMEElecmetalEquipment(true)
        .withName('Test Asset')
        .withNeverInstalled(true)
        .withPreviouslyInstalled(false).withAccountId(anAccount)
        .build();

        insert anAsset;

    }

    @IsTest
    static void correctAssignmentOfOpportunitysNameToAssetsName(){

        Asset anAsset = [
            SELECT Id, Name
            FROM Asset
            LIMIT 1
        ];

        Opportunity anOpp = [
            SELECT Id, Name
            FROM Opportunity
            LIMIT 1
        ];

        Assets_by_Opportunity__c assetByOpportunity;

        assetByOpportunity = BuilderController.anAssetsbyOpportunity()
        .withOpportunity(anOpp)
        .withAsset(anAsset)
        .build();
        
        
        Test.startTest();
        insert assetByOpportunity;
        Test.stopTest();

        Assets_by_Opportunity__c result = [
            SELECT Id, Name
            FROM Assets_by_Opportunity__c
            LIMIT 1
        ];

        System.assertEquals(anOpp.Name, result.Name, 'The names are equal when they shouldnt be');
        
    }
}