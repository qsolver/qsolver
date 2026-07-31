@isTest
public class ActivateContactControllerExtensionTest {
    
    @isTest static void testGetInactivatedContact() {
        // Step 1: Set up test data
        // Create a Contact record
        Contact testContact = new Contact(LastName = 'TestContact');
        insert testContact;
        
        // Create an Inactivated Contacts record related to the Contact
        InactivContacts__Inactivated_Contacts__c inactivatedContact = new InactivContacts__Inactivated_Contacts__c(
            InactivContacts__Contact__c = testContact.Id
        );
        insert inactivatedContact;

        // Step 2: Initialize the ActivateContactControllerExtension
        Test.startTest();
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testContact);
        ActivateContactControllerExtension controllerExtension = new ActivateContactControllerExtension(stdController);
        
        // Step 3: Test the getInactivatedContact method
        InactivContacts__Inactivated_Contacts__c result = controllerExtension.getInactivatedContact();
        
        Test.stopTest();
        
        // Step 4: Verify the result
        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assertEquals(inactivatedContact.Id, result.Id, 'The returned inactivated contact should match the one we created.');
    }

}