// ============================================================================
// File: config/server-native.pwn
// Wrapper functions that sit in front of SA-MP natives (ORP_SetPlayerPos,
// ORP_SetVehicleHealth, ORP_SetPosWithFade...) so the script can track and validate changes -
// for example for anti-cheat. Also contains geometry helpers (distances, angles, relative
// positions). Included LAST so it can wrap functions defined by other modules. ALWAYS use the
// ORP_ wrappers instead of the raw natives.
// ============================================================================

// All functions that have to be included "last".

// Returns how many properties (houses and businesses) a player owns.
GetPlayerPropertyCount(playerid)
{
	new properties = 0;

	foreach(new i: Properties)
	{
		if (Property[i][E_PROPERTY_ID] == INVALID_PROPERTY_ID) continue;
		if (Property[i][E_PROPERTY_OWNER] == Character[playerid][E_CHARACTER_ID] || Character[playerid][E_CHARACTER_RENTEDHOUSE] == Property[i][E_PROPERTY_ID])
		{
			properties ++;
		}
	}

	return properties;
}

// Spawns the player at their last saved position (falls back to the spawn menu if there isn't
// one).
static Spawn_LastPosition(playerid, bool:isrespawn)
{
	if ( ! Character [ playerid ] [ E_CHARACTER_LAST_POS_X ] || ! Character [ playerid ] [ E_CHARACTER_LAST_POS_Y ] || !  Character [ playerid ] [ E_CHARACTER_LAST_POS_Z ] ) {

		SendClientMessage(playerid, -1, "Can't find previous location, try a different spawn!");

		Player_LastSpawnPage [ playerid ] = 1 ;
		return SpawnArea_Selection(playerid) ;
	}

	if (!isrespawn)
	{
		SetSpawnInfo(playerid, 0, 264, Character [ playerid ] [ E_CHARACTER_LAST_POS_X ], Character [ playerid ] [ E_CHARACTER_LAST_POS_Y ], Character [ playerid ] [ E_CHARACTER_LAST_POS_Z ], Character [ playerid ] [ E_CHARACTER_LAST_POS_A ], 0, 0, 0, 0, 0, 0);
		CS_SpawnPlayer(playerid) ;

	}


	SetPlayerInterior ( playerid, Character [ playerid ] [ E_CHARACTER_LAST_POS_INT ] ) ;
	SetPlayerVirtualWorld ( playerid, Character [ playerid ] [ E_CHARACTER_LAST_POS_VW ] ) ;
	ORP_SetPosWithFade ( playerid,  Character [ playerid ] [ E_CHARACTER_LAST_POS_X ], Character [ playerid ] [ E_CHARACTER_LAST_POS_Y ], Character [ playerid ] [ E_CHARACTER_LAST_POS_Z ]);
	SetCameraBehindPlayer(playerid);

	
	// Must call this
	// Spawn_Common(playerid, isrespawn);
	return true;
}

// Spawns the player at their faction's main spawn point.
static Spawn_Faction(playerid, bool:isrespawn=false)
{
	new faction_enum_id = INVALID_FACTION_ID;
	if (Character [ playerid ] [ E_CHARACTER_FACTIONID ])
	{
		faction_enum_id = Faction_GetEnumID(Character [ playerid ] [ E_CHARACTER_FACTIONID ] ); 
	}
	
	if (faction_enum_id != INVALID_FACTION_ID) 
	{
		if (!isrespawn)
		{
			SetSpawnInfo(playerid, 0, 264, Faction [ faction_enum_id ] [ E_FACTION_SPAWN_X ], 
				Faction [ faction_enum_id ] [ E_FACTION_SPAWN_Y ], Faction [ faction_enum_id ] [ E_FACTION_SPAWN_Z ], Faction [ faction_enum_id ] [ E_FACTION_SPAWN_A ], 0, 0, 0, 0, 0, 0);
			CS_SpawnPlayer(playerid) ;
		}

		SetPlayerInterior ( playerid, Faction [ faction_enum_id ] [ E_FACTION_SPAWN_INT ] );
		SetPlayerVirtualWorld ( playerid, Faction [ faction_enum_id ] [ E_FACTION_SPAWN_VW ] );
		ORP_SetPosWithFade(playerid, Faction [ faction_enum_id ] [ E_FACTION_SPAWN_X ], Faction [ faction_enum_id ] [ E_FACTION_SPAWN_Y ], Faction [ faction_enum_id ] [ E_FACTION_SPAWN_Z ], Faction [ faction_enum_id ] [ E_FACTION_NAME ]);
		SetCameraBehindPlayer(playerid);

		// Must call this
		// Spawn_Common(playerid, isrespawn);
	}
	else 
	{
		Player_LastSpawnPage [ playerid ] = 1 ;
		SendClientMessage(playerid, COLOR_ERROR, "You're not in a faction. Pick a different spawn.");
		SpawnArea_Selection(playerid) ;
	}

	return true;
}

