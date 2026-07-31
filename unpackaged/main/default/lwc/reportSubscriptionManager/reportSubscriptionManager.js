import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import searchReports from '@salesforce/apex/ReportSubscriptionController.searchReports';

import getSubscriptions from '@salesforce/apex/ReportSubscriptionController.getSubscriptions';
import saveSubscription from '@salesforce/apex/ReportSubscriptionController.saveSubscription';
import deleteSubscription from '@salesforce/apex/ReportSubscriptionController.deleteSubscription';
import addSubscriber from '@salesforce/apex/ReportSubscriptionController.addSubscriber';
import removeSubscriber from '@salesforce/apex/ReportSubscriptionController.removeSubscriber';
import toggleSubscriptionActive from '@salesforce/apex/ReportSubscriptionController.toggleSubscriptionActive';

const FREQUENCY_OPTIONS = [
    { label: 'Daily', value: 'Daily' },
    { label: 'Weekly', value: 'Weekly' },
    { label: 'Monthly', value: 'Monthly' }
];

const DAY_OF_WEEK_OPTIONS = [
    { label: 'Monday', value: 'Monday' },
    { label: 'Tuesday', value: 'Tuesday' },
    { label: 'Wednesday', value: 'Wednesday' },
    { label: 'Thursday', value: 'Thursday' },
    { label: 'Friday', value: 'Friday' },
    { label: 'Saturday', value: 'Saturday' },
    { label: 'Sunday', value: 'Sunday' }
];

const FORMAT_OPTIONS = [
    { label: 'CSV', value: 'CSV' },
    { label: 'XLSX', value: 'XLSX' }
];

// Counter for temporary IDs assigned to deferred subscribers
let tempIdCounter = 0;

export default class ReportSubscriptionManager extends LightningElement {
    @track subscriptions = [];
    @track formData = {};
    @track formSubscribers = [];
    @track isLoading = true;
    @track showForm = false;
    @track showAddModal = false;
    @track activeSubscriptionId = null;
    @track addModalMode = 'deferred'; // 'deferred' in form, 'direct' from cards

    @track reportOptions = [];
    @track isSearching = false;
    wiredSubscriptionsResult;
    @track reportSearchTerm = '';
    @track showReportDropdown = false;
    _searchDebounce;

    frequencyOptions = FREQUENCY_OPTIONS;
    dayOfWeekOptions = DAY_OF_WEEK_OPTIONS;
    formatOptions = FORMAT_OPTIONS;

    // ─── Generate time options in UTC (every 1 hour) ───────────────────
    // Times are stored and matched in UTC. Users must select the UTC hour
    // that corresponds to their desired local delivery time.
    get timeOptions() {
        const options = [];
        for (let i = 0; i < 24; i++) {
            const hour = String(i).padStart(2, '0');
            const displayHour = i === 0 ? 12 : i > 12 ? i - 12 : i;
            const ampm = i < 12 ? 'AM' : 'PM';
            options.push({ label: `${displayHour}:00 ${ampm} (UTC)`, value: `${hour}:00` });
        }
        return options;
    }

    // ─── Show user's local UTC offset as a hint ─────────────────────────
    // e.g. "Your local time is UTC-6. Select 22:00 UTC to receive at 4:00 PM local."
    get utcOffsetLabel() {
        const offsetMinutes = new Date().getTimezoneOffset(); // e.g. 360 for UTC-6
        const sign = offsetMinutes <= 0 ? '+' : '-';
        const absHours = Math.floor(Math.abs(offsetMinutes) / 60);
        return `Your browser timezone is UTC${sign}${absHours}. All times above are in UTC — add ${sign === '+' ? absHours : absHours} hour(s) to convert from your local time.`;
    }

    // ─── Computed Properties ────────────────────────────────────────────
    get isWeekly() {
        return this.formData.frequency === 'Weekly';
    }

    get isMonthly() {
        return this.formData.frequency === 'Monthly';
    }

