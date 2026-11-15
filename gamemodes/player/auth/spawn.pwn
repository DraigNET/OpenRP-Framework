// ============================================================================
// File: player/auth/spawn.pwn
// Spawn handling: the spawn location menu (last position, property, faction spawn, rented
// room), draw distance selection and refund checks.
// ============================================================================


static PropertyDlgStr[4096];

// Extra faction spawn points a faction may have (see faction/spawnpoints.pwn).
#define MAX_FACTION_SPAWNS_PER  ( 4 )

enum
{
	PLAYER_SPAWN_TYPE_LAST,
	PLAYER_SPAWN_TYPE_FACTION,
	PLAYER_SPAWN_TYPE_PROPERTY,
	PLAYER_SPAWN_TYPE_NEWBIE,
	PLAYER_SPAWN_TYPE_FACTIONPT
}

new PlayerSpawnOptions[MAX_PLAYERS][8];

// Skips the spawn menu: straight to the saved last position.
Player_SpawnAtLastLocation(playerid)
{
	PlayerSpawnOptions[playerid][0] = PLAYER_SPAWN_TYPE_LAST;
	return PlayerSpawnSelection(playerid, 0, false);
}

// Shows the spawn location menu (last position, faction, properties...).
Player_DisplaySpawnList(playerid, bool:respawn=false) {

	inline SpawnLocationPick(pid, dialogid, response, listitem, string:inputtext[] ) 
	{ 
		#pragma unused pid, dialogid, response, listitem, inputtext

		if ( ! response && !respawn ) 
		{
			SendClientMessage(pid, COLOR_RED, "Actually choose a spawn location!");
			return Player_DisplaySpawnList(pid) ;
		}

		if ( response ) 
		{
			PlayerSpawnSelection(pid, listitem, respawn );
			return true;
		}
	}

	format(PropertyDlgStr, sizeof(PropertyDlgStr), "Type\tOption\n");

	new options = 0, address[64], zone[64];

	if (Character[playerid][E_CHARACTER_ARREST_TIME])
	{
		strcat(PropertyDlgStr, "{BCAAA4}Prison\tBack to your cell...");
		PlayerSpawnOptions[playerid][options] = PLAYER_SPAWN_TYPE_LAST;
		options ++;
	}
	else
	{
		if (Character[playerid][E_CHARACTER_LAST_POS_X] && Character[playerid][E_CHARACTER_LAST_POS_Y] && Character[playerid][E_CHARACTER_LAST_POS_Z])
		{
			new Float:x, Float:y;
			x = Character[playerid][E_CHARACTER_LAST_POS_X];
			y = Character[playerid][E_CHARACTER_LAST_POS_Y];
			//new Float:z = Character[playerid][E_CHARACTER_LAST_POS_Z];

			if (Character[playerid][E_CHARACTER_LAST_POS_VW] > 0)
			{
				// TODO: They were probably in a property, so use the exterior of that if they were for the last position name
			}

			GetCoords2DZone(x, y, zone, sizeof(zone));
			GetPlayerAddress(x, y, address);

			strcat(PropertyDlgStr, sprintf("{FFCC80}Previous Location\t%s, %s\n", address, zone));
			PlayerSpawnOptions[playerid][options] = PLAYER_SPAWN_TYPE_LAST;
			options ++;
		}

		if (Character[playerid][E_CHARACTER_FACTIONID]) 
		{
			new faction_enum_id = Faction_GetEnumID(Character[playerid][E_CHARACTER_FACTIONID]);
			if (faction_enum_id != -1) 
			{
				strcat(PropertyDlgStr, sprintf("{9FA8DA}Your Faction\t%s\n", Faction_GetNameByID(faction_enum_id)));
				PlayerSpawnOptions[playerid][options] = PLAYER_SPAWN_TYPE_FACTION;
				options ++;

				// Extra spawn points the faction's leader has set (/addfspawn), kept in their own sub-menu.
				new fspawn_list[MAX_FACTION_SPAWNS_PER];
				if (FactionSpawn_GetForPlayer(playerid, fspawn_list))
				{
					strcat(PropertyDlgStr, "{9FA8DA}Faction Spawn Points\tSelect...\n");
					PlayerSpawnOptions[playerid][options] = PLAYER_SPAWN_TYPE_FACTIONPT;
					options ++;
				}
			}
		}

		new properties = GetPlayerPropertyCount(playerid);
		if (properties)
		{
			strcat(PropertyDlgStr, "{80CBC4}Your Properties\tSelect...\n");
			PlayerSpawnOptions[playerid][options] = PLAYER_SPAWN_TYPE_PROPERTY;
			options ++;
		}

		strcat(PropertyDlgStr, "{F48FB1}Newcomer Spawns\tSelect...\n");
		PlayerSpawnOptions[playerid][options] = PLAYER_SPAWN_TYPE_NEWBIE;

		PlayerVar[playerid][E_PLAYER_SPAWN_OPTIONS_COUNT] = options;
	}

	if (options)
	{
		if (respawn)
		{
			Dialog_ShowCallback ( playerid, using inline SpawnLocationPick, DIALOG_STYLE_TABLIST_HEADERS, "Spawn Selection", PropertyDlgStr, "Select", "Back" ) ;
		}
		else
		{
			Dialog_ShowCallback ( playerid, using inline SpawnLocationPick, DIALOG_STYLE_TABLIST_HEADERS, "Spawn Selection", PropertyDlgStr, "Select", "" ) ;
		}
	}
	else
	{
		// Show the newcomer spawn dialog instead since there's nowhere else
		Spawn_Newbie(playerid, respawn);
	}

	if (respawn)
	{
		return true;
	}


	return true ;			
}


