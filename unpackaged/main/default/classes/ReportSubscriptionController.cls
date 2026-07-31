public with sharing class ReportSubscriptionController {

    // ─── Report Lookup (legacy, kept for backward compatibility) ────────
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getReports() {
        List<Map<String, String>> reportList = new List<Map<String, String>>();
        for (Report r : [SELECT Id, Name, DeveloperName, FolderName FROM Report ORDER BY Name ASC LIMIT 200]) {
            reportList.add(new Map<String, String>{
                'id' => r.Id,
                'name' => r.Name,
                'folderName' => r.FolderName
            });
        }
        return reportList;
    }

    // ─── Server-Side Report Search ───────────────────────────────────────
    // Returns up to 10 reports whose name contains the search term.
    // Not cacheable because the result depends on a dynamic parameter.
    @AuraEnabled
    public static List<Map<String, String>> searchReports(String searchTerm) {
        List<Map<String, String>> reportList = new List<Map<String, String>>();
        String likePattern = '%' + String.escapeSingleQuotes(searchTerm != null ? searchTerm : '') + '%';
        for (Report r : [
            SELECT Id, Name, FolderName
            FROM Report
            WHERE Name LIKE :likePattern
            ORDER BY Name ASC
            LIMIT 10
        ]) {
            reportList.add(new Map<String, String>{
                'id' => r.Id,
                'name' => r.Name,
                'folderName' => r.FolderName
            });
        }
        return reportList;
    }

    // ─── Get All Subscriptions for Current User ─────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Report_Subscription__c> getSubscriptions() {
        return [
            SELECT Id, Name, Report_Id__c, Report_Name__c, Frequency__c,
                   Day_of_Week__c, Day_of_Month__c, Preferred_Time__c,
                   Attachment_Format__c, Is_Active__c,
                   (SELECT Id, Subscriber_Type__c, User__c, User__r.Name,
                           User__r.Email, Email__c, Display_Name__c
                    FROM Report_Subscribers__r
                    ORDER BY CreatedDate ASC)
            FROM Report_Subscription__c
            WHERE OwnerId = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
        ];
    }

    // ─── Get Single Subscription by Id ──────────────────────────────────
    @AuraEnabled
    public static Report_Subscription__c getSubscription(Id subscriptionId) {
        List<Report_Subscription__c> subs = [
            SELECT Id, Name, Report_Id__c, Report_Name__c, Frequency__c,
                   Day_of_Week__c, Day_of_Month__c, Preferred_Time__c,
                   Attachment_Format__c, Is_Active__c,
                   (SELECT Id, Subscriber_Type__c, User__c, User__r.Name,
                           User__r.Email, Email__c, Display_Name__c
                    FROM Report_Subscribers__r
                    ORDER BY CreatedDate ASC)
            FROM Report_Subscription__c
            WHERE Id = :subscriptionId
            LIMIT 1
        ];
        if (subs.isEmpty()) {
            throw new AuraHandledException('Subscription not found.');
        }
        return subs[0];
    }

    // ─── Get Subscription by Report Id ──────────────────────────────────
    @AuraEnabled
    public static Report_Subscription__c getSubscriptionByReportId(String reportId) {
        List<Report_Subscription__c> subs = [
            SELECT Id, Name, Report_Id__c, Report_Name__c, Frequency__c,
                   Day_of_Week__c, Day_of_Month__c, Preferred_Time__c,
                   Attachment_Format__c, Is_Active__c,
                   (SELECT Id, Subscriber_Type__c, User__c, User__r.Name,
                           User__r.Email, Email__c, Display_Name__c
                    FROM Report_Subscribers__r
                    ORDER BY CreatedDate ASC)
            FROM Report_Subscription__c
            WHERE Report_Id__c = :reportId
              AND OwnerId = :UserInfo.getUserId()
            LIMIT 1
        ];
        return subs.isEmpty() ? null : subs[0];
    }

    // ─── Save (Upsert) Subscription ─────────────────────────────────────
    @AuraEnabled
    public static Report_Subscription__c saveSubscription(String subscriptionJSON) {
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(subscriptionJSON);

            Report_Subscription__c sub = new Report_Subscription__c();

            // If updating an existing record
            if (data.containsKey('id') && data.get('id') != null) {
                sub.Id = (Id) data.get('id');
            }

            sub.Report_Id__c       = (String) data.get('reportId');
            sub.Report_Name__c     = (String) data.get('reportName');
            sub.Frequency__c       = (String) data.get('frequency');
            sub.Day_of_Week__c     = (String) data.get('dayOfWeek');
            sub.Preferred_Time__c  = (String) data.get('preferredTime');
            sub.Attachment_Format__c = (String) data.get('attachmentFormat');
            sub.Is_Active__c       = data.containsKey('isActive') ? (Boolean) data.get('isActive') : true;

            if (data.containsKey('dayOfMonth') && data.get('dayOfMonth') != null) {
                sub.Day_of_Month__c = ((Decimal) data.get('dayOfMonth')).intValue();
            }

            upsert sub;
            return getSubscription(sub.Id);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ─── Delete Subscription ────────────────────────────────────────────
    @AuraEnabled
    public static void deleteSubscription(Id subscriptionId) {
        try {
            delete [SELECT Id FROM Report_Subscription__c WHERE Id = :subscriptionId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ─── Add Subscriber ─────────────────────────────────────────────────
    @AuraEnabled
    public static Report_Subscriber__c addSubscriber(String subscriberJSON) {
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(subscriberJSON);

            Report_Subscriber__c subscriber = new Report_Subscriber__c();
            subscriber.Report_Subscription__c = (Id) data.get('subscriptionId');
            subscriber.Subscriber_Type__c     = (String) data.get('subscriberType');

            if (subscriber.Subscriber_Type__c == 'Internal') {
                subscriber.User__c = (Id) data.get('userId');
                // Auto-fill display name from User
                User u = [SELECT Name, Email FROM User WHERE Id = :subscriber.User__c LIMIT 1];
                subscriber.Display_Name__c = u.Name;
                subscriber.Email__c        = u.Email;
            } else {
                subscriber.Email__c        = (String) data.get('email');
                subscriber.Display_Name__c = (String) data.get('displayName');
            }

            // Check for duplicate subscriber
            List<Report_Subscriber__c> existing;
            if (subscriber.Subscriber_Type__c == 'Internal') {
                existing = [
                    SELECT Id FROM Report_Subscriber__c
                    WHERE Report_Subscription__c = :subscriber.Report_Subscription__c
                      AND User__c = :subscriber.User__c
                    LIMIT 1
                ];
            } else {
                existing = [
                    SELECT Id FROM Report_Subscriber__c
                    WHERE Report_Subscription__c = :subscriber.Report_Subscription__c
                      AND Email__c = :subscriber.Email__c
                      AND Subscriber_Type__c = 'External'
                    LIMIT 1
                ];
            }
            if (!existing.isEmpty()) {
                throw new AuraHandledException('This subscriber already exists on this subscription.');
            }

            insert subscriber;

            // Re-query to get relationship fields
            return [
                SELECT Id, Subscriber_Type__c, User__c, User__r.Name,
                       User__r.Email, Email__c, Display_Name__c
                FROM Report_Subscriber__c
                WHERE Id = :subscriber.Id
                LIMIT 1
            ];
        } catch (AuraHandledException ae) {
            throw ae;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ─── Remove Subscriber ──────────────────────────────────────────────
    @AuraEnabled
    public static void removeSubscriber(Id subscriberId) {
        try {
            delete [SELECT Id FROM Report_Subscriber__c WHERE Id = :subscriberId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ─── Search Users for Internal Subscriber Add ───────────────────────
    @AuraEnabled
    public static List<Map<String, String>> searchUsers(String searchTerm) {
        List<Map<String, String>> results = new List<Map<String, String>>();

        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return results;
        }

        String searchQuery = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        for (User u : [
            SELECT Id, Name, Email, SmallPhotoUrl, Profile.Name
            FROM User
            WHERE IsActive = true
              AND UserType = 'Standard'
              AND (Name LIKE :searchQuery OR Email LIKE :searchQuery)
            ORDER BY Name ASC
            LIMIT 20
        ]) {
            results.add(new Map<String, String>{
                'id'       => u.Id,
                'name'     => u.Name,
                'email'    => u.Email,
                'photoUrl' => u.SmallPhotoUrl,
                'profile'  => u.Profile.Name
            });
        }
        return results;
    }

    // ─── Toggle Subscription Active Status ──────────────────────────────
    @AuraEnabled
    public static void toggleSubscriptionActive(Id subscriptionId, Boolean isActive) {
        try {
            Report_Subscription__c sub = new Report_Subscription__c(
                Id = subscriptionId,
                Is_Active__c = isActive
            );
            update sub;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}