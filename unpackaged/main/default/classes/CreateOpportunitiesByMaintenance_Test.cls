@IsTest
private class CreateOpportunitiesByMaintenance_Test {
    // -------- Test Data Helpers --------
    private static Account makeAccount(String name) {
        Account a = new Account(Name = name);
        insert a;
        return a;
    }

    private static Opportunity makeOpp(String name, Id accountId) {
        Opportunity o = new Opportunity(
            Name      = name,
            AccountId = accountId,
            StageName = 'Prospecting',   // required
            CloseDate = Date.today().addDays(30)
            // Opportunity_Number__c not required for this logic; set if your org enforces it
        );
        insert o;
        return o;
    }

    private static Maintenance__c makeMaintenance(String name, account acc) {
        // Create Maintenance__c 
        Maintenance__c mtn = new Maintenance__c(
            Name = name,
            Account__c = acc.Id 
        );
        
        insert mtn;
        return mtn;
    }

    // -------- Tests --------

    @IsTest
    static void test_getOpportunityResults_filters_and_excludes_selected() {
        // Arrange
        Account acc = makeAccount('Acme');
        Opportunity o1 = makeOpp('Pump Maintenance - North', acc.Id);
        Opportunity o2 = makeOpp('Pump Maintenance - South', acc.Id);
        Opportunity o3 = makeOpp('Valve Upgrade', acc.Id);
        Maintenance__c mtn = makeMaintenance('Test Maintenance', acc);

        // Exclude o2; filter by 'Pump'
        List<String> preselected = new List<String>{ o2.Id };

        // Act
        Test.startTest();
        List<Opportunity> got = CreateOpportunitiesByMaintenance.getOpportunityResults(preselected, 'Pump', mtn.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, got, 'Should return a non-null list');
        // Candidates by filter: o1, o2. Then exclude o2 -> only o1 remains.
        System.assertEquals(1, got.size(), 'Should return exactly one Opportunity after exclusion');
        System.assertEquals(o1.Id, got[0].Id, 'Should include o1 and exclude o2');
        // Negative check: unrelated names must not appear
        for (Opportunity o : got) {
            System.assert(o.Name.contains('Pump'), 'Only Opportunities matching filter should be returned');
            System.assert(o.Id != o2.Id, 'Preselected Opportunity must be excluded');
        }
    }

    @IsTest
    static void test_createJunctionRegisters_inserts_one_per_opportunity() {
        // Arrange
        Account acc = makeAccount('Beta Co');
        Opportunity o1 = makeOpp('Quarterly Maintenance Q1', acc.Id);
        Opportunity o2 = makeOpp('Quarterly Maintenance Q2', acc.Id);

        Maintenance__c maint = makeMaintenance('2025 Preventive Plan', acc);
        List<String> oppIds = new List<String>{ o1.Id, o2.Id };

        // Act
        Test.startTest();
        // Note: 'name' parameter is not used by the method, pass any string
        CreateOpportunitiesByMaintenance.createJunctionRegisters('ignored', String.valueOf(maint.get('Id')), oppIds);
        Test.stopTest();

        // Assert
        List<Opportunity_by_Maintenance__c> links = [
            SELECT Id, Opportunity__c, Maintenance__c
            FROM Opportunity_by_Maintenance__c
            
        ];
        System.assertEquals(2, links.size(), 'Must create exactly one junction per Opportunity');

        Set<Id> linked = new Set<Id>();
        for (Opportunity_by_Maintenance__c l : links) linked.add(l.Opportunity__c);

        System.assert(linked.contains(o1.Id), 'Junction must include o1');
        System.assert(linked.contains(o2.Id), 'Junction must include o2');
    }

    @IsTest
    static void test_createJunctionRegisters_handles_empty_selection() {
        // Arrange
        Account acc = makeAccount('Beta Co');
        Maintenance__c maint = makeMaintenance('Empty Selection Test', acc);

        // Act (should not throw)
        Test.startTest();
        CreateOpportunitiesByMaintenance.createJunctionRegisters('ignored', String.valueOf(maint.get('Id')), new List<String>());
        Test.stopTest();

        // Assert
        Integer count = [
            SELECT COUNT()
            FROM Opportunity_by_Maintenance__c
            
        ];
        System.assertEquals(0, count, 'No junctions should be inserted for empty selection');
    }

    
}