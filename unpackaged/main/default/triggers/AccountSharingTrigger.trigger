/**
 * @description       : Manages AccountShare records when sales rep fields change on Account.
 *                      Replaces the AccountEditPermission record-triggered flow.
 *                      Before Update: Updates UserID cache fields.
 *                      After Update: Creates/deletes AccountShare records.
 * @author            : Auto-generated
 * @last modified on  : 2026-03-02
 */
trigger AccountSharingTrigger on Account (before update, after update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        AccountSharingHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountSharingHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}