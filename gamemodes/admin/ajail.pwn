// ============================================================================
// File: admin/ajail.pwn
// Admin jail: sends rule-breakers to a private 'dungeon' room for a set time (/ajail, /unajail,
// /offlineajail) and tracks the countdown (AdminJail_Tick). Also the staff meeting room
// (/staffroom, /adminroom). The room position (ADMIN_JAIL_POS_*) is 0,0,0 until you set it for
// your map.
// Commands: /staffroom /adminroom /gotoadminroom /gotoajail /ajail /unajail /offlineajail
// ============================================================================

#if !defined ADMIN_JAIL_POS_X 
	#define ADMIN_JAIL_POS_X (RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_X]) // Cached database setting; edit through ACP.
#endif

#if !defined ADMIN_JAIL_POS_Y
	#define ADMIN_JAIL_POS_Y (RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_Y]) // Cached database setting; edit through ACP.
#endif

#if !defined ADMIN_JAIL_POS_Z
	#define ADMIN_JAIL_POS_Z (RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_Z]) // Cached database setting; edit through ACP.
#endif

#if !defined ADMIN_JAIL_POS_INT
	#define ADMIN_JAIL_POS_INT (RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_INTERIOR]) // Cached database setting; edit through ACP.
#endif

#include <YSI_Coding\y_hooks>
#define ADMIN_JAIL_WORLD (RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_WORLD]) // Cached database setting; edit through ACP.
// Measured 2DFX emitter offset inside stock SAMP.img/fire.dff (model 18688).
#define ADMIN_JAIL_FIRE_OFFSET_X 0.001708984375
#define ADMIN_JAIL_FIRE_OFFSET_Y 0.0054931640625
#define ADMIN_JAIL_FIRE_OFFSET_Z 1.6113290786743164
static ADM_JAIL_AREA, AdminJailObjects[64], AdminJailObjectCount;
static bool:AdminJailRebuilding;
static AdminJailApplied[6], bool:AdminJailHasApplied;
static bool:AdminJailEnvironment[MAX_PLAYERS];
static const Float:AdminJailCells[][4] = {
    {-4.4836,  3.4464, 1.0, 267.4665},
    {-4.5979, -1.3783, 1.0, 275.4657},
    {-4.6067, -6.3914, 1.0, 267.2981},
    { 4.9629, -6.4938, 1.0,  91.7905},
    { 4.4434, -1.4461, 1.0,  90.5175},
    { 4.4133,  3.6533, 1.0,  90.0371}
};

// Returns true if the player is inside the admin jail room (matching virtual world and interior).
stock bool:IsPlayerInAdminDungeon(playerid)
{
    return GetPlayerVirtualWorld(playerid) == ADMIN_JAIL_WORLD && GetPlayerInterior(playerid) == ADMIN_JAIL_POS_INT;
}

hook OnPlayerConnect(playerid)
{
    AdminJailEnvironment[playerid] = false;
    return 1;
}

