@isTest
public with sharing class AssetTriggerTest {

    @TestSetup
    static void makeData(){

        Account anAccountNA = BuilderController.anAccountCustomer()
        .withName('Test Account NA')
        .withPhone('8888')
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

        insert anAccountNA;

        Account anAccountSA = BuilderController.anAccountCustomer()
        .withName('Test Account SA')
        .withPhone('8888')
        .withType('Customer')
        .withRegion('NA')
        .withBillingCity('Burns Harbor')
        .withBillingCountry('USA')
        .withBillingPostalCode('46304')
        .withBillingState('IN')
        .withBillingStreet('250 West Us Hghway 12')
        .withCopyBillingAddresstoShippingAddress(false)
        .build();

        insert anAccountSA;

        Asset anAsset;
        anAsset = BuilderController.anAsset()
        .withIsCompetitorProduct(false)
        .withCurrentlyInstalled(true)
        .withIsInternal(true)
        .withLineofBusiness('Alerta Temprana')
        .withMEElecmetalEquipment(true)
        .withName('Test Asset SA')
        .withNeverInstalled(true)
        .withPreviouslyInstalled(false)
        .withAccountId(anAccountSA)
        .build();

        insert anAsset;

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
    }

    @IsTest
    static void checkNAUsersCannotCreateSouthAmericanAssets(){

        Account anAccountSA = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account SA'
        ];

        User user = [
            SELECT Id
            FROM User
            WHERE Username = 'testmanagerna@elecmetal.com'
        ];

        Asset anAsset;
        anAsset = BuilderController.anAsset()
        .withIsCompetitorProduct(false)
        .withCurrentlyInstalled(true)
        .withIsInternal(true)
        .withLineofBusiness('Alerta Temprana')
        .withMEElecmetalEquipment(true)
        .withName('Test Asset NA')
        .withNeverInstalled(true)
        .withPreviouslyInstalled(false)
        .withAccountId(anAccountSA)
        .build();
        
        Test.startTest();
        System.runAs(user){
            
            Database.SaveResult result = Database.insert(anAsset, false);

            Assert.AreEqual(false, result.isSuccess(),'The record was successfully created when it should not have');
        }
        Test.stopTest();
        
        
    }

    @IsTest
    static void checkNAUsersCannotUpdateSouthAmericanAssets(){

        Asset anAssetSA = [
            SELECT Id, Never_Installed__c
            FROM Asset
            WHERE Name = 'Test Asset SA'
        ];

        User user = [
            SELECT Id
            FROM User
            WHERE Username = 'testmanagerna@elecmetal.com'
        ];
        
        Test.startTest();
        System.runAs(user){
            
            anAssetSA.Never_Installed__c = false;

            Database.SaveResult result = Database.update(anAssetSA, false);

            Assert.AreEqual(false, result.isSuccess(),'The record was successfully updated when it should not have');
        }
        Test.stopTest();
        
        
    }
}