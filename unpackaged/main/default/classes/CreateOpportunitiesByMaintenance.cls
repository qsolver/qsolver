public class CreateOpportunitiesByMaintenance {
     @AuraEnabled
    public static List<Opportunity> getOpportunityResults(List<String> selectedOpportunitiesIds, String filter, String maintenanceId) {

        String searchFilter = '%'+filter+'%';

        Maintenance__c mtn = [SELECT Id, Name, Account__c, Linea_de_Negocios__c FROM Maintenance__c WHERE Id =: maintenanceId LIMIT 1];

        //if (mtn.Linea_de_Negocios__c == null) {
            // Only AccountId filter
            return [
                SELECT Id, Name, Opportunity_Number__c
                FROM Opportunity
                WHERE Name LIKE :searchFilter
                  AND Id NOT IN :selectedOpportunitiesIds
                  AND AccountId = :mtn.Account__c
                
            ];
        //} else {
            // AccountId + Line of Business filter
            //return [
                //SELECT Id, Name, Opportunity_Number__c
                //FROM Opportunity
                //WHERE Name LIKE :searchFilter
                  //AND Id NOT IN :selectedOpportunitiesIds
                  //AND AccountId = :mtn.Account__c
                  //AND ELM_Line_of_Business__c = :mtn.Linea_de_Negocios__c
                
            //];
        //}

    }

    @AuraEnabled
    public static void createJunctionRegisters(String name, String maintenance, List<String> selectedopportunitiesIds){

        List<Opportunity_by_Maintenance__c> resultList = new List<Opportunity_by_Maintenance__c>();
        
    
        for(String opptId : selectedopportunitiesIds){
                Opportunity_by_Maintenance__c junctionRegister = new Opportunity_by_Maintenance__c(
                Maintenance__c = maintenance,
                Opportunity__c = opptId 
            );
           
            resultList.add(junctionRegister);
        }
       
        insert resultList;

    }
}