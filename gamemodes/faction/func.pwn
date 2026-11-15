// ============================================================================
// File: faction/func.pwn
// Faction helper functions: look up names, abbreviations and types by faction id, write faction
// logs and track faction activity.
// ============================================================================

MatchPlayerFactionType ( playerid, type ) {

	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		return false ;
	}

	new faction_enum_id = Faction_GetEnumID(factionid ); 

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return false ;
	}

	if ( Faction [ faction_enum_id ] [ E_FACTION_EXTRA ] == type ) {

		return true ;
	}

	return false ;
}

// Sends a message to every online member of a faction (optionally pinging them).
Faction_SendMessage(factionid, const message[], enum_id, split, ping = false, color = 0, bool:nohide = false ) {
// factionid == E_FACTION_ID, not enum ID

	if ( ! color ) {
		color = Faction [ enum_id ] [ E_FACTION_HEXCOLOR ] ;
	}

	foreach(new playerid: Player) {

		if ( Character [ playerid ] [ E_CHARACTER_ID ] == -1 ) {

			continue ;
		}

		if ( ! IsPlayerLogged ( playerid ) ) {

			continue ;
		}

		if ( Character [ playerid ] [ E_CHARACTER_FACTIONID ] <= 0 ) {
			continue ;
		}
		if ( PlayerVar [ playerid ] [ E_PLAYER_HIDING_FACTION ] && !nohide) {

			continue ;
		}

		if ( Character [ playerid ] [ E_CHARACTER_FACTIONID ] == factionid )
		{
			if ( split ) ZMsg_SendClientMessage(playerid, color, message);
			else SendClientMessage(playerid, color, message);

			if ( ping ) PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
			continue ;
		}
	}

	return true ;
}

// Sends a message to every online member of every faction of a given type.
Faction_SendTypeMessage(factiontypeid, message [], split, ping = false, color = 0, bool:nohide = false ) 
{
	foreach(new playerid: Player) 
	{
		if ( Character [ playerid ] [ E_CHARACTER_ID ] == -1 ) continue ;
		else if ( ! IsPlayerLogged ( playerid ) ) continue ;
		else if ( Character [ playerid ] [ E_CHARACTER_FACTIONID ] <= 0 ) continue ;
		else if ( PlayerVar [ playerid ] [ E_PLAYER_HIDING_FACTION ] && !nohide) continue;

		if ( Faction_GetType(Character [ playerid ] [ E_CHARACTER_FACTIONID ]) == factiontypeid ) 
		{
			if ( ! color ) color = Faction [ Faction_GetEnumID(Character [ playerid ] [ E_CHARACTER_FACTIONID ]) ] [ E_FACTION_HEXCOLOR ] ;
			if ( ping ) PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);

			if ( split )  ZMsg_SendClientMessage(playerid, color, message);
			else SendClientMessage(playerid, color, message);
		}
	}

	return true ;
}

Faction_GetEnumID ( factionid ) {
// factionid = E_FACTION_ID 

	for ( new i, j = sizeof ( Faction ); i < j ; i ++ ) {

		if ( Faction [ i ] [ E_FACTION_ID ] == factionid ) {

			return i ;
		}

		else continue ;
	}

	return INVALID_FACTION_ID ;
}

// Returns a faction's type (FACTION_TYPE_*) from its array index.
Faction_GetType(faction_enum_id ) {

	if(faction_enum_id < 0 || faction_enum_id >= MAX_FACTIONS || faction_enum_id == -1) {
		return 0;
	}
	return Faction [ faction_enum_id ] [ E_FACTION_TYPE ] ;
}

// Builds an abbreviation from the first letters of each word in a name.
Faction_GetAbbreviation(input[]) {

	new output [ 256 ] ;

	format ( output, sizeof ( output ), "%0.1s", input [ 0 ] ) ;

	for ( new i, j = strlen ( input ); i < j; i ++ ) {

	    if(input[i] == ' ') {

	    	format ( output, sizeof ( output ), "%s%.01s", output, input [ i + 1 ] ) ;
	    	continue ;
	    }

	    else continue ;
	}

	return output ;
}

