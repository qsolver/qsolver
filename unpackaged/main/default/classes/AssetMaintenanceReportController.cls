public with sharing class AssetMaintenanceReportController {

    // ─── Inner Wrapper Classes ─────────────────────────────────────────────────

    public class ReportResponse {
        @AuraEnabled public List<FlatRow>       rows;
        @AuraEnabled public List<String>        monthHeaders;   // ['Ene 2025', 'Feb 2025', ...]
        @AuraEnabled public List<String>        monthKeys;      // ['2025-01', '2025-02', ...]
        @AuraEnabled public Integer             totalAccounts;
        @AuraEnabled public List<PicklistOption> salesTeamOptions;
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PicklistOption(String l, String v) { label = l; value = v; }
    }

    public class FlatRow {
        @AuraEnabled public String  rowKey;
        // ── Country grouping
        @AuraEnabled public Boolean showCountry;
        @AuraEnabled public Integer countryRowspan;
        @AuraEnabled public String  country;
        // ── LOB grouping
        @AuraEnabled public Boolean showLob;
        @AuraEnabled public Integer lobRowspan;
        @AuraEnabled public String  lob;
        // ── Account grouping
        @AuraEnabled public Boolean showAccount;
        @AuraEnabled public Integer accountRowspan;
        @AuraEnabled public String  accountName;
        @AuraEnabled public String  vendedorMolienda;
        @AuraEnabled public Decimal consumoTotalAnual;
        @AuraEnabled public Decimal consumoAnualElecmetal;
        @AuraEnabled public Decimal consumoAnualOtros;
        // ── Asset grouping
        @AuraEnabled public Boolean      showAsset;
        @AuraEnabled public Integer      assetRowspan;
        @AuraEnabled public String       assetName;
        @AuraEnabled public Decimal      diameter;
        @AuraEnabled public Decimal      length;
        @AuraEnabled public List<String> maintenanceCells; // 24 values: null / 'MM' / 'MS'
        // ── Product row
        @AuraEnabled public String  productName;
        @AuraEnabled public Boolean hasProducts;
    }

    // ─── Sales-Team Picklist ────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getSalesTeamOptions() {
        return getSalesTeamOptionsInternal();
    }

    private static List<PicklistOption> getSalesTeamOptionsInternal() {
        List<PicklistOption> opts = new List<PicklistOption>();
        for (Schema.PicklistEntry e : Account.ELM_Equipo_de_Ventas__c.getDescribe().getPicklistValues()) {
            if (e.isActive()) {
                opts.add(new PicklistOption(e.getLabel(), e.getValue()));
            }
        }
        return opts;
    }

    // ─── Main Report Method ─────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static ReportResponse getReportData(
        String  salesTeam,
        String  countryFilter,
        String  accountFilter,
        String  lobFilter,
        Integer year,
        Integer pageSize,
        Integer pageNumber
    ) {
        // ── Defaults
        if (String.isBlank(salesTeam)) salesTeam = 'SURAMERICA';
        Integer currentYear = (year != null) ? year : Date.today().year();
        Integer ps  = (pageSize   != null && pageSize   > 0) ? pageSize   : 20;
        Integer pn  = (pageNumber != null && pageNumber > 1) ? pageNumber : 1;
        Integer offsetVal = (pn - 1) * ps;

        ReportResponse resp = new ReportResponse();

        // ── Build 24-month headers
        resp.monthHeaders = new List<String>();
        resp.monthKeys    = new List<String>();
        String[] mNames = new String[]{ 'Ene','Feb','Mar','Abr','May','Jun',
                                        'Jul','Ago','Sep','Oct','Nov','Dic' };
        for (Integer y = currentYear; y <= currentYear + 1; y++) {
            for (Integer m = 1; m <= 12; m++) {
                String mm = m < 10 ? '0' + m : String.valueOf(m);
                resp.monthKeys.add(y + '-' + mm);
                resp.monthHeaders.add(mNames[m - 1] + ' ' + y);
            }
        }

        // ── Sales team options
        resp.salesTeamOptions = getSalesTeamOptionsInternal();

        // ── Dynamic account query
        String countryLike = String.isNotBlank(countryFilter)  ? '%' + countryFilter  + '%' : null;
        String accountLike = String.isNotBlank(accountFilter)  ? '%' + accountFilter  + '%' : null;

        String baseWhere = ' WHERE ELM_Equipo_de_Ventas__c = :salesTeam';
        if (countryLike != null) baseWhere += ' AND BillingCountry LIKE :countryLike';
        if (accountLike != null) baseWhere += ' AND Name LIKE :accountLike';

        resp.totalAccounts = Database.countQuery(
            'SELECT COUNT() FROM Account' + baseWhere
        );

        List<Account> accounts = Database.query(
            'SELECT Id, Name, BillingCountry, Vendedor_Molienda__r.Name,' +
            ' Consumo_Total_Anual__c, Consumo_Anual_Elecmetal_Toneladas__c,' +
            ' Consumo_Anual_Otros_Proveedores_Tons__c' +
            ' FROM Account' + baseWhere +
            ' ORDER BY BillingCountry NULLS LAST, Name' +
            ' LIMIT :ps OFFSET :offsetVal'
        );

        if (accounts.isEmpty()) {
            resp.rows = new List<FlatRow>();
            return resp;
        }

        // ── Maps
        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        // ── Assets
        String lobLike  = String.isNotBlank(lobFilter) ? '%' + lobFilter + '%' : null;
        String assetWhere = ' WHERE AccountId IN :accountIds';
        if (lobLike != null) assetWhere += ' AND Line_of_Business__c LIKE :lobLike';

        List<Asset> assets = Database.query(
            'SELECT Id, Name, AccountId, Line_of_Business__c, Diameter__c, Length__c' +
            ' FROM Asset' + assetWhere +
            ' ORDER BY Line_of_Business__c NULLS LAST, Name'
        );

        Map<Id, List<Asset>> accountToAssets = new Map<Id, List<Asset>>();
        Set<Id> assetIds = new Set<Id>();
        for (Asset a : assets) {
            assetIds.add(a.Id);
            if (!accountToAssets.containsKey(a.AccountId)) {
                accountToAssets.put(a.AccountId, new List<Asset>());
            }
            accountToAssets.get(a.AccountId).add(a);
        }

        // ── Products via junction
        Map<Id, List<String>> assetToProducts = new Map<Id, List<String>>();
        if (!assetIds.isEmpty()) {
            for (ELM_Products_by_Asset__c pj : [
                SELECT ELM_Asset__c, ELM_Product__r.Name
                FROM ELM_Products_by_Asset__c
                WHERE ELM_Asset__c IN :assetIds
                ORDER BY ELM_Product__r.Name
            ]) {
                if (!assetToProducts.containsKey(pj.ELM_Asset__c)) {
                    assetToProducts.put(pj.ELM_Asset__c, new List<String>());
                }
                assetToProducts.get(pj.ELM_Asset__c).add(pj.ELM_Product__r.Name);
            }
        }

        // ── Maintenances via junction
        Map<Id, Map<String, String>> assetCellMap = new Map<Id, Map<String, String>>();
        if (!assetIds.isEmpty()) {
            Set<Id> maintIds = new Set<Id>();
            Map<Id, Id> maintToAsset = new Map<Id, Id>();
            for (Asset_by_Maintenance__c mj : [
                SELECT Asset__c, Maintenance__c
                FROM Asset_by_Maintenance__c
                WHERE Asset__c IN :assetIds
            ]) {
                maintIds.add(mj.Maintenance__c);
                maintToAsset.put(mj.Maintenance__c, mj.Asset__c);
            }

            if (!maintIds.isEmpty()) {
                Date startDate = Date.newInstance(currentYear, 1, 1);
                Date endDate   = Date.newInstance(currentYear + 1, 12, 31);
                for (Maintenance__c maint : [
                    SELECT Id, Fecha_Inicio__c, Tipo_de_Mantencion__c
                    FROM Maintenance__c
                    WHERE Id IN :maintIds
                    AND Fecha_Inicio__c >= :startDate
                    AND Fecha_Inicio__c <= :endDate
                ]) {
                    Id assetId = maintToAsset.get(maint.Id);
                    if (assetId == null || maint.Fecha_Inicio__c == null) continue;
                    // Safely cast to Date regardless of whether field is Date or DateTime
                    Date maintDate = Date.valueOf(String.valueOf(maint.Fecha_Inicio__c).left(10));
                    Integer monthNum = maintDate.month();
                    Integer yearNum  = maintDate.year();
                    String mm2 = monthNum < 10 ? '0' + monthNum : String.valueOf(monthNum);
                    String ym  = yearNum + '-' + mm2;
                    if (!assetCellMap.containsKey(assetId)) {
                        assetCellMap.put(assetId, new Map<String, String>());
                    }
                    assetCellMap.get(assetId).put(ym, mapTipo(maint.Tipo_de_Mantencion__c));
                }
            }
        }

        // ── Build flat rows
        resp.rows = buildFlatRows(
            accounts, accountToAssets, assetToProducts, assetCellMap, resp.monthKeys
        );
        return resp;
    }

    // ─── Helpers ────────────────────────────────────────────────────────────────

    private static String mapTipo(String tipo) {
        if (tipo == null) return null;
        String t = tipo.trim();
        if (t.equalsIgnoreCase('Mantencion mayor'))        return 'MM';
        if (t.equalsIgnoreCase('Mantencion de servicios')) return 'MS';
        return t;
    }

    private static List<FlatRow> buildFlatRows(
        List<Account>            accounts,
        Map<Id, List<Asset>>     accountToAssets,
        Map<Id, List<String>>    assetToProducts,
        Map<Id, Map<String, String>> assetCellMap,
        List<String>             monthKeys
    ) {
        List<FlatRow> rows = new List<FlatRow>();

        // ── Group accounts by country to compute rowspans
        // Build ordered unique country list (accounts already sorted by country)
        List<String>            countryOrder    = new List<String>();
        Map<String, List<Account>> countryToAccts = new Map<String, List<Account>>();
        for (Account acc : accounts) {
            String ctry = String.isNotBlank(acc.BillingCountry) ? acc.BillingCountry : '(Sin País)';
            if (!countryToAccts.containsKey(ctry)) {
                countryToAccts.put(ctry, new List<Account>());
                countryOrder.add(ctry);
            }
            countryToAccts.get(ctry).add(acc);
        }

        Integer rowIndex = 0;

        for (String country : countryOrder) {
            List<Account> countryAccts = countryToAccts.get(country);

            // ── Group by LOB within country
            // LOB is an asset-level field; we order assets by LOB first.
            // Build tuples: (lob, account, asset)
            List<String>               lobOrder   = new List<String>();
            Map<String, List<Object[]>> lobToTuples = new Map<String, List<Object[]>>();

            for (Account acc : countryAccts) {
                List<Asset> accAssets = accountToAssets.get(acc.Id);
                if (accAssets == null || accAssets.isEmpty()) {
                    // Account with no assets — still show 1 row
                    String lob = '(Sin Línea de Negocio)';
                    if (!lobToTuples.containsKey(lob)) {
                        lobToTuples.put(lob, new List<Object[]>());
                        lobOrder.add(lob);
                    }
                    lobToTuples.get(lob).add(new Object[]{ acc, null });
                } else {
                    for (Asset ast : accAssets) {
                        String lob = String.isNotBlank(ast.Line_of_Business__c)
                            ? ast.Line_of_Business__c : '(Sin Línea de Negocio)';
                        if (!lobToTuples.containsKey(lob)) {
                            lobToTuples.put(lob, new List<Object[]>());
                            lobOrder.add(lob);
                        }
                        lobToTuples.get(lob).add(new Object[]{ acc, ast });
                    }
                }
            }

            // ── Compute country rowspan
            Integer countryRowspan = 0;
            for (String lob : lobOrder) {
                for (Object[] t : lobToTuples.get(lob)) {
                    Asset ast = (Asset) t[1];
                    if (ast == null) {
                        countryRowspan++;
                    } else {
                        List<String> prods = assetToProducts.get(ast.Id);
                        countryRowspan += (prods != null && !prods.isEmpty()) ? prods.size() : 1;
                    }
                }
            }

            Boolean firstLob = true;
            for (String lob : lobOrder) {
                List<Object[]> tuples = lobToTuples.get(lob);

                // ── Compute LOB rowspan
                Integer lobRowspan = 0;
                for (Object[] t : tuples) {
                    Asset ast = (Asset) t[1];
                    if (ast == null) {
                        lobRowspan++;
                    } else {
                        List<String> prods = assetToProducts.get(ast.Id);
                        lobRowspan += (prods != null && !prods.isEmpty()) ? prods.size() : 1;
                    }
                }

                // ── Group by account within this LOB bucket
                List<Id>               acctOrder   = new List<Id>();
                Map<Id, List<Object[]>> acctToTuples = new Map<Id, List<Object[]>>();
                for (Object[] t : tuples) {
                    Account acc = (Account) t[0];
                    if (!acctToTuples.containsKey(acc.Id)) {
                        acctToTuples.put(acc.Id, new List<Object[]>());
                        acctOrder.add(acc.Id);
                    }
                    acctToTuples.get(acc.Id).add(t);
                }

                Map<Id, Account> acctMap = new Map<Id, Account>();
                for (Account a : countryAccts) acctMap.put(a.Id, a);

                Boolean firstAcct = true;
                for (Id accId : acctOrder) {
                    List<Object[]> acctTuples = acctToTuples.get(accId);
                    Account acc = acctMap.get(accId);

                    // Compute account rowspan
                    Integer acctRowspan = 0;
                    for (Object[] t : acctTuples) {
                        Asset ast = (Asset) t[1];
                        if (ast == null) {
                            acctRowspan++;
                        } else {
                            List<String> prods = assetToProducts.get(ast.Id);
                            acctRowspan += (prods != null && !prods.isEmpty()) ? prods.size() : 1;
                        }
                    }

                    Boolean firstAsset = true;
                    for (Object[] t : acctTuples) {
                        Asset ast = (Asset) t[1];

                        if (ast == null) {
                            // No asset — single placeholder row
                            FlatRow row = new FlatRow();
                            row.rowKey         = 'r-' + rowIndex++;
                            row.showCountry    = (firstLob && firstAcct && firstAsset);
                            row.countryRowspan = row.showCountry ? countryRowspan : 0;
                            row.country        = country;
                            row.showLob        = (firstAcct && firstAsset);
                            row.lobRowspan     = row.showLob ? lobRowspan : 0;
                            row.lob            = lob;
                            row.showAccount    = firstAsset;
                            row.accountRowspan = row.showAccount ? acctRowspan : 0;
                            row.accountName    = acc.Name;
                            row.vendedorMolienda    = acc.Vendedor_Molienda__r.Name;
                            row.consumoTotalAnual   = acc.Consumo_Total_Anual__c;
                            row.consumoAnualElecmetal = acc.Consumo_Anual_Elecmetal_Toneladas__c;
                            row.consumoAnualOtros   = acc.Consumo_Anual_Otros_Proveedores_Tons__c;
                            row.showAsset      = true;
                            row.assetRowspan   = 1;
                            row.assetName      = '';
                            row.maintenanceCells = buildEmptyCells(monthKeys);
                            row.productName    = '';
                            row.hasProducts    = false;
                            rows.add(row);
                            firstAsset = false;
                        } else {
                            List<String> prods = assetToProducts.get(ast.Id);
                            Boolean hasProds = (prods != null && !prods.isEmpty());
                            Integer assetRowspan = hasProds ? prods.size() : 1;
                            List<String> cells = buildMaintenanceCells(ast.Id, assetCellMap, monthKeys);

                            Integer numRows = hasProds ? prods.size() : 1;
                            for (Integer pi = 0; pi < numRows; pi++) {
                                Boolean isFirstProdRow = (pi == 0);
                                FlatRow row = new FlatRow();
                                row.rowKey         = 'r-' + rowIndex++;
                                row.showCountry    = (firstLob && firstAcct && firstAsset && isFirstProdRow);
                                row.countryRowspan = row.showCountry ? countryRowspan : 0;
                                row.country        = country;
                                row.showLob        = (firstAcct && firstAsset && isFirstProdRow);
                                row.lobRowspan     = row.showLob ? lobRowspan : 0;
                                row.lob            = lob;
                                row.showAccount    = (firstAsset && isFirstProdRow);
                                row.accountRowspan = row.showAccount ? acctRowspan : 0;
                                row.accountName    = acc.Name;
                                row.vendedorMolienda      = acc.Vendedor_Molienda__r.Name;
                                row.consumoTotalAnual     = acc.Consumo_Total_Anual__c;
                                row.consumoAnualElecmetal = acc.Consumo_Anual_Elecmetal_Toneladas__c;
                                row.consumoAnualOtros     = acc.Consumo_Anual_Otros_Proveedores_Tons__c;
                                row.showAsset      = isFirstProdRow;
                                row.assetRowspan   = row.showAsset ? assetRowspan : 0;
                                row.assetName      = ast.Name;
                                row.diameter       = ast.Diameter__c;
                                row.length         = ast.Length__c;
                                row.maintenanceCells = cells;
                                row.productName    = hasProds ? prods[pi] : '';
                                row.hasProducts    = hasProds;
                                rows.add(row);
                            }
                            firstAsset = false;
                        }
                    }
                    firstAcct = false;
                }
                firstLob = false;
            }
        }
        return rows;
    }

    private static List<String> buildMaintenanceCells(
        Id assetId,
        Map<Id, Map<String, String>> assetCellMap,
        List<String> monthKeys
    ) {
        Map<String, String> cellMap = assetCellMap.containsKey(assetId)
            ? assetCellMap.get(assetId) : new Map<String, String>();
        List<String> cells = new List<String>();
        for (String key : monthKeys) {
            // Use '' (empty string) instead of null so LWC for:each iterates ALL 24 cells.
            // LWC skips null entries in arrays, which would collapse the month columns.
            cells.add(cellMap.containsKey(key) ? cellMap.get(key) : '');
        }
        return cells;
    }

    private static List<String> buildEmptyCells(List<String> monthKeys) {
        List<String> cells = new List<String>();
        for (Integer i = 0; i < monthKeys.size(); i++) cells.add('');
        return cells;
    }
}