// Spawns the player at one specific faction spawn point (see faction/spawnpoints.pwn).
static Spawn_FactionPoint(playerid, fsp, bool:isrespawn=false)
{
    if (!isrespawn)
    {
        SetSpawnInfo(playerid, 0, 264,
            FactionSpawnPoint[fsp][E_FSP_X], FactionSpawnPoint[fsp][E_FSP_Y], FactionSpawnPoint[fsp][E_FSP_Z], FactionSpawnPoint[fsp][E_FSP_A],
            0, 0, 0, 0, 0, 0);

        CS_SpawnPlayer(playerid);
    }

    SetPlayerInterior(playerid, FactionSpawnPoint[fsp][E_FSP_INT]);
    SetPlayerVirtualWorld(playerid, FactionSpawnPoint[fsp][E_FSP_VW]);

    ORP_SetPosWithFade(playerid,
        FactionSpawnPoint[fsp][E_FSP_X], FactionSpawnPoint[fsp][E_FSP_Y], FactionSpawnPoint[fsp][E_FSP_Z],
        FactionSpawnPoint[fsp][E_FSP_NAME]);

    SetCameraBehindPlayer(playerid);

    return true;
}

// Shows the faction spawn point list (extra stations) and spawns the player at the one they
// choose.
static Spawn_FactionPoints(playerid, bool:isrespawn=false)
{
    new list[MAX_FACTION_SPAWNS_PER];
    new count = FactionSpawn_GetForPlayer(playerid, list);

    if (count == 0)
    {
        Player_LastSpawnPage [ playerid ] = 1 ;
        SendClientMessage(playerid, COLOR_ERROR, "Your faction has no spawn points you can use. Pick a different spawn.");
        SpawnArea_Selection(playerid);
        return true;
    }

    new zone[64], dlg[512];
    format(dlg, sizeof(dlg), "Name\tArea");

    for (new i = 0; i < count; i ++)
    {
        zone[0] = EOS;
        GetCoords2DZone(FactionSpawnPoint[list[i]][E_FSP_X], FactionSpawnPoint[list[i]][E_FSP_Y], zone, sizeof(zone));
        format(dlg, sizeof(dlg), "%s\n%s\t%s", dlg, FactionSpawnPoint[list[i]][E_FSP_NAME], zone);
    }

    inline DlgFactionPointSpawn(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, inputtext

        if (!response)
        {
            return Player_DisplaySpawnList(playerid, isrespawn);
        }

        // The list is rebuilt from the same data; make sure the spawn is still there before using it.
        new fsp = list[listitem];

        if (FactionSpawnPoint[fsp][E_FSP_SQLID] <= 0)
        {
            SendClientMessage(playerid, COLOR_ERROR, "That spawn point was removed. Pick a different spawn.");
            return Player_DisplaySpawnList(playerid, isrespawn);
        }

        Spawn_FactionPoint(playerid, fsp, isrespawn);
        return true;
    }

    Dialog_ShowCallback(playerid, using inline DlgFactionPointSpawn, DIALOG_STYLE_TABLIST_HEADERS, "Faction Spawn Points", dlg, "Select", "Back");
    return true;
}

