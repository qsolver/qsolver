public with sharing class ContentVersionHelper {

    static List<ELM_File_Link__c> fileLinksToInsert = new List<ELM_File_Link__c>();

    public static List<ELM_File_Link__c> createFileLink(Map<Id, ContentVersion> contentVersionByFirstPublishedId, String sObj) {

        Set<Id> keys = contentVersionByFirstPublishedId.keySet();

        String query = 'SELECT Id';

        if (sObj == 'Task') {
            
            query += ', Subject';
        }else {
            
            query += ', Name';
        }

        if(sObj == 'Opportunity'){

            query += ', StageName';
        }else if(sObj == 'Contract' || sObj == 'Quote' || 
            sObj == 'Order' || sObj == 'Task' || sObj == 'Lead' ){

            query += ', Status';
        }else if(sObj == 'ELM_Vaes__c' || sObj == 'Asset_Request__c'){

            query += ', ELM_Status__c';
        }

        if (sObj == 'Contract' || sObj == 'Order') {
            
            query += ', ' + sObj + 'Number';
        }

        query += ' FROM '+ sObj + ' WHERE Id IN ';
        query += ':keys';

        List<sObject> sObjList = Database.query(query);


        for (SObject obj : sObjList) {

            Id objId = (Id)obj.get('Id');
                
            if (contentVersionByFirstPublishedId.containsKey(objId)) {

                ELM_File_Link__c fileLink = new ELM_File_Link__c();
                fileLink.ELM_Object_Name__c = sObj; 
                fileLink.ELM_Title__c = contentVersionByFirstPublishedId.get(objId).Title + '.' 
                    + contentVersionByFirstPublishedId.get(objId).FileType;
                fileLink.ELM_Document_Path__c = 'https://me-elecmetal.lightning.force.com/lightning/r/ContentDocument/' 
                    + contentVersionByFirstPublishedId.get(objId).ContentDocumentId + '/view';
                fileLink.ELM_Document_Created_By__c = contentVersionByFirstPublishedId.get(objId).OwnerId;
                fileLink.ELM_Document_Creation_Date__c = System.now();
                fileLink.ELM_Content_Version_Id__c = contentVersionByFirstPublishedId.get(objId).ContentDocumentId;

                if (sObj == 'Opportunity') {

                    fileLink.ELM_Stage__c = (String) obj.get('StageName');
                }else if(sObj == 'Contract' || sObj == 'Quote' || 
                    sObj == 'Order' || sObj == 'Task' || sObj == 'Lead' ){

                    fileLink.ELM_Stage__c = (String) obj.get('Status');
                }else if(sObj == 'ELM_Vaes__c' || sObj == 'Asset_Request__c'){

                    fileLink.ELM_Stage__c = (String) obj.get('ELM_Status__c');
                }else{

                    fileLink.ELM_Stage__c = 'N/A';    
                }

                if (sObj == 'Contract') {

                    fileLink.ELM_Registry_Name__c = (String)obj.get('ContractNumber');
                }else if (sObj == 'Order') {

                    fileLink.ELM_Registry_Name__c = (String)obj.get('OrderNumber');
                }else {
                    
                    if (sObj == 'Task') {

                        fileLink.ELM_Registry_Name__c = (String)obj.get('Subject');
                    }else {

                        fileLink.ELM_Registry_Name__c = (String)obj.get('Name');    
                    }
                }
                
                fileLinksToInsert.add(fileLink);

            }

        }
        
        return fileLinksToInsert;

    }


}