// ============================================================================
// File: admin/jetpack.pwn
// /jetpack and /givejetpack for admins.
// Commands: /jetpack /givejetpack
// ============================================================================

CMD:jetpack(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_BETA ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK) ;

	return true ;
}

CMD:givejetpack(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new targetid;

	if (sscanf ( params, "k<player>", targetid ))
		return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/givejetpack [player]");

	if ( ! IsPlayerConnected ( targetid ) )
		return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "Target isn't connected.");
	
	SetPlayerSpecialAction(targetid, SPECIAL_ACTION_USEJETPACK) ;

	return true ;
}