@IsTest
public with sharing class ProductsByVaesTriggerTest {

    @TestSetup
    static void makeData(){
        
        ELM_Vaes__c aVaes = BuilderController.anELMVaes()
        .withELMLineOfBusiness('Crushing')
        .build();

        insert aVaes;

        Product2 aProduct = BuilderController.aProduct2()
        .withName('test product')
        .withCurrencyIsoCode('USD')
        .build();

        insert aProduct;
    }

    @IsTest
    static void ProductsByVaesTriggerTest() {

        ELM_Vaes__c vaes = [
            SELECT Id, Name
            FROM ELM_Vaes__c
            LIMIT 1
        ];

        Product2 product = [
            SELECT Id
            FROM Product2
            LIMIT 1
        ];

        ELM_ProductsByVAES__c prodByVaes = new ELM_ProductsByVAES__c(
            ELM_VAES__c = vaes.Id,
            ELM_Product__c = product.Id
        );

        Test.startTest();
        insert prodByVaes;
        Test.stopTest();

        ELM_ProductsByVAES__c result = [
            SELECT Id, Name
            FROM ELM_ProductsByVAES__c
            LIMIT 1
        ];

        System.assertEquals(vaes.Name, result.Name, 'The Name is not equal');

    }
}