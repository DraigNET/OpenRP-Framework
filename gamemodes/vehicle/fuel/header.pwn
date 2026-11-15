// ============================================================================
// File: vehicle/fuel/header.pwn
// Fuel system entry point: /refuel (/fill, /fuel), gas cans (/gascan), fuel type selection and
// the pump key handling.
// Commands: /refill /refuel /einfo /refuelcar /fillcar /carfill /carrefuel /carfuel /fuelcar
// /fuel /fill /gascan /acarfuel
// ============================================================================

#include <a_samp>
#include <streamer>
#include <sscanf2>
#include <strlib>
#include <YSI_Data\y_iterate>
#include <zcmd>
#include <progress2>

/*
	Park at a fuel pump, engine off, get out, and stand at the vehicle's fuel cap
	(read straight from the model data, not guessed) and type /refuel. Choose the
	fuel type the vehicle actually needs - petrol or diesel (see GetVehicleFuelType
	in vehicle/data/func.pwn) - pick the wrong one and the engine won't start again
	until it's drained and refuelled correctly. No passive area textdraw - GameText
	shows the running % and cost each second while it fills. Type /refuel again to
	stop early; walking off, turning the engine back on, or hitting 100% all stop
	it automatically and charge for what was pumped.

	Fuel types:
		Sort all GTA SA cars into an array per type and assign them fuel types appropiately.
			tron = normal cars
			globeoil = sports / performance / bikes
			terroil = utility, 4x4, "heavy" 

	Players can "buy" fuel stations. They earn 30% of the fuel cost. 
	They can collect this freely by doing /fuelcollect near their fuel tank object.

	For now it's static, but add a modifier for EACH fuel type.
	(Upcoming government system from v2 will be able to change these prices per nozzle stage (low/med/high)!)
	(Add a default framework for government that allows government to change these prices (government fuel tax!))
	(This fuel tax is put into the government fbank, which will eventually be linked to SD / EMS / etc)

	Fuel station owners have to invest! Fuel stations need to be refilled and can run out of juice!
	(/fuelorder: you enter an amount of $ to invest, this is 50% the cost of fuel based on type)
	(so if your regular 100% amount is 250, you pay 125 per 10%. To get 100% filled you pay 12.5k)
*/

#define GAS_CAP_RANGE (1.5)

#include "vehicle/fuel/data_owner.pwn"
#include "vehicle/fuel/data_pump.pwn"
#include "vehicle/fuel/cmds_pump.pwn"
#include "vehicle/fuel/cmds_owner.pwn"
#include "vehicle/fuel/func.pwn"
#include "vehicle/fuel/native.pwn"

// Start-up for the fuel system.
Fuel_OnScriptInit() {
	FuelStation_LoadEntities();
	FuelPump_LoadEntities();

	return true ;
}

//#warning add /fuelstations CMD - shows all fuel stations, distance, and type! (like /firms)

// Shows the fuel type dialog (regular, premium, diesel) at a pump.
Fuel_ShowTypeDialog(playerid, vehicleid) {

	inline FuelTypeResponse(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused dialogid, listitem, inputtext

		if ( ! IsPlayerConnected(pid) ) return true ;

		new veh_enum_id = Vehicle_GetEnumID(vehicleid);

		if ( veh_enum_id == -1 || ! IsValidVehicle(vehicleid) ) {

			return SendServerMessage(pid, COLOR_ERROR, "Error", "A3A3A3", "That vehicle isn't there anymore.");
		}

		new Float: capX, Float: capY, Float: capZ;
		GetVehiclePetrolCapPos(vehicleid, capX, capY, capZ);

		if ( ! IsPlayerInRangeOfPoint(pid, GAS_CAP_RANGE, capX, capY, capZ) ) {

			return SendServerMessage(pid, COLOR_ERROR, "Error", "A3A3A3", "You walked away from the fuel cap.");
		}

		new chosen_type = response ? VEHICLE_FUEL_TYPE_PETROL : VEHICLE_FUEL_TYPE_DIESEL;

		// Doesn't reveal whether it's the right type - that's only found out when the
		// engine is next started (see CMD:engine). Pumping proceeds identically either way.
		PlayerVar [ pid ] [ E_PLAYER_REFUEL_WRONG_TYPE ] = (chosen_type != GetVehicleFuelType(vehicleid));

		PlayerVar [ pid ] [ E_PLAYER_USING_NOZZLE ] = true;
		PlayerVar [ pid ] [ E_PLAYER_REFUEL_VEHICLE ] = vehicleid;

		Fuel_StartRefuelAnim(pid);

		SendServerMessage(pid, COLOR_BLUE, "Fuel", "A3A3A3", "You start refueling the vehicle. Type /refuel again to stop.");

		OnPlayerRefuelCar(pid);

		return true;
	}

	Dialog_ShowCallback(playerid, using inline FuelTypeResponse, DIALOG_STYLE_MSGBOX, "Fuel Type",
		"What type of fuel does this vehicle need?", "Petrol", "Diesel");

	return true;
}

