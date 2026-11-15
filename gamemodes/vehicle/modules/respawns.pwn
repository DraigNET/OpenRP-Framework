// ============================================================================
// File: vehicle/modules/respawns.pwn
// Staff tools that recreate missing or broken vehicles: /respawnallcars,
// /respawnmissingvehicles, /respawnrentals, /respawnjobcars.
// Commands: /respawnallcars /respawnmissingvehicles /respawnrentals /respawnjobcars
// ============================================================================


// /respawnallcars - (admin) respawns every unoccupied vehicle.
CMD:respawnallcars(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	defer Vehicle_CarRespawnTick[15000]();
	SendClientMessageToAll(COLOR_INFO, "(( AdminMsg )) ALL unoccupied vehicles respawning in 15 seconds. Sit in driver seat to keep yours!");

	return true ;
}

// Timer: respawns vehicles that were left unoccupied.
timer Vehicle_CarRespawnTick[15000]() {

	for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

		if ( ! IsValidVehicle(Vehicle [ i ] [ E_VEHICLE_ID ] ) ) {

			continue ;
		}

		//new vehicleid = Vehicle_GetEnumID(i);
		if ( GetVehicleDriver ( Vehicle [ i ] [ E_VEHICLE_ID ] ) == INVALID_PLAYER_ID ) {
			
			//Vehicle_ClearTruckerVariables(i);

			if ( Vehicle [ i ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_PLAYER ) {

				new Float: health ;
				GetVehicleHealth(Vehicle [ i ] [ E_VEHICLE_ID ], health ) ;

				Vehicle [ i ] [ E_VEHICLE_HEALTH ] = health ;
				new panels, doors, lights, tires;
				GetVehicleDamageStatus(Vehicle [ i ] [ E_VEHICLE_ID ], panels, doors, lights, tires);

				Vehicle [ i ] [ E_VEHICLE_DMG_PANELS ] 	= panels ;
				Vehicle [ i ] [ E_VEHICLE_DMG_DOORS ] 	= doors ;
				Vehicle [ i ] [ E_VEHICLE_DMG_LIGHTS ] 	= lights ;
				Vehicle [ i ] [ E_VEHICLE_DMG_TIRES ] 	= tires ;

				Vehicle [ i ] [ E_VEHICLE_IS_SPAWNED ] = false ;
			 
				if ( IsValidVehicle( Vehicle [ i ] [ E_VEHICLE_ID ]  ) ) {

					ORP_DestroyVehicle( Vehicle [ i ] [ E_VEHICLE_ID ], "respawnallcars_playerveh" ) ;
				}

				Vehicle [ i ] [ E_VEHICLE_ID ] = -1 ;
				Unit_StopByVehicleEnum(i);
			}

			else {
				ORP_SetVehicleToRespawn ( Vehicle [ i ] [ E_VEHICLE_ID ], "respawnallcars" ) ; 
				Vehicle [ i ] [ E_VEHICLE_FUEL ] = 100 ;
				Unit_StopByVehicleEnum(i);
			}
		}

		else continue ;

	}

	SendClientMessageToAll(COLOR_INFO, "(( AdminMsg )) All unoccupied vehicles respawned by an admin." ) ;
}

// /respawnmissingvehicles - (admin) respawns owned vehicles that went missing.
CMD:respawnmissingvehicles(playerid, params[]) {
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR) {
		return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
	}

	defer Vehicle_RespawnMissingTick(playerid);
	SendClientMessage(playerid, COLOR_INFO, "(( AdminMsg )) Checking for missing non-player vehicles (memory + database)...");

	return true;
}

