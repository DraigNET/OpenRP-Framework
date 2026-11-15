// ============================================================================
// File: vehicle/data/native.pwn
// Vehicle callbacks: entering and exiting vehicles, state changes, death and respawn, and the
// hint messages shown when you get in.
// ============================================================================



public OnVehicleSpawn (vehicleid) {
	new veh_enum_id = Vehicle_GetEnumID ( vehicleid );

	if ( veh_enum_id == -1 ) {

		return true ;
	} 

	ORP_SetVehicleCanExplode(vehicleid, false);
	SetVehicleHealth(vehicleid, 999);
	Vehicle_SetDoorsEngineStatus(veh_enum_id );

	ChangeVehicleColorEx(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_A ], Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_B ]);

	// Restoring tuning stuff
	Tune_ApplyComponents(veh_enum_id );
			
	Vehicle_DestroyLabel(veh_enum_id);

	Vehicle_ClearRuntimeVariables(veh_enum_id);
	Vehicle_ClearTruckerVariables(veh_enum_id);
	Gunrack_Reset(vehicleid);
	Scanner_Reset(vehicleid);

	printf("OnVehicleSpawn: %s (%d) (SQL: %d) was (re)spawned.  From death: %d", ReturnVehicleName(vehicleid), vehicleid, Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], VehicleVar [ veh_enum_id ] [ E_VEHICLE_RECENT_DEATH ]);
	

	if ( VehicleVar [ veh_enum_id ] [ E_VEHICLE_RECENT_DEATH ] )
	{
		if (  Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE] == E_VEHICLE_TYPE_PLAYER )
		{
			// Despawn player vehicles after they die
			VehicleVar [ veh_enum_id ] [ E_VEHICLE_RECENT_DEATH ] = false ;
			Vehicle [ veh_enum_id ] [ E_VEHICLE_IS_SPAWNED ] = false ;
 
			if ( IsValidVehicle( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ]  ) ) 
			{
				ORP_DestroyVehicle( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], "onvehiclespawn_playerdespawn" ) ;
			}

			Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] = -1 ;

			foreach(new playerid: Player) 
			{
				if ( Character [ playerid ] [ E_CHARACTER_ID ] == Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] ) {

					SendServerMessage ( playerid, COLOR_VEHICLE, "Vehicle", "A3A3A3", "Your personal vehicle has been destroyed and was despawned.");
				}
			}
		}
	}

	
	#if defined veh_OnVehicleSpawn
		return veh_OnVehicleSpawn(vehicleid);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnVehicleSpawn
	#undef OnVehicleSpawn
#else
	#define _ALS_OnVehicleSpawn
#endif

#define OnVehicleSpawn veh_OnVehicleSpawn
#if defined veh_OnVehicleSpawn
	forward veh_OnVehicleSpawn(vehicleid);
#endif


// Called when a vehicle is destroyed: marks it wrecked and removes it.
public OnVehicleDeath(vehicleid, killerid) {

	new veh_enum_id = Vehicle_GetEnumID ( vehicleid );

	if ( veh_enum_id == -1 ) 
	{
		return true ;
	}

	VehicleVar[veh_enum_id][E_VEHICLE_RECENT_DEATH] = true;

	Vehicle_DestroyLabel(veh_enum_id);

	Vehicle_ClearTruckerVariables(veh_enum_id);

	foreach(new playerid: Player ) {
		if ( IsPlayerLogged ( playerid ) && IsPlayerSpawned ( playerid ) ) {
			if ( PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_CARID ] == Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ) {

				GameTextForPlayer(playerid, "~r~Mission Failed~n~~w~The chopshop car has been destroyed.", 5000, 6);
		 		PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_PAYOUT ] = 0 ;
			 	PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_CARID ] = INVALID_VEHICLE_ID ;
				PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_DROPPOINT ] = -1 ;	
			}

			if ( PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_VEHICLE ] == Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ) {

				GameTextForPlayer(playerid, "~r~Mission Failed~n~~w~The chopshop car has been destroyed.", 5000, 6);
				GarbageJob_CancelData(playerid) ;
			}
		}
	}

	if (  Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE] == E_VEHICLE_TYPE_RENTAL ) {

		Vehicle [veh_enum_id] [ E_VEHICLE_OWNER ] = INVALID_PLAYER_ID ;
	}

	
	Vehicle_DestroyLabel(veh_enum_id);

	if (Vehicle[veh_enum_id][E_VEHICLE_TYPE] != E_VEHICLE_TYPE_PLAYER) {
		printf("[vdeath] non-player vehicle %d (enum %d, type %d, sqlid %d, owner %d) died — scheduling recovery",
			vehicleid, veh_enum_id,
			Vehicle[veh_enum_id][E_VEHICLE_TYPE],
			Vehicle[veh_enum_id][E_VEHICLE_SQLID],
			Vehicle[veh_enum_id][E_VEHICLE_OWNER]);
		defer Vehicle_RecoverAfterDeath[500](veh_enum_id);
	}

	#if defined veh_OnVehicleDeath
		return veh_OnVehicleDeath(vehicleid, killerid);
	#else
		return 1;
	#endif
}

