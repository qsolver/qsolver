public with sharing class ProductoPedidoClienteController {

    public List<Order> pedidosCliente {get;set;}
    public List<OrderItem> productosPedido {get; set;}
    public String idCta {get; set;}

    public Pagereference cargaPedidos(){

        idCta = ApexPages.currentPage().getParameters().get('id');

        return null;

    }

    @RemoteAction
    public static List<Order> getCustomerOrders(String AccId, String picklistFilter){
        List<Order> order = new List<Order>();
        order = [select id, ordernumber, PoNumber, ELM_Pedido_SAP__c, ELM_Fecha_Entrega__c, tolabel(status), PoDate from order where AccountId = :AccId order by poDate Desc];

        // Add condition based on the picklist filter
        if (String.isNotBlank(picklistFilter) && picklistFilter != 'Todas') {

            List<OrderItem> ordersItem = [SELECT Order.Id  FROM OrderItem WHERE Order.AccountId = :AccId AND Product2.Fuente_de_Suministro__c = :picklistFilter];
            List<Id> ordersItemIds = new List<Id>();

            for(OrderItem oi: ordersItem){
                ordersItemIds.add(oi.OrderId);

            }
        
            order = [select id, ordernumber, PoNumber, ELM_Pedido_SAP__c, ELM_Fecha_Entrega__c, tolabel(status), PoDate from order where id IN :ordersItemIds order by poDate Desc];

        }

        System.debug('ORderData = > '+order);

        return order;
    }

    @RemoteAction
    public static List<OrderItem> getOrderItems(String OrdId, String picklistFilter){
        
        List<OrderItem> OrderItems = new List<OrderItem>();
        
        OrderItems =  [select Id, ELM_Programado__c, ELM_Por_programar__c,ELM_Por_Fundir__c, ELM_Fundida__c, ELM_Desmoldeo__c,
            ELM_Tratamiento_Termico__c,ELM_Calidad_de_Tratamiento_Termico__c, ELM_Terminaciones__c, ELM_Inspeccion_Externa__c, 
            ELM_Pendiente_Vulcanizado__c, ELM_Rechazo_Inspeccion_Externa__c, ELM_Bodega__c, ELM_Agendado__c,ELM_Despachado__c, OrderId, Order.OrderNumber, 
            Product2Id, Product2.Name, Product2.ProductCode, Quantity, ELM_Fecha_Entrega_SKU__c
            from OrderItem where OrderId =: OrdId
        ];

        

        if (String.isNotBlank(picklistFilter) && picklistFilter != 'Todas') {

            OrderItems = [select Id, ELM_Programado__c, ELM_Por_programar__c,ELM_Por_Fundir__c, ELM_Fundida__c, ELM_Desmoldeo__c,
            ELM_Tratamiento_Termico__c,ELM_Calidad_de_Tratamiento_Termico__c, ELM_Terminaciones__c, ELM_Inspeccion_Externa__c, 
            ELM_Pendiente_Vulcanizado__c, ELM_Rechazo_Inspeccion_Externa__c, ELM_Bodega__c, ELM_Agendado__c,ELM_Despachado__c, OrderId, Order.OrderNumber, 
            Product2Id, Product2.Name, Product2.ProductCode, Quantity, ELM_Fecha_Entrega_SKU__c
            from OrderItem where OrderId =: OrdId AND Product2.Fuente_de_Suministro__c = :picklistFilter
        ];

        }

        return OrderItems;
    }

}