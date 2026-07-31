@isTest
private class TestReporteVisionPlanta {
    @isTest
	static void testShowOrders() {
    
    	// Create mock data
    	Account testAcc = new Account(Name = 'Test Account');
    	insert testAcc;
    
    	Order testOrder = new Order(AccountId = testAcc.Id, Status = 'Draft', EffectiveDate = Date.today());
    	insert testOrder;
    
    	// Mock the current page with parameters
    	PageReference testPage = Page.reporteVisionPlanta;  
    	testPage.getParameters().put('id', testAcc.Id);
    	Test.setCurrentPage(testPage);
    
    	// Instantiate the controller
    	ReporteVisionPlantaController controller = new ReporteVisionPlantaController();
    
    	// Test cargaPedidos method
    	Test.startTest();
    	controller.showOrders();
    	Test.stopTest();
    
    	// Asserts
    	System.assertEquals(testAcc.Id, controller.idCta, 'Expected account id does not match');
	}

    @isTest
    static void testGetOrderItems() {
        
        // Create mock data
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;
        
        
        // Instantiate the Pricebook2 record first, setting the Id
		Pricebook2 standardPricebook = new Pricebook2(
			Id = Test.getStandardPricebookId(),
			IsActive = true
		);

        
		// Run an update DML on the Pricebook2 record
		// on the PricebookEntry record
		update standardPricebook;
        
        Order testOrder = new Order(AccountId = testAcc.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = standardPricebook.Id, CurrencyIsocode = 'USD');
        insert testOrder;
        
        Asset asset = new Asset(Name = 'Test Asset', ELM_Asset_Number__c = '12324', ELM_ExternalId__c = '1234'); 
        insert asset;
        
		Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
 		insert testProduct;

        
        // Before inserting, check if an entry already exists for the product in the standard pricebook.
        List<PricebookEntry> existingEntries = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :standardPricebook.Id AND Product2Id = :testProduct.Id LIMIT 1];
        
        if (existingEntries.isEmpty()) {
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = testProduct.Id, IsActive = true, UnitPrice = 100, CurrencyIsocode = 'USD');
            insert pbe;
        }
        
      
        PricebookEntry pbeForOrderItem = [SELECT Id, CurrencyIsocode FROM PricebookEntry WHERE Pricebook2Id = :standardPricebook.Id AND Product2Id = :testProduct.Id LIMIT 1];
        System.debug('pbeForOrderItem currency->'+pbeForOrderItem.CurrencyIsocode);
        
        OrderItem testOrderItem = new OrderItem(OrderId = testOrder.Id, Product2Id = testProduct.Id, PricebookEntryId = pbeForOrderItem.Id, Quantity = 1, UnitPrice = 100);
        insert testOrderItem;
        
        // Test getOrderItems method
        Test.startTest();
        List<OrderItem> orderItems = ReporteVisionPlantaController.getOrderItems(testAcc.Id, 'Todas');
        Test.stopTest();
        
        // Asserts
        System.assertEquals(1, orderItems.size(), 'Expected 1 order item for the order');
        System.assertEquals(testOrderItem.Id, orderItems[0].Id, 'Expected order item id does not match');
    }
    
    @isTest
    static void testsetFullReport() {
        
        // Create mock data
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;
        
        
        // Instantiate the Pricebook2 record first, setting the Id
		Pricebook2 standardPricebook = new Pricebook2(
			Id = Test.getStandardPricebookId(),
			IsActive = true
		);

        
		// Run an update DML on the Pricebook2 record
		// on the PricebookEntry record
		update standardPricebook;
        
        Order testOrder = new Order(AccountId = testAcc.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = standardPricebook.Id, CurrencyIsocode = 'USD');
        insert testOrder;
        
        
		Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
 		insert testProduct;

        
        // Before inserting, check if an entry already exists for the product in the standard pricebook.
        List<PricebookEntry> existingEntries = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :standardPricebook.Id AND Product2Id = :testProduct.Id LIMIT 1];
        
        if (existingEntries.isEmpty()) {
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = testProduct.Id, IsActive = true, UnitPrice = 100, CurrencyIsocode = 'USD');
            insert pbe;
        }
        
      
        PricebookEntry pbeForOrderItem = [SELECT Id, CurrencyIsocode FROM PricebookEntry WHERE Pricebook2Id = :standardPricebook.Id AND Product2Id = :testProduct.Id LIMIT 1];
        System.debug('pbeForOrderItem currency->'+pbeForOrderItem.CurrencyIsocode);
        
        OrderItem testOrderItem = new OrderItem(OrderId = testOrder.Id, Product2Id = testProduct.Id, PricebookEntryId = pbeForOrderItem.Id, Quantity = 1, UnitPrice = 100);
        insert testOrderItem;
        
        // Test setFullReport method
        Test.startTest();
        ReporteVisionPlantaController.setFullReport('total', testAcc.Id);
        OrderItem orderItemFieldSet = [select id, Vision_Planta_Report_Type__c from OrderItem where order.AccountId =:testAcc.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('total', orderItemFieldSet.Vision_Planta_Report_Type__c, 'Expected total');
        
        
    }
    
    @isTest
    static void testGetMetadataReportTypes(){
        
        Test.startTest();
        List<Vision_Planta_Report_Type__mdt> listMedatataResportType =  ReporteVisionPlantaController.getMetadataReportTypes();
        Test.stopTest();
        
        System.assert(listMedatataResportType.size() > 0, 'Expected total');
        
    }


}