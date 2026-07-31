/**
 * @description       : 
 * @author            : dhurtado@neox.cl
 * @group             : 
 * @last modified on  : 03-28-2025
 * @last modified by  : dhurtado@neox.cl
**/
public with sharing class manageVAESEmailSend {

    private static final String oClass = 'manageVAESEmailSend';

    public manageVAESEmailSend() {

    }

    public static Trip_Report_Setting__mdt GetSettings() {

        String oMethod = 'GetSettings';

        List<Trip_Report_Setting__mdt> oSettings = [SELECT MasterLabel, Disabled__c, Group_Name__c, Additional_Emails__c,
                                                    Email_Template_DeveloperName__c, Exception_Emails__c
                                                    FROM Trip_Report_Setting__mdt Where MasterLabel = 'Default'];

        Trip_Report_Setting__mdt oSetting;

        if (oSettings.size() > 0) {
            oSetting = oSettings[0];
        } else if (Test.isRunningTest() == false) {
            System.Debug(oClass +'.'+oMethod+';'+' Trip_Report_Setting__mdt MetaDataType Record is missing');
        }

        return oSetting;

    }



    @AuraEnabled //(cacheable=true)
    public static List<ContentVersion> getAttachments(String oRecordId) {
        String oMethod = 'getAttachments';

        System.Debug(oClass + '.' + oMethod + '; Enter');
        List<ContentDocumentLink> oContentDocumentLinks = [SELECT id, LinkedEntityId, ContentDocumentId 
                                                            FROM ContentDocumentLink WHERE LinkedEntityId =:oRecordId];

        Set<Id> oSetIds = new Set<Id>();
        for(ContentDocumentLink oLink : oContentDocumentLinks) {
            oSetIds.add(oLink.ContentDocumentId);
        }

        return [SELECT Id, Title, FileExtension, ContentSize FROM ContentVersion WHERE contentDocumentId IN :oSetIds];

    }

    @AuraEnabled //(cacheable=true)
    public static List<String> getEmails() {

        String oMethod = 'getEmails';

        System.Debug(oClass + '.' + oMethod + '; Enter');
        List<String> oAddresses = new List<String>();
        //To get save SA Groups Names
        List<VAES_Email_Groups__mdt> SAGroups = new List<VAES_Email_Groups__mdt>();

        try {

            Trip_Report_Setting__mdt oSetting = GetSettings();

            Group g = [SELECT id, Name, (select userOrGroupId from GroupMembers) FROM group Where Name = :oSetting.Group_Name__c];


            SAGroups = [SELECT MasterLabel FROM VAES_Email_Groups__mdt];

            if (String.isNotBlank(oSetting.Additional_Emails__c)) {
                String s                        = oSetting.Additional_Emails__c.Replace(' ','');
                List<String> oAdditionalEmails  = new List<String>();
                oAdditionalEmails = s.split(',');
                for (String oAdditionalEmail : oAdditionalEmails) {
                    oAddresses.add(oAdditionalEmail);
                }
            }


        } catch(Exception e) {
            System.Debug(oClass + '.' + oMethod + '; Exception: ' + e.getMessage());
        }

        //Add SA Groups Names
        if(SAGroups.size() > 0){
            for(VAES_Email_Groups__mdt sa_g : SAGroups){

                oAddresses.add(sa_g.MasterLabel);
            }
        }

        return oAddresses;

    }



    //Add SA Groups emails
    public static List<String> addSAGroupsEmails(List<String> oAddresses){

        //Set<Id> oUserIds = new Set<Id>();
        List<VAES_Email_Groups__mdt> grps = new List<VAES_Email_Groups__mdt>();
        List<String> oAddressesRT = new List<String>();



        //Gets all SA emails from metadata groups
        grps = [SELECT MasterLabel, Emails_to_VAES__c FROM VAES_Email_Groups__mdt Where MasterLabel IN : oAddresses];

        System.debug('Groups => '+grps);



        //add emails

        for (String em : oAddresses) {
            if(em.contains('@')){
                oAddressesRT.add(em);

            }
        }


        if(grps.size() > 0){
            for(VAES_Email_Groups__mdt groupRecord : grps){

                if (String.isNotBlank(groupRecord.Emails_to_VAES__c)) {

                    String s = groupRecord.Emails_to_VAES__c.Replace(' ','');
                    List<String> groupEmails  = new List<String>();
                    groupEmails = s.split(',');

                    for (String em : groupEmails) {
                        oAddressesRT.add(em);
                    }
                }
            }
        }


        return oAddressesRT;

    }


    @AuraEnabled //(cacheable=true)
    public static void sendVAES(String oRecordId, List<String> oAddresses, List<String> oSelectedAttachments, String emailSubject, String emailBody, Boolean isInternal) {

        List<String> oAddressesRT =  addSAGroupsEmails(oAddresses);

        String oMethod = 'sendVAES';

        Id userContextId = UserInfo.getUserId();

        System.Debug(oClass + '.' + oMethod + '; Enter');

        if (String.isBlank(oRecordId)) { return; }
        if (oAddressesRT.size() == 0) { return; }
        // if (oSelectedAttachments.size() == 0) { return; }

        try {

            Contact ct = [SELECT Id FROM Contact LIMIT 1];
            ELM_Vaes__c VAES_record = [SELECT Id, Name, ELM_Project_Name__c, ELM_Account__r.Name FROM ELM_Vaes__c where Id =:oRecordId limit 1];
            EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName ='VAES_Send_Internal_Email'];
            EmailTemplate etEnglish = [SELECT Id FROM EmailTemplate WHERE DeveloperName ='VAES_Send_Internal_Email_English'];
            User userContext = [SELECT Id, ELM_Equipo_de_Ventas__c  FROM User WHERE Id=:userContextId LIMIT 1];

            // Create a new SingleEmailMessage instance
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();


            System.debug('After Getting VAES record');


            if(isInternal){

                System.debug('IsInternal = '+isInternal);

                // Set subject and body
                if(userContext.ELM_Equipo_de_Ventas__c  == 'SURAMERICA'){
                    email = Messaging.renderStoredEmailTemplate(et.Id, ct.Id, VAES_record.Id); //DEHR - 27/03/2025
                }else{
                    email = Messaging.renderStoredEmailTemplate(etEnglish.Id, ct.Id, VAES_record.Id); //DEHR - 27/03/2025
                }
                String additionalBody = '<br/><br/>' + emailBody; //DEHR - 27/03/2025
                email.setHtmlBody(email.getHtmlBody().unescapeHtml4() + additionalBody); //DEHR - 27/03/2025
                email.setSaveAsActivity(false);
                email.setUseSignature(false);
                email.setTreatTargetObjectAsRecipient(false);
            }else{
                email.setSubject(emailSubject);
                email.setPlainTextBody(emailBody);
            }


            List<Messaging.Emailfileattachment> oAttachments = new List<Messaging.Emailfileattachment>();



            Set<Id> oSetIds = new Set<Id>();


            if (oSelectedAttachments.size() > 0) {
                for (String s : oSelectedAttachments) {
                    oSetIds.add(s);
                }

                System.Debug(oClass + '.' + oMethod + '; List of contentDocumentId: ' + oSetIds);
                System.Debug('oSelectedAttachments' + oSelectedAttachments);


                List<ContentVersion> oContentVersions = [SELECT Id, Title, VersionData, FileExtension FROM ContentVersion WHERE Id IN :oSetIds];

                System.Debug(oClass + '.' + oMethod + '; List of oContentVersions: ' + oContentVersions);

                for (ContentVersion oContentVersion : oContentVersions) {
                    Messaging.Emailfileattachment oEmailfileattachment = new Messaging.Emailfileattachment();
                    Blob oDocumentContentBlob   = oContentVersion.VersionData;
                    oEmailfileattachment.setFileName(oContentVersion.Title + '.' + oContentVersion.FileExtension);
                    oEmailfileattachment.setBody(oDocumentContentBlob);
                    oAttachments.add(oEmailfileattachment);
                }

                System.Debug(oClass + '.' + oMethod + '; List of oAttachments: ' + oAttachments);

                email.setFileAttachments(oAttachments);
            }

            // Loop through the email addresses in chunks to avoid hiting the limit of recipients
            for (Integer i = 0; i < oAddressesRT.size(); i += 100) {

                // Get the current chunk of email addresses
                Integer ending = Math.min(i + 100, oAddressesRT.size());
                List<String> batchEmails = new List<String>();
                for (Integer j = i; j < ending; j++) {
                    batchEmails.add(oAddressesRT.get(j));
                }

                email.setToAddresses(batchEmails);

                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                System.debug('Email Log > '+r);

            }

        } catch(Exception e) {
            System.Debug(oClass + '.' + oMethod + '; Exception: ' + e.getMessage());
        }

    }

}