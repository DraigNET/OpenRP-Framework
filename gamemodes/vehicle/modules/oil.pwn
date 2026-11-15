// ============================================================================
// File: vehicle/modules/oil.pwn
// Oil servicing and engine wear: /oil shows condition, overdue oil raises the chance of a
// failed start and a seized engine.
// Commands: /oil
// ============================================================================

// Oil servicing and engine wear.
//
// A car's oil is due for a change OIL_SERVICE_INTERVAL miles after the last one (the odometer reading
// at the last change is saved in E_VEHICLE_OIL_SERVICE_MILES, so it can't be bought off at a Pay'n'Spray,
// only a mechanic's /mechanic oilchange resets it). Once it is due:
//  - every time the engine is turned on, the dash shows "OIL SERVICE PAST DUE";
//  - the further past due, the harder the car is to start;
//  - while the engine runs (checked once a minute by VehicleConstantTick) it wears, faster the longer
//    the oil is left; past a point it can seize at random, and at full wear it seizes for certain;
//  - a seized engine won't start at all until a mechanic rebuilds it (/mechanic engine).
// Player, firm and law enforcement vehicles are tracked. Rental, job and other faction vehicles aren't.
// Law enforcement vehicles can't be worked on by mechanics, they are serviced with /rprf at a faction garage.
// All the numbers are constants below.

#define OIL_SERVICE_INTERVAL        (100)   // miles between oil changes
#define OIL_START_GRACE_MILES       (25)    // miles past due before starting gets any harder
#define OIL_START_FAIL_DIVISOR      (5)     // +1% chance of a failed start per this many miles past the grace
#define OIL_START_FAIL_MAX          (60)    // never worse than this chance of a failed start (seized aside)
#define OIL_WEAR_SEIZED             (1000)  // wear at which the engine is seized
#define OIL_WEAR_RISK_FROM          (600)   // above this wear it can seize at random while running
#define OIL_WEAR_PER_MINUTE         (1)     // wear added per minute of running on overdue oil...
#define OIL_WEAR_MILES_STEP         (50)    // ...plus 1 more per this many miles past due

// Defined in faction/header.pwn, which is included after the vehicle system.
forward IsFactionTypeVehicle(vehicleid, factiontype);

// Whether a vehicle's oil is tracked at all.
bool: Oil_IsTracked(veh_enum_id) {

	if ( veh_enum_id < 0 || veh_enum_id >= MAX_VEHICLES || Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] == -1 ) {

		return false ;
	}

	new vehicleid = Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ;

	if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_PLAYER && Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_FIRM ) {

		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_FACTION || ! IsValidVehicle ( vehicleid ) || ! IsFactionTypeVehicle ( vehicleid, FACTION_TYPE_LEO ) ) {

			return false ;
		}
	}

	if ( Vehicle_IsPooled ( veh_enum_id ) ) {

		return false ;
	}

	return IsValidVehicle ( vehicleid ) && IsEngineVehicle ( vehicleid ) ;
}

// Returns the miles driven since the last oil service.
Oil_GetMilesSinceService(veh_enum_id) {

	new since = Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] - Vehicle [ veh_enum_id ] [ E_VEHICLE_OIL_SERVICE_MILES ] ;

	return ( since < 0 ) ? 0 : since ;
}

// Miles past the service interval, 0 while the oil is still fine.
Oil_GetOverdue(veh_enum_id) {

	new overdue = Oil_GetMilesSinceService ( veh_enum_id ) - OIL_SERVICE_INTERVAL ;

	return ( overdue < 0 ) ? 0 : overdue ;
}

// Returns true if the engine has seized from lack of oil.
bool: Oil_IsSeized(veh_enum_id) {

	return Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE_WEAR ] >= OIL_WEAR_SEIZED ;
}

// Chance (0-100) that starting the engine fails because of the oil.
Oil_GetStartFailChance(veh_enum_id) {

	new overdue = Oil_GetOverdue ( veh_enum_id ) - OIL_START_GRACE_MILES ;

	if ( overdue <= 0 ) {

		return 0 ;
	}

	new chance = overdue / OIL_START_FAIL_DIVISOR ;

	return ( chance > OIL_START_FAIL_MAX ) ? OIL_START_FAIL_MAX : chance ;
}

