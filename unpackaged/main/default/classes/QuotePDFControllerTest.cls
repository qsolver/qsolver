@isTest
public class QuotePDFControllerTest {

    @testSetup
    static void setupTestData() {
        Id standardPricebookId = Test.getStandardPricebookId();

        update new Pricebook2(
            Id = standardPricebookId,
            IsActive = true
        );

        String uniqueSuffix = String.valueOf(System.now().getTime());

        Account testAccount = new Account(
            Name = 'Cuenta de Prueba ' + uniqueSuffix
        );
        insert testAccount;

        Contact testContact = new Contact(
            LastName = 'Contacto ' + uniqueSuffix,
            AccountId = testAccount.Id,
            Email = 'test_' + uniqueSuffix + '@example.com'
        );
        insert testContact;

        Product2 testProduct = new Product2(
            Name = 'Producto ' + uniqueSuffix,
            IsActive = true,
            Description = 'Producto creado para test'
        );
        insert testProduct;

        List<PricebookEntry> stdEntries = [
            SELECT Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :standardPricebookId
            AND Product2Id = :testProduct.Id
        ];

        PricebookEntry standardEntry;

        if (stdEntries.isEmpty()) {
            standardEntry = new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = testProduct.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            insert standardEntry;
        } else {
            standardEntry = stdEntries[0];
        }

        Pricebook2 customPB = new Pricebook2(
            Name = 'PB Personalizado ' + uniqueSuffix,
            IsActive = true
        );
        insert customPB;

        PricebookEntry customEntry = new PricebookEntry(
            Pricebook2Id = customPB.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert customEntry;

        OpportunityHelper.canRunFromTestClass = false;

        Opportunity testOpp = new Opportunity(
            Name = 'Oportunidad ' + uniqueSuffix,
            AccountId = testAccount.Id,
            StageName = 'Negotiation/Review',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = customPB.Id,
            ELM_Line_Of_Business__c = 'Chancado',
            Sub_Linea_de_Negocio_OPP__c = 'Repuestos',
            Ship_Date__c = Date.today().addDays(30)
        );
        insert testOpp;

        Quote testQuote = new Quote(
            Name = 'Cotización ' + uniqueSuffix,
            OpportunityId = testOpp.Id,
            Pricebook2Id = customPB.Id,
            ContactId = testContact.Id,
            Status = 'Draft',
            Lugar_de_entrega__c = 'Bodega Principal',
            Notas__c = 'Notas de prueba'
        );
        insert testQuote;

        QuoteLineItem testQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = customEntry.Id,
            Quantity = 2,
            UnitPrice = 100.00,
            Description = 'Detalle del item'
        );
        insert testQLI;
    }

    @isTest
    static void testGenerateQuotePDF() {
        Quote q = [
            SELECT Id, Name, OpportunityId
            FROM Quote
            LIMIT 1
        ];

        PageReference pageRef = new PageReference('/apex/QuotePDFPage');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', q.Id);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(q);
        QuotePDFController controller = new QuotePDFController(stdController);
        Test.stopTest();

        Assert.isNotNull(controller, 'El controlador debe instanciarse correctamente.');
        Assert.isNotNull(controller.quoteRecord, 'La propiedad quoteRecord debe ser cargada.');
        Assert.isTrue(controller.quoteRecord.Name.startsWith('Cotización'), 'El nombre de la cotización cargada debe ser correcto.');

        Assert.isNotNull(controller.lineItems, 'La lista de ítems no debe ser nula.');
        Assert.areEqual(1, controller.lineItems.size(), 'Debe cargarse exactamente 1 línea de cotización.');
        Assert.areEqual(2, controller.lineItems[0].Quantity, 'La cantidad de la línea debe coincidir.');

        Assert.isNotNull(controller.fechaEspanol, 'La fecha en español debe ser calculada.');
        Assert.areNotEqual('', controller.fechaEspanol, 'La cadena de fecha en español no debe estar vacía.');
    }

    @isTest
    static void testFormatearFechaEspanolNull() {
        Quote q = new Quote();
        ApexPages.StandardController stdController = new ApexPages.StandardController(q);
        
        Test.startTest();
        QuotePDFController controller = new QuotePDFController(stdController);
        Test.stopTest();

        Assert.areEqual('', controller.fechaEspanol, 'Si CreatedDate es null, debe retornar una cadena vacía.');
    }
}