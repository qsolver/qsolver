/**
 * @description       : Class Trigger of FeedItem Object
 * @author            : dhurtado@neox.cl
 * @group             :
 * @last modified on  : 01-09-2025
 * @last modified by  : dhurtado@neox.cl
**/
trigger FeedItemTrigger on FeedItem (after insert) {
	if(Trigger.isAfter && Trigger.isInsert){
        FeedItemTriggerHandler.handlerAfterInsert(trigger.new);
    }
}