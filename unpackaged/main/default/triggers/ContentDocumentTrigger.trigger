trigger ContentDocumentTrigger on ContentDocument (before delete) {

    if (Trigger.isBefore) {

        if (Trigger.isDelete) {

            List<ELM_File_Link__c> fileLinks = [
                SELECT Id
                FROM ELM_File_Link__c
                WHERE ELM_Content_Version_Id__c IN : Trigger.oldMap.keySet()
            ];

            if (fileLinks.size() > 0) {

                delete fileLinks;

            }

        }
        
    }

}