// ============================================================================
// File: vehicle/modules/repairrefuel.pwn
// Repair and refuel points (/rprf) for specific vehicle types, managed in game with /rprfadmin
// and stored in the `rprf_points` table.
// Commands: /rprf /rprfadmin
// ============================================================================

// Repair & refuel points (/rprf). The points live in the `rprf_points` table and are managed in game with
// /rprfadmin (lead admin and above), nothing is hard-coded any more.
//
//   type 1 dockworker   only Dockworker vehicles (model 530)
//   type 2 airport      only aircraft
//   type 3 boat         only boats
//   type 4 faction      only vehicles of the faction type in "faction type" (0 law enforcement, 3 EMS,
//                       8 public works, 10 federal ... see the FACTION_TYPE_ defines), used by members
//
// /rprf repairs the body, refuels to full and does a full service (oil, engine, fuel tank).

// Defined in oil.pwn, which is included after this file.
forward Vehicle_FullService(veh_enum_id);

#define MAX_RPRF_POINTS             (48)
#define INVALID_RPRF_ID             (-1)

enum E_RPRF_DATA {

	E_RPRF_SQLID,
	E_RPRF_DESC [ 64 ],
	Float: E_RPRF_POS_X,
	Float: E_RPRF_POS_Y,
	Float: E_RPRF_POS_Z,
	E_RPRF_TYPE,
	E_RPRF_FACTION_TYPE,
	bool:E_RPRF_HIDDEN,
	E_RPRF_PICKUP,
	DynamicText3D: E_RPRF_LABEL
} ;


enum { // RPRF_TYPES

	E_RPRF_TYPE_NONE = -1,
	E_RPRF_TYPE_DOCKWORKER = 1,
	E_RPRF_TYPE_AIRPORT,
	E_RPRF_TYPE_BOAT,
	E_RPRF_TYPE_FACTION,
} ;

new RPRF_Points [ MAX_RPRF_POINTS ] [ E_RPRF_DATA ] ;

// Writes the name of a repair/refuel point type.
RPRF_GetTypeName(type, name[], len = sizeof ( name )) {

	switch ( type ) {

		case E_RPRF_TYPE_DOCKWORKER: 	format ( name, len, "dockworker" ) ;
		case E_RPRF_TYPE_AIRPORT: 		format ( name, len, "airport" ) ;
		case E_RPRF_TYPE_BOAT: 			format ( name, len, "boat" ) ;
		case E_RPRF_TYPE_FACTION: 		format ( name, len, "faction" ) ;
		default: 						format ( name, len, "unknown" ) ;
	}

	return true ;
}

// Finds a repair/refuel point by SQL id.
RPRF_GetBySqlId(sqlid) {

	if ( sqlid <= 0 ) {

		return INVALID_RPRF_ID ;
	}

	for ( new i; i < MAX_RPRF_POINTS; i ++ ) {

		if ( RPRF_Points [ i ] [ E_RPRF_SQLID ] == sqlid ) {

			return i ;
		}
	}

	return INVALID_RPRF_ID ;
}

// Destroys the visuals of a repair/refuel point.
RPRF_DestroyVisuals(index) {

	if ( IsValidDynamicPickup ( RPRF_Points [ index ] [ E_RPRF_PICKUP ] ) ) {

		DestroyDynamicPickup ( RPRF_Points [ index ] [ E_RPRF_PICKUP ] ) ;
	}

	if ( IsValidDynamic3DTextLabel ( RPRF_Points [ index ] [ E_RPRF_LABEL ] ) ) {

		DestroyDynamic3DTextLabel ( RPRF_Points [ index ] [ E_RPRF_LABEL ] ) ;
	}

	RPRF_Points [ index ] [ E_RPRF_PICKUP ] = INVALID_STREAMER_ID ;
	RPRF_Points [ index ] [ E_RPRF_LABEL ] = DynamicText3D: INVALID_STREAMER_ID ;

	return true ;
}