// Timer: runs one second after spawning - loads toys, checks refunds and welcome messages.
timer OnSpawn_Common[1000](playerid, isrespawn)
{
	Attach_LoadDelayedEntities(playerid);

	if (!isrespawn)
	{
		// Legacy refunds (the old code like furniture)
		CheckLegacyRefunds(playerid);
		
		// New refund system (weapons and properties)
		Refund_CheckRefunds(playerid); 

		// Load players weapons (this function has additional checks in it)
		Weapon_LoadPlayerWeapons(playerid);
	}

	// They quit while handcuffed: put the cuffs back on now they've spawned
	if (Character[playerid][E_CHARACTER_CUFF_RESTORE])
	{
		ORP_SetPlayerCuffed(playerid, true, true, Character[playerid][E_CHARACTER_CUFF_RESTORE] == 2);
		Character[playerid][E_CHARACTER_CUFF_RESTORE] = 0;
	}

	// And then fire the hookable spawn event for setting other stuff
	CallLocalFunction("ORP_OnCharacterSpawn", "dd", playerid, isrespawn);
	PlayerVar[playerid][E_PLAYER_FIRST_SPAWN] = false;
}

// Common spawn setup for a character that has spawned.
Spawn_Common(playerid, isrespawn=0)
{
	// Very important that this is set.
	PlayerVar[playerid][E_PLAYER_SPAWNED_CHARACTER] = true;
	PlayerVar[playerid][E_PLAYER_CREATING_CHAR] = false;

	// Then doing the rest on a short delay to maybe solve some spawn issues for people
	defer OnSpawn_Common(playerid, isrespawn);
	return 1;
}

// Called when the player clicks Spawn; blocks it unless they have logged in and picked a
// character.
public OnPlayerRequestSpawn(playerid)
{
	// printf("OnPlayerRequestSpawn: (%d) %s", playerid, ORP_PlayerName(playerid, PLAYER_NAME_STYLE_DEFAULT));
    if (!IsPlayerLogged(playerid) || !PlayerVar[playerid][E_PLAYER_CHOSE_CHARACTER])
	{
		SendClientMessage(playerid, -1, "You must login to spawn!");
		SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s tried to spawn without logging in or choosing a character.", playerid, ReturnRPName(playerid)));
		printf("Blocked OnPlayerRequestSpawn for %d (%s)", playerid, ReturnRPName(playerid));
		TogglePlayerControllable(playerid, false);
		return 0;
	}

    return 1;
}

// Applies a draw distance preference (currently a no-op).
stock ApplyPlayerDrawDistance(playerid) {
    #pragma unused playerid
    /*
    new items, Float:multiplier;

    switch (Account[playerid][E_PLAYER_ACCOUNT_DDSETTING]) {
        case 1: { items = 500;   multiplier = 1.0; }
        case 2: { items = 750;   multiplier = 1.0; }
        case 3: { items = 1000;  multiplier = 1.5; }
        case 4: { items = 1500;  multiplier = 1.5; }
        case 5: { items = 2000;  multiplier = 2.0; }
        default:{ items = 500;   multiplier = 1.0; }
    }

    new types[] = {
        STREAMER_TYPE_OBJECT,
        STREAMER_TYPE_PICKUP,
        STREAMER_TYPE_3D_TEXT_LABEL,
        STREAMER_TYPE_ACTOR
    };
    for (new i = 0; i < sizeof(types); i++) {
        Streamer_SetVisibleItems(types[i], items, playerid);
        Streamer_SetRadiusMultiplier(types[i], multiplier, playerid);
        Streamer_Update(playerid, types[i]);
    }
    */
    return 1;
}