// Timer: respawns missing vehicles one at a time.
timer Vehicle_RespawnMissingTick[0](playerid) {
	// Phase 1: in-memory pass — recreate any non-player vehicle whose SA-MP ID has gone invalid
	new mem_created = 0, mem_failed = 0;

	for (new i, j = sizeof(Vehicle); i < j; i++) {
		if (Vehicle[i][E_VEHICLE_SQLID] == -1) continue;
		if (Vehicle[i][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_PLAYER) continue;
		if (IsValidVehicle(Vehicle[i][E_VEHICLE_ID])) continue;

		Temp_ReleaseVehicleEnumId(Vehicle[i][E_VEHICLE_ID]);

		new veh_respawn_delay = (Vehicle[i][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_FACTION || Vehicle[i][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_FIRM) ? -1 : 0;
		Vehicle[i][E_VEHICLE_ID] = ORP_CreateVehicle(
			Vehicle[i][E_VEHICLE_MODELID],
			Vehicle[i][E_VEHICLE_POS_X], Vehicle[i][E_VEHICLE_POS_Y], Vehicle[i][E_VEHICLE_POS_Z],
			Vehicle[i][E_VEHICLE_POS_A],
			Vehicle[i][E_VEHICLE_VW], Vehicle[i][E_VEHICLE_INT],
			Vehicle[i][E_VEHICLE_COLOR_A], Vehicle[i][E_VEHICLE_COLOR_B],
			veh_respawn_delay,
			Vehicle[i][E_VEHICLE_SIREN]
		);

		if (!IsValidVehicle(Vehicle[i][E_VEHICLE_ID])) {
			printf("[respawnmissing] p1 failed sqlid %d model %d", Vehicle[i][E_VEHICLE_SQLID], Vehicle[i][E_VEHICLE_MODELID]);
			Vehicle[i][E_VEHICLE_ID] = INVALID_VEHICLE_ID;
			mem_failed++;
			continue;
		}

		Temp_SetVehicleEnumId(Vehicle[i][E_VEHICLE_ID], i);
		SetVehicleNumberPlate(Vehicle[i][E_VEHICLE_ID], Vehicle[i][E_VEHICLE_LICENSE]);
		Vehicle_SetDoorsEngineStatus(i);
		Tune_ApplyComponents(i);
		ORP_SetVehicleHealth(Vehicle[i][E_VEHICLE_ID], (Vehicle[i][E_VEHICLE_HEALTH] <= 250.0) ? 1000.0 : Vehicle[i][E_VEHICLE_HEALTH]);
		ChangeVehiclePaintjob(Vehicle[i][E_VEHICLE_ID], Vehicle[i][E_VEHICLE_PAINTJOB]);
		Vehicle[i][E_VEHICLE_FUEL] = 100;
		mem_created++;
	}

	SendClientMessage(playerid, COLOR_INFO, sprintf("(( AdminMsg )) Phase 1 (memory): %d restored, %d failed. Running database check...", mem_created, mem_failed));
	printf("[respawnmissing] p1 admin %d: %d restored, %d failed", playerid, mem_created, mem_failed);

	// Phase 2: DB pass — reload any non-player vehicle completely absent from the array
	inline VehicleReload_DBPass() {
		new db_created = 0, db_failed = 0;

		for (new r = 0, total = cache_num_rows(); r < total; r++) {
			new db_sqlid;
			cache_get_value_name_int(r, "vehicle_sqlid", db_sqlid);

			// Check if this SQLID already exists in the array
			new found = -1;
			for (new i = 0, j = sizeof(Vehicle); i < j; i++) {
				if (Vehicle[i][E_VEHICLE_SQLID] == db_sqlid) { found = i; break; }
			}
			if (found != -1) continue; // In memory (valid or not), skip

			// Truly absent from memory — find a free slot and load from DB
			new slot = Vehicle_GetFreeID();
			if (slot == -1) {
				printf("[respawnmissing] p2 no free array slots for sqlid %d", db_sqlid);
				db_failed++;
				continue;
			}

			Vehicle[slot][E_VEHICLE_SQLID] = db_sqlid;
			Vehicle_ResetLabelHandles(slot);
			cache_get_value_name_int(r,   "vehicle_modelid",  Vehicle[slot][E_VEHICLE_MODELID]);
			cache_get_value_name_int(r,   "vehicle_type",     Vehicle[slot][E_VEHICLE_TYPE]);
			cache_get_value_name_int(r,   "vehicle_owner",    Vehicle[slot][E_VEHICLE_OWNER]);
			cache_get_value_name_int(r,   "vehicle_color_a",  Vehicle[slot][E_VEHICLE_COLOR_A]);
			cache_get_value_name_int(r,   "vehicle_color_b",  Vehicle[slot][E_VEHICLE_COLOR_B]);
			cache_get_value_name_float(r, "vehicle_pos_x",    Vehicle[slot][E_VEHICLE_POS_X]);
			cache_get_value_name_float(r, "vehicle_pos_y",    Vehicle[slot][E_VEHICLE_POS_Y]);
			cache_get_value_name_float(r, "vehicle_pos_z",    Vehicle[slot][E_VEHICLE_POS_Z]);
			cache_get_value_name_float(r, "vehicle_pos_a",    Vehicle[slot][E_VEHICLE_POS_A]);
			cache_get_value_name_int(r,   "vehicle_vw",       Vehicle[slot][E_VEHICLE_VW]);
			cache_get_value_name_int(r,   "vehicle_int",      Vehicle[slot][E_VEHICLE_INT]);
			cache_get_value_name_int(r,   "vehicle_siren",    Vehicle[slot][E_VEHICLE_SIREN]);
			cache_get_value_name(r,       "vehicle_license",  Vehicle[slot][E_VEHICLE_LICENSE]);
			cache_get_value_name_int(r,   "vehicle_paintjob", Vehicle[slot][E_VEHICLE_PAINTJOB]);
			cache_get_value_name_int(r,   "vehicle_fuel",     Vehicle[slot][E_VEHICLE_FUEL]);
			cache_get_value_name_float(r, "vehicle_health",   Vehicle[slot][E_VEHICLE_HEALTH]);
			cache_get_value_name_int(r,   "vehicle_doors",    Vehicle[slot][E_VEHICLE_DOORS]);
			cache_get_value_name_int(r,   "vehicle_squad",    Vehicle[slot][E_VEHICLE_SQUAD]);
			cache_get_value_name_int(r,   "vehicle_mileage", Vehicle[slot][E_VEHICLE_MILEAGE]);
			cache_get_value_name_int(r,   "vehicle_sale_price", Vehicle[slot][E_VEHICLE_SALE_PRICE]);
			cache_get_value_name_int(r,   "vehicle_pooled_at", Vehicle[slot][E_VEHICLE_POOLED_AT]);
			cache_get_value_name_int(r,   "vehicle_pool_value", Vehicle[slot][E_VEHICLE_POOL_VALUE]);
			cache_get_value_name_int(r,   "vehicle_oil_service_miles", Vehicle[slot][E_VEHICLE_OIL_SERVICE_MILES]);
			cache_get_value_name_int(r,   "vehicle_engine_wear", Vehicle[slot][E_VEHICLE_ENGINE_WEAR]);
			cache_get_value_name_int(r,   "vehicle_repair_ready_at", Vehicle[slot][E_VEHICLE_REPAIR_READY]);
			Vehicle[slot][E_VEHICLE_ENGINE]  = false;
			Vehicle[slot][E_VEHICLE_WINDOW]  = true;
			Vehicle[slot][E_VEHICLE_STATION] = -1;
			VehicleVar[slot][E_VEHICLE_RENTEDBY] = INVALID_PLAYER_ID;
			VehicleVar[slot][E_VEHICLE_RENTUNIX] = 0;

			new veh_respawn_delay = (Vehicle[slot][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_FACTION || Vehicle[slot][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_FIRM) ? -1 : 0;
			Vehicle[slot][E_VEHICLE_ID] = ORP_CreateVehicle(
				Vehicle[slot][E_VEHICLE_MODELID],
				Vehicle[slot][E_VEHICLE_POS_X], Vehicle[slot][E_VEHICLE_POS_Y], Vehicle[slot][E_VEHICLE_POS_Z],
				Vehicle[slot][E_VEHICLE_POS_A],
				Vehicle[slot][E_VEHICLE_VW], Vehicle[slot][E_VEHICLE_INT],
				Vehicle[slot][E_VEHICLE_COLOR_A], Vehicle[slot][E_VEHICLE_COLOR_B],
				veh_respawn_delay, Vehicle[slot][E_VEHICLE_SIREN]
			);

			if (!IsValidVehicle(Vehicle[slot][E_VEHICLE_ID])) {
				printf("[respawnmissing] p2 spawn failed sqlid %d", db_sqlid);
				Vehicle[slot][E_VEHICLE_SQLID] = -1; // return slot to free pool
				db_failed++;
				continue;
			}

			Temp_SetVehicleEnumId(Vehicle[slot][E_VEHICLE_ID], slot);
			SetVehicleNumberPlate(Vehicle[slot][E_VEHICLE_ID], Vehicle[slot][E_VEHICLE_LICENSE]);
			Vehicle_SetDoorsEngineStatus(slot);
			Tune_ApplyComponents(slot);
			ORP_SetVehicleHealth(Vehicle[slot][E_VEHICLE_ID], (Vehicle[slot][E_VEHICLE_HEALTH] <= 250.0) ? 1000.0 : Vehicle[slot][E_VEHICLE_HEALTH]);
			ChangeVehiclePaintjob(Vehicle[slot][E_VEHICLE_ID], Vehicle[slot][E_VEHICLE_PAINTJOB]);
			Vehicle[slot][E_VEHICLE_FUEL] = 100;

			printf("[respawnmissing] p2 reloaded from DB sqlid %d -> slot %d, SA-MP id %d", db_sqlid, slot, Vehicle[slot][E_VEHICLE_ID]);
			db_created++;
		}

		SendClientMessage(playerid, COLOR_INFO, sprintf("(( AdminMsg )) Phase 2 (database): %d reloaded from DB, %d failed.", db_created, db_failed));
		printf("[respawnmissing] p2 admin %d: %d from DB, %d failed", playerid, db_created, db_failed);
	}

	MySQL_TQueryInline(mysql, using inline VehicleReload_DBPass, "SELECT vehicle_sqlid, vehicle_modelid, vehicle_type, vehicle_owner, vehicle_color_a, vehicle_color_b, vehicle_pos_x, vehicle_pos_y, vehicle_pos_z, vehicle_pos_a, vehicle_vw, vehicle_int, vehicle_siren, vehicle_license, vehicle_paintjob, vehicle_fuel, vehicle_health, vehicle_doors, vehicle_squad FROM vehicles WHERE vehicle_type != 3", "");
}

// /respawnrentals - (admin) respawns the rental vehicles.
CMD:respawnrentals(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	defer Vehicle_RentalRespawnTick[15000]();

	SendClientMessageToAll(COLOR_INFO, "(( AdminMsg )) Public / Rentable vehicles respawning in 15 seconds. Sit in driver seat to keep yours!");

	return true ;
}

// /respawnjobcars - (admin) respawns the job vehicles.
CMD:respawnjobcars(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	defer Vehicle_JobCarRespawnTick[15000]();

	SendClientMessageToAll(COLOR_INFO, "(( AdminMsg )) Job vehicles respawning in 15 seconds. Sit in driver seat to keep yours!");

	return true ;
}

// Timer: respawns job vehicles.
timer Vehicle_JobCarRespawnTick[15000]() {

	for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

		if ( ! IsValidVehicle(Vehicle [ i ] [ E_VEHICLE_ID ] ) ) {

			continue ;
		}

		if ( Vehicle [ i ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_JOB ) {

			if ( GetVehicleDriver ( Vehicle [ i ] [ E_VEHICLE_ID ]  ) == INVALID_PLAYER_ID ) {

				Vehicle_ClearTruckerVariables(i);

				Vehicle [i] [ E_VEHICLE_OWNER ] = INVALID_PLAYER_ID ;
				ORP_SetVehicleToRespawn ( Vehicle [ i ] [ E_VEHICLE_ID ], "respawnjobvehicles"  ) ; 

				Vehicle [ i ] [ E_VEHICLE_FUEL ] = 100 ;
			}

			else continue ;
		}

		else continue ;
	}

	SendClientMessageToAll(COLOR_INFO, "(( AdminMsg )) Job vehicles vehicles respawned by an admin." ) ;
}


// Timer: respawns rental vehicles.
timer Vehicle_RentalRespawnTick[15000]() {

	for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

		if ( ! IsValidVehicle(Vehicle [ i ] [ E_VEHICLE_ID ] ) ) {

			continue ;
		}

		if ( Vehicle [ i ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_RENTAL || Vehicle [ i ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_DMV ) {

			if ( GetVehicleDriver ( Vehicle [ i ] [ E_VEHICLE_ID ]  ) == INVALID_PLAYER_ID ) {

				Vehicle_ClearTruckerVariables(i);

				Vehicle [i] [ E_VEHICLE_OWNER ] = INVALID_PLAYER_ID ;
				ORP_SetVehicleToRespawn ( Vehicle [ i ] [ E_VEHICLE_ID ], "respawnrentals"  ) ; 

				Vehicle [ i ] [ E_VEHICLE_FUEL ] = 100 ;
			}

			else continue ;
		}

		else continue ;
	}

	SendClientMessageToAll(COLOR_INFO, "(( AdminMsg )) Public / Rentable vehicles respawned by an admin." ) ;
}