// Creates the visuals of a repair/refuel point.
RPRF_CreateVisuals(index) {

	RPRF_DestroyVisuals ( index ) ;

	new text [ 128 ] ;

	format ( text, sizeof ( text ), "[%s]\n{DEDEDE}Available commands: /rprf", RPRF_Points [ index ] [ E_RPRF_DESC ] ) ;

	if ( RPRF_Points [ index ] [ E_RPRF_HIDDEN ] ) {

		// Smaller draw distance
		RPRF_Points [ index ] [ E_RPRF_PICKUP ] = CreateDynamicPickup ( 1370, 1, RPRF_Points [ index ] [ E_RPRF_POS_X ], RPRF_Points [ index ] [ E_RPRF_POS_Y ], RPRF_Points [ index ] [ E_RPRF_POS_Z ], -1, -1, -1, 7.5 ) ;
		RPRF_Points [ index ] [ E_RPRF_LABEL ] = CreateDynamic3DTextLabel ( text, COLOR_FACTION, RPRF_Points [ index ] [ E_RPRF_POS_X ], RPRF_Points [ index ] [ E_RPRF_POS_Y ], RPRF_Points [ index ] [ E_RPRF_POS_Z ], 7.5, .testlos = true ) ;
	}

	else {

		RPRF_Points [ index ] [ E_RPRF_PICKUP ] = CreateDynamicPickup ( 1370, 1, RPRF_Points [ index ] [ E_RPRF_POS_X ], RPRF_Points [ index ] [ E_RPRF_POS_Y ], RPRF_Points [ index ] [ E_RPRF_POS_Z ], -1, -1, -1, 50.0 ) ;
		RPRF_Points [ index ] [ E_RPRF_LABEL ] = CreateDynamic3DTextLabel ( text, COLOR_FACTION, RPRF_Points [ index ] [ E_RPRF_POS_X ], RPRF_Points [ index ] [ E_RPRF_POS_Y ], RPRF_Points [ index ] [ E_RPRF_POS_Z ], 10.0, .testlos = true ) ;
	}

	return true ;
}

// Clears a repair/refuel point.
RPRF_ClearEntity(index) {

	new blank [ E_RPRF_DATA ] ;

	RPRF_Points [ index ] = blank ;
	RPRF_Points [ index ] [ E_RPRF_PICKUP ] = INVALID_STREAMER_ID ;
	RPRF_Points [ index ] [ E_RPRF_LABEL ] = DynamicText3D: INVALID_STREAMER_ID ;
	RPRF_Points [ index ] [ E_RPRF_FACTION_TYPE ] = -1 ;

	return true ;
}

// Loads the repair/refuel points from the database.
RPRF_LoadEntities() {

	for ( new i; i < MAX_RPRF_POINTS; i ++ ) {

		RPRF_DestroyVisuals ( i ) ;
		RPRF_ClearEntity ( i ) ;
	}

	print ( " * [RPRF] Loading repair & refuel points..." ) ;

	inline RPRF_OnDataLoad() {

		new loaded ;

		for ( new i = 0, r = cache_num_rows(); i < r && i < MAX_RPRF_POINTS; i ++ ) {

			new hidden ;

			cache_get_value_name_int ( i, "rprf_id", RPRF_Points [ i ] [ E_RPRF_SQLID ] ) ;
			cache_get_value_name ( i, "rprf_desc", RPRF_Points [ i ] [ E_RPRF_DESC ], 64 ) ;
			cache_get_value_name_float ( i, "rprf_pos_x", RPRF_Points [ i ] [ E_RPRF_POS_X ] ) ;
			cache_get_value_name_float ( i, "rprf_pos_y", RPRF_Points [ i ] [ E_RPRF_POS_Y ] ) ;
			cache_get_value_name_float ( i, "rprf_pos_z", RPRF_Points [ i ] [ E_RPRF_POS_Z ] ) ;
			cache_get_value_name_int ( i, "rprf_type", RPRF_Points [ i ] [ E_RPRF_TYPE ] ) ;
			cache_get_value_name_int ( i, "rprf_faction_type", RPRF_Points [ i ] [ E_RPRF_FACTION_TYPE ] ) ;
			cache_get_value_name_int ( i, "rprf_hidden", hidden ) ;

			RPRF_Points [ i ] [ E_RPRF_HIDDEN ] = ( hidden != 0 ) ;

			RPRF_CreateVisuals ( i ) ;
			loaded ++ ;
		}

		printf ( " * [RPRF] Loaded %d repair & refuel points.", loaded ) ;
	}

	MySQL_TQueryInline ( mysql, using inline RPRF_OnDataLoad, "SELECT * FROM rprf_points ORDER BY rprf_id ASC", "" ) ;

	return true ;
}

