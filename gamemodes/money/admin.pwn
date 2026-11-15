// ============================================================================
// File: money/admin.pwn
// Staff commands /givemoney and /takemoney. Always logged.
// Commands: /givemoney /takemoney
// ============================================================================


CMD:givemoney ( playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_DEVELOPER) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new targetid, amount, reason[128] ;

	if ( sscanf ( params, "k<player>is[128]", targetid, amount, reason ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/givemoney [playerid] [amount of money] [reason]");
	}

	if ( ! IsPlayerConnected( targetid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Target isn't connected." ) ;
	}

	GivePlayerCash ( targetid, amount, sprintf("Admin cash from %s", ReturnRPName(playerid)) ) ;


	AddLogEntry(targetid, LOG_TYPE_SCRIPT, sprintf("[Admin] Received $%s from %s (%d) - Reason: %s", IntegerWithDelimiter(amount), ReturnRPName(playerid), true, reason));
	
	SendClientMessage(playerid, COLOR_INFO, sprintf("You have refunded (%d) %s $%s.", targetid, ReturnSettingsName(targetid, playerid), IntegerWithDelimiter ( amount ) ) ) ;
	SendClientMessage(targetid, COLOR_ERROR, sprintf("You have been refunded $%s by (%d) %s.", IntegerWithDelimiter(amount), playerid, ReturnSettingsName(playerid, targetid))) ;

	return true ;
}
CMD:takemoney ( playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_DEVELOPER) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new targetid, amount ;

	if ( sscanf ( params, "k<player>i", targetid, amount ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/takemoney [playerid] [amount of money]");
	}

	if ( ! IsPlayerConnected( targetid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Target isn't connected." ) ;
	}

	TakePlayerCash ( targetid, amount, sprintf("Admin %s took money", ReturnSettingsName(playerid, targetid)) ) ;

	SendClientMessage(playerid, COLOR_INFO, sprintf("You have fined (%d) %s $%s.", targetid, ReturnSettingsName(targetid, playerid), IntegerWithDelimiter ( amount ) ) ) ;
	SendClientMessage(targetid, COLOR_ERROR, sprintf("You have been fined $%s by (%d) %s.", IntegerWithDelimiter(amount), playerid, ReturnSettingsName(playerid, targetid))) ;
	AddLogEntry(targetid, LOG_TYPE_SCRIPT, sprintf("[Admin] Fined $%s by %s (%d)", IntegerWithDelimiter(amount), ReturnRPName(playerid), true));

	return true ;
}
