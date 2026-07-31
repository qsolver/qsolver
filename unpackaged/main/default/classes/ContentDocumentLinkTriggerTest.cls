@isTest
public class ContentDocumentLinkTriggerTest {

    @testSetup
    static void setupTestData() {
        // Create a Task record to associate with ContentDocumentLink
        Task task = new Task(
            Subject = 'Test Task',
            Status = 'Not Started',
            Priority = 'Normal'
        );
        insert task;
        
        // Create an Account record to test non-Task LinkedEntityId
        Account account = new Account(
            Name = 'Test Account'
        );
        insert account;
        
        // Create a ContentVersion (necessary for ContentDocumentLink)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Content'), // Content of the file
            IsMajorVersion = true
        );
        insert contentVersion;
        
        // Retrieve the auto-created ContentDocumentId from the inserted ContentVersion
        String contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1].ContentDocumentId;

        // Link the ContentDocument to the Task using ContentDocumentId
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = task.Id, // This links the content to the Task
            ContentDocumentId = contentDocumentId,
            ShareType = 'I' // Inferred permission
        );
        insert contentDocumentLink;
    }

    @isTest
    static void testContentDocumentLinkTriggerWithTask() {
        // Retrieve the Task and ContentDocumentLink created in testSetup
        Task task = [SELECT Id FROM Task LIMIT 1];
        ContentDocument contentDocument = [SELECT Id FROM ContentDocument LIMIT 1];
        
        // Check if ContentDocumentLink already exists for the Task and ContentDocument
        ContentDocumentLink existingCDL = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :task.Id AND ContentDocumentId = :contentDocument.Id LIMIT 1];
        
        // Optionally, assert that the ContentDocumentLink exists and the trigger logic has been processed
        System.assertNotEquals(null, existingCDL, 'ContentDocumentLink should already exist for this Task.');
    }

    @isTest
    static void testContentDocumentLinkTriggerWithoutTask() {
        // Retrieve the Account created in testSetup
        Account account = [SELECT Id FROM Account LIMIT 1];
        ContentDocument contentDocument = [SELECT Id FROM ContentDocument LIMIT 1];
        
        // Create a ContentDocumentLink with LinkedEntityId as an Account (not a Task)
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = account.Id, // Linking to the Account instead of a Task
            ContentDocumentId = contentDocument.Id,
            ShareType = 'I' // Inferred permission
        );
        
        Test.startTest();
        
        // Insert the ContentDocumentLink to invoke the trigger
        insert cdl;
        
        Test.stopTest();
        
        
    }
}