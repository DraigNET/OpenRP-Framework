// ============================================================================
// File: vehicle/modules/carscrap.pwn
// Scrapyards: /carscrap sells a vehicle for parts (cars, boats and planes go to different
// yards), with pooled cars bought later by used-car firms. /deletecar for staff.
// Commands: /carscrap /deletecar
// ============================================================================

#define SCRAPYARD_POS_X (0.0) // TODO: set coordinates for your map
#define SCRAPYARD_POS_Y (0.0) // TODO: set coordinates for your map
#define SCRAPYARD_POS_Z (0.0) // TODO: set coordinates for your map

#define SCRAPYARD_BOAT_POS_X (0.0) // TODO: set coordinates for your map
#define SCRAPYARD_BOAT_POS_Y (0.0) // TODO: set coordinates for your map
#define SCRAPYARD_BOAT_POS_Z (0.0) // TODO: set coordinates for your map

#define SCRAPYARD_AIR_POS_X (0.0) // TODO: set coordinates for your map
#define SCRAPYARD_AIR_POS_Y (0.0) // TODO: set coordinates for your map
#define SCRAPYARD_AIR_POS_Z (0.0) // TODO: set coordinates for your map

#define SCRAPYARD_PICKUP_MODEL 851
#define SCRAPYARD_MAP_ICON	37

// Loads the scrap yard points.
ScrapYard_LoadEntities() {

	print(" * [SCRAPYARD] Loaded vehicle scrapyards (land, boat, air).") ;

	CreateDynamic3DTextLabel("[Vehicle Scrap Location]\n{DEDEDE}Available commands: /carscrap",
		COLOR_BLUE, SCRAPYARD_POS_X, SCRAPYARD_POS_Y, SCRAPYARD_POS_Z, 15.0 
	);

	CreateDynamicPickup(SCRAPYARD_PICKUP_MODEL, 1,  SCRAPYARD_POS_X, SCRAPYARD_POS_Y, SCRAPYARD_POS_Z ) ;
	CreateDynamicMapIcon(SCRAPYARD_POS_X, SCRAPYARD_POS_Y, SCRAPYARD_POS_Z, SCRAPYARD_MAP_ICON, 0 );


	CreateDynamic3DTextLabel("[Boat Scrap Location]\n{DEDEDE}Available commands: /carscrap",
		COLOR_BLUE, SCRAPYARD_BOAT_POS_X, SCRAPYARD_BOAT_POS_Y, SCRAPYARD_BOAT_POS_Z, 15.0 
	);

	CreateDynamicPickup(SCRAPYARD_PICKUP_MODEL, 1,  SCRAPYARD_BOAT_POS_X, SCRAPYARD_BOAT_POS_Y, SCRAPYARD_BOAT_POS_Z ) ;
	CreateDynamicMapIcon(SCRAPYARD_BOAT_POS_X, SCRAPYARD_BOAT_POS_Y, SCRAPYARD_BOAT_POS_Z, SCRAPYARD_MAP_ICON, 0 );


	CreateDynamic3DTextLabel("[Airplane Scrap Location]\n{DEDEDE}Available commands: /carscrap",
		COLOR_BLUE, SCRAPYARD_AIR_POS_X, SCRAPYARD_AIR_POS_Y, SCRAPYARD_AIR_POS_Z, 15.0 
	);

	CreateDynamicPickup(SCRAPYARD_PICKUP_MODEL, 1,  SCRAPYARD_AIR_POS_X, SCRAPYARD_AIR_POS_Y, SCRAPYARD_AIR_POS_Z ) ;
	CreateDynamicMapIcon(SCRAPYARD_AIR_POS_X, SCRAPYARD_AIR_POS_Y, SCRAPYARD_AIR_POS_Z, SCRAPYARD_MAP_ICON, 0 );


	return true ;
}

#define SCRAPYARD_TYPE_LAND		(0)
#define SCRAPYARD_TYPE_BOAT		(1)
#define SCRAPYARD_TYPE_AIR		(2)

