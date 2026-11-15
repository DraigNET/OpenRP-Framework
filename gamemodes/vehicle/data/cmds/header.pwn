// ============================================================================
// File: vehicle/data/cmds/header.pwn
// The three most-used vehicle commands: /lock (/carlock) and /engine, with the engine start
// delay and job vehicle restrictions.
// Commands: /lock /carlock /engine
// ============================================================================

#include "vehicle/data/cmds/owner.pwn"
#include "vehicle/data/cmds/default.pwn"
#include "vehicle/data/cmds/admin.pwn"
#include "vehicle/data/cmds/storage.pwn"
#include "vehicle/data/cmds/flatbed.pwn"

CMD:lock(playerid, params[]) {

	return cmd_carlock(playerid, params);
}

// /carlock - locks or unlocks a vehicle.
CMD:carlock(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	new vehicleid = Vehicle_GetClosestEntity(playerid, .radius = 5.0);

	if ( vehicleid == INVALID_VEHICLE_ID ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not near any vehicle!");
	}

	new veh_enum_id = Vehicle_GetEnumID ( vehicleid );

	if ( veh_enum_id == -1 ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not near any proper vehicle! (couldn't fetch ID)");
	}

	if ( GetVehicleModel(vehicleid) == 481 || GetVehicleModel(vehicleid) == 509 || GetVehicleModel(vehicleid) == 510 ) {

        return SendServerMessage ( playerid, COLOR_ERROR, "Uh Oh!", "A3A3A3", "This vehicle does not have a door lock!" ) ;
    }

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {
		switch ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ]) {

			case E_VEHICLE_TYPE_PLAYER: {
				if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] && !HasCarDuplicateKey(playerid, veh_enum_id)) {

					return SendClientMessage(playerid, COLOR_ERROR, "You do not have the keys to this vehicle!");
				}
			}

			case E_VEHICLE_TYPE_FACTION: {

				if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] != Character [ playerid ] [ E_CHARACTER_FACTIONID ] ) {

					return SendClientMessage(playerid, COLOR_ERROR, "You do not have the keys to this vehicle!");
				}
			}
		}	
	}

	PlayerPlaySound(playerid, 24600, 0, 0, 0);
	if (GetDoorStatus ( vehicleid ) ) {
   
		ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**", sprintf("unlocks the %s.", ReturnVehicleName ( vehicleid )), .annonated=true);
		ShowInfoText(playerid, "~b~~h~~h~Vehicle Unlocked!", 3000);
		Vehicle [ veh_enum_id ] [ E_VEHICLE_DOORS ] = false ;
		SetDoorStatus ( vehicleid, false );
	}

	else if (!GetDoorStatus ( vehicleid ) ) {
		Vehicle [ veh_enum_id ] [ E_VEHICLE_DOORS ] = true ;
		ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**", sprintf("locks the %s.", ReturnVehicleName ( vehicleid )), .annonated=true);
		ShowInfoText(playerid, "~b~~h~~h~Vehicle Locked!", 3000);
		SetDoorStatus ( vehicleid, true );
	}


	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE vehicles SET vehicle_doors = %d WHERE vehicle_sqlid = %d",
		Vehicle [ veh_enum_id ] [ E_VEHICLE_DOORS ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ]
	);

	mysql_tquery(mysql, query);
	ClearAlarmData ( vehicleid ) ;
	
	return true ;
}

  
// /engine - starts or stops the engine.
CMD:engine(playerid) {

	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

    if ( PlayerVar [ playerid ] [ E_PLAYER_USING_NOZZLE ] ) {

		return SendClientMessage(playerid, COLOR_ERROR, "Finish refueling your vehicle before trying to turn on the engine!");
    }

	new vehicleid = GetPlayerVehicleID(playerid);
	new veh_enum_id = Vehicle_GetEnumID ( vehicleid );
	if ( veh_enum_id == -1 ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not near any proper vehicle! (couldn't fetch ID)");
	}
	if (!IsEngineVehicle(vehicleid))
		return SendClientMessage(playerid, COLOR_ERROR, "You are not in any vehicle.");

	if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
	    return SendClientMessage(playerid, COLOR_ERROR, "You can't do this as you're not the driver.");

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {
		switch ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ]) {

			case E_VEHICLE_TYPE_PLAYER: {
				if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] && !HasCarDuplicateKey(playerid, veh_enum_id)) {

					return SendClientMessage(playerid, COLOR_ERROR, "You do not own this vehicle!");
				}
			}

			case E_VEHICLE_TYPE_FACTION: {

				if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] != Character [ playerid ] [ E_CHARACTER_FACTIONID ] ) {

					return SendClientMessage(playerid, COLOR_ERROR, "You do not own this vehicle!");
				}
			}

			case E_VEHICLE_TYPE_RENTAL : {
				/*
				if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] ) {

					return SendClientMessage(playerid, COLOR_ERROR, "You have not rented this vehicle!");
				}*/

				if ( VehicleVar [ veh_enum_id ] [ E_VEHICLE_RENTEDBY ] != playerid ) {

					return SendClientMessage(playerid, COLOR_ERROR, "You have not rented this vehicle!");
				}
			}

			case E_VEHICLE_TYPE_DMV: {

				return SendClientMessage(playerid, COLOR_ERROR, "This is a DMV vehicle. You need to use /taketest!");
			}
			case E_VEHICLE_TYPE_JOB: {

				// Trucker sadlers start with /engine like a normal vehicle. Other job
				// vehicles (dockworker, pizza, garbage) must be started via their job
				// command, so keep those blocked here.
				if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_JOBID ] != E_VEHICLE_JOB_TRUCKER ) {

					return SendClientMessage(playerid, COLOR_ERROR, "You must do the right command or keystroke to turn this engine on!");
				}
			}
		}	
	}

	else {

		SendClientMessage(playerid, COLOR_YELLOW, "You're using your admin powers to start this vehicle.");
	}

	if (Vehicle [ veh_enum_id ] [E_VEHICLE_IMPOUNDED] && GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL){
		return SendClientMessage(playerid, COLOR_ERROR, "You cannot start the engine of this vehicle as it's impounded. Use /unimpound to pay the fee.");
	}

	if (Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] <= 1) {
	    return SendClientMessage(playerid, COLOR_ERROR, "The fuel tank is empty.");
	}

	if (ReturnVehicleHealth(vehicleid) <= 300) {
		if ( ! IsAircraft ( vehicleid ) ) {
	    	return SendClientMessage(playerid, COLOR_ERROR, "This vehicle is totalled and can't be started.");
	    }

	    else {

	    	SendClientMessage(playerid, COLOR_YELLOW, "Your vehicle is in very bad condition (engine damage). Get it fixed before it blows up!");
	    }
	}

	switch (GetEngineStatus(vehicleid))
	{
	    case false:
		{
			if (PlayerVar[playerid][E_PLAYER_STARTING_ENGINE])
				return SendClientMessage(playerid, COLOR_ERROR, "You're already trying to start the engine.");

			PlayerVar[playerid][E_PLAYER_STARTING_ENGINE] = true;

			ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**",
				sprintf("twists the key of the %s.",
				ReturnVehicleName(vehicleid)), .annonated=true);
			
			SetTimerEx("Engine_StartDelay", 2000, false, "ii", playerid, vehicleid);
		}
		case true:
		{
		    SetEngineStatus(vehicleid, false);
			ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**", sprintf("twists the key, turning the engine of the %s off.", ReturnVehicleName ( vehicleid )), .annonated=true);
			ShowInfoText(playerid, "~b~~h~Engine Off", 3000);
		}
	}

	ClearAlarmData ( vehicleid ) ;
	ShowVehicleGUI(playerid);
	return 1;
}

