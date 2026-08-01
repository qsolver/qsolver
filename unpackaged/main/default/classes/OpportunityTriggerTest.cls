@isTest
public with sharing class OpportunityTriggerTest {
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
        anAccount.Line_of_Business__c = 'Other';

        insert anAccount;

        Account anAccount2 = BuilderController.anAccountCustomer()
        .withName('Test Account 2')
        .withPhone('888820')
        .withType('Customer')
        .withRegion('NA')
        .withBillingCity('Burns Harbor')
        .withBillingCountry('USA')
        .withBillingPostalCode('46304')
        .withBillingState('IN')
        .withBillingStreet('250 West Us Hghway 12')
        .withCopyBillingAddresstoShippingAddress(false)
        .withELMEquipodeVentas('SURAMERICA')
        .build();
        anAccount2.Line_of_Business__c = 'Other';

        insert anAccount2;

        // Product2 aProduct = BuilderController.aProduct2()
        // .withName('Test product')
        // .build();

        // insert aProduct;

        Account anAccount3 = BuilderController.anAccountCustomer()
        .withName('Test Account 3')
        .withPhone('888820')
        .withType('Customer')
        .withRegion('NA')
        .withBillingCity('Burns Harbor')
        .withBillingCountry('USA')
        .withBillingPostalCode('46304')
        .withBillingState('IN')
        .withBillingStreet('250 West Us Hghway 12')
        .withCopyBillingAddresstoShippingAddress(false)
        .withELMEquipodeVentas('NORTEAMERICA')
        .build();
        anAccount3.Line_of_Business__c = 'Other';

        insert anAccount3;

        Opportunity anOpp = BuilderController.anOpportunityRecurringSale()
        .withAccountId(anAccount)
        .withCurrencyIsoCode('USD')
        .withELMCantidadrequerida('test')
        .withELMCdigoanteriorsihubiese('test')
        .withELMCompromisodecompradelcliente('Si')
        .withELMGarantias('Si')
        .withELMInventariodelclienteactualrevisado('Si')
        .withELMPlazorequerido('test')
        .withELMPropuestaaprobadaconcdigodepieza('Si')
        .withELMVBIvan('Si')
        .withHasOC('Yes')
        .withName('Test opp')
        .withStageName('Qualification')
        .withType('Liners')
        .withDescription('Test description')
        .withELMActivationDateReal(System.today())
        .withELMOrderType('En Tramite')
        .build();
        anOpp.ELM_Line_of_Business__c = 'Other';
        anOpp.ELM_VB_Ivan__c = 'Sin estado';

        OpportunityHelper.canRunFromTestClass = false;
        insert anOpp;

        Profile salesRepsProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Sales Reps'
            LIMIT 1
        ];

        Profile managerProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Manager NA'
        ];

        User anUser = BuilderController.anUser()
        .withELMEquipodeVentas('SURAMERICA')
        .withProfileId(salesRepsProfile)
        .withLinesofbusiness('Alerta Temprana; Chancado')
        .build();

        insert anUser;

        User anUserNA = BuilderController.anUser()
        .withELMEquipodeVentas('NORTEAMERICA')
        .withProfileId(managerProfile)
        .withLinesofbusiness('Bolas (Grinding Media); Other')
        .withUsername('testmanagerna@elecmetal.com')
        .withEmail('testmanagerna@elecmetal.com')
        .withAlias('man.ln')
        .withCommunityNickname('nn')
        .build();

        insert anUserNA;

        Account anAccount4 = BuilderController.anAccountCustomer()
        .withName('Test Account 4')
        .withPhone('888820')
        .withType('Customer')
        .withRegion('NA')
        .withBillingCity('Burns Harbor')
        .withBillingCountry('USA')
        .withBillingPostalCode('46304')
        .withBillingState('IN')
        .withBillingStreet('250 West Us Hghway 12')
        .withCopyBillingAddresstoShippingAddress(false)
        .withELMEquipodeVentas('SURAMERICA')
        .build();
		anAccount4.Line_of_Business__c = 'Other';
        insert anAccount4;

        AccountShare anAccountShare = BuilderController.anAccountShare()
        .withAccountId(anAccount4)
        .withOpportunityAccessLevel('None')
        .withUserOrGroupId(anUser)
        .build();

        insert anAccountShare;
    }

    // @IsTest
    // static void checkCorrectUpdateOfOpportunityWhenOnlyStageChangeToCloseWon(){

    //     Opportunity anOpp = [
    //         SELECT Name, ELM_Order_Type__c, Has_OC__c
    //         FROM Opportunity
    //         WHERE RecordType.Name = 'Recurring Sale'
    //     ];

    //     User user = [
    //         SELECT Id
    //         FROM User
    //         WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
    //             AND Profile.Name = 'Sales Reps'
    //         LIMIT 1
    //     ];

    //     anOpp.StageName = 'Closed Won';
        
    //     Test.startTest();
    //     System.runAs(user){

    //         Database.SaveResult result = Database.update(anOpp, false);

    //         System.assertEquals(true, result.isSuccess(), 'The record was not successfully updated when it should have');
    //     }
        
    //     Test.stopTest();
        
    // }

    @IsTest
    static void checkTheIncorrectUpdateOfAnOpportunityWhenFieldHasOCIsNoAndThereAreNoProductsAssociated(){

        Opportunity anOpp = [
            SELECT Name, HasOpportunityLineItem
            FROM Opportunity
            WHERE RecordType.Name = 'Recurring Sale'
            LIMIT 1
        ];

        anOpp.ELM_Order_Type__c = 'To Follow';
        anOpp.Has_OC__c = 'No';
        anOpp.StageName = 'Closed Won';
        
        Test.startTest();
        Database.SaveResult result = Database.update(anOpp, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess(), 'The record was successfully updated when it should not have');    
    }

    @IsTest
    static void checkCorrectAssignmentOfErrorMessageWhenAccountDoesNotHaveAnEarlyAlertRepresentativeAssociated(){

        User user = [
            SELECT Id
            FROM User
            WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
                AND Profile.Name = 'Sales Reps' AND IsActive = true
            LIMIT 1
        ];

        Account anAccount2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 2'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
            .withAccountId(anAccount2)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            System.assertEquals(false, result.isSuccess(), 'The record was successfully created when it should not have');
        }

        Test.stopTest();

    }

    @IsTest
    static void checkCorrectAssignmentOfErrorMessageWhenAccountDoesNotHaveAGrindingMediaRepresentativeAssociated(){

        User user = [
            SELECT Id
            FROM User
            WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
                AND Profile.Name = 'Sales Reps' AND IsActive = true
            LIMIT 1
        ];

        user.Lines_of_business__c = 'Bolas (Grinding Media)';

        update user;

        Account anAccount2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 2'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
            .withAccountId(anAccount2)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            System.assertEquals(false, result.isSuccess(), 'The record was successfully created when it should not have');
        }

        Test.stopTest();

    }

    @isTest
    static void checkCorrectAssignmentOfErrorMessageWhenAccountDoesNotHaveAChancadoRepresentativeAssociated(){

        User user = [
            SELECT Id
            FROM User
            WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
                AND Profile.Name = 'Sales Reps' AND IsActive = true
            LIMIT 1
        ];

        user.Lines_of_business__c = 'Chancado';

        update user;

        Account anAccount2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 2'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
            .withAccountId(anAccount2)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            System.assertEquals(false, result.isSuccess(), 'The record was successfully created when it should not have');
        }

        Test.stopTest();

    }

    // @isTest
    // static void checkCorrectAssignmentOfErrorMessageWhenAccountDoesNotHaveAChutesRepresentativeAssociated(){

    //     User user = [
    //         SELECT Id
    //         FROM User
    //         WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
    //             AND Profile.Name = 'Sales Reps'
    //         LIMIT 1
    //     ];

    //     user.Lines_of_business__c = 'Chutes';

    //     update user;

    //     Account anAccount2 = [
    //         SELECT Id
    //         FROM Account
    //         WHERE Name = 'Test Account 2'
    //     ];
        
    //     Test.startTest();
    //     System.runAs(user){

    //         Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
    //         .withAccountId(anAccount2)
    //         .withCurrencyIsoCode('USD')
    //         .withHasOC('Yes')
    //         .withName('Test opp 2')
    //         .withStageName('Qualification')
    //         .withType('Liners')
    //         .withDescription('Test description')
    //         .withShipDate(System.today())
    //         .build();
            
    //         Database.SaveResult result = Database.insert(anOpp2, false);

    //         System.assertEquals(false, result.isSuccess(), 'The record was successfully created when it should not have');
    //     }

    //     Test.stopTest();

    // }

    @isTest
    static void checkCorrectAssignmentOfErrorMessageWhenAccountDoesNotHaveAGETRepresentativeAssociated(){

        User user = [
            SELECT Id
            FROM User
            WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
                AND Profile.Name = 'Sales Reps' AND IsActive = true
            LIMIT 1
        ];

        user.Lines_of_business__c = 'GET';

        update user;

        Account anAccount2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 2'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
            .withAccountId(anAccount2)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            System.assertEquals(false, result.isSuccess(), 'The record was successfully created when it should not have');
        }

        Test.stopTest();

    }

    @isTest
    static void checkCorrectAssignmentOfErrorMessageWhenAccountDoesNotHaveAMaestranzaRepresentativeAssociated(){

        User user = [
            SELECT Id
            FROM User
            WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
                AND Profile.Name = 'Sales Reps' AND IsActive = true
            LIMIT 1
        ];

        user.Lines_of_business__c = 'Maestranza';

        update user;

        Account anAccount2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 2'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
            .withAccountId(anAccount2)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            System.assertEquals(false, result.isSuccess(), 'The record was successfully created when it should not have');
        }

        Test.stopTest();

    }

    @isTest
    static void checkCorrectAssignmentOfErrorMessageWhenAccountDoesNotHaveAMoliendaRepresentativeAssociated(){

        User user = [
            SELECT Id
            FROM User
            WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
                AND Profile.Name = 'Sales Reps' AND IsActive = true
            LIMIT 1
        ];

        user.Lines_of_business__c = 'Molienda';

        update user;

        Account anAccount2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 2'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
            .withAccountId(anAccount2)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            System.assertEquals(false, result.isSuccess(), 'The record was successfully created when it should not have');
        }

        Test.stopTest();

    }

    // @isTest
    // static void checkCorrectAssignmentOfErrorMessageWhenAccountDoesNotHaveAOllasRepresentativeAssociated(){

    //     User user = [
    //         SELECT Id
    //         FROM User
    //         WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
    //             AND Profile.Name = 'Sales Reps'
    //         LIMIT 1
    //     ];

    //     user.Lines_of_business__c = 'Ollas';

    //     update user;

    //     Account anAccount2 = [
    //         SELECT Id
    //         FROM Account
    //         WHERE Name = 'Test Account 2'
    //     ];
        
    //     Test.startTest();
    //     System.runAs(user){

    //         Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
    //         .withAccountId(anAccount2)
    //         .withCurrencyIsoCode('USD')
    //         .withHasOC('Yes')
    //         .withName('Test opp 2')
    //         .withStageName('Qualification')
    //         .withType('Liners')
    //         .withDescription('Test description')
    //         .withShipDate(System.today())
    //         .build();
            
    //         Database.SaveResult result = Database.insert(anOpp2, false);

    //         System.assertEquals(false, result.isSuccess(), 'The record was successfully created when it should not have');
    //     }

    //     Test.stopTest();

    // }

    // @isTest
    // static void checkCorrectAssignmentOfErrorMessageWhenAccountDoesNotHaveAPartesYRespuestosRepresentativeAssociated(){

    //     User user = [
    //         SELECT Id
    //         FROM User
    //         WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
    //             AND Profile.Name = 'Sales Reps'
    //         LIMIT 1
    //     ];

    //     user.Lines_of_business__c = 'Partes y Respuestos';

    //     update user;

    //     Account anAccount2 = [
    //         SELECT Id
    //         FROM Account
    //         WHERE Name = 'Test Account 2'
    //     ];
        
    //     Test.startTest();
    //     System.runAs(user){

    //         Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
    //         .withAccountId(anAccount2)
    //         .withCurrencyIsoCode('USD')
    //         .withHasOC('Yes')
    //         .withName('Test opp 2')
    //         .withStageName('Qualification')
    //         .withType('Liners')
    //         .withDescription('Test description')
    //         .withShipDate(System.today())
    //         .build();
            
    //         Database.SaveResult result = Database.insert(anOpp2, false);

    //         System.assertEquals(false, result.isSuccess(), 'The record was successfully created when it should not have');
    //     }

    //     Test.stopTest();

    // }

    @IsTest
    static void checkCorrectAssignmentOfErrorMessageWhenUserAndAccountSalesTeamDoesNotMatchSalesRep(){

        User user = [
            SELECT Id
            FROM User
            WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
                AND Profile.Name = 'Sales Reps' AND IsActive = true
            LIMIT 1
        ];

        Account anAccount3 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 3'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
            .withAccountId(anAccount3)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            Assert.AreEqual(false, result.isSuccess(), 'The record was successfully created when it should not have');
        }

        Test.stopTest();

    }

    @IsTest
    static void checkCorrectAssignmentOfErrorMessageWhenUserAndAccountSalesTeamDoesNotMatchManager(){

        User user = [
            SELECT Id
            FROM User
            WHERE ELM_Equipo_de_Ventas__c = 'NORTEAMERICA'
                AND Profile.Name = 'Manager NA'
            LIMIT 1
        ];

        Account anAccount2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 2'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
            .withAccountId(anAccount2)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            Assert.AreEqual(false, result.isSuccess(), 'The record was successfully created when it should not have');
        }

        Test.stopTest();

    }

    @IsTest
    static void checkCorrectAssignmentOfErrorMessageWhenUserAndAccountSalesTeamDoesMatchSalesRepButNotAssignedInTheAccount(){

        User user = [
            SELECT Id
            FROM User
            WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
                AND Profile.Name = 'Sales Reps' AND IsActive = true
            LIMIT 1
        ];

        Account anAccount2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 2'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
            .withAccountId(anAccount2)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            Assert.AreEqual(false, result.isSuccess(), 'The record was successfully created when it should not have');
        }

        Test.stopTest();

    }

    @IsTest
    static void checkCorrectAssignmentOfErrorMessageWhenUserAndAccountSalesTeamDoesMatchSalesRepButNotAssignedInTheAccountAndOppAccessLevelIsPrivate(){

        User user = [
            SELECT Id
            FROM User
            WHERE ELM_Equipo_de_Ventas__c = 'SURAMERICA'
                AND Profile.Name = 'Sales Reps' AND IsActive = true
            LIMIT 1
        ];

        Account anAccount2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 4'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunityRecurringSale()
            .withAccountId(anAccount2)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            Assert.AreEqual(false, result.isSuccess(), 'The record was successfully created when it should not have');
        }

        Test.stopTest();

    }
    
    @IsTest
    static void checkvalidateInsertionByUser(){

        User user = [
            SELECT Id
            FROM User
            WHERE IsActive = true AND userrole.name = 'Grinding Media Int Sales Rep'
            LIMIT 1
        ];


        Account anAccount2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 2'
        ];
        
        Test.startTest();
        System.runAs(user){

            Opportunity anOpp2 = BuilderController.anOpportunity()
            .withAccountId(anAccount2)
            .withCurrencyIsoCode('USD')
            .withHasOC('Yes')
            .withName('Test opp 2')
            .withStageName('Qualification')
            .withType('Liners')
            .withDescription('Test description')
            .withShipDate(System.today())
            .build();
            
            Database.SaveResult result = Database.insert(anOpp2, false);

            System.assertEquals(false, result.isSuccess(), 'You cannot create an Opportunity for this client || Account Share');
        }

        Test.stopTest();
    }

}