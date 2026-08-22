trigger ContentVersionTrigger on ContentVersion (after insert, before delete) {

    if (Trigger.isAfter) {

        if (Trigger.isInsert) {

            Map<Id, ContentVersion> contentVersionByFirstPublishedIdAcc = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdContact = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdAsset = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdAfterSale = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdOpp = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdContract = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdQuote = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdOrder = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdTask = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdLead = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdVAES = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdAssetRequest = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> contentVersionByFirstPublishedIdMaintenance = new Map<Id, ContentVersion>();

            List<ELM_File_Link__c> fileLinksToInsert = new List<ELM_File_Link__c>();
            List<ELM_File_Link__c> fileLinksAcc;
            List<ELM_File_Link__c> fileLinksContact;
            List<ELM_File_Link__c> fileLinksAsset;
            List<ELM_File_Link__c> fileLinksAfterSale;
            List<ELM_File_Link__c> fileLinksOpp;
            List<ELM_File_Link__c> fileLinksContract;
            List<ELM_File_Link__c> fileLinksQuote;
            List<ELM_File_Link__c> fileLinksOrder;
            List<ELM_File_Link__c> fileLinksTask;
            List<ELM_File_Link__c> fileLinksLead;
            List<ELM_File_Link__c> fileLinksVAES;
            List<ELM_File_Link__c> fileLinksAssetRequest;
            List<ELM_File_Link__c> fileLinksMaintenance;

            for (ContentVersion contentVersion : Trigger.new) {
                
                if(contentVersion.FileType != 'SNOTE'){
                
                	if (contentVersion.FirstPublishLocationId.getSObjectType() == Schema.Account.sObjectType) {

                    	contentVersionByFirstPublishedIdAcc.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.Contact.sObjectType) {

                    	contentVersionByFirstPublishedIdContact.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.Asset.sObjectType) {

                    	contentVersionByFirstPublishedIdAsset.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.After_Sales__c.sObjectType) {
                    
                    	contentVersionByFirstPublishedIdAfterSale.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.Opportunity.sObjectType) {
                    
                    	contentVersionByFirstPublishedIdOpp.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.Contract.sObjectType) {
                    
                    	contentVersionByFirstPublishedIdContract.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.Quote.sObjectType) {
                    
                    	contentVersionByFirstPublishedIdQuote.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.Order.sObjectType) {
                    
                    	contentVersionByFirstPublishedIdOrder.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.Task.sObjectType) {
                    
                    	contentVersionByFirstPublishedIdTask.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.Lead.sObjectType) {
                    
                    	contentVersionByFirstPublishedIdLead.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.ELM_Vaes__c.sObjectType) {
                    
                    	contentVersionByFirstPublishedIdVAES.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if (contentVersion.FirstPublishLocationId.getSobjectType() == Schema.Asset_Request__c.sObjectType) {
                    
                    	contentVersionByFirstPublishedIdAssetRequest.put(contentVersion.FirstPublishLocationId, contentVersion);
                	}else if(contentVersion.FirstPublishLocationId.getSobjectType() == Schema.Maintenance__c.sObjectType){
                    
                    	contentVersionByFirstPublishedIdMaintenance.put(contentVersion.FirstPublishLocationId, contentVersion);
                    }
                }

            }
            
            if (contentVersionByFirstPublishedIdAcc.size() > 0) {

                fileLinksAcc = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdAcc, 'Account');
                fileLinksToInsert.addAll(fileLinksAcc);
            }

            if (contentVersionByFirstPublishedIdContact.size() > 0) {

                fileLinksContact = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdContact, 'Contact');
                fileLinksToInsert.addAll(fileLinksContact);
            }

            if (contentVersionByFirstPublishedIdAsset.size() > 0) {
                
                fileLinksAsset = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdAsset, 'Asset');
                fileLinksToInsert.addAll(fileLinksAsset);
            }

            if (contentVersionByFirstPublishedIdAfterSale.size() > 0) {
                
                fileLinksAfterSale = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdAfterSale, 'After_Sales__c');
                fileLinksToInsert.addAll(fileLinksAfterSale);
            }

            if (contentVersionByFirstPublishedIdOpp.size() > 0) {

                fileLinksOpp = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdOpp, 'Opportunity');
                fileLinksToInsert.addAll(fileLinksOpp);
            }

            if (contentVersionByFirstPublishedIdContract.size() > 0) {

                fileLinksContract = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdContract, 'Contract');
                fileLinksToInsert.addAll(fileLinksContract);
            }

            if (contentVersionByFirstPublishedIdQuote.size() > 0) {

                fileLinksQuote = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdQuote, 'Quote');
                fileLinksToInsert.addAll(fileLinksQuote);
            }

            if (contentVersionByFirstPublishedIdOrder.size() > 0) {

                fileLinksOrder = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdOrder, 'Order');
                fileLinksToInsert.addAll(fileLinksOrder);
            }

            if (contentVersionByFirstPublishedIdTask.size() > 0) {

                fileLinksTask = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdTask, 'Task');
                fileLinksToInsert.addAll(fileLinksTask);
            }

            if (contentVersionByFirstPublishedIdLead.size() > 0) {

                fileLinksLead = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdLead, 'Lead');
                fileLinksToInsert.addAll(fileLinksLead);
            }

            if (contentVersionByFirstPublishedIdVAES.size() > 0) {

                fileLinksVAES = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdVAES, 'ELM_Vaes__c');
                fileLinksToInsert.addAll(fileLinksVAES);
            }

            if (contentVersionByFirstPublishedIdAssetRequest.size() > 0) {

                fileLinksAssetRequest = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdAssetRequest, 'Asset_Request__c');
                fileLinksToInsert.addAll(fileLinksAssetRequest);
            }

            if (contentVersionByFirstPublishedIdMaintenance.size() > 0) {

                fileLinksMaintenance = ContentVersionHelper.createFileLink(contentVersionByFirstPublishedIdMaintenance, 'Maintenance__c');
                fileLinksToInsert.addAll(fileLinksMaintenance);
            }

            insert fileLinksToInsert;
        }
    }
}