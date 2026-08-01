import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendTripReport from '@salesforce/apex/manageTripReportController.sendTripReport';
import getEmails from '@salesforce/apex/manageTripReportController.getEmails';
import getAttachments from '@salesforce/apex/manageTripReportController.getAttachments';

const oColumns = [
    {label: 'Email', fieldName: 'Email'} 
];

const oColumnsAttachment = [
    {label: 'Attachment', fieldName: 'Name'}, 
    {label: 'Size (Approx)', fieldName: 'Size'} 
];

const formatter = new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });

export default class ManageTripReport extends LightningElement {

    @api recordId; 
    useModal            = false;
    wasEmailed          = false;
    emails              = [];
    attachments         = [];
    autoselectedemails      = [];
    autoselectedattachments = [];
    additionalemails;
    oColumns            = oColumns;
    oColumnsAttachment = oColumnsAttachment;
    totalAttachmentSize = 0;
    totalAttachmentSizeForDisplay = '0 Mb';
    // @wire(getAddresses, {}) 
    // getEmails(result) {
    //     if(result.data){
    //         this.emails = result.data;
    //         this.error = undefined;
    //         console.log('ManageTripReport: Calling getEmails');
    //     } else if (result.error) {
    //         this.error = result.error;
    //         this.emails = undefined;
    //     }
    // }

    @api
    get emailsExist() {
        if (this.emails == []) {
            return false;
        } else {
            return true;
        }
    }

    closeModal() {

        if (this.wasEmailed) {
            this.useModal = false;
        } else {
            if (confirm("The Trip Report has not been emailed. Are you sure you want to Close?")) {
                this.useModal = false;
            }
        }
        
    }

    handlePreSend() {
        this.useModal = true;
        this.showSpinner = true;
        this.wasEmailed = false;
        getEmails()
        .then(result => {
            this.showSpinner = false;
            let currentData = [];
            let currentSelectedData = [];
            currentSelectedData.push(result[0]);
            result.forEach((row) => {
                let rowData = {};
                //rowData.Id                   = row;
                rowData.Email                = row;
                currentData.push(rowData);
                //currentSelectedData.push(row);
            });
            //this.emails =  JSON.stringify(currentData);
            this.emails             =  currentData;
            this.autoselectedemails =  currentSelectedData;
            //this.emails = result;
            this.error = undefined;
            this.getAttachmentsJS();
        }).catch(error=>{
            this.showSpinner = false;
            this.error = error;
            this.emails = undefined;
            this.attachments    = undefined;
            //this.autoselectedattachments =  undefined;
        })
    }

    getAttachmentsJS() {
        console.log("getAttachmentsJS Enter");
        //this.totalAttachmentSize = 0;
        getAttachments( { oRecordId: this.recordId } )
        .then(result => {
            this.showSpinner = false;
            console.log("getAttachmentsJS ", JSON.stringify(result));
            let currentData         = [];
            let currentSelectedData = [];
            result.forEach((row) => {
                let rowData = {};
                let rowDataIdOnly = {};
                //rowData.Id                   = row;
                rowData.Id                = row.Id;
                rowData.Name                = row.Title;
                if (row.ContentSize < 1000000) {
                    rowData.Size                = parseInt(row.ContentSize * 0.001);
                    rowData.Size += ' Kb';
                } else {
                    rowData.Size                = parseInt(row.ContentSize * 0.000001);
                    rowData.Size += ' Mb';
                }
                rowData.ContentSize = row.ContentSize;
                rowDataIdOnly.Id = row.Id;
                //this.totalAttachmentSize += row.ContentSize;
                currentData.push(rowData);
                currentSelectedData.push(rowDataIdOnly);
            });
            
            this.attachments             =  currentData;
            this.autoselectedattachments =  currentSelectedData;
            this.error = undefined;
            console.log("getAttachmentsJS this.attachments ", JSON.stringify(this.attachments));
            console.log("getAttachmentsJS this.autoselectedattachments ", JSON.stringify(this.autoselectedattachments));
        }).catch(error=>{
            this.showSpinner    = false;
            this.error          = error;
            this.attachments    = undefined;
            this.autoselectedattachments =  undefined;
        })
    }