// Timer: restores a vehicle after it was destroyed.
timer Vehicle_RecoverAfterDeath[500](veh_enum_id) {
	if (veh_enum_id < 0 || veh_enum_id >= MAX_VEHICLES) return;
	if (Vehicle[veh_enum_id][E_VEHICLE_SQLID] == -1) return;
	if (Vehicle[veh_enum_id][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_PLAYER) return;

	if (IsValidVehicle(Vehicle[veh_enum_id][E_VEHICLE_ID])) {
		// Vehicle still in pool (wrecked but valid) — just respawn it to spawn pos
		VehicleVar[veh_enum_id][E_VEHICLE_RECENT_DEATH] = false;
		ORP_SetVehicleToRespawn(Vehicle[veh_enum_id][E_VEHICLE_ID], "death_recovery");
		Vehicle[veh_enum_id][E_VEHICLE_FUEL] = 100;
		return;
	}

	// Vehicle was removed from the pool on death (respawn_delay=-1) — recreate it
	new old_id = Vehicle[veh_enum_id][E_VEHICLE_ID];
	Temp_ReleaseVehicleEnumId(old_id); // clear stale mapping so SA-MP can safely reuse old_id

	new veh_respawn_delay = (Vehicle[veh_enum_id][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_FACTION || Vehicle[veh_enum_id][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_FIRM) ? -1 : 0;
	Vehicle[veh_enum_id][E_VEHICLE_ID] = ORP_CreateVehicle(
		Vehicle[veh_enum_id][E_VEHICLE_MODELID],
		Vehicle[veh_enum_id][E_VEHICLE_POS_X], Vehicle[veh_enum_id][E_VEHICLE_POS_Y], Vehicle[veh_enum_id][E_VEHICLE_POS_Z],
		Vehicle[veh_enum_id][E_VEHICLE_POS_A],
		Vehicle[veh_enum_id][E_VEHICLE_VW], Vehicle[veh_enum_id][E_VEHICLE_INT],
		Vehicle[veh_enum_id][E_VEHICLE_COLOR_A], Vehicle[veh_enum_id][E_VEHICLE_COLOR_B],
		veh_respawn_delay,
		Vehicle[veh_enum_id][E_VEHICLE_SIREN]
	);

	if (!IsValidVehicle(Vehicle[veh_enum_id][E_VEHICLE_ID])) {
		printf("[vdeath] FAILED to recreate vehicle (enum %d, sqlid %d) — pool may be full",
			veh_enum_id, Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
		Vehicle[veh_enum_id][E_VEHICLE_ID] = INVALID_VEHICLE_ID;
		return;
	}

	VehicleVar[veh_enum_id][E_VEHICLE_RECENT_DEATH] = false;
	Temp_SetVehicleEnumId(Vehicle[veh_enum_id][E_VEHICLE_ID], veh_enum_id);
	SetVehicleNumberPlate(Vehicle[veh_enum_id][E_VEHICLE_ID], Vehicle[veh_enum_id][E_VEHICLE_LICENSE]);
	Vehicle_SetDoorsEngineStatus(veh_enum_id);
	Tune_ApplyComponents(veh_enum_id);
	ORP_SetVehicleHealth(Vehicle[veh_enum_id][E_VEHICLE_ID], 1000.0);
	ChangeVehiclePaintjob(Vehicle[veh_enum_id][E_VEHICLE_ID], Vehicle[veh_enum_id][E_VEHICLE_PAINTJOB]);
	Vehicle[veh_enum_id][E_VEHICLE_FUEL] = 100;

	printf("[vdeath] vehicle (enum %d, sqlid %d) recreated after pool removal — new SA-MP id %d",
		veh_enum_id, Vehicle[veh_enum_id][E_VEHICLE_SQLID], Vehicle[veh_enum_id][E_VEHICLE_ID]);
}
#if defined _ALS_OnVehicleDeath
	#undef OnVehicleDeath
#else
	#define _ALS_OnVehicleDeath
#endif

#define OnVehicleDeath veh_OnVehicleDeath
#if defined veh_OnVehicleDeath
	forward veh_OnVehicleDeath(vehicleid, killerid);
#endif
	
// Called when a player starts to enter a vehicle (checks the lock).
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger) {

  	if (IsPlayerNPC(playerid))
	    return 1;

	PlayerVar [ playerid ] [ E_PLAYER_LAST_VEH_ENTER_TIME ] = gettime();
	PlayerVar [ playerid ] [ E_PLAYER_LAST_VEH_TICK ] = GetTickCount();

	if (GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_CARRY ) {

	    ClearAnimations(playerid);

	    return 0;
	}

	if ( PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] || PlayerVar [ playerid ] [ E_PLAYER_IS_BEANBAGGED ] || PlayerVar [ playerid ] [ E_PLAYER_IS_TAZED ]) {

		SendClientMessage(playerid, COLOR_ERROR, "You're not allowed to enter vehicles whilst in injury, tased or beanbag mode.");

		new string [ 256 ] ;
		format ( string, sizeof ( string ), "{[ (%d) %s has tried to enter a vehicle whilst in injury, tased or beanbag mode. ]}", playerid, ReturnRPName(playerid)) ;
		SendAdminMessage(string) ;

		ClearAnimations(playerid); 
		ApplyAnimation(playerid,"PED", "FLOOR_hit_f", 4.1, 0, 0, 0, 1, 0);

		return 0 ;
	}

	// If player owns vehicle...
	//SendClientMessage ( playerid, 0xA3A3A3FF, "This vehicle is owned by you.");

	if ( ! ispassenger && ! Pilot_CanFlyVehicle ( playerid, vehicleid ) ) {

		SendClientMessage(playerid, COLOR_ERROR, "You need a pilot's license to fly this aircraft. You can take the test at the Aircraft Dealership (/gps).");
		ClearAnimations(playerid);
		return 0 ;
	}

	if ( ! ispassenger ) {
		if ( ! Character [ playerid ] [ E_CHARACTER_DRIVERSLICENSE ] && IsEngineVehicle ( vehicleid ) && !IsAircraft(vehicleid)) {
			SendClientMessage(playerid, COLOR_ERROR, "You don't own a drivers license, drive safely or the cops may issue you a ticket.");
		}
		//GameTextForPlayer(playerid, "~n~~n~~r~No license", 2000, 3);

	}

	//ShowInfoText(playerid, "~y~Press ~k~~TOGGLE_SUBMISSIONS~ to start the engine", 3000);

	#if defined veh_OnPlayerEnterVehicle
		return veh_OnPlayerEnterVehicle(playerid, vehicleid, ispassenger);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerEnterVehicle
	#undef OnPlayerEnterVehicle
#else
	#define _ALS_OnPlayerEnterVehicle
#endif

#define OnPlayerEnterVehicle veh_OnPlayerEnterVehicle
#if defined veh_OnPlayerEnterVehicle
	forward veh_OnPlayerEnterVehicle(playerid, vehicleid, ispassenger);
#endif


// Called when a player's state changes (driver, passenger, on foot). Handles the vehicle entry/exit rules.
public OnPlayerStateChange(playerid, newstate, oldstate) {

    new vehicleid = GetPlayerVehicleID(playerid);
	new veh_enum_id = Vehicle_GetEnumID(vehicleid) ;

   	if(newstate != PLAYER_STATE_ONFOOT) //wat?
    {
        RemovePlayerFromBasketball(playerid);
    }

	if ( oldstate == PLAYER_STATE_ONFOOT && newstate == PLAYER_STATE_PASSENGER ) {

		if (IsABike(vehicleid) || ! DriveBy_IsValidWeapon(AC_GetPlayerWeapon(playerid)) ) {

			SetPlayerArmedWeapon(playerid, 0);
		} 

		if (GetPVarInt(playerid, "CUFFED") == 0 && !IsABike(vehicleid))
		{
			new gunid, ammo;
			for (new i = 0; i < 13; i ++)
			{
				GetPlayerWeaponData(playerid, i, gunid, ammo ) ;

				if (DriveBy_IsValidWeapon(gunid) && ammo > 0)
				{	
					SendServerMessage ( playerid, COLOR_VEHICLE, "Drive-by", "A3A3A3", "To switch weapons type /setaw. To toggle drive-by on/off press H (wait for camera to reset!)." ); 
					break;
				}	
			} 
		}
	}

	// Show vehicle UI to driver and front seat passenger
	if ( newstate == PLAYER_STATE_DRIVER || (newstate == PLAYER_STATE_PASSENGER && GetPlayerVehicleSeat(playerid) == 1) )
	{
		if (IsEngineVehicle(vehicleid)) ShowVehicleGUI(playerid);

		// Cache the vehicle passenger too: E_VEHICLE_PASSENGER
		// Note: this is not reset if they leave the vehicle or switch seats or whatever
		if (newstate == PLAYER_STATE_PASSENGER) Vehicle [ veh_enum_id ] [ E_VEHICLE_PASSENGER ] = playerid;
	}

    if ( oldstate == PLAYER_STATE_ONFOOT && newstate == PLAYER_STATE_DRIVER ) {

		if ( PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] || PlayerVar [ playerid ] [ E_PLAYER_IS_BEANBAGGED ] || PlayerVar [ playerid ] [ E_PLAYER_IS_TAZED ]) {

			SendAdminMessage(sprintf("[Bug Abusing] (%d) %s has tried to enter a car as a driver whilst in injury, tased or beanbag mode. If persisting, ban them.", playerid, ReturnRPName(playerid))) ;

			SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Abusing SA-MP physics to get out of death- tased or beanbagmode is a bannable offence. Admins have been alerted." ) ;
			JT_RemovePlayerFromVehicle(playerid);
			TogglePlayerControllable(playerid, false);

			defer Injury_AppendAnimAfterEject(playerid);

			return true; 
    	}

		if ( GetVehicleModel ( vehicleid ) == 537 ) 
		{
			if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR) {
				new Float:x, Float:y, Float:z;

				GetPlayerPos ( playerid, x, y, z ) ;
				PauseAC(playerid, 3);
				SetPlayerPos ( playerid, x, y, z + 4 ) ;
				SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Players can not drive the train." ) ;

				return true ;
			}
		}

    	if (  IsAircraft(vehicleid) ) {
			ShowPlayerSubtitle(playerid, "Make sure to alert the authorities that you are entering airspace by using /atc.", .showtime = 6000 );
		}

    	SetPlayerArmedWeapon(playerid, 0);

		if ( IsTruckingVehicle(vehicleid) ) {

			ShowPlayerSubtitle(playerid, "This is a delivery vehicle. Use /truckerjob to learn how to make deliveries.", .showtime = 6000 );
		}
		
		if ( IsEngineVehicle(vehicleid) ) {
			if ( ! GetEngineStatus ( vehicleid ) && Vehicle_GetType ( vehicleid ) != E_VEHICLE_TYPE_JOB && Vehicle_GetType ( vehicleid ) != E_VEHICLE_TYPE_RENTAL ) {
		
				ShowPlayerSubtitle(playerid, "The engine of this vehicle is off.~n~Use /engine to turn it on or /hotwire to hotwire it.", .showtime = 6000 );
			}
		}
		
		else if ( ! IsEngineVehicle(vehicleid) ) {
			SetEngineStatus(vehicleid, true);
		}

		if ( GetEngineStatus ( vehicleid ) ) {

			defer OnPlayerDrive(playerid, vehicleid) ;
		}


		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] == Character [ playerid ] [ E_CHARACTER_ID ] ) {

			switch ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] ) {

				case E_VEHICLE_TYPE_PLAYER : SendClientMessage(playerid, COLOR_VEHICLE, "This vehicle is owned by you.");
				case E_VEHICLE_TYPE_RENTAL : SendClientMessage(playerid, COLOR_VEHICLE, "This is a rentable vehicle.");
			}

			return true ;
		}


		switch ( Vehicle_GetType ( vehicleid ) ) {

			case E_VEHICLE_TYPE_INVALID: {


				SendClientMessage(playerid, COLOR_VEHICLE, "This vehicle is not yet initialised. Please contact an admin." ) ;

				JT_RemovePlayerFromVehicle(playerid);
				return true ;
			}

			case E_VEHICLE_TYPE_RENTAL: {
							
				if ( VehicleVar [ veh_enum_id ] [ E_VEHICLE_RENTEDBY ] != INVALID_PLAYER_ID ) {

					if ( VehicleVar [ veh_enum_id ] [ E_VEHICLE_RENTEDBY ] != playerid ) {
						SendClientMessage(playerid, COLOR_VEHICLE, "This vehicle is already rented by someone else." ) ;

						return true ;
					}
				}

				else if ( VehicleVar [ veh_enum_id ] [ E_VEHICLE_RENTEDBY ] == INVALID_PLAYER_ID ) {
					ShowPlayerInfoMessage(playerid, "You can lock and unlock the car, turn the engine on and off until you quit. Unrenting refunds you.", .height=167.5, .width=180, .showtime=4000);
					ShowPlayerSubtitle(playerid, sprintf("This vehicle is rentable for $%d.~n~Type /rentvehicle to rent. /unrentvehicle to unrent.", SERVER_VEH_RENT_FEE), .showtime = 6000 );

					return true ;
				}
			}

			case E_VEHICLE_TYPE_DMV: {
				ShowPlayerInfoMessage(playerid, "This is a DMV vehicle. In order to get your drivers license, you must pass a series of challenges.", .height=167.5, .width=180, .showtime=4000);
				ShowPlayerSubtitle(playerid, sprintf("You have to drive under the speed limit and not damage the~n~vehicle. Use /taketest to start. It will cost $%d.", SERVER_DMV_FEE ), .showtime = 6000 );
		
				return true ;
			}

			case E_VEHICLE_TYPE_FACTION: {

				// If veh_faction = player_faciton...

				// "This vehicle is owned by your faction."

				if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] == Character [ playerid ] [ E_CHARACTER_FACTIONID ] ) 
				{
					if (IsGovFactionVehicle(vehicleid)) {
						if ( ! Character [ playerid ] [ E_CHARACTER_DRIVERSLICENSE ]) {
							SendClientMessage(playerid, COLOR_ERROR, "You can not drive a faction vehicle without a drivers license.");
							JT_RemovePlayerFromVehicle(playerid);
							return 1;
						}
					}
					ShowPlayerInfoMessage(playerid, "This vehicle is owned by your faction.", .height=167.5, .width=180, .showtime=4000);
					if (GetPlayerFactionSuspension(playerid)) JT_RemovePlayerFromVehicle(playerid);
				}
				else 
				{
					if ( IsGovFactionVehicle ( vehicleid ) ) 
					{
						ShowPlayerInfoMessage(playerid, "It's against the server rules to operate a government vehicle.", .height=167.5, .width=180, .showtime=4000);
						if (!PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DUTY ]) JT_RemovePlayerFromVehicle(playerid);
					}

					else ShowPlayerSubtitle(playerid, "This is a faction vehicle. Don't let them catch you using it!", .showtime = 6000 );
				}
				//else SendClientMessage(playerid, COLOR_VEHICLE, "This is a faction vehicle! Don't let them catch you using it!");
			}

			case E_VEHICLE_TYPE_JOB: {

				//switch ( GetVehicleModel ( vehicleid ) ) {
				switch ( Vehicle [ veh_enum_id ] [ E_VEHICLE_JOBID ]) {

					case E_VEHICLE_JOB_DOCKWORKER: { // dockworker 

						SendClientMessage(playerid, COLOR_JOB, "This vehicle is part of the Dockworker job. To start, type /cargojob then head to the designated point and do /cargocollect.") ;
						SendClientMessage(playerid, COLOR_JOB, "It will then point you to one of the three warehouses. Drive to the right colour and do /cargostore and repeat. /cargostop to stop.") ;
					}

					case E_VEHICLE_JOB_GARBAGEJOB: {
						SendClientMessage(playerid, COLOR_JOB, "This vehicle is part of the garbageman job. To start, type /garbagejob then head to the designated point press LALT.") ;
						SendClientMessage(playerid, COLOR_JOB, "You will pick up the trash which you must put in your garbage truck. Type /garbagejob again to stop.") ;
					}

					case E_VEHICLE_JOB_BOATYARDJOB: {
						SendClientMessage(playerid, COLOR_JOB, "This vehicle is part of the boatyard job. To start, type /freighttransport then head to the designated point.") ;
						SendClientMessage(playerid, COLOR_JOB, "You will load and unload boats as directed. Type /freighttransport again to stop.") ;
					}

					case E_VEHICLE_JOB_PIZZA: {
						SendClientMessage(playerid, COLOR_JOB, "This vehicle is part of the pizza delivery job. To start, type /pizza. You'll be given a route of 5 houses to deliver to.") ;
						SendClientMessage(playerid, COLOR_JOB, "At each house, get out, press Y next to the van to grab a pizza, then walk into the checkpoint. Use /endpizza to stop.") ;
					}

					case E_VEHICLE_JOB_TRUCKER: {
						SendClientMessage(playerid, COLOR_JOB, "This vehicle is part of the trucker job. Use /truckerjob to learn how the delivery job works.");
					}

					default: {

						SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This vehicle is a static job vehicle, but has no job assigned to it." ) ;
						JT_RemovePlayerFromVehicle(playerid);
						return true ;
					}
				}

				return true ;
			}

			case E_VEHICLE_TYPE_FIRM: {

				new firm_sql_id = Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] ;

				if ( IsPlayerInFirm ( playerid, firm_sql_id ) )
				{
					ShowPlayerInfoMessage(playerid, "This vehicle is owned by your firm.", .height=167.5, .width=180, .showtime=4000);
				}
				else
				{
					SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This vehicle belongs to a firm you're not a member of." ) ;
					JT_RemovePlayerFromVehicle(playerid);
					return true ;
				}
			}
		}
		
		/*
		if ( ! IsABike(vehicleid) || !IsAircraft(vehicleid) || !IsAPlane(vehicleid) || ! IsAHelicopter(vehicleid) ) {

			Vehicle_PlayRandomEvent(playerid);
		}*/
			
	}

	if (  (oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)  && newstate == PLAYER_STATE_ONFOOT ) {
		PauseAC(playerid, 3); // false positive when exiting cars for tp hacks, this should fix it

		if ( oldstate != PLAYER_STATE_PASSENGER ) {

			RemoveVehicleComponent(vehicleid, 1010 );
		}

		if ( PlayerVar [ playerid ] [ E_PLAYER_DRIVEBY_BRASSKNUCKLES ] ) {

			PlayerVar [ playerid ] [ E_PLAYER_DRIVEBY_BRASSKNUCKLES ]  = false ;
			GiveCustomWeapon(playerid, CUSTOM_BRASSKNUCKLE, 1 ) ;
		}

		// Clears drive-by variable.
		PlayerVar [ playerid ] [ E_PLAYER_DRIVEBY_OLD_WEAPON ] = 0 ;

		Hotwire_CloseMenu(playerid) ;
		HideVehicleGUI(playerid);
		Fuel_OnPlayerExitCar(playerid);

		if ( PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] ) {

			ApplyAnimation(playerid,"PED", "FLOOR_hit_f", 4.1, 0, 0, 0, 1, 0);
			SendServerMessage ( playerid, COLOR_BLUE, "Sync", "A3A3A3", "Re-applying death animation." ) ;
						
			return true ;
		}
	} 
	
	#if defined car_OnPlayerStateChange
		return car_OnPlayerStateChange(playerid, newstate, oldstate);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerStateChange
	#undef OnPlayerStateChange
