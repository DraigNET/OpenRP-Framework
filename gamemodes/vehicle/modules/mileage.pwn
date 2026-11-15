// ============================================================================
// File: vehicle/modules/mileage.pwn
// Vehicle mileage: distance driven in miles and the depreciation curve used to price a car for
// scrapyards and used-car firms.
// ============================================================================

// Vehicle mileage: real distance driven, in miles (E_VEHICLE_MILEAGE), plus the depreciation
// curve the scrapyard and used car firms use to price a car by how far it has been driven.
//
// Before this the counter went up by 1 for every minute the car was moving, which is why it never
// looked like a real odometer. Now the driver's speed is integrated once a second, so 60 mph for an
// hour adds 60 miles, and only movement the car really made counts (see Mileage_Tick). The whole-mile counter is saved by Fuel_UpdateVehicleFuel; the fraction of a
// mile still building up lives in VehicleVar and is not saved (a restart loses under one mile).

#define VEH_MILEAGE_MAX_SPEED       (300)   // speed readings above this (teleports, desync) are ignored

// Depreciation. A car is worth VEH_VALUE_FULL_PCT of its new price up to VEH_DEPR_FREE_MILES, slides
// down in a straight line to VEH_VALUE_FLOOR_PCT at VEH_DEPR_FLOOR_MILES and stays there.
// Retune these once there is real driving data (look at the spread of vehicle_mileage).
#define VEH_DEPR_FREE_MILES         (100)
#define VEH_DEPR_FLOOR_MILES        (4000)
#define VEH_VALUE_FULL_PCT          (50)
#define VEH_VALUE_FLOOR_PCT         (20)

// Percentage of the new price a car with this mileage is worth to the scrapyard / a used car firm.
Vehicle_GetValuePercent(mileage)
{
	if ( mileage <= VEH_DEPR_FREE_MILES ) {

		return VEH_VALUE_FULL_PCT ;
	}

	if ( mileage >= VEH_DEPR_FLOOR_MILES ) {

		return VEH_VALUE_FLOOR_PCT ;
	}

	new drop = ( VEH_VALUE_FULL_PCT - VEH_VALUE_FLOOR_PCT ) * ( mileage - VEH_DEPR_FREE_MILES ) / ( VEH_DEPR_FLOOR_MILES - VEH_DEPR_FREE_MILES ) ;

	return VEH_VALUE_FULL_PCT - drop ;
}

// Scrap / trade-in value of a car. Returns 0 for models that aren't sold at any dealership, so the
// caller can fall back to whatever it uses for those.
Vehicle_GetTradeInValue(modelid, mileage)
{
	new price = Vehicle_GetCatalogPrice(modelid) ;

	if ( price <= 0 ) {

		return 0 ;
	}

	new value = price * Vehicle_GetValuePercent(mileage) / 100 ;

	return ( value < 1 ) ? 1 : value ;
}

// Distance is only counted for movement that really happened. Each second the car's position is
// compared with where it was at the last sample, and the miles added come from the smaller of that
// real movement and the speed reading, so:
//  - a teleport (admin /goto, /gotoveh, setpos, a streamed jump) is a huge position change, which is
//    thrown away instead of counted, and the sample after it starts from the new position;
//  - wheels spinning against a wall, a car held in place or a bogus velocity add nothing, because the
//    car didn't move;
//  - a sample that came too late or too early (lag, a freshly entered car) is skipped.
// Position change is converted with the same scale as TRP_GetVehicleSpeed (speed = velocity * 90,
// and a velocity of 1.0 is about 50 units a second, so units per second * 1.8 = speed).
#define VEH_MILEAGE_UNITS_TO_SPEED  (1.8)
#define VEH_MILEAGE_MIN_SAMPLE_MS   (500)
#define VEH_MILEAGE_MAX_SAMPLE_MS   (3000)

ptask Mileage_Tick[1000](playerid)
{
	if ( GetPlayerState(playerid) != PLAYER_STATE_DRIVER ) {

		return 1 ;
	}

	new vehicleid = GetPlayerVehicleID(playerid) ;

	if ( vehicleid <= 0 || ! IsEngineVehicle(vehicleid) || ! GetEngineStatus(vehicleid) ) {

		return 1 ;
	}

	new veh_enum_id = Vehicle_GetEnumID(vehicleid) ;

	if ( veh_enum_id == -1 || Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_DMV ) {

		return 1 ;
	}

	new Float: x, Float: y, Float: z, now = GetTickCount() ;

	GetVehiclePos(vehicleid, x, y, z) ;

	new last_tick = VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_LAST_TICK ] ;
	new Float: last_x = VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_LAST_X ], Float: last_y = VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_LAST_Y ], Float: last_z = VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_LAST_Z ] ;

	// Always move the baseline on, whatever happens below, so a teleport only ever costs one sample.
	VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_LAST_X ] = x ;
	VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_LAST_Y ] = y ;
	VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_LAST_Z ] = z ;
	VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_LAST_TICK ] = now ;

	if ( last_tick == 0 ) {

		return 1 ;
	}

	new elapsed = now - last_tick ;

	if ( elapsed < VEH_MILEAGE_MIN_SAMPLE_MS || elapsed > VEH_MILEAGE_MAX_SAMPLE_MS ) {

		return 1 ;
	}

	new Float: moved = floatsqroot ( ( x - last_x ) * ( x - last_x ) + ( y - last_y ) * ( y - last_y ) + ( z - last_z ) * ( z - last_z ) ) ;

	// What speed that movement works out to over the time that really passed.
	new Float: real_speed = moved / ( float ( elapsed ) / 1000.0 ) * VEH_MILEAGE_UNITS_TO_SPEED ;

	// Nothing a car can do is this fast, so it was moved, not driven.
	if ( real_speed > float ( VEH_MILEAGE_MAX_SPEED ) ) {

		return 1 ;
	}

	new Float: speed = float ( TRP_GetVehicleSpeed(vehicleid) ) ;

	if ( speed < 1.0 || speed > float ( VEH_MILEAGE_MAX_SPEED ) ) {

		return 1 ;
	}

	// Count the smaller of the two, so neither a bogus velocity nor a jump can inflate it.
	if ( real_speed < speed ) {

		speed = real_speed ;
	}

	// Miles for the time that passed (speed is in miles per hour).
	VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_FRAC ] += speed * ( float ( elapsed ) / 1000.0 ) / 3600.0 ;

	if ( VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_FRAC ] >= 1.0 ) {

		new whole = floatround ( VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_FRAC ], floatround_floor ) ;

		VehicleVar [ veh_enum_id ] [ E_VEHICLE_MILE_FRAC ] -= float(whole) ;
		Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] += whole ;
	}

	return 1 ;
}
