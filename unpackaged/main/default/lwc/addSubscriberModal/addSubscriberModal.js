import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import searchUsers from '@salesforce/apex/ReportSubscriptionController.searchUsers';
import addSubscriber from '@salesforce/apex/ReportSubscriptionController.addSubscriber';

export default class AddSubscriberModal extends LightningElement {
    @api subscriptionId;
    @api mode = 'direct'; // 'direct' = save to Apex immediately, 'deferred' = return data to parent

    @track activeTab = 'internal';
    @track searchTerm = '';
    @track searchResults = [];
    @track isSearching = false;
    @track selectedUserId = null;
    @track selectedUserName = '';
    @track selectedUserEmail = '';
    @track externalName = '';
    @track externalEmail = '';

    searchTimeout;

    // ─── Computed Properties ────────────────────────────────────────────
    get hasSearchResults() {
        return this.searchResults && this.searchResults.length > 0;
    }

    get noResults() {
        return !this.isSearching && this.searchTerm.length >= 2 && this.searchResults.length === 0;
    }

    get isAddDisabled() {
        if (this.activeTab === 'internal') {
            return !this.selectedUserId;
        }
        return !this.externalEmail || !this.externalName;
    }

    // ─── Tab Handling ───────────────────────────────────────────────────
    handleTabChange(event) {
        this.activeTab = event.target.value;
        // Reset state when switching tabs
        this.searchTerm = '';
        this.searchResults = [];
        this.selectedUserId = null;
        this.selectedUserName = '';
        this.selectedUserEmail = '';
        this.externalName = '';
        this.externalEmail = '';
    }

    // ─── Internal User Search ───────────────────────────────────────────
    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.selectedUserId = null;
        this.selectedUserName = '';
        this.selectedUserEmail = '';

        // Debounce the search
        clearTimeout(this.searchTimeout);

        if (this.searchTerm.length < 2) {
            this.searchResults = [];
            return;
        }

        this.searchTimeout = setTimeout(() => {
            this.performSearch();
        }, 300);
    }

    async performSearch() {
        this.isSearching = true;
        try {
            const results = await searchUsers({ searchTerm: this.searchTerm });
            this.searchResults = results.map(user => ({
                ...user,
                itemClass: 'search-result-item slds-p-around_x-small'
            }));
        } catch (error) {
            this.showToast('Error', 'Search failed: ' + this.reduceErrors(error), 'error');
            this.searchResults = [];
        } finally {
            this.isSearching = false;
        }
    }

    handleUserSelect(event) {
        const userId = event.currentTarget.dataset.id;
        this.selectedUserId = userId;

        // Store selected user's info for deferred mode
        const selectedUser = this.searchResults.find(u => u.id === userId);
        if (selectedUser) {
            this.selectedUserName = selectedUser.name;
            this.selectedUserEmail = selectedUser.email;
        }

        // Highlight selected user
        this.searchResults = this.searchResults.map(user => ({
            ...user,
            itemClass: user.id === userId
                ? 'search-result-item slds-p-around_x-small selected'
                : 'search-result-item slds-p-around_x-small'
        }));
    }

    // ─── External Email Inputs ──────────────────────────────────────────
    handleExternalNameChange(event) {
        this.externalName = event.target.value;
    }

    handleExternalEmailChange(event) {
        this.externalEmail = event.target.value;
    }

    // ─── Add Subscriber ─────────────────────────────────────────────────
    async handleAdd() {
        if (this.activeTab === 'internal') {
            if (!this.selectedUserId) {
                this.showToast('Error', 'Please select a user.', 'error');
                return;
            }

            if (this.mode === 'deferred') {
                // Return data to parent without saving
                this.dispatchEvent(new CustomEvent('subscriberdata', {
                    detail: {
                        subscriberType: 'Internal',
                        userId: this.selectedUserId,
                        userName: this.selectedUserName,
                        userEmail: this.selectedUserEmail,
                        email: this.selectedUserEmail,
                        displayName: this.selectedUserName
                    }
                }));
                return;
            }

            // Direct mode: save to Apex
            const subscriberData = {
                subscriptionId: this.subscriptionId,
                subscriberType: 'Internal',
                userId: this.selectedUserId
            };
            try {
                await addSubscriber({ subscriberJSON: JSON.stringify(subscriberData) });
                this.showToast('Success', 'Subscriber added successfully.', 'success');
                this.dispatchEvent(new CustomEvent('subscriberadded'));
            } catch (error) {
                this.showToast('Error', this.reduceErrors(error), 'error');
            }
        } else {
            // Validate email inputs
            const allValid = [...this.template.querySelectorAll('lightning-input')]
                .reduce((valid, input) => {
                    input.reportValidity();
                    return valid && input.checkValidity();
                }, true);

            if (!allValid) return;

            if (this.mode === 'deferred') {
                // Return data to parent without saving
                this.dispatchEvent(new CustomEvent('subscriberdata', {
                    detail: {
                        subscriberType: 'External',
                        email: this.externalEmail,
                        displayName: this.externalName
                    }
                }));
                return;
            }

            // Direct mode: save to Apex
            const subscriberData = {
                subscriptionId: this.subscriptionId,
                subscriberType: 'External',
                email: this.externalEmail,
                displayName: this.externalName
            };
            try {
                await addSubscriber({ subscriberJSON: JSON.stringify(subscriberData) });
                this.showToast('Success', 'Subscriber added successfully.', 'success');
                this.dispatchEvent(new CustomEvent('subscriberadded'));
            } catch (error) {
                this.showToast('Error', this.reduceErrors(error), 'error');
            }
        }
    }

    // ─── Close Modal ────────────────────────────────────────────────────
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    // ─── Utilities ──────────────────────────────────────────────────────
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceErrors(error) {
        if (typeof error === 'string') return error;
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        if (Array.isArray(error?.body)) return error.body.map(e => e.message).join(', ');
        return 'Unknown error';
    }
}