// Spawns a new character at the starter spawn area.
Spawn_Newbie(playerid, bool:isrespawn)
{
	Player_LastSpawnPage [ playerid ] = 1 ;

	if (isrespawn)
	{
		SpawnArea_SelectionEx(playerid);
		return true;
	}

	SpawnArea_Selection(playerid);
	return true;
}

static PropertyDlgStr[4096];

// Shows the list of properties the player can spawn at (owned and rented).
static Spawn_Properties(playerid, bool:isrespawn=false)
{
	// Make a list of properties to spawn at
	new address[64], zone[64], count = 0, map[50];
	format(PropertyDlgStr, sizeof(PropertyDlgStr), "Type\tAddress");

	foreach(new i: Properties)
	{
		if (Property[i][E_PROPERTY_ID] == INVALID_PROPERTY_ID) continue;
		if (Property[i][E_PROPERTY_OWNER] == Character[playerid][E_CHARACTER_ID] || Character[playerid][E_CHARACTER_RENTEDHOUSE] == Property[i][E_PROPERTY_ID]) 
		{
			address[0] = EOS, zone[0] = EOS;
			GetCoords2DZone(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
			GetPlayerAddress(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], address );

			if (Property[i][E_PROPERTY_TYPE] == E_PROPERTY_TYPE_BIZ) format(PropertyDlgStr, sizeof(PropertyDlgStr), "%s\n{4FC3F7}Business\t%d %s, %s", PropertyDlgStr, i, address, zone, Property[i][E_PROPERTY_ID]);
			else if (Character[playerid][E_CHARACTER_RENTEDHOUSE] == Property[i][E_PROPERTY_ID]) format(PropertyDlgStr, sizeof(PropertyDlgStr), "%s\n{DCE775}Residence\t%d %s, %s", PropertyDlgStr, i, address, zone, Property[i][E_PROPERTY_ID]);
			else if (Property[i][E_PROPERTY_TYPE] == E_PROPERTY_TYPE_HOUSE) format(PropertyDlgStr, sizeof(PropertyDlgStr), "%s\n{AED581}Residence\t%d %s, %s", PropertyDlgStr, i, address, zone, Property[i][E_PROPERTY_ID]);
			else format(PropertyDlgStr, sizeof(PropertyDlgStr), "%s\nStatic\t%d %s, %s (SQL: %d)", PropertyDlgStr, i, address, zone, Property[i][E_PROPERTY_ID]);
			
			map[count] = i;
			count ++;
		}
	}

	if (count == 0)
	{
		// Something went badly wrong
		Player_LastSpawnPage [ playerid ] = 1 ;
		SendClientMessage(playerid, COLOR_ERROR, "You don't have any properties. Pick a different spawn.");
		SpawnArea_Selection(playerid);
		return true;
	}

	inline DlgPropertySpawn(pid, dialogid, response, listitem, string:inputtext[]) 
	{ 
		#pragma unused pid, dialogid, response, listitem, inputtext

		if (!response) 
		{
			// Take them back to the main list
			return Player_DisplaySpawnList(pid, isrespawn);
		}

		new chosen = map[listitem];
		Spawn_Property(playerid, chosen, isrespawn);
		return true;
	}

	Dialog_ShowCallback ( playerid, using inline DlgPropertySpawn, DIALOG_STYLE_TABLIST_HEADERS, "Spawn Property", PropertyDlgStr, "Select", "Back" ) ;
	return true;
}

