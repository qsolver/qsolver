/**
 * @description       : Class Test to FeedItemTrigger, FeedItemTriggerHandler and FeedItemTriggerHelper
 * @author            : dhurtado@neox.cl
 * @group             : 
 * @last modified on  : 01-28-2025
 * @last modified by  : dhurtado@neox.cl
**/

@isTest
private class FeedItemTriggerHandlerTest {

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

        Opportunity anOpportunity = BuilderController.anOpportunity()
        .withName('Opportunity Test')
        .withCurrencyIsoCode('USD')
        .withStageName('Qualification')
        .withType('Liners')
        .withAccountId(anAccount)
        .build();
        anOpportunity.ELM_Line_of_Business__c = 'Other';
        insert anOpportunity;

        Task aTask = BuilderController.aTask()
        .withPriority('Normal')
        .withStatus('In Progress')
        .withSubject('Test subject')
        .build();
        aTask.WhatId = anOpportunity.Id;

        insert aTask;

        List<String> profiles = FeedItemTriggerHelper.permissionProfileSendEmailNotification.split(',');
        List<String> userEmail = FeedItemTriggerHelper.userWithoutPermissionToSendNotificationEmail.split(',');
        List<User> us = new List<User>();

        Profile p = [SELECT Id FROM Profile WHERE Id =: profiles[0]];
        User u = new User(Email = 'prueba445DPOR125@neox.cl', Title = 'Analist', LastName = 'Test', Alias = 'Test', Username = 'prueba445DPOR125@gruporecordar.com', EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles', LanguageLocaleKey = 'en_US', ProfileId = p.Id);
        us.add(u);
        User u2 = new User(Email = userEmail[0], Title = 'Analist', LastName = 'Test2', Alias = 'Test', Username = 'prueba445DPOR126@gruporecordar.com', EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles', LanguageLocaleKey = 'en_US', ProfileId = p.Id);
        us.add(u2);
        insert us;
    }

    @isTest
    static void successSendEmailNotificationOpp() {

        List<User> users = [SELECT Id, Name FROM User WHERE Name IN ('Test', 'Test2')];
        Opportunity anOpportunity = [SELECT Id, Name FROM Opportunity LIMIT 1];
        String body = '';
        for(User u: users){
            body = body + '@' + u.Name +' ';
        }

        Test.startTest();

        FeedItem fi = new feedItem();
        fi.body = body + '@Test Test Post';
        fi.ParentId = anOpportunity.Id;
        fi.Type = 'TextPost';
        insert fi;

        Integer emailCount = Limits.getEmailInvocations();
        System.assertEquals(1, emailCount, 'An email should have been sent');

        Test.stopTest();
    }

    @isTest
    static void successSendEmailNotificationTaskWithOpp() {

        User u = [SELECT Id, Name FROM User WHERE Name = 'Test' LIMIT 1];
        Task aTask = [SELECT Id FROM Task LIMIT 1];

        Test.startTest();

        FeedItem fi = new feedItem();
        fi.body = '@' + u.Name + '@Test Test Post';
        fi.ParentId = aTask.Id;
        fi.Type = 'TextPost';
        insert fi;

        Integer emailCount = Limits.getEmailInvocations();
        System.assertEquals(1, emailCount, 'An email should have been sent');

        Test.stopTest();
    }
}