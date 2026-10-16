public class QuotePDFController {

    public Quote quoteRecord { get; set; }
    public List<QuoteLineItem> lineItems { get; set; }
    public String fechaEspanol { get; set; }

    public QuotePDFController(ApexPages.StandardController stdController) {

        Id quoteId = stdController.getId();

        this.lineItems = new List<QuoteLineItem>();

        if (quoteId != null) {

            List<Quote> quotes = [
                SELECT Id,
                       QuoteNumber,
                       Name,
                       TotalPrice,
                       CreatedDate,
                       CurrencyIsoCode,
                       Account.Name,
                       Contact.Name,
                       Owner.Name,
                       Owner.Title,
                       Owner.Email,
                       Metodo_de_pago__c,
                       Lugar_de_entrega__c,
                       Notas__c
                FROM Quote
                WHERE Id = :quoteId
                LIMIT 1
            ];

            if (!quotes.isEmpty()) {
                this.quoteRecord = quotes[0];
            }

            this.lineItems = [
                SELECT Id,
                       LineNumber,
                       PricebookEntry.Product2.Name,
                       PricebookEntry.Product2.ProductCode,
                       Description,
                       Quantity,
                       UnitPrice,
                       TotalPrice,
                       Weight_Unit__c
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId
                ORDER BY LineNumber ASC
            ];
        }

        if (this.quoteRecord != null && this.quoteRecord.CreatedDate != null) {
            this.fechaEspanol = formatearFechaEspanol(this.quoteRecord.CreatedDate);
        } else {
            this.fechaEspanol = '';
        }
    }

    private String formatearFechaEspanol(Datetime dt) {

        if (dt == null) {
            return '';
        }

        Date d = dt.date();

        Integer diff = d.daysBetween(Date.newInstance(1900, 1, 7));
        Integer dow = Math.mod(diff, 7);

        if (dow < 0) {
            dow += 7;
        }

        String[] dias = new String[]{
            'Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'
        };

        String[] meses = new String[]{
            'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
            'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
        };

        Integer mesIdx = d.month() - 1;

        if (mesIdx < 0) {
            mesIdx = 0;
        }

        if (mesIdx > 11) {
            mesIdx = 11;
        }

        String diaSemana = dias[dow];
        String mes = meses[mesIdx];

        return diaSemana + ' ' + d.day() + ' de ' + mes + ' ' + d.year();
    }
}