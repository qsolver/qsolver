trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    
    if (Trigger.isAfter) {
        
        if(Trigger.isInsert){
            
            if(String.valueOf(Trigger.New[0].LinkedEntityId).startsWith('00T')){
                
                // Prepare the Flow variables
        		Map<String, Object> params = new Map<String, Object>();
                Task relatedTask = [SELECT Id FROM Task WHERE Id = :Trigger.New[0].LinkedEntityId LIMIT 1];
        		params.put('TaskId', relatedTask.Id);
        
        		// Instantiate and start the Flow
        		Flow.Interview.NewTaskNoteCreation NewTaskNoteCreation_Flow = new Flow.Interview.NewTaskNoteCreation(params);
        		NewTaskNoteCreation_Flow.start();
                
                
                
            }
            
        }
        
    }

}