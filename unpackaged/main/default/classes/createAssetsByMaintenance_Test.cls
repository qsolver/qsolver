@IsTest
public class createAssetsByMaintenance_Test {
    // Helper: create a minimal Product (often useful for Assets)
    private static Product2 makeProduct(String name) {
        Product2 p = new Product2(Name = name, IsActive = true);
        insert p;
        return p;
    }
    
    // Helper: create a minimal Account (usually used by Assets)
    private static Account makeAccount(String name) {
        Account a = new Account(Name = name);
        insert a;
        return a;
    }
    
    // Helper: create an Asset with common fields populated
    private static Asset makeAsset(String name, Id accountId, Id productId) {
        Asset a = new Asset(
            Name      = name,
            AccountId = accountId,
            Product2Id = productId
            // ELM_ExternalId__c not required for the test logic
        );
        insert a;
        return a;
    }
    
    // Helper: create a Maintenance__c record (lookup target for the junction)
    private static Maintenance__c makeMaintenance(String name, account acc) {
        // Create Maintenance__c 
        Maintenance__c mtn = new Maintenance__c(
            Name = name,
            Account__c = acc.Id 
        );
        
        insert mtn;
        return mtn;
    }

    @IsTest
    static void test_getAssetsResults_filters_and_excludes_selected() {
        // Data setup
        Account acc = makeAccount('Acme Corp');
        Product2 prod = makeProduct('Pump');

        Asset a1 = makeAsset('Pump A', acc.Id, prod.Id);
        Asset a2 = makeAsset('Pump B', acc.Id, prod.Id);
        Asset a3 = makeAsset('Valve X', acc.Id, prod.Id);
        
        Maintenance__c mtn = makeMaintenance('Test Maintenance', acc);

        // Exclude a2 explicitly, and filter by 'Pump'
        List<String> selectedIds = new List<String>{ a2.Id };

        Test.startTest();
        List<Asset> results = createAssetsByMaintenance.getAssetsResults(selectedIds, 'Pump', mtn.Id);
        Test.stopTest();

        // Assert: returns only assets whose Name LIKE '%Pump%' and NOT IN selectedIds
        System.assertNotEquals(null, results, 'Results should not be null');
        // Candidate set is {a1, a2}; a2 is excluded => expect only a1
        System.assertEquals(1, results.size(), 'Should return exactly one matching Asset');
        System.assertEquals(a1.Id, results[0].Id, 'Should return Pump A and exclude Pump B');
        
        // Negative check: assets that don’t match filter should not be returned
        for (Asset a : results) {
            System.assert(a.Name.contains('Pump'), 'Returned asset must match the filter');
            System.assert(a.Id != a2.Id, 'Returned list must exclude pre-selected assets');
        }
    }

    @IsTest
    static void test_createJunctionRegisters_inserts_one_per_asset() {
        // Data setup
        Account acc = makeAccount('Beta Co');
        Product2 prod = makeProduct('Valve Line');

        Asset a1 = makeAsset('Valve A', acc.Id, prod.Id);
        Asset a2 = makeAsset('Valve B', acc.Id, prod.Id);

        Maintenance__c mtn = makeMaintenance('Test Maintenance', acc);

        List<String> assetIds = new List<String>{ a1.Id, a2.Id };

        Test.startTest();
        // maintenance parameter is the Id string of Maintenance__c
        createAssetsByMaintenance.createJunctionRegisters('ignoredNameParam', mtn.Id, assetIds);
        Test.stopTest();

        // Verify junction records
        List<Asset_by_Maintenance__c> links = [
            SELECT Id, Asset__c, Maintenance__c
            FROM Asset_by_Maintenance__c
        ];
        System.assertEquals(2, links.size(), 'Should insert one junction per asset');

        Set<Id> linkedAssets = new Set<Id>();
        for (Asset_by_Maintenance__c l : links) linkedAssets.add(l.Asset__c);
        System.assert(linkedAssets.contains(a1.Id), 'Junction must include Valve A');
        System.assert(linkedAssets.contains(a2.Id), 'Junction must include Valve B');
    }

   
}