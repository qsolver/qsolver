public with sharing class VaesSendEmailController {

    @AuraEnabled
    public static void sendEmail(Id recordId) {

        PageReference pdf;
        Blob blobContent;
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<String> addresses = new List<String>();
        EmailTemplate emailTemp;
        

        emailTemp = [
            SELECT Id, Subject, HtmlValue, body
            FROM EmailTemplate
            WHERE Name = 'VaesPDF'
            WITH SECURITY_ENFORCED];
        
        ELM_Vaes__c vaes = [
            SELECT Id, ELM_Contact__c, ELM_Contact__r.Email, ELM_Project_Name__c, Name,
                ELM_Contact_2__c, ELM_Contact_3__c, ELM_Contact_2__r.Email, ELM_Contact_3__r.Email
            FROM ELM_Vaes__c
            WHERE Id =: recordId
        ];

        

        if (vaes.ELM_Contact__c != null) {
            
            addresses.add(vaes.ELM_Contact__r.Email);
        }

        if (vaes.ELM_Contact_2__c != null) {

            addresses.add(vaes.ELM_Contact_2__r.Email);
        }

        if (vaes.ELM_Contact_3__c != null) {
            
            addresses.add(vaes.ELM_Contact_3__r.Email);
        }

        pdf = Page.VaesPDF;

        pdf.getParameters().put('id', String.valueOf(recordId));

        if (Test.isRunningTest()){
            blobContent = blob.valueOf('Unit.Test');
        } else{
            blobContent = pdf.getContentAsPDF();
        }

        efa.setContentType('application/pdf');
        efa.setFileName('Project VAES' + ' - '+ vaes.ELM_Project_Name__c + ' - ' + vaes.Name);
        efa.setInline(false);
        efa.setBody(blobContent);

        mail = Messaging.renderStoredEmailTemplate(emailTemp.Id, null, null);
        mail.setSubject('Project VAES' + ' - '+ vaes.ELM_Project_Name__c + ' - ' + vaes.Name);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{ efa });
        mail.setSaveAsActivity(false);
        mail.setCcAddresses(new List<String>{UserInfo.getUserEmail()});
        if (!addresses.isEmpty()) {

            mail.setToAddresses(new List<String>(addresses));
        }else {
            
            mail.setToAddresses(new List<String>{vaes.ELM_Contact__r.Email});
        }
        

        emails.add(mail);

        Messaging.sendEmail(emails);
    }
}