import { LightningElement, track, api, wire } from 'lwc';

import { notifyRecordUpdateAvailable, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import LINE_OF_BUSINESS from '@salesforce/schema/Account.Line_of_Business__c';
import getAccount from '@salesforce/apex/changeSalesRepLWController.getAccount';
import updateAccAndOpps from '@salesforce/apex/changeSalesRepLWController.updateAccAndOpps';

export default class ChangeSalesRepLWC extends LightningElement {
    @api recordId;
    @api salesrepsel;
    @track isModalOpen = false;
    @track Account;
    @track selectedValues = [];
    @track options = [];
    @track defaultOpportunityRecordTypeId;
    @track saveStatus = true;
    @track closedOpps = false;
    @track openOpps = false;
    @track openTasks = false;
    @track closedTasks = false;
    @track selectedUser;
    @track fieldSelected;
    @track userSelectedCheck;
    @track lineOfBusCheck;
    @track isSaving = false;

    //Modal - Inicio
    openModal() {
        this.isModalOpen = true;
        this.selectedValues = [];
        this.salesrepsel = '';
    }
    connectedCallback() {
        this.selectedUser = '';
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }

    submitDetails() {
        this.isSaving = true;
        console.log('this.openTasks => '+this.openTasks);
        updateAccAndOpps({ oAccountId: this.recordId, oNewSalesRep: this.selectedUser, oLineOfBus: this.fieldSelected.toString(), oCheckOpen: this.openOpps, oCheckClosed: this.closedOpps, oCheckTasksOpen: this.openTasks, oCheckTasksclosed: this.closedTasks })
            .then(result => {
                if (result) {
                    this.showSuccessToast();
                    this.isModalOpen = false;
                    // Notificar al Flexipage que los datos se han actualizado
                    notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                    this.selectedValues = [];
                    this.saveStatus = true;
                } else {
                    this.showErrorToast();
                }
            })
            .catch(error => {
                console.log('Error: ', error);
                this.showErrorToast();
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    //Modal - Fin

    @wire(getAccount, { oAccountId: '$recordId' })
    getAccount(result) {
        if (result.data) {
            this.Account = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.Account = undefined;
        }
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo({ error, data }) {
        if (data) {
            this.defaultOpportunityRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.log(error);
        }
    }
    //Picklist de LB - Inicio
    @wire(getPicklistValues, { recordTypeId: '$defaultOpportunityRecordTypeId', fieldApiName: LINE_OF_BUSINESS })
    getStageNamePickListValues({ error, data }) {
        if (data) {
            this.options = data.values;
        } else if (error) {
            console.log(error);
        }
    }

    handlePicklistChange(event) {
        this.selectedValues = event.detail.value;
        // Utilizar un case para realizar diferentes acciones según el valor seleccionado
        switch (this.selectedValues) {
            case 'Alerta Temprana':
                // Acción para la opción 1
                this.handleCheckSalesRep('Vendedor_Alerta_Temprana__c');
                break;
            case 'Molienda':
                // Acción para la opción 2
                this.handleCheckSalesRep('Vendedor_Molienda__c');
                break;
            case 'GET':
                // Acción para la opción 3
                this.handleCheckSalesRep('Vendedor_GET__c');
                break;
            case 'Chancado':
                // Acción para la opción 4
                this.handleCheckSalesRep('Vendedor_Chancado__c');
                break;
            case 'Maestranza':
                // Acción para la opción 5
                this.handleCheckSalesRep('Vendedor_Maestranza__c');
                break;
            case 'Bolas (Grinding Media)':
                // Acción para la opción 6
                this.handleCheckSalesRep('Vendedor_Grinding_Media__c');
                break;
            case 'Other':
                // Acción para la opción 7
                this.handleCheckSalesRep('ELM_OtherSalesRep__c');
                break;
            case 'High Value':
                // Acción para la opción 8
                this.handleCheckSalesRep('High_Value_Manager__c');
                break;
            default:
                // Acción por defecto si no se seleccionó ninguna opción válida
                console.log('No option has been chosen.');
                break;
        }
    }

    handleCheckSalesRep(field_) {
        if (this.Account[field_]) {
            this.fieldSelected = [field_];
            this.lineOfBusCheck = true;
        } else {
            const event = new ShowToastEvent({
                title: '¡Atention!',
                message: 'There´s not previous Sales Rep to change. Select one that´s populated.',
                variant: 'warning',
            });
            this.dispatchEvent(event);
            this.lineOfBusCheck = false;
        }
        this.handleSaveButtonStatus();
    }
    //Picklist de LB - Fin

    //Input - Lookup User - Inicio

    handleUserChange(event) {
        this.selectedUser = event.detail.value[0];
        (this.selectedUser) ? this.userSelectedCheck = true : this.userSelectedCheck = false;
        this.handleSaveButtonStatus();
    }
    //Input - Lookup User - Fin

    handleSaveButtonStatus() {
        if (this.userSelectedCheck && this.lineOfBusCheck) {
            this.saveStatus = false;
        } else {
            this.saveStatus = true;
        }
    }

    //Checkboxes de Opps - Inicio
    // Función para manejar el cambio en el checkbox de oportunidades cerradas
    handleClosedOppsChange(event) {
        this.closedOpps = event.target.checked;
    }

    // Función para manejar el cambio en el checkbox de oportunidades abiertas
    handleOpenOppsChange(event) {
        this.openOpps = event.target.checked;
    }

    // Función para manejar el cambio en el checkbox de tareas abiertas
    handleOpenTasksChange(event) {
        this.openTasks = event.target.checked;
    }

    // Función para manejar el cambio en el checkbox de oportunidades cerradas
    handleClosedTasksChange(event) {
        this.closedTasks = event.target.checked;
    }
    //Checkboxes de Opps - Fin

    showSuccessToast() {
        const evt = new ShowToastEvent({
            message: 'The records were successfully updated',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    showErrorToast() {
        const evt = new ShowToastEvent({
            message: 'There was an error, contact Admin.',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}