/**
* @author   Cirrius Solutions
* @version  Oct.2021
*
* CHANGE HISTORY
* =============================================================================
* Date          Name            Description
* Oct.2021      Cirrius         Created
* =============================================================================
*/ 
@isTest
public class manageTripReportControllerTest {

    @TestSetup
    static void makeData() {

        Account a = new Account();
        a.Name = 'Test Account';
        a.Region__c = 'NA';
        a.Line_of_Business__c = 'Other';
        insert a;

        Contact c = new Contact (FirstName = 'Test', LastName = 'Test', Email = 'test@test.com', AccountId = a.id);
        insert c;

        ID standardPBID = Test.getStandardPricebookId();

        Product2 p  = new Product2();
        p.Name      = 'Test';
        insert p;
        
         //Create pricebook entries for the products
         PricebookEntry pbe = new PricebookEntry();
         pbe.Pricebook2Id    = standardPBID;
         pbe.Product2Id      = p.id;
         pbe.UnitPrice       = 1;
         pbe.IsActive        = true;
         insert pbe;

        Opportunity o   = new Opportunity();
        o.Name          = 'Test'; 
        o.StageName     = 'Qualification';
        o.CloseDate     = Date.Today()+1; 
        o.AccountId     = a.id; 
        o.Description   = 'Test';
        o.Pricebook2Id  = standardPBID;
        o.Ship_Date__c  = Date.Today()+1;
        o.Pricebook2Id  = standardPBID;
        o.Pricebook2Id  = standardPBID;
        o.Ship_Date__c = System.today() + 3;
        o.ELM_Line_of_Business__c = 'Other';
        insert o;

        PricebookEntry PricebookEntry = [
            SELECT Id
            FROM PricebookEntry
            WHERE Product2Id = : p.Id
            LIMIT 1
        ];

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = o.id , Quantity = 1.00,  PricebookEntryId = PricebookEntry.Id, UnitPrice = 0);
        insert oli; 

        // EmailTemplate oTemplate = new EmailTemplate();
        // oTemplate.isActive      = true;
        // oTemplate.Subject       = 'VALID_SUBJECT';
        // oTemplate.Name          = 'TEMPLATE_NAME';
        // oTemplate.DeveloperName = 'VALID_DEVELOPERNAME';
        // oTemplate.TemplateType  = 'Text';
        // oTemplate.FolderId      = UserInfo.getUserId();
        // oTemplate.HtmlValue     = 'BODY_HTML_VALUE';
        // oTemplate.Body          = 'BODY_TEXT_VALUE';
        // insert oTemplate;

    }

    public static testMethod void testMain() {

        Test.startTest();
        
        Account a = [Select Id From Account Limit 1];

        Trip_Report__c oTrip = new Trip_Report__c();
        oTrip.Customer_Company__c =  a.id;
        oTrip.Price_Vendor_Driver__c = '1';
        oTrip.Service_Vendor_Driver__c = '2';
        oTrip.Solution_Vendor_Driver__c = '3';
        oTrip.Delivery_Vendor_Driver__c = '4';
        oTrip.Quality_Vendor_Driver__c = '5';
        insert oTrip;

        ContentVersion oContent = new ContentVersion(); 
        oContent.Title          = 'Test'; 
        oContent.PathOnClient   = '/test.pdf'; 
        Blob oBlob              = Blob.valueOf('Test Body'); 
        oContent.VersionData    = oBlob; 
        insert oContent;

        List<String> oContents = new List<String>();
        oContents.add(oContent.id);

        List<String> oAddresses = new List<String>();
        oAddresses.add('test@meglobal.com');

        manageTripReportController.getEmails();
        manageTripReportController.sendTripReport(oTrip.Id, oAddresses, oContents);
        manageTripReportController.getContacts(oTrip.Id);

        List<String> oContacts = new List<String>();
        oContacts.add('test');

        manageTripReportController.saveTripReport(oTrip.Id, oContacts);
        Test.stopTest();
    }

}