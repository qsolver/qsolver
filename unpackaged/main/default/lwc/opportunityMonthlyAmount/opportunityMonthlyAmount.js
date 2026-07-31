import { LightningElement, track, wire } from 'lwc';
import getOpportunities from '@salesforce/apex/OpportunityMonthlyAmountController.getOpportunities';
import getGMUsers from '@salesforce/apex/OpportunityMonthlyAmountController.getGMUsers';
import USER_ID from '@salesforce/user/Id';
import { refreshApex } from '@salesforce/apex';

export default class OpportunityMonthlyAmount extends LightningElement {

    @track currentUserId = USER_ID;
    @track opportunities = [];
    @track users = [];
    @track salesTeam = 'Todas';
    @track selectedYear = 'Todas';
    @track accountSearchQuery = ''; // Track the Account Name search query
    @track newOppRecords = [];
    @track opportunityRecords = [];
    @track userOptions = [];
    @track yearOptions = []; // To store the year options for the combobox
    @track filteredOpportunityRecords = [];
    wiredOpportunitiesResult;
    isRefresh = false;
    @track salesTeamOptions = [{ label: 'Todas', value: 'Todas' },{ label: 'SurAmerica', value: 'SouthAmerica' },{ label: 'NorteAmerica', value: 'NorthAmerica' }];
    

    renderedCallback() {
        if(this.isLoaded) return;
        const STYLE = document.createElement("style");
        STYLE.innerText = `.uiModal--medium .modal-container{
            width: 90% !important;
            max-width: 90%;
            min-width: 480px;
            max-height: 100%;
            min-height: 480px;   
            padding: 2%;
        }`;
        this.template.querySelector('lightning-card').appendChild(STYLE);
        this.isLoaded = true;
    }

    //To generate Year Options based on the opportunity ship date
    generateYearOptions(opportunities) {
        // Extract unique years from the CreatedDate of opportunities
        const years = new Set();
        let hasSinFecha = false;
        opportunities.forEach(opp => {
            const year = new Date(opp.Ship_Date__c).getFullYear();
            if(year === null || year === undefined || isNaN(year)){
                hasSinFecha = true; // Mark that we have a "Sin Fecha" option

            }else{
                years.add(year);
            }
        });

        // Convert the set of years into an array of options
        this.yearOptions = [...years].map(year => {
            return { label: year.toString(), value: year.toString() };
        });

        // Optionally, sort the year options
        this.yearOptions.sort((a, b) => b.value - a.value);

        // Add a placeholder option at the beginning of the array
        this.yearOptions.unshift({ label: 'Todas', value: 'Todas' });

        // Add the "Sin Fecha" option at the end if it exists
        if (hasSinFecha) {
            this.yearOptions.push({ label: 'Sin Fecha', value: 'Sin Fecha' });
        }
    }


    yearHandleChange(event) {
        this.selectedYear = event.detail.value;

        this.applyFilters();

    }

    // Unified Filtering Method
    applyFilters() {

        this.filteredOpportunityRecords = this.newOppRecords;

        // Apply year filter
        if (this.selectedYear != 'Todas') {
            this.filteredOpportunityRecords = this.filteredOpportunityRecords.filter(opp => {
                console.log('YEAR TO STRING > '+opp.year.toString());
                return opp.year.toString() == this.selectedYear;
            });
        }

        // Apply SalesTeam filter
        if (this.salesTeam != 'Todas') {
            this.filteredOpportunityRecords = this.filteredOpportunityRecords.filter(opp => {
                return opp.oppSalesTeam == this.salesTeam;;
            });
        }


        // Apply user filter
        if (this.currentUserId != 'Todos') {
            this.filteredOpportunityRecords = this.filteredOpportunityRecords.filter(opp => {
                return opp.oppCreatedBy == this.currentUserId;
            });
        }
            

        // Apply Account Name filter
        if (this.accountSearchQuery) {
            this.filteredOpportunityRecords = this.filteredOpportunityRecords.filter(opp => 
                opp.oppAccountName.toLowerCase().includes(this.accountSearchQuery)
            );
        }


    }
    

    //To get opportunity records
    @wire(getOpportunities)
         wiredOpportunities(result) {
            this.wiredOpportunitiesResult = result;
            if (result.data) {
                this.opportunities = result.data;

                this.formatDataTable(this.opportunities);
                this.generateYearOptions(this.opportunities);
                //this.generateMonthOptions(this.opportunities);
                console.log('Data: ' + JSON.stringify(this.opportunities));

                this.filterByUserContext();
                
                
                
            }else{
                console.log('Data Error: '+result.error)
                console.log('Error Details:', JSON.stringify(result.error));
            }
        }

        //To get User records
        @wire(getGMUsers)
         wiredUsers({ error, data }) {
            if (data) {
                this.users = data;

                // Map the user data to combobox options
                this.userOptions = data.map(user => {
                    return { label: user.Name, value: user.Id };
                });

                // adding a "All Users" option at the beginning
                this.userOptions.unshift({ label: 'Todos los usuarios', value: 'Todos' });

                // Set the selected user to the current user if they exist in the options          
                const currentUserOption = this.userOptions.find(option => option.value == USER_ID);
                if (currentUserOption) {
                    this.currentUserId = USER_ID;
                }else {
                    this.currentUserId = 'Todos';

                }
                
            }else{
                console.log('Data Error: '+error)
                console.log('Error Details:', JSON.stringify(error));
            }
        }

