@isTest
public with sharing class createAssetsByOppControllerTest {

    @TestSetup
    static void makeData(){

        Account anAccount1 = BuilderController.anAccount()
        .withName('Test')
        .withPhone('8888')
        .withRegion('NA')
        .withBillingCity('Burns Harbor')
        .withBillingCountry('USA')
        .withBillingPostalCode('46304')
        .withBillingState('IN')
        .withBillingStreet('250 West Us Hghway 12')
        .withCopyBillingAddresstoShippingAddress(false)
        .build();
        anAccount1.Line_of_Business__c = 'Other';

        insert anAccount1;

        anAccount1.Type = 'Customer';

        update anAccount1;

        Opportunity anOpportunity = BuilderController.anOpportunity()
        .withAccountId(anAccount1)
        .withName('Opportunity Test')
        .withCurrencyIsoCode('USD')
        .withStageName('Qualification')
        .withType('Liners')
        .build();
        anOpportunity.ELM_Line_of_Business__c = 'Other';
        
        insert anOpportunity;

        Asset anAsset1 = BuilderController.anAsset()
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

        insert anAsset1;

        Asset anAsset2 = BuilderController.anAsset()
        .withAccountId(anAccount1)
        .withCurrentlyInstalled(true)
        .withIsCompetitorProduct(true)
        .withIsInternal(true)
        .withLineofBusiness('Alerta Temprana')
        .withMEElecmetalEquipment(true)
        .withName('Tost Asset')
        .withNeverInstalled(true)
        .withPreviouslyInstalled(false)
        .build();

        insert anAsset2;


        
    }

    @IsTest
    static void checkGetAssetsResultMethod(){

        Opportunity anOpp = [
            SELECT Id, Name
            FROM Opportunity
            LIMIT 1
        ];

        Asset anAsset = [
            SELECT Id, Name
            FROM Asset
            WHERE Name =: 'Test Asset'
            LIMIT 1
        ];

        String filter = 'o';
        List<Id> selectedAssetsIds = new List<Id>();
        selectedAssetsIds.add(anAsset.Id);
        
        Test.startTest();
        List<Asset> result = createAssetsByOpportunity.getAssetsResults(selectedAssetsIds, filter, anOpp.Id);
        Test.stopTest();

        System.assertNotEquals(anAsset.Name, result[0].Name, 'The asset is the same when it should not be');
        
    }

    @IsTest
    static void correctCreationOfJuctionRegisterTest(){

        String name = 'junction name';
        String isoCode = 'USD';
        Opportunity anOpportunity = [
            SELECT Id, Name, Opportunity_Number__c
            FROM Opportunity
            LIMIT 1
        ];
        List<Asset> assets = [
            SELECT Id, Name
            FROM Asset
        ];

        List<String> assetIds = new List<String>();

        for (Asset asset : assets) {

            assetIds.add(asset.Id);
            
        }
        
        Test.startTest();
        createAssetsByOpportunity.createJunctionRegisters(isoCode, (String)anOpportunity.Id, assetIds);
        Test.stopTest();

        List<Assets_by_Opportunity__c> result = [
            SELECT Id, Name, Opportunity__r.Opportunity_Number__c
            FROM Assets_by_Opportunity__c
        ];

        System.assertEquals(anOpportunity.Opportunity_Number__c, result[0].Opportunity__r.Opportunity_Number__c, 'The register was not created');
        
    }

}