AdminJail_Rebuild() 
{
    new signature[6];
    signature[0]=_:ADMIN_JAIL_POS_X; signature[1]=_:ADMIN_JAIL_POS_Y; signature[2]=_:ADMIN_JAIL_POS_Z;
    signature[3]=ADMIN_JAIL_WORLD; signature[4]=ADMIN_JAIL_POS_INT; signature[5]=RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_ENABLED];
    new bool:changed=!AdminJailHasApplied;
    for(new i; i<6; i++) if(signature[i]!=AdminJailApplied[i]) changed=true;
    if(!changed) return 1;
    foreach(new playerid:Player) if(Character[playerid][E_CHARACTER_AJAIL_TIME] && !signature[5]) return 0;
    new objects[64], count, area;
    if(signature[5]) {
    // Placeholder cell block built from stock objects (floor + wall ring). Replace with your own map.
	for (new fx = -1; fx <= 1; fx++)
	{
		for (new fy = -1; fy <= 1; fy++)
		{
			objects[count++]=CreateDynamicObject(19377, ADMIN_JAIL_POS_X + float(fx) * 10.0, ADMIN_JAIL_POS_Y + float(fy) * 10.0, ADMIN_JAIL_POS_Z - 0.1, 0.0, 0.0, 0.0, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT, -1, 300.0, 300.0);
		}
	}
	for (new w = -2; w <= 2; w++)
	{
		objects[count++]=CreateDynamicObject(19353, ADMIN_JAIL_POS_X + float(w) * 3.0, ADMIN_JAIL_POS_Y - 10.4, ADMIN_JAIL_POS_Z + 1.4, 0.0, 0.0, 90.0, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT, -1, 300.0, 300.0);
		objects[count++]=CreateDynamicObject(19353, ADMIN_JAIL_POS_X + float(w) * 3.0, ADMIN_JAIL_POS_Y + 10.4, ADMIN_JAIL_POS_Z + 1.4, 0.0, 0.0, 90.0, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT, -1, 300.0, 300.0);
	}
	for (new w = -3; w <= 3; w++)
	{
		objects[count++]=CreateDynamicObject(19353, ADMIN_JAIL_POS_X - 7.4, ADMIN_JAIL_POS_Y + float(w) * 3.0, ADMIN_JAIL_POS_Z + 1.4, 0.0, 0.0, 0.0, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT, -1, 300.0, 300.0);
		objects[count++]=CreateDynamicObject(19353, ADMIN_JAIL_POS_X + 7.4, ADMIN_JAIL_POS_Y + float(w) * 3.0, ADMIN_JAIL_POS_Z + 1.4, 0.0, 0.0, 0.0, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT, -1, 300.0, 300.0);
	}
    // Stock water stays below the walking surface, visible only in floor recesses.
    for (new column = 0; column < 3; column++)
    {
        for (new row = 0; row < 4; row++)
        {
            objects[count++]=CreateDynamicObject(19603, ADMIN_JAIL_POS_X - 5.0 + float(column) * 5.0, ADMIN_JAIL_POS_Y - 7.5 + float(row) * 5.0, ADMIN_JAIL_POS_Z - 0.025, 0.0, 0.0, 0.0, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT, -1, 150.0, 150.0);
        }
    }
    // Stock fire particles reliably render on SA-MP clients; custom DFF has 2DFX lights.
    objects[count++]=CreateDynamicObject(18688, ADMIN_JAIL_POS_X - 1.59 - ADMIN_JAIL_FIRE_OFFSET_X, ADMIN_JAIL_POS_Y - 8.0 - ADMIN_JAIL_FIRE_OFFSET_Y, ADMIN_JAIL_POS_Z + 2.85 - ADMIN_JAIL_FIRE_OFFSET_Z, 0.0, 0.0, 0.0, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT, -1, 100.0, 100.0);
    objects[count++]=CreateDynamicObject(18688, ADMIN_JAIL_POS_X + 1.59 - ADMIN_JAIL_FIRE_OFFSET_X, ADMIN_JAIL_POS_Y - 3.0 - ADMIN_JAIL_FIRE_OFFSET_Y, ADMIN_JAIL_POS_Z + 2.85 - ADMIN_JAIL_FIRE_OFFSET_Z, 0.0, 0.0, 0.0, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT, -1, 100.0, 100.0);
    objects[count++]=CreateDynamicObject(18688, ADMIN_JAIL_POS_X - 1.59 - ADMIN_JAIL_FIRE_OFFSET_X, ADMIN_JAIL_POS_Y + 2.0 - ADMIN_JAIL_FIRE_OFFSET_Y, ADMIN_JAIL_POS_Z + 2.85 - ADMIN_JAIL_FIRE_OFFSET_Z, 0.0, 0.0, 0.0, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT, -1, 100.0, 100.0);
    objects[count++]=CreateDynamicObject(18688, ADMIN_JAIL_POS_X + 1.59 - ADMIN_JAIL_FIRE_OFFSET_X, ADMIN_JAIL_POS_Y + 5.6 - ADMIN_JAIL_FIRE_OFFSET_Y, ADMIN_JAIL_POS_Z + 2.85 - ADMIN_JAIL_FIRE_OFFSET_Z, 0.0, 0.0, 0.0, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT, -1, 100.0, 100.0);
	area = CreateDynamicCuboid(ADMIN_JAIL_POS_X - 7.4, ADMIN_JAIL_POS_Y - 10.4, ADMIN_JAIL_POS_Z - 0.5, ADMIN_JAIL_POS_X + 7.4, ADMIN_JAIL_POS_Y + 10.4, ADMIN_JAIL_POS_Z + 6.5, ADMIN_JAIL_WORLD, ADMIN_JAIL_POS_INT);

    new bool:valid=IsValidDynamicArea(area);
    for(new i; i<count; i++) if(!IsValidDynamicObject(objects[i])) valid=false;
    if(!valid) {
        for(new i; i<count; i++) if(IsValidDynamicObject(objects[i])) DestroyDynamicObject(objects[i]);
        if(IsValidDynamicArea(area)) DestroyDynamicArea(area);
        return 0;
    }
    }
    AdminJailRebuilding=true;
    for(new i; i<AdminJailObjectCount; i++) if(IsValidDynamicObject(AdminJailObjects[i])) DestroyDynamicObject(AdminJailObjects[i]);
    if(IsValidDynamicArea(ADM_JAIL_AREA)) DestroyDynamicArea(ADM_JAIL_AREA);
    AdminJailObjectCount=count; ADM_JAIL_AREA=area;
    for(new i; i<count; i++) AdminJailObjects[i]=objects[i];
    for(new i; i<6; i++) AdminJailApplied[i]=signature[i];
    AdminJailHasApplied=true;
    foreach(new playerid:Player) if(Character[playerid][E_CHARACTER_AJAIL_TIME]) { PauseAC(playerid,3); SetPlayerIntoAdminJail(playerid); }
    AdminJailRebuilding=false;
    return 1;
}

