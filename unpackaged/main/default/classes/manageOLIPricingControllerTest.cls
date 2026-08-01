/**
* @author   Cirrius Solutions
* @version  03.10.2021
*
* CHANGE HISTORY
* =============================================================================
* Date          Name            Description
* 03.10.2021    Cirrius         Created
* =============================================================================
*/ 
@isTest
public class manageOLIPricingControllerTest {

    @TestSetup
    static void makeData() {

        Account a = new Account();
        a.Name = 'Test Account';
        a.Region__c = 'NA';
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
        o.Ship_Date__c = System.today() + 3;
        o.Type = 'Liners';
        insert o;

        PricebookEntry pricebookEntry = [
            SELECT Id
            FROM PricebookEntry
            WHERE Product2Id = : p.Id
            LIMIT 1
        ];

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = o.id , Quantity = 1.00,  PricebookEntryId = pricebookEntry.id, UnitPrice = 0);
        insert oli; 

    }

    public static testMethod void testMain() {

        Test.startTest();
        
        Opportunity o = [Select Id From Opportunity Limit 1];

        Opportunity oOpportunity = manageOLIPricingController.getOpportunity(o.Id);

        System.AssertNotEquals(null, oOpportunity);

        manageOLIPricingController.getOpportunityLineItems(oOpportunity.Id);

        manageOLIPricingController.updatePricing(oOpportunity.Id);

        Test.stopTest();
    }

}