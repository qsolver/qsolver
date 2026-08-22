public with sharing class AssetHelper {

    public static void validateInsertionByUser(List<Asset> assets, Map<Id, Account> accountsById) {
        
        Id userId = UserInfo.getUserId();
        Id userProfileId = UserInfo.getProfileId();

        Profile adminProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Administrador del sistema' OR Name = '系统管理员'
            LIMIT 1
        ];
        
        Profile integratorProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Integrator'
            LIMIT 1
        ];

        User user = [
            SELECT Id, ELM_Equipo_de_Ventas__c, Alias, Profile.Name
            FROM User
            WHERE Id =: userId
            LIMIT 1
        ];

        accountsById.remove(null);
        accountsById.putAll([
            SELECT Id, ELM_Equipo_de_Ventas__c
            FROM Account
            WHERE Id
            IN : accountsById.keySet()
        ]);

        for (Asset asset : assets) {
            
            if (accountsById.containsKey(asset.AccountId)) {

                if (userProfileId != adminProfile.Id && userProfileId != integratorProfile.Id) {
                    
                    if (user.ELM_Equipo_de_Ventas__c != accountsById.get(asset.AccountId).ELM_Equipo_de_Ventas__c) {
                    
                        asset.addError('Your sales team needs to match the client sales team to create the asset // Tu sales team tiene que ser igual que el sales team de la cuenta para poder crear el asset');
                    }
                }
            }
        }
    }
    
    public static void validateUpdateByUser(List<Asset> assets) {
        
        Id userId = UserInfo.getUserId();
        Id userProfileId = UserInfo.getProfileId();

        Profile adminProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Administrador del sistema' OR Name = '系统管理员'
            LIMIT 1
        ];
        
        Profile integratorProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Integrator'
            LIMIT 1
        ];

        User user = [
            SELECT Id, ELM_Equipo_de_Ventas__c
            FROM User
            WHERE Id =: userId
            LIMIT 1
        ];

        for (Asset asset : assets) {
            
            String user_sales_team = '';
            if(!String.isBlank(user.ELM_Equipo_de_Ventas__c)){
                
                if(user.ELM_Equipo_de_Ventas__c == 'NORTEAMERICA' || user.ELM_Equipo_de_Ventas__c == 'SURAMERICA'){
                    user_sales_team = user.ELM_Equipo_de_Ventas__c == 'NORTEAMERICA'?'NorthAmerica':'SouthAmerica';
                }else{
                    user_sales_team = user.ELM_Equipo_de_Ventas__c;
                }
                
                
            }
            
            
            if (userProfileId != adminProfile.Id) {
                
                if (user_sales_team != asset.ELM_Sales_Team__c && userProfileId != integratorProfile.Id) {
                    
                    asset.addError('Your Sales Team needs to match the client Sales Team to update the asset // Tu Sales Team tiene que ser igual que el sales team de la cuenta para poder actualizar el asset');
                }
            }
        }
    }
}