hook OnPlayerLeaveDynArea(playerid, STREAMER_TAG_AREA:areaid)
{
	if (!AdminJailRebuilding && areaid == ADM_JAIL_AREA && Character[playerid][E_CHARACTER_AJAIL_TIME])
	{
		new acstr[144];
		format(acstr, sizeof(acstr), "[AntiCheat]: (%d) %s may have warped out of admin jail.", playerid, ReturnRPName(playerid));
        SendAdminMessage(acstr);
	}

    return 1;
} 



///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

CMD:staffroom(playerid, params[]) return cmd_gotoadminroom(playerid, params);
CMD:adminroom(playerid, params[]) return cmd_gotoadminroom(playerid, params);

CMD:gotoadminroom(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	SetPlayerIntoAdminRoom(playerid);
	SendClientMessage(playerid, 0xA3A3A3FF, "You've been teleported to the admin meeting room.");

	return 1;
}

// Teleports a staff member into the admin meeting room.
SetPlayerIntoAdminRoom(playerid)
{
    if(!RuntimeLocations[RT_LOC_STAFF_ROOM][RLOC_ENABLED]) return SendClientMessage(playerid,COLOR_ERROR,"The staff room is not configured in the ACP.");
    SetPlayerInterior(playerid,RuntimeLocations[RT_LOC_STAFF_ROOM][RLOC_INTERIOR]);
    SetPlayerVirtualWorld(playerid,RuntimeLocations[RT_LOC_STAFF_ROOM][RLOC_WORLD]);
    ORP_SetPosWithFade(playerid,RuntimeLocations[RT_LOC_STAFF_ROOM][RLOC_X],RuntimeLocations[RT_LOC_STAFF_ROOM][RLOC_Y],RuntimeLocations[RT_LOC_STAFF_ROOM][RLOC_Z],"Meeting Room");
    SetPlayerFacingAngle(playerid,RuntimeLocations[RT_LOC_STAFF_ROOM][RLOC_ANGLE]);
    return 1;
}

// /gotoajail - (junior admin+) visit the admin jail without being jailed.
CMD:gotoajail(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	SetPlayerIntoAdminJail(playerid, true);
	SendClientMessage(playerid, 0xA3A3A3FF, "You've been teleported to the admin jail.");

	return 1;
}

// Puts a player into one of the admin jail cells (chosen by player id). visitor=true spawns them
// at the room entrance instead.
SetPlayerIntoAdminJail(playerid, bool:visitor = false)
{
    if(!RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_ENABLED]) return SendClientMessage(playerid,COLOR_ERROR,"Admin jail is not configured in the ACP.");
    // Everyone shares the dungeon; distribute prisoners among its six cells.
    new cell = playerid % sizeof(AdminJailCells);
    new Float:x = ADMIN_JAIL_POS_X + 0.0482, Float:y = ADMIN_JAIL_POS_Y + 8.5200;
    new Float:z = ADMIN_JAIL_POS_Z + 2.6172;
    new Float:angle = 175.0519;
    if (!visitor || Character[playerid][E_CHARACTER_AJAIL_TIME])
    {
        x = ADMIN_JAIL_POS_X + AdminJailCells[cell][0];
        y = ADMIN_JAIL_POS_Y + AdminJailCells[cell][1];
        z = ADMIN_JAIL_POS_Z + AdminJailCells[cell][2];
        angle = AdminJailCells[cell][3];
    }
    SetPlayerInterior(playerid, ADMIN_JAIL_POS_INT);
    SetPlayerVirtualWorld(playerid, ADMIN_JAIL_WORLD);
    SetPlayerWeather(playerid, 10);
    SetPlayerTime(playerid, 23, 0);
    AdminJailEnvironment[playerid] = true;
    ORP_SetPosWithFade(playerid, x, y, z, "Admin Dungeon");
    SetPlayerFacingAngle(playerid, angle);
    SetCameraBehindPlayer(playerid);
    return 1;
}

