@IsTest
private class CruspiAverageControllerTest {

    @IsTest
    static void buildRowsSortsAndMergesYears() {
        // Custom metadata cannot be inserted in tests, so records are built in memory
        List<CRUSPICMT__mdt> records = (List<CRUSPICMT__mdt>) JSON.deserialize(
            '[{"Anio__c":"2026","Enero__c":239.90,"Febrero__c":244.90},' +
            '{"Anio__c":"2025","Noviembre__c":237.80,"Diciembre__c":238.50},' +
            '{"Anio__c":"2026","Enero__c":1,"Marzo__c":244.50},' +
            '{"Anio__c":"invalid"}]',
            List<CRUSPICMT__mdt>.class
        );

        Test.startTest();
        List<CruspiAverageController.YearRow> rows = CruspiAverageController.buildRows(records);
        Test.stopTest();

        Assert.areEqual(2, rows.size());
        Assert.areEqual(2025, rows[0].year);
        Assert.areEqual(2026, rows[1].year);
        Assert.areEqual(12, rows[1].values.size());
        Assert.areEqual(239.90, rows[1].values[0], 'First non-empty value wins');
        Assert.areEqual(244.50, rows[1].values[2], 'Duplicate year fills gaps');
        Assert.isNull(rows[1].values[11]);
    }

    @IsTest
    static void getYearsReturnsList() {
        Assert.isNotNull(CruspiAverageController.getYears());
    }
}