// Spawns the player at one of their properties.
static Spawn_Property(playerid, property_enum_id, bool:isrespawn=false)
{
	// new property_enum_id = Property_LinkSQLToEnum(Character [ playerid ] [ E_CHARACTER_PROPERTYSPAWN ]) ;

	if ( property_enum_id == -1 ) 
	{
		SendClientMessage(playerid, -1, "You haven't set which property you'd like to spawn at. Please choose a different spawn!");

		Player_LastSpawnPage [ playerid ] = 1 ;
		return SpawnArea_Selection(playerid) ;
	}

	if (!isrespawn)
	{
		SetSpawnInfo(playerid, 0, 264, Property [ property_enum_id ] [ E_PROPERTY_INT_X ],  Property [ property_enum_id ] [ E_PROPERTY_INT_Y ], Property [ property_enum_id ] [ E_PROPERTY_INT_Z ], Character [ playerid ] [ E_CHARACTER_LAST_POS_A ], 0, 0, 0, 0, 0, 0);
		CS_SpawnPlayer(playerid) ;
	}

	SetCameraBehindPlayer(playerid);
	SetPlayerInterior ( playerid, Property [ property_enum_id ] [ E_PROPERTY_INT_INT ] ) ;
	SetPlayerVirtualWorld ( playerid, Property [ property_enum_id ] [ E_PROPERTY_INT_VW ] ) ;
	ORP_SetPosWithFade (playerid, Property [ property_enum_id ] [ E_PROPERTY_INT_X ],  Property [ property_enum_id ] [ E_PROPERTY_INT_Y ], Property [ property_enum_id ] [ E_PROPERTY_INT_Z ], FormatPropertyName(property_enum_id));

	SetPlayerWeather(playerid, Property [ property_enum_id ] [ E_PROPERTY_INT_WEATHER ]);

	if(Property [ property_enum_id ] [ E_PROPERTY_INT_HOURS ] == -1)
	{
		SetPlayerTime(playerid, Server [ E_SERVER_TIME_HOURS], Server [ E_SERVER_TIME_MINUTES]);
	} else {
		SetPlayerTime(playerid, Property [ property_enum_id ] [ E_PROPERTY_INT_HOURS ], Property [ property_enum_id ] [ E_PROPERTY_INT_MINS ]);
	}
	
	if(Property [ property_enum_id ] [ E_PROPERTY_INT_AUDIO_ON ])
	{
		if (strlen(Property [ property_enum_id ] [ E_PROPERTY_INT_AUDIOURL ]))
		{
			ORP_PlayAudioStreamForPlayer ( playerid, Property [ property_enum_id ] [ E_PROPERTY_INT_AUDIOURL ], Property [ property_enum_id ] [ E_PROPERTY_INT_AUDIOX ], Property [ property_enum_id ] [ E_PROPERTY_INT_AUDIOY ], Property [ property_enum_id ] [ E_PROPERTY_INT_AUDIOZ ], 50.0, true );
		}
	}
	
	//SendClientMessage(playerid, -1, "You've spawned inside the selected property!");
	// Streamer_Update(playerid, STREAMER_TYPE_PICKUP);

	// Must call this
	// Spawn_Common(playerid, isrespawn);
		
	return true;
}

// Applies the spawn menu choice (last position, property, faction, newbie spawn, admin jail...)
// and then finishes spawning.
PlayerSpawnSelection(playerid, listitem, bool:isrespawn=false ) 
{
	if ( !Character [ playerid ] [ E_CHARACTER_GYM_SETUP ] ) 
	{
		Gym_SetupDefaultVariables(playerid);
	}
	
	// So basically, they can spawn at:
	// 0. Last Location
	// 1. Faction Spawn
	// 2. Property Spawns
	// 3. Newcomer Spawns

	// But, if they are arrested/ajailed we override the spawn selection regardless.

	if (Character [ playerid ] [ E_CHARACTER_AJAIL_TIME ])
	{
		Spawn_AdminJail(playerid, isrespawn);
		return true;
	}

	if ( Character [ playerid ] [ E_CHARACTER_ARREST_TIME ]) 
	{
		Spawn_ArrestJail(playerid, isrespawn);
		return true;
	}

	new option = PlayerSpawnOptions[playerid][listitem];

	if (option == PLAYER_SPAWN_TYPE_LAST) Spawn_LastPosition(playerid,isrespawn);
	else if (option == PLAYER_SPAWN_TYPE_FACTIONPT) Spawn_FactionPoints(playerid, isrespawn);
	else if (option == PLAYER_SPAWN_TYPE_FACTION) Spawn_Faction(playerid,isrespawn);
	else if (option == PLAYER_SPAWN_TYPE_PROPERTY) Spawn_Properties(playerid,isrespawn);
	else
	{
		Spawn_Newbie(playerid, isrespawn);
	} 

	return true ;
}


