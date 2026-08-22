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
public with sharing class bulkOpportunityCreationController {

    private static final String oClass = 'bulkOpportunityCreationController';

    public bulkOpportunityCreationController() {

    }

    @AuraEnabled(cacheable=true)
    public static Account getAccount(String oAccountId) { 

        String oMethod = 'getAccount';

        return [Select Id, Name From Account Where Id = :oAccountId];

    }

    // @AuraEnabled
    // public static List<Opportunity> getOpportunities(String oAccountId) { 

    //     String oMethod = 'getOpportunities';

    //     return getOpportunities2(oAccountId, System.today().year());

    // }

    @AuraEnabled
    public static List<Opportunity> getOpportunities(String oAccountId, Integer oYear) { 

        String oMethod = 'getOpportunities';

        return [Select Id, Name, Type, Ship_Date__c, Supplier_Notes__c From Opportunity 
                Where AccountId = :oAccountId 
                and CALENDAR_YEAR(Ship_Date__c) = :oYear
                Order by Name];

    }

    @AuraEnabled
    public static List<Opportunity> cloneOpportunities(List<Opportunity> oOpportunities, String oShipDate, String oCloseDate, String oStageName, Boolean oShipDateAddYear, Boolean oCloseDateAddYear) { 

        String oMethod = 'cloneOpportunities';

        Set<Id> oSetIds = new Set<Id>();
        for (Opportunity o : oOpportunities) {
            oSetIds.add(o.Id);
        }

        List<Opportunity> oExisting = [Select AccountId, Account_Region__c, Amount, CampaignId, CAR_Required_Qty__c, ClonedFromId__c, CloseDate, Commercial_Support_Requirements__c, 
                                    ContactId, Contacts_Identified__c, ContractId, CurrencyIsoCode, Current_Supplier__c, Customer_Equipment__c, Customer_Expected_Results__c,
                                    DB_Competitor__c, Decision_Maker_Identified__c, Delivery_Requirements__c, Description, ECO_Required_Qty__c, Fiscal, FiscalQuarter,
                                    FiscalYear, Follow_Up__c, ForecastCategory, ForecastCategoryName, Id, Influencer_Identified__c, LeadSource, Likely_to_Win__c, 
                                    ME_FIT_Program_Number__c, ME_FIT_Program__c, Name, NextStep, Opportunity_Number__c, Opportunity_Weight__c,
                                    Order_Generated__c, OwnerId, Performance_Guarantees__c, Potential_Blocker_Identified__c, 
                                    Pricebook2Id, Pricing_Strategy__c, Probability, Product_Test_Plan__c, 
                                    RecordTypeId, Ship_Date_Previous__c, Ship_Date__c, Ship_Year__c, StageName,
                                    Supplier_Notes__c, Technical_Buyer_Identified__c, Technical_Requirements__c, Tons__c, Type, 
                                    (select id, Name, Description, OpportunityId, Product2Id, ProductCode, Product_Item_Weight__c, Quantity, UnitPrice, ListPrice, Discount, ServiceDate, Customer_Material_Identifier__c, Total_Item_Weight__c  From OpportunityLineItems),
                                    (select id, ContactId, OpportunityId, IsPrimary, Role From OpportunityContactRoles) 
                                    From Opportunity Where Id IN :oSetIds];

        //Note: Not including because trying to reduce cloning validation issues
        //PO_Documents_have_been_uploaded__c
        //Ready_to_Sample__c

        List<Opportunity> oClonedResults = new List<Opportunity>();
        List<Opportunity> oClonedOpportunities = new List<Opportunity>();
        List<OpportunityLineItem> oClonedOpportunityLineItems = new List<OpportunityLineItem>();
        List<OpportunityContactRole> oClonedOpportunityContactRoles = new List<OpportunityContactRole>();

        for (Opportunity o : oExisting) {
            Opportunity oNew        = o.clone(false, true, false, false);
            oNew.ClonedFromId__c    = o.Id;

            System.Debug(oClass+'.'+oMethod+'; Processing ShipDate');
            System.Debug(oClass+'.'+oMethod+'; oShipDateAddYear:'+oShipDateAddYear);
            if (oShipDateAddYear) {
                if (o.Ship_Date__c != null) { oNew.Ship_Date__c = o.Ship_Date__c.addDays(365); }
            } else {
                if (oShipDate != null && oShipDate != 'undefined') 
                { 
                    try { oNew.Ship_Date__c       =  Date.valueOf(oShipDate); }
                    catch(Exception e){}
                }
            }
            
            System.Debug(oClass+'.'+oMethod+'; Processing CloseDate');
            System.Debug(oClass+'.'+oMethod+'; oCloseDateAddYear:'+oCloseDateAddYear);
            if (oCloseDateAddYear) {
                if (o.CloseDate != null) { oNew.CloseDate = o.CloseDate.addDays(365); }
            } else {
                if (oCloseDate != null && oShipDate != 'undefined') 
                { 
                    try { oNew.CloseDate          =  Date.valueOf(oCloseDate); }
                    catch(Exception e){}
                }
            }

            if (oStageName != null) { oNew.StageName          = oStageName; }

            oClonedOpportunities.add(oNew);
        }

        List<Database.SaveResult> oSaveResults = Database.insert(oClonedOpportunities, false);
        //integer oFailureCount = 0;

        for(Integer i = 0; i < oSaveResults.size();i++){
            if(oSaveResults[i].isSuccess()){
                //oFailureCount += 1;
                oClonedResults.add(new Opportunity(Id=oClonedOpportunities[i].ClonedFromId__c, Name=oClonedOpportunities[i].Name, 
                                                    CloseDate=oClonedOpportunities[i].CloseDate, Type=oClonedOpportunities[i].Type, Supplier_Notes__c='Sucess'));
            } else {
                oClonedResults.add(new Opportunity(Id=oClonedOpportunities[i].ClonedFromId__c, Name=oClonedOpportunities[i].Name, 
                                                    CloseDate=oClonedOpportunities[i].CloseDate, Type=oClonedOpportunities[i].Type, Supplier_Notes__c='Failed'));
            }
        }

        for (Opportunity oClone : oClonedOpportunities) {
            for (Opportunity oOriginal : oExisting) {
                if (oClone.Id != null) {
                    if (oClone.ClonedFromId__c == oOriginal.Id) {
                        for (OpportunityLineItem oOli : oOriginal.OpportunityLineItems) {
                            OpportunityLineItem oNewOli = oOli.clone(false, true, false, false);
                            oNewOli.OpportunityId = oClone.Id;
                            oClonedOpportunityLineItems.add(oNewOli);
                        }
                        for (OpportunityContactRole oOcr : oOriginal.OpportunityContactRoles) {
                            OpportunityContactRole oNewOcr = oOcr.clone(false, true, false, false);
                            oNewOcr.OpportunityId = oClone.Id;
                            oClonedOpportunityContactRoles.add(oNewOcr);
                        }
                    }
                }
            }
        }

        insert oClonedOpportunityLineItems;
        insert oClonedOpportunityContactRoles;

        return oClonedResults;
    }

}