#else
	#define _ALS_OnPlayerStateChange
#endif

#define OnPlayerStateChange car_OnPlayerStateChange
#if defined car_OnPlayerStateChange
	forward car_OnPlayerStateChange(playerid, newstate, oldstate);
#endif

// Called when a player exits a vehicle.
public OnPlayerExitVehicle(playerid, vehicleid) {

	if ( PlayerVar [ playerid ] [ player_hasseatbelton ] ) {

		new specifier [ 32] ;

		if ( IsABike ( vehicleid ) ) {

		    format ( specifier, sizeof ( specifier ), "helmet" ) ;
			RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM);
		}

		else format ( specifier, sizeof ( specifier ), "seatbelt" ) ;
		
		PlayerVar [ playerid ] [ player_hasseatbelton ] = false ;

		ProxDetectorEx(playerid, 20, COLOR_ACTION, "*", sprintf("takes off their %s.", specifier), .annonated=true);
	}

	new veh_enum_id = Vehicle_GetEnumID(vehicleid) ;
	
	if (veh_enum_id > -1)
	{
		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_JOB ) {

			if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_JOBID ] == E_VEHICLE_JOB_DOCKWORKER ) {

				//cmd_cargostop(playerid, "");
			}

		}
	}

	Vehicle [ veh_enum_id ] [ E_VEHICLE_DOORS ] = false ;
	SetDoorStatus ( vehicleid, false );

	return true ;
}
