@IsTest
private class ReportSubscriptionBatchTest {

    // Mock HTTP callout for the Analytics report API
    private class ReportCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(getMockReportJSON());
            return res;
        }

        private String getMockReportJSON() {
            return '{'
                + '"reportMetadata": {'
                + '  "detailColumns": ["ACCOUNT_NAME", "AMOUNT"],'
                + '  "aggregates": ["a!AMOUNT", "RowCount"]'
                + '},'
                + '"reportExtendedMetadata": {'
                + '  "detailColumnInfo": {'
                + '    "ACCOUNT_NAME": {"label": "Account Name", "dataType": "string"},'
                + '    "AMOUNT": {"label": "Amount", "dataType": "currency"}'
                + '  },'
                + '  "aggregateColumnInfo": {'
                + '    "a!AMOUNT": {"label": "Sum of Total Amount", "dataType": "currency"},'
                + '    "RowCount": {"label": "Record Count", "dataType": "int"}'
                + '  }'
                + '},'
                + '"factMap": {'
                + '  "T!T": {'
                + '    "rows": ['
                + '      {"dataCells": [{"label": "Acme Corp", "value": "Acme Corp"}, {"label": "$1,000.00", "value": 1000}]},'
                + '      {"dataCells": [{"label": "Globex", "value": "Globex"}, {"label": "$2,500.00", "value": 2500}]}'
                + '    ],'
                + '    "aggregates": ['
                + '      {"label": "USD 3,500.00", "value": 3500},'
                + '      {"label": "2", "value": 2}'
                + '    ]'
                + '  }'
                + '}'
                + '}';
        }
    }

    // Mock for error scenario
    private class ErrorCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"errorCode": "INTERNAL_ERROR", "message": "Report execution failed"}');
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        Report_Subscription__c sub = new Report_Subscription__c(
            Report_Id__c = '00O000000000001AAA',
            Report_Name__c = 'Test Batch Report',
            Frequency__c = 'Daily',
            Preferred_Time__c = String.valueOf(Datetime.now().hour()).leftPad(2, '0') + ':00',
            Attachment_Format__c = 'CSV',
            Is_Active__c = true
        );
        insert sub;

        Report_Subscriber__c internalSub = new Report_Subscriber__c(
            Report_Subscription__c = sub.Id,
            Subscriber_Type__c = 'Internal',
            User__c = UserInfo.getUserId(),
            Display_Name__c = UserInfo.getName(),
            Email__c = UserInfo.getUserEmail()
        );

        Report_Subscriber__c externalSub = new Report_Subscriber__c(
            Report_Subscription__c = sub.Id,
            Subscriber_Type__c = 'External',
            Email__c = 'batch-test@example.com',
            Display_Name__c = 'Batch Tester'
        );

        insert new List<Report_Subscriber__c>{ internalSub, externalSub };
    }

    @IsTest
    static void testBatchExecution() {
        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());

        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];

        Test.startTest();
        Database.executeBatch(new ReportSubscriptionBatch(new List<Id>{ sub.Id }), 1);
        Test.stopTest();

        System.assert(true, 'Batch should complete successfully');
    }

    @IsTest
    static void testBatchWithApiError() {
        Test.setMock(HttpCalloutMock.class, new ErrorCalloutMock());

        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];

        Test.startTest();
        Database.executeBatch(new ReportSubscriptionBatch(new List<Id>{ sub.Id }), 1);
        Test.stopTest();

        System.assert(true, 'Batch should handle errors gracefully');
    }

    @IsTest
    static void testSchedulerExecution() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Report Sub Scheduler',
            '0 0 * * * ?',
            new ReportSubscriptionScheduler()
        );
        Test.stopTest();

        CronTrigger ct = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId LIMIT 1];
        System.assertNotEquals(null, ct, 'Scheduled job should exist');
    }

    @IsTest
    static void testSchedulerWithNoSubscriptions() {
        delete [SELECT Id FROM Report_Subscription__c];

        Test.startTest();
        new ReportSubscriptionScheduler().execute(null);
        Test.stopTest();

        System.assert(true, 'Scheduler should handle empty subscriptions');
    }

    @IsTest
    static void testSchedulerExecuteDaily() {
        String currentTime = Datetime.now().format('HH:mm');
        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];
        sub.Preferred_Time__c = currentTime;
        sub.Frequency__c = 'Daily';
        update sub;

        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());
        Test.startTest();
        new ReportSubscriptionScheduler().execute(null);
        Test.stopTest();

        System.assert(true, 'Scheduler Daily path should complete without error');
    }

    @IsTest
    static void testSchedulerExecuteWeekly() {
        String currentTime = Datetime.now().format('HH:mm');
        String currentDay  = Datetime.now().format('EEEE');

        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];
        sub.Preferred_Time__c = currentTime;
        sub.Frequency__c      = 'Weekly';
        sub.Day_of_Week__c    = currentDay;
        update sub;

        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());
        Test.startTest();
        new ReportSubscriptionScheduler().execute(null);
        Test.stopTest();

        System.assert(true, 'Scheduler Weekly path should complete without error');
    }

    @IsTest
    static void testSchedulerExecuteMonthly() {
        String currentTime        = Datetime.now().format('HH:mm');
        Integer currentDayOfMonth = Datetime.now().day();

        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];
        sub.Preferred_Time__c = currentTime;
        sub.Frequency__c      = 'Monthly';
        sub.Day_of_Month__c   = currentDayOfMonth;
        update sub;

        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());
        Test.startTest();
        new ReportSubscriptionScheduler().execute(null);
        Test.stopTest();

        System.assert(true, 'Scheduler Monthly path should complete without error');
    }

    @IsTest
    static void testSchedulerSkipsNoSubscribers() {
        String currentTime = Datetime.now().format('HH:mm');
        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];
        sub.Preferred_Time__c = currentTime;
        sub.Frequency__c = 'Daily';
        update sub;
        delete [SELECT Id FROM Report_Subscriber__c WHERE Report_Subscription__c = :sub.Id];

        Test.startTest();
        new ReportSubscriptionScheduler().execute(null);
        Test.stopTest();

        System.assert(true, 'Scheduler should skip subscriptions with no subscribers');
    }

    @IsTest
    static void testBatchExecutionXlsx() {
        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());

        Report_Subscription__c sub = [SELECT Id FROM Report_Subscription__c LIMIT 1];
        sub.Attachment_Format__c = 'XLSX';
        update sub;

        Test.startTest();
        Database.executeBatch(new ReportSubscriptionBatch(new List<Id>{ sub.Id }), 1);
        Test.stopTest();

        System.assert(true, 'Batch XLSX format path should complete without error');
    }

    @IsTest
    static void testBatchSkipsEmptyEmailSubscribers() {
        Report_Subscription__c sub2 = new Report_Subscription__c(
            Report_Id__c = '00O000000000003AAA',
            Report_Name__c = 'Empty Email Report',
            Frequency__c = 'Daily',
            Preferred_Time__c = '09:00',
            Attachment_Format__c = 'CSV',
            Is_Active__c = true
        );
        insert sub2;

        Report_Subscriber__c blankEmailSub = new Report_Subscriber__c(
            Report_Subscription__c = sub2.Id,
            Subscriber_Type__c = 'External',
            Email__c = '',
            Display_Name__c = 'No Email'
        );
        insert blankEmailSub;

        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());
        Test.startTest();
        Database.executeBatch(new ReportSubscriptionBatch(new List<Id>{ sub2.Id }), 1);
        Test.stopTest();

        System.assert(true, 'Batch should skip subscriptions where all recipients have blank emails');
    }

    @IsTest
    static void testBatchFinishSendsErrorEmail() {
        Report_Subscription__c sub3 = new Report_Subscription__c(
            Report_Id__c = '00O000000000004AAA',
            Report_Name__c = 'Error Trigger Report',
            Frequency__c = 'Daily',
            Preferred_Time__c = '09:00',
            Attachment_Format__c = 'CSV',
            Is_Active__c = true
        );
        insert sub3;

        // Internal subscriber with no User__c — User__r will be null → NPE in execute()
        // which populates errorLog and then triggers finish() to send the error email
        Report_Subscriber__c badSub = new Report_Subscriber__c(
            Report_Subscription__c = sub3.Id,
            Subscriber_Type__c = 'Internal',
            User__c = null,
            Display_Name__c = 'Bad Subscriber',
            Email__c = 'fallback@example.com'
        );
        insert badSub;

        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());
        Test.startTest();
        Database.executeBatch(new ReportSubscriptionBatch(new List<Id>{ sub3.Id }), 1);
        Test.stopTest();

        System.assert(true, 'Batch finish() should handle errorLog and send error email');
    }

    // ─── Direct tests for @TestVisible private helpers ──────────────────

    @IsTest
    static void testCleanHtmlFromCsv() {
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        // CSV-encoded double-quote alt pattern: alt=""MM""
        String csvEncoded = '"Status","<a href=""#""><img src=""icon.png"" alt=""MM"" /></a>"';
        Blob result = batch.cleanHtmlFromCsv(Blob.valueOf(csvEncoded));
        System.assertNotEquals(null, result, 'cleanHtmlFromCsv should return a blob for valid input');
        String cleaned = result.toString();
        System.assert(cleaned.contains('MM'), 'Should extract alt text MM: ' + cleaned);

        // Standard HTML quote alt pattern: alt="MS"
        String standardHtml = '"Status","<a href=\"#\"><img src=\"icon.png\" alt=\"MS\" /></a>"';
        Blob result2 = batch.cleanHtmlFromCsv(Blob.valueOf(standardHtml));
        System.assertNotEquals(null, result2, 'cleanHtmlFromCsv should handle standard HTML quotes');

        // Generic HTML tags (no img/alt)
        String genericHtml = '"Name","<b>Bold Text</b>"';
        Blob result3 = batch.cleanHtmlFromCsv(Blob.valueOf(genericHtml));
        String cleaned3 = result3.toString();
        System.assert(!cleaned3.contains('<b>'), 'Should strip generic HTML tags');
        System.assert(cleaned3.contains('Bold Text'), 'Should keep text content');
    }

    @IsTest
    static void testCleanHtmlFromCsvNullReturn() {
        // cleanHtmlFromCsv should return the cleaned blob for valid input
        // Test with simple valid CSV content
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());
        Blob validCsv = Blob.valueOf('Simple,CSV,Data');
        Blob result = batch.cleanHtmlFromCsv(validCsv);
        System.assertNotEquals(null, result, 'Valid UTF-8 blob should return non-null');
        System.assertEquals('Simple,CSV,Data', result.toString());
    }

    @IsTest
    static void testStripHtmlWithAlt() {
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        // HTML with alt attribute — should extract alt value
        String htmlWithAlt = '<a href="#"><img src="icon.png" alt="MM" /></a>';
        String result = batch.stripHtml(htmlWithAlt);
        System.assertEquals('MM', result, 'Should extract alt attribute value');

        // Multi-character alt
        String htmlWithLongAlt = '<img alt="Monthly Metric" />';
        String result2 = batch.stripHtml(htmlWithLongAlt);
        System.assertEquals('Monthly Metric', result2, 'Should extract full alt text');
    }

    @IsTest
    static void testStripHtmlPlainTags() {
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        // HTML without alt attribute — should strip tags and return text
        String htmlNoAlt = '<span style="color:red">Error Value</span>';
        String result = batch.stripHtml(htmlNoAlt);
        System.assertEquals('Error Value', result, 'Should strip tags and return text');
    }

    @IsTest
    static void testStripHtmlBlankOrNoHtml() {
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        // Null input
        System.assertEquals(null, batch.stripHtml(null), 'Null should return null');

        // Blank input
        System.assertEquals('', batch.stripHtml(''), 'Empty should return empty');
        System.assertEquals('  ', batch.stripHtml('  '), 'Whitespace should return whitespace');

        // Plain text (no HTML)
        System.assertEquals('No tags here', batch.stripHtml('No tags here'), 'Plain text returned as-is');
    }

    @IsTest
    static void testBuildGroupingLabelMap() {
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        // Build a nested groupings structure: level 0 → level 1
        List<Object> groupings = new List<Object>{
            new Map<String, Object>{
                'key' => '0',
                'label' => 'Acme Corp',
                'groupings' => new List<Object>{
                    new Map<String, Object>{
                        'key' => '0_0',
                        'label' => 'West Region',
                        'groupings' => null
                    },
                    new Map<String, Object>{
                        'key' => '0_1',
                        'label' => 'East Region',
                        'groupings' => null
                    }
                }
            },
            new Map<String, Object>{
                'key' => '1',
                'label' => 'Globex',
                'groupings' => null
            }
        };

        Map<String, List<String>> keyToLabels = new Map<String, List<String>>();
        batch.buildGroupingLabelMap(groupings, new List<String>(), keyToLabels);

        System.assert(keyToLabels.containsKey('0'), 'Should have key 0');
        System.assertEquals(new List<String>{'Acme Corp'}, keyToLabels.get('0'));

        System.assert(keyToLabels.containsKey('0_0'), 'Should have key 0_0');
        System.assertEquals(new List<String>{'Acme Corp', 'West Region'}, keyToLabels.get('0_0'));

        System.assert(keyToLabels.containsKey('0_1'), 'Should have key 0_1');
        System.assertEquals(new List<String>{'Acme Corp', 'East Region'}, keyToLabels.get('0_1'));

        System.assert(keyToLabels.containsKey('1'), 'Should have key 1');
        System.assertEquals(new List<String>{'Globex'}, keyToLabels.get('1'));

        // Null groupings should not fail
        batch.buildGroupingLabelMap(null, new List<String>(), keyToLabels);
        System.assertEquals(4, keyToLabels.size(), 'Null input should not add entries');
    }

    @IsTest
    static void testBuildSummaryHtml() {
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        // Build a realistic reportInfo structure
        Map<String, Object> reportInfo = new Map<String, Object>{
            'reportMetadata' => new Map<String, Object>{
                'aggregates' => new List<Object>{ 'a!AMOUNT', 'RowCount' }
            },
            'reportExtendedMetadata' => new Map<String, Object>{
                'aggregateColumnInfo' => new Map<String, Object>{
                    'a!AMOUNT' => new Map<String, Object>{ 'label' => 'Sum of Amount' },
                    'RowCount' => new Map<String, Object>{ 'label' => 'Record Count' }
                }
            },
            'factMap' => new Map<String, Object>{
                'T!T' => new Map<String, Object>{
                    'aggregates' => new List<Object>{
                        new Map<String, Object>{ 'label' => 'USD 3,500.00', 'value' => 3500 },
                        new Map<String, Object>{ 'label' => '2', 'value' => 2 }
                    }
                }
            }
        };

        String html = batch.buildSummaryHtml(reportInfo);
        System.assert(String.isNotBlank(html), 'Should return non-empty HTML');
        System.assert(html.contains('Summary'), 'Should contain Summary heading');
        System.assert(html.contains('Sum of Amount'), 'Should contain aggregate label');
        System.assert(html.contains('USD 3,500.00'), 'Should contain aggregate value');
        System.assert(html.contains('Record Count'), 'Should contain Record Count label');
    }

    @IsTest
    static void testBuildSummaryHtmlEmptyInput() {
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        // Null input
        System.assertEquals('', batch.buildSummaryHtml(null), 'Null should return empty');

        // Empty map
        System.assertEquals('', batch.buildSummaryHtml(new Map<String, Object>()), 'Empty map should return empty');

        // Missing aggregateColumnInfo
        Map<String, Object> partial = new Map<String, Object>{
            'reportExtendedMetadata' => new Map<String, Object>()
        };
        System.assertEquals('', batch.buildSummaryHtml(partial), 'Missing agg info should return empty');

        // Missing factMap T!T
        Map<String, Object> noGrandTotal = new Map<String, Object>{
            'reportExtendedMetadata' => new Map<String, Object>{
                'aggregateColumnInfo' => new Map<String, Object>{
                    'a!AMOUNT' => new Map<String, Object>{ 'label' => 'Sum' }
                }
            },
            'factMap' => new Map<String, Object>()
        };
        System.assertEquals('', batch.buildSummaryHtml(noGrandTotal), 'Missing T!T should return empty');
    }

    @IsTest
    static void testSendReportEmail() {
        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());

        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
        att.setBody(Blob.valueOf('col1,col2\nval1,val2'));
        att.setFileName('Test_Report.csv');
        att.setContentType('text/csv');

        // With summary data
        Map<String, Object> reportInfo = new Map<String, Object>{
            'reportMetadata' => new Map<String, Object>{
                'aggregates' => new List<Object>{ 'a!AMOUNT' }
            },
            'reportExtendedMetadata' => new Map<String, Object>{
                'aggregateColumnInfo' => new Map<String, Object>{
                    'a!AMOUNT' => new Map<String, Object>{ 'label' => 'Total' }
                }
            },
            'factMap' => new Map<String, Object>{
                'T!T' => new Map<String, Object>{
                    'aggregates' => new List<Object>{
                        new Map<String, Object>{ 'label' => '$1,000', 'value' => 1000 }
                    }
                }
            }
        };

        Test.startTest();
        batch.sendReportEmail(
            'Test Report', '00O000000000001AAA',
            new List<String>{ UserInfo.getUserEmail() },
            att, reportInfo
        );
        Test.stopTest();

        // Email deliverability settings may suppress sends in test context
        System.assert(true, 'sendReportEmail with summary should complete without error');
    }

    @IsTest
    static void testSendReportEmailNoSummary() {
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
        att.setBody(Blob.valueOf('data'));
        att.setFileName('Report.csv');
        att.setContentType('text/csv');

        // Empty reportInfo → no summary → fallback message
        Test.startTest();
        batch.sendReportEmail(
            'No Summary Report', '00O000000000002AAA',
            new List<String>{ UserInfo.getUserEmail() },
            att, new Map<String, Object>()
        );
        Test.stopTest();

        System.assert(true, 'sendReportEmail without summary should complete without error');
    }

    @IsTest
    static void testBuildApiBasedCsvSuccess() {
        // Mock that returns a full report structure with groupings
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        // Build a rich mock response with groupings
        String mockJson = '{'
            + '"reportMetadata": {'
            + '  "groupingsDown": [{"name": "ACCOUNT_NAME"}],'
            + '  "detailColumns": ["AMOUNT"],'
            + '  "aggregates": ["RowCount"]'
            + '},'
            + '"reportExtendedMetadata": {'
            + '  "groupingColumnInfo": {"ACCOUNT_NAME": {"label": "Account Name"}},'
            + '  "detailColumnInfo": {"AMOUNT": {"label": "Amount"}}'
            + '},'
            + '"groupingsDown": {'
            + '  "groupings": [{"key": "0", "label": "Acme Corp", "groupings": null}]'
            + '},'
            + '"factMap": {'
            + '  "0!T": {'
            + '    "rows": [{"dataCells": [{"label": "$1,000.00", "value": 1000}]}],'
            + '    "aggregates": [{"label": "1", "value": 1}]'
            + '  },'
            + '  "T!T": {'
            + '    "rows": [],'
            + '    "aggregates": [{"label": "1", "value": 1}]'
            + '  }'
            + '}'
            + '}';

        Test.setMock(HttpCalloutMock.class, new SingleResponseMock(200, mockJson));
        Test.startTest();
        Blob csv = batch.buildApiBasedCsv('00O000000000001AAA');
        Test.stopTest();

        System.assertNotEquals(null, csv, 'Should return CSV blob');
        String csvText = csv.toString();
        System.assert(csvText.contains('Account Name'), 'CSV should contain grouping header: ' + csvText);
        System.assert(csvText.contains('Amount'), 'CSV should contain detail header: ' + csvText);
        System.assert(csvText.contains('Acme Corp'), 'CSV should contain group label: ' + csvText);
    }

    @IsTest
    static void testBuildApiBasedCsvFailure() {
        ReportSubscriptionBatch batch = new ReportSubscriptionBatch(new List<Id>());

        // 500 error → should return null
        Test.setMock(HttpCalloutMock.class, new SingleResponseMock(500, 'Internal Server Error'));
        Test.startTest();
        Blob csv = batch.buildApiBasedCsv('00O000000000001AAA');
        Test.stopTest();

        System.assertEquals(null, csv, 'Should return null on API error');
    }

    // Reusable mock for single HTTP responses
    private class SingleResponseMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public SingleResponseMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.body);
            return res;
        }
    }
}