// /rprf - uses a repair or refuel point.
CMD:rprf(playerid, params[]) {
	new near_rprf = -1 ;

	for ( new i; i < MAX_RPRF_POINTS; i ++ ) {

		if ( RPRF_Points [ i ] [ E_RPRF_SQLID ] <= 0 ) {

			continue ;
		}

		if ( IsPlayerInRangeOfPoint(playerid, 15.0, RPRF_Points [ i ] [ E_RPRF_POS_X ],
			RPRF_Points [ i ] [ E_RPRF_POS_Y ], RPRF_Points [ i ] [ E_RPRF_POS_Z ] ) ) {

			near_rprf = i ;
		}
	}

	if ( near_rprf != -1) {

		new vehicleid = GetPlayerVehicleID(playerid) ;

		if ( ! IsPlayerInAnyVehicle(playerid) || ! vehicleid ) {
			return SendServerMessage(playerid, COLOR_ERROR, "Repair & Refuel", "DEDEDE", "You're not in a vehicle!" ) ;
		}

		if ( IsPlayerIncapacitated(playerid, false) ) {
			return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
		}

		new type = RPRF_Points [ near_rprf ] [ E_RPRF_TYPE ] ;
		new ftype = RPRF_Points [ near_rprf ] [ E_RPRF_FACTION_TYPE ] ;

		if ( type != -1 )
		{
			switch ( type )
			{
				case E_RPRF_TYPE_BOAT:
				{
					if ( ! IsABoat ( vehicleid ) )
					{
						return SendServerMessage(playerid, COLOR_ERROR, "Repair & Refuel", "DEDEDE", "You're not in the right vehicle type - only boats!" ) ;
					}
				}
				case E_RPRF_TYPE_DOCKWORKER:
				{
					if ( GetVehicleModel ( vehicleid ) != 530 )
					{
						return SendServerMessage(playerid, COLOR_ERROR, "Repair & Refuel", "DEDEDE", "You're not in the right vehicle type - only Dockworker vehicles!" ) ;
					}
				}
				case E_RPRF_TYPE_AIRPORT:
				{
					if ( ! IsAircraft(vehicleid) )
					{
				    	return SendServerMessage ( playerid, COLOR_ERROR, "Repair & Refuel", "A3A3A3", "You're not in the right vehicle type - only aircraft!" ) ;
					}
				}
				case E_RPRF_TYPE_FACTION:
				{
					if (!IsPlayerInFactionType(playerid, ftype)) return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in the correct faction type to use this.");
					if (!IsFactionTypeVehicle(vehicleid, ftype)) return SendServerMessage(playerid, COLOR_ERROR, "Repair & Refuel", "DEDEDE", "You can only repair faction vehicles here.");
				}
			}


			ORP_RepairVehicle(vehicleid) ;

	        new query [ 128 ] ;

			new veh_enum_id = Vehicle_GetEnumID(vehicleid) ;
	        Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] = 100 ;

	        // Repair everything: oil service reset, engine rebuilt and the tank drained and refilled clean.
	        Vehicle_FullService ( veh_enum_id ) ;

	        mysql_format(mysql, query, sizeof ( query), "UPDATE vehicles SET vehicle_fuel = %d WHERE vehicle_sqlid = %d",
	            Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] );

	        mysql_tquery(mysql, query);

			ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**", "has repaired, serviced and refueled their vehicle.", .annonated=true);
		}
	}

	return true ;
}

// ---------------------------------------------------------------------------------------------
// /rprfadmin
// ---------------------------------------------------------------------------------------------

// Shows /rprfadmin usage.
static RPRF_AdminUsage(playerid) {

	SendClientMessage ( playerid, COLOR_GRAD0, "/rprfadmin [list / create / delete / move / rename / hidden / goto]" ) ;
	SendClientMessage ( playerid, COLOR_GRAD0, "create [type] [faction type] [description] (at your position) | delete [id] | move [id] | rename [id] [description]" ) ;
	SendClientMessage ( playerid, COLOR_GRAD0, "hidden [id] [0/1] (hidden points only show up close by) | goto [id]" ) ;
	SendClientMessage ( playerid, COLOR_INFO, "Types: 1 dockworker, 2 airport (aircraft), 3 boat, 4 faction." ) ;
	SendClientMessage ( playerid, COLOR_INFO, "Faction type only matters for type 4 (use 0 otherwise): 0 law enforcement, 3 EMS, 8 public works, 10 federal." ) ;

	return true ;
}

