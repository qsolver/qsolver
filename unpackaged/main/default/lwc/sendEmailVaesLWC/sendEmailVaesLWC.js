import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/VaesSendEmailController.sendEmail';

export default class SendEmailVaesLWC extends LightningElement {

    @api recordId;

    handleClick(){

        sendEmail({recordId: this.recordId}).then((result) =>{
            this.showSuccessToast();
        }).catch((err) =>{
            this.showErrorToast();
        })

    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
            message: 'The email was successfully sent!',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    showErrorToast() {
        const evt = new ShowToastEvent({
            message: 'An error occurred sending the email. Please, fill the Contact Field.',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

}