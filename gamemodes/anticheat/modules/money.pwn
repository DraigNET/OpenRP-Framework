// ============================================================================
// File: anticheat/modules/money.pwn
// SetPlayerCash(): the single place that changes a player's cash and updates the money HUD
// (positive and negative styles). All money changes should go through here so cheats cannot
// desync it.
// ============================================================================


GetPlayerCash ( playerid ) {

	return Character [ playerid ] [ E_CHARACTER_CASH ] ;
}

// Sets the character's cash to an exact amount and refreshes the on-screen money. All cash
// changes go through here.
SetPlayerCash(playerid, amount) {

	Character [ playerid ] [ E_CHARACTER_CASH ] = amount ;
	ResetPlayerMoney(playerid);
	GivePlayerMoney(playerid, Character [ playerid ] [ E_CHARACTER_CASH ] ) ;

	return true ;
}

stock GivePlayerCash ( playerid, amount, const reason[] ) {

	if ( amount < 0 ) {

		return false ;
	}

	Character [ playerid ] [ E_CHARACTER_CASH ] += amount ;

	new query [ 96 ] ; 

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_cash = %d WHERE player_id = %d",
		Character [ playerid ] [ E_CHARACTER_CASH ], Character [ playerid ] [ E_CHARACTER_ID ] ) ;
	mysql_tquery ( mysql, query ) ;

	ResetPlayerMoney ( playerid ) ;
	GivePlayerMoney ( playerid, Character [ playerid ] [ E_CHARACTER_CASH ] ) ;
	
	// Style 11 (Positive Money Style)
	GameTextForPlayer(playerid, sprintf("~n~+$%d", amount), 4500, 11) ;
	AddLogEntry(playerid, LOG_TYPE_MONEY_FLOW, sprintf("Give Cash: %s - Amount: $%d", reason, amount));

	return Character [ playerid ] [ E_CHARACTER_CASH ] ;
}

TakePlayerCash ( playerid, amount, const reason[] ) {

	if ( amount < 0 ) {

		return false ;
	}

	Character [ playerid ] [ E_CHARACTER_CASH ] -= amount ;

	new query [ 96 ] ; 

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_cash = %d WHERE player_id = %d",
		Character [ playerid ] [ E_CHARACTER_CASH ], Character [ playerid ] [ E_CHARACTER_ID ] ) ;
	mysql_tquery ( mysql, query ) ;

	ResetPlayerMoney ( playerid ) ;
	GivePlayerMoney ( playerid, Character [ playerid ] [ E_CHARACTER_CASH ] ) ;
	
	// Style 12 (Negative Money Style)
	GameTextForPlayer(playerid, sprintf("~n~-$%d", amount), 4500, 12) ;

	AddLogEntry(playerid, LOG_TYPE_MONEY_FLOW, sprintf("Take Cash: %s - Amount: $%d", reason, amount));

	return Character [ playerid ] [ E_CHARACTER_CASH ] ; 
}

TakePlayerBankCash ( playerid, amount ) {

	if ( amount < 0 ) {

		return false ;
	}

	Character [ playerid ] [ E_CHARACTER_BANKCASH ] -= amount ;
	AddLogEntry(playerid, LOG_TYPE_MONEY_FLOW, sprintf("Bank Debit - Amount: $%d", amount));

	new query [ 96 ] ; 

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_bankcash = %d WHERE player_id = %d",
		Character [ playerid ] [ E_CHARACTER_BANKCASH ], Character [ playerid ] [ E_CHARACTER_ID ] ) ;
	mysql_tquery ( mysql, query ) ;

	return Character [ playerid ] [ E_CHARACTER_BANKCASH ] ; 
}
