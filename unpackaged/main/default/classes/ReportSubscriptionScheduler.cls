public class ReportSubscriptionScheduler implements Schedulable {

    /**
     * Schedule this class to run every 1 hour. It will check which
     * subscriptions are due and launch the batch job to process them.
     *
     * Times are compared in the Salesforce running user's profile timezone.
     * Preferred_Time__c should be set to the desired LOCAL delivery time
     * (e.g. '17:00' means 5:00 PM in the user's Salesforce timezone).
     *
     * IMPORTANT: Always schedule this job using the account of the user
     * whose timezone matches the subscriptions, so format() returns the
     * correct local time.
     *
     * Example to schedule every 1 hour:
     *   String cronExp = '0 0 * * * ?';
     *   System.schedule('Report Subscription Every 1hr', cronExp, new ReportSubscriptionScheduler());
     */
    public void execute(SchedulableContext ctx) {
        // Compare times in the running user's Salesforce profile timezone.
        // Preferred_Time__c stores local time as selected in the LWC (e.g. '17:00').
        Datetime now = Datetime.now();
        String currentTime        = now.format('HH:mm');  // local time per user's SF profile
        String currentDay         = now.format('EEEE');   // e.g. 'Wednesday'
        Integer currentDayOfMonth = now.day();

        // Query active subscriptions that match current schedule
        List<Report_Subscription__c> dueSubscriptions = [
            SELECT Id, Report_Id__c, Report_Name__c, Frequency__c,
                   Day_of_Week__c, Day_of_Month__c, Preferred_Time__c,
                   Attachment_Format__c, OwnerId,
                   (SELECT Id, Subscriber_Type__c, User__c, User__r.Name,
                           User__r.Email, Email__c, Display_Name__c
                    FROM Report_Subscribers__r)
            FROM Report_Subscription__c
            WHERE Is_Active__c = true
              AND Preferred_Time__c = :currentTime
        ];

        // Filter by frequency match
        List<Id> subscriptionIds = new List<Id>();
        for (Report_Subscription__c sub : dueSubscriptions) {
            Boolean isDue = false;

            if (sub.Frequency__c == 'Daily') {
                isDue = true;
            } else if (sub.Frequency__c == 'Weekly' && sub.Day_of_Week__c == currentDay) {
                isDue = true;
            } else if (sub.Frequency__c == 'Monthly' && sub.Day_of_Month__c == currentDayOfMonth) {
                isDue = true;
            }

            if (isDue && !sub.Report_Subscribers__r.isEmpty()) {
                subscriptionIds.add(sub.Id);
            }
        }

        // Launch batch if there are any due subscriptions
        if (!subscriptionIds.isEmpty()) {
            Database.executeBatch(new ReportSubscriptionBatch(subscriptionIds), 1);
        }
    }
}