// Which scrapyard takes a vehicle model (the same split /carscrap uses by vehicle).
Vehicle_GetYardForModel(modelid) {

	switch ( modelid ) {

		case 430, 446, 452, 453, 454, 472, 473, 484, 493, 595: return SCRAPYARD_TYPE_BOAT ;
		case 460, 464, 476, 511, 512, 513, 519, 520, 553, 577, 592, 593: return SCRAPYARD_TYPE_AIR ;
		case 417, 425, 447, 465, 469, 487, 488, 497, 501, 548, 563: return SCRAPYARD_TYPE_AIR ;
	}

	return SCRAPYARD_TYPE_LAND ;
}

// Which scrapyard the player is standing at (within a few steps), or -1.
ScrapYard_GetNearby(playerid) {

	if ( IsPlayerInRangeOfPoint ( playerid, 10.0, SCRAPYARD_POS_X, SCRAPYARD_POS_Y, SCRAPYARD_POS_Z ) ) return SCRAPYARD_TYPE_LAND ;
	if ( IsPlayerInRangeOfPoint ( playerid, 10.0, SCRAPYARD_BOAT_POS_X, SCRAPYARD_BOAT_POS_Y, SCRAPYARD_BOAT_POS_Z ) ) return SCRAPYARD_TYPE_BOAT ;
	if ( IsPlayerInRangeOfPoint ( playerid, 10.0, SCRAPYARD_AIR_POS_X, SCRAPYARD_AIR_POS_Y, SCRAPYARD_AIR_POS_Z ) ) return SCRAPYARD_TYPE_AIR ;

	return -1 ;
}

// A scrapped car that is waiting in the pool for a used car firm to buy it. Pooled cars stay in the
// vehicles table as dormant player vehicles with owner 0, so nothing in the game spawns them.
bool: Vehicle_IsPooled(veh_enum_id) {

	return veh_enum_id >= 0 && veh_enum_id < MAX_VEHICLES
		&& Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] != -1
		&& Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_PLAYER
		&& Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] == 0
		&& Vehicle [ veh_enum_id ] [ E_VEHICLE_POOLED_AT ] > 0 ;
}

// True when nothing is stored in the trunk (weapons, drugs, burglary loot), so scrapping a car can't
// hand that stash to whoever buys it from the pool.
bool: Vehicle_IsTrunkEmpty(veh_enum_id) {

	for ( new i; i < 10; i ++ ) {

		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TRUNK_WEP ] [ i ] || Vehicle [ veh_enum_id ] [ E_VEHICLE_TRUNK_AMMO ] [ i ]
			|| Vehicle [ veh_enum_id ] [ E_VEHICLE_TRUNK_DRUGS_TYPE ] [ i ] || Vehicle [ veh_enum_id ] [ E_VEHICLE_TRUNK_BURGLARY_MODEL ] [ i ] ) {

			return false ;
		}
	}

	return true ;
}

