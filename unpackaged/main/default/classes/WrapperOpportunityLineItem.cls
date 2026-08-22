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
public class WrapperOpportunityLineItem {

    @AuraEnabled
    public String Id     {get;set;}  //This is the wrappers Id

    @AuraEnabled
    public boolean PricesMatch     {get;set;}   

    @AuraEnabled
    public OpportunityLineItem oli      {get;set;}  
    
    
    public WrapperOpportunityLineItem() {
        Id                  = String.valueOf(System.now().getTime()); //Ticks; Key in the iterator in the html
    }

    public WrapperOpportunityLineItem(OpportunityLineItem oli) {
        Id                  = String.valueOf(System.now().getTime()); //Ticks; Key in the iterator in the html
        this.oli            = oli;
    }

    // public WrapperOpportunityLineItem(OpportunityLineItem oli, Boolean PricesMatch) {
    //     Id                  = String.valueOf(System.now().getTime()); //Ticks; Key in the iterator in the html
    //     this.oli            = oli;
    //     this.PricesMatch    = PricesMatch;
    // }

}