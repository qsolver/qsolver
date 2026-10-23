/**
 * Controlador del LWC quoteLineItemsEditor.
 * Permite editar en bloque los Quote Line Items de una Quote. Las columnas son los campos de QuoteLineItem
 * definidos en el Field Set Quote_Line_Items_Editor, que solo un administrador puede modificar.
 */
public class QuoteLineItemsEditorController {

    @TestVisible
    private static final String FIELD_SET_NAME = 'Quote_Line_Items_Editor';

    @TestVisible
    private static final String CONFIG_PERMISSION = 'Configure_Quote_Line_Items_Editor';

    // Columnas que se muestran si el Field Set no existe o esta vacio
    @TestVisible
    private static final List<String> DEFAULT_COLUMNS = new List<String>{ 'Quantity', 'ListPrice', 'UnitPrice', 'Description' };

    // Campos que no se muestran como columna (el producto siempre se muestra como columna fija)
    private static final Set<String> EXCLUDED_FIELDS = new Set<String>{
        'id', 'quoteid', 'product2id', 'pricebookentryid', 'opportunitylineitemid', 'isdeleted', 'currencyisocode'
    };

    private static final Set<Schema.DisplayType> EXCLUDED_TYPES = new Set<Schema.DisplayType>{
        Schema.DisplayType.ID, Schema.DisplayType.ADDRESS, Schema.DisplayType.LOCATION, Schema.DisplayType.BASE64
    };

    public class EditorData {
        @AuraEnabled public Boolean canConfigure;
        @AuraEnabled public String configUrl;
        @AuraEnabled public List<ColumnInfo> columns;
        @AuraEnabled public List<QuoteLineItem> lineItems;
    }

    public class ColumnInfo {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean updateable;
        @AuraEnabled public Boolean required;
    }

    public class RowError {
        @AuraEnabled public String recordId;
        @AuraEnabled public String message;
    }

    @AuraEnabled
    public static EditorData getEditorData(Id quoteId) {
        try {
            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.QuoteLineItem.fields.getMap();

            List<ColumnInfo> columns = new List<ColumnInfo>();
            Set<String> queryFields = new Set<String>{ 'Id', 'Product2Id', 'Product2.Name', 'SortOrder', 'LineNumber' };
            for (ColumnDefinition definition : getColumnDefinitions()) {
                Schema.SObjectField field = fieldMap.get(definition.fieldApiName.toLowerCase());
                if (!isDisplayableField(field)) {
                    continue;
                }
                Schema.DescribeFieldResult describe = field.getDescribe();
                ColumnInfo column = new ColumnInfo();
                column.fieldApiName = describe.getName();
                column.label = describe.getLabel();
                column.type = describe.getType().name();
                column.updateable = describe.isUpdateable();
                column.required = describe.isUpdateable() && (definition.required ||
                    (!describe.isNillable() && describe.getType() != Schema.DisplayType.BOOLEAN));
                columns.add(column);
                queryFields.add(column.fieldApiName);
            }

            String soql = 'SELECT ' + String.join(new List<String>(queryFields), ', ') +
                ' FROM QuoteLineItem WHERE QuoteId = :quoteId ORDER BY SortOrder NULLS LAST, LineNumber';

            EditorData data = new EditorData();
            data.canConfigure = canConfigure();
            data.configUrl = '/lightning/setup/ObjectManager/QuoteLineItem/FieldSets/view';
            data.columns = columns;
            data.lineItems = Database.queryWithBinds(soql, new Map<String, Object>{ 'quoteId' => quoteId }, AccessLevel.USER_MODE);
            return data;
        } catch (Exception e) {
            throw buildException(e.getMessage());
        }
    }

