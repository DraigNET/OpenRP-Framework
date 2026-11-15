// ============================================================================
// File: faction/spawnpoints.pwn
// Extra faction spawn points (stations, substations) leaders can add with /addfspawn, move with
// /movefspawn and delete with /delfspawn; players choose them at spawn.
// Commands: /fspawns /addfspawn /movefspawn /delfspawn
// ============================================================================

// ------------------------------------------------------------------------------
// Extra faction spawn points. The faction's main spawn (/fspawn, "Your Faction" in the spawn menu) is separate
// and unchanged. Faction leaders (tier 1) add up to MAX_FACTION_SPAWNS_PER of these for their own faction with
// /addfspawn while standing on the spot; staff can manage any faction's. Saved in `faction_spawns` (see
// the schema) and offered to members under "Faction Spawn Points" in the login spawn menu.

#define MAX_FACTION_SPAWNS      ( 64 )  // all factions together
#define FSPAWN_NAME_LEN         ( 32 )

enum {
	FSPAWN_REQ_ANY              // any member of the faction (add your own requirements here)
}

enum E_FACTION_SPAWNPOINT {
	E_FSP_SQLID,                // 0 = free slot, -1 = being saved
	E_FSP_FACTION_ID,           // factions.faction_id (E_FACTION_ID), not the Faction[] index
	E_FSP_NAME [ FSPAWN_NAME_LEN ],
	Float: E_FSP_X,
	Float: E_FSP_Y,
	Float: E_FSP_Z,
	Float: E_FSP_A,
	E_FSP_INT,
	E_FSP_VW,
	E_FSP_REQ
}

new FactionSpawnPoint [ MAX_FACTION_SPAWNS ] [ E_FACTION_SPAWNPOINT ] ;

// Loads the extra faction spawn points from the database.
FactionSpawns_Load() {

	for ( new i; i < MAX_FACTION_SPAWNS; i ++ ) {

		FactionSpawnPoint [ i ] [ E_FSP_SQLID ] = 0 ;
	}

	inline OnFactionSpawnsLoaded() {

		new loaded ;

		for ( new i = 0, r = cache_num_rows(); i < r && loaded < MAX_FACTION_SPAWNS; i ++ ) {

			cache_get_value_name_int ( i, "spawn_id", FactionSpawnPoint [ loaded ] [ E_FSP_SQLID ] ) ;
			cache_get_value_name_int ( i, "spawn_faction_id", FactionSpawnPoint [ loaded ] [ E_FSP_FACTION_ID ] ) ;
			cache_get_value_name ( i, "spawn_name", FactionSpawnPoint [ loaded ] [ E_FSP_NAME ], FSPAWN_NAME_LEN ) ;
			cache_get_value_name_float ( i, "spawn_x", FactionSpawnPoint [ loaded ] [ E_FSP_X ] ) ;
			cache_get_value_name_float ( i, "spawn_y", FactionSpawnPoint [ loaded ] [ E_FSP_Y ] ) ;
			cache_get_value_name_float ( i, "spawn_z", FactionSpawnPoint [ loaded ] [ E_FSP_Z ] ) ;
			cache_get_value_name_float ( i, "spawn_a", FactionSpawnPoint [ loaded ] [ E_FSP_A ] ) ;
			cache_get_value_name_int ( i, "spawn_int", FactionSpawnPoint [ loaded ] [ E_FSP_INT ] ) ;
			cache_get_value_name_int ( i, "spawn_vw", FactionSpawnPoint [ loaded ] [ E_FSP_VW ] ) ;
			cache_get_value_name_int ( i, "spawn_requirement", FactionSpawnPoint [ loaded ] [ E_FSP_REQ ] ) ;

			loaded ++ ;
		}

		printf(" * [FACTIONS] Loaded %d extra faction spawn points.", loaded ) ;
	}

	MySQL_TQueryInline(mysql, using inline OnFactionSpawnsLoaded, "SELECT * FROM faction_spawns ORDER BY spawn_id ASC", "" ) ;
	return true ;
}

// Counts how many extra spawn points a faction has.
static FactionSpawn_CountForFaction(faction_sql_id) {

	new count ;

	for ( new i; i < MAX_FACTION_SPAWNS; i ++ ) {

		if ( FactionSpawnPoint [ i ] [ E_FSP_SQLID ] != 0 && FactionSpawnPoint [ i ] [ E_FSP_FACTION_ID ] == faction_sql_id ) {

			count ++ ;
		}
	}

	return count ;
}

