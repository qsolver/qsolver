public with sharing class ReporteVisionPlantaController {



    public String idCta {get; set;}


    public Pagereference showOrders(){

        idCta = ApexPages.currentPage().getParameters().get('id');

        return null;

    }
    @RemoteAction
    public static List<OrderItem> getOrderItems(String AccId, String picklistFilter){
        // Build query dynamically based on input filters
        String query = 'select id, Order.PoNumber, ELM_Peso_Neto__c, Quantity  from OrderItem where order.AccountId = :AccId';

        if (String.isNotBlank(picklistFilter) && picklistFilter != 'Todas') {

                query += ' AND Product2.Fuente_de_Suministro__c = :picklistFilter';
            
        }
        return Database.query(query);
    }

    @RemoteAction
    public static void setFullReport(String type, String AccId){

        
        List<OrderItem> orders =  getOrderItems(AccId, '');
        List<OrderItem> ordersToBeUpdated = new List<OrderItem>();
        

        for(OrderItem order: orders){
            order.Vision_Planta_Report_Type__c = type;
            ordersToBeUpdated.add(order);

        }

        if(ordersToBeUpdated.size() > 0){
            update ordersToBeUpdated;
        }
    
    }

    @RemoteAction
    public static List<Vision_Planta_Report_Type__mdt> getMetadataReportTypes(){

        List<Vision_Planta_Report_Type__mdt> reportURLS = [SELECT DeveloperName,Report_URL__c FROM Vision_Planta_Report_Type__mdt];
        System.debug('Report URL'+reportURLS);
        return reportURLS;
        

    }
}