// Saves the player's draw distance setting.
stock SavePlayerDrawDistanceSetting(playerid) {
    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE `accounts` SET `account_ddsetting` = %d, `account_ddmessage` = 1 WHERE `account_id` = %d",
        Account[playerid][E_PLAYER_ACCOUNT_DDSETTING],
        Account[playerid][E_PLAYER_ACCOUNT_ID]
    );
    mysql_tquery(mysql, query);
}


new SkipCooldown[MAX_PLAYERS];
#include <YSI_Coding\y_hooks>
// Shows the draw distance information dialog.
ShowDrawDistanceInfo(playerid) {
    SkipCooldown[playerid] = gettime() + 3;

    inline OnDrawDistanceInfoResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, listitem, inputtext

        if (!response) {
            ShowDrawDistanceInfo(playerid);
            return 1;
        }

        ShowDrawDistanceSelect(playerid);
        return 1;
    }

    return Dialog_ShowCallback(playerid, using inline OnDrawDistanceInfoResponse,
        DIALOG_STYLE_MSGBOX, "Draw Distance - Information",
        "{E8C96A}" SERVER_NAME " {FFFFFF}runs on {E6DC5E}open.mp / SA:MP.\n{DEDEDE}But the general experience is not the same for everyone as PC performance varies.\n{FFFFFF}Selecting a lower setting {70A288}reduces the load on your machine{FFFFFF} and helps prevent FPS issues. You can always change this later with {00a6ed}/drawdistance{FFFFFF}.\n{FFB400}Please select a setting on the next screen that best suits your PC.",
        "Continue", "Close"
    );
}

// Shows the draw distance selection dialog.
ShowDrawDistanceSelect(playerid) {
    inline OnDrawDistanceSelect(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext

        if (!response) {
            ShowDrawDistanceSelect(playerid);
            return 1;
        }

        switch (listitem) {
            case 0: Account[playerid][E_PLAYER_ACCOUNT_DDSETTING] = 1;
            case 1: Account[playerid][E_PLAYER_ACCOUNT_DDSETTING] = 2;
            case 2: Account[playerid][E_PLAYER_ACCOUNT_DDSETTING] = 3;
            case 3: Account[playerid][E_PLAYER_ACCOUNT_DDSETTING] = 4;
        }

        Account[playerid][E_PLAYER_ACCOUNT_DDMESSAGE] = 1;
        SavePlayerDrawDistanceSetting(playerid);
        ApplyPlayerDrawDistance(playerid);

        new names[][] = { "LOW", "MEDIUM", "HIGH", "ULTRA" };
        SendClientMessage(playerid, 0x84aa63ff, sprintf("-> Draw distance set to %s. You can change this anytime with /drawdistance.", names[listitem]));
        return 1;
    }

    return Dialog_ShowCallback(playerid, using inline OnDrawDistanceSelect,
        DIALOG_STYLE_LIST, "Draw Distance - Select Setting",
        "{46B373}Low {DBD5D5}- Recommended for low-end PCs\n{B4AA48}Medium {DBD5D5}- Balanced setting for most players (default)\n{87CEEB}High {DBD5D5}- For decent PCs, more detail at range\n{AA6516}Ultra {DBD5D5}- High-end PCs only",
        "Apply", "Close"
    );
}

forward ORP_OnPlayerSpawn(playerid);
// Called when the player spawns: fixes visibility and finishes spawning.
public ORP_OnPlayerSpawn(playerid)
{
    Property_UpdatePlayerVisibility(playerid);

    if (!PlayerVar[playerid][E_PLAYER_SPAWNED_CHARACTER])
    {
        printf("ORP_OnPlayerSpawn (FIRST): (%d) %s", playerid, ReturnRPName(playerid));
        new year, month, day, hour, minute, second;
        stamp2datetime(gettime(), year, month, day, hour, minute, second, 1);
        Spawn_Common(playerid, 0);
    }
    else
    {
        printf("ORP_OnPlayerSpawn (RESPAWN): (%d) %s", playerid, ReturnRPName(playerid));
        Spawn_Common(playerid, 1);
    }

    // Draw distance selection is disabled: ApplyPlayerDrawDistance() is a no-op and
    // /drawdistance is commented out in visuals/header.pwn. Showing the dialog would
    // force every new player through a modal that changes nothing.
    // if (!Account[playerid][E_PLAYER_ACCOUNT_DDMESSAGE]) ShowDrawDistanceInfo(playerid);

    return 1;
}

