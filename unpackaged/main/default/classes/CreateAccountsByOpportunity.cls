public without sharing class CreateAccountsByOpportunity {

    @AuraEnabled
    public static List<Account> getAccountResults(List<Id> selectedAccountsIds, String filter) {
        String searchFilter = '%'+filter+'%';
        return [
            SELECT Id, Name 
            FROM Account 
            WHERE (Name LIKE :searchFilter AND Id NOT IN :selectedAccountsIds AND Type = 'Competitor')
            WITH SECURITY_ENFORCED
            ];
    }

    @AuraEnabled
    public static void createJunctionRegisters(String name, String isoCode, String opportunity, List<String> selectedAccountsIds){

        List<Accounts_by_Opportunity__c> resultList = new List<Accounts_by_Opportunity__c>();
    
        for(String accId : selectedAccountsIds){
            Accounts_by_Opportunity__c junctionRegister = new Accounts_by_Opportunity__c(
                Name = name,
                CurrencyIsoCode = isoCode,
                Opportunity__c = opportunity,
                Account__c = accId 
            );
            System.debug(Schema.sObjectType.Accounts_by_Opportunity__c.fields.Opportunity__c.isAccessible());
            resultList.add(junctionRegister);
        }
        insert resultList;
    
    }
}