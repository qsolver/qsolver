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
public with sharing class manageOLIPricingController {

    private static final String oClass = 'manageOLIPricingController';

    public manageOLIPricingController() {

    }

    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunity(String oOpportunityId) { 

        String oMethod = 'getOpportunity';

        System.debug(oClass +'.'+oMethod+ '; Enter. Opportunity Id = ' + oOpportunityId);

        return [Select Id, Name, PriceBook2.Name From Opportunity Where Id = :oOpportunityId];

    }

    // ----------------------------------------------------------------------------------------------------
    // This works great but its hard to make styling decision in the template if I need to compare properties.
    // For Example: I need to change a color if ListPrice != UnitPrice but doing something like 
    // <template if:false={it.value.UnitPrice == it.value.ListPrice}> gives an error so now
    //I need to make a wrapper class and determine this answer in apex
    // ----------------------------------------------------------------------------------------------------

    // @AuraEnabled //(cacheable=true)
    // public static List<opportunityLineItem> getOpportunityLineItems(String oOpportunityId) { 

    //     String oMethod = 'getOpportunityLineItems';

    //     System.debug(oClass +'.'+oMethod+ '; Enter. Opportunity Id = ' + oOpportunityId);

    //     List<opportunityLineItem> oList = [Select Id, Name, Product2.Name, Quantity, ListPrice, UnitPrice From OpportunityLineItem Where OpportunityId = :oOpportunityId ORDER BY Name];

    //     return oList;

    // }
    
    @AuraEnabled //(cacheable=true)
    public static List<WrapperOpportunityLineItem> getOpportunityLineItems(String oOpportunityId) { 

        String oMethod = 'getOpportunityLineItems';

        System.debug(oClass +'.'+oMethod+ '; Enter. Opportunity Id = ' + oOpportunityId);

        List<WrapperOpportunityLineItem> oReturn = new List<WrapperOpportunityLineItem>();

        List<opportunityLineItem> oList = [Select Id, Name, Product2.Name, Quantity, ListPrice, UnitPrice From OpportunityLineItem Where OpportunityId = :oOpportunityId ORDER BY Name];

        Long lId = System.now().getTime();

        for (opportunityLineItem oli : oList) {

            WrapperOpportunityLineItem w = new WrapperOpportunityLineItem(oli); 
            w.Id = String.valueOf(lId);
            lId = lId + 1;

            w.PricesMatch = (oli.ListPrice == oli.UnitPrice);
            System.debug(oClass +'.'+oMethod+ '; PricesMatch = ' + w.PricesMatch);
            oReturn.add(w);

        }

        return oReturn;

    }

    @AuraEnabled //(cacheable=true)
    public static void updatePricing(String oOpportunityId) { 

        String oMethod = 'updatePricing';

        System.debug(oClass +'.'+oMethod+ '; Enter. Opportunity Id = ' + oOpportunityId);

        if (String.isBlank(oOpportunityId)) { return; }

        List<opportunityLineItem> oForUpdate = new List<opportunityLineItem>();

        List<opportunityLineItem> oList = [Select Id, ListPrice, UnitPrice From OpportunityLineItem Where OpportunityId = :oOpportunityId];

        for (opportunityLineItem oli : oList) { 
            if (oli.ListPrice != oli.UnitPrice) {
                //WHY DO IT THIS WAY?
                //Update behaves strange in that if I include the ListPrice it will complain I can not change it - even when I am NOT changing it.
                opportunityLineItem oNewOLI = new opportunityLineItem();
                oNewOLI.Id = oli.Id;
                oNewOLI.UnitPrice = oli.ListPrice;
                oForUpdate.add(oNewOLI);
            }
        }

        if (oForUpdate.size() > 0) {
            System.debug(oClass +'.'+oMethod+ '; Updating = ' + oForUpdate);
            update oForUpdate;
        }

    }
}