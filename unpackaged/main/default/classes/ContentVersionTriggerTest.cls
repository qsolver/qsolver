@isTest
public with sharing class ContentVersionTriggerTest {

    @TestSetup
    static void makeData(){

        User anUser = BuilderController.anUser()
        .withProfileId([
            SELECT Id
            FROM Profile
            WHERE Name = 'System administrator'
                OR Name = 'Administrador del sistema'
        ])
        .build();

        insert anUser;

        Account anAccount = BuilderController.anAccount()
        .withName('Test')
        .withPhone('8888')
        .withRegion('NA')
        .withType('Competitor')
        .withBillingCity('Burns Harbor')
        .withBillingCountry('USA')
        .withBillingPostalCode('46304')
        .withBillingState('IN')
        .withBillingStreet('250 West Us Hghway 12')
        .withCopyBillingAddresstoShippingAddress(false)
        .withELMEquipodeVentas('SURAMERICA')
        .build();

        insert anAccount;

        Contact aContact = BuilderController.aContact()
        .withAccountId(anAccount)
        .withEmail('test@elecmetal.com')
        .withLastName('test')
        .withLineofBusiness('Alerta Temprana')
        .withPhone('235489')
        .withRole('Comprador')
        .build();

        insert aContact;

        Asset anAsset = BuilderController.anAsset()
        .withAccountId(anAccount)
        .withCurrentlyInstalled(true)
        .withIsCompetitorProduct(true)
        .withIsInternal(true)
        .withLineofBusiness('Alerta Temprana')
        .withMEElecmetalEquipment(true)
        .withName('Test Asset')
        .withNeverInstalled(true)
        .withPreviouslyInstalled(false)
        .build();

        insert anAsset;

        After_Sales__c anAfterSales = BuilderController.anAfterSales()
        .withOwnerId(anUser)
        .withCurrencyIsoCode('USD')
        .build();

        insert anAfterSales;

        Opportunity anOpportunity = BuilderController.anOpportunity()
        .withAccountId(anAccount)
        .withName('Opportunity Test')
        .withCurrencyIsoCode('USD')
        .withStageName('Qualification')
        .withType('Liners')
        .build();
        anOpportunity.ELM_Line_of_Business__c = 'Other';
        anOpportunity.Sub_Linea_de_Negocio_OPP__c = 'Harneros';
        OpportunityHelper.canRunFromTestClass = false;
        insert anOpportunity;

        
        Contract aContract = BuilderController.aContract()
        .withAccountId(anAccount)
        .withContractTerm(2)
        .withELMContractAmount(3000)
        .withELMContractType('Consignment')
        .withELMLineoofBusiness('Alerta Temprana')
        .withStartDate(System.today() + 1)
        .withStatus('Draft')
        .build();

        insert aContract;

        Quote aQuote = BuilderController.aQuote()
        .withName('Test quote')
        .withOpportunityId(anOpportunity)
        .build();

        insert aQuote;

        Order anOrder = BuilderController.anOrder()
        .withAccountId(anAccount)
        .withEffectiveDate(System.today())
        .withStatus('Draft')
        .build();

        insert anOrder;
    
        Task aTask = BuilderController.aTask()
        .withOwnerId(anUser)
        .withPriority('Normal')
        .withStatus('In Progress')
        .withSubject('Test subject')
        .build();

        insert aTask;

        Lead aLead = BuilderController.aLead()
        .withCompany('test company')
        .withLastName('test lastname')
        .build();

        insert aLead;
    }

    @IsTest
    static void creationOfFileLinkRegistryAssociatedToTheAccountTest(){

        User anUser = [
            SELECT Id
            FROM User
            WHERE Username = 'test@elecmetal.com'
            LIMIT 1
        ];

        Account anAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test'
            LIMIT 1
        ];

        ContentVersion aContentVersion;
        String versionData = 'Testing base 64 encode';

        aContentVersion = new ContentVersion();
        aContentVersion.Title = 'test';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = anAccount.Id;
        
        Test.startTest();
        insert aContentVersion;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(1, fileLinks.size(), 'The registry on File Link was created when it should not be');
        
    }

    @IsTest
    static void creationOfFileLinkRegistryAssociatedToTheContactTest(){

        User anUser = [
            SELECT Id
            FROM User
            WHERE Username = 'test@elecmetal.com'
            LIMIT 1
        ];

        Contact aContact = [
            SELECT Id
            FROM Contact
            WHERE Email = 'test@elecmetal.com'
            LIMIT 1
        ];

        ContentVersion aContentVersion;
        String versionData = 'Testing base 64 encode';

        aContentVersion = new ContentVersion();
        aContentVersion.Title = 'test';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = aContact.Id;
        
        Test.startTest();
        insert aContentVersion;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(1, fileLinks.size(), 'The registry on File Link was created when it should not be');
        
    }

    @IsTest
    static void creationOfFileLinkRegistryAssociatedToTheAssetTest(){

        User anUser = [
            SELECT Id
            FROM User
            WHERE Username = 'test@elecmetal.com'
            LIMIT 1
        ];

        Asset anAsset = [
            SELECT Id
            FROM Asset
            LIMIT 1
        ];

        ContentVersion aContentVersion;
        String versionData = 'Testing base 64 encode';

        aContentVersion = new ContentVersion();
        aContentVersion.Title = 'test';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = anAsset.Id;
        
        Test.startTest();
        insert aContentVersion;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(1, fileLinks.size(), 'The registry on File Link was created when it should not be');
        
    }

    @IsTest
    static void creationOfFileLinkRegistryAssociatedToAnAfterSalesObjectTest(){

        User anUser = [
            SELECT Id
            FROM User
            WHERE Username = 'test@elecmetal.com'
            LIMIT 1
        ];

        After_Sales__c anAfterSales = [
            SELECT Id
            FROM After_Sales__c
            LIMIT 1
        ];

        ContentVersion aContentVersion;
        String versionData = 'Testing base 64 encode';

        aContentVersion = new ContentVersion();
        aContentVersion.Title = 'test';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = anAfterSales.Id;
        
        Test.startTest();
        insert aContentVersion;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(1, fileLinks.size(), 'The registry on File Link was created when it should not be');
        
    }

    @IsTest
    static void creationOfFileLinkRegistryAssociatedToAnOpportunityObjectTest(){

        User anUser = [
            SELECT Id
            FROM User
            WHERE Username = 'test@elecmetal.com'
            LIMIT 1
        ];

        Opportunity anOpp = [
            SELECT Id
            FROM Opportunity
            LIMIT 1
        ];

        ContentVersion aContentVersion;
        String versionData = 'Testing base 64 encode';

        aContentVersion = new ContentVersion();
        aContentVersion.Title = 'test';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = anOpp.Id;
        
        Test.startTest();
        insert aContentVersion;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(1, fileLinks.size(), 'The registry on File Link was created when it should not be');
        
    }

    @IsTest
    static void creationOfFileLinkRegistryAssociatedToAContractObjectTest(){

        User anUser = [
            SELECT Id
            FROM User
            WHERE Username = 'test@elecmetal.com'
            LIMIT 1
        ];

        Contract aContract = [
            SELECT Id
            FROM Contract
            LIMIT 1
        ];

        ContentVersion aContentVersion;
        String versionData = 'Testing base 64 encode';

        aContentVersion = new ContentVersion();
        aContentVersion.Title = 'test';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = aContract.Id;
        
        Test.startTest();
        insert aContentVersion;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(1, fileLinks.size(), 'The registry on File Link was created when it should not be');
        
    }

    @IsTest
    static void creationOfFileLinkRegistryAssociatedToAQuoteObjectTest(){

        User anUser = [
            SELECT Id
            FROM User
            WHERE Username = 'test@elecmetal.com'
            LIMIT 1
        ];

        Quote aQuote = [
            SELECT Id
            FROM Quote
            LIMIT 1
        ];

        ContentVersion aContentVersion;
        String versionData = 'Testing base 64 encode';

        aContentVersion = new ContentVersion();
        aContentVersion.Title = 'test';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = aQuote.Id;
        
        Test.startTest();
        insert aContentVersion;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(1, fileLinks.size(), 'The registry on File Link was created when it should not be');
        
    }

    @IsTest
    static void creationOfFileLinkRegistryAssociatedToAnOrderObjectTest(){

        User anUser = [
            SELECT Id
            FROM User
            WHERE Username = 'test@elecmetal.com'
            LIMIT 1
        ];

        Order anOrder = [
            SELECT Id
            FROM Order
            LIMIT 1
        ];

        ContentVersion aContentVersion;
        String versionData = 'Testing base 64 encode';

        aContentVersion = new ContentVersion();
        aContentVersion.Title = 'test';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = anOrder.Id;
        
        Test.startTest();
        insert aContentVersion;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(1, fileLinks.size(), 'The registry on File Link was created when it should not be');
        
    }

    @IsTest
    static void creationOfFileLinkRegistryAssociatedToATaskObjectTest(){

        User anUser = [
            SELECT Id
            FROM User
            WHERE Username = 'test@elecmetal.com'
            LIMIT 1
        ];

        Task aTask = [
            SELECT Id
            FROM Task
            LIMIT 1
        ];

        ContentVersion aContentVersion;
        String versionData = 'Testing base 64 encode';

        aContentVersion = new ContentVersion();
        aContentVersion.Title = 'test';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = aTask.Id;
        
        Test.startTest();
        insert aContentVersion;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(1, fileLinks.size(), 'The registry on File Link was created when it should not be');
        
    }

    @IsTest
    static void creationOfFileLinkRegistryAssociatedToALeadObjectTest(){

        User anUser = [
            SELECT Id
            FROM User
            WHERE Username = 'test@elecmetal.com'
            LIMIT 1
        ];

        Lead aLead = [
            SELECT Id
            FROM Lead
            LIMIT 1
        ];

        ContentVersion aContentVersion;
        String versionData = 'Testing base 64 encode';

        aContentVersion = new ContentVersion();
        aContentVersion.Title = 'test';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = aLead.Id;
        
        Test.startTest();
        insert aContentVersion;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(1, fileLinks.size(), 'The registry on File Link was created when it should not be');
        
    }

}