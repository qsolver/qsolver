/**
 * @description       : Class handler of Feed Item Object
 * @author            : dhurtado@neox.cl
 * @group             :
 * @last modified on  : 01-16-2025
 * @last modified by  : dhurtado@neox.cl
**/
public with sharing class FeedItemTriggerHandler {
    public static void handlerAfterInsert(List<FeedItem> feedItemNews) {
        List<FeedItem> feedItemsMentions = new List<FeedItem>();
        for(FeedItem feedItemNew: feedItemNews){
            if(feedItemNew.body.contains('@') && (feedItemNew.ParentId.getSObjectType() == Opportunity.SObjectType || feedItemNew.ParentId.getSObjectType() == Task.SObjectType)){
                feedItemsMentions.add(feedItemNew);
            }
        }
        if(!feedItemsMentions.isEmpty()){
            FeedItemTriggerHelper.sendEmailNotification(feedItemsMentions);
        }
    }
}