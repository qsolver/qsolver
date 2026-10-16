/**
 * @description       : Handles AccountShare record management when sales rep fields change on Account.
 *                      Replaces the AccountEditPermission record-triggered flow with bulkified,
 *                      maintainable Apex logic.
 *
 *                      KEY DESIGN DECISIONS:
 *                      1. LOB_FIELD_MAP — Single configuration map for all Lines of Business.
 *                         Adding a new LOB requires only 1 new entry.
 *                      2. Before Update — Updates UserID cache fields (no DML needed).
 *                      3. After Update — Bulkified AccountShare create/delete (2 DML max).
 *                      4. Duplicate-user protection — Checks if a removed user is still assigned
 *                         to another LOB before deleting their share.
 *                      5. Existing share check — Prevents duplicate AccountShare inserts.
 *
 * @author            : Auto-generated
 * @last modified on  : 2026-03-02
 */
public without sharing class AccountSharingHandler {

    // ─── RECURSION GUARD ───────────────────────────────────────────────
    private static Boolean isExecuting = false;

    // ─── LOB CONFIGURATION ─────────────────────────────────────────────
    // Maps each sales rep lookup field to its corresponding UserID cache text field.
    // To add a new Line of Business, simply add a new entry here.
    @TestVisible
    private static final Map<String, String> LOB_FIELD_MAP = new Map<String, String>{
        'Vendedor_Alerta_Temprana__c' => 'AlertatempranaUserID__c',
        'Vendedor_Chancado__c'       => 'ChancadoUserID__c',
        'Vendedor_Chutes__c'         => 'ChutesUserID__c',
        'Vendedor_GET__c'            => 'GETUserID__c',
        'Vendedor_Grinding_Media__c' => 'GrindingMediaUserID__c',
        'Vendedor_Maestranza__c'     => 'MaestranzaUserID__c',
        'Vendedor_Molienda__c'       => 'MoliendaUserID__c',
        'Vendedor_Ollas__c'          => 'OllasUserID__c',
        'Vendedor_Partes_y_Respuestos__c' => 'RepuestosUserID__c',
        'ELM_OtherSalesRep__c'       => 'ELM_OtherUserID__c',
        'High_Value_Manager__c'      => 'High_Value_User_ID__c'
    };

    // Access levels granted to sales reps on the Account
    private static final String ACCOUNT_ACCESS  = 'Edit';
    private static final String OPP_ACCESS      = 'Edit';
    private static final String CASE_ACCESS     = 'Edit';

    // ─── BEFORE UPDATE ─────────────────────────────────────────────────
    /**
     * @description Updates the UserID cache text fields on the Account record.
     *              Runs in Before Update context so no DML is needed and no re-triggering occurs.
     * @param newAccounts  List of Account records being updated (Trigger.new)
     * @param oldMap       Map of old Account record values (Trigger.oldMap)
     */
    public static void handleBeforeUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        for (Account acc : newAccounts) {
            for (String lobField : LOB_FIELD_MAP.keySet()) {
                String cacheField = LOB_FIELD_MAP.get(lobField);

                // Get the current lookup value (this is the User Id or null)
                Id currentUserId = (Id) acc.get(lobField);

                // Update the cache field with the current user's Id as text
                // This maintains backward compatibility with any automation that reads these fields
                acc.put(cacheField, currentUserId != null ? String.valueOf(currentUserId) : null);
            }
        }
    }

    // ─── AFTER UPDATE ──────────────────────────────────────────────────
    /**
     * @description Manages AccountShare records based on changes to sales rep fields.
     *              - Detects which LOB fields changed
     *              - Deletes shares for removed users (only if not assigned to another LOB)
     *              - Creates shares for newly assigned users (only if share doesn't already exist)
     *              Uses bulkified operations: max 1 DELETE + 1 INSERT for the entire batch.
     * @param newAccounts  List of Account records after update (Trigger.new)
     * @param oldMap       Map of old Account record values (Trigger.oldMap)
     */
    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        // Recursion guard
        if (isExecuting) {
            return;
        }
        isExecuting = true;

        try {
            processShareChanges(newAccounts, oldMap);
        } finally {
            isExecuting = false;
        }
    }

    // ─── CORE LOGIC ────────────────────────────────────────────────────
    /**
     * @description Core method that processes all sharing changes across all accounts in the batch.
     */
    private static void processShareChanges(List<Account> newAccounts, Map<Id, Account> oldMap) {
        // Collect all sharing changes needed
        // Key: AccountId, Value: Set of User Ids to potentially add shares for
        Map<Id, Set<Id>> usersToAddByAccount = new Map<Id, Set<Id>>();
        // Key: AccountId, Value: Set of User Ids to potentially remove shares for
        Map<Id, Set<Id>> usersToRemoveByAccount = new Map<Id, Set<Id>>();
        // Track all new account records by Id for multi-LOB check
        Map<Id, Account> newMap = new Map<Id, Account>(newAccounts);

        // ── Step 1: Identify changes ────────────────────────────────────
        for (Account newAcc : newAccounts) {
            Account oldAcc = oldMap.get(newAcc.Id);

            for (String lobField : LOB_FIELD_MAP.keySet()) {
                Id oldUserId = (Id) oldAcc.get(lobField);
                Id newUserId = (Id) newAcc.get(lobField);

                // Skip if the field hasn't changed
                if (oldUserId == newUserId) {
                    continue;
                }

                // User was removed or changed — mark old user for potential removal
                if (oldUserId != null) {
                    if (!usersToRemoveByAccount.containsKey(newAcc.Id)) {
                        usersToRemoveByAccount.put(newAcc.Id, new Set<Id>());
                    }
                    usersToRemoveByAccount.get(newAcc.Id).add(oldUserId);
                }

                // New user was assigned — mark for potential addition
                if (newUserId != null) {
                    if (!usersToAddByAccount.containsKey(newAcc.Id)) {
                        usersToAddByAccount.put(newAcc.Id, new Set<Id>());
                    }
                    usersToAddByAccount.get(newAcc.Id).add(newUserId);
                }
            }
        }

        // Exit early if nothing changed
        if (usersToRemoveByAccount.isEmpty() && usersToAddByAccount.isEmpty()) {
            return;
        }

        // ── Step 2: Protect users still assigned to other LOBs ─────────
        // Before deleting a share for a removed user, check if they are still
        // assigned to ANY other LOB on the same account.
        for (Id accountId : usersToRemoveByAccount.keySet()) {
            Set<Id> usersToRemove = usersToRemoveByAccount.get(accountId);
            Account currentAcc = newMap.get(accountId);

            // Collect all currently assigned user Ids on this account
            Set<Id> currentlyAssignedUsers = getAllAssignedUsers(currentAcc);

            // Only actually remove shares for users NOT still assigned somewhere
            Set<Id> safeToRemove = new Set<Id>();
            for (Id userId : usersToRemove) {
                if (!currentlyAssignedUsers.contains(userId)) {
                    safeToRemove.add(userId);
                }
            }

            // Replace the set with only the safe-to-remove users
            usersToRemoveByAccount.put(accountId, safeToRemove);
        }

        // Also remove from "add" set any user that is in "remove" set (edge case)
        // And remove from "add" set any user that doesn't need a new share
        // (they might already be in usersToRemove but also reassigned to another LOB)

        // ── Step 3: Query existing shares to avoid duplicates ──────────
        Set<Id> allAccountIds = new Set<Id>();
        Set<Id> allUserIds = new Set<Id>();

        for (Id accId : usersToAddByAccount.keySet()) {
            allAccountIds.add(accId);
            allUserIds.addAll(usersToAddByAccount.get(accId));
        }
        for (Id accId : usersToRemoveByAccount.keySet()) {
            allAccountIds.add(accId);
            allUserIds.addAll(usersToRemoveByAccount.get(accId));
        }

        // Query existing manual shares (RowCause = 'Manual') for the involved users/accounts
        Map<String, AccountShare> existingShares = new Map<String, AccountShare>();
        if (!allAccountIds.isEmpty() && !allUserIds.isEmpty()) {
            for (AccountShare share : [
                SELECT Id, AccountId, UserOrGroupId, RowCause
                FROM AccountShare
                WHERE AccountId IN :allAccountIds
                  AND UserOrGroupId IN :allUserIds
                  AND RowCause = 'Manual'
            ]) {
                String key = share.AccountId + '-' + share.UserOrGroupId;
                existingShares.put(key, share);
            }
        }

        // ── Step 4: Build delete list ──────────────────────────────────
        List<AccountShare> sharesToDelete = new List<AccountShare>();

        for (Id accId : usersToRemoveByAccount.keySet()) {
            for (Id userId : usersToRemoveByAccount.get(accId)) {
                if (userId == null) continue;
                String key = accId + '-' + userId;
                if (existingShares.containsKey(key)) {
                    sharesToDelete.add(existingShares.get(key));
                }
            }
        }

        // ── Step 5: Build create list ──────────────────────────────────
        List<AccountShare> sharesToCreate = new List<AccountShare>();

        for (Id accId : usersToAddByAccount.keySet()) {
            for (Id userId : usersToAddByAccount.get(accId)) {
                if (userId == null) continue;
                String key = accId + '-' + userId;
                // Only create if no manual share already exists
                if (!existingShares.containsKey(key)) {
                    AccountShare newShare = new AccountShare();
                    newShare.AccountId = accId;
                    newShare.UserOrGroupId = userId;
                    newShare.AccountAccessLevel = ACCOUNT_ACCESS;
                    newShare.OpportunityAccessLevel = OPP_ACCESS;
                    newShare.CaseAccessLevel = CASE_ACCESS;
                    newShare.RowCause = Schema.AccountShare.RowCause.Manual;
                    sharesToCreate.add(newShare);
                }
            }
        }

        // ── Step 6: Execute DML (bulkified — max 2 DML operations) ─────
        if (!sharesToDelete.isEmpty()) {
            Database.delete(sharesToDelete, false);
        }

        if (!sharesToCreate.isEmpty()) {
            Database.insert(sharesToCreate, false);
        }
    }

    // ─── HELPER METHODS ────────────────────────────────────────────────

    /**
     * @description Returns the set of all User Ids currently assigned to any LOB field
     *              on the given Account record. Used to prevent deleting shares for users
     *              still assigned to at least one LOB.
     * @param acc  The Account record to inspect
     * @return     Set of User Ids currently assigned to any LOB
     */
    @TestVisible
    private static Set<Id> getAllAssignedUsers(Account acc) {
        Set<Id> assignedUsers = new Set<Id>();
        for (String lobField : LOB_FIELD_MAP.keySet()) {
            Id userId = (Id) acc.get(lobField);
            if (userId != null) {
                assignedUsers.add(userId);
            }
        }
        return assignedUsers;
    }
}