// Returns true if the player is alive on the map (on foot, driving, passenger or just spawned).
IsPlayerSpawned(playerid) {

	switch (GetPlayerState(playerid)) {
		case PLAYER_STATE_ONFOOT .. PLAYER_STATE_PASSENGER,
		     PLAYER_STATE_SPAWNED: {
			return true;
		}
	}

	return false;
}


// Wrapper for SetObjectRot / SetDynamicObjectRot that logs why the rotation changed. `streamer`
// selects the streamer object type.
ORP_SetObjectRot(objectid, Float: x, Float: y, Float: z, const reason[], streamer) {
	#pragma unused reason

	/*
	if ( streamer ) {

		printf("SetDynamicObjectRot: [%s] Rotated object ID %d with model %d to x %0.2f, y %0.2f, z, %0.2f. Reason: %s",
			reason, objectid, GetDynamicObjectModel(objectid), x, y, z, reason ) ;

		SetDynamicObjectRot(objectid, x, y, z);
	}

	else if ( ! streamer ) {

		printf("SetObjectRot: [%s] Rotated object ID %d with model %d to x %0.2f, y %0.2f, z, %0.2f. Reason: %s",
			reason, objectid, GetObjectModel(objectid), x, y, z, reason ) ;

		SetObjectRot(objectid, x, y, z);	
	}*/

	if ( streamer ) {

		if ( IsValidDynamicObject(objectid) ) {

			SetDynamicObjectRot(objectid, x, y, z);
		}
	}

	else {

		SetObjectRot(objectid, x, y, z);
	}
}



// Wrapper for destroying an object (normal or streamer) that can log the reason.
ORP_DestroyObject(objectid, const reason[], streamer, warn=false) {

	if ( streamer ) {
		if(warn) {
			printf("DestroyDynamicObject: [%s] Destroyed object ID %d with model %d, reason %s", 
				reason, objectid, GetDynamicObjectModel(objectid), reason);
		}

		if ( IsValidDynamicObject(objectid) ) {
			DestroyDynamicObject(objectid);
		}
	}

	else if ( ! streamer ) {
		if(warn) {
			printf("DestroyObject: [%s] Destroyed object ID %d with model %d, reason %s", 
				reason, objectid, GetObjectModel(objectid), reason);
		}
		DestroyObject(objectid);
	}
}

// You need to call this with a SAMP gunid.
ORP_SetPlayerAmmo(playerid, gunid, amount) {

	new slot = GetWeaponSlot ( gunid ) ;

	PlayerVar [ playerid ] [ E_PLAYER_AMMO_SYNCED ] [ slot ] =  amount ;

	return SetPlayerAmmo(playerid, gunid, amount);
}

// Returns the player's real ammo for their current weapon, using the server-synced value when
// available.
ORP_GetPlayerAmmo(playerid) {

	new ammo = PlayerVar [ playerid ] [ E_PLAYER_AMMO_SYNCED ] [ GetWeaponSlot ( GetPlayerWeapon ( playerid ) ) ] ;

	if ( ammo == 0 ) {

		ammo = GetPlayerAmmo(playerid);
	}

	return ammo ;
	//return GetPlayerAmmo(playerid);
}

// Teleports a player with a screen fade, resets streaming, and tells the anti-cheat the move is
// legitimate. Always use this instead of SetPlayerPos.
ORP_SetPlayerPos(playerid, Float: x, Float: y, Float: z, freeze=true ) {

    BlackScreen(playerid);

	new vw = GetPlayerVirtualWorld(playerid);
	new int = GetPlayerInterior(playerid);

	Streamer_UpdateEx(playerid, x, y, z, vw, int, STREAMER_TYPE_OBJECT);
	PauseAC(playerid, 5);
	SetPlayerPos(playerid, x, y, z);
	//Streamer_UpdateEx(playerid, x, y, z, vw, int, STREAMER_TYPE_OBJECT);

	FadeIn ( playerid, freeze );	
	Boombox_SyncForPlayer( playerid ) ;

	// defer DoStreamerUpdate(playerid, x, y, z, vw, int);

	return true ;
}

