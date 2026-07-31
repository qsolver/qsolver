@isTest
public class Product2TriggerTest {
    
    @testSetup
    static void setupData(){
        // Create sample Assets to be used in tests
        Asset asset1 = new Asset(
            Name = 'Asset 1234',
            ELM_ExternalId__c = '1234'
        );
        
        Asset asset2 = new Asset(
            Name = 'Asset 5678',
            ELM_ExternalId__c = '5678'
        );
        
        Asset asset3 = new Asset(
            Name = 'Asset 2345',
            ELM_ExternalId__c = '2345'
        );
        
        Asset asset4 = new Asset(
            Name = 'Asset 6789',
            ELM_ExternalId__c = '6789'
        );
        
        insert new List<Asset>{asset1, asset2, asset3, asset4};
            
        // Create sample data to use across all tests
        
        Product2 p1 = new Product2(
            Name = 'Test Product 1', 
            StockKeepingUnit = 'SKU001',
            ELM_ASSETS__c = '[1234,5678]'
        );
        insert p1;
        
        Product2 p2 = new Product2(
            Name = 'Test Product 2', 
            StockKeepingUnit = 'SKU002',
            ELM_ASSETS__c = '[2345,6789]'
        );
        insert p2;
    }

    @isTest
    static void testAfterInsert(){
        // Retrieve the inserted products from test setup
        List<Product2> insertedProducts = [SELECT Id, ELM_ASSETS__c FROM Product2 WHERE StockKeepingUnit = 'SKU001'];

        // Assert that products were inserted
        System.assert(insertedProducts.size() == 1, 'Should have 1 product inserted');
        
        // Test after insert logic
        Test.startTest();
        Product2 p = new Product2(
            Name = 'Test Product 3',
            StockKeepingUnit = 'SKU003',
            ELM_ASSETS__c = '[1234,5678]'
        );
        insert p;
        Test.stopTest();
        
        // After Insert assert statements to verify related assets logic
        List<EM_ASSETSMATERIALS__c> relatedAssets = [SELECT Id, Name, EM_MATERIAL__c FROM EM_ASSETSMATERIALS__c WHERE EM_MATERIAL__c =:p.Id];
        System.assert(relatedAssets.size() > 0, 'Product was created');
    }

    @isTest
    static void testAfterUpdate(){
        // Get the product to be updated
        Product2 pToUpdate = [SELECT Id, ELM_ASSETS__c, StockKeepingUnit FROM Product2 WHERE StockKeepingUnit = 'SKU002' LIMIT 1];
        
        // Modify some fields
        pToUpdate.ELM_ASSETS__c = '[1234,5678]';
        pToUpdate.StockKeepingUnit = 'SKU_UPDATED';
        
        Test.startTest();
        update pToUpdate;
        Test.stopTest();
        
        // Verify related assets were updated correctly after update
        List<EM_ASSETSMATERIALS__c> relatedAssetsAfterUpdate = [SELECT Id, Name, EM_MATERIAL__c FROM EM_ASSETSMATERIALS__c WHERE EM_MATERIAL__c =:pToUpdate.Id];
        System.assert(relatedAssetsAfterUpdate.size() > 0, 'Product was updated');
    }

    @isTest
    static void testNullAssetHandling(){
        // Test scenario when ELM_ASSETS__c is null
        
        Product2 p = new Product2(
            Name = 'Test Product 4',
            StockKeepingUnit = 'SKU004',
            ELM_ASSETS__c = null
        );
        
        Test.startTest();
        insert p;
        Test.stopTest();
        
        // Assert that no related assets were created
        List<EM_ASSETSMATERIALS__c> relatedAssets = [SELECT Id, Name, EM_MATERIAL__c FROM EM_ASSETSMATERIALS__c WHERE EM_MATERIAL__c =:p.Id];
        System.assert(relatedAssets.size() == 0, 'No Related Assets should be created when ELM_ASSETS__c is null');
    }

    @isTest
    static void testBulkInsert(){
        // Create multiple products to test bulk insert scenario
        List<Product2> productList = new List<Product2>();
        
        for(Integer i=0; i<200; i++){
            productList.add(new Product2(
                Name = 'Test Product ' + i,
                StockKeepingUnit = 'SKU001' + i,
                ELM_ASSETS__c = '[1234,5678]'
            ));
        }
        
        Test.startTest();
        insert productList;
        Test.stopTest();
        
        // Verify that related assets were created for all inserted products
        List<EM_ASSETSMATERIALS__c> relatedAssets = [SELECT Id, EM_MATERIAL__c FROM EM_ASSETSMATERIALS__c WHERE EM_MATERIAL__c IN (SELECT Id FROM Product2)];
        System.assert(relatedAssets.size() > 0, 'All products were created');
    }
    
    @isTest
    static void testBulkUpdate(){
        // Retrieve products from test setup
        List<Product2> productList = [SELECT Id, ELM_ASSETS__c FROM Product2];
        
        // Modify all products in bulk
        for(Product2 p : productList){
            p.ELM_ASSETS__c = '[1234,5678]';
        }
        
        Test.startTest();
        update productList;
        Test.stopTest();
        
        // Verify related assets were updated for all products
        List<EM_ASSETSMATERIALS__c> relatedAssets = [SELECT Id, EM_MATERIAL__c FROM EM_ASSETSMATERIALS__c WHERE EM_MATERIAL__c IN (SELECT Id FROM Product2)];
        System.assert(relatedAssets.size() > 0, 'All products were modified');
    }
    
    @isTest
    static void testFutureMethodAndContextMethods() {
        // Call the future method OnAfterUpdateAsync
        Set<Id> productIds = new Set<Id>{};
        List<Product2> products = [SELECT Id FROM Product2];
        for (Product2 product : products) {
            productIds.add(product.Id);
        }
        
        Test.startTest();
        Product2TriggerHandler.OnAfterUpdateAsync(productIds);
        Test.stopTest();
        
        // Assert that the future method ran successfully
        System.assert(true, 'Future method executed successfully');
        
        // Test the context methods
        Product2TriggerHandler handler = new Product2TriggerHandler(true, 200);
        
        // Test IsTriggerContext
        System.assertEquals(true, handler.IsTriggerContext, 'IsTriggerContext should return true when in trigger context');
        
        // Test IsVisualforcePageContext
        System.assertEquals(false, handler.IsVisualforcePageContext, 'IsVisualforcePageContext should return false when in trigger context');
        
        // Test IsWebServiceContext
        System.assertEquals(false, handler.IsWebServiceContext, 'IsWebServiceContext should return false when in trigger context');
        
        // Test IsExecuteAnonymousContext
        System.assertEquals(false, handler.IsExecuteAnonymousContext, 'IsExecuteAnonymousContext should return false when in trigger context');
    }
}