    get hasSubscriptions() {
        return this.subscriptions && this.subscriptions.length > 0;
    }

    get formTitle() {
        return this.formData.id ? 'Edit Subscription' : 'New Subscription';
    }

    get formIcon() {
        return this.formData.id ? 'utility:edit' : 'utility:add';
    }

    // ─── Report Search: results come directly from Apex ──────────────────
    get filteredReportOptions() {
        return this.reportOptions;
    }

    get hasFilteredReports() {
        return this.reportOptions.length > 0;
    }

    get reportDropdownClass() {
        return 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click' +
            (this.showReportDropdown ? ' slds-is-open' : '');
    }

    // ─── Wire: Load Reports (removed — now uses server-side search) ──────

    // ─── Wire: Load Subscriptions ───────────────────────────────────────
    @wire(getSubscriptions)
    wiredSubscriptions(result) {
        this.wiredSubscriptionsResult = result;
        const { data, error } = result;
        if (data) {
            this.subscriptions = data.map(sub => ({
                ...sub,
                isExpanded: false,
                subscriberCount: sub.Report_Subscribers__r ? sub.Report_Subscribers__r.length : 0,
                scheduleDisplay: this.buildScheduleDisplay(sub),
                toggleLabel: sub.Is_Active__c ? 'Deactivate' : 'Activate',
                toggleIcon: sub.Is_Active__c ? 'utility:pause' : 'utility:play'
            }));
            this.isLoading = false;
        } else if (error) {
            this.showToast('Error', 'Failed to load subscriptions: ' + this.reduceErrors(error), 'error');
            this.isLoading = false;
        }
    }

    // ─── Build Schedule Display String ──────────────────────────────────
    buildScheduleDisplay(sub) {
        let display = sub.Frequency__c;
        if (sub.Frequency__c === 'Weekly' && sub.Day_of_Week__c) {
            display += ` on ${sub.Day_of_Week__c}`;
        } else if (sub.Frequency__c === 'Monthly' && sub.Day_of_Month__c) {
            display += ` on day ${sub.Day_of_Month__c}`;
        }
        if (sub.Preferred_Time__c) {
            const parts = sub.Preferred_Time__c.split(':');
            const hour = parseInt(parts[0], 10);
            const minutes = parts[1] || '00';
            const ampm = hour < 12 ? 'AM' : 'PM';
            const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
            display += ` at ${displayHour}:${minutes} ${ampm}`;
        }
        return display;
    }

    // ─── Form Handlers ──────────────────────────────────────────────────
    handleNewSubscription() {
        this.formData = {
            reportId: '',
            reportName: '',
            frequency: 'Daily',
            dayOfWeek: 'Monday',
            dayOfMonth: 1,
            preferredTime: '08:00',
            attachmentFormat: 'CSV',
            isActive: true
        };
        this.formSubscribers = [];
        this.reportSearchTerm = '';
        this.showForm = true;
    }

    handleEditSubscription(event) {
        const subId = event.target.dataset.id;
        const sub = this.subscriptions.find(s => s.Id === subId);
        if (!sub) return;

        this.formData = {
            id: sub.Id,
            reportId: sub.Report_Id__c,
            reportName: sub.Report_Name__c,
            frequency: sub.Frequency__c,
            dayOfWeek: sub.Day_of_Week__c || 'Monday',
            dayOfMonth: sub.Day_of_Month__c || 1,
            preferredTime: sub.Preferred_Time__c,
            attachmentFormat: sub.Attachment_Format__c,
            isActive: sub.Is_Active__c
        };
        // Pre-populate search field with existing report name
        this.reportSearchTerm = sub.Report_Name__c || '';
        // Load existing subscribers into the form
        this.formSubscribers = sub.Report_Subscribers__r
            ? sub.Report_Subscribers__r.map(s => ({ ...s, _isExisting: true }))
            : [];
        this.showForm = true;
    }

