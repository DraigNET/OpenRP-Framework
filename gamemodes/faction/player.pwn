// ============================================================================
// File: faction/player.pwn
// Player-facing faction commands: /factions (list and members dialogs), /fservervehs and the
// rag on/off toggle.
// Commands: /fservervehs /factions /ragon /ragoff
// ============================================================================


static FacDlgStr[4096];
static FacDlgLine[200];

// /fservervehs - shows how many vehicles each faction has.
CMD:fservervehs(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	SendClientMessage(playerid, COLOR_BLUE, "[FACTIONS] Server faction vehicle counts:") ;

	for ( new f, fj = sizeof ( Faction ); f < fj; f++ ) {

		if ( Faction [ f ] [ E_FACTION_ID ] == INVALID_FACTION_ID ) continue ;

		new count = 0 ;

		for ( new i, j = sizeof ( Vehicle ); i < j; i++ ) {

			if ( ! IsValidVehicle ( Vehicle [ i ] [ E_VEHICLE_ID ] ) ) continue ;

			if ( Vehicle [ i ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_FACTION && Vehicle [ i ] [ E_VEHICLE_OWNER ] == Faction [ f ] [ E_FACTION_ID ] ) {

				count++ ;
			}
		}

		SendClientMessage(playerid, COLOR_INFO, sprintf("[%s] %s - %d vehicles",
			Faction_GetAbbreviationByID(f), Faction_GetNameByID(f), count)) ;
	}

	return true ;
}

// /factions - lists the factions on the server (admins see ids and online counts).
CMD:factions(playerid) 
{
	if (!GetPlayerAdminLevel(playerid)) format(FacDlgStr, sizeof(FacDlgStr), "ID\tTag\tName\tOnline");
	else format(FacDlgStr, sizeof(FacDlgStr), "ID [SQL]\tTag\tName\tOnline");
	
	new online[100]; // just assuming it's never gonna be more than 100...
	new map[32], index = 0;

	foreach (new i: Player) 
	{
		if (!Character [ i ] [ E_CHARACTER_FACTIONID ] || strcmp(Character[i][E_CHARACTER_FACTIONRANK], "Admin") == 0) continue;
		online[Character [ i ] [ E_CHARACTER_FACTIONID ]] ++;
	}

	for ( new i, j = sizeof ( Faction ); i < j ; i ++ ) 
	{
		if ( Faction [ i ] [ E_FACTION_ID ] == INVALID_FACTION_ID ) continue;
		new color = Faction [ i ] [ E_FACTION_VISIBLE ] ? 0 : 0x9E9E9E;

		if (!Faction [ i ] [ E_FACTION_VISIBLE ])
		{
			if (GetPlayerAdminLevel ( playerid ) <= ADMIN_LVL_LEAD) {
				continue;
			}
		}

		if (!GetPlayerAdminLevel(playerid)) {
			// No admin, we format this first. It will get overwritten if the player is an admin.
			format(FacDlgLine, sizeof(FacDlgLine), "\n%d\t%s\t%s\t%d", i, Faction [ i ] [ E_FACTION_ABBREV ], Faction [ i ] [ E_FACTION_NAME ], online[Faction [ i ] [ E_FACTION_ID ]]);
		}
		else {
		
			if (color)
			{
				format(FacDlgLine, sizeof(FacDlgLine), "\n{%06x}%d [%d]\t{%06x}%s\t{%06x}%s\t{%06x}%d", color, i, Faction [ i ] [ E_FACTION_ID ], color, Faction [ i ] [ E_FACTION_ABBREV ], color, Faction [ i ] [ E_FACTION_NAME ], color, online[Faction [ i ] [ E_FACTION_ID ]]);
			}
			else
			{
				format(FacDlgLine, sizeof(FacDlgLine), "\n%d [%d]\t%s\t%s\t%d", i, Faction [ i ] [ E_FACTION_ID ], Faction [ i ] [ E_FACTION_ABBREV ], Faction [ i ] [ E_FACTION_NAME ], online[Faction [ i ] [ E_FACTION_ID ]]);
			}
		}

		strcat(FacDlgStr, FacDlgLine);

		map[index] = i;
		index ++;
	}

	inline DlgShowFactions(pid, dialogid, response, listitem, string:inputtext[]) 
	{
		#pragma unused pid, dialogid, inputtext, listitem
		
		if (response)
		{
			new facindex = map[listitem];

			// Shows faction members (only to admins or their own faction)
			if (Character [ playerid ] [ E_CHARACTER_FACTIONID ] == Faction[facindex][E_FACTION_ID] || GetPlayerAdminLevel(playerid) >= ADMIN_LVL_JUNIOR)
			{
				ShowFactionMembersDlg(playerid, facindex);
			}
		}
	}

	Dialog_ShowCallback ( playerid, using inline DlgShowFactions, DIALOG_STYLE_TABLIST_HEADERS, "Factions", FacDlgStr, "View", "Close" );
	return true ;
}

// Shows a dialog listing the online members of a faction.
ShowFactionMembersDlg(playerid, facindex)
{
	new count = 0;
	format(FacDlgStr, sizeof(FacDlgStr), "Player ID\tName\tRank\tTier");

	foreach (new i: Player) 
	{
		if (!IsPlayerConnected(i)) continue;
		if (Character[i][E_CHARACTER_FACTIONID] != Faction [facindex][E_FACTION_ID]) continue;

		count ++;
		format(FacDlgStr, sizeof(FacDlgStr), "%s\n%03d\t%s\t%s\tTier %d", FacDlgStr, i, ReturnRPName(i), Character[i][E_CHARACTER_FACTIONRANK], Character[i][E_CHARACTER_FACTIONTIER]);
	}

	inline DlgShowFactionMembers(pid, dialogid, response, listitem, string:inputtext[]) 
	{
		#pragma unused pid, dialogid, inputtext, listitem
		
		if (response)
		{
			// Back to factions
			cmd_factions(playerid);
		}
	}

	Dialog_ShowCallback ( playerid, using inline DlgShowFactionMembers, DIALOG_STYLE_TABLIST_HEADERS, sprintf("%s Online Members (%d)", Faction[facindex][E_FACTION_ABBREV], count), FacDlgStr, "Back", "Close" );
	return true ;
}

// /ragon - turns on a gang rag so your faction colours show.
CMD:ragon(playerid, params[])
{
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	if ( Character[playerid][E_CHARACTER_ARREST_TIME] > 0 ) {
		SendServerMessage ( playerid, COLOR_ERROR, "Incarcerated", "A3A3A3", "You do not have your rag in prison." ) ;
	}

    if (GetPlayerFactionType(playerid) != FACTION_TYPE_ILLEGAL)
    {
        return SendServerMessage(
            playerid,
            COLOR_ERROR,
            "Error",
            "A3A3A3",
            "Only gang members can enable gang colours."
        );
    }

    if (Character[playerid][E_CHARACTER_RAG_ON])
        return SendClientMessage(playerid, -1, "Gang colours are already enabled.");

    Character[playerid][E_CHARACTER_RAG_ON] = true;

    UpdateTabListForOthers(playerid);

    new ronText[96], ronLogString[150];
	new Float: range = 15.0, color = COLOR_ACTION;
    format(ronText, sizeof(ronText), "puts on their rag.");

	format(ronLogString, sizeof(ronLogString), "%s", ronText);
	ProxDetectorEx(playerid, range, color, "*", ronLogString);
	
	format(ronLogString, sizeof(ronLogString), "* %s", ronText);
	AddLogEntry(playerid, LOG_TYPE_ACTION, ronLogString);
	
    return true;
}

// /ragoff - turns off your gang rag.
CMD:ragoff(playerid, params[])
{
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	if ( Character[playerid][E_CHARACTER_ARREST_TIME] > 0 ) {
		SendServerMessage ( playerid, COLOR_ERROR, "Incarcerated", "A3A3A3", "You do not have your rag in prison." ) ;
	}

    if (!Character[playerid][E_CHARACTER_RAG_ON])
        return SendClientMessage(playerid, -1, "Gang colours are already disabled.");

    Character[playerid][E_CHARACTER_RAG_ON] = false;

    UpdateTabListForOthers(playerid);

    new roffText[96], roffLogString[150];
	new Float: range = 15.0, color = COLOR_ACTION;
    format(roffText, sizeof(roffText), "puts on their rag.");

	format(roffLogString, sizeof(roffLogString), "%s", roffText);
	ProxDetectorEx(playerid, range, color, "*", roffLogString);
	
	format(roffLogString, sizeof(roffLogString), "* %s", roffText);
	AddLogEntry(playerid, LOG_TYPE_ACTION, roffLogString);
    return true;
}