// Spare keys to a car stop working when it changes hands.
Vehicle_WipeKeys(sqlid) {

	foreach ( new userid : Player ) {

		for ( new i = 0; i < 2; i ++ ) {

			if ( Character [ userid ] [ E_CHARACTER_VEH_KEYS ] [ i ] == sqlid ) {

				Character [ userid ] [ E_CHARACTER_VEH_KEYS ] [ i ] = -1 ;
			}
		}
	}

	new query [ 128 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM character_vehicle_keys WHERE vehicle_sqlid = %d", sqlid ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// What the scrapyard pays for a car: a share of its new price that falls with mileage (see
// mileage.pwn). Models no dealership sells get a small random amount, as before.
Vehicle_GetScrapValue(veh_enum_id) {

	new value = Vehicle_GetTradeInValue ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ) ;

	if ( value <= 0 ) {

		value = 150 + random ( 450 ) ;
	}

	return value ;
}

// Takes a scrapped car out of the game and puts it in the pool. The vehicle row (colours, tuning,
// mileage, damage, plate) is kept so a used car firm gets the car exactly as it was scrapped.
Vehicle_MoveToPool(veh_enum_id, value) {

	new sqlid = Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ;

	Vehicle_WipeKeys ( sqlid ) ;
	Vehicle_DestroyLabel ( veh_enum_id ) ;

	if ( IsValidVehicle ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ) ) {

		ORP_DestroyVehicle ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], "carscrap" ) ;
	}

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] = INVALID_VEHICLE_ID ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_IS_SPAWNED ] = false ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] = E_VEHICLE_TYPE_PLAYER ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POOLED_AT ] = gettime () ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POOL_VALUE ] = value ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE ] = false ;

	new query [ 640 ] ;

	mysql_format ( mysql, query, sizeof ( query ),
		"UPDATE vehicles SET vehicle_type = 3, vehicle_owner = 0, vehicle_pooled_at = %d, vehicle_pool_value = %d, vehicle_sale_price = 0, vehicle_mileage = %d, vehicle_fuel = %d, vehicle_health = '%f', vehicle_dmg_panels = %d, vehicle_dmg_doors = %d, vehicle_dmg_lights = %d, vehicle_dmg_tires = %d WHERE vehicle_sqlid = %d",
		Vehicle [ veh_enum_id ] [ E_VEHICLE_POOLED_AT ], value, Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ], Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ], Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ],
		Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_PANELS ], Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_DOORS ], Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_LIGHTS ], Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_TIRES ],
		sqlid ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// Spawns (or respawns) a vehicle record at a position the way /carspawn does. respawn_delay -1 means
// it stays where it is parked. Returns the new vehicle id, or INVALID_VEHICLE_ID if it couldn't spawn.
Vehicle_SpawnRecord(veh_enum_id, Float: x, Float: y, Float: z, Float: a, vw, interior, respawn_delay = -1) {

	if ( IsValidVehicle ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ) ) {

		ORP_DestroyVehicle ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], "spawnrecord" ) ;
	}

	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_X ] = x ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Y ] = y ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Z ] = z ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_A ] = a ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_VW ] = vw ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_INT ] = interior ;

	new vehicleid = ORP_CreateVehicle ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ], x, y, z, a, vw, interior,
		Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_A ], Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_B ], respawn_delay ) ;

	if ( ! IsValidVehicle ( vehicleid ) ) {

		Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] = INVALID_VEHICLE_ID ;
		return INVALID_VEHICLE_ID ;
	}

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] = vehicleid ;
	Temp_SetVehicleEnumId ( vehicleid, veh_enum_id ) ;

	if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ] <= 250.0 ) {

		ORP_SetVehicleHealth ( vehicleid, 300 ) ;
	}

	else ORP_SetVehicleHealth ( vehicleid, Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ] ) ;

	SetVehicleNumberPlate ( vehicleid, Vehicle [ veh_enum_id ] [ E_VEHICLE_LICENSE ] ) ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_IS_SPAWNED ] = true ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ] = true ;

	Vehicle_SetDoorsEngineStatus ( veh_enum_id ) ;
	ChangeVehiclePaintjob ( vehicleid, Vehicle [ veh_enum_id ] [ E_VEHICLE_PAINTJOB ] ) ;
	Tune_ApplyComponents ( veh_enum_id ) ;
	Vehicle_ClearRuntimeVariables ( veh_enum_id ) ;
	Vehicle_ClearTruckerVariables ( veh_enum_id ) ;
	Scanner_Reset ( vehicleid ) ;

	UpdateVehicleDamageStatus ( vehicleid, Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_PANELS ], Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_DOORS ],
		Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_LIGHTS ], Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_TIRES ] ) ;


	return vehicleid ;
}