// /rprfadmin - (admin) manages the repair/refuel points.
CMD:rprfadmin(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_LEAD ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command." ) ;
	}

	new sub [ 16 ], rest [ 96 ] ;

	if ( sscanf ( params, "s[16]S()[96]", sub, rest ) ) {

		return RPRF_AdminUsage ( playerid ) ;
	}

	if ( ! strcmp ( sub, "list", true ) ) {

		new count, type_name [ 16 ] ;

		SendClientMessage ( playerid, COLOR_INFO, "[ID] Description | type | faction type | hidden" ) ;

		for ( new i; i < MAX_RPRF_POINTS; i ++ ) {

			if ( RPRF_Points [ i ] [ E_RPRF_SQLID ] <= 0 ) {

				continue ;
			}

			RPRF_GetTypeName ( RPRF_Points [ i ] [ E_RPRF_TYPE ], type_name, sizeof ( type_name ) ) ;

			SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "[%d] %s | %s | %d | %s", RPRF_Points [ i ] [ E_RPRF_SQLID ], RPRF_Points [ i ] [ E_RPRF_DESC ], type_name,
				RPRF_Points [ i ] [ E_RPRF_FACTION_TYPE ], RPRF_Points [ i ] [ E_RPRF_HIDDEN ] ? ( "yes" ) : ( "no" ) ) ) ;

			count ++ ;
		}

		if ( ! count ) {

			SendClientMessage ( playerid, COLOR_GRAD0, "There are no repair & refuel points. Use /rprfadmin create." ) ;
		}

		return true ;
	}

	if ( ! strcmp ( sub, "create", true ) ) {

		new type, ftype, desc [ 64 ] ;

		if ( sscanf ( rest, "iis[64]", type, ftype, desc ) || type < E_RPRF_TYPE_DOCKWORKER || type > E_RPRF_TYPE_FACTION || strlen ( desc ) < 3 || strfind ( desc, "{", true ) != -1 ) {

			return SendClientMessage ( playerid, COLOR_GRAD0, "/rprfadmin create [type 1-4] [faction type (0 if not a faction point)] [description, at least 3 characters]" ) ;
		}

		if ( type != E_RPRF_TYPE_FACTION ) {

			ftype = -1 ;
		}

		new index = -1 ;

		for ( new i; i < MAX_RPRF_POINTS; i ++ ) {

			if ( RPRF_Points [ i ] [ E_RPRF_SQLID ] == 0 ) {

				index = i ;
				break ;
			}
		}

		if ( index == -1 ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "RPRF", "A3A3A3", sprintf ( "The limit of %d points has been reached.", MAX_RPRF_POINTS ) ) ;
		}

		new Float: x, Float: y, Float: z, query [ 384 ] ;

		GetPlayerPos ( playerid, x, y, z ) ;

		// Reserve the slot until the insert comes back.
		RPRF_ClearEntity ( index ) ;
		RPRF_Points [ index ] [ E_RPRF_SQLID ] = -1 ;

		mysql_format ( mysql, query, sizeof ( query ),
			"INSERT INTO rprf_points (rprf_desc, rprf_pos_x, rprf_pos_y, rprf_pos_z, rprf_type, rprf_faction_type, rprf_hidden) VALUES ('%e', '%f', '%f', '%f', %d, %d, 0)",
			desc, x, y, z, type, ftype ) ;

		inline RPRF_OnCreate() {

			new sqlid = cache_insert_id () ;

			if ( sqlid <= 0 ) {

				RPRF_Points [ index ] [ E_RPRF_SQLID ] = 0 ;
				return SendServerMessage ( playerid, COLOR_ERROR, "RPRF", "A3A3A3", "The point couldn't be saved. Is the rprf_points table there?" ) ;
			}

			RPRF_Points [ index ] [ E_RPRF_SQLID ] = sqlid ;
			RPRF_Points [ index ] [ E_RPRF_DESC ] [ 0 ] = EOS ;
			strcat ( RPRF_Points [ index ] [ E_RPRF_DESC ], desc, 64 ) ;
			RPRF_Points [ index ] [ E_RPRF_POS_X ] = x ;
			RPRF_Points [ index ] [ E_RPRF_POS_Y ] = y ;
			RPRF_Points [ index ] [ E_RPRF_POS_Z ] = z ;
			RPRF_Points [ index ] [ E_RPRF_TYPE ] = type ;
			RPRF_Points [ index ] [ E_RPRF_FACTION_TYPE ] = ftype ;
			RPRF_Points [ index ] [ E_RPRF_HIDDEN ] = false ;

			RPRF_CreateVisuals ( index ) ;

			AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Created repair & refuel point %d (%s)", sqlid, desc ) ) ;

			return SendServerMessage ( playerid, COLOR_BLUE, "RPRF", "A3A3A3", sprintf ( "Created repair & refuel point %d (%s) here.", sqlid, desc ) ) ;
		}

		MySQL_TQueryInline ( mysql, using inline RPRF_OnCreate, query, "" ) ;

		return true ;
	}

	// Everything else starts with a point id.
	new sqlid, extra [ 64 ] ;

	if ( sscanf ( rest, "iS()[64]", sqlid, extra ) ) {

		return RPRF_AdminUsage ( playerid ) ;
	}

	new index = RPRF_GetBySqlId ( sqlid ) ;

	if ( index == INVALID_RPRF_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "RPRF", "A3A3A3", "That isn't a valid point id. Use /rprfadmin list." ) ;
	}

	new query [ 256 ] ;

	if ( ! strcmp ( sub, "delete", true ) ) {

		mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM rprf_points WHERE rprf_id = %d", sqlid ) ;
		mysql_tquery ( mysql, query ) ;

		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Deleted repair & refuel point %d (%s)", sqlid, RPRF_Points [ index ] [ E_RPRF_DESC ] ) ) ;
		SendServerMessage ( playerid, COLOR_BLUE, "RPRF", "A3A3A3", sprintf ( "Deleted repair & refuel point %d (%s).", sqlid, RPRF_Points [ index ] [ E_RPRF_DESC ] ) ) ;

		RPRF_DestroyVisuals ( index ) ;
		RPRF_ClearEntity ( index ) ;

		return true ;
	}

	if ( ! strcmp ( sub, "move", true ) ) {

		new Float: x, Float: y, Float: z ;

		GetPlayerPos ( playerid, x, y, z ) ;

		RPRF_Points [ index ] [ E_RPRF_POS_X ] = x ;
		RPRF_Points [ index ] [ E_RPRF_POS_Y ] = y ;
		RPRF_Points [ index ] [ E_RPRF_POS_Z ] = z ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE rprf_points SET rprf_pos_x = '%f', rprf_pos_y = '%f', rprf_pos_z = '%f' WHERE rprf_id = %d", x, y, z, sqlid ) ;
		mysql_tquery ( mysql, query ) ;

		RPRF_CreateVisuals ( index ) ;

		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Moved repair & refuel point %d (%s)", sqlid, RPRF_Points [ index ] [ E_RPRF_DESC ] ) ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "RPRF", "A3A3A3", "The point has been moved to your position." ) ;
	}

	if ( ! strcmp ( sub, "rename", true ) ) {

		if ( strlen ( extra ) < 3 || strfind ( extra, "{", true ) != -1 ) {

			return SendClientMessage ( playerid, COLOR_GRAD0, "/rprfadmin rename [id] [description, at least 3 characters, no colour codes]" ) ;
		}

		RPRF_Points [ index ] [ E_RPRF_DESC ] [ 0 ] = EOS ;
		strcat ( RPRF_Points [ index ] [ E_RPRF_DESC ], extra, 64 ) ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE rprf_points SET rprf_desc = '%e' WHERE rprf_id = %d", RPRF_Points [ index ] [ E_RPRF_DESC ], sqlid ) ;
		mysql_tquery ( mysql, query ) ;

		RPRF_CreateVisuals ( index ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "RPRF", "A3A3A3", sprintf ( "Point %d is now called %s.", sqlid, extra ) ) ;
	}

	if ( ! strcmp ( sub, "hidden", true ) ) {

		new flag ;

		if ( sscanf ( extra, "i", flag ) || flag < 0 || flag > 1 ) {

			return SendClientMessage ( playerid, COLOR_GRAD0, "/rprfadmin hidden [id] [0/1]" ) ;
		}

		RPRF_Points [ index ] [ E_RPRF_HIDDEN ] = ( flag == 1 ) ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE rprf_points SET rprf_hidden = %d WHERE rprf_id = %d", flag, sqlid ) ;
		mysql_tquery ( mysql, query ) ;

		RPRF_CreateVisuals ( index ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "RPRF", "A3A3A3", sprintf ( "Point %d is now %s.", sqlid, flag ? ( "hidden (only visible up close)" ) : ( "visible from a distance" ) ) ) ;
	}

	if ( ! strcmp ( sub, "goto", true ) ) {

		PauseAC ( playerid, 3 ) ;
		SetPlayerPos ( playerid, RPRF_Points [ index ] [ E_RPRF_POS_X ], RPRF_Points [ index ] [ E_RPRF_POS_Y ], RPRF_Points [ index ] [ E_RPRF_POS_Z ] ) ;
		SetPlayerInterior ( playerid, 0 ) ;
		SetPlayerVirtualWorld ( playerid, 0 ) ;

		return true ;
	}

	return RPRF_AdminUsage ( playerid ) ;
}