/*timer DoStreamerUpdate[250](playerid, Float:x, Float:y, Float:z, vw, int)
{	
	Streamer_UpdateEx(playerid, x, y, z, vw, int, STREAMER_TYPE_OBJECT);
}*/

// Teleports a vehicle (and its driver) with a fade and anti-cheat notice. Use instead of
// SetVehiclePos.
ORP_SetVehiclePos(playerid, vehicleid, Float: x, Float: y, Float: z ) {

	if ( GetPlayerVehicleID ( playerid ) == vehicleid && GetPlayerVehicleSeat(playerid) == 0 ) {

		BlackScreen(playerid);

		Streamer_UpdateEx(playerid, x, y, z, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid), STREAMER_TYPE_OBJECT);
		SetVehiclePos(vehicleid, x, y, z ) ;
		JT_PutPlayerInVehicle(playerid, vehicleid, 0);

		new vw = GetPlayerVirtualWorld(playerid);
		new int = GetPlayerInterior(playerid);

		Streamer_UpdateEx(playerid, x, y, z, vw, int, STREAMER_TYPE_OBJECT);

		FadeIn ( playerid );
	}
}

#include <YSI_Coding\y_hooks>
new Float:g_AwaitingPos[MAX_PLAYERS][3];
new g_AwaitingPosTime[MAX_PLAYERS];
// Fades the screen to black, teleports the player to x,y,z and fades back in, optionally showing
// a location text.
stock ORP_SetPosWithFade(playerid, Float:x, Float:y, Float:z, const text[]="")
{
    g_AwaitingPos[playerid][0] = x;
    g_AwaitingPos[playerid][1] = y;
    g_AwaitingPos[playerid][2] = z;
	g_AwaitingPosTime[playerid] = gettime();

	BlackScreen(playerid);
	Streamer_UpdateEx(playerid, x, y, z, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid), STREAMER_TYPE_OBJECT);
    TogglePlayerControllable(playerid, false);
	PauseAC(playerid, 3);
    SetPlayerPos(playerid, x, y, z - 0.3);

	if (strlen(text) > 1) UpdateZone(playerid, text);
	else UpdateZone(playerid, "", true, x, y);
	
    return 1;
}

hook OnPlayerUpdate(playerid)
{
    if (g_AwaitingPosTime[playerid])
	{
        if ((GetPlayerDistanceFromPoint(playerid, g_AwaitingPos[playerid][0], g_AwaitingPos[playerid][1], g_AwaitingPos[playerid][2]) < 0.2) || (gettime() - g_AwaitingPosTime[playerid]) >= 3) 
		{
            //TogglePlayerControllable(playerid, true);
			g_AwaitingPosTime[playerid] = 0;
            g_AwaitingPos[playerid][0] = 0.0;

			//Streamer_UpdateEx(playerid, g_AwaitingPos[playerid][0], g_AwaitingPos[playerid][1], g_AwaitingPos[playerid][2], GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid), STREAMER_TYPE_OBJECT);
			SetCameraBehindPlayer(playerid);
			FadeIn(playerid, true);	
        }
	}

    return 1;
}

hook OnPlayerConnect(playerid)
{
    g_AwaitingPos[playerid][0] = 0.0;
	g_AwaitingPosTime[playerid] = 0;
    return 1;
}

// Returns true if the player is currently listening to an audio stream (boombox, property
// audio...).
IsPlayerListeningToAudioStream(playerid) {

	if ( ! IsPlayerSpawned ( playerid ) || ! IsPlayerLogged ( playerid ) ) {

		return true ;
	}

	if ( PlayerVar [ playerid ] [ E_PLAYER_AUDIO_STREAM ] ) {

		return true ;
	}

	else return false ;
}

