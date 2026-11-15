// ============================================================================
// File: faction/bank/header.pwn
// Faction bank account: /factionbank (/fbank) to deposit and withdraw, plus
// Faction_AddBankMoney / Faction_TakeBankMoney used by other systems (fines, paychecks).
// Commands: /factionbank /fbank
// ============================================================================

// /factionbank - shows the faction's bank balance.
CMD:factionbank(playerid, params[]) {
	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
	}

	new faction_enum_id = Faction_GetEnumID(factionid ); 

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
	}

	if (Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] > 2 ) {
		// 1 : owner, 2: command, 3 : member

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have permission to do this.");
	}

	SendServerMessage ( playerid, COLOR_BLUE, "Faction Funds", "A3A3A3", sprintf("Faction has $%s in it's bank.", 
		IntegerWithDelimiter(Faction_GetBankMoney ( faction_enum_id ) ) ) );
	
	return true ;
}

// /fbank [deposit/withdraw] [amount] - deposit or withdraw faction money (leaders only).
CMD:fbank(playerid, params[]) {
	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
	}

	new faction_enum_id = Faction_GetEnumID(factionid);

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
	}

	if (!IsPlayerNearArmory(playerid) && !IsPlayerInRangeOfPoint(playerid, 5.0, Faction [ faction_enum_id ] [ E_FACTION_SPAWN_X ], Faction [ faction_enum_id ] [ E_FACTION_SPAWN_Y ], Faction [ faction_enum_id ] [ E_FACTION_SPAWN_Z ] ) )
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only do this at your faction spawn or armory!");
	}

	new action [ 16 ], amount ;

	if ( sscanf(params, "s[16]i", action, amount) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Usage", "A3A3A3", "/fbank [deposit/withdraw] [amount]");
	}

	if ( amount <= 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Amount must be greater than 0.");
	}

	if ( ! strcmp(action, "deposit", true) ) {

		if ( GetPlayerCash(playerid) < amount ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("You don't have $%s in cash.", IntegerWithDelimiter(amount)));
		}

		TakePlayerCash(playerid, amount, "Faction bank deposit");
		Faction_AddBankMoney(faction_enum_id, amount, sprintf("%s deposited cash", ReturnRPName(playerid)));

		AddLogEntry(playerid, LOG_TYPE_FACTION_BANK, sprintf("Deposited $%s into faction bank (%s)", IntegerWithDelimiter(amount), Faction[faction_enum_id][E_FACTION_NAME]), true);

		SendServerMessage ( playerid, COLOR_BLUE, "Faction Bank", "A3A3A3", sprintf("You deposited $%s into the faction bank.", IntegerWithDelimiter(amount)));

		return true ;
	}

	if ( ! strcmp(action, "withdraw", true) ) {

		if ( Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] != 1 ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Only the faction owner can withdraw funds.");
		}

		if ( ! Faction_TakeBankMoney(faction_enum_id, amount, sprintf("%s withdrew cash", ReturnRPName(playerid))) ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("The faction bank doesn't have enough funds. Balance: $%s.", IntegerWithDelimiter(Faction_GetBankMoney(faction_enum_id))));
		}

		GivePlayerCash(playerid, amount, "Faction bank withdrawal");

		AddLogEntry(playerid, LOG_TYPE_FACTION_BANK, sprintf("Withdrew $%s from faction bank (%s)", IntegerWithDelimiter(amount), Faction[faction_enum_id][E_FACTION_NAME]), true);

		SendServerMessage ( playerid, COLOR_BLUE, "Faction Bank", "A3A3A3", sprintf("You withdrew $%s from the faction bank.", IntegerWithDelimiter(amount)));

		return true ;
	}

	return SendServerMessage ( playerid, COLOR_ERROR, "Usage", "A3A3A3", "/fbank [deposit/withdraw] [amount]");
}

// Adds money to a faction's bank and logs the reason. Use this instead of editing Faction[].
Faction_AddBankMoney(factionid, amount, const reason[]) {

	Faction [ factionid ] [ E_FACTION_BANK ] += amount ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE factions SET faction_bank = %d WHERE faction_id = %d",

		Faction [ factionid ] [ E_FACTION_BANK ], Faction [ factionid ] [ E_FACTION_ID ]
	);

	mysql_tquery(mysql, query);

	FactionLog(factionid, amount, true, reason);

	return true ;
}

// Takes money from a faction's bank. Returns false if the faction doesn't have enough.
stock Faction_TakeBankMoney(factionid, amount, const reason[]) {
	
	if ( Faction [ factionid ] [ E_FACTION_BANK ] < amount ) {

		return false ;
	}

	Faction [ factionid ] [ E_FACTION_BANK ] -= amount ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE factions SET faction_bank = %d WHERE faction_id = %d",

		Faction [ factionid ] [ E_FACTION_BANK ], Faction [ factionid ] [ E_FACTION_ID ]
	);

	mysql_tquery(mysql, query);

	FactionLog(factionid, amount, false, reason);

	return true ;
}

// Returns a faction's bank balance.
Faction_GetBankMoney(factionid) {

	return Faction [ factionid ] [ E_FACTION_BANK ] ;
}
