@isTest
private class TestProductoPedidoClienteController {
    
    @isTest
	static void testCargaPedidos() {
    
    	// Create mock data
    	Account testAcc = new Account(Name = 'Test Account');
    	insert testAcc;
    
    	Order testOrder = new Order(AccountId = testAcc.Id, Status = 'Draft', EffectiveDate = Date.today());
    	insert testOrder;
    
    	// Mock the current page with parameters
    	PageReference testPage = Page.prodPedidoCliente;  
    	testPage.getParameters().put('id', testAcc.Id);
    	Test.setCurrentPage(testPage);
    
    	// Instantiate the controller
    	ProductoPedidoClienteController controller = new ProductoPedidoClienteController();
    
    	// Test cargaPedidos method
    	Test.startTest();
    	controller.cargaPedidos();
    	Test.stopTest();
    
    	// Asserts
    	System.assertEquals(testAcc.Id, controller.idCta, 'Expected account id does not match');
	}

    
    @isTest
    static void testGetCustomerOrders() {
        
        // Create mock data
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;
        
        Order testOrder = new Order(AccountId = testAcc.Id, Status = 'Draft', EffectiveDate = Date.today());
        insert testOrder;
        
        // Test getCustomerOrders method
        Test.startTest();
        List<Order> orders = ProductoPedidoClienteController.getCustomerOrders(testAcc.Id, 'Todas');
        List<Order> ordersFTL = ProductoPedidoClienteController.getCustomerOrders(testAcc.Id, 'FTL');
        Test.stopTest();
        
        // Asserts for Todas
        System.assertEquals(1, orders.size(), 'Expected 1 order for the account');
        System.assertEquals(testOrder.Id, orders[0].Id, 'Expected order id does not match');
        
        // Asserts for FTL
        System.assertEquals(0, ordersFTL.size(), 'Expected 1 order for the account');
    }
    
    @isTest(SeeAllData=false)
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
        
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        
        
        
        // Avoiding the duplicate pricebook entry error:
        // Before inserting, check if an entry already exists for the product in the standard pricebook.
        List<PricebookEntry> existingEntries = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :standardPricebook.Id AND Product2Id = :testProduct.Id LIMIT 1];
        
        if (existingEntries.isEmpty()) {
            PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = testProduct.Id, IsActive = true, UnitPrice = 100, CurrencyIsocode = 'USD');
            System.debug('inside of if');
            insert pbe;
        }
        
      
        PricebookEntry pbeForOrderItem = [SELECT Id, CurrencyIsocode FROM PricebookEntry WHERE Pricebook2Id = :standardPricebook.Id AND Product2Id = :testProduct.Id LIMIT 1];
        System.debug('pbeForOrderItem currency->'+pbeForOrderItem.CurrencyIsocode);
        
        OrderItem testOrderItem = new OrderItem(OrderId = testOrder.Id, Product2Id = testProduct.Id, PricebookEntryId = pbeForOrderItem.Id, Quantity = 1, UnitPrice = 100);
        insert testOrderItem;
        
        // Test getOrderItems method
        List<OrderItem> orderItems = ProductoPedidoClienteController.getOrderItems(testOrder.Id, 'Todas');
        
        // Asserts
        System.assertEquals(1, orderItems.size(), 'Expected 1 order item for the order');
        System.assertEquals(testOrderItem.Id, orderItems[0].Id, 'Expected order item id does not match');
    }
}