ORP_PlayAudioStreamForPlayer ( playerid, const url [], Float:posX = 0.0, Float:posY = 0.0, Float:posZ = 0.0, Float:distance = 50.0, usepos = 0 ) {

	if ( IsPlayerListeningToAudioStream(playerid) ) {

		ORP_StopAudioStreamForPlayer(playerid);
	}

	PlayerVar [ playerid ] [ E_PLAYER_AUDIO_STREAM ] = true ;

	PlayAudioStreamForPlayer(playerid, url, posX, posY, posZ, distance, usepos);
}

ORP_StopAudioStreamForPlayer ( playerid ) {

	PlayerVar [ playerid ] [ E_PLAYER_AUDIO_STREAM ] = false ;
	StopAudioStreamForPlayer(playerid);
}


// Creates a vehicle and checks the engine returned a valid id. Use instead of CreateVehicle.
ORP_CreateVehicle(vehicletype, Float:x, Float:y, Float:z, Float:rotation, vw, int, color1, color2, respawn_delay, bool:addsiren=false) 
{
    new vehicleid = CreateVehicle(vehicletype, x, y, z, rotation, color1, color2, respawn_delay, addsiren);

	if (vehicleid <= 0 || vehicleid >= MAX_VEHICLES)
	{
		printf("VEH ERROR: ORP_CreateVehicle with type %d, got back an invalid Vehicle ID (%)", vehicletype, vehicleid);
		return INVALID_VEHICLE_ID;
	}

	RemoveVehicleTurnSignals(vehicleid, EI_TURN_SIGNAL_BOTH);
	ORP_SetVehicleHealth(vehicleid, 999);
	Gunrack_Reset(vehicleid);
	SetVehicleVirtualWorld(vehicleid, vw);
	LinkVehicleToInterior(vehicleid, int);

    return vehicleid ;
}

// Allows or forbids a vehicle from exploding. Only the chop shop may allow it.
ORP_SetVehicleCanExplode(vehicleid, bool:explode) 
{
	VehicleVar[vehicleid][E_VEHICLE_CAN_EXPLODE] = explode;
}


// Sets vehicle health, capped at 999 so it never explodes unexpectedly.
ORP_SetVehicleHealth(vehicleid, Float:health) {

	new Float: fixed_health = health;

	if ( health >= 999 ) {

		fixed_health = 999 ;
	}

	return SetVehicleHealth(vehicleid, fixed_health ) ;
}

// Adds a static vehicle (with colours and respawn delay) at full health.
stock ORP_AddStaticVehicleEx(modelid, Float:spawn_x, Float:spawn_y, Float:spawn_z, Float:z_angle, color1, color2, respawn_delay, addsiren=0) {

	new vid = AddStaticVehicleEx(vehicletype, x, y, z, rotation, color1, color2, respawn_delay);
	SetVehicleHealth(vid, 999);
	return vid;
}

// Adds a static vehicle at full health.
stock ORP_AddStaticVehicle(modelid, Float:spawn_x, Float:spawn_y, Float:spawn_z, Float:z_angle, color1, color2) {
	new vid = AddStaticVehicle(modelid, spawn_x, spawn_y, spawn_z, z_angle, color1, color2);
	SetVehicleHealth(vid, 999);
	return vid;
}


// Fully repairs a vehicle (body, health and damage status).
ORP_RepairVehicle(vehicleid) {

	RepairVehicle(vehicleid);
	ORP_SetVehicleHealth(vehicleid, 999);
	UpdateVehicleDamageStatus(vehicleid, 0, 0, 0, 0);

	return true ;
}
// Gets a position relative to an object (offset in front/side/above its rotation).
stock GetDynObjRelativePos(objectid, &Float:x, &Float:y, &Float:z, Float:xoff=0.0, Float:yoff=0.0, Float:zoff=0.0)
{
    new Float:rx, Float:ry, Float:rz;
    GetDynamicObjectRot(objectid, rx, ry, rz);
    rz = 360 - rz;    // Making the vehicle rotation compatible with pawns sin/cos
    GetDynamicObjectPos(objectid, x, y, z);
    x = floatsin(rz,degrees) * yoff + floatcos(rz,degrees) * xoff + x;
    y = floatcos(rz,degrees) * yoff - floatsin(rz,degrees) * xoff + y;
    z = zoff + z;

    /*
       where xoff/yoff/zoff are the offsets relative to the vehicle
       x/y/z then are the coordinates of the point with the given offset to the vehicle
       xoff = 1.0 would e.g. point to the right side of the vehicle, -1.0 to the left, etc.
    */
}

