@isTest
public class manageVAESEmailSendTest {
    
    @testSetup
    static void setupTestData() {
        
        //Insert an account to create the VAES
        Account a = new Account();
        a.Name = 'Test Account';
        a.Region__c = 'NA';
        a.Line_of_Business__c = 'Other';
        insert a;

        // Insert a Contact
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert testContact;

        // Insert a VAES Record
        ELM_Vaes__c vaesRecord = new ELM_Vaes__c(ELM_Project_Name__c = 'Test VAES', ELM_Account__c = a.Id);
        insert vaesRecord;

        // Create Setup Objects inside System.runAs()
    	System.runAs(new User(Id = UserInfo.getUserId())) {
        
        
       
        ContentVersion oContent = new ContentVersion(); 
        oContent.Title          = 'Test'; 
        oContent.PathOnClient   = '/test.pdf'; 
        Blob oBlob              = Blob.valueOf('Test Body'); 
        oContent.VersionData    = oBlob; 
        insert oContent;
        
        // Get the newly created ContentDocumentId from ContentVersion
    	ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Test' LIMIT 1];
        
        // Insert ContentDocumentLink (This links the file to the VAES record)
    	ContentDocumentLink contentLink = new ContentDocumentLink(
        LinkedEntityId = vaesRecord.Id,
        ContentDocumentId = insertedVersion.ContentDocumentId,
        ShareType = 'V'
    	);
    	insert contentLink;
        }
        
    }
    
    @isTest
    static void testGetSettings() {
        Test.startTest();
        Trip_Report_Setting__mdt result = manageVAESEmailSend.GetSettings();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Settings should not be null');
        System.assertEquals('Trip Report', result.Group_Name__c, 'Group name should match');
    }
    
    @isTest
    static void testGetAttachments() {
        Test.startTest();
        List<ContentVersion> attachments = manageVAESEmailSend.getAttachments(
            [SELECT Id FROM ELM_Vaes__c LIMIT 1].Id
        );
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, attachments, 'Attachments should not be null');
        System.assertEquals(1, attachments.size(), 'Should retrieve one attachment');
        System.assertEquals('Test', attachments[0].Title, 'Attachment title should match');
    }
    
    @isTest
    static void testGetEmails() {
        Test.startTest();
        List<String> emailList = manageVAESEmailSend.getEmails();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null,emailList,'EmailList should not be null');
        
    }
    
    @isTest
    static void testAddSAGroupsEmails() {
        List<String> inputEmails = new List<String>{'arachet@elecmetal.cl', 'Sales contact report Chile'};
        
        Test.startTest();
        List<String> resultEmails = manageVAESEmailSend.addSAGroupsEmails(inputEmails);
        Test.stopTest();

        // Assertions
        System.assert(resultEmails.contains('arachet@elecmetal.cl'), 'User email should be included');
        
    }


    @isTest
	static void testSendVAES() {
    	
    	Test.startTest();
        // Fetch required test records
        Id vaesRecordId = [SELECT Id FROM ELM_Vaes__c LIMIT 1].Id;
        Id contactId = [SELECT Id FROM Contact LIMIT 1].Id;
        List<String> emailAddresses = new List<String>{'recipient@example.com'};
        Id contentVersionId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
        List<String> attachments = new List<String>{contentVersionId};
        

        String subject = 'Test Email';
        String body = 'Test Email Body';
        

        // Call with isInternal = false (Covers plain text email logic)
        manageVAESEmailSend.sendVAES(vaesRecordId, emailAddresses, attachments, '', '', false);
        Test.stopTest();
        
        
	}


}