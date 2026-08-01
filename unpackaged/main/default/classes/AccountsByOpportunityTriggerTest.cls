@isTest
public with sharing class AccountsByOpportunityTriggerTest {
    
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
        .withAccountId(anAccount)
        .withName('Opportunity Test')
        .withCurrencyIsoCode('USD')
        .withStageName('Qualification')
        .withType('Liners')
        .build();
        
        insert anOpportunity;

    }

    @IsTest
    static void assignOpportunityNameToAccountsByOpportunityName(){

        Account anAccount = [
            SELECT Id
            FROM Account 
            LIMIT 1
        ];

        Opportunity anOpportunity = [
            SELECT Id, Name
            FROM Opportunity
            LIMIT 1
        ];

        Accounts_by_Opportunity__c anAccountByOpportunity;

        anAccountByOpportunity = BuilderController.anAccountsbyOpportunity()
        .withAccount(anAccount)
        .withOpportunity(anOpportunity)
        .build();
        
        Test.startTest();
        insert anAccountByOpportunity;
        Test.stopTest();

        Accounts_by_Opportunity__c result = [
            SELECT Id, Name
            FROM Accounts_by_Opportunity__c
            LIMIT 1
        ];

        System.assertEquals(anOpportunity.Name, result.Name, 'The names are equal when they shouldnt be');
        
    }

}