// Finds a spawn point by its database id.
static FactionSpawn_FindBySQL(spawn_sql_id) {

	for ( new i; i < MAX_FACTION_SPAWNS; i ++ ) {

		if ( FactionSpawnPoint [ i ] [ E_FSP_SQLID ] == spawn_sql_id && spawn_sql_id > 0 ) {

			return i ;
		}
	}

	return -1 ;
}

// Fills list[] with the pool indexes of the extra spawns this player may use. Returns how many.
FactionSpawn_GetForPlayer(playerid, list[], max = MAX_FACTION_SPAWNS_PER) {

	new count, factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		return 0 ;
	}

	for ( new i; i < MAX_FACTION_SPAWNS && count < max; i ++ ) {

		if ( FactionSpawnPoint [ i ] [ E_FSP_SQLID ] <= 0 || FactionSpawnPoint [ i ] [ E_FSP_FACTION_ID ] != factionid ) {

			continue ;
		}

		list [ count ++ ] = i ;
	}

	return count ;
}

// Who may manage this faction's spawns? Staff (any faction) or a tier 1 member of that faction.
static bool:FactionSpawn_CanManage(playerid, faction_sql_id) {

	if ( GetPlayerAdminLevel ( playerid ) >= ADMIN_LVL_JUNIOR ) {

		return true ;
	}

	return Character [ playerid ] [ E_CHARACTER_FACTIONID ] == faction_sql_id && Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] == 1 ;
}

// Works out which faction a command is for. Staff give a faction index first (see /factions); leaders always
// mean their own. Returns the Faction[] index, or INVALID_FACTION_ID after telling the player why not.
static FactionSpawn_ResolveFaction(playerid, const params[], &name_offset) {

	new faction_enum_id = INVALID_FACTION_ID ;
	name_offset = 0 ;

	if ( GetPlayerAdminLevel ( playerid ) >= ADMIN_LVL_JUNIOR ) {

		new index ;

		if ( sscanf ( params, "i", index ) || index < 0 || index >= MAX_FACTIONS || Faction [ index ] [ E_FACTION_ID ] == INVALID_FACTION_ID ) {

			SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Staff: give a valid faction index first (see /factions)." ) ;
			return INVALID_FACTION_ID ;
		}

		// skip past the number and the space after it
		while ( params [ name_offset ] && params [ name_offset ] != ' ' ) name_offset ++ ;
		while ( params [ name_offset ] == ' ' ) name_offset ++ ;

		return index ;
	}

	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!" ) ;
		return INVALID_FACTION_ID ;
	}

	if ( Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] != 1 ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Only the faction leader (tier 1) can manage spawn points." ) ;
		return INVALID_FACTION_ID ;
	}

	faction_enum_id = Faction_GetEnumID ( factionid ) ;

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV." ) ;
	}

	return faction_enum_id ;
}

// /fspawns - lists the extra spawn points of your faction.
CMD:fspawns(playerid, params[]) {

	new name_offset, faction_enum_id = FactionSpawn_ResolveFaction ( playerid, params, name_offset ) ;

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return true ;
	}

	new faction_sql_id = Faction [ faction_enum_id ] [ E_FACTION_ID ], count ;

	SendClientMessage ( playerid, COLOR_BLUE, sprintf("[%s] Extra spawn points (max %d). Your main spawn is set with /fspawn.", Faction [ faction_enum_id ] [ E_FACTION_ABBREV ], MAX_FACTION_SPAWNS_PER ) ) ;

	for ( new i; i < MAX_FACTION_SPAWNS; i ++ ) {

		if ( FactionSpawnPoint [ i ] [ E_FSP_SQLID ] <= 0 || FactionSpawnPoint [ i ] [ E_FSP_FACTION_ID ] != faction_sql_id ) {

			continue ;
		}

		new zone [ 64 ] ;
		GetCoords2DZone ( FactionSpawnPoint [ i ] [ E_FSP_X ], FactionSpawnPoint [ i ] [ E_FSP_Y ], zone, sizeof ( zone ) ) ;

		SendClientMessage ( playerid, 0xDEDEDEFF, sprintf("ID %d: %s (%s)", FactionSpawnPoint [ i ] [ E_FSP_SQLID ], FactionSpawnPoint [ i ] [ E_FSP_NAME ], zone ) ) ;
		count ++ ;
	}

	if ( ! count ) {

		SendClientMessage ( playerid, 0xDEDEDEFF, "None yet. Stand where you want it and use /addfspawn [name]." ) ;
	}

	return true ;
}

