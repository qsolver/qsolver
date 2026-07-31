import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendVAES from '@salesforce/apex/manageVAESEmailSend.sendVAES';
import getEmails from '@salesforce/apex/manageVAESEmailSend.getEmails';
import getAttachments from '@salesforce/apex/manageVAESEmailSend.getAttachments';


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
export default class ManageVAESEmails extends LightningElement {

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
    subject = '';
    emailBody = '';
    // Boolean properties to track the current view
    isView1 = false;
    isView2 = false;

    // This method will handle which button was clicked
    handleButtonClick(event) {
        const clickedView = event.target.dataset.view;

        // Reset both views before updating the selected view
        this.isView1 = false;
        this.isView2 = false;

        // Check which button was clicked and set the appropriate view
        if (clickedView === 'view1') {
            this.isView1 = true;
        } else if (clickedView === 'view2') {
            this.isView2 = true;
        }
    }


    //Copied Code ------------------------------------------------------------------

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
            if (confirm("The VAES File has not been emailed. Are you sure you want to Close?")) {
                this.useModal = false;
            }
        }
        
        
    }

    refreshVariables(){
        this.emails = [];
        this.attachments = [];
        this.autoselectedemails = [];
        this.autoselectedattachments = [];
        this.additionalemails = '';
        this.totalAttachmentSize = 0;
        this.totalAttachmentSizeForDisplay = '0 Mb';
        this.subject = '';
        this.emailBody = '';
    }

    handlePreSend(event) {



        const clickedView = event.target.dataset.view;

        // Reset both views before updating the selected view
        this.isView1 = false;
        this.isView2 = false;

        // Check which button was clicked and set the appropriate view
        if (clickedView === 'view1') {
            this.isView1 = true;
        } else if (clickedView === 'view2') {
            this.isView2 = true;
        }

        console.log('isView1 > '+this.isView1);
        console.log('isView2 > '+this.isView2);

        this.refreshVariables();

        


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
            this.autoselectedemails = currentSelectedData;
            //console.log('Slected emials '+this.autoselectedemails);
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

    handleSubjectChange(event){

        this.subject = event.target.value;

    }

    handleEmailBodyChange(event){

        this.emailBody = event.target.value;

    }

    handleSend() {



        //this.useModal = true;
        console.log("handleSend Enter");
        var oAddresses = [];

        if(this.isView1){
            console.log("Inside isView1");
        
        //----------------------------------------------------------------------------------------------------
        var emailtable = this.template.querySelector("[data-field='emailtable']");
        //ALSO CAN USE var el = this.template.querySelector("lightning-datatable");
        //----------------------------------------------------------------------------------------------------

        var emailsSelected = emailtable.getSelectedRows();

        emailsSelected.forEach((j) => {
            if (j != '') {
                oAddresses.push(j.Email);
            }
        });

        }

        


        

        if (this.additionalemails) {
            console.log("additionalemails #1 ");
            this.additionalemails = this.additionalemails.replace(";",",");
            console.log("additionalemails #2 ");
            
            (this.additionalemails||'').split(',').forEach((j) => {
                if (j != '') {
                    oAddresses.push(j);
                }
            });
            console.log("additionalemails #3 ");
        }

        

        if ( !oAddresses || oAddresses.length === 0 || JSON.stringify(oAddresses) == []) {
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'VAES Email',
                    message: 'At least one email address is required',
                    variant: 'warning'
                })
            );
            return;
        }

        

        if (this.totalAttachmentSize >= 25000000) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'VAES Email',
                    message: 'There is a 25Mb limit on included attachments. Please adust selected attachment to stay under this limit.',
                    variant: 'warning'
                })
            );
            return;
        }

        

        if ( this.attachments.length > 0 && JSON.stringify(this.attachments) != [] ) {
            //Attachments exist
            if (this.totalAttachmentSize == 0) {
                if (confirm("Send VAES with out attachments?")) {
                    
                } else {
                    return;
                }
            }
        } 
        


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

        console.log('Record Id > '+this.recordId);
        console.log('isView1 > '+this.isView1);


        sendVAES( { oRecordId: this.recordId, oAddresses: oAddresses, oSelectedAttachments: oAttachmentIds, emailSubject: this.subject, emailBody:  this.emailBody, isInternal: this.isView1} )
        .then(result => {
            this.error = undefined;
            this.showSpinner = false;
            this.wasEmailed = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'VAES Sent',
                    variant: 'success'
                })
            );
            this.closeModal();
            this.isView1 = false;
            this.isView2 = false;
        }).catch(error=>{
            this.error = error;
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'We\'ve had an issue sending the VAES',
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
                title: 'VAES Email',
                message: 'There is a 25Mb limit on included attachments.',
                variant: 'warning'
            })
        );
    }

  }

}