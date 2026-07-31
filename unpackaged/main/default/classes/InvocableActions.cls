public class InvocableActions {

    @InvocableMethod(label = 'Get record sObject Type Name')
    public static List<String> getSObjectTypeName(List<ID> recordId) {

        List<String> sObjName = new List<String>();

        sObjName.add(recordId[0].getSobjectType().getDescribe().getName());

        return sObjName;
    }
}