        handleSalesTeamChange(event)
        {
            this.salesTeam = event.target.value;
            this.applyFilters();

        }

        //To filter results by the actual user
        filterByUserContext(){
            // Filter the opportunities based on the oppCreatedBy
            if(this.currentUserId != 'Todos'){
                const filteredRecords = this.filteredOpportunityRecords.filter(record => {
                    return record.oppCreatedBy == this.currentUserId;
                });

                console.log('filteredRecords.size >> '+filteredRecords.length);
                console.log('filteredRecords >> '+JSON.stringify(filteredRecords));

                
                this.filteredOpportunityRecords = filteredRecords;
                
            }
        }

        // Method to refresh opportunity data
        refreshData() {
            this.isRefresh = true;
            console.log('Refreshed Data #1>> '+JSON.stringify(this.opportunities));
            refreshApex(this.wiredOpportunitiesResult).then(() => {
                // Reapply formatting and filtering logic after data is refreshed
                console.log('Refreshed Data >> '+JSON.stringify(this.opportunities));

                //Reset Filters
                this.salesTeam = 'Todas';
                this.selectedYear = 'Todas';
                this.currentUserId = 'Todos';
                this.accountSearchQuery = '';
                this.formatDataTable(this.opportunities);
                this.filterByUserContext();
                this.isRefresh = false;

            }).catch(error => {
                console.error('Error refreshing data: ', error);
            });
        }


    
    //To format data shown in the table
    formatDataTable(opportunities) {
        if(this.isRefresh){
            this.newOppRecords = [];
        }
        this.opportunityRecords = opportunities.map(opp => {
            // Convert CreatedDate from string to Date object
            let stringShipDate = opp.Ship_Date__c+"T00:00:00"
            let shipDate = new Date(stringShipDate);

            let firstMonth = shipDate.getMonth();
            let lastMonth = (shipDate.getMonth() + Number(opp.Cantidad_de_entregas_de_venta__c));
            let oppAmountDivision = opp.Amount / Number(opp.Cantidad_de_entregas_de_venta__c);
            let oppTotalTonsDivision = Number(opp.ELM_Total_Tons__c) / Number(opp.Cantidad_de_entregas_de_venta__c);


            const formattedTotalAmount = this.formatAmount(opp.Amount, opp.CurrencyIsoCode);

            const newOppRecord = {
                opportunityId: opp.Id,
                oppCreatedBy : opp.CreatedById,
                oppSalesTeam : opp.ELM_Equipo_de_Ventas__c, 
                opportunityName: opp.Name,
                oppAccountName: opp.Account.Name,
                oppStage: opp.StageName,
                oppType: opp.ELM_GM_Opp_Type__c,
                oppTotalAmount: formattedTotalAmount,
                oppTons: opp.ELM_Total_Tons__c,
                oppCurrencyISOCode: opp.CurrencyIsoCode,
                oppURL: `/lightning/r/Opportunity/${opp.Id}/view`,
                year: shipDate.getFullYear() === null || shipDate.getFullYear() === undefined || isNaN(shipDate.getFullYear()) ? 'Sin Fecha' : shipDate.getFullYear().toString(),
                months: Array.from({ length: 12 }, (_, index) => ({
                    id: `month_${opp.Id}_${index}`, // Unique id for each month based on opportunityId and month index
                    amount: 0,
                    tons: 0,
                    currencyISOCode: ''
                })) // Initialize all months with 0
            };

            for (let i = firstMonth; i < lastMonth && i < 12; i++) {
                const formattedAmount = this.formatAmount(oppAmountDivision, opp.CurrencyIsoCode);
                newOppRecord.months[i].amount = formattedAmount;
                newOppRecord.months[i].tons = oppTotalTonsDivision;
                newOppRecord.months[i].currencyISOCode = opp.CurrencyIsoCode;
            }

            this.newOppRecords.push(newOppRecord);

        });


        this.filteredOpportunityRecords = this.newOppRecords;

    }

    handleUserChange(event) {
        this.currentUserId = event.detail.value;

        this.applyFilters();
    }

    // Method to handle Account Name search change
    handleAccountSearchChange(event) {
        this.accountSearchQuery = event.detail.value.toLowerCase(); // Convert to lowercase for case-insensitive search
        this.applyFilters();
    }

    // Method to format amount based on the currency code
    formatAmount(amount, currencyIsoCode) {
        console.log('Amount Type > '+typeof amount);
        // Handle null or undefined amounts by setting them to 0.00
        if (amount === null || amount === undefined || isNaN(amount)) {
            amount = 0.00;
        }
        if (currencyIsoCode === 'USD') {
            return new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD',
                minimumFractionDigits: 2
            }).format(amount);
        } else if (currencyIsoCode === 'CLP') {
            return new Intl.NumberFormat('es-CL', {
                style: 'currency',
                currency: 'CLP',
                minimumFractionDigits: 2
            }).format(amount);
        } else {
            return amount; // Fallback: no formatting
    }
}


}