// /refill - refuels the vehicle you are in at a pump.
CMD:refill(playerid) {

	if ( PlayerVar [ playerid ] [ E_PLAYER_USING_NOZZLE ] ) {

		PlayerVar [ playerid ] [ E_PLAYER_USING_NOZZLE ] = false;
		Fuel_StopRefuelAnim(playerid);
		Fuel_FinalizePayment(playerid);
		return SendServerMessage(playerid, COLOR_BLUE, "Fuel", "A3A3A3", "You've stopped refueling.");
	}

	if ( IsPlayerInAnyVehicle(playerid) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Get out of the vehicle and walk to its fuel cap to refuel it.");
	}

	new vehicleid = Vehicle_GetClosestEntity(playerid, 5.0);

	if ( vehicleid == INVALID_VEHICLE_ID ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "There's no vehicle nearby to refuel.");
	}

	if ( ! IsEngineVehicle(vehicleid) || GetVehicleFuelType(vehicleid) == VEHICLE_FUEL_TYPE_NONE ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This vehicle doesn't use liquid fuel.");
	}

	if ( GetEngineStatus(vehicleid) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Turn the vehicle's engine off before refueling (/engine).");
	}

	new veh_enum_id = Vehicle_GetEnumID(vehicleid);

	if ( veh_enum_id == -1 ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near a proper vehicle.");
	}

	if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] >= 100 ) {

		Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] = 100;
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This vehicle's tank is already full.");
	}

	new Float: capX, Float: capY, Float: capZ;
	GetVehiclePetrolCapPos(vehicleid, capX, capY, capZ);

	if ( ! IsPlayerInRangeOfPoint(playerid, GAS_CAP_RANGE, capX, capY, capZ) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You need to be standing right at the vehicle's fuel cap.");
	}

	new fuelid = Fuel_GetNearestPump(playerid, 10.0);

	if ( fuelid == INVALID_FUEL_STATION_ID ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be parked at a fuel pump to refuel.");
	}

	// Any vehicle can use any pump - the old normal/freight pump restriction is gone.

	Fuel_ShowTypeDialog(playerid, vehicleid);

	return true;
}
CMD:refuel(playerid) return cmd_refill(playerid);

// /einfo - shows engine and fuel information for your vehicle.
CMD:einfo(playerid) {

	new vehicleid = IsPlayerInAnyVehicle(playerid) ? GetPlayerVehicleID(playerid) : Vehicle_GetClosestEntity(playerid, 5.0);

	if ( vehicleid == INVALID_VEHICLE_ID || ! IsEngineVehicle(vehicleid) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You need to be in, or standing near, a vehicle with an engine.");
	}

	new fueltype[8];

	switch ( GetVehicleFuelType(vehicleid) ) {

		case VEHICLE_FUEL_TYPE_PETROL: fueltype = "Petrol";
		case VEHICLE_FUEL_TYPE_DIESEL: fueltype = "Diesel";
		default: fueltype = "None";
	}

	SendClientMessage(playerid, COLOR_INFO, sprintf("[%s] Fuel Type: {38B0DE}%s", ReturnVehicleName(vehicleid), fueltype));

	return true;
}
CMD:refuelcar(playerid) return cmd_refill(playerid);
CMD:fillcar(playerid) return cmd_refill(playerid);
CMD:carfill(playerid) return cmd_refill(playerid);
CMD:carrefuel(playerid) return cmd_refill(playerid);
CMD:carfuel(playerid) return cmd_refill(playerid);
CMD:fuelcar(playerid) return cmd_refill(playerid);
CMD:fuel(playerid) return cmd_refill(playerid);
CMD:fill(playerid) return cmd_refill(playerid);

#define GASCAN_POUR_TIME (4000)

forward Gascan_FinishPour(playerid, vehicleid);
// Finishes pouring a gas can into a vehicle.
public Gascan_FinishPour(playerid, vehicleid) {

	if ( ! IsPlayerConnected(playerid) ) return true;

	Fuel_StopRefuelAnim(playerid);

	new veh_enum_id = Vehicle_GetEnumID(vehicleid);

	if ( veh_enum_id == -1 || ! IsValidVehicle(vehicleid) || ! PlayerVar [ playerid ] [ E_PLAYER_HAS_GASCAN ] ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Something interrupted the refuel - your gascan wasn't used.");
	}

	new Float: capX, Float: capY, Float: capZ;
	GetVehiclePetrolCapPos(vehicleid, capX, capY, capZ);

	if ( ! IsPlayerInRangeOfPoint(playerid, GAS_CAP_RANGE * 2, capX, capY, capZ) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You walked away before finishing - your gascan wasn't used.");
	}

	VehicleVar [ veh_enum_id ] [ E_VEHICLE_VAR_FUEL_INCR ] = 0;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] = 35;
	PlayerVar [ playerid ] [ E_PLAYER_HAS_GASCAN ] = false;

	new query [ 256 ];

	mysql_format(mysql, query, sizeof ( query), "UPDATE vehicles SET vehicle_fuel = %d WHERE vehicle_sqlid = %d",
		Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] );

	mysql_tquery(mysql, query);

	ProxDetectorEx(playerid, 30.0, COLOR_ACTION, "**", sprintf("empties a gascan into their %s.", ReturnVehicleName ( vehicleid )), .annonated=true);
	SendServerMessage ( playerid, COLOR_BLUE, "Fuel", "A3A3A3", "You've refueled your vehicle." );

	return true;
}

