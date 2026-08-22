/**
* @author   Cirrius Solutions
* @version  08.23.2021
*
* CHANGE HISTORY
* =============================================================================
* Date          Name            Description
* 08.23.2021    Cirrius         Created
* 05.23.2024    Willian         Modification  
* =============================================================================
*/ 
public with sharing class manageTripReportController {
    
    private static final String oClass = 'manageTripReportController';

    public manageTripReportController() {

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

    // public static void SendExceptionEmail(String oSubject, String oMessage) {

    //     String oMethod = 'SendExceptionEmail';
    
    //     System.Debug(oClass + '.' + oMethod + '; Enter');
    
    //     try {

    //         Messaging.SingleEmailMessage oEmail 	= new Messaging.SingleEmailMessage();
    //         List<String> oAddresses 				= new List<String>();
        
    //         Trip_Report_Setting__mdt oSetting 	= GetSettings();
        
    //         if (String.isNotBlank(oSetting.Exception_Emails__c)) {
    //             String s = oSetting.Exception_Emails__c.Replace(' ','');
    //             oAddresses = s.split(',');
    //         }
                    
    //         if (oAddresses.size() == 0) { return; }
            
    //         if (String.isBlank(oMessage)) { oMessage = ''; }
            
    //         oEmail.setHTMLBody(oMessage);
    //         oEmail.setSubject(oSubject);
    //         oEmail.setToAddresses(oAddresses);
        
    //         Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {oEmail});

    //     } catch(Exception e) {
    //         System.Debug(oClass + '.' + oMethod + '; Exception: ' + e.getMessage()); 
    //     }

    //     System.Debug(oClass + '.' + oMethod + '; Exit');
    // }

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
        List<SA_Trip_Report_Groups__mdt> SAGroups = new List<SA_Trip_Report_Groups__mdt>();

        try {

            Trip_Report_Setting__mdt oSetting = GetSettings();

            Group g = [SELECT id, Name, (select userOrGroupId from GroupMembers) FROM group Where Name = :oSetting.Group_Name__c];

            //To get SA Groups Names
            SAGroups = [SELECT MasterLabel FROM SA_Trip_Report_Groups__mdt];

            

            Set<Id> oUserIds = new Set<Id>();


            
            For (GroupMember gm : g.groupMembers) {
                if (String.ValueOf(gm.userOrGroupId).startsWith('005')) {
                    oUserIds.add(gm.userOrGroupId);
                }
            }
            

            

            List<User> oUsers = [Select Id, Name, Email From User Where Id IN : oUserIds];

            
            for (User u : oUsers) {
                oAddresses.add(u.Email);
            }

            System.debug('Additional emails: '+oSetting.Additional_Emails__c);

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
            for(SA_Trip_Report_Groups__mdt sa_g : SAGroups){

                oAddresses.add(sa_g.MasterLabel);
            }
        }
        
        return oAddresses;

    }

    

    //Add SA Groups emails
    public static List<String> addSAGroupsEmails(List<String> oAddresses){

        Set<Id> oUserIds = new Set<Id>();
        List<SA_Trip_Report_Groups__mdt> grps = new List<SA_Trip_Report_Groups__mdt>();
        List<String> oAddressesRT = new List<String>();

        

        //Gets all SA emails from metadata groups
        grps = [SELECT MasterLabel, Emails_to_send_trip_report__c FROM SA_Trip_Report_Groups__mdt Where MasterLabel IN : oAddresses];

        System.debug('Groups => '+grps);

        

        //add emails  
        
        for (String em : oAddresses) {
            if(em.contains('@')){
                oAddressesRT.add(em);

            }
        }


        if(grps.size() > 0){
            for(SA_Trip_Report_Groups__mdt groupRecord : grps){

                if (String.isNotBlank(groupRecord.Emails_to_send_trip_report__c)) {
            
                    String s = groupRecord.Emails_to_send_trip_report__c.Replace(' ','');
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
    public static void sendTripReport(String oRecordId, List<String> oAddresses, List<String> oSelectedAttachments) { 

        List<String> oAddressesRT =  addSAGroupsEmails(oAddresses);

        String oMethod = 'sendTripReport';

        System.Debug(oClass + '.' + oMethod + '; Enter');
        
        if (String.isBlank(oRecordId)) { return; }
        if (oAddressesRT.size() == 0) { return; }
        // if (oSelectedAttachments.size() == 0) { return; }

        try {

            Trip_Report__c oTrip = [Select Id, Visit_Target_Customer__c, Presentation_Target_Individual_Group__c, 
                                    Joint_Visit_Liner_Media_CPS_Spec__c, Customer_Company__r.Name, 
                                    Quotation_Submitted_new_business__c, Purchase_Order_Received__c 
                                    From Trip_Report__c Where Id = :oRecordId];

            Trip_Report_Setting__mdt oSetting = GetSettings();

            if (oSetting.Disabled__c) {
                System.debug(oClass+'.'+oMethod+'; Trip Report emailing has been disabled in settings. Exiting.');
                return;
            }

            EmailTemplate oTemplate = [Select Id, Name, Subject, HtmlValue, Markup, DeveloperName 
                                                from EmailTemplate where DeveloperName = :oSetting.Email_Template_DeveloperName__c];


            // Group g = [SELECT id, Name, (select userOrGroupId from GroupMembers) FROM group Where Name = :oSetting.Group_Name__c];
            // Set<Id> oUserIds = new Set<Id>();

            // For (GroupMember gm : g.groupMembers) {
            //     if (String.ValueOf(gm.userOrGroupId).startsWith('005')) {
            //         oUserIds.add(gm.userOrGroupId);
            //     }
            // }

            // if (oUserIds.size() == 0) { 
            //     System.Debug(oClass + '.' + oMethod + '; Unable to email; Group is empty');
            //     return;
            // }

            // List<User> oUsers = [Select Id, Name, Email From User Where Id IN : oUserIds];

            // List<String> oAddresses = new List<String>();
            // for (User u : oUsers) {
            //     oAddresses.add(u.Email);
            // }

            // if (String.isNotBlank(oSetting.Additional_Emails__c)) {
            //     String s                        = oSetting.Additional_Emails__c.Replace(' ','');
            //     List<String> oAdditionalEmails  = new List<String>();
            //     oAdditionalEmails = s.split(',');
            //     for (String oAdditionalEmail : oAdditionalEmails) {
            //         oAddresses.add(oAdditionalEmail);
            //     }
            // }
                    
            

            System.Debug(oClass + '.' + oMethod + '; Rendering with Template: ' + oTemplate.Id);
            Messaging.SingleEmailMessage oMail = Messaging.renderStoredEmailTemplate(oTemplate.Id, UserInfo.getUserID(), oRecordId);

            String oHTMLBody = oMail.getHTMLBody();
            
            System.Debug(oClass + '.' + oMethod + '; oTrip.Visit_Target_Customer__c: ' + oTrip.Visit_Target_Customer__c);

            oHTMLBody = oHTMLBody.replace('###TOV_TARGET###', (oTrip.Visit_Target_Customer__c                       ? '<input type="checkbox" class="larger" checked>':'<input type="checkbox" class="larger">'));
            oHTMLBody = oHTMLBody.replace('###TOV_PRESENTATION###', (oTrip.Presentation_Target_Individual_Group__c  ? '<input type="checkbox" class="larger" checked>':'<input type="checkbox" class="larger">'));
            oHTMLBody = oHTMLBody.replace('###TOV_JOINT###', (oTrip.Joint_Visit_Liner_Media_CPS_Spec__c             ? '<input type="checkbox" class="larger" checked>':'<input type="checkbox" class="larger">'));
            oHTMLBody = oHTMLBody.replace('###TOV_QUOTATION###', (oTrip.Quotation_Submitted_new_business__c         ? '<input type="checkbox" class="larger" checked>':'<input type="checkbox" class="larger">'));
            oHTMLBody = oHTMLBody.replace('###TOV_PURCHASEORDER###', (oTrip.Purchase_Order_Received__c              ? '<input type="checkbox" class="larger" checked>':'<input type="checkbox" class="larger">'));

            oMail.setHtmlBody(oHTMLBody);

            oMail.setSubject('Trip Report for ' + oTrip.Customer_Company__r.Name);
            System.Debug(oClass + '.' + oMethod + '; oAddresses: ' + oAddressesRT);
            
            oMail.setSaveAsActivity(false);

            List<Messaging.Emailfileattachment> oAttachments = new List<Messaging.Emailfileattachment>();

            // for (Attachment a : [select Id, Name, Body, BodyLength from Attachment where ParentId = :oRecordId])
            // {
            //     Messaging.Emailfileattachment j = new Messaging.Emailfileattachment();
            //     j.setFileName(a.Name);
            //     j.setBody(a.Body);
            //     oAttachments.add(j);
            // }

            //01.05.2022 List<ContentDocumentLink> oContentDocumentLinks = [SELECT id, LinkedEntityId, ContentDocumentId 
            //01.05.2022                                                     FROM ContentDocumentLink WHERE LinkedEntityId =:oRecordId];

            Set<Id> oSetIds = new Set<Id>();
            //01.05.2022 for(ContentDocumentLink oLink : oContentDocumentLinks) {
            //01.05.2022     oSetIds.add(oLink.ContentDocumentId);
            //01.05.2022 }

            if (oSelectedAttachments.size() > 0) {
                for (String s : oSelectedAttachments) {
                    oSetIds.add(s);
                }

                System.Debug(oClass + '.' + oMethod + '; List of contentDocumentId: ' + oSetIds);

                //List<ContentVersion> oContentVersions = [SELECT Id, Title, VersionData, FileExtension FROM ContentVersion WHERE contentDocumentId IN :oSetIds];
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

                oMail.setFileAttachments(oAttachments);
            }

            // Loop through the email addresses in chunks to avoid hiting the limit of recipients
            for (Integer i = 0; i < oAddressesRT.size(); i += 100) {

                // Get the current chunk of email addresses
                Integer ending = Math.min(i + 100, oAddressesRT.size());
                List<String> batchEmails = new List<String>();
                for (Integer j = i; j < ending; j++) {
                    batchEmails.add(oAddressesRT.get(j));
                }

                oMail.setToAddresses(batchEmails);
            
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {oMail});

            }

        } catch(Exception e) {
            System.Debug(oClass + '.' + oMethod + '; Exception: ' + e.getMessage()); 
        }

    }

    @AuraEnabled //(cacheable=true)
    public static List<Contact> getContacts(String oRecordId) {  

        String oMethod = 'getContacts';

        System.Debug(oClass + '.' + oMethod + '; Enter');
        List<Contact> oContacts = new List<Contact>();

        try {

            Trip_Report__c oTripReport =[select Id, Customer_Company__c From Trip_Report__c Where Id = :oRecordId];

            oContacts = [Select Id, Name From Contact Where AccountId = : oTripReport.Customer_Company__c];
            
        } catch(Exception e) {
            System.Debug(oClass + '.' + oMethod + '; Exception: ' + e.getMessage()); 
        }

        return oContacts;

    }

    @AuraEnabled //(cacheable=true)
    public static void saveTripReport(String oRecordId, List<String> oContacts) {  

        String oMethod = 'saveTripReport';

        System.Debug(oClass + '.' + oMethod + '; Enter');
        String oCustomerRepresentatives = '';

        try {

            Trip_Report__c oTripReport =[select Id, Customer_Representatives__c From Trip_Report__c Where Id = :oRecordId];

            if (oTripReport.Customer_Representatives__c == null) { oTripReport.Customer_Representatives__c = ''; }

            oCustomerRepresentatives = oTripReport.Customer_Representatives__c;

            for (String s : oContacts) {
                if (oTripReport.Customer_Representatives__c.containsIgnoreCase(s) == false) {

                    if (oCustomerRepresentatives.containsIgnoreCase(s) == false) {
                        if (String.isNotBlank(s)) {
                            if (oCustomerRepresentatives.endsWith(','))
                                oCustomerRepresentatives += ' ' + s.trim() + ', ';
                            else if (oCustomerRepresentatives.endsWith(', '))
                                oCustomerRepresentatives += s.trim() + ', ';
                            else 
                                oCustomerRepresentatives += ', ' + s.trim() + ', ';
                        }
                    }

                }
            }

            oCustomerRepresentatives = oCustomerRepresentatives.removeEnd(', ');
            oCustomerRepresentatives = oCustomerRepresentatives.removeEnd(',');
            oCustomerRepresentatives = oCustomerRepresentatives.replace(',,',', ');
            oCustomerRepresentatives = oCustomerRepresentatives.replace(', ,',', ');
            oCustomerRepresentatives = oCustomerRepresentatives.removeStart(', ');
            oCustomerRepresentatives = oCustomerRepresentatives.removeStart(',');
            oCustomerRepresentatives = oCustomerRepresentatives.trim();

            oTripReport.Customer_Representatives__c = oCustomerRepresentatives;
            update oTripReport;
            
        } catch(Exception e) {
            System.Debug(oClass + '.' + oMethod + '; Exception: ' + e.getMessage()); 
        }

    }

}