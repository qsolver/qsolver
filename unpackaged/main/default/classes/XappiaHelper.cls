global class XappiaHelper {		
	static Map<String, RecordType> mapRecordTypes = new Map<String, RecordType> ();
	global static RecordType getRecordType(String SobjectType, String recordTypeDevName) {
		if (mapRecordTypes.containsKey(SobjectType + '-' + recordTypeDevName)) {			
			return mapRecordTypes.get(SobjectType + '-' + recordTypeDevName);
		} else {
			Schema.SObjectType sot = Schema.getGlobalDescribe().get(SobjectType);			
			RecordTypeInfo rti = sot == null? null : sot.getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeDevName);			
			if (rti != null) {
				RecordType rt = new RecordType();
				rt.Name = rti.getName();
				rt.DeveloperName = rti.getDeveloperName();
				rt.id = rti.getRecordTypeId();
				mapRecordTypes.put(SobjectType + '-' + recordTypeDevName, rt);
				return rt;
			} else {
				return null;
			}
		}
	}
	
	// /*******************************************************************************************************	
	// * it use format 'sObjectType-recordTypeName'
	// */		
	// global static RecordType getRecordType(String encodedName) {
	// 	List<String> parameters = encodedName.split('-');
	// 	system.debug(parameters);
	// 	if (parameters.size() == 2) {
	// 		return getRecordType(parameters[0], parameters[1]);			
	// 	} else {
	// 		return null;
	// 	}
	// }	

	// /*******************************************************************************************************	
	// * return CUIT in format xy-DNI-z. If it's not a valid DNI, return ''. Works only to fisical person.
	// */	
	// global static String generateCUITFromDNI(String DNI, boolean isMale) {
	// 	if (String.isBlank(dni)
	// 			||!dni.isNumeric() || DNI.length() < 7 
	// 			|| DNI.length() > 8 || isMale == null
	// 	) {
	// 		return '';
	// 	}
	// 	if (DNI.length() == 7) {
	// 		DNI = '0' + DNI;
	// 	}
	// 	String XY;
	// 	if (isMale) {
	// 		XY = '20';
	// 	}
	// 	else {
	// 		XY = '27';
	// 	}

	// 	String XYWithDNI = XY + DNI;
	// 	Integer[] serie = new Integer[] { 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 };
	// 	Integer aux = 0;
	// 	for (Integer i = 0; i < 10; i++) {
	// 		String simbol = XYWithDNI.subString(i, i + 1);
	// 		aux += Integer.valueOf(simbol) * serie[i];
	// 	}
	// 	aux = (Math.mod(aux, 11));		
	// 	String Z = '';
	// 	if (aux == 0) {
	// 		Z = '0';
	// 	}
	// 	else if (aux == 1)	{
	// 		XY = '23';
	// 		if (isMale)	{
	// 			Z = '9';
	// 		} else	{
	// 			Z = '4';
	// 		}
	// 	}
	// 	else {
	// 		Z = String.valueOf(11 - aux);
	// 	}		
	// 	return XY + dni + Z;
	// }

	// /*******************************************************************************************************
	// * accept both formats: xx-xxxxxxxx-x and xxxxxxxxxxx
	// */
	// global static Boolean isItValidCUIT(String CUIT) {
	// 	if (String.isBlank(CUIT)) {
	// 		return false;
	// 	}
	// 	String numericCUIT = StringToNumericString(CUIT);
	// 	if (numericCUIT.length() != 11) {
	// 		return false;
	// 	}
	// 	if (CUIT.length() == 13 
	// 			&& (CUIT.subString(2,3)!='-'
	// 				|| CUIT.subString(11,12)!='-')
	// 	) {
	// 		return false;		
	// 	}
	// 	CUIT = StringToNumericString(CUIT);
	// 	if (CUIT.subString(0,2)!='34'
	// 			&& CUIT.subString(0,2)!='33'
	// 			&& CUIT.subString(0,2)!='30'
	// 			&& CUIT.subString(0,2)!='27'
	// 			&& CUIT.subString(0,2)!='24'
	// 			&& CUIT.subString(0,2)!='23'
	// 			&& CUIT.subString(0,2)!='20'
	// 	) {
	// 		return false;
	// 	}
	// 	Integer[] serie = new Integer[] { 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 };
	// 	Integer aux = 0;
	// 	for (Integer i = 0; i < 10; i++) {
	// 		String simbol = CUIT.subString(i, i + 1);
	// 		aux += Integer.valueOf(simbol) * serie[i];			
	// 	}
	// 	aux = 11 - (Math.mod(aux, 11));		
	// 	if (aux == 11) {
	// 		aux = 0;
	// 	}
	// 	return Integer.valueOf(CUIT.subString(10, 11)) == aux;
	// }
	
	// /*******************************************************************************************************	
	// * its validation for most credit cards and other stuff
	// */
	// public static boolean isItValidLuhnCode(String creditCardNumber) {		
	// 	if (String.isBlank(creditCardNumber)) {
	// 		return false;
	// 	}
	// 	Integer sumOfDigits = 0;
	// 	List<String> cardDigits = creditCardNumber.split('');
	// 	Integer checkEven = Math.mod(cardDigits.size(), 2);
	// 	for (Integer i = 0; i < cardDigits.size(); i++) {
	// 		Integer d = Integer.valueOf(cardDigits[i]);
	// 		if (Math.mod(i, 2) == checkEven) {
	// 			d *= 2;
	// 			if (d >= 10) {
	// 				d = d / 10 + Math.mod(d, 10);
	// 			}
	// 		}
	// 		sumOfDigits += d;
	// 	}				
	// 	return Math.mod(sumOfDigits, 10) == 0;
	// }

	// /*******************************************************************************************************
	// * 's2w3df41'->'2341'
	// */
	// global static String stringToNumericString(String str) {
	// 	if (String.isBlank(str)) {
	// 		return '';
	// 	}
	// 	String numericString = '';
	// 	Integer strLength = str.length();
	// 	for (Integer i = 0; i<str.length(); i++) {
	// 		String s = str.mid(i, 1);
	// 		if (s.isNumeric()) {
	// 			numericString += s;
	// 		}
	// 	}
	// 	return numericString;
	// }
	// /*******************************************************************************************************
	// * @description validate if CBU is well formed - Validation provided by Mauricio Closa - Adapted by Xappia
	// */
	// global static Boolean isItValidCBU(String CBU) {
	// 	List<Integer> VEC1 = new List<Integer> {7, 1, 3, 9, 7, 1, 3};
	// 	List<Integer> VEC2 = new List<Integer> {3, 9, 7, 1, 3, 9, 7, 1, 3, 9, 7, 1, 3};		
	// 	if(String.isBlank(CBU)) {
	// 		return false;		
	// 	}
	// 	CBU = CBU.replace('-', '');
	// 	if (CBU.length() == 22 && CBU.isNumeric()) {
	// 		Integer acum = 0;
	// 		for (Integer i = 0; i < 7; i++) {				
	// 			acum += Integer.valueOf(CBU.subString(0, 7).subString(i, i + 1)) * VEC1[i];
	// 		}						
	// 		Integer verificador2 = Integer.valueOf(CBU.subString(7, 8));
	// 		Integer diferencia1 = math.mod(10 - (math.mod(acum, 10)), 10);						
	// 		boolean primerBloqueCbuOk = (verificador2 == diferencia1);
	// 		acum = 0;
	// 		for (Integer i = 0; i < 13; i++) {
	// 			acum += Integer.valueOf(CBU.subString(8, 21).subString(i, i + 1)) * VEC2[i];
	// 		}			
	// 		Integer diferencia2 = math.mod(10 - (math.mod(acum, 10)), 10);						
	// 		boolean segundoBloqueCbuOk = (Integer.valueOf(CBU.subString(21)) == diferencia2);			
	// 		return (primerBloqueCbuOk && segundoBloqueCbuOk);
	// 	}
	// 	else {
	// 		return false;
	// 	}
	// }	

}