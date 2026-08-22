public with sharing class ActivateContactControllerExtension {

    private final Contact ct;



    public ActivateContactControllerExtension(ApexPages.StandardController stdController) {
        this.ct = (Contact)stdController.getRecord();

    }

    public InactivContacts__Inactivated_Contacts__c getInactivatedContact() {
        return [SELECT Id FROM InactivContacts__Inactivated_Contacts__c where InactivContacts__Contact__c =: this.ct.Id  LIMIT 1];
    }
}