// Gets a position relative to a player's facing direction.
stock GetPlayerRelativePos(playerid, &Float:x, &Float:y, &Float:z, Float:xoff=0.0, Float:yoff=0.0, Float:zoff=0.0)
{
    new Float:rot;
    GetPlayerFacingAngle(playerid, rot);
    rot = 360 - rot;    // Making the ped rotation compatible with pawns sin/cos
    GetPlayerPos(playerid, x, y, z);
    x = floatsin(rot,degrees) * yoff + floatcos(rot,degrees) * xoff + x;
    y = floatcos(rot,degrees) * yoff - floatsin(rot,degrees) * xoff + y;
    z = zoff + z;

    /*
       where xoff/yoff/zoff are the offsets relative to the vehicle
       x/y/z then are the coordinates of the point with the given offset to the vehicle
       xoff = 1.0 would e.g. point to the right side of the vehicle, -1.0 to the left, etc.
    */
}

// Returns the 2D distance from a player to a point.
stock Float:GetPlayerDistanceToPoint2D(playerid, Float:x, Float:y) {
	new Float:x2, Float:y2;

	if (GetPlayerPos(playerid, x2, y2, Float:playerid)) {
		return VectorSize(x - x2, y - y2, 0);
	}

	return FLOAT_NAN;
}

// Returns the distance between two points (2D if the second point has no Z).
stock Float:GetPointDistanceToPoint(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2 = FLOAT_NAN, Float:z2 = FLOAT_NAN) {
	if (_:y2 == _:FLOAT_NAN) {
		return VectorSize(x1 - z1, y1 - x2, 0.0);
	}

	return VectorSize(x1 - x2, y1 - y2, z1 - z2);
}

// Returns the heading angle (0-360) from point 1 to point 2.
stock Float:GetAngleBetweenPoints(Float:X1,Float:Y1,Float:X2,Float:Y2)
{
	new Float:angle=atan2(X2-X1,Y2-Y1);
	if(angle>360)angle-=360;
	if(angle<0)angle+=360;
	return angle;
}

// Returns the up/down angle from point 1 to point 2.
stock Float:GetUpAngleBetweenPoints(Float:X1,Float:Y1,Float:Z1,Float:X2,Float:Y2,Float:Z2)
{
	new Float:angle=atan2(Z2 - Z1, GetPointDistanceToPoint(X2, Y2, X1, Y1));
	if(angle>360)angle-=360;
	if(angle<0)angle+=360;
	return angle;
}

// Shows a short message at the bottom of the player's screen for `time` milliseconds.
stock ShowPlayerFooter(playerid, const message[], time=4000)
{
    CallLocalFunction("ORP_ShowPlayerSubtitle", "dsd", playerid, message, time);
	return 1;
}

// Hides the footer message.
stock HidePlayerFooter(playerid)
{
    HidePlayerSubtitle(playerid);
    //CallRemoteFunction("HidePlayerMessageText", "d", playerid);
}

// Returns true if the player is in the metro training area (interior 7, world 6003).
IsPlayerInMetroTraining(playerid)
{
    return GetPlayerInterior(playerid) == 7 && GetPlayerVirtualWorld(playerid) == 6003;
}

// Returns true if the player is in the SEB training area (interior 7, world 6004).
IsPlayerInSEBTraining(playerid)
{
    return GetPlayerInterior(playerid) == 7 && GetPlayerVirtualWorld(playerid) == 6004;
}
