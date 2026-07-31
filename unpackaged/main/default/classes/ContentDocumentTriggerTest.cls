@IsTest
public with sharing class ContentDocumentTriggerTest {

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
        .build();

        insert anAccount;
        
    }

    @IsTest
    static void correctDeletionOfFileLinkRegistryWhenAContentVersionIsDeleted(){

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
        aContentVersion.Title = 'test2';
        aContentVersion.PathOnClient = 'testing';
        aContentVersion.VersionData = Blob.valueOf(versionData);
        aContentVersion.OwnerId = anUser.Id;
        aContentVersion.FirstPublishLocationId = anAccount.Id;

        insert aContentVersion;

        ContentVersion cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = : aContentVersion.Id
            LIMIT 1
        ];

        Id contentDocumentId = cv.ContentDocumentId;

        ContentDocument contentDocument = [
            SELECT Id
            FROM ContentDocument
            WHERE Id = : contentDocumentId
        ];
        
        Test.startTest();
        delete contentDocument;
        Test.stopTest();

        List<ELM_File_Link__c> fileLinks = [
            SELECT Id
            FROM ELM_File_Link__c
        ];

        System.assertEquals(0, fileLinks.size(), 'The registry on File Link was deleted when it should not be');
        
    }

}