import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getVAESResults from '@salesforce/apex/createVAESByOpportunity.getVAESResults';
import getOpportunityProducts from '@salesforce/apex/createVAESByOpportunity.getOpportunityProducts';
import createJunctionRegisters from '@salesforce/apex/createVAESByOpportunity.createJunctionRegisters';
import createProductByVAESJunctionRegisters from '@salesforce/apex/createVAESByOpportunity.createProductByVAESJunctionRegisters';
import { NavigationMixin } from 'lightning/navigation';
export default class CreateVAESByOpportunity extends NavigationMixin(LightningElement) {

    @api recordId;
    @api opportunityId;

    name;
    recordsBackUp = [];
    LoadingText = false;

    @track disableInputField = false;
    @track searchRecords = [];
    @track selectedIds = [];
    @track selectedRecords=[];
    @track messageFlag = false;
    @track currentText;
    @track options = [];
    @track selectedProducts = [];

    prevOpportunityId;

    
    setName(event){
        this.name = event.target.value;
        console.log('Name Opp JS: '+this.name);
    }
    

    searchField(event) {

        console.log("OppID=>"+this.opportunityId);
        this.currentText = event.target.value;
        var selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            selectRecId.push(this.selectedRecords[i].recId);
        }
        this.LoadingText = true;
        getVAESResults({selectedVAESIds: selectRecId, filter: this.currentText, opportunityId: this.opportunityId}).then(result =>{
  
            console.log("Result=>"+result);
            this.searchRecords = result;
            this.recordsBackUp = result;
            this.LoadingText = false;
            if(this.currentText === null || this.currentText === undefined || this.currentText.length === 0){
                this.LoadingText = false;
            }
  
            if(this.currentText.length > 0 && result.length == 0) {
                this.messageFlag = true;
            }
            else {
                this.messageFlag = false;
            }
  
            if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }
            else {
                this.iconFlag = true;
                this.clearIconFlag = false;
            }
        });
        if(this.selectedRecords.length > 0){
            this.showResults = true;
        } else {
            this.showResults = false;
        }
  
  
    }

    setSelectedRecord(event) {

        var recId = event.currentTarget.dataset.id;
        var selectName = event.currentTarget.dataset.name;
        let newsObject = { 'Id' : recId ,'Name' : selectName };
        this.selectedIds.push(recId);
        this.selectedRecords.push(newsObject);
        this.searchRecords.forEach(record =>{
            if(record.Id === recId){
                this.searchRecords = this.searchRecords.filter(function(value, index, arr){
                    return value.Id != recId
                });
            }
        })
        if(this.selectedRecords.length > 0){
            this.showResults = true;
        } else {
            this.showResults = false;
        }
        
    }

    removeRecord (event){

        var deletedRecordId = event.currentTarget.name;
        let selectRecId = [];
        let selectedIds1 = [];
  
        for(let i = 0; i < this.selectedRecords.length; i++){
            if(deletedRecordId !== this.selectedRecords[i].Id){
                selectRecId.push(this.selectedRecords[i]);
                selectedIds1.push(this.selectedRecords[i].Id)
            }
            this.recordsBackUp.forEach(record =>{
                if(record.Id === deletedRecordId){
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

    //This is used to related opportunity products with selected VAES
    createProductByVAESRegisters(){

        createProductByVAESJunctionRegisters({selectedProductIds: this.selectedProducts, selectedVAESIds: this.selectedIds, opportunityId: this.opportunityId})
            .then((result) => {
                this.updateRecordView();
                this.showSuccessToast();
            }).catch((error) => {
                console.log('Error: ', error);
            });

    }

    createRegisters(event){

        if(this.selectedIds != ''){

            let junctionData = {
                name: this.name,
                currencyIsoCode: this.isoCode,
                opportunity: this.opportunityId
            }


            createJunctionRegisters({name: this.name, opportunity: this.opportunityId, selectedVAESIds: this.selectedIds})
            .then((result) => {

                this.showSuccessToast();
                this.updateRecordView();

                //to relate products to VAES
                if(this.selectedProducts.length > 0){
                    return this.createProductByVAESRegisters();
                }
                
            }).then(()=>{

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.opportunityId,
                        objectApiName: 'Opportunity',
                        actionName: 'view'
                        }
                    });
        
                    this.selectedIds = [];
                    this.selectedRecords = [];
                    this.currentText = '';

            }).catch((error) => {
                console.log('Error: ', error);
                this.showErrorToast();
            });

        }else{

            this.showErrorToast();

        }



    }


    updateRecordView() {
        setTimeout(() => {
                eval("$A.get('e.force:refreshView').fire();");
            }, 1000); 
    }

    
    getOpportunityProducts() {

            getOpportunityProducts({opportunityId: this.opportunityId}).then(result =>{

                this.options = result.map(item => {
                    return {
                        label: `${item.Product2.Name} (${item.Product2.ProductCode})`,
                        value: item.Product2.Id
                    };
                });
    
                console.log('Options => '+this.options);
    
            }).catch(error => {
                console.log('Error => '+error);
            });
        }

        handleOpportunityChange(event){
            this.opportunityId = event.target.value;
            this.getOpportunityProducts();

        }

        connectedCallback() {
            this.getOpportunityProducts();


        }

    handleChange(event) {
        this.selectedProducts = [...event.detail.value];
        console.log('selectedProducts => '+this.selectedProducts);
    }

    renderedCallback(){

        console.log('Name Opp from renderedCallBack: '+this.name);

        if(this.prevOpportunityId !== this.opportunityId){

            this.prevOpportunityId = this.opportunityId;

            if(this.selectedIds.length >= 0 && this.selectedRecords.length >= 0 && this.currentText !== undefined ){

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