// ============================================================================
// File: vehicle/modules/repair.pwn
// Pay 'n' Spray workshop state: a repaired car is despawned for a time and brought back with
// /collectcar.
// ============================================================================

// The Pay'n'Spray workshop. A car taken in for repair is despawned, stays out of the game for
// PNS_REPAIR_SECONDS, and is brought back with /collectcar at the same spot it was left (the command
// is in paynspray/cmds.pwn). While it is in the workshop E_VEHICLE_REPAIR_READY holds the unix time it
// is ready, which is saved, so it survives logging out and server restarts, and /carspawn refuses to
// spawn it early.

#define PNS_REPAIR_SECONDS          (60)

// Seconds until a car in the workshop is ready, 0 if it is ready (or isn't there at all).
Vehicle_RepairSecondsLeft(veh_enum_id) {

	new ready = Vehicle [ veh_enum_id ] [ E_VEHICLE_REPAIR_READY ] ;

	if ( ready <= 0 ) {

		return 0 ;
	}

	new left = ready - gettime () ;

	return ( left > 0 ) ? left : 0 ;
}

// Whether the car is in the workshop at all (still being repaired or finished and waiting).
bool: Vehicle_IsInWorkshop(veh_enum_id) {

	return Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] != -1 && Vehicle [ veh_enum_id ] [ E_VEHICLE_REPAIR_READY ] > 0 ;
}

// The car leaves the workshop (collected, or spawned some other way once it was ready).
Vehicle_ClearRepair(veh_enum_id) {

	Vehicle [ veh_enum_id ] [ E_VEHICLE_REPAIR_READY ] = 0 ;

	new query [ 128 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE vehicles SET vehicle_repair_ready_at = 0 WHERE vehicle_sqlid = %d", Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// Takes a spawned vehicle out of the game and saves everything about it, like /carpark does, so it can
// be spawned again later from the saved record.
Vehicle_DespawnRecord(veh_enum_id) {

	new vehicleid = Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ;

	Vehicle_DestroyLabel ( veh_enum_id ) ;

	if ( IsValidVehicle ( vehicleid ) ) {

		if ( IsTrailerAttachedToVehicle ( vehicleid ) ) {

			ORP_DestroyVehicle ( GetVehicleTrailer ( vehicleid ), "workshop_trailer_detach" ) ;
		}

		ORP_DestroyVehicle ( vehicleid, "workshop" ) ;
	}

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] = INVALID_VEHICLE_ID ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_IS_SPAWNED ] = false ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE ] = false ;

	new query [ 768 ] ;

	mysql_format ( mysql, query, sizeof ( query ),
		"UPDATE vehicles SET vehicle_pos_x = '%f', vehicle_pos_y = '%f', vehicle_pos_z = '%f', vehicle_pos_a = '%f', vehicle_vw = %d, vehicle_int = %d, vehicle_fuel = %d, vehicle_mileage = %d, vehicle_health = '%f', vehicle_dmg_panels = %d, vehicle_dmg_doors = %d, vehicle_dmg_lights = %d, vehicle_dmg_tires = %d, vehicle_repair_ready_at = %d WHERE vehicle_sqlid = %d",
		Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_X ], Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Y ], Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Z ], Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_A ],
		Vehicle [ veh_enum_id ] [ E_VEHICLE_VW ], Vehicle [ veh_enum_id ] [ E_VEHICLE_INT ], Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ], Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ], Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ],
		Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_PANELS ], Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_DOORS ], Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_LIGHTS ], Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_TIRES ],
		Vehicle [ veh_enum_id ] [ E_VEHICLE_REPAIR_READY ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}