    handleFormChange(event) {
        const field = event.target.name;
        let value = event.target.value;

        if (field === 'dayOfMonth') {
            value = parseInt(value, 10);
        }

        this.formData = { ...this.formData, [field]: value };

        // Auto-fill report name when report is selected
        if (field === 'reportId') {
            const selectedReport = this.reportOptions.find(r => r.value === value);
            if (selectedReport) {
                this.formData = { ...this.formData, reportName: selectedReport.label.split(' (')[0] };
            }
        }
    }

    handleCancelForm() {
        this.showForm = false;
        this.formData = {};
        this.formSubscribers = [];
        this.reportSearchTerm = '';
        this.showReportDropdown = false;
    }

    // ─── Report Search Handlers ──────────────────────────────────────────
    handleReportSearch(event) {
        this.reportSearchTerm = event.target.value;
        this.showReportDropdown = true;
        if (!this.reportSearchTerm) {
            this.formData = { ...this.formData, reportId: null, reportName: null };
        }
        // Debounce: wait 300 ms after the last keystroke before calling Apex
        clearTimeout(this._searchDebounce);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._searchDebounce = setTimeout(() => {
            this._runSearch(this.reportSearchTerm);
        }, 300);
    }

    handleReportSearchFocus() {
        this.showReportDropdown = true;
        // Load initial results when the field is first focused and nothing is loaded yet
        if (this.reportOptions.length === 0) {
            this._runSearch('');
        }
    }

