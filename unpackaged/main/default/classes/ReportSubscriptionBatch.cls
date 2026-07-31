public class ReportSubscriptionBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private List<Id> subscriptionIds;
    private List<String> errorLog;

    public ReportSubscriptionBatch(List<Id> subscriptionIds) {
        this.subscriptionIds = subscriptionIds;
        this.errorLog = new List<String>();
    }

    // ─── START ──────────────────────────────────────────────────────────
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Report_Id__c, Report_Name__c, Attachment_Format__c, OwnerId,
                   (SELECT Id, Subscriber_Type__c, User__c, User__r.Name,
                           User__r.Email, Email__c, Display_Name__c
                    FROM Report_Subscribers__r)
            FROM Report_Subscription__c
            WHERE Id IN :subscriptionIds
        ]);
    }

    // ─── EXECUTE ────────────────────────────────────────────────────────
    public void execute(Database.BatchableContext bc, List<Report_Subscription__c> scope) {
        for (Report_Subscription__c sub : scope) {
            try {
                // 1. Export the report as CSV using PageReference
                Messaging.EmailFileAttachment attachment = buildAttachment(
                    sub.Report_Name__c,
                    sub.Report_Id__c,
                    sub.Attachment_Format__c
                );

                // 2. Fetch report metadata (filters + summary) via Analytics API
                Map<String, Object> reportInfo = getReportMetadata(sub.Report_Id__c);

                // 3. Collect email addresses
                List<String> toAddresses = new List<String>();
                for (Report_Subscriber__c subscriber : sub.Report_Subscribers__r) {
                    String email = subscriber.Subscriber_Type__c == 'Internal'
                        ? subscriber.User__r.Email
                        : subscriber.Email__c;
                    if (String.isNotBlank(email)) {
                        toAddresses.add(email);
                    }
                }

                if (toAddresses.isEmpty()) {
                    continue;
                }

                // 4. Send email
                sendReportEmail(sub.Report_Name__c, sub.Report_Id__c, toAddresses, attachment, reportInfo);

            } catch (Exception e) {
                errorLog.add('Subscription ' + sub.Id + ': ' + e.getMessage());
            }
        }
    }

    // ─── FINISH ─────────────────────────────────────────────────────────
    public void finish(Database.BatchableContext bc) {
        if (!errorLog.isEmpty()) {
            Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
            errorEmail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
            errorEmail.setSubject('Report Subscription Batch - Errors');
            errorEmail.setPlainTextBody(
                'The following errors occurred during report subscription processing:\n\n' +
                String.join(errorLog, '\n')
            );
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ errorEmail });
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to send error email: ' + e.getMessage());
            }
        }
    }

    // ─── HELPER: Build Email Attachment ──────────────────────────────────
    // Primary path: PageReference CSV export + HTML stripping (fast, all report types).
    // Fallback path: Analytics REST API-based CSV (used when PageReference returns a
    // non-UTF-8 blob, e.g. report data contains Latin-1 encoded special characters).
    private Messaging.EmailFileAttachment buildAttachment(String reportName, String reportId, String format) {
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        String safeName = reportName.replaceAll('[^a-zA-Z0-9_]', '_');

        if (!Test.isRunningTest()) {
            Blob csvBody = null;

            // Primary: PageReference CSV + HTML stripping
            try {
                ApexPages.PageReference reportPage = new ApexPages.PageReference('/' + reportId + '?csv=1&isdtp=p1');
                csvBody = cleanHtmlFromCsv(reportPage.getContent()); // returns null on UTF-8 failure
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'buildAttachment PageReference failed: ' + e.getMessage());
            }

            // Fallback: API-based CSV (always UTF-8, includes HTML stripping on cell labels)
            if (csvBody == null) {
                System.debug(LoggingLevel.INFO, 'buildAttachment: using API-based CSV fallback for ' + reportId);
                csvBody = buildApiBasedCsv(reportId);
            }

            // Last resort: placeholder message
            if (csvBody == null) {
                csvBody = Blob.valueOf('Could not generate CSV. Please open the report directly in Salesforce.');
            }

            attachment.setBody(csvBody);
        } else {
            attachment.setBody(Blob.valueOf('Test CSV Content'));
        }

        attachment.setFileName(safeName + '.' + format.toLowerCase());
        attachment.setContentType(format == 'CSV' ? 'text/csv' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

        return attachment;
    }

    // ─── HELPER: Strip HTML from PageReference CSV blob ──────────────────
    // Returns null (instead of the raw blob) if the content cannot be decoded
    // as UTF-8 so that the caller can fall back to buildApiBasedCsv.
    @TestVisible
    private Blob cleanHtmlFromCsv(Blob rawCsv) {
        try {
            String csvText = rawCsv.toString();

            // Pass 1: CSV-encoded double-quotes  alt=""MM""
            csvText = csvText.replaceAll(
                '(?i)<a [^<>]*><img [^<>]*?alt=""([^"]+)""[^<>]*/?>\\s*</a>',
                '$1'
            );
            // Pass 2: Standard HTML quotes  alt="MM"
            csvText = csvText.replaceAll(
                '(?i)<a [^<>]*><img [^<>]*?alt="([^"]+)"[^<>]*/?>\\s*</a>',
                '$1'
            );
            // Pass 3: Strip any remaining HTML tags
            csvText = csvText.replaceAll('<[^>]+>', '');

            return Blob.valueOf(csvText);

        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                'cleanHtmlFromCsv: UTF-8 decode failed (' + e.getMessage() + '). API fallback will be used.');
            return null; // signal failure to buildAttachment
        }
    }

    // ─── HELPER: Build CSV via Analytics REST API ─────────────────────────
    // Used as a fallback when the PageReference CSV export cannot be decoded
    // as UTF-8 (e.g. report data contains Latin-1 encoded special characters).
    //
    // For Summary Reports the Analytics API separates grouping column values
    // (Account Name, Planta, Asset Name) from the per-row detail columns
    // (ExternalId, month fields).  We re-combine them so the CSV contains
    // ALL columns, matching what the user sees in the Salesforce UI.
    //
    // Adds a UTF-8 BOM so Excel opens the file with correct encoding.
    @TestVisible
    private Blob buildApiBasedCsv(String reportId) {
        try {
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String endpoint = baseUrl + '/services/data/v62.0/analytics/reports/' + reportId + '?includeDetails=true';

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);

            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                System.debug(LoggingLevel.WARN, 'buildApiBasedCsv: API returned ' + res.getStatusCode());
                return null;
            }

            Map<String, Object> reportData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> reportMeta = (Map<String, Object>) reportData.get('reportMetadata');
            Map<String, Object> extMeta    = (Map<String, Object>) reportData.get('reportExtendedMetadata');
            Map<String, Object> factMap    = (Map<String, Object>) reportData.get('factMap');

            if (reportMeta == null || extMeta == null || factMap == null) return null;

            // ── Grouping columns (Account Name, Planta, Asset Name, …) ──────
            // reportMetadata.groupingsDown = ordered list of grouping field defs
            // reportExtendedMetadata.groupingColumnInfo = field → label map
            List<Object>        groupingsDef   = (List<Object>)        reportMeta.get('groupingsDown');
            Map<String, Object> groupingColInfo = (Map<String, Object>) extMeta.get('groupingColumnInfo');

            List<String> groupingFieldOrder = new List<String>(); // field API names, in order
            List<String> groupingHeaders    = new List<String>(); // column header labels

            if (groupingsDef != null && groupingColInfo != null) {
                for (Object gDef : groupingsDef) {
                    Map<String, Object> gd = (Map<String, Object>) gDef;
                    String fieldName = (String) gd.get('name'); // API field name
                    if (fieldName == null) fieldName = (String) gd.get('fieldName');
                    groupingFieldOrder.add(fieldName != null ? fieldName : '');
                    Map<String, Object> ci = fieldName != null
                        ? (Map<String, Object>) groupingColInfo.get(fieldName)
                        : null;
                    String lbl = (ci != null && ci.get('label') != null) ? (String) ci.get('label') : '';
                    groupingHeaders.add('"' + lbl.replace('"', '""') + '"');
                }
            }

            // Build factMap-key → [label at level 0, label at level 1, …] map
            // by traversing reportData.groupingsDown.groupings recursively.
            Map<String, List<String>> keyToGroupLabels = new Map<String, List<String>>();
            Map<String, Object> groupingsDownObj = (Map<String, Object>) reportData.get('groupingsDown');
            if (groupingsDownObj != null) {
                List<Object> topGroupings = (List<Object>) groupingsDownObj.get('groupings');
                buildGroupingLabelMap(topGroupings, new List<String>(), keyToGroupLabels);
            }

            // ── Detail columns (ExternalId, month fields, …) ────────────────
            List<Object>        detailColumns = (List<Object>)        reportMeta.get('detailColumns');
            Map<String, Object> detailColInfo = (Map<String, Object>) extMeta.get('detailColumnInfo');
            if (detailColumns == null) detailColumns = new List<Object>();
            if (detailColInfo == null) detailColInfo = new Map<String, Object>();

            List<String> detailHeaders = new List<String>();
            for (Object col : detailColumns) {
                Map<String, Object> info = (Map<String, Object>) detailColInfo.get((String) col);
                String lbl = (info != null && info.get('label') != null) ? (String) info.get('label') : (String) col;
                detailHeaders.add('"' + (lbl != null ? lbl.replace('"', '""') : '') + '"');
            }

            // ── Assemble header row ──────────────────────────────────────────
            List<String> csvLines = new List<String>();
            List<String> allHeaders = new List<String>();
            allHeaders.addAll(groupingHeaders);
            allHeaders.addAll(detailHeaders);
            csvLines.add(String.join(allHeaders, ','));

            // ── Assemble data rows ───────────────────────────────────────────
            List<String> sortedKeys = new List<String>(factMap.keySet());
            sortedKeys.sort();

            Integer numGroupingCols = groupingFieldOrder.size();

            for (String key : sortedKeys) {
                Map<String, Object> groupEntry = (Map<String, Object>) factMap.get(key);
                if (groupEntry == null) continue;
                List<Object> rows = (List<Object>) groupEntry.get('rows');
                if (rows == null || rows.isEmpty()) continue;

                // Resolve the group labels for this factMap key (strip "!T" or "!D" suffix)
                String keyPrefix = key.contains('!') ? key.substringBefore('!') : key;
                List<String> groupLabels = keyToGroupLabels.containsKey(keyPrefix)
                    ? keyToGroupLabels.get(keyPrefix)
                    : new List<String>();

                for (Object rowObj : rows) {
                    Map<String, Object> row       = (Map<String, Object>) rowObj;
                    List<Object>        dataCells = (List<Object>) row.get('dataCells');
                    if (dataCells == null) continue;

                    List<String> cells = new List<String>();

                    // Grouping columns first
                    for (Integer i = 0; i < numGroupingCols; i++) {
                        String grpLabel = i < groupLabels.size() ? groupLabels.get(i) : '';
                        cells.add('"' + grpLabel.replace('"', '""') + '"');
                    }

                    // Detail columns
                    for (Object cellObj : dataCells) {
                        Map<String, Object> cell = (Map<String, Object>) cellObj;
                        String cellLabel = cell.get('label') != null ? String.valueOf(cell.get('label')) : '';
                        cells.add('"' + stripHtml(cellLabel).replace('"', '""') + '"');
                    }

                    csvLines.add(String.join(cells, ','));
                }
            }

            // UTF-8 BOM so Excel opens the file with correct encoding
            return Blob.valueOf('\uFEFF' + String.join(csvLines, '\r\n'));

        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'buildApiBasedCsv failed: ' + e.getMessage());
            return null;
        }
    }

    // ─── HELPER: Recursively build factMap-key → grouping-labels map ──────
    // Traverses the groupingsDown.groupings tree and maps each node's key
    // (e.g. "0_1_2") to the ordered list of ancestor + own labels so we
    // can look up group labels when composing CSV rows.
    @TestVisible
    private void buildGroupingLabelMap(
        List<Object>              groupings,
        List<String>              parentLabels,
        Map<String, List<String>> keyToLabels
    ) {
        if (groupings == null) return;
        for (Object gObj : groupings) {
            Map<String, Object> g     = (Map<String, Object>) gObj;
            String              key   = (String) g.get('key');
            String              label = (String) g.get('label');

            List<String> currentLabels = new List<String>(parentLabels);
            currentLabels.add(label != null ? label : '');

            if (key != null) {
                keyToLabels.put(key, currentLabels);
            }

            List<Object> subGroupings = (List<Object>) g.get('groupings');
            buildGroupingLabelMap(subGroupings, currentLabels, keyToLabels);
        }
    }

    // ─── HELPER: Extract plain text from an HTML string ───────────────────
    // For HYPERLINK(IMAGE(..., "MM", ...)) formula cells: extracts img alt value.
    // For other HTML: strips all tags and returns plain text.
    @TestVisible
    private String stripHtml(String text) {
        if (String.isBlank(text) || !text.contains('<')) return text;
        Matcher m = Pattern.compile('(?i)alt="([^"]*)"').matcher(text);
        if (m.find()) return m.group(1);
        return text.replaceAll('<[^>]+>', '').trim();
    }


    // ─── HELPER: Get Report Metadata (Filters + Summary) via Analytics API ──
    // Lightweight call WITHOUT includeDetails — returns only metadata and aggregates
    private Map<String, Object> getReportMetadata(String reportId) {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String endpoint = baseUrl + '/services/data/v62.0/analytics/reports/' + reportId;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            return new Map<String, Object>();
        }

        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }


    // ─── HELPER: Build Summary HTML ─────────────────────────────────────
    // Extracts aggregate totals from factMap and renders them as a summary table
    @TestVisible
    private String buildSummaryHtml(Map<String, Object> reportInfo) {
        if (reportInfo == null || reportInfo.isEmpty()) {
            return '';
        }

        try {
            // Get aggregate column info (labels for the summary fields)
            Map<String, Object> reportExtendedMetadata = (Map<String, Object>) reportInfo.get('reportExtendedMetadata');
            if (reportExtendedMetadata == null) return '';

            Map<String, Object> aggregateColumnInfo = (Map<String, Object>) reportExtendedMetadata.get('aggregateColumnInfo');
            if (aggregateColumnInfo == null || aggregateColumnInfo.isEmpty()) return '';

            // Get grand total aggregates from factMap → T!T
            Map<String, Object> factMap = (Map<String, Object>) reportInfo.get('factMap');
            if (factMap == null) return '';

            Map<String, Object> grandTotal = (Map<String, Object>) factMap.get('T!T');
            if (grandTotal == null) return '';

            List<Object> aggregates = (List<Object>) grandTotal.get('aggregates');
            if (aggregates == null || aggregates.isEmpty()) return '';

            // Get the ordered list of aggregate column keys
            Map<String, Object> reportMetadata = (Map<String, Object>) reportInfo.get('reportMetadata');
            List<Object> aggregateKeys = (List<Object>) reportMetadata.get('aggregates');

            String html = '<p style="color: #0176d3; font-size: 16px; font-weight: bold; margin: 16px 0 12px 0;">Summary</p>'
                + '<table style="border-collapse: collapse; font-size: 13px;" cellpadding="0" cellspacing="0">'
                + '<tr>';

            // Build header row
            List<String> headerCells = new List<String>();
            for (Integer i = 0; i < aggregates.size() && i < (aggregateKeys != null ? aggregateKeys.size() : aggregates.size()); i++) {
                String aggKey = aggregateKeys != null ? (String) aggregateKeys[i] : 'agg_' + i;
                Map<String, Object> aggInfo = (Map<String, Object>) aggregateColumnInfo.get(aggKey);
                String label = aggInfo != null ? (String) aggInfo.get('label') : 'Total';
                headerCells.add('<td style="padding: 4px 24px 4px 0; font-weight: bold; color: #333; white-space: nowrap;">' + label.escapeHtml4() + '</td>');
            }
            html += String.join(headerCells, '') + '</tr><tr>';

            // Build value row
            List<String> valueCells = new List<String>();
            for (Object aggObj : aggregates) {
                Map<String, Object> agg = (Map<String, Object>) aggObj;
                String val = agg.get('label') != null ? String.valueOf(agg.get('label')) : '-';
                valueCells.add('<td style="padding: 4px 24px 4px 0; font-size: 16px; color: #333; white-space: nowrap;">' + val.escapeHtml4() + '</td>');
            }
            html += String.join(valueCells, '') + '</tr></table>';

            return html;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to build summary HTML: ' + e.getMessage());
            return '';
        }
    }

    // ─── HELPER: Send Email ─────────────────────────────────────────────
    @TestVisible
    private void sendReportEmail(String reportName, String reportId, List<String> recipients, Messaging.EmailFileAttachment attachment, Map<String, Object> reportInfo) {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String reportUrl = baseUrl + '/lightning/r/Report/' + reportId + '/view';

        String ownerName = UserInfo.getName();
        String nowFormatted = Datetime.now().format('M/d/yyyy \'at\' h:mm a');

        // Build the Summary section only (filters removed)
        String summaryHtml = buildSummaryHtml(reportInfo);

        String detailsSection = '<hr style="border: none; border-top: 1px solid #e5e5e5; margin: 16px 0;" />';

        if (String.isNotBlank(summaryHtml)) {
            detailsSection += summaryHtml;
        } else {
            // Fallback if the report has no aggregate summary data
            detailsSection += '<p style="font-size: 13px; color: #706e6b; margin: 0 0 16px 0;">'
                + 'The report data is attached as a ' + attachment.getFileName().substringAfterLast('.').toUpperCase() + ' file.'
                + '</p>';
        }

        String htmlBody = '<!DOCTYPE html><html><body style="margin:0; padding:0; font-family: Arial, Helvetica, sans-serif; color: #333;">'
            + '<div style="background-color: #0176d3; height: 6px;"></div>'
            + '<div style="max-width: 700px; margin: 0 auto; padding: 24px 32px;">'
            // Report Title
            + '<h1 style="color: #0176d3; font-size: 22px; font-weight: bold; margin: 0 0 8px 0; text-align: center;">'
            + String.valueOf(reportName).escapeHtml4() + '</h1>'
            // Timestamp
            + '<p style="text-align: center; color: #706e6b; font-size: 13px; margin: 0 0 16px 0;">'
            + 'As of ' + nowFormatted
            + ' &middot; Report subscription started by ' + ownerName.escapeHtml4()
            + '</p>'
            // Open in Salesforce Button
            + '<div style="text-align: center; margin: 0 0 24px 0;">'
            + '<a href="' + reportUrl + '" '
            + 'style="display: inline-block; background-color: #0176d3; color: #ffffff; text-decoration: none; '
            + 'padding: 10px 24px; border-radius: 4px; font-size: 13px; font-weight: bold; letter-spacing: 0.5px;">'
            + 'OPEN IN SALESFORCE</a>'
            + '</div>'
            // Details section (Filters + Summary)
            + detailsSection
            // Footer
            + '<hr style="border: none; border-top: 1px solid #e5e5e5; margin: 16px 0;" />'
            + '<p style="text-align: center; color: #999; font-size: 11px; margin: 16px 0 0 0;">'
            + 'Copyright &copy; 2000-' + String.valueOf(Date.today().year()) + ' salesforce.com, Inc. All rights reserved.'
            + '</p>'
            + '</div></body></html>';

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(recipients);
        email.setSubject('Report Subscription: ' + reportName);
        email.setHtmlBody(htmlBody);
        email.setPlainTextBody(
            reportName + '\n'
            + 'As of ' + nowFormatted + '\n'
            + 'Report subscription started by ' + ownerName + '\n\n'
            + 'The report data is attached.\n\n'
            + 'This is an automated report subscription email.'
        );
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
        email.setSaveAsActivity(false);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}