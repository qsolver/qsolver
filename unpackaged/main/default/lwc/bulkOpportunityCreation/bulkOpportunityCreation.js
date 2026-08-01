import { LightningElement, api, wire, track } from 'lwc';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getAccount from '@salesforce/apex/bulkOpportunityCreationController.getAccount';
import getOpportunities from '@salesforce/apex/bulkOpportunityCreationController.getOpportunities';
import cloneOpportunities from '@salesforce/apex/bulkOpportunityCreationController.cloneOpportunities';

import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGENAME_FIELD from '@salesforce/schema/Opportunity.StageName';

//import { refreshApex } from '@salesforce/apex';  //https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.apex
import { NavigationMixin } from 'lightning/navigation';  //https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.use_navigate_basic

const oColumns = [
    // {label: 'Account Name', fieldName: 'AccountName', editable: false, initialWidth: 300},
    {label: 'Opportunity Name', fieldName: 'Name', initialWidth: 400},
    {label: 'Ship Date', fieldName: 'Ship_Date__c'},
    {label: 'Type', fieldName: 'Type'},
    {label: 'Status', fieldName: 'Supplier_Notes__c', editable:true} //Overriding this field so I don't need to use a Wrapper
];

export default class BulkOpportunityCreation extends LightningElement {

    @api recordId; 
    @track useModal = false;
    @track showSpinner = false;
    @track error;
    @track message;
    @track Opportunities = [];
    @track Errors = [];
    @track oColumns = oColumns;
    @track Account;
    @track opportunityyear = new Date().getFullYear();
    @track shipdate;
    @track shipdateaddyear = false;
    @track closedate;
    @track closedateaddyear = false;
    @track stagename = 'Qualification';
    @track stagenames;
    @track disableBulkCreateButton = false;

