import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getOpportunity from '@salesforce/apex/manageOLIPricingController.getOpportunity';
import getOpportunityLineItems from '@salesforce/apex/manageOLIPricingController.getOpportunityLineItems';
import updatePricing from '@salesforce/apex/manageOLIPricingController.updatePricing';

//import { refreshApex } from '@salesforce/apex';  //https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.apex
import { NavigationMixin } from 'lightning/navigation';  //https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.use_navigate_basic

export default class ManageOpportunityProductPricing extends LightningElement {

    @api recordId; 
    @track useModal = false;
    @track showSpinner = false;
    @track error;
    @track message;
    @track OpportunityLineItems = [];
    @track wiredOpportunityLineItems = [];
    @track Opportunity;

    //internalmessage;
    //internalalerttype;

    @wire(getOpportunity, {oOpportunityId: '$recordId'}) 
    wiredgetOpportunity(result) {
        //this.wiredOpportunityLineItems = result;

        console.log('manageOpportunityProductPricing.wiredgetOpportunity:'+JSON.stringify(result));
        
        if(result.data){
            this.Opportunity = result.data;
            this.error = undefined;
            this.loadOpportunityLineItems();
        } else if (result.error) {
            this.error = result.error;
            this.Opportunity = undefined;
        }
    }

    connectedCallback() { 
        //This happens on the initial load
        //this.loadOpportunityLineItems();
    }

    //--------------------------------------------------
    showToastError(title, message) { this.showToast(this.title, this.message, 'error'); }
    showToastWarning(title, message) { this.showToast(this.title, this.message, 'warning'); }
    showToastSuccess(title, message) { this.showToast(this.title, this.message, 'success'); } 
    showToastInfo(title, message) { this.showToast(this.title, this.message, 'info'); }

    showToast(otitle, omessage, ovariant) {
        const event = new ShowToastEvent({ title: this.otitle, message: this.omessage, variant: this.ovariant });
        this.dispatchEvent(event);
    }
    //--------------------------------------------------

    @api
    get opportunityProductExist() {
        return (this.OpportunityLineItems.length > 0);
    }

    loadOpportunityLineItems() { 
        this.showSpinner = true;
        getOpportunityLineItems( { oOpportunityId: this.recordId } )
        .then(result => {
            console.log('manageOpportunityProductPricing.loadOpportunityLineItems:'+JSON.stringify(result));
            this.OpportunityLineItems = result;
            //this.PriceBookName = this.OpportunityLineItems[0].Opportunity.PriceBook2.Name;
            //this.calculateGrandTotal(result);
            this.error = undefined;
            //this.bRefreshRequired = false;
            this.showSpinner = false;
        }).catch(error=>{
            this.error = error;
            this.OpportunityLineItems = undefined;
            this.showSpinner = false; 
        })
    }

    handleManagePricing() {
        this.message = undefined;
        this.error = undefined;
        this.useModal = true;
        this.showSpinner = false;
    }

    updatePricing() {
        //this.useModal = true;
        this.showSpinner = true;
        updatePricing( { oOpportunityId: this.recordId } )
        .then(result => {
            this.error = undefined;
            this.loadOpportunityLineItems();
            this.showSpinner = false; 
            this.message = 'Opportunity Product Pricing was updated.';
            this.showToastSuccess('Manage Pricing', 'Opportunity Product Pricing was updated.');
        }).catch(error=>{
            this.error = error;
            this.showSpinner = false; 
            this.message = 'Opportunity Product Pricing failed to update.';
            this.showToastError('Manage Pricing', 'Opportunity Product Pricing failed to update.');
        })
    }

    closeModal() {
        this.useModal = false;
    }

}