// True while the player still has admin jail time left. Admin-jailed players can't be hurt or
// killed, so two people sharing a cell can't fight each other to death.
IsPlayerInAdminJail(playerid)
{
	return Character [ playerid ] [ E_CHARACTER_AJAIL_TIME ] > 0 ;
}

// /ajail [player] [minutes] [reason] - sends an online player to admin jail; the time counts down
// in AdminJail_Tick.
CMD:ajail(playerid, params[])
{
    if(!RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_ENABLED]) return SendClientMessage(playerid,COLOR_ERROR,"Configure and enable admin jail in the ACP first.");
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new target, time, reason [ 64 ] ;

	if ( sscanf ( params, "k<player>is[64]", target, time, reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/ajail [target] [time (minutes)] [reason]" );
	}

	if ( ! IsPlayerConnected ( target ) ) {

		return SendServerMessage ( playerid, COLOR_RED, "Error", "A3A3A3", "Target isn't connected." ) ;
	}

	if ( time < 5 ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "Can't be less than 5 minutes." );
	}

	if ( strlen ( reason ) > 64 ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "Reason can't be longer than 64 characters." );
	}

	new string [ 256 ] ;
	SetPlayerIntoAdminJail(target);
	Character [ target ] [ E_CHARACTER_AJAIL_TIME ] = time * 60 ;

	format ( Character [ playerid ] [ E_CHARACTER_OAJAIL_REASON ], 256, "%s", reason ) ;
	format ( Character [ playerid ] [ E_CHARACTER_OAJAIL_ADMIN ], MAX_PLAYER_NAME, "%s", Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ]);

	string [ 0 ] = EOS ;
	mysql_format(mysql, string, sizeof ( string ), "UPDATE characters SET player_oajail_reason = '%e', player_oajail_admin = '%e', player_ajail_time = '%d' WHERE player_id = '%d'", 
		Character [ playerid ] [ E_CHARACTER_OAJAIL_REASON ], Character [ playerid ] [ E_CHARACTER_OAJAIL_ADMIN ], 
		Character [ target ] [ E_CHARACTER_AJAIL_TIME ], Character [ target ] [ E_CHARACTER_ID ] ) ;
	mysql_tquery ( mysql, string ) ;

	string [ 0 ] = EOS ;
	format ( string, sizeof ( string ), "[AdmCmd]: %s was admin jailed by %s for %d minutes. Reason: %s.", 
		ReturnRPName(target), Account[playerid][E_PLAYER_ACCOUNT_NAME], time, reason ) ;

	AddLogEntry(target, LOG_TYPE_ADMIN, sprintf("Ajailed for %d minutes by %s for %s", time, Account[playerid][E_PLAYER_ACCOUNT_NAME], reason));
	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Ajailed %s for %d minutes for %s", ReturnRPName(target), time, reason));

	Weapon_ResetPlayerWeapons(target);
	SendClientMessage(target, 0xA3A3A3FF, "Your weapons have been confiscated.");
	Weapon_SavePlayerWeapons(target);

	ZMsg_SendClientMessageToAll(COLOR_RED, string);
	DCC_SendAdminPunishmentMessage(string);

	SetAdminRecord ( Account [ target ] [ E_PLAYER_ACCOUNT_ID ], Character [ target ] [ E_CHARACTER_ID ], Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ], ARECORD_TYPE_AJAIL, reason, time, ReturnDateTime () ) ;
	


	return true ;
}

