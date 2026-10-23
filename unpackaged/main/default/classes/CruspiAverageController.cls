/**
 * Provides the CRUSPI monthly values (CRUSPICMT__mdt) to the cruspiMonthlyAverage LWC.
 * Each metadata record holds the 12 monthly values for one year (Anio__c).
 */
public with sharing class CruspiAverageController {

    private static final List<SObjectField> MONTH_FIELDS = new List<SObjectField>{
        CRUSPICMT__mdt.Enero__c,
        CRUSPICMT__mdt.Febrero__c,
        CRUSPICMT__mdt.Marzo__c,
        CRUSPICMT__mdt.Abril__c,
        CRUSPICMT__mdt.Mayo__c,
        CRUSPICMT__mdt.Junio__c,
        CRUSPICMT__mdt.Julio__c,
        CRUSPICMT__mdt.Agosto__c,
        CRUSPICMT__mdt.Septiembre__c,
        CRUSPICMT__mdt.Octubre__c,
        CRUSPICMT__mdt.Noviembre__c,
        CRUSPICMT__mdt.Diciembre__c
    };

    @AuraEnabled(cacheable=true)
    public static List<YearRow> getYears() {
        return buildRows([
            SELECT Anio__c, Enero__c, Febrero__c, Marzo__c, Abril__c, Mayo__c, Junio__c,
                   Julio__c, Agosto__c, Septiembre__c, Octubre__c, Noviembre__c, Diciembre__c
            FROM CRUSPICMT__mdt
        ]);
    }

    @TestVisible
    private static List<YearRow> buildRows(List<CRUSPICMT__mdt> records) {
        Map<Integer, YearRow> rowsByYear = new Map<Integer, YearRow>();

        for (CRUSPICMT__mdt rec : records) {
            Integer year = parseYear(rec.Anio__c);
            if (year == null) continue;

            YearRow row = rowsByYear.get(year);
            if (row == null) {
                row = new YearRow(year);
                rowsByYear.put(year, row);
            }
            // If two records share the same year, a later non-empty value fills the gaps
            for (Integer i = 0; i < MONTH_FIELDS.size(); i++) {
                Decimal value = (Decimal) rec.get(MONTH_FIELDS[i]);
                if (value != null && row.values[i] == null) {
                    row.values[i] = value;
                }
            }
        }

        List<YearRow> rows = rowsByYear.values();
        rows.sort();
        return rows;
    }

    private static Integer parseYear(String value) {
        if (String.isBlank(value)) return null;
        try {
            return Integer.valueOf(value.trim());
        } catch (Exception e) {
            return null;
        }
    }

    public class YearRow implements Comparable {
        @AuraEnabled public Integer year;
        @AuraEnabled public List<Decimal> values;

        public YearRow(Integer year) {
            this.year = year;
            this.values = new List<Decimal>();
            for (Integer i = 0; i < 12; i++) values.add(null);
        }

        public Integer compareTo(Object other) {
            return year - ((YearRow) other).year;
        }
    }
}