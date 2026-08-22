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
            SELECT Id, Report_Id__c, Report_Name__c,
                   Report_2_Id__c, Report_2_Name__c,
                   Attachment_Format__c, OwnerId, IncludeEmailBody__c, Email_Language__c,
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
                // 1. Build report attachments (primary + optional second report)
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                attachments.add(buildAttachment(sub.Report_Name__c, sub.Report_Id__c, sub.Attachment_Format__c));
                if (String.isNotBlank(sub.Report_2_Id__c)) {
                    attachments.add(buildAttachment(sub.Report_2_Name__c, sub.Report_2_Id__c, sub.Attachment_Format__c));
                }

                // 2. Collect email addresses
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

                // 3. Send email
                sendReportEmail(
                    sub.Report_Name__c, sub.Report_Id__c,
                    sub.IncludeEmailBody__c, sub.Email_Language__c,
                    toAddresses, attachments
                );

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
    String safeName = reportName;
    if (!Test.isRunningTest()) {
        Blob csvBody = buildApiBasedCsv(reportId);
        // Last resort: placeholder message if the API path also fails
        if (csvBody == null) {
            csvBody = Blob.valueOf(
                'Could not generate CSV. Please open the report directly in Salesforce.');
        }
        attachment.setBody(csvBody);
    } else {
        attachment.setBody(Blob.valueOf('Test CSV Content'));
    }
    // AISLAMOS LA LÓGICA POR FORMATO
    if (format.toUpperCase() == 'CSV') {
        // La ruta original de CSV que ya te funciona perfecto
        attachment.setFileName(safeName + '.csv');
        attachment.setContentType('text/csv');
    } else {
        // LÓGICA EXCLUSIVA PARA ARREGLAR EL FORMATO EXCEL
        // Tomamos el cuerpo de texto plano que generó el reporte o el fallback API
        String plainTextBody = attachment.getBody().toString();

        // Strip UTF-8 BOM if present — otherwise the first cell keeps a leading "
        // because the ^" strip sees the BOM before the quote.
        if (plainTextBody.startsWith('\uFEFF')) {
            plainTextBody = plainTextBody.substring(1);
        }

        // Lo envolvemos en una estructura XML/HTML nativa que Microsoft Excel sí acepta
        String xmlExcel = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">';
        xmlExcel += '<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></head>';
        xmlExcel += '<body><table border="1">';

        // Separamos el texto por saltos de línea para armar las filas.
        // Negative limit (-1) preserves trailing empty cells so the last column
        // stays the last column instead of being displaced.
        List<String> lines = plainTextBody.split('\r\n', -1);
        if (lines.size() == 1) {
            lines = plainTextBody.split('\n', -1);
        }

        for (String line : lines) {
            if (String.isEmpty(line)) continue;  // skip trailing blank line from CSV's final \r\n
            xmlExcel += '<tr>';
            // Separamos por comas considerando que los campos pueden venir entre comillas
            List<String> columns = line.split('",(?=")', -1);
            for (String col : columns) {
                // Fixed: '"$' not '$"' — the end-anchor goes AFTER the literal quote.
                String cleanCol = col.replaceAll('^"', '').replaceAll('"$', '');
                xmlExcel += '<td style="vnd.ms-excel.numberformat:@">' + cleanCol.escapeHtml4() + '</td>';
            }
            xmlExcel += '</tr>';
        }
        xmlExcel += '</table></body></html>';

        // Seteamos el cuerpo transformado, la extensión .xls y su Content-Type oficial
        attachment.setBody(Blob.valueOf(xmlExcel));
        attachment.setFileName(safeName + '.xls');
        attachment.setContentType('application/vnd.ms-excel');
    }
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


    // ─── Email Content Templates ─────────────────────────────────────────
    // Subject/body copy lives here in source (no more Custom Metadata) so it's
    // easy to find and edit. Keyed by "<Email_Language__c>_<includeEmailBody>":
    //   *_true  → subscriber opted in to the specific maintenance-schedule copy
    //   *_false → generic report-subscription copy
    // Supported placeholder tokens (replaced in replacePlaceholders()):
    //   {{FechaEnvio}} / {{DateSent}} / {{SubmissionDate}} — send date, dd/MM/yyyy
    //   {{AnioActual}} / {{CurrentYear}}                   — current year
    //   {{AnioSiguiente}} / {{NextYear}}                   — current year + 1
    //   {{NombreReporte}} / {{ReportName}}                 — report name
    //   {{ReportLink}}                                     — link to the report in Salesforce
    private class EmailTemplate {
        String subject;
        String body;
        EmailTemplate(String subject, String body) {
            this.subject = subject;
            this.body = body;
        }
    }

    private static Map<String, EmailTemplate> emailTemplates() {
        return new Map<String, EmailTemplate>{
            'Spanish_true' => new EmailTemplate(
                'Calendario de mantenciones actualizado al {{FechaEnvio}}',
                '<p>Estimados,</p>'
                + '<p>Junto con saludar, comparto el calendario actualizado de mantenciones administrado en Salesforce, correspondiente al año en curso y al próximo año.</p>'
                + '<p><strong>Fecha de envío:</strong> {{FechaEnvio}}</p>'
                + '<p>Este correo tiene como objetivo mantener visibilidad periódica sobre las mantenciones registradas, facilitando la coordinación comercial, técnica y operacional de los equipos involucrados.</p>'
                + '<p>En los archivos adjuntos podrán revisar la información disponible, incluyendo las mantenciones planificadas para:</p>'
                + '<ul>'
                + '<li><strong>Año actual:</strong> {{AnioActual}}</li>'
                + '<li><strong>Próximo año:</strong> {{AnioSiguiente}}</li>'
                + '</ul>'
                + '<p>La información compartida corresponde a los registros administrados en Salesforce, por lo que cualquier ajuste, actualización o corrección debe ser canalizado a través del proceso definido para mantener la trazabilidad y consistencia de la información.</p>'
                + '<p>Este correo se envía de forma automática, con el objetivo de asegurar que todos los equipos cuenten con una versión actualizada del calendario de mantenciones.</p>'
                + '<p>Saludos,</p>'
                + '<p>Equipo Soporte Salesforce</p>'
            ),
            'English_true' => new EmailTemplate(
                'Maintenance Schedule Updated as of {{DateSent}}',
                '<p>Dear All,</p>'
                + '<p>I hope this message finds you well. I am sharing the updated maintenance schedule managed in Salesforce for the current year and the coming year.</p>'
                + '<p><strong>Date sent:</strong> {{DateSent}}</p>'
                + '<p>The purpose of this email is to provide regular visibility into the scheduled maintenance tasks, facilitating commercial, technical, and operational coordination among the teams involved.</p>'
                + '<p>In the attached files, you can review the available information, including scheduled maintenance for:</p>'
                + '<ul>'
                + '<li><strong>Current year:</strong> {{CurrentYear}}</li>'
                + '<li><strong>Next year:</strong> {{NextYear}}</li>'
                + '</ul>'
                + '<p>The information shared corresponds to the records managed in Salesforce; therefore, any adjustments, updates, or corrections must be submitted through the defined process to maintain the traceability and consistency of the information.</p>'
                + '<p>This email is sent automatically to ensure that all teams have an up-to-date version of the maintenance schedule.</p>'
                + '<p>Best regards,</p>'
                + '<p>Salesforce Support Team</p>'
            ),
            'Spanish_false' => new EmailTemplate(
                'Envío de reporte {{NombreReporte}} - {{FechaEnvio}}',
                '<p>Estimados,</p>'
                + '<p>Junto con saludar, se comparte el siguiente reporte que creemos les puede ser útil.</p>'
                + '<p><strong>Fecha de envío:</strong> {{FechaEnvio}}</p>'
                + '<p>Este correo tiene como objetivo mantener la visibilidad periódica de los datos de este reporte.</p>'
                + '<p>En los archivos adjuntos podrán revisar la información disponible.</p>'
                + '<p>Este correo se envía de forma automática, con el objetivo de asegurar que todos los equipos cuenten con una versión actualizada de este reporte que existe en Salesforce.</p>'
                + '<p>{{ReportLink}}</p>'
                + '<p>Saludos,</p>'
                + '<p>Equipo Soporte Salesforce</p>'
            ),
            'English_false' => new EmailTemplate(
                'Report Subscription {{ReportName}} - {{SubmissionDate}}',
                '<p>Dear All,</p>'
                + '<p>We hope this message finds you well. We are sharing the following report, which we believe may be useful to you.</p>'
                + '<p><strong>Date sent:</strong> {{SubmissionDate}}</p>'
                + '<p>The purpose of this email is to provide regular updates on the data in this report. You can review the available information in the attached files.</p>'
                + '<p>This email is sent automatically to ensure that all teams have an up-to-date version of this report, which is available in Salesforce.</p>'
                + '<p>{{ReportLink}}</p>'
                + '<p>Best regards,</p>'
                + '<p>Salesforce Support Team</p>'
            )
        };
    }

    // ─── HELPER: Replace {{token}} placeholders in template copy ────────
    private static String replacePlaceholders(String text, Map<String, String> tokenValues) {
        String result = text;
        for (String token : tokenValues.keySet()) {
            result = result.replace('{{' + token + '}}', tokenValues.get(token));
        }
        return result;
    }

    // ─── HELPER: Send Email ─────────────────────────────────────────────
    @TestVisible
    private void sendReportEmail(
        String reportName, String reportId,
        Boolean includeEmailBody, String emailLanguage,
        List<String> recipients,
        List<Messaging.EmailFileAttachment> attachments
    ) {
        String baseUrl   = URL.getOrgDomainUrl().toExternalForm();
        String reportUrl = baseUrl + '/lightning/r/Report/' + reportId + '/view';
        String language  = String.isNotBlank(emailLanguage) ? emailLanguage : 'Spanish';
        Boolean isSpanish = language == 'Spanish';

        EmailTemplate template = emailTemplates().get(language + '_' + String.valueOf(includeEmailBody));

        Date today = Date.today();
        String linkText = isSpanish ? 'Ver reporte en Salesforce' : 'View report in Salesforce';

        Map<String, String> tokenValues = new Map<String, String>{
            'FechaEnvio'     => Datetime.now().format('dd/MM/yyyy'),
            'DateSent'       => Datetime.now().format('dd/MM/yyyy'),
            'SubmissionDate' => Datetime.now().format('dd/MM/yyyy'),
            'AnioActual'     => String.valueOf(today.year()),
            'CurrentYear'    => String.valueOf(today.year()),
            'AnioSiguiente'  => String.valueOf(today.year() + 1),
            'NextYear'       => String.valueOf(today.year() + 1),
            'NombreReporte'  => reportName,
            'ReportName'     => reportName,
            'ReportLink'     => '<a href="' + reportUrl + '">' + linkText + '</a>'
        };

        String subject  = replacePlaceholders(template.subject, tokenValues);
        String htmlBody = replacePlaceholders(template.body, tokenValues);

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(recipients);
        email.setSubject(subject);
        email.setHtmlBody(htmlBody);
        email.setFileAttachments(attachments);
        email.setSaveAsActivity(false);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}