// Writes the oil condition (Good, Low, Critical...) of a vehicle.
Oil_GetConditionName(veh_enum_id, name[], len = sizeof ( name )) {

	new wear = Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE_WEAR ] ;

	if ( wear >= OIL_WEAR_SEIZED ) 		format ( name, len, "{FF4444}seized" ) ;
	else if ( wear >= 600 ) 			format ( name, len, "{FF8844}failing" ) ;
	else if ( wear >= 300 ) 			format ( name, len, "{FFCC44}worn" ) ;
	else if ( wear >= 50 ) 				format ( name, len, "{DEDEDE}a little worn" ) ;
	else 								format ( name, len, "{66DD66}good" ) ;

	return true ;
}

// Saves the oil data of a vehicle.
Oil_Save(veh_enum_id) {

	new query [ 160 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE vehicles SET vehicle_oil_service_miles = %d, vehicle_engine_wear = %d WHERE vehicle_sqlid = %d",
		Vehicle [ veh_enum_id ] [ E_VEHICLE_OIL_SERVICE_MILES ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE_WEAR ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// A mechanic changes the oil: the odometer reading is stored as the new baseline.
Oil_ChangeOil(veh_enum_id) {

	Vehicle [ veh_enum_id ] [ E_VEHICLE_OIL_SERVICE_MILES ] = Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ;

	return Oil_Save ( veh_enum_id ) ;
}

// A mechanic rebuilds a worn or seized engine.
Oil_RebuildEngine(veh_enum_id) {

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE_WEAR ] = 0 ;

	return Oil_Save ( veh_enum_id ) ;
}

// Everything a garage does in one go: fresh oil, a rebuilt engine and a drained tank. Used by /rprf and
// the admin /carfix. (The caller refuels and repairs the body.)
Vehicle_FullService(veh_enum_id) {

	Vehicle [ veh_enum_id ] [ E_VEHICLE_OIL_SERVICE_MILES ] = Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE_WEAR ] = 0 ;
	VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ] = 0 ;

	new query [ 192 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE vehicles SET vehicle_oil_service_miles = %d, vehicle_engine_wear = 0, vehicle_wrong_fuel_amount = 0 WHERE vehicle_sqlid = %d",
		Vehicle [ veh_enum_id ] [ E_VEHICLE_OIL_SERVICE_MILES ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// The engine gives up while running.
static Oil_SeizeEngine(veh_enum_id) {

	new vehicleid = Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Float: x, Float: y, Float: z ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE_WEAR ] = OIL_WEAR_SEIZED ;

	SetEngineStatus ( vehicleid, false ) ;

	GetVehiclePos ( vehicleid, x, y, z ) ;

	ProxDetectorXYZ ( x, y, z, 0, GetVehicleVirtualWorld ( vehicleid ), 25.0, COLOR_ACTION, sprintf ( "** a loud bang comes from the %s as its engine grinds and seizes up.", ReturnVehicleName ( vehicleid ) ) ) ;

	foreach ( new i : Player ) {

		if ( IsPlayerInRangeOfPoint ( i, 25.0, x, y, z ) ) {

			PlayerPlaySound ( i, 6802, x, y, z ) ;
		}
	}

	// Badly damaged but never explodes, same as the wrong-fuel blow. The seize itself is what stops it
	// starting, so a Pay'n'Spray can top the health back up but can't un-seize the engine.
	SetVehicleHealth ( vehicleid, 275.0 ) ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ] = 275.0 ;

	new health_query [ 128 ] ;

	mysql_format ( mysql, health_query, sizeof ( health_query ), "UPDATE vehicles SET vehicle_health = '%f' WHERE vehicle_sqlid = %d", 275.0, Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;
	mysql_tquery ( mysql, health_query ) ;

	new driver = GetVehicleDriver ( vehicleid ) ;

	if ( driver != INVALID_PLAYER_ID && IsPlayerConnected ( driver ) ) {

		AddLogEntry ( driver, LOG_TYPE_SCRIPT, sprintf ( "The engine of a %s seized from overdue oil (%d miles since service).", ReturnVehicleName ( vehicleid ), Oil_GetMilesSinceService ( veh_enum_id ) ) ) ;
		SendClientMessage ( driver, COLOR_ERROR, "The engine has seized from worn-out oil! It needs a mechanic to rebuild it." ) ;
		ShowInfoText ( driver, "~r~ENGINE SEIZED", 5000 ) ;
	}

	Oil_Save ( veh_enum_id ) ;

	return true ;
}

// Called once a minute for every vehicle (VehicleConstantTick).
Oil_TickVehicle(veh_enum_id) {

	if ( ! Oil_IsTracked ( veh_enum_id ) || Oil_IsSeized ( veh_enum_id ) ) {

		return false ;
	}

	if ( ! GetEngineStatus ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ) ) {

		return false ;
	}

	new overdue = Oil_GetOverdue ( veh_enum_id ) ;

	if ( overdue <= 0 ) {

		return false ;
	}

	new wear = Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE_WEAR ] + OIL_WEAR_PER_MINUTE + ( overdue / OIL_WEAR_MILES_STEP ) ;

	if ( wear > OIL_WEAR_SEIZED ) {

		wear = OIL_WEAR_SEIZED ;
	}

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE_WEAR ] = wear ;

	// Past the risk point the engine can seize at random, and the worse the wear the likelier it is.
	if ( wear >= OIL_WEAR_SEIZED || ( wear >= OIL_WEAR_RISK_FROM && random ( 1000 ) < ( wear - OIL_WEAR_RISK_FROM ) / 10 ) ) {

		return Oil_SeizeEngine ( veh_enum_id ) ;
	}

	Oil_Save ( veh_enum_id ) ;

	return true ;
}

