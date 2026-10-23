@isTest
private class QuoteLineItemsEditorControllerTest {

    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Id standardPricebookId = Test.getStandardPricebookId();
        update new Pricebook2(Id = standardPricebookId, IsActive = true);

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            Amount = 10000,
            CloseDate = Date.today().addMonths(1),
            Ship_Date__c = Date.today().addMonths(1),
            Cantidad_de_entregas_de_venta__c = '2',
            CurrencyIsoCode = 'USD',
            StageName = 'Prospecting',
            ELM_GM_Opp_Type__c = 'Product Test',
            ELM_Line_of_Business__c = 'Bolas (Grinding Media)',
            Pricebook2Id = standardPricebookId,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Grinding_Media').getRecordTypeId()
        );
        insert testOpportunity;

        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Test Product 1', IsActive = true),
            new Product2(Name = 'Test Product 2', IsActive = true)
        };
        insert products;

        Map<Id, PricebookEntry> entriesByProduct = new Map<Id, PricebookEntry>();
        for (PricebookEntry entry : [
            SELECT Id, Product2Id FROM PricebookEntry
            WHERE Pricebook2Id = :standardPricebookId AND Product2Id IN :products AND CurrencyIsoCode = 'USD'
        ]) {
            entriesByProduct.put(entry.Product2Id, entry);
        }
        List<PricebookEntry> newEntries = new List<PricebookEntry>();
        for (Product2 product : products) {
            if (!entriesByProduct.containsKey(product.Id)) {
                newEntries.add(new PricebookEntry(
                    Pricebook2Id = standardPricebookId, Product2Id = product.Id,
                    IsActive = true, UnitPrice = 100, CurrencyIsoCode = 'USD'
                ));
            }
        }
        insert newEntries;
        for (PricebookEntry entry : newEntries) {
            entriesByProduct.put(entry.Product2Id, entry);
        }

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            Pricebook2Id = standardPricebookId
        );
        insert testQuote;

        List<QuoteLineItem> lineItems = new List<QuoteLineItem>();
        for (Product2 product : products) {
            lineItems.add(new QuoteLineItem(
                QuoteId = testQuote.Id,
                Product2Id = product.Id,
                PricebookEntryId = entriesByProduct.get(product.Id).Id,
                Quantity = 1,
                UnitPrice = 10
            ));
        }
        insert lineItems;
    }

    @isTest
    static void getEditorDataReturnsColumnsAndLineItems() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        QuoteLineItemsEditorController.EditorData data = QuoteLineItemsEditorController.getEditorData(testQuote.Id);
        Test.stopTest();

        Assert.areEqual(2, data.lineItems.size(), 'Deben retornarse los dos productos de la Quote');
        Assert.isFalse(data.columns.isEmpty(), 'Debe haber al menos una columna');
        Assert.isNotNull(data.canConfigure, 'canConfigure siempre debe venir informado');
        Assert.isNotNull(data.configUrl, 'Debe venir la URL de configuracion');

        Set<String> columnNames = new Set<String>();
        for (QuoteLineItemsEditorController.ColumnInfo column : data.columns) {
            columnNames.add(column.fieldApiName);
        }
        Assert.isTrue(columnNames.contains('Quantity'), 'Quantity debe estar entre las columnas');
        Assert.isFalse(columnNames.contains('Product2Id'), 'El producto es una columna fija, no configurable');
    }

    @isTest
    static void getEditorDataWithoutLineItemsReturnsEmptyList() {
        Test.startTest();
        QuoteLineItemsEditorController.EditorData data = QuoteLineItemsEditorController.getEditorData(null);
        Test.stopTest();
        Assert.isTrue(data.lineItems.isEmpty(), 'Sin Quote no deben retornarse productos');
    }

    @isTest
    static void saveLineItemsUpdatesRecords() {
        List<QuoteLineItem> lineItems = [SELECT Id FROM QuoteLineItem ORDER BY Product2.Name];
        Map<String, Object> changes = new Map<String, Object>{
            lineItems[0].Id => new Map<String, Object>{ 'Quantity' => '3', 'Description' => 'Copiado' },
            lineItems[1].Id => new Map<String, Object>{ 'Quantity' => 5, 'Description' => 'Copiado' }
        };

        Test.startTest();
        List<QuoteLineItemsEditorController.RowError> errors =
            QuoteLineItemsEditorController.saveLineItems(JSON.serialize(changes));
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'No deben haber errores: ' + JSON.serialize(errors));
        for (QuoteLineItem item : [SELECT Quantity, Description FROM QuoteLineItem]) {
            Assert.areEqual('Copiado', item.Description, 'La descripcion debe actualizarse');
        }
        Assert.areEqual(3, [SELECT Quantity FROM QuoteLineItem WHERE Id = :lineItems[0].Id].Quantity, 'Quantity debe actualizarse');
    }

    @isTest
    static void saveLineItemsReturnsRowErrors() {
        QuoteLineItem item = [SELECT Id FROM QuoteLineItem LIMIT 1];
        // Quantity en cero no es valida en QuoteLineItem
        Map<String, Object> changes = new Map<String, Object>{
            item.Id => new Map<String, Object>{ 'Quantity' => 0 }
        };

        Test.startTest();
        List<QuoteLineItemsEditorController.RowError> errors =
            QuoteLineItemsEditorController.saveLineItems(JSON.serialize(changes));
        Test.stopTest();

        Assert.areEqual(1, errors.size(), 'Debe retornarse el error de la fila');
        Assert.areEqual(String.valueOf(item.Id), errors[0].recordId, 'El error debe indicar el registro');
    }

    @isTest
    static void saveLineItemsRejectsNonUpdateableField() {
        QuoteLineItem item = [SELECT Id FROM QuoteLineItem LIMIT 1];
        Map<String, Object> changes = new Map<String, Object>{
            item.Id => new Map<String, Object>{ 'ListPrice' => 1 }
        };

        Boolean thrown = false;
        Test.startTest();
        try {
            QuoteLineItemsEditorController.saveLineItems(JSON.serialize(changes));
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();
        Assert.isTrue(thrown, 'Un campo no editable debe ser rechazado');
    }

    @isTest
    static void saveLineItemsRejectsInvalidJson() {
        Boolean thrown = false;
        try {
            QuoteLineItemsEditorController.saveLineItems('no-es-json');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Un JSON invalido debe ser rechazado');
    }

    @isTest
    static void coerceValueHandlesFieldTypes() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.QuoteLineItem.fields.getMap();

        Assert.areEqual(2.5, QuoteLineItemsEditorController.coerceValue('2.5', fields.get('quantity').getDescribe()));
        Assert.areEqual(Date.newInstance(2026, 10, 19),
            QuoteLineItemsEditorController.coerceValue('2026-10-19', fields.get('servicedate').getDescribe()));
        Assert.areEqual('texto', QuoteLineItemsEditorController.coerceValue('texto', fields.get('description').getDescribe()));
        Assert.isNull(QuoteLineItemsEditorController.coerceValue('', fields.get('description').getDescribe()));
        Assert.areEqual(true,
            QuoteLineItemsEditorController.coerceValue(true, fields.get('copiar_datos_de_producto__c').getDescribe()));
        Assert.areEqual(false,
            QuoteLineItemsEditorController.coerceValue(null, fields.get('copiar_datos_de_producto__c').getDescribe()));
    }

    @isTest
    static void canConfigureReturnsValue() {
        Assert.isNotNull(QuoteLineItemsEditorController.canConfigure(), 'Debe retornar true o false');
    }
}