// Defined in vehicle/modules/oil.pwn, which is included after this file.
forward bool:Oil_StartCheck(playerid, vehicleid, veh_enum_id);
forward Engine_StartDelay(playerid, vehicleid);
// Timer: finishes the engine start after the starting delay.
public Engine_StartDelay(playerid, vehicleid)
{
    if (!IsPlayerConnected(playerid))
        return 1;

    PlayerVar[playerid][E_PLAYER_STARTING_ENGINE] = false;

    if (GetPlayerVehicleID(playerid) != vehicleid)
        return 1;

    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        return 1;

    if (GetEngineStatus(vehicleid))
        return 1;

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    // Overdue oil: the dash warning, a harder start, and a seized engine that won't start at all (oil.pwn).
    if (veh_enum_id != -1 && Oil_StartCheck(playerid, vehicleid, veh_enum_id))
        return 1;

    // Wrong fuel isn't revealed at the pump - it only shows up now, when the engine is
    // actually started. More than 20% of the tank being the wrong type wrecks the engine
    // outright; a smaller amount just makes it rough to start.
    if (veh_enum_id != -1 && VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ] > 0)
    {
        ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**",
            sprintf("turns the key of the %s - the engine cranks roughly.",
            ReturnVehicleName(vehicleid)), .annonated=true);

        if (VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ] > 20)
        {
            ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**",
                sprintf("hears a loud bang as the %s's engine blows.",
                ReturnVehicleName(vehicleid)), .annonated=true);

            new Float:bangX, Float:bangY, Float:bangZ;
            GetVehiclePos(vehicleid, bangX, bangY, bangZ);

            foreach (new i : Player) {

                if (IsPlayerInRangeOfPoint(i, 20.0, bangX, bangY, bangZ)) {

                    PlayerPlaySound(i, 6802, bangX, bangY, bangZ);
                }
            }

            SendClientMessage(playerid, COLOR_ERROR, "Wrong fuel! The engine has blown - get it towed to a mechanic.");

            // Badly damaged, but never actually explodes - only the chopshop minigame does that.
            SetVehicleHealth(vehicleid, 275.0);

            AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("blew the engine of a %s from bad fuel (%d%%).",
                ReturnVehicleName(vehicleid), VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ]));

            return 1;
        }

        SendClientMessage(playerid, COLOR_YELLOW, "The engine struggles for a moment on bad fuel, then catches.");

        SetEngineStatus(vehicleid, true);
        defer OnPlayerDrive(playerid, vehicleid);

        new Float:veh_x, Float:veh_y, Float:veh_z;
        GetVehiclePos(vehicleid, veh_x, veh_y, veh_z);

        ProxDetectorXYZ(veh_x, veh_y, veh_z, 0, GetPlayerVirtualWorld(playerid), 20.0, COLOR_ACTION,
            sprintf("** the %s's engine rumbles to life, running rough.", ReturnVehicleName(vehicleid)));
        ShowInfoText(playerid, "~b~~h~~h~~h~Engine On", 2000);

        ClearAlarmData(vehicleid);
        ShowVehicleGUI(playerid);

        return 1;
    }

    new Float:health = ReturnVehicleHealth(vehicleid);

    // Completely dead engine
    if (health <= 259.0)
    {
        ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**",
            sprintf("turns the key, but the %s's engine is completely dead.",
            ReturnVehicleName(vehicleid)), .annonated=true);

        SendClientMessage(playerid, COLOR_ERROR,
            "The engine is too badly damaged to start.");

        return 1;
    }

    new failureChance = 0;

    if (health >= 500.0)
    {
        // Gentle scaling from 0% → 20%
        new hpLost = floatround(999.0 - health);
        failureChance = hpLost / 50; // very light scaling
    }
    else
    {
        // Progressive worsening under 500 HP
        new damageBelow500 = floatround(500.0 - health);

        // Base 20% at 500 HP, then ramp hard
        failureChance = 20 + (damageBelow500 / 5);
    }

    // Clamp
    if (failureChance > 80)
        failureChance = 80;

    if (failureChance < 0)
        failureChance = 0;

    if (random(100) < failureChance)
    {
        ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**",
            sprintf("turns the key, but the %s's engine struggles and fails to start.",
            ReturnVehicleName(vehicleid)), .annonated=true);

        SendClientMessage(playerid, COLOR_ERROR,
            "The engine sputters and dies.");

        return 1;
    }

    // SUCCESS
    SetEngineStatus(vehicleid, true);

    defer OnPlayerDrive(playerid, vehicleid);

    new Float:veh_x, Float:veh_y, Float:veh_z;
    GetVehiclePos(vehicleid, veh_x, veh_y, veh_z);

    ProxDetectorXYZ(veh_x, veh_y, veh_z, 0, GetPlayerVirtualWorld(playerid), 20.0, COLOR_ACTION,
        sprintf("** the engine of the %s rumbles to life.",
        ReturnVehicleName(vehicleid)));
	ShowInfoText(playerid, "~b~~h~~h~~h~Engine On", 2000);

    ClearAlarmData(vehicleid);
    ShowVehicleGUI(playerid);

    return 1;
}
