public class ConvertLeadFlowAction {
    @InvocableMethod(label='Convert Lead' description='Converts a lead into account/contact/opportunity')
    public static void convertLeads(List<ConvertRequest> requests) {
        for (ConvertRequest req : requests) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(req.leadId);
            lc.setDoNotCreateOpportunity(false); // Cambia a true si no deseas crear Opportunity
            lc.setConvertedStatus(req.convertStatus); // Ej: 'Qualified'

            try {
                Database.LeadConvertResult result = Database.convertLead(lc);
                if (!result.isSuccess()) {
                    throw new FlowException('Error converting lead: ' + result.getErrors()[0].getMessage());
                }
            } catch (Exception e) {
                throw new FlowException('Exception: ' + e.getMessage());
            }
        }
    }

    public class ConvertRequest {
        @InvocableVariable(required=true)
        public Id leadId;

        @InvocableVariable
        public String convertStatus; // Ejemplo: 'Qualified'
    }
}