// /unajail [player] - releases a player from admin jail early.
CMD:unajail(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new target ;

	if ( sscanf ( params, "i", target ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/unajail [target]" );
	}

	new string [ 256 ] ;

	format ( string, sizeof ( string ), "[!!!] [AdmWarn] (%d) %s was released from admin jail by %s.", 
		target, ReturnRPName(target), Account[playerid][E_PLAYER_ACCOUNT_NAME]) ;
	DCC_SendAdminPunishmentMessage(string);


	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("released %s from admin jail", ReturnRPName(target)));
	SendClientMessage(playerid, COLOR_YELLOW, sprintf("%s has been released from admin jail.", ReturnRPName(target)));

	///////////////////////////////////////////////////////

	Character [ target ] [ E_CHARACTER_AJAIL_TIME ] = 0 ;

	SetPlayerPos(target, 1811.0447,-1577.7692,13.5267);
	PauseAC(target, 3);
	SetPlayerFacingAngle(target, 260.1323);

	SetPlayerInterior(target, 0);
	SetPlayerVirtualWorld(target, 0);
    AdminJailEnvironment[target] = false;
    Player_RefreshWeather(target);
    Player_RefreshTime(target);

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_ajail_time = 0 WHERE player_id = %d", 
		Character [ target ] [ E_CHARACTER_ID ] ) ;

	mysql_tquery(mysql, query);

	SendServerMessage ( target, COLOR_BLUE, "Arrest", "A3A3A3", "You've been released from captivity." ) ;

	return true ;
}

// /offlineajail [character name] [minutes] [reason] - admin-jails a character who is not online;
// takes effect when they next log in.
CMD:offlineajail(playerid, params[]) {
    if(!RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_ENABLED]) return SendClientMessage(playerid,COLOR_ERROR,"Configure and enable admin jail in the ACP first.");
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new charname [ MAX_PLAYER_NAME ], time, reason [ 64 ] ;

	if ( sscanf ( params, "s[24]is[64]", charname, time, reason ) ) {


		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/offlineajail [firstname_lastname] [minutes] [reason] (/getc)" );
	}


	if ( strlen ( charname ) > MAX_PLAYER_NAME ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Names can't be longer than 24 characters ") ;
	}

	if ( strlen ( reason ) > 64 ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Reason can't be longer than 64 characters!") ;
	}

	if ( time < 10 ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "You can't admin jail someone for less than 10 minutes.") ;
	}

	new old_time = time ;
	time *= 60 ; // i.e. time = 5 * 60 = 5 min

  	new query[300], char_id, acc_id, return_char_name[64], return_acc_name[64];

	foreach(new i: Player) {

		if ( IsPlayerLogged ( i ) && IsPlayerSpawned ( i ) ) {
			if ( ! strcmp(charname, Character [ i ] [ E_CHARACTER_NAME ] ) ) {

				format ( query, sizeof ( query ), "Player seems to be connected as ID %d. Use /ajail instead.", i ) ;
				return SendServerMessage( playerid, COLOR_YELLOW, "Warning", "A3A3A3",  query ) ;
			}
		}
	}

	query[0]=EOS;

	inline ReturnAccountName() {
		if (!cache_num_rows()) {
			return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Database didn't return any account data. Maybe your mistyped the name.") ;
		}

		cache_get_value_name_int( 0, "player_id", char_id);
		cache_get_value_name_int(0, "account_id", acc_id);
		cache_get_value_name(0, "player_name", return_char_name);
		cache_get_value_name(0, "account_name", return_acc_name);

		mysql_format(mysql, query, sizeof ( query ), "UPDATE characters SET player_oajail_reason = '%e', player_oajail_admin = '%e', player_ajail_time = '%d' WHERE player_id = '%d'", 
			reason, Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], time, char_id ) ;
		mysql_tquery ( mysql, query ) ;

		SetAdminRecord ( acc_id, char_id, Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ], ARECORD_TYPE_AJAIL, reason, time, ReturnDateTime () ) ;

		format ( query, sizeof ( query ), "[AdmCmd] %s (%s) was offline admin jailed by %s for %d minutes. Reason: %s.", 
			return_char_name, return_acc_name, Account[playerid][E_PLAYER_ACCOUNT_NAME], old_time, reason ) ;


		// AddOfflineLogEntry(char_id, return_char_name, LOG_TYPE_ADMIN, sprintf("Ajailed for %d minutes by %s for %s", old_time, Account[playerid][E_PLAYER_ACCOUNT_NAME], reason));
		AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Ajailed %s (%s) for %d minutes for %s", return_char_name, return_acc_name, old_time, reason));

		ZMsg_SendClientMessageToAll(COLOR_RED, query);
		DCC_SendAdminPunishmentMessage(query);
	}

	mysql_format ( mysql, query, sizeof ( query ), "SELECT `player_id`, `characters`.`account_id`, `player_name`, `account_name` FROM `characters` JOIN `accounts` ON `accounts`.`account_id` = `characters`.`account_id` WHERE `player_name` LIKE '%e'", charname ) ;
	MySQL_TQueryInline(mysql, using inline ReturnAccountName, query, "");

	return true ;
}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