    handleSend() {
        //this.useModal = true;
        console.log("handleSend Enter");
        

        //----------------------------------------------------------------------------------------------------
        var emailtable = this.template.querySelector("[data-field='emailtable']");
        //ALSO CAN USE var el = this.template.querySelector("lightning-datatable");
        //----------------------------------------------------------------------------------------------------
        var oAddresses = [];

        var emailsSelected = emailtable.getSelectedRows();

        emailsSelected.forEach((j) => {
            if (j != '') {
                oAddresses.push(j.Email);
            }
        });

        if (this.additionalemails) {
            this.additionalemails = this.additionalemails.replace(";",",");
            
            (this.additionalemails||'').split(',').forEach((j) => {
                if (j != '') {
                    oAddresses.push(j);
                }
            });
        }

        console.log("sendTripReport parameter => B ", JSON.stringify(oAddresses));

        if ( !oAddresses || oAddresses.length === 0 || JSON.stringify(oAddresses) == []) {
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Trip Report',
                    message: 'At least one email address is required',
                    variant: 'warning'
                })
            );
            return;
        }

        if (this.totalAttachmentSize >= 25000000) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Trip Report',
                    message: 'There is a 25Mb limit on included attachments. Please adust selected attachment to stay under this limit.',
                    variant: 'warning'
                })
            );
            return;
        }

        console.log("sendTripReport this.attachments.length => ", this.attachments.length);
        console.log("sendTripReport JSON.stringify(this.attachments) => ", this.attachments.length);

        if ( this.attachments.length > 0 && JSON.stringify(this.attachments) != [] ) {
            //Attachments exist
            if (this.totalAttachmentSize == 0) {
                if (confirm("Send the Trip Report with out attachments?")) {
                    
                } else {
                    return;
                }
            }
        } 
        // else {
        //     if (this.totalAttachmentSize == 0) {
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Trip Report',
        //                 message: 'Please select at least one attachment.',
        //                 variant: 'warning'
        //             })
        //         );
        //         return
        //     }
        // }


        //----------------------------------------------------------------------------------------------------
        var attachmenttable = this.template.querySelector("[data-field='attachmenttable']");
        //----------------------------------------------------------------------------------------------------

        var attachmentsselected = attachmenttable.getSelectedRows();
        
        let oAttachmentIds = [];
        attachmentsselected.forEach((j) => {
            oAttachmentIds.push(j.Id);
        });

        console.log("getAttachmentsJS oAttachmentIds ", JSON.stringify(oAttachmentIds));

        this.showSpinner = true;

        sendTripReport( { oRecordId: this.recordId, oAddresses: oAddresses, oSelectedAttachments: oAttachmentIds } )
        .then(result => {
            this.error = undefined;
            this.showSpinner = false;
            this.wasEmailed = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Trip Report Sent',
                    variant: 'success'
                })
            );
            this.closeModal();
        }).catch(error=>{
            this.error = error;
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'We\'ve had an issue sending the Trip Report',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        })
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

        if(event.target.dataset.id === 'additionalemails'){
            this.additionalemails = value;
        }

  }

  handleAttachmentChange(event){

    //----------------------------------------------------------------------------------------------------
    var attachmenttable = this.template.querySelector("[data-field='attachmenttable']");
    //----------------------------------------------------------------------------------------------------

    var attachmentsselected = attachmenttable.getSelectedRows();

    this.totalAttachmentSize = 0;

    attachmentsselected.forEach((j) => {
        this.totalAttachmentSize += j.ContentSize;
    });

    let nCalc = 0;
    if (this.totalAttachmentSize < 1000000) {
        nCalc                = formatter.format(this.totalAttachmentSize * 0.001);
        this.totalAttachmentSizeForDisplay = nCalc + ' Kb';
    } else {
        nCalc                = formatter.format(this.totalAttachmentSize * 0.000001);
        //nCalc                = Math.round(this.totalAttachmentSize * 0.000001 * Math.pow(10, 2))
        this.totalAttachmentSizeForDisplay = nCalc + ' Mb';
    }

    if (this.totalAttachmentSize >= 25000000) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Trip Report',
                message: 'There is a 25Mb limit on included attachments.',
                variant: 'warning'
            })
        );
    }

  }


}