hook OnPlayerSpawn(playerid)
{
	printf("OnPlayerSpawn: (%d) %s", playerid, ReturnRPName(playerid));

	if (!IsPlayerLogged(playerid))
	{
		SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s spawned without logging in and was kicked.", playerid, ReturnRPName(playerid)));
		printf("[!] Kicked (%d) %s for spawning without being logged in.", playerid, ReturnRPName(playerid));
		ResetPlayerWeapons(playerid);
		TogglePlayerSpectating(playerid, true);
		SetPlayerVirtualWorld(playerid, 65535);
		Kick(playerid);
		return 0;
	}

	if (!PlayerVar[playerid][E_PLAYER_CHOSE_CHARACTER])
	{
		SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s spawned without choosing a character and was kicked.", playerid, ReturnRPName(playerid)));
		printf("[!] Kicked (%d) %s for spawning without choosing a character.", playerid, ReturnRPName(playerid));
		ResetPlayerWeapons(playerid);
		TogglePlayerSpectating(playerid, true);
		SetPlayerVirtualWorld(playerid, 65535);
		Kick(playerid);
		return 0;
	}

	CallLocalFunction("ORP_OnPlayerSpawn", "d", playerid);
	return 1;
}

// Handles refunds on login.
static LegacyRefundQuery[256];
// Refunds legacy items (sold fuel stations, etc.) when a character logs in.
static CheckLegacyRefunds(playerid)
{
	if ( Character [ playerid ] [ E_CHARACTER_SOLD_FUELSTATION ] ) {
		FuelStation_RefundPlayer(playerid);

		Character [ playerid ] [ E_CHARACTER_SOLD_FUELSTATION ] = 0 ;

		mysql_format(mysql, LegacyRefundQuery, sizeof(LegacyRefundQuery), "UPDATE characters SET player_soldfuelstation = 0 WHERE player_id = %d", 
			Character [ playerid ] [ E_CHARACTER_ID ] ) ;
		mysql_tquery(mysql, LegacyRefundQuery);
	}

	if ( Character [ playerid ] [ E_CHARACTER_SOLD_PROPERTY ] ) {

		new id = Character [ playerid ] [ E_CHARACTER_SOLD_PROPERTY ] ;

		Property_RefundPlayer(playerid, id) ;

		Character [ playerid ] [ E_CHARACTER_SOLD_PROPERTY ] = -1 ;
		mysql_format(mysql, LegacyRefundQuery, sizeof(LegacyRefundQuery), "UPDATE characters SET player_soldproperty = 0 WHERE player_id = %d",
		Character [ playerid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, LegacyRefundQuery);
	}

	if ( Character [ playerid ] [ E_CHARACTER_SOLD_FURNITURE ] ) {

		SendClientMessage(playerid, -1, " " ) ;
		SendClientMessage(playerid, COLOR_YELLOW, sprintf("WARNING:{DEDEDE} ALL of your furniture has been sold while you were OFFLINE. You have been refunded $%s.",
			IntegerWithDelimiter ( Character [ playerid ] [ E_CHARACTER_SOLD_FURNITURE ] ) ) ) ;
		SendClientMessage(playerid, COLOR_RED, "If you think this was a mistake, post a refund request with the property ID. ");
		SendClientMessage(playerid, -1, " " ) ;

		GivePlayerCash ( playerid, Character [ playerid ] [ E_CHARACTER_SOLD_FURNITURE ], "Auto furniture refund" ) ;
		Character [ playerid ] [ E_CHARACTER_SOLD_FURNITURE ] = 0 ;

		mysql_format(mysql, LegacyRefundQuery, sizeof(LegacyRefundQuery), "UPDATE characters SET player_soldfurni = 0 WHERE player_id = %d",
			Character [ playerid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, LegacyRefundQuery);
	}
}



// -------------------------------------------------------
// The below functions are whenever a player spawns or respawns from the MENUS only (e.g. login or /respawnplayer) and NOT if they die/respawn from the GAME
// Use them when your scripts need to do stuff when a player logs in, e.g. checking if they have an email address set
// Example is below, always include y_hooks at the top of the file first (so that the same hook in different files don't conflict)


// #include <YSI_Coding\y_hooks>

/*
	hook ORP_OnCharacterSpawn(playerid, isrespawn)
	{
		PlayerVar[playerid][E_PLAYER_PM_BLOCKED] = true;
		SendClientMessage(playerid, COLOR_YELLOW, "Your PMs have been automatically blocked to avoid player nuisance.");
		return 1;
	}
*/

// -----------------------------------------------------