// Called when the key is turned (Engine_StartDelay). Returns true when the engine mustn't start, after
// telling the player why.
bool: Oil_StartCheck(playerid, vehicleid, veh_enum_id) {

	if ( ! Oil_IsTracked ( veh_enum_id ) ) {

		return false ;
	}

	// The dash warning shows every single time the engine is turned on once the oil is due.
	new since = Oil_GetMilesSinceService ( veh_enum_id ) ;

	if ( since >= OIL_SERVICE_INTERVAL ) {

		ShowInfoText ( playerid, "~y~OIL SERVICE PAST DUE", 4000 ) ;
		SendClientMessage ( playerid, COLOR_YELLOW, sprintf ( "[Dash] Oil service past due - %d miles since the last oil change (due every %d). Visit a mechanic.", since, OIL_SERVICE_INTERVAL ) ) ;
	}

	if ( Oil_IsSeized ( veh_enum_id ) ) {

		ProxDetectorEx ( playerid, 20.0, COLOR_ACTION, "**", sprintf ( "turns the key, but the engine of the %s is seized solid and won't turn over.", ReturnVehicleName ( vehicleid ) ), .annonated = true ) ;
		SendClientMessage ( playerid, COLOR_ERROR, "The engine has seized from worn-out oil. It needs a mechanic to rebuild it." ) ;

		return true ;
	}

	new chance = Oil_GetStartFailChance ( veh_enum_id ) ;

	if ( chance > 0 && random ( 100 ) < chance ) {

		ProxDetectorEx ( playerid, 20.0, COLOR_ACTION, "**", sprintf ( "turns the key, but the %s's engine turns over slowly and won't catch.", ReturnVehicleName ( vehicleid ) ), .annonated = true ) ;
		SendClientMessage ( playerid, COLOR_ERROR, "The engine struggles and fails to start. The oil is badly overdue for a change, try again or get it serviced." ) ;

		return true ;
	}

	return false ;
}

// /oil: what the driver can see on the dash.
CMD:oil(playerid, params[]) {

	#pragma unused params

	if ( ! IsPlayerInAnyVehicle ( playerid ) ) {

		return SendClientMessage ( playerid, COLOR_ERROR, "You must be in a vehicle for this to work." ) ;
	}

	new vehicleid = GetPlayerVehicleID ( playerid ), veh_enum_id = Vehicle_GetEnumID ( vehicleid ) ;

	if ( veh_enum_id == -1 || ! Oil_IsTracked ( veh_enum_id ) ) {

		return SendClientMessage ( playerid, COLOR_ERROR, "This vehicle doesn't need oil servicing." ) ;
	}

	new since = Oil_GetMilesSinceService ( veh_enum_id ), condition [ 32 ] ;

	Oil_GetConditionName ( veh_enum_id, condition, sizeof ( condition ) ) ;

	SendClientMessage ( playerid, COLOR_INFO, sprintf ( "[Dash] %s | %d miles since the last oil change (due every %d) | Engine: %s", ReturnVehicleName ( vehicleid ), since, OIL_SERVICE_INTERVAL, condition ) ) ;

	if ( since >= OIL_SERVICE_INTERVAL ) {

		SendClientMessage ( playerid, COLOR_YELLOW, sprintf ( "[Dash] OIL SERVICE PAST DUE by %d miles. Only a mechanic can change the oil.", since - OIL_SERVICE_INTERVAL ) ) ;
	}

	else {

		SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "[Dash] Next oil change due in %d miles.", OIL_SERVICE_INTERVAL - since ) ) ;
	}

	return true ;
}
