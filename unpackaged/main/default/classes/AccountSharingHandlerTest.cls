/**
 * @description       : Comprehensive tests for AccountSharingHandler.
 *                      Tests cover all sharing scenarios including multi-LOB protection,
 *                      bulk operations, and edge cases.
 * @author            : Auto-generated
 * @last modified on  : 2026-03-02
 */
@isTest
private class AccountSharingHandlerTest {

    // ─── TEST DATA SETUP ───────────────────────────────────────────────

    /**
     * @description Creates test users with different Sales Teams and profiles.
     *              - userA: Sales Team SURAMERICA
     *              - userB: Sales Team SURAMERICA
     *              - userC: Sales Team NORTEAMERICA
     */
    @testSetup
    static void setup() {
        // Get a profile for test users
        Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        List<User> testUsers = new List<User>();

        // User A — SURAMERICA team
        testUsers.add(new User(
            Alias = 'usrA',
            Email = 'usera.sharing.test@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserA_SharingTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = salesProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'usera.sharing.test.' + System.currentTimeMillis() + '@test.com',
            ELM_Equipo_de_Ventas__c = 'SURAMERICA'
        ));

        // User B — SURAMERICA team
        testUsers.add(new User(
            Alias = 'usrB',
            Email = 'userb.sharing.test@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserB_SharingTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = salesProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'userb.sharing.test.' + System.currentTimeMillis() + '@test.com',
            ELM_Equipo_de_Ventas__c = 'SURAMERICA'
        ));

        // User C — NORTEAMERICA team
        testUsers.add(new User(
            Alias = 'usrC',
            Email = 'userc.sharing.test@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserC_SharingTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = salesProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'userc.sharing.test.' + System.currentTimeMillis() + '@test.com',
            ELM_Equipo_de_Ventas__c = 'NORTEAMERICA'
        ));

        insert testUsers;

        // Create test accounts with different Sales Teams
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(
            Name = 'Test Account Suramerica',
            ELM_Equipo_de_Ventas__c = 'SURAMERICA'
        ));
        testAccounts.add(new Account(
            Name = 'Test Account Norteamerica',
            ELM_Equipo_de_Ventas__c = 'NORTEAMERICA'
        ));
        insert testAccounts;
    }

    // ─── HELPER METHODS ────────────────────────────────────────────────

    private static List<User> getTestUsers() {
        return [
            SELECT Id, LastName, ELM_Equipo_de_Ventas__c
            FROM User
            WHERE LastName IN ('UserA_SharingTest', 'UserB_SharingTest', 'UserC_SharingTest')
            ORDER BY LastName
        ];
    }

    private static User getUserA() {
        return [SELECT Id FROM User WHERE LastName = 'UserA_SharingTest' LIMIT 1];
    }

    private static User getUserB() {
        return [SELECT Id FROM User WHERE LastName = 'UserB_SharingTest' LIMIT 1];
    }

    private static User getUserC() {
        return [SELECT Id FROM User WHERE LastName = 'UserC_SharingTest' LIMIT 1];
    }

    private static Account getAccountSuramerica() {
        return [SELECT Id FROM Account WHERE Name = 'Test Account Suramerica' LIMIT 1];
    }

    private static Account getAccountNorteamerica() {
        return [SELECT Id FROM Account WHERE Name = 'Test Account Norteamerica' LIMIT 1];
    }

    private static List<AccountShare> getManualShares(Id accountId, Id userId) {
        return [
            SELECT Id, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel, UserOrGroupId
            FROM AccountShare
            WHERE AccountId = :accountId
              AND UserOrGroupId = :userId
              AND RowCause = 'Manual'
        ];
    }

    private static List<AccountShare> getAllManualShares(Id accountId) {
        return [
            SELECT Id, UserOrGroupId, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel
            FROM AccountShare
            WHERE AccountId = :accountId
              AND RowCause = 'Manual'
        ];
    }

    // ─── TEST 1: Assign Sales Rep to Empty LOB ─────────────────────────
    @isTest
    static void test_assignSalesRepToEmptyLOB_createsShare() {
        User userA = getUserA();
        Account acc = getAccountSuramerica();

        Test.startTest();
        acc.Vendedor_Alerta_Temprana__c = userA.Id;
        update acc;
        Test.stopTest();

        // Verify AccountShare was created
        List<AccountShare> shares = getManualShares(acc.Id, userA.Id);
        System.assertEquals(1, shares.size(), 'Should create 1 manual share for the assigned user');
        System.assertEquals('Edit', shares[0].AccountAccessLevel, 'Account access should be Edit');
        System.assertEquals('Edit', shares[0].OpportunityAccessLevel, 'Opportunity access should be Edit');
        System.assertEquals('Edit', shares[0].CaseAccessLevel, 'Case access should be Edit');

        // Verify cache field was updated
        Account updatedAcc = [SELECT AlertatempranaUserID__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(String.valueOf(userA.Id), updatedAcc.AlertatempranaUserID__c,
            'Cache field should contain the assigned user Id');
    }

    // ─── TEST 2: Change Sales Rep from User A to User B ─────────────────
    @isTest
    static void test_changeSalesRep_deletesOldCreatesNew() {
        User userA = getUserA();
        User userB = getUserB();
        Account acc = getAccountSuramerica();

        // First assign User A
        acc.Vendedor_Chancado__c = userA.Id;
        update acc;

        // Verify User A has a share
        System.assertEquals(1, getManualShares(acc.Id, userA.Id).size(),
            'User A should have a share after initial assignment');

        Test.startTest();
        // Now change to User B
        acc.Vendedor_Chancado__c = userB.Id;
        update acc;
        Test.stopTest();

        // Verify User A's share was deleted
        System.assertEquals(0, getManualShares(acc.Id, userA.Id).size(),
            'User A share should be deleted after being replaced');

        // Verify User B's share was created
        List<AccountShare> newShares = getManualShares(acc.Id, userB.Id);
        System.assertEquals(1, newShares.size(),
            'User B should have a new share');
        System.assertEquals('Edit', newShares[0].OpportunityAccessLevel,
            'New share should have Edit opportunity access');

        // Verify cache field was updated
        Account updatedAcc = [SELECT ChancadoUserID__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(String.valueOf(userB.Id), updatedAcc.ChancadoUserID__c,
            'Cache field should now contain User B Id');
    }

    // ─── TEST 3: Remove Sales Rep (Set to Null) ─────────────────────────
    @isTest
    static void test_removeSalesRep_deletesShare() {
        User userA = getUserA();
        Account acc = getAccountSuramerica();

        // First assign User A
        acc.Vendedor_GET__c = userA.Id;
        update acc;

        // Verify share exists
        System.assertEquals(1, getManualShares(acc.Id, userA.Id).size(),
            'Share should exist after assignment');

        Test.startTest();
        // Remove User A
        acc.Vendedor_GET__c = null;
        update acc;
        Test.stopTest();

        // Verify share was deleted
        System.assertEquals(0, getManualShares(acc.Id, userA.Id).size(),
            'Share should be deleted after user removed from LOB');

        // Verify cache field was cleared
        Account updatedAcc = [SELECT GETUserID__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, updatedAcc.GETUserID__c,
            'Cache field should be null after user removed');
    }

    // ─── TEST 4: Same User on 2 LOBs — Remove from 1 (Share Preserved) ─
    @isTest
    static void test_sameUserMultipleLOBs_removeOne_sharePreserved() {
        User userA = getUserA();
        Account acc = getAccountSuramerica();

        // Assign User A to TWO LOBs
        acc.Vendedor_Alerta_Temprana__c = userA.Id;
        acc.Vendedor_Molienda__c = userA.Id;
        update acc;

        // Verify exactly 1 share exists (same user, deduped by AccountShare unique constraint)
        List<AccountShare> initialShares = getManualShares(acc.Id, userA.Id);
        System.assertEquals(1, initialShares.size(),
            'Should have exactly 1 share even with user on 2 LOBs');

        Test.startTest();
        // Remove User A from Alerta Temprana ONLY (still on Molienda)
        acc.Vendedor_Alerta_Temprana__c = null;
        update acc;
        Test.stopTest();

        // Verify share STILL exists because user is still on Molienda
        List<AccountShare> remainingShares = getManualShares(acc.Id, userA.Id);
        System.assertEquals(1, remainingShares.size(),
            'Share should be PRESERVED because user is still assigned to Molienda');
    }

    // ─── TEST 5: Same User on 2 LOBs — Remove from Both (Share Deleted) ─
    @isTest
    static void test_sameUserMultipleLOBs_removeAll_shareDeleted() {
        User userA = getUserA();
        Account acc = getAccountSuramerica();

        // Assign User A to TWO LOBs
        acc.Vendedor_Alerta_Temprana__c = userA.Id;
        acc.Vendedor_Molienda__c = userA.Id;
        update acc;

        // Verify share exists
        System.assertEquals(1, getManualShares(acc.Id, userA.Id).size(),
            'User A should have a share');

        Test.startTest();
        // Remove User A from BOTH LOBs at once
        acc.Vendedor_Alerta_Temprana__c = null;
        acc.Vendedor_Molienda__c = null;
        update acc;
        Test.stopTest();

        // Verify share was deleted
        System.assertEquals(0, getManualShares(acc.Id, userA.Id).size(),
            'Share should be deleted when user is removed from ALL LOBs');
    }

    // ─── TEST 6: Multiple LOBs Changed Simultaneously ───────────────────
    @isTest
    static void test_multipleLOBsChangedAtOnce_handlesCorrectly() {
        User userA = getUserA();
        User userB = getUserB();
        User userC = getUserC();
        Account acc = getAccountSuramerica();

        Test.startTest();
        // Assign 3 different users to 3 different LOBs at once
        acc.Vendedor_Alerta_Temprana__c = userA.Id;
        acc.Vendedor_Chancado__c = userB.Id;
        acc.Vendedor_Grinding_Media__c = userC.Id;
        update acc;
        Test.stopTest();

        // Verify all 3 users have shares
        System.assertEquals(1, getManualShares(acc.Id, userA.Id).size(),
            'User A should have a share (Alerta Temprana)');
        System.assertEquals(1, getManualShares(acc.Id, userB.Id).size(),
            'User B should have a share (Chancado)');
        System.assertEquals(1, getManualShares(acc.Id, userC.Id).size(),
            'User C should have a share (Grinding Media)');

        // Verify cache fields
        Account updatedAcc = [
            SELECT AlertatempranaUserID__c, ChancadoUserID__c, GrindingMediaUserID__c
            FROM Account WHERE Id = :acc.Id
        ];
        System.assertEquals(String.valueOf(userA.Id), updatedAcc.AlertatempranaUserID__c);
        System.assertEquals(String.valueOf(userB.Id), updatedAcc.ChancadoUserID__c);
        System.assertEquals(String.valueOf(userC.Id), updatedAcc.GrindingMediaUserID__c);
    }

    // ─── TEST 7: Non-LOB Field Changed — No Sharing Operations ──────────
    @isTest
    static void test_nonLOBFieldChanged_noSharingOps() {
        Account acc = getAccountSuramerica();

        // Get initial share count
        Integer initialShareCount = getAllManualShares(acc.Id).size();

        Test.startTest();
        // Update a non-LOB field only
        acc.Name = 'Updated Account Name';
        update acc;
        Test.stopTest();

        // Verify no new shares were created
        Integer afterShareCount = getAllManualShares(acc.Id).size();
        System.assertEquals(initialShareCount, afterShareCount,
            'No shares should be created/deleted when only non-LOB fields change');
    }

    // ─── TEST 8: Bulk Update — Multiple Accounts ────────────────────────
    @isTest
    static void test_bulkUpdate_multipleAccounts() {
        User userA = getUserA();
        User userB = getUserB();
        Account accSA = getAccountSuramerica();
        Account accNA = getAccountNorteamerica();

        Test.startTest();
        // Update both accounts at the same time
        accSA.Vendedor_Alerta_Temprana__c = userA.Id;
        accNA.Vendedor_Alerta_Temprana__c = userB.Id;
        update new List<Account>{ accSA, accNA };
        Test.stopTest();

        // Verify shares for both accounts
        System.assertEquals(1, getManualShares(accSA.Id, userA.Id).size(),
            'User A should have share on Suramerica account');
        System.assertEquals(1, getManualShares(accNA.Id, userB.Id).size(),
            'User B should have share on Norteamerica account');
    }

    // ─── TEST 9: Cache Fields Updated Correctly ─────────────────────────
    @isTest
    static void test_cacheFieldsUpdated_allLOBs() {
        User userA = getUserA();
        Account acc = getAccountSuramerica();

        Test.startTest();
        // Assign user to multiple LOBs
        acc.Vendedor_Alerta_Temprana__c = userA.Id;
        acc.Vendedor_Chancado__c = userA.Id;
        acc.Vendedor_Chutes__c = userA.Id;
        acc.Vendedor_GET__c = userA.Id;
        acc.Vendedor_Grinding_Media__c = userA.Id;
        acc.Vendedor_Maestranza__c = userA.Id;
        acc.Vendedor_Molienda__c = userA.Id;
        acc.Vendedor_Ollas__c = userA.Id;
        acc.Vendedor_Partes_y_Respuestos__c = userA.Id;
        acc.ELM_OtherSalesRep__c = userA.Id;
        acc.High_Value_Manager__c = userA.Id;
        update acc;
        Test.stopTest();

        // Query all cache fields
        Account result = [
            SELECT AlertatempranaUserID__c, ChancadoUserID__c, ChutesUserID__c,
                   GETUserID__c, GrindingMediaUserID__c, MaestranzaUserID__c,
                   MoliendaUserID__c, OllasUserID__c, RepuestosUserID__c,
                   ELM_OtherUserID__c, High_Value_User_ID__c
            FROM Account WHERE Id = :acc.Id
        ];

        String expectedId = String.valueOf(userA.Id);
        System.assertEquals(expectedId, result.AlertatempranaUserID__c, 'AlertatempranaUserID__c should match');
        System.assertEquals(expectedId, result.ChancadoUserID__c, 'ChancadoUserID__c should match');
        System.assertEquals(expectedId, result.ChutesUserID__c, 'ChutesUserID__c should match');
        System.assertEquals(expectedId, result.GETUserID__c, 'GETUserID__c should match');
        System.assertEquals(expectedId, result.GrindingMediaUserID__c, 'GrindingMediaUserID__c should match');
        System.assertEquals(expectedId, result.MaestranzaUserID__c, 'MaestranzaUserID__c should match');
        System.assertEquals(expectedId, result.MoliendaUserID__c, 'MoliendaUserID__c should match');
        System.assertEquals(expectedId, result.OllasUserID__c, 'OllasUserID__c should match');
        System.assertEquals(expectedId, result.RepuestosUserID__c, 'RepuestosUserID__c should match');
        System.assertEquals(expectedId, result.ELM_OtherUserID__c, 'ELM_OtherUserID__c should match');
        System.assertEquals(expectedId, result.High_Value_User_ID__c, 'High_Value_User_ID__c should match');
    }

    // ─── TEST 10: Existing Share — No Duplicate Created ─────────────────
    @isTest
    static void test_existingShare_noDuplicateCreated() {
        User userA = getUserA();
        Account acc = getAccountSuramerica();

        // Assign user to first LOB — creates the share
        acc.Vendedor_Alerta_Temprana__c = userA.Id;
        update acc;

        System.assertEquals(1, getManualShares(acc.Id, userA.Id).size(),
            'Should have 1 share after first assignment');

        Test.startTest();
        // Now assign same user to a SECOND LOB
        // The handler should NOT try to create a duplicate share
        acc.Vendedor_Chancado__c = userA.Id;
        update acc;
        Test.stopTest();

        // Should still be exactly 1 share (not 2)
        System.assertEquals(1, getManualShares(acc.Id, userA.Id).size(),
            'Should still have exactly 1 manual share (no duplicate)');
    }

    // ─── TEST 11: User from Different Sales Team Assigned ───────────────
    @isTest
    static void test_differentSalesTeamUser_shareCreated() {
        User userC = getUserC(); // NORTEAMERICA
        Account accSA = getAccountSuramerica(); // SURAMERICA account

        Test.startTest();
        // Assign NORTEAMERICA user to SURAMERICA account
        accSA.Vendedor_Alerta_Temprana__c = userC.Id;
        update accSA;
        Test.stopTest();

        // The trigger creates the share regardless of Sales Team mismatch
        // (Sales Team validation is handled by OpportunityHelper, not sharing)
        List<AccountShare> shares = getManualShares(accSA.Id, userC.Id);
        System.assertEquals(1, shares.size(),
            'Share should be created even for cross-team users (sharing is not team-restricted)');
    }

    // ─── TEST 12: Swap Users Between LOBs ───────────────────────────────
    @isTest
    static void test_swapUsersBetweenLOBs_handlesCorrectly() {
        User userA = getUserA();
        User userB = getUserB();
        Account acc = getAccountSuramerica();

        // Initial: User A on Alerta Temprana, User B on Chancado
        acc.Vendedor_Alerta_Temprana__c = userA.Id;
        acc.Vendedor_Chancado__c = userB.Id;
        update acc;

        // Verify initial state
        System.assertEquals(1, getManualShares(acc.Id, userA.Id).size(), 'User A should have share');
        System.assertEquals(1, getManualShares(acc.Id, userB.Id).size(), 'User B should have share');

        Test.startTest();
        // SWAP: User A → Chancado, User B → Alerta Temprana
        acc.Vendedor_Alerta_Temprana__c = userB.Id;
        acc.Vendedor_Chancado__c = userA.Id;
        update acc;
        Test.stopTest();

        // Both users should still have shares (just on different LOBs)
        System.assertEquals(1, getManualShares(acc.Id, userA.Id).size(),
            'User A should still have share after swap');
        System.assertEquals(1, getManualShares(acc.Id, userB.Id).size(),
            'User B should still have share after swap');
    }

    // ─── TEST 13: Change Sales Rep via Controller (LWC Simulation) ──────
    @isTest
    static void test_changeSalesRepViaController_sharingUpdated() {
        User userA = getUserA();
        User userB = getUserB();
        Account acc = getAccountSuramerica();

        // Initial assignment
        acc.Vendedor_Alerta_Temprana__c = userA.Id;
        update acc;

        System.assertEquals(1, getManualShares(acc.Id, userA.Id).size(),
            'User A should have share');

        Test.startTest();
        // Simulate what the changeSalesRepLWC does:
        // Call the controller method which updates the Account field
        Boolean result = changeSalesRepLWController.updateAccAndOpps(
            acc.Id,
            userB.Id,
            'Vendedor_Alerta_Temprana__c',
            false, // don't transfer open opps
            false, // don't transfer closed opps
            false, // don't transfer open tasks
            false  // don't transfer closed tasks
        );
        Test.stopTest();

        System.assertEquals(true, result, 'Controller should return true on success');

        // Verify sharing was updated by the trigger
        System.assertEquals(0, getManualShares(acc.Id, userA.Id).size(),
            'User A share should be deleted after LWC change');
        System.assertEquals(1, getManualShares(acc.Id, userB.Id).size(),
            'User B share should be created after LWC change');
    }
}