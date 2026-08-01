@IsTest
private class ReportSubscriptionControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create a subscription
        Report_Subscription__c sub = new Report_Subscription__c(
            Report_Id__c = '00O000000000001AAA',
            Report_Name__c = 'Test Report',
            Frequency__c = 'Daily',
            Preferred_Time__c = '08:00',
            Attachment_Format__c = 'CSV',
            Is_Active__c = true
        );
        insert sub;

        // Create an internal subscriber
        Report_Subscriber__c internalSub = new Report_Subscriber__c(
            Report_Subscription__c = sub.Id,
            Subscriber_Type__c = 'Internal',
            User__c = UserInfo.getUserId(),
            Display_Name__c = UserInfo.getName(),
            Email__c = UserInfo.getUserEmail()
        );
        insert internalSub;

        // Create an external subscriber
        Report_Subscriber__c externalSub = new Report_Subscriber__c(
            Report_Subscription__c = sub.Id,
            Subscriber_Type__c = 'External',
            Email__c = 'external@example.com',
            Display_Name__c = 'External User'
        );
        insert externalSub;
    }

    @IsTest
    static void testGetReports() {
        Test.startTest();
        List<Map<String, String>> reports = ReportSubscriptionController.getReports();
        Test.stopTest();
        // Reports may or may not exist in the test context, just verify no exception
        System.assertNotEquals(null, reports, 'Reports list should not be null');
    }

    @IsTest
    static void testGetSubscriptions() {
        Test.startTest();
        List<Report_Subscription__c> subs = ReportSubscriptionController.getSubscriptions();
        Test.stopTest();
        System.assertEquals(1, subs.size(), 'Should have 1 subscription');
        System.assertEquals(2, subs[0].Report_Subscribers__r.size(), 'Should have 2 subscribers');
    }

    @IsTest
    static void testGetSubscription() {
        Report_Subscription__c existingSub = [SELECT Id FROM Report_Subscription__c LIMIT 1];
        Test.startTest();
        Report_Subscription__c result = ReportSubscriptionController.getSubscription(existingSub.Id);
        Test.stopTest();
        System.assertEquals('Test Report', result.Report_Name__c);
    }

    @IsTest
    static void testGetSubscriptionNotFound() {
        Test.startTest();
        try {
            // Use a fake Id
            ReportSubscriptionController.getSubscription(
                Report_Subscription__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001'
            );
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName(), 'Expected AuraHandledException for not found');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetSubscriptionByReportId() {
        Test.startTest();
        Report_Subscription__c result = ReportSubscriptionController.getSubscriptionByReportId('00O000000000001AAA');
        Test.stopTest();
        System.assertNotEquals(null, result, 'Should find subscription by report ID');
    }

    @IsTest
    static void testGetSubscriptionByReportIdNotFound() {
        Test.startTest();
        Report_Subscription__c result = ReportSubscriptionController.getSubscriptionByReportId('00O000000000999AAA');
        Test.stopTest();
        System.assertEquals(null, result, 'Should return null for non-existent report ID');
    }

    @IsTest
    static void testSaveSubscriptionNew() {
        Map<String, Object> data = new Map<String, Object>{
            'reportId' => '00O000000000002AAA',
            'reportName' => 'New Test Report',
            'frequency' => 'Weekly',
            'dayOfWeek' => 'Monday',
            'preferredTime' => '09:00',
            'attachmentFormat' => 'XLSX',
            'isActive' => true
        };

        Test.startTest();
        Report_Subscription__c result = ReportSubscriptionController.saveSubscription(JSON.serialize(data));
        Test.stopTest();

        System.assertNotEquals(null, result.Id, 'Should create a new subscription');
        System.assertEquals('New Test Report', result.Report_Name__c);
        System.assertEquals('Weekly', result.Frequency__c);
    }

    @IsTest
    static void testSaveSubscriptionUpdate() {
        Report_Subscription__c existingSub = [SELECT Id FROM Report_Subscription__c LIMIT 1];

        Map<String, Object> data = new Map<String, Object>{
            'id' => existingSub.Id,
            'reportId' => '00O000000000001AAA',
            'reportName' => 'Updated Report Name',
            'frequency' => 'Monthly',
            'dayOfMonth' => 15,
            'preferredTime' => '10:00',
            'attachmentFormat' => 'CSV',
            'isActive' => true
        };

        Test.startTest();
        Report_Subscription__c result = ReportSubscriptionController.saveSubscription(JSON.serialize(data));
        Test.stopTest();

        System.assertEquals('Updated Report Name', result.Report_Name__c);
        System.assertEquals('Monthly', result.Frequency__c);
    }

    @IsTest
    static void testDeleteSubscription() {
        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];
        Test.startTest();
        ReportSubscriptionController.deleteSubscription(sub.Id);
        Test.stopTest();
        List<Report_Subscription__c> remaining = [SELECT Id FROM Report_Subscription__c];
        System.assertEquals(0, remaining.size(), 'Subscription should be deleted');
    }

    @IsTest
    static void testAddInternalSubscriber() {
        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];

        // First remove the existing internal subscriber to avoid duplicate
        delete [SELECT Id FROM Report_Subscriber__c WHERE Report_Subscription__c = :sub.Id AND Subscriber_Type__c = 'Internal'];

        Map<String, Object> data = new Map<String, Object>{
            'subscriptionId' => sub.Id,
            'subscriberType' => 'Internal',
            'userId' => UserInfo.getUserId()
        };

        Test.startTest();
        Report_Subscriber__c result = ReportSubscriptionController.addSubscriber(JSON.serialize(data));
        Test.stopTest();

        System.assertNotEquals(null, result.Id);
        System.assertEquals('Internal', result.Subscriber_Type__c);
    }

    @IsTest
    static void testAddExternalSubscriber() {
        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];

        Map<String, Object> data = new Map<String, Object>{
            'subscriptionId' => sub.Id,
            'subscriberType' => 'External',
            'email' => 'newexternal@example.com',
            'displayName' => 'New External'
        };

        Test.startTest();
        Report_Subscriber__c result = ReportSubscriptionController.addSubscriber(JSON.serialize(data));
        Test.stopTest();

        System.assertNotEquals(null, result.Id);
        System.assertEquals('External', result.Subscriber_Type__c);
        System.assertEquals('newexternal@example.com', result.Email__c);
    }

    @IsTest
    static void testAddDuplicateSubscriber() {
        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];

        // Try to add the same external subscriber again
        Map<String, Object> data = new Map<String, Object>{
            'subscriptionId' => sub.Id,
            'subscriberType' => 'External',
            'email' => 'external@example.com',
            'displayName' => 'External User'
        };

        Test.startTest();
        try {
            ReportSubscriptionController.addSubscriber(JSON.serialize(data));
            System.assert(false, 'Should have thrown duplicate error');
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName(), 'Expected AuraHandledException for duplicate');
        }
        Test.stopTest();
    }

    @IsTest
    static void testRemoveSubscriber() {
        Report_Subscriber__c subscriber = [
            SELECT Id FROM Report_Subscriber__c
            WHERE Subscriber_Type__c = 'External'
            LIMIT 1
        ];

        Test.startTest();
        ReportSubscriptionController.removeSubscriber(subscriber.Id);
        Test.stopTest();

        List<Report_Subscriber__c> remaining = [
            SELECT Id FROM Report_Subscriber__c
            WHERE Subscriber_Type__c = 'External'
        ];
        System.assertEquals(0, remaining.size(), 'External subscriber should be removed');
    }

    @IsTest
    static void testSearchUsers() {
        Test.startTest();
        List<Map<String, String>> results = ReportSubscriptionController.searchUsers(UserInfo.getName().substring(0, 3));
        Test.stopTest();
        // Should find at least the running user
        System.assert(!results.isEmpty(), 'Should find at least one user');
    }

    @IsTest
    static void testSearchUsersShortTerm() {
        Test.startTest();
        List<Map<String, String>> results = ReportSubscriptionController.searchUsers('a');
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Should return empty for search term < 2 chars');
    }

    @IsTest
    static void testToggleSubscriptionActive() {
        Report_Subscription__c sub = [SELECT Id, Is_Active__c FROM Report_Subscription__c LIMIT 1];
        System.assertEquals(true, sub.Is_Active__c);

        Test.startTest();
        ReportSubscriptionController.toggleSubscriptionActive(sub.Id, false);
        Test.stopTest();

        sub = [SELECT Is_Active__c FROM Report_Subscription__c WHERE Id = :sub.Id];
        System.assertEquals(false, sub.Is_Active__c, 'Should be deactivated');
    }
}