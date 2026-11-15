// ============================================================================
// File: vehicle/fuel/func.pwn
// Refuelling logic: the refuel animation, charging for fuel and updating the vehicle's fuel
// level.
// ============================================================================


// Freezes the player and holds them in a looping holding animation for the whole fill - same
// freeze+AnimationLoop+E_PLAYER_LOOPING_ANIM pattern as Mechanic_BeginWork/EndWork
// (firm/jobs/mechanic.pwn).
Fuel_StartRefuelAnim(playerid) {

	TogglePlayerControllable(playerid, false);
	AnimationLoop(playerid, "PED", "Gun_2_IDLE", 4.1, 0, 1, 1, 1, 1, 1);
}

// Releases the freeze/animation from Fuel_StartRefuelAnim. A bare ClearAnimations doesn't
// reliably reset a frozen animation - re-apply a neutral idle stance after, same fix used
// for the pizza job's carry animation.
Fuel_StopRefuelAnim(playerid) {

	PlayerVar[playerid][E_PLAYER_LOOPING_ANIM] = 0;
	ClearAnimations(playerid, 1);
	ApplyAnimation(playerid, "PED", "IDLE_STANCE", 4.0, 0, 0, 0, 0, 1, 1);
	TogglePlayerControllable(playerid, true);
}

// Charges whatever's accumulated in E_PLAYER_FUEL_COST (from ticks in OnPlayerRefuelCar)
// and credits the linked fuel station's 70% cut. Called whenever refueling ends, whichever
// way that happens: /refuel toggled off, tank hit 100%, walked off, or the engine got started.
Fuel_FinalizePayment(playerid) {

	if ( PlayerVar [ playerid ] [ E_PLAYER_FUEL_COST ] ) {

		new fuelid = Fuel_GetNearestPump(playerid, 10.0);

		if ( fuelid != INVALID_FUEL_STATION_ID ) {
			new station_idx =  FuelStation_LinkSQLIDToEnum( FuelPump [ fuelid ] [ E_FUEL_PUMP_MANAGER_ID ] ), query [ 256 ] ;

			// Subtracting 30% of the total from the full value for end gain.
			new cost_after_taxes = PlayerVar [ playerid ] [ E_PLAYER_FUEL_COST ] - ( PlayerVar [ playerid ] [ E_PLAYER_FUEL_COST ] / 100 * 30 );

			new premium = Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL];
			new bool:isVIP = (premium >= E_PREMIUM_LVL_3);

			if (!isVIP)
			{
				FuelStation[station_idx][E_FUEL_STATION_INCOME] += cost_after_taxes;

				mysql_format(mysql, query, sizeof(query),
					"UPDATE fuelmanager SET fuelmanager_income = %d WHERE fuelmanager_id = %d",
					FuelStation[station_idx][E_FUEL_STATION_INCOME],
					FuelStation[station_idx][E_FUEL_STATION_ID]);

				mysql_tquery(mysql, query);
			}
		}

		new premium = Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL];
		new bool:isVIP = (premium >= E_PREMIUM_LVL_3);

		if (!isVIP)
		{
			TakePlayerCash(playerid, PlayerVar[playerid][E_PLAYER_FUEL_COST], "Fuel station cost");

			ShowPlayerInfoMessage(playerid, sprintf("You have paid ~g~$%s~w~ for your vehicle's fuel.",
				IntegerWithDelimiter(PlayerVar[playerid][E_PLAYER_FUEL_COST])),
				.height=285.0, .width=200.0, .showtime=6000);
		}
		else
		{
			ShowPlayerInfoMessage(playerid, "~y~VIP PERK:~w~ You refueled your vehicle for free.",
				.height=285.0, .width=200.0, .showtime=6000);
		}

		PlayerVar[playerid][E_PLAYER_FUEL_COST] = 0;
	}

	PlayerVar[playerid][E_PLAYER_REFUEL_VEHICLE] = INVALID_VEHICLE_ID;

	return true ;
}

