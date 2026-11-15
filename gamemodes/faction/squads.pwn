// ============================================================================
// File: faction/squads.pwn
// Faction squads/divisions (SWAT, Traffic, Detectives...). The Squads table gives each squad a
// role bitmask; /setsquad assigns members.
// Commands: /setsquad
// ============================================================================


enum E_FACTION_SQUAD
{
	E_FACTION_SQUAD_ID,
	E_FACTION_SQUAD_ABBREV[8],   // keyed to the faction, not its type
	E_FACTION_SQUAD_NAME[24],
	E_FACTION_SQUAD_ROLES        // SQUAD_ROLE_* bitmask - what this squad can do
}

static const Squads[][E_FACTION_SQUAD] =
{
    // --- San Andreas Police Department ---
    {FACTION_SQUAD_NONE, "SAPD", "None",      0},
    {SQUAD_SAPD_SWAT,    "SAPD", "SWAT",      SQUAD_ROLE_TACTICAL},
    {SQUAD_SAPD_TSD,     "SAPD", "Traffic",   0},                      // Traffic Support Division
    {SQUAD_SAPD_DB,      "SAPD", "Detectives", SQUAD_ROLE_DETECTIVE},  // Detective Bureau

    // --- Fire Department of San Andreas ---
    {FACTION_SQUAD_NONE, "FDSA", "None",      0},
    {SQUAD_FDSA_FIRE,    "FDSA", "Fire",      0},
    {SQUAD_FDSA_EMS,     "FDSA", "EMS",       0},
    {SQUAD_FDSA_RESCUE,  "FDSA", "Rescue",    0}

    // --- Other factions: none by default ---
    // To give another faction squads:
    //   1. #define a unique squad id near SQUAD_SAPD_SWAT in gamemode.pwn (keep ids unique across
    //      factions so one number never means two things).
    //   2. Add a row above (add a comma after the previous row):
    //        {SQUAD_MYFAC_ALPHA, "ABBR", "Alpha", SQUAD_ROLE_TACTICAL}
    //      "ABBR" must match the faction abbreviation in the factions table, and the last value is
    //      a SQUAD_ROLE_* bitmask (0 if the squad needs no special powers).
    //   3. Members are assigned in game with /setsquad.
};

// Roles held by a squad id (0 if unknown / None).
GetSquadRoles(squad_id)
{
    for (new i = 0; i < sizeof(Squads); i ++)
    {
        if (Squads[i][E_FACTION_SQUAD_ID] == squad_id && Squads[i][E_FACTION_SQUAD_ROLES] != 0)
            return Squads[i][E_FACTION_SQUAD_ROLES];
    }
    return 0;
}

// Does any of the player's squad slots grant this role?
bool:PlayerSquadHasRole(playerid, role)
{
    return (GetSquadRoles(Character[playerid][E_CHARACTER_FACTION_SQUAD])  & role) != 0
        || (GetSquadRoles(Character[playerid][E_CHARACTER_FACTION_SQUAD2]) & role) != 0
        || (GetSquadRoles(Character[playerid][E_CHARACTER_FACTION_SQUAD3]) & role) != 0;
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
        if (GetSquadRoles(slots[i]) & role)
            return slots[i];
    }
    return FACTION_SQUAD_NONE;
}

// Returns true if the player is in the given squad (optionally of a faction type and on duty).
IsPlayerInFactionSquad(playerid, squad, factiontype = -1, bool:onduty = false)
{
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

    new userid = INVALID_PLAYER_ID, option = -1, helpstr[128], squad = -1, slot = -1;
	sscanf ( params, "k<player>ii", userid, option, slot );

    format(helpstr, sizeof(helpstr), "Available Squads: ");
    new index = 0;

    for (new i = 0; i < sizeof(Squads); i ++)
    {
        if (strcmp(Squads[i][E_FACTION_SQUAD_ABBREV], Faction[faction_enum_id][E_FACTION_ABBREV], true) != 0) continue;
        else if (index) strcat(helpstr, ", ");

        format(helpstr, sizeof(helpstr), "%s%d: %s", helpstr, Squads[i][E_FACTION_SQUAD_ID], Squads[i][E_FACTION_SQUAD_NAME]);

        index ++;
        
        if (option >= 0 && option == Squads[i][E_FACTION_SQUAD_ID])
        {
            squad = i;
            break;
        }
    }

    if (index < 1)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Your faction doesn't have any squads.");
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
        case 0: Character[userid][E_CHARACTER_FACTION_SQUAD] = Squads[squad][E_FACTION_SQUAD_ID];
        case 1: Character[userid][E_CHARACTER_FACTION_SQUAD2] = Squads[squad][E_FACTION_SQUAD_ID];
        case 2: Character[userid][E_CHARACTER_FACTION_SQUAD3] = Squads[squad][E_FACTION_SQUAD_ID];
    }

    new query[128];
    mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_factionsquad = %d, player_factionsquad2 = %d, player_factionsquad3 = %d WHERE player_id = %d", 
        Character[userid][E_CHARACTER_FACTION_SQUAD], Character[userid][E_CHARACTER_FACTION_SQUAD2], Character[userid][E_CHARACTER_FACTION_SQUAD3], 
        Character[userid][E_CHARACTER_ID]);

	mysql_tquery(mysql, query);

    Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s set squad %i of (%d) %s to \"%s\" }",
		Faction[faction_enum_id][ E_FACTION_ABBREV], playerid, ReturnRPName(playerid), slot, userid, ReturnRPName(userid), Squads[squad][E_FACTION_SQUAD_NAME]
	), faction_enum_id, false ) ;
	
	return true ;
}
