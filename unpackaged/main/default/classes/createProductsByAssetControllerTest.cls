@isTest(seeAllData = false)
public with sharing class createProductsByAssetControllerTest {

    @TestSetup
    static void makeData(){

        Product2 aProduct = BuilderController.aProduct2()
        .withName('Test prodict')
        .withCurrencyIsoCode('USD')
        .build();

        insert aProduct;

        Product2 aProduct2 = BuilderController.aProduct2()
        .withName('Test product')
        .withCurrencyIsoCode('USD')
        .build();

        insert aProduct2;

        Product2 aProduct3 = BuilderController.aProduct2()
        .withName('Test prodect')
        .withCurrencyIsoCode('USD')
        .build();

        insert aProduct3;

        // Pricebook2 aPriceBook = BuilderController.aPricebook2()
        // .withName('Test price book')
        // .withCurrencyIsoCode('USD')
        // .withIsActive(true)
        // .build();

        // insert aPriceBook;

        Account anAccount1 = BuilderController.anAccount()
        .withName('Test account')
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

        // List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
        Id priceBookId = Test.getStandardPricebookId();

        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = priceBookId;
        pricebook.CurrencyIsoCode = 'USD';
        pricebook.IsActive = true;

        upsert pricebook;

        PricebookEntry aPricebookE = new PricebookEntry(
        Pricebook2Id = pricebook.Id,
        Product2Id = aProduct.Id,
        UnitPrice = 645698794,
        IsActive = true
        );

        insert aPricebookE;

        // priceBookEntries.add(aPricebookE);

        // PricebookEntry aPricebookEntry = BuilderController.aPricebookEntry()
        // .withCurrencyIsoCode('USD')
        // .withIsActive(true)
        // .withPricebook2Id(aPricebookE)
        // .withProduct2Id(aProduct)
        // .withUnitPrice(200.00)
        // .withUseStandardPrice(false)
        // .build();

        // priceBookEntries.add(aPricebookEntry);

        // insert priceBookEntries;

    }

    @IsTest
    static void checkGetProductResultMethod(){

        // Asset asset = [
        //     SELECT Id, Name
        //     FROM Asset
        //     LIMIT 1
        // ];

        Product2 product = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test product'
            LIMIT 1
        ];

        String filter = 'i';
        List<Id> selectedProductsIds = new List<Id>();

        Test.startTest();
        List<Product2> result = createProductsByAsset.getProductResults(selectedProductsIds, filter);
        Test.stopTest();

        System.assertNotEquals(product.Name, result[0].Name, 'The product is the same when it should not be');

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
        List<Product2> products = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test prodict'
        ];

        List<String> prodIds = new List<String>();

        for (Product2 product : products) {

            prodIds.add(product.Id);

        }

        Test.startTest();
        createProductsByAsset.createJunctionRegisters(name, isoCode, (String)anAsset.Id, prodIds);
        Test.stopTest();

        List<ELM_Products_by_Asset__c> result = [
            SELECT Id, Name
            FROM ELM_Products_by_Asset__c
        ];

        System.assertEquals(1, result.size(), 'The registry was not created');
        System.assertEquals(anAsset.Name, result[0].Name, 'The name is not the same');

    }

}