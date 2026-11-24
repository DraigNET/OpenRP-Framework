// ============================================================================
// File: faction/squads.pwn
// Faction squads/divisions (SWAT, Traffic, Detectives...). The Squads table gives each squad a
// role bitmask; /setsquad assigns members.
// Commands: /setsquad
// ============================================================================


// Persistent squad IDs, faction ownership and role flags are edited in the ACP.
// Zero always means None; disabled or unknown squads grant no permissions.
GetSquadRoles(squad_id)
{
    if (squad_id < 1 || squad_id >= RT_MAX_SQUADS || !RuntimeSquadEnabled[squad_id]) return 0;
    return RuntimeSquadRoles[squad_id];
}

// Confirm current faction ownership before using a stored squad assignment.
GetPlayerSquadRoles(playerid, squad_id)
{
    if (squad_id < 1 || squad_id >= RT_MAX_SQUADS || RuntimeSquadFaction[squad_id] != Character[playerid][E_CHARACTER_FACTIONID]) return 0;
    return GetSquadRoles(squad_id);
}

// Does any of the player's squad slots grant this role?
bool:PlayerSquadHasRole(playerid, role)
{
    return (GetPlayerSquadRoles(playerid, Character[playerid][E_CHARACTER_FACTION_SQUAD])  & role) != 0
        || (GetPlayerSquadRoles(playerid, Character[playerid][E_CHARACTER_FACTION_SQUAD2]) & role) != 0
        || (GetPlayerSquadRoles(playerid, Character[playerid][E_CHARACTER_FACTION_SQUAD3]) & role) != 0;
}

// The player's first squad id carrying this role, or FACTION_SQUAD_NONE.
GetPlayerSquadWithRole(playerid, role)
{
    new slots[3];
    slots[0] = Character[playerid][E_CHARACTER_FACTION_SQUAD];
    slots[1] = Character[playerid][E_CHARACTER_FACTION_SQUAD2];
    slots[2] = Character[playerid][E_CHARACTER_FACTION_SQUAD3];

    for (new i = 0; i < 3; i ++)
    {
        if (GetPlayerSquadRoles(playerid, slots[i]) & role)
            return slots[i];
    }
    return FACTION_SQUAD_NONE;
}

// Returns true if the player is in the given squad (optionally of a faction type and on duty).
IsPlayerInFactionSquad(playerid, squad, factiontype = -1, bool:onduty = false)
{
    if(squad<1 || squad>=RT_MAX_SQUADS || !RuntimeSquadEnabled[squad] || RuntimeSquadFaction[squad]!=Character[playerid][E_CHARACTER_FACTIONID]) return 0;
    if (factiontype != -1)
    {
        if (!IsPlayerInFactionType(playerid, factiontype, onduty))
            return 0;
    }

    if (!Character[playerid][E_CHARACTER_FACTIONID])
        return 0;

    return
        Character[playerid][E_CHARACTER_FACTION_SQUAD]  == squad ||
        Character[playerid][E_CHARACTER_FACTION_SQUAD2] == squad ||
        Character[playerid][E_CHARACTER_FACTION_SQUAD3] == squad;
}

// /setsquad [player] [squad] [slot 0-2] - assigns a member to a squad or division.
CMD:setsquad(playerid, params[]) 
{
	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
	}

	new faction_enum_id = Faction_GetEnumID(factionid ); 

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
	}
	
	if (Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] > 2 ) 
	{
		// 1 : owner, 2: command, 3 : member
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have permission to do this (only tier 1).");
	}

    new userid = INVALID_PLAYER_ID, option = -1, helpstr[2048], squad = -1, slot = -1;
	sscanf ( params, "k<player>ii", userid, option, slot );

    format(helpstr, sizeof(helpstr), "Available Squads: 0: None");
    if (option == 0) squad = 0;
    for (new i = 1; i < RT_MAX_SQUADS; i++)
    {
        if (!RuntimeSquadEnabled[i] || RuntimeSquadFaction[i] != factionid) continue;
        format(helpstr, sizeof(helpstr), "%s, %d: %s", helpstr, i, RuntimeSquadName[i]);
        if (option == i) squad = i;
    }

    if (squad == -1 || slot < 0 || slot > 2)
    {
        SendClientMessage(playerid, 0xDEDEDEFF, helpstr);
        SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/setsquad [player] [squad] [slot (0-2)]" );
        return true;
    }

    if (!IsPlayerConnected(userid) || !IsPlayerPlaying(userid) || !IsPlayerInFaction(userid, factionid))
    {
        return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid player or this player isn't in your faction.");
    }

    switch(slot) {
        case 0: Character[userid][E_CHARACTER_FACTION_SQUAD] = squad;
        case 1: Character[userid][E_CHARACTER_FACTION_SQUAD2] = squad;
        case 2: Character[userid][E_CHARACTER_FACTION_SQUAD3] = squad;
    }

    new query[128];
    mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_factionsquad = %d, player_factionsquad2 = %d, player_factionsquad3 = %d WHERE player_id = %d", 
        Character[userid][E_CHARACTER_FACTION_SQUAD], Character[userid][E_CHARACTER_FACTION_SQUAD2], Character[userid][E_CHARACTER_FACTION_SQUAD3], 
        Character[userid][E_CHARACTER_ID]);

	mysql_tquery(mysql, query);

    Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s set squad %i of (%d) %s to \"%s\" }",
		Faction[faction_enum_id][ E_FACTION_ABBREV], playerid, ReturnRPName(playerid), slot, userid, ReturnRPName(userid), squad ? RuntimeSquadName[squad] : "None"
	), faction_enum_id, false ) ;
	
	return true ;
}