// /addfspawn [faction] [name] - adds a spawn point at your position (leaders).
CMD:addfspawn(playerid, params[]) {

	if ( IsPlayerIncapacitated ( playerid, false ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
	}

	new name_offset, faction_enum_id = FactionSpawn_ResolveFaction ( playerid, params, name_offset ) ;

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return true ;
	}

	new spawn_name [ FSPAWN_NAME_LEN ] ;

	if ( sscanf ( params [ name_offset ], "s[32]", spawn_name ) || strlen ( spawn_name ) < 3 ) {

		if ( GetPlayerAdminLevel ( playerid ) >= ADMIN_LVL_JUNIOR ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/addfspawn [faction index] [name] - stand where the spawn should be (name: 3-31 characters)" ) ;
		}

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/addfspawn [name] - stand where the spawn should be (name: 3-31 characters)" ) ;
	}

	if ( strfind ( spawn_name, "{" ) != -1 || strfind ( spawn_name, "}" ) != -1 || strfind ( spawn_name, "%" ) != -1 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "The name can't contain { } or % characters." ) ;
	}

	new faction_sql_id = Faction [ faction_enum_id ] [ E_FACTION_ID ] ;

	if ( FactionSpawn_CountForFaction ( faction_sql_id ) >= MAX_FACTION_SPAWNS_PER ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("A faction can only have %d extra spawn points. Remove one with /delfspawn first.", MAX_FACTION_SPAWNS_PER ) ) ;
	}

	new slot = -1 ;

	for ( new i; i < MAX_FACTION_SPAWNS; i ++ ) {

		if ( FactionSpawnPoint [ i ] [ E_FSP_SQLID ] == 0 ) {

			slot = i ;
			break ;
		}
	}

	if ( slot == -1 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "The server has run out of spawn point slots. Contact a DEV." ) ;
	}

	new Float: x, Float: y, Float: z, Float: a ;
	GetPlayerPos ( playerid, x, y, z ) ;
	GetPlayerFacingAngle ( playerid, a ) ;

	FactionSpawnPoint [ slot ] [ E_FSP_SQLID ] = -1 ;
	FactionSpawnPoint [ slot ] [ E_FSP_FACTION_ID ] = faction_sql_id ;
	FactionSpawnPoint [ slot ] [ E_FSP_NAME ] [ 0 ] = EOS ;
	strcat ( FactionSpawnPoint [ slot ] [ E_FSP_NAME ], spawn_name, FSPAWN_NAME_LEN ) ;
	FactionSpawnPoint [ slot ] [ E_FSP_X ] = x ;
	FactionSpawnPoint [ slot ] [ E_FSP_Y ] = y ;
	FactionSpawnPoint [ slot ] [ E_FSP_Z ] = z ;
	FactionSpawnPoint [ slot ] [ E_FSP_A ] = a ;
	FactionSpawnPoint [ slot ] [ E_FSP_INT ] = GetPlayerInterior ( playerid ) ;
	FactionSpawnPoint [ slot ] [ E_FSP_VW ] = GetPlayerVirtualWorld ( playerid ) ;
	FactionSpawnPoint [ slot ] [ E_FSP_REQ ] = FSPAWN_REQ_ANY ;

	new query [ 512 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "INSERT INTO faction_spawns (spawn_faction_id, spawn_name, spawn_x, spawn_y, spawn_z, spawn_a, spawn_int, spawn_vw, spawn_requirement) VALUES (%d, '%e', %f, %f, %f, %f, %d, %d, %d)",
		faction_sql_id, spawn_name, x, y, z, a, FactionSpawnPoint [ slot ] [ E_FSP_INT ], FactionSpawnPoint [ slot ] [ E_FSP_VW ], FSPAWN_REQ_ANY ) ;

	inline OnFactionSpawnAdded() {

		FactionSpawnPoint [ slot ] [ E_FSP_SQLID ] = cache_insert_id() ;
	}

	MySQL_TQueryInline(mysql, using inline OnFactionSpawnAdded, query, "" ) ;

	SendServerMessage ( playerid, COLOR_BLUE, "Faction", "A3A3A3", sprintf("Added spawn point \"%s\" for %s. Members will see it under Faction Spawn Points when they next log in.", spawn_name, Faction [ faction_enum_id ] [ E_FACTION_ABBREV ] ) ) ;

	SendAdminMessage ( sprintf("[!!!] [AdmWarn] (%d) %s added the %s spawn point \"%s\".", playerid, ReturnRPName ( playerid ), Faction [ faction_enum_id ] [ E_FACTION_ABBREV ], spawn_name ) ) ;

	return true ;
}

