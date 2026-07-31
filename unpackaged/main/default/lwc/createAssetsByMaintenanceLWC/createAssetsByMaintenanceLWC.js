import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAssetsResults from '@salesforce/apex/createAssetsByMaintenance.getAssetsResults';
import createJunctionRegisters from '@salesforce/apex/createAssetsByMaintenance.createJunctionRegisters';
import { NavigationMixin } from 'lightning/navigation';

export default class CreateAssetsByMaintenanceLWC extends NavigationMixin(LightningElement) {

    @api recordId;
    @api maintenanceId;

    name;
    recordsBackUp = [];
    LoadingText = false;

    @track disableInputField = false;
    @track searchRecords = [];
    @track selectedIds = [];
    @track selectedRecords = [];
    @track messageFlag = false;
    @track currentText;

    prevMaintenanceId;


    setName(event) {
        this.name = event.target.value;
    }


    searchField(event) {

        this.currentText = event.target.value;
        var selectRecId = [];
        for (let i = 0; i < this.selectedRecords.length; i++) {
            selectRecId.push(this.selectedRecords[i].recId);
        }
        this.LoadingText = true;
        getAssetsResults({ selectedAssetsIds: selectRecId, filter: this.currentText, maintenanceId: this.maintenanceId }).then(result => {

            this.searchRecords = result;
            this.recordsBackUp = result;
            this.LoadingText = false;
            if (this.currentText === null || this.currentText === undefined || this.currentText.length === 0) {
                this.LoadingText = false;
            }

            if (this.currentText.length > 0 && result.length == 0) {
                this.messageFlag = true;
            }
            else {
                this.messageFlag = false;
            }

            if (this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }
            else {
                this.iconFlag = true;
                this.clearIconFlag = false;
            }
        });
        if (this.selectedRecords.length > 0) {
            this.showResults = true;
        } else {
            this.showResults = false;
        }


    }

    setSelectedRecord(event) {

        var recId = event.currentTarget.dataset.id;
        var selectName = event.currentTarget.dataset.name;
        let newsObject = { 'Id': recId, 'Name': selectName };
        this.selectedIds.push(recId);
        this.selectedRecords.push(newsObject);
        this.searchRecords.forEach(record => {
            if (record.Id === recId) {
                this.searchRecords = this.searchRecords.filter(function (value, index, arr) {
                    return value.Id != recId
                });
            }
        })
        if (this.selectedRecords.length > 0) {
            this.showResults = true;
        } else {
            this.showResults = false;
        }

    }

    removeRecord(event) {

        var deletedRecordId = event.currentTarget.name;
        let selectRecId = [];
        let selectedIds1 = [];

        for (let i = 0; i < this.selectedRecords.length; i++) {
            if (deletedRecordId !== this.selectedRecords[i].Id) {
                selectRecId.push(this.selectedRecords[i]);
                selectedIds1.push(this.selectedRecords[i].Id)
            }
            this.recordsBackUp.forEach(record => {
                if (record.Id === deletedRecordId) {
                    this.searchRecords.push(record);
                }
            })
        }

        this.selectedRecords = [...selectRecId];
        this.selectedIds = [...selectedIds1];

        const selectedEvent = new CustomEvent('userselected', {
            detail: this.selectedRecords
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    createRegisters(event) {

        if (this.selectedIds != '') {


            createJunctionRegisters({ name: this.name, maintenance: this.maintenanceId, selectedAssetsIds: this.selectedIds })
                .then((result) => {
                    this.showSuccessToast();
                    this.updateRecordView();
                }).catch((error) => {
                    console.log('Error: ', error);
                    this.showErrorToast();
                });

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.maintenanceId,
                    objectApiName: 'Maintenance__c',
                    actionName: 'view'
                }
            });

            this.selectedIds = [];
            this.selectedRecords = [];
            this.currentText = '';

        } else {

            this.showErrorToast();

        }

    }

    updateRecordView() {
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 1000);
    }

    renderedCallback() {

        if (this.prevMaintenanceId !== this.maintenanceId) {

            console.log('Maintenance Id => '+this.maintenanceId);
            console.log('prevMaintenanceId => '+this.prevMaintenanceId);

            this.prevMaintenanceId = this.maintenanceId;

            if (this.selectedIds.length >= 0 && this.selectedRecords.length >= 0 && this.currentText !== undefined) {

                this.updateRecordView();

                console.log('Update record view executed');

            }

        }

    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
            message: 'The records were successfully created',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    showErrorToast() {
        const evt = new ShowToastEvent({
            message: 'All fields must be completed',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}