    handleReportSearchBlur() {
        // Delay so onmousedown on option fires before the dropdown closes
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.showReportDropdown = false;
        }, 200);
    }

    async _runSearch(term) {
        this.isSearching = true;
        try {
            const results = await searchReports({ searchTerm: term });
            this.reportOptions = results.map(r => ({
                label: `${r.name} (${r.folderName})`,
                value: r.id
            }));
        } catch (error) {
            this.showToast('Error', 'Failed to search reports: ' + this.reduceErrors(error), 'error');
        } finally {
            this.isSearching = false;
        }
    }

    handleReportSelect(event) {
        const { value, label } = event.currentTarget.dataset;
        // Strip folder name from display label for Report_Name__c storage
        const reportName = label.split(' (')[0];
        this.formData = { ...this.formData, reportId: value, reportName };
        this.reportSearchTerm = label;
        this.showReportDropdown = false;
    }

    async handleSaveSubscription() {
        // Validate
        if (!this.formData.reportId) {
            this.showToast('Error', 'Please select a report.', 'error');
            return;
        }
        if (!this.formData.preferredTime) {
            this.showToast('Error', 'Please select a preferred time.', 'error');
            return;
        }
        if (this.formData.frequency === 'Weekly' && !this.formData.dayOfWeek) {
            this.showToast('Error', 'Please select a day of the week.', 'error');
            return;
        }
        if (this.formData.frequency === 'Monthly' && (!this.formData.dayOfMonth || this.formData.dayOfMonth < 1 || this.formData.dayOfMonth > 28)) {
            this.showToast('Error', 'Please enter a valid day of month (1-28).', 'error');
            return;
        }
        if (!this.formSubscribers || this.formSubscribers.length === 0) {
            this.showToast('Error', 'Please add at least one subscriber or recipient before saving.', 'error');
            return;
        }

        this.isLoading = true;
        try {
            // 1. Save the subscription
            const savedSub = await saveSubscription({ subscriptionJSON: JSON.stringify(this.formData) });
            const subscriptionId = savedSub.Id;

            // 2. Persist new (deferred) subscribers
            const newSubscribers = this.formSubscribers.filter(s => !s._isExisting);
            for (const sub of newSubscribers) {
                const subscriberData = {
                    subscriptionId: subscriptionId,
                    subscriberType: sub.Subscriber_Type__c,
                    userId: sub.User__c || null,
                    email: sub.Email__c,
                    displayName: sub.Display_Name__c
                };
                await addSubscriber({ subscriberJSON: JSON.stringify(subscriberData) });
            }

            // 3. Remove existing subscribers that were deleted from the form
            if (this.formData.id && this._removedSubscriberIds && this._removedSubscriberIds.length > 0) {
                for (const subId of this._removedSubscriberIds) {
                    await removeSubscriber({ subscriberId: subId });
                }
            }

            this.showToast('Success', 'Subscription saved successfully.', 'success');
            this.showForm = false;
            this.formData = {};
            this.formSubscribers = [];
            this._removedSubscriberIds = [];
            await refreshApex(this.wiredSubscriptionsResult);
        } catch (error) {
            this.showToast('Error', 'Failed to save subscription: ' + this.reduceErrors(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ─── Subscription Card Actions ──────────────────────────────────────
    async handleToggleActive(event) {
        const subId = event.target.dataset.id;
        const currentActive = event.target.dataset.active === 'true';
        const newActive = !currentActive;

        this.isLoading = true;
        try {
            await toggleSubscriptionActive({ subscriptionId: subId, isActive: newActive });
            this.showToast('Success', `Subscription ${newActive ? 'activated' : 'deactivated'}.`, 'success');
            await refreshApex(this.wiredSubscriptionsResult);
        } catch (error) {
            this.showToast('Error', this.reduceErrors(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleDeleteSubscription(event) {
        const subId = event.target.dataset.id;

        this.isLoading = true;
        try {
            await deleteSubscription({ subscriptionId: subId });
            this.showToast('Success', 'Subscription deleted.', 'success');
            await refreshApex(this.wiredSubscriptionsResult);
        } catch (error) {
            this.showToast('Error', this.reduceErrors(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ─── Subscriber Events (Form - Deferred Mode) ───────────────────────
    handleOpenAddModal() {
        this.addModalMode = 'deferred';
        this.activeSubscriptionId = this.formData.id || null;
        this.showAddModal = true;
    }

    handleSubscriberData(event) {
        // Deferred mode: add subscriber locally to the form
        const data = event.detail;
        tempIdCounter++;
        const newSub = {
            Id: 'temp-' + tempIdCounter,
            Subscriber_Type__c: data.subscriberType,
            User__c: data.userId || null,
            User__r: data.userName ? { Name: data.userName, Email: data.userEmail } : null,
            Email__c: data.email,
            Display_Name__c: data.displayName,
            _isExisting: false
        };
        this.formSubscribers = [...this.formSubscribers, newSub];
        this.showAddModal = false;
        this.activeSubscriptionId = null;
    }

    handleRemoveFormSubscriber(event) {
        const subId = event.detail.subscriberId;
        const removedSub = this.formSubscribers.find(s => s.Id === subId);

        // If removing a persisted subscriber, track it for deletion on save
        if (removedSub && removedSub._isExisting) {
            if (!this._removedSubscriberIds) {
                this._removedSubscriberIds = [];
            }
            this._removedSubscriberIds.push(subId);
        }

        this.formSubscribers = this.formSubscribers.filter(s => s.Id !== subId);
    }

    // ─── Subscriber Events (Card - Direct Mode) ────────────────────────
    handleOpenAddModalFromCard(event) {
        this.addModalMode = 'direct';
        this.activeSubscriptionId = event.detail.subscriptionId;
        this.showAddModal = true;
    }

    handleCloseAddModal() {
        this.showAddModal = false;
        this.activeSubscriptionId = null;
    }

    async handleSubscriberAdded() {
        // Direct mode: subscriber was already saved by the modal
        this.showAddModal = false;
        this.activeSubscriptionId = null;
        await refreshApex(this.wiredSubscriptionsResult);
    }

    async handleRemoveSubscriber(event) {
        const subscriberId = event.detail.subscriberId;
        this.isLoading = true;
        try {
            await removeSubscriber({ subscriberId });
            this.showToast('Success', 'Subscriber removed.', 'success');
            await refreshApex(this.wiredSubscriptionsResult);
        } catch (error) {
            this.showToast('Error', this.reduceErrors(error), 'error');
        } finally {
            this.isLoading = false;
        }
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