// /movefspawn [id] - moves a spawn point to your position.
CMD:movefspawn(playerid, params[]) {

	if ( IsPlayerIncapacitated ( playerid, false ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
	}

	new spawn_sql_id ;

	if ( sscanf ( params, "i", spawn_sql_id ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/movefspawn [id] - stand where it should go (ids are in /fspawns)" ) ;
	}

	new slot = FactionSpawn_FindBySQL ( spawn_sql_id ) ;

	if ( slot == -1 || ! FactionSpawn_CanManage ( playerid, FactionSpawnPoint [ slot ] [ E_FSP_FACTION_ID ] ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "No spawn point with that ID that you can manage. See /fspawns." ) ;
	}

	GetPlayerPos ( playerid, FactionSpawnPoint [ slot ] [ E_FSP_X ], FactionSpawnPoint [ slot ] [ E_FSP_Y ], FactionSpawnPoint [ slot ] [ E_FSP_Z ] ) ;
	GetPlayerFacingAngle ( playerid, FactionSpawnPoint [ slot ] [ E_FSP_A ] ) ;
	FactionSpawnPoint [ slot ] [ E_FSP_INT ] = GetPlayerInterior ( playerid ) ;
	FactionSpawnPoint [ slot ] [ E_FSP_VW ] = GetPlayerVirtualWorld ( playerid ) ;

	new query [ 384 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE faction_spawns SET spawn_x = %f, spawn_y = %f, spawn_z = %f, spawn_a = %f, spawn_int = %d, spawn_vw = %d WHERE spawn_id = %d",
		FactionSpawnPoint [ slot ] [ E_FSP_X ], FactionSpawnPoint [ slot ] [ E_FSP_Y ], FactionSpawnPoint [ slot ] [ E_FSP_Z ], FactionSpawnPoint [ slot ] [ E_FSP_A ],
		FactionSpawnPoint [ slot ] [ E_FSP_INT ], FactionSpawnPoint [ slot ] [ E_FSP_VW ], spawn_sql_id ) ;
	mysql_tquery ( mysql, query ) ;

	SendServerMessage ( playerid, COLOR_BLUE, "Faction", "A3A3A3", sprintf("Moved spawn point \"%s\" to where you're standing.", FactionSpawnPoint [ slot ] [ E_FSP_NAME ] ) ) ;

	SendAdminMessage ( sprintf("[!!!] [AdmWarn] (%d) %s moved faction spawn point %d (\"%s\").", playerid, ReturnRPName ( playerid ), spawn_sql_id, FactionSpawnPoint [ slot ] [ E_FSP_NAME ] ) ) ;

	return true ;
}

// /delfspawn [id] - deletes a spawn point.
CMD:delfspawn(playerid, params[]) {

	new spawn_sql_id ;

	if ( sscanf ( params, "i", spawn_sql_id ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/delfspawn [id] (ids are in /fspawns)" ) ;
	}

	new slot = FactionSpawn_FindBySQL ( spawn_sql_id ) ;

	if ( slot == -1 || ! FactionSpawn_CanManage ( playerid, FactionSpawnPoint [ slot ] [ E_FSP_FACTION_ID ] ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "No spawn point with that ID that you can manage. See /fspawns." ) ;
	}

	new query [ 96 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM faction_spawns WHERE spawn_id = %d", spawn_sql_id ) ;
	mysql_tquery ( mysql, query ) ;

	SendServerMessage ( playerid, COLOR_BLUE, "Faction", "A3A3A3", sprintf("Removed spawn point \"%s\".", FactionSpawnPoint [ slot ] [ E_FSP_NAME ] ) ) ;

	SendAdminMessage ( sprintf("[!!!] [AdmWarn] (%d) %s removed faction spawn point %d (\"%s\").", playerid, ReturnRPName ( playerid ), spawn_sql_id, FactionSpawnPoint [ slot ] [ E_FSP_NAME ] ) ) ;

	FactionSpawnPoint [ slot ] [ E_FSP_SQLID ] = 0 ;

	return true ;
}
