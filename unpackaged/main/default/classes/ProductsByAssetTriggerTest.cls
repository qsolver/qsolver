@isTest
public with sharing class ProductsByAssetTriggerTest {

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

        Product2 aProduct = BuilderController.aProduct2()
        .withName('Test product')
        .build();

        insert aProduct;
        
    }

    @IsTest
    static void correctAssignmentOfRelatedAssetNameToProductsByAssetName(){

        Asset anAsset = [
            SELECT Id, Name
            FROM Asset
            LIMIT 1
        ];

        Product2 aProduct = [
            SELECT Id, Name
            FROM Product2
            LIMIT 1
        ];

        ELM_Products_by_Asset__c aProductByAsset = BuilderController.anELMProductsbyAsset()
        .withELMAsset(anAsset)
        .withELMProduct(aProduct)
        .build();
        
        Test.startTest();
        insert aProductByAsset;
        Test.stopTest();

        ELM_Products_by_Asset__c result = [
            SELECT Id, Name
            FROM ELM_Products_by_Asset__c
            LIMIT 1
        ];

        System.assertEquals(anAsset.Name, result.Name, 'The names are equal when they shouldnt be');
        
    }

}