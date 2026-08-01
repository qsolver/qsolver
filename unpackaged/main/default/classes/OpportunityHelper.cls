/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 09-20-2023
 * @last modified by  : wflores@neox.cl
**/
public with sharing class OpportunityHelper {
    
    public static boolean canRunFromTestClass = true;

    public static void validateProducts(Map<Id, Opportunity> opportunitiesByIdOld, List<Opportunity> opportunities) {

        for (Opportunity opp : opportunities) {

            if ((opp.Has_OC__c == 'No' || opp.ELM_Order_Type__c == 'To Follow') && 
                (opp.RecordTypeId == Label.ELM_OpportunityRecurringSaleRecordTypeId ||
                    opp.RecordtypeId == Label.ELM_OpportunityTrialSaleRecordTypeId) && opp.StageName == 'Closed Won'){

                if (!opp.HasOpportunityLineItem) {
                    System.debug('Primer Error');
                    opp.addError('You need to associate Products to this Opportunity before updating it');
                }
            }
        }
    }

    public static void validateInsertionByUser(List<Opportunity> opportunities, Map<Id, Account> accounts) {
        
        Id userId = UserInfo.getUserId();
        Id userProfileId = UserInfo.getProfileId();
        List<String> userLinesOfBusiness;

        User user = [
            SELECT Id, ELM_Equipo_de_Ventas__c, Lines_of_business__c, Profile.Name, UserRole.Name
            FROM User
            WHERE Id =: userId
            LIMIT 1
        ];
        system.debug('USER INFO: '+user);
        system.debug('USER INFO: '+user.ELM_Equipo_de_Ventas__c);
        system.debug('USER INFO: '+user.Lines_of_business__c);

        //userLinesOfBusiness = user.Lines_of_business__c.split(';');

        Profile salesRepsProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Sales Reps'
            LIMIT 1
        ];
        
        system.debug('salesRepsProfile: '+salesRepsProfile);

        accounts.remove(null);
        accounts.putAll(
            [
                SELECT Id, Name, Vendedor_Alerta_Temprana__c, Vendedor_Chancado__c, 
                Vendedor_Chutes__c, Vendedor_GET__c, Vendedor_Grinding_Media__c,
                Vendedor_Maestranza__c, Vendedor_Molienda__c, Vendedor_Ollas__c,
                Vendedor_Partes_y_Respuestos__c, ELM_OtherSalesRep__c, ELM_Equipo_de_Ventas__c
                FROM Account 
                WHERE Id 
                IN : accounts.keySet()
            ]
        );
        
        System.debug('accounts : ' + accounts);
        
        
		// 1. Collect all IDs that could match AccountShare.UserOrGroupId
		Set<Id> groupAndUserIds = new Set<Id>();
		groupAndUserIds.add(userId);

		User u = [SELECT UserRoleId FROM User WHERE Id = :userId LIMIT 1];

		if (u.UserRoleId != null) {
    		// 2. Walk UP the role hierarchy to find all ancestor roles
    		Map<Id, UserRole> allRoles = new Map<Id, UserRole>(
        		[SELECT Id, ParentRoleId FROM UserRole]
    		);

    		Set<Id> userRoleAndAncestors = new Set<Id>();
    		Id currentRoleId = u.UserRoleId;
    		while (currentRoleId != null) {
        		userRoleAndAncestors.add(currentRoleId);
        		UserRole role = allRoles.get(currentRoleId);
        		currentRoleId = (role != null) ? role.ParentRoleId : null;
    		}

    		// 3. For the user's OWN role: add all group types (Role, RoleAndSubordinates, etc.)
    		for (Group g : [SELECT Id FROM Group WHERE RelatedId = :u.UserRoleId]) {
        		groupAndUserIds.add(g.Id);
    		}

    		// 4. For ANCESTOR roles: add RoleAndSubordinates groups (which include the user as a subordinate)
    		Set<Id> ancestorRoleIds = new Set<Id>(userRoleAndAncestors);
    		ancestorRoleIds.remove(u.UserRoleId); // Own role already handled above
    		if (!ancestorRoleIds.isEmpty()) {
        		for (Group g : [SELECT Id FROM Group WHERE RelatedId IN :ancestorRoleIds AND Type IN ('RoleAndSubordinates', 'RoleAndSubordinatesInternal')]) {
            		groupAndUserIds.add(g.Id);
        		}
    		}
		}

		// 5. Get all Public Groups the user belongs to (directly or via role groups)
		for (GroupMember gm : [SELECT GroupId FROM GroupMember WHERE UserOrGroupId IN :groupAndUserIds]) {
    		groupAndUserIds.add(gm.GroupId);
		}
        
        System.debug('groupAndUserIds => '+groupAndUserIds);

		// 4. Final Query - Now includes User, Public Groups, Roles, and Role-Groups
		List<AccountShare> accountShare = [
    		SELECT Id, OpportunityAccessLevel, AccountId, UserOrGroupId, RowCause
    		FROM AccountShare
    		WHERE AccountId IN :accounts.keySet() 
    		AND UserOrGroupId IN :groupAndUserIds
		];
        
        System.debug('AccountShare => '+accountShare);

        if(canRunFromTestClass == true){
            
        for (Opportunity opp : opportunities) {
            
            if(accounts.containsKey(opp.AccountId)){

                if ( user.Profile.Name == 'System Administrator' || user.UserRole.Name.contains('Grinding Media Int Manager')) {
                    continue;    

                } else if (user.UserRole.Name.contains('Grinding Media Int Sales Rep')) {
                    checkAccountShare(accountShare, opp);

                } else if (user.ELM_Equipo_de_Ventas__c != accounts.get(opp.AccountId).ELM_Equipo_de_Ventas__c) {
                    opp.addError('Your sales team needs to match the client sales team to create the opportunity // Tu sales team tiene que ser igual que el sales team de la cuenta para poder crear la oportunidad');

                }else if(user.ELM_Equipo_de_Ventas__c == accounts.get(opp.AccountId).ELM_Equipo_de_Ventas__c && user.Profile.Name.contains('Sales Rep')){
                    checkAccountShare(accountShare, opp);
                }
            }
        }
            
      }
    }

    private static void checkAccountShare(List<AccountShare> accountShare, Opportunity opp) {
        
        // Collect ALL AccountShare records per AccountId (multiple can exist from manual sharing, sharing rules via groups/roles)
        Map<Id, List<AccountShare>> accountSharesByAccountId = new Map<Id, List<AccountShare>>();

        for (AccountShare accountSh : accountShare) {
            if (!accountSharesByAccountId.containsKey(accountSh.AccountId)) {
                accountSharesByAccountId.put(accountSh.AccountId, new List<AccountShare>());
            }
            accountSharesByAccountId.get(accountSh.AccountId).add(accountSh);
        }

        // Check if there are no shares at all for this opportunity's account
        if (!accountSharesByAccountId.containsKey(opp.AccountId)) {
            opp.addError('You cannot create an Opportunity for this client, please check the permissions // No puedes crear una oportunidad para esta cuenta, por favor revisa los permisos');
        } else {
            // Check if ANY of the shares grants at least Read access to opportunities
            Boolean hasAccess = false;
            for (AccountShare accShare : accountSharesByAccountId.get(opp.AccountId)) {
                if (accShare.OpportunityAccessLevel == 'Read' || accShare.OpportunityAccessLevel == 'Edit') {
                    hasAccess = true;
                    break;
                }
            }
            if (!hasAccess) {
                opp.addError('You cannot create an Opportunity for this client, please check the permissions // No puedes crear una oportunidad para esta cuenta, por favor revisa los permisos');
            }
        }
    }
}