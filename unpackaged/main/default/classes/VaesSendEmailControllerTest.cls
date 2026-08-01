@isTest
public with sharing class VaesSendEmailControllerTest {

    @TestSetup
    static void makeData(){
        Account anAccount = BuilderController.anAccount()
        .withName('Test')
        .withPhone('8888')
        .withType('Competitor')
        .withRegion('NA')
        .withBillingCity('Burns Harbor')
        .withBillingCountry('USA')
        .withBillingPostalCode('46304')
        .withBillingState('IN')
        .withBillingStreet('250 West Us Hghway 12')
        .withCopyBillingAddresstoShippingAddress(false)
        .build();

        insert anAccount;

        Contact aContact = BuilderController.aContact()
        .withAccountId(anAccount)
        .withEmail('test@gmail.com')
        .withLineofBusiness('Alerta Temprana')
        .withPhone('2222')
        .withRole('Comprador')
        .build();

        insert aContact;

        ELM_Vaes__c aVaes = BuilderController.anELMVaes()
        .withELMAccount(anAccount)
        .withELMContact(aContact)
        .withELMLineOfBusiness('Crushing')
        .withELMProjectName('Test name')
        .build();

        insert aVaes;
    }

    @isTest
    static void checkCorrectEmailSent(){

        ELM_Vaes__c aVaes = [
            SELECT Id
            FROM ELM_Vaes__c
            LIMIT 1
        ];
        
        Test.startTest();

        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');

        VaesSendEmailController.sendEmail(aVaes.Id);

        System.assertEquals(1, Limits.getEmailInvocations(), 'Email should be sent');

        Test.stopTest();

        
    }
}