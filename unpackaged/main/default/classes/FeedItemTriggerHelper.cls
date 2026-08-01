/**
 * @description       : Class helper of Feed Item Object
 * @author            : dhurtado@neox.cl
 * @group             :
 * @last modified on  : 01-29-2025
 * @last modified by  : dhurtado@neox.cl
**/
public with sharing class FeedItemTriggerHelper {

    public class WrapperEmailNotifications{
        public List<String> address;
        public String subject;
        public String body;
    }

    public static String subjectEmailNotificationOpp = Label.Subject_Email_Notification_Opp;
    public static String permissionProfileSendEmailNotification = Label.Permission_Profile_Send_Email_Notification;
    public static String userWithoutPermissionToSendNotificationEmail = Label.Users_without_Permission_To_Send_Notification_Email;

    /**
    * @description Method that sends mass notification emails to everyone who has been mentioned
    * @author dhurtado@neox.cl | 01-09-2025
    * @param feedItems
    **/
    public static void sendEmailNotification(List<FeedItem> feedItems){
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Map<Id, FeedItem> mapFeedItemWithOpp = new Map<Id, FeedItem>();
        Map<Id, FeedItem> mapTaskByFeedItem = new Map<Id, FeedItem>();
        Map<Id, Task> mapTasks = new Map<Id,Task>();
        List<Id> oppIds = new List<Id>();
        List<Id> taskIds = new List<Id>();
        for(feedItem fi: feedItems){
            if(fi.ParentId.getSObjectType() == Opportunity.SObjectType){
                oppIds.add(fi.ParentId);
                mapFeedItemWithOpp.put(fi.Id, fi);
            }
            if(fi.ParentId.getSObjectType() == Task.SObjectType){
                taskIds.add(fi.ParentId);
                mapTaskByFeedItem.put(fi.ParentId, fi);
            }
        }
        if(!taskIds.isEmpty()){
            mapTasks = new Map<Id,Task>([SELECT Id, WhatId FROM Task WHERE Id IN: taskIds]);
            for(Task t: mapTasks.values()){
                if(t.WhatId.getSobjectType() == Opportunity.SObjectType){
                    oppIds.add(t.WhatId);
                    FeedItem fi = mapTaskByFeedItem.get(t.Id);
                    mapFeedItemWithOpp.put(fi.Id, fi);
                }
            }
        }
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>([SELECT Id, Name, Owner.Email,Owner.ProfileId FROM Opportunity WHERE Id IN: oppIds]);


        String userEmail = UserInfo.getUserEmail();
        String userProfileId = UserInfo.getProfileId();
        Map<Id, List<String>> mapMentionEmails = getMentionEmails(feedItems);

        for(feedItem fi: mapFeedItemWithOpp.values()){
            Boolean isUserEmail = false;
            Boolean isOppOwnerEmail = false;
            Opportunity op = new Opportunity();

            List<String> mentionEmails = mapMentionEmails.get(fi.Id);

            if(fi.ParentId.getSObjectType() == Opportunity.SObjectType){
                op = opps.get(fi.ParentId);
            }else if(fi.ParentId.getSObjectType() == Task.SObjectType){
                op = opps.get(mapTasks.get(fi.ParentId).WhatId);
            }
            System.debug('Mention: ' + mentionEmails);

            if(!mentionEmails.isEmpty() || validProfOrEmailForSendNotifEmail(userProfileId, userEmail) || validProfOrEmailForSendNotifEmail(op.Owner.ProfileId, op.Owner.Email)){

                WrapperEmailNotifications wen = new WrapperEmailNotifications();
                wen.subject = subjectEmailNotificationOpp + ' ' + op.Name;
                wen.body = fi.body.replaceAll('\\u200b', '');
                wen.address = new List<String>();

                for(String mentionEmail: mentionEmails){
                    wen.address.add(mentionEmail);
                    if(userEmail == mentionEmail) {isUserEmail = true;}
                    if(op.Owner.Email == mentionEmail) {isOppOwnerEmail = true;}
                }
                if(!isUserEmail){ if(validProfOrEmailForSendNotifEmail(userProfileId, userEmail)){wen.address.add(userEmail);}}
                if(!isOppOwnerEmail){ if(validProfOrEmailForSendNotifEmail(op.Owner.ProfileId, op.Owner.Email)){wen.address.add(op.Owner.Email);}}

                emailsToSend.add(createEmailNotification(wen));
            }
        }
        if (!emailsToSend.isEmpty()) {
            System.debug('Emails to send');
            Messaging.sendEmail(emailsToSend);
        }
    }

    /**
    * @description Method that creates notifications one by one and returns them
    * @author dhurtado@neox.cl | 01-09-2025
    * @param wen
    * @return Messaging.SingleEmailMessage
    **/
    public static Messaging.SingleEmailMessage createEmailNotification(WrapperEmailNotifications wen){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(wen.address);
        mail.setSubject(wen.subject);
        mail.setHtmlBody(wen.body);
        return mail;
    }

    /**
    * @description Gets the emails of users who have been mentioned in a post
    * @author dhurtado@neox.cl | 01-09-2025
    * @param feedItems
    * @return Map<Id, List<String>>
    **/
    public static Map<Id, List<String>> getMentionEmails(List<FeedItem> feedItems){
        List<String> allMentionNames = new List<String>();
        Map<String, String> mapEmailsList = new Map<String, String>();
        Map<Id, List<String>> mapMentionNames = new Map<Id, List<String>>();
        Map<Id, List<String>> mapMentionEmailsById = new Map<Id, List<String>>();
        List<String> mentionEmails = new List<String>();
        for(FeedItem fi: feedItems){
            System.debug('FeedItem: ' + fi.Body);
            List<String> mentionNames = getMentionNames(fi.Body);
            System.debug('Mention Emails: ' + mentionNames);
            if(!mentionNames.isEmpty()){
                for(String mentionName: mentionNames){
                    allMentionNames.add(mentionName);
                }
            }
            mapMentionNames.put(fi.Id, mentionNames);
        }

        List<User> users = [
            SELECT Id, Name, Email, ProfileId
            FROM User
            WHERE name IN : allMentionNames
        ];

        for(User u: users){
            if(validProfOrEmailForSendNotifEmail(u.ProfileId, u.Email)){
                mapEmailsList.put(u.Name, u.Email);
            }
        }

        for(FeedItem fi: feedItems){
            mentionEmails = new List<String>();
            List<String> mentionNames = mapMentionNames.get(fi.Id);
            for(String mentionName: mentionNames){
                if(mapEmailsList.containsKey(mentionName)){
                    mentionEmails.add(mapEmailsList.get(mentionName));
                }
            }
            mapMentionEmailsById.put(fi.Id, mentionEmails);
        }
        return mapMentionEmailsById;
    }

    /**
    * @description Method that Gets the names of users who have been mentioned in a post or string
    * @author dhurtado@neox.cl | 01-09-2025
    * @param body
    * @return List<String>
    **/
    public static List<String > getMentionNames(String body){
        Pattern mentionPattern = Pattern.compile('@([\\w\\s]+)');
        List<String> mentionNames = new List<String>();
        System.debug('Body: ' + body);
        Matcher m = mentionPattern.matcher(body);
        while (m.find()) mentionNames.add(m.group(1).trim());
        System.debug(mentionNames);
        return mentionNames;
    }

    /**
    * @description Method that validates that it is among the label profiles and that it is not among the label emails
    * @author dhurtado@neox.cl | 01-29-2025
    * @param profile
    * @param email
    * @return boolean
    **/
    public static boolean validProfOrEmailForSendNotifEmail(String profile, String email){
        if(permissionProfileSendEmailNotification.contains(profile) && !userWithoutPermissionToSendNotificationEmail.contains(email)){
            return true;
        }
        return false;
    }
}