// /carscrap - scraps a vehicle at the scrap yard for money.
CMD:carscrap(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }
    
    if ( IsABoat ( GetPlayerVehicleID ( playerid ) ) ) {

    	if ( ! IsPlayerInRangeOfPoint(playerid, 2.5, SCRAPYARD_BOAT_POS_X , SCRAPYARD_BOAT_POS_Y , SCRAPYARD_BOAT_POS_Z ) ) {

			GPS_MarkLocation(playerid, "The ~r~boat scrapyard~w~ has been marked on your ~r~minimap~w~.", E_GPS_COLOR_SCRIPT, 
				SCRAPYARD_BOAT_POS_X, SCRAPYARD_BOAT_POS_Y, SCRAPYARD_BOAT_POS_Z ) ;
			return true ;

    	}
    }

    else if ( IsAircraft ( GetPlayerVehicleID ( playerid ) ) ) {
    	if ( ! IsPlayerInRangeOfPoint(playerid, 2.5, SCRAPYARD_AIR_POS_X , SCRAPYARD_AIR_POS_Y , SCRAPYARD_AIR_POS_Z ) ) {

			GPS_MarkLocation(playerid, "The ~r~airplane scrapyard~w~ has been marked on your ~r~minimap~w~.", E_GPS_COLOR_SCRIPT, 
				SCRAPYARD_AIR_POS_X, SCRAPYARD_AIR_POS_Y, SCRAPYARD_AIR_POS_Z ) ;
			return true ;

    	}
    }

    else {
		if ( ! IsPlayerInRangeOfPoint(playerid, 2.5,  SCRAPYARD_POS_X, SCRAPYARD_POS_Y, SCRAPYARD_POS_Z) ) {

			GPS_MarkLocation(playerid, "The ~r~scrapyard~w~ has been marked on your ~r~minimap~w~.", E_GPS_COLOR_SCRIPT, SCRAPYARD_POS_X, SCRAPYARD_POS_Y, SCRAPYARD_POS_Z ) ;
			return true ;
		}

	}

	new vehicleid = GetPlayerVehicleID(playerid);
	new veh_enum_id = Vehicle_GetEnumID ( vehicleid );

	if (!IsPlayerInAnyVehicle(playerid)) {
		return SendClientMessage(playerid, COLOR_ERROR, "You are not in any vehicle.");
	}

	if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
	    return SendClientMessage(playerid, COLOR_ERROR, "You can't do this as you're not the driver.");

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_LEAD ) {
		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_PLAYER ) {
			if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] ) {

				return SendClientMessage(playerid, COLOR_ERROR, "You do not own this vehicle!");
			}
		}

		else {

			return SendClientMessage(playerid, COLOR_ERROR, "Only player owned vehicles can be transfered.");
		}
	}

	if (VehicleOutstandingFines[veh_enum_id] > 0)
	{
		return SendClientMessage(playerid, COLOR_ERROR,
			"You cannot scrap a vehicle with unpaid citations. Clear them at the Administration Building first.");
	}

	if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_PLAYER ) {

		return SendClientMessage(playerid, COLOR_ERROR, "Only player owned vehicles can be scrapped.");
	}

	if ( ! Vehicle_IsTrunkEmpty ( veh_enum_id ) ) {

		return SendClientMessage(playerid, COLOR_ERROR, "Empty the trunk (weapons, drugs and anything else stored in it) before scrapping this vehicle.");
	}

	new scrap_money = Vehicle_GetScrapValue ( veh_enum_id ) ;
	new scrap_mileage = Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ;

	static CarScrapStr[1024];

	inline CarScrap_Confirm(pid, dialogid, response, listitem, string: inputtext[]) {
		#pragma unused pid, dialogid, inputtext, listitem

		if ( ! response ) {

			return true ;
		}

		// The player could have driven off or swapped cars while the dialog was open.
		if ( GetPlayerVehicleID(playerid) != vehicleid || GetPlayerState(playerid) != PLAYER_STATE_DRIVER || Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] == -1 ) {

			return SendClientMessage(playerid, COLOR_ERROR, "You must stay in the vehicle you are scrapping.");
		}

		new model_name [ 32 ] ;
		format ( model_name, sizeof ( model_name ), "%s", ReturnVehicleModelName ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ) ) ;

		JT_RemovePlayerFromVehicle(playerid);

		new scrapped_sqlid = Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ;

		Vehicle_MoveToPool ( veh_enum_id, scrap_money ) ;

	 	SendClientMessage(playerid, COLOR_ERROR, sprintf("You've scrapped your vehicle. You've received %s in scrap change.", IntegerWithDelimiter(scrap_money)));

	 	GivePlayerCash ( playerid, scrap_money, "Car scrap" ) ;

	 	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Scrapped a %s (%d miles) for $%d, vehicle SQLID %d went to the used car pool", model_name, scrap_mileage, scrap_money, scrapped_sqlid ));

		return true ;
	}

	format(CarScrapStr, sizeof(CarScrapStr), "{EC9424}Warning! {DEDEDE}This is a destructive action!");

	strcat(CarScrapStr, "\n\n{DEDEDE}You are about to scrap and {EC9424}SELL{DEDEDE} your vehicle.");
	strcat(CarScrapStr, sprintf("\n\n{A3A3A3}Vehicle: {DEDEDE}%s", ReturnVehicleName(vehicleid)));
	strcat(CarScrapStr, sprintf("\n{A3A3A3}Mileage: {DEDEDE}%d miles", scrap_mileage));
	strcat(CarScrapStr, sprintf("\n{A3A3A3}Scrapyard offer: {32CD32}$%s", IntegerWithDelimiter(scrap_money)));
	strcat(CarScrapStr, "\n\n{DEDEDE}The scrapyard pays a share of the new price, and the more miles a car has done the less it is worth.");
	strcat(CarScrapStr, "\n{DEDEDE}A used car dealer can buy it from the scrapyard and resell it. If you want to sell it to someone yourself, use /carsell.");
	strcat(CarScrapStr, "\n\n{DEDEDE}Are you sure you want to continue?");
	strcat(CarScrapStr, "\n{f1c38a}You will not be refunded if you change your mind.");

	Dialog_ShowCallback ( playerid, using inline CarScrap_Confirm, DIALOG_STYLE_MSGBOX, "{EC9424}SCRAP WARNING{DEDEDE}", CarScrapStr, "Scrap it", "Cancel" );

	return true ;
}

