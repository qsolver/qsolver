import { LightningElement, api } from 'lwc';

export default class SubscriberList extends LightningElement {
    @api subscriptionId;
    @api subscribers = [];

    get hasSubscribers() {
        return this.subscribers && this.subscribers.length > 0;
    }

    get subscriberCount() {
        return this.subscribers ? this.subscribers.length : 0;
    }

    get formattedSubscribers() {
        if (!this.subscribers) return [];
        return this.subscribers.map(sub => ({
            ...sub,
            displayName: sub.Subscriber_Type__c === 'Internal'
                ? (sub.User__r ? sub.User__r.Name : sub.Display_Name__c)
                : sub.Display_Name__c || sub.Email__c,
            displayEmail: sub.Subscriber_Type__c === 'Internal'
                ? (sub.User__r ? sub.User__r.Email : sub.Email__c)
                : sub.Email__c,
            icon: sub.Subscriber_Type__c === 'Internal'
                ? 'standard:user'
                : 'standard:email',
            badgeClass: sub.Subscriber_Type__c === 'Internal'
                ? 'internal-badge'
                : 'external-badge'
        }));
    }

    handleAddClick() {
        this.dispatchEvent(new CustomEvent('addsubscriber', {
            detail: { subscriptionId: this.subscriptionId }
        }));
    }

    handleRemoveClick(event) {
        const subscriberId = event.target.dataset.id;
        this.dispatchEvent(new CustomEvent('removesubscriber', {
            detail: { subscriberId }
        }));
    }
}