// Every second
ptask AdminJail_Environment[1000](playerid) {
    if (IsPlayerInAdminDungeon(playerid))
    {
        SetPlayerWeather(playerid, 10);
        SetPlayerTime(playerid, 23, 0);
        AdminJailEnvironment[playerid] = true;
    }
    else if (AdminJailEnvironment[playerid])
    {
        AdminJailEnvironment[playerid] = false;
        Player_RefreshWeather(playerid);
        Player_RefreshTime(playerid);
    }


    return 1;
}

// Called every second for each player: counts down the admin jail time and releases the player
// when it reaches zero.
AdminJail_Tick(playerid) {
	if ( Character [ playerid ] [ E_CHARACTER_AJAIL_TIME ] ) {

		if ( -- Character [ playerid ] [ E_CHARACTER_AJAIL_TIME ] <= 0 ) {
			Character [ playerid ] [ E_CHARACTER_AJAIL_TIME ] = 0 ;

			SetPlayerPos(playerid, 1811.0447,-1577.7692,13.5267);
			PauseAC(playerid, 3);
			SetPlayerFacingAngle(playerid, 260.1323);

			SetPlayerInterior(playerid, 0);
			SetPlayerVirtualWorld(playerid, 0);
            AdminJailEnvironment[playerid] = false;
            Player_RefreshWeather(playerid);
            Player_RefreshTime(playerid);

			SendServerMessage ( playerid, COLOR_RED, "Admin", "A3A3A3", "You've been released from admin jail." ) ;
		}

		/*
		if ( ! IsPlayerInRangeOfPoint(playerid, 7.5, ADMIN_JAIL_POS_X, ADMIN_JAIL_POS_Y, ADMIN_JAIL_POS_Z) ) {

			SetPlayerPos(playerid, ADMIN_JAIL_POS_X, ADMIN_JAIL_POS_Y, ADMIN_JAIL_POS_Z ) ;
		}
		*/

		new string [ 64 ] ;

		format ( string, sizeof ( string ), "~w~~n~~n~~n~~n~~n~~n~Admin Jail: ~r~%s", GetCountdown(gettime(), gettime() + Character [ playerid ] [ E_CHARACTER_AJAIL_TIME ]) ) ;
		GameTextForPlayer(playerid, string, 950, 3 ) ;

		new query [ 256 ] ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_ajail_time = %d WHERE player_id = %d", 
			Character [ playerid ] [ E_CHARACTER_AJAIL_TIME ], Character [ playerid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);
	}

	return true ;
}


// Spawn handler used when a player logs in while admin-jailed: sets their spawn point to the
// admin jail.
Spawn_AdminJail(playerid, bool:isrespawn) 
{
	#pragma unused isrespawn
	SetSpawnInfo(playerid, 0, 264, 
		ADMIN_JAIL_POS_X, ADMIN_JAIL_POS_Y, ADMIN_JAIL_POS_Z, 0.0, 0, 0, 0, 0, 0, 0);

	CS_SpawnPlayer(playerid) ;

	SetCameraBehindPlayer(playerid);

	SetPlayerIntoAdminJail(playerid);
	SendServerMessage ( playerid, COLOR_YELLOW, "Admin Jail", "A3A3A3", "You've been returned to admin jail to serve your time." ) ;

	Weapon_ResetPlayerWeapons(playerid);
	SendClientMessage(playerid, 0xA3A3A3FF, "Your weapons have been confiscated.");
	Weapon_SavePlayerWeapons(playerid);	

	new string [ 144 ] ;
	format ( string, sizeof ( string ), "You were admin jailed for \"%s\" by %s.",

		Character [ playerid ] [ E_CHARACTER_OAJAIL_REASON ],
		Character [ playerid ] [ E_CHARACTER_OAJAIL_ADMIN ]	
	) ;

	SendServerMessage ( playerid, COLOR_RED, "Admin Jail", "A3A3A3", string ) ;

	// Must call this
	// Spawn_Common(playerid, isrespawn);
    return 1;
}