// probably not the best place to put this but if i added it in admin/vehicle.pwn it would not want to work.

// /deletecar [id] - (admin) permanently deletes a vehicle.
CMD:deletecar(playerid, params[]) {

    if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL )
        return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;

    new carid;

    if ( sscanf ( params, "i", carid ) ){
        SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/deletecar [vehicleid]") ;
        return SendServerMessage(playerid, COLOR_ERROR, "WARNING", "A3A3A3", "This command permanently deletes the car. Use carefully.");
    }

    if (!IsValidVehicle(carid))
        return SendClientMessage(playerid, COLOR_ERROR, "This is not a valid vehicle ID.");

    new veh_enum_id = Vehicle_GetEnumID ( carid );

    new query [ 256 ] ;

    mysql_format(mysql, query, sizeof ( query), "DELETE FROM `vehicles` WHERE vehicle_sqlid = %d ", Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] );
    mysql_tquery(mysql, query); 

    Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] = INVALID_VEHICLE_ID ;
    Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] = INVALID_PLAYER_ID ;

    if ( IsValidVehicle( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID] ) ) {
                
        ORP_DestroyVehicle( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID], "deletecar" ) ;
        Vehicle [ veh_enum_id ] [ E_VEHICLE_ID] = INVALID_VEHICLE_ID ;
    }
    
    SendClientMessage(playerid, COLOR_ERROR, sprintf("You've deleted a %s with ID %d.", ReturnVehicleName(carid), carid));
    SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s has deleted a vehicle with ID %d.", playerid, ReturnRPName(playerid), carid));
	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("%s has deleted a vehicle with ID %d.", ReturnRPName(playerid), carid));

    return true ;
}
