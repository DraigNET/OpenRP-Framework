// ============================================================================
// File: vehicle/data/hooks.pwn
// Wrappers ORP_SetVehicleToRespawn and ORP_DestroyVehicle that clean up cargo, occupants and
// runtime variables when a vehicle respawns or is removed. Always use them instead of the raw
// natives.
// ============================================================================

 
// Wrapper for SetVehicleToRespawn that also resets the framework's vehicle data.
ORP_SetVehicleToRespawn(vehicleid, const reason[32], nokick=false) {

	new veh_enum_id = Vehicle_GetEnumID ( vehicleid );
	new Float:x, Float:y, Float:z;
    if(veh_enum_id<0 || veh_enum_id>=sizeof Vehicle) return SetVehicleToRespawn(vehicleid);

	Vehicle_ClearRuntimeVariables(veh_enum_id);
	Vehicle_ClearTruckerVariables(veh_enum_id);
	Gunrack_Reset(vehicleid);
	Scanner_Reset(vehicleid);

	if (VehicleVar[vehicleid][E_VEHICLE_FLAME_OBJECT] && IsValidDynamicObject(VehicleVar[vehicleid][E_VEHICLE_FLAME_OBJECT]))
	{
		DestroyDynamicObject(VehicleVar[vehicleid][E_VEHICLE_FLAME_OBJECT]);
		VehicleVar[vehicleid][E_VEHICLE_FLAME_OBJECT] = 0;
	}

	if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] == vehicleid ) 
	{
		Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ] = true;
		SetAllVehicleDoorsOpen(vehicleid, VEHICLE_PARAMS_OFF, veh_enum_id);
		
		SetVehicleZAngle(vehicleid, Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_A ]);

		if (!nokick)
		{
			foreach ( new i : Player ) 
			{
				if (GetPlayerVehicleID(i) == vehicleid)
				{
					// Kick occupants out before respawning the car
					GetPlayerPos(i, x, y, z);
					PauseAC(i, 3);
					SetPlayerPos(i, x, y, z);
					JT_RemovePlayerFromVehicle(i);
				}
			}
		}

		SetVehiclePos (vehicleid, 
			Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_X ],
			Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Y ],
			Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Z ]
		);

		ORP_RepairVehicle(vehicleid);
		SetVehicleParamsEx(vehicleid, 0, 0, 0, 0, 0, 0, 0);
		SetVehicleParamsCarWindows(vehicleid, 1, 1, 1, 1);
		SetVehicleParamsCarDoors(vehicleid, 0, 0, 0, 0);

		SetVehicleZAngle(vehicleid, Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_A ]);

		SetVehicleVirtualWorld(vehicleid, Vehicle [ veh_enum_id ] [ E_VEHICLE_VW ]);
		LinkVehicleToInterior(vehicleid, Vehicle [ veh_enum_id ] [ E_VEHICLE_INT ]);

		if(IsObjectInVehicleSlot(vehicleid, 1))
			RemoveObjectFromVehicleSlot(vehicleid, 1);

		new factiontype = GetVehicleFactionType(vehicleid);
		new model = GetVehicleModel(vehicleid);
		if ((factiontype == FACTION_TYPE_LEO) && model == 596 || model == 598 || model == 490) // FACTION_TYPE_LEO/POLICE
		{
			// Setting police cars to spawn with front 2 windows down
			SetVehicleParamsCarWindows(vehicleid, 0, 0, 1, 1);
			Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ] = false;

			// And trying to stop tunes...
			// nvm...

			/*
			for ( new i, j = MAX_COMPONENTS; i < j ; i ++ ) 
			{
				if ( VehicleComponent [ i ] [ E_COMPONENT_VEH_SQL_ID ] == Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID] ) {
					VehicleComponent [ i ] [ E_COMPONENT_SQL_ID ] = -1 ;
					VehicleComponent [ i ] [ E_COMPONENT_VEH_SQL_ID ] = INVALID_VEHICLE_ID ;
				}

				else continue ;
			}
			*/
		}
	}

	if (strlen(reason) > 1) printf("[vrespawn] vehicle %d was respawned, reason: %s", vehicleid, reason); // to track random respawns
    return 1;
}


// Wrapper for DestroyVehicle that saves and clears the framework's vehicle data.
ORP_DestroyVehicle(vehicleid, const reason[] = "unknown") {

	new veh_enum_id = Vehicle_GetEnumID ( vehicleid );

	if ( veh_enum_id != -1 ) {

		Vehicle_ClearTruckerVariables(veh_enum_id);

		Vehicle_DestroyLabel(veh_enum_id);

		new sqlid = Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ];

		foreach(new userid: Player) {
			for (new i = 0; i < 2; i++) {
				if (Character [ userid ] [ E_CHARACTER_VEH_KEYS ] [ i ] == sqlid) {
					Character [ userid ] [ E_CHARACTER_VEH_KEYS ] [ i ] = -1;
				}
			}
		}

		new query [ 128 ];
		format(query, sizeof(query), "DELETE FROM character_vehicle_keys WHERE vehicle_sqlid = %d", sqlid);
		mysql_tquery(mysql, query);

		// Track what destroys vehicles (esp. faction cars vanishing). Pair this with
		// the [vrespawn] log to tell a destroy apart from a respawn-to-spawn.
		printf("[vdestroy] vehicle %d (enum %d, type %d, sqlid %d) was DESTROYED. reason: %s",
			vehicleid, veh_enum_id, Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ], sqlid, reason);
	}

	Temp_ReleaseVehicleEnumId(vehicleid);

//	TotalCarsSpawned -- ;

	return DestroyVehicle(vehicleid);
}
