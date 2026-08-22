public with sharing class CreateAccountsByAsset {

    @AuraEnabled
    public static List<Account> getAccountResults(List<String> selectedAccountsIds, String filter) {
        String searchFilter = '%'+filter+'%';
        return [
            SELECT Id, Name
            FROM Account 
            WHERE (Name LIKE :searchFilter AND Id NOT IN :selectedAccountsIds AND RecordType.Name = 'Competitor')
        ];
    }

    @AuraEnabled
    public static void createJunctionRegisters(String name, String isoCode, String asset, List<String> selectedAccountsIds){

            List<ELM_Accounts_By_Asset__c> resultList = new List<ELM_Accounts_By_Asset__c>();
        
            for(String accId : selectedAccountsIds){

                ELM_Accounts_By_Asset__c junctionRegister = new ELM_Accounts_By_Asset__c(
                    Name = name,
                    CurrencyIsoCode = isoCode,
                    Asset__c = asset,
                    Account__c = accId 
                );

                System.debug('****junctionRegister: ' + junctionRegister);

                resultList.add(junctionRegister);
                
            }

            insert resultList;

    }
}