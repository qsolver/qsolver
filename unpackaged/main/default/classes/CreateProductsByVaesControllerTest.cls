@IsTest
public with sharing class CreateProductsByVaesControllerTest {

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

        ELM_Vaes__c aVaes = new ELM_Vaes__c(ELM_Account__c = anAccount1.Id, ELM_Line_Of_Business__c = 'Grinding Media', ELM_Fecha_inicio__c = Date.newInstance(2025, 12, 3));
            

        insert aVaes;
    }

    @IsTest
    static void checkGetProductResultMethod(){

        Product2 product = [
            SELECT Id, Name
            FROM Product2
            WHERE Name = 'Test prodict'
            LIMIT 1
        ];
        
        ELM_Vaes__c aVaes = [
            SELECT Id, Name
            FROM ELM_Vaes__c
            LIMIT 1
        ];

        String filter = 'i';
        List<Id> selectedProductsIds = new List<Id>();

        Test.startTest();
        List<Product2> result = CreateProductsByVaesController.getProductResults(selectedProductsIds, filter, aVaes.Id);
        Test.stopTest();

        System.assertEquals(product.Name, result[0].Name, 'The product is the same when it should not be');

    }

    @IsTest
    static void creationOfJunctionRegisterTest(){

        String name = 'junction name';
        String isoCode = 'USD';
        ELM_Vaes__c aVaes = [
            SELECT Id, Name
            FROM ELM_Vaes__c
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
        CreateProductsByVaesController.createJunctionRegisters(name, isoCode, (String)aVaes.Id, prodIds);
        Test.stopTest();

        List<ELM_ProductsByVAES__c> result = [
            SELECT Id, Name
            FROM ELM_ProductsByVAES__c
        ];

        System.assertEquals(1, result.size(), 'The registry was not created');
        System.assertEquals(aVaes.Name, result[0].Name, 'The name is not the same');

    }
}