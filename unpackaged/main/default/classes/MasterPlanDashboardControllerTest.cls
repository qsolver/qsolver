@isTest(seeAllData = false)
public with sharing class MasterPlanDashboardControllerTest {

    private static final Integer TEST_YEAR = Date.today().year();

    @TestSetup
    static void makeData() {

        Profile salesRepsProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Sales Reps'
            LIMIT 1
        ];

        User vendedor = BuilderController.anUser()
            .withProfileId(salesRepsProfile)
            .withELMEquipodeVentas('SURAMERICA')
            .build();

        insert vendedor;

        // ── Matching account (in scope) ─────────────────────────────────────
        Account matchingAccount = BuilderController.anAccount()
            .withName('Matching Account')
            .withBillingCountry('Chile')
            .withELMEquipodeVentas('SURAMERICA')
            .withVendedorAlertaTemprana(vendedor)
            .build();
        matchingAccount.Conglomerado__c = 'CODELCO';

        insert matchingAccount;

        // ── Account excluded: wrong sales team ──────────────────────────────
        Account wrongTeamAccount = BuilderController.anAccount()
            .withName('Wrong Team Account')
            .withBillingCountry('Chile')
            .withELMEquipodeVentas('NORTEAMERICA')
            .withVendedorAlertaTemprana(vendedor)
            .build();

        insert wrongTeamAccount;

        // ── Account excluded: no Vendedor Alerta Temprana ───────────────────
        Account noVendedorAccount = BuilderController.anAccount()
            .withName('No Vendedor Account')
            .withBillingCountry('Chile')
            .withELMEquipodeVentas('SURAMERICA')
            .build();

        insert noVendedorAccount;

        Asset matchingAsset = BuilderController.anAsset()
            .withName('Matching Asset')
            .withAccountId(matchingAccount)
            .withLineofBusiness('Chancado')
            .build();

        insert matchingAsset;

        Product2 product = BuilderController.aProduct2()
            .withName('Test Product')
            .build();

        insert product;

        ELM_Products_by_Asset__c junction = BuilderController.anELMProductsbyAsset()
            .withELMAsset(matchingAsset)
            .withELMProduct(product)
            .build();
        junction.Competitor__c = 'HAB';
        junction.Requerimiento_industria__c = 'Auditoria';

        insert junction;

        Maintenance__c mm = new Maintenance__c(
            Name                  = 'MM Test',
            Titulo__c             = 'Mantencion Mayor Test',
            Fecha_Inicio__c       = Date.newInstance(TEST_YEAR, 3, 15),
            Tipo_de_Mantencion__c = 'Mantencion Mayor'
        );
        Maintenance__c ms = new Maintenance__c(
            Name                  = 'MS Test',
            Titulo__c             = 'Mantencion Servicios Test',
            Fecha_Inicio__c       = Date.newInstance(TEST_YEAR, 7, 4),
            Tipo_de_Mantencion__c = 'Mantencion de Servicios'
        );
        // Prior-year record — the Enero__c..Diciembre__c formula fields on
        // Maintenance__c only key off MONTH(Fecha_Inicio__c), not the year,
        // so this must still surface under the current year's dashboard.
        Maintenance__c priorYearMm = new Maintenance__c(
            Name                  = 'MM Prior Year Test',
            Titulo__c             = 'Mantencion Mayor Prior Year Test',
            Fecha_Inicio__c       = Date.newInstance(TEST_YEAR - 1, 11, 20),
            Tipo_de_Mantencion__c = 'Mantencion Mayor'
        );
        insert new List<Maintenance__c>{ mm, ms, priorYearMm };

        insert new List<Asset_by_Maintenance__c>{
            new Asset_by_Maintenance__c(Asset__c = matchingAsset.Id, Maintenance__c = mm.Id),
            new Asset_by_Maintenance__c(Asset__c = matchingAsset.Id, Maintenance__c = ms.Id),
            new Asset_by_Maintenance__c(Asset__c = matchingAsset.Id, Maintenance__c = priorYearMm.Id)
        };
    }

    @IsTest
    static void checkDashboardDataOnlyIncludesMatchingAccounts() {

        Test.startTest();
        MasterPlanDashboardController.DashboardData result =
            MasterPlanDashboardController.getDashboardData(TEST_YEAR);
        Test.stopTest();

        System.assertEquals(1, result.accounts.size(), 'Only the matching account should be returned');

        MasterPlanDashboardController.AccountData acc = result.accounts[0];
        System.assertEquals('Matching Account', acc.name, 'Unexpected account name');
        System.assertEquals('Chile', acc.billingCountry, 'Unexpected billing country');
        System.assertEquals('CODELCO', acc.conglomerado, 'Unexpected conglomerado');
        System.assertEquals(1, acc.assets.size(), 'Expected one asset on the account');
    }

    @IsTest
    static void checkAssetProductsAndCompetenciaRows() {

        Test.startTest();
        MasterPlanDashboardController.DashboardData result =
            MasterPlanDashboardController.getDashboardData(TEST_YEAR);
        Test.stopTest();

        MasterPlanDashboardController.AssetData asset = result.accounts[0].assets[0];
        System.assertEquals('Chancado', asset.lineOfBusiness, 'Unexpected line of business');

        System.assertEquals(1, asset.products.size(), 'Expected one product row');
        System.assertEquals('Test Product', asset.products[0].productName, 'Unexpected product name');

        System.assertEquals(1, asset.competencia.size(), 'Expected one competencia row');
        System.assertEquals('HAB', asset.competencia[0].competitor, 'Unexpected competitor');
        System.assertEquals('Auditoria', asset.competencia[0].industryRequirement, 'Unexpected industry requirement');
    }

    @IsTest
    static void checkMaintenanceTypeIsMappedToAbbreviation() {

        Test.startTest();
        MasterPlanDashboardController.DashboardData result =
            MasterPlanDashboardController.getDashboardData(TEST_YEAR);
        Test.stopTest();

        MasterPlanDashboardController.AssetData asset = result.accounts[0].assets[0];
        System.assertEquals(3, asset.maintenances.size(), 'Expected three maintenance entries');

        Map<Integer, String> typeByMonth = new Map<Integer, String>();
        for (MasterPlanDashboardController.MaintenanceEntry me : asset.maintenances) {
            typeByMonth.put(me.month, me.type);
        }

        System.assertEquals('MM', typeByMonth.get(3), 'March entry should map to MM');
        System.assertEquals('MS', typeByMonth.get(7), 'July entry should map to MS');
    }

    @IsTest
    static void checkMaintenanceMatchesByMonthRegardlessOfYear() {

        Test.startTest();
        MasterPlanDashboardController.DashboardData result =
            MasterPlanDashboardController.getDashboardData(TEST_YEAR);
        Test.stopTest();

        MasterPlanDashboardController.AssetData asset = result.accounts[0].assets[0];

        MasterPlanDashboardController.MaintenanceEntry priorYearEntry = null;
        for (MasterPlanDashboardController.MaintenanceEntry me : asset.maintenances) {
            if (me.month == 11) {
                priorYearEntry = me;
            }
        }

        System.assertNotEquals(null, priorYearEntry, 'A prior-year November maintenance should still surface');
        System.assertEquals('MM', priorYearEntry.type, 'Prior-year November entry should map to MM');
        System.assertEquals(TEST_YEAR - 1, priorYearEntry.maintenanceDate.year(), 'Sanity check: entry is really from the prior year');
    }

    @IsTest
    static void checkNullYearDefaultsToCurrentYear() {

        Test.startTest();
        MasterPlanDashboardController.DashboardData result =
            MasterPlanDashboardController.getDashboardData(null);
        Test.stopTest();

        System.assertEquals(Date.today().year(), result.year, 'Null year should default to the current year');
    }
}