    /**
     * Guarda los cambios de los line items. changesJson tiene la forma { "<lineItemId>": { "<campo>": valor } }.
     * Retorna los errores por registro; los registros sin error se guardan igualmente.
     */
    @AuraEnabled
    public static List<RowError> saveLineItems(String changesJson) {
        Map<String, Object> changes;
        try {
            changes = (Map<String, Object>) JSON.deserializeUntyped(changesJson);
        } catch (Exception e) {
            throw buildException('Formato de cambios invalido.');
        }

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.QuoteLineItem.fields.getMap();
        List<QuoteLineItem> records = new List<QuoteLineItem>();
        try {
            for (String recordId : changes.keySet()) {
                QuoteLineItem record = new QuoteLineItem(Id = Id.valueOf(recordId));
                Map<String, Object> fieldValues = (Map<String, Object>) changes.get(recordId);
                for (String fieldName : fieldValues.keySet()) {
                    Schema.SObjectField field = fieldMap.get(fieldName.toLowerCase());
                    if (field == null || !field.getDescribe().isUpdateable()) {
                        throw buildException('El campo ' + fieldName + ' no se puede editar.');
                    }
                    record.put(field, coerceValue(fieldValues.get(fieldName), field.getDescribe()));
                }
                records.add(record);
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw buildException('Valor invalido: ' + e.getMessage());
        }

        List<RowError> errors = new List<RowError>();
        List<Database.SaveResult> results = Database.update(records, false, AccessLevel.USER_MODE);
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                continue;
            }
            List<String> messages = new List<String>();
            for (Database.Error error : results[i].getErrors()) {
                messages.add(error.getMessage());
            }
            RowError rowError = new RowError();
            rowError.recordId = records[i].Id;
            rowError.message = String.join(messages, '; ');
            errors.add(rowError);
        }
        return errors;
    }

    @TestVisible
    private static Boolean canConfigure() {
        if (FeatureManagement.checkPermission(CONFIG_PERMISSION)) {
            return true;
        }
        // Incluye el perfil (cada perfil tiene un permission set propio) y los permission sets asignados
        return ![
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.PermissionsModifyAllData = TRUE
            LIMIT 1
        ].isEmpty();
    }

    private class ColumnDefinition {
        String fieldApiName;
        Boolean required;
        ColumnDefinition(String fieldApiName, Boolean required) {
            this.fieldApiName = fieldApiName;
            this.required = required;
        }
    }

    private static List<ColumnDefinition> getColumnDefinitions() {
        List<ColumnDefinition> definitions = new List<ColumnDefinition>();
        Schema.FieldSet fieldSet = Schema.SObjectType.QuoteLineItem.fieldSets.getMap().get(FIELD_SET_NAME);
        if (fieldSet != null) {
            for (Schema.FieldSetMember member : fieldSet.getFields()) {
                // Los campos de objetos relacionados (ej. Product2.Family) no se pueden editar en el registro
                if (!member.getFieldPath().contains('.')) {
                    definitions.add(new ColumnDefinition(member.getFieldPath(), member.getRequired() || member.getDBRequired()));
                }
            }
        }
        if (definitions.isEmpty()) {
            for (String fieldName : DEFAULT_COLUMNS) {
                definitions.add(new ColumnDefinition(fieldName, false));
            }
        }
        return definitions;
    }

    private static Boolean isDisplayableField(Schema.SObjectField field) {
        if (field == null) {
            return false;
        }
        Schema.DescribeFieldResult describe = field.getDescribe();
        return describe.isAccessible() &&
            !EXCLUDED_FIELDS.contains(describe.getName().toLowerCase()) &&
            !EXCLUDED_TYPES.contains(describe.getType());
    }

    @TestVisible
    private static Object coerceValue(Object value, Schema.DescribeFieldResult describe) {
        if (value == null || (value instanceof String && String.isBlank((String) value))) {
            return describe.getType() == Schema.DisplayType.BOOLEAN ? (Object) false : null;
        }
        String text = String.valueOf(value);
        switch on describe.getType() {
            when DOUBLE, CURRENCY, PERCENT {
                return Decimal.valueOf(text);
            }
            when INTEGER {
                return Decimal.valueOf(text).intValue();
            }
            when LONG {
                return Decimal.valueOf(text).longValue();
            }
            when BOOLEAN {
                return value instanceof Boolean ? value : Boolean.valueOf(text);
            }
            when DATE {
                return Date.valueOf(text.left(10));
            }
            when DATETIME {
                return (Datetime) JSON.deserialize('"' + text + '"', Datetime.class);
            }
            when TIME {
                List<String> parts = text.split('[:.]');
                return Time.newInstance(
                    Integer.valueOf(parts[0]),
                    parts.size() > 1 ? Integer.valueOf(parts[1]) : 0,
                    parts.size() > 2 ? Integer.valueOf(parts[2]) : 0,
                    parts.size() > 3 ? Integer.valueOf(parts[3].left(3).replaceAll('[^0-9]', '')) : 0
                );
            }
            when else {
                return text;
            }
        }
    }

    private static AuraHandledException buildException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}