// This is a tick that's ongoing (see player hooks). Player must remain on foot at the
// vehicle's fuel cap for the whole fill - walking off, the vehicle disappearing, or the
// engine getting started (by someone else) all stop it and charge for what's been pumped.
OnPlayerRefuelCar(playerid) {

	if ( PlayerVar [ playerid ] [ E_PLAYER_USING_NOZZLE ] ) {

		new vehicleid = PlayerVar [ playerid ] [ E_PLAYER_REFUEL_VEHICLE ] ;
		new veh_enum_id = Vehicle_GetEnumID ( vehicleid ) ;

		new bool: shouldStop = false ;

		if ( IsPlayerInAnyVehicle ( playerid ) || veh_enum_id == -1 || ! IsValidVehicle ( vehicleid ) || GetEngineStatus ( vehicleid ) ) {

			shouldStop = true ;
		}

		else {
			new Float: capX, Float: capY, Float: capZ ;
			GetVehiclePetrolCapPos(vehicleid, capX, capY, capZ) ;

			if ( ! IsPlayerInRangeOfPoint(playerid, GAS_CAP_RANGE, capX, capY, capZ) || Fuel_GetNearestPump(playerid, 10.0) == INVALID_FUEL_STATION_ID ) {

				shouldStop = true ;
			}
		}

		if ( shouldStop ) {

			PlayerVar [ playerid ] [ E_PLAYER_USING_NOZZLE ] = false ;
			Fuel_StopRefuelAnim(playerid);
			ShowPlayerInfoMessage(playerid, "Refueling stopped.", .height=285.0, .width=200.0, .showtime=4000);
			Fuel_FinalizePayment(playerid);
			return true ;
		}

		Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] ++;

		// Silently tracked - not revealed here, only when the engine is next started. Saved on
		// every tick (same cadence as Fuel_UpdateVehicleFuel's per-second save while driving) so
		// a crash/restart mid-fill doesn't lose the contamination that's already been pumped in.
		if ( PlayerVar [ playerid ] [ E_PLAYER_REFUEL_WRONG_TYPE ] && VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ] < 100 ) {

			VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ] ++;

			new query [ 128 ] ;
			mysql_format(mysql, query, sizeof ( query), "UPDATE vehicles SET vehicle_wrong_fuel_amount = %d WHERE vehicle_sqlid = %d",
				VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ]);
			mysql_tquery(mysql, query);
		}

		new premium = Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL];
		new bool:isVIP = (premium >= E_PREMIUM_LVL_3);

		if (!isVIP)
		{
			// Firm vehicles get 25% off ($1.50/unit average). Fuel costs whole
			// dollars per tick, so the discount alternates 2/1/2/1... keyed off
			// the fuel level's own parity - no extra state needed, and it lands
			// on exactly 150 for a full 100-unit fill instead of 200.
			if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_FIRM )
			{
				PlayerVar[playerid][E_PLAYER_FUEL_COST] += ( Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] % 2 == 0 ) ? 2 : 1;
			}
			else
			{
				PlayerVar[playerid][E_PLAYER_FUEL_COST] += 2;
			}
		}

		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] >= 100 ) {

			Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] = 100 ;
			PlayerVar [ playerid ] [ E_PLAYER_USING_NOZZLE ] = false ;
			Fuel_StopRefuelAnim(playerid);

			GameTextForPlayer(playerid, "~g~Tank full!", 3000, 4);
			Fuel_FinalizePayment(playerid);
			return true ;
		}

		if (isVIP)
		{
			GameTextForPlayer(playerid, sprintf("~b~%d%%~n~~g~FREE", Vehicle[veh_enum_id][E_VEHICLE_FUEL]), 1100, 4);
		}
		else
		{
			GameTextForPlayer(playerid, sprintf("~b~%d%%~n~~g~$%s",
				Vehicle[veh_enum_id][E_VEHICLE_FUEL],
				IntegerWithDelimiter(PlayerVar[playerid][E_PLAYER_FUEL_COST])
			), 1100, 4);
		}
	}

	return true ;
}

// Refueling now only happens on foot at the vehicle's fuel cap, so simply hopping into a
// (different) vehicle mid-fill no longer has anything to do with fuel - kept as a no-op
// since vehicle/data/native.pwn still calls it on every vehicle exit.
Fuel_OnPlayerExitCar(playerid) {
	#pragma unused playerid
}

// Updates a vehicle's fuel level based on how it is driven.
Fuel_UpdateVehicleFuel(veh_enum_id) {

	new vehicleid = Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ;

	if ( ! IsValidVehicle ( vehicleid ) ) {

		return false ;
	}

	if (!IsEngineVehicle(vehicleid)) {
		return false ;
	}

	if ( ! GetEngineStatus(vehicleid) ) {

		return true ;
	}

	new query[256] ;

	// DMV vehicles shouldn't lose fuel.
	if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_DMV ) {

		Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] = 100 ;
		return false ;
	}
	
	if ( GetEngineStatus ( vehicleid ) && TRP_GetVehicleSpeed(vehicleid) > 1.0 ) {

		// Mileage is tracked by Mileage_Tick (vehicle/modules/mileage.pwn) from real distance driven;
		// this once-a-minute save below just persists whatever it has built up.
		-- Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] ;

		mysql_format(mysql, query, sizeof ( query), "UPDATE vehicles SET vehicle_fuel = %d, vehicle_mileage = %d WHERE vehicle_sqlid = %d",
			Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ], Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] );

		mysql_tquery(mysql, query);
		
		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] <= 1 ) {

	    	SetEngineStatus(vehicleid, false);

	    	foreach(new playerid: Player) {

				if ( IsPlayerInVehicle ( playerid, vehicleid ) && GetVehicleDriver ( vehicleid ) == playerid ) {
					new Float: x, Float: y, Float: z, world = GetVehicleVirtualWorld(vehicleid); 
					ProxDetectorXYZ(x, y, z, 0, world, 30, COLOR_ACTION, sprintf("** The engine shuts off with a loud bang, and the %s comes to a stop.", ReturnVehicleName ( vehicleid )));
					SendServerMessage(playerid, COLOR_BLUE, "Fuel", "A3A3A3", "You've ran out of fuel. Find someone to tow your car to a gas station." ) ;
				}

				else continue ;
			}

			return true ;
		}
	}

	foreach(new playerid: Player) {

		if ( IsPlayerInVehicle ( playerid, vehicleid ) && GetPlayerVehicleSeat(playerid) <= 1 ) {

			ShowVehicleGUI(playerid);
		}

		else continue ;
	}

	return true ;
}
