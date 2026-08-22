@isTest
public with sharing class createVAESByOpportunityTest {
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
        
         // Create a test Product2
        Product2 prod1 = new Product2(Name = 'Test Product 1', ProductCode = 'TP1');
        insert prod1;

        Product2 prod2 = new Product2(Name = 'Test Product 2', ProductCode = 'TP2');
        insert prod2;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        // Create PricebookEntry for products
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe1;

        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod2.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert pbe2;

        //Create an opportunity
        Opportunity anOpportunity = BuilderController.anOpportunity()
        .withAccountId(anAccount1)
        .withName('Opportunity Test')
        .withCurrencyIsoCode('USD')
        .withStageName('Qualification')
        .withType('Liners')
        .build();
        anOpportunity.ELM_Line_of_Business__c = 'Other';
        anOpportunity.Pricebook2Id = pricebookId;
        
        insert anOpportunity;
        
        // Create OpportunityLineItems
        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = anOpportunity.Id,
            PricebookEntryId = pbe1.Id,
            Product2Id = prod1.Id,
            UnitPrice = 100,
            Quantity = 1
        );
        insert oli1;

        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = anOpportunity.Id,
            PricebookEntryId = pbe2.Id,
            Product2Id = prod2.Id,
            UnitPrice = 200,
            Quantity = 2
        );
        insert oli2;


        ELM_Vaes__c vaes = new ELM_Vaes__c(ELM_Account__c=anAccount1.Id, ELM_Project_Name__c='TestProject x');
        insert vaes;
        
        ELM_Vaes__c vaes2 = new ELM_Vaes__c(ELM_Account__c=anAccount1.Id, ELM_Project_Name__c='TestProject z');
        insert vaes2;

  
    }

    @IsTest
    static void checkGetAssetsResultMethod(){

        Opportunity anOpp = [
            SELECT Id, Name
            FROM Opportunity
            LIMIT 1
        ];

        ELM_Vaes__c vaes = [
            SELECT Id, Name, ELM_Project_Name__c
            FROM ELM_Vaes__c
            LIMIT 1
        ];

        String filter = 'z';
        List<Id> selectedVAESIds = new List<Id>();
        selectedVAESIds.add(vaes.Id);
        
        Test.startTest();
        List<ELM_Vaes__c> result = createVAESByOpportunity.getVAESResults(selectedVAESIds, filter, anOpp.Id);
        Test.stopTest();

        System.assertNotEquals(vaes.Name, '', 'the vaes is null');
        System.assertNotEquals(anOpp.Name, '', 'the Opp is null');
        System.assertNotEquals(vaes.Name, result[0].Name, 'The asset is the same when it should not be');
        
    }

    @IsTest
    static void correctCreationOfJuctionRegisterTest(){

        String name = 'junction name';
        Opportunity anOpportunity = [
            SELECT Id, Name
            FROM Opportunity
            LIMIT 1
        ];
        List<ELM_Vaes__c> vaess = [
            SELECT Id, Name
            FROM ELM_Vaes__c
        ];

        List<String> VAESIds = new List<String>();

        for (ELM_Vaes__c vaes : vaess) {

            VAESIds.add(vaes.Id);
            
        }
        
        Test.startTest();
        createVAESByOpportunity.createJunctionRegisters(name, (String)anOpportunity.Id, VAESIds);
        Test.stopTest();

        List<VAES_by_Opportunity__c> result = [
            SELECT Id, Name
            FROM VAES_by_Opportunity__c
        ];

        System.assertEquals(anOpportunity.Name, result[0].Name, 'The register was not created');
        
    }
    
    @isTest
    static void testGetOpportunityProducts() {
        // Retrieve test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        // Test getOpportunityProducts method
        Test.startTest();
        List<OpportunityLineItem> result = createVAESByOpportunity.getOpportunityProducts(testOpp.Id);
        Test.stopTest();

        // Verify the result
        System.assertNotEquals(null, result);
        System.assertEquals(2, result.size());
        System.assert(result[0].Product2Id != null);
        System.assert(result[1].Product2Id != null);
    }
    
    @isTest
    static void testCreateProductByVAESJunctionRegisters() {
        // Retrieve test data
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 2];
        List<ELM_VAES__c> vaesList = [SELECT Id FROM ELM_VAES__c LIMIT 2];

        List<String> productIds = new List<String>();
        for (Product2 prod : products) {
            productIds.add(prod.Id);
        }

        List<String> vaesIds = new List<String>();
        for (ELM_VAES__c vaes : vaesList) {
            vaesIds.add(vaes.Id);
        }

        // Test createProductByVAESJunctionRegisters method
        Test.startTest();
        createVAESByOpportunity.createProductByVAESJunctionRegisters(productIds, vaesIds, testOpp.Id);
        Test.stopTest();

        // Verify the result
        List<ELM_ProductsByVAES__c> result = [SELECT Id, Name, ELM_VAES__c, ELM_Product__c FROM ELM_ProductsByVAES__c];
        System.assertEquals(4, result.size()); // 2 products * 2 VAES = 4 junction records

        for (ELM_ProductsByVAES__c record : result) {
            System.assertNotEquals(null, record.ELM_VAES__c);
            System.assertNotEquals(null, record.ELM_Product__c);
        }
    }
}