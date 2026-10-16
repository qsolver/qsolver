public with sharing class ChatterMentionExtractor {
    
    // Clase para recibir los parámetros desde el Flow
    public class FlowInput {
        @InvocableVariable(required=true)
        public Id commentId;
    }

    // Clase para devolver los resultados al Flow
    public class FlowOutput {
        @InvocableVariable
        public List<String> mentionedUserIds;
        
        @InvocableVariable
        public String commentText;
    }

    @InvocableMethod(label='Extraer Menciones de FeedComment' description='Obtiene los IDs de los usuarios mencionados en un comentario de Chatter.')
    public static List<FlowOutput> extractMentions(List<FlowInput> inputs) {
        List<FlowOutput> results = new List<FlowOutput>();

        // Hacemos una sola consulta para todos los IDs recibidos (Bulkificación)
        Set<Id> commentIds = new Set<Id>();
        for (FlowInput input : inputs) {
            if (input.commentId != null) {
                commentIds.add(input.commentId);
            }
        }

        // Mapa para guardar los comentarios consultados
        Map<Id, FeedComment> commentsMap = new Map<Id, FeedComment>([
            SELECT Id, CommentBody 
            FROM FeedComment 
            WHERE Id IN :commentIds
        ]);

        // Procesamos cada input
        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();
            output.mentionedUserIds = new List<String>();
            output.commentText = '';

            if (input.commentId != null && commentsMap.containsKey(input.commentId)) {
                FeedComment fc = commentsMap.get(input.commentId);
                output.commentText = fc.CommentBody;

                // Extraer los IDs de mención del HTML (data-mention-id="005...")
                if (String.isNotBlank(fc.CommentBody)) {
                    // Expresión regular para encontrar data-mention-id="ID"
                    Pattern mentionPattern = Pattern.compile('data-mention-id="([a-zA-Z0-9]{15,18})"');
                    Matcher matcher = mentionPattern.matcher(fc.CommentBody);
                    
                    while (matcher.find()) {
                        output.mentionedUserIds.add(matcher.group(1));
                    }
                }
            }
            results.add(output);
        }
        return results;
    }
}