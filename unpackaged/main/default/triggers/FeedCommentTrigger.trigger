trigger FeedCommentTrigger on FeedComment (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        
        List<ChatterMentionExtractor.FlowInput> flowInputs = new List<ChatterMentionExtractor.FlowInput>();
        
        for (FeedComment fc : Trigger.new) {
            if (String.isNotBlank(fc.CommentBody)) {
                ChatterMentionExtractor.FlowInput input = new ChatterMentionExtractor.FlowInput();
                input.commentId = fc.Id;
                flowInputs.add(input);
            }
        }

        if (!flowInputs.isEmpty()) {
            List<ChatterMentionExtractor.FlowOutput> outputs = ChatterMentionExtractor.extractMentions(flowInputs);

            for (ChatterMentionExtractor.FlowOutput output : outputs) {
                if (output.mentionedUserIds != null && !output.mentionedUserIds.isEmpty()) {
                    
                    Map<String, Object> flowParams = new Map<String, Object>();
                    flowParams.put('mentionedUserIds', output.mentionedUserIds);
                    flowParams.put('commentText', output.commentText);

                    // ✅ API Name correcto de tu Flow
                    Flow.Interview.Chatter_Menciones myFlow = new Flow.Interview.Chatter_Menciones(flowParams);
                    myFlow.start();
                }
            }
        }
    }
}