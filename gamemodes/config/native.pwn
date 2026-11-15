// ============================================================================
// File: config/native.pwn
// Command hooks: runs before and after every command (OnPlayerCommandReceived/Performed) to
// block commands for players who are not logged in or are incapacitated, and handles the
// remove-building hook on connect.
// ============================================================================

// On connect: rejects invalid player ids and sets up the player.
public OnPlayerConnect(playerid) {

	if ( playerid > MAX_PLAYERS ) {

		Kick ( playerid ) ;
		return true ;
	}
 
	EnablePlayerCameraTarget(playerid, 1);

	//PreloadAnimLib(playerid, "PED");
	//PreloadAnimLib(playerid, "SHOP");

	#if defined config_OnPlayerConnect
		return config_OnPlayerConnect(playerid);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerConnect
	#undef OnPlayerConnect
#else
	#define _ALS_OnPlayerConnect
#endif

#define OnPlayerConnect config_OnPlayerConnect
#if defined config_OnPlayerConnect
	forward config_OnPlayerConnect(playerid);
#endif

#include <YSI_Coding\y_hooks>
hook OnRemoveBuilding() {
#if FEATURE_REMOVE_STOCK_GRAFFITI
	RemoveBuilding(1490, 0.0, 0.0, 0.0, 10000.0 );
	RemoveBuilding(1524, 0.0, 0.0, 0.0, 10000.0 );
	RemoveBuilding(1525, 0.0, 0.0, 0.0, 10000.0 );
	RemoveBuilding(1526, 0.0, 0.0, 0.0, 10000.0 );
	RemoveBuilding(1527, 0.0, 0.0, 0.0, 10000.0 );
	RemoveBuilding(1528, 0.0, 0.0, 0.0, 10000.0 );
	RemoveBuilding(1529, 0.0, 0.0, 0.0, 10000.0 );
	RemoveBuilding(1530, 0.0, 0.0, 0.0, 10000.0 );
	RemoveBuilding(1531, 0.0, 0.0, 0.0, 10000.0 );
	//Map_RemoveBuildings(playerid);
#endif
}


// Runs BEFORE every command: stops commands from players who are not logged in or spawned.
public OnPlayerCommandReceived(playerid, cmdtext[]) {
	//printf("OnPlayerCommandReceived: pid: %d, cmd: %s", playerid, cmdtext); // to find the cause of the crashes
	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] < ADMIN_LVL_JUNIOR ) {
		if (! IsPlayerSpawned ( playerid ) || !IsPlayerLogged(playerid)) {

			if (GetPVarType(playerid, "FlyMode"))
			{
				// allows players in /noclip to do commands
			}
			else
			{
				SendClientMessage(playerid, COLOR_ERROR, "You must be spawned before you can do a command.");
				return 0 ;
			}
		}
	}

	return 1 ;
}

// Runs AFTER every command: shows spectating staff which commands the player tried.
public OnPlayerCommandPerformed(playerid, cmdtext[], success) 
{
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_HEAD) // Stops lower admins seeing cmds of high admins
	{
		foreach (new i: Player) 
		{
			if (!IsPlayerLogged(i) || Account[i][E_PLAYER_ACCOUNT_STAFFLEVEL] <= 0) continue;

			if (PlayerVar[i][E_PLAYER_IS_SPECTATING] == playerid) 
			{
				SendClientMessage(i, 0xDEDEDEFF, sprintf("[SPEC]: (%d) %s tried command (performed): %s", playerid, ReturnRPName(playerid), cmdtext));
			}
		}
	}
	
	if (!success) 
	{
		SendClientMessage(playerid, COLOR_OOC, "The command you entered does not exist. Use /help to see a list of available commands.");
	}

	return true ;
}

