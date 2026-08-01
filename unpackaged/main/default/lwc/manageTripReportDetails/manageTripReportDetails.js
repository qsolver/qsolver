import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { updateRecord } from 'lightning/uiRecordApi';
import saveTripReport from '@salesforce/apex/manageTripReportController.saveTripReport';
import getContacts from '@salesforce/apex/manageTripReportController.getContacts';

const oColumns = [
    {label: 'Name', fieldName: 'Name'} 
];

export default class ManageTripReportDetails extends LightningElement {

    @api recordId; 
    useModal            = false;
    contacts            = [];
    oColumns            = oColumns;
    refreshRequired     = false;

    @api
    get contactsExist() {
        if (this.contacts == []) {
            return false;
        } else {
            return true;
        }
    }

    closeModal() {
        this.useModal = false;
        if (this.refreshRequired == true) {
            window.location.reload();
        }
    }

    handleLoad() {
        this.useModal = true;
        this.showSpinner = true;
        getContacts( { oRecordId: this.recordId } )
        .then(result => {
            console.log("handleLoad => result:", JSON.stringify(result));
            this.showSpinner    = false;
            this.contacts       =  result;
            this.error          = undefined;
        }).catch(error => {
            this.showSpinner    = false;
            this.error          = error;
            this.contacts       = undefined;
        })
    }


    handleSave() {

        //----------------------------------------------------------------------------------------------------
        var contacttable = this.template.querySelector("[data-field='contacttable']");
        //ALSO CAN USE var el = this.template.querySelector("lightning-datatable");
        //----------------------------------------------------------------------------------------------------
        var oContacts = [];

        var contactsSelected = contacttable.getSelectedRows();

        contactsSelected.forEach((j) => {
            if (j != '') {
                oContacts.push(j.Name);
            }
        });

        this.showSpinner = true;

        saveTripReport( { oRecordId: this.recordId, oContacts: oContacts } )
        .then(result => {
            this.error = undefined;
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Trip Report Saved',
                    variant: 'success'
                })
            );
            this.refreshRequired = true;
            //updateRecord({fields: this.recordId});
            //window.location.reload();
        }).catch(error=>{
            this.error = error;
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'We\'ve had an issue saving the Trip Report',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        })
    }

}