// /gascan - pours a gas can into the vehicle you are at.
CMD:gascan(playerid) {

	if ( ! PlayerVar [ playerid ] [ E_PLAYER_HAS_GASCAN ] ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have a gascan! Buy one from a 24/7 or General Store.");
	}

	if ( IsPlayerInAnyVehicle(playerid) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Get out of the vehicle and stand at its fuel cap to use the gascan.");
	}

	new vehicleid = Vehicle_GetClosestEntity(playerid, 5.0);
	new veh_enum_id = Vehicle_GetEnumID(vehicleid);

	if ( veh_enum_id == -1 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "There's no vehicle nearby to refuel.");
	}

	if ( ! IsEngineVehicle(vehicleid) || GetVehicleFuelType(vehicleid) == VEHICLE_FUEL_TYPE_NONE ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This vehicle doesn't use liquid fuel.");
	}

	if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] >= 25 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Your vehicle still has 25 percent or more left in the tank!");
	}

	new Float: capX, Float: capY, Float: capZ;
	GetVehiclePetrolCapPos(vehicleid, capX, capY, capZ);

	if ( ! IsPlayerInRangeOfPoint(playerid, GAS_CAP_RANGE, capX, capY, capZ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You need to be standing right at the vehicle's fuel cap.");
	}

	Fuel_StartRefuelAnim(playerid);

	SendServerMessage(playerid, COLOR_BLUE, "Fuel", "A3A3A3", "You start emptying the gascan into the vehicle...");

	SetTimerEx("Gascan_FinishPour", GASCAN_POUR_TIME, false, "ii", playerid, vehicleid);

	return true ;
}

// Sets a vehicle's fuel level directly (bypassing the pump dialog entirely, so it's always
// clean fuel of the correct type) and always clears any wrong-fuel contamination - this is
// the admin equivalent of a mechanic's /mechanic drainfuel followed by a refill.
CMD:acarfuel(playerid, params[])
{
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

    new endpid, vid, amount, string [ 128 ], name[MAX_PLAYER_NAME+1], msgfrom[MAX_PLAYER_NAME+24] ;

    if (sscanf(params, "k<player>I(100)", endpid, amount) == 0)
    {
    	vid = GetPlayerVehicleID(endpid);

        if (IsPlayerConnected(endpid))
        {
			amount = clamp(amount, 0, 100);

            GetPlayerName(endpid, name, sizeof(name));
			if (vid != 0)
			{

				new veh_enum_id = Vehicle_GetEnumID(vid) ;
				Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] = amount;
				VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ] = 0;

				mysql_format(mysql, string, sizeof(string), "UPDATE vehicles SET vehicle_fuel = %d, vehicle_wrong_fuel_amount = 0 WHERE vehicle_sqlid = %d",
					amount, Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ]);
				mysql_tquery(mysql, string);

			   	format (string, sizeof(string), "[AdminCmd]: (%d) %s has set car (%d)'s fuel to %d%%.", playerid, ReturnRPName(playerid), vid, amount) ;
			   	SendAdminMessage(string) ;

			    if (endpid != playerid)
			    {
			        new msgto[48];
				    format(msgto, sizeof(msgto), "Your car's fuel has been set to %d%% by an admin.", amount);
					SendClientMessage(endpid, 0xFFFFFFFF, msgto);
				}
	    	}
	    	else
			{
   				new msg[MAX_PLAYER_NAME+33];
			    format(msg, sizeof(msg), "%s is not in any vehicle.", name);
				SendClientMessage(playerid, COLOR_RED, msg);
			}
    	}
    	else SendClientMessage(playerid, COLOR_RED, "Invalid player ID");
	}
	else
	{
		vid = GetPlayerVehicleID(playerid) ;
        GetPlayerName(playerid, name, sizeof(name));
		if (vid != 0)
		{
			amount = clamp(amount, 0, 100);

			new veh_enum_id = Vehicle_GetEnumID(vid) ;
			Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] = amount;
			VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ] = 0;

			mysql_format(mysql, string, sizeof(string), "UPDATE vehicles SET vehicle_fuel = %d, vehicle_wrong_fuel_amount = 0 WHERE vehicle_sqlid = %d",
				amount, Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ]);
			mysql_tquery(mysql, string);

		   	format ( string, sizeof ( string ), "[AdminCmd]: (%d) %s has set car (%d)'s fuel to %d%%.",
		   		playerid, ReturnRPName ( playerid ), vid, amount ) ;

		   	SendAdminMessage(string) ;

			format(msgfrom, sizeof(msgfrom), "%s's car's fuel has been set to %d%%.", name, amount);
			SendClientMessage(playerid, 0xFFFFFFFF, msgfrom);
    	}
    	else SendClientMessage(playerid, COLOR_RED,"Usage: /acarfuel [playerid] [amount (default 100)]");
	}

	return 1;
}
