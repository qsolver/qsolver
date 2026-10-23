public with sharing class MasterPlanDashboardController {

    // ─── Wrapper classes ────────────────────────────────────────────────────────

    public class DashboardData {
        @AuraEnabled public Integer year;
        @AuraEnabled public List<AccountData> accounts;
    }

    public class AccountData {
        @AuraEnabled public Id     id;
        @AuraEnabled public String name;
        @AuraEnabled public String billingCountry;
        @AuraEnabled public String conglomerado;
        @AuraEnabled public List<AssetData> assets;
    }

    public class AssetData {
        @AuraEnabled public Id     id;
        @AuraEnabled public String name;
        @AuraEnabled public String lineOfBusiness;
        @AuraEnabled public List<ProductRow>      products;
        @AuraEnabled public List<CompetenciaRow>  competencia;
        @AuraEnabled public List<MaintenanceEntry> maintenances;
    }

    public class ProductRow {
        @AuraEnabled public Id     id;
        @AuraEnabled public String productName;
        @AuraEnabled public String productCode;
    }

    public class CompetenciaRow {
        @AuraEnabled public Id     id;
        @AuraEnabled public String productName;
        @AuraEnabled public String competitor;
        @AuraEnabled public String industryRequirement;
    }

    public class MaintenanceEntry {
        @AuraEnabled public Id      id;
        @AuraEnabled public Integer month; // 1-12
        @AuraEnabled public String  type;  // 'MM' or 'MS'
        @AuraEnabled public Date    maintenanceDate;
    }

    // ─── Main dashboard query ───────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static DashboardData getDashboardData(Integer year) {
        Integer targetYear = (year != null) ? year : Date.today().year();

        DashboardData result = new DashboardData();
        result.year     = targetYear;
        result.accounts = new List<AccountData>();

        List<Account> accounts = [
            SELECT Id, Name, BillingCountry, Conglomerado__c
            FROM Account
            WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
              AND Vendedor_Alerta_Temprana__c != null
            WITH SECURITY_ENFORCED
            ORDER BY Name
        ];

        if (accounts.isEmpty()) {
            return result;
        }

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        List<Asset> assets = [
            SELECT Id, Name, AccountId, Line_of_Business__c
            FROM Asset
            WHERE AccountId IN :accountIds
            WITH SECURITY_ENFORCED
            ORDER BY Name
        ];

        Set<Id> assetIds = new Map<Id, Asset>(assets).keySet();

        Map<Id, List<Asset>> assetsByAccount = new Map<Id, List<Asset>>();
        for (Asset a : assets) {
            if (!assetsByAccount.containsKey(a.AccountId)) {
                assetsByAccount.put(a.AccountId, new List<Asset>());
            }
            assetsByAccount.get(a.AccountId).add(a);
        }

        Map<Id, List<ProductRow>>     productsByAsset    = new Map<Id, List<ProductRow>>();
        Map<Id, List<CompetenciaRow>> competenciaByAsset = new Map<Id, List<CompetenciaRow>>();

        if (!assetIds.isEmpty()) {
            for (ELM_Products_by_Asset__c pj : [
                SELECT Id, ELM_Asset__c, ELM_Product__r.Name, Product_Code__c,
                    Competitor__c, Requerimiento_industria__c
                FROM ELM_Products_by_Asset__c
                WHERE ELM_Asset__c IN :assetIds
                WITH SECURITY_ENFORCED
                ORDER BY ELM_Product__r.Name
            ]) {
                if (!productsByAsset.containsKey(pj.ELM_Asset__c)) {
                    productsByAsset.put(pj.ELM_Asset__c, new List<ProductRow>());
                    competenciaByAsset.put(pj.ELM_Asset__c, new List<CompetenciaRow>());
                }

                ProductRow pr = new ProductRow();
                pr.id          = pj.Id;
                pr.productName = pj.ELM_Product__r != null ? pj.ELM_Product__r.Name : null;
                pr.productCode = pj.Product_Code__c;
                productsByAsset.get(pj.ELM_Asset__c).add(pr);

                CompetenciaRow cr = new CompetenciaRow();
                cr.id                  = pj.Id;
                cr.productName         = pr.productName;
                cr.competitor          = pj.Competitor__c;
                cr.industryRequirement = pj.Requerimiento_industria__c;
                competenciaByAsset.get(pj.ELM_Asset__c).add(cr);
            }
        }

        Map<Id, List<MaintenanceEntry>> maintenanceByAsset = new Map<Id, List<MaintenanceEntry>>();
        if (!assetIds.isEmpty()) {
            Map<Id, Id> maintenanceIdToAssetId = new Map<Id, Id>();
            for (Asset_by_Maintenance__c mj : [
                SELECT Asset__c, Maintenance__c
                FROM Asset_by_Maintenance__c
                WHERE Asset__c IN :assetIds AND Maintenance__c != null
                WITH SECURITY_ENFORCED
            ]) {
                maintenanceIdToAssetId.put(mj.Maintenance__c, mj.Asset__c);
            }

            if (!maintenanceIdToAssetId.isEmpty()) {
                // Mirrors the existing Enero__c .. Diciembre__c formula fields on
                // Maintenance__c, which key off MONTH(Fecha_Inicio__c) only —
                // they don't check the year, so we don't either.
                for (Maintenance__c m : [
                    SELECT Id, Fecha_Inicio__c, Tipo_de_Mantencion__c
                    FROM Maintenance__c
                    WHERE Id IN :maintenanceIdToAssetId.keySet()
                      AND Fecha_Inicio__c != null
                    WITH SECURITY_ENFORCED
                ]) {
                    if (m.Fecha_Inicio__c == null) continue;
                    Id assetId = maintenanceIdToAssetId.get(m.Id);
                    if (assetId == null) continue;

                    MaintenanceEntry me = new MaintenanceEntry();
                    me.id              = m.Id;
                    me.month           = m.Fecha_Inicio__c.month();
                    me.maintenanceDate = m.Fecha_Inicio__c;
                    me.type            = mapTipoMantencion(m.Tipo_de_Mantencion__c);

                    if (!maintenanceByAsset.containsKey(assetId)) {
                        maintenanceByAsset.put(assetId, new List<MaintenanceEntry>());
                    }
                    maintenanceByAsset.get(assetId).add(me);
                }
            }
        }

        for (Account acc : accounts) {
            AccountData ad = new AccountData();
            ad.id             = acc.Id;
            ad.name           = acc.Name;
            ad.billingCountry = acc.BillingCountry;
            ad.conglomerado   = acc.Conglomerado__c;
            ad.assets         = new List<AssetData>();

            List<Asset> accAssets = assetsByAccount.get(acc.Id);
            if (accAssets != null) {
                for (Asset a : accAssets) {
                    AssetData asd = new AssetData();
                    asd.id             = a.Id;
                    asd.name           = a.Name;
                    asd.lineOfBusiness = a.Line_of_Business__c;
                    asd.products     = productsByAsset.containsKey(a.Id)    ? productsByAsset.get(a.Id)    : new List<ProductRow>();
                    asd.competencia  = competenciaByAsset.containsKey(a.Id) ? competenciaByAsset.get(a.Id) : new List<CompetenciaRow>();
                    asd.maintenances = maintenanceByAsset.containsKey(a.Id) ? maintenanceByAsset.get(a.Id) : new List<MaintenanceEntry>();
                    ad.assets.add(asd);
                }
            }

            result.accounts.add(ad);
        }

        return result;
    }

    private static String mapTipoMantencion(String tipo) {
        if (tipo == null) return null;
        String t = tipo.trim();
        if (t.equalsIgnoreCase('Mantencion Mayor'))        return 'MM';
        if (t.equalsIgnoreCase('Mantencion de Servicios')) return 'MS';
        return t;
    }
}