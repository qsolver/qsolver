public with sharing class Product2Actions {

    public static void updateRelatedAssets(List<Product2> productos){
        system.debug('Assets v1: '+ productos[0].ELM_ASSETS__c);
        List<String> assetCode = new List<String>();
        List<EM_ASSETSMATERIALS__c> assetByMaterial = new List<EM_ASSETSMATERIALS__c>();
        List<EM_ASSETSMATERIALS__c> assetByMaterialDelete = new List<EM_ASSETSMATERIALS__c>();
        String assetsCodes = productos[0].ELM_ASSETS__c;
        assetsCodes = assetsCodes.trim();
        assetsCodes = assetsCodes.remove('[');
        assetsCodes = assetsCodes.remove(']');
        system.debug('Assets v2: '+ assetsCodes);
        while(String.isNotEmpty(assetsCodes)){
            if(assetsCodes.contains(',')){
                if((!String.isBlank(productos[0].StockKeepingUnit))){
                    if(!productos[0].StockKeepingUnit.contains('INVALID PRE SAP INTEGRATION')){
                		assetCode.add(assetsCodes.substringBefore(',') + '-' +productos[0].StockKeepingUnit);
                    }else{
                        assetCode.add(assetsCodes.substringBefore(','));
                    }
                }else{
                    assetCode.add(assetsCodes.substringBefore(','));
                }
                assetsCodes = assetsCodes.substringAfter(',');  
            }else{
                if(!String.isBlank(productos[0].StockKeepingUnit)){
                    if(!productos[0].StockKeepingUnit.contains('INVALID PRE SAP INTEGRATION')){
                		assetCode.add(assetsCodes + '-' +productos[0].StockKeepingUnit);
                    }else{
                        assetCode.add(assetsCodes);
                    }
                }else{
                    assetCode.add(assetsCodes);
                }
                assetsCodes = '';
            }                      
        }
        for(String abym:assetCode){
            EM_ASSETSMATERIALS__c abm = new EM_ASSETSMATERIALS__c();
            abm.EM_EXTERNALID__c=abym;
            abm.Name=abym;
            abm.EM_MATERIAL__c=productos[0].Id;
            String cod = '';
            if(abym.contains('-')){
            	cod = abym.substringBefore('-');
            }else{
                cod = abym;
            }
            abm.EM_ASSET__c = [SELECT Id FROM Asset WHERE ELM_ExternalId__c=:cod].Id;
            assetByMaterial.add(abm);
        }            
        try{
            assetByMaterialDelete = [SELECT Id FROM EM_ASSETSMATERIALS__c WHERE EM_MATERIAL__c =: productos[0].Id];
            if(assetByMaterialDelete.size() > 0) delete assetByMaterialDelete;
            if(assetByMaterial.size() > 0) insert assetByMaterial;
        }catch(DMLException dmlEX){
            system.debug('@@@@ You can not delete and insert record Releted Assets - ' + dmlEx.getMessage() );
        }
    }
}