    @track objectInfo;
    @track defaultOpportunityRecordTypeId;

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT }) 
    objectInfo({error, data}) {
        if (data) {
            this.defaultOpportunityRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.log(error);
        }
    }

    get getRecordTypeId() {
        // Returns a map of record type Ids 
        //const recordTypes = this.objectInfo.data.recordTypeInfos;
        //return Object.keys(recordTypes).find(t => recordTypes[t].name === 'Support Request');
        return this.objectInfo.data.defaultRecordTypeId;
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultOpportunityRecordTypeId', fieldApiName: STAGENAME_FIELD } ) 
      getStageNamePickListValues({error, data}) {
        if (data) {
            //console.log("getStageNamePickListValues data.values => ", JSON.stringify(data.values));
            //console.log("getStageNamePickListValues data.values => ", JSON.stringify(data.values[0]));
            this.stagenames = data.values;


        } else if (error) {
            console.log(error);
        }
    }

    get opportunityyears() {
        return [
            { label: '2021', value: '2021' },
            { label: '2022', value: '2022' },
            { label: '2023', value: '2023' },
            { label: '2024', value: '2024' },
            { label: '2025', value: '2025' },
            { label: '2026', value: '2026' },
            { label: '2027', value: '2027' },
            { label: '2028', value: '2028' },
            { label: '2029', value: '2029' },
            { label: '2030', value: '2030' }
        ];
    }

    @wire(getAccount, {oAccountId: '$recordId'}) 
        getAccount(result) {

            //console.log('manageOpportunityProductPricing.wiredgetOpportunity:'+JSON.stringify(result));
            
            if(result.data){
                this.Account = result.data;
                this.error = undefined;
                console.log('BulkOpportunityCreation: Calling loadOpportunities');
                this.loadOpportunities();
            } else if (result.error) {
                this.error = result.error;
                this.Account = undefined;
            }

        }

    connectedCallback() { 
        //This happens on the initial load
        //this.loadOpportunityLineItems();
    }

    //--------------------------------------------------
    // showToastError(title, message) { this.showToast(this.title, this.message, 'error'); }
    // showToastWarning(title, message) { this.showToast(this.title, this.message, 'warning'); }
    // showToastSuccess(title, message) { this.showToast(this.title, this.message, 'success'); } 
    // showToastInfo(title, message) { this.showToast(this.title, this.message, 'info'); }

    // showToast(otitle, omessage, ovariant) {
    //     const event = new ShowToastEvent({ title: this.otitle, message: this.omessage, variant: this.ovariant });
    //     this.dispatchEvent(event);
    // }
    //--------------------------------------------------

    handleBulkOpportunityCreation() {
        this.message = undefined;
        this.error = undefined;
        this.useModal = true;
        this.showSpinner = false;
    }

    handleOpportunityYearChange(event) {
        //console.log('BulkOpportunityCreation: this.OpportunityYear: CURRENT:' + this.OpportunityYear);
        console.log('BulkOpportunityCreation: this.OpportunityYear: DISCOVERED:' + event.detail.value);
        this.opportunityyear = event.detail.value;
        console.log('BulkOpportunityCreation: this.OpportunityYear: ASSIGNED:' + this.opportunityyear);
        this.loadOpportunities();
    }

    handleBulkCreate() {
        this.cloneRecords();
    }

    handleChange(event){
        var value;
        console.log("handleChange event.target.type=> ", event.target.type);
        
        if(event.target.type === 'checkbox' || event.target.type === 'checkbox-button' || event.target.type === 'toggle'){
            //console.log("handleChange => event.target.checked:", event.target.checked);
            value = event.target.checked;
        }else{
            //console.log("handleChange => event.target.value:", event.target.value);
            value = event.target.value;
        }
        console.log("handleChange => event.target.dataset.id:", event.target.dataset.id);
        if(event.target.dataset.id === 'dateShipDate'){
            this.shipdate = value;
        }else if(event.target.dataset.id === 'checkboxShipDate'){
            this.shipdateaddyear = value;
        }else if(event.target.dataset.id === 'dateCloseDate'){
            this.closedate = value;
        }else if(event.target.dataset.id === 'checkboxCloseDate'){
            this.closedateaddyear = value;
        }else if(event.target.dataset.id === 'textProgress'){
            this.stagename = value;
        }

        console.log("handleChange => this.shipdate:", this.shipdate);
        console.log("handleChange => this.shipdateaddyear:", this.shipdateaddyear);
        console.log("handleChange => this.closedate:", this.closedate);
        console.log("handleChange => this.closedateaddyear:", this.closedateaddyear);
        console.log("handleChange => this.stagename:", this.stagename);

  }

    @api
    get opportunitiesExist() {
        if (this.Opportunities == []) {
            return false;
        } else {
            return true;
        }
        
    }

    loadOpportunities() {
        //this.useModal = true;
        //console.log('BulkOpportunityCreation: Entered getAccountOpportunities');
        //console.log('BulkOpportunityCreation: this.recordId: ' + this.recordId);
        //console.log('BulkOpportunityCreation: this.OpportunityYear: ' + this.opportunityyear);
        this.showSpinner = true;
        this.disableBulkCreateButton = false;
        this.Opportunities = [];
        getOpportunities( { oAccountId : this.recordId, oYear : this.opportunityyear } )
        .then(result => {
            //console.log('BulkOpportunityCreation.getAccountOpportunities:'+JSON.stringify(result));
            this.Opportunities = result;
            this.error = undefined;
            this.showSpinner = false; 
        }).catch(error=>{
            //console.log('BulkOpportunityCreation: Data failed: '+JSON.stringify(error));
            this.Opportunities = undefined;
            this.error = error;
            this.showSpinner = false; 
        })
    }

    cloneRecords() {
        //this.useModal = true;
        this.showSpinner = true;

        //----------------------------------------------------------------------------------------------------
        var oppstable = this.template.querySelector("[data-field='opptable']");
        //ALSO CAN USE var el = this.template.querySelector("lightning-datatable");
        //----------------------------------------------------------------------------------------------------

        //console.log("getSelectedRows => "+el);
        var oppsSelected = oppstable.getSelectedRows();
        //console.log("getSelectedRows => ", oppsSelected);
        //console.log("getSelectedRows => ", oppsSelected.length);
        //console.log("getSelectedRows => ", JSON.stringify(oppsSelected));
        //console.log("getSelectedRows => ", oppsSelected.length());
        //console.log("getSelectedRows => ", oppsSelected.size());

        //Note: Was acting inconsistently
        if ( !oppsSelected || oppsSelected.length === 0 || JSON.stringify(oppsSelected) == []) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Bulk Opportunity Creation',
                    message: 'Please select one or more Opportunities',
                    variant: 'warning'
                })
            );
            return;
        }

        //for(const x of oppsSelected) {
        //    console.log('BulkOpportunityCreation.cloneRecords:'+JSON.stringify(x));
        //}

        //this.disableBulkCreateButton = true;

        console.log("cloneOpportunities parameter => ", JSON.stringify(oppsSelected));
        console.log("cloneOpportunities parameter => this.shipdate:", this.shipdate);
        console.log("cloneOpportunities parameter => this.closedate:", this.closedate);
        console.log("cloneOpportunities parameter => this.stagename:", this.stagename);
        console.log("cloneOpportunities parameter => this.shipdateaddyear:", this.shipdateaddyear);
        console.log("cloneOpportunities parameter => this.closedateaddyear:", this.closedateaddyear);

        cloneOpportunities( {   oOpportunities:oppsSelected, 
                                oShipDate:this.shipdate, 
                                oCloseDate:this.closedate, 
                                oStageName:this.stagename, 
                                oShipDateAddYear:this.shipdateaddyear, 
                                oCloseDateAddYear:this.closedateaddyear } )
        .then(result => {
            this.error = undefined;
            this.showSpinner = false; 

            this.Opportunities=result;
            this.Errors={ rows: {}, table: {} };

            // https://forceblogs.com/how-to-display-errors-in-lightning-datatable/
            // https://salesforce.stackexchange.com/questions/319318/error-messages-for-multiple-lines-in-lwc-datatable

            this.Opportunities.forEach(ele => {
                //ele.style = ele.Supplier_Notes__c = 'Failed' ? 'slds-text-color_error' : 'slds-text-color_success';
                //ele.style = ele.Supplier_Notes__c = 'Failed' ? '{color:"red"}' : '{color:"green"}';
                //Object.assign(ele.style, {color:'green',textAlign:'center',fontSize:'15px'});
                if (ele.Supplier_Notes__c == 'Failed' && ele.Id != undefined) {

                    this.Errors.rows[ele.Id] = {title: 'Issues', 
                                                messages: ['Failed to Clone'],
                                                fieldNames: ['Supplier_Notes__c']};

                    
                }
                this.Errors.table.title = "We found issues...";
                this.Errors.table.messages = ['Failed to Clone'];
            });
            console.log("cloneOpportunities this.Errors => ", JSON.stringify(this.Errors));
            //this.Opportunities=result;
            //this.data = data;

            //if (result==0){
            //    this.message = 'All Opportunities Cloned.';
            //} else {
            //    this.message = 'Some Opportunities Cloned. ' + oFailureCount + ' Opportunities failed to Clone';
            //}
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Bulk Opportunity Creation',
                    message: 'Opportunities Cloned Completed',
                    variant: 'success'
                })
            );
        }).catch(error=>{
            this.error = JSON.stringify(error);
            this.showSpinner = false; 
            this.message = error.message;
            console.log("cloneOpportunities error => ", JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Bulk Opportunity Creation',
                    message: 'Opportunities Failed to Clone',
                    variant: 'error'
                })
            );
        })

    }

    closeModal() {
        this.useModal = false;
    }

}