// For use in cross-hooks! (kept as stock - its former callers now use
// Faction_CanID capability checks, but it stays available for cross-scripts.)
stock Faction_GetTypeByID(enum_id) {

	return Faction [ enum_id ] [ E_FACTION_TYPE ] ;
}

// Returns a faction's abbreviation from its array index.
Faction_GetAbbreviationByID(enum_id) {

	new abbreviation  [ 64 ] ;
	format ( abbreviation, sizeof ( abbreviation ), "%s", Faction [ enum_id ] [ E_FACTION_ABBREV ] ) ;

	return abbreviation ;
}
// Returns a faction's name from its array index.
Faction_GetNameByID(enum_id) {

	new name  [ 128 ] ;
	format ( name, sizeof ( name ), "%s", Faction [ enum_id ] [ E_FACTION_NAME ] ) ;

	return name ;
}

// Adds money to the bank of every faction of a given type.
Faction_AddBankMoneyPerType(type, amount, const reason[]) {

	for(new factionid, j = sizeof ( Faction ); factionid < j ; factionid ++ ) {

		if ( Faction [ factionid ] [ E_FACTION_TYPE ] == type ) {
			Faction [ factionid ] [ E_FACTION_BANK ] += amount ;

			new query [ 256 ] ;

			mysql_format(mysql, query, sizeof(query), "UPDATE factions SET faction_bank = %d WHERE faction_id = %d",

				Faction [ factionid ] [ E_FACTION_BANK ], Faction [ factionid ] [ E_FACTION_ID ]
			);

			mysql_tquery(mysql, query);

			FactionLog(factionid, amount, true, reason);
		}
	}

	return true ;
}



forward FactionActivity_Tick();
// Repeating task: counts the minutes each online faction member is active and saves the faction's
// daily activity.
public FactionActivity_Tick()
{
    new active[100];

    // --------------------------------------------------
    // Detect active factions
    // --------------------------------------------------
    foreach (new i: Player)
    {
        new fid = Character[i][E_CHARACTER_FACTIONID];

        if (!fid) continue;
        if (strcmp(Character[i][E_CHARACTER_FACTIONRANK], "Admin") == 0) continue;

        active[fid] = 1;
    }

    // --------------------------------------------------
    // Get current date
    // --------------------------------------------------
    new year, month, day;
    getdate(year, month, day);

    new query[256];

    // --------------------------------------------------
    // Loop factions
    // --------------------------------------------------
    for (new i, j = sizeof(Faction); i < j; i++)
    {
        new fid = Faction[i][E_FACTION_ID];

        if (fid == INVALID_FACTION_ID) continue;
        if (!active[fid]) continue;

        // --------------------------------------------------
        // 1. Lifetime tracking
        // --------------------------------------------------
        mysql_format(mysql, query, sizeof(query),
            "UPDATE factions \
             SET faction_active_minutes = faction_active_minutes + 1 \
             WHERE faction_id = %d",
            fid
        );
        mysql_tquery(mysql, query);

        // --------------------------------------------------
        // 2. Daily tracking (archive system)
        // --------------------------------------------------
        mysql_format(mysql, query, sizeof(query),
            "INSERT INTO faction_activity (faction_id, activity_date, minutes) \
             VALUES (%d, '%04d-%02d-%02d', 1) \
             ON DUPLICATE KEY UPDATE minutes = minutes + 1",
            fid, year, month, day
        );
        mysql_tquery(mysql, query);
    }
}

// Writes a faction bank transaction (deposit or withdrawal) to the `faction_logs` table.
FactionLog(factionid, amount, bool:isDeposit, const reason[])
{
    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO faction_logs (faction_id, action, amount, balance_after, reason) \
         VALUES (%d, %d, %d, %d, '%e')",
        Faction[factionid][E_FACTION_ID],
        isDeposit ? 1 : 2,
        amount,
        Faction[factionid][E_FACTION_BANK],
        reason
    );
    mysql_tquery(mysql, query);
}

