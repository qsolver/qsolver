public with sharing class OpportunityMonthlyAmountController {
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunities(){
        List<Opportunity> opps = new List<Opportunity>();
        opps = [SELECT Id, Name, Account.Name, Account.Id, Amount, CloseDate, CreatedDate, Ship_Date__c, ELM_Total_Tons__c,  Cantidad_de_entregas_de_venta__c, CurrencyIsoCode, CreatedById, ELM_Equipo_de_Ventas__c, StageName, ELM_GM_Opp_Type__c  FROM Opportunity WHERE RecordType.name = 'Grinding Media / GET'];
        return opps;
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getGMUsers(){
        List<User> users = new List<User>();
        users = [SELECT Id, Name, Username, Profile.Name FROM user where Profile.Name = 'Sales